local canvas = {}

local stack = {}

canvas.set = love.graphics.setCanvas
canvas.get = love.graphics.getCanvas

function canvas.push(c)
	stack[#stack + 1] = canvas.get()
	canvas.set(c)
end

function canvas.pop()
	canvas.set(stack[#stack])
	stack[#stack] = nil
end

return canvas