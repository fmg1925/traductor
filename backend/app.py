from flask import Flask, jsonify, request
from flask_cors import cross_origin
from beginnergen import generate_sentence_beginner
from dotenv import load_dotenv
from functools import lru_cache
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from typing import Any, Tuple, cast, List
from diskcache import Cache
from phonemizer import phonemize
from phonemizer.separator import Separator
import hashlib, requests, os, sys, io, base64, numpy as np
from PIL import Image, ImageOps
from paddleocr import PaddleOCR
from pypinyin import lazy_pinyin, Style

EN = "en"

LANG_MAP = {
    'es': 'es',
    'en': 'en-us',
    'zh': 'cmn-latn-pinyin',
    'ko': 'ko',
}

MAX_LONG_SIDE = 2000

load_dotenv()
URI = os.getenv("LIBRETRANSLATE_URI", "").rstrip("/")
REQUEST_TIMEOUT = float(os.getenv("LT_TIMEOUT", "20"))
MAX_WORKERS = int(os.getenv("LT_MAX_WORKERS", "8"))

ocrInstance = PaddleOCR()

if sys.platform == "win32":
    ESPEAK_DIR = os.getenv("PHONEMIZER_ESPEAK_DIR", r"C:\Program Files\eSpeak NG")
    ESPEAK_DLL = os.path.join(ESPEAK_DIR, "libespeak-ng.dll")
    os.environ.setdefault("PHONEMIZER_ESPEAK_LIBRARY", ESPEAK_DLL)

def _json_or_text(resp: requests.Response) -> Tuple[bool, dict[str, Any] | str]:
    try:
        return True, resp.json()
    except Exception:
        return False, resp.text

def _pretty_error(prefix: str, resp: requests.Response) -> str:
    is_json, data = _json_or_text(resp)
    if is_json and isinstance(data, dict) and "error" in data:
        return f"{prefix}: {data['error']}"
    if is_json:
        return f"{prefix}: invalid JSON schema: {data}"
    if isinstance(data, str):
        return f"{prefix}: {resp.status_code} {resp.reason} · body={data[:240]}"
    return f"{prefix}: {resp.status_code} {resp.reason} · body={str(data)[:240]}"

def make_session() -> requests.Session:
    sess = requests.Session()
    retries = Retry(
        total = 3,
        connect = 3,
        read = 3,
        backoff_factor= 0.5,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=frozenset(["POST", "GET"])
    )
    adapter = HTTPAdapter(max_retries=retries, pool_connections=20, pool_maxsize=50)
    sess.mount("http://", adapter)
    sess.mount("https://", adapter)
    sess.headers.update({
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "waza-flask/1.0"
    })
    return sess

session = make_session()
app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 25 * 1024 * 1024 # 25 MB máximo en fotos
cache = Cache('./.cache')

def cache_key(text, source, target):
    h = hashlib.sha256(f'{source}|{target}|{text}'.encode()).hexdigest()
    return f'th:{h}'

@lru_cache(maxsize=8192)
def translate_cached(text: str, source: str, target: str) -> str:
    target = target.strip().lower()
    payload = {"q": text, "source": source.strip().lower(), "target": target, "format": "text"}
    r = session.post(f"{URI}/translate", json=payload, timeout=REQUEST_TIMEOUT)
    if not r.ok:
        raise RuntimeError(_pretty_error("HTTP error", r))
    ok_json, data = _json_or_text(r)
    if not ok_json:
        raise ValueError(f"Non-JSON response from backend: {str(data)[:200]}")

    if not isinstance(data, dict):
        raise TypeError(f"Unexpected response type: {type(data)}")

    if "error" in data:
        raise ValueError(str(data["error"]))

    if "translatedText" not in data:
        raise KeyError("Missing 'translatedText' in response")

    return str(data["translatedText"])

