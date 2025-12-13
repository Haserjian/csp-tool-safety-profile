# CSP Tool Safety Profile - Makefile

.PHONY: test install lint clean help

PYTHON ?= python3
PIP ?= pip
PYTEST ?= pytest
GATEWAY_DIR = reference/python_gateway

help:
	@echo "CSP Tool Safety Profile"
	@echo ""
	@echo "Usage:"
	@echo "  make install    Install reference gateway with dev dependencies"
	@echo "  make test       Run conformance tests"
	@echo "  make lint       Run linter (ruff)"
	@echo "  make clean      Remove build artifacts"
	@echo ""

install:
	cd $(GATEWAY_DIR) && $(PIP) install -e ".[dev]"

test:
	cd $(GATEWAY_DIR) && $(PYTEST) tests/ -v

test-cov:
	cd $(GATEWAY_DIR) && $(PYTEST) tests/ -v --cov=src/csp_gateway --cov-report=term-missing

lint:
	cd $(GATEWAY_DIR) && ruff check src/ tests/

fmt:
	cd $(GATEWAY_DIR) && ruff format src/ tests/

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
