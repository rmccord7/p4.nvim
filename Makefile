lint:
	@printf "\nRunning luacheck\n"
	luacheck lua/*
	@printf "\nRunning stylua\n"
	stylua --check .

.PHONY: lint

