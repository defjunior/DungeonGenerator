local Grid3D = {}
Grid3D.__index = Grid3D

-- Constructor for Grid3D

-- Get the index for a given position

-- Check if a position is within bounds
function Grid3D:inBounds(pos)
	pos = pos + self.offset
	return pos.x >= 0 and pos.x < self.size.x and
		pos.y >= 0 and pos.y < self.size.y and
		pos.z >= 0 and pos.z < self.size.z
end

-- Getter for accessing the grid elements using vector position
function Grid3D:get(pos)
	pos = Vector3.new(pos.x,pos.y,pos.z)
	pos = pos + self.offset
	print(self)
	if self:inBounds(pos) then
		return self.data[self:getIndex(pos)]
	end
	return nil
end

-- Setter for setting grid elements using vector position
function Grid3D:set(pos, value)
	pos = pos + self.offset
	if self:inBounds(pos) then
		self.data[self:getIndex(pos)] = value
	end
end



--- There's a problem when indexing with the pairs function as it triggers the index metamethod
--- This behavior doesn't occur in C# so it must be changed with some sort of internal function to perform whatever
-- DungeonPathfinder3D is attempting to do.
-- Indexer method for accessing elements using []
function Grid3D.__index(self, pos)
	if type(pos) == "table" and pos.x and pos.y and pos.z then
		return Grid3D.get(self, pos)
	elseif rawget(self, pos) then
		return rawget(self, pos)
	else
		return rawget(Grid3D,pos)
	end
end

-- Newindex method for setting elements using []
function Grid3D.__newindex(self, pos, value)
	if type(pos) == "table" and pos.x and pos.y and pos.z then
		Grid3D.set(self, pos, value)
	else
		rawset(self, pos, value)
	end
end


function Grid3D.new(size, offset)
	local self = setmetatable({}, Grid3D)
	self.size = size
	self.offset = offset
	self.data = {}

	function self:getIndex(pos)
		return pos.x + (self.size.x * pos.y) + (self.size.x * self.size.y * pos.z)
	end

	-- Initialize the data array
	--for x = 0, size.x - 1 do
	--	for y = 0, size.y - 1 do
	--		for z = 0, size.z - 1 do
	--			self.data[self:getIndex(Vector3.new(x, y, z))] = nil
	--		end
	--	end
	--end

	return self
end

return Grid3D