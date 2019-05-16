return function()
	local bounds  = require 'boundaries'
	local scissor = bounds.scissor
	local color   = bounds.color
	local font    = bounds.font
	
	local format, min, max = string.format, math.min, math.max
	
	local fontBig = love.graphics.newFont(64)
	
	return function()
		bounds.push()
		font.push(fontBig)
		
		for x,y in bounds.grid({1, 2, 3}, 3) do
			local i = x + (y - 1) * 3
			bounds.solid(unpack((select(i % 2 + 1, {0.8, 0.8, 0.8}, {0.2, 0.2, 0.2}))))
			scissor.pushIntersect(bounds.getRectangle())
			color.push(unpack((select(i % 2 + 1, {0.2, 0.2, 0.2}, {0.8, 0.8, 0.8}))))
			bounds.label(x .. ',' .. y, 0.5, 0.5)
			color.pop()
			scissor.pop()
		end
		
		font.pop()
		bounds.pop()
	end
end