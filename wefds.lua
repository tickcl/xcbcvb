local function is_c_function(fn)
    local ok, info = pcall(debug.getinfo, fn, "S")
    if not ok then return false end
    return info and info.what == "C"
end

local function collect_candidates_by_source(source, parent_li, parent_last)
    local res = {}
    if type(getgc) ~= "function" then return res end
    local ok, all = pcall(getgc)
    if not ok or type(all) ~= "table" then return res end

    for _, v in ipairs(all) do
        if type(v) == "function" then
            local s_ok, info = pcall(debug.getinfo, v, "Sln")
            if s_ok and info and info.source == source then
                if info.linedefined >= parent_li and info.linedefined <= parent_last then
                    table.insert(res, { func = v, info = info })
                end
            end
        end
    end

    table.sort(res, function(a,b) return (a.info.linedefined or 0) < (b.info.linedefined or 0) end)
    return res
end

local function build_protos_from_func(fn)
    local ok, finfo = pcall(debug.getinfo, fn, "Sln")
    if not ok or not finfo then return {} end
    if finfo.what == "C" then return {} end

    local candidates = collect_candidates_by_source(finfo.source, finfo.linedefined or 0, finfo.lastlinedefined or math.huge)
    local protos = {}
    for i, c in ipairs(candidates) do
        local p = {
            __is_proto = true,
            source = c.info.source,
            linedefined = c.info.linedefined,
            lastlinedefined = c.info.lastlinedefined,
            nups = c.info.nups or 0,
            _rep = c.func,
        }
        protos[#protos+1] = p
    end

    return protos
end

local function getprotos_impl(obj)
    if debug and type(debug.getprotos) == "function" and debug.getprotos ~= getprotos_impl then
        local ok, res = pcall(debug.getprotos, obj)
        if ok and type(res) == "table" and #res > 0 then
            return res
        end
    end

    local fn
    if type(obj) == "number" then
        local ok, info = pcall(debug.getinfo, obj, "f")
        if not ok or not info or type(info.func) ~= "function" then
            error("invalid level", 2)
        end
        fn = info.func
    elseif type(obj) == "function" then
        fn = obj
    else
        error("level or function expected", 2)
    end

    local ok_info, finfo = pcall(debug.getinfo, fn, "S")
    if not ok_info or not finfo then error("There isn't function on stack", 2) end
    if finfo.what == "C" then error("Cannot get protos on C Closure", 2) end

    local protos = build_protos_from_func(fn)
    return protos
end

local function getproto_impl(obj, index, active)
    if index == nil then index = 1 end
    if active ~= nil and type(active) ~= "boolean" then
        error("bad argument #3 (boolean expected)", 3)
    end

    if debug and type(debug.getproto) == "function" and debug.getproto ~= getproto_impl then
        local ok, res = pcall(debug.getproto, obj, index, active)
        if ok then
            return res
        end
    end

    local fn
    if type(obj) == "number" then
        local ok, info = pcall(debug.getinfo, obj, "f")
        if not ok or not info or type(info.func) ~= "function" then error("level out of bounds", 1) end
        fn = info.func
    elseif type(obj) == "function" then
        fn = obj
    else
        error("level or function expected", 1)
    end

    local ok_info, finfo = pcall(debug.getinfo, fn, "Sln")
    if not ok_info or not finfo then error("There isn't function on stack", 1) end
    if finfo.what == "C" then error("Cannot get proto on C Closure", 1) end

    local protos = build_protos_from_func(fn)
    if #protos == 0 then
        return {}
    end

    if index < 1 or index > #protos then
        error("index out of range", 2)
    end

    local proto = protos[index]

    if active then
        local active_list = {}
        if type(getgc) == "function" then
            local ok_gc, all = pcall(getgc)
            if ok_gc and type(all) == "table" then
                for _, v in ipairs(all) do
                    if type(v) == "function" then
                        local oki, info_v = pcall(debug.getinfo, v, "Sln")
                        if oki and info_v and info_v.source == proto.source then
                            if info_v.linedefined >= proto.linedefined and info_v.linedefined <= (proto.lastlinedefined or info_v.linedefined) then
                                table.insert(active_list, v)
                            end
                        end
                    end
                end
            end
        end
        return active_list
    else
        local descriptor = {
            __proto = true,
            source = proto.source,
            linedefined = proto.linedefined,
            lastlinedefined = proto.lastlinedefined,
            nups = proto.nups
        }
        setmetatable(descriptor, {
            __tostring = function(t)
                return string.format("proto[%s:%d-%d]", t.source or "?", t.linedefined or 0, t.lastlinedefined or 0)
            end,
            __call = function()
                error("attempt to call inactive proto (use debug.getproto(..., true) to get active closures)", 2)
            end
        })
        return descriptor
    end
end

if not debug then debug = {} end
debug.getprotos = function(obj)
    return getprotos_impl(obj)
end
debug.getproto = function(obj, index, active)
    return getproto_impl(obj, index, active)
end
