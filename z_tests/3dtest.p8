pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--3d test

tris={
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

objs={}

camx,camy,camz=0,-20,60
//dx,dy,dz=0,0,0 //for testing
cam_ya,cam_pi,cam_ro=0,0,0
//vi_ya,vi_pi,vi_ro=0,0,0
cam_mode=0

fov=0.1
zfar=100
znear=3
//lam=(zfar/zfar-znear)

//view_m={}

function _init()
	printh("------ start ------")
	poke(0x5f2d, 0x1)
	
	add(objs,{-60,0,-20})
	add(objs,{0,0,-20})
	add(objs,{60,0,-20})
	
	//add(objs,{0,0,0})
end

function _draw()
	cls()
	
	for o in all(objs) do
		draw_obj(o)
	end
	
	--[[
	print("pos: "..camx.." "..camy.." "..camz,
		0,0,cam_mode==0 and 8 or 7)
	print("dir dx:"..dx..
							" dy:"..dy..
							" dz:"..dz,
		0,6,6)
	print("cam_ya: "..
							cam_ya.." "..
							cos(cam_ya).." "..
							sin(cam_ya),
		0,12,cam_mode==1 and 8 or 7)
	print("cam_pi: "..
							cam_pi.." "..
							cos(cam_pi).." "..
							sin(cam_pi),
		0,18,cam_mode==1 and 8 or 7)
	print("cam_ro: "..
							cam_ro.." "..
							cos(cam_ro).." "..
							sin(cam_ro),
		0,24,cam_mode==1 and 8 or 7)
	]]--
	--[[
	print("zn,zf: "..znear.." "..zfar,
		0,18,6)
	print("fov: "..fov,
		0,25,6)
	]]--
	
	--[[
	print(test,90,0)
	print(test2,90,6)
	]]--
	
	line(27,120,64,100,7)
	line(100,120,64,100,7)
end

function _update()
	lam=(zfar/zfar-znear)
	
	local inx,inz=0,0

	if btn(❎) then
		if(btn(⬆️))cam_pi-=0.01
		if(btn(⬇️))cam_pi+=0.01
		if(btn(⬅️))cam_ya+=0.01
		if(btn(➡️))cam_ya-=0.01
		cam_mode=1
	else
		if(btn(⬆️))inz=-1
		if(btn(⬇️))inz=1
		if(btn(⬅️))inx-=1
		if(btn(➡️))inx+=1
		cam_mode=0
	end
	
	cam_ya=cam_ya%1
	cam_pi=cam_pi%1
	cam_ro=cam_ro%1
	
	dx,dy,dz=rot3d(
		0,0,1,
		-cam_pi,
		-cam_ya,
		0)
	
	dx,dy,dz=rot3d(
		dx,dy,dz,
		0,
		0,
		-cam_ro)
		
	
	--[[
	dz,dy,dx=rot3d(
		1,0,0,
		cam_ro,
		cam_ya,
		0)
	
	dz,dy,dx=rot3d(
		dz,dy,dx,
		0,
		0,
		cam_ro)
	]]--
		
	camx+=dx*inz
	camy+=dy*inz
	camz+=dz*inz
	
	
	local kb=stat(31)
	//if(kb=='q')znear-=2
	//if(kb=='w')znear+=2
	//if(kb=='e')zfar-=2
	//if(kb=='r')zfar+=2
	//if(kb=='t')fov-=0.1
	//if(kb=='y')fov+=0.1
	if(kb=='a')cam_ro+=0.01
	if(kb=='s')cam_ro-=0.01
	
end

-->8
--drawing

//test=0
//test2=0
function draw_obj(o)
	cc=0
	for t in all(tris)do
		tt={}
		for i=1,3 do
			local x=t[i][1]+o[1]
			local y=t[i][2]+o[2]
			local z=t[i][3]+o[3]
			x=x-camx
			y=y-camy
			z=z-camz
			
			x,y,z=rot3d(
				x,y,z,
				0,
				cam_ya,
				0)
			
			x,y,z=rot3d(
				x,y,z,
				cam_pi,
				0,
				0)
				
			x,y,z=rot3d(
				x,y,z,
				0,
				0,
				cam_ro)
		
			
			
			local px=x*(1/tan(fov/2))
			local py=y*(1/tan(fov/2))
			local pz=z*lam-lam*znear
			

			//printh(z)
			//local px,py=0,0
			//if z>0 then
			pz=max(pz,1)
			px=-64*px/pz+64
			py=-64*py/pz+64
			//end
			
			--[[
			add(tt,{
				mid(0,px,127),
				mid(0,py,127)
			})
			]]--
			add(tt,{px,py})
			
			--[[
			if cc==0 then
				test=z
				test2=py
			end
			cc+=1
			]]--
			
			//add(tt,{px,py})
		end
		
		draw_tri(tt,t[4])
	end
end

function draw_tri(t,c)
	//for i=1,3 do
		//local p1x,p1y=t[i][1],t[i][2]
	
//	if p1d>-13 or p2d>-13 or p3d>-13 then
	//if p1d>0 or p2d>0 or p3d>0 then	
		--[[
		pelogen_tri(
			p1x,p1y,
			p2x,p2y,
			p3x,p3y,
			c)
			]]--
		pelogen_tri(
			t[1][1],t[1][2],
			t[2][1],t[2][2],
			t[3][1],t[3][2],
			c)
	//end
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
--helpers

--[[
function rot3d(x,y,z,ya,pi,ro)
	local cy,sy=cos(ya),sin(ya)
	local cp,sp=cos(pi),sin(pi)
	local cr,sr=cos(ro),sin(ro)
	
 local axx=cr*cy
 local axy=cr*sy*sp-sr*cp
 local axz=cr*sy*cp+sr*sp

 local ayx=sr*cy
 local ayy=sr*sy*sp+cr*cp
 local ayz=sr*sy*cp-cr*sp

 local azx=-sy
 local azy=cy*sp
 local azz=cy*cp
 
 local rx=x*axx+y*axy+z*axz
 local ry=x*ayx+y*ayy+z*ayz
 local rz=x*azx+y*azy+z*azz
 
 return rx,ry,rz
end
]]--

function rot2d(x,y,a)
	local rx=x*cos(a)-y*sin(a)
	local ry=x*sin(a)+y*cos(a)
	return rx,ry
end


--[[
this works well for yaw and
pitch, but the roll axis is stuck
on the forward vector always.
im not really sure if its
gimbal lock or not.

eg, changing this from zyx to
xyz fixes the roll problem but
then causes the same to happen
to the pitch.

hmmmm...
]]--
function rot3d(x,y,z,pi,ya,ro)
	--x axis rotation (pitch) 
	local y1,z1=rot2d(y,z,pi)
	--y axis rotation (yaw) 
	local z2,x1=rot2d(z1,x,ya)
	--z axis rotation (roll) 
	local x2,y2=rot2d(x1,y1,ro)
	
	return x2,y2,z2
end

function tan(a)
	return sin(a)/cos(a)
end
-->8
-- notes

--projection calculation
--[[
aspect ratio:
a = screen h / screen w
a = 1 since screen is square

theta t (fov angle?):
tan(t) = sin(t)/cos(t)
f = 1 / (tan( t / 2 ))

z position? (lambda l):
l = zfar / (zfar - znear)

px,py,pz = projected x,y,z

px = x * 1/(sin(t/2)/cos(t/2))
py = y * 1/(sin(t/2)/cos(t/2))
pz = z * l - l*znear
]]--
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
