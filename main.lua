--https://stackoverflow.com/questions/1426954/split-string-in-lua
function split(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

--http://lua-users.org/wiki/SimpleRound
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function love.load()
    cursor = {x = 0, y = 0}
    local mapFile, size = love.filesystem.read("maps/zekk_calling.txt")
    local mapLines = split(mapFile, "\n")
    timings = {}
    for i,line in ipairs(mapLines) do
        local tokens = split(line, ",")
        table.insert(timings, tokens[3])
    end
    index = 1
    -- objects show up in the following order
    oldObject = {x = 0, y = 0}
    nextObject = {x = 0, y = 1}
    afterObject = {x = 0, y = 2}
    nextKey = ""
    nextObjectApproachProgress = 0
    tick = require "tick" 
    song = love.audio.newSource("maps/zekk_calling.mp3", "stream")

    local startDelay = 0
    tick.delay(function () song:play() end, startDelay)
    start = love.timer.getTime() + startDelay  --wait three seconds

    hitSound = love.audio.newSource("resources/normal-hitnormal.wav", "static")

    math.randomseed(os.time())

    love.audio.setVolume(0.1)
    MAX_Y = 5
    MAX_X = 5

    hit = 0
    total = 0
    love.window.setMode((MAX_X + 1) * 100, (MAX_Y + 1) * 100)
end

function drawCenteredSquare(x, y, size, color, style)
    style = style or "line"
    color = color or {1, 1, 1}
    love.graphics.setColor(color[1], color[2], color[3])
    local offset = (100 - size) / 2
    love.graphics.rectangle(style, x * 100 + offset, y * 100 + offset, size, size)
    love.graphics.setColor(1, 1, 1)
end

function love.draw()
    local offset = 32 -- text offset
    for i=0,MAX_X do
        for j=0,MAX_Y do
            local symbol = "#"
            if i == cursor.x then
                symbol = math.abs(cursor.y - j)
            elseif j == cursor.y then
                symbol = math.abs(cursor.x - i)
            end
            love.graphics.print(symbol, i * 100 + offset, j * 100 + offset, 0, 2)
        end
    end
    love.graphics.rectangle("fill", 100 * cursor.x, 100 * cursor.y, 100, 100)
    love.graphics.rectangle("line", nextObject.x * 100 + 25, nextObject.y * 100 + 25, 50, 50)
    love.graphics.print({{0, 0, 0}, nextKey}, 100 * cursor.x + offset, 100 * cursor.y + offset, 0, 2)
    if cursor.x == oldObject.x and cursor.y == oldObject.y then
        if didHit == true then
            love.graphics.setColor(0, 0, 1)
        else
            love.graphics.setColor(1, 0, 0)
        end
        love.graphics.rectangle("fill", oldObject.x * 100 + 25, oldObject.y * 100 + 25, 50, 50)
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.rectangle("line", afterObject.x * 100 + 35, afterObject.y * 100 + 35, 30, 30)
    if nextObjectApproachProgress > 0 then
        drawCenteredSquare(nextObject.x, nextObject.y, 50 * nextObjectApproachProgress)
    end
    love.graphics.print({{1, 0, 0}, tostring(round(100 * hit / total, 2)).."%"}, 0, 0, 0, 2)
end

function love.keypressed(key)
    if key == "h" and cursor.x > 0 then
        cursor.x = cursor.x - 1
    elseif key == "j" and cursor.y < MAX_Y then
        cursor.y = cursor.y + 1
    elseif key == "k" and cursor.y > 0 then
        cursor.y = cursor.y - 1
    elseif key == "l" and cursor.x < MAX_X then
        cursor.x = cursor.x + 1
    end
    hitSound:play()
end

function love.update(dt)
    tick.update(dt)
    local adjustedTime = (love.timer.getTime() - start) * 1000 
    if adjustedTime > tonumber(timings[index]) then
        index = index + 1
        total = total + 1
        if cursor.x == nextObject.x and cursor.y == nextObject.y then
            didHit = true
            hit = hit + 1
        else
            didHit = false
        end
        local options = {j = {0, 1}, l = {1,0}, h = {-1,0}, k = {0,-1}}
        local inBoundsOptions = {}
        for key, option in pairs(options) do
            if afterObject.x + option[1] >= 0 and afterObject.x + option[1] <= MAX_X and afterObject.y + option[2] >= 0 and afterObject.y + option[2] <= MAX_Y then
                table.insert(inBoundsOptions, key)
            end
        end
        nextKey = inBoundsOptions[math.random(1, #inBoundsOptions)]
        local objChange = options[nextKey]
        oldObject.x = nextObject.x
        oldObject.y = nextObject.y
        nextObject.x = afterObject.x
        nextObject.y = afterObject.y
        afterObject.x = afterObject.x + objChange[1]
        afterObject.y = afterObject.y + objChange[2]
    end   
    nextObjectApproachProgress = 1 - (tonumber(timings[index]) - adjustedTime) / 1000
end
