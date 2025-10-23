from __future__ import annotations
import argparse, random, time, sys, os
from typing import Iterable, List, Tuple, Any, Dict
import requests
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED

def make_session() -> requests.Session:
    s = requests.Session()
    retries = Retry(
        total=3, connect=3, read=3,
        backoff_factor=0.4,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=frozenset(["POST", "GET"]),
    )
    adapter = HTTPAdapter(max_retries=retries, pool_connections=50, pool_maxsize=200)
    s.mount("http://", adapter)
    s.mount("https://", adapter)
    s.headers.update({
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "trilingo-precache/1.0",
    })
    return s

def load_words_from_file(path: str, limit: int | None) -> List[str]:
    seen = set()
    out: List[str] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            w = line.strip()
            if not w:
                continue
            w = " ".join(w.split())
            if w in seen:
                continue
            seen.add(w)
            out.append(w)
            if limit and len(out) >= limit:
                break
    return out

def _dig(d: Dict[str, Any], *path: str) -> Any:
    cur: Any = d
    for k in path:
        if not isinstance(cur, dict) or k not in cur:
            return None
        cur = cur[k]
    return cur

def parse_translated_text(data: Dict[str, Any]) -> str:
    for k in ("translatedText", "translation", "text"):
        v = data.get(k)
        if isinstance(v, str):
            return v
    for path in (("data", "translatedText"), ("data", "text"), ("result", "translatedText")):
        v = _dig(data, *path)
        if isinstance(v, str):
            return v
    lst = data.get("translations") or data.get("data")
    if isinstance(lst, list) and lst:
        first = lst[0]
        if isinstance(first, dict):
            for k in ("text", "translatedText"):
                if isinstance(first.get(k), str):
                    return first[k]
        if isinstance(first, str):
            return first
    return ""

def job_translate(session: requests.Session, backend: str, word: str,
                  source: str, target: str, timeout_s: float) -> Tuple[str, str, str, bool, str, str]:
    # devuelve (word, source, target, success, error, translated)
    import json
    url = f"{backend.rstrip('/')}/translate"
    payload = {"q": word, "source": source, "target": target}
    try:
        r = session.post(url, json=payload, timeout=(3.0, timeout_s))
        r.raise_for_status()
        data = r.json()
        translated = parse_translated_text(data)
        if not isinstance(translated, str):
            translated = str(translated)
        translated = " ".join(translated.split())
        if not translated:
            return (word, source, target, False, "EmptyTranslation", "")
        return (word, source, target, True, "", translated)
    except Exception as e:
        return (word, source, target, False, f"{type(e).__name__}: {e}", "")

def iter_pairs(words: Iterable[str], targets: List[str]) -> Iterable[Tuple[str, str]]:
    for w in words:
        for t in targets:
            yield (w, t)

