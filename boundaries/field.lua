local path = (...):gsub('/', '.'):gsub('\\', '.'):gsub('%.[^%.]+$', '')

local ui = require(path)
local font = require(path .. '.font')
local color = require(path .. '.color')

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

local function sortAB(a, b)
	if a > b then
		return b, a
	end
	return a, b
end

local function resetTime(self)
	self.time = love.timer.getTime()
end

return function()
	return {
		cursor = 0,
		selection = 0,
		time = 0,
		text = '',
		mousepressed = {
			function(self, x, y, button)
				if ui.isInBounds(x, y) then
					self.cursor = findCursorPosition(self.text, self.font, x - ui.getX())
					self.selection = self.cursor
					
					--resetTime(self)
					
					return true
				end
			end
		},
		mousemoved = function(self, x, y, dx, dy)
			if love.mouse.isDown(1) and ui.isActive(self) then
				self.selection = findCursorPosition(self.text, self.font, x - ui.getX())
			end
		end,
		textinput = function(self, text)
			local p1, p2 = self.cursor, self.selection
			if p1 > p2 then p1, p2 = p2, p1 end
			
			resetTime(self)
			
			self.text = self.text:sub(1, p1) .. text .. self.text:sub(p2 + 1, -1)
			self.cursor = p1 + 1
			self.selection = self.cursor
		end,
		keypressed = {
			backspace = function(self, key)
				local p1, p2 = sortAB(self.cursor, self.selection)
				if p1 == p2 then
					if self.cursor > 0 then
						self.text = self.text:sub(1, self.cursor - 1) .. self.text:sub(self.cursor + 1, -1)
						self.cursor = self.cursor - 1
						self.selection = self.cursor
					end
				else
					self.text = self.text:sub(1, p1) .. self.text:sub(p2 + 1, -1)
					self.cursor = p1
					self.selection = p1
				end
				resetTime(self)
			end,
			delete = function(self, key)
				local p1, p2 = sortAB(self.cursor, self.selection)
				if p1 == p2 then
					self.text = self.text:sub(1, self.cursor) .. self.text:sub(self.cursor + 2, -1)
				else
					self.text = self.text:sub(1, p1) .. self.text:sub(p2 + 1, -1)
					self.cursor = p1
					self.selection = p1
				end
				resetTime(self)
			end,
			left = function(self, key)
				local p1, p2 = sortAB(self.cursor, self.selection)
				if p1 == p2 then
					self.selection = math.max(self.selection - 1, 0)
					if not love.keyboard.isDown('lshift', 'rshift') then
						self.cursor = self.selection
					end
				else
					if love.keyboard.isDown('lshift', 'rshift') then
						self.selection = math.max(self.selection - 1, 0)
					else
						self.cursor = p1
						self.selection = p1
					end
				end
				resetTime(self)
			end,
			right = function(self, key)
				local p1, p2 = sortAB(self.cursor, self.selection)
				if p1 == p2 then
					self.selection = math.min(self.selection + 1, #self.text)
					if not love.keyboard.isDown('lshift', 'rshift') then
						self.cursor = self.selection
					end
				else
					if love.keyboard.isDown('lshift', 'rshift') then
						self.selection = math.min(self.selection + 1, #self.text)
					else
						self.cursor = p2
						self.selection = p2
					end
				end
				resetTime(self)
			end,
			x = function(self, key)
				if love.keyboard.isDown('lctrl', 'rctrl') then
					local p1, p2 = sortAB(self.cursor, self.selection)
					if p1 ~= p2 then
						love.system.setClipboardText(self.text:sub(p1 + 1, p2))
						self.text = self.text:sub(1, p1) .. self.text:sub(p2 + 1, -1)
						self.cursor = p1
						self.selection = p1
						resetTime(self)
					end
				end
			end,
			c = function(self, key)
				if love.keyboard.isDown('lctrl', 'rctrl') then
					local p1, p2 = sortAB(self.cursor, self.selection)
					if p1 ~= p2 then
						love.system.setClipboardText(self.text:sub(p1 + 1, p2))
					end
				end
			end,
			v = function(self, key)
				if love.keyboard.isDown('lctrl', 'rctrl') then
					local p1, p2 = sortAB(self.cursor, self.selection)
					local cbt = love.system.getClipboardText()
					self.text = self.text:sub(1, p1) .. cbt .. self.text:sub(p2 + 1, -1)
					self.cursor = p1 + #cbt
					self.selection = p1 + #cbt
					resetTime(self)
				end
			end,
			a = function(self, key)
				if love.keyboard.isDown('lctrl', 'rctrl') then
					self.cursor = 0
					self.selection = #self.text
				end
			end,
			escape = function(self, key)
				self.selection = self.cursor
				resetTime(self)
			end,
			home = function(self, key)
				self.cursor = 0
				self.selection = 0
				resetTime(self)
			end,
			['end'] = function(self, key)
				self.cursor = #self.text
				self.selection = #self.text
				resetTime(self)
			end,
		},
		draw = function(self)
			local f, t = self.font, self.text
			local w, h = f:getWidth(t), f:getHeight()
			font.push(f)
				--[
				ui.align(0, 0.5, w, h)
					local x, y = ui.getPosition()
					
					local p1, p2 = sortAB(self.cursor, self.selection)
					if p1 ~= p2 then
						if ui.isFocused(self) and love.window.hasFocus() then
							color.push(0.2, 0.2, 0.8)
						else
							color.push(0.5, 0.5, 0.5)
						end
							local r1 = self.font:getWidth(self.text:sub(1, p1))
							local r2 = self.font:getWidth(self.text:sub(1, p2))
							--local tw = self.font:getWidth(self.text:sub(p1 + 1, p2))
							--local tox = self.font:getWidth(self.text:sub(1, p2))
							love.graphics.rectangle('fill', x + r1, y, r2 - r1, h)
						color.pop()
					end
					
					color.push(0, 0, 0, 1)
						if p1 == p2 then
							love.graphics.print(t, x, y)
						else
							local t1 = t:sub(1, p1)
							local t2 = t:sub(p1 + 1, p2)
							local t3 = t:sub(p2 + 1, -1)
							local w1 = f:getWidth(t1 .. t2)
							local w2 = f:getWidth(t2)
							local w3 = f:getWidth(t3)
							love.graphics.print(t1, x, y)
							color.push(1, 1, 1, 1)
								love.graphics.print(t2, x + w1 - w2, y)
							color.pop()
							love.graphics.print(t3, x + w - w3, y)
						end
						if (love.timer.getTime() - self.time) % 1 < 0.5 and p1 == p2 and ui.isFocused(self) and love.window.hasFocus() then
							local cursorPosition = f:getWidth(t:sub(1, self.cursor))
							love.graphics.line(x + cursorPosition + 0.5, y + 0.5, x + cursorPosition + 0.5, y + h + 0.5)
						end
					color.pop()
				ui.pop()
			font.pop()
		end,
		place = function(self)
			if self.draw then self:draw() end
			ui.capture(self)
		end
	}
end