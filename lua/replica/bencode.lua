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
    local i = i + 1 -- skip 'i'
    local a, b, int = find(m, "^(%-?%d+)e", i)
    if not int then return nil, "not a number", nil end
    local int = tonumber(int)
    if not int then return nil, "not a number", nil end
    return int, b + 1
  end,
  list = function(m, i)
    local i = i + 1 -- skip 'l'
    local t = {}

    while sub(m, i, i) ~= "e" do
      local e, ev
      e, i, ev = module.decode(m, i)
      if not e then return e, i, ev end
      insert(t, e)
    end

    index = i + 1 -- skip 'e'
    return t, index
  end,
  dictionary = function(m, i)
    local i = i + 1 -- skip 'd'
    local t = {}

    while sub(m, i, i) ~= "e" do
      local key, value, ev

      key, i, ev = module.decode(m, i)
      if not key then return key, i, ev end

      value, i, ev = module.decode(m, i)
      if not value then return value, i, ev end

      t[key] = value
    end

    i = i + 1 -- skip closing 'e'
    return t, i
  end,
  string = function(m, i)
    local a, b, length = find(m, "^([0-9]+):", i)
    if not length then return nil, "no length detected", length end
    local index = b + 1

    local value = sub(m, index, index + length -1)
    if #value < length - 1 then return nil, "truncated string at end of input", value end
    index = index + length
    return value, index
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

  return module.type_decoders[module.detect_type(next_char)](message, index)
end

-- decoder is a stateful wrapper around the decode function because of the way messages are/can be sent as incomplete
-- chunks over the network so we need a place to store them.
module.decoder = function()
  local buffer = ""

  -- N.B there is an assumption 
  local decode = function(chunk, acc)
    buffer = buffer .. chunk
    local message, index = module.decode(buffer)

    if message then
      insert(acc, message)
    end

    if index > len(buffer) then -- there is more than one message in the buffer
      buffer = sub(buffer, index)
      decode(buffer, acc)
    elseif index == len(buffer) then -- we have a complete set of messages
      buffer = ""
      return acc
    else -- there is less than a complete message remaining, keep that in buffer
      return acc
    end
  end

  return decode
end

return module
