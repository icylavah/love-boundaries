return function()
	local bounds  = require 'boundaries'
	local scissor = bounds.scissor
	local color   = bounds.color
	local font    = bounds.font
	
	local field = bounds.field:new()
	field.font = love.graphics.newFont(20)
	
	return function()
		bounds.push()
		bounds.solid(0.2, 0.1, 0.1, 1)
			bounds.slice('vertical', 2)
				bounds.align('center', 'center', bounds.getWidth() - 100, 50)
				field:place()
				bounds.pop()
			bounds.next()
				bounds.outline(1, 1, 1, 1, 0.2)
				bounds.pad('32px')
				
				color.push(0.7, 0.2, 0.2, 1)
				bounds.outline(10, color.get())
				bounds.stripes(20)
				color.pop()
				bounds.pop()
			bounds.pop()
		bounds.pop()
	end
end