def translate_many(text: str, source: str, targets: list[str]) -> dict[str, str]:
    results: dict[str, str] = {}
    unique_targets = list(dict.fromkeys([t.strip().lower() for t in targets if t and t.strip()]))
    if not unique_targets:
        return results
    to_translate: list[str] = []
    
    for t in unique_targets:
        key = cache_key(text, source, t)
        cached = cache.get(key)
        if cached is not None:
            results[t] = str(cached)
        else:
            to_translate.append(t)
    
    with ThreadPoolExecutor(max_workers=min(MAX_WORKERS, len(to_translate))) as ex:
        futs = {ex.submit(translate_cached, text, source, t): t for t in to_translate}
        for fut in as_completed(futs):
            t = futs[fut]
            try:
                results[t] = fut.result()
            except Exception as e:
                results[t] = f"[error: {type(e).__name__}: {e}]"
    return results

def lt_translate(q: str, source: str, target: str) -> dict:
    payload = {"q": q, "source": source, "target": target, "format": "text"}
    r = session.post(f"{URI}/translate", json=payload, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    return r.json()

def build_payload(originalText=None, translatedText=None,
                  detectedLanguage=None, target=None,
                  originalIpa=None, translatedIpa = None, error=None) -> dict:
    payload = {
        "originalText": originalText,
        "translatedText": translatedText,
        "detectedLanguage": detectedLanguage,
        "target": target,
        "originalIpa": originalIpa,
        "translatedIpa": translatedIpa,
    }
    if error is not None:
        payload["error"] = f"Error generando frase: {str(error)}"
    return payload

def retornar(payload: dict, status_code: int = 200):
    return jsonify(payload), status_code
    
def ipa_word(sentence: str, lang_code: str) -> list[str]:
    lang = LANG_MAP.get(lang_code.split('-')[0].lower())
    if not lang:
        return []
    
    if lang == 'zh' or lang == 'cmn-latn-pinyin':
        try:
            parts = sentence.split()
            if parts:
                return [' '.join(lazy_pinyin(w, style=Style.TONE)).strip() for w in parts if w]
            # no spaces: pinyin per char, joined with spaces
            return [' '.join(lazy_pinyin(sentence, style=Style.TONE)).strip()]
        except Exception:
            # fallback to IPA path below if pypinyin isn't available
            pass
    
    words = sentence.split()
    if not words:
        return []

    out = phonemize(
        words,
        language=lang,
        backend='espeak',
        strip=True,
        with_stress=True,
        njobs=1,
        punctuation_marks=';:,.!?¡¿—…"«»“”()[]{}<>',
        preserve_punctuation=False,
        separator=Separator(phone=' ', word='', syllable=''),
    )

    ipa_list: List[str] = []
    for item in out:
        if isinstance(item, (list, tuple)):
            ipa_list.append(' '.join(str(x) for x in item if x))
        else:
            ipa_list.append(str(item).strip())
    return [w for w in ipa_list if w]

@app.route("/", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def index():
    data = request.get_json(force=True) or {}
    originalLanguage = (data.get("originalLanguage") or EN).strip().lower()
    target = (data.get("target") or "es").strip().lower()

    try:
        sentence = generate_sentence_beginner()
    except Exception as e:
        payload = build_payload(error=e, target=target)
        return retornar(payload, 500)
        
    key = cache_key(sentence, originalLanguage, target)
    cached = cache.get(key)
    if cached:
        return jsonify(cached)
    
    detected_for_ui = originalLanguage if originalLanguage != "auto" else EN

    try:
        if originalLanguage == EN and target == EN:
            ipa = ipa_word(sentence, EN)
            payload = build_payload(sentence, sentence, EN, target, ipa, ipa)
            cache.set(key, payload)
            return retornar(payload, 200)
    
        if originalLanguage == target != EN:
            data_lang = lt_translate(sentence, EN, target)
            text_lang = data_lang.get("translatedText", "")
            if originalLanguage == "auto":
                dl = data_lang.get("detectedLanguage")
                if isinstance(dl, dict) and dl.get("language"):
                    detected_for_ui = dl["language"]
                elif isinstance(dl, str) and dl:
                    detected_for_ui = dl
                    
            ipa = ipa_word(text_lang, detected_for_ui)
                    
            payload = build_payload(text_lang, text_lang, detected_for_ui, target, ipa, ipa)
            cache.set(key, payload, expire=86400)
            return retornar(payload, 200)   
        original_text = sentence
        translated_text = sentence

        if originalLanguage != EN and originalLanguage != "auto":
            resp_orig = lt_translate(sentence, EN, originalLanguage)
            original_text = resp_orig.get("translatedText", "")
        elif originalLanguage == "auto":
            original_text = sentence

        if target == EN:
            translated_text = sentence
        else:
            resp_tgt = lt_translate(sentence, EN, target)
            translated_text = resp_tgt.get("translatedText", "")
            if originalLanguage == "auto":
                dl = resp_tgt.get("detectedLanguage")
                if isinstance(dl, dict) and dl.get("language"):
                    detected_for_ui = dl["language"]
                elif isinstance(dl, str) and dl:
                    detected_for_ui = dl

        originalIpa = ipa_word(original_text, detected_for_ui)
        translatedIpa = ipa_word(translated_text, target)                    
        payload = build_payload(original_text, translated_text, detected_for_ui, target, originalIpa, translatedIpa)
    
        return retornar(payload, 200)
    except Exception as e:
        payload = build_payload(sentence, None, detected_for_ui, target, None, None, e)
        return retornar(payload, 502)
    
@app.route("/translate", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def translate():
    data = request.get_json(force=True)
    sentence = data.get("q", "")
    source = data.get("source", "auto")
    target = data.get("target", "es")
    
    if source == target:
        ipa = ipa_word(sentence, source if source != 'auto' else target)
        resultado = build_payload(sentence, sentence, source, target, ipa, ipa)
        return retornar(resultado, 200)
    
    key = cache_key(sentence, source, target)
    cached = cache.get(key)
    if cached is not None:
        cached_dict = cast(dict[str, Any], cached)
        return retornar(cached_dict, 200)
    
    payload = {"q": sentence, "source": source, "target": target, "format": "text"}
    r = session.post(f"{URI}/translate", json=payload, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    data = r.json()
    translated = data.get("translatedText")
    detected = data.get("detectedLanguage", {}).get("language")
    if not detected:
        detected = source
        
    originalIpa = ipa_word(sentence, detected)
    translatedIpa = ipa_word(translated, target)
        
    resultado = build_payload(sentence, translated, detected, target, originalIpa, translatedIpa)
    cache.set(key, resultado)
    return retornar(resultado, 200)

@app.route("/ocr", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def ocr():
    data = request.get_json(force=True)
    target = data.get("target", "en")
    img = read_image_from_request()
    
    result = ocrInstance.predict(input=img)
    
    texts = result[0]['rec_texts']
    
    ocrString = " ".join(texts)
    
    payload = {"q": ocrString, "source": "auto", "target": target, "format": "text"}
    r = session.post(f"{URI}/translate", json=payload, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    data = r.json()
    translated = data.get("translatedText")
    detected = data.get("detectedLanguage", {}).get("language")
    
    originalIpa = ipa_word(ocrString, detected)
    translatedIpa = ipa_word(translated, target)
        
    resultado = build_payload(ocrString, translated, detected, target, originalIpa, translatedIpa)
        
    return retornar(resultado, 200)

def read_image_from_request():
    f = request.files.get('file')
    if f:
        img = Image.open(f.stream)
    else:
        data = request.get_json(silent=True) or {}
        b64 = data.get('image_b64')
        if not b64:
            raise ValueError("No hay 'file' ni 'image_b64'")
        if b64.strip().startswith('data:') and ',' in b64:
            b64 = b64.split(',', 1)[1]
        img = Image.open(io.BytesIO(base64.b64decode(b64)))
    
    img = ImageOps.exif_transpose(img)
    if img.mode != "RGB":
        img = img.convert("RGB")
        
    w, h = img.size
    long_side = max(w, h)
    if long_side > MAX_LONG_SIDE:
        scale = MAX_LONG_SIDE / float(long_side)
        img = img.resize((int(w * scale), int(h * scale)), Image.Resampling.LANCZOS)

    arr = np.array(img, dtype=np.uint8)

    # Hard-guard shape to HxWx3
    if arr.ndim == 2:
        arr = np.stack([arr, arr, arr], axis=-1)
    elif arr.ndim == 3 and arr.shape[2] == 4:
        arr = arr[..., :3]
    elif arr.ndim != 3 or arr.shape[2] != 3:
        raise ValueError(f"Unexpected image shape {arr.shape}; expected HxWx3.")

    return arr

if __name__ == "__main__":
    app.run(debug=True, port=3000, threaded=True)
