pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--[[
	f-15 dimensions
	wingspan: ~14m
	length: ~20m
]]--

pp_base={
	{
		{0,-10,0},
		{7,10,0},
		{0,10,0},
		7
	},
	{
		{0,-10,0},
		{-7,10,0},
		{0,10,0},
		13
	},
	{
		{3,0,0},
		{3,10,0},
		{3,10,5},
		13
	},
	{
		{-3,0,0},
		{-3,10,0},
		{-3,10,5},
		7
	},
}

obj_base={
	{
		{-10,0,-10},
		{-10,0,10},
		{10,0,10},
		10
	},
	{
		{10,0,-10},
		{-10,0,-10},
		{10,0,10},
		11
	},
}

ppx,ppy,ppz=0,0,0
ppya,pppi,ppro=0,0,0--yaw,pitch,roll
turn=0
camx,camy,camz,cama=0,0,0,0

//pov_o=0
cam_d=30
cam_h=1
pov_d=600
//pvt_y=0
//pvt_x=0

objs={}

function obj(tris)
	return {
		tris=tris,
		x=0,y=0,z=0,
		ya=0,pi=0,ro=0 --yaw,pitch,roll
	}
end

function _init()
	printh("====== start ======")
	
	o1=obj(obj_base)
	o1.x=-30
	o1.y=100
	add(objs,o1)
	
	o2=obj(obj_base)
	o2.x=30
	o2.y=100
	add(objs,o2)
	
	o3=obj(obj_base)
	o3.x=-30
	o3.y=150
	add(objs,o3)
	
	o4=obj(obj_base)
	o4.x=30
	o4.y=150
	add(objs,o4)
end

function _draw()
	cls()
	camera(camx-64,camy-64)
	
	rectfill(camx-64,camy,
		camx+64,camy+64,1)
	
	for o in all(objs)do
		draw_obj(o)
	end
	draw_obj({
		tris=pp_base,
		x=ppx,y=ppy,z=ppz,
		ya=ppya,pi=pppi,ro=ppro
	})
	
	print(ppx,camx-64,camy-64,7)
	print(ppy,camx-64,camy-56,7)
	print(ppya,camx-64,camy-48,7)
	print(pppi,camx-64,camy-40,7)
end

function _update()
	camx=ppx-cam_d*cos(ppya+0.75)
	camy=ppy+cam_d*sin(ppya+0.25)
	camz=ppz+cam_h
	cama=-ppya
		
	update_plane()
end

function update_plane()
	if btn(⬆️) then
		pppi=max(pppi-0.01,-0.125)
	elseif btn(⬇️) then
		pppi=min(pppi+0.01,0.125)
	elseif pppi<0 then
		pppi=min(pppi+0.01,0)
	elseif pppi>0 then
		pppi=max(pppi-0.01,0)
	end
	
	if btn(➡️) then
		turn=max(turn-0.001,-0.01)
		ppro=max(ppro-0.01,-0.125)
	elseif btn(⬅️) then
		turn=min(turn+0.001,0.01)
		ppro=min(ppro+0.01,0.125)
	else
		if turn<0 then
			turn=min(turn+0.001,0)
		elseif turn>0 then
			turn=max(turn-0.001,0)
		end
		
		if ppro<0 then
			ppro=min(ppro+0.01,0)
		elseif ppro>0 then
			ppro=max(ppro-0.01,0)
		end
	end
	
	ppya+=turn
	
	local vx=cos(ppya-0.25)
	local vy=sin(ppya+0.75)
	local vz=sin(pppi)
	
	ppx+=vx+vx*vz
	ppy+=vy+vy*vz
	
	ppz-=vz
end
-->8
--pov

function draw_obj(o)
	for tri in all(o.tris)do
		local tt={}
		for i=1,3 do
			local p=tri[i]

			local rx,ry,rz=rot3d(
				p[1],p[2],p[3],
				o.ya+0.5,o.pi,o.ro)
			
			add(tt,{
				rx+o.x,
				ry+o.y,
				rz+o.z
			})
		end
		draw_tri(tt,tri[4])
	end
end

function pov(x,y,z)	
	local dx=x-camx
	local dy=y-camy
	
	local rx,ry=rot2d(
		dx,-dy,cama)
		
	//printh(rx.." "..ry)
	
	local de=max(0.1,ry)

	povy=-pov_d/de
	//povy=-pvt_y+(pvt_y-64)-povy
	povy+=(z-camz)*(30/de)
	//povy=mid(-128,povy,128)
	
	//local povx=rx*min(60/de,7.5)
	povx=(rx/de)*40
	
	//printh(povx.." "..povy)
	
	return camx-povx,camy-povy,ry
end

function rot2d(x,y,a)
	local rx=x*cos(a)+y*sin(a)
	local ry=x*sin(a)-y*cos(a)
	return rx,ry
end

function rot3d(x,y,z,ya,pi,ro)
	local cy,sy=cos(ya),sin(ya)
	local cp,sp=cos(pi),sin(pi)
	local cr,sr=cos(ro),sin(ro)
	
 local axx=cy*cr
 local axy=cy*sr*sp-sy*cp
 local axz=cy*sr*cp+sy*sp

 local ayx=sy*cr
 local ayy=sy*sr*sp+cy*cp
 local ayz=sy*sr*cp-cy*sp

 local azx=-sr
 local azy=cr*sp
 local azz=cr*cp
 
 local rx=x*axx+y*axy+z*axz
 local ry=x*ayx+y*ayy+z*ayz
 local rz=x*azx+y*azy+z*azz
 
 return rx,ry,rz
end


function draw_tri(t,c)
	local p1x,p1y,p1d=pov(t[1][1],t[1][2],t[1][3])
	local p2x,p2y,p2d=pov(t[2][1],t[2][2],t[2][3])
	local p3x,p3y,p3d=pov(t[3][1],t[3][2],t[3][3])
		
	//printh(p1x.." "..p1y)
	
	if p1d>-13 or p2d>-13 or p3d>-13 then
	//if p1d>0 or p2d>0 or p3d>0 then	
		pelogen_tri(
			p1x,p1y,
			p2x,p2y,
			p3x,p3y,
			c)
	end
end

--trifill
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
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
