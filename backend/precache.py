from __future__ import annotations
import argparse, random, time, sys, os
from typing import Iterable, List, Tuple, Any, Dict
import requests
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from concurrent.futures import ThreadPoolExecutor, as_completed

DEFAULT_WORDS = [
    "time","year","people","way","day","man","thing","woman","life","child",
    "world","school","state","family","student","group","country","problem","hand",
    "part","place","case","week","company","system","program","question","work",
    "government","number","night","point","home","water","room","mother","area",
    "money","story","fact","month","lot","right","study","book","eye","job","word",
    "business","issue","side","kind","head","house","service","friend","father",
    "power","hour","game","line","end","member","law","car","city","community",
    "name","president","team","minute","idea","kid","body","information","back",
    "parent","face","others","level","office","door","health","person","art",
    "war","history","party","result","change","morning","reason","research",
    "girl","guy","moment","air","teacher","force","education","foot","boy",
    "age","policy","everything","process","music"
]

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

def make_random_words(n: int, source: str) -> List[str]:
    base = DEFAULT_WORDS
    if n <= len(base):
        return random.sample(base, n)
    words: List[str] = []
    i = 0
    while len(words) < n:
        words.append(f"{base[i % len(base)]}")
        i += 1
    return words[:n]

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
                  source: str, target: str, timeout_s: float) -> Tuple[str, str, bool, str, str]:
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
            return (word, target, False, "EmptyTranslation", "")
        return (word, target, True, "", translated)
    except Exception as e:
        return (word, target, False, f"{type(e).__name__}: {e}", "")

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
    ap.add_argument("--random", type=int, default=0, help="Si no usas --file, cuántas palabras aleatorias generar")
    ap.add_argument("--workers", type=int, default=16, help="Hilos concurrentes")
    ap.add_argument("--timeout", type=float, default=20.0, help="Timeout de respuesta del backend (segundos)")
    ap.add_argument("--shuffle", action="store_true", help="Barajar las palabras antes de enviar")
    ap.add_argument("--outdir", default="out_translations", help="Carpeta destino para .txt/.tsv")
    ap.add_argument("--pairs", action="store_true", help="Guardar también pares source→target en TSV")
    args = ap.parse_args()

    targets = [t.strip().lower() for t in args.targets.split(",") if t.strip()]
    if not targets:
        print("ERROR: define --targets, ej: --targets es,ko,zh", file=sys.stderr)
        sys.exit(2)

    if args.file:
        words = load_words_from_file(args.file, args.limit)
    else:
        if args.random <= 0:
            print("No se especificó --file ni --random > 0. Nada que precachear.", file=sys.stderr)
            sys.exit(0)
        words = make_random_words(args.random, args.source)

    if args.shuffle:
        random.shuffle(words)

    os.makedirs(args.outdir, exist_ok=True)

    print(f"Precaching: {len(words)} palabra(s) × {len(targets)} target(s) = {len(words)*len(targets)} peticiones")
    session = make_session()

    t0 = time.time()
    ok = 0
    fail = 0

    acc_txt: Dict[str, List[str]] = {t: [] for t in targets}
    acc_tsv: Dict[str, List[Tuple[str, str]]] = {t: [] for t in targets}

    futures = []
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        for (w, t) in iter_pairs(words, targets):
            futures.append(ex.submit(job_translate, session, args.backend, w, args.source, t, args.timeout))

        for i, fut in enumerate(as_completed(futures), 1):
            word, target, success, msg, translated = fut.result()
            if success:
                ok += 1
                acc_txt[target].append(translated)
                if args.pairs:
                    acc_tsv[target].append((word, translated))
            else:
                fail += 1

            if i % 100 == 0 or not success:
                status = "OK" if success else f"FAIL ({msg})"
                prev = f"{translated[:60]}…" if translated and len(translated) > 60 else translated
                print(f"[{i}/{len(futures)}] {word!r} → {target}: {status}" + (f"  '{prev}'" if success else ""))

    for t in targets:
        seen = set()
        uniq: List[str] = []
        for s in acc_txt[t]:
            if s and s not in seen:
                seen.add(s)
                uniq.append(s)

        txt_path = os.path.join(args.outdir, f"{args.source}_to_{t}.txt")
        with open(txt_path, "w", encoding="utf-8", newline="\n") as f:
            for s in uniq:
                f.write(s + "\n")
        print(f"↳ guardado {len(uniq)} líneas en: {txt_path}")

        if args.pairs and acc_tsv[t]:
            tsv_path = os.path.join(args.outdir, f"{args.source}_to_{t}.tsv")
            with open(tsv_path, "w", encoding="utf-8", newline="\n") as f:
                for src, dst in acc_tsv[t]:
                    f.write(f"{src}\t{dst}\n")
            print(f"↳ guardado {len(acc_tsv[t])} pares en: {tsv_path}")

    dt = time.time() - t0
    print(f"\nHecho en {dt:.1f}s. OK={ok}  FAIL={fail}  ({ok+fail} total)")

if __name__ == "__main__":
    main()
