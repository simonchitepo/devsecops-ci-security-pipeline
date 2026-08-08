# DevSecOps CI Security Pipeline

![CI Security Pipeline](https://github.com/simonchitepo/devsecops-ci-security-pipeline/actions/workflows/ci.yml/badge.svg)

A demo project showing a hardened CI/CD pipeline with automated security gates:
unit testing, linting, secret scanning, dependency scanning, and container image scanning.

## Pipeline Stages
1. **Unit Tests** — pytest
2. **Lint** — flake8
3. **Secret Scan** — Gitleaks
4. **Dependency Scan** — pip-audit
5. **Docker Image Scan** — Trivy

## Project Structure
```
.
├── .github/workflows/ci.yml   # CI pipeline definition
├── src/app.py                 # Sample Flask app
├── tests/test_app.py          # Unit tests
├── Dockerfile                 # Container definition
├── requirements.txt           # Python dependencies
├── risk-register.md           # Tracked security risks
├── SECURITY_REPORT.md         # Findings & remediation report
└── docs/screenshots/          # CI run evidence
```

## Running Locally
```bash
pip install -r requirements.txt
pytest tests/ -v
flake8 src/ tests/
python src/app.py
```

## Docker
```bash
docker build -t devsecops-ci-security-pipeline .
docker run -p 5000:5000 devsecops-ci-security-pipeline
```

## Security Docs
- [Risk Register](./risk-register.md)
- [Security Report](./SECURITY_REPORT.md)
