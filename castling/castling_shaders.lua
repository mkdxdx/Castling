local l_gfx = love.graphics

-- vertical blur pass
local c_blur_vert = [[	
	// Faster Gaussian Blur shader by xissburg
	// http://xissburg.com/faster-gaussian-blur-in-glsl/
	// adapted for love2d by mkdxdx/cval

	varying vec2 v_texCoord;
	varying vec2 v_blurTexCoords[14];

	#ifdef VERTEX
	vec4 position( mat4 transform_projection, vec4 vertex_position )
	{
		v_texCoord = VaryingTexCoord.st;
		v_blurTexCoords[0] = v_texCoord + vec2(0.0, -0.028);
		v_blurTexCoords[1] = v_texCoord + vec2(0.0, -0.024);
		v_blurTexCoords[2] = v_texCoord + vec2(0.0, -0.020);
		v_blurTexCoords[3] = v_texCoord + vec2(0.0, -0.016);
		v_blurTexCoords[4] = v_texCoord + vec2(0.0, -0.012);
		v_blurTexCoords[5] = v_texCoord + vec2(0.0, -0.008);
		v_blurTexCoords[6] = v_texCoord + vec2(0.0, -0.004);
		v_blurTexCoords[7] = v_texCoord + vec2(0.0,  0.004);
		v_blurTexCoords[8] = v_texCoord + vec2(0.0,  0.008);
		v_blurTexCoords[9] = v_texCoord + vec2(0.0,  0.012);
		v_blurTexCoords[10] = v_texCoord + vec2(0.0,  0.016);
		v_blurTexCoords[11] = v_texCoord + vec2(0.0,  0.020);
		v_blurTexCoords[12] = v_texCoord + vec2(0.0,  0.024);
		v_blurTexCoords[13] = v_texCoord + vec2(0.0,  0.028);
		return transform_projection * vertex_position;
	}
	#endif
	 
	#ifdef PIXEL
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
	{
		vec4 f_color = vec4(0.0);
		f_color += Texel(texture, v_blurTexCoords[0])*0.0044299121055113265;
		f_color += Texel(texture, v_blurTexCoords[1])*0.00895781211794;
		f_color += Texel(texture, v_blurTexCoords[2])*0.0215963866053;
		f_color += Texel(texture, v_blurTexCoords[3])*0.0443683338718;
		f_color += Texel(texture, v_blurTexCoords[4])*0.0776744219933;
		f_color += Texel(texture, v_blurTexCoords[5])*0.115876621105;
		f_color += Texel(texture, v_blurTexCoords[6])*0.147308056121;
		f_color += Texel(texture, v_texCoord)*0.159576912161;
		f_color += Texel(texture, v_blurTexCoords[7])*0.147308056121;
		f_color += Texel(texture, v_blurTexCoords[8])*0.115876621105;
		f_color += Texel(texture, v_blurTexCoords[9])*0.0776744219933;
		f_color += Texel(texture, v_blurTexCoords[10])*0.0443683338718;
		f_color += Texel(texture, v_blurTexCoords[11])*0.0215963866053;
		f_color += Texel(texture, v_blurTexCoords[12])*0.00895781211794;
		f_color += Texel(texture, v_blurTexCoords[13])*0.0044299121055113265;
		return f_color;
	}
	#endif
]]

local s_blur_vert = l_gfx.newShader(c_blur_vert)


