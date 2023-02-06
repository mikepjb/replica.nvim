repl:
	clojure -M:nrepl:figwheel

test:
	nvim --headless --clean --noplugin \
		-u "./tests/minimal_init.vim" \
		-c "PlenaryBustedDirectory ./tests/replica/ { minimal_init = './tests/minimal_init.vim' }"

todo:
	rg "(TODO|XXX)" -g '*.lua'
