# gfire-selfhosted — optional automation targets (no Go build).

.DEFAULT_GOAL := help

COMPOSE_MINIMAL := run/docker-compose/minimal/docker-compose.yml
ENV_EXAMPLE := run/common/.env.example
# Disposable HOST_DATA for make release-check only (not for operators).
RELEASE_CHECK_DATA := data/release-check

GREEN  := \033[0;32m
YELLOW := \033[0;33m
CYAN   := \033[0;36m
RESET  := \033[0m

.PHONY: help release-check

help:
	@echo "$(GREEN)gfire-selfhosted$(RESET) — deployment manifests (Compose, Helm, run/)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "$(YELLOW)Release:$(RESET)"
	@echo "  $(GREEN)release-check$(RESET)             validate minimal Compose config."
	@echo "                                 Needs: docker. Helm lint added when chart lands."
	@echo ""
	@echo "$(YELLOW)Day-to-day:$(RESET)"
	@echo "  export GFIRE_HOST_DATA=/path/outside/clone"
	@echo "  ./run/scripts/compose-stack.sh minimal up -d"
	@echo ""
	@echo "$(CYAN)Examples:$(RESET)"
	@echo "  make release-check"

release-check:
	@command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
	@mkdir -p "$(RELEASE_CHECK_DATA)/postgres"
	@sed 's|^GFIRE_HOST_DATA=.*|GFIRE_HOST_DATA=$(CURDIR)/$(RELEASE_CHECK_DATA)|' \
		"$(ENV_EXAMPLE)" > "$(RELEASE_CHECK_DATA)/.env"
	@echo "release-check: docker compose config (minimal)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" config >/dev/null
	@echo "release-check: docker compose config (minimal + redis profile)..."
	@mkdir -p "$(RELEASE_CHECK_DATA)/redis"
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" --profile redis config >/dev/null
	@echo "release-check: docker compose config (minimal + valkey profile)..."
	@mkdir -p "$(RELEASE_CHECK_DATA)/valkey"
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" --profile valkey config >/dev/null
	@echo "release-check: compose-stack.sh help..."
	@./run/scripts/compose-stack.sh --help >/dev/null
	@echo "release-check passed."
