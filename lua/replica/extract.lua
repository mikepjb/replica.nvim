local ts_utils = nil
local module = {}
local treesitter = {}

treesitter.enabled = function()
  local noerr, tsu = pcall(function ()
    return require("nvim-treesitter.ts_utils")
  end)
  if noerr then
    ts_utils = tsu
    return true
  else
    return false
  end
end

-- form returns an sexp as a string to send for evaluation (by default the sexp under cursor)
module.form = function() -- TODO take opts?
  if treesitter.enabled() then
    -- TODO currently requires you to be hovering an sexp, this can be improved
    -- Range returns 4 integers, start_row, start_column, end_row, end_column
    local srow, scol, erow, ecol = ts_utils.get_node_at_cursor():range()
    local sexp = ""
    for _, line in ipairs(vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})) do
      sexp = sexp .. line .. "\n"
    end
    return sexp
  end
end

return module
