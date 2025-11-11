# precache_sentences.py
# Uso:
#   PROG_STEP=500 python precache_sentences.py -i sentences.txt -t es,ko,ja,zh -s en
try:
    import orjson as _json
    dumps = lambda o: _json.dumps(o).decode()
except Exception:
    import json as _json
    dumps = lambda o: _json.dumps(o, ensure_ascii=False, separators=(",",":"))

import argparse, pathlib, os, time, sys, signal, threading
from app import (
    cache, cache_key, build_payload, lt_translate, _get_pron,
    space_chinese_for_flutter, space_japanese_for_flutter,
    PRON_POOL, MAX_SENTENCE_LENGTH
)

STOP = threading.Event()
def _on_sigint(signum, frame):
    STOP.set()
    print("\n[INTERRUPT] cancelando…", file=sys.stderr, flush=True)
    raise KeyboardInterrupt
signal.signal(signal.SIGINT, _on_sigint)

cache_set = getattr(cache, "set", cache.add)

def _normalize(s: str) -> str:
    s = s[:MAX_SENTENCE_LENGTH]
    return " ".join(s.split()) if ("  " in s or "\n" in s or "\t" in s) else s

def _space_by_lang(s: str, lang: str) -> str:
    if not s: return s
    if lang in ('ja','jpx'): return space_japanese_for_flutter(s)
    if lang.startswith('zh'): return space_chinese_for_flutter(s)
    return s

def _iter_sentences(path: pathlib.Path):
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if s: yield s

