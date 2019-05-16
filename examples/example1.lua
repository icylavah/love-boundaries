return function()
	local bounds  = require 'boundaries'
	local scissor = bounds.scissor
	local color   = bounds.color
	local font    = bounds.font
	
	local fontBig = love.graphics.newFont(48)
	
	return function()
		bounds.push()
			font.push(fontBig)
				local f = font.get()
				local lines = love.graphics.getHeight() / (f:getHeight() * f:getLineHeight())
				lines = math.max(1, math.floor(lines))
				for i,w in bounds.slice('vertical', lines) do
					bounds.solid(unpack((select(i % 2 + 1, {0.8, 0.5, 0.5}, {0.3, 0.3, 0.5}))))
					color.push(unpack((select(i % 2 + 1, {0.2, 0.05, 0.05}, {0.8, 0.8, 0.9}))))
						bounds.pad(0, 32 .. 'px')
						bounds.label(i, lines > 1 and ((i - 1) / (lines - 1)) or 'center', 'center')
						bounds.pop()
					color.pop()
				end
			font.pop()
		bounds.pop()
	end
end