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

--[[
idea
add col_box(x1,x1,y1,y1,z1,12)

use this to collide with
objects

also, consider adding a landing
strip. if the player flies
through it, they refill their
ammo
]]--

ver="0.0.1"

--constants
secs=300 --sec size
sech=150 --sec size half
spd_min=2
spd_mid=4
spd_max=7

-- camera
camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
//cam_d_s=-50 --cam dist start
//cam_h=-8
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
pp_spd=spd_mid
spd_m=0 --speed mode
turnx=0
turny=0
wpn=0 --weapon index
dam_t=0
trg_t=0

pp_targ=nil --target object
pp_t_idx=0 --targ finding inx
st_p={} --[[
									sp_p[1]=x
									st_p[2]=y
									st_p[3]=-1 no targ
																	0 targ tracked
																	1 targ locked
									]]--
										
menu_t,menu_t2=0,0
tit_idx=1
lvl_s_idx=1
lvl_s_tot=3
pln_s_idx=1
pln_s_tot=5

-- other globals
alert_m="destroyed"
alert_t=0
warn=false
uit=0
g_mode="title"
g_start_t=0
lvl_t=300
lvl_start_t=0
cur_lvl=nil
sunx,suny,sunz=0,0,0


function _init()
	printh("====== start ======")
	
	menuitem(1,"flip cam",
		function() 
			cam_flip=(cam_flip+0.5)%1
		end
	)
	
	pp_obj=obj(0,0,0,0,0,0,nil)
	cur_lvl=lvls[1]
end

function _draw()
	//cls()
	t_sorted_ll=nil
	n_t_sorted=0
	n_o_proj=0
	
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
	menu_t2+=0.5
	
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
	cls()
	local prog=0 //track progress
	print(
		"start ("..prog.."%)",
		45,92,7)
	print(
		"config",
		53,100,7)
	print(
		"clear save",
		45,108,7)
	
	//if uits() then
		rect(
			34,82+tit_idx*8,
			94,90+tit_idx*8,
			3)
	//end
	//line(64,0,64,128,1)
	//line(44,0,44,128,1)
	//line(84,0,84,128,1)
	print(ver,100,120,1)
end

function update_title()
	if btnp(❎) then
		if tit_idx==1 then
			g_mode="lvl s"
		elseif tit_idx==2 then
		elseif tit_idx==3 then
		end
		menu_t,menu_t2=0,0
	end
	
	if(btnp(⬆️))tit_idx-=1
	if(btnp(⬇️))tit_idx+=1
	tit_idx=mid(1,tit_idx,3)
end

function draw_lvl_s()
	//rectfill(0,0,127,127,1)
	cls()
	print("mission select",1,1,12)
	
	rect(20,20,108,108,7)
	
	//local lvl=lvls[cur_lvl]
	for e in all(cur_lvl.enmy)do
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
	
	for i=1,#lvls do
		print(
			i<=lvl_s_tot and lvls[i].title or "??????",
			i==lvl_s_idx and 8 or 5,
			i*6+16,
			i==lvl_s_idx and 12 or 5)
	end
end

function update_lvl_s()
	if btnp(❎) then
		g_mode="plane s"
		menu_t,menu_t2=0,0
		cur_lvl=lvls[lvl_s_idx]
	elseif btnp(🅾️) then
		g_mode="title"
		menu_t,menu_t2=0,0
	end
	if(btnp(⬆️))lvl_s_idx-=1
	if(btnp(⬇️))lvl_s_idx+=1
	lvl_s_idx=mid(
		1,
		lvl_s_idx,
		lvl_s_tot)
end

function draw_plane_s()
	cls()
	print("plane slct",0,0,7)
	
	local p=planes[pln_s_idx]
	
	if menu_t>10 then
		proj_obj({
			tris=plane_tris(p.tris),
			x=0,y=0,z=0,
			ya=pp_ya,pi=0,ro=0
		})
		draw_sorted()
	
		print(p.data.name,5,20,7)
	
		print("speed",5,35,7)
		print("armor",5,45,7)
		print("turn",5,55,7)
		print("missile",5,70,7)
		print("gun",5,77,7)
		
		if menu_t2>10 then
			print(p.data.ammo1,40,70,7)
			print(p.data.ammo2,40,77,7)
		end
		
		local ds={
			{p.data.spd_max,8},
			{p.data.hp_max,200},
			{p.data.turn,0.005}
		}
		
		for i=1,#ds do
			local d=ds[i]
			local o=i*10
			line(
				6,32+o,
				max(
					6,
					49*(d[1]/d[2])*min(1,menu_t2/10)),
				32+o,8)
			rect(5,31+o,50,33+o,7)
		end
	end
	
	rect(1,13,
		52*min(menu_t/5,1),26,6)

	rect(1,28,52*min(menu_t/5,1),85,6)
		
	if menu_t>5 then
		sspr(0,8,32,4,3,15)
		sspr(0,12,32,4,3,30)
		for i=1,min(flr(menu_t)-5,5) do
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
	
	if btnp(⬅️) then
		pln_s_idx-=1
		menu_t2=0
	elseif btnp(➡️) then
		pln_s_idx+=1
		menu_t2=0
	end
	pln_s_idx=mid(
		1,
		pln_s_idx,
		pln_s_tot)
	
	if btnp(❎) then
		//pp_plane=planes[pln_s_idx]
		local pl=planes[pln_s_idx]
		pp_plane=plane_tris(pl.tris)
		pp_plane_d=pl.data
		init_lvl()
	elseif btnp(🅾️) then
		g_mode="lvl s"
		menu_t,menu_t2=0,0
	end
