-- Namespace centered around gathering/using knowledge about Clojure systems.

local module = {}

local gsub, sub, find, gmatch = string.gsub, string.sub, string.find, string.gmatch
local insert = table.insert


module.paths_query = "(java.lang.System/getProperty \"java.class.path\")"
module.pwd_query = "(java.lang.System/getProperty \"user.dir\")"

module.user_paths = function(raw_path_string)
  local paths = {}
  for path in gmatch(raw_path_string, '([^:]+)') do
    if not find(path, ".jar$") then
      insert(paths, path)
    end
  end
  return paths
end

module.discover_nrepl_port = function()
  -- TODO filereadable succeeds even if the file is not around, needs fixing.
  -- if vim.fn.filereadable(".nrepl-port") then
  -- TODO I don't like that this uses io.open and then vim.fn.readfile seperately..
  local port_file = io.open(".nrepl-port", r)
  if port_file ~= nil then
    return tonumber(vim.fn.readfile(".nrepl-port")[1])
  else
    return nil
  end
end

-- TODO project does not need to mention shadow/figwheel directly e.g abstracted common repo
-- module.discover_cljs_build_tool = function()
-- end

module.is_cljs = function(filepath)
  local filepath = filepath or vim.fn.expand("%:p")
  return find(filepath, ".cljs$") ~= nil
end

module.namespace = function(connection, filepath)
  local full_filepath = vim.fn.expand('%:p')

  if filepath == nil and full_filepath == nil then
    return "user" -- if no filepath given and we're in an empty buffer
  elseif filepath == nil then
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

  local fp_no_ext_no_pwd = gsub(filepath_no_ext, connection.pwd, "")

  local _, match_end

  -- N.B Lua does not implement a POSIX regex engine so we use conditionals to iterate all the possible variations.
  for _, path in ipairs(connection.paths) do
    if find(fp_no_ext_no_pwd, path .. "/") then
      _, match_end = find(fp_no_ext_no_pwd, path .. "/") 
      break
    end
  end

  local fp_without_source_path = sub(fp_no_ext_no_pwd, match_end + 1)
  local fp_dots = gsub(fp_without_source_path, "/", ".")
  local fp_hyphens = gsub(fp_dots, "_", "-")

  return fp_hyphens
end

return module
