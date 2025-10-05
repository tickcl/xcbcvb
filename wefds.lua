local envs = {
    getrenv and getrenv() or nil,
    getgenv and getgenv() or nil,
    getfenv and getfenv() or nil
}

local function findFunc(name)
    for _, e in ipairs(envs) do
        if e and type(rawget(e, name)) == "function" then
            return rawget(e, name)
        end
    end
    return nil
end

local targets = {
    "getthreadidentity",
    "getrenv",
    "getgenv",
    "hookfunction"
}

for _, name in ipairs(targets) do
    local f = findFunc(name)
    if not f then
        print(name, "не найден")
    else
        warn(name, "найден, тип:", typeof(f))
        -- Два теста на работоспособность
        local ok1, res1 = pcall(function()
            if name == "getthreadidentity" then
                return f()
            elseif name == "getrenv" or name == "getgenv" then
                return type(f())
            elseif name == "hookfunction" then
                local dummy = function(x) return x+1 end
                local old = f(dummy, function(x) return x+2 end)
                return old(5)
            end
        end)
        print(name, "тест1:", ok1, res1)

        local ok2, res2 = pcall(function()
            if name == "getthreadidentity" then
                return type(f()) == "number"
            elseif name == "getrenv" or name == "getgenv" then
                local env = f()
                return type(env) == "table" and rawget(env, "game") ~= nil
            elseif name == "hookfunction" then
                local dummy = function() return "ok" end
                local old = f(dummy, function() return "patched" end)
                return old()
            end
        end)
        print(name, "тест2:", ok2, res2)
    end
end
