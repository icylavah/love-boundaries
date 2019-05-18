local bounds = require 'boundaries'
local button = bounds.button
local color  = bounds.color
local font   = bounds.font

local fontBig

local example
local examples = require 'examples.list'

local root
local buttons
local function action(self) example = require(self.path)() end
local function draw(self)
	bounds.solid(1, 1, 1)
	color.push(0, 0, 0)
	font.push(fontBig)
	bounds.label(self.path, 'center', 'center')
	font.pop()
	color.pop()
end

local function text(self)
	return self.path
end

function love.load(arg)
	fontBig = love.graphics.newFont(24)
	love.keyboard.setKeyRepeat(true)
	
	root = bounds.basic:new()
	
	buttons = {}
	for _,p in ipairs(examples) do
		local b = button:new()
		b.path = p
		b.action = action
		b.text = text
		b.font = fontBig
		b.parent = root
		
		table.insert(buttons, b)
	end
	
	root.next = buttons[1]
	root.previous = buttons[#buttons]
	root.keymap = {
		escape = function(self)
			love.event.quit()
		end
	}
	root.backgroundColor = {0, 0, 0, 0}
	bounds.setFocused(root)
	
	for i,b in ipairs(buttons) do
		b.next = buttons[(i - 1 + 1) % #buttons + 1]
		b.previous = buttons[(i - 1 - 1 + #buttons) % #buttons + 1]
	end
end

function love.update(dt)
	bounds.update(dt)
end

local function picker()
	bounds.push()
	
	root:place()
	bounds.solid(0.4, 0.4, 0.4, 1)
	
	local r = {}
	for i = 1, #buttons do r[i] = 1 end
	
	bounds.pad(math.min(math.floor(bounds.getWidth() / 2) - 8, 64) .. 'px')
	for i,b in ipairs(buttons) do
		bounds.align('center', (i - 1) / (#buttons - 1), bounds.getWidth(), 50)
		b:place()
		bounds.pop()
	end
	bounds.pop()
	
	bounds.pop()
end

function love.draw()
	if example then
		example()
	else
		picker()
	end
end

function love.mousepressed(...)
	bounds.mousepressed(...)
end

function love.mousereleased(...)
	bounds.mousereleased(...)
end

function love.keypressed(...)
	bounds.keypressed(...)
end

function love.keyreleased(...)
	bounds.keyreleased(...)
end

function love.textinput(...)
	bounds.textinput(...)
end

function love.mousemoved(...)
	bounds.mousemoved(...)
end

function love.wheelmoved(...)
	bounds.wheelmoved(...)
end