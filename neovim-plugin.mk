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
	nvim --headless -i NONE -n +"luafile ${MAKEFILE_DIR_PATH}script/requireall.lua"

# target to overwrite
deps: assertlib.nvim requireall.nvim

assertlib.nvim: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/assertlib.nvim
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/assertlib.nvim:
	git clone https://github.com/notomo/assertlib.nvim.git --depth 1 $@

requireall.nvim: $(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/requireall.nvim
$(MAKEFILE_DIR_PATH)/packages/pack/testpack/start/requireall.nvim:
	git clone https://github.com/notomo/requireall.nvim.git --depth 1 $@

FORCE:
.PHONY: FORCE
