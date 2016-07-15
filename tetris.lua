gameBoard = {}
currentBlocks = {}
populationWeights = {}
popNumber = 1
generation = 1
blockRotations = {[134]=1, [131]=0, [133]=3, [132]=3, [130]=1, [129]=3, [138]=1, [128]=1}
math.randomseed(os.time())

local f = io.open("population.txt", "r")
for line in f:lines() do
  populationWeights[#populationWeights+1] = {}
  for w in line:gmatch("%S+") do
    table.insert(populationWeights[#populationWeights],w)
  end
end
f:close()


ButtonNames = {
  "A",
  "B",
  "Left",
  "Right",
}

function moveTo(counter)
  local controller = {["A"]=false, ["B"]=false, ["Left"]=false, ["Right"]=false, ["Down"]=false}
  while counter ~= 0 do
    if counter < 0 then
      controller["Left"] = true
      counter = counter + 1
    else
      controller["Right"] = true
      counter = counter - 1
    end
    joypad.set(controller)
    advanceFrame(13)
  end
  controller = {["A"]=false, ["B"]=false, ["Left"]=false, ["Right"]=false, ["Down"]=true}
  local ready = false
  while ready == false do
    if memory.readbyte(0x20) == 255 then
        ready = true
    end
    currentBlocks = getCurrentBlocks()
    for i=0,3 do
      --console.writeline(blocks[i].x .. " " .. blocks[i].y)
      if currentBlocks[i].x == 4 and currentBlocks[i].y == 16 then
        ready = true
        --console.writeline("Next block!")
      end
    end
    joypad.set(controller)
    emu.frameadvance()
  end
  clearJoypad()
end

function clearJoypad()
	controller = {}
	for b = 1,#ButtonNames do
		controller[ButtonNames[b]] = false
	end
	joypad.set(controller)
end

function getGameBoard()
  --console.writeline("Getting gameBoard!")
  --local newTiles = tiles
  for row=1,17 do
    for column=2,11 do
      tile = memory.readbyte(2048+row*32+column)
      if tile ~= 0x2F then
        gameBoard[column-2][17-row] = true
      else
        --console.writeline(column-2 .. " " .. 17-row)
        gameBoard[column-2][17-row] = false
      end
    end
  end
end

function getHeuristics(gameBoard) --takes a gameBoard and returns: lines, height, bumpy, Holes
  local lines = {true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true}
  lines[0] = true
  local aggregateHeight = 0
  local numberInColumn = {0,0,0,0,0,0,0,0,0}
  numberInColumn[0] = 0
  local maximum = {0,0,0,0,0,0,0,0,0}
  maximum[0] = 0
  for i=0,9 do
    for j=0,16 do
      if gameBoard[i][j] then --if there's a block there
        if (j+1)>maximum[i] then --if it's higher than the previous maximum
          maximum[i] = (j+1)
        end
        numberInColumn[i] = numberInColumn[i]+1 --the number of blocks in that column increases by one
      else --if there isn't a block there
        lines[j]=false --there can't be a complete line on that row
      end
    end
    aggregateHeight = aggregateHeight + maximum[i]
  end
  --gui.drawText(0, 0, "Aggregate Height: " .. aggregateHeight, 0xFF000000, 11)
  local bumpy = 0
  for i=0,8 do
    bumpy = bumpy + math.abs(maximum[i]-maximum[i+1])
  end
  --gui.drawText(0, 0, "Bumpiness: " .. bumpy, 0xFF000000, 11)
  local totalLines = 0
  for number, item in pairs(lines) do
    if item then
      totalLines = totalLines + 1
    end
  end
  --gui.drawText(0, 0, "Lines: " .. totalLines, 0xFF000000, 11)
  local totalHoles = 0
  for i=0,9 do
    totalHoles = totalHoles + (maximum[i]-numberInColumn[i])
  end
  --gui.drawText(0, 0, "Holes: " .. totalHoles, 0xFF000000, 11)
  return totalLines, aggregateHeight, bumpy, totalHoles
end


function copyBoard(gameBoard)
  local newBoard = {}
  for i = 0,9 do
    newBoard[i] = {}
    for j= 0,16 do
      if gameBoard[i][j] then
        newBoard[i][j] = true
      else
        newBoard[i][j] = false
      end
    end
  end
  return newBoard
end


function getCurrentBlocks()
  local newBlocks = {}
  for number=0,3 do
    blockY = memory.readbyte(0x10 + number*4)
    if blockY >= 8 and blockY <= 152 then
      correctedY = (152-blockY)/8
    else
      correctedY = ""
    end
    blockX = memory.readbyte(0x11 + number*4)
      if blockX >= 24 and blockX <= 96 then
        correctedX = (blockX-24)/8
      else
        correctedX = ""
      end
    newBlocks[number] = {["x"]=correctedX, ["y"]=correctedY}
  end
  return newBlocks
end



function sleep(n)
  local t = os.clock()
  while os.clock() - t <= n do
    -- nothing
  end
end

function gameOver()
  --console.writeline("Game Over!")
  local q = io.open("scores.txt", "a")
  for i=1,5 do --here
    q:write(populationWeights[popNumber][i])
    q:write(" ")
  end
  local runScore = getGameScore()
  q:write(runScore)
  q:write("\n")
  q:close()

  popNumber = popNumber + 1
  if popNumber < 101 and tonumber(populationWeights[popNumber][6]) == 0 then
  --if popNumber < 31 then
    console.writeline("Score: " .. runScore)
    console.writeline("")
    console.writeline("Gen: " .. generation .. " Child Number: " .. popNumber)
    console.writeline("Weights:")
    console.writeline("Completed Lines: " .. populationWeights[popNumber][1])
    console.writeline("Aggregate Height: " .. populationWeights[popNumber][2])
    console.writeline("Bumpiness: " .. populationWeights[popNumber][3])
    console.writeline("Total Holes: " .. populationWeights[popNumber][4])
    console.writeline("Max Height: " .. populationWeights[popNumber][5])
  end

  while popNumber < 101 and tonumber(populationWeights[popNumber][6]) ~= 0 do --here
    local q = io.open("scores.txt", "a")
    for i=1,5 do --here
      q:write(populationWeights[popNumber][i])
      q:write(" ")
    end
    q:write(populationWeights[popNumber][6]) --here
    q:write("\n")
    q:close()
    popNumber = popNumber + 1


  end
  clearJoypad()
  if popNumber > 100 then
    popNumber = 1
    generation = generation + 1
    os.execute("blah.bat")
    sleep(5)
    local f = io.open("population.txt", "r")
    populationWeights = {}
    for line in f:lines() do
      populationWeights[#populationWeights+1] = {}
      for w in line:gmatch("%S+") do
        table.insert(populationWeights[#populationWeights],w)
      end
    end
    f:close()
    resetBoard()
    console.writeline("Score: " .. runScore)
    console.writeline("")
    console.writeline("Gen: " .. generation .. " Child Number: " .. popNumber)
    console.writeline("Weights:")
    console.writeline("Completed Lines: " .. populationWeights[popNumber][1])
    console.writeline("Aggregate Height: " .. populationWeights[popNumber][2])
    console.writeline("Bumpiness: " .. populationWeights[popNumber][3])
    console.writeline("Total Holes: " .. populationWeights[popNumber][4])
    console.writeline("Max Height: " .. populationWeights[popNumber][5])
  end
  savestate.loadslot(1)
  advanceFrame(13)
  getGameBoard()
end


function getMaxHeight()
  local maximum = {0,0,0,0,0,0,0,0,0}
  maximum[0] = 0
  for i=0,9 do
    for j=0,16 do
      if gameBoard[i][j] then --if there's a block there
        if (j+1)>maximum[i] then --if it's higher than the previous maximum
          maximum[i] = (j+1)
        end
      end
    end
  end
  return maximum
end

function overallMaxHeight() --here
  tableA = getMaxHeight()
  overallMax = 0
  for number, item in pairs(tableA) do
    if item > overallMax then
      overallMax = item
    end
  end
  return overallMax
end

--[[function getMaxHeight()
  local heights = {}
  for i=0,9 do
    j = 16
    while(j~=0 and not gameBoard[i][j]) do
      j = j - 1
    end
    heights[i] = j
  end
  return heights
end--]]

function getXMinBlocks()
  min = 11
  for i=0,3 do
    if currentBlocks[i].x < min then
      min = currentBlocks[i].x
    end
  end
  return min
end

function getXMaxBlocks()
  local max = 0
  for i=0,3 do
    if currentBlocks[i].x > max then
      max = currentBlocks[i].x
    end
  end
  return max
end

function getBoardIter(maxColHeights)
  currentBlocks = getCurrentBlocks()
  local minX = getXMinBlocks()
  local maxX = getXMaxBlocks()
  local width = maxX - minX
  local minHeight = {}
  local maxScore = 0
  for i=0,3 do
    minHeight[i] = -1
  end
  local overallMin = 18
  for i=0,3 do
    --console.writeline(currentBlocks[i].y .. " " .. overallMin)

    local block = currentBlocks[i]
    if block.y == "" or block.x == "" then
      return nil, nil
    end
    if minHeight[block.x-minX] == -1 or minHeight[block.x-minX] > block.y then
      minHeight[block.x-minX] = block.y
      if block.y < overallMin then
        overallMin = block.y
      end
    end
  end
  for i=0,3 do
    minHeight[i] = minHeight[i] - overallMin
  end
  local bestScore = -9999
  local bestAction = 0
  for j=0,(9-width) do --CHECK J LOGIC
    local firstCollision = 0 --ISSUE THAT FIRST RUN HAS FC OF 1
    for i=0,3 do
      if minHeight[i] > -1 then
        if (maxColHeights[i+j] - minHeight[i]) > firstCollision then --CHECK J LOGIC
          firstCollision = (maxColHeights[i+j] - minHeight[i])
        end
        --console.writeline(maxColHeights[i+j] .. " " .. minHeight[i] .. " " .. firstCollision)

      end
    end
    local newBlock = copyCurrentBlock(currentBlocks)
    local newGameBoard = copyBoard(gameBoard)
    for i=0,3 do
      newBlock[i].x = newBlock[i].x - minX + j --CHECK J LOGIC
      newBlock[i].y = newBlock[i].y - overallMin + firstCollision
      newGameBoard[newBlock[i].x][newBlock[i].y] = true
      --console.writeline("Adding block to " .. newBlock[i].x .. " " .. newBlock[i].y .. " " .. firstCollision) --DEBUG THIS
    end
    --console.writeline("")
    local lines, height, bumpy, holes = getHeuristics(newGameBoard)
    local maxHeight = overallMaxHeight()
    --console.writeline("Looking at column " .. j .. "-" .. j+width)
    --console.writeline("Lines: " .. lines .. " Height: " .. height .. " Bumpy: " .. bumpy .. " Holes: " .. holes)
    local currScore = getScore({lines,height,bumpy,holes,maxHeight}, populationWeights[popNumber])
    --console.writeline("Action: ".. j-minX .. " Score: " .. currScore)
    if currScore > bestScore then
      bestScore = currScore
      bestAction = j - minX
    end

  end
  return bestAction, bestScore
  --moveTo(bestAction)
end

function rotationIter(maxColHeights)
  local blockType = memory.readbyte(0x12)
  local maxRotations = blockRotations[blockType]
  if maxRotations ~= 0 and maxRotations ~= 1 and maxRotations ~=3 then
    console.writeline("Couldn't determine block type!")
    maxRoations = 3
  end
  local overallBestScore = -9999
  local overallBestAction = 0
  local numberOfRotations = 0
  local controller = {["A"]=true, ["B"]=false, ["Left"]=false, ["Right"]=false, ["Down"]=false}
  for i=0,maxRotations do
    --console.writeline("Testing rotation number: " .. i)
    local thisBestAction, thisBestScore = getBoardIter(maxColHeights)
    if thisBestAction == nil or thisBestScore == nil then
      --console.writeline("You suck")
      return
    end
    --console.writeline(thisBestAction .. " " .. thisBestScore)
    if thisBestScore > overallBestScore then
      overallBestScore = thisBestScore
      overallBestAction = thisBestAction
      numberOfRotations = (i+1) % (maxRotations+1)
      --console.writeline(overallBestScore)
      --console.writeline(overallBestAction)
    end
    if i~= maxRotations then
      joypad.set(controller)
      advanceFrame(13)
    end
  end
  --console.writeline(numberOfRotations)
  if numberOfRotations == 3 then
    controller = {["A"]=false, ["B"]=true, ["Left"]=false, ["Right"]=false, ["Down"]=false}
    joypad.set(controller)
    advanceFrame(13)
    numberOfRotations = 0
  end

  while numberOfRotations > 0 do
    joypad.set(controller)
    advanceFrame(13)
    numberOfRotations = numberOfRotations - 1
  end
  moveTo(overallBestAction)
end

function copyCurrentBlock(oldBlock)
  newBlock = {{},{},{}}
  newBlock[0] = {}
  for number, item in pairs(oldBlock) do
    newBlock[number]["x"] = item["x"]
    newBlock[number]["y"] = item["y"]
  end
  return newBlock
end

function copyBoard(oldBoard)
  newBoard = {}
  for i=0,9 do
    newBoard[i] = {}
    for j=0,16 do
      newBoard[i][j] = oldBoard[i][j]
    end
  end
  return newBoard
end

function getScore(heuristics, weights)
  local score = 0
  for i=1,5 do
    score = score + heuristics[i] * weights[i]
  end
  return score
end

function advanceFrame(number)
  while number>0 do
    number = number - 1
    emu.frameadvance()
  end
end

--function onExit()
--	forms.destroy(form)
--end

--form = forms.newform(50, 70, "Options")
--showMap = forms.checkbox(form, "Show Map", 5, 5)
--event.onexit(onExit)

function convertToDec(hexa)
  local first = hexa % 10
  local sec = hexa
  sec = sec - first
  sec = sec / 10
  sec = sec * 16
  return sec + first
end

function getGameScore()
  return decimalToHex(memory.readbyte(0xA2))*10000 + decimalToHex(memory.readbyte(0xA1))*100 + decimalToHex(memory.readbyte(0xA0))
end

function drawBox()
  gui.drawBox(20,10,70,95,0xFF000000, 0x80808080)
  local color = 100
  local opacity = 0xFF000000
  color = opacity + color*0x10000 + color*0x100 + color
  for number, cell in pairs(gameBoard) do
    for number2, cell2 in pairs(cell) do
        if cell2 == true then
          gui.drawBox(20+number*5,95-(number2*5),20+(number+1)*5,95-((number2+1)*5),opacity,color)
        end
    end
  end
  for number, cell in pairs(currentBlocks) do
    if cell["x"] ~= "" and cell["y"] ~= "" then
      local color = 255
      local opacity = 0xFF000000
      color = opacity + color*0x10000 + color*0x100 + color
      gui.drawBox(20+cell["x"]*5,95-(cell["y"]*5),20+(cell["x"]+1)*5,95-((cell["y"]+1)*5),opacity,color)
    end
  end
end

function decimalToHex(num)
    local hexstr = '0123456789abcdef'
    local s = ''
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == '' then s = '0' end
    return s
end

function resetBoard()
  for i=0,9 do
    gameBoard[i] = {}
    for j=0,16 do
      gameBoard[i][j] = false
    end
  end
end

resetBoard()
--event.onloadstate(runGame)

--function runGame()
--  currentBlocks = getCurrentBlocks()
--  getGameBoard()
--  columnHeights = getMaxHeight()
--  rotationIter(columnHeights)
--end

console.writeline("Gen: " .. generation .. " Child Number: " .. popNumber)
console.writeline("Weights:")
console.writeline("Completed Lines: " .. populationWeights[popNumber][1])
console.writeline("Aggregate Height: " .. populationWeights[popNumber][2])
console.writeline("Bumpiness: " .. populationWeights[popNumber][3])
console.writeline("Total Holes: " .. populationWeights[popNumber][4])
console.writeline("Max Height: " .. populationWeights[popNumber][5])

while true do
  getGameBoard()
  columnHeights = getMaxHeight()
  rotationIter(columnHeights)
  local randomExtraFrame = math.random(0,1)
  advanceFrame(5+randomExtraFrame)
  if memory.readbyte(0x20) == 255 then
    --console.writeline("Got here!")
    gameOver()
  end
end





--EXTRA CODE
--if #gameBoard>=4 then
--  for number=1,4 do
--    gui.drawText(0, (number-1)*14, "Block " .. number .. " : (" ..  gameBoard[number]["x"] .. "," .. gameBoard[number]["y"] .. ")", 0xFF000000, 11)
--  end
--end
--for number=1,4 do
  --gui.drawText(0, (number-1)*14, "Block " .. number .. " : (" ..  currentBlocks[number]["x"] .. "," .. currentBlocks[number]["y"] .. ")", 0xFF000000, 11)
--end
--gui.drawText(0,56, #gameBoard, 0xFF000000, 11)
--gui.drawBox(0, 0, 300, 70, 0xD0FFFFFF, 0xD0FFFFFF)
--gui.drawText(0, 0, "Score: " ..  decimalToHex(memory.readbyte(0xA1))*100 + decimalToHex(memory.readbyte(0xA0)), 0xFF000000, 11)
