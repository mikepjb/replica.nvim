repl:
	clojure -M:nrepl:figwheel

test:
	make clean
	nvim --headless --clean --noplugin \
		-u "./tests/minimal_init.vim" \
		-c "PlenaryBustedDirectory ./tests/replica/ { minimal_init = './tests/minimal_init.vim' }"

clean:
	# Cleans temporary file store
	rm -rf ~/.local/state/nvim/shada/*

todo:
	rg "(TODO|XXX)" -g '*.lua'
