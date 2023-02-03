local module = {}

module.setup = function()
  -- local cmd = nvim_create_user_command

  -- cmd("Connect" 'echo "Hello world!"', {})
  vim.api.nvim_create_user_command("Connect", 'echo "Hello world!"', {})
  return
end

return module
