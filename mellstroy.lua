local getmt  = getrawmetatable
local setro  = setreadonly or function() end
local ncc    = newcclosure or function(f) return f end
local running = coroutine.running

local __hm_store = setmetatable({}, { __mode = "k" })

local function normalize_orig(orig, method)
	if type(orig) == "function" then
		return orig
	elseif type(orig) == "table" then
		if method == "__index" then
			return function(self, k) return orig[k] end
		elseif method == "__newindex" then
			return function(self, k, v) orig[k] = v end
		else
			return function(...) return nil end
		end
	else
		return function(...) return nil end
	end
end

local function get_bucket(mt)
	local b = __hm_store[mt]
	if not b then
		b = { orig = {}, wrap = {}, hooks = {}, busy = false }
		__hm_store[mt] = b
	end
	return b
end

local function make_wrapper(mt, method)
	local bucket = get_bucket(mt)
	local origf  = bucket.orig[method]
	local hooks  = bucket.hooks[method]

	local function dispatch(self, ...)
		if bucket.busy then
			return origf(self, ...)
		end
		local h = hooks and hooks[self]
		if h then
			bucket.busy = true
			local ok, ret = pcall(h, self, ...)
			bucket.busy = false
			if ok then return ret end
			return origf(self, ...)
		end
		return origf(self, ...)
	end

	bucket.wrap[method] = ncc(dispatch)
	return bucket.wrap[method]
end

local function install_wrapper(mt, method)
	local bucket = get_bucket(mt)
	if not bucket.orig[method] then
		bucket.orig[method] = normalize_orig(mt[method], method)
	end
	if not bucket.wrap[method] then
		setro(mt, false)
		mt[method] = make_wrapper(mt, method)
		setro(mt, true)
	end
end

local function uninstall_if_unused(mt, method)
	local bucket = __hm_store[mt]; if not bucket then return end
	local hooks = bucket.hooks[method]
	if hooks and next(hooks) == nil then
		if bucket.wrap[method] then
			setro(mt, false)
			mt[method] = bucket.orig[method]
			setro(mt, true)
			bucket.wrap[method] = nil
		end
	end
end

hookmetamethod = ncc(function(obj, method, hook)
	assert(type(obj) == "userdata", "hookmetamethod: obj must be userdata")
	assert(type(method) == "string" and method:sub(1,2) == "__", "hookmetamethod: bad metamethod name")
	assert(type(hook) == "function", "hookmetamethod: hook must be function")

	local mt = getmt(obj)
	assert(type(mt) == "table", "hookmetamethod: no metatable")

	local bucket = get_bucket(mt)
	if not bucket.orig[method] then
		bucket.orig[method] = normalize_orig(mt[method], method)
	end

	install_wrapper(mt, method)

	bucket.hooks[method] = bucket.hooks[method] or setmetatable({}, { __mode = "k" })
	bucket.hooks[method][obj] = hook

	local original = ncc(function(self, ...)
		return bucket.orig[method](self, ...)
	end)

	return original
end)
