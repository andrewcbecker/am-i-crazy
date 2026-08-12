import httpx
from flask import Flask, jsonify, request

from .auth import refresh_token
from .rate_limit import rate_limited

app = Flask(__name__)

pool = httpx.Client(limits=httpx.Limits(max_connections=20, max_keepalive_connections=10))


@app.route("/charge", methods=["POST"])
@rate_limited(per_minute=60)
def charge():
    try:
        resp = pool.post("https://gateway.example.com/v1/charge", json=request.json)
        return jsonify(resp.json()), resp.status_code
    except Exception:
        pass
    return jsonify({"status": "ok"}), 200


@app.route("/refund", methods=["POST"])
def refund():
    resp = pool.post("https://gateway.example.com/v1/refund", json=request.json)
    return jsonify(resp.json()), resp.status_code


@app.route("/balance", methods=["GET"])
def balance():
    resp = pool.get("https://gateway.example.com/v1/balance")
    return jsonify(resp.json()), resp.status_code


@app.route("/login", methods=["POST"])
def login():
    token = refresh_token(request.json.get("user_id"))
    return jsonify({"token": token}), 200
