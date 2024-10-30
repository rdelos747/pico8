pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- plane
camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0

fov=0.08
zfar=600
znear=3
lam=(zfar/zfar-znear)
//printh(lam)

objs={}

ppx,ppy,ppz=0,0,100
pp_dx,pp_dy,pp_dz=0,0,0
--yaw,pitch,roll
pp_ya,pp_pi,pp_ro=0,0,0
turn=0

c_dx,c_dy,c_dz=0,0,0

function _init()
	printh("====== start ======")
	o1=obj(obj_base,0,0,0)
	o2=obj(obj_base,-30,0,0)
	o3=obj(obj_base,30,0,0)
	
	o4=obj(obj_base,-300,0,0)
	o5=obj(obj_base,300,0,0)
	o6=obj(obj_base,0,0,500)
	
	
	add(objs,o1)
	add(objs,o2)
	add(objs,o3)
	add(objs,o4)
	add(objs,o5)
	add(objs,o6)
end

function _draw()
	cls()
	
	for o in all(objs)do
		draw_obj(o)
	end
	
	draw_obj({
		tris=pp_base,
		x=ppx,y=ppy,z=ppz,
		ya=pp_ya,pi=pp_pi,ro=pp_ro
	})
	
	print(ppx.." "..ppy.." "..ppz,
		0,0,7)
	print(pp_ya.." "..pp_pi.." "..pp_ro,
		0,6,7)
	print(camx.." "..camy.." "..camz,
		0,12,6)
//	print(dcx.." "..dcy.." "..dcz,
	//	0,18,6)
end

function _update()
	update_plane()
	update_cam()
end
-->8
-- pov

function draw_obj(o)
	for t in all(o.tris)do
		tt={}
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
			
						
			local px,py=proj(
				x+o.x,y+o.y,z+o.z)
			add(tt,{px,py})
		end
		
		draw_tri(tt,t[4])
	end
	
	px,py=proj(o.x,o.y,o.z)
	pset(px,py,8)
end

function proj(x,y,z)
	z,y,x=rot3d(
		z-camz,
		y-camy,
		x-camx,
		0,
		-cam_ya,
		-cam_pi)
			
	local px=x*(1/tan(fov/2))
	local py=y*(1/tan(fov/2))
	local pz=z*lam-lam*znear
			

	//printh(z)
	//local px,py=0,0
	//if z>0 then
	pz=max(pz,1)
	px=-64*px/pz+64
	py=-64*py/pz+64
	return px,py
end

function rot2d(x,y,a)
	local rx=x*cos(a)-y*sin(a)
	local ry=x*sin(a)+y*cos(a)
	return rx,ry
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
		t[1][1],t[1][2],
		t[2][1],t[2][2],
		t[3][1],t[3][2],
		c)
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
-- player 


function update_cam()
	//camz=ppz+30*cos(pp_ya)
	//camx=ppx+30*sin(pp_ya)
	//camy=ppy-5
	
	//camz=ppz+30
	//camx=ppx
	//camy=ppy-5
	
	--[[
	camx,camy,camz=rot3d(
		ppx+30,ppy-5,ppz+30,
		-pp_pi,
		-pp_ya,
		0)
	]]--
	
	cam_ya=-pp_ya
	cam_pi=-pp_pi
	--[[
	dcz,dcy,dcx=rot3d(
		30,-5,0,
		pp_pi,
		pp_ya,
		0)
	]]--
	
	dcx,dcy,dcz=0,-5,30

	//dcz,dcx=rot2d(30,0,-cam_ya)
	dcy,dcz=rot2d(-5,30,-cam_pi)
	dcz,dcx=rot2d(dcz,0,-cam_ya)
	camz=ppz+dcz
	camx=ppx+dcx
	camy=ppy+dcy
	//camz=ppz+30
	//camx=0
	//camy=-5
	
	//dcy=-5
	//dcz,dcx=rot2d(30,0,-cam_ya)

	//printh(dcx.." "..dcy.." "..dcz)
	
	//camz=ppz-dcz
	//camx=ppx-dcx
	//camy=ppy-dcy
	//camz=ppz+30
	//camx=0
	//camy=-5
	
		
	//cam_ya=-pp_ya
	//cam_pi=pp_pi
	
	//camy=ppy-5
end

function update_plane()
	if btn(⬆️) then
		pp_pi=max(pp_pi-0.01,-0.125)
	elseif btn(⬇️) then
		pp_pi=min(pp_pi+0.01,0.125)
	end
	--[[
	elseif pp_pi<0 then
		pp_pi=min(pp_pi+0.01,0)
	elseif pp_pi>0 then
		pp_pi=max(pp_pi-0.01,0)
	end
	]]--
	
	if btn(➡️) then
		turn=max(turn-0.001,-0.01)
		pp_ro=max(pp_ro-0.01,-0.125)
	elseif btn(⬅️) then
		turn=min(turn+0.001,0.01)
		pp_ro=min(pp_ro+0.01,0.125)
	else
		if turn<0 then
			turn=min(turn+0.001,0)
		elseif turn>0 then
			turn=max(turn-0.001,0)
		end
		
		if pp_ro<0 then
			pp_ro=min(pp_ro+0.01,0)
		elseif pp_ro>0 then
			pp_ro=max(pp_ro-0.01,0)
		end
	end
	
	pp_ya-=turn
	pp_ya=pp_ya%1
	
	pp_dx,pp_dy,pp_dz=rot3d(
		0,0,1,
		pp_pi,
		pp_ya,
		0)
		
	ppx-=pp_dx
	ppy-=pp_dy
	ppz-=pp_dz
end
-->8
-- helpers

function obj(tris,x,y,z)
	return {
		tris=tris,
		x=x,y=y,z=z,
		ya=0,pi=0,ro=0
	}
end

function tan(a)
	return sin(a)/cos(a)
end
-->8
-- models

pp_base={
	{
		{0,0,-10},
		{7,0,10},
		{0,0,10},
		7
	},
	{
		{0,0,-10},
		{-7,0,10},
		{0,0,10},
		13
	},
	{
		{3,0,0},
		{3,0,10},
		{3,-5,10},
		13
	},
	{
		{-3,0,0},
		{-3,0,10},
		{-3,-5,10},
		7
	},
}

obj_base={
	{
		{-10,0,10},
		{0,-10,0},
		{10,0,10},
		10
	},
	{
		{-10,0,-10},
		{0,-10,0},
		{10,0,-10},
		9
	},
}

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
