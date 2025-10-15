from collections.abc import Iterable
from flask import Flask, jsonify, request
from flask_cors import cross_origin
from beginnergen import generate_sentence_beginner, conseguirPalabraRandom
from dotenv import load_dotenv
from concurrent.futures import ThreadPoolExecutor
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from typing import Any, cast
from diskcache import Cache
import hashlib, requests, os, sys, io, base64, re, numpy as np
from PIL import Image, ImageOps
from paddleocr import PaddleOCR
from ipa import pronounce, space_chinese_for_flutter, space_japanese_for_flutter

EN = "en"

Image.MAX_IMAGE_PIXELS = 40_000_000
MAX_LONG_SIDE = 1920

load_dotenv()
URI = os.getenv("LIBRETRANSLATE_URI", "http://localhost:5050").rstrip("/")
REQUEST_TIMEOUT = float(os.getenv("LT_TIMEOUT", "20"))
MAX_WORKERS = int(os.getenv("LT_MAX_WORKERS", "8"))
MAX_SENTENCE_LENGTH = 50

ocrInstance = PaddleOCR()

if sys.platform == "win32":
    ESPEAK_DIR = os.getenv("PHONEMIZER_ESPEAK_DIR", r"C:\Program Files\eSpeak NG")
    ESPEAK_DLL = os.path.join(ESPEAK_DIR, "libespeak-ng.dll")
    os.environ.setdefault("PHONEMIZER_ESPEAK_LIBRARY", ESPEAK_DLL)

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
    h = hashlib.blake2b(f'{source.lower()}|{target.lower()}|{text.lower()}'.encode(), digest_size=16).hexdigest()
    return f'th:{h}'

def lt_translate(q: str, source: str, target: str) -> dict:
    payload = {"q": q, "source": source.strip().lower(), "target": target.strip().lower(), "format": "text"}
    r = session.post(f"{URI}/translate", json=payload, timeout=(3.0, REQUEST_TIMEOUT))
    r.raise_for_status()
    return r.json()

def build_payload(originalText=None, translatedText=None,
                  detectedLanguage=None, target=None,
                  originalIpa=None, translatedIpa = None, originalRomanization=None, translatedRomanization=None, error=None) -> dict:
    payload = {
        "originalText": originalText,
        "translatedText": translatedText,
        "detectedLanguage": detectedLanguage,
        "target": target,
        "originalRomanization": originalRomanization,
        "translatedRomanization": translatedRomanization,
        "originalIpa": originalIpa,
        "translatedIpa": translatedIpa
    }
    if error is not None:
        payload["error"] = f"Error generando frase: {str(error)}"
    return payload

def retornar(payload: dict, status_code: int = 200):
    return jsonify(payload), status_code

def ensure_list_str(v) -> list[str]:
    if v is None: return []
    if isinstance(v, str): return [s for s in v.split() if s]
    if isinstance(v, Iterable) and not isinstance(v, (str, bytes)):
        return [str(x) for x in v]
    return [str(v)]

