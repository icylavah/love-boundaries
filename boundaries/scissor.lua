local scissor = {}

local stack = {}

scissor.set = love.graphics.setScissor
scissor.get = love.graphics.getScissor
scissor.intersect = love.graphics.intersectScissor

function scissor.push(...)
	stack[#stack + 1] = {scissor.get()}
	scissor.set(...)
end

function scissor.pushIntersect(...)
	stack[#stack + 1] = {scissor.get()}
	scissor.intersect(...)
end

function scissor.pop()
	scissor.set(unpack(stack[#stack]))
	--print(scissor.get())
	stack[#stack] = nil
end

return scissor