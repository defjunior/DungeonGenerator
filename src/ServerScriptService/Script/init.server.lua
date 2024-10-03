local DungeonGenerator = {}
DungeonGenerator.__index = DungeonGenerator

local Pathfinder = require(script.Pathfinder)
local Grid = require(script.Grid)
local Node = require(script.Node)
function DungeonGenerator.new(roomCount, minSize, maxSize, maxPosition,floors)
	local self = setmetatable({}, DungeonGenerator)
	self.rooms = {}
	self.roomCount = roomCount
	self.minSize = minSize
	self.maxSize = maxSize
	self.maxPosition = maxPosition
	self.floors = floors
	return self
end

local function Vector3Int(x, y, z)
	return {x = x, y = y, z = z}
end

local function ToVector3(T)
	return Vector3.new(T.Position.x,T.Position.y,T.Position.z)
end
local function ToVector32(T)
	return Vector3.new(T.x,T.y,T.z)
end


function DungeonGenerator:initGrid(gridSize)
	self.grid = Grid.new(Vector3.new(gridSize, self.floors , gridSize), Vector3.new(0, 0, 0))
	for x = 0, gridSize do
		for y = 0, self.floors do
			for z = 0, gridSize do
				self.grid[tostring(x)..","..tostring(y)..","..tostring(z)] = Node:new(Vector3.new(x, y, z))
			end
		end
	end
	for _, room in ipairs(self.rooms) do
		--local roomPart = Instance.new("Part")
		--roomPart.Size = room.Size
		--roomPart.Position = room.Position
		--roomPart.Anchored = true
		--roomPart.Transparency = 0.5
		--roomPart.BrickColor = BrickColor.new("Bright blue")
		--roomPart.Parent = workspace.Rooms
		--room.Part = roomPart

		-- Calculate room extents in world coordinates
		local roomMin = room.Position - (room.Size / 2)
		local roomMax = room.Position + (room.Size / 2)

		-- Convert room extents to grid coordinates
		local gridMin = toGridCoordinates(roomMin)
		local gridMax = toGridCoordinates(roomMax)

		gridMin = floorv3(gridMin)
		gridMax = floorv3(gridMax)

		-- Iterate over the grid cells that the room occupies
		for x = gridMin.x, gridMax.x - 1 do
			for y = gridMin.y, gridMax.y - 1 do
				for z = gridMin.z, gridMax.z - 1 do
					local key = tostring(x)..","..tostring(y)..","..tostring(z)
					if self.grid[key] then
						self.grid[key].CellType = "Room"
						-- Optionally, you can set the cost or other properties here
						--room.part = PlacePart(toWorldPosition(Vector3.new(x,y,z)), Color3.fromRGB(145, 20, 255))
					end
				end
			end
		end
	end
end
function DungeonGenerator:placeRooms()
	for _, room in ipairs(self.rooms) do
		--local roomPart = Instance.new("Part")
		--roomPart.Size = room.Size
		--roomPart.Position = room.Position
		--roomPart.Anchored = true
		--roomPart.Transparency = 0.5
		--roomPart.BrickColor = BrickColor.new("Bright blue")
		--roomPart.Parent = workspace.Rooms
		--room.Part = roomPart

		-- Calculate room extents in world coordinates
		local roomMin = room.Position - (room.Size / 2)
		local roomMax = room.Position + (room.Size / 2)

		-- Convert room extents to grid coordinates
		local gridMin = toGridCoordinates(roomMin)
		local gridMax = toGridCoordinates(roomMax)

		gridMin = floorv3(gridMin)
		gridMax = floorv3(gridMax)

		-- Iterate over the grid cells that the room occupies
		for x = gridMin.x, gridMax.x - 1 do
			for y = gridMin.y, gridMax.y - 1 do
				for z = gridMin.z, gridMax.z - 1 do
					local key = tostring(x)..","..tostring(y)..","..tostring(z)
					if self.grid[key] then
						-- Optionally, you can set the cost or other properties here
						room.part = PlacePart(toWorldPosition(Vector3.new(x,y,z)), Color3.fromRGB(145, 20, 255))
					end
				end
			end
		end
	end
	
end

local function vectorSub(v1, v2)
	return v1 - v2
end

local function vectorCross(v1, v2)
	return Vector3.new(
		v1.Y * v2.Z - v1.Z * v2.Y,
		v1.Z * v2.X - v1.X * v2.Z,
		v1.X * v2.Y - v1.Y * v2.X
	)
end

local function vectorDot(v1, v2)
	return v1.X * v2.X + v1.Y * v2.Y + v1.Z * v2.Z
end

local function vectorMagnitude(v)
	return math.sqrt(v.X^2 + v.Y^2 + v.Z^2)
end

