from flask import Flask, request
from flask.wrappers import Response
from flask_cors import cross_origin
from beginnergen import generate_sentence_beginner, conseguirPalabraRandom
from dotenv import load_dotenv
from concurrent.futures import Future, ThreadPoolExecutor
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from typing import List, Optional, Tuple
from diskcache import Cache
import hashlib, requests, os, sys, io, base64, numpy as np
from PIL import Image, ImageOps
from paddleocr import PaddleOCR
from ipa import pronounce, space_chinese_for_flutter, space_japanese_for_flutter
from langdetect import DetectorFactory, detect
import orjson
import threading

DetectorFactory.seed = 0

EN = "en"

Image.MAX_IMAGE_PIXELS = 40_000_000
MAX_LONG_SIDE = 1920

load_dotenv()

if sys.platform == "win32":
    URI = "http://localhost:5050".rstrip("/")
else:
    URI = "http://0.0.0.0:5050".rstrip("/")
    
REQUEST_TIMEOUT = float(os.getenv("LT_TIMEOUT", "20"))
MAX_WORKERS = int(os.getenv("LT_MAX_WORKERS", "8"))
MAX_SENTENCE_LENGTH = 50

ocrInstance = PaddleOCR()

PRON_POOL = ThreadPoolExecutor(max_workers=os.cpu_count() or 8 * 2)
_inflight = {}
_inflight_lock = threading.Lock()

if sys.platform == "win32":
    ESPEAK_DIR = os.getenv("PHONEMIZER_ESPEAK_DIR", r"C:\Program Files\eSpeak NG")
    ESPEAK_DLL = os.path.join(ESPEAK_DIR, "libespeak-ng.dll")
    os.environ.setdefault("PHONEMIZER_ESPEAK_LIBRARY", ESPEAK_DLL)
else:
    os.environ.setdefault("PHONEMIZER_ESPEAK_LIBRARY", "/usr/lib/x86_64-linux-gnu/libespeak-ng.so.1")

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
    adapter = HTTPAdapter(max_retries=retries, pool_connections=256, pool_maxsize=1024)
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

def _get_pron(cache, key: str, text: str, lang: str) -> Tuple[list[str], list[str]]:
    po: Optional[object] = cache.get(key)

    ipa: Optional[list[str]] = None
    roman: Optional[list[str]] = None

    if isinstance(po, dict):
        v1 = po.get('ipa'); v2 = po.get('roman')
        if isinstance(v1, list) and (not v1 or isinstance(v1[0], str)) \
           and isinstance(v2, list) and (not v2 or isinstance(v2[0], str)):
            ipa, roman = v1, v2

    if ipa is None or roman is None:
        pr = pronounce(text, lang)
        ipa, roman = pr.ipa, pr.roman
        cache.add(key, {'ipa': ipa, 'roman': roman})

    return ipa, roman

def _upd_str(h, s: str) -> None:
    s = " ".join(s.split())
    b = s.encode("utf-8")
    h.update(len(b).to_bytes(4, "big")); h.update(b)

def _upd_list(h, seq: Optional[List[str]]) -> None:
    if not seq:
        h.update((0).to_bytes(4, "big"))
        return
    h.update(len(seq).to_bytes(4, "big")) 
    for item in seq:
        _upd_str(h, item)

def cache_key(
    text: str, source: str, target: str,
    originalIpa: Optional[List[str]] = None,
    translatedIpa: Optional[List[str]] = None,
    originalRomanization: Optional[List[str]] = None,
    translatedRomanization: Optional[List[str]] = None,
) -> str:
    h = hashlib.blake2b(digest_size=16)
    _upd_str(h, source); _upd_str(h, target); _upd_str(h, text)
    _upd_list(h, originalIpa); _upd_list(h, translatedIpa)
    _upd_list(h, originalRomanization); _upd_list(h, translatedRomanization)
    return "th:" + h.hexdigest()

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

def retornar(payload: dict, status_code: int = 200) -> Response:
    return Response(orjson.dumps(payload), status=status_code, mimetype="application/json")

