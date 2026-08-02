local data_root = vim.fs.joinpath(vim.fn.getcwd(), "spec")

--- @param path string
local function delete(path)
  if vim.fn.delete(path, "rf") == -1 then
    error("failed to delete: " .. path)
  end
end

return {
  teardown = function()
    for name, entry_type in vim.fs.dir(data_root) do
      if entry_type == "directory" and name:find("^%.test_data") then
        delete(vim.fs.joinpath(data_root, name))
      end
    end
  end,
}
