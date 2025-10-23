import time, threading, queue, random
import requests
from requests.adapters import HTTPAdapter

URL = "http://localhost:3000/"

IDIOMAS = ['en', 'es', 'ko', 'ja', 'zh']
WORKERS = 4
CONNECT_TIMEOUT = 1.0
READ_TIMEOUT = 10.0
STATS_EVERY = 1.0
BATCH_PER_PAIR = 100  # 100 por cada par origen→destino
PREFETCH_WHEN = WORKERS * 4

def main() -> None:
    stop = threading.Event()
    ok = fail = 0
    lock = threading.Lock()
    q = queue.Queue()

    def targets_for(src) -> list[str]:
        # Mantiene el orden pedido: todos menos el origen
        return [t for t in IDIOMAS if t != src]

    def refill_tasks() -> None:
        # Un ciclo: 100 por cada par origen→destino
        tasks = []
        for src in IDIOMAS:
            for tgt in targets_for(src):
                tasks.extend([(src, tgt)] * BATCH_PER_PAIR)
        random.shuffle(tasks)  # distribuye carga entre pares
        for item in tasks:
            q.put(item)

    refill_tasks()

    def mk_session() -> requests.Session:
        s = requests.Session()
        s.headers.update({
            "Accept": "application/json, text/plain, */*",
            "User-Agent": "lang-pairs/1.0",
            "Connection": "keep-alive",
        })
        adapter = HTTPAdapter(pool_connections=WORKERS, pool_maxsize=WORKERS)
        s.mount("http://", adapter)
        s.mount("https://", adapter)
        return s

    def worker() -> None:
        nonlocal ok, fail
        s = mk_session()
        post = s.post
        to = (CONNECT_TIMEOUT, READ_TIMEOUT)
        while not stop.is_set():
            try:
                src, tgt = q.get()
                payload = {'originalLanguage': src, 'target': tgt, 'tipo': 'frase'}
                r = post(URL, json=payload, timeout=to)
                with lock:
                    if 200 <= r.status_code < 300: ok += 1
                    else: fail += 1
            except Exception:
                with lock: fail += 1
            finally:
                try: q.task_done()
                except Exception: pass

    threads = [threading.Thread(target=worker, daemon=True) for _ in range(WORKERS)]
    for t in threads: t.start()

    print(f"Flooding POST {URL} con {WORKERS} workers (Ctrl+C para detener)")
    try:
        last_ok = last_fail = 0
        last_t = time.monotonic()
        while True:
            time.sleep(STATS_EVERY)
            if q.qsize() < PREFETCH_WHEN:
                refill_tasks()  # siguiente ciclo infinito

            with lock:
                cur_ok, cur_fail = ok, fail
            now = time.monotonic()
            delta = (cur_ok + cur_fail) - (last_ok + last_fail)
            rps = delta / max(now - last_t, 1e-9)
            print(f"OK={cur_ok} FAIL={cur_fail} | ~{rps:.1f} req/s | cola={q.qsize()}")
            last_ok, last_fail, last_t = cur_ok, cur_fail, now
    except KeyboardInterrupt:
        stop.set()
    finally:
        for t in threads: t.join(timeout=1.0)
        with lock:
            print(f"Done. OK={ok} FAIL={fail}")

if __name__ == "__main__":
    main()
