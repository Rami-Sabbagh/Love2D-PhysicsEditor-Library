--PhysicsEditor Object Loader V1 By: RamiLego4Game--
--[[
	* The MIT License (MIT)
	* 
	* Copyright (c) 2015 RamiLego4Game
	* 
	* Permission is hereby granted, free of charge, to any person obtaining a copy
	* of this software and associated documentation files (the "Software"), to deal
	* in the Software without restriction, including without limitation the rights
	* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	* copies of the Software, and to permit persons to whom the Software is
	* furnished to do so, subject to the following conditions:
	* 
	* The above copyright notice and this permission notice shall be included in all
	* copies or substantial portions of the Software.
	* 
	* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	* SOFTWARE.
--]]

local path = ... --The loader path

--Requirements--
local JSON = require(path..".json") --The JSON library
local Class = require(path..".class") --The hump class system

---
-- The PhysicsEditor Object.
-- 
-- @module PEObject
-- @extends Class#Class
-- @returns #PEObject

---@type PEObject
local PEObject = Class{}

---
-- Creates new PhysicsEditor Object instance.
-- 
-- @callof PEObject#PEObject
-- @param Image image The love.graphics image to draw.
-- @param World world The love.physics world to create the object at.
-- @param #table The part table.
-- @param #number x The x position to create the object at.
-- @param #number y The y position to create the object at.
-- @return PEObject#PEObject
function PEObject:init(image,world,model,x,y)
  self.world = world
  self.model = model
  
  self.image = image
  self.imageWidth, self.imageHeight = self.image:getDimensions()
  
  self.x, self.y = x or 0, y or 0
  self.x, self.y = self.x-self.imageWidth/2,self.y-self.imageHeight/2
  
  if self.model.static then
    self.body = love.physics.newBody(self.world,self.x,self.y)
  else
    self.body = love.physics.newBody(self.world,self.x,self.y,"dynamic")
  end
  
  self.body:setFixedRotation(self.model.fixedRotation)
  self.body:setGravityScale(self.model.gravityScale)
  
  self.shapes = {}
  self.fixtures = {}
  
  for k,v in ipairs(self.model.fixtures) do
    local shape, fixture
    if v.type == "Circle" then
      shape = love.physics.newCircleShape(v.shape.x, v.shape.y, v.shape.radius)
    elseif v.type == "Polygon" then
      shape = love.physics.newPolygonShape(unpack(v.shape))
    end
    fixture = love.physics.newFixture(self.body,shape)
    fixture:setDensity(v.density)
    fixture:setFriction(v.friction)
    fixture:setRestitution(v.restitution)
    fixture:setFilterData(v.filter.categoryBits,v.filter.maskBits,0)
    fixture:setUserData({Type="PhysicsEditor"})
    table.insert(self.shapes,shape)
    table.insert(self.fixtures,fixture)
  end
end

---
-- Returns the love.physics body.
-- 
-- @function [parent=#PEObject] getBody
-- @param self This PhysicsEditor Object.
-- @return Body The love.physics body.
function PEObject:getBody()
  return self.body
end

---
-- Draws the object.
-- 
-- @function [parent=#PEObject] draw
-- @param self This PhysicsEditor Object.
-- @param #table color The color to tint the image with.
-- @param Image overImage to replace the drawing image.
-- @return PEObject#PEObject This PhysicsEditor Object.
function PEObject:draw(color,overImage)
  local c = color or {255,255,255,255}
  if not self.body:isActive() then return end
  if self.dead then return end
  
  love.graphics.push()
  love.graphics.setColor(c)
  love.graphics.translate(self.body:getPosition())
  love.graphics.rotate(self.body:getAngle())
  love.graphics.draw(overImage or self.image,0,0)
  love.graphics.pop()
  
  return self
end

---
-- Destroys the object and prevents it from drawing.
-- 
-- @function [parent=#PEObject] destroy
-- @param self This PhysicsEditor Object.
function PEObject:destroy()
  self.body:destroy()
  self.dead = true
end

---
-- The PhysicsEditor Loader.
-- https://github.com/RamiLego4Game/Love2D-PhysicsEditor-Library
-- 
-- @module PELoader
-- @return #PELoader

---@type PELoader
local PELoader = {}

---
-- Loads a PhysicsEditor object from the given path (using love.filesystem).
-- Uses JSON.lua package by Jeffrey Friedl to decode the object.
-- 
-- @function [parent=#PELoader] loadPath
-- @param Image image The love.graphics image to draw.
-- @param World world The love.physics world to create the object at.
-- @param #string part The part to create from the PhysicsEditor Objects.
-- @param #string path The path to load from (.json file).
-- @param #number x The x position to create the object at.
-- @param #number y The y position to create the object at.
-- @return PEObject#PEObject The new loaded PhysicsEditor Object instace.
function PELoader.loadPath(image,world,part,path,x,y)
  local JSONData = JSON.decode(love.filesystem.load(path))
  return PEObject(image,world,JSONData[part],x,y)
end

---
-- Loads a PhysicsEditor object from the given raw JSON data.
-- Uses JSON.lua package by Jeffrey Friedl to decode the object.
-- 
-- @function [parent=#PELoader] loadPath
-- @param Image image The love.graphics image to draw.
-- @param World world The love.physics world to create the object at.
-- @param #string part The part to create from the PhysicsEditor Objects.
-- @param #string rawJSON The raw JSON data to load from.
-- @param #number x The x position to create the object at.
-- @param #number y The y position to create the object at.
-- @return PEObject#PEObject The new loaded PhysicsEditor Object instace.
function PELoader.loadJSON(image,world,part,rawJSON,x,y)
  local JSONData = JSON.decode(rawJSON)
  return PEObject(image,world,JSONData[part],x,y)
end

---
-- Loads a PhysicsEditor object from the given decoded table.
-- Must be decoded with a JSON library.
-- 
-- @function [parent=#PELoader] loadPath
-- @param Image image The love.graphics image to draw.
-- @param World world The love.physics world to create the object at.
-- @param #string part The part to create from the PhysicsEditor Objects.
-- @param #string t The table to load from.
-- @param #number x The x position to create the object at.
-- @param #number y The y position to create the object at.
-- @return PEObject#PEObject The new loaded PhysicsEditor Object instace.
function PELoader.loadTable(image,world,part,t,x,y)
  return PEObject(image,world,t[part],x,y)
end

return PELoader, PEObject --PEObject for advanced users [Must understand the code].