.PHONY: storage-snapshot invariants coverage slither

storage-snapshot:
	forge inspect CreditRegistry storage-layout > storage-layout-snapshot.json
	@echo "Snapshot saved to storage-layout-snapshot.json"
	@echo "Commit this file and diff it before every upgrade."

invariants:
	forge test --match-contract Invariant -v --profile deep

coverage:
	forge coverage --report lcov
	genhtml lcov.info --output-directory coverage-html
	@echo "Coverage report at coverage-html/index.html"

slither:
	slither src/ --config-file .slither.config.json