local c_blur_horiz = [[	
	// Faster Gaussian Blur shader by xissburg
	// http://xissburg.com/faster-gaussian-blur-in-glsl/
	// adapted for love2d by mkdxdx/cval

	varying vec2 v_texCoord;
	varying vec2 v_blurTexCoords[14];	
	
	#ifdef VERTEX
	vec4 position( mat4 transform_projection, vec4 vertex_position )
	{
		v_texCoord = VaryingTexCoord.st;
		v_blurTexCoords[0] = v_texCoord + vec2(-0.028, 0.0);
		v_blurTexCoords[1] = v_texCoord + vec2(-0.024, 0.0);
		v_blurTexCoords[2] = v_texCoord + vec2(-0.020, 0.0);
		v_blurTexCoords[3] = v_texCoord + vec2(-0.016, 0.0);
		v_blurTexCoords[4] = v_texCoord + vec2(-0.012, 0.0);
		v_blurTexCoords[5] = v_texCoord + vec2(-0.008, 0.0);
		v_blurTexCoords[6] = v_texCoord + vec2(-0.004, 0.0);
		v_blurTexCoords[7] = v_texCoord + vec2( 0.004, 0.0);
		v_blurTexCoords[8] = v_texCoord + vec2( 0.008, 0.0);
		v_blurTexCoords[9] = v_texCoord + vec2( 0.012, 0.0);
		v_blurTexCoords[10] = v_texCoord + vec2( 0.016, 0.0);
		v_blurTexCoords[11] = v_texCoord + vec2( 0.020, 0.0);
		v_blurTexCoords[12] = v_texCoord + vec2( 0.024, 0.0);
		v_blurTexCoords[13] = v_texCoord + vec2( 0.028, 0.0);
		return transform_projection * vertex_position;
	}
	#endif
	 
	#ifdef PIXEL
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
	{
		vec4 f_color = vec4(0.0);
		f_color += Texel(texture, v_blurTexCoords[0])*0.0044299121055113265;
		f_color += Texel(texture, v_blurTexCoords[1])*0.00895781211794;
		f_color += Texel(texture, v_blurTexCoords[2])*0.0215963866053;
		f_color += Texel(texture, v_blurTexCoords[3])*0.0443683338718;
		f_color += Texel(texture, v_blurTexCoords[4])*0.0776744219933;
		f_color += Texel(texture, v_blurTexCoords[5])*0.115876621105;
		f_color += Texel(texture, v_blurTexCoords[6])*0.147308056121;
		f_color += Texel(texture, v_texCoord)*0.159576912161;
		f_color += Texel(texture, v_blurTexCoords[7])*0.147308056121;
		f_color += Texel(texture, v_blurTexCoords[8])*0.115876621105;
		f_color += Texel(texture, v_blurTexCoords[9])*0.0776744219933;
		f_color += Texel(texture, v_blurTexCoords[10])*0.0443683338718;
		f_color += Texel(texture, v_blurTexCoords[11])*0.0215963866053;
		f_color += Texel(texture, v_blurTexCoords[12])*0.00895781211794;
		f_color += Texel(texture, v_blurTexCoords[13])*0.0044299121055113265;
		return f_color;
	}
	#endif
]]

local s_blur_horiz = l_gfx.newShader(c_blur_horiz)


local amblight_shader = [[
	// this shader mixes ambient light 
	// with shadow map texels and input scene texels
	extern vec4 ambient;
	// this will turn off color multiplying so that spotlight effect will not be present
	extern bool isFOV;
	extern Image lightmap;
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{	
		vec4 sc_tex = Texel(texture,texture_coords); // aka diffuse
		vec4 lm_tex = Texel(lightmap,texture_coords); // aka lightmap data
		if (isFOV == true)
		{
			return sc_tex*lm_tex.r;
		} else
		{
			vec3 amblt = ambient.rgb*ambient.a;
			vec3 intensity = amblt+lm_tex.rgb;
			vec3 fcol = sc_tex.rgb*intensity;
			return color*vec4(fcol,sc_tex.a*lm_tex.a)+vec4(sc_tex.rgb*lm_tex.rgb,lm_tex.a);		
		}
	}
]]

local amb_shader = l_gfx.newShader(amblight_shader)

