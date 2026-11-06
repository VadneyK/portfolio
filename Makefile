# Release path for vadneyk.github.io/portfolio. `make ship` is the only way to release (see README).
# make check : static tests + layout-check at nine widths against a local server (free, local)
# make smoke : static tests + layout-check at 375 and 1440 (what CI could run)
# make ship  : check, then squash-merge the open PR, wait for the Pages deploy of that commit,
#              smoke-test the live site, and revert the merge if the smoke test fails
# GitHub Pages has no preview channels, so the preview is `make check` on the PR head, and ship
# refuses to run unless the tree is clean and matches the pushed branch.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
REPO    := VadneyK/portfolio
LIVE    := https://vadneyk.github.io/portfolio/
WIDTHS  := 320,375,414,768,1024,1280,1440,1920,2560
PORT    ?= 8766
OUT     ?= .layout-check
NODE    := node $(shell node -e "process.exit(typeof WebSocket==='undefined'?0:1)" && echo --experimental-websocket)
GHTOKEN  = $${GH_TOKEN:-$$(gh auth token -u VadneyK)}
PR      ?= $(shell GH_TOKEN=$$(gh auth token -u VadneyK 2>/dev/null) gh pr list --repo $(REPO) --head "$$(git rev-parse --abbrev-ref HEAD)" --json number -q ".[0].number" 2>/dev/null)

.PHONY: deps test check smoke ship
deps:
	@[ -d node_modules/axe-core ] || npm ci --silent

test:
	python3 tests/check_static.py

# Serve public/ locally, run the layout check at $(1) widths, always stop the server.
define local_layout
	python3 -m http.server $(PORT) -d public >/dev/null 2>&1 & srv=$$!; trap "kill $$srv" EXIT; \
	for i in $$(seq 1 40); do curl -sf -o /dev/null http://127.0.0.1:$(PORT)/ && break; sleep 0.25; done; \
	$(NODE) tests/layout-check.mjs http://127.0.0.1:$(PORT)/ --widths $(1) --out $(OUT)/local
endef

check: deps test
	$(call local_layout,$(WIDTHS))

smoke: deps test
	$(call local_layout,375,1440)

ship: check
	@[ -n "$(PR)" ] || { echo "No open PR for this branch. Push and open one first."; exit 1; }
	@[ -z "$$(git status --porcelain)" ] || { echo "Commit your changes first."; exit 1; }
	@git fetch -q origin && [ "$$(git rev-parse HEAD)" = "$$(git rev-parse @{u})" ] || { echo "Push the branch first: the PR must match what was tested."; exit 1; }
	@[ "$$(GH_TOKEN=$(GHTOKEN) gh api repos/$(REPO) -q .visibility)" = public ] && GH_TOKEN=$(GHTOKEN) gh api repos/$(REPO)/pages >/dev/null 2>&1 || { echo "The repo is private or Pages is off. Turning them on is Kentaro's call (board inbox portfolio.md, pf-1)."; exit 1; }
	GH_TOKEN=$(GHTOKEN) gh pr merge $(PR) --repo $(REPO) --squash --delete-branch
	git checkout -q main && git pull -q --ff-only origin main
	sha=$$(git rev-parse HEAD); echo "waiting for Pages to serve $$sha"; \
	for i in $$(seq 1 60); do [ "$$(curl -sf "$(LIVE)version.txt?n=$$i" | tr -d '[:space:]')" = "$$sha" ] && break; sleep 10; done; \
	if [ "$$(curl -sf "$(LIVE)version.txt?n=final" | tr -d '[:space:]')" = "$$sha" ] && \
	   curl -sf "$(LIVE)" | grep -q 'id="hero-title"' && \
	   $(NODE) tests/layout-check.mjs "$(LIVE)" --widths 375,1440 --out $(OUT)/live; then \
	  echo "SHIPPED: $(LIVE) serves $$sha and passes the smoke test"; \
	else \
	  echo "SMOKE TEST FAILED: reverting $$sha on main"; \
	  git revert --no-edit "$$sha" && git push origin main; exit 1; \
	fi