end

function draw_game()
	//printh("ug draw =====")
	//printh(" ")
	cls(cur_lvl.ter[1])
	
	if pp_int_d>=0 then
		cls(0)
		draw_hud()
		
		if uits() then
		rectfill(
			53,78+pp_int_d*8,
			75,86+pp_int_d*8,3)
		end
		print("retry",55,80,11)
		print("exit",55,88,11) 
		
		return
	elseif win_t>0 then
		cls(0)
		draw_hud()
		return
	end
	
	local gh=64+pp_pi*512
	gh-=sin(pp_pi)*((500-camy)/500)*12
	gh=mid(0,gh,128)
	
	
	if camy<0 then
		//sx,sy=proj(
		//	camx-30,
		//	camy-5,
		//	camz-100)
		//circfill(
		//	sx,sy,
		//	7,9)
		//fillp(▤)
		//rectfill(0,gh,127,gh+4,3)
		//fillp()
		rectfill(
			0,gh,
			127,gh+127,
			cur_lvl.ter[2])
	end
	
	proj_sprite(
		obj(
			draw_sun,
			sunx,suny,sunz,
			0,0,0,0,0,
			nil
		)
	)
	
	for o in all(objs)do
		if type(o.tris)=="function" then
			proj_sprite(o)
		elseif onscr(o) then
			proj_obj(o)
		end
	end
	
	for b in all(cur_lvl.blds)do
		pbx,pby=proj(b[1],-100,b[2])
		if pbx<-1 or pbx>128 or
					pby<-1 or pby>128 then
			goto bd_cnt
		end
		
		local drs={
			{0,-1},
			{1,	0},
			{0,	1},
			{-1,0}
		}
		
		local mdz=30000
		local dmin=nil
		for d in all(drs)do
			px,py,dz=proj(
					b[1]+d[1]*22,
					-100,
					b[2]+d[2]*22
				)
			if dz<mdz then
				mdz=dz
				dmin=d
			end
		end
		
		for d in all({dmin})do
			
			x,z=d[1],d[2]
			local x1=(x-abs(z))*15+b[1]
			local x2=(x+abs(z))*15+b[1]
			local z1=(z-abs(x))*15+b[2]
			local z2=(z+abs(x))*15+b[2]
			
			local lines={}
			for i=0,9 do
				px1,py1=proj(x1,i*-10,z1)
				px2,py2=proj(x2,i*-10,z2)
				add(lines,{px1,py1,px2,py2})
			end
			
				proj_sprite({
					tris=draw_bld_line,
					x=b[1]+d[1]*22,
					y=-100,
					z=b[2]+d[2]*22,
					ya=0,pi=0,ro=0,
					lines=lines
				})
		end
		::bd_cnt::
	end
	
	draw_pp_plane()
	draw_spr_layer(0,200,draw_grnd)
	draw_spr_layer(-500,500,draw_cld)
	draw_sorted()
	draw_map()
	draw_hud()
	
	//print(secx,110,40,7)
	//print(secz,110,46,7)
	//printh(" ")
	//print(pp_pi,110,40,7)
end

function update_game()
	if alert_t>0 then
		alert_t-=1
	else
		alert_m=""
	end
	
	sunx=ppx-1000
	sunz=ppz
	suny=ppy-100
	
	if pp_hp==0 or 
				lvl_t<=0 and 
				pp_scr<cur_lvl.rs[4] then
		alert("mission failed")
		if pp_int_d==-1 and 
					btnp(❎) then
			pp_int_d=0
			return
		end
		if pp_int_d>=0 then
			if(btnp(⬆️))pp_int_d=0
			if(btnp(⬇️))pp_int_d=1
			
			if btnp(❎) then
				if pp_int_d==0 then
					init_lvl()
				elseif pp_int_d==1 then
					g_mode="lvl s"
					menu_t=0
				end
			end
			return
		end
	elseif #enmy==0 or lvl_t<=0 then
		//alert("mission complete")
		if alert_t==0 then
			//g_mode="lvl s"
			//menu_t=0
			win_t+=1
		end
		if win_t>40 and btnp(❎) then
			g_mode="lvl s"
			menu_t=0
		end
		return
	end
	
	warn=false
	update_player()
	
	pp_obj.x=ppx
	pp_obj.y=ppy
	pp_obj.z=ppz
	pp_obj.ya=pp_ya
	pp_obj.pi=pp_pi
	pp_obj.ro=pp_ro
	
	//secx=flr(ppx/secs)
	//secz=flr(ppz/secs)
	
	update_cam()
	
	if pp_s_wpn>10 then
		return
	end
	
	
	for o in all(objs)do
		if(o.update)o.update(o)
	end
		
	g_start_t-=1
	if g_start_t==0 then
		alert("mission start")
		lvl_start_t=time()
	elseif g_start_t<0 then
		lvl_t=300-(time()-lvl_start_t)
	end
	
	-- this is a hack, but w/e
	if #enmy==0 or 
				lvl_t<=0 and 
				pp_scr>=cur_lvl.rs[4] then
		alert_m="mission complete"
		alert_t=120
	end
end

