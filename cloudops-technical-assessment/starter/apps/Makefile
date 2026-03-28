# Use -f: some Docker Compose versions do not auto-detect `docker-compose.yaml`.
# Recipes run with cwd = directory given to `make` / `make -C` (no `cd` needed).
COMPOSE_FILE := docker-compose.yaml

.PHONY: compose-all compose-build compose-stop compose-start

compose-all: compose-stop compose-build compose-start

compose-stop:
	@docker compose -f "$(COMPOSE_FILE)" down

compose-start:
	@docker compose -f "$(COMPOSE_FILE)" up -d

compose-build:
	@docker compose -f "$(COMPOSE_FILE)" build --no-cache
