test:
	nvim --version

ci: test

git_hooks:
	cp script/git-hooks/commit-msg "$$(git rev-parse --git-path hooks)/commit-msg"
	chmod +x "$$(git rev-parse --git-path hooks)/commit-msg"
