local BinaryHeap = {}
BinaryHeap.__index = BinaryHeap

function BinaryHeap:new()
	local obj = {heap = {}}
	setmetatable(obj, self)
	return obj
end

function BinaryHeap:insert(element)
	table.insert(self.heap, element)
	self:heapifyUp(#self.heap)
end

function BinaryHeap:pop()
	if #self.heap == 0 then return nil end
	if #self.heap == 1 then return table.remove(self.heap, 1) end

	local root = self.heap[1]
	self.heap[1] = table.remove(self.heap, #self.heap)
	self:heapifyDown(1)
	return root
end

function BinaryHeap:isEmpty()
	return #self.heap == 0
end

function BinaryHeap:heapifyUp(index)
	if index == 1 then return end
	local parentIndex = math.floor(index / 2)
	if self.heap[index].priority < self.heap[parentIndex].priority then
		self.heap[index], self.heap[parentIndex] = self.heap[parentIndex], self.heap[index]
		self:heapifyUp(parentIndex)
	end
end

function BinaryHeap:heapifyDown(index)
	local leftIndex = 2 * index
	local rightIndex = 2 * index + 1
	local smallestIndex = index

	if leftIndex <= #self.heap and self.heap[leftIndex].priority < self.heap[smallestIndex].priority then
		smallestIndex = leftIndex
	end

	if rightIndex <= #self.heap and self.heap[rightIndex].priority < self.heap[smallestIndex].priority then
		smallestIndex = rightIndex
	end

	if smallestIndex ~= index then
		self.heap[index], self.heap[smallestIndex] = self.heap[smallestIndex], self.heap[index]
		self:heapifyDown(smallestIndex)
	end
end

return BinaryHeap
