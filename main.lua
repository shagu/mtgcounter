-- include core functions
require "framestack"
require "framestack/mouse"

-- widgets
require "framestack/color"
require "framestack/font"
require "framestack/resize"

-- set the default font to joti-one:
-- https://fonts.google.com/specimen/Joti+One
local font = "res/JotiOne.ttf"

-- register framestack to love update
function love.load()
  framestack:init()
end

-- slowly fade back to given color
local function fadecolor(frame, r, g, b, a, step)
  for id, val in pairs({ r, g, b, a}) do
    if frame.color[id] - step > val then
      frame.color[id] = frame.color[id] - step
    elseif frame.color[id] + step < val then
      frame.color[id] = frame.color[id] + step
    else
      frame.color[id] = val
    end
  end
end

-- create new counter
local function newcounter(name, rotate)
  local counter = framestack:new(1, name, "color", "resize")

  counter.life = counter:new(4, name.."Text", "font", "resize")
  counter.life.font = love.graphics.newFont(font, 72)
  counter.life.text = "20"
  counter.life.rotate = rotate and math.pi or 0

  counter.increase = counter:new(5, name.."ButtonIncrease", "font", "resize")
  counter.increase.font = love.graphics.newFont(font, 32)
  counter.increase.mouse = true
  counter.increase.offset = { rotate and .1 or 0, .1, rotate and 0 or .1, .6}

  counter.decrease = counter:new(5, name.."ButtonDecrease", "font", "resize")
  counter.decrease.font = love.graphics.newFont(font, 32)
  counter.decrease.mouse = true
  counter.decrease.offset = { rotate and .1 or 0, .6, rotate and 0 or .1, .1}

  local plus = rotate and counter.decrease or counter.increase
  plus.text = "[+]"
  plus.color = { .5, 1, .5, 1}
  plus:on("click", function(self, event, x, y, button)
    counter.life.text = counter.life.text + 1
    counter.color[2] = .5
  end)

  local minus = rotate and counter.increase or counter.decrease
  minus.text = "[-]"
  minus.color = { 1, .5, .5, 1}
  minus:on("click", function(self, event, x, y, button)
    counter.life.text = counter.life.text - 1
    counter.color[1] = .5
  end)

  counter:on("draw", function()
    fadecolor(counter, .1, .1, .1, 1, .1)
  end)

  return counter
end

-- create lifecounters
local top = newcounter("player1", true)
top.offset = { 0, 0, .55, 0 }

local bottom = newcounter("player2")
bottom.offset = { .55, 0, 0, 0 }

-- create middle panel
local dice = framestack:new(1, "Dice", "color", "resize")
dice.color = { .2, .2, .2, 1 }
dice.offset = { .45, 0, .45, 0 }

-- add reset button
dice.reset = dice:new(5, "Reset", "font", "resize")
dice.reset.mouse = true
dice.reset.font = love.graphics.newFont(font, 32)
dice.reset.text = "[=]"
dice.reset.color = { 1, 1, 1, .5 }
dice.reset:on("click", function()
  -- reset health
  top.life.text = 20
  bottom.life.text = 20

  -- flash colors
  top.color = { 1, 1, 1, 0 }
  bottom.color = { 1, 1, 1, 0 }
end)
