from flask import Flask, jsonify, request
from flask_cors import cross_origin
from beginnergen import generate_sentence_beginner
from dotenv import load_dotenv
from functools import lru_cache
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from typing import Any, Tuple
import requests
import os

EN = "en"

load_dotenv()
URI = os.getenv("LIBRETRANSLATE_URI", "").rstrip("/")
REQUEST_TIMEOUT = float(os.getenv("LT_TIMEOUT", "20"))
MAX_WORKERS = int(os.getenv("LT_MAX_WORKERS", "8"))

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
    with ThreadPoolExecutor(max_workers=min(MAX_WORKERS, len(unique_targets))) as ex:
        futs = {ex.submit(translate_cached, text, source, t): t for t in unique_targets}
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

@app.route("/", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def index():
    data = request.get_json(force=True) or {}
    originalLanguage = (data.get("originalLanguage") or EN).strip().lower()
    target = (data.get("target") or "es").strip().lower()

    try:
        sentence = generate_sentence_beginner()
    except Exception as e:
        return jsonify({
            "originalText": None,
            "translatedText": None,
            "detectedLanguage": None,
            "target": target,
            "error": f"Error generando frase: {str(e)}"
        }), 500
    
    detected_for_ui = originalLanguage if originalLanguage != "auto" else EN

    try:
        if originalLanguage == EN and target == EN:
            return jsonify({
                "originalText": sentence,
                "translatedText": sentence,
                "detectedLanguage": detected_for_ui,
                "target": target
            }), 200
    
        if originalLanguage == target != EN:
            data_lang = lt_translate(sentence, EN, target)
            text_lang = data_lang.get("translatedText", "")
            if originalLanguage == "auto":
                dl = data_lang.get("detectedLanguage")
                if isinstance(dl, dict) and dl.get("language"):
                    detected_for_ui = dl["language"]
                elif isinstance(dl, str) and dl:
                    detected_for_ui = dl
            return jsonify({
                "originalText": text_lang,
                "translatedText": text_lang,
                "detectedLanguage": detected_for_ui,
                "target": target
            }), 200
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

        return jsonify({
            "originalText": original_text,
            "translatedText": translated_text,
            "detectedLanguage": detected_for_ui,
            "target": target
        }), 200
    
    except Exception as e:
        return jsonify({
            "originalText": sentence,
            "translatedText": None,
            "detectedLanguage": detected_for_ui,
            "target": target,
            "error": str(e),
        }), 502
    
@app.route("/translate", methods=["POST"])
@cross_origin(origins="*", methods=["POST"])
def translate():
    data = request.get_json(force=True)
    sentence = data.get("q", "")
    source = data.get("source", "auto")
    target = data.get("target", "es")
    payload = {"q": sentence, "source": source, "target": target, "format": "text"}
    r = session.post(f"{URI}/translate", json=payload, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    data = r.json()
    translated = data.get("translatedText")
    detected = data.get("detectedLanguage", {}).get("language")
    if not detected:
        detected = source

    return jsonify({
        "originalText": sentence,
        "translatedText": translated,
        "detectedLanguage": detected
    })


if __name__ == "__main__":
    app.run(debug=True, port=3000, threaded=True)
