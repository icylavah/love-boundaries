return function()
	local bounds  = require 'boundaries'
	local scissor = bounds.scissor
	local color   = bounds.color
	local font    = bounds.font
	
	local format, min, max = string.format, math.min, math.max
	
	local fontBig = love.graphics.newFont(32)
	
	return function()
		bounds.push()
		font.push(fontBig)
		
		local totalW = bounds.getWidth()
		local ratios = {100 .. 'px', 1, 1}
		local lerp = (max(500, min(totalW, 600)) - 500) / 100
		ratios[1] = lerp * 50 + 50 .. 'px'
		ratios[2] = ratios[2] + lerp
		
		for i,w in bounds.slice('horizontal', ratios) do
			scissor.pushIntersect(bounds.getRectangle())
				bounds.solid(unpack((select(i % 2 + 1, {0.8, 0.8, 0.8}, {0.2, 0.2, 0.2}))))
				if i % 2 == 0 and lerp % 1 ~= 0 then bounds.solid(0.8, 0.6, 0.6) end
				
				color.push(unpack((select(i % 2 + 1, {0.2, 0.2, 0.2}, {0.8, 0.8, 0.8}))))
					bounds.label(w .. 'px', 0.5, 1 / 3)
					bounds.label(format('%0.1f%%', w / totalW * 100), 0.5, 2 / 3)
				color.pop()
			scissor.pop()
		end
		
		font.pop()
		bounds.pop()
	end
end