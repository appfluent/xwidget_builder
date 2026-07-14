.PHONY: check
check:
	@TEST_PATH=test/bin bash tool/release_check.sh
