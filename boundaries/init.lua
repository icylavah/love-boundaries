local stackLimit = 256

local scissor = require(... .. '.scissor')
local color = require(... .. '.color')
local font = require(... .. '.font')

local stack = {}

local floor, min, max = math.floor, math.min, math.max

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

local function getBounds()
	return unpack(stack[#stack])
end

local function getRectangle()
	local x1, y1, x2, y2 = getBounds()
	return x1, y1, x2 - x1, y2 - y1
end

local function getPosition()
	local x, y = getBounds()
	return x, y
end

local function getDimensions()
	local x1, y1, x2, y2 = getBounds()
	return x2 - x1, y2 - y1
end

local function getX()
	return (getBounds())
end

local function getY()
	return select(2, getBounds())
end

local function getWidth()
	local x1, y1, x2, y2 = getBounds()
	return x2 - x1
end

local function getHeight()
	local x1, y1, x2, y2 = getBounds()
	return y2 - y1
end

local lgw, lgh = love.graphics.getWidth, love.graphics.getHeight
local function push(x1, y1, x2, y2)
	assert(#stack < stackLimit, 'ui.push(): Stack limit exeeded. Did you forget a ui.pop()?')
	x1, y1, x2, y2 = x1 or 0, y1 or 0, x2 or lgw(), y2 or lgh()
	table.insert(stack, {x1, y1, x2, y2})
end

local function pop(n)
	n = n or 1
	assert(#stack >= n, 'bounds.pop(): Popped too many times.')
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
	if not f then
		assert('boundaries.pad(): invalid number of arguments')
	end
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

local function isInBounds(x, y)
	local x1, y1, x2, y2 = getBounds()
	local sx1, sy1, sw, sh = scissor.get()
	if sx1 then
		sx2, sy2 = sx1 + sw, sy1 + sh
		x1, y1, x2, y2 = max(x1, sx1), max(y1, sy1), min(x2, sx2), min(y2, sy2)
	end
	return x >= x1 and x < x2 and y >= y1 and y < y2
end

local function isHovered(checker, ...)
	local mx, my = love.mouse.getPosition()
	return checker(mx, my, ...)
end

local releaseCallback = {
	[false] = {},
	[true] = {}
}

local captures, focused

local function clearCaptures()
	captures = {}
end
clearCaptures()

local function capture(t)
	captures[#captures + 1] = {t, stack[#stack], {scissor.get()}}
end

local function getFocused()
	return focused
end

local function isFocused(t)
	return t == focused
end

local function defocus(t)
	if not t or isFocused(t) then focused = nil end
end

local function focus(t)
	if focused ~= t then
		if type(t.focus) == 'function' and t:focus(focused) or t.focus ~= false then
			focused = t
		end
	end
end

local function findActive(cbt, t)
	for i = 1, 10 do
		if cbt[i] and cbt[i][1] == t then
			return true
		end
	end
end

local function isActive(t)
	if not t then
		for k,v in pairs(releaseCallback[false]) do return true end
		for k,v in pairs(releaseCallback[true]) do return true end
	end
	return findActive(releaseCallback[false], t) or findActive(releaseCallback[true], t) or false
end

local function mousepressed(x, y, button, istouch, ...)
	for i = #captures, 1, -1 do
		local t, stack, s = unpack(captures[i])
		push(unpack(stack))
		scissor.push(unpack(s))
		local mp = t.mousepressed
		if (type(mp) == 'function' and mp(t, x, y, button, istouch, ...)) or
		(type(mp) == 'table' and mp[button] and (mp[button])(t, x, y, button, istouch, ...)) or
		(mp ~= false and (t.isHovered or isInBounds)(x, y)) then
			releaseCallback[istouch][button] = {t, stack, s}
			focus(t)
			scissor.pop()
			pop()
			break
		end
		scissor.pop()
		pop()
	end
end

local function mousereleased(x, y, button, istouch, ...)
	local cb = releaseCallback[istouch][button]
	if cb then
		local t, stack, s = unpack(cb)
		local mr = t.mousereleased
		if t.mousereleased then
			push(unpack(stack))
			scissor.push(unpack(s))
			if type(mr) == 'function' then
				mr(t, x, y, button, istouch, ...)
			elseif type(mr) == 'table' and mr[button] then
				mr[button](t, x, y, button, istouch, ...)
			end
			scissor.pop()
			pop()
		end
	end
	releaseCallback[istouch][button] = nil
end

local function keypressed(key, ...)
	if focused and focused.keypressed then
		for i = #captures, 1, -1 do
			local t, stack, s = unpack(captures[i])
			if isFocused(t) then
				push(unpack(stack))
				scissor.push(unpack(s))
				if type(focused.keypressed) == 'function' then
					focused.keypressed(t, key, ...)
				elseif type(focused.keypressed) == 'table' and focused.keypressed[key] then
					focused.keypressed[key](t, key, ...)
				end
				scissor.pop()
				pop()
				break
			end
		end
	end
end

local function keyreleased(...)
	if focused and focused.keyreleased then
		for i = #captures, 1, -1 do
			local t, stack, s = unpack(captures[i])
			if isFocused(t) then
				push(unpack(stack))
				scissor.push(unpack(s))
				if type(focused.keyreleased) == 'function' then
					focused.keyreleased(t, key, ...)
				elseif type(focused.keyreleased) == 'table' and focused.keyreleased[key] then
					focused.keyreleased[key](t, key, ...)
				end
				scissor.pop()
				pop()
				break
			end
		end
	end
end

local function textinput(...)
	if focused and focused.textinput then
		for i = #captures, 1, -1 do
			local t, stack, s = unpack(captures[i])
			if isFocused(t) then
				push(unpack(stack))
				scissor.push(unpack(s))
				focused.textinput(t, ...)
				scissor.pop()
				pop()
				break
			end
		end
	end
end

local function mousemoved(...)
	if focused and focused.mousemoved then
		for i = #captures, 1, -1 do
			local t, stack, s = unpack(captures[i])
			if isFocused(t) then
				push(unpack(stack))
				scissor.push(unpack(s))
				focused.mousemoved(t, ...)
				scissor.pop()
				pop()
				break
			end
		end
	end
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
	end
}

local function image(mode, img, ...)
	imageMode[mode or 'fit'](img)
end

local function solid(r, g, b, a)
	color.push(r, g, b, a or 1)
	love.graphics.rectangle('fill', getRectangle())
	color.pop()
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
	clearCaptures()
end

return {
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
	isInBounds = isInBounds,
	isHovered = isHovered,
	align = align,
	translate = translate,
	image = image,
	solid = solid,
	label = label,
	capture = capture,
	mousepressed = mousepressed,
	mousereleased = mousereleased,
	mousemoved = mousemoved,
	keypressed = keypressed,
	keyreleased = keyreleased,
	textinput = textinput,
	focus = focus,
	defocus = defocus,
	isActive = isActive,
	getFocused = getFocused,
	isFocused = isFocused,
	clearCaptures = clearCaptures,
	update = update,
	scissor = scissor,
	color = color,
	font = font,
}