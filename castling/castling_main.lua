--[[
	(ray)Castling by mkdxdx/cval, 2016
	
	A light/shadow engine for love2d
	
	A collection of shader sources from around the internet to provide some
	lighting functionality for love2d projects.
	
	

]]--

local cf = (...):gsub('%.[^%.]+$', '')

local l_gfx = love.graphics
local max,min = math.max,math.min

-- lightsource object for castling engine
local Cl_Lightsource = {}
Cl_Lightsource.__index = Cl_Lightsource
Cl_Lightsource.ident = "cl_lightsource"
--[[
	Create lightsource object
	: world position X,Y
	: radius in pixels
	: elevation (0.0 - 1.0) - the higher the value the more it ignores shading, values more than 1 will amplify attentuation
	: RGBA (0-255) light color
	
]]--
function Cl_Lightsource:new(x,y,r,h,cr,cg,cb,ca)
	local self = setmetatable({},Cl_Lightsource)
	self[1] = x or 0
	self[2] = y or 0
	self[3] = r or 0
	self[4] = h or 0.5
	self[6] = cr or 0
	self[7] = cg or 0
	self[8] = cb or 0
	self[9] = ca or 0
	-- is enabled
	self[10] = true
	-- cast shadow
	self[11] = true
	return self
end

-- sets light enabled or disabled in lightsource pass
function Cl_Lightsource:setEnable(e) self[10] = e end
function Cl_Lightsource:isEnabled() return self[10] end

-- sets lightsource world position (affected by graphics translations and scaling)
function Cl_Lightsource:setPosition(x,y) self[1] = x or self[1] self[2] = y or self[2] end
function Cl_Lightsource:getPosition() return self[1],self[2] end

-- sets light radius, affected by graphics scaling
function Cl_Lightsource:setRadius(r) self[3] = r or self[3] end 
function Cl_Lightsource:getRadius() return self[3] end	

-- sets light elevation (preferred values 0.0 - 1.0)
function Cl_Lightsource:setHeight(h) self[4] = h or self[4] end
function Cl_Lightsource:getHeight() return self[4] end

-- sets light color
function Cl_Lightsource:setColor(r,g,b,a) self[6],self[7],self[8],self[9] = min(max(r or self[6],0),255),min(max(g or self[7],0),255),min(max(b or self[8],0),255),min(max(a or self[9],0),255) end
function Cl_Lightsource:getColor() return self[6],self[7],self[8],self[9] end

-- sets if lightsource casts any shadows
function Cl_Lightsource:setCastShadow(cs) self[11] = cs end
function Cl_Lightsource:isCastShadow() return self[11] end


Castling = {}
Castling.__index = Castling
Castling.ident = "c_castling"
-- load shaders table
Castling.shaders = require(cf..".castling_shaders")
Castling.ambient = {0,0,0,0}
Castling.enable_sb_blur = false
Castling.viewport = {0,0, 1,1, 0,0}
Castling.min_ofb_resol = 32
Castling.isFOV = false
--[[
	Create Castling instance
		: resolution (number, min_ofb_resol) - occlusion FBO maximum resolution (higher values give crispier shadows but drain more vram)
		
		: use_occlusion_fbo (boolean, false) - specifies if engine will use separate occlusion FBO
		separate FBO usage decreases scene occlusion draw count but will create separate canvas with current GraphicsResolution/sm_div
		
		: use_dyn_ofb (boolean, true) - specifies if engine will accomodate per-light occlusion fbo to light radius
		if disabled - will always use one per-light occlusion canvas with specified resolution
		if enabled - will create multiple canvases with resolutions down from specified to min_ofb_resol (e.g. resolution 256 
		and min_ofb_resol = 32 will create per-light occlusion canvases with resolutions 256x256,128x128,64x64,32x32) and if 
		light radius will be 48 pixels, it will use canvas with 64x64 and hypothetically this will decrease GPU bandwidth usage
		
		: sm_div (number, 1) - shadowmap and occlusion fbo resolution divider. specifying numbers higher than 1 will
		divide shadowmap resolution by that number. decreases gpu bandwidth usage
]]
function Castling:new(resolution,use_occlusion_fbo,use_dyn_ofb,sm_div)
	local self = setmetatable({},Castling)
	self.smresol = resolution or self.min_ofb_resol
	self.use_occlusion_fbo = use_occlusion_fbo or false
	self.sm_div = sm_div or 1
	self.use_dynamic_ofb = use_dyn_ofb or true
	
	-- active lights
	self.lights = {}
	-- all "released" lights go here
	self.lights_stack = {}
	
	-- 1d shadowmap table	
	self.lookup_fbt = {}
	-- 2d occlusion map per light table
	self.occ_fbt = {}
	-- occlusion map resolutions
	self.occ_rt = {}
	
	if self.use_dynamic_ofb == true then
		local tr = self.smresol
		local i = 1
		-- create occlusion canvi for each resolution stage down from specified
		repeat
			self.lookup_fbt[i] = l_gfx.newCanvas(tr,1)
			self.lookup_fbt[i]:setWrap("repeat","repeat")
			self.occ_fbt[i] = l_gfx.newCanvas(tr,tr)
			self.occ_rt[i] = {tr,tr}
			i = i+1
			tr = tr/2
		until tr<self.min_ofb_resol
	else
		-- or create single one for all light radii
		self.lookup_fbt[1] = l_gfx.newCanvas(self.smresol,1)
		self.lookup_fbt[1]:setWrap("repeat","repeat")
		self.occ_rt[1] = {self.smresol,self.smresol}
		self.occ_fbt[1] = l_gfx.newCanvas(self.smresol,self.smresol)
	end
	self:initMainFB()
	return self