local function vectorScale(v, s)
	return Vector3.new(v.X * s, v.Y * s, v.Z * s)
end

local function vectorAdd(v1, v2)
	return v1 + v2
end

local function vectorEqual(v1, v2)
	return v1 == v2
end

local function pointEqual(a, b)
	return a.Position == b.Position
end

local defaultsize = 6

function DungeonGenerator:generateRooms()
	local function isOverlapping(roomA, roomB)
		return not (
			roomA.Position.x + roomA.Size.x / 2 < roomB.Position.x - roomB.Size.x / 2 or
				roomA.Position.x - roomA.Size.x / 2 > roomB.Position.x + roomB.Size.x / 2 or
				roomA.Position.z + roomA.Size.z / 2 < roomB.Position.z - roomB.Size.z / 2 or
				roomA.Position.z - roomA.Size.z / 2 > roomB.Position.z + roomB.Size.z / 2 or
				roomA.Position.y + roomA.Size.y / 2 < roomB.Position.y - roomB.Size.y / 2 or
				roomA.Position.y - roomA.Size.y / 2 > roomB.Position.y + roomB.Size.y / 2
		)
	end

	local function findValidPosition(size)
		local position
		local isValid = false

		while not isValid do
			position = Vector3.new(
				math.random(0, self.maxPosition) * defaultsize,
				math.random(0, self.floors)  * (defaultsize), -- was 24
				math.random(0, self.maxPosition) * defaultsize
			)

			isValid = true
			for _, existingRoom in ipairs(self.rooms) do
				local bufferSize = Vector3.new(
					existingRoom.Size.x + defaultsize, 
					existingRoom.Size.y, 
					existingRoom.Size.z + defaultsize
				)
				local bufferPosition = existingRoom.Position + Vector3.new(0, 0, 0)
				if isOverlapping({ Position = position, Size = size }, { Position = bufferPosition, Size = bufferSize }) then
					isValid = false
					break
				end
			end
		end

		return position
	end

	for i = 1, self.roomCount do
		local size = Vector3.new(
			(math.random(self.minSize, self.maxSize) * defaultsize),
			math.random(0, self.floors)  * (defaultsize), 
			(math.random(self.minSize, self.maxSize) * defaultsize) 
		)
	

		local position = findValidPosition(size)
		position = Vector3.new(position.X,position.Y,position.Z)
		table.insert(self.rooms, { Position = position, Size = size })
	end
end

local Triangle = {}
Triangle.__index = Triangle

function Triangle:new(p1,p2,p3)
	local self = setmetatable({},Triangle)
	self.points = {p1,p2,p3}
	self.edges = { -- Edges are pairs of points connected
		{p1,p2},
		{p2,p3},
		{p3,p1}
	}
	return self	
end

local function determinant(matrix)
	local det = matrix[1][1] * (
		matrix[2][2] * (matrix[3][3] * matrix[4][4] - matrix[3][4] * matrix[4][3]) -
			matrix[2][3] * (matrix[3][2] * matrix[4][4] - matrix[3][4] * matrix[4][2]) +
			matrix[2][4] * (matrix[3][2] * matrix[4][3] - matrix[3][3] * matrix[4][2])
	) - matrix[1][2] * (
		matrix[2][1] * (matrix[3][3] * matrix[4][4] - matrix[3][4] * matrix[4][3]) -
			matrix[2][3] * (matrix[3][1] * matrix[4][4] - matrix[3][4] * matrix[4][1]) +
			matrix[2][4] * (matrix[3][1] * matrix[4][3] - matrix[3][3] * matrix[4][1])
	) + matrix[1][3] * (
		matrix[2][1] * (matrix[3][2] * matrix[4][4] - matrix[3][4] * matrix[4][2]) -
			matrix[2][2] * (matrix[3][1] * matrix[4][4] - matrix[3][4] * matrix[4][1]) +
			matrix[2][4] * (matrix[3][1] * matrix[4][2] - matrix[3][2] * matrix[4][1])
	) - matrix[1][4] * (
		matrix[2][1] * (matrix[3][2] * matrix[4][3] - matrix[3][3] * matrix[4][2]) -
			matrix[2][2] * (matrix[3][1] * matrix[4][3] - matrix[3][3] * matrix[4][1]) +
			matrix[2][3] * (matrix[3][1] * matrix[4][2] - matrix[3][2] * matrix[4][1])
	)
	return det
end
local function determinant5(matrix)
	local n = #matrix

	-- Base case for 2x2 matrix
	if n == 2 then
		return matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1]
	end

	local det = 0

	-- Iterate over the first row to expand along it
	for col = 1, n do
		-- Create the minor matrix by excluding the current row and column
		local minor = {}
		for i = 2, n do
			local row = {}
			for j = 1, n do
				if j ~= col then
					table.insert(row, matrix[i][j])
				end
			end
			table.insert(minor, row)
		end

		-- Recursively calculate the determinant of the minor matrix
		local minorDet = determinant(minor)

		-- Alternate the sign based on the column index
		local sign = (col % 2 == 0) and -1 or 1

		-- Add to the determinant total
		det = det + sign * matrix[1][col] * minorDet
	end

	return det