-- generating shadow from 1d and blur it
local shadow_code = [[
	// Pixel perfect shadows by davedes
	// https://github.com/mattdesl/lwjgl-basics/wiki/2D-Pixel-Perfect-Shadows
	// adapted for love2d by mkdxdx/cval

	const float PI = 3.1415926535897;
	extern float lheight;
	extern bool lcast;
	extern vec2 shadowres;
	extern float blur_step_width = 1.0;
	extern bool isFOV;
	
	float sample(vec2 coord, float r, Image texture) {
		return step(r,Texel(texture,coord).r);
	}
	
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
		// rect to pol
		vec2 norm = texture_coords.st*2.0-1.0;
		float r = length(norm);
		if ((lcast == true) || (isFOV == true))
		{
			float theta = atan(norm.y,norm.x);
			float coord = (theta + PI)/(2.0*PI);
			// coordinate to sample from s1d
			vec2 sc = vec2(coord,0.0);
			// hard shadow on center
			float cent = sample(sc,r,texture);
			// blur away
			float sum = 0.0;
			float blur = (1./shadowres.x)  * smoothstep(0.,1.,r);
			sum += sample(vec2(sc.x - blur_step_width*4.0*blur, sc.y), r, texture) * 0.05;
			sum += sample(vec2(sc.x - blur_step_width*3.0*blur, sc.y), r, texture) * 0.09;
			sum += sample(vec2(sc.x - blur_step_width*2.0*blur, sc.y), r, texture) * 0.12;
			sum += sample(vec2(sc.x - blur_step_width*1.0*blur, sc.y), r, texture) * 0.15;
			sum += cent * 0.16;
			sum += sample(vec2(sc.x + blur_step_width*1.0*blur, sc.y), r, texture) * 0.15;
			sum += sample(vec2(sc.x + blur_step_width*2.0*blur, sc.y), r, texture) * 0.12;
			sum += sample(vec2(sc.x + blur_step_width*3.0*blur, sc.y), r, texture) * 0.09;
			sum += sample(vec2(sc.x + blur_step_width*4.0*blur, sc.y), r, texture) * 0.05;
			
			if (isFOV == false)
				return color*vec4(vec3(1.0),max(sum,pow(lheight,2))*smoothstep(1.0,0.0,r));
			else
				return color*vec4(vec3(1.0),sum);
		} else
		{
			return color*vec4(vec3(1.0),smoothstep(1.0,0.0,r));
		}
	}
	
	
]]

local shadow_shader = l_gfx.newShader(shadow_code)

-- thresholding for occlusion map
local pix_threshold = [[
	// makes stencil out of image for occlusion map
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
		vec4 tc = Texel(texture, texture_coords);
		if (tc.a>0)	tc.rgb *= 0;
		else discard;
		return tc;
	}
]]

local occ_shader = l_gfx.newShader(pix_threshold)


-- generate 1d shadowmap
local pix_raycast = [[
	// Pixel perfect shadows by davedes
	// https://github.com/mattdesl/lwjgl-basics/wiki/2D-Pixel-Perfect-Shadows
	// adapted for love2d by mkdxdx/cval

	const float PI = 3.1415926535897;
	extern vec2 occres;
	const float threshold = 0.5;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
		float distance = 1.0;
		for (float y=0.0; y<=occres.y; y+=1.0)
		{
			// rect to pol
			vec2 norm = vec2(texture_coords.s,y/occres.y)*2.0 - 1.0;
			float theta = PI * 1.5 + norm.x * PI;
			float r = (1.0+norm.y)*0.5;
			// sampling coord
			vec2 coord = vec2(-r * sin(theta), -r * cos(theta))/2.0 + 0.5;
			// sampling occlusion map
			vec4 occ_tc = Texel(texture,coord);
			// get distance
			float dst = y/occres.y;
			float caster = occ_tc.a;
			if (caster>threshold) {
				distance = min(distance,dst);
				break;
			}
		}
		
		//vec4 tc = Texel(texture, texture_coords);
		return vec4(vec3(distance),1.0);

	}
]]
local raycast_shader = l_gfx.newShader(pix_raycast)

return {raycast = raycast_shader,occlusion = occ_shader,shadow = shadow_shader,ambient = amb_shader,blur_h = s_blur_horiz,blur_v = s_blur_vert}