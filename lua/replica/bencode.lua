local module = {}

-- N.B message can be bytes, string, integer, array, object/map containing any combination of the rest!
module.type_encoders = {
  number = function(n)
    return "i"..n.."e"
  end,
  string = function(s)
    return string.len(s) .. ":" .. s
  end,
  -- Arrays and Dictionaries are both Tables in Lua We assume number indexed Tables are in fact Arrays and are encoded
  -- as such.
  table = function(t)
    if t[1] == nil then
      local out_dict = "d"
      for k, v in pairs(t) do
        out_dict = out_dict .. module.encode(k) .. module.encode(v) 
      end
      return out_dict .. "e"
    else
      local out_list = "l"
      for _, v in pairs(t) do
        out_list = out_list .. module.encode(v) 
      end
      return out_list .. "e"
    end
  end,
}

module.encode = function(message)
  local type_encoder = module.type_encoders[type(message)]

  if type(type_encoder) == 'function' then
    return module.type_encoders[type(message)](message)
  else
    return "not sure what to do with message type: " .. type(message)
  end
end

-- functions to remove each type from the front of an bencoded message
module.type_pop = {
  dictionary = function(dmsg)
    return string.sub(dmsg, 2, -2)
  end,
  list = function(lmsg)
    return string.sub(lmsg, 2, -2)
  end,
  string = function(smsg)
    local number_length = (string.find(smsg, ":")[1])
    local string_msg_length = tonumber(string.sub(smsg, 1, string.len(smsg) - number_length))
    return string.sub(smsg, 1, string_msg_length + number_length + 1)
  end,
  integer = function(imsg)
    -- TODO wrong, we need to search until we hit the non-numerical value after i
    return string.sub(imsg, 2, -2)
  end,
}

module.type_decoders = {
  string = function(s_msg)
    local s_start, s_end = string.find(s_msg, ":")
    local string_length = tonumber(string.sub(s_msg, 1, s_start - 1))
    -- + 1 to accomodate the : delimiter
    return string.sub(s_msg, s_end + 1, s_end + string_length)
  end
}

module.detect_type = function(bmessage)
  local next_char = string.sub(bmessage, 1, 1)

  if next_char == "d" then
    return "dictionary"
  elseif next_char == "l" then
    return "list"
  elseif tonumber(next_char) ~= nil then -- is a number?
    return "string"
  elseif next_char == "i" then
    return "integer"
  else
    return "could not detect type from next character; " .. next_char
  end
end

module.decode = function(bmessage)
  return module.type_decoders[module.detect_type(bmessage)](bmessage)
end

-- module.type_decoders = {
--   dictionary = function(d)
--     -- ignore first char (should be d)
--     -- ignore last char (should be e)
--     -- recall decode on the internal?
--     local raw_content = string.sub(d, 2, -2)
-- 
--     while raw_content ~= "" do
-- 
--     end
-- 
--     -- local content = module.decode(dict_content)
--     return 'dict!'
--   end,
--   list = function(d)
--     return 'list!'
--   end,
--   string = function(d)
--     return 'string!'
--   end,
--   integer = function(d)
--     return 'integer!'
--   end,
-- }
-- 
-- module.detect_type = function(next_char)
--   if next_char == "d" then
--     return "dictionary"
--   elseif next_char == "l" then
--     return "list"
--   elseif tonumber(next_char) ~= nil then -- is a number?
--     return "string"
--   elseif next_char == "i" then
--     return "integer"
--   else
--     return "could not detect type from next character; " .. next_char
--   end
-- end
-- 
-- module.decode = function(bmessage)
--   first_char = string.sub(bmessage, 1, 1)
-- 
--   module.type_decoders[module.detect_type(first_char)](bmessage)
-- end

return module
