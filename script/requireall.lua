require("requireall").execute({
  module_filter = function(module_path)
    if module_path:find("%.test%.helper") then
      return false
    end
    if module_path:find("vusted") then
      return false
    end
    return true
  end,
})
