import time
from collections import defaultdict, deque
from functools import wraps

from flask import jsonify, request

_hits = defaultdict(deque)


def rate_limited(per_minute):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            key = request.remote_addr
            now = time.time()
            window = _hits[key]
            while window and window[0] < now - 60:
                window.popleft()
            if len(window) >= per_minute:
                return jsonify({"error": "rate limit exceeded"}), 429
            window.append(now)
            return fn(*args, **kwargs)

        return wrapper

    return decorator