end
function Triangle:containsCircumcircle(point)
	local p1, p2, p3 = self.points[1], self.points[2], self.points[3]
	local matrix = {
		{p1.x, p1.y, p1.x^2 + p1.y^2, 1},
		{p2.x, p2.y, p2.x^2 + p2.y^2, 1},
		{p3.x, p3.y, p3.x^2 + p3.y^2, 1},
		{point.x, point.y, point.x^2 + point.y^2, 1}
	}
	return determinant(matrix) > 0
end

local function sameEdge(e1, e2)
	return (e1[1] == e2[1] and e1[2] == e2[2]) or (e1[1] == e2[2] and e1[2] == e2[1])
end

function Triangle:sharesEdge(edge)

	for _, e in ipairs(self.edges) do
		if sameEdge(e, edge) then
			return true
		end
	end

	return false
end

-- Check if a triangle is in a list of triangles
function Triangle:isInList(triangles)
	for _, triangle in ipairs(triangles) do
		if self == triangle then
			return true
		end
	end
	return false
end

-- Check if a triangle contains a vertex
function Triangle:hasVertex(vertices)
	for _, vertex in ipairs(vertices) do
		for _, point in ipairs(self.points) do
			if point == vertex then
				return true
			end
		end
	end
	return false
end

function delaunayTriangulation(points)
	-- Create a super triangle that contains all points
	local superTriangle = Triangle:new({x = -1000, y = -1000}, {x = 5000, y = -1000}, {x = 2000, y = 5000})
	local triangles = {superTriangle}

	-- Add each point incrementally
	for _, point in ipairs(points) do
		local badTriangles = {}
		for _, triangle in ipairs(triangles) do
			if triangle:containsCircumcircle(point) then
				table.insert(badTriangles, triangle)
			end
		end

		-- Find the boundary of the polygonal hole
		local polygon = {}
		for _, triangle in ipairs(badTriangles) do
			for _, edge in ipairs(triangle.edges) do
				local isShared = false
				for _, otherTriangle in ipairs(badTriangles) do
					if otherTriangle ~= triangle and otherTriangle:sharesEdge(edge) then
						isShared = true
						break
					end
				end
				if not isShared then
					table.insert(polygon, edge)
				end
			end
		end

		-- Remove bad triangles
		for i = #triangles, 1, -1 do
			if triangles[i]:isInList(badTriangles) then
				table.remove(triangles, i)
			end
		end

		-- Add new triangles formed with the polygon's boundary and the new point
		for _, edge in ipairs(polygon) do
			local newTriangle = Triangle:new(edge[1], edge[2], point)
			table.insert(triangles, newTriangle)
		end
	end

	-- Remove triangles that include vertices of the super triangle
	for i = #triangles, 1, -1 do
		if triangles[i]:hasVertex(superTriangle.points) then
			table.remove(triangles, i)
		end
	end

	return triangles
end

local function drawLine(startPos, endPos, parent,isMST,isHallways)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	local s1 = 0.2
	if isMST then
		s1 = 0.7
		part.Material = Enum.Material.Neon
		part.Color = Color3.new(1,1,1)
	elseif isHallways then
		--print("Hallways",(endPos - startPos).Magnitude)
		s1 = 1
		part.Material = Enum.Material.Neon
		part.Color = Color3.new(0, 1, 0.0313725)
	end
	part.Size = Vector3.new(s1, s1, (endPos - startPos).Magnitude)
	part.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -part.Size.Z / 2)
	part.Parent = parent
end
function Triangle:visualize(parent)
	drawLine(Vector3.new(self.points[1].x, self.points[1].y, self.points[1].z),
		Vector3.new(self.points[2].x, self.points[2].y, self.points[2].z), parent)
	drawLine(Vector3.new(self.points[2].x, self.points[2].y, self.points[2].z),
		Vector3.new(self.points[3].x, self.points[3].y, self.points[3].z), parent)
	drawLine(Vector3.new(self.points[3].x, self.points[3].y, self.points[3].z),
		Vector3.new(self.points[1].x, self.points[1].y, self.points[1].z), parent)
end



Tetrahedron = {}
Tetrahedron.__index = Tetrahedron

function Tetrahedron:new(p1, p2, p3, p4)
	local self = setmetatable({}, Tetrahedron)
	self.points = {p1, p2, p3, p4}
	self.faces = {
		{p1, p2, p3},
		{p1, p2, p4},
		{p1, p3, p4},
		{p2, p3, p4}
	}
	return self
