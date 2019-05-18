local path = (...):gsub('/', '.'):gsub('\\', '.'):gsub('%.[^%.]+$', '', 1)

local bounds   = require(path)
local font     = bounds.font
local color    = bounds.color
local scissor  = bounds.scissor

local button = bounds.basic:extend()

function button:mousereleased(...)
	if self.action and bounds.isHovered(self, 'sub') then
		self.action(self, ...)
	end
end

button.keymap = {
	['return'] = function(self, ...)
		if self.action then
			self.action(self, ...)
		end
	end
}

button.foregroundColor = {0, 0, 0, 1}
button.focusColor = {0.1, 0.1, 0.8, 1}
button.cursor = 'hand'

function button:backgroundColor()
	local r, g, b = 0.8, 0.8, 0.8
	if self:getMode() == 'hover' then
		r, g, b = r + 0.1, g + 0.1, b + 0.1
	end
	return {r, g, b, 1}
end

function button:draw()
	scissor.push(bounds.getRectangle())
	self.super.draw(self)
	
	color.push(unpack(self:getValue('foregroundColor')))
	font.push(self:getValue('font') or font.get())
	
	local text = self:getValue('text')
	if text ~= nil then
		text = tostring(text)
	else
		text = ''
	end
	
	if bounds.isFocused(self) then
		color.set(unpack(self:getValue('focusColor')))
	end
	
	bounds.label(text, 'center', 'center')
	
	local x, y, w, h = bounds.getRectangle()
	love.graphics.rectangle('line', x + 0.5, y + 0.5, w - 1, h - 1)
	
	font.pop()
	color.pop()
	scissor.pop()
end

return button