@app.route("/", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def index():
    data = request.get_json(force=True) or {}
    originalLanguage = (data.get("originalLanguage") or EN).strip().lower()
    target = (data.get("target") or "es").strip().lower()
    tipo = (data.get("tipo") or "").strip().lower()

    if tipo == "frase":
        sentence = generate_sentence_beginner()
    else:
        sentence = conseguirPalabraRandom(tipo)

    key = cache_key(sentence, originalLanguage, target)
    cached = cache.get(key)
    if cached:
        return jsonify(cached)

    detected_for_ui = originalLanguage if originalLanguage != "auto" else EN

    try:
        if originalLanguage == EN and target == EN:
            pr = pronounce(sentence, EN)
            payload = build_payload(sentence, sentence, EN, target, pr.ipa, pr)
            cache.set(key, payload)
            return retornar(payload, 200)

        if originalLanguage == target and originalLanguage != EN:
            data_lang = lt_translate(sentence, EN, target)
            text_lang = data_lang.get("translatedText", "")
            if originalLanguage == "auto":
                dl = data_lang.get("detectedLanguage")
                if isinstance(dl, dict) and dl.get("language"):
                    detected_for_ui = dl["language"]
                elif isinstance(dl, str) and dl:
                    detected_for_ui = dl

            ipa = pronounce(text_lang, detected_for_ui)
            payload = build_payload(text_lang, text_lang, detected_for_ui, target, ipa.ipa, ipa.ipa, ipa.roman, ipa.roman)
            cache.set(key, payload)
            return retornar(payload, 200)

        original_text = sentence
        translated_text = sentence

        fut_orig = None
        fut_tgt  = None
        with ThreadPoolExecutor(max_workers=2) as ex:
            if originalLanguage not in (EN, "auto"):
                fut_orig = ex.submit(lt_translate, sentence, EN, originalLanguage)
            if target != EN:
                fut_tgt = ex.submit(lt_translate, sentence, EN, target)

        if fut_orig is not None:
            resp_orig = fut_orig.result()
            original_text = resp_orig.get("translatedText", "")

        if fut_tgt is not None:
            resp_tgt = fut_tgt.result()
            translated_text = resp_tgt.get("translatedText", "")
            if originalLanguage == "auto":
                dl = resp_tgt.get("detectedLanguage")
                if isinstance(dl, dict) and dl.get("language"):
                    detected_for_ui = dl["language"]
                elif isinstance(dl, str) and dl:
                    detected_for_ui = dl
                    
        display_original = original_text or ''
        display_translated = translated_text or ''
        if detected_for_ui in ('ja','jpx'):
            display_original = space_japanese_for_flutter(display_original)
        elif detected_for_ui.startswith('zh'):
            display_original = space_chinese_for_flutter(display_original)
        if target in ('ja','jpx'):
            display_translated = space_japanese_for_flutter(display_translated)
        elif target.startswith('zh'):
            display_translated = space_chinese_for_flutter(display_translated)
   
        oIpa = pronounce(sentence, detected_for_ui)
        tIpa = pronounce(translated_text, target)
        originalIpa = oIpa.ipa
        translatedIpa = tIpa.ipa
        originalRomanization = oIpa.roman
        translatedRomanization = tIpa.roman

        payload = build_payload(
            display_original, display_translated, detected_for_ui, target, originalIpa, translatedIpa, originalRomanization, translatedRomanization
        )
        cache.set(key, payload)
        return retornar(payload, 200)

    except Exception as e:
        return retornar(
            build_payload(sentence, None, detected_for_ui, target, None, None, e), 502
        )
    
@app.route("/translate", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def translate():
    data = request.get_json(silent=True) or {}
    sentence = data.get("q", "").strip()
    source = data.get("source", "auto")
    target = data.get("target", "es")
    
    if not sentence:
        return retornar(build_payload("", "", source, target, [], []), 200)
    
    sentence = " ".join(sentence.split())[:MAX_SENTENCE_LENGTH]
    
    if target == "auto":
        target = "es"
    
    if source == target:
        ipa = pronounce(sentence, source if source != 'auto' else target)
        resultado = build_payload(sentence, sentence, source, target, ipa.ipa, ipa.roman, ipa.ipa)
        return retornar(resultado, 200)
    
    key = cache_key(sentence, source, target)
    cached = cache.get(key)
    if cached is not None:
        cached_dict = cast(dict[str, Any], cached)
        return retornar(cached_dict, 200)
    
    payload = {"q": sentence, "source": source, "target": target}
    r = session.post(f"{URI}/translate", json=payload, timeout=(3.0, REQUEST_TIMEOUT))
    r.raise_for_status()
    data = r.json()
    
    translated = data.get("translatedText") or ""
    dl = data.get("detectedLanguage")
    if isinstance(dl, dict):
        detected = (dl.get("language") or source) if dl is not None else source
    elif isinstance(dl, str):
        detected = dl or source
    else:
        detected = source
        
    with ThreadPoolExecutor(max_workers=2) as ex:
        f1 = ex.submit(pronounce, sentence, detected)
        f2 = ex.submit(pronounce, translated, target)
        originalIpa = f1.result().ipa
        originalRomanization = f1.result().roman
        translatedIpa = f2.result().ipa
        translatedRomanization = f2.result().roman
    
    resultado = build_payload(sentence, translated, detected, target, originalIpa, translatedIpa, originalRomanization, translatedRomanization)
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
    r = session.post(f"{URI}/translate", json=payload, timeout=(3.0, REQUEST_TIMEOUT))
    r.raise_for_status()
    data = r.json()
    translated = data.get("translatedText")
    detected = data.get("detectedLanguage", {}).get("language")
    
    oIpa = pronounce(ocrString, detected)
    originalIpa = oIpa.ipa
    originalRomanization = oIpa.roman
    tIpa = pronounce(translated, target)
    translatedIpa = tIpa.ipa
    translatedRomanization = tIpa.roman
        
    resultado = build_payload(ocrString, translated, detected, target, originalIpa, translatedIpa, originalRomanization, translatedRomanization)
        
    return retornar(resultado, 200)

def read_image_from_request():
    f = request.files.get('file')
    if f:
        img = Image.open(f.stream)
    else:
        data = request.get_json(silent=True) or {}
        b64 = data.get('image_b64')
        if not b64: raise ValueError("No hay 'file' ni 'image_b64'")
        if b64.strip().startswith('data:') and ',' in b64:
            b64 = b64.split(',', 1)[1]
        img = Image.open(io.BytesIO(base64.b64decode(b64)))
    img = ImageOps.exif_transpose(img)
    if img.mode != "RGB": img = img.convert("RGB")
    w, h = img.size
    m = max(w, h)
    if m > MAX_LONG_SIDE:
        s = MAX_LONG_SIDE / float(m)
        img = img.resize((int(w*s), int(h*s)), Image.Resampling.LANCZOS)
    arr = np.asarray(img, dtype=np.uint8)
    if arr.ndim == 2: arr = np.stack([arr, arr, arr], axis=-1)
    if arr.ndim == 3 and arr.shape[2] == 4: arr = arr[..., :3]
    if arr.ndim != 3 or arr.shape[2] != 3:
        raise ValueError(f"Unexpected image shape {arr.shape}")
    return arr

if __name__ == "__main__":
    app.run(debug=True, port=3000, threaded=True)
