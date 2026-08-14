vim.opt.packpath:prepend(vim.env.TESTPACK_PACKPATH)
vim.opt.runtimepath:prepend(vim.fn.getcwd())

dofile(vim.env.DOC_SOURCE)