end

function Tetrahedron:visualize(parent)
	-- Draw edges for each face
	for _, face in ipairs(self.faces) do
		drawLine(Vector3.new(face[1].x, face[1].y, face[1].z),
			Vector3.new(face[2].x, face[2].y, face[2].z), parent)
		drawLine(Vector3.new(face[2].x, face[2].y, face[2].z),
			Vector3.new(face[3].x, face[3].y, face[3].z), parent)
		drawLine(Vector3.new(face[3].x, face[3].y, face[3].z),
			Vector3.new(face[1].x, face[1].y, face[1].z), parent)
	end
end

function Tetrahedron:containsCircumsphere(point)
	local p1, p2, p3, p4 = self.points[1], self.points[2], self.points[3], self.points[4]
	local mat = {
		{p1.x, p1.y, p1.z, p1.x^2 + p1.y^2 + p1.z^2, 1},
		{p2.x, p2.y, p2.z, p2.x^2 + p2.y^2 + p2.z^2, 1},
		{p3.x, p3.y, p3.z, p3.x^2 + p3.y^2 + p3.z^2, 1},
		{p4.x, p4.y, p4.z, p4.x^2 + p4.y^2 + p4.z^2, 1},
		{point.x, point.y, point.z, point.x^2 + point.y^2 + point.z^2, 1}
	}
	return determinant5(mat) > 0
end


function delaunayTetrahedralization(points)
	local tetrahedrons = {}

	-- Initialize with a super tetrahedron that contains all points
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

	for _, p in ipairs(points) do
		if p.x < minX then minX = p.x end
		if p.y < minY then minY = p.y end
		if p.z < minZ then minZ = p.z end
		if p.x > maxX then maxX = p.x * 2 end
		if p.y > maxY then maxY = p.y * 2 end
		if p.z > maxZ then maxZ = p.z * 2 end
	end

	local d = math.max(maxX - minX, maxY - minY, maxZ - minZ)
	local midX, midY, midZ = (maxX + minX) / 2, (maxY + minY) / 2, (maxZ + minZ) / 2

	local superTetrahedron = Tetrahedron:new(
		{x = midX - 3*d, y = midY, z = midZ},
		{x = midX + 3*d, y = midY, z = midZ},
		{x = midX, y = midY - 3*d, z = midZ},
		{x = midX, y = midY, z = midZ + 3*d}
	)

	table.insert(tetrahedrons, superTetrahedron)

	for _, point in ipairs(points) do
		local badTetrahedrons = {}
		local polygon = {}

		for i = #tetrahedrons, 1, -1 do
			local tetra = tetrahedrons[i]
			if tetra:containsCircumsphere(point) then
				table.insert(badTetrahedrons, tetra)
				table.remove(tetrahedrons, i)
			end
		end

		local function findFace(tri, faces)
			for _, face in ipairs(faces) do
				if (tri[1] == face[1] and tri[2] == face[2] and tri[3] == face[3]) or
					(tri[1] == face[2] and tri[2] == face[3] and tri[3] == face[1]) or
					(tri[1] == face[3] and tri[2] == face[1] and tri[3] == face[2]) then
					return true
				end
			end
			return false
		end

		for _, tetra in ipairs(badTetrahedrons) do
			for _, face in ipairs(tetra.faces) do
				if not findFace(face, polygon) then
					table.insert(polygon, face)
				else
					for j = #polygon, 1, -1 do
						if findFace(polygon[j], {face}) then
							table.remove(polygon, j)
						end
					end
				end
			end
		end

		for _, face in ipairs(polygon) do
			local newTetrahedron = Tetrahedron:new(face[1], face[2], face[3], point)
			table.insert(tetrahedrons, newTetrahedron)
		end
	end

	for i = #tetrahedrons, 1, -1 do
		local tetra = tetrahedrons[i]
		for _, p in ipairs(superTetrahedron.points) do
			if tetra.points[1] == p or tetra.points[2] == p or tetra.points[3] == p or tetra.points[4] == p then
				table.remove(tetrahedrons, i)
				break
			end
		end
	end

	return tetrahedrons
end


function cullRooms(points, tetrahedrons)
	local pointInTetrahedron = {}

	-- Initialize the dictionary to mark points that are in the tetrahedralization
	for _, point in ipairs(points) do
		pointInTetrahedron[point] = false
	end

	-- Mark points that are part of any tetrahedron
	for _, tetra in ipairs(tetrahedrons) do
		for _, p in ipairs(tetra.points) do
			pointInTetrahedron[p] = true
		end
	end

	-- Collect points that are part of the tetrahedralization
	local culledRooms = {}
	for _, point in ipairs(points) do
		if not pointInTetrahedron[point] then
			table.insert(culledRooms, point)
		end
	end

	return culledRooms
