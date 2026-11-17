set shell := ["bash", "-euo", "pipefail", "-c"]

# Lists the available commands.
default:
    @just --list

# Installs the existing locked execution graphs; editable builds belong on execution hosts.
setup: setup-backend setup-frontend

# Prepares locked prebuilt source-check dependencies without building this package or running scripts.
[group('source')]
setup-source:
    UV_PYTHON_DOWNLOADS=never uv sync --locked --group dev --no-install-project --no-build
    just _setup-source-frontend

# Prepares only frontend source dependencies, without install-script execution.
[private]
[working-directory('apps/web')]
_setup-source-frontend:
    npm ci --ignore-scripts --no-audit

# Installs the same locked backend/development graph used by native CI.
[group('backend')]
setup-backend:
    uv sync --locked --group dev

# Installs the existing frontend lock and its declared build prerequisites.
[group('frontend')]
[working-directory('apps/web')]
setup-frontend:
    npm ci --no-audit

# Runs offline source, types, workflows and retained-history checks with prepared inputs.
check: check-backend check-frontend check-workflows

# Checks authored Python without importing the application or installing the project.
[group('checks')]
check-backend:
    UV_OFFLINE=1 uv run --no-sync ruff check .
    MYPYPATH=src UV_OFFLINE=1 uv run --no-sync mypy

# Preserves the existing frontend typecheck independently of artifact generation.
[group('checks')]
[working-directory('apps/web')]
check-frontend:
    npm run typecheck

# Checks command formatting, workflow safety and retained Git history.
[group('checks')]
check-workflows:
    just --fmt --check
    actionlint
    zizmor --offline --no-progress .github
    gitleaks git --no-banner --redact --log-opts=--all .

# Formats authored Python and the command file with prepared source tools.
fix:
    uv run --no-sync ruff format .
    uv run --no-sync ruff check --fix .
    just --fmt

# Runs the original synthetic backend test suite on an execution host.
test:
    uv run --no-sync pytest

# Builds the original TypeScript/Vite frontend artifact.
[working-directory('apps/web')]
build:
    npm run build

# Preserves the mandatory network-backed Semgrep error gate with metrics off.
[group('security')]
scan:
    uvx semgrep@1.182.1 scan --error --metrics off --config p/ci

# Runs the full source/native/artifact/security verification without any runtime operator.
verify: check test build scan