end

-- toggles shadows blur
function Castling:setBlur(b) self.enable_sb_blur = b end
function Castling:getBlur() return self.enable_sb_blur end

-- toggles FOV mode
-- if enabled, will render lightsource as raycasting field of vision simulation
-- ignores light color, ambient color and light height
function Castling:setFOV(f)	self.isFOV = f end
function Castling:getFOV() return self.isFOV end 

-- toggles occlusion prerender mode, same effect as use_occlusion_fbo
function Castling:setOcclusionPrerender(op) 
	self.use_occlusion_fbo = op
	if self.use_occlusion_fbo == true and self.fb_occlusion == nil then
		self.fb_occlusion = l_gfx.newCanvas(l_gfx.getWidth()/self.sm_div,l_gfx.getHeight()/self.sm_div)
	end
end
function Castling:getOcclusionPrerender() return self.use_occlusion_fbo end

-- adds lightsource at specified world coordinates X,Y, with radius R, elevation H and color CR/CG/CB/CA
-- returns lightsource table
function Castling:addSource(x,y,r,h,cr,cg,cb,ca)
	local index = #self.lights+1
	local lt = Cl_Lightsource:new(x,y,r,h,cr,cg,cb,ca)
	self.lights[index] = lt
	return lt
end


-- sets viewport shift if scene uses camera translations for lightsources rendering
-- accepts X,Y translation and SX,SY graphics scale and SHX,SHY shear that doesnt work yet
function Castling:setViewport(x,y,sx,sy,shx,shy)
	self.viewport[1] = x or self.viewport[1]
	self.viewport[2] = y or self.viewport[2]
	self.viewport[3] = sx or self.viewport[3]
	self.viewport[4] = sy or self.viewport[4]
	self.viewport[5] = (shx or self.viewport[5])*0 -- lightsource coordinates shearing is not implemented yet!
	self.viewport[6] = (shy or self.viewport[6])*0
end

-- sets ambient light value
function Castling:setAmbient(r,g,b,a)
	if type(r) == "table" then
		self.ambient[1],self.ambient[2],self.ambient[3],self.ambient[4] = min(max((r[1] or 0)/255,0),1.0),min(max((r[2] or 0)/255,0),1.0),min(max((r[3] or 0)/255,0),1.0),min(max((r[4] or 0)/255,0),1.0)
	else
		self.ambient[1],self.ambient[2],self.ambient[3],self.ambient[4] = min(max((r or 0)/255,0),1.0),min(max((g or 0)/255,0),1.0),min(max((b or 0)/255,0),1.0),min(max((a or 0)/255,0),1.0)
	end
end
function Castling:getAmbient() return self.ambient[1]*255,self.ambient[2]*255,self.ambient[3]*255,self.ambient[4]*255 end

-- calculate occlusion with OCC_F function, project shadows and project them on CANVAS framebuffer
function Castling:obscure(canvas,occ_f)
	-- main pass
	self:clear()
	self:pass(occ_f)
	self:castOn(canvas)
end

-- clears shadowmap and occlusion framebuffer
function Castling:clear()
	l_gfx.push("all")
	if self.use_occlusion_fbo == true then
		l_gfx.setCanvas(self.fb_occlusion)
		l_gfx.clear(0,0,0,0)
	end
	l_gfx.setCanvas(self.fb_shadowmap,self.fb_shadowmap_t)
	-- fb occlusion always should be cleared with transparent a=0 color!
	l_gfx.clear(0,0,0,255, 0,0,0,255)
	l_gfx.pop()
end

-- casts calculated shadows onto a FBO
function Castling:castOn(canvas)
	l_gfx.push("all")
	self.shaders.ambient:send("isFOV",self.isFOV)
	l_gfx.setShader(self.shaders.ambient)
	l_gfx.draw(canvas)
	l_gfx.pop()
end