end

function getRoomsNotOnEdges(rooms, edges)
	local pointSet = {}

	-- Add all points from edges to the set
	for _, edge in ipairs(edges) do
		local p1 = edge[1]
		local p2 = edge[2]
		local key1 = p1.x .. "," .. p1.y .. "," .. p1.z
		local key2 = p2.x .. "," .. p2.y .. "," .. p2.z
		pointSet[key1] = true
		pointSet[key2] = true
	end

	local isolatedRooms = {}

	-- Check each room to see if it's in the pointSet
	for _, room in ipairs(rooms) do
		local roomKey = room.Position.x .. "," .. room.Position.y .. "," .. room.Position.z
		if not pointSet[roomKey] then
			table.insert(isolatedRooms, room)
		end
	end

	return isolatedRooms
end


function minimumSpanningTreeFromTetrahedrons(tetrahedrons)
	local edges = {}
	local pointIndex = {}
	local points = {}
	local currentIndex = 1

	-- Assign an index to each unique point in the tetrahedrons
	for _, tetra in ipairs(tetrahedrons) do
		for _, point in ipairs(tetra.points) do
			local pointKey = point.x .. "," .. point.y .. "," .. point.z
			if not pointIndex[pointKey] then
				pointIndex[pointKey] = currentIndex
				table.insert(points, point)
				currentIndex = currentIndex + 1
			end
		end
	end

	-- Generate edges based on tetrahedrons' edges
	for _, tetra in ipairs(tetrahedrons) do
		local pts = tetra.points
		for i = 1, 3 do
			for j = i + 1, 4 do
				local index1 = pointIndex[pts[i].x .. "," .. pts[i].y .. "," .. pts[i].z]
				local index2 = pointIndex[pts[j].x .. "," .. pts[j].y .. "," .. pts[j].z]
				if index1 and index2 then
					local distance = calculateDistance(pts[i], pts[j])
					table.insert(edges, {index1, index2, distance})
				end
			end
		end
	end

	table.sort(edges, function(a, b) return a[3] < b[3] end)

	local parent = {}
	local rank = {}
	for i = 1, #points do
		parent[i] = i
		rank[i] = 0
	end

	local mst = {}
	local e = 0
	local i = 1

	while e < #points - 1 and i <= #edges do
		local u = edges[i][1]
		local v = edges[i][2]
		local weight = edges[i][3]
		i = i + 1

		local x = findParent(parent, u)
		local y = findParent(parent, v)

		if x ~= y then
			e = e + 1
			table.insert(mst, {points[u], points[v], weight})
			union(parent, rank, x, y)
		end
	end

	return mst
end

function visualizeMST(mst)
	for _, edge in ipairs(mst) do
		local p1 = edge[1]
		local p2 = edge[2]
		--drawLine(p1,p2,workspace.Triangles,true)
	end
end
function visualizeHallways(mst)
	for _, edge in pairs(mst) do
		local p1 = edge[1]
		local p2 = edge[2]
		drawLine(p1,p2,workspace.Triangles,nil,true)
	end
end

function calculateDistance(p1, p2)
	local dx = p1.x - p2.x
	local dy = p1.y - p2.y
	local dz = p1.z - p2.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end


-- Helper functions for Kruskal's algorithm (Union-Find)
function findParent(parent, i)
	if parent[i] ~= i then
		parent[i] = findParent(parent, parent[i])
	end
	return parent[i]
end

function union(parent, rank, x, y)
	local rootX = findParent(parent, x)
	local rootY = findParent(parent, y)
	if rank[rootX] < rank[rootY] then
		parent[rootX] = rootY
	elseif rank[rootX] > rank[rootY] then
		parent[rootY] = rootX
	else
		parent[rootY] = rootX
		rank[rootX] = rank[rootX] + 1
	end
end

function getAllTetrahedronEdges(tetrahedrons)
	local edges = {}
	local edgeSet = {}

	for _, tetra in ipairs(tetrahedrons) do
		local pts = tetra.points
		for i = 1, 3 do
			for j = i + 1, 4 do
				local p1 = pts[i]
				local p2 = pts[j]
				local edgeKey = p1.x .. "," .. p1.y .. "," .. p1.z .. "-" .. p2.x .. "," .. p2.y .. "," .. p2.z
				local reverseEdgeKey = p2.x .. "," .. p2.y .. "," .. p2.z .. "-" .. p1.x .. "," .. p1.y .. "," .. p1.z

				-- Ensure each edge is only added once by checking both directions
				if not edgeSet[edgeKey] and not edgeSet[reverseEdgeKey] then
					edgeSet[edgeKey] = true
					table.insert(edges, {p1, p2})
				end
			end
		end
	end

	return edges
