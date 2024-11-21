pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- plane

--[[
notes:
ave fighter jet cruise spd:
 - 621 mph = 227 m/s
 - 30 fps: 227/30 = 7.5 m/frame
]]--

-- camera
camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=-50
cam_h=-8
cam_flip=0.5

-- pov
fov=0.11
fov_c=-2.778 // 1/tan(fov/2)
zfar=500
znear=10
lam=zfar/(zfar-znear)
//lam=zfar/zfar-znear

-- collections
objs={}
enmy={}
e_mssl={}

--player
secx,secz=0,0
ppx,ppy,ppz=0,-50,600
--yaw,pitch,roll
pp_ya,pp_pi,pp_ro=0,0,0
pp_hp=100
pp_spd=4
turnx=0
turny=0
wpn=0 --weapon index
dam_t=0

pp_targ=nil --target object
pp_t_idx=0 --targ finding inx
st_p={} --[[
									sp_p[1]=x
									st_p[2]=y
									st_p[3]=-1 no targ
																	0 targ tracked
																	1 targ locked
									]]--
									
--menus
menu_t=0
lvl_s_idx=0
lvl_s_tot=1
pln_s_idx=0
pln_s_tot=2

--constants
alert_m="destroyed"
alert_t=0
warn=false
uit=0

g_mode="title"
g_start_t=0
lvl_t=0
lvl_start_t=0
cur_lvl=1

function _init()
	printh("====== start ======")
	
	menuitem(1,"flip cam",
		function() 
			cam_flip=(cam_flip+0.5)%1
		end
	)
	
	pp_obj=obj(0,0,0,0,0,0,nil)
end

function _draw()
	cls()
	t_sorted={}
	
	if g_mode=="title" then
		draw_title()
	elseif g_mode=="lvl s" then
		draw_lvl_s()
	elseif g_mode=="plane s" then
		draw_plane_s()
	elseif g_mode=="game" then
		draw_game()
	end
end

function _update()
	uit=(uit+0.5)%4
	menu_t+=0.5
	
	if g_mode=="title" then
		update_title()
	elseif g_mode=="lvl s" then
		update_lvl_s()
	elseif g_mode=="plane s" then
		update_plane_s()
	elseif g_mode=="game" then
		update_game()
	end
end

function draw_title()
	print("press ❎ to start",0,0,7)
end

function update_title()
	if btnp(❎) then
		g_mode="lvl s"
		menu_t=0
	end
end

function draw_lvl_s()
	rectfill(0,0,127,127,1)
	print("mission select",1,1,12)
	
	rect(20,20,108,108,7)
	
	local lvl=lvls[cur_lvl]
	for e in all(lvl.enmy)do
		local mx=(e[1]/1000)*40+64
		local mz=(e[3]/1000)*40+64
		//pset(mx,mz,9)
		if e[4]=="sam" then
			//pset(mx,mz,15)
			spr(9,mx,mz)
		else
			line(mx+3,mz+4,mx+3,mz+9,6)
			spr(8,mx,mz)
		end
		
		//line
	end
	
	for i=0,3 do
		print(
			i<lvl_s_tot and "lvl 1" or "??????",
			i==lvl_s_idx and 8 or 5,
			i*6+16,
			i<lvl_s_tot and 12 or 5)
	end
end

function update_lvl_s()
	if btnp(❎) then
		g_mode="plane s"
		menu_t=0
	end
	if(btnp(⬆️))lvl_s_idx-=1
	if(btnp(⬇️))lvl_s_idx+=1
	lvl_s_idx=mid(
		0,
		lvl_s_idx,
		lvl_s_tot-1)
end

function draw_plane_s()
	print("plane slct",0,0,7)
	
	if menu_t>10 then
	proj_obj({
		tris=pp_tris,
		x=0,y=0,z=0,
		ya=pp_ya,pi=0,ro=0
	})
	draw_sorted()
	
	print("mig-29",5,20,7)
	
	print("speed",5,35,7)
	print("armor",5,41,7)
	print("missile",5,47,7)
	print("gun",5,53,7)
	end
	
	rect(1,13,
		50*min(menu_t/5,1),26,6)

	rect(1,28,50*min(menu_t/5,1),70,6)
		
	if menu_t>5 then
		sspr(0,8,32,4,3,15)
		sspr(0,12,32,4,3,30)
		for i=0,min(flr(menu_t)-5,5) do
			spr(
				i>pln_s_tot and 7 or
				i==pln_s_idx and 5 or 6,
				i*8+40,50)
		end
	end
