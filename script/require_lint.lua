--- A rule entry in the REQUIRE_LINT_CONFIG json.
--- All prefixes are module paths matched at dot boundaries.
--- @class RequireLintRuleBase
--- @field from string importer module prefix the rule applies to
--- @field message string? why the rule exists, shown along with the violation

--- @class RequireLintAllowRule : RequireLintRuleBase
--- @field allow string[] within `from`'s top namespace, requiring a target matching none of these is forbidden
--- @field forbid nil

--- @class RequireLintForbidRule : RequireLintRuleBase
--- @field allow nil
--- @field forbid string[] requiring a target matching any of these is forbidden

--- @alias RequireLintRule RequireLintAllowRule|RequireLintForbidRule

--- @class RequireLintConfig
--- @field rules RequireLintRule[]?

--- @param module string
--- @param prefix string
--- @return boolean
local function matches_prefix(module, prefix)
  return module == prefix or module:sub(1, #prefix + 1) == prefix .. "."
end

--- @param target string required module path
--- @param rule RequireLintRule
--- @return boolean forbidden
local function is_forbidden(target, rule)
  if rule.forbid then
    return vim.iter(rule.forbid):any(function(prefix)
      return matches_prefix(target, prefix)
    end)
  end
  local top = rule.from:match("^[^.]+")
  if not matches_prefix(target, top) then
    return false
  end
  return not vim.iter(rule.allow):any(function(prefix)
    return matches_prefix(target, prefix)
  end)
end

--- @param path string absolute file path under `lua/`
--- @param lua_dir string absolute `lua/` directory
--- @return string module path
local function to_module(path, lua_dir)
  local rel = path:sub(#lua_dir + 2):gsub("%.lua$", "")
  rel = rel:gsub("/init$", "")
  return (rel:gsub("/", "."))
end

--- @param path string
--- @return RequireLintRule[]
local function load_rules(path)
  --- @type RequireLintConfig
  local config = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  local rules = config.rules or {}
  for _, rule in ipairs(rules) do
    if not rule.from or (rule.allow == nil) == (rule.forbid == nil) then
      error(("each rule needs `from` and exactly one of `allow`/`forbid`: %s"):format(vim.inspect(rule)))
    end
  end
  return rules
end

local config_path = vim.env.REQUIRE_LINT_CONFIG
if not config_path or config_path == "" then
  os.exit(0)
end
local rules = load_rules(config_path)
if #rules == 0 then
  os.exit(0)
end

local lua_dir = vim.fs.joinpath(vim.fn.getcwd(), "lua")
local files = vim.fn.glob(vim.fs.joinpath(lua_dir, "**", "*.lua"), false, true)

local violations = {}
for _, path in ipairs(files) do
  local module = to_module(path, lua_dir)
  local applicable = vim
    .iter(rules)
    :filter(function(rule)
      return matches_prefix(module, rule.from)
    end)
    :totable()
  if #applicable > 0 then
    local lines = vim.fn.readfile(path)
    for lineno, line in ipairs(lines) do
      for target in line:gmatch("require%(%s*['\"]([%w%._%-]+)['\"]") do
        for _, rule in ipairs(applicable) do
          if is_forbidden(target, rule) then
            local kind = rule.forbid and ("forbid " .. table.concat(rule.forbid, ","))
              or ("allow " .. table.concat(rule.allow, ","))
            local reason = rule.message and (": " .. rule.message) or ""
            table.insert(
              violations,
              ("%s:%d: %s requires %s (rule: from %s, %s)%s"):format(
                path,
                lineno,
                module,
                target,
                rule.from,
                kind,
                reason
              )
            )
          end
        end
      end
    end
  end
end

if #violations > 0 then
  io.stderr:write(table.concat(violations, "\n") .. "\n")
  os.exit(1)
end
os.exit(0)
