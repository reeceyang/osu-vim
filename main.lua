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
    local mapFile, size = love.filesystem.read("maps/zutomayo.txt")
    local mapLines = split(mapFile, "\n")
    timings = {}
    for i,line in ipairs(mapLines) do
        local tokens = split(line, ",")
        table.insert(timings, tokens[3])
    end
    index = 1
    nextObject = {x = 0, y = 1}
    nextKey = ""
    song = love.audio.newSource("maps/zutomayo.mp3", "stream")
    song:play()
    start = love.timer.getTime()

    hitSound = love.audio.newSource("resources/normal-hitnormal.wav", "static")

    math.randomseed(os.time())

    love.audio.setVolume(0.1)
    MAX_Y = 5
    MAX_X = 7

    hit = 0
    total = 0
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
    if (love.timer.getTime() - start) * 1000 > tonumber(timings[index]) then
        index = index + 1
        total = total + 1
        if cursor.x == nextObject.x and cursor.y == nextObject.y then
            hit = hit + 1
        end
        local options = {j = {0, 1}, l = {1,0}, h = {-1,0}, k = {0,-1}}
        local inBoundsOptions = {}
        for key, option in pairs(options) do
            if nextObject.x + option[1] >= 0 and nextObject.x + option[1] <= MAX_X and nextObject.y + option[2] >= 0 and nextObject.y + option[2] <= MAX_Y then
                table.insert(inBoundsOptions, key)
            end
        end
        nextKey = inBoundsOptions[math.random(1, #inBoundsOptions)]
        local objChange = options[nextKey]
        print(objChange[1], objChange[2])
        nextObject.x = nextObject.x + objChange[1]
        nextObject.y = nextObject.y + objChange[2]
        print(nextObject.x, nextObject.y)
    end   
end
