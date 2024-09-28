---@diagnostic disable: lowercase-global


function HEX(hex)
    hex = hex:gsub("#", "")
    if #hex <= 6 then hex = hex .. "FF" end
    local _, _, r, g, b, a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
    local color = { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, tonumber(a, 16) / 255 }
    return color
end


function push(x, y, r, sx, sy)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(r or 0)
    love.graphics.scale(sx or 1, sy or sx or 1)
    love.graphics.translate(-x, -y)
end

-- 随机列表
-- events = chanceList({'x', 3},{'y', 3}, {'z', 4})
function chance_list(...)
    return {
        chance_list = {},
        chance_definitions = {...},
        next = function (self)
            if #self.chance_list == 0 then
                for _, chance_definition in ipairs(self.chance_definitions) do
                    for i = 1, chance_definition[2] do
                        table.insert(self.chance_list, chance_definition[1])
                    end
                end
            end
            return table.remove(self.chance_list, love.math.random(1, #self.chance_list))
        end
    }
end

-- 忽略传入uniform没使用的错误
function shader_send(shader, key, value)
    local success, msg = pcall(function ()
        shader:send(key, value)
    end)
    if not success then
        -- print('error '..msg)
    end
end

-- 运行.lua文件
-- success, valueOrErrormsg = runFile( name )
function runFile(name)
	local ok, chunk, err = pcall(love.filesystem.load, name) -- load the chunk safely
	if not ok    then  return false, "Failed loading code: "..chunk  end
	if not chunk then  return false, "Failed reading file: "..err    end

	local ok, value = pcall(chunk) -- execute the chunk safely
	if not ok then  return false, "Failed calling chunk: "..tostring(value)  end

	return true, value -- success!
end



-- 带缩进的table详细打印
function pretty_print(t, level)
    level = level or 1
	return getfulldump(t, level)
end

-- level 表示表中表的支持层数
function getfulldump(t, level, i)
	i = i or ""
	level = level or 99999999
	currLevel = 1

	local seen = {}
	local retstr

	local function _dump(t, i)
		seen[t] = true

		local keys = {}
		local keyStrs = {}
		local maxKeyLen = 0

		for k, _ in pairs(t) do
			keys[#keys + 1] = k
			keyStrs[k] = {
				type(k) == "string" and "'" .. tostring(k) .. "'" or tostring(k)
			}

			local klen = #keyStrs[k][1]

			keyStrs[k][2] = klen
			maxKeyLen = maxKeyLen <= klen and klen or maxKeyLen
		end

		table.sort(keys, function(k1, k2)
            k1 = tostring(k1)
            k2 = tostring(k2)
        
            return k1 < k2
        end)

		for _, k in ipairs(keys) do
			local arrowIndent = string.rep(" ", maxKeyLen - keyStrs[k][2]) .. "  "

			retstr = retstr .. string.format("%s    [%s]", i, keyStrs[k][1])
			retstr = retstr .. arrowIndent
			retstr = retstr .. string.format("->  %s\t%s\n", tostring(t[k]), seen[t[k]] and "(seen)" or "")
			k = t[k]

			if type(k) == "table" and k ~= nil and not seen[k] and currLevel < level then
				currLevel = currLevel + 1

				_dump(k, i .. arrowIndent .. "    ")

				currLevel = currLevel - 1
			end
		end
	end

	retstr = "self: \t" .. tostring(t) .. "\n"

	if t ~= nil then
		_dump(t, i)
	end

	return retstr
end


-- 简单统计内存，table
function type_count()
    local counts = {}
    local enumerate = function(o)
        local t = type_name(o)
        counts[t] = (counts[t] or 0) + 1
    end
    count_all(enumerate)
    return counts
end


function count_all(f)
    local seen = {}
    local count_table
    count_table = function(t)
        if seen[t] then return end
        f(t)
        seen[t] = true    
        for k, v in pairs(t) do
            if type(v) == "table" then
                count_table(v)
            elseif type(v) == "userdata" then
                f(v)
            end
        end  
    end
    count_table(_G)
end

function type_name(o)
    if global_type_table == nil then
        global_type_table = {}
        for k, v in pairs(_G) do
            global_type_table[v] = k
        end
        global_type_table[0] = "table"
    end
    return global_type_table[getmetatable(o) or 0] or "Unknown"
end