local util = require("replica.util")

local trim = util.trim

local module = {}

module.debug_enabled = false

module.debug = function(message)
  if module.debug_enabled then
    local log_file_path = './replica.log'
    local log_file = io.open(log_file_path, "a")
    io.output(log_file)
    if type(message) == "table" then
      io.write(vim.inspect(message))
    else
      io.write(message.."\n")
    end
    io.close(log_file)
  end
end

log_message = function(message, level)
  vim.schedule(function()
    if level == vim.log.levels.INFO then
      print(message)
      -- vim.notify(trim(vim.inspect(message)), level)
    else
      vim.notify(trim(vim.inspect(message)), level)
    end
  end)
end

module.info = function(message)
  log_message(message, vim.log.levels.INFO)
end

module.error = function(message)
  log_message(message, vim.log.levels.ERROR)
end

module.setup = function(config)
  module.debug_enabled = config.debug
end

return module
