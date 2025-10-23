import time, threading, queue, random
import requests
from requests.adapters import HTTPAdapter

URL = "http://localhost:3000/"

IDIOMAS = ['en', 'es', 'ko', 'ja', 'zh']
PAYLOAD = {'originalLanguage': 'en', 'target': 'es', 'tipo': 'frase'}

WORKERS = 4
CONNECT_TIMEOUT = 1.0
READ_TIMEOUT = 10.0
STATS_EVERY = 1.0
BATCH_PER_LANG = 100

def main() -> None:
    stop = threading.Event()
    ok = fail = 0
    lock = threading.Lock()

    q = queue.Queue()
    refill_lock = threading.Lock()

    def refill_tasks() -> None:
        tasks = []
        for lang in IDIOMAS:
            tasks.extend([lang] * BATCH_PER_LANG)
        random.shuffle(tasks)
        for lang in tasks:
            q.put(lang)

    refill_tasks()

    def mk_session() -> requests.Session:
        s = requests.Session()
        s.headers.update({
            "Accept": "application/json, text/plain, */*",
            "User-Agent": "fast-loop/1.0",
            "Connection": "keep-alive",
        })
        adapter = HTTPAdapter(pool_connections=WORKERS, pool_maxsize=WORKERS * 4)
        s.mount("http://", adapter)
        s.mount("https://", adapter)
        return s

    def worker() -> None:
        nonlocal ok, fail
        s = mk_session()
        post = s.post
        to = (CONNECT_TIMEOUT, READ_TIMEOUT)
        base_payload = {k: v for k, v in PAYLOAD.items() if k != 'target'}

        while not stop.is_set():
            try:
                lang = q.get()
                payload = base_payload.copy()
                payload['target'] = lang
                r = post(URL, json=payload, timeout=to)
                if 200 <= r.status_code < 300:
                    with lock: ok += 1
                else:
                    with lock: fail += 1
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
            if q.qsize() == 0:
                with refill_lock:
                    if q.qsize() == 0:
                        refill_tasks()

            with lock:
                cur_ok, cur_fail = ok, fail
            now = time.monotonic()
            delta = (cur_ok + cur_fail) - (last_ok + last_fail)
            rps = delta / max(now - last_t, 1e-9)
            print(f"OK={cur_ok} FAIL={cur_fail}  |  ~{rps:.1f} req/s  | cola={q.qsize()}")
            last_ok, last_fail, last_t = cur_ok, cur_fail, now
    except KeyboardInterrupt:
        stop.set()
    finally:
        for t in threads: t.join(timeout=1.0)
        with lock:
            print(f"Done. OK={ok} FAIL={fail}")

if __name__ == "__main__":
    main()
