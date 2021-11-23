-- include core functions
require "framestack"
require "framestack/mouse"

-- widgets
require "framestack/color"
require "framestack/font"
require "framestack/resize"
require "framestack/image"

-- set the default font to joti-one:
-- https://fonts.google.com/specimen/Joti+One
local font = "res/JotiOne.ttf"

-- dice-roll number to word associations
local num2word = {
  "One", "Two", "Three", "Four", "Five",
  "Six", "Seven", "Eight", "Nine", "Ten",
  "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen",
  "Sixteen", "Seventeen", "Eighteen", "Nineteen", "Twenty",
}

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
  counter.life.offset = { .1, .1, .1, .1 }

  counter.increase = counter:new(5, name.."ButtonIncrease", "font", "resize")
  counter.increase.font = love.graphics.newFont(font, 32)
  counter.increase.mouse = true
  counter.increase.offset = { .1, .1, .1, .6}

  counter.decrease = counter:new(5, name.."ButtonDecrease", "font", "resize")
  counter.decrease.font = love.graphics.newFont(font, 32)
  counter.decrease.mouse = true
  counter.decrease.offset = { .1, .6, .1, .1}

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
local panel = framestack:new(1, "panel", "color", "resize")
panel.color = { .2, .2, .2, 1 }
panel.offset = { .45, 0, .45, 0 }

local popup = framestack:new(10, "PopUp", "color", "resize")
popup.show = nil
popup.color = { 0, 0, 0, .9 }
popup.mouse = true
popup.display = function(self, mode)
  popup.mode = mode
  popup.flipto = nil

  if mode == "coin" then
    popup.roll.icon.image = "res/coin.png"
    popup.roll.icontext.text = ""
    popup.roll.text.text = "Flip!"
  else
    popup.roll.icon.image = "res/w20.png"
    popup.roll.icontext.text = "20"
    popup.roll.text.text = "Roll!"
  end

  popup.roll.icon.rotate = 0
  popup.show = true
end

popup:on("click", function()
  popup.show = nil
end)

popup.roll = popup:new(11, "PopUpRoll", "color", "resize")
popup.roll.color = { .1, .1, .1, 1 }
popup.roll.offset = { .25, .1, .25, .1 }
popup.roll.mouse = true

popup.roll.text = popup.roll:new(12, nil, "font", "resize")
popup.roll.text.offset = { .5, .3, .1, .3 }
popup.roll.text.font = love.graphics.newFont(font, 48)

popup.roll.icon = popup.roll:new(12, "PanelDiceButtonIcon", "image", "resize")
popup.roll.icon.offset = { .2, .3, .4, .3 }

popup.roll.icontext = popup.roll:new(12, nil, "font", "resize")
popup.roll.icontext.offset = { .2, .3, .4, .3 }
popup.roll.icontext.font = love.graphics.newFont(font, 48)

popup.roll:on("click", function()
  popup.flipto = love.timer.getTime() + .5 + math.random()
  popup.roll.color = { 1, 1, 1, .5 }
end)

popup.roll:on("draw", function()
  fadecolor(popup.roll, .1, .1, .1, 1, .1)
  if not popup.flipto then return end

  local running = love.timer.getTime() < popup.flipto

  if popup.mode == "coin" then
    if running then
      popup.roll.state = not popup.roll.state
      popup.roll.text.text = "..."
      popup.roll.icon.image = popup.roll.state and "res/coin.png" or "res/coin_head.png"
    else
      popup.roll.icon.image = popup.roll.state and "res/coin.png" or "res/coin_head.png"
      popup.roll.text.text = popup.roll.state and "Tail" or "Head"
    end
  else
    if running then
      popup.roll.icon.rotate = math.random(20)
      popup.roll.icontext.text = math.random(20)
      popup.roll.text.text = "..."
    else
      popup.roll.icon.rotate = 0
      popup.roll.text.text = num2word[popup.roll.icontext.text]
    end
  end
end)

-- add flip coin button
panel.coin = panel:new(5, "PanelCoinButton", "resize")
panel.coin.mouse = true
panel.coin.offset = { 0, .6, 0, .1 }
panel.coin:on("click", function()
  popup:display("coin")
end)

panel.coin.icon = panel.coin:new(6, "PanelCoinButtonIcon", "image", "resize")
panel.coin.icon.image = "res/coin.png"
panel.coin.icon.offset = { .25, .25, .25, .25 }

-- add reset button
panel.reset = panel:new(5, "PanelResetButton", "resize")
panel.reset.mouse = true
panel.reset.offset = { 0, .4, 0, .4 }
panel.reset:on("click", function()
  -- reset health
  top.life.text = 20
  bottom.life.text = 20

  -- flash colors
  top.color = { 1, 1, 1, 0 }
  bottom.color = { 1, 1, 1, 0 }
end)

panel.reset.icon = panel.reset:new(6, "PanelResetButtonIcon", "image", "resize")
panel.reset.icon.image = "res/reset.png"
panel.reset.icon.offset = { .25, .25, .25, .25 }

-- add dice roll button
panel.dice = panel:new(5, "PanelDiceButton", "resize")
panel.dice.mouse = true
panel.dice.offset = { 0, .1, 0, .6 }
panel.dice:on("click", function()
  popup:display("dice")
end)

panel.dice.icon = panel.dice:new(6, "PanelDiceButtonIcon", "image", "resize")
panel.dice.icon.image = "res/dice.png"
panel.dice.icon.offset = { .25, .25, .25, .25 }
