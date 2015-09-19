io.stdout:setvbuf("no") --For console output

Loader = require("Loader")

--====CONFIG START====--

--Note: Make sure that your images are pngs.

_Path = "/ExampleObjects/"
_SheetName = "ExampleObjects.json"
_ObjectsNames = {"AlienBeige","AlienBlue","AlienPink","DebrisGlass","DebrisStone","DebrisWood","Explosive"} --Fill in your objects names

--====CONFIG END====--

--============Controls===========--
--Left Mouse: Add Object (Random)--
--=====WASD: Change Gravity======--
--===Q: Toggle Objects Debug=====--
--===============================--

--Note: You can only add objects if debug is off--

_ObjectsImages = {}
_Objects = {}

function love.load(args)
  _Background = love.graphics.newImage("Background.png")
  _Width, _Height = love.graphics.getWidth(), love.graphics.getHeight()
  
  love.physics.setMeter(64)
  _World = love.physics.newWorld(0, 9.81*64, false)
  
  BuildWorld(_World)
  
  for k, name in pairs(_ObjectsNames) do
    _ObjectsImages[name] = love.graphics.newImage(_Path..name..".png") --Loading the Images
  end
end

function love.update(dt)
  _World:update(dt)
  
  love.window.setTitle("PhysicsEditor Demo [FPS = "..love.timer.getFPS().." ]")
  
  local gx, gy, gs = 0, 9.81*64, 500
  if love.keyboard.isDown("d") then
    _World:setGravity( gx+gs, gy )
  end
  
  if love.keyboard.isDown("a") then
    _World:setGravity( gx-gs, gy )
  end
  
  if love.keyboard.isDown("w") then
    _World:setGravity( gx, gy-gs*2 )
  end
  
  if love.keyboard.isDown("s") then
    _World:setGravity( gx, gy )
  end
end

function love.draw()
  love.graphics.setColor(255,255,255,255)
  
  love.graphics.draw(_Background,0,0,0,_Width/_Background:getWidth(),_Height/_Background:getHeight())
  
  for k,obj in ipairs(_Objects) do
    obj:draw()
  end
  
  if _Debug then DebugWorld(_World) end
end

function love.mousepressed(x, y, button)
  if not _Debug then CreateRandObject(x,y) end
end

function love.keypressed(key,isrepeat)
  if key == "q" then _Debug = not _Debug end
end

function RandSeed()
  math.randomseed(math.random(1000,9999)*love.timer.getTime())
end

function RandObject()
  RandSeed()
  
  return math.random(1,#_ObjectsNames)
end

function CreateRandObject(x,y)
  local objName = _ObjectsNames[RandObject()] print(objName)
  local obj = Loader.loadPath(_ObjectsImages[objName],_World,objName,_Path.._SheetName,x,y)
  table.insert(_Objects,obj)
end

function BuildWorld(world)
  local newEdge = function(World,xS,yS,xE,yE,type)
    xE, yE = xE - xS, yE - yS
    
    local object = {}
    object.body = love.physics.newBody( World, xS, yS, type )
    object.body:setMass(5)
    object.shape = love.physics.newEdgeShape( 0, 0, xE, yE )
    object.fixture = love.physics.newFixture( object.body, object.shape, 1 )
    object.fixture:setRestitution(0)
    object.fixture:setFriction(.5)
    
    return object
  end
  
  newEdge(world,0,0,_Width,0)
  newEdge(world,_Width,0,_Width,_Height)
  newEdge(world,_Width,_Height,0,_Height)
  newEdge(world,0,_Height,0,0)
end

function DebugWorld(world)
   local bodies = world:getBodyList()
   
   for b=#bodies,1,-1 do
      local body = bodies[b]
      local bx,by = body:getPosition()
      local bodyAngle = body:getAngle()
      love.graphics.push()
      love.graphics.translate(bx,by)
      love.graphics.rotate(bodyAngle)
      
      math.randomseed(1) --for color generation
      
      local fixtures = body:getFixtureList()
      for i=1,#fixtures do
         local fixture = fixtures[i]
         local shape = fixture:getShape()
         local shapeType = shape:getType()
         local isSensor = fixture:isSensor()
         
         if (isSensor) then
            love.graphics.setColor(0,0,255,96)
         else
            love.graphics.setColor(math.random(32,200),math.random(32,200),math.random(32,200),96)
         end
         
         love.graphics.setLineWidth(1)
         if (shapeType == "circle") then
            local x,y = fixture:getMassData() --0.9.0 missing circleshape:getPoint()
            --local x,y = shape:getPoint() --0.9.1
            local radius = shape:getRadius()
            love.graphics.circle("fill",x,y,radius,15)
            love.graphics.setColor(0,0,0,255)
            love.graphics.circle("line",x,y,radius,15)
            local eyeRadius = radius/4
            love.graphics.setColor(0,0,0,255)
            love.graphics.circle("fill",x+radius-eyeRadius,y,eyeRadius,10)
         elseif (shapeType == "polygon") then
            local points = {shape:getPoints()}
            love.graphics.polygon("fill",points)
            love.graphics.setColor(0,0,0,255)
            love.graphics.polygon("line",points)
         elseif (shapeType == "edge") then
            love.graphics.setColor(0,0,0,255)
            love.graphics.line(shape:getPoints())
         elseif (shapeType == "chain") then
            love.graphics.setColor(0,0,0,255)
            love.graphics.line(shape:getPoints())
         end
      end
      love.graphics.pop()
   end
   
   local joints = world:getJointList()
   for index,joint in pairs(joints) do
      love.graphics.setColor(0,255,0,255)
      local x1,y1,x2,y2 = joint:getAnchors()
      if (x1 and x2) then
         love.graphics.setLineWidth(3)
         love.graphics.line(x1,y1,x2,y2)
      else
         love.graphics.setPointSize(3)
         if (x1) then
            love.graphics.point(x1,y1)
         end
         if (x2) then
            love.graphics.point(x2,y2)
         end
      end
   end
   
   local contacts = world:getContactList()
   for i=1,#contacts do
      love.graphics.setColor(255,0,0,255)
      love.graphics.setPointSize(3)
      local x1,y1,x2,y2 = contacts[i]:getPositions()
      if (x1) then
         love.graphics.point(x1,y1)
      end
      if (x2) then
         love.graphics.point(x2,y2)
      end
   end
   love.graphics.setColor(255,255,255,255)
end