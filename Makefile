test:
	nvim --version

ci: test

git_hooks:
	cp script/git-hooks/commit-msg "$$(git rev-parse --git-path hooks)/commit-msg"
	chmod +x "$$(git rev-parse --git-path hooks)/commit-msg"

PLUGINS_DIR ?= $(abspath $(CURDIR)/..)
LOCAL_DEPS ?= ntf assertlib.nvim requireall.nvim genvdoc
DEPS_START_DIRS ?= $(wildcard $(PLUGINS_DIR)/*/spec/.shared/packages/pack/testpack/start) $(wildcard $(CURDIR)/packages/pack/testpack/start)

link_deps:
	@for name in ${LOCAL_DEPS}; do \
	  if [ ! -d "${PLUGINS_DIR}/$$name" ]; then echo "no such directory: ${PLUGINS_DIR}/$$name"; exit 1; fi; \
	done
	@for dir in ${DEPS_START_DIRS}; do \
	  for name in ${LOCAL_DEPS}; do \
	    src="${PLUGINS_DIR}/$$name"; \
	    dst="$$dir/$$name"; \
	    case "$$dir" in "$$src"/*) continue;; esac; \
	    if [ ! -L "$$dst" ]; then rm -rf "$$dst"; fi; \
	    ln -sfn "$$src" "$$dst"; \
	    echo "linked: $$dst"; \
	  done; \
	done

unlink_deps:
	@for dir in ${DEPS_START_DIRS}; do \
	  for name in ${LOCAL_DEPS}; do \
	    dst="$$dir/$$name"; \
	    if [ -L "$$dst" ]; then rm "$$dst"; echo "unlinked: $$dst"; fi; \
	  done; \
	done