function init_lvl()
	reset_objs()
	//local lvl=lvls[cur_lvl]
	g_mode="game"
	cam_d=-50
	cam_h=-8
	pp_ya,pp_pi,pp_ro=0,0,0
	turny,turnx=0,0
	sh_delay=0
	ppx=cur_lvl.ppx
	ppy=cur_lvl.ppy
	ppz=cur_lvl.ppz
	pp_hp=100
	pp_bay=0
	pp_bays={0,0}
	pp_ammo1=pp_plane_d.ammo1
	pp_ammo2=pp_plane_d.ammo2
	pp_scr=0
	g_start_t=60
	pp_int_d=-1 --interact after death
	win_t=0
	
	for e in all(cur_lvl.enmy)do
		add_enemy(e[1],e[2],e[3],e[4])
	end
	
	for o in all(cur_lvl.objs)do
		add(objs,
			obj(o[4],o[1],o[2],o[3])
		)
	end
	
	for b in all(cur_lvl.blds)do
		add(objs,
			obj(
				bld_tris,
				b[1],0,b[2],
				0,0,0,
				function(o)
					o.y-=100
					get_onscr(o)
					o.y=0
				end
			)
		)
	end
	
	rf_o=obj(
		draw_rf,
		cur_lvl.rf[1],
		-40,
		cur_lvl.rf[2],
		0,0,0,
		get_onscr
	)
	add(objs,rf_o)
end

function reset_objs()
	for a in all(
		{enmy,objs,e_mssl}
	)do
		for o in all(a)do	
			del(a,o)
		end 
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
				--[[
				print(
					e.typ,
					e.scrx+3,
					e.scry-7)
				]]--
				print2(
					e.typ,
					e.scrx+3,
					e.scry-7,
					e==pp_targ and 11 or 5)
				//print( --debug
				//	e.mode,
				//	e.scrx+3,
				//	e.scry-1)
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
	
	if onscr(rf_o) then
		print2(
			"refuel",
			rf_o.scrx,
			rf_o.scry,
			12)
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
	elseif #e_mssl>0 then
		c=8
	end
	
	--crosshairs
	circ(
		64-turnx*1000,
		64+turny*1000,
		1,7)
	
	--weapons
	if pp_s_wpn>10 then
		pal(6,c)
		spr(20,3,74)
		spr(20,24,74,1,1,true)
		spr(21,87,82)
		spr(21,87,87,1,1,false,true)
		pal()
	end
	
	print(
		"mssl "..pp_ammo1,95,82,
		(wpn==0 or c!=11) and c or 5)
	print(
		"gun "..pp_ammo2,95,90,
		(wpn==1 or c!=11) and c or 5)
	//rect(94,72+wpn*7,127,80+wpn*7,11)
	//print("hp "..pp_hp,96,98,c)
	rect(93,80+8*wpn,127,88+8*wpn,c)

	--speed mode
	print("mode",10,74,pp_s_wpn and c or 1)
	print(
		"hold",10,82,
		(spd_m==0 or c!=11) and c or 5)
	print(
		"burn",10,90,
		(spd_m==1 or c!=11) and c or 5)
	rect(8,80+8*spd_m,30,88+8*spd_m,c)
	
	--spd/alt/hp
	//print(flr(pp_spd*30),20,60,c)
	pal(6,c)
	sspr(0,16,12,4,95,70,12,4)
	sspr(0,24,12,4,16,53,12,4)
	sspr(0,20,12,4,100,53,12,4)
	pal()
	
	rect(93,68,107,75,c)
	rect(14,51,28,58,c)
	rect(98,51,112,58,c)
	print(flr(100-pp_hp),111,70,c)
	print(flr(pp_spd*30),20,60,c)
	print(flr(ppy*-1),100,60,c)
	
	--targ
	if trg_t>0 and not uits() then
		print("targ",60,74,c)
	end
	
	--alert
	if alert_t>0 then
		rectfill(
			39,49,
			39+#alert_m*4,55,
			10)
		print(alert_m,40,50,0)
	end
	
	--warning
	if #e_mssl>0 or 
				(warn and uits()) then
		print("warning",50,42,8)
	end
	
	--altitude
	if ppy>-100 and uits() then
		print("pull up",50,62,8)
	end
	
	--time/score
	if win_t==0 then
		print(ftime(lvl_t),100,1,7)
		print("scr:"..pp_scr,100,7,7)
	end
	--win
	//line(64,0,64,128,1)
	//line(24,0,24,128,1)
	//line(104,0,104,128,1)
	if win_t>0 then
		print("score",55,10,7)
	end
	if win_t>10 then
		print("score",55,10,7)
		print(
			pp_scr.."("..rank()..")",
			59,18,7)
	end
	if win_t>20 then
		print(
			"time remaining",
			37,30,7)
	end
	if win_t>30 then
		print(ftime(lvl_t),40,38,7)
	end
	if win_t>40 then
		print(
			"press ❎ to continue ",
			25,110,7)
	end
end

function draw_map()
	//fillp(░)
	//rectfill(1,1,32,32,1)
	//fillp()
	rectfill(1,1,32,32,0)
	rect(1,1,32,32,1)
	
	for e in all(enmy)do
		local mx,mz=get_map_xz(e)
		
		pset(
			16+mx,16-mz,
			pp_targ==e and 9 or 13)
	end
	
	for e in all(e_mssl)do
		local mx,mz=get_map_xz(e)
		
		pset(
			16+mx,16-mz,
			uits() and 7 or 5)
	end
	
	pset(16,16,11)
	pset(15,17,3)
	pset(17,17,3)
end

function get_map_xz(o)
	local mx,mz=rot2d(
			o.x-ppx,
			o.z-ppz,
			(pp_ya+0.5))
		mx=mid(-15,mx/64,15)
		mz=mid(-15,mz/64,15)
	return mx,mz
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
		//dz=0
		return
	end
	sort_tri(
		{s.tris,{px,py}},s,dz)
end

