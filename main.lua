-- 

-- An example usage of Castling engine, tested on 0.10.1
-- Scene control:
-- arrows control camera position
-- Q/A,W/S,E/D  +/- RGB of current lightsource accordingly
-- R/F +/- current lightsource elevation value
-- Space toggles shadow casting mode of current lightsource
-- Return toggles shadow blur
-- Y/H,U/J +/- Shear X and Y
-- Home toggles occlusion prerender
-- 1/2,3/4,5/6 +/- Ambient RGB
-- Left CTRL toggles FOV mode

-- left click places lightsource
-- right click places a figure with shadow
-- mouse scroll controls camera scale

require("castling")

local l_gfx = love.graphics
tex = l_gfx.newImage("figs.png")

-- for a castling to render its shadows, user must create some canvas where scene will be rendered to
local gw,gh = l_gfx.getWidth(),l_gfx.getHeight()
main_fb = l_gfx.newCanvas(gw,gh)

-- virtual camera data, unrelated to castling but is needed for it if scene uses viewport transform
camx,camy = 0,0
camsx,camsy = 1,1
camhx,camhy = 0,0

-- declare castling engine
-- 256: 256x256 maximum occlusion canvas size per light
-- false: not using occlusion prerender
-- true: use dynamic occlusion canvi
-- 8: final shadowmap and occlusion sizes will be GfxSize/2
cl = Castling:new(256,false,true,2)
-- turn blur on
cl:setBlur(true)


function love.load()
	-- create some quads
	tile1 = l_gfx.newQuad(0,0,64,64,tex:getWidth(),tex:getHeight())
	tile2 = l_gfx.newQuad(64,0,64,64,tex:getWidth(),tex:getHeight())
	
	figures = {	l_gfx.newQuad(128,0,64,64,tex:getWidth(),tex:getHeight()),
				l_gfx.newQuad(192,0,64,64,tex:getWidth(),tex:getHeight()),
				l_gfx.newQuad(256,0,64,64,tex:getWidth(),tex:getHeight()),
				l_gfx.newQuad(320,0,64,64,tex:getWidth(),tex:getHeight()) }
				
	lamp = l_gfx.newQuad(384,0,64,64,tex:getWidth(),tex:getHeight())
	
	scene_batch = l_gfx.newSpriteBatch(tex,1000)
	shadow_batch = l_gfx.newSpriteBatch(tex,1000)	
	
	-- set ambient light to dim orange light
	cl:setAmbient(32,24,16,255)
	-- add first lightsource
	local lt = cl:addSource(256,128,256,0.5,255,255,255,255)

	
	local fieldx,fieldy = 8,8
	-- create chess field
	local t = 1
	for y=1,fieldy do
		for x=1,fieldx do
			local qx,qy,qw,qh = tile1:getViewport()
			if x%2 ~= y%2 then
				scene_batch:add(tile1,qw*(x),qh*(y))
			else
				scene_batch:add(tile2,qw*(x),qh*(y))
			end
		end
	end
	
	-- add some figures
	for i=1,6 do
		local qx,qy,qw,qh = tile1:getViewport()
		local x,y = math.random(1,fieldx)*qw,math.random(1,fieldy)*qh
		local fig = math.random(1,4)
		scene_batch:add(figures[fig],x,y)
		shadow_batch:add(figures[fig],x,y)
	end
end

