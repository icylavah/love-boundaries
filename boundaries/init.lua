local stackLimit = 256
local captures, captureIndex, focused, hovered
local weakKeys = {__mode = 'k'}

local function getStackLimit() return stackLimit end
local function setStackLimit(limit) stackLimit = limit end

local lmsc = love.mouse.setCursor
local lmgc = love.mouse.getCursor

local cursor = lmgc()
function love.mouse.setCursor(c) cursor = c end
function love.mouse.getCursor() return cursor end

local function setCursor(c)
	lmsc(c or cursor)
end

local req = ...
local function tryRequire(mod)
	local status, result = pcall(require, req .. '.' .. mod)
	if status then return result end
	return nil, result
end

local scissor = tryRequire('scissor')
local color   = tryRequire('color')
local font    = tryRequire('font')
local canvas  = tryRequire('canvas')
local line    = tryRequire('line')

local stack = {}

local floor, min, max, format = math.floor, math.min, math.max, string.format

local function round(x) return floor(x + 0.5) end

local function sum(t)
	local s, len = 0, #t
	for i = 1, len do
		s = s + t[i]
	end
	return s
end

local function ratios(available, ...)
	assert(select('#', ...) > 0)
	local weights = type(...) == 'table' and (...) or {...}
	
	local distributed_amounts = {}
	local total_weights = sum(weights)
	
	for i,weight in ipairs(weights) do
		local p
		if total_weights > 0 then
			p = weight / total_weights
		else
			p = 0
		end
		
		distributed_amount = round(p * available)
		table.insert(distributed_amounts, distributed_amount)
		total_weights = total_weights - weight
		available = available - distributed_amount
	end
	
	return distributed_amounts
end