@app.route("/", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def index() -> Response:
    data = orjson.loads(request.data or b"{}")
    originalLanguage = (data.get("originalLanguage") or EN).strip().lower()
    target = (data.get("target") or "es").strip().lower()
    tipo = (data.get("tipo") or "").strip().lower()
    
    originalLanguage = originalLanguage if originalLanguage != 'auto' else EN

    if tipo == "frase":
        sentence = generate_sentence_beginner()
    else:
        sentence = conseguirPalabraRandom(tipo)

    key = cache_key(sentence, originalLanguage, target)
    _cached = cache.get(key)
    if isinstance(_cached, dict) and all(k in _cached for k in (
    "originalIpa","translatedIpa","originalRomanization","translatedRomanization"
    )):
        return retornar(_cached, 200)
    
    display_src = sentence
    if originalLanguage in ('ja', 'jpx'):
        display_src = space_japanese_for_flutter(display_src)
    elif originalLanguage.startswith('zh'):
        display_src = space_chinese_for_flutter(display_src)

    rev_key = "rev:" + cache_key(display_src, originalLanguage, target)
    _rev = cache.get(rev_key)
    
    cache_set = getattr(cache, "set", cache.add)

    if isinstance(_rev, dict):
        ptr = _rev.get("payload_key")
        back = cache.get(ptr) if isinstance(ptr, str) else None
        translated_text = _rev.get("orig_text") or ""

        if isinstance(back, dict) and all(k in back for k in (
            "originalIpa","translatedIpa","originalRomanization","translatedRomanization"
        )):
            payload = build_payload(
                display_src, translated_text, originalLanguage, target,
                back["translatedIpa"], back["originalIpa"],
                back["translatedRomanization"], back["originalRomanization"]
            )
        else:
            k_o = cache_key(display_src,      originalLanguage, f"pron:{originalLanguage}")
            k_t = cache_key(translated_text,  target,           f"pron:{target}")
            oIpa, oRom = _get_pron(cache, k_o, display_src,     originalLanguage)
            tIpa, tRom = _get_pron(cache, k_t, translated_text, target)
            payload = build_payload(display_src, translated_text, originalLanguage, target,
                                    oIpa, tIpa, oRom, tRom)

        cache_set(key, payload)
        return retornar(payload, 200)

    try:
        if (originalLanguage == EN or originalLanguage == "auto") and target == EN: # Inglés a inglés
            k = cache_key(sentence, EN, f"pron:{EN}")
            ipa, roman = _get_pron(cache, k, sentence, EN)
            payload = build_payload(sentence, sentence, EN, EN, ipa, ipa, roman, roman)
            cache_set(key, payload)
            return retornar(payload, 200)

        if originalLanguage == target and originalLanguage != EN:
            ltk_same = "lt:" + cache_key(sentence, EN, target)
            with _inflight_lock:
                fut_same = _inflight.get(ltk_same)
                if fut_same is None:
                    fut_same = PRON_POOL.submit(lt_translate, sentence, EN, target)
                    _inflight[ltk_same] = fut_same
            try:
                resp_same = fut_same.result()
            finally:
                with _inflight_lock:
                    if _inflight.get(ltk_same) is fut_same:
                        del _inflight[ltk_same]

            translated_text = resp_same.get("translatedText", "") or ""

            display = translated_text
            if target in ('ja','jpx'):
                display = space_japanese_for_flutter(display)
            elif target.startswith('zh'):
                display = space_chinese_for_flutter(display)

            k = cache_key(display, target, f"pron:{target}")
            ipa, roman = _get_pron(cache, k, display, target)

            payload = build_payload(display, display, target, target, ipa, ipa, roman, roman)
            cache_set(key, payload)

            rev_key = "rev:" + cache_key(display, originalLanguage, target)
            cache_set(rev_key, {"payload_key": key, "orig_text": display})

            return retornar(payload, 200)

        original_text = sentence
        translated_text = sentence

        fut_orig: Optional[Future] = None
        fut_tgt: Optional[Future] = None
        ltk_orig: Optional[str] = None
        ltk_tgt:  Optional[str] = None
        
        if originalLanguage not in (EN, "auto"):
            ltk_orig = "lt:" + cache_key(sentence, EN, originalLanguage)
            with _inflight_lock:
                fut_orig = _inflight.get(ltk_orig)
                if fut_orig is None:
                    fut_orig = PRON_POOL.submit(lt_translate, sentence, EN, originalLanguage)
                    _inflight[ltk_orig] = fut_orig
            
        if target != EN:
            ltk_tgt = "lt:" + cache_key(sentence, EN, target)
            with _inflight_lock:
                fut_tgt = _inflight.get(ltk_tgt)
                if fut_tgt is None:
                    fut_tgt = PRON_POOL.submit(lt_translate, sentence, EN, target)
                    _inflight[ltk_tgt] = fut_tgt

        if fut_orig is not None:
            try:
                resp_orig = fut_orig.result()
                original_text = resp_orig.get("translatedText", "")
            finally:
                if ltk_orig is not None:
                    with _inflight_lock:
                        if _inflight.get(ltk_orig) is fut_orig:
                            del _inflight[ltk_orig]

        if fut_tgt is not None:
            try:
                resp_tgt = fut_tgt.result()
                translated_text = resp_tgt.get("translatedText", "")
            finally:
                if ltk_tgt is not None:
                    with _inflight_lock:
                        if _inflight.get(ltk_tgt) is fut_tgt:
                            del _inflight[ltk_tgt]
                    
        display_original = original_text or ''
        display_translated = translated_text or ''
        if originalLanguage in ('ja','jpx'):
            display_original = space_japanese_for_flutter(display_original)
        elif originalLanguage.startswith('zh'):
            display_original = space_chinese_for_flutter(display_original)
        if target in ('ja','jpx'):
            display_translated = space_japanese_for_flutter(display_translated)
        elif target.startswith('zh'):
            display_translated = space_chinese_for_flutter(display_translated)
   
        k_o = cache_key(display_original,     originalLanguage, f"pron:{originalLanguage}")
        k_t = cache_key(display_translated, target,           f"pron:{target}")
        pko = "pron:" + k_o
        pkt = "pron:" + k_t
        with _inflight_lock:
            f1 = _inflight.get(pko)
            if f1 is None:
                f1 = PRON_POOL.submit(_get_pron, cache, k_o, display_original,     originalLanguage)
                _inflight[pko] = f1
            f2 = _inflight.get(pkt)
            if f2 is None:
                f2 = PRON_POOL.submit(_get_pron, cache, k_t, translated_text, target)
                _inflight[pkt] = f2
        try:
            originalIpa, originalRomanization = f1.result()
            translatedIpa, translatedRomanization = f2.result()
        finally:
            with _inflight_lock:
                if _inflight.get(pko) is f1: del _inflight[pko]
                if _inflight.get(pkt) is f2: del _inflight[pkt]

        payload = build_payload(
            display_original, display_translated, originalLanguage, target, originalIpa, translatedIpa, originalRomanization, translatedRomanization
        )
        cache_set(key, payload)
        rev_key = "rev:" + cache_key(display_translated, originalLanguage, target)
        cache_set(rev_key, {"payload_key": key, "orig_text": display_original})
        return retornar(payload, 200)

    except Exception as e:
        resp = getattr(e, "response", None)
        status = getattr(resp, "status_code", None)
        body = (getattr(resp, "text", "") or "")
        body = body[:200].replace("\n", " ")
        msg = f"{e.__class__.__name__}: {e}"
        if status is not None:
            msg += f" | upstream={status} | body={body}"

        return retornar(
            build_payload(sentence, None, originalLanguage, target, None, None, msg),
            502
        )
    
@app.route("/translate", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def translate() -> Response:
    data = orjson.loads(request.data or b"{}")
    get = data.get
    sentence = (get("q") or "").strip()
    source   = (get("source") or "auto").strip().lower()
    target   = (get("target") or "es").strip().lower()

    if not sentence:
        return retornar(build_payload("", "", source, target), 200)

    sentence = sentence[:MAX_SENTENCE_LENGTH]
    if "  " in sentence or "\n" in sentence or "\t" in sentence:
        sentence = " ".join(sentence.split())

    if source == "auto":
        s = sentence
        if any("\u3040" <= ch <= "\u30ff" for ch in s):   # JA kana
            source = "ja"
        elif any("\u3400" <= ch <= "\u9fff" for ch in s): # CJK
            source = "zh"
        else:
            source = detect(sentence)

    key = cache_key(sentence, source, target)
    _cached = cache.get(key)
    if isinstance(_cached, dict) and all(k in _cached for k in (
        "originalIpa","translatedIpa","originalRomanization","translatedRomanization"
    )):
        return retornar(_cached, 200)

    cache_set = getattr(cache, "set", cache.add)

    display_src = sentence
    if source in ('ja', 'jpx'):
        display_src = space_japanese_for_flutter(display_src)
    elif source.startswith('zh'):
        display_src = space_chinese_for_flutter(display_src)

    rev_key = "rev:" + cache_key(display_src, source, target)
    _rev = cache.get(rev_key)
    if isinstance(_rev, dict):
        ptr = _rev.get("payload_key")
        back = cache.get(ptr) if isinstance(ptr, str) else None
        translated_text = _rev.get("orig_text") or ""
        if isinstance(back, dict) and all(k in back for k in (
            "originalIpa","translatedIpa","originalRomanization","translatedRomanization"
        )):
            payload = build_payload(
                display_src, translated_text, source, target,
                back["translatedIpa"], back["originalIpa"],
                back["translatedRomanization"], back["originalRomanization"]
            )
        else:
            k_o = cache_key(display_src,     source, f"pron:{source}")
            k_t = cache_key(translated_text, target, f"pron:{target}")
            pko = "pron:" + k_o
            pkt = "pron:" + k_t
            with _inflight_lock:
                f1 = _inflight.get(pko)
                if f1 is None:
                    f1 = PRON_POOL.submit(_get_pron, cache, k_o, display_src,     source)
                    _inflight[pko] = f1
                f2 = _inflight.get(pkt)
                if f2 is None:
                    f2 = PRON_POOL.submit(_get_pron, cache, k_t, translated_text, target)
                    _inflight[pkt] = f2
            try:
                (oIpa, oRom) = f1.result()
                (tIpa, tRom) = f2.result()
            finally:
                with _inflight_lock:
                    if _inflight.get(pko) is f1: del _inflight[pko]
                    if _inflight.get(pkt) is f2: del _inflight[pkt]
            payload = build_payload(display_src, translated_text, source, target, oIpa, tIpa, oRom, tRom)

        cache_set(key, payload)
        return retornar(payload, 200)

    if source == target:
        k_pron = cache_key(display_src, target, f"pron:{target}")
        ipa, roman = _get_pron(cache, k_pron, display_src, target)
        payload = build_payload(display_src, display_src, target, target, ipa, ipa, roman, roman)
        cache_set(key, payload)
        return retornar(payload, 200)

    ltk: Optional[str] = "lt:" + cache_key(sentence, source, target)
    with _inflight_lock:
        fut: Optional[Future] = _inflight.get(ltk)
        if fut is None:
            fut = PRON_POOL.submit(lt_translate, sentence, source, target)
            _inflight[ltk] = fut
    try:
        data_lt = fut.result()
    finally:
        with _inflight_lock:
            if _inflight.get(ltk) is fut:
                del _inflight[ltk]

    translated = (data_lt.get("translatedText") or "")

    display_original  = display_src
    display_translated = translated
    if target in ('ja','jpx'):
        display_translated = space_japanese_for_flutter(display_translated)
    elif target.startswith('zh'):
        display_translated = space_chinese_for_flutter(display_translated)

    k_o = cache_key(display_original,  source, f"pron:{source}")
    k_t = cache_key(display_translated, target, f"pron:{target}")
    pko = "pron:" + k_o
    pkt = "pron:" + k_t
    with _inflight_lock:
        f1 = _inflight.get(pko)
        if f1 is None:
            f1 = PRON_POOL.submit(_get_pron, cache, k_o, display_original,  source)
            _inflight[pko] = f1
        f2 = _inflight.get(pkt)
        if f2 is None:
            f2 = PRON_POOL.submit(_get_pron, cache, k_t, display_translated, target)
            _inflight[pkt] = f2
    try:
        (originalIpa,  originalRomanization)    = f1.result()
        (translatedIpa, translatedRomanization) = f2.result()
    finally:
        with _inflight_lock:
            if _inflight.get(pko) is f1: del _inflight[pko]
            if _inflight.get(pkt) is f2: del _inflight[pkt]

    resultado = build_payload(
        display_original, display_translated, source, target,
        originalIpa, translatedIpa, originalRomanization, translatedRomanization
    )
    cache_set(key, resultado)

    rev_key = "rev:" + cache_key(display_translated, source, target)
    cache_set(rev_key, {"payload_key": key, "orig_text": display_original})

    return retornar(resultado, 200)


@app.route("/ocr", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def ocr() -> Response:
    data = orjson.loads(request.data or b"{}")
    get = data.get
    target = (get("target") or "en").strip().lower()

    img = read_image_from_request()
    if img is None:
        return retornar(build_payload(error="No image"), 422)

    try:
        result = ocrInstance.predict(input=img)
        texts = (result and result[0].get("rec_texts")) or []
    except Exception as e:
        return retornar(build_payload(error=f"OCR Error: {e}"), 500)

    ocrString = " ".join(t for t in texts if t).strip()
    if not ocrString:
        return retornar(build_payload("", "", "auto", target), 200)

    ocrString = ocrString[:MAX_SENTENCE_LENGTH]
    if "  " in ocrString or "\n" in ocrString or "\t" in ocrString:
        ocrString = " ".join(ocrString.split())

    s = ocrString
    if any("\u3040" <= ch <= "\u30ff" for ch in s):
        lang = "ja"
    elif any("\u3400" <= ch <= "\u9fff" for ch in s):
        lang = "zh"
    else:
        lang = detect(s)

    key = cache_key(ocrString, lang, target)
    _cached = cache.get(key)
    if isinstance(_cached, dict) and all(k in _cached for k in (
        "originalIpa","translatedIpa","originalRomanization","translatedRomanization"
    )):
        return retornar(_cached, 200)

    cache_set = getattr(cache, "set", cache.add)

    if lang == target:
        display = s
        if lang in ("ja", "jpx"):
            display = space_japanese_for_flutter(display)
        elif lang.startswith("zh"):
            display = space_chinese_for_flutter(display)

        k_pron = cache_key(display, lang, f"pron:{lang}")
        pkey = "pron:" + k_pron
        with _inflight_lock:
            f = _inflight.get(pkey)
            if f is None:
                f = PRON_POOL.submit(_get_pron, cache, k_pron, display, lang)
                _inflight[pkey] = f
        try:
            ipa, rom = f.result()
        finally:
            with _inflight_lock:
                if _inflight.get(pkey) is f:
                    del _inflight[pkey]

        payload = build_payload(display, display, lang, target, ipa, ipa, rom, rom)
        cache_set(key, payload)
        return retornar(payload, 200)

    ltk = "lt:" + cache_key(ocrString, lang, target)
    with _inflight_lock:
        fut = _inflight.get(ltk)
        if fut is None:
            fut = PRON_POOL.submit(lt_translate, ocrString, lang, target)
            _inflight[ltk] = fut
    try:
        data_lt = fut.result()
    finally:
        with _inflight_lock:
            if _inflight.get(ltk) is fut:
                del _inflight[ltk]

    translated = (data_lt.get("translatedText") or "")

    display_original = s
    if lang in ("ja","jpx"):
        display_original = space_japanese_for_flutter(display_original)
    elif lang.startswith("zh"):
        display_original = space_chinese_for_flutter(display_original)

    display_translated = translated
    if target in ("ja","jpx"):
        display_translated = space_japanese_for_flutter(display_translated)
    elif target.startswith("zh"):
        display_translated = space_chinese_for_flutter(display_translated)

    k_o = cache_key(display_original,  lang,    f"pron:{lang}")
    k_t = cache_key(display_translated, target, f"pron:{target}")
    pko = "pron:" + k_o
    pkt = "pron:" + k_t
    with _inflight_lock:
        f1 = _inflight.get(pko)
        if f1 is None:
            f1 = PRON_POOL.submit(_get_pron, cache, k_o, display_original,  lang)
            _inflight[pko] = f1
        f2 = _inflight.get(pkt)
        if f2 is None:
            f2 = PRON_POOL.submit(_get_pron, cache, k_t, display_translated, target)
            _inflight[pkt] = f2
    try:
        (originalIpa,  originalRomanization)    = f1.result()
        (translatedIpa, translatedRomanization) = f2.result()
    finally:
        with _inflight_lock:
            if _inflight.get(pko) is f1: del _inflight[pko]
            if _inflight.get(pkt) is f2: del _inflight[pkt]

    resultado = build_payload(
        display_original, display_translated, lang, target,
        originalIpa, translatedIpa, originalRomanization, translatedRomanization
    )
    cache_set(key, resultado)
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

@app.route("/retranslate", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def retranslate() -> Response:
    data = orjson.loads(request.data or b"{}")
    get = data.get
    sentence   = (get("sentence")   or "").strip()
    sourceLang = (get("sourceLang") or "").strip().lower()
    targetLang = (get("targetLang") or "").strip().lower()

    if not sentence or not sourceLang or not targetLang:
        return retornar(build_payload(error="No data"), 422)

    sentence = sentence[:MAX_SENTENCE_LENGTH]
    if "  " in sentence or "\n" in sentence or "\t" in sentence:
        sentence = " ".join(sentence.split())

    key_payload = cache_key(sentence, sourceLang, targetLang)
    cache_del = getattr(cache, "delete", None)
    cache_set = getattr(cache, "set", cache.add)

    prev = cache.get(key_payload)

    if cache_del:
        cache_del(key_payload)

    if isinstance(prev, dict):
        prev_trans = (
            prev.get("translatedText") or prev.get("translated_text")
            or prev.get("translated") or prev.get("display_translated") or ""
        )
        if prev_trans:
            old_disp_trans = prev_trans
            if targetLang in ("ja","jpx"):
                old_disp_trans = space_japanese_for_flutter(old_disp_trans)
            elif targetLang.startswith("zh"):
                old_disp_trans = space_chinese_for_flutter(old_disp_trans)
            old_rev_key = "rev:" + cache_key(old_disp_trans, sourceLang, targetLang)
            if cache_del:
                cache_del(old_rev_key)

    probe = sentence + "…"
    ltk = "relt:" + cache_key(probe, sourceLang, targetLang)
    with _inflight_lock:
        fut = _inflight.get(ltk)
        if fut is None:
            fut = PRON_POOL.submit(lt_translate, probe, sourceLang, targetLang)
            _inflight[ltk] = fut
    try:
        data_lt = fut.result()
    finally:
        with _inflight_lock:
            if _inflight.get(ltk) is fut:
                del _inflight[ltk]

    translatedText = (data_lt.get("translatedText") or "")
    if translatedText.endswith("…"):
        translatedText = translatedText[:-1].rstrip()
    elif translatedText.endswith("..."):
        translatedText = translatedText[:-3].rstrip()

    display_original = sentence
    if sourceLang in ("ja","jpx"):
        display_original = space_japanese_for_flutter(display_original)
    elif sourceLang.startswith("zh"):
        display_original = space_chinese_for_flutter(display_original)

    display_translated = translatedText
    if targetLang in ("ja","jpx"):
        display_translated = space_japanese_for_flutter(display_translated)
    elif targetLang.startswith("zh"):
        display_translated = space_chinese_for_flutter(display_translated)

    k_o = cache_key(display_original,  sourceLang, f"pron:{sourceLang}")
    k_t = cache_key(display_translated, targetLang, f"pron:{targetLang}")
    pko = "pron:" + k_o
    pkt = "pron:" + k_t
    with _inflight_lock:
        f1 = _inflight.get(pko)
        if f1 is None:
            f1 = PRON_POOL.submit(_get_pron, cache, k_o, display_original,  sourceLang)
            _inflight[pko] = f1
        f2 = _inflight.get(pkt)
        if f2 is None:
            f2 = PRON_POOL.submit(_get_pron, cache, k_t, display_translated, targetLang)
            _inflight[pkt] = f2
    try:
        (originalIpa,  originalRomanization)    = f1.result()
        (translatedIpa, translatedRomanization) = f2.result()
    finally:
        with _inflight_lock:
            if _inflight.get(pko) is f1: del _inflight[pko]
            if _inflight.get(pkt) is f2: del _inflight[pkt]

    resultado = build_payload(
        display_original, display_translated, sourceLang, targetLang,
        originalIpa, translatedIpa, originalRomanization, translatedRomanization
    )

    cache_set(key_payload, resultado)
    rev_key = "rev:" + cache_key(display_translated, sourceLang, targetLang)
    cache_set(rev_key, {"payload_key": key_payload, "orig_text": display_original})

    return retornar(resultado, 200)
        
if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True, use_reloader=False, port=3000, threaded=True)
