pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- plane
camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=21
cam_h=-8

fov=0.11
zfar=500
znear=3
lam=(zfar/zfar-znear)

objs={}
enmy={}

ppx,ppy,ppz=0,-30,150
--yaw,pitch,roll
pp_ya,pp_pi,pp_ro=0.0,0,0
turnx=0
turny=0
pp_targ=nil
st_e=nil --screen target enemy
st_p=nil --screen target pos

function _init()
	printh("====== start ======")
	
	add(objs,obj(obj_base,0,0,0))
	add(objs,obj(obj_base,-30,0,0))
	add(objs,obj(obj_base,30,0,0))
	add(objs,obj(obj_base,0,0,-300))
	add(objs,obj(obj_base,300,0,0))
	add(objs,obj(obj_base,0,0,500))

	local e=obj(
		pp_base,
		0,-70,0,
		update_enemy)
	e.scrx=-1
	e.scry=-1
	add(objs,e)
	add(enmy,e)
end

function _draw()
	cls()
	
	local gh=64+pp_pi*512
	gh-=sin(pp_pi)*((500-camy)/500)*12
	gh=mid(0,gh,128)
	
	if camy<0 then
		sx,sy=proj(
			camx-30,
			camy-5,
			camz-100)
		circfill(
			sx,sy,
			7,9)
		rectfill(0,gh,127,gh+127,3)
	end

	t_sorted={}
	for o in all(objs)do
		if type(o.tris)=="string" then
			proj_sprite(o)
		else
			proj_obj(o)
		end
		//if o.draw then
		//	o.draw(o)
		//else
		//	draw_obj(o)
		//end
	end
	
	proj_obj({
		tris=pp_base,
		x=ppx,y=ppy,z=ppz,
		ya=pp_ya,pi=pp_pi,ro=pp_ro
	})
	
	
	for t in all(t_sorted)do
		if type(t[3])=="number" then
			draw_sprite(t)
		else
			draw_tri(t,t[2])
		end
		
	end
	
	//printh(turn)
	
	circ(
		64+turnx*1000,
		64+turny*1000,
		1,7)
	
	if st_p then
		rect(
			st_p[1]-2,st_p[2]-2,
			st_p[1]+2,st_p[2]+2,
			st_p[3]>10 and 8 or 2)
	end
	
	print("gun  750",94,80,7)
	print("mssl 080",94,86,7)
	
	

	pria(
		{flr(ppx),flr(ppy),flr(ppz)},
		0,0,7)
	pria({pp_ya,pp_pi,},0,6,7)

	
end

function _update()
	update_plane()
	update_cam()
	
	for o in all(objs)do
		if(o.update)o.update(o)
	end
end
-->8
-- pov

function proj_sprite(s)
	local px,py,dz=proj(
		s.x,s.y,s.z)
	sort_tri({3,{px,py}},5,dz)
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
				
			dz_max=max(dz_max,dz)			
			add(tt,{px,py})
		end
		
		sort_tri(tt,t[4],dz_max)
	end
	
	//px,py=proj(o.x,o.y,o.z)
	//pset(px,py,8)
end

function sort_tri(tt,col,dz)
	if dz>1 and dz<zfar then
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
		t[3][1],t[3][2],
		t[4][1],t[4][2],
		t[5][1],t[5][2],
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

function draw_sprite(s)
	local z=(zfar-s[1])/zfar
	--[[
	consider updating this to
	sspr
	]]--
	spr(s[3],s[4][1],s[4][2],z,z)
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

