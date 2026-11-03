"""Watch the requested PR read-only; never review, approve, or merge it."""
import json
import sys
import subprocess
import urllib.error
import time
import urllib.request

number = int(sys.argv[1]) if len(sys.argv) > 1 else 15
url = f'https://api.github.com/repos/dreamer2664/civitas/pulls/{number}'
last_main = None
for attempt in range(60):
    main = subprocess.check_output(['git', 'ls-remote', 'origin', 'refs/heads/main'], text=True, timeout=30).split()[0]
    if main == last_main and attempt % 10 != 0:
        time.sleep(60)
        continue
    last_main = main
    request = urllib.request.Request(url, headers={'User-Agent': 'CIVITAS-WALK-merge-watch'})
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            pr = json.load(response)
        if pr['merged']:
            print(f"MERGED PR={number} commit={pr['merge_commit_sha']} at={pr['merged_at']}", flush=True)
            sys.exit(0)
        if pr['state'] == 'closed':
            print(f'CLOSED_UNMERGED PR={number}; audit must not claim the fixes landed', flush=True)
            sys.exit(2)
        if attempt % 6 == 0:
            print(f"WAITING_FOR_AUTHORIZED_MERGE PR={number} head={pr['head']['sha']}", flush=True)
    except urllib.error.HTTPError as error:
        if error.code == 403 and error.headers.get('X-RateLimit-Remaining') == '0':
            delay = max(60, int(error.headers.get('X-RateLimit-Reset', time.time()+120))-int(time.time())+2)
            print(f'PUBLIC_READ_RATE_LIMIT {url}; backoff={delay}s', flush=True)
            time.sleep(delay)
        else:
            print(f'WATCH_HTTP_BLOCKED {error.code} {url}; no permission retry', flush=True)
            sys.exit(4)
    except Exception as error:
        print(f'WATCH_READ_ERROR {type(error).__name__}: {error}', flush=True)
    time.sleep(60)
print('MERGE_WATCH_TIMEOUT; no merge performed by WALK', flush=True)
sys.exit(3)
