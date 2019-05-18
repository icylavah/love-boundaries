return function()
	local bounds  = require 'boundaries'
	local font    = bounds.font
	local color   = bounds.color
	
	local format, min, max = string.format, math.min, math.max
	
	local fontBig = love.graphics.newFont(64)
	local text = ''
	local root = bounds.basic:new()
	
	local function numberAction(self)
		text = text .. self.text
	end
	
	buttons = {}
	for x = 1, 3 do
		buttons[x] = {}
		for y = 1, 3 do
			local i = 4 - x + (y - 1) * 3
			local b = bounds.button:new()
			b.text = 10 - i
			b.action = numberAction
			b.parent = root
			buttons[x][y] = b
		end
	end
	
	operators = {}
	for i,v in ipairs{'/', '*', '-', '+'} do
		local b = bounds.button:new()
		b.text = v
		b.action = numberAction
		b.parent = root
		operators[i] = b
	end
	
	zero = bounds.button:new()
	zero.text = '0'
	zero.action = numberAction
	zero.parent = root
	
	dot = bounds.button:new()
	dot.text = '.'
	dot.action = numberAction
	dot.parent = root
	
	root.keymap = {
		backspace = function(self)
			text = text:sub(1, -2)
		end
	}
	root.backgroundColor = {0, 0, 0, 0}
	
	return function()
		bounds.push()
		font.push(fontBig)
		
		root:place()
		
		for i in bounds.slice('vertical', {1, 3}) do
			if i == 1 then
				bounds.solid(0.9, 0.9, 0.9, 1)
				color.push(0, 0, 0, 1)
				bounds.pad('16px')
				bounds.label(text .. ' = ' .. tostring((loadstring('return ' .. text) or function() return 'invalid' end)() or 'invalid'), 'right', 'center')
				bounds.pop()
				color.pop()
			else
				for i in bounds.slice('horizontal', {3, 1}) do
					if i == 1 then
						for i in bounds.slice('vertical', {3, 1}) do
							if i == 1 then
								for x,y in bounds.grid(3, 3) do
									buttons[x][y]:place()
								end
							else
								for i in bounds.slice('horizontal', {2, 1}) do
									if i == 1 then
										zero:place()
									else
										dot:place()
									end
								end
							end
						end
					else
						for i in bounds.slice('vertical', 4) do
							operators[i]:place()
						end
					end
				end
			end
		end
		
		font.pop()
		bounds.pop()
	end
end