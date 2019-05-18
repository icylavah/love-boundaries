local path = (...):gsub('/', '.'):gsub('\\', '.'):gsub('%.[^%.]+$', '', 1)

local bounds = require(path)
local font   = bounds.font
local color  = bounds.color

local basic = {}
basic.__index = basic
basic.class = basic

function basic:new()
	return setmetatable({}, self)
end

basic.keymap = {
	tab = function(self, key, code, isrepeat)
		if not isrepeat then
			if love.keyboard.isDown('lshift', 'rshift') then
				self:focusPrevious()
			else
				self:focusNext()
			end
		end
	end
}

function basic:focusNext()
	if self.next then return bounds.focus(self.next) end
	return false
end

function basic:focusPrevious()
	if self.previous then return bounds.focus(self.previous) end
	return false
end

function basic:keypressed(key, ...)
	local c = self.class
	local classes = {self}
	while c do
		table.insert(classes, c)
		c = c.super
	end
	for i = #classes, 1, -1 do
		local km = rawget(classes[i], 'keymap')
		if km then
			local f = km[key]
			if f then return f(self, key, ...) ~= false end
		end
	end
end

basic.backgroundColor = {1, 1, 1, 1}

function basic:draw()
	local color = self:getValue('backgroundColor')
	bounds.solid(unpack(color))
end

function basic:place()
	if self.draw then self:draw() end
	bounds.capture(self)
end

function basic:getMode()
	if bounds.isActive(self) then
		return 'active'
	elseif bounds.isHovered(self, 'sub') then
		return 'hover'
	else
		return 'normal'
	end
end

function basic:extend()
	local t = {}
	t.__index = t
	t.super = self
	t.class = t
	return setmetatable(t, self)
end

function basic:getValue(k)
	local v = self[k]
	if type(v) == 'function' then
		v = v(self)
	end
	return v
end

return basic