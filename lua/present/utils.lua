local M = {}

M.foreach = function(list, cb)
  for name, float in pairs(list) do
    cb(name, float)
  end
end

return M
