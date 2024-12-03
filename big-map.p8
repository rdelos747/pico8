pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
ppx,ppy,ppz=64,0,64
pp_pi,pp_ya=0,0
sex,sez=0,0

camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=0
cam_h=-8
//cam_flip=0.5

-- pov
fov=0.11
fov_c=-2.778 // 1/tan(fov/2)
zfar=500
znear=-30
lam=zfar/(zfar-znear)

objs={}
cache={}
hist={}
enemy={}

d_mode=true

function _init()
	printh("====== init ======")
	for j=-1,1 do
		cache[j+2]={}
		for i=-1,1 do
			cache[j+2][i+2]=init_sec(i,j,i,j,true)
		end 
	end
end

function _draw()
	cls()
	spr(1,60,60)
	
	if not d_mode then
		for j=-1,1 do
		for i=-1,1 do
		local sec=cache[j+2][i+2]
		for s in all(sec) do
			local x=128*i+s[1]-(ppx-64)
			local y=128*j+s[2]-(ppz-64)
			spr(s[4],x-4,y-4)
			print(x.." "..y,x+8,y+4,1)
			print(s[1].." "..s[2],x+8,y+10,1)
		end
		end end
		
		line(
			64,64,
			64-cos(pp_ya+0.75)*40,
			64+sin(pp_ya+0.75)*40,
			9)
		
		print("p "..ppx.." "..ppz,0,0,8)
		print("s "..sex.." "..sez,0,6,8)
		print("a "..pp_ya,0,30,8)
		return
	end
	
	np=0--test
	
	t_sorted={}
	local gh=64+pp_pi*512
	
	gh-=sin(pp_pi)*((500-camy)/500)*12
	gh=mid(0,gh,128)
	
	rectfill(0,gh,127,gh+127,3)
	
	//for e in all(enemy)do
	//	proj_sprite(e)
	//end
	
	for j=-1,1 do
	for i=-1,1 do
		local sec=cache[j+2][i+2]
		for s in all(sec) do
			//local x=128*i+s[1]-(px-64)
			//local y=128*j+s[2]-(py-64)
			//spr(s[3],x,y)
			
			local drx=128*i+s[1]
			local drz=128*j+s[2]
			local a=atan2(
				drx-ppz,
				drz-ppx
			)
			sx,sy,dz=proj(
				128*i+s[1],
				0,
				128*j+s[2]
			)
			local onscr=(sx>-1 and 
																sx<128 and
																sy>-1 and 
																sy<128)
			//onscr=true
			//local pa=(pp_ya+0.75)%1
			//local a2=((a-pa)+0.1)%1
			//loga({
			//	((a-pp_ya)+0.1)%1,
			//	drx-ppz
			//})
			
			//if a2<=0.2 then
			//if ((a-pp_ya)+0.1)%1<0.2 then
				//printh(abs(a-pp_ya))
			if onscr then
				np+=1
				//loga({a,a2})
				//loga({"obj",128*i+s[1],128*j+s[2]})
				proj_obj({
					tris=s[4]==2 and tree_tris or tree_tris2,
					x=drx,
					y=0,
					z=drz,
					ya=s[3],pi=0,ro=0
				})
			end
		end
	end end
	
	draw_sorted()
	
	--[[
	for e in all(enemy)do
		spr(
			4,
			e.x-(px-64),
			e.y-(py-64))	
	end
	]]--
	
	print("p "..ppx.." "..ppz,0,0,8)
	print("s "..sex.." "..sez,0,6,8)
	print("h "..#hist,0,12,8)
	print("e "..#enemy,0,18,8)
	print("o "..#t_sorted.." "..np,0,24,8)
	print("a "..pp_ya,0,30,8)
end

function _update()
	if(btnp(❎))d_mode=not d_mode
	update_player()
	update_cam()
	
	local dx,dz=0,0
	if ppx>127 then
		ppx,dx=0,1
	elseif ppx<0 then
		ppx,dx=127,-1
	elseif ppz>127 then
		ppz,dz=0,1
	elseif ppz<0 then
		ppz,dz=127,-1
	end
	
	--[[
	for e in all(enemy)do
		update_e(e)
	end
	]]--
	
	if dx!=0 or dz!=0 then
		shift_cache(dx,dz)
		for e in all(enemy)do
			e.x-=128*dx
			e.z-=128*dz
			
			if e.x>256 or e.x<-256 or
						e.z>256 or e.z<-256 then
				del(enemy,e)
			end
		end
	end
	
	--[[
	for j=-1,1 do
	for i=-1,1 do
		local sec=cache[j+2][i+2]
		for s in all(sec) do
			
		end
	end end
	]]--
end

function shift_cache(dx,dz)
	sex+=dx
	sez+=dz
	printh("new sec "..sex.." "..sez)
	if dz==0 then
		for j=-1,1 do
			for i=2,2+dx,dx do
				cache[j+2][i-dx]=cache[j+2][i]
			end
			cache[j+2][2+dx]=init_sec(sex+dx,sez+j,dx,dz) 
		end
	elseif dx==0 then
		for	i=-1,1 do
			for j=2,2+dz,dz do
				cache[j-dz][i+2]=cache[j][i+2]
			end
			cache[2+dz][i+2]=init_sec(sex+i,sez+dz,dx,dz) 
		end
	end
	
	for j=1,3 do
	for i=1,3 do
		printh(i.." "..j.." "..#cache[j][i])
	end end
end

function init_sec(x,z,dx,dz)
	local seed=(x<<8)+z
	printh("at "..x.." "..z)
	
	srand(seed)
	
	--[[
	--test
	local sec={}
	if x==0 and z==0 then
		add(sec,{64,64,3})
		return sec
	else
		//add(sec,{})
		return sec
	end
	--end test
	]]--
	
	--always generate terrain
	local sec={}
	local n=flr(rnd(20))
	for i=0,n do
		local rx=flr(rnd(128))
		local rz=flr(rnd(128))
		local ra=rnd()
		local s=rnd()>0.5 and 2 or 3
		
		//rx=0
		//rx=64 --test
		//rz=64 --test
		add(sec,{rx,rz,ra,s})
	end
	
	local found=false
	for h in all(hist)do
		if(h==seed)found=true	
	end
	
	-- generate based if not in
	-- history
	if not found then
		n=flr(rnd(3))
		for i=0,n do
			local rx=flr(rnd(128))
			local rz=flr(rnd(128))
		
			--[[
			add(enemy,
				{
					x=rx+dx*128*2,
					y=ry+dy*128*2
				}
			)
			]]--
			local blob=obj(
				draw_blob,
				rx,0,rz,
				0,0,0,
				update_blob
			)
			add(objs,blob)
		end
		add(hist,seed,1)
	else
		printh("skip "..x.." "..z.." "..seed)
	end
	
	printh("=history=".." "..seed)
	for h in all(hist)do
		printh(h)
	end
	
	srand(time())
	//printh("init sec "..x.." "..y.." "..#sec)
	return sec
end


-->8
--pov

function proj_sprite(s)
	local px,py,dz=proj(
		s.x,s.y,s.z)
	if px<0 or px>127 or
				py<0 or py>127 then
		dz=0
	end
	sort_tri(
		{s.tris,{px,py}},s,dz)
end

function proj_obj(o)
	for t in all(o.tris)do
		local tt={}
		local dz_max=-1
		for i=1,3 do
			x,y,z=rot3d(
				t[i][1],
				t[i][2],
				t[i][3],
				0,
				0,
				o.ro)
			x,y,z=rot3d(
				x,y,z,
				o.pi,
				o.ya,
				0)
			
			local px,py,dz=proj(
				x+o.x,y+o.y,z+o.z)
			if px<0 or px>127 or
						py<0 or py>127 then
				dz=0
			end
			dz_max=max(dz_max,dz)			
			add(tt,{px,py})
		end
		
		sort_tri(tt,t[4],dz_max)
	end
	
	//px,py=proj(o.x,o.y,o.z)
	//pset(px,py,8)
end

--[[
	inserts 2 infos:
	1:z dist (highest of all pts in tri or sprite)
	2:color (or sprite obj if sprite)
	3..: existing info shifted
]]--
function sort_tri(tt,col,dz)
	//if dz>1 and dz<zfar then
	if dz>1 then
		add(tt,dz,1)
		add(tt,col,2)
			
		local i=1
		while i<=#t_sorted+1 do
			if i>#t_sorted or 
						dz>t_sorted[i][1] then
				add(t_sorted,tt,i)
				i=#t_sorted+100
			end
			i+=1
		end
	end
end

function proj(x,y,z)
	z,y,x=rot3d(
		z-camz,
		y-camy,
		x-camx,
		0,
		-cam_ya,
		-cam_pi)
						
	local dz=z*lam-lam*znear
	local dz0=max(1,dz)	
	
	local px=mid(
		-500,
		(x*fov_c)/dz0,
		500
	)
	local py=mid(
		-500,
		(y*fov_c)/dz0,
		500
	)
			
	px=-64*px+64
	py=-64*py+64
	
	return px,py,dz//,pxz,pyz
end

--[[
	hack for sprites:
	when creating sprites, we set
	the "tris" field to its 
	render function. when the sort
	function is called, the data
	is shifted, and t[3] is either
	the existing tris, or the 
	render function
]]--
function draw_sorted()
	for t in all(t_sorted)do
		if type(t[3])=="function" then
			//draw_sprite(t)
			t[3](t)
		else
			draw_tri(t,t[2])
		end
			
		//print(
	end
end

function rot2d(x,y,a)
	local rx=x*cos(a)-y*sin(a)
	local ry=x*sin(a)+y*cos(a)
	return rx,ry,pz
end

function rot3d(x,y,z,pi,ya,ro)
	--x axis rotation (pitch) 
	local y1,z1=rot2d(y,z,pi)
	--y axis rotation (yaw) 
	local z2,x1=rot2d(z1,x,ya)
	--z axis rotation (roll) 
	local x2,y2=rot2d(x1,y1,ro)
	
	return x2,y2,z2
end


function draw_tri(t,c)
	pelogen_tri(
		t[3][1],t[3][2],
		t[4][1],t[4][2],
		t[5][1],t[5][2],
		c)
	fillp()
end

function pelogen_tri(l,t,c,m,r,b,col,f)
	color(col)
	fillp(f)
	if(t>m) l,t,c,m=c,m,l,t
	if(t>b) l,t,r,b=r,b,l,t
	if(m>b) c,m,r,b=r,b,c,m
	local i,j,k,r=(c-l)/(m-t),(r-l)/(b-t),(r-c)/(b-m),l
	while t~=b do
		for t=ceil(t),min(flr(m),1024) do
			rectfill(l,t,r,t)
			r+=j
			l+=i
		end
		l,t,m,i=c,m,b,k
	end
end
-->8
--player

function update_cam()

	cam_ya=-pp_ya
	//cam_pi=pp_pi+sin(pp_pi)*0.05
	
	dcy,dcz=rot2d(
		cam_h,cam_d,-cam_pi)
	dcz,dcx=rot2d(
		dcz,0,-cam_ya)
	
	camz=ppz+dcz
	camx=ppx+dcx
	camy=ppy+dcy
end


function update_player()
	local ppv=0
	if(btn(➡️))pp_ya-=0.01
	if(btn(⬅️))pp_ya+=0.01
	pp_ya=pp_ya%1
	if(btn(⬇️))ppv=1
	if(btn(⬆️))ppv=-1
	
	dx,dy,dz=rot3d(
		0,0,ppv,
		pp_pi,
		pp_ya,
		0)
		
	ppx-=dx
	ppy-=dy
	ppz-=dz
end
-->8
-- enemy

function draw_blob(b)
	local z=(zfar-b[1])/zfar
	spr(3,b[4][1],b[4][2],z,z)
end

function update_blob(b)
	local a=atan2(e.x-ppx,e.y-ppy)
	e.x-=cos(a)*0.2
	e.y-=sin(a)*0.2
end

function draw_tree(t)
	local z=(zfar-t[1])/200
	spr(2,t[4][1],t[4][2],z,z)
end
-->8
-- helpers

function obj(tris,x,y,z,ya,pi,ro,up)
	local o={
		tris=tris,
		x=x,y=y,z=z,
		ya=ya,pi=pi,ro=ro,
		scrx=-1,scry=-1,
		update=up
	}
	return o
end

function get_onscr(o)
	sx,sy,dz=proj(o.x,o.y,o.z)
	o.scrx,o.scry=flr(sx),flr(sy)
	o.scrdz=flr(dz)
end

function onscr(o)
	return o.scrx>-1 and 
								o.scrx<128 and
								o.scry>-1 and 
								o.scry<128
end

--debug functions
--todo remove
function a_to_s(arr)
	local s=arr[1]
	for i=2,#arr do
		s=s.." "..arr[i]
	end
	return s
end

function loga(arr)
	printh(a_to_s(arr))
end

function pria(arr,x,y,c)
	print(a_to_s(arr),x,y,c)
end
-->8
-- models
tree_tris={
	{
		{-4,0,0},
		{4,0,0},
		{0,-5,0},
		4
	},
	{
		{-10,-5,0},
		{10,-5,0},
		{0,-25,0},
		11
	},
	{
		{-10,-25,0},
		{10,-25,0},
		{0,-40,0},
		11
	}
}

tree_tris2={
	{
		{-4,0,0},
		{4,0,0},
		{0,-5,0},
		4
	},
	{
		{-10,-5,0},
		{10,-5,0},
		{0,-25,0},
		14
	},
	{
		{-10,-25,0},
		{10,-25,0},
		{0,-40,0},
		14
	}
}
__gfx__
00000000009999000b30bbb00e20eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009000090bbbbb3bbeeeee2ee000ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070090099909b3bbbbbbe2eeeeee00e22e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700090900909bbbbbbb3eeeeeee20e2222e000eeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000909009090bb3b3bb0ee2e2eee272272e0e2222e000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007009009999000bbb4b000eee4e0e222222ee272272e00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000900000000444500004445000e2222e0e222222e00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000999900054545400545454000eeee000eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000