l_pi=0
function update_plane()
	if btn(⬆️) then
		pp_pi=max(pp_pi-0.01,-0.125)
	elseif btn(⬇️) then
		pp_pi=min(pp_pi+0.01,0.125)
	end
	
	if l_pi!=pp_pi then
		turny+=0.01*sin(l_pi-pp_pi)
	else
		if turny<0 then
			turny=min(turny+0.001,0)
		elseif turny>0 then
			turny=max(turny-0.001,0)
		end
	end
	l_pi=pp_pi
	--[[
	elseif pp_pi<0 then
		pp_pi=min(pp_pi+0.01,0)
	elseif pp_pi>0 then
		pp_pi=max(pp_pi-0.01,0)
	end
	]]--
	
	if btn(➡️) then
		turnx=max(turnx-0.001,-0.01)
		pp_ro=max(pp_ro-0.01,-0.125)
	elseif btn(⬅️) then
		turnx=min(turnx+0.001,0.01)
		pp_ro=min(pp_ro+0.01,0.125)
	else
		if turnx<0 then
			turnx=min(turnx+0.001,0)
		elseif turnx>0 then
			turnx=max(turnx-0.001,0)
		end
		
		if pp_ro<0 then
			pp_ro=min(pp_ro+0.01,0)
		elseif pp_ro>0 then
			pp_ro=max(pp_ro-0.01,0)
		end
	end
	
	pp_ya-=turnx
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
	
	-- check enemy on screen
	local f_targ=nil
	for e in all(enmy)do
		if e.scrx>-1 and e.scrx<128 and
					e.scry>-1 and e.scry<128 then
			f_targ=e
		end
	end
	
	if not f_targ then
		-- no targ, clear
		st_e=nil
		st_p=nil
	elseif st_e==nil then
		-- new targ, start tracking
		st_e=f_targ
		st_p={64,64,0}
	else
		-- same targ, update tracking
		local dfx=st_e.scrx-st_p[1]
		local dfy=st_e.scry-st_p[2]
		//loga({dfx,dfy})
		if abs(dfx)>3 or abs(dfy)>3 then
			st_p[1]+=sgn(dfx)
			st_p[2]+=sgn(dfy)
		end
		if abs(dfx)<5 or abs(dfy)<5 then
			st_p[3]+=1
		else
			st_p[3]=0
		end
	end
	
	
	if btnp(❎) then
		if st_e and st_p and 
					st_p[3]>10 then
			shoot_mssl(st_e)
		else
			shoot_mssl(nil)
		end
	end
end

function shoot_mssl(e)
	local mssl=obj(
		mssl_base,
		ppx,ppy+10,ppz,
		update_mssl)
	mssl.pi=pp_pi
	mssl.ya=pp_ya
	mssl.t=200
	mssl.targ=e
	printh("fire")
	add(objs,mssl)
end

function update_mssl(m)

	if m.targ then
		tya=(atan2(
			m.targ.x-m.x,
			-(m.targ.z-m.z)
		)+0.25)%1
				
		tpi=(atan2(
			m.targ.y-m.y,
			(m.targ.z-m.z)*cos(m.ya)+
			(m.targ.x-m.x)*sin(m.ya)
		)-0.25)%1
		
		loga({pp_pi,m.pi,tpi})
		
		m.ya=ang_lerp(m.ya,tya,0.1)
		m.pi=ang_lerp(m.pi,tpi,0.1)
	end
	
	dx,dy,dz=rot3d(
		0,0,2,
		m.pi,
		m.ya,
		0)
	
	m.x-=dx
	m.y-=dy
	m.z-=dz
		
	m.y=min(0,m.y)
	
	m.t-=1
	if m.t%2==0 then
		local smoke=obj("smoke",
			m.x,m.y,m.z,
			update_smoke)
		smoke.t=20
		add(objs,smoke)
	end
	if m.t==0 or m.y>=0 then
		del(objs,m)
	end
end
-->8
-- helpers

function obj(tris,x,y,z,up)
	local o={
		tris=tris,
		x=x,y=y,z=z,
		ya=0,pi=0,ro=0,
		update=up
	}
	//comb(o,ext)
	return o
end

--[[
function comb(a,b)
	for k,v in pairs(b)do
		a[k]=v
	end
end
]]--

function tan(a)
	return sin(a)/cos(a)
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function atan25(x,y)
	local a=atan2(x,y)
	if a>0.5 then
		return (a+0.25)%1
	else
		return (a-0.25)%1
	end
end

function ang_lerp(a1,a2,t)
	a1=a1%1
	a2=a2%1
	if abs(a1-a2)>0.5 then
		if a1>a2 then
			a2+=1
		else
			a1+=1
		end
	end
	return ((1-t)*a1+t*a2)%1
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
-- effects and ememies

function update_smoke(s)
	s.t-=1
	if s.t==0 or s.y>=0 then
		del(objs,s)
	end
end

function update_enemy(e)
	sx,sy=proj(e.x,e.y,e.z)
	e.scrx,e.scry=flr(sx),flr(sy)
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
		{3,-5,12},
		7
	},
	{
		{-3,0,0},
		{-3,0,10},
		{-3,-5,12},
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

mssl_base={
	{
		{0,0,-2},
		{-1,0,2},
		{1,0,2},
		7
	},
	{
		{0,0,-2},
		{0,-1,2},
		{0,1,2},
		13
	}
}
__gfx__
00000000333033303330300050505500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333030003000300050555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700303000300030300005005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000303033303330333055555050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000005055005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000005550505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000500505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003330303033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003000303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003330333030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