end

function update_plane_s()
	camz=48
	camy=-21
	camx=0
	cam_ya=0.5
	cam_pi=-0.05
	pp_ya+=0.005
	
	if(btnp(⬅️))pln_s_idx-=1
	if(btnp(➡️))pln_s_idx+=1
	pln_s_idx=mid(
		0,
		pln_s_idx,
		pln_s_tot-1)
	
	if btnp(❎) then
		init_lvl()
	end
end

function draw_game()
	//printh("ug draw =====")
	//printh(" ")
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
		//fillp(▤)
		//rectfill(0,gh,127,gh+4,3)
		//fillp()
		rectfill(0,gh,127,gh+127,3)
	end
		
	for o in all(objs)do
		if type(o.tris)=="function" then
			proj_sprite(o)
		else
			proj_obj(o)
		end
	end
	
	proj_obj({
		tris=pp_tris,
		x=ppx,y=ppy,z=ppz,
		ya=pp_ya,pi=pp_pi,ro=pp_ro
	})

	local povx=round(secx-1*sin(pp_ya))
	local povz=round(secz-1*cos(pp_ya))	
	for i=povx-1,povx+1 do
	for j=povz-1,povz+1 do
		srand((i<<8)+j)
		for k=0,10 do
			proj_sprite({
				tris=draw_grnd,
				x=i*100+rand(-100,100),
				y=0,
				z=j*100+rand(-100,100),
				ya=0,pi=0,ro=0
			})
		end
	end end
	srand(time())

	draw_sorted()
	draw_map()
	draw_hud()
	
	print(secx,110,40,7)
	print(secz,110,46,7)
	//printh(" ")
end

function update_game()
	warn=false
	update_player()
	
	pp_obj.x=ppx
	pp_obj.y=ppy
	pp_obj.z=ppz
	pp_obj.ya=pp_ya
	pp_obj.pi=pp_pi
	pp_obj.ro=pp_ro
	
	secx=flr(ppx/100)
	secz=flr(ppz/100)
	
	update_cam()
	
	for o in all(objs)do
		if(o.update)o.update(o)
	end
	
	alert_t=max(alert_t-1,0)
	
	g_start_t-=1
	if g_start_t==0 then
		alert("mission start")
		lvl_start_t=time()
	elseif g_start_t<0 then
		lvl_t=300-(time()-lvl_start_t)
	end
end

function init_lvl()
	g_mode="game"
	pp_ya,pp_pi,pp_ro=0,0,0
	g_start_t=60 --test, set back to 60
	
	local lvl=lvls[cur_lvl]
	for e in all(lvl.enmy)do
		add_enemy(e[1],e[2],e[3],e[4])
	end
	
	for o in all(lvl.objs)do
		add(objs,
			obj(o[4],o[1],o[2],o[3])
		)
	end
end

function draw_hud()
	-- boxes around enemies
	for e in all(enmy)do
		if onscr(e) then
			if e!=pp_targ or 
						st_p[3]==1 or
						uitf() then
				rect(
					e.scrx-2,e.scry-2,
					e.scrx+2,e.scry+2,
					e==pp_targ and 11 or 5)
				print(
					e.typ,
					e.scrx+3,
					e.scry-7)
				print( --debug
				e.mode,
					e.scrx+3,
					e.scry-1)
			end
		elseif e==pp_targ then
			local a=atan2(
				64-e.scrx,
				64-e.scry
			)
			a=(a+0.5)%1
			
			pelogen_tri(
				64+cos(a)*62,
				64+sin(a)*62,
				64+cos(a-0.01)*46,
				64+sin(a-0.01)*46,
				64+cos(a+0.01)*46,
				64+sin(a+0.01)*46,
				11)
		end
	end
	
	--screen target box
	if (st_p[3]==0 and uitf()) or
				st_p[3]==1 then
		rect(
			st_p[1]-2,st_p[2]-2,
			st_p[1]+2,st_p[2]+2,
			11)
	end
	
	local c=11
	if dam_t>0 then
		c=uitf() and 9 or 8
	end
	
	--crosshairs
	circ(
		64+turnx*1000,
		64+turny*1000,
		1,7)
	
	--weapons
	print("targ",96,74,wpn==0 and c or 1)
	print("mssl 750",96,80,wpn==1 and c or 1)
	print("gun  080",96,86,wpn==2 and c or 1)
	//rect(94,72+wpn*7,127,80+wpn*7,11)
	print("hp "..pp_hp,96,98,c)
	
	--spd/alt
	print(flr(pp_spd*30),20,60,c)
	print(flr(ppy*-1),100,60,c)
	
	--time/score
	print(ftime(lvl_t),100,1,7)
	print("scr:000",100,7,7)
	
	--alert
	if alert_t>0 then
		rectfill(
			49,49,
			49+#alert_m*4,55,
			10)
		print(alert_m,50,50,0)
	end
	
	--warning
	if #e_mssl>0 or 
				(warn and uits()) then
		print("warning",50,42,8)
	end
	
	--altitude
	if ppy>-100 and uits() then
		print("to low",50,62,8)
	end