function proj_obj(o)
	n_o_proj+=1
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
--[[
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
]]--
function sort_tri(tt,col,dz)
	//if dz>1 and dz<zfar then
	if dz>1 then
		n_t_sorted+=1
		
		local newn={
			tri=tt,
			col={col,nil},//temp, later add flip thing if needed
			dz=dz,
			nxt=nil,
			prv=nil
		}
		
		//n_t_sort+=1
		if t_sorted_ll==nil then
			t_sorted_ll=newn
			return
		end
		
		local node=t_sorted_ll
		while node!=nil do
			//i+=1
			if dz>node.dz then
				if node.prv then
					node.prv.nxt=newn
				else
					t_sorted_ll=newn
				end
				newn.prv=node.prv
				newn.nxt=node
				node.prv=newn
				return
			end
			if node.nxt==nil then
				node.nxt=newn
				newn.prv=node
				return
			end
			node=node.nxt
		end
		
		printh("node not added")
		alert="oops"
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
--[[
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
]]--
function draw_sorted()
	n_t_sorted_d=0
	local node=t_sorted_ll
	while node!=nil do
		
		if type(node.tri[1])=="function" then
			//draw_sprite(t)
			node.tri[1](node)
		else
			n_t_sorted_d+=1
			draw_tri(
				node.tri,
				node.col[1],
				node.col[2]
			)
		end
		node=node.nxt
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
	--[[
	pelogen_tri(
		t[3][1],t[3][2],
		t[4][1],t[4][2],
		t[5][1],t[5][2],
		c)
		]]--
	pelogen_tri(
	 t[1][1],t[1][2],
	 t[2][1],t[2][2],
	 t[3][1],t[3][2],
	 c,f)
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

function draw_spr_layer(y,sz,f)
	local secx=flr(ppx/sz)
	local secz=flr(ppz/sz)
	local sz2=flr(sz/2)
	//printh(cos(pp_pi))
	local hf=flr(
		(abs(ppy-y)/100)*cos(pp_pi)
	)+1
	//printh(hf)
	
	local povx=round(secx-hf*sin(pp_ya))
	local povz=round(secz-hf*cos(pp_ya))	
	for i=povx-1,povx+1 do
	for j=povz-1,povz+1 do
		srand((i<<8)+j)
		for k=0,max(1,5-hf) do
			proj_sprite({
				tris=f,
				x=i*sz+rand(-sz2,sz2)+sz2,
				y=y,
				z=j*sz+rand(-sz2,sz2)+sz2,
				ya=0,pi=0,ro=0
			})
		end
	end end
	srand(time())
end
-->8
-- player 

function draw_pp_plane()
	proj_obj({
		tris=pp_plane,
		x=ppx,y=ppy,z=ppz,
		ya=pp_ya,pi=pp_pi,ro=pp_ro
	})
end

function update_cam()
	if pp_hp<=0 then
		cam_ya+=0.005
		cam_d-=0.5
	else
		cam_ya=-pp_ya+cam_flip --debug for rear view
		cam_pi=pp_pi+sin(pp_pi)*0.05
	end
	
	dcy,dcz=rot2d(
		cam_h,cam_d,-cam_pi)
	dcz,dcx=rot2d(
		dcz,0,-cam_ya)
	
	camz=ppz+dcz
	camx=ppx+dcx
	camy=ppy+dcy
end

l_pi=0
pp_s_wpn=0
function update_player()
	if g_start_t>0 or pp_hp<=0 then
		goto pp_after_ctrl
	end
	
	if btn(❎) then
		pp_s_wpn+=1
		if pp_s_wpn>10 then
			if btnp(⬅️) then
				spd_m=0
			elseif btnp(➡️) then
				spd_m=1
			elseif btnp(⬆️) then
				wpn=(wpn-1)%2
			elseif btnp(⬇️) then
				wpn=(wpn+1)%2
			end
			//goto pp_after_ctrl
			return
		end
	elseif pp_s_wpn>0 then
		if pp_s_wpn<10 then
			find_targ(true)
			trg_t=20
		end
		pp_s_wpn=0
	end
	
	if btn(⬆️) then
		pp_pi=max(pp_pi-0.005,-0.24)
	elseif btn(⬇️) then
		pp_pi=min(pp_pi+0.005,0.24)
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
		turnx=min(turnx+0.0005,0.005)
		pp_ro=min(pp_ro+0.01,0.125)
	elseif btn(⬅️) then
		turnx=max(turnx-0.0005,-0.005)
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
	
	can_mssl=#pp_bays
	for i=1,#pp_bays do
		local b=pp_bays[i]
		if b>0 then
			pp_bays[i]-=1 //not sure why b-=1 isnt working
			can_mssl-=1
		end
	end
	
	if sh_delay>0 then
		sh_delay-=1
	end
	
	if btn(🅾️) and sh_delay==0 then
		//if(wpn==0)find_targ(true)
		if wpn==0 and 
					can_mssl>0 and 
					pp_ammo1>0 then
			sh_delay=15
			pp_bays[pp_bay+1]=90
			pp_bay=(pp_bay+1)%2
			pp_ammo1-=1
			local targ=nil
			if pp_targ and st_p[3]==1 then
				targ=pp_targ
			end
			shoot_mssl(
				ppx,ppy+2,ppz,
				pp_ya,pp_pi,
				6,0.06,
				targ)
		elseif wpn==1 and pp_ammo2>0 then
			sh_delay=2
			pp_ammo2-=1
			shoot_gun(
				ppx,ppy,ppz,
				pp_ya,pp_pi)
		end
	end
	
	::pp_after_ctrl::
	
	dam_t-=1
	trg_t-=1
	
	pp_ya-=turnx
	pp_ya=pp_ya%1
	
	if spd_m==0 then
		//if pp_spd>spd_
		pp_spd=max(spd_mid,pp_spd-0.1)
	elseif spd_m==1 then
		pp_spd=min(spd_max,pp_spd+0.1)
	end
	
	if pp_hp<=0 then
		pp_pi=max(pp_pi-0.001,-0.24)
		pp_ya+=0.01
	end
	
	dx,dy,dz=rot3d(
		0,0,pp_spd,
		pp_pi,
		pp_ya,
		0)
		
	ppx-=dx
	ppy-=dy
	ppz-=dz
	
	if ppy>=0 then
		pp_hp=0
	end
	
	for b in all(cur_lvl.blds)do
		if col_box(b[1],b[2],10,100) then
			pp_hp=0	
		end
	end
	
	if col_box(rf_o.x,rf_o.z,40,40) then
		pp_ammo1=pp_plane_d.ammo1
		pp_ammo2=pp_plane_d.ammo2
		alert("refuled")
	end
	
	ppy=min(0,ppy)
	
	if wpn!=0 or 
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

