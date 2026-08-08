# usage: include {this_file}

FULL_PLUGIN_NAME ?= $(notdir $(abspath .))
PLUGIN_NAME ?= $(basename $(notdir $(abspath .)))
SPEC_DIR ?= ./spec/lua/${PLUGIN_NAME}

# entry point for CI. overwrite CI_TARGETS to run more than tests.
CI_TARGETS ?= test
ci: FORCE
	$(MAKE) ${CI_TARGETS}

NTF ?= $(MAKEFILE_DIR_PATH)packages/pack/testpack/start/ntf/bin/ntf

NTF_GLOBAL_HOOK ?= ${MAKEFILE_DIR_PATH}script/ntf_global_hook.lua
NTF_GLOBAL_HOOK_FLAGS = --global-hook=${NTF_GLOBAL_HOOK}

test: FORCE deps
	$(MAKE) requireall
	$(NTF) ${NTF_GLOBAL_HOOK_FLAGS} ${SPEC_DIR}

test_list: FORCE deps
	$(NTF) list ${NTF_GLOBAL_HOOK_FLAGS} ${SPEC_DIR}

EXCLUDE_CODE ?= $(wildcard lua/${PLUGIN_NAME}/vendor lua/${PLUGIN_NAME}/test)
EXCLUDE_CODE_FLAGS = $(foreach path,${EXCLUDE_CODE},--exclude-code=${path})

COVERAGE_STATS ?= ${MAKEFILE_DIR_PATH}luacov.stats.out
coverage: FORCE deps
	$(NTF) --coverage=${COVERAGE_STATS} ${EXCLUDE_CODE_FLAGS} ${NTF_GLOBAL_HOOK_FLAGS} ${SPEC_DIR}

MUTATION_RESULTS ?= ${MAKEFILE_DIR_PATH}ntf-mutation.json
MUTATION_CONFIG ?= $(wildcard spec/mutation.json)
MUTATION_CONFIG_FLAGS = $(foreach path,${MUTATION_CONFIG},--config=${path})
MUTATION_FLAGS = ${MUTATION_CONFIG_FLAGS} ${NTF_GLOBAL_HOOK_FLAGS}

mutation: MUTATION_FLAGS += --strict
mutation: FORCE deps
	$(NTF) mutation --results=${MUTATION_RESULTS} ${MUTATION_FLAGS} ${EXCLUDE_CODE_FLAGS} ${SPEC_DIR}

mutation_list: FORCE deps
	$(NTF) mutation list ${MUTATION_FLAGS} ${EXCLUDE_CODE_FLAGS} ${SPEC_DIR}

mutation_verify_baseline: FORCE deps
	$(NTF) mutation verify-baseline ${MUTATION_FLAGS} ${EXCLUDE_CODE_FLAGS} ${SPEC_DIR}

mutation_ci: MUTATION_FLAGS += --strict --verify-baseline
mutation_ci: FORCE deps
	$(NTF) mutation --results=${MUTATION_RESULTS} ${MUTATION_FLAGS} ${EXCLUDE_CODE_FLAGS} ${SPEC_DIR}

DOC_CONFIG ?= $(wildcard spec/doc_config.json)
doc: FORCE
	rm -f ./doc/${FULL_PLUGIN_NAME}.txt ./README.md
	PLUGIN_NAME=${PLUGIN_NAME} DOC_CONFIG="${DOC_CONFIG}" nvim --headless -i NONE -n +"lua dofile('${SPEC_DIR}/doc.lua')" +"quitall!"
	cat ./doc/${FULL_PLUGIN_NAME}.txt ./README.md

vendor: FORCE
	nvim --headless -i NONE -n +"lua require('vendorlib').install('${PLUGIN_NAME}', '${SPEC_DIR}/vendorlib.lua')" +"quitall!"

MAKEFILE_DIR_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
sync_config:
	cp ${MAKEFILE_DIR_PATH}/stylua.toml ${MAKEFILE_DIR_PATH}/../../stylua.toml

git_hooks: FORCE
	cp ${MAKEFILE_DIR_PATH}script/git-hooks/commit-msg "$$(git rev-parse --git-path hooks)/commit-msg"
	chmod +x "$$(git rev-parse --git-path hooks)/commit-msg"

requireall: FORCE deps
	REQUIREALL_PACKPATH=${MAKEFILE_DIR_PATH}packages REQUIREALL_IGNORE_MODULES=${REQUIREALL_IGNORE_MODULES} nvim --headless --clean +"luafile ${MAKEFILE_DIR_PATH}script/requireall.lua"

REQUIRE_LINT_CONFIG ?= $(wildcard spec/require_lint.json)
require_lint: FORCE
	REQUIRE_LINT_CONFIG="${REQUIRE_LINT_CONFIG}" nvim --headless --clean +"luafile ${MAKEFILE_DIR_PATH}script/require_lint.lua"

comment_lint: FORCE
	DOC_CONFIG="${DOC_CONFIG}" nvim --headless --clean +"luafile ${MAKEFILE_DIR_PATH}script/comment_lint.lua"

CHECK_RESULT_DIR:=/tmp/luals-check
CHECK_RESULT_LUA:=${CHECK_RESULT_DIR}/${PLUGIN_NAME}-lua.json
CHECK_RESULT_SPEC:=${CHECK_RESULT_DIR}/${PLUGIN_NAME}-spec.json
CHECK_VIMRUNTIME ?= $(shell nvim --headless -u NONE -i NONE -n +"lua io.write(vim.env.VIMRUNTIME or '')" +"quitall!" 2>/dev/null)
check: FORCE
	mkdir -p ${CHECK_RESULT_DIR}
	VIMRUNTIME=${CHECK_VIMRUNTIME} lua-language-server --check_out_path=${CHECK_RESULT_LUA} --configpath=${MAKEFILE_DIR_PATH}.luarc.json --checklevel=Hint --check=lua
	VIMRUNTIME=${CHECK_VIMRUNTIME} lua-language-server --check_out_path=${CHECK_RESULT_SPEC} --configpath=${MAKEFILE_DIR_PATH}.luarc.json --checklevel=Hint --check=spec/lua
	cat ${CHECK_RESULT_LUA} ${CHECK_RESULT_SPEC}

# target to overwrite
deps: ntf assertlib.nvim requireall.nvim

ntf: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/ntf
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/ntf:
	@if [ "${DEPS_SKIP_NTF}" != "1" ]; then git clone https://github.com/notomo/ntf.git --depth 1 $@; fi

assertlib.nvim: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/assertlib.nvim
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/assertlib.nvim:
	@if [ "${DEPS_SKIP_ASSERTLIB}" != "1" ]; then git clone https://github.com/notomo/assertlib.nvim.git --depth 1 $@; fi

requireall.nvim: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/requireall.nvim
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/requireall.nvim:
	@if [ "${DEPS_SKIP_REQUIREALL}" != "1" ]; then git clone https://github.com/notomo/requireall.nvim.git --depth 1 $@; fi

nvim-treesitter: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/opt/nvim-treesitter
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/opt/nvim-treesitter:
	git clone https://github.com/notomo/nvim-treesitter.git --depth 1 $@;
	npm install -g tree-sitter-cli@0.26.9

FORCE:
.PHONY: FORCE
