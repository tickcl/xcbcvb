__scriptable_map = __scriptable_map or {}

local function mkid(obj) return tostring(obj) end

local function ensure_mt_wrapped(obj)
  if type(getrawmetatable) ~= "function" then return end
  local mt = getrawmetatable(obj)
  if type(mt) ~= "table" then return end
  if mt.____scriptable_wrapped then return end

  local orig_index = mt.__index
  local orig_newindex = mt.__newindex

  local function safe_index(self, key)
    if type(orig_index) == "function" then
      local ok, res = pcall(orig_index, self, key)
      if ok then return res end
    else
      if type(orig_index) == "table" then
        local ok2, val = pcall(function() return orig_index[key] end)
        if ok2 then return val end
      end
    end

    local id = mkid(self)
    local t = __scriptable_map[id]
    if t and t[key] then
      return 0
    end

    error("attempt to index a non-existing member", 2)
  end

  local function safe_newindex(self, key, value)
    if type(orig_newindex) == "function" then
      local ok, err = pcall(orig_newindex, self, key, value)
      if ok then return end
    else
      if type(orig_newindex) == "table" then
        local ok2, _ = pcall(function() orig_newindex[key] = value end)
        if ok2 then return end
      end
    end

    local id = mkid(self)
    local t = __scriptable_map[id]
    if t and t[key] then
      return
    end

    error("attempt to write to non-existing member", 2)
  end

  if type(setreadonly) == "function" then
    pcall(setreadonly, mt, false)
  end

  mt.__index = safe_index
  mt.__newindex = safe_newindex
  mt.___orig_index = orig_index
  mt.___orig_newindex = orig_newindex
  mt.____scriptable_wrapped = true

  if type(setreadonly) == "function" then
    pcall(setreadonly, mt, true)
  end
end

function __setscriptable_helper(obj, prop, make)
  if type(prop) ~= "string" then error("bad argument #2 (string expected)", 2) end
  local id = mkid(obj)
  local prev = false
  __scriptable_map[id] = __scriptable_map[id] or {}
  prev = __scriptable_map[id][prop] and true or false

  if make then __scriptable_map[id][prop] = true else __scriptable_map[id][prop] = nil end

  pcall(ensure_mt_wrapped, obj)

  return prev
end

function __is_scriptable_helper(obj, prop)
  if type(prop) ~= "string" then error("bad argument #2 (string expected)", 2) end
  local id = mkid(obj)
  if __scriptable_map[id] and __scriptable_map[id][prop] then return true end
  return false
end
