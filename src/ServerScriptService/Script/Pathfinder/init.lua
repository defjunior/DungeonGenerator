local DungeonPathfinder3D = {}
DungeonPathfinder3D.__index = DungeonPathfinder3D
local Grid = require(script.Parent.Grid)
local Node = require(script.Parent.Node)
local function Vector3Int(x, y, z)
	return {x = x, y = y, z = z}
end


function DungeonPathfinder3D:new(grid,dungeon)
	local self = setmetatable({}, DungeonPathfinder3D)
	self.grid = grid
	self.queue = {} -- Priority queue will be handled with a sorted table
	self.closed = {}
	self.stack = {}
	self.dungeon = dungeon

	self.neighbors = {
		Vector3.new(1, 0, 0),
		Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, 1),
		Vector3.new(0, 0, -1),
		
		Vector3.new(3, 1, 0),
		Vector3.new(-3, 1, 0),
		Vector3.new(0, 1, 3),
		Vector3.new(0, 1, -3),
		
		Vector3.new(3, -1, 0),
		Vector3.new(-3, -1, 0),
		Vector3.new(0, -1, 3),
		Vector3.new(0, -1, -3),
	}

	return self
end

function DungeonPathfinder3D:ResetNodes()
	for x = 0, self.grid.size.x do
		for y = 0, self.dungeon.floors do
			for z = 0, self.grid.size.z do
				local node = self.grid[tostring(x)..","..tostring(y)..","..tostring(z)]
				node.Previous = nil
				node.Cost = 0
				node.PreviousSet = {}
			end
		end
	end
end
local function ToVector3(T)
	return Vector3.new(T.Position.x,T.Position.y,T.Position.z)
end

local function similarpos(pos,goal)
	if (ToVector3(pos) - goal).Magnitude <= 6 then 
		return true 
	else
		return false
	end
end

local function TryGetPriority(queue, node)
	for _, item in ipairs(queue) do
		if item.node == node then
			return true, item.priority
		end
	end
	return false, nil
end

local function updateQueue(queue, neighbor, newCost)
	local found = false
	for i, item in ipairs(queue) do
		if item.node == neighbor then
			queue[i].priority = newCost
			found = true
			break
		end
	end
	if not found then
		table.insert(queue, {node = neighbor, priority = newCost})
	end
	table.sort(queue, function(a, b) return a.priority < b.priority end)
end

--if similarpos(currentNode,goal) then
--function DungeonPathfinder3D:FindPath(start, goal, costFunction)
--	self:ResetNodes()
--	self.queue = {}
--	self.closed = {}
	
--	local function enqueue(node, priority)
--		table.insert(self.queue, {node = node, priority = priority})
--		table.sort(self.queue, function(a, b) return a.priority < b.priority end)
--	end
--	local function nodeKey(node)
--		return node.Position.x .. "," .. node.Position.y .. "," .. node.Position.z
--	end


--	enqueue(self.grid[start.x..","..start.y..","..start.z], 0)
	
--	local Count = 0
--	while #self.queue > 0 and Count < 3000 do
--		Count += 1
--		--print("Path")
--		local currentNode = table.remove(self.queue, 1).node
--		self.closed[nodeKey(currentNode)] = true

--		if currentNode.Position.x == goal.x and currentNode.Position.y == goal.y and currentNode.Position.z == goal.z then
		
--			return self:ReconstructPath(currentNode)
--		end

--		for _, offset in ipairs(self.neighbors) do
--			local neighborPos = Vector3.new(
--				currentNode.Position.x + offset.x,
--				currentNode.Position.y + offset.y,
--				currentNode.Position.z + offset.z
--			)

--			if self.grid[neighborPos.x..","..neighborPos.y..","..neighborPos.z] then
--				local neighbor = self.grid[neighborPos.x..","..neighborPos.y..","..neighborPos.z]
--				if self.closed[nodeKey(neighbor)] then continue end
--				if self:isInPreviousSet(currentNode, neighbor.Position) then  continue end
				
				
--				local pathCost = costFunction(currentNode, neighbor)
--				if not pathCost.traversable then  continue end

