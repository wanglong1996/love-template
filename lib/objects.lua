

Spring = Object:extend()
-- 胡克定律 f = -k*x
function Spring:new(x, k, d)
    self.x = x or 0
    -- 弹性系数
    self.k = k or 100
    -- 阻尼
    self.d = d or 10
    self.target_x = self.x
    self.v = 0
end

function Spring:update(dt)
    local a = -self.k * (self.x - self.target_x) - self.d * self.v
    self.v = self.v + a*dt
    self.x = self.x + self.v*dt
end
-- k越大，弹簧返回初始值的速度越快，阻尼越低，弹簧震荡时间越长。
function Spring:pull(f, k, d)
    if k then self.k = k end
    if d then self.d = d end
    self.x = self.x + f
end