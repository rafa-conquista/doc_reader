# =========================
# Configurações base
# =========================

PYTHON ?= python3
VENV_PATH ?= .venv
BIN = $(VENV_PATH)/bin

PIP = $(BIN)/pip
PY = $(BIN)/python

SRC ?= .
TEST_PATH ?= tests

REQ_IN ?= requirements.in
REQ_DEV_IN ?= requirements-dev.in
REQ ?= requirements.txt
REQ_DEV ?= requirements-dev.txt

# coverage
COV_FLAGS = --branch

# pip-compile
PIP_COMPILE_FLAGS = --rebuild --upgrade --no-header --no-emit-index-url --resolver=backtracking

# =========================
# Helpers
# =========================

.PHONY: help
help:
	@echo "Targets disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-25s %s\n", $$1, $$2}'

# =========================
# Bootstrap
# =========================

venv: ## Cria virtualenv
	$(PYTHON) -m venv $(VENV_PATH)
	@echo "✔ Ambiente virtual criado."

bootstrap: venv ## Prepara ambiente base do projeto
	$(PIP) install --upgrade pip setuptools wheel
	$(PIP) install \
		pip-tools \
		pytest \
		pytest-cov \
		pytest-watch \
		coverage \
		ruff \
		black \
		isort
	@echo "✔ Ferramentas instaladas."

# =========================
# Dependências
# =========================

init-deps: ## Cria arquivos requirements.in se não existirem
	@if [ ! -f $(REQ_IN) ]; then \
		echo "# Dependências de produção" > $(REQ_IN); \
		echo "✔ $(REQ_IN) criado"; \
	fi
	@if [ ! -f $(REQ_DEV_IN) ]; then \
		echo "# Dependências de desenvolvimento" > $(REQ_DEV_IN); \
		echo "✔ $(REQ_DEV_IN) criado"; \
	fi

lock-deps: bootstrap init-deps ## Gera requirements.txt
	$(BIN)/pip-compile $(PIP_COMPILE_FLAGS) $(REQ_IN)
	@echo "✔ $(REQ) gerado."

lock-deps-dev: bootstrap init-deps ## Gera requirements-dev.txt
	$(BIN)/pip-compile $(PIP_COMPILE_FLAGS) $(REQ_DEV_IN)
	@echo "✔ $(REQ_DEV) gerado."

install: bootstrap ## Instala dependências de produção
	@if [ -f $(REQ) ]; then \
		$(PIP) install -r $(REQ); \
	else \
		echo "Arquivo $(REQ) não encontrado"; \
	fi

install-dev: bootstrap ## Instala dependências de desenvolvimento
	@if [ -f $(REQ_DEV) ]; then \
		$(PIP) install -r $(REQ_DEV); \
	else \
		echo "Arquivo $(REQ_DEV) não encontrado"; \
	fi

# =========================
# Qualidade
# =========================

lint: ## Ruff + isort (check)
	$(BIN)/ruff check $(SRC)
	$(BIN)/isort $(SRC) --check-only

lint-path: ## make lint-path file=src/foo.py
	$(BIN)/ruff check $(or $(file), $(SRC))
	$(BIN)/isort $(or $(file), $(SRC)) --check-only

format: ## Black + isort
	$(BIN)/black $(SRC)
	$(BIN)/isort $(SRC)

format-path: ## make format-path file=src/foo.py
	$(BIN)/black $(or $(file), $(SRC))
	$(BIN)/isort $(or $(file), $(SRC))

fix: ## Ruff --fix + isort
	$(BIN)/ruff check $(or $(file), $(SRC)) --fix
	$(BIN)/isort $(or $(file), $(SRC))

outdated: ## Lista dependências desatualizadas
	$(PIP) list --outdated

security: ## Auditoria de vulnerabilidades
	$(PIP) install pip-audit
	$(BIN)/pip-audit

deps-tree:
	$(PIP) install pipdeptree
	$(BIN)/pipdeptree

# =========================
# Testes
# =========================

test: ## Testes rápidos
	$(BIN)/pytest -q

test-verbose:
	$(BIN)/pytest -vv

test-cov:
	$(BIN)/pytest --cov=$(SRC) --cov-report=term-missing

coverage-test:
	$(BIN)/coverage run $(COV_FLAGS) -m pytest

coverage-report:
	$(BIN)/coverage report

# =========================
# Limpeza
# =========================

clean: ## Remove arquivos temporários
	rm -rf .coverage coverage.xml htmlcov
	rm -rf .pytest_cache
	find . -type d -name "__pycache__" -exec rm -rf {} +
	@echo "✔ Arquivos temporários removidos."

clean-all:
	rm -rf $(VENV_PATH)
	rm -rf .coverage coverage.xml htmlcov
	rm -rf .pytest_cache
	find . -type d -name "__pycache__" -exec rm -rf {} +
	@echo "✔ Limpeza completa."

# =========================
# Docker (opcional)
# =========================

docker-up:
	docker compose up -d
	@echo "✔ Containers iniciados."

docker-down:
	docker compose down
	@echo "✔ Containers interrompidos."

docker-shell:
	docker compose exec app bash

# =========================
# Pre-commit
# =========================

PRECOMMIT_CONFIG = .pre-commit-config.yaml

precommit-install-tool: bootstrap ## Instala pre-commit
	$(PIP) install pre-commit

precommit-init: ## Cria .pre-commit-config.yaml se não existir
	@if [ ! -f $(PRECOMMIT_CONFIG) ]; then \
		echo "Criando $(PRECOMMIT_CONFIG)..."; \
		printf "%s\n" \
"repos:" \
"  - repo: https://github.com/pre-commit/pre-commit-hooks" \
"    rev: v4.6.0" \
"    hooks:" \
"      - id: end-of-file-fixer" \
"      - id: trailing-whitespace" \
"      - id: check-yaml" \
"      - id: check-added-large-files" \
"" \
"  - repo: https://github.com/astral-sh/ruff-pre-commit" \
"    rev: v0.4.8" \
"    hooks:" \
"      - id: ruff" \
"        args: [--fix]" \
"" \
"  - repo: https://github.com/psf/black" \
"    rev: 24.4.2" \
"    hooks:" \
"      - id: black" \
"" \
"  - repo: https://github.com/pycqa/isort" \
"    rev: 5.13.2" \
"    hooks:" \
"      - id: isort" \
		> $(PRECOMMIT_CONFIG); \
		echo "✔ $(PRECOMMIT_CONFIG) criado"; \
	else \
		echo "✔ $(PRECOMMIT_CONFIG) já existe"; \
	fi

precommit-install: precommit-install-tool precommit-init ## Instala hooks do pre-commit
	@if [ ! -d .git ]; then \
		echo "Repositório git não encontrado. Execute git init."; exit 1; \
	fi
	$(BIN)/pre-commit install
	@echo "✔ Hooks instalados"

precommit-run: ## Roda hooks manualmente
	$(BIN)/pre-commit run -a -v

precommit: precommit-install ## Inicializa pre-commit (atalho)