def main():
    ap = argparse.ArgumentParser(description="Precacher de traducciones para Trilingo (golpea /translate).")
    ap.add_argument("--backend", default="http://localhost:3000", help="URL del backend Flask (p. ej. http://localhost:3000)")
    ap.add_argument("--source", default="en", help="Idioma de origen (ej: en, es, auto)")
    ap.add_argument("--targets", required=True, help="Lista de targets separada por coma (ej: es,ko,zh)")
    ap.add_argument("--file", help="Ruta a archivo con palabras/frases (una por línea)")
    ap.add_argument("--limit", type=int, default=None, help="Máximo a leer del archivo")
    ap.add_argument("--workers", type=int, default=16, help="Hilos concurrentes")
    ap.add_argument("--timeout", type=float, default=20.0, help="Timeout de respuesta del backend (segundos)")
    ap.add_argument("--outdir", default="out_translations", help="Carpeta destino para .txt/.tsv")
    ap.add_argument("--pairs", action="store_true", help="Guardar también pares source→target en TSV")
    args = ap.parse_args()

    targets = [t.strip().lower() for t in args.targets.split(",") if t.strip()]
    if not targets:
        print("ERROR: define --targets, ej: --targets es,ko,zh", file=sys.stderr)
        sys.exit(2)

    words = load_words_from_file(args.file, args.limit)

    os.makedirs(args.outdir, exist_ok=True)

    languages = [args.source] + [t for t in targets if t != args.source]
    print(f"Idiomas: {languages}")

    print(f"Precaching pase 1 (seed): {len(words)} palabra(s) × {len(targets)} target(s) = {len(words)*len(targets)} peticiones")
    session = make_session()

    t0 = time.time()
    ok = 0
    fail = 0
    total_requests = 0

    # Acumuladores por par (src,dst)
    acc_txt: Dict[Tuple[str, str], List[str]] = {}
    acc_tsv: Dict[Tuple[str, str], List[Tuple[str, str]]] = {}

    # Semillas acumuladas por idioma destino (de-duplicadas on the fly)
    words_by_lang: Dict[str, List[str]] = {args.source: list(words)}
    seen_by_lang: Dict[str, set] = {args.source: set(words)}

    max_pending = max(args.workers * 10, args.workers)

    # ---------- PASE 1: source -> targets ----------
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        pending = set()
        total_pairs_1 = len(words) * len(targets)
        i = 0

        for w in words:
            for t in targets:
                fut = ex.submit(job_translate, session, args.backend, w, args.source, t, args.timeout)
                pending.add(fut)
                total_requests += 1

                if len(pending) >= max_pending:
                    done, pending = wait(pending, return_when=FIRST_COMPLETED)
                    for fut2 in done:
                        word, src, dst, success, msg, translated = fut2.result()
                        i += 1
                        if success:
                            ok += 1
                            acc_txt.setdefault((src, dst), []).append(translated)
                            if args.pairs:
                                acc_tsv.setdefault((src, dst), []).append((word, translated))
                            # alimentar semilla del idioma dst
                            if dst not in seen_by_lang:
                                seen_by_lang[dst] = set()
                                words_by_lang[dst] = []
                            if translated and translated not in seen_by_lang[dst]:
                                seen_by_lang[dst].add(translated)
                                words_by_lang[dst].append(translated)
                        else:
                            fail += 1
                        if i % 100 == 0 or not success:
                            status = "OK" if success else f"FAIL ({msg})"
                            prev = f"{translated[:60]}…" if success and len(translated) > 60 else translated
                            print(f"[{i}/{total_pairs_1}] {word!r} {src}→{dst}: {status}" + (f"  '{prev}'" if success else ""))

        # drenar los restantes
        if pending:
            done, _ = wait(pending)
            for fut in done:
                word, src, dst, success, msg, translated = fut.result()
                i += 1
                if success:
                    ok += 1
                    acc_txt.setdefault((src, dst), []).append(translated)
                    if args.pairs:
                        acc_tsv.setdefault((src, dst), []).append((word, translated))
                    if dst not in seen_by_lang:
                        seen_by_lang[dst] = set()
                        words_by_lang[dst] = []
                    if translated and translated not in seen_by_lang[dst]:
                        seen_by_lang[dst].add(translated)
                        words_by_lang[dst].append(translated)
                else:
                    fail += 1
                if i % 100 == 0 or not success:
                    status = "OK" if success else f"FAIL ({msg})"
                    prev = f"{translated[:60]}…" if success and len(translated) > 60 else translated
                    print(f"[{i}/{total_pairs_1}] {word!r} {src}→{dst}: {status}" + (f"  '{prev}'" if success else ""))

    # ---------- PASE 2: cruzado entre TODOS los idiomas ----------
    # Construimos todas las parejas dirigidas distintas, excepto las ya hechas (source->targets ya hechas)
    print("\nPrecaching pase 2 (cruzado entre idiomas)…")
    pairs_done = set(acc_txt.keys())
    all_langs = list(words_by_lang.keys())  # incluye source y los que obtuvimos en pase 1
    # Aseguramos que también estén los targets aunque quedaran vacíos
    for t in targets:
        if t not in words_by_lang:
            words_by_lang[t] = []
            seen_by_lang[t] = set()
            all_langs.append(t)

    cross_jobs = 0
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        pending = set()
        i = 0

        for src in all_langs:
            src_words = words_by_lang.get(src, [])
            if not src_words:
                continue
            # Si el usuario pasó --limit, úsalo también como cap para el cruce por idioma
            if args.limit and len(src_words) > args.limit:
                src_words = src_words[:args.limit]

            for dst in all_langs:
                if dst == src:
                    continue
                if (src, dst) in pairs_done:
                    continue
                # programamos todos los src_words hacia dst
                for w in src_words:
                    fut = ex.submit(job_translate, session, args.backend, w, src, dst, args.timeout)
                    pending.add(fut)
                    total_requests += 1
                    cross_jobs += 1

                    if len(pending) >= max_pending:
                        done, pending = wait(pending, return_when=FIRST_COMPLETED)
                        for fut2 in done:
                            word, s_src, s_dst, success, msg, translated = fut2.result()
                            i += 1
                            if success:
                                ok += 1
                                acc_txt.setdefault((s_src, s_dst), []).append(translated)
                                if args.pairs:
                                    acc_tsv.setdefault((s_src, s_dst), []).append((word, translated))
                                # alimentar semilla del idioma destino (no es estrictamente necesario en pase 2)
                                if s_dst not in seen_by_lang:
                                    seen_by_lang[s_dst] = set()
                                    words_by_lang[s_dst] = []
                                if translated and translated not in seen_by_lang[s_dst]:
                                    seen_by_lang[s_dst].add(translated)
                                    words_by_lang[s_dst].append(translated)
                            else:
                                fail += 1

                            if i % 200 == 0 or not success:
                                status = "OK" if success else f"FAIL ({msg})"
                                prev = f"{translated[:60]}…" if success and len(translated) > 60 else translated
                                print(f"[cruzado {i}] {word!r} {s_src}→{s_dst}: {status}" + (f"  '{prev}'" if success else ""))

        # drenar restantes
        if pending:
            done, _ = wait(pending)
            for fut in done:
                word, s_src, s_dst, success, msg, translated = fut.result()
                i += 1
                if success:
                    ok += 1
                    acc_txt.setdefault((s_src, s_dst), []).append(translated)
                    if args.pairs:
                        acc_tsv.setdefault((s_src, s_dst), []).append((word, translated))
                    if s_dst not in seen_by_lang:
                        seen_by_lang[s_dst] = set()
                        words_by_lang[s_dst] = []
                    if translated and translated not in seen_by_lang[s_dst]:
                        seen_by_lang[s_dst].add(translated)
                        words_by_lang[s_dst].append(translated)
                else:
                    fail += 1
                if i % 200 == 0 or not success:
                    status = "OK" if success else f"FAIL ({msg})"
                    prev = f"{translated[:60]}…" if success and len(translated) > 60 else translated
                    print(f"[cruzado {i}] {word!r} {s_src}→{s_dst}: {status}" + (f"  '{prev}'" if success else ""))

    # ---------- Escritura de archivos por (src,dst) ----------
    # De-dup final por par y volcado a disco
    total_files = 0
    for (src, dst), lines in acc_txt.items():
        seen = set()
        uniq: List[str] = []
        for s in lines:
            if s and s not in seen:
                seen.add(s)
                uniq.append(s)

        txt_path = os.path.join(args.outdir, f"{src}_to_{dst}.txt")
        with open(txt_path, "w", encoding="utf-8", newline="\n") as f:
            for s in uniq:
                f.write(s + "\n")
        total_files += 1
        print(f"↳ guardado {len(uniq)} líneas en: {txt_path}")

        if args.pairs and acc_tsv.get((src, dst)):
            tsv_path = os.path.join(args.outdir, f"{src}_to_{dst}.tsv")
            with open(tsv_path, "w", encoding="utf-8", newline="\n") as f:
                for srcw, dstw in acc_tsv[(src, dst)]:
                    f.write(f"{srcw}\t{dstw}\n")
            print(f"↳ guardado {len(acc_tsv[(src, dst)])} pares en: {tsv_path}")

    dt = time.time() - t0
    total = ok + fail
    print(f"\nHecho en {dt:.1f}s. Archivos={total_files}  OK={ok}  FAIL={fail}  Requests={total_requests}  (total={total})")

if __name__ == "__main__":
    main()