def _humanize_bytes(n: int) -> str:
    size = float(n)
    for unit in ("B","KB","MB","GB","TB","PB"):
        if size < 1024.0: return f"{size:,.2f} {unit}"
        size /= 1024.0
    return f"{size:,.2f} EB"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-i","--input", required=True)
    ap.add_argument("-t","--targets", required=True)
    ap.add_argument("-s","--source", default="en")
    args = ap.parse_args()

    in_path = pathlib.Path(args.input)
    targets = tuple(t.strip().lower() for t in args.targets.split(",") if t.strip())
    src     = args.source.strip().lower()

    PROG_STEP = int(os.getenv("PROG_STEP", "100"))  # imprime cada N procesados

    hit_count = 0
    done_count = 0
    t0 = time.time()

    # Procesar 1×1 (solo singles)
    for s in _iter_sentences(in_path):
        if STOP.is_set(): break
        ns = _normalize(s)
        o_disp = _space_by_lang(ns, src)

        # IPA del ORIGINAL una sola vez por frase (caché local)
        o_pron = None
        def _get_o_pron():
            nonlocal o_pron
            if o_pron is None:
                k_o = cache_key(o_disp, src, f"pron:{src}")
                o_pron = _get_pron(cache, k_o, o_disp, src)
            return o_pron

        # Guardamos traducciones de ESTA frase por destino para pivotar luego
        translations = {}  # tgt -> texto traducido (espaciado)

        for tgt in targets:
            if STOP.is_set(): break
            k = cache_key(ns, src, tgt)
            hit = cache.get(k)

            # --------- HIT (aunque incompleto): NO golpear motor ---------
            if isinstance(hit, dict) and ("translatedText" in hit):
                t_cached = hit.get("translatedText") or ""
                if not t_cached:
                    rev = cache.get("rev:" + cache_key(o_disp, src, tgt))
                    if isinstance(rev, dict):
                        t_cached = rev.get("orig_text") or ""

                t_disp = _space_by_lang(t_cached, tgt)
                if t_disp:
                    translations[tgt] = t_disp

                need_enrich = not all(x in hit for x in (
                    "originalIpa","translatedIpa","originalRomanization","translatedRomanization"
                ))
                if need_enrich and t_disp:
                    back = None
                    rev = cache.get("rev:" + cache_key(o_disp, src, tgt))
                    if isinstance(rev, dict) and isinstance(rev.get("payload_key"), str):
                        back = cache.get(rev["payload_key"])

                    if isinstance(back, dict) and all(kx in back for kx in (
                        "originalIpa","translatedIpa","originalRomanization","translatedRomanization"
                    )):
                        # swap IPA desde reverse
                        oIpa, oRom = back["translatedIpa"], back["translatedRomanization"]
                        tIpa, tRom = back["originalIpa"],   back["originalRomanization"]
                    else:
                        oIpa, oRom = _get_o_pron()
                        k_t = cache_key(t_disp, tgt, f"pron:{tgt}")
                        tIpa, tRom = _get_pron(cache, k_t, t_disp, tgt)

                    payload = build_payload(o_disp, t_disp, src, tgt, oIpa, tIpa, oRom, tRom)
                    cache_set(k, payload)
                    k_rev = cache_key(t_disp, tgt, src)
                    payload_rev = build_payload(t_disp, o_disp, tgt, src, tIpa, oIpa, tRom, oRom)
                    cache_set(k_rev, payload_rev)
                    cache_set("rev:"+cache_key(o_disp, src, tgt), {"payload_key": k_rev, "orig_text": t_disp})

                hit_count += 1
                continue

            # --------- MISS: traducir 1x1 y cachear (forward + reverse + rev:) ---------
            d = lt_translate(ns, src, tgt)
            t_raw = (d.get("translatedText") or "")
            t_disp = _space_by_lang(t_raw, tgt)
            translations[tgt] = t_disp

            oIpa, oRom = _get_o_pron()
            k_t = cache_key(t_disp, tgt, f"pron:{tgt}")
            tIpa, tRom = _get_pron(cache, k_t, t_disp, tgt)

            payload = build_payload(o_disp, t_disp, src, tgt, oIpa, tIpa, oRom, tRom)
            cache_set(k, payload)
            k_rev = cache_key(t_disp, tgt, src)
            payload_rev = build_payload(t_disp, o_disp, tgt, src, tIpa, oIpa, tRom, oRom)
            cache_set(k_rev, payload_rev)
            cache_set("rev:"+cache_key(o_disp, src, tgt), {"payload_key": k_rev, "orig_text": t_disp})

            done_count += 1
            if (done_count % PROG_STEP) == 0:
                rate = done_count / max(1e-6, (time.time()-t0))
                print(
                    f"[PROG] {done_count}  {rate:6.2f} ops/s",
                    file=sys.stderr, flush=True
                )

        if STOP.is_set(): break

        # --------- FASE 2: traducir ENTRE destinos usando pivotes existentes ---------
        langs = [lg for lg in targets if lg in translations]
        # caché local de IPA por texto/idioma durante esta frase
        pron_cache = {}
        def _pron(text, lang):
            key = (text, lang)
            if key in pron_cache: return pron_cache[key]
            kpron = cache_key(text, lang, f"pron:{lang}")
            pron_cache[key] = _get_pron(cache, kpron, text, lang)
            return pron_cache[key]

        for i, li in enumerate(langs):
            if STOP.is_set(): break
            oi_disp = translations[li]
            for lj in langs:
                if STOP.is_set(): break
                if lj == li: continue

                kx = cache_key(oi_disp, li, lj)
                hit = cache.get(kx)
                if isinstance(hit, dict) and ("translatedText" in hit):
                    # enrich si falta IPA
                    need_enrich = not all(x in hit for x in (
                        "originalIpa","translatedIpa","originalRomanization","translatedRomanization"
                    ))
                    if need_enrich:
                        tj = hit.get("translatedText") or ""
                        tj_disp = _space_by_lang(tj, lj)
                        if tj_disp:
                            oIpa, oRom = _pron(oi_disp, li)
                            tIpa, tRom = _pron(tj_disp, lj)
                            payload = build_payload(oi_disp, tj_disp, li, lj, oIpa, tIpa, oRom, tRom)
                            cache_set(kx, payload)
                            k_revx = cache_key(tj_disp, lj, li)
                            payload_rev = build_payload(tj_disp, oi_disp, lj, li, tIpa, oIpa, tRom, oRom)
                            cache_set(k_revx, payload_rev)
                            cache_set("rev:"+cache_key(oi_disp, li, lj), {"payload_key": k_revx, "orig_text": tj_disp})
                    hit_count += 1
                    continue

                dx = lt_translate(oi_disp, li, lj)
                tj_disp = _space_by_lang((dx.get("translatedText") or ""), lj)

                oIpa, oRom = _pron(oi_disp, li)
                tIpa, tRom = _pron(tj_disp, lj)

                payload = build_payload(oi_disp, tj_disp, li, lj, oIpa, tIpa, oRom, tRom)
                cache_set(kx, payload)
                k_revx = cache_key(tj_disp, lj, li)
                payload_rev = build_payload(tj_disp, oi_disp, lj, li, tIpa, oIpa, tRom, oRom)
                cache_set(k_revx, payload_rev)
                cache_set("rev:"+cache_key(oi_disp, li, lj), {"payload_key": k_revx, "orig_text": tj_disp})

                done_count += 1
                if (done_count % PROG_STEP) == 0:
                    rate = done_count / max(1e-6, (time.time()-t0))
                    print(f"[PROG XLANG] {done_count}  {rate:6.2f} ops/s", file=sys.stderr, flush=True)

    print(f"Precache terminado. hits={hit_count} done={done_count}")
    cache_dir = pathlib.Path(".cache")
    total_bytes = 0
    if cache_dir.exists():
        for dp,_,fs in os.walk(cache_dir, followlinks=False):
            for fn in fs:
                try:
                    total_bytes += os.stat(os.path.join(dp, fn), follow_symlinks=False).st_size
                except:
                    pass
    print(f".cache size: {total_bytes} bytes ({_humanize_bytes(total_bytes)})")

if __name__ == "__main__":
    main()
