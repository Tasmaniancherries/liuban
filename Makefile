SHELL := /bin/bash

.PHONY: help ci-quality ci-smoke format analyze test coverage

help:
	@echo "Targets:"
	@echo "  make ci-quality  # Run the same checks as CI quality job"
	@echo "  make ci-smoke    # Run web + Android smoke builds"
	@echo "  make format      # Check formatting only"
	@echo "  make analyze     # Run analyzer with fatal infos"
	@echo "  make test        # Run tests"
	@echo "  make coverage    # Run tests with coverage"

ci-quality:
	./tool/ci_quality.sh

ci-smoke:
	./tool/ci_smoke_builds.sh

format:
	dart format --output=none --set-exit-if-changed .

analyze:
	dart analyze --fatal-infos

test:
	flutter test

coverage:
	flutter test --coverage
