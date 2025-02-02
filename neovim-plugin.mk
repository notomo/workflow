# usage: include {this_file}

FULL_PLUGIN_NAME ?= $(notdir $(abspath .))
PLUGIN_NAME ?= $(basename $(notdir $(abspath .)))
SPEC_DIR ?= ./spec/lua/${PLUGIN_NAME}

test: FORCE deps
	$(MAKE) requireall
	vusted --shuffle ${SPEC_DIR}

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
CHECK_RESULT:=${CHECK_RESULT_DIR}/${PLUGIN_NAME}.json
check: FORCE
	mkdir -p ${CHECK_RESULT_DIR}
	lua-language-server --check_out_path=${CHECK_RESULT} --configpath=${MAKEFILE_DIR_PATH}.luarc.json --check=lua
	cat ${CHECK_RESULT}
	if [ "$(shell cat ${CHECK_RESULT} | head -c 2)" = "[]" ]; then rm ${CHECK_RESULT}; fi

# target to overwrite
deps: assertlib.nvim requireall.nvim

assertlib.nvim: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/assertlib.nvim
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/assertlib.nvim:
	if [ "${DEPS_SKIP_ASSERTLIB}" != "1" ]; then git clone https://github.com/notomo/assertlib.nvim.git --depth 1 $@; fi

requireall.nvim: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/requireall.nvim
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/requireall.nvim:
	if [ "${DEPS_SKIP_REQUIREALL}" != "1" ]; then git clone https://github.com/notomo/requireall.nvim.git --depth 1 $@; fi

nvim-treesitter: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/opt/nvim-treesitter
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/opt/nvim-treesitter:
	git clone https://github.com/nvim-treesitter/nvim-treesitter.git --depth 1 $@;

FORCE:
.PHONY: FORCE
