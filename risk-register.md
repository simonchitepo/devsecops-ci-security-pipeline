# Risk Register — devsecops-ci-security-pipeline

| ID | Risk | Category | Likelihood | Impact | Severity | Mitigation | Status |
|----|------|----------|-----------|--------|----------|------------|--------|
| R-01 | Outdated `requests` dependency (CVE-2018-18074) | Dependency | Medium | High | High | Pin to `requests>=2.32.0`, enforce `pip-audit` in CI | Fixed |
| R-02 | Secrets accidentally committed to repo | Secrets | Low | Critical | High | Gitleaks scan on every push/PR | Mitigated (control in place) |
| R-03 | Container running as root user | Docker | Medium | Medium | Medium | Add non-root `USER` in Dockerfile | Fixed |
| R-04 | Base image not pinned to digest, could drift | Docker | Medium | Low | Low | Pin base image tag/digest, rebuild regularly | Accepted (monitor) |
| R-05 | No branch protection, unreviewed code can merge to main | Process | Medium | High | High | Require PR review + passing CI checks before merge | Fixed |
| R-06 | No linting, style/logic issues can slip through | Code Quality | Medium | Low | Low | flake8 step in CI | Fixed |
| R-07 | Unscanned Docker image vulnerabilities | Container | Medium | High | High | Trivy scan in CI, fail build on CRITICAL/HIGH | Fixed |

## Notes
- Severity = combination of Likelihood x Impact, rated Low/Medium/High/Critical.
- Status values: Open, Mitigated, Fixed, Accepted.
- This register should be revisited whenever a new scan tool finding appears or a dependency is upgraded.
