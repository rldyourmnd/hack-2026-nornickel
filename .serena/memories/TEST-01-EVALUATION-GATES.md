<!-- Memory Metadata
Last updated: 2026-07-05
Last commit: 67f08b0 fix(llm): map claude effort for dataeyes
Scope: Makefile; tests/; .github/workflows/ci.yml; pyproject.toml; scripts/run_realcase_eval.py
Area: TEST
-->

# TEST-01-EVALUATION-GATES

## Purpose

Capture current validation commands and what they prove.

## Source Of Truth

- `justfile`: source/native/artifact/security verification.
- `Makefile`: runtime `eval-realcase`, `reindex`, `warmup` and service/container operators.
- `.github/workflows/ci.yml`: CI backend/frontend gates.
- `tests/unit/`: domain/service/adapter tests.
- `tests/integration/`: FastAPI, DuckDB ledger, graph, ingest, analytics tests.
- `scripts/run_realcase_eval.py`: live real-corpus honesty eval.

## Current Behavior

`scripts/run_eval.py`, `eval/*.yml`, and the legacy fixture corpus test were removed. There is no `make eval` target.

Full local verification remains:

- `just check`: offline Python/frontend/source/workflow checks after preparation.
- `just test`: the original synthetic backend suite on an execution host.
- `just build`: the original frontend artifact on an execution host.
- `just verify`: the complete checks, including metrics-off scanner rules.

Provider-specific unit coverage includes:

- `tests/unit/test_llm_gateway.py::test_gateway_sends_yandex_project_header`:
  verifies Yandex AI Studio OpenAI-compatible calls receive the `OpenAI-Project`
  header derived from `YANDEX_FOLDER_ID`.
- `tests/unit/test_llm_gateway.py::test_gateway_forwards_reasoning_effort`:
  verifies `LLM_REASONING_EFFORT` is passed through LiteLLM, GPT-5-family model
  IDs use provider-compatible `temperature=1`, and extraction calls do not set
  output token caps that could truncate structured JSON.
- `tests/unit/test_llm_gateway.py::test_gateway_uses_default_temperature_for_claude_effort`:
  verifies DataEyes Claude/Sonnet answer calls use `temperature=1` and
  Anthropic-style `output_config.effort`, not OpenAI-style `reasoning_effort`.
- `tests/unit/test_yandex_embeddings.py`: verifies split doc/query embedding
  model URIs and the configured `dim` field in Yandex text-vectorization payloads.
- `tests/unit/test_answer_composer.py::test_transient_llm_error_retries_before_fallback`:
  verifies answer synthesis retries a transient `LLMError` such as an empty
  completion before falling back to deterministic output.

`scripts/run_realcase_eval.py` checks four organizer track questions against a running API. It asserts citation coverage 1.0, zero fabricated numbers, zero source-label leaks, zero prompt-injection success, zero semantic unsupported sentences, non-empty evidence, and no legacy fixture leakage.

## Invariants

- Add or update tests in the same change as ingestion, extraction, retrieval, answer verification, or API contract changes.
- Source checks stay offline. Full `just verify` keeps the mandatory scanner-rule network input and requires no provider secrets or external LLM calls.
- Use `eval-realcase` only against a live stand/API.

## Verification

- `just verify`: backend lint/type/test plus frontend build.
- `make eval-realcase`: live stand honesty check.
- `uv run pytest tests/integration/test_api.py::test_health_uses_llm_settings_aliases`:
  verifies `/health` uses the same LLM alias handling as runtime wiring while still
  hiding exact provider model IDs.
- `uv run pytest tests/unit/test_answer_composer.py`: verifies LLM answer
  composition, citation filtering, contradiction drops, provider-error fallback,
  and transient LLM-error retry behavior.
