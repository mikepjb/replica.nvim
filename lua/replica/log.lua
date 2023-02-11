local module = {}

module.debug = function(message)
  if debug then
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

module.info = function(message)
  vim.schedule(function()
    vim.notify(trim(message), vim.log.levels.INFO)
  end)
end

module.error = function(message)
  vim.schedule(function()
    vim.notify(trim(message), vim.log.levels.ERROR)
  end)
end

return module
