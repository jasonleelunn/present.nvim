# NOTE: `just test` runs all the tests, can be overridden to test a single file; `just test path/to/test/file`
test target="tests/":
	nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedDirectory {{target}} { minimal_init = './tests/minimal_init.lua' }"

# re-run the test command whenever any lua file changes (requires `watchexec` to be installed)
test-watch target="tests/":
	watchexec --timings -c -r -e lua just test {{target}}