--				if pathCost.isStairs then
--					if self:isInvalidStaircase(currentNode, offset) then
--						print("Staircase is invalid!")
--					end
--					if self:isInvalidStaircase(currentNode, offset) then
--						print("InvalidStaircase")
--						continue 
--					end
--				end

--				local newCost = currentNode.Cost + pathCost.cost

--				if newCost < neighbor.Cost or neighbor.Cost == 0  then
--					neighbor.Previous = currentNode
--					neighbor.Cost = newCost
					
--					local found, existingPriority = TryGetPriority(self.queue, neighbor)
--					if found then
--						updateQueue(self.queue, neighbor, neighbor.Cost)
--					else
--						enqueue(neighbor, neighbor.Cost)
--					end
					
					
--					neighbor.PreviousSet = self:cloneSet(currentNode.PreviousSet)
--					neighbor:addToPreviousSet(currentNode.Position)
--					if pathCost.isStairs then
--						self:addStaircaseOffsetsToPreviousSet(neighbor, currentNode, offset)
--					end
--				end

--				continue
--			end
--		end
--	end

--	return nil
--end

--function DungeonPathfinder3D:FindPath(start, goal, costFunction)
--	self:ResetNodes()
--	self.queue = {}
--	self.closed = {}

--	local function enqueue(node, priority)
--		table.insert(self.queue, {node = node, priority = priority})
--	end

--	local function dequeue()
--		table.sort(self.queue, function(a, b) return a.priority < b.priority end)
--		return table.remove(self.queue, 1)
--	end

--	local function nodeKey(node)
--		return node.Position.x .. "," .. node.Position.y .. "," .. node.Position.z
--	end

--	enqueue(self.grid[start.x..","..start.y..","..start.z], 0)

--	local Count = 0
--	while #self.queue > 0 and Count < 3000 do
--		Count += 1

--		local current = dequeue()
--		local currentNode = current.node
--		self.closed[nodeKey(currentNode)] = true

--		if currentNode.Position.x == goal.x and currentNode.Position.y == goal.y and currentNode.Position.z == goal.z then
--			return self:ReconstructPath(currentNode)
--		end

--		for _, offset in ipairs(self.neighbors) do
--			local neighborPos = Vector3.new(
--				currentNode.Position.x + offset.x,
--				currentNode.Position.y + offset.y,
--				currentNode.Position.z + offset.z
--			)

--			local neighborKey = tostring(neighborPos.x) .. "," .. tostring(neighborPos.y) .. "," .. tostring(neighborPos.z)
--			local neighbor = self.grid[neighborKey]

--			if neighbor and not self.closed[neighborKey] then
--				if self:isInPreviousSet(currentNode, neighbor.Position) then continue end

--				local pathCost = costFunction(currentNode, neighbor)
--				if not pathCost.traversable then continue end

--				if pathCost.isStairs and self:isInvalidStaircase(currentNode, offset) then
--					continue
--				end

--				local newCost = currentNode.Cost + pathCost.cost
--				if newCost < neighbor.Cost or neighbor.Cost == 0 then
--					neighbor.Previous = currentNode
--					neighbor.Cost = newCost

--					local found, existingPriority = TryGetPriority(self.queue, neighbor)
--					if found then
--						updateQueue(self.queue, neighbor, neighbor.Cost)
--					else
--						enqueue(neighbor, neighbor.Cost)
--					end

--					neighbor.PreviousSet = self:cloneSet(currentNode.PreviousSet)
--					neighbor:addToPreviousSet(currentNode.Position)
--					if pathCost.isStairs then
--						self:addStaircaseOffsetsToPreviousSet(neighbor, currentNode, offset)
--					end
--				end
--			end
--		end
--	end

--	return nil
--end


local BinaryHeap = require(script.BinaryHeap) -- Assume this is a Min-Heap implementation

