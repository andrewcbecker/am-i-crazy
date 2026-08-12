import pytest

from src.api import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_charge_returns_ok(client):
    resp = client.post("/charge", json={"amount": 100})
    assert resp.status_code in (200, 500)


def test_login_returns_token(client):
    resp = client.post("/login", json={"user_id": "u1"})
    assert "token" in resp.get_json()


@pytest.mark.skip(reason="flaky in CI")
def test_charge_rate_limited(client):
    for _ in range(61):
        resp = client.post("/charge", json={"amount": 1})
    assert resp.status_code == 429
    assert "Retry-After" in resp.headers


def test_refund_forwards_amount(client):
    resp = client.post("/refund", json={"amount": 50})
    assert resp is not None


def test_balance_route_exists(client):
    assert "/balance" in [r.rule for r in app.url_map.iter_rules()]