function find_targ(from_p)
	printh("finding targs")
	local f_targs={}
	for e in all(enmy)do
		if not from_p or
					onscr(e) then	
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

function shoot_gun(x,y,z,ya,pi)
	local blt=obj(
		draw_blt,
		x,y,z,
		ya,pi,0,
		update_blt)
	dx,dy,dz=rot3d(
		0,0,30,
		pi,
		ya,
		0)
	blt.dx=dx
	blt.dy=dy
	blt.dz=dz
	blt.t=100
	add(objs,blt)
end

local acc=0.05
function update_blt(b)
	if b.dy>-2 then
		b.dy-=acc
	else
		b.dy+=acc
	end
	
	b.dx-=acc*sin(b.ya)
	b.dz-=acc*cos(b.ya)
	
	b.x-=b.dx
	b.y-=b.dy
	b.z-=b.dz
	
	b.t-=1
	if(b.t<=0)del(objs,b)
	
	check_hit_e(b,10,10)
end
-->8
-- ememies

function add_enemy(x,y,z,typ)
	local base=enmy_p_base[typ]
	local plane=base.plane
	local up=update_e_plane
	
	local tris={}
	if typ=="tnk" then
		//tris=base.plane
		up=update_e_tnk
	elseif typ=="sam" then
		//tris=base.plane
		up=update_e_sam
	else
		tris=plane_tris(base.plane.tris)
	end
	
	local e=obj(
		tris,
		x,y,z,0,0,0,
		up)
	e.typ=typ
	e.base=base
	e.hp=100
	e.mode="evade"
	e.t=1 --mode timer
	e.lt=base.lt_max --lock timer

	e.spd=5
	e.tx=0 --target x
	e.ty=0 --target y
	e.tz=0 --target z
	e.sx=x --start x
	e.sz=z --start z
	e.la=0 --turn lerp amt

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
		e.la=0.05
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
	e.tx=ppx
	e.tz=ppz
	e.ty=ppy
	
	e.la=e.base.la_f
	if pd>200 then
		e.spd=pp_spd+2
		//e.la=0.05
	else
		e.spd=pp_spd
		//e.la=0.05
	end
	
	local dff=abs(
		cos(e.ya)-cos(pp_ya)
	)%1
		
	//if dff<0.35 and e.scrdz<2 then
	if dff<0.35 then
		warn=true
		e.lt-=1
		if e.lt==0 then
			printh("enemy fire")
			e.lt=e.base.lt_max
			shoot_mssl(
				e.x,e.y+2,e.z,
				e.ya,e.pi,
				6,0.08,
				pp_obj)
		end
	else
		e.lt=e.base.lt_max
		e.t-=1
	end
		
	if e.t==0 then
		e_set_evade(e)
		--[[
		local sd=dist(
			e.x,0,e.z,e.sx,0,e.sz)
		if sd>1000 or 
					rnd()>e.base.f_ch then
			e_set_evade(e)
		else
			e_set_follow(e)		
		end
		]]--
	end
end

function update_e_evade(e,pd)
	e.la=e.base.la_e
	e.t-=1
		
	if pd<100 then
		e.spd=pp_spd
	else
		e.spd=pp_spd-1
	end
		
	if e.t==0 then
		local sd=dist(
			e.x,0,e.z,e.sx,0,e.sz)
		if sd>1000 or 
					rnd()>e.base.f_ch then
			e_set_evade(e)
		else
			e_set_follow(e)
		end
	end
end

function e_set_evade(e)
	loga({"s mode:",e.mode,"-> evade"})
	e.mode="evade"
	e.t=30*15
	e.tx=rand(-500,500)+e.sx
	e.tz=rand(-500,500)+e.sz
	//e.ty=rand(150,10000)*-1
	e.ty=min(
		rand(-1000,1000)+e.y,
		-150
	)
	loga({"set evade targ",e.tx,e.ty,e.tz})
end

function e_set_follow(e)
	loga({"s mode:",e.mode,"-> follow"})
	e.mode="follow"
	e.t=30*5
	e.lt=30
end

function update_e_sam(e)
	get_onscr(e)
	
	local pd=dist(
		e.x,e.y,e.z,ppx,ppy,ppz)
	if pd>1000 then
		e.lt=90
	else
		warn=true
		e.lt-=1
		if e.lt==0 then
			if rnd()<0.5 then
				printh("enemy fire")
				local aya,api=atan3d(
					e.x,e.y,e.z,
					ppx,ppy,ppz,
					0)
				shoot_mssl(
					e.x,e.y-5,e.z,
					aya,api,
					5,0.06,
					pp_obj)
			end
			e.lt=90
		end
	end
	
	check_e_dead(e)
