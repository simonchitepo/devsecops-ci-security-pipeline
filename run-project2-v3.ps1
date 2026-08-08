# =========================================================
# DevSecOps CI Security Pipeline - Full 2-Week Script (v2, fixed)
# Safe to run top-to-bottom in ONE go, and safe to re-run if it errors partway.
# =========================================================

$ErrorActionPreference = "Continue"
$ProjectPath = "C:\Users\simon\cloud-security-devsecops-portfolio\02-devsecops-ci-security-pipeline"
Set-Location $ProjectPath

Write-Host "===== Sanity checks =====" -ForegroundColor Cyan
git --version
python --version
docker --version

# ---------------------------------------------------------
# STEP 0: Extract starter kit only if not already present
# ---------------------------------------------------------
if (-not (Test-Path ".\requirements.txt")) {
    Write-Host "Extracting starter kit..." -ForegroundColor Yellow
    $zip = "$env:USERPROFILE\Downloads\devsecops-ci-security-pipeline.zip"
    if (Test-Path $zip) {
        $tmp = Join-Path $env:TEMP "devsecops-extract"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        Expand-Archive -Path $zip -DestinationPath $tmp -Force
        # robocopy merges folders safely (Move-Item cannot)
        robocopy "$tmp\devsecops-ci-security-pipeline" "." /E | Out-Null
        Remove-Item $tmp -Recurse -Force
    } else {
        Write-Host "Zip not found at $zip - place it there and re-run this script." -ForegroundColor Red
    }
} else {
    Write-Host "Project files already present - skipping extraction." -ForegroundColor Green
}

# ---------------------------------------------------------
# STEP 1: Git repo setup (safe to re-run)
# ---------------------------------------------------------
if (-not (Test-Path ".git")) {
    Write-Host "Initializing git repo..." -ForegroundColor Yellow
    git init
    git branch -M main
    git remote add origin https://github.com/simonchitepo/devsecops-ci-security-pipeline.git
} else {
    Write-Host "Git repo already initialized." -ForegroundColor Green
}

# ---------------------------------------------------------
# STEP 2: Dedicated virtual environment for THIS project
# (fixes the wrong-interpreter / ModuleNotFoundError problem)
# Prefers Python 3.12 - Python 3.14's ensurepip is known to hang
# during venv creation on some Windows setups.
# ---------------------------------------------------------
if ((Test-Path ".\.venv") -and -not (Test-Path ".\.venv\Scripts\python.exe")) {
    Write-Host "Removing incomplete/broken venv from a previous run..." -ForegroundColor Yellow
    Remove-Item ".\.venv" -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path ".\.venv\Scripts\python.exe")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    $created = $false

    if (Get-Command py -ErrorAction SilentlyContinue) {
        Write-Host "Trying Python 3.12 via py launcher (more stable than 3.14 for venv)..." -ForegroundColor Yellow
        py -3.12 -m venv .venv 2>$null
        if (Test-Path ".\.venv\Scripts\python.exe") { $created = $true }
    }

    if (-not $created) {
        Write-Host "Falling back to default 'python' interpreter..." -ForegroundColor Yellow
        python -m venv .venv
    }

    if (-not (Test-Path ".\.venv\Scripts\python.exe")) {
        Write-Host "Venv creation failed. Run 'py -0p' to see installed Python versions, then re-run this script." -ForegroundColor Red
        exit 1
    }
}

$venvPython = ".\.venv\Scripts\python.exe"
$venvPip    = ".\.venv\Scripts\pip.exe"

& $venvPip install --upgrade pip
& $venvPip install -r requirements.txt
& $venvPip install flake8 pip-audit

# Check Docker once, reuse the result later
$dockerRunning = $true
try { docker info *> $null } catch { $dockerRunning = $false }
if (-not $dockerRunning) {
    Write-Host "Docker Desktop is not running. Start it before the Sat/Wed steps run docker build." -ForegroundColor Red
}

# =========================================================
# WEEK 1
# =========================================================

Write-Host "`n===== MON: Create Project 2 repo =====" -ForegroundColor Cyan
git add .
git commit -m "chore: initial project scaffold"
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "Initial push rejected (remote has existing commits) - merging histories..." -ForegroundColor Yellow
    git pull origin main --allow-unrelated-histories --no-edit
    git push -u origin main
}

