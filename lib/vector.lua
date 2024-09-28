

local assert = assert
local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2

local vector = {}
vector.__index = vector

local function new(x,y)
	return setmetatable({x = x or 0, y = y or 0}, vector)
end
local zero = new(0,0)

local function fromPolar(angle, radius)
	radius = radius or 1
	return new(cos(angle) * radius, sin(angle) * radius)
end

local function randomDirection(len_min, len_max)
	len_min = len_min or 1
	len_max = len_max or len_min

	assert(len_max > 0, "len_max must be greater than zero")
	assert(len_max >= len_min, "len_max must be greater than or equal to len_min")
	
	return fromPolar(math.random() * 2*math.pi,
	                 math.random() * (len_max-len_min) + len_min)
end

local function isvector(v)
	return type(v) == 'table' and type(v.x) == 'number' and type(v.y) == 'number'
end

function vector:clone()
	return new(self.x, self.y)
end

function vector:unpack()
	return self.x, self.y
end

-- position size构造函数
local function ps(x, y, w, h)
	return {
		pos = new(x, y),
		size = new(w, h)
	}
end

local function ps_clone(t)
	return {
		pos = {
			t.pos.x,
			t.pos.y
		},
		size = {
			t.size.x,
			t.size.y
		}
	}
end

function vector:__tostring()
	return "("..tonumber(self.x)..","..tonumber(self.y)..")"
end

function vector.__unm(a)
	return new(-a.x, -a.y)
end

function vector.__add(a,b)
	assert(isvector(a) and isvector(b), "Add: wrong argument types (<vector> expected)")
	return new(a.x+b.x, a.y+b.y)
end

function vector.__sub(a,b)
	assert(isvector(a) and isvector(b), "Sub: wrong argument types (<vector> expected)")
	return new(a.x-b.x, a.y-b.y)
end

function vector.__mul(a,b)
	if type(a) == "number" then
		return new(a*b.x, a*b.y)
	elseif type(b) == "number" then
		return new(b*a.x, b*a.y)
	else
		assert(isvector(a) and isvector(b), "Mul: wrong argument types (<vector> or <number> expected)")
		return a.x*b.x + a.y*b.y
	end
end

function vector.__div(a,b)
	assert(isvector(a) and type(b) == "number", "wrong argument types (expected <vector> / <number>)")
	return new(a.x / b, a.y / b)
end

function vector.__eq(a,b)
	return a.x == b.x and a.y == b.y
end

function vector.__lt(a,b)
	return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function vector.__le(a,b)
	return a.x <= b.x and a.y <= b.y
end

function vector.permul(a,b)
	assert(isvector(a) and isvector(b), "permul: wrong argument types (<vector> expected)")
	return new(a.x*b.x, a.y*b.y)
end

function vector:toPolar()
	return new(atan2(self.x, self.y), self:len())
end

function vector:len2()
	return self.x * self.x + self.y * self.y
end

function vector:len()
	return sqrt(self.x * self.x + self.y * self.y)
end

function vector.dist(a, b)
	assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
	local dx = a.x - b.x
	local dy = a.y - b.y
	return sqrt(dx * dx + dy * dy)
end

function vector.dist2(a, b)
	assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
	local dx = a.x - b.x
	local dy = a.y - b.y
	return (dx * dx + dy * dy)
end

function vector:normalizeInplace()
	local l = self:len()
	if l > 0 then
		self.x, self.y = self.x / l, self.y / l
	end
	return self
end

function vector:normalized()
	return self:clone():normalizeInplace()
end

function vector:rotateInplace(phi)
	local c, s = cos(phi), sin(phi)
	self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
	return self
end

function vector:rotated(phi)
	local c, s = cos(phi), sin(phi)
	return new(c * self.x - s * self.y, s * self.x + c * self.y)
end

function vector:perpendicular()
	return new(-self.y, self.x)
end

function vector:projectOn(v)
	assert(isvector(v), "invalid argument: cannot project vector on " .. type(v))
	-- (self * v) * v / v:len2()
	local s = (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
	return new(s * v.x, s * v.y)
end

function vector:mirrorOn(v)
	assert(isvector(v), "invalid argument: cannot mirror vector on " .. type(v))
	-- 2 * self:projectOn(v) - self
	local s = 2 * (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
	return new(s * v.x - self.x, s * v.y - self.y)
end

function vector:cross(v)
	assert(isvector(v), "cross: wrong argument types (<vector> expected)")
	return self.x * v.y - self.y * v.x
end

-- ref.: http://blog.signalsondisplay.com/?p=336
function vector:trimInplace(maxLen)
	local s = maxLen * maxLen / self:len2()
	s = (s > 1 and 1) or math.sqrt(s)
	self.x, self.y = self.x * s, self.y * s
	return self
end

function vector:angleTo(other)
	if other then
		return atan2(self.y, self.x) - atan2(other.y, other.x)
	end
	return atan2(self.y, self.x)
end

function vector:angle()
	return atan2(self.y, self.x)
end

function vector:trimmed(maxLen)
	return self:clone():trimInplace(maxLen)
end

-- expand
function vector:midPoint(other)
	return new((self.x+other.x)/2, (self.y+other.y)/2)
end

-- is self in circle
function vector:in_circle(x, y, radius)
	return vector.dist(self, new(x,y)) <= radius
end

function vector:in_rectangle(x, y, w, h)
	return self.x - x > 0  and self.y - y > 0 and
		x + w - self.x > 0  and y + h - self.y > 0
end

-- 线性插值
function vector:lerp(other, amount)
	return new(math.lerp(self.x, other.x, amount),
			math.lerp(self.y, other.y, amount))
end

-- 重新赋值
function vector:set(x, y)
	if isvector(x) then
		self.x,self.y = x.x,x.y
	else
		self.x,self.y = x, y
	end
end

-- the module
return setmetatable({
	new             = new,
	fromPolar       = fromPolar,
	randomDirection = randomDirection,
	isvector        = isvector,
	zero            = zero,
	ps 				= ps,
	ps_clone        = ps_clone
}, {
	__call = function(_, ...) return new(...) end
})
