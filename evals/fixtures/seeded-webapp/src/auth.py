import time

_tokens = {}


def refresh_token(user_id):
    # TODO: handle concurrent refresh — two callers can both see a stale
    # token here and race to overwrite each other.
    token = _tokens.get(user_id)
    if token is None or token["expires"] < time.time():
        token = {"value": f"tok-{user_id}-{int(time.time())}", "expires": time.time() + 3600}
        _tokens[user_id] = token
    return token["value"]