-- renders occlusion with OCC_F and generates shadowmap
function Castling:pass(occ_f)
	self.shaders.ambient:send("isFOV",self:getFOV())
	self.shaders.shadow:send("isFOV",self:getFOV())
	-- all calculations per lightsource must be performed here
	l_gfx.push("all")
	-- external occlusion map rendering function
	if self.use_occlusion_fbo == true then
		l_gfx.push()
		l_gfx.setCanvas(self.fb_occlusion)
		l_gfx.clear(0,0,0,0)
		l_gfx.setShader(self.shaders.occlusion)
		l_gfx.scale(1/self.sm_div,1/self.sm_div)
		occ_f()
		l_gfx.pop()
	end
		
	
	local lights = self.lights
	if #lights>0 then
		for i=#lights,1,-1 do
			if lights[i]:isEnabled() == true then
				self:passSource(lights[i],occ_f)
			end
		end
	end
	
	
	if self.enable_sb_blur == true then
		l_gfx.setCanvas(self.fb_shadowmap_t)
		l_gfx.setShader(self.shaders.blur_v)
		l_gfx.draw(self.fb_shadowmap)
		
		l_gfx.setCanvas(self.fb_shadowmap)
		l_gfx.setShader(self.shaders.blur_h)
		l_gfx.draw(self.fb_shadowmap_t)
		
	end
	
	self.shaders.ambient:send("ambient",self.ambient)
	self.shaders.ambient:send("lightmap",self.fb_shadowmap)
	
	l_gfx.pop()
end

-- lightsource pass - generate occlusion (if separate occlusion FBO is not used) and create shadowmap for this lightsource
function Castling:passSource(ls,of)
	l_gfx.push("all")
	local vpx,vpy,vpsx,vpsy,vphx,vphy = self.viewport[1],self.viewport[2],self.viewport[3],self.viewport[4],self.viewport[5],self.viewport[6]
	
	local x,y = ls:getPosition()
	x,y = (x-vpx)*vpsx,(y-vpy)*vpsy
	local r = ls:getRadius()*max(vpsx,vpsy)
	local h = ls:getHeight()
	local cr,cg,cb,ca = ls:getColor()
	local cast = ls:isCastShadow()
	
	-- pick appropriate canvas for this light
	local canv_index = 1
	local fb_2d,fb_2db,fb_1d,fbo_res
	if #self.occ_rt>1 then
		if cast == true then
			for i=#self.occ_rt+1,1,-1 do
				canv_index = i-1
				if canv_index>0 then
					if r<=self.occ_rt[canv_index][1] then break end
				end
			end
			if canv_index<1 then canv_index = 1 end
		else
			canv_index = #self.occ_rt
		end
		
	end
	
	fb_2d = self.occ_fbt[canv_index]
	fb_1d = self.lookup_fbt[canv_index]
	fbo_res = self.occ_rt[canv_index]
	
	
	-- here we draw occlusion map for each lightsource
	local lw = fbo_res[1]
	local lw_h = lw*0.5
	local ts = lw_h/r -- actual factor of light radius to occlusion map size
	local tsr = r/lw_h -- reverse factor to restore transorm
	
	l_gfx.setCanvas(fb_2d)
	l_gfx.clear(0,0,0,0)
	l_gfx.push()
	l_gfx.scale(ts,ts)
	l_gfx.translate(-x+lw_h*tsr,-y+lw_h*tsr)
	l_gfx.shear(vphx,vphy)
	if self.use_occlusion_fbo == true then
		l_gfx.draw(self.fb_occlusion,0,0,0,self.sm_div,self.sm_div)
	else
		l_gfx.setShader(self.shaders.occlusion)
		of()
	end
	l_gfx.pop()
	
	
	-- next we update 1d shadowmap for each lightsource
	
	l_gfx.setCanvas(fb_1d)
	if cast == false then
		l_gfx.clear(255,255,255,255)
	else
		self.shaders.raycast:send("occres",fbo_res)
		l_gfx.setShader(self.shaders.raycast)
		l_gfx.draw(fb_2d,lw_h,lw_h, math.pi,1,1, lw_h,lw_h)
	end

	
	-- and finally for each lightsource we render actuall shadow and enlight the area
	self.shaders.shadow:send("lcast",cast)
	self.shaders.shadow:send("shadowres",fbo_res)
	self.shaders.shadow:send("lheight",h)	
	l_gfx.setShader(self.shaders.shadow)
	l_gfx.setColor(cr,cg,cb,ca)
	l_gfx.push()
	l_gfx.scale(1/self.sm_div,1/self.sm_div)
	l_gfx.setCanvas(self.fb_shadowmap)
	l_gfx.setBlendMode("add")
	l_gfx.draw(fb_1d,x,y, 0, tsr,lw*tsr, lw_h,0.5)	
	l_gfx.pop()

	l_gfx.pop()
end

-- create framebuffers for Castling
function Castling:initMainFB()
	-- calculating shadowmap resolution against its divider if specified
	local sm_w,sm_h = l_gfx.getWidth()/self.sm_div,l_gfx.getHeight()/self.sm_div
	-- full shadow map and its blur buffer
	self.fb_shadowmap = l_gfx.newCanvas(sm_w,sm_h)
	self.fb_shadowmap_t = l_gfx.newCanvas(sm_w,sm_h)
	-- full occlusion canvas
	self:setOcclusionPrerender(self.use_occlusion_fbo)
end