end

function update_e_tnk(e)
	get_onscr(e)
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
		pp_scr+=e.base.scr
		del(enmy,e)
		find_targ(false)
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
		check_hit_e(m,4,50)
	end
	
	if m.t==0 or m.y>=0 then
		del(objs,m)
		del(e_mssl,m)
		if m.p and alert_m=="" then
			alert("miss")
		end
	end
end

function check_hit_e(o,dst,dam)
	for e in all(enmy)do		
		local d=dist(
			o.x,o.y,o.z,
			e.x,e.y,e.z)

		if d<dst then
			o.t=0
			e.hp-=dam
			del(objs,m)
			alert("hit")
			add_expl(o.x,o.y,o.z)
			return
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
	local z=(zfar-s.dz)/zfar
	spr(3,s.tri[2][1],s.tri[2][2],z,z)
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
	if(e.col[1].t>20)return
	local z=(zfar-e.dz)/zfar
	//spr(3,s[4][1],s[4][2],z,z)
	circfill(
		e.tri[2][1],
		e.tri[2][2],
		(20-abs(e.col[1].t-15))*z,
		e.col[1].c)
end

function draw_blt(b)
	pset(b.tri[2][1],b.tri[2][2],10)
end

function draw_grnd(g)
	local z=max(0,(500-g.dz)/500)
	//spr(11,g[4][1],g[4][2],z,z)
	//printh(z)
	sspr(
		cur_lvl.ter[3]*8,0,16,16*z,
		g.tri[2][1],g.tri[2][2],
		z*16,z*16)
end

function draw_cld(c)
	//printh(c)
	local z=max(0,(2000-c.dz)/2000)
	sspr(
		88,16,24,16,
		c.tri[2][1],c.tri[2][2],
		z*24,z*16)
end

function draw_bld_line(b)
	//local z=max(0,(2000-c.dz)/2000)
	for l in all(b.col[1].lines)do
		line(l[1],l[2],l[3],l[4],13)
	end
end

function draw_sun(s)
	circfill(
		s.tri[2][1],
		s.tri[2][2],
		10,
		cur_lvl.ter[1]==12 and 9 or 6)
end

function draw_rf(r)
	pset(r.tri[2][1],r.tri[2][2],8)
	local pts={
		{-1,-1},
		{1,-1},
		{1,1},
		{-1,1}
	}
	for i=1,#pts do
		local i2=max(1,(i+1)%5)
		local x=r.col[1].x
		local z=r.col[1].z
		local x1=x+pts[i][1]*40
		local z1=z+pts[i][2]*40
		local x2=x+pts[i2][1]*40
		local z2=z+pts[i2][2]*40
		local px1,py1=proj(x1,-40,z1)
		local px2,py2=proj(x2,-40,z2)
		local px3,py3=proj(x1,0,z1)
		//pset(px,py,8)
		line(px1,py1,px2,py2,12)
		line(px1,py1,px3,py3,12)
	end
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

function print2(s,x,y,c1,c2)
	if(c2==nil)c2=0
	if(c2==0)palt(0,false)
	print(s,x+1,y+1,c2)
	print(s,x,y,c1)
	pal()
end

function plane_tris(pl)
	local tris={}
	for t in all(pl)do
		for f in all({-1,1})do
			local tt={}
			for i=1,3 do
				local pts={}
				pts[1]=t[i][1]*f
				pts[2]=t[i][2]
				pts[3]=t[i][3]
				add(tt,pts)
			end
			tt[4]=t[4]
			add(tris,tt)
		end
	end
	return tris
end

function col_box(x,z,w,h)
	return ppx>x-w and 
				ppx<x+w and
				ppz>z-w and 
				ppz<z+w and
				ppy>h*-1
end

function rank()
	local r={"s","a","b","c"}
	for i=1,#cur_lvl.rs do
		if pp_scr>=cur_lvl.rs[i] then
			return r[i]
		end
	end
	return "f"
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

