local Node = {}
Node.__index = Node

function Node:new(position)
	local self = setmetatable({}, Node)
	self.Position = position
	self.Previous = nil
	self.CellType = "None"
	self.PreviousSet = {}
	self.Cost = 100000
	return self
end

function Node:addToPreviousSet(pos)
	self.PreviousSet[#self.PreviousSet + 1] = pos
end
return Node