end


-- Helper function to convert world coordinates to grid coordinates
function toGridCoordinates(position)
	
	return Vector3.new(
		math.floor(position.x / defaultsize) + 0.5,
		math.floor(position.y / defaultsize)+ 0.5,
		math.floor(position.z / defaultsize)+ 0.5
	)
end

function toWorldPosition(gridCoord)
	-- Offset by defaultsize/2 to ensure (0,0) in grid maps to (6,6) in world space
	return Vector3.new(
		(gridCoord.x * defaultsize) + defaultsize / 2,
		(gridCoord.y * defaultsize) + defaultsize / 2,
		(gridCoord.z * defaultsize) + defaultsize / 2
	)
end

-- Heuristic function for A* (Manhattan distance in 3D)
local function heuristic(start, goal)
	return math.abs(start.x - goal.x) + math.abs(start.y - goal.y) + math.abs(start.z - goal.z)
end

-- Check if a point is within a room's boundaries
local function isPointInRoom(point, room)
	local roomSize = toGridCoordinates(room.Size)
	local roomPos = toGridCoordinates(room.Position) 
	return point.x >= roomPos.x - roomSize.x / 2 and point.x <= roomPos.x + roomSize.x / 2 and
		point.y >= roomPos.y - roomSize.y / 2 and point.y <= roomPos.y + roomSize.y / 2 and
		point.z >= roomPos.z - roomSize.z / 2 and point.z <= roomPos.z + roomSize.z / 2,room
end

-- Check if a point is inside any room
local function isPointInAnyRoom(point, rooms)
	for _, room in ipairs(rooms) do
		if isPointInRoom(point,room) then
		--	print(isPointInRoom(point,room),point,toGridCoordinates(room.Position),toGridCoordinates(room.Size))
			return true
		end
	end
	return false
end


-- Find the nearest node outside of rooms
local function findNearestOutsideNode(point, rooms)
	local node1 = Vector3Int(point.x,point.y,point.z)
	local directions = {
		{x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0},
		{x = 2, y = 0, z = 0}, {x = -2, y = 0, z = 0},
		{x = 0, y = 0, z = 1}, {x = 0, y = 0, z = -1},
		{x = 0, y = 0, z = 2}, {x = 0, y = 0, z = -2},
		{x = 0, y = 1, z = 0}, {x = 0, y = -1, z = 0},
		{x = 0, y = 2, z = 0}, {x = 0, y = -2, z = 0},
	}

	while isPointInAnyRoom(node1, rooms) do
		print("Check")
		for _, dir in ipairs(directions) do
			--print(node1)
			node1.x += dir.x
			node1.y += dir.y
			node1.z += dir.z
			task.wait()
			--print(node1)
			if not isPointInAnyRoom(node1, rooms) then
				print("Out")
				break
			end
		end
		
	end
	print("Returned")
	return ToVector32(node1)
end


function PlacePart(position, color)
	local part = Instance.new("Part")
	part.Size = Vector3.new(defaultsize, defaultsize, defaultsize)
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Parent = workspace 
	return part
end

local function PlaceStairs(position,isbottom)
	PlacePart(toWorldPosition(position), (not isbottom and Color3.fromRGB(255, 255, 0) or Color3.new(1, 0.764706, 0.294118)))
end

local function PlaceHallway(position)
	PlacePart(toWorldPosition(position), Color3.fromRGB(0, 0, 255))
end


--function getRoomFromPosition(rooms,position)
--	for _, room in ipairs(rooms) do
--		local minX, minY, minZ = room.min.X, room.min.Y, room.min.Z
--		local maxX, maxY, maxZ = room.max.X, room.max.Y, room.max.Z

--		if position.X >= minX and position.X <= maxX and
--			position.Y >= minY and position.Y <= maxY and
--			position.Z >= minZ and position.Z <= maxZ then
--			return room
--		end
--	end
--	return nil -- Return nil if no room is found at the given position
--end
function floorv3(v3)
	return Vector3.new(math.floor(v3.x),math.floor(v3.y),math.floor(v3.z))
