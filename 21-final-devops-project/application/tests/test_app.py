import pytest
from app.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_home(client):
    response = client.get("/")
    assert response.status_code == 200


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "healthy"


def test_greet(client):
    response = client.get("/api/greet/Ayush")
    assert response.status_code == 200
    data = response.get_json()
    assert "Ayush" in data["message"]


def test_add_numbers(client):
    response = client.post("/api/add", json={"number1": 10, "number2": 20})
    assert response.status_code == 200
    data = response.get_json()
    assert data["result"] == 30


def test_add_numbers_missing_fields(client):
    response = client.post("/api/add", json={"number1": 5})
    assert response.status_code == 400


def test_calculator_multiply(client):
    response = client.post("/api/calculate", json={"a": 4, "b": 5, "operation": "multiply"})
    assert response.status_code == 200
    data = response.get_json()
    assert data["result"] == 20


def test_calculator_divide_by_zero(client):
    response = client.post("/api/calculate", json={"a": 10, "b": 0, "operation": "divide"})
    assert response.status_code == 400


def test_status(client):
    response = client.get("/api/status")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "running"
    assert "python_version" in data
