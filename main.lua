local bounds = require 'boundaries'
local button = require 'boundaries.button'
local color  = require 'boundaries.color'
local font   = require 'boundaries.font'

local fontBig

local example
local examples = require 'examples.list'

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

function love.load(arg)
	fontBig = love.graphics.newFont(24)
	
	buttons = {}
	for _,p in ipairs(examples) do
		local b = button()
		b.path = p
		b.action = action
		b.draw = draw
		b.font = font
		
		table.insert(buttons, b)
	end
end

local function picker()
	bounds.clearCaptures()
	
	bounds.push()
	
	local r = {}
	for i = 1, #buttons do r[i] = 1 end
	
	bounds.slice('vertical', r)
	for _,b in ipairs(buttons) do
		bounds.align('center', 'center', bounds.getWidth() - 32, 50)
		b:place()
		bounds.pop()
		bounds.next()
	end
	
	bounds.pop()
end

function love.update(dt)
	bounds.update(dt)
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