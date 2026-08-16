vim.opt.packpath:prepend(vim.env.TESTPACK_PACKPATH)
vim.opt.runtimepath:prepend(vim.fn.getcwd())

dofile(vim.env.DOC_SOURCE)

-- WHY: a `>` on the line right after a list item is read as more of that item,
-- so the block is shown with its markers instead of as code, which only the
-- help parser can say - the text alone looks like every other block.
-- NOT: reading the rendered help, which is where this was first noticed.
--- @param path string a generated help file
local function assert_code_blocks(path)
  local text = table.concat(vim.fn.readfile(path), "\n")
  local root = assert(vim.treesitter.get_string_parser(text, "vimdoc"):parse())[1]:root()
  --- @type table<integer, true> every row a code block the help parser sees covers
  local code_block_rows = {}
  for _, node in vim.treesitter.query.parse("vimdoc", "(codeblock) @block"):iter_captures(root, text) do
    local start_row, _, end_row, end_column = node:range()
    local last_row = end_column == 0 and end_row or end_row + 1
    for row = start_row + 1, last_row do
      code_block_rows[row] = true
    end
  end
  for row, line in ipairs(vim.split(text, "\n")) do
    if vim.startswith(line, ">") and not code_block_rows[row] then
      error(("%s:%d opens a code block the help parser does not see: %s"):format(path, row, line))
    end
  end
end

for _, path in ipairs(vim.fn.glob("./doc/*.txt", false, true)) do
  assert_code_blocks(path)
end
