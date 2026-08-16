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
-- documents, so a missing one can be told from it only for a name the plugin
-- owns - and it owns the case variants too, since a type is tagged `NameInfo`.
-- NOT: requiring every link to be defined here, which reads each link into the
-- runtime help as broken.
--- @param help GeneratedHelp
--- @param prefixes string[] what a link this plugin owns starts with
--- @param tags table<string, true> every tag these documents define
local function assert_tag_links(help, prefixes, tags)
  each_capture(help, "(taglink (word) @link)", function(node)
    local link = vim.treesitter.get_node_text(node, help.text)
    local owned = vim.iter(prefixes):any(function(prefix)
      return vim.startswith(link, prefix)
    end)
    if owned and not tags[link] then
      error(("%s links to a tag it does not define: %s"):format(help.path, link))
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
local tags = {}
for _, help in ipairs(helps) do
  each_capture(help, "(tag (word) @tag)", function(node)
    tags[vim.treesitter.get_node_text(node, help.text)] = true
  end)
end

local plugin_name = assert(vim.env.PLUGIN_NAME, "PLUGIN_NAME is required")
local prefixes = { plugin_name, plugin_name:sub(1, 1):upper() .. plugin_name:sub(2), plugin_name:upper() }

for _, help in ipairs(helps) do
  assert_code_blocks(help)
  assert_tag_links(help, prefixes, tags)
end