function DungeonPathfinder3D:FindPath(start, goal, costFunction)
	self:ResetNodes()
	self.queue = BinaryHeap:new()
	self.closed = {}

	local function nodeKey(node)
		return node.Position.x .. "," .. node.Position.y .. "," .. node.Position.z
	end

	local function heuristic(node)
		return (node.Position - goal).magnitude
	end
	
	self.grid[start.x..","..start.y..","..start.z].Cost = 0
	self.queue:insert({node = self.grid[start.x..","..start.y..","..start.z], priority = 0})

	local Count = 0
	while not self.queue:isEmpty() and Count < 5000 do
		Count += 1

		local current = self.queue:pop()
		local currentNode = current.node
		self.closed[nodeKey(currentNode)] = true

		if currentNode.Position.x == goal.x and currentNode.Position.y == goal.y and currentNode.Position.z == goal.z then
			return self:ReconstructPath(currentNode)
		end

		for _, offset in ipairs(self.neighbors) do
			task.spawn(function()
				local neighborPos = Vector3.new(
					currentNode.Position.x + offset.x,
					currentNode.Position.y + offset.y,
					currentNode.Position.z + offset.z
				)

				local neighborKey = tostring(neighborPos.x) .. "," .. tostring(neighborPos.y) .. "," .. tostring(neighborPos.z)
				local neighbor = self.grid[neighborKey]

				if neighbor and not self.closed[neighborKey] then
					if self:isInPreviousSet(currentNode, neighbor.Position) then return end

					local pathCost = costFunction(currentNode, neighbor)
					if not pathCost.traversable then return end

					if pathCost.isStairs and self:isInvalidStaircase(currentNode, offset) then
						return
					end

					local newCost = currentNode.Cost + pathCost.cost 
					if newCost < neighbor.Cost or neighbor.Cost == 0  then -- or neighbor.cost == 0
						neighbor.Previous = currentNode
						neighbor.Cost = newCost
						
						task.defer(function()
							self.queue:insert({node = neighbor, priority = newCost})
							updateQueue(self.queue,neighbor,newCost)
						end)
					

						neighbor.PreviousSet = self:cloneSet(currentNode.PreviousSet)
						neighbor:addToPreviousSet(currentNode.Position)
						if pathCost.isStairs then
							self:addStaircaseOffsetsToPreviousSet(neighbor, currentNode, offset)
						end
					end
				end
			end)
			
		end
	end

	return nil
end


--function DungeonPathfinder3D:FindPath(start, goal, costFunction)
--	self:ResetNodes()
--	self.queue = {}
--	self.closed = {}

--	local function enqueue(node, priority)
--		table.insert(self.queue, {node = node, priority = priority})
--		table.sort(self.queue, function(a, b) return a.priority < b.priority end)
--	end

--	local startNode = self.grid[tostring(start.x)][tostring(start.y)][tostring(start.z)]
--	local goalNode = self.grid[tostring(goal.x)][tostring(goal.y)][tostring(goal.z)]

--	enqueue(startNode, 0)

--	while #self.queue > 0 do
--		local currentNode = table.remove(self.queue, 1).node
--		self.closed[currentNode] = true

--		if similarpos(currentNode, goal) then
--			return self:ReconstructPath(currentNode)
--		end

--		for _, offset in ipairs(self.neighbors) do
--			local neighborPos = Vector3Int(
--				currentNode.Position.x + offset.x,
--				currentNode.Position.y + offset.y,
--				currentNode.Position.z + offset.z
--			)

--			if self.grid[tostring(neighborPos.x)] and self.grid[tostring(neighborPos.x)][tostring(neighborPos.y)] and self.grid[tostring(neighborPos.x)][tostring(neighborPos.y)][tostring(neighborPos.z)] then
--				local neighbor = self.grid[tostring(neighborPos.x)][tostring(neighborPos.y)][tostring(neighborPos.z)]
--				if self.closed[neighbor] then continue end

