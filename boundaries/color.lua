local color = {}

local stack = {}

color.set = love.graphics.setColor
color.get = love.graphics.getColor

function color.push(r, g, b, a)
	local lr, lg, lb, la = color.get()
	r, g, b, a = r or lr, g or lg, b or lb, a or la
	stack[#stack + 1] = {lr, lg, lb, la}
	
	color.set(r, g, b, a)
end

local function mult(a, b, c, d, x, y, z, w) return a * x, b * y, c * z, d * w end
function color.pushMultiply(r, g, b, a) color.push(mult(r, g, b, a or 1, color.get())) end
function color.setMultiply (r, g, b, a) color.set (mult(r, g, b, a or 1, color.get())) end

local function add(a, b, c, d, x, y, z, w) return a + x, b + y, c + z, d + w end
function color.pushAdd(r, g, b, a) color.push(add(r, g, b, a or 0, color.get())) end
function color.setAdd (r, g, b, a) color.set (add(r, g, b, a or 0, color.get())) end

function color.pop()
	color.set(unpack(stack[#stack]))
	stack[#stack] = nil
end

return color