return function()
	local bounds  = require 'boundaries'
	local scissor = bounds.scissor
	local color   = bounds.color
	local font    = bounds.font
	
	local fontBig = love.graphics.newFont(96)
	
	local timePerStage = 0.7
	
	local function time() return love.timer.getTime() % (4 * timePerStage) end
	local function stage() return math.floor(time() / timePerStage) + 1 end
	local function animate() return math.min(1, (time() % timePerStage) / timePerStage * 2) ^ 2 end
	
	
	local colorA = {0.7, 0.3, 0.3}
	local colorB = {0.3, 0.3, 0.7}
	local colorC = {0.3, 0.7, 0.3}
	local colorD = {0.7, 0.7, 0.3}
	
	local t1 = function(t) return {1 - t, t} end
	local t2 = function(t) return {t, 1 - t} end
	
	local directions = {
		{'horizontal', t1},
		{'vertical', t2},
		{'horizontal', t2},
		{'vertical', t1},
	}
	
	local function rectangle(text, col)
		bounds.solid(unpack(col))
		
		scissor.push(bounds.getRectangle())
			bounds.push()
				color.push(unpack(col))
				color.setMultiply(0.6, 0.6, 0.6)
					font.push(fontBig)
						local f = font.get()
						local lines = love.graphics.getHeight() / (f:getHeight() * f:getLineHeight())
						lines = math.max(1, math.floor(lines))
						
						bounds.slice('vertical', lines)
						for i = 1, lines do
							bounds.label(text, 'center', 'center')
							bounds.next()
						end
					font.pop()
				color.pop()
			bounds.pop()
		scissor.pop()
	end
	
	local function transitionFunction(direction, fromColor, toColor)
		local orientation, weightFunction = unpack(directions[direction])
		if weightFunction == t2 then fromColor, toColor = toColor, fromColor end
		
		local text = 'love-boundaries'
		
		return function(t)
			bounds.slice(orientation, weightFunction(t))
				rectangle(text, fromColor)
				bounds.next()
				rectangle(text, toColor)
			bounds.pop()
		end
	end
	
	local one    = transitionFunction(1, colorA, colorB)
	local two    = transitionFunction(2, colorB, colorC)
	local three  = transitionFunction(3, colorC, colorD)
	local four   = transitionFunction(4, colorD, colorA)
	local choice = {one, two, three, four}
	
	return function()
		bounds.clearCaptures()
		bounds.push()
		choice[stage()](animate())
		bounds.pop()
	end
end