local function getBounds(c)
	if c then
		c = captures[captureIndex[c] or false]
		if c then return unpack(c[2]) end
		return nil
	end
	return unpack(stack[#stack])
end

local function getRectangle(c)
	local x1, y1, x2, y2 = getBounds(c)
	if x1 then return x1, y1, x2 - x1, y2 - y1 end
	return nil
end

local function getPosition(c)
	local x, y = getBounds(c)
	return x, y
end

local function getDimensions(c)
	local x1, y1, x2, y2 = getBounds(c)
	if x1 then return x2 - x1, y2 - y1 end
	return nil
end

local function getX(c)
	return (getBounds(c))
end

local function getY(c)
	return select(2, getBounds(c))
end

local function getWidth(c)
	local x1, y1, x2, y2 = getBounds(c)
	if x1 then return x2 - x1 end
	return nil
end

local function getHeight(c)
	local x1, y1, x2, y2 = getBounds(c)
	if x1 then return y2 - y1 end
	return nil
end

local lgw, lgh = love.graphics.getWidth, love.graphics.getHeight
local function getScreenWidth()
	local c = canvas.get()
	if c then return c:getWidth() end
	return lgw()
end
local function getScreenHeight()
	local c = canvas.get()
	if c then return c:getHeight() end
	return lgh()
end
local function push(x1, y1, x2, y2)
	assert(#stack < stackLimit, 'boundaries.push(): Stack limit exeeded. Did you forget a boundaries.pop()?')
	x1, y1 = x1 or 0, y1 or 0
	x2, y2 = x2 or (getScreenWidth() + x1), y2 or (getScreenHeight() + y1)
	table.insert(stack, {x1, y1, x2, y2})
end

local function pop(n)
	n = n or 1
	assert(#stack >= n, 'boundaries.pop(): Popped too many times.')
	local len = #stack + 1
	for i = 1, n do
		stack[len - i] = nil
	end
end

local cantParse = 'boundaries.pixelLengths(): Can not parse weight #%d: \'%s\''

local parseNumber = {
	['([%d%.%-%+]+)%s*px'] = function(number)
		return tonumber(number)
	end,
	['([%d%.%-%+]+)%s*%%'] = function(number, w)
		local n, err = tonumber(number)
		if not n then return nil, err end
		return w * n / 100
	end
}
local function pixelLengths(r, w)
	-- if the ratio is just a number then fill up a table with ones
	if type(r) == 'number' then
		local t = {}
		for i = 1, r do
			t[i] = 1
		end
		r = t
	end
	
	-- parse values with modifiers and store them, store weights in a different table
	local widths, weights = {}, {}
	local wTotal = w
	for i,v in ipairs(r) do
		if type(v) == 'string' then
			local m, parser
			for k,p in pairs(parseNumber) do
				m = v:lower():match(k)
				if m then
					parser = p
					break
				end
			end
			assert(m, cantParse:format(i, v))
			
			widths[i] = round(assert(parser(m, wTotal), cantParse:format(i, v)))
			w = w - widths[i]
		else
			table.insert(weights, v)
		end
	end
	
	-- turn weights into pixel lenghts and put them in the gaps
	local j = 1
	for _,v in ipairs(ratios(w, weights)) do
		while widths[j] do j = j + 1 end
		widths[j] = v
	end
	
	return widths
end

-- split up the current bounds into rectangles based on the supplied weights
local function grid(rh, rv)
	local x1, y1, x2, y2 = getBounds()
	rh, rv = pixelLengths(rh, x2 - x1), pixelLengths(rv, y2 - y1)
	rhLen, rvLen = #rh, #rv
	
	-- push the rectangles onto the stack in reverse order
	local lastBorderV = y2
	for j = rvLen, 1, -1 do
		local currentBorderV = lastBorderV - rv[j]
		local lastBorderH = x2
		for i = rhLen, 1, -1 do
			local currentBorderH = lastBorderH - rh[i]
			push(currentBorderH, currentBorderV, lastBorderH, lastBorderV)
			lastBorderH = currentBorderH
		end
		lastBorderV = currentBorderV
	end
	
	-- return iterator
	local i, len = 0, rhLen * rvLen
	return function()
		i = i + 1
		if i > len then
			pop()
			return nil
		end
		if i ~= 1 then pop() end
		return (i - 1) % rhLen + 1, floor((i - 1) / rhLen) + 1
	end
end

-- split up the current bounds into rectangles based on the supplied weights
local function slice(layout, r)
	layout = layout == 'horizontal'
	if layout then
		grid(r, 1)
	else
		grid(1, r)
	end
	
	-- return iterator
	local i, len = 0, type(r) == 'number' and r or #r
	return function()
		i = i + 1
		if i > len then
			pop()
			return nil
		end
		if i ~= 1 then pop() end
		return i, layout and getWidth() or getHeight()
	end
end

local function _pad(top, right, bottom, left)
	local x1, y1, x2, y2 = getBounds()
	if type(top) == 'number' then top = top * 100 .. '%' end
	if type(right) == 'number' then right = right * 100 .. '%' end
	if type(bottom) == 'number' then bottom = bottom * 100 .. '%' end
	if type(left) == 'number' then left = left * 100 .. '%' end
	local h = pixelLengths({left, right}, x2 - x1)
	local v = pixelLengths({top, bottom}, y2 - y1)
	push(x1 + h[1], y1 + v[1], x2 - h[2], y2 - v[2])
end

local padArgs = {
	function(all)
		_pad(all, all, all, all)
	end,
	function(tb, lr)
		_pad(tb, lr, tb, lr)
	end,
	function(top, lr, bottom)
		_pad(top, lr, bottom, lr)
	end,
	_pad,
}

local function pad(...)
	local f = padArgs[select('#', ...)]
	assert(f, 'boundaries.pad(): invalid number of arguments')
	f(...)
end

local a = {left = 0, top = 0, center = 0.5, right = 1, bottom = 1}
local function align(horizontal, vertical, w, h)
	horizontal = a[horizontal] or horizontal
	vertical = a[vertical] or vertical
	w, h = round(w), round(h)
	
	local rx, ry, rw, rh = getRectangle()
	
	if rw < w then horizontal = 0.5 end
	if rh < h then vertical = 0.5 end
	
	local left, right = unpack(ratios(rw - w, horizontal, 1 - horizontal))
	local top, bottom = unpack(ratios(rh - h, vertical, 1 - vertical))
	
	local x1, y1 = rx + left, ry + top
	local x2, y2 = x1 + w, y1 + h
	push(x1, y1, x2, y2)
end

local function translate(x, y)
	local s = stack[#stack]
	push(s[1] + x, s[2] + y, s[3] + x, s[4] + y)
end

local releaseCallback = {
	[false] = setmetatable({}, weakKeys),
	[true]  = setmetatable({}, weakKeys),
}

local checkRelation
checkRelation = {
	self = function(self, other)
		return self == other and 0 or false
	end,
	super = function(self, other)
		local t = self
		local i = 0
		while t do
			if other == t then return i end
			t = t.parent
			i = i - 1
		end
		return false
	end,
	sub = function(self, other)
		local t = other
		local i = 0
		while t do
			if self == t then return i end
			t = t.parent
			i = i + 1
		end
		return false
	end,
	any = function(self, other)
		return checkRelation.sub(self, other) or checkRelation.super(self, other)
	end,
}

local function isHovered(self, type)
	local rel = assert(checkRelation[type or 'self'], format('boundaries.isHovered(): invalid hover type \'%s\'', type))
	return rel(self, hovered)
end

local function clearCaptures()
	captures      = {}
	captureIndex = setmetatable({}, weakKeys)
end
clearCaptures()

local function capture(t)
	local i = #captures + 1
	captures[i] = {t, stack[#stack], {scissor.get()}}
	captureIndex[t] = i
end

local function getFocused()
	return focused
end

local function setFocused(t)
	focused = t
end

local function isFocused(self, type)
	local rel = assert(checkRelation[type or 'self'], format('boundaries.isFocused(): invalid focus type \'%s\'', type))
	return rel(self, focused)
end

local function defocus(t)
	if not t or isFocused(t) then focused = nil end
end

local function focus(t)
	if focused ~= t and captureIndex[t] then
		local allow = true
		if focused and focused.focus then
			allow = focused:focus(false, t)
			if allow == nil then allow = true end
		end
		if allow then
			if t and t.focus then
				allow = t:focus(true, focused)
				if allow == nil then allow = true end
			end
			if allow then
				focused = t
				return true
			end
		end
	end
	return false
end

local function findActive(cbt, t)
	for k,v in pairs(cbt) do if v[1] == t then return true end end
end

local function isActive(t)
	if not t then
		for k,v in pairs(releaseCallback[false]) do return true end
		for k,v in pairs(releaseCallback[true]) do return true end
	end
	return findActive(releaseCallback[false], t) or findActive(releaseCallback[true], t) or false
end

local function mousepressed(x, y, button, istouch, ...)
	local i = captureIndex[hovered or false]
	if i then
		local t, stack, s = unpack(captures[i])
		push(unpack(stack))
		scissor.push(unpack(s))
		focus(t)
		if focused == t then
			if t.mousepressed and t:mousepressed(x, y, button, istouch, ...) or t.mousepressed == nil then
				releaseCallback[istouch][button] = captures[i]
			end
		end
		scissor.pop()
		pop()
	end
end

local function mousereleased(x, y, button, istouch, ...)
	local cb = releaseCallback[istouch][button]
	if cb then
		local t, stack, s = unpack(cb)
		if t.mousereleased and captureIndex[t] then
			push(unpack(stack))
			scissor.push(unpack(s))
			t:mousereleased(x, y, button, istouch, ...)
			scissor.pop()
			pop()
		end
	end
	releaseCallback[istouch][button] = nil
end

local keyReleaseCallback = setmetatable({}, weakKeys)

local function keypressed(key, ...)
	local i = captureIndex[focused or false]
	if i then
		local t, stack, s = unpack(captures[i])
		while t do
			i = captureIndex[t]
			if i then
				local t, stack, s = unpack(captures[i])
				push(unpack(stack))
				scissor.push(unpack(s))
				if t.keypressed and t:keypressed(key, ...) or t.keypressed == nil then
					keyReleaseCallback[key] = captures[i]
					scissor.pop()
					pop()
					return
				end
				scissor.pop()
				pop()
			end
			t = t.parent
		end
	end
end

local function keyreleased(key, ...)
	local cb = keyReleaseCallback[key]
	if cb then
		local t, stack, s = unpack(cb)
		if t.keyreleased and captureIndex[t] then
			push(unpack(stack))
			scissor.push(unpack(s))
			t:keyreleased(key, ...)
			scissor.pop()
			pop()
		end
	end
	releaseCallback[key] = nil
end

local function textinput(...)
	local i = captureIndex[focused or false]
	if i then
		local t, stack, s = unpack(captures[i])
		while t do
			i = captureIndex[t]
			if i then
				local t, stack, s = unpack(captures[i])
				push(unpack(stack))
				scissor.push(unpack(s))
				if t.textinput and t:textinput(...) or t.textinput == nil then
					scissor.pop()
					pop()
					return
				end
				scissor.pop()
				pop()
			end
			t = t.parent
		end
	end
end

local function mousemoved(...)
	local i = captureIndex[focused or false]
	if i and focused.mousemoved then
		local t, stack, s = unpack(captures[i])
		push(unpack(stack))
		scissor.push(unpack(s))
		t:mousemoved(...)
		scissor.pop()
		pop()
	end
end

local function wheelmoved(...)
	local i = captureIndex[hovered or false]
	if i and hovered.wheelmoved then
		local t, stack, s = unpack(captures[i])
		push(unpack(stack))
		scissor.push(unpack(s))
		t:wheelmoved(...)
		scissor.pop()
		pop()
	end
end

local function isInAABB(x, y, x1, y1, x2, y2) return x >= x1 and x < x2 and y >= y1 and y < y2 end

local function isInScissor(x, y)
	local x1, y1, x2, y2 = scissor.get()
	if x1 then return isInAABB(x, y, x1, y1, x2, y2) end
	return true
end

local function isInBounds(x, y)
	return isInAABB(x, y, getBounds())
end

local function mousehover(x, y)
	for i = #captures, 1, -1 do
		local t, stack, s = unpack(captures[i])
		push(unpack(stack))
		scissor.push(unpack(s))
		
		if isInScissor(x, y) and
		(t.mousehover and t:mousehover(x, y)) or
		(not t.mousehover and isInBounds(x, y)) then
			hovered = t
			
			scissor.pop()
			pop()
			return
		end
		
		scissor.pop()
		pop()
	end
	hovered = nil
end

local imageMode = {
	fit = function (img)
		local x, y, w, h = getRectangle()
		local iw, ih = img:getDimensions()
		local sx, sy = w / iw, h / ih
		local scale = min(sx, sy)
		love.graphics.draw(img, round(x + (w - iw * scale) / 2), round(y + (h - ih * scale) / 2), 0, scale)
	end,
	fill = function (img)
		local x, y, w, h = getRectangle()
		local iw, ih = img:getDimensions()
		local sx, sy = w / iw, h / ih
		local scale = max(sx, sy)
		love.graphics.draw(img, round(x + (w - iw * scale) / 2), round(y + (h - ih * scale) / 2), 0, scale)
	end,
	stretch = function (img)
		local x, y, w, h = getRectangle()
		local iw, ih = img:getDimensions()
		local sx, sy = w / iw, h / ih
		love.graphics.draw(img, round(x + (w - iw * sx) / 2), round(y + (h - ih * sy) / 2), 0, sx, sy)
	end,
	texture = function(img, horizontal, vertical)
		local iw, ih = img:getDimensions()
		local x, y, w, h = getRectangle()
		local wr, hr = math.ceil(w / iw), math.ceil(h / ih)
		
		local offx, offy = w * horizontal % iw, h * vertical % ih
		
		scissor.pushIntersect(x, y, w, h)
		for y = 0, hr + 1 do
			for x = 0, wr + 1 do
				love.graphics.draw(img, round((x - 1) * iw + offx), round((y - 1) * ih + offy))
			end
		end
		scissor.pop()
	end
}

local function image(mode, img, ...)
	imageMode[mode or 'fit'](img, ...)
end

local function solid(r, g, b, a)
	color.push(r, g, b, a or 1)
	love.graphics.rectangle('fill', getRectangle())
	color.pop()
end

local function outline(width, r, g, b, a)
	local x, y, w, h = getRectangle()
	if width * 2 >= w or width * 2 >= h then
		solid(r, g, b, a)
		return
	end
	
	color.push(r, g, b, a or 1)
	local lw2 = width / 2
	line.pushWidth(width)
	love.graphics.rectangle('line', x + lw2, y + lw2, w - width, h - width)
	line.popWidth()
	color.pop()
end

local function stripes(width, angle)
	angle = angle or -math.pi / 4
	local x, y, w, h = getRectangle()
	local len = (math.sqrt(w * w + h * h) + width) / 2
	x, y = round(x + w / 2), round(y + h / 2)
	local nx, ny = math.cos(angle), math.sin(angle)
	local offx, offy = nx * len, ny * len
	local offlx, offly = ny * width * 2, -nx * width * 2
	scissor.pushIntersect(getRectangle())
	line.pushWidth(width)
	local limit = math.ceil(len / width / 2)
	for i = -limit, limit do
		love.graphics.line(
			x - offx + offlx * i, y - offy + offly * i,
			x + offx + offlx * i, y + offy + offly * i
		)
	end
	line.popWidth()
	scissor.pop()
end

local function label(text, horizontal, vertical)
	text = tostring(text)
	local f = font.get()
	local w, h = f:getWidth(text), f:getHeight()
	align(horizontal, vertical, w, h)
		love.graphics.print(text, getPosition())
	pop()
end

local function update(dt)
	for i = #captures, 1, -1 do
		local t, stack, s = unpack(captures[i])
		push(unpack(stack))
		scissor.push(unpack(s))
		if t.update then t:update(dt) end
		scissor.pop()
		pop()
	end
	mousehover(love.mouse.getPosition())
	
	if hovered then
		local c = hovered.cursor
		if type(c) == 'function' then c = c(hovered) end
		if type(c) == 'string' then c = love.mouse.getSystemCursor(c) end
		if not c then c = love.mouse.getSystemCursor('arrow') end
		setCursor(c)
	else
		setCursor()
	end
	
	clearCaptures()
end

return setmetatable({
	stack = stack,
	ratios = ratios,
	getBounds = getBounds,
	pop = pop,
	next = pop,
	push = push,
	ratios = ratios,
	slice = slice,
	grid = grid,
	pad = pad,
	getRectangle = getRectangle,
	getPosition = getPosition,
	getDimensions = getDimensions,
	getX = getX,
	getY = getY,
	getWidth = getWidth,
	getHeight = getHeight,
	isHovered = isHovered,
	align = align,
	translate = translate,
	image = image,
	solid = solid,
	outline = outline,
	stripes = stripes,
	label = label,
	capture = capture,
	mousepressed = mousepressed,
	mousereleased = mousereleased,
	mousemoved = mousemoved,
	wheelmoved = wheelmoved,
	keypressed = keypressed,
	keyreleased = keyreleased,
	textinput = textinput,
	focus = focus,
	defocus = defocus,
	isActive = isActive,
	getFocused = getFocused,
	setFocused = setFocused,
	isFocused = isFocused,
	clearCaptures = clearCaptures,
	update = update,
	getStackLimit = getStackLimit,
	setStackLimit = setStackLimit,
}, {
	__index = function(t, k)
		local mod = tryRequire(k)
		if mod then t[k] = mod end
		return mod
	end,
	__call = function(t, limit)
		setStackLimit(limit)
		return t
	end
})