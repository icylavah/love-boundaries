local path = (...):gsub('/', '.'):gsub('\\', '.'):gsub('%.[^%.]+$', '')

local ui = require(path)
local font = require(path .. '.font')
local color = require(path .. '.color')

return function()
	return {
		mousepressed = function(self, x, y, button)
			if ui.isHovered(self.isHovered or ui.isInBounds) then
				return true
			end
		end,
		mousereleased = function(self, x, y, button)
			local action = self.action
			if action and ui.isHovered(self.isHovered or ui.isInBounds) then
				if type(action) == 'table' then
					if action[button] then action[button](self) end
				else
					action(self)
				end
			end
		end,
		place = function(self)
			if self.draw then self:draw() end
			ui.capture(self)
		end,
		getMode = function(self)
			if ui.isActive(self) then
				return 'active'
			elseif ui.isHovered(self.isHovered or ui.isInBounds) then
				return 'hover'
			else
				return 'normal'
			end
		end
	}
end