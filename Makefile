.PHONY: test
test: test_dir
	$(eval TMP_DIR := $(shell mktemp -dp /tmp/presence_test))
	XDG_CONFIG_HOME="$(TMP_DIR)" XDG_DATA_HOME="$(TMP_DIR)" XDG_STATE_HOME="$(TMP_DIR)" \
					nvim --headless --clean -u scripts/minimal.lua -c "PlenaryBustedDirectory tests"

.PHONY: test_dir
test_dir:
	mkdir -p /tmp/presence_test
