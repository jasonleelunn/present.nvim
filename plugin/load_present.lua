vim.api.nvim_create_user_command("PresentStart", function(context)
  local filepath = context.args
  local start = require("present").start_presentation

  if #filepath > 0 then
    start({ filepath = filepath })
  else
    start()
  end
end, { complete = "file", nargs = "?" })