planes={
--[[
	{ //test plane
		tris={
			{ //wing
				{0,0,-10},
				{10,0,8},
				{0,0,0},
					7,
			},
			{ // horz stab
				{0,0,0},
				{8,0,10},
				{0,0,8},
				15,
			},
			{ //ver stab
				{3,0,0},
				{3,0,10},
				{3,-5,8},
				7,
			},
			{ //cockpit 1
				{0,0,-8},
				{2,0,-5},
				{0,-1,-5},
				5
			},
			{ //cockpit 2
				{0,-1,-5},
				{2,0,-5},
				{0,0,-3},
				5
			},
		},
		data={
			name="test plane",
			ammo1=80, //missle
			ammo2=500 //bullet
		}
	},
	]]--
	{ //mirage 2000
		tris={
			{ //body 1
				{0,0,-10},
				{0,0,-4},
				{1,0,-4},
				7
			},
			{ //body 1
				{0,0,-10},
				{0,0,10},
				{1,0,10},
				7
			},
			{ //body 2
				{0,0,-4},
				{2,0,-4},
				{1,0,10},
				7
			},
			{ //wing
				{2,0,-2},
				{8,0,7},
				{1,0,8},
				6
			},
			{//ver stab
				{0,0,3},
				{0,-4,9},
				{0,0,9},
				5
			},
			{ //cockpit 1
				{0,0,-6},
				{1,0,-4},
				{0,-1,-4},
				5
			},
			{ //cockpit 2
				{0,-1,-4},
				{1,0,-4},
				{0,0,-2},
				5
			},
		},
		data={
			name="m 2000",
			ammo1=80,
			ammo2=500,
			spd_max=8,
			turn=0.001,
			hp_max=100
		}
	},
	{ // f-14
		tris={
			{
				{0,0,-12},
				{0,0,10},
				{3,0,10},
				6
			},
			{
				{0,0,-5},
				{2,0,-5},
				{2,0,6},
				6
			},
			{
				{2,0,-5},
				{2,0,4},
				{8,0,10},
				7
			},
			{
				{2,0,5},
				{0,0,9},
				{6,0,10},
				7
			},
			{
				{2,0,3},
				{2,0,9},
				{3,-4,9},
				15
			},
			{ //cockpit 1
				{0,0,-6},
				{1,0,-3},
				{0,-1,-3},
				5
			},
			{ //cockpit 2
				{0,-1,-3},
				{1,0,-3},
				{0,0,-1},
				5
			},
		},
		data={
			name="fc-14",
			ammo1=80, //missle
			ammo2=500, //bullet
			spd_max=8,
			turn=0.001,
			hp_max=100
		}
	},
	{ //rafale
		tris={
			{ //body 1
				{0,0,-10},
				{0,0,-1},
				{2,0,-1},
				7
			},
			{ //body 2
				{0,0,-1},
				{2,0,-1},
				{0,0,10},
				7
			},
			{ //body 3
				{2,0,-1},
				{0,0,10},
				{1,0,10},
				7
			},
			{ //canard
				{1,0,-4},
				{4,0,-1},
				{2,0,-1},
				13
			},
			{ //wing 1
				{2,0,-1},
				{8,0,6},
				{1,0,8},
				6
			},
			{ //wing 2
				//{2,0,-1},
				{8,0,6},
				{8,0,7},
				{1,0,8},
				6
			},
			{ //thingy
				{7.8,0,8},
				{8,0,8},
				{8,0,4},
				6
			},
			{//ver stab
				{0,0,3},
				{0,-4,9},
				{0,0,9},
				5
			},
			{ //cockpit 1
				{0,0,-6},
				{1,0,-3},
				{0,-1,-3},
				5
			},
			{ //cockpit 2
				{0,-1,-3},
				{1,0,-3},
				{0,0,0},
				5
			},
		},
		data={
			name="raf m",
			ammo1=80,
			ammo2=500,
			spd_max=8,
			turn=0.001,
			hp_max=100
		}
	},
	{ //f15
		tris={
			{
				{0,0,-12},
				{0,0,8},
				{2,0,8},
				6
			},
			{
				{0,0,-5},
				{2,0,-5},
				{2,0,8},
				6
			},
			{
				{2,0,-3},
				{2,0,5},
				{8,0,7},
				7
			},
			{
				{2,0,-3},
				{8,0,7},
				{9,0,6},
				7
			},
			{ //horz stab
				{2,0,6},
				{2,0,10},
				{6,0,11},
				7
			},
			{ //ver stab
				{2,0,6},
				{2,0,10},
				{2,-4,11},
				15
			},
			{ //cockpit 1
				{0,0,-6},
				{1,0,-3},
				{0,-1,-3},
				5
			},
			{ //cockpit 2
				{0,-1,-3},
				{1,0,-3},
				{0,0,-1},
				5
			},
		},
		data={
			name="fe-15",
			ammo1=80, //missle
			ammo2=500, //bullet
			spd_max=8,
			turn=0.001,
			hp_max=100
		}
	},
	{ //su37
		tris={
			{ //body
				{0,0,-10},
				{0,0,10},
				{2,0,10},
				7
			},
			{ //body2
				{0,0,-6},
				{2,0,-2},
				{2,0,10},
				7
			},
			{ //canards
				{2,0,-2},
				{2,0,0},
				{5,0,1},
				13
			},
			{ //wing1
				{2,0,0},
				{2,0,6},
				{8,0,6},
				6
			},
			{ //wing2
				{2,0,6},
				{8,0,6},
				{8,0,8},
				6
			},
			{ // not sure what called
				{7.8,0,8},
				{8,0,8},
				{8,0,4},
				7
			},
			{ // hor stab
				{2,0,6},
				{2.5,0,10},
				{5,0,11},
				6
			},
			{ //ver stab
				{2,0,5},
				{2,-4,10},
				{2,0,10},
				5
			},
			{ //cockpit 1
				{0,0,-5},
				{1,0,-2},
				{0,-1,-2},
				5
			},
			{ //cockpit 2
				{0,-1,-2},
				{1,0,-2},
				{0,0,0},
				5
			},
		},
		data={
			name="sk37",
			ammo1=80,
			ammo2=500,
			spd_max=8,
			turn=0.001,
			hp_max=100
		}
	},
}

function sam_tris(c)
	return {
		{
			{0,0,-10},
			{0,-10,0},
			{0,0,10},
			c
		},
		{
			{-10,0,0},
			{0,-10,0},
			{10,0,0},
			c
		}
	}
end

