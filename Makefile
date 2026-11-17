.PHONY: api web eval-realcase reindex warmup docker-up docker-down

api:
	uv run fastapi dev services/api/main.py --host 0.0.0.0 --port 8000

web:
	cd apps/web && npm run dev -- --host 0.0.0.0 --port 5173

eval-realcase:
	uv run python scripts/run_realcase_eval.py

reindex:
	uv run python scripts/reindex.py

warmup:
	uv run python scripts/warmup.py

docker-up:
	docker compose up --build

docker-down:
	docker compose down
