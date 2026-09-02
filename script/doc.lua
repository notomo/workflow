vim.opt.packpath:prepend(vim.env.TESTPACK_PACKPATH)
vim.opt.runtimepath:prepend(vim.fn.getcwd())

dofile(vim.env.DOC_SOURCE)

--- @class GeneratedHelp
--- @field path string
--- @field text string
--- @field root TSNode

--- @param help GeneratedHelp
--- @param query string
--- @param f fun(node: TSNode)
local function each_capture(help, query, f)
  for _, node in vim.treesitter.query.parse("vimdoc", query):iter_captures(help.root, help.text) do
    f(node)
  end
end

-- WHY: a `>` on the line right after a list item is read as more of that item,
-- so the block is shown with its markers instead of as code, which only the
-- help parser can say - the text alone looks like every other block.
-- NOT: reading the rendered help, which is where this was first noticed.
--- @param help GeneratedHelp
local function assert_code_blocks(help)
  --- @type table<integer, true> every row a code block the help parser sees covers
  local code_block_rows = {}
  each_capture(help, "(codeblock) @block", function(node)
    local start_row, _, end_row, end_column = node:range()
    local last_row = end_column == 0 and end_row or end_row + 1
    for row = start_row + 1, last_row do
      code_block_rows[row] = true
    end
  end)
  for row, line in ipairs(vim.split(help.text, "\n")) do
    if vim.startswith(line, ">") and not code_block_rows[row] then
      error(("%s:%d opens a code block the help parser does not see: %s"):format(help.path, row, line))
    end
  end
end

-- WHY: a link to a tag the runtime defines (`|:lcd|`) resolves outside these
-- documents, so every tag file on the runtimepath answers for a link too.
-- NOT: the plugin's own doc/tags, a `:helptags` leftover that is not committed,
-- which would answer for a tag these documents no longer define.
--- @return table<string, true> every tag the runtime help defines
local function collect_runtime_tags()
  local cwd = vim.fn.getcwd()
  local tags = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file("doc/tags", true)) do
    if not vim.startswith(vim.fs.abspath(path), cwd) then
      for _, line in ipairs(vim.fn.readfile(path)) do
        tags[vim.split(line, "\t")[1]] = true
      end
    end
  end
  return tags
end

-- WHY: a link resolves to a tag or it is broken, wherever the tag lives, so a
-- name no document defines is a typo - `|statusline|` for `|'statusline'|` and
-- `|nvim_set_hl|` for `|nvim_set_hl()|` are what this catches.
-- NOT: only checking the names the plugin owns, which passes every typo in a
-- link to the runtime help.
--- @param help GeneratedHelp
--- @param tags table<string, true> every tag these documents and the runtime define
local function assert_tag_links(help, tags)
  each_capture(help, "(taglink (word) @link)", function(node)
    local link = vim.treesitter.get_node_text(node, help.text)
    if not tags[link] then
      error(("%s links to a tag nothing defines: %s"):format(help.path, link))
    end
  end)
end

--- @type GeneratedHelp[]
local helps = {}
for _, path in ipairs(vim.fn.glob("./doc/*.txt", false, true)) do
  local text = table.concat(vim.fn.readfile(path), "\n")
  local root = assert(vim.treesitter.get_string_parser(text, "vimdoc"):parse())[1]:root()
  table.insert(helps, { path = path, text = text, root = root })
end

--- @type table<string, true>
local tags = collect_runtime_tags()
for _, help in ipairs(helps) do
  each_capture(help, "(tag (word) @tag)", function(node)
    tags[vim.treesitter.get_node_text(node, help.text)] = true
  end)
end

for _, help in ipairs(helps) do
  assert_code_blocks(help)
  assert_tag_links(help, tags)
end
