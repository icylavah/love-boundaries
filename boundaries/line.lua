local line = {}

local stack = {}

line.setWidth = love.graphics.setLineWidth
line.getWidth = love.graphics.getLineWidth

function line.pushWidth(w)
	stack[#stack + 1] = line.getWidth()
	line.setWidth(w)
end

function line.popWidth()
	line.setWidth(stack[#stack])
	stack[#stack] = nil
end

return line