Write-Host "`n===== TUE: Add unit tests =====" -ForegroundColor Cyan
& $venvPython -m pytest tests\ -v
git add tests\ src\app.py
git commit -m "test: add unit tests for app logic"
git push

Write-Host "`n===== WED: Add lint step =====" -ForegroundColor Cyan
& $venvPython -m flake8 src\ tests\ --max-line-length=100
git add .github\workflows\ci.yml
git commit -m "ci: add flake8 lint job"
git push

Write-Host "`n===== THU: Add Gitleaks =====" -ForegroundColor Cyan
git add .gitleaks.toml
git commit -m "ci: add gitleaks secret scanning"
git push

Write-Host "`n===== FRI: Add dependency scan =====" -ForegroundColor Cyan
Write-Host "(expect a finding for requests==2.19.1 - screenshot the GitHub Actions output for later)" -ForegroundColor Yellow
& $venvPython -m pip_audit -r requirements.txt
git commit --allow-empty -m "ci: enable dependency scanning with pip-audit"
git push

Write-Host "`n===== SAT: Add Trivy scan =====" -ForegroundColor Cyan
if ($dockerRunning) {
    docker build -t devsecops-ci-security-pipeline:latest .
} else {
    Write-Host "Skipped docker build - Docker Desktop not running. Run manually later:" -ForegroundColor Red
    Write-Host "  docker build -t devsecops-ci-security-pipeline:latest ." -ForegroundColor Red
}
git add Dockerfile
git commit -m "ci: add Trivy container image scan"
git push

Write-Host "`n===== SUN: CI screenshots + notes =====" -ForegroundColor Cyan
Write-Host "MANUAL: screenshot each Actions job into docs\screenshots\, and write notes.md" -ForegroundColor Yellow
if (-not (Test-Path "notes.md")) { New-Item notes.md -ItemType File | Out-Null }
git add docs\screenshots\ notes.md
git commit -m "docs: add CI run screenshots and week 1 notes"
git push

# =========================================================
# WEEK 2
# =========================================================

Write-Host "`n===== MON: Block unsafe merge in docs =====" -ForegroundColor Cyan
Write-Host "MANUAL (GitHub.com): Settings -> Branches -> protect main, require PR + status checks" -ForegroundColor Yellow
git add README.md docs\screenshots\
git commit -m "docs: document branch protection rules"
git push

Write-Host "`n===== TUE: Create failed/passed example =====" -ForegroundColor Cyan
(Get-Content requirements.txt) -replace 'requests==2\.19\.1', 'requests>=2.32.0' | Set-Content requirements.txt
& $venvPip install -r requirements.txt
git add requirements.txt
git commit -m "fix: upgrade requests to patch CVE-2018-18074"
git push
Write-Host "MANUAL: screenshot the pipeline going red -> green after this push" -ForegroundColor Yellow

Write-Host "`n===== WED: Docker hardening =====" -ForegroundColor Cyan
@'
FROM python:3.12-slim

RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 5000
CMD ["python", "src/app.py"]
'@ | Set-Content -Path Dockerfile -Encoding utf8

if ($dockerRunning) {
    docker build -t devsecops-ci-security-pipeline:latest .
}
git add Dockerfile
git commit -m "security: harden Dockerfile with non-root user"
git push

Write-Host "`n===== THU: Risk register =====" -ForegroundColor Cyan
Write-Host "MANUAL: open and edit risk-register.md with your real findings before this commit lands on GitHub" -ForegroundColor Yellow
git add risk-register.md
git commit -m "docs: finalize risk register"
git push

Write-Host "`n===== FRI: Security report =====" -ForegroundColor Cyan
Write-Host "MANUAL: open and edit SECURITY_REPORT.md with your real findings/screenshots" -ForegroundColor Yellow
git add SECURITY_REPORT.md docs\screenshots\
git commit -m "docs: complete security report"
git push

Write-Host "`n===== SAT: Badges + screenshots =====" -ForegroundColor Cyan
git add README.md docs\screenshots\
git commit -m "docs: add badges and final screenshots"
git push

Write-Host "`n===== SUN: Publish/pin project =====" -ForegroundColor Cyan
git add .
git commit -m "chore: final polish for Project 2"
git push
Write-Host "MANUAL (GitHub.com): Profile -> Customize your pins -> select devsecops-ci-security-pipeline" -ForegroundColor Yellow

Write-Host "`n===== DONE =====" -ForegroundColor Green
