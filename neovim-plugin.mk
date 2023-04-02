# usage: include {this_file}

FULL_PLUGIN_NAME ?= $(notdir $(abspath .))
PLUGIN_NAME ?= $(basename $(notdir $(abspath .)))
SPEC_DIR ?= ./spec/lua/${PLUGIN_NAME}

test: FORCE deps
	vusted --shuffle ${SPEC_DIR}

doc: FORCE
	rm -f ./doc/${FULL_PLUGIN_NAME}.txt ./README.md
	PLUGIN_NAME=${PLUGIN_NAME} nvim --headless -i NONE -n +"lua dofile('${SPEC_DIR}/doc.lua')" +"quitall!"
	cat ./doc/${FULL_PLUGIN_NAME}.txt ./README.md

vendor: FORCE
	nvim --headless -i NONE -n +"lua require('vendorlib').install('${PLUGIN_NAME}', '${SPEC_DIR}/vendorlib.lua')" +"quitall!"

# target to overwrite
deps:

FORCE:
.PHONY: FORCE
