--- @class DocConfigSource
--- @field patterns string[]? globs relative to cwd whose lua doc feeds document generation, so `---` lines in them are not linted

--- @class DocConfig
--- @field source DocConfigSource?

local GUIDE = [[

instructions:
- delete the comment. it restates the code and drifts away from it. express what it says as a test, a type annotation or a better name instead, and keep a comment only if a reader would otherwise undo the decision.
- a kept comment must be in English and in this form, where `NOT:` is optional and each entry may continue onto the following comment lines:
    -- WHY: {reason}
    -- NOT: {rejected alternative}
- type annotations are allowed. write descriptions on the annotation line itself, not as prose lines.
]]

--- @param path string
--- @return string[] doc source globs
local function load_doc_source_patterns(path)
  if not path or path == "" then
    return {}
  end
  --- @type DocConfig
  local config = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  local patterns = (config.source or {}).patterns or {}
  if not vim.islist(patterns) then
    error(("`source.patterns` must be a list: %s"):format(vim.inspect(patterns)))
  end
  return patterns
end

local cwd = vim.fn.getcwd()

--- @param path string absolute path
--- @return string path relative to cwd
local function to_relative(path)
  return path:sub(#cwd + 2)
end

--- @param patterns string[]
--- @return table<string,boolean> paths relative to cwd
local function expand_patterns(patterns)
  local paths = {}
  for _, pattern in ipairs(patterns) do
    for _, path in ipairs(vim.fn.glob(vim.fs.joinpath(cwd, pattern), false, true)) do
      paths[to_relative(path)] = true
    end
  end
  return paths
end

--- @return string[] paths relative to cwd
local function collect_files()
  local files = {}
  for _, path in ipairs(vim.fn.glob(vim.fs.joinpath(cwd, "lua", "**", "*.lua"), false, true)) do
    local relative = to_relative(path)
    if not relative:find("/vendor/", 1, true) then
      table.insert(files, relative)
    end
  end
  table.sort(files)
  return files
end

--- @class CommentLintComment
--- @field row integer 1-based line number
--- @field text string whole comment text
--- @field luadoc boolean starts with `---`
--- @field own_line boolean nothing but indent before the comment
--- @field multiline boolean `--[[ ]]` form

--- @param src string
--- @param lines string[]
--- @return CommentLintComment[] sorted by position
local function collect_comments(src, lines)
  local root = vim.treesitter.get_string_parser(src, "lua"):parse()[1]:root()

  local comments = {}
  local function walk(node)
    if node:type() == "comment" then
      local start_row, start_col, end_row = node:range()
      local text = vim.treesitter.get_node_text(node, src)
      table.insert(comments, {
        row = start_row + 1,
        text = text,
        luadoc = text:match("^%-%-%-") ~= nil,
        own_line = lines[start_row + 1]:sub(1, start_col):match("^%s*$") ~= nil,
        multiline = end_row ~= start_row,
      })
    end
    for child in node:iter_children() do
      walk(child)
    end
  end
  walk(root)

  table.sort(comments, function(a, b)
    return a.row < b.row
  end)
  return comments
end

--- @param previous CommentLintComment
--- @param comment CommentLintComment
--- @return boolean
local function continues(previous, comment)
  return not previous.multiline
    and not comment.multiline
    and previous.own_line
    and comment.own_line
    and previous.luadoc == comment.luadoc
    and previous.row + 1 == comment.row
end

--- Consecutive own-line comments of the same kind form one block.
--- @param comments CommentLintComment[]
--- @return CommentLintComment[][]
local function to_blocks(comments)
  local blocks = {}
  for _, comment in ipairs(comments) do
    local block = blocks[#blocks]
    if block and continues(block[#block], comment) then
      table.insert(block, comment)
    else
      table.insert(blocks, { comment })
    end
  end
  return blocks
end

--- @param text string
--- @return boolean
local function is_tool_directive(text)
  local content = text:gsub("^%-%-+%s*", "")
  return content:match("^@diagnostic%s") ~= nil
    or content:match("^stylua:%s") ~= nil
    or content:match("^luacheck:%s") ~= nil
    or content:match("^selene:%s") ~= nil
end

--- @param block CommentLintComment[]
--- @return {row:integer,message:string}[]
local function check_luadoc_block(block)
  local violations = {}
  local annotated = false
  for _, comment in ipairs(block) do
    local content = comment.text:gsub("^%-%-%-", "")
    if content:match("^%s*@") then
      annotated = true
    elseif not annotated then
      violations[#violations + 1] = {
        row = comment.row,
        message = ("lua doc prose without an annotation: %s"):format(comment.text),
      }
    end
  end
  return violations
end

--- @param block CommentLintComment[]
--- @return {row:integer,message:string}[]
local function check_plain_block(block)
  local first = block[1]
  if first.multiline then
    return { { row = first.row, message = ("block comment: %s"):format(vim.split(first.text, "\n")[1]) } }
  end
  if #block == 1 and is_tool_directive(first.text) then
    return {}
  end

  local violations = {}
  if not first.text:gsub("^%-%-+%s*", ""):match("^WHY:%s*%S") then
    violations[#violations + 1] = {
      row = first.row,
      message = ("comment does not start with `WHY: {reason}`: %s"):format(first.text),
    }
  end
  for _, comment in ipairs(vim.list_slice(block, 2)) do
    local content = comment.text:gsub("^%-%-+%s*", "")
    if content:match("^WHY:") then
      violations[#violations + 1] = {
        row = comment.row,
        message = ("second `WHY:` in one comment block, split it into its own block: %s"):format(comment.text),
      }
    elseif content:match("^NOT:") and not content:match("^NOT:%s*%S") then
      violations[#violations + 1] = {
        row = comment.row,
        message = ("`NOT:` without a rejected alternative: %s"):format(comment.text),
      }
    end
  end
  return violations
end

--- @param path string relative to cwd
--- @param doc_sources table<string,boolean> paths relative to cwd
--- @return string[]
local function check_file(path, doc_sources)
  local lines = vim.fn.readfile(path)
  local src = table.concat(lines, "\n")

  local violations = {}
  for _, block in ipairs(to_blocks(collect_comments(src, lines))) do
    local checked
    if not block[1].luadoc then
      checked = check_plain_block(block)
    elseif doc_sources[path] then
      checked = {}
    else
      checked = check_luadoc_block(block)
    end
    for _, violation in ipairs(checked) do
      table.insert(violations, ("%s:%d: %s"):format(path, violation.row, violation.message))
    end
  end
  return violations
end

local doc_sources = expand_patterns(load_doc_source_patterns(vim.env.DOC_CONFIG))

local violations = {}
for _, path in ipairs(collect_files()) do
  vim.list_extend(violations, check_file(path, doc_sources))
end

if #violations > 0 then
  io.stderr:write(table.concat(violations, "\n") .. "\n" .. GUIDE)
  os.exit(1)
end
os.exit(0)