function love.draw()	
	l_gfx.setCanvas(main_fb)
	l_gfx.clear(0,0,0,255)
	-- draw main scene with respect to virutal camera
	l_gfx.push()
	l_gfx.scale(camsx,camsy)
	l_gfx.translate(-camx,-camy)
	l_gfx.shear(camhx,camhy)
	l_gfx.draw(scene_batch)
	l_gfx.pop()
	l_gfx.setCanvas()
	
	-- create occlusion render function
	-- it will be roughly similar to scene render
	-- except it should only render shadow stencils or something that is considered light obstructor
	local focl = function() 
		l_gfx.push()
		l_gfx.scale(camsx,camsy)
		l_gfx.translate(-camx,-camy)
		l_gfx.shear(camhx,camhy)
		l_gfx.draw(shadow_batch) 
		l_gfx.pop()
	end
	
	-- if scene uses camera or virtual one
	-- user should send its translation and scale
	-- in order to transform light's worldspace position
	-- to screenspace
	cl:setViewport(camx,camy, camsx,camsy, camhx,camhy)
	
	-- this will cast shadows and lights onto scene 
	-- it receives final (unlit) scene framebuffer
	-- and will render final result onto current canvas
	cl:obscure(main_fb,focl)

	-- display miscellaneous stuff
	local s = "Num lights:"..#cl.lights
	local lt = cl.lights[#cl.lights]
	local lr,lg,lb,la = lt:getColor()
	local lrad = lt:getRadius()
	local lh = lt:getHeight()
	local ls = tostring(lt:isCastShadow())
	local ar,ag,ab,aa = cl:getAmbient()
	s = s.."\nCurrent color:"..math.floor(lr).."/"..math.floor(lg).."/"..math.floor(lb).."/"..math.floor(la)
	s = s.."\nCurrent radius:"..math.floor(lrad)
	s = s.."\nCurrent height:"..math.floor(lh*100)/100
	s = s.."\nCasts shadow:"..ls
	s = s.."\nAmbient:"..math.floor(ar).."/"..math.floor(ag).."/"..math.floor(ab).."/"..math.floor(aa)
	s = s.."\nBlur:"..tostring(cl:getBlur())
	s = s.."\nFOV:"..tostring(cl:getFOV())
	s = s.."\n\nFPS:"..love.timer.getFPS()
	stats = love.graphics.getStats()
	s = s.."\nDrawcalls:"..stats.drawcalls
	s = s.."\nCanvas sw:"..stats.canvasswitches
	s = s.."\nTexMem:"..(math.floor(stats.texturememory/1024/1024*10)/10).."MB"
	s = s.."\nCanv count:"..stats.canvases
	s = s.."\nImg count:"..stats.images
	l_gfx.print(s)
end

function love.mousepressed(x,y,b)
	local scalx,scaly = (x/camsx),(y/camsy)
	x,y = scalx+camx,scaly+camy
	
	if b == 1 then
		cl:addSource(x,y,256,0.5,128,128,32,255)
		scene_batch:add(lamp,x,y,0,1,1,32,32) 
	elseif b == 2 then
		local fig = math.random(1,4)
		local q = figures[fig]
		local qx,qy,qw,qh = q:getViewport()
		scene_batch:add(q,x,y,0,1,1,qw/2,qh/2)
		shadow_batch:add(q,x,y,0,1,1,qw/2,qh/2)
	end
end

-- You can disregard the following section - it's a complete mess

-- define reactions on different keys
key_update = {
	up = function(dt) camy = camy - 100*dt end,
	down = function(dt) camy = camy + 100*dt end,
	left = function(dt) camx = camx - 100*dt end,
	right = function(dt) camx = camx + 100*dt end,
	
	q = function(dt) local cr,cg,cb,ca = cl.lights[#cl.lights]:getColor() cl.lights[#cl.lights]:setColor(cr+100*dt,cg,cb,ca) end,
	a = function(dt) local cr,cg,cb,ca = cl.lights[#cl.lights]:getColor() cl.lights[#cl.lights]:setColor(cr-100*dt,cg,cb,ca) end,
	
	w = function(dt) local cr,cg,cb,ca = cl.lights[#cl.lights]:getColor() cl.lights[#cl.lights]:setColor(cr,cg+100*dt,cb,ca) end,
	s = function(dt) local cr,cg,cb,ca = cl.lights[#cl.lights]:getColor() cl.lights[#cl.lights]:setColor(cr,cg-100*dt,cb,ca) end,
	
	e = function(dt) local cr,cg,cb,ca = cl.lights[#cl.lights]:getColor() cl.lights[#cl.lights]:setColor(cr,cg,cb+100*dt,ca) end,
	d = function(dt) local cr,cg,cb,ca = cl.lights[#cl.lights]:getColor() cl.lights[#cl.lights]:setColor(cr,cg,cb-100*dt,ca) end,
	
	r = function(dt) cl.lights[#cl.lights]:setHeight(cl.lights[#cl.lights]:getHeight()+dt) end,
	f = function(dt) cl.lights[#cl.lights]:setHeight(cl.lights[#cl.lights]:getHeight()-dt) end,
	
	t = function(dt) cl.lights[#cl.lights]:setRadius(cl.lights[#cl.lights]:getRadius()+dt*100) end,
	g = function(dt) cl.lights[#cl.lights]:setRadius(cl.lights[#cl.lights]:getRadius()-dt*100) end,
	
	y = function(dt) camhx = camhx + dt/2 end,
	h = function(dt) camhx = camhx - dt/2 end,
	
	u = function(dt) camhy = camhy + dt/2 end,
	j = function(dt) camhy = camhy - dt/2 end,
}

key_update["1"] = function(dt) local ar,ag,ab,aa = cl:getAmbient() cl:setAmbient(ar-100*dt,ag,ab,aa) end
key_update["2"] = function(dt) local ar,ag,ab,aa = cl:getAmbient() cl:setAmbient(ar+100*dt,ag,ab,aa) end

key_update["3"] = function(dt) local ar,ag,ab,aa = cl:getAmbient() cl:setAmbient(ar,ag-100*dt,ab,aa) end
key_update["4"] = function(dt) local ar,ag,ab,aa = cl:getAmbient() cl:setAmbient(ar,ag+100*dt,ab,aa) end

key_update["5"] = function(dt) local ar,ag,ab,aa = cl:getAmbient() cl:setAmbient(ar,ag,ab-100*dt,aa) end
key_update["6"] = function(dt) local ar,ag,ab,aa = cl:getAmbient() cl:setAmbient(ar,ag,ab+100*dt,aa) end

key_update["7"] = function(dt) local ar,ag,ab,aa = cl:getAmbient() cl:setAmbient(ar,ag,ab,aa-100*dt) end
key_update["8"] = function(dt) local ar,ag,ab,aa = cl:getAmbient() cl:setAmbient(ar,ag,ab,aa+100*dt) end

key_press = {
	space = function() cl.lights[#cl.lights]:setCastShadow(not(cl.lights[#cl.lights]:isCastShadow())) end,
	home = function() cl:setOcclusionPrerender(not(cl:getOcclusionPrerender())) end,
	lctrl = function() cl:setFOV(not(cl:getFOV())) end
}
key_press["return"] = function() cl:setBlur(not(cl:getBlur())) end



function love.update(dt)
	for k,v in pairs(key_update) do
		if love.keyboard.isDown(tostring(k)) == true then v(dt) end
	end
	local px,py = love.mouse:getPosition()
	if #cl.lights>0 then cl.lights[#cl.lights]:setPosition((px/camsx+camx),(py/camsy+camy)) end
end


function love.keypressed(key,ir)
	for k,v in pairs(key_press) do
		if key == tostring(k) then v() end
	end
end



function love.wheelmoved(x,y)
	if y~=0 then
		camsx = camsx+math.max(y,-0.1)
		camsy = camsy+math.max(y,-0.1)
	end
end