end

function draw_map()
	//fillp(░)
	//rectfill(1,1,32,32,1)
	//fillp()
	
	for e in all(enmy)do
		local mx,mz=rot2d(
			e.x-ppx,
			e.z-ppz,
			(pp_ya+0.5))
		mx=mid(-16,mx/64,16)
		mz=mid(-16,mz/64,16)
		
		pset(
			16+mx,16-mz,
			pp_targ==e and 9 or 13)
	end
	
	pset(16,16,3)
	pset(16,15,11)
	
	rect(1,1,32,32,1)
end

function alert(s)
	alert_m=s
	alert_t=60
end
-->8
-- pov

--[[
	obj layout:
	{
		tris=table of triangles
		.. other data
	}
	
	sprite layout:
	{
		tris=some render function
		..other data
	}
]]--

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
						
	local dz=max(1,z*lam-lam*znear)	
	//local px=x*fov_c
	//local py=y*fov_c
	
	local px=mid(
		-500,
		(x*fov_c)/dz,
		500
	)
	local py=mid(
		-500,
		(y*fov_c)/dz,
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

--[[
function draw_sprite(s)
	local z=(zfar-s[1])/zfar
	
	//consider updating this to
	//sspr
	spr(s[3],s[4][1],s[4][2],z,z)
end
]]--
-->8
-- player 

function update_cam()	
	cam_ya=-pp_ya+cam_flip --debug for rear view
	cam_pi=pp_pi+sin(pp_pi)*0.05

	dcy,dcz=rot2d(
		cam_h,cam_d,-cam_pi)
	dcz,dcx=rot2d(
		dcz,0,-cam_ya)
	
	camz=ppz+dcz
	camx=ppx+dcx
	camy=ppy+dcy
end

l_pi=0
function update_player()
	if g_start_t>0 then
		goto pp_move
	end
	
	if(btnp(🅾️))wpn=(wpn+1)%3
	
	if btn(⬆️) then
		pp_pi=max(pp_pi-0.01,-0.24)
	elseif btn(⬇️) then
		pp_pi=min(pp_pi+0.01,0.24)
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
	
	if btn(➡️) then
		turnx=min(turnx+0.001,0.005)
		pp_ro=min(pp_ro+0.01,0.125)
	elseif btn(⬅️) then
		turnx=max(turnx-0.001,-0.005)
		pp_ro=max(pp_ro-0.01,-0.125)
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
	
	if btnp(❎) then
		if(wpn==0)find_targ()
		if wpn==1 then
			local targ=nil
			if pp_targ and st_p[3]==1 then
				targ=pp_targ
			end
			shoot_mssl(
				ppx,ppy+2,ppz,
				pp_ya,pp_pi,
				6,0.1,
				targ)
		end
	end
	
	::pp_move::
	dam_t-=1
	
	pp_ya-=turnx
	pp_ya=pp_ya%1
	
	dx,dy,dz=rot3d(
		0,0,pp_spd,
		pp_pi,
		pp_ya,
		0)
		
	ppx-=dx
	ppy-=dy
	ppz-=dz
	
	ppy=min(0,ppy)
	
	if wpn!=1 or 
				pp_targ==nil or 
				not onscr(pp_targ) then
		st_p={64,64,-1}
	else
		--update tracking
		local dfx=pp_targ.scrx-st_p[1]
		local dfy=pp_targ.scry-st_p[2]
		if abs(dfx)>3 or abs(dfy)>3 then
			st_p[1]+=sgn(dfx)
			st_p[2]+=sgn(dfy)
			st_p[3]=0
		else
			st_p[1]=pp_targ.scrx
			st_p[2]=pp_targ.scry
			st_p[3]=1
		end
	end
end

function find_targ()
	printh("finding targs")
	local f_targs={}
	for e in all(enmy)do
		if onscr(e) then	
			add(f_targs,e)
		end
	end
	printh(#f_targs)
	st_p={64,64,-1}
	pp_targ=nil
	if #f_targs==0 then
		pp_t_idx=0
		//pp_targ=nil
		return
	else
		pp_t_idx+=1
		if pp_t_idx>#f_targs then
			pp_t_idx=1
		end
		pp_targ=f_targs[pp_t_idx]
	end
end
-->8
-- ememies

function add_enemy(x,y,z,typ)
	local base=enmy_p_base[typ]
	local tris=base.tris
	local up=update_e_plane
	if typ=="sam" then
		tris=sam_tris
		up=update_e_sam
	end
	
	local e=obj(
		tris,
		x,y,z,0,0,0,
		up)
	e.typ=typ
	e.hp=100
	e.mode="evade"
	e.t=1 --mode timer
	e.lt=base.lt_max --lock timer
	e.lt_max=base.lt_max
	e.spd=5
	e.tx=0 --target x
	e.ty=0 --target y
	e.tz=0 --target z
	e.sx=x --start x
	e.sz=z --start z
	e.la=0.05 --turn lerp amt
	e.f_ch=base.f_ch --follow chance
	add(objs,e)
	add(enmy,e)
end

function update_e_plane(e)
	get_onscr(e)
			
	local pd=dist(
		e.x,e.y,e.z,ppx,ppy,ppz)
	
	-- run mode
	if e.mode=="follow" then
		update_e_follow(e,pd)
	elseif e.mode=="evade" then
		update_e_evade(e,pd)
	elseif e.mode=="dead" then
		e.la=0.02
		e.t-=1
		if e.t%2==0 then
			add_smoke(e.x,e.y,e.z)
		end
	end
		
	--move to target
	local aya,api=atan3d(
		e.x,e.y,e.z,
		e.tx,e.ty,e.tz,
		e.ya)
	
	e.ya=ang_lerp(e.ya,aya,e.la)
	e.pi=ang_lerp(e.pi,api,e.la)
	
	dx,dy,dz=rot3d(
		0,0,e.spd,
		e.pi,
		e.ya,
		0)
	
	e.x-=dx
	e.y-=dy
	e.z-=dz
	
	if e.mode!="dead" then
		//hack, whatever
		e.y=min(e.y,-40) 
	end
	
	check_e_dead(e)
end

function update_e_follow(e,pd)
	if pd>1000 then
		printh("s mode:follow -> evade (out of range)")
		e.mode="evade"
		e.t=120
		return
	end
	
	e.tx=ppx
	e.tz=ppz
	e.ty=ppy
	
	if pd>200 then
		e.spd=pp_spd+2
		e.la=0.05
	else
		e.spd=pp_spd
		e.la=0.05
	end
	
	local dff=abs(
		cos(e.ya)-cos(pp_ya)
	)%1
		
	if dff<0.20 and e.scrdz<2 then
		warn=true
		e.lt-=1
		if e.lt==0 then
			printh("enemy fire")
			e.lt=e.lt_max
			shoot_mssl(
				e.x,e.y+2,e.z,
				e.ya,e.pi,
				6,0.08,
				pp_obj)
		end
	else
		e.lt=e.lt_max
		e.t-=1
	end
		
	if e.t==0 then
		if rnd()<e.f_ch then
			printh("s mode:follow -> follow")
			e.mode="follow"
			e.t=30*5
			e.lt=30
		else
			printh("s mode:follow -> evade")
			e.mode="evade"
			e.t=30*15
			e.tx=rand(-500,500)+e.sx
			e.tz=rand(-500,500)+e.sz
			e.ty=rand(150,10000)*-1
			loga({"set",e.tx,e.ty,e.tz})
		end
	end
end

function update_e_evade(e,pd)
	e.la=0.02
	e.t-=1
		
	if pd<100 then
		e.spd=pp_spd
	else
		e.spd=pp_spd-1
	end
			
	if e.t==0 then
		printh("s mode:evade -> follow")
		e.mode="follow"
		e.t=200
	end
end

function update_e_sam(e)
	get_onscr(e)
	
	local pd=dist(
		e.x,e.y,e.z,ppx,ppy,ppz)
	if pd>400 then
		e.lt=90
	else
		warn=true
		e.lt-=1
		if e.lt==0 then
			printh("enemy fire")
			local aya,api=atan3d(
				e.x,e.y,e.z,
				ppx,ppy,ppz,
				0)
			e.lt=90
			shoot_mssl(
				e.x,e.y-5,e.z,
				aya,api,
				5,0.1,
				pp_obj)
		end
	end
	
	check_e_dead(e)
end

function check_e_dead(e)
	if e.hp<=0 and e.mode!="dead" then
		alert("destroyed")
		e.mode="dead"
		e.t=30000
		e.tx=e.x
		e.tz=e.z
		e.ty=0
		del(enmy,e)
		find_targ()
	elseif e.y>=0 and e.mode=="dead" then
		del(objs,e)
	end
end
-->8
-- effects

function shoot_mssl(
	x,y,z,ya,pi,spd,trn,targ)
	local mssl=obj(
		mssl_tris,
		x,y,z,
		ya,pi,0,
		update_mssl)
	mssl.t=200
	mssl.d=30000
	mssl.targ=targ
	mssl.trn=trn
	mssl.spd=spd
	mssl.p=targ!=pp_obj

	printh("fire")
	add(objs,mssl)
	if targ==pp_obj then
		add(e_mssl,mssl)
	end
end

function update_mssl(m)
	if m.targ then		
		local tya,tpi=atan3d(
			m.x,m.y,m.z,
			m.targ.x,m.targ.y,m.targ.z,
			m.ya)
		
		m.ya=ang_lerp(m.ya,tya,m.trn)
		m.pi=ang_lerp(m.pi,tpi,m.trn)
	
		local d=dist(
			m.x,m.y,m.z,
			m.targ.x,m.targ.y,m.targ.z)
		if d>m.d then
			printh("lost tracking")
			m.targ=nil
			del(e_mssl,m)
		end
		m.d=d
	end
	
	dx,dy,dz=rot3d(
		0,0,m.spd,
		m.pi,
		m.ya,
		0)
	
	m.x-=dx
	m.y-=dy
	m.z-=dz
	m.y=min(0,m.y)
	
	m.t-=1
	if m.t%2==0 then
		// consider only showing
		// smoke if close to player
		add_smoke(m.x,m.y,m.z)
	end
	
	if m.targ==pp_obj then
		local d=dist(
			m.x,m.y,m.z,
			ppx,ppy,ppz)
		if d<4 then
			m.t=0
			pp_hp-=50
			del(objs,m)
			del(e_mssl,m)
			//alert("ouch")
			add_expl(m.x,m.y,m.z)
			dam_t=30
			return
		end
	else
		for e in all(enmy)do		
			local d=dist(
				m.x,m.y,m.z,
				e.x,e.y,e.z)

			if d<4 then
				m.t=0
				e.hp-=50
				del(objs,m)
				alert("hit")
				add_expl(m.x,m.y,m.z)
				return
			end
		end
	end
	
	if m.t==0 or m.y>=0 then
		del(objs,m)
		del(e_mssl,m)
		if m.p then
			alert("miss")
		end
	end
end

function add_smoke(x,y,z)
	local smoke=obj(draw_smoke,
		x,y,z,
		0,0,0,
		update_smoke)
	smoke.t=20
	add(objs,smoke)
end

function update_smoke(s)
	s.t-=1
	if s.t==0 or s.y>=0 then
		del(objs,s)
	end
end

function draw_smoke(s)
	local z=(zfar-s[1])/zfar
	spr(3,s[4][1],s[4][2],z,z)
end

function add_expl(x,y,z)
	for i=0,5 do 
		local expl=obj(draw_expl,
			x+rand(-5,5),
			y+rand(-5,5),
			z+rand(-5,5),
			0,0,0,
			update_expl)
		expl.t=20+rand(0,5)
		expl.c=rnd({5,5,6,6,9})
		add(objs,expl)
	end
end

function update_expl(e)
	e.t-=1
	if e.t==0 then
		del(objs,e)
	end
end

function draw_expl(e)
	if(e[2].t>20)return
	local z=(zfar-e[1])/zfar
	//spr(3,s[4][1],s[4][2],z,z)
	circfill(
		e[4][1],e[4][2],
		(20-abs(e[2].t-15))*z,e[2].c)
end

function add_grnd(x,z)
	local g=obj(draw_grnd,
			x,
			0,
			z,
			0,0,0,
			nil)
		//expl.t=20+rand(0,5)
		//expl.c=rnd({5,5,6,6,9})
		add(objs,g)
end

function draw_grnd(g)
	local z=(zfar-g[1])/zfar
	spr(11,g[4][1],g[4][2],z,z)
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

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end


function tan(a)
	return sin(a)/cos(a)
end

function lerp(a,b,t)
	return a+(b-a)*t
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

function atan3d(x1,y1,z1,x2,y2,z2,ya)	
	local nya=(atan2(
		x2-x1,
		-(z2-z1)
	)+0.25)%1
				
	local npi=(atan2(
		y2-y1,
		(z2-z1)*cos(ya)+
		(x2-x1)*sin(ya)
	)-0.25)%1
	
	return nya,npi
end

function dist(x1,y1,z1,x2,y2,z2)
	local x=abs(x1-x2)
	local y=abs(y1-y2)
	local z=abs(z1-z2)
	local ax=atan2(x,y)
	local d2=x*cos(ax)+y*sin(ax)
	local az=atan2(d2,z)
	return d2*cos(az)+z*sin(az)
end

function uits()
	return flr(uit)>1
end

function uitf()
	return flr(uit)%2==1
end

function ftime(t)
	if type(t)!="number" then
		return t
	end
	local mins=flr(t/60)
	local s=""
	if mins>0 then
		s=s..mins..":"
	end
	s=s..t%60
	return sub(s,1,7)
end

function round(n)
	if n-flr(n)>=0.5 then
		return flr(n)+1
	end
	return flr(n)
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

pp_tris={
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

sam_tris={
	{
		{-10,0,10},
		{0,-10,0},
		{10,0,10},
		8
	},
	{
		{-10,0,-10},
		{0,-10,0},
		{10,0,-10},
		8
	}
}

obj_tris={
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

mssl_tris={
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

lvls={
 { -- level 1
 	enmy={
 		{-1000,-400,0,"mig"},
 		{0,-400,0,"mig"},
 		{500,-400,0,"mig"},
 		//{0,0,100,"sam"},
 	},
 	objs={
 		{0,0,0,obj_tris},
 		{-30,0,0,obj_tris},
 		{30,0,0,obj_tris},
 		{0,0,-300,obj_tris},
 		{100,0,-500,obj_tris},
 		{-100,0,-1000,obj_tris},
 		
 		//{300,0,0,obj_base},
 		//{0,0,500,obj_base},
 	}
 }
}

enmy_p_base={
	sam={
		tris=sam_tris,
		lt_max=90,
		f_ch=nil
	},
	mig={
		tris=pp_tris,
		lt_max=90, --lock time max
		f_ch=0.5, --follow chance
	},
}
__gfx__
00000000000000000000000050505500bb000000666666606666666066666660000000000000000000000000b0b0b00b00000000000000000000000000000000
000000000000000000000000505555500bbb00006700076061000160600000600090000000000000000000000b000b0000000000000000000000000000000000
0070070000000000000000000500505000bbbb0060707060601010606000006000090000000fff0000000000b00b0bbb00000000000000000000000000000000
00077000000000000000000055555050000bbbbb60070060600100606000006000009000000f0f00000000000bb0b0bb00000000000000000000000000000000
00077000000000000000000005055005000bbbbb60707060601010606000006000090000000fff000000000000b0bb0b00000000000000000000000000000000
0070070000000000000000000555050500bbbb00670007606100016060000060009000000000000000000000b00bb0b000000000000000000000000000000000
000000000000000000000000505050500bbb00006666666066666660666666600000000000000000000000000b000b0000000000000000000000000000000000
00000000000000000000000000500505bb000000000000000000000000000000000000000000000000000000b00b0b0b00000000000000000000000000000000
66606066606660666066606660666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606060606000606060606000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606066006000660066606600060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606060606660606060606000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606660666066606660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000600606006006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600600666006000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600600606006006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
