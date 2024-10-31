pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- plane
camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=25
cam_h=-5

fov=0.08
zfar=500
znear=3
lam=(zfar/zfar-znear)
//printh(lam)

objs={}

ppx,ppy,ppz=100,-1,0
//pp_dx,pp_dy,pp_dz=0,0,0
--yaw,pitch,roll
pp_ya,pp_pi,pp_ro=0.75,0,0
turn=0

function _init()
	printh("====== start ======")
	o1=obj(obj_base,0,0,0)
	o2=obj(obj_base,-30,0,0)
	o3=obj(obj_base,30,0,0)
	o4=obj(obj_base,0,0,-300)
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
	
	if camy<0 then
		local gh=64+pp_pi*512
		gh-=sin(pp_pi)*((500-camy)/500)*12
		gh=mid(0,gh,128)
		rectfill(0,gh,127,gh+127,3)
	end

	t_sorted={}
	for o in all(objs)do
		draw_obj(o)
	end
	
	draw_obj({
		tris=pp_base,
		x=ppx,y=ppy,z=ppz,
		ya=pp_ya,pi=pp_pi,ro=pp_ro
	})
	
	for t in all(t_sorted)do
		draw_tri(t,t[4])
	end

	pria(
		{flr(ppx),flr(ppy),flr(ppz)},
		0,0,7)
	pria({pp_ya,pp_pi,},0,6,7)
	//print(pp_ya.." "..pp_pi.." "..pp_ro,
	//0,6,7)
	//print(camx.." "..camy.." "..camz,
	//	0,12,6)
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
				
			dz_max=max(dz_max,dz)			
			add(tt,{px,py})
		end
			
		if dz_max>1 and dz_max<zfar then
			add(tt,t[4])
			add(tt,dz_max)
			
			local i=1
			while i<=#t_sorted+1 do
				if i>#t_sorted or 
							dz_max>t_sorted[i][5] then
					add(t_sorted,tt,i)
					i=#t_sorted+100
				end
				i+=1
			end
		end
	end
	
	//px,py=proj(o.x,o.y,o.z)
	//pset(px,py,8)
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
	local dz=z*lam-lam*znear
		
	if abs(px)>zfar or 
				abs(py)>zfar then
		return 0,0,zfar
	end
	
	dz=max(dz,0.5)
	px=-64*px/dz+64
	py=-64*py/dz+64
	if px<0 or px>127 or
				py<0 or py>127 then
		dz=0.5
	end
	return px,py,dz
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
	cam_ya=-pp_ya
	cam_pi=-pp_pi-sin(pp_pi)*0.01

	dcy,dcz=rot2d(
		cam_h,cam_d,-cam_pi)
	dcz,dcx=rot2d(
		dcz,0,-cam_ya)
	
	camz=ppz+dcz
	camx=ppx+dcx
	camy=ppy+dcy
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
	
	dx,dy,dz=rot3d(
		0,0,1,
		pp_pi,
		pp_ya,
		0)
	//dy,dz=rot2d(0,1,pp_pi)
	//dz,dx=rot2d(dz,0,pp_ya)
		
	ppx-=dx
	ppy-=dy
	ppz-=dz
	
	ppy=min(0,ppy)
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

function lerp(a,b,t)
	return a+(b-a)*t
end

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

pp_base={
	{
		{0,0,-10},
		{10,0,8},
		{0,0,0},
		7
	},
	{
		{0,0,0},
		{8,0,10},
		{0,0,8},
		13
	},
	{
		{0,0,-10},
		{-10,0,8},
		{0,0,0},
		13
	},
	{
		{0,0,0},
		{-8,0,10},
		{0,0,8},
		7
	},
	{
		{3,0,0},
		{3,0,10},
		{3,-5,10},
		7
	},
	{
		{-3,0,0},
		{-3,0,10},
		{-3,-5,10},
		13
	},
}

obj_base={
	{
		{-30,0,30},
		{0,-30,0},
		{30,0,30},
		10
	},
	{
		{-30,0,-30},
		{0,-30,0},
		{30,0,-30},
		9
	},
}

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700009009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000100000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