end
function PathfindHallways(dungeon)
	local selectedEdges = table.clone(dungeon.hallways)
	local rooms = dungeon.rooms
	local grid = dungeon.grid
	
	local DungeonPathfinder3D = Pathfinder
	local aStar = DungeonPathfinder3D:new(grid,dungeon)
	
	local function exec(n,edge)
		local startRoom = edge[1]
		local endRoom = edge[2]

		local startPosf = startRoom
		local endPosf = endRoom
		
		local startPos = Vector3.new(startPosf.x, startPosf.y, startPosf.z)
		local endPos = Vector3.new(endPosf.x, endPosf.y, endPosf.z)
		startPos = toGridCoordinates(startPos)
		endPos = toGridCoordinates(endPos)
		startPos = floorv3(startPos)
		endPos = floorv3(endPos)

		--startPos = findNearestOutsideNode(startPos, rooms)
		--endPos = findNearestOutsideNode(endPos, rooms)




		local path = aStar:FindPath(startPos, endPos,
			function(a, b)
				a = ToVector3(a)
				b = ToVector3(b)
				local pathCost = {traversable = false, cost = 0, isStairs = false}
				local delta = Vector3.new{x = b.x - a.x, y = b.y - a.y, z = b.z - a.z}

				if delta.y == 0 then
					-- Flat hallway
					pathCost.cost = heuristic(b,endPos)

					if grid[b.x..","..b.y..","..b.z].CellType == "Stairs" then
						return pathCost
					elseif grid[b.x..","..b.y..","..b.z].CellType == "Room" then
						pathCost.cost = pathCost.cost + 5
					elseif grid[b.x..","..b.y..","..b.z].CellType == "None" then
						pathCost.cost = pathCost.cost + 1
					end

					pathCost.traversable = true
				else
					-- Staircase
					if (grid[a.x..","..a.y..","..a.z].CellType ~= "None" and grid[a.x..","..a.y..","..a.z].CellType ~= "Hallway") then
						return pathCost
					end
					if	(grid[b.x..","..b.y..","..b.z].CellType ~= "None" and grid[b.x..","..b.y..","..b.z].CellType ~= "Hallway") then
						return pathCost
					end


					pathCost.cost = 100 + heuristic(b,endPos)

					local xDir = math.clamp(delta.x,-1,1)
					local zDir = math.clamp(delta.z,-1,1)
					local verticalOffset = Vector3.new(0, delta.y, 0)
					local horizontalOffset = Vector3.new(xDir, 0, zDir)

					if not aStar.grid:InBounds(a + verticalOffset) or
						not aStar.grid:InBounds(a + horizontalOffset) or
						not aStar.grid:InBounds(a + verticalOffset + horizontalOffset) then
						return pathCost
					end

					local a1 = a + horizontalOffset
					local a2 = a + horizontalOffset * 2
					local a3 = a + verticalOffset + horizontalOffset
					local a4 = a + verticalOffset + horizontalOffset * 2
					if grid[a1.x..","..a1.y..","..a1.z].CellType ~= "None" or
						grid[a2.x..","..a2.y..","..a2.z].CellType ~= "None" or
						grid[a3.x..","..a3.y..","..a3.z].CellType ~= "None" or
						grid[a4.x..","..a4.y..","..a4.z].CellType ~= "None" then
						return pathCost
					end

					pathCost.traversable = true
					pathCost.isStairs = true
				end

				return pathCost
			end,grid)

		if path then
			warn("Found a path for edge "..n)
			table.remove(selectedEdges,n)
			for i, current in ipairs(path) do
				if 	grid[current.x..","..current.y..","..current.z].CellType == "None" then
					grid[current.x..","..current.y..","..current.z].CellType = "Hallway"
				end

				if i > 1 then
					local prev = path[i - 1] 
					prev = ToVector32(prev)
					local delta = {x = current.x - prev.x, y = current.y - prev.y, z = current.z - prev.z}

					if delta.y ~= 0 then
						local xDir = math.clamp(delta.x,-1,1)
						local zDir = math.clamp(delta.z,-1,1)
						local verticalOffset = Vector3.new(0, delta.y, 0)
						local horizontalOffset = Vector3.new(xDir, 0, zDir)


						local a1 = prev + horizontalOffset
						local a2 = prev + horizontalOffset * 2
						local a3 = prev + verticalOffset + horizontalOffset
						local a4 = prev + verticalOffset + horizontalOffset * 2

						grid[a1.x..","..a1.y..","..a1.z].CellType= "Stairs" 
						grid[a2.x..","..a2.y..","..a2.z].CellType= "Stairs" 
						grid[a3.x..","..a3.y..","..a3.z].CellType= "Stairs" 
						grid[a4.x..","..a4.y..","..a4.z].CellType = "Stairs" 


						PlaceStairs(prev + horizontalOffset,true)
						PlaceStairs(prev + horizontalOffset * 2,true)
						PlaceStairs(prev + verticalOffset + horizontalOffset)
						PlaceStairs(prev + verticalOffset + horizontalOffset * 2)
					end
				end
			end

			for _, pos in ipairs(path) do
				if 	grid[pos.x..","..pos.y..","..pos.z].CellType == "Hallway" then
					PlaceHallway(pos)
				end
			end
		end
	end
	
	for i = 1,3,1 do
			for n, edge in ipairs(selectedEdges) do
				exec(n,edge)
			end
		task.wait(5)
	end

	
