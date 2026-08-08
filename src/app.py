from flask import Flask

app = Flask(__name__)


def add(a: int, b: int) -> int:
    """Simple pure function so we have something to unit test."""
    return a + b


@app.route("/")
def home():
    return "DevSecOps CI Security Pipeline demo app is running."


@app.route("/health")
def health():
    return {"status": "ok"}, 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
