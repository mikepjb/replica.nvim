-- Namespace centered around gathering/using knowledge about Clojure systems.

local module = {}
local gsub, sub, find = string.gsub, string.sub, string.find

module.discover_nrepl_port = function()
    -- TODO filereadable succeeds even if the file is not around, needs fixing.
    if vim.fn.filereadable(".nrepl-port") then
      local nrepl_port = tonumber(vim.fn.readfile(".nrepl-port")[1])
      return nrepl_port
    else
      return nil
    end
end

module.is_cljs = function(filepath)
  local filepath = filepath or vim.fn.expand("%:p")
  return find(filepath, ".cljs$") ~= nil
end

-- TODO (java.lang.System/getProperty "java.class.path") should be able to help here.
module.namespace = function(filepath)
  -- TODO handle case where you are doing this is an unnamed buffer?
  -- based on filepath
  -- local filetype = vim.bo.filetype
  local full_filepath = vim.fn.expand('%:p')
  if filepath == nil then
    filepath = full_filepath
  end

  local filepath_no_ext
  if find(filepath, ".clj$") then
    filepath_no_ext = sub(filepath, 0, -5)
  elseif find(filepath, ".cljs$") then
    filepath_no_ext = sub(filepath, 0, -6)
  elseif find(filepath, ".cljc$") then
    filepath_no_ext = sub(filepath, 0, -6)
  else
    filepath_no_ext = filepath
  end

  -- strip prefix based on project paths (or guessed src/clj src/cljs paths)
  local a, b, _

  -- N.B Lua does not implement a POSIX regex engine so we use conditionals to iterate all the possible variations.
  -- TODO need to pull down project path folders incase the user works with different folder names!
  if find(filepath_no_ext, "src/clj/") then
    a, b, _ = find(filepath_no_ext, "^.*src/clj/", 0)
  elseif find(filepath_no_ext, "src/cljs/") then
    a, b, _ = find(filepath_no_ext, "^.*src/cljs/", 0)
  -- TODO hardcoding to work with replica.nvim structure
  elseif find(filepath_no_ext, "tests/cljs/") then
    a, b, _ = find(filepath_no_ext, "^.*tests/cljs/", 0)
  elseif find(filepath_no_ext, "src/cljc/") then
    a, b, _ = find(filepath_no_ext, "^.*src/cljc/", 0)
  elseif find(filepath_no_ext, "dev/") then
    a, b, _ = find(filepath_no_ext, "^.*dev/", 0)
  else
    a, b, _ = find(filepath_no_ext, "^.*src/", 0)
  end

  local fp_dots = gsub(sub(filepath_no_ext, b + 1), "/", ".")
  local fp_hyphens = gsub(fp_dots, "_", "-")

  return fp_hyphens
end

return module
