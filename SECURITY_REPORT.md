# Security Report — devsecops-ci-security-pipeline

## 1. Overview
This report summarizes the security controls implemented in the CI/CD pipeline for this project,
findings identified during development, and remediation actions taken.

## 2. Pipeline Security Controls

| Stage | Tool | Purpose |
|-------|------|---------|
| Unit Testing | pytest | Verify application logic behaves as expected |
| Linting | flake8 | Enforce code quality and catch obvious bugs |
| Secret Scanning | Gitleaks | Detect hardcoded credentials, tokens, keys |
| Dependency Scanning | pip-audit | Detect known CVEs in Python dependencies |
| Container Scanning | Trivy | Detect OS and library vulnerabilities in the Docker image |
| Branch Protection | GitHub branch rules | Prevent unreviewed/unscanned code reaching `main` |

## 3. Findings & Remediation

### Finding 1: Vulnerable dependency (requests==2.19.1)
- **Detected by:** pip-audit
- **CVE:** CVE-2018-18074
- **Risk:** Authorization header could be leaked on cross-domain redirects.
- **Remediation:** Upgraded to `requests>=2.32.0`.
- **Evidence:** See `docs/screenshots/` for before/after pipeline run.

### Finding 2: Container running as root
- **Detected by:** Manual Dockerfile review (Trivy also flags root-user misconfiguration)
- **Risk:** A container compromise would give an attacker root privileges inside the container.
- **Remediation:** Added a dedicated non-root `USER` in the Dockerfile.

### Finding 3: No secret scanning on push
- **Detected by:** Gap analysis before Gitleaks was added.
- **Risk:** Accidental credential leaks would go unnoticed until manually reviewed.
- **Remediation:** Added `gitleaks-action` as a required CI job.

## 4. Before / After Evidence
_Attach CI run screenshots here: a failing run (vulnerable dependency / unscanned image) and a
passing run after remediation._

- Before: `docs/screenshots/ci-failed-run.png`
- After: `docs/screenshots/ci-passed-run.png`

## 5. Residual Risks
See `risk-register.md` for the full list of tracked risks and their current status.

## 6. Conclusion
The pipeline now enforces automated testing, linting, secret scanning, dependency scanning, and
container image scanning on every push and pull request, with merges to `main` blocked unless all
checks pass.
