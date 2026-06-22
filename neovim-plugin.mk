# usage: include {this_file}

FULL_PLUGIN_NAME ?= $(notdir $(abspath .))
PLUGIN_NAME ?= $(basename $(notdir $(abspath .)))
SPEC_DIR ?= ./spec/lua/${PLUGIN_NAME}

NTF ?= $(MAKEFILE_DIR_PATH)packages/pack/testpack/start/ntf/bin/ntf
test: FORCE deps
	$(MAKE) requireall
	$(NTF) --shuffle ${SPEC_DIR}

doc: FORCE
	rm -f ./doc/${FULL_PLUGIN_NAME}.txt ./README.md
	PLUGIN_NAME=${PLUGIN_NAME} nvim --headless -i NONE -n +"lua dofile('${SPEC_DIR}/doc.lua')" +"quitall!"
	cat ./doc/${FULL_PLUGIN_NAME}.txt ./README.md

vendor: FORCE
	nvim --headless -i NONE -n +"lua require('vendorlib').install('${PLUGIN_NAME}', '${SPEC_DIR}/vendorlib.lua')" +"quitall!"

MAKEFILE_DIR_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
sync_config:
	cp ${MAKEFILE_DIR_PATH}/stylua.toml ${MAKEFILE_DIR_PATH}/../../stylua.toml

requireall: FORCE deps
	REQUIREALL_IGNORE_MODULES=${REQUIREALL_IGNORE_MODULES} nvim --headless --clean +"luafile ${MAKEFILE_DIR_PATH}script/requireall.lua"

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
	if [ "${DEPS_SKIP_NTF}" != "1" ]; then git clone https://github.com/notomo/ntf.git --depth 1 $@; fi

assertlib.nvim: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/assertlib.nvim
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/assertlib.nvim:
	if [ "${DEPS_SKIP_ASSERTLIB}" != "1" ]; then git clone https://github.com/notomo/assertlib.nvim.git --depth 1 $@; fi

requireall.nvim: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/requireall.nvim
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/requireall.nvim:
	if [ "${DEPS_SKIP_REQUIREALL}" != "1" ]; then git clone https://github.com/notomo/requireall.nvim.git --depth 1 $@; fi

nvim-treesitter: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/opt/nvim-treesitter
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/opt/nvim-treesitter:
	git clone https://github.com/notomo/nvim-treesitter.git --depth 1 $@;
	npm install -g tree-sitter-cli@0.26.9

FORCE:
.PHONY: FORCE
