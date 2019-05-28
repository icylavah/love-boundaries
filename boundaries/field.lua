local path = (...):gsub('/', '.'):gsub('\\', '.'):gsub('%.[^%.]+$', '')

local bounds  = require(path)
local font    = bounds.font
local color   = bounds.color
local scissor = bounds.scissor
local line    = bounds.line

local field = bounds.basic:extend()


field.foregroundColor = {0, 0, 0, 1}
field.backgroundColor = {1, 1, 1, 1}
field.selectionBackgroundColor = {0.2, 0.2, 0.8, 1}
field.selectionForegroundColor = {1, 1, 1, 1}
field.emptyForegroundColor = {0.5, 0.5, 0.5, 1}
field.cursor = 'ibeam'

field.text = ''
field.emptyText = ''
field.cursorPos = 0
field.selectOff = 0
field.padSide = 4
field.isDragged = false

function field:draw()
	-- background and outline
	bounds.solid(unpack(self.backgroundColor))
	bounds.outline(1, unpack(self.foregroundColor))
	
	bounds.pad(0, self.padSide .. 'px', 0)
		local x, y, w, h = bounds.getRectangle()
		
		local f = self.font or font.get()
		font.set(f)
		
		scissor.pushIntersect(x, y, w, h)
		
		local fh = f:getHeight()
		local yOff = math.floor((h - fh) / 2 + 0.5)
		
		color.push(unpack(self.foregroundColor))
		if self.selectOff == 0 then
			-- text
			if #self.text == 0 then
				color.push(unpack(self.emptyForegroundColor))
				love.graphics.print(self.emptyText, x, y + yOff)
				color.pop()
			else
				love.graphics.print(self.text, x, y + yOff)
			end
			-- cursor position
			if bounds.isFocused(self) then
				local xOff = f:getWidth(self.text:sub(1, self.cursorPos))
				line.pushWidth(1)
				love.graphics.line(x + xOff + 0.5, y + yOff + 0.5, x + xOff + 0.5, y + yOff + fh + 0.5)
				line.popWidth()
			end
		else
			local a, b = self:getPositions()
			local ap, bp = f:getWidth(self.text:sub(1, a)), f:getWidth(self.text:sub(1, b))
			color.push(unpack(self.selectionBackgroundColor))
			love.graphics.rectangle('fill', x + ap, y + yOff, bp - ap, fh)
			color.set(unpack(self.selectionForegroundColor))
			love.graphics.print(self.text:sub(a + 1, b), x + ap, y + yOff)
			color.pop()
			love.graphics.print(self.text:sub(1, a), x, y + yOff)
			love.graphics.print(self.text:sub(b + 1, -1), x + bp, y + yOff)
		end
		color.pop()
	
		scissor.pop()
	bounds.pop()
end

local function findCursorPosition(text, font, x)
	local w = 0
	local textLen = #text
	for i = 1, textLen do
		local cw = font:getWidth(text:sub(i, i))
		if x < font:getWidth(text:sub(1, i)) - cw / 2 then
			return i - 1
		end
		w = w + cw
	end
	
	return textLen
end

function field:getPositions()
	if self.selectOff == 0 then return self.cursorPos, self.cursorPos end
	local a = self.cursorPos
	local b = a + self.selectOff
	if a > b then a, b = b, a end
	return a, b
end

function field:getSelection()
	local a, b = self:getPositions()
	if a == b then return '' end
	return self.text:sub(a + 1, b)
end

function field:insertText(text)
	if self.selectOff ~= 0 then self:deleteSelection() end
	self.text = self.text:sub(1, self.cursorPos) .. text .. self.text:sub(self.cursorPos + 1, -1)
	self.cursorPos = self.cursorPos + #text
end

function field:deleteSelection()
	if self.selectOff == 0 then return end
	
	local a, b = self:getPositions()
	
	self.text = self.text:sub(1, a) .. self.text:sub(b + 1, -1)
	
	if self.selectOff < 0 then self.cursorPos = self.cursorPos + self.selectOff end
	self.selectOff = 0
end

field.keymap = {
	right = function(self, key, code, isrepeat)
		if love.keyboard.isDown('lshift', 'rshift') then
			if self.cursorPos ~= #self.text then
				self.selectOff = self.selectOff - 1
				self.cursorPos = math.min(self.cursorPos + 1, #self.text)
			end
		elseif self.selectOff == 0 then
			self.cursorPos = math.min(self.cursorPos + 1, #self.text)
		else
			local a, b = self:getPositions()
			self.selectOff = 0
			self.cursorPos = b
		end
	end,
	left = function(self, key, code, isrepeat)
		if love.keyboard.isDown('lshift', 'rshift') then
			if self.cursorPos ~= 0 then
				self.selectOff = self.selectOff + 1
				self.cursorPos = math.max(self.cursorPos - 1, 0)
			end
		elseif self.selectOff == 0 then
			self.cursorPos = math.max(self.cursorPos - 1, 0)
		else
			local a, b = self:getPositions()
			self.selectOff = 0
			self.cursorPos = a
		end
	end,
	backspace = function(self, key, code, isrepeat)
		if self.selectOff == 0 and self.cursorPos > 0 then
			self.text = self.text:sub(1, self.cursorPos - 1) .. self.text:sub(self.cursorPos + 1, -1)
			self.cursorPos = self.cursorPos - 1
		else
			self:deleteSelection()
		end
	end,
	delete = function(self, key, code, isrepeat)
		if self.selectOff == 0 and self.cursorPos < #self.text then
			self.text = self.text:sub(1, self.cursorPos) .. self.text:sub(self.cursorPos + 2, -1)
		else
			self:deleteSelection()
		end
	end,
	c = function(self, key, code, isrepeat)
		if love.keyboard.isDown('lctrl', 'rctrl') then
			love.system.setClipboardText(self:getSelection())
		else
			return false
		end
	end,
	x = function(self, key, code, isrepeat)
		if love.keyboard.isDown('lctrl', 'rctrl') then
			love.system.setClipboardText(self:getSelection())
			self:deleteSelection()
		else
			return false
		end
	end,
	v = function(self, key, code, isrepeat)
		if love.keyboard.isDown('lctrl', 'rctrl') then
			self:insertText(love.system.getClipboardText())
		else
			return false
		end
	end,
	a = function(self, key, code, isrepeat)
		if love.keyboard.isDown('lctrl', 'rctrl') then
			self.cursorPos = #self.text
			self.selectOff = -self.cursorPos
		else
			return false
		end
	end,
	home = function(self, key, code, isrepeat)
		self.cursorPos = 0
		self.selectOff = 0
	end,
	['end'] = function(self, key, code, isrepeat)
		self.cursorPos = #self.text
		self.selectOff = 0
	end,
	escape = function(self, key, code, isrepeat)
		self.selectOff = 0
	end
}

function field:textinput(text)
	self:insertText(text)
end

function field:mousepressed(x, y)
	local f = self.font or font.get()
	self.cursorPos = findCursorPosition(self.text, f, x - bounds.getX() - self.padSide)
	self.selectOff = 0
	self.isDragged = true
	return true
end

function field:mousereleased(x, y)
	self.isDragged = false
end

function field:update(dt)
	if self.isDragged then
		local f = self.font or font.get()
		local c = findCursorPosition(self.text, f, love.mouse.getX() - bounds.getX() - self.padSide)
		self.selectOff = self.selectOff + self.cursorPos - c
		self.cursorPos = c
	end
end

return field