vim.opt.packpath:prepend(vim.fs.joinpath(vim.fn.getcwd(), "spec/.shared/packages"))
vim.opt.runtimepath:prepend(vim.fn.getcwd())

require("requireall").execute({
  module_filter = function(module_path)
    local ignore = vim
      .iter(vim.split(vim.env.REQUIREALL_IGNORE_MODULES or "", ",", { plain = true, trimempty = true }))
      :any(function(x)
        local found = module_path:find(x)
        return found ~= nil
      end)
    if ignore then
      return false
    end
    if module_path:find("%.test%.helper") then
      return false
    end
    if module_path:find("vusted") then
      return false
    end
    return true
  end,
})