bld_tris={
	{
		{-20,0,-20},
		{20,0,-20},
		{-20,-100,-20},
		5,
	},
	{	
		{20,0,-20},
		{20,-100,-20},
		{-20,-100,-20},
		5,
	},
	{	
		{20,0,-20},
		{20,0,20},
		{20,-100,-20},
		5,
	},
	{	
		{20,0,20},
		{20,-100,20},
		{20,-100,-20},
		5,
	},
	{	
		{-20,0,20},
		{20,0,20},
		{-20,-100,20},
		5,
	},
	{	
		{20,0,20},
		{20,-100,20},
		{-20,-100,20},
		5,
	},
	{	
		{-20,0,-20},
		{-20,0,20},
		{-20,-100,-20},
		5,
	},
	{	
		{-20,0,20},
		{-20,-100,20},
		{-20,-100,-20},
		5,
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
 	ppx=0,
 	ppy=-250,
 	ppz=1000,
 	title="lvl 1",
 	ter={ //terrain
 		12, //sky color
 		3, //ground color
 		11 //ground sprite idx
 	},
 	enmy={
 		//{-1000,-400,0,"mig"},
 		//{0,-400,0,"mig"},
 		//{500,-400,0,"mig"},
 		//{0,0,-1000,"sam"},
 		//{0,0,-1120,"tnk"},
 		{100,0,-1000,"tnk"}
 	},
 	objs={},
 	blds={
 		//{0,0}, //x,z
 		//{-100,0},
 		//{100,0},
 		{0,-300},
 		{100,-500},
 		{-100,-1000},
 		{0,-2000},
 		{0,-3000},
 	},
 	rf={0,0}, //refuel coords
 	rs={50,40,30,20} //ranks
 },
 { -- level 2
 	ppx=0,
 	ppy=-50,
 	ppz=600,
 	title="lvl 2",
 	ter={ 
 		0,
 		3, 
 		11 
 	},
 	enmy={
 		{-1000,-400,0,"mig"},
 		{0,-400,0,"mig"},
 		{500,-400,0,"mig"},
 		{0,0,1000,"sam"},
 	},
 	objs={},
 	blds={
 		{0,0},
 		{-30,0},
 		{30,0},
 		{0,-300},
 		{100,-500},
 		{-100,-1000},
 	},
 	rf={0,0},
 	rs={50,40,30,20}
 },
 { -- level 3
 	ppx=0,
 	ppy=-50,
 	ppz=600,
 	title="lvl 3",
 	ter={ 
 		12,
 		1, 
 		13 
 	},
 	enmy={},
 	objs={},
 	blds={},
 	rf={0,0},
 	rs={50,40,30,20}
 }
}

enmy_p_base={
	tnk={
		plane=sam_tris(15),
		scr=50
	},
	sam={
		plane=sam_tris(2),
		scr=30,
		lt_max=90,
	},
	mig={
		plane=planes[1],
		scr=60,
		lt_max=60, --lock time max
		f_ch=0.5, --follow chance
		la_f=0.03, --turn spd follow
		la_e=0.005  --turn spd evade
	},
}
__gfx__
00000000000000000000000050505500bb000000666666606666666066666660000000000000000000000000b0b0b00bb0b0b00b000000000000000000000000
000000000000000000000000505555500bbb00006700076061000160600000600090000000000000000000000b000b000b000b00000000000000000000000000
0070070000000000000000000500505000bbbb0060707060601010606000006000090000000fff0000000000b00b01b3b00b01b3000000000000000000000000
00077000000000000000000055555050000bbbbb60070060600100606000006000009000000f0f00000000000b10b0bb0b10b0bb000060000000600000000000
00077000000000000000000005055005000bbbbb60707060601010606000006000090000000fff000000000000b01b0b00b01b0b000606000006060000000000
0070070000000000000000000555050500bbbb00670007606100016060000060009000000000000000000000b0b1b010b0b1b010006000600060006000000000
000000000000000000000000505050500bbb00006666666066666660666666600000000000000000000000000b0b010b0b0b010b660000066600000600000000
00000000000000000000000000500505bb0000000000000000000000000000000000000000000000000000001013010110130101000000000000000000000000
66606066606660666066606660666000006060000060000000000000000000000000000000000000000000000000004004000000000000000000000000000000
60606060606000606060606000060000060600000606000000000000000000000000000000000000000000000000000400000000000000000000000000000000
66606066006000660066606600060000606000006060600000000000000000000000000000000000000000000000005004000000000060000006000000000000
60606060606660606060606000060000060600000606000000000000000000000000000000000000000000000000004400000000000606600060600000000000
66606660666066606660000000000000006060006000600000000000000000000000000000000000000000000000000505000000066000066060066000000000
60000600606006006000000000000000000000000000000000000000000000000000000000000000000000000000005050000000600000000600000600000000
00600600666006000060000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000
66600600606006006660000000000000000000000000000000000000000000000000000000000000000000000000005505000000000000000000000000000000
66006660666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606660600000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000060000000000000000000000000
60606060606000000000000000000000000000000000000000000000000000000000000000000000000000000006666660000666600000000000000000000000
66006060666000000000000000000000000000000000000000000000000000000000000000000000000000000066666666006666660060000000000000000000
66606000666000000000000000000000000000000000000000000000000000000000000000000000000000000666666666606666666666000000000000000000
60606000060000000000000000000000000000000000000000000000000000000000000000000000000000006666666666666666666666600000000000000000
66606000060000000000000000000000000000000000000000000000000000000000000000000000000000006666666666666666666666660000000000000000
60606660060000000000000000000000000000000000000000000000000000000000000000000000000000006666666666666666666666660000000000000000
66606660660000000000000000000000000000000000000000000000000000000000000000000000000000000666666666666666666666660000000000000000
60006060606000000000000000000000000000000000000000000000000000000000000000000000000000000666666666666666666666600000000000000000
00606660606000000000000000000000000000000000000000000000000000000000000000000000000000000066666666666666666666600000000000000000
66606000660000000000000000000000000000000000000000000000000000000000000000000000000000000006666666666666666666000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666666660066660000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666000000000000000000000000000
