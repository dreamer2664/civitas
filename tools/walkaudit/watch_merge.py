"""Watch the requested PR read-only; never review, approve, or merge it."""
import json
import sys
import time
import urllib.request

number = int(sys.argv[1]) if len(sys.argv) > 1 else 15
url = f'https://api.github.com/repos/dreamer2664/civitas/pulls/{number}'
for attempt in range(180):
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
    except Exception as error:
        print(f'WATCH_READ_ERROR {type(error).__name__}: {error}', flush=True)
    time.sleep(20)
print('MERGE_WATCH_TIMEOUT; no merge performed by WALK', flush=True)
sys.exit(3)
