local Registry = {}
Registry.__index = function (self, k)
    return Registry[k] or (function ()
        local t = {}
        rawset(self, k, t)
        return t
    end)()
end

function Registry:register(event, func)
    self[event][func] = func
    return func
end

function Registry:emit(event, ...)
    for f in pairs(self[event]) do
        f(...)
    end
end

-- 解除s信号下的指定方法（注册时返回的handle）
-- select('#', unpack(table))  返回table长度
-- select(2, unpack(table))    返回table[2],table[3],...,table[#table]
function Registry:remove(event, ...)
    local f = {...}
    for i = 1, select('#', ...) do
        self[event][f[i]] = nil
    end
end

-- 清除指定信号的所有方法
function Registry:clear(...)
    local s = {...}
    for i = 1, select('#', ...) do
        self[s[i]] = {}
    end
end

function Registry:emitPattern(p, ...)
    for s in pairs(self) do
        if s:match(p) then
            self:emit(s, ...)
        end
    end
end


function Registry:registerPattern(p, f)
    for s in pairs(self) do
        if s:match(p) then
            self:register(s, f)
        end
    end
    return f
end


function Registry:removePattern(p, ...)
    for s in pairs(self) do
        if s:match(p) then
            self:remove(s, ...)
        end
    end
end

function Registry:clearPattern(p)
    for s in pairs(self) do
        if s:match(p) then
            self[s] = {}
        end
    end
end


function Registry.new()
    return setmetatable({}, Registry)
end

local default = Registry.new()

local module = {}
for k, v in pairs(Registry) do
    if not k:find("__") then
        module[k] = function (...)
            -- 调用默认实例default的方法
            return default[k](default, ...)
        end
    end
end

return setmetatable(module, {__call = Registry.new})