--				local pathCost = costFunction(currentNode, neighbor)
--				if not pathCost.traversable then continue end

--				if pathCost.isStairs then
--					if self:isInvalidStaircase(currentNode, offset) then continue end
--				end

--				local newCost = currentNode.Cost + pathCost.cost

--				if newCost < neighbor.Cost then
--					neighbor.Previous = currentNode
--					neighbor.Cost = newCost
--					enqueue(neighbor, neighbor.Cost)
--					neighbor.PreviousSet = self:cloneSet(currentNode.PreviousSet)
--					neighbor:addToPreviousSet(currentNode.Position)
--					if pathCost.isStairs then
--						self:addStaircaseOffsetsToPreviousSet(neighbor, currentNode, offset)
--					end
--				end
--			end
--		end
--	end

--	return nil
--end
function DungeonPathfinder3D:isInPreviousSet(node, position)
	for _, pos in ipairs(node.PreviousSet) do
		if pos.x == position.x and pos.y == position.y and pos.z == position.z then
			return true
		end
	end
	return false
end
function DungeonPathfinder3D:isInvalidStaircase(node, offset)
	-- Convert offset to direction vectors
	local xDir = math.clamp(offset.x, -1, 1)
	local zDir = math.clamp(offset.z, -1, 1)
	local verticalOffset = Vector3Int(0, offset.y, 0)
	local horizontalOffset = Vector3Int(xDir, 0, zDir)

	-- Calculate positions based on offset and direction
	local checkPos1a = Vector3Int(
		node.Position.x + horizontalOffset.x,
		node.Position.y + verticalOffset.y,
		node.Position.z + horizontalOffset.z
	)
	local checkPos1b = Vector3Int(
		node.Position.x + horizontalOffset.x,
		node.Position.y,
		node.Position.z + horizontalOffset.z
	)

	local checkPos2a = Vector3Int(
		node.Position.x + horizontalOffset.x * 2,
		node.Position.y + verticalOffset.y,
		node.Position.z + horizontalOffset.z * 2
	)
	local checkPos2b = Vector3Int(
		node.Position.x + horizontalOffset.x * 2,
		node.Position.y,
		node.Position.z + horizontalOffset.z * 2
	)

	-- Debug prints to ensure positions are computed correctly
	print("Checking positions:")
	print("checkPos1a: ", checkPos1a.x, checkPos1a.y, checkPos1a.z)
	print("checkPos1b: ", checkPos1b.x, checkPos1b.y, checkPos1b.z)
	print("checkPos2a: ", checkPos2a.x, checkPos2a.y, checkPos2a.z)
	print("checkPos2b: ", checkPos2b.x, checkPos2b.y, checkPos2b.z)

	-- Check if any of the computed positions are in the previous set
	if self:isInPreviousSet(node, checkPos1a) or 
		self:isInPreviousSet(node, checkPos1b) or 
		self:isInPreviousSet(node, checkPos2a) or 
		self:isInPreviousSet(node, checkPos2b) then
		return true
	end

	return false
end

function DungeonPathfinder3D:addStaircaseOffsetsToPreviousSet(node, currentNode, offset)
	local xDir = math.clamp(offset.x,-1,1)
	local zDir = math.clamp(offset.z,-1,1)
	local verticalOffset = Vector3Int(0, offset.y, 0)
	local horizontalOffset = Vector3Int(xDir, 0, zDir)

	for i = 1, 2 do
		node:addToPreviousSet(Vector3Int(currentNode.Position.x + horizontalOffset.x * i, currentNode.Position.y + verticalOffset.y, currentNode.Position.z + horizontalOffset.z * i))
	end
end

function DungeonPathfinder3D:cloneSet(set)
	local newSet = {}
	for _, v in ipairs(set) do
		newSet[#newSet + 1] = v
	end
	return newSet
end

function DungeonPathfinder3D:ReconstructPath(node)
	local result = {}
	while node do
		table.insert(result, node.Position)
		node = node.Previous
	end
	return result
end

return DungeonPathfinder3D