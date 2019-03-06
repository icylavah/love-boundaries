local font = {}

local stack = {}

font.set = love.graphics.setFont
font.get = love.graphics.getFont

function font.push(f)
	stack[#stack + 1] = font.get()
	font.set(f)
end

function font.pop()
	font.set(stack[#stack])
	stack[#stack] = nil
end

return font