end


local Generations = {}
local CurrentInstances = 0
local Iterations = 0
local Failed = -1
local Success = 0
function RunGenerator(StartTime,Iterations,Failed,Success)

	CurrentInstances += 1
	local InstanceID = CurrentInstances

	repeat
		--local dungeon = DungeonGenerator.new(17, 2, 5,30,5)
		--(34, 4, 10,60,10)
		--(7, 2, 4,25, 2)
		local dungeon = DungeonGenerator.new(32, 2, 7,30,5)
		local Culled = 0
		local Tetrahedralization = {}
		repeat
			Iterations += 1
			Failed += 1
			Culled = 0
			Tetrahedralization = {}
			--workspace.Rooms:ClearAllChildren()
			---	workspace.Triangles:ClearAllChildren()
			dungeon.rooms = {}

			dungeon:generateRooms()
			dungeon:initGrid(dungeon.maxPosition)
			local RoomPositions = {}
			for a,b in pairs(dungeon.rooms) do
				table.insert(RoomPositions,b.Position)
			end


			Tetrahedralization = delaunayTetrahedralization(RoomPositions)
			--print(Tetrahedralization)
			--for a,b in pairs(Tetrahedralization) do
			--b:visualize(workspace.Triangles)
			--end
			--task.wait(1)
			local mst = minimumSpanningTreeFromTetrahedrons(Tetrahedralization)
			local edges = {}
			for a,b in pairs(mst) do
				table.insert(edges,{b[1],b[2]})
			end

			local alledges = getAllTetrahedronEdges(Tetrahedralization)
			for a,b in pairs(alledges) do
				local fse = false
				for c,d in pairs(mst) do
					if sameEdge(b,d) then
						fse	= true
						break
					end
				end
				if not fse then
					if math.random(1,100) <= 14 then
						table.insert(edges,b)
					end
				end
			end


			for a,b in pairs(getRoomsNotOnEdges(dungeon.rooms,edges)) do
				for c,d in pairs(dungeon.rooms) do
					if d.Position == b.Position then
						Culled += 1
						--dungeon.rooms[c].Part:Destroy()
						table.remove(dungeon.rooms,c)
					end
				end
			end

			RoomPositions = nil
			dungeon.hallways = edges
			dungeon.roompositions = {}
			for a,b in pairs(dungeon.rooms) do
				table.insert(dungeon.roompositions,b.Position)
			end
			--visualizeMST(minimumSpanningTreeFromTetrahedrons(Tetrahedralization))
			task.wait(0.1)

		until #Tetrahedralization ~= 0
		Success += 1
		dungeon.Tetrahedralization = Tetrahedralization
		table.insert(Generations,{dungeon,Culled})
		task.wait(0.1)

	until #Generations >= 5 

	if InstanceID ~= 1 then CurrentInstances -= 1 return end
	repeat wait() until CurrentInstances == 1

	table.sort(Generations,function(a,b)
		return a[2] < b[2]
	end)

	local dungeon = Generations[1]
	for i = 2,#Generations,1 do
		if Generations[i] ~= dungeon then
			Generations[i] = nil
		end
	end

	
	for a,b in pairs(dungeon[1].Tetrahedralization) do
		--b:visualize(workspace.Triangles)
	end
	local mst = minimumSpanningTreeFromTetrahedrons(dungeon[1].Tetrahedralization)
	visualizeMST(mst)
	--local edges = {}
	--for a,b in pairs(mst) do
	--	table.insert(edges,{b[1],b[2]})
	--end
	--local alledges = getAllTetrahedronEdges(dungeon[1].Tetrahedralization)
	--for a,b in pairs(alledges) do
	--	local fse = false
	--	for c,d in pairs(mst) do
	--		if sameEdge(b,d) then
	--			fse	= true
	--			break
	--		end
	--	end
	--	if not fse then
	--		if math.random(1,100) <= 14 then
	--			table.insert(edges,b)
	--		end
	--	end
	--end
	
	visualizeHallways(dungeon[1].hallways)
	--connectRoomsThroughGrid(dungeon[1].rooms,dungeon[1].hallways)
	PathfindHallways(dungeon[1])
	dungeon[1]:placeRooms(dungeon[1].maxPosition)
	print("Iterations : "..Iterations," Failed : "..Failed," Successes : "..Success, " Time Elapsed : "..string.sub(tick() - st,5))

end
st = tick()
for i = 1,10,1 do
	coroutine.wrap(function()
		RunGenerator(st,Iterations,Failed,Success)
	end)()

end



local tri = Triangle:new(Vector3.new(0,0),Vector3.new(1,0),Vector3.new(0,1))
print(tri:containsCircumcircle(Vector3.new(2,0)))
