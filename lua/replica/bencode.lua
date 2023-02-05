local module = {}

-- TODO cleanup
local sort, concat, insert = table.sort, table.concat, table.insert
local pairs, ipairs, type, tonumber = pairs, ipairs, type, tonumber
local sub, find, len = string.sub, string.find, string.len

-- N.B message can be bytes, string, integer, array, object/map containing any combination of the rest!
module.type_encoders = {
  number = function(n)
    return "i"..n.."e"
  end,
  string = function(s)
    return len(s) .. ":" .. s
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

module.detect_type = function(char)
  if char == "i" then return "integer"
  elseif char == "l" then return "list"
  elseif char == "d" then return "dictionary"
  elseif char >= '0' and char <= '9' then return "string"
  else return "unknown"
  end
end

module.type_decoders = {
  integer = function(m, i)
    return nil, "unknown type", m
  end,
  list = function(m, i)
    return nil, "unknown type", m
  end,
  dictionary = function(m, i)
    return nil, "unknown type", m
  end,
  string = function(m, i)
    return nil, "unknown type", m
  end,
  unknown = function(m, i)
    return nil, "unknown type", m
  end
}

module.decode = function(message, index)
  if not message then
    return nil, "no data", nil
  end

  -- index is the position of the message we are currently parsing
  local index = index or 1

  local next_char = sub(message, index, index)
  if len(next_char) == 0 then return nil, "truncation error", nil end
  if not next_char then return nil, "truncation error", nil end

  return module.type_decoders[module.detect_type(next_char)](message, index + 1)
end

return module
