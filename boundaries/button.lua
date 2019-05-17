local path = (...):gsub('/', '.'):gsub('\\', '.'):gsub('%.[^%.]+$', '')

local bounds = require(path)
local font   = bounds.font
local color  = bounds.color

return function()
	return {
		mousereleased = function(self, ...)
			local action = self.action
			if action and bounds.isHovered(self, 'any') then
				action(self, ...)
			end
		end,
		place = function(self)
			if self.draw then self:draw() end
			bounds.capture(self)
		end,
		getMode = function(self)
			if bounds.isActive(self) then
				return 'active'
			elseif bounds.isHovered(self) then
				return 'hover'
			else
				return 'normal'
			end
		end
	}
end