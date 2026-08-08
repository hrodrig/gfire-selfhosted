# gfire-selfhosted — optional automation targets (no Go build).

.DEFAULT_GOAL := help

COMPOSE_MINIMAL := run/docker-compose/minimal/docker-compose.yml
COMPOSE_CONSOLE := run/docker-compose/console/docker-compose.yml
ENV_EXAMPLE := run/common/.env.example
ENV_CONSOLE_EXAMPLE := run/docker-compose/console/.env.example
CHART_DIR ?= run/kubernetes/helm/gfire
KUBERNETES_VERSION ?= 1.30.0
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
	@echo "  $(GREEN)release-check$(RESET)             helm lint/template/kubeconform + Compose config."
	@echo "                                 Needs: helm, kubeconform, docker."
	@echo ""
	@echo "$(YELLOW)Day-to-day:$(RESET)"
	@echo "  export GFIRE_STACK_HOST_DATA=/path/outside/clone"
	@echo "  ./run/scripts/compose-stack.sh minimal up -d"
	@echo "  ./run/scripts/compose-stack.sh console up -d"
	@echo ""
	@echo "$(CYAN)Examples:$(RESET)"
	@echo "  make release-check"

release-check:
	@command -v helm >/dev/null 2>&1 || { echo "helm not found"; exit 1; }
	@command -v kubeconform >/dev/null 2>&1 || { echo "kubeconform not found (brew install kubeconform)"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
	@echo "release-check: helm lint $(CHART_DIR)..."
	@helm lint "$(CHART_DIR)"
	@echo "release-check: helm template + kubeconform (inline postgres DSN)..."
	@helm template test-rel "$(CHART_DIR)" --namespace test-ns \
		--set postgres.dsn='postgres://gfire:gfire@postgres:5432/gfire?sslmode=disable' | \
		kubeconform -strict -kubernetes-version "$(KUBERNETES_VERSION)" -summary -
	@echo "release-check: helm template + kubeconform (existing Secret)..."
	@helm template test-rel "$(CHART_DIR)" --namespace test-ns \
		--set postgres.existingSecret=gfire-postgres | \
		kubeconform -strict -kubernetes-version "$(KUBERNETES_VERSION)" -summary -
	@mkdir -p "$(RELEASE_CHECK_DATA)/postgres" "$(RELEASE_CHECK_DATA)/redis" "$(RELEASE_CHECK_DATA)/valkey"
	@mkdir -p "$(RELEASE_CHECK_DATA)/postgres-ui" "$(RELEASE_CHECK_DATA)/migrations-ui"
	@touch "$(RELEASE_CHECK_DATA)/migrations-ui/.keep"
	@sed 's|^GFIRE_STACK_HOST_DATA=.*|GFIRE_STACK_HOST_DATA=$(CURDIR)/$(RELEASE_CHECK_DATA)|' \
		"$(ENV_EXAMPLE)" > "$(RELEASE_CHECK_DATA)/.env"
	@echo "release-check: docker compose config (minimal)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" config >/dev/null
	@echo "release-check: docker compose config (minimal + redis profile)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" --profile redis config >/dev/null
	@echo "release-check: docker compose config (minimal + valkey profile)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" --profile valkey config >/dev/null
	@sed 's|^GFIRE_STACK_HOST_DATA=.*|GFIRE_STACK_HOST_DATA=$(CURDIR)/$(RELEASE_CHECK_DATA)|' \
		"$(ENV_CONSOLE_EXAMPLE)" > "$(RELEASE_CHECK_DATA)/.env.console"
	@echo "release-check: docker compose config (console)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env.console" -p gfire-console \
		-f "$(COMPOSE_CONSOLE)" config >/dev/null
	@echo "release-check: compose-stack.sh help..."
	@./run/scripts/compose-stack.sh --help >/dev/null
	@echo "release-check passed."