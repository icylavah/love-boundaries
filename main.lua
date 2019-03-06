local bounds = require 'boundaries'
local color = require 'boundaries.color'
local field = require 'boundaries.field'
local flux = require 'flux'

function love.load(arg)
	f = field()
	f.font = love.graphics.newFont(16)
	f.text = "hello world"
end

function love.update(dt)
	
end

function love.draw()
	bounds.clearCaptures()
	
	bounds.push()
	bounds.solid(1, 1, 1, 1)
	f:place()
	bounds.pop()
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