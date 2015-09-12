--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

---
-- The hump class.
-- 
-- @module Class
-- @return #Class

--- @type Class

---
-- Deeply copies "other" into "class". keys in "other" that are already defined in "class" are omitted.
-- 
-- @function [parent = #Class] include
-- @param #Class class Target class object.
-- @param #Class other Other class object.
-- @return #Class The result class object.

---
-- Returns a deep copy of other.
-- 
-- @function [parent = #Class] clone
-- @param #Class other Other class object.
-- @return #Class The result class object.

---
-- Creates a new instance of this class.
-- 
-- @function [parent = #Class] new
-- @param #Class class The class to create the instance from.
-- @return #Class The new instance.

---
-- Called when the class is created.
-- 
-- @function [parent = #Class] init
-- @param ... Any arguments can be passed.
-- @return #Class The class after creating it.

---
-- Creates a new instance of this class.
-- 
-- @callof #Class
-- @return #Class The new instance.

local function include_helper(to, from, seen)
	if from == nil then
		return to
	elseif type(from) ~= 'table' then
		return from
	elseif seen[from] then
		return seen[from]
	end

	seen[from] = to
	for k,v in pairs(from) do
		k = include_helper({}, k, seen) -- keys might also be tables
		if not to[k] then
			to[k] = include_helper({}, v, seen)
		end
	end
	return to
end

local function include(class, other)
	return include_helper(class, other, {})
end

local function clone(other)
	return setmetatable(include({}, other), getmetatable(other))
end

local function new(class)
	-- mixins
	local inc = class.__includes or {}
	if getmetatable(inc) then inc = {inc} end

	for _, other in ipairs(inc) do
		include(class, other)
	end

	-- class implementation
	class.__index = class
	class.init    = class.init    or class[1] or function() end
	class.include = class.include or include
	class.clone   = class.clone   or clone

	-- constructor call
	return setmetatable(class, {__call = function(c, ...)
		local o = setmetatable({}, c)
		o:init(...)
		return o
	end})
end

---
-- interface for cross class-system compatibility.
-- See https://github.com/bartbes/Class-Commons
if class_commons ~= false and not common then
	common = {}
	function common.class(name, prototype, parent)
		return new{__includes = {prototype, parent}}
	end
	function common.instance(class, ...)
		return class(...)
	end
end


-- the module
return setmetatable({new = new, include = include, clone = clone},
	{__call = function(_,...) return new(...) end})
