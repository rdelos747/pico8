pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- nuclear semiotics

ver="0.0.11"

-- constants

rpso=-1
walt=0	--walk time

rp1_us=2.4 --rad1 up speed
rp1_ds=1 		--rad1 down speed
rp2_s=1 			--rad2 up speed

hand_d=-3.5 	--hand delay
hand_up=0.07 --hand up speed
hand_dn=0.07 --hand down speed

--temp
//hand_d=0 	--hand delay
//hand_up=1 --hand up speed
//hand_dn=1 --hand down speed

sp_hs=1 	--spike hell speed
sp_hd=20 --spike hell dist

--globals

ppx,ppy,ppz=0,-8,-420
pp_pi,pp_ya=0,0
pp_rp,pp_rp2=0,0
pdd=30000
keys={}
lock_i=nil
lock_j=nil

camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=0
cam_h=0

sunx,suny,sunz=0,-200,0

fov=0.15
fov_c=-2.778 //1/tan(fov/2)
zfar=500
znear=-14
lam=zfar/(zfar-znear)
pov_scr_t=0

sec_s_a=0.11 //sec search ang
sec_s_n=11 //sec search slices
sec_d={ //sec layer rend dists
	sp=20,
	sh=5,
	ky=5
	//sy=5,
	//tr=5
}

secr=25
secr2=50
sex,sez=0,0
d_mode=0
mode="title"
story=0
alert=nil

function _init()
	printh("====== init ======")
	
	for t in all(hand_tris)do
		add(t,5)
	end
	
	hand=obj(
		hand_tris,
		0,0,0,
		0,0,0,
		0,0,
		nil)
	hand_t=hand_d
	
	lvl={}
	
	init_title()
end

function reset_vars()
	pdd=60			--death delay
	pdt=0				--death time
	pp_rp=0 	--rad psn temp
	pp_rp2=0 --rad psn perm
	hand_t=-2 --hand time
	act_sp=nil --active spike
end

function init_title()
	mode="title"
	ppx=306.6851
	ppy=-8
	ppz=-1.009
	pp_ya,pp_pi=0.2299,0.06
	srand(2)
	add_me_area(0,0,2)
	music(2)
end

function init_story_0()
	srand(time())
	//ppx,ppy,ppz=0,-8,-420
	//ppx,ppy,ppz=14,-8,-125
	//ppx,ppy,ppz=-189,-8,43
	ppy=-8
	ppx,ppz=40,5
	pp_pi,pp_ya=0,0.88
	mode="game"
	story=0
	
	lock_ord={}
	local vals={1,2,3}
	for _=1,3 do
		local v=deli(
			vals,rand(1,#vals)
		)
		loga({"x",v})
		add(lock_ord,v)
	end
	
	srand(2)
	menuitem(1,"map",function()
		d_mode=(d_mode+1)%3
	end)
	
	lvl={}
	add_me_area(0,-7,2)
	add_lk_area(4,-12)
	add_me_sp(2,1)
	
	srand(time())
	music(0)
	
	reset_vars()
	
	--temp test keys
	--[[
	local to=obj(
		pyr_tris,
		0,0,0,
		0,0,0,
		0,0,
		nil
	)
	to.key_n=1
	to.t=0
	add(keys,to)
	]]--
end

function init_story_1()
	ppx,ppy,ppz=0,-100,0
	pp_pi,pp_ya=0,0
	mode="game"
	story=1
	
	lvl={}
	add_hell_area(0,0,2)
	
	menuitem(1,"map",function()
		d_mode=(d_mode+1)%3
	end)
	
	reset_vars()
end

function _draw()	
	t_sorted_ll=nil
	n_t_sorted=0
	n_o_proj=0
	
	n_sec_chk=0
	n_sec_fnd=0
	
	if mode=="title" then
		draw_title()
	else
		draw_game()
	end
end

function draw_title()
	proj_pov()
	draw_sorted()
	proj_sun_rays()
	
	print(ver,1,1,1)
	print("press ❎ to start",1,7,2)
end

function draw_game()
	if d_mode==1 then
		draw_top_down()
		return
	elseif d_mode==2 then
		draw_full_map()
		return
	end
	
	proj_pov()
	proj_hand()
	if pdd>0 then
		draw_sorted()
	end
	if story<1 then
		proj_sun_rays()
	end
	draw_rad()
	draw_log()
	
	if pdd==0 then
		print(
			"press ❎ to retry",
			1,120,
			7)
	end
end

function proj_pov()
	if pp_rp2<100 then
		cls(story==0 and 7 or 0)
	end
	
	-- scrolling sky
	if story==1 then
		pov_scr_t=(pov_scr_t+1)%8
		for j=0,16 do
		for i=0,16 do
			spr(
				128,
				i*8-pov_scr_t,
				j*8-pov_scr_t)
		end end
	end
	
	camera(0,0)
	
	if pp_rp2<100 then
		local gh=64+pp_pi*1024
		gh=mid(0,gh,128)
		rectfill(
			0,gh,
			127,gh+127,
			story==0 and 15 or 1)
	end
	
	//n_t_sort=0
	
	if story<1 then
	proj_spr(
		obj(
			draw_sun,
			sunx,suny,sunz,
			0,0,0,0,0,
			nil
		)
	)
	end
	
	proj_secs()
	//draw_sorted()
	
	if alert then
		print(
			alert,
			64-#tostr(alert)*2.5,
			80,
			11)
	end
end

function draw_rad()
	for i=1,pp_rp do
		pset(
			rand(0,127),
			rand(0,127),
			2)
	end
	for i=1,pp_rp2*5 do
		pset(
			rand(0,127),
			rand(0,127),
			0)
	end
end

function draw_log()
	pria({"x",ppx,"z",ppz,"ya",pp_ya},0,0,5)
	pria({"sc ch",n_sec_chk},0,6,5)
	pria({"sc fn",n_sec_fnd},0,12,5)
	
	pria({"o prj",n_o_proj},0,18,5)
	pria({"n t s",n_t_sorted},0,30,8)
	pria({"n t d",n_t_sorted_d},0,36,5)
	pria({pp_rp,pp_rp2},0,42,11)
	pria({#keys},0,48,11)
end

function proj_sun_rays()
	ray_pts=0
	local ray_pts_h=0
	
	local sx,sy=proj(sunx,suny,sunz)
	//printh(sx)
	if sx>=0 and sx<=127 then
		//for p in all({
		//pset(sx-10,sy-10,8)
		local a=0
		while a<1 do
			//local ca,sa=cos(a),sin(a)
			if pget(
							sx+cos(a)*9,
							sy+sin(a)*9
						)==5 then
				ray_pts_h+=1
				//ray_pts+=1
			elseif pget(
							sx+cos(a)*9,
							sy+sin(a)*9
						)==9 then
				//pset(sx+ca*9,sy+sa*9,8)
				ray_pts+=1
				for j=-5,5 do
					local aa=a+j*0.002
					line(
						sx+cos(aa)*11,
						sy+sin(aa)*11,
						sx+cos(aa)*150,
						sy+sin(aa)*150,
						7)
				end
			end
			a+=1/10
		end
		
		//loga({ray_pts,ray_pts_h})
		ray_pts+=ray_pts_h
		
		//ray_pts=min(ray_pts,ray_pts_h)
		//if ray
		
		
		if pget(sx,sy)==9 then
			local fx=sx-64
			circ(64+fx/16,55,10,7)
			circ(64-fx/2,60,30,7)
		end
	end
end

function proj_hand()
	//printh(hand_t)
	local ht=max(hand_t,0)
	hand.x=ppx
	hand.z=ppz
	if #keys>0 then
		hand.y=-2-5*ht+pp_pi*50
		hand.ro=0.35//0.07+0.08*ht
		hand.ya=pp_ya-0.1
		hand.pi=0.65
		
		keys[1].y=-2-7*ht+pp_pi*50
	else
		hand.y=-2-7*ht+pp_pi*50
		hand.ro=0.07+0.08*ht
		hand.ya=pp_ya
		hand.pi=0//pp_pi
	end
	
	//temp
	//hand.ro=0
	//hand.y=-7
		
	if ht>0 then
		proj_obj(hand,false)
		if #keys>0 then
			proj_obj(keys[1],false)
		end
	end
end

function proj_secs()	
	//loga({"checking"})
	local chkd={}	
	for n=0,10 do
	for ai=0,sec_s_n-1 do
		local a=sec_s_a*(ai/(sec_s_n-1))-(sec_s_a/2)
		n_sec_chk+=1
			
		local i=round(
			sex+sin(pp_ya+a)*n)
		local j=round(
			sez+cos(pp_ya+a)*n)				
		
		local id=(j>>8)+i
		local sec=get_sec(i,j)
		if chkd[id] then
			//lol
		elseif sec then
			//loga({"found",i,j,id})
			n_sec_fnd+=1
			//loga({dtb2(i)})
			//loga({dtb2(j)})
			//loga({dtb2(id)})
			chkd[id]=true
				
			for k,v in pairs(sec_d) do
				if n<v then
					for o in all(sec[k]) do
						sx,sy,dz=proj(o.x,o.y,o.z)
						if on_scr_x(sx) then
							proj_obj(o,k=="sp")
						end
					end
				end
			end
		end
			
		if n_t_sorted>72 then
			return
		end
		
	end end
end

function draw_top_down()
	cls(0)
	local zm=10
	local pmx=ppx/zm
	local pmz=ppz/zm
	camera(pmx-64,pmz-64)
		
	for i=0,sec_s_n-1 do
		local a=sec_s_a*(i/(sec_s_n-1))-(sec_s_a/2)
		
		line(
			pmx,pmz,
			pmx+sin(pp_ya-a)*64,
			pmz+cos(pp_ya-a)*64,
			1)
	end
	
	//loga({"checking"})
	local nchk,nfnd=0,0
	local chkd={}
	for ai=0,sec_s_n-1 do
		local a=sec_s_a*(ai/(sec_s_n-1))-(sec_s_a/2)
		for n=0,10 do
			nchk+=1
			
			local i=round(
				sex+sin(pp_ya+a)*n)
			local j=round(
				sez+cos(pp_ya+a)*n)
		
			local id=(j>>8)+i
			local sec=get_sec(i,j)
			if chkd[id] then
				//loga({"checked",i,j,id})
			elseif sec then
				//loga({"found",i,j,id})
				nfnd+=1
				//loga({dtb2(i)})
				//loga({dtb2(j)})
				//loga({dtb2(id)})
				chkd[id]=true
			
				local x=(i*secr2)-secr
				local z=(j*secr2)-secr
			
				rect(
					x/zm,
					z/zm,
					(x+secr2)/zm,
					(z+secr2)/zm,
					n<3 and 13 or 1)
		
				for sp in all(sec.sp)do
					pset(
						sp.x/zm,
						sp.z/zm,
						5)
				end
				
				for sp in all(sec.ky)do
					pset(
						sp.x/zm,
						sp.z/zm,
						12)
				end
				--[[
				for sp in all(sec.sy)do
					pset(
						sp.x/zm,
						sp.z/zm,
						8)
				end
				]]--
				--[[
				for r in all(sec.rs)do
					pset(
						r.x/zm,
						r.z/zm,
						14)
					circ(
						r.x/zm,
						r.z/zm,
						r.r/zm,
						11)
				end
				]]--
			end
		end
	end
	
	//pset(pmx,pmz,8)
	
	pria({ppx,ppz},
		pmx-64,pmz-64,8)
	pria({sex,sez},
		pmx-64,pmz-58,8)
	pria({nchk,nfnd},
		pmx-64,pmz-52,8)
end

function draw_full_map()
	//local w=0
	//local h=0
	local zm=50
	cls()
	camera(-64,-64)
	for a in all(areas)do
		for j=1,a.ws do
		for i=1,a.ws do
			for o in all(a.secs[j][i].sp)do
				pset(o.x/zm,o.z/zm,5)
			end
		end end
	end
	pset(ppx/zm,ppz/zm,7)
end

function _update()
	if mode=="title" then
		update_cam()
		if(btn(❎))init_story_0()
		return
	end


 alert=nil
 --[[
 if mode==1 then
 	update_term1()
 	return
 elseif mode==2 then
 	update_term2()
 	return
 elseif mode==3 then
 	update_term3()
 	return
 end
 ]]--

	
	if pp_rp2>=100 then
		update_dead()
	else
		update_player()
	end
	
	update_cam()
	
	sunx=ppx-1000
	sunz=ppz
	
	if ray_pts==0 then
		hand_t=max(hand_d,hand_t-hand_dn)
	elseif ray_pts>2 or hand_t>hand_d then
		hand_t=min(1,hand_t+hand_up)
	end
	
	if story==1 then
		sex=0
		sez=0
	else
		sex=round((ppx)/secr2)
		sez=round((ppz)/secr2)
	end
	
	for j=sez-3,sez+3 do
	for i=sex-3,sex+3 do
		local sec=get_sec(i,j)
		if sec!=nil then
			for k in all(sec.ky)do
			update_key(k)
			end
		end
	end end
	
	for k in all(keys)do
		k.x=ppx
		k.z=ppz
		
		if hand_t==1 and 
					act_sp!=nil and
					act_sp.lock_n==k.key_n then
			k.t=min(1,k.t+0.001)
		else
			k.t=max(0,k.t-0.01)
		end
		
		k.ya+=max(0.01,k.t)
		k.pi+=max(0.01,k.t)
		k.ro+=mid(0.01,k.t,1)/2
	end
	
	if story==0 then
		update_story_0()
	elseif story==1 then
		update_hell()
	end
end

function update_key(p)
	p.ya+=0.01
	p.pi+=0.01 
	p.ro+=0.01
end

function update_story_0()
	act_sp=nil
	for j=lock_j-1,lock_j+1 do
		local s=lvl[j][lock_i].sp[1]
		if dist(ppx,ppz,s.x+10,s.z)<20 then
			alert=s.lock_n
			act_sp=s
		end
	end
end

function update_hell()
	for s in all(lvl[0][0].sp)do
		local a=atan2(s.x,s.z,0,0)
		s.x-=cos(a)*sp_hs
		s.z-=sin(a)*sp_hs
	end
	
	for s in all(lvl[0][0].sh)do
		local a=atan2(s.x,s.z,0,0)
		s.x-=cos(a)*sp_hs
		s.z-=sin(a)*sp_hs
	end
end
-->8
-- pov

function proj_spr(s)
	n_o_proj+=1
	local px,py,dz=proj(
		s.x,s.y,s.z)
	if px<0 or px>127 or
				py<0 or py>127 then
		dz=0
	end
	sort_itm({
		draw=s.tris,
		pts={{x=px,y=py}},
		data=s,
		dz=dz
	})
end

--[[
sorting all of the symbol tris
is causing a huge slow down.
it should be possible to project
the symbol tris all at once
]]--

function proj_obj(o,f)
	n_o_proj+=1
	local ts={}
	//local dz_max_all=-1
	//local flat_max=-1
	//loga({#o.tris})
	for t in all(o.tris)do
		local pts={} --projected pts
		local dz_max=-1
		for p in all(t.pts) do
			x,y,z=rot3d(
				p.x,
				p.y,
				p.z,
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
			if(not on_scr_y(py))dz=0 
			dz_max=max(dz_max,dz)
			//loga({dz_max})
			add(pts,{x=px,y=py})
		end
		
		local i=1
		while i<=#ts+1 do
			if i>#ts or
						dz_max>ts[i].dz then
				//loga({dz_max})
				add(ts,{
					pts=pts,
					col=t.c,
					dz=dz_max
				},i)
				i=#ts+2
			end
			i+=1
		end
	end
	
	//printh(#ts)
	
	--[[
	todo:
	change f to be a number of
	faces to render. at farther
	distances render less faces
	]]--

	//f=false
	local imin=1
	if(f)imin=#ts-1
	for i=max(1,imin),#ts do
		//local t=ts[i]
		sort_itm(ts[i])
	end
end

function sort_itm(itm)
	//loga({itm.dz})
	if itm.dz>1 then
		n_t_sorted+=1
	
		//local newn={
		//	tri=tt,
		//	col=col,
		//	dz=dz,
		//	nxt=nil,
		//	prv=nil
		//}
		itm.nxt=nil
		itm.prv=nil
		
		//n_t_sort+=1
		if t_sorted_ll==nil then
			t_sorted_ll=itm
			return
		end
		
		local node=t_sorted_ll
		while node!=nil do
			//i+=1
			if itm.dz>node.dz then
				if node.prv then
					node.prv.nxt=itm
				else
					t_sorted_ll=itm
				end
				itm.prv=node.prv
				itm.nxt=node
				node.prv=itm
				return
			end
			if node.nxt==nil then
				node.nxt=itm
				itm.prv=node
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

function draw_sorted()
	n_t_sorted_d=0
	local node=t_sorted_ll
	while node!=nil do
		
		if type(node.draw)=="function" then
			//draw_sprite(t)
			node.draw(node)
		else
			n_t_sorted_d+=1
			draw_tri(
				node.pts,
				node.col,
				node.dz
			)
		end
		node=node.nxt
	end
end

--[[
function draw_sorted()
	//sortdz(t_sorted)
	tsa=0
	for t in all(t_sorted)do
		if type(t[1])=="function" then
			//draw_sprite(t)
			t[1](t)
		elseif t[#t-1]=="flat" then
			loga({"xxx",#t})
			for i=1,#t-2 do
				//loga({"here",type(tf)})
				//
				local tf=t[i]
				loga({#tf[1],type(tf[2])})
				draw_tri(tf[1],tf[2][1],nil)
			end
		else
			tsa+=1
			draw_tri(t,t[4][1],t[4][2])
			//print(
			//	t[1],
			//	t[3][1],
			//	t[3][2],
			//	tsa%2==0 and 8 or 11)
		end
	end
end
]]--

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

dz_cols={1,13,15}
function draw_tri(t,c,dz)
	local ddz=min(ceil(dz/250),4)
	if c<0 then
		if story==1 then
			if(c==-5)c=8
			if(c==-6)c=2
		else
			if(c==-5)c=1
			if(c==-6)c=0
			if ddz>1 then
				c=dz_cols[ddz-1]
			end
		end
	end
	
	pelogen_tri_hvb(
	 t[1].x,t[1].y,
	 t[2].x,t[2].y,
	 t[3].x,t[3].y,
	 c,
	 ddz)
end

function pelogen_tri_hvb(l,t,c,m,r,b,col,ddz)
	color(col)
	local a=rectfill
	::_w_::
	if(t>m)l,t,c,m=c,m,l,t
	if(m>b)c,m,r,b=r,b,c,m
	if(t>m)l,t,c,m=c,m,l,t

	local q,p=l,c
	if (q<c) q=c
	if (q<r) q=r
	if (p>l) p=l
	if (p>r) p=r
	if b-t>q-p then
		l,t,c,m,r,b,col=t,l,m,c,b,r
		goto _w_
	end

	local e,j,i=l,(r-l)/(b-t)
	while m do
		i=(c-l)/(m-t)
		local f=m\1-1
		f=f>127 and 127 or f
		if(t<0)t,l,e=0,l-i*t,b and e-j*t or e
		if col then
			for t=t\1,f do
				a(l,t,e,t)
				l=i+l
				e=j+e
			end
		else
			for t=t\1,f,1 do
				a(t,l,t,e)
				l=i+l
				e=j+e
			end
		end
		l,t,m,c,b=c,m,b,r
	end
	--[[
	if i<8 and i>-8 then
		if col then
			pset(r,t)
		else
			pset(t,r)
		end
	end
	]]--
end
-->8
-- player

function update_cam()
	//if mode!=0 then
	//	return
	//end
	cam_ya=-pp_ya
	cam_pi=pp_pi
	
	dcy,dcz=rot2d(
		cam_h,cam_d,-cam_pi)
	dcz,dcx=rot2d(
		dcz,0,-cam_ya)
	
	camz=ppz+dcz
	camx=ppx+dcx
	camy=ppy+dcy
end

function update_player()
	
	
	local ppv,ppvs=0,0
	if btn(🅾️) then
		if btn(⬇️) then
			pp_pi=max(-0.20,pp_pi-0.01)
		elseif btn(⬆️) then
			pp_pi=min(0.20,pp_pi+0.01)
		end
	elseif ppy==-8 then
		pp_pi=0
		if(btn(⬇️))ppv=1
		if(btn(⬆️))ppv=-1
	end
	
	if btn(❎) then
		if ppy==-8 then
			if(btn(➡️))ppvs-=0.5
			if(btn(⬅️))ppvs+=0.5
		end
	else
		if(btn(➡️))pp_ya-=0.01
		if(btn(⬅️))pp_ya+=0.01
		pp_ya=pp_ya%1
	end
	
	if ppy<-8 then
		ppy+=1
	end
	
	dx,dy,dz=rot3d(
		ppvs,0,ppv,
		pp_pi,
		pp_ya,
		0)
	
	dx*=2
	dz*=2
	
	-- walk sfx
	if ppv!=0 or ppvs!=0 then
		if walt==0 then
			sfx(
				4,
				-1,
				rand(0,3)*8,
				4)
		end
		walt=(walt+1)%20
	else
		walt=0
	end
	
	local touch_r=false
	local po={x=ppx,z=ppz,w=8,d=8}
	local can_x,can_z=true,true
	
	for j=sez-1,sez+1 do
	for i=sex-1,sex+1 do
		local sec=get_sec(i,j)
		if sec==nil then
			goto update_continue
		end
		
		-- check spike collision
		for o in all(sec.sp)do
			if(col_bb(po,o,-dx,0))can_x=false
			if(col_bb(po,o,0,-dz))can_z=false
		end
		
		-- check radiation
		for r in all(sec.rs)do
			local d=dist(ppx,ppz,r.x,r.z)
			if d<=r.r then
				touch_r=true
				pp_rp+=((r.r-d)/r.r)*rp1_us
			end
		end
		
		-- check term
		--[[
		for t in all(sec.tr)do
			local d=dist(ppx,ppz,t.x,t.z)
			if d<15 do
				alert="❎ interact"
				if btnp(❎) then
					cur_term=t
					mode=cur_term.mode
					init_term()
				end
			end
		end
		]]--
		
		-- check keys
		for k in all(sec.ky)do
			local d=dist(ppx,ppz,k.x,k.z)
			if d<5 do
				//init_story_1()
				add(keys,k)
				del(sec.ky,k)
			end
		end
		
		::update_continue::
	end end
	//end end end
	
	if touch_r and pp_rp>=100 then
		pp_rp=100
		pp_rp2+=rp2_s
	elseif not touch_r then
		pp_rp=max(0,pp_rp-rp1_ds)
	end
	
	local rps=flr(pp_rp/10)
	local rps2=flr(rps/2)
	if pp_rp==0 or pp_rp2>=100 then
		sfx(-1,1)
		sfx(-1,2)
		if pp_rp2>=100 then
			sfx(24)
		end
	elseif rps!=rpso then
		loga({
			rps,
			rpso,
			rps+10,
			flr(rps/2)+18
		})
		sfx(rps+10,1)
		if rps>5 then
			sfx(rps2+18,2)
		else
			sfx(-1,2)
		end
	end	
	
	rpso=rps
	
	if(can_x)ppx-=dx
	if(can_z)ppz-=dz
	//ppy-=dy
end

function update_dead()
	if pdt<8 then
		pdt+=0.1
	end
	ppy=-8+pdt
	
	if pdd==0 then
		if(btnp(❎))pdd=-1
	elseif pdd<-30 then
		init_story_0()
	else
		pdd-=1
	end
end
-->8
-- helpers

function obj(tris,x,y,z,ya,pi,ro,w,d,up)
	//if type
	local tt=nil
	if type(tris)=="function" then
		tt=tris
	else
		tt=read_tris(tris)
	end
	
	local o={
		tris=tt,
		x=x,y=y,z=z,
		ya=ya,pi=pi,ro=ro,
		w=w,d=d, --width/depth
		scrx=-1,scry=-1,
		update=up
	}
	return o
end

function read_tris(tr)
	local out={}
	for t in all(tr)do //evry tri
		//local tt={pts={},c=t[4]}
		local pts={}
		for pi=1,3 do //evry pt
			//local pt={}
			local sp=split(t[pi],",")
				//pt.x=sp[1]
				//pt.y=sp[2]
				//pt.z=sp[3]
			//loga({sp[1]})
			add(pts,{
				x=sp[1],
				y=sp[2],
				z=sp[3]
			})
		end
		add(out,{
			pts=pts,
			c=t[4]
		})
	end
	
	return out
end

function nsec()
	return {
		sp={},
		sh={},
		rs={},
		ky={},
		//sy={},
		//tr={}
	}
end

function get_sec(i,j)
	if lvl[j] and lvl[j][i] then
		return lvl[j][i]
	end
	
	return nil
end

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function round(n)
	if n-flr(n)>=0.5 then
		return flr(n)+1
	end
	return flr(n)
end

function col_bb(a,b,aox,aoz)
	local ax=(a.x+aox)-a.w/2
	local az=(a.z+aoz)-a.d/2
	local bx=(b.x)-b.w/2
	local bz=(b.z)-b.d/2
	
	return ax<=bx+b.w and
								ax+a.w>=bx and 
								az<=bz+b.d and
								az+a.d>=bz
end

function on_scr_x(x)
	return x>-20 and 
								x<148 
end

function on_scr_y(y)
	return y>-50 and 
								y<178
end

function on_scr(x,y)
	return on_scr_x(x) and 
								on_scr_y(y)
end

function dist(x1,y1,x2,y2)
 local a0,b0=abs(x1-x2),abs(y1-y2)
 return max(a0,b0)*0.9609+min(a0,b0)*0.3984
end

function p_to_s(x,y,z)
	return ""..x..","..y..","..z
end

--debug functions
--todo remove
function a_to_s(arr)
	local s=tostr(arr[1])
	for i=2,#arr do
		s=s.." "..tostr(arr[i])
	end
	return s
end

function loga(arr)
	printh(a_to_s(arr))
end

function pria(arr,x,y,c)
	print(a_to_s(arr),x,y,c)
end

function dtb2(num)
	local n1=num
	local n2=num
 local bin=""
	
	n2<<=1
	for i=1,16 do
  bin=n2 %2\1 ..bin
  n2<<=1
  if i%4==0 and i<32 then
   bin=" "..bin
  end
	end
	
	for i=1,16 do
  bin=n1 %2\1 ..bin
  n1>>>=1
  if i%4==0 and i<32 then
   bin=" "..bin
  end
	end
 
 return bin
end
-->8
-- models

hand_tris={
	{ --arm 1
		"-1.5,2.5,0",
		"-1.5,8,0",
		"1.5,2.5,0"
	},
	{ --arm 2
		"1.5,2.5,0",
		"-1.5,8,0",
		"1.5,8,0"
	},
	{ --palm 1
		"-2,0,0",
		"2,0,0",
		"-1.5,2.5,0"
	},
	{ --palm 2
		"2,0,0",
		"1.5,2.5,0",
		"-1.5,2.5,0"
	},
	{ --thumb 1
		"-1.5,2.5,0",
		"-1.5,1,0",
		"-2.5,-1,0"
	},
	{ --thumb 2
		"-1.5,2.5,0",
		"-2.5,-1.5,0",
		"-2.8,0.5,0"
	},
	{ --index 1
		"-2,0,0",
		"-2.2,-2,0",
		"-1.2,-2,0"
	},
	{ --index 2
		"-2,0,0",
		"-1.2,-2,0",
		"-1.2,0,0"
	},
	{ --index 3
		"-2.2,-2,0",
		"-1.2,-2,0",
		"-1.7,-4.5,1"
	},
	{ --middle 1
		"-1,0,0",
		"-1,-2,0",
		"0,-2,0"
	},
	{ --middle 2
		"-1,0,0",
		"0,-2,0",
		"0,0,0"
	},
	{ --middle 3
		"-0.5,-4.5,0",
		"-1,-2,0",
		"0,-2,0"
	},
	{ --ring 1
		"0,0,0",
		"0.2,-1.8,0",
		"1,-1.8,0"
	},
	{ --ring 2
		"0,0,0",
		"1,-1.8,0",
		"1,0,0"
	},
	{ --ring 3
		"0.6,-4.2,0",
		"0.2,-1.8,0",
		"1,-1.8,0"
	},
	{ --pinky 1
		"1,0,0",
		"1.2,-1.6,0",
		"2,-1.6,0"
	},
	{ --pinky 2
		"1,0,0",
		"2,-1.6,0",
		"2,0,0"
	},
	{ --pinky 3
		"1.5,-3,0",
		"1.2,-1.6,0",
		"2,-1.6,0"
	},
}

pyr_tris={
	{
		"-1,-1,1",
		"0,-1,-1",
		"1,-1,1",
		8
	},
	{
		"-1,-1,1",
		"0,-1,-1",
		"0,1,0",
		2
	},
	{
		"0,-1,-1",
		"1,-1,1",
		"0,1,0",
		14
	},
	{
		"-1,-1,1",
		"1,-1,1",
		"0,1,0",
		8
	},
}

function spike(x,z,s_num,dr,h,r)
	rx,rz=rand(-40,40),rand(-40,40)
	h=(h==nil and -100 or h)
	r=(r==nil and 10 or r)
	
	
	local s=nil
	if s_num>-1 then
		if(dr==nil)dr=rand(1,4)
		local sya=0
		if(dr==1)rx,rz,sya=-10,0,-0.25
		if(dr==2)rx,rz,sya=10,0,0.25
		if(dr==3)rx,rz=0,-10
		if(dr==4)rx,rz,sya=0,10,0.5
		if(dr==5)rx,rz=0,0
		
		local sxo,szo=0,0
		if dr<3 then
			sxo=2*sgn(rx)
		else
			szo=2*sgn(rz)
		end
		
		s=symb(
			x+rx+sxo,-30,z+rz+szo,s_num,9)
		s.ya=sya
	end
	
	local sp_tris={
		{ -- west face
			"-1,0,-1",
			"-1,0,1",
			p_to_s(rx-0.1,h,rz),
			-5 //1
		},
		{ -- east face
			"1,0,1",
			"1,0,-1",
			p_to_s(rx+0.1,h,rz),
			-6 //0
		},
		{ -- north face
			"1,0,-1",
			"-1,0,-1",
			p_to_s(rx,h,rz-0.1),
			-6 //0
		},
		{ --south face
			"-1,0,1",
			"1,0,1",
			p_to_s(rx,h,rz+0.1),
			-5 //1
		}
	}
	local sh_tris={
		{
			p_to_s(h,0,-r),
			p_to_s(h,0,r),
			p_to_s(-h,0,0),
			5
		}
	}
	
	local o_sp=obj(
		sp_tris,
		x,0,z,
		0,0,0,
		20,20,
		nil
	)
	
	--hack to save tokens
	for t in all(o_sp.tris) do
		for i=1,2 do
			t.pts[i].x*=r
			t.pts[i].z*=r
		end	
	end
	
	local o_sh=obj(
		sh_tris,
		x-h,0,z,
		0,0,0,
		0,0,
		nil
	)
	return o_sp,o_sh,s
end

function draw_sun(s)
	circfill(
		s.pts[1].x,
		s.pts[1].y,
		10,
		9
	)
end

function symb(x,y,z,n,col)
	local tris={}
	for c=1,min(n,4) do
		add(
			tris,
			symb_tri(
				-0.25*c+0.25,
				false,
				col
			)
		)
	end
	
	if n>4 then
	for c=1,4 do
		add(
			tris,
			symb_tri(
				-0.25*c+0.125,
				n>=c+5,
				col
			)
		)
	end end
	
	local o=obj(
		tris,
		x,y,z,
		0,0,0,
		0,0,
		nil
	)
	return o
end

function symb_tri(a,l,col)
	local dat={
		{-1,-4},
		{1,-4},
		{0,l and 0 or -2},
		//{col,nil}
	}
	local tri={}
	for i=1,3 do
		local x,y=rot2d(
			dat[i][1],dat[i][2],a
		)
		//tri[i][1]=x
		//tri[i][2]=y
		add(tri,""..x..","..y..",0")
	end
	add(tri,col)
	return tri
end

function pyr(x,z)
	local o_pyr=obj(
		pyr_tris,
		x,-5,z,
		0,0,0,
		5,5,
		nil
	)
	return o_pyr
end

--[[
function add_st_area(ci,cj)
	local secs={}
	secs[0]={}
	secs[0][0]={
		sp={},sh={},rs={},sy={},tr={}
	}
	local ansrs={
		rand(1,9),
		rand(1,9),
		rand(1,9),
	}
	local sps={
		{-30,0,ansrs[1],3},
		{0,20,ansrs[2],3},
		{30,0,ansrs[3],3},
		//{60,0,4,3},
	}
	
	local sec={
		sp={},sh={},rs={},sy={},tr={}
	}
	local x=ci*secr2
	local z=cj*secr2
	for pt in all(sps)do
		local rx=pt[1]+x
		local rz=pt[2]+z
		//local symb_n=pt[3]
		local sp,sh,sy=spike(
			rx,rz,pt[3],pt[4])
		add(sec.sp,sp)
		add(sec.sh,sh)
		add(sec.sy,sy)
	end
	local term,t_sh=term(x,z)
	term.ansrs=ansrs
	term.inpt={3,3,3}
	term.mode=1
	add(sec.tr,term)
	add(sec.sh,t_sh)
	
	lvl[cj]={}
	lvl[cj][ci]=sec
end
]]--

--[[
function add_cn_area(ci,cj)
	local x=ci*secr2
	local z=cj*secr2
	
	local sec={
		sp={},sh={},rs={},sy={},tr={}
	}
	local term2,t_sh2=term(x-20,z)
	term2.mode=2
	add(sec.tr,term2)
	add(sec.sh,t_sh2)
	
	local term3,t_sh3=term(x,z)
	term3.mode=3
	add(sec.tr,term3)
	add(sec.sh,t_sh3)

	lvl[cj]={}
	lvl[cj][ci]=sec
end
]]--

function add_me_area(ci,cj,r)
	local imin,imax=ci-r,ci+r
	local jmin,jmax=cj-r,cj+r
	
	local symbs={}
	--temp, key goes in center
	symbs[0]={i=ci,j=cj,n=-1}
	
	for k=1,3 do
		ri,rj=free_sec(
			symbs,
			imin,imax,
			jmin,jmax
		)
		symbs[k]={
			i=ri,
			j=rj,
			n=rand(1,9)
		}
		
		--[[		
		loga({
			"symb",
			symbs[k].i,
			symbs[k].j,
			symbs[k].n,
		})
		]]--
	end
	
	--[[
	ti,tj=free_sec(
		symbs,
		imin,imax,
		jmin,jmax
	)
	loga({"term",ti,tj})
	]]--
	
	
	for j=jmin,jmax do
		for i=imin,imax do
			local sec=nsec()
			
			local symb_n=-1
			for sm in all(symbs)do
				if j==sm.j and i==sm.i then
					symb_n=sm.n
				end
			end
		
			local sx=i*secr2
			local sy=j*secr2
			local rx=rand(-secr,secr)+sx
			local rz=rand(-secr,secr)+sy
			
			--[[
			if j==tj and i==ti then
				local term,t_sh=term(rx,rz)
				term.ansrs={}
				term.inpt={3,3,3}
				term.mode=1
				for s in all(symbs)do
					add(term.ansrs,s.n)
				end
				add(sec.tr,term)
				add(sec.sh,t_sh)
			]]--
			if j==cj and i==ci then
				local o_key=obj(
					pyr_tris,
					rx,-5,rz,
					0,0,0,
					5,5,
					nil
				)
				o_key.key_n=1
				o_key.t=0
				add(sec.ky,o_key)
			else
				local sp,sh,sy=spike(rx,rz,symb_n)
				add(sec.sp,sp)
				add(sec.sh,sh)
				//add(sec.sy,sy)
			end
			
			--add radiation
			//local nrs=rand(1,3)
			//for k=1,nrs do
			//temp removed for test
			--[[
				add(secs[j][i].rs,
					{
						x=rand(0,secsz)+i*secsz,
						z=rand(0,secsz)+j*secsz,
						r=rand(20,30)
					})
				]]--
			//end
			if true then
				add(sec.rs,{
					x=rx,z=rz,
					r=rand(20,30)
				})
			end
			
			if(lvl[j]==nil)lvl[j]={}
			lvl[j][i]=sec
			//loga({"adding",i,j})
		end
	end
end

function add_me_sp(i,j)
	local sx=i*secr2
	local sy=j*secr2
	local rx=rand(-secr,secr)+sx
	local rz=rand(-secr,secr)+sy
	local sec=nsec()
	local sp,sh,sy=spike(rx,rz,0,5)
	add(sec.sp,sp)
	add(sec.sh,sh)
	add(sec.rs,{
		x=rx,z=rz,
		r=rand(20,30)
	})
	if(lvl[j]==nil)lvl[j]={}
	lvl[j][i]=sec
end

function add_lk_area(ci,cj)
	lock_i=ci
	lock_j=cj
	
	local secs={{-1,0},{0,0},{1,0}}
	for c=1,3 do
		local s=secs[c]
		local j,i=s[1]+cj,s[2]+ci
		local sec=nsec()
		local sp,sh,sy=spike(
			i*secr2,j*secr2,0,5,-10,2)
		sp.lock_n=lock_ord[c]
		add(sec.sp,sp)
		add(sec.sh,sh)
		add(sec.sy,sy)
		lvl[j]={}
		lvl[j][i]=sec
	end
end

function add_hell_area()
	local sec=nsec()
	
	for i=0,29 do
		local a=i/30
		local sx,sz=cos(a),sin(a)
		local sp,sh,sy=spike(
			sx*secr2*sp_hd,
			sz*secr2*sp_hd,
			0,
			5)
		add(sec.sp,sp)
		add(sec.sh,sh)
		add(sec.sy,sy)
	end
	
	lvl[0]={}
	lvl[0][0]=sec
end

function free_sec(arr,imin,imax,jmin,jmax)
	local f=true
	while f do
	local ri=rand(imin,imax)
	local rj=rand(jmin,jmax)
		f=false
		for o in all(arr) do
			if o.i==ri and o.j==rj then
				f=true
			end
		end
		
		if not f then
			return ri,rj
		end
	end
end

-->8
-- old temp delete

-- terminals

--[[
cur_term=nil
t_idx_x=0 	--term idx left/right
t_idx_y=-1 --term idx up/down
t_pr_t=0 --term press time
]]--

--[[
function draw_term1()
	cls(1)
	camera(0,0)
	//spr(41,60,60,2,2)
	srand(cur_term.seed)
	//fillp(0b0011001111001100)
	  //fillp(0b1111000000000000)
	rectfill(10,10,117,50,0)
	//fillp()
	
	for j=0,4 do
	for i=0,1 do
		s=rand(0,3)
		spr(
			86+s,
			2+i*116,
			13+j*8,
			1,1,
			i==1)
	end
	end
	
	for j=0,1 do
	for i=0,1 do
		s=rand(0,3)
		spr(
			66+s,
			5+110*i,
			5+43*j,
			1,1,
			i==1,j==1)
		s=rand(0,3)
		spr(70+s,5+111*i,5+44*j)
	end end
	
	for j=0,1 do
	for i=0,12 do
		s=rand(0,3)
		spr(
			82+s,
			13+i*8,
			5+43*j,
			1,1,
			false,j==1)
	end end
	
	local s //idk if this is really necessary, but it makes me feel better
	for i=-1,1 do
		for j=0,1 do	
			for ii=0,1 do
				--top corners
				s=rand(0,3)
				spr(66+s,
					52+34*i+16*ii,
					60+23*j,
					1,1,
					ii==1)
				
				--top screws
				s=rand(0,3)
				spr(70+s,
					52+34*i+17*ii,
					60+23*j)
			end
		
			--top button metal
			s=rand(0,3)
			spr(82+s,
				60+34*i,
				60+23*j)
		
			--side button metal
			rectfill(
				52+34*i,68+22*j,
				75+34*i,70+23*j,
				5)
			
			local off=0
			if i==t_idx_x and
						(
							(j==0 and t_idx_y==-1) or
							(j==1 and t_idx_y==1)
						)then
				off=(1-abs(t_pr_t-5)/5)*2
			end
			
			--button
			spr(
				64+32*j,
				56+34*i,
				60+23*j+off,
				2,2)
			
			for ii=0,1 do
				--bottom corner
				s=rand(0,3)
				spr(66+s,
					52+34*i+16*ii,
					71+23*j,
					1,1,
					ii==1,
					true)
				--bottom screws
				s=rand(0,3)
				spr(70+s,
					52+34*i+17*ii,
					72+23*j)
			end
			
			--bottom metal
			s=rand(0,3)
			spr(82+s,
				60+34*i,
				71+23*j,
				1,1,
				false,true)
		end
		
		local s=cur_term.inpt[i+2]
		local o=symb(10*i,-10,40,s,3)
		proj_obj(
			o,
			false
		)
	end
	
	for i=0,2 do
		s=rand(0,3)
		spr(86+s,5,67+i*8)
		s=rand(0,3)
		spr(86+s,4,67+i*8,1,1,true)
	end
	
	local actv=true
	for i=1,#cur_term.inpt do
		local inpt=cur_term.inpt[i]
		local ansr=cur_term.ansrs[i]
		if(inpt!=ansr)actv=false
	end
	spr(100,4,62,2,1)
	spr(70,5,62)
	spr(
		not actv and t_crt_t<15 and 114 or 115,
		5,70)
	spr(
		actv and t_crt_t<15 and 98 or 99,
		5,81)
	spr(100,4,88,2,1,false,true)
	spr(70,5,89)
	
	
	proj_obj(hand,false)
	
	//draw_sorted()
	
	--scan lines
	for l in all(t_crt_l)do
		//line(10,l.y+10,117,l.y+10,6)
		for i=10,117 do
		for j=-1,1do
			local c=pget(i,l.y+10+j)
			if c!=0 then
				pset(i-2,l.y+10+j,c)
			end
		end end
	end
	srand(time())
end

function draw_term2()
	cls(1)
	camera(0,0)
	//spr(41,60,60,2,2)
	srand(cur_term.seed)
	
	circ(64,64,5,7)
	
	spr(99,64,5)
	spr(114,72,5)
	line(64,15,64,57,5)
	
	
	srand(time())
end

function draw_term3()
	cls(1)
	camera(0,0)
	//spr(41,60,60,2,2)
	srand(cur_term.seed)
	
	for i=0,3 do
		spr(101,5,20+i*10)
		rect(
			5,20+i*10,12,28+i*10,7)
		spr(101,5,20+i*10)
	end
	
	//these represent tries.
	//if the player guesses
	//incorrect, a light goes out.
	//if all go out game over.
	
	spr(98,120,20)
	for i=1,2 do
		spr(101,120,20+i*10)
		spr(114,120,20+(i+2)*10)
	end
	
	
	srand(time())
end
]]--

--[[
function update_term2()
	if(btnp(🅾️))mode=0
end

function update_term3()
	if(btnp(🅾️))mode=0
end
]]--

--[[
function init_term()
	t_crt_t=0
	t_crt_l={}
	
	cam_ya=0
	cam_pi=0
	
	//dcy,dcz=rot2d(
	//	cam_h,cam_d,-cam_pi)
	//dcz,dcx=rot2d(
	//	dcz,0,-cam_ya)
	
	camz=0
	camx=0
	camy=0
	
	hand.ro=0.1
	hand.ya=0.05
	hand.pi=0.05
end
]]--

--[[
function update_term1()
	//cam_ya=0
	//cam_pi=0
	
	////dcy,dcz=rot2d(
	////	cam_h,cam_d,-cam_pi)
	////dcz,dcx=rot2d(
	////	dcz,0,-cam_ya)
	
	//camz=0
	//camx=0
	//camy=0
	//
	//hand.ro=0.1
	//hand.ya=0.05
	//hand.pi=0.05
	
	
	if(btnp(🅾️))mode=0
	if btnp(⬅️) then
		t_idx_x=max(-1,t_idx_x-1)	
	elseif btnp(➡️) then
		t_idx_x=min(1,t_idx_x+1)
	end
	
	if btnp(⬆️) then
		t_idx_y=-1
	elseif btnp(⬇️) then
		t_idx_y=1
	end
	
	if btnp(❎) then
		t_pr_t=10
		local val=cur_term.inpt[t_idx_x+2]
		val=mid(
			1,
			9,
			val+t_idx_y)
		cur_term.inpt[t_idx_x+2]=val
	end
	
	if t_pr_t>0 then
		t_pr_t-=1
	end
	
	hand.x=2.7*t_idx_x+4.2
	local off=1-abs(t_pr_t-5)/5
	hand.y=t_idx_y+3+0.5*off
	
	--scan lines
	if t_crt_t==0 then
		if rnd()>0.2 then
			local s=rnd(0.3)+0.5
			add(t_crt_l,{y=0,s=s})
		end
		t_crt_t=30
	else
		t_crt_t-=1
	end
	
	for l in all(t_crt_l)do
		l.y+=l.s
		if l.y>35 then
			del(t_crt_l,l)
		end
	end
end
]]--

--[[
function term(x,z)
	local t_tris={
		{--scr 1
			"-2,-4,-5",
			"2,-4,-5",
			"2,-8,-5",
			2
		},
		{--scr 2
			"-2,-4,-5",
			"-2,-8,-5",
			"2,-8,-5",
			2
		},
		{--front 1
			"-4,0,-4",
			"4,0,-4",
			"4,-10,-4",
			1
		},
		{--front 2
			"-4,0,-4",
			"-4,-10,-4",
			"4,-10,-4",
			1
		},
		{--back 1
			"-4,0,4",
			"4,0,4",
			"4,-10,4",
			13
		},
		{--back 2
			"-4,0,4",
			"-4,-10,4",
			"4,-10,4",
			13
		},
		{--left 1
			"-4,0,-4",
			"-4,0,4",
			"-4,-10,-4",
			13
		},
		{--left 2
			"-4,0,4",
			"-4,-10,4",
			"-4,-10,-4",
			13
		},
		{--right 1
			"4,0,-4",
			"4,0,4",
			"4,-10,-4",
			1
		},
		{--right 2
			"4,0,4",
			"4,-10,4",
			"4,-10,-4",
			1
		},
	}
	local sh_tri={
		{
			"-10,0,-4",
			"-10,0,4",
			"10,0,0",
			5
		}
	}
	local o_sh=obj(
		sh_tri,
		x+14,0,z,
		0,0,0,
		0,0,
		nilx
	)
	local o_term=obj(
		t_tris,
		x,0,z,
		0,0,0,
		5,5,
		nil
	)
	o_term.seed=rand(1,30000)
	return o_term,o_sh
end
]]--

--[[
//dz_mm=-30000
function pelogen_tri_old(l,t,c,m,r,b,col,dzz)
	//poke(0x5f34, 0x3)
	color(col)
	fillp(f)
	
	if(t>m) l,t,c,m=c,m,l,t
	if(t>b) l,t,r,b=r,b,l,t
	if(m>b) c,m,r,b=r,b,c,m
	local i,j,k,r=(c-l)/(m-t),(r-l)/(b-t),(r-c)/(b-m),l
	local cc=0
	while t~=b do
		//loga({
		//	ceil(t),
		//	min(flr(m),128),
		//	j,i
		//})
		for t=ceil(t),min(flr(m),128),dzz do
			rectfill(l,t,r,t)
			r+=j
			l+=i
		end
		l,t,m,i=c,m,b,k
	end
end
]]--

-- in _darw
--[[
	if mode==0 then
		draw_pov()
	elseif mode==1 then
		draw_term1()
	elseif mode==2 then
		draw_term2()
	elseif mode==3 then
		draw_term3()
	end
]]--
__gfx__
00000000009999000000000000000000000000000000005555500000000000555550000000000000000000000000000000000000000000000000000000000000
00000000090000900000000000000000000000000000555555550000000055555555000000009000000900000000000000000000000000000000900000090000
00700700900990090000000000000000000000000005555555555000000555555555500000099000000990000000000000000000000000000009900000099000
00077000909009090000000000000000000000000055555555555000005555555555500000999900009999000000000000000000000000000099990000999900
00077000909009090000000000000000000000000055550000000600005555000000060009999900009999900000006600000000000000000999990000999990
00700700900990900000000000000000000000000055500000000600005550000000060009999900009999900000000000000000000000000999990000999990
00000000090000000000000000000000000000000055000000000600005500000000060099999009900999990000000000000000000000009999900990099999
00000000009999900000000000000000000000000055066606660600005500600060060000000099990000000000000000000000000000000000009999000000
00000000000000000666666000000000000000000050006000600600005006660666060000000099990000000000000044444444444444440000009999000000
00000000000000006000000600000000000000000060000060000600006000006000060000000009900000000000000040000000000000040000000990000000
00000000000000006066066600000000000000000006600060006600000600000000060000000000000000000000000040009000000900040000000000000000
00000000000000006007007600000000000000000006060000060600000600066600060000000099990000000000000040099900009990040000009999000000
00000000000000006000000600000000000000000006006666600600000600600060060000000999999000000000000040099990099990040000099999900000
00000000000000000607777600000000000000000000600000006000000060666660600000009999999900000000000040099909909990040000999999990000
00000000000000000600000600000000000000000000600000006000000060000000600000009999999900000000000040000009900000040000999999990000
00000000000000000066666000000000000000000000066666660000000006666666000000000099990000000000000040000000000000040000009999000000
00010000000700000007000000070000000700000007000000070000000700000007000000070000000700000000000040000009900000040000000000000000
01010100000000000000000000000000000000000700070007070700070707000707070007070700070007000000000040000099990000040000000000000000
00111000000700000007000000070000000700000007000000077000000770000007700000777000000000000000000040000099990000040000000000000000
11111110007770000077707000777070707770707077707077777770777777707777777077777770700000700000000040000000000000040000000000000000
00111000000700000007000000070000000700000007000000070000000770000077700000777000000000000000000044444444444444440000000000000000
01010100000000000000000000000000000000000700070007070700070707000707070007070700070007000000000000000000000000000000000000000000
00010000000000000000000000070000000700000007000000070000000700000007000000070000000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700000007000000070000000700000007000000070000000700000007000000070000000000000000770777700000000000000000700000000000
00000000000000000000000000000000000000000700070000000700000007000000070007000700000000000000007000070000000000000000070000000000
00070000007070000070700000707000007070000070700000707000007070000070700000707000000000000000070700007000000000000007007000000000
00707000000000000000007000000070700000707000007070000070700000707000007070000070000000000000070700007000000000000077007000000000
00070000007070000070700000707000007070000070700000707000007070000070700000707000000000007000070700000000000700007000007000000000
00000000000000000000000000000000000000000700070000000000000007000700070007000700000000007000070700007000000700000700070000000000
00000000000000000000000000070000000700000007000000070000000700000007000000070000000000000700007000000700007000000077700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077770770000077770000000000000000000000
00000000000000000055555500500555004555550055151500000000000000000000000000000000000000000000000000000000000000000000000000000000
0002222222222000055555550550555504555555055555550066d0000066d0000066d000004440000066d0000000000000000002200000000000000000000000
0022222222222200555555555555555555555555155555510661dd0006161d0006614d00041114000661dd000000000000000022220000000000000000000000
02222222222222205555555555555555455555554555555406111d000661dd0006141d000111110006111d000000000000555222222555000000000000000000
0222222ee2222220555555555555555545555454455555450661dd00061d1d0006414d000111110006611d000000000005552222222255500000000000000000
022222e22e2222205555555055555550555554405555555000ddd00000ddd00000dd40000011100000ddd0000000000055522222222225550000000000000000
02222e2222e222205555550005555500555544005555550000000000000000000000000000000000000000000000000055222222222222550000000000000000
0222e222222e22205555500050555000555440005545400000000000000000000000000000000000000000000000000052222222222222250000000000000000
0222eeeeeeee2220555555555055500555555555500050050005555500055555000555540005555500000000000000005dddddddddddddd50000000000000000
0222222222222220555555555555550555555555500555550005555500005555000555440005554400000000000000005dddddddddddddd50000000000000000
0d222222222222105555555555555555554554555555545500055555000505550005555500055514000000000000000005555555555555500000000000000000
0dd22222222221105555555555555555555454555555555400055555000555550005555500055551000000000000000000000000000000000000000000000000
00ddddd1d11d11005555555555555555454454445545545400055555000055550005544500055455000000000000000000000000000000000000000000000000
000dddd1d11d10000000000000000000000000000000000000055555000555550005555400055554000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055555000555550005555500055544000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055555000005550005554400055555000000000000000000000000000000000000000000000000
000000000000000000ddd00000ddd0000055555000ddd00000ddd000000000000000000000000000000000000000000002222222222222200000000000000000
00022222222220000dbbbd000d333d00055555550dcccd000d666d0000000000000000000000000000000000000000000d222222222222d00000000000000000
0022222222222200dbbbbbd0d33333d055555555dcccccd0d66666d000000000000000000000000000000000000000005dd2222222222dd50000000000000000
0222222222222220dbbb7bd0d33353d055555555dccc7cd0d66656d000000000000000000000000000000000000000005ddd22222222ddd50000000000000000
0222eeeeeeee2220dbb77bd0d33553d055555555dcc77cd0d66556d0000000000000000000000000000000000000000055ddd222222ddd550000000000000000
0222e222222e22200dbbbd000d333d00000000000dcccd000d666d000000000000000000000000000000000000000000555ddd2222ddd5550000000000000000
02222e2222e2222000ddd00000ddd0000000000000ddd00000ddd00000000000000000000000000000000000000000005555ddd22ddd55550000000000000000
022222e22e2222200000000000000000000000000000000000000000000000000000000000000000000000000000000055555dddddd555550000000000000000
0222222ee222222000ddd00000ddd0000000000000000000000000000000000000000000000000000000000000000000555555dddd5555550000000000000000
02222222222222200d888d000d222d0000000000000000000000000000000000000000000000000000000000000000000555555dd55555500000000000000000
0d22222222222210d88888d0d22222d0000000000000000000000000000000000000000000000000000000000000000000555555555555000000000000000000
0dd2222222222110d88878d0d22252d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddddd1d11d1100d88778d0d22552d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dddd1d11d10000d888d000d222d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000ddd00000ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
55775557555777775557577757577777555755577777555757575557555777775557777755575577555755577777555777775557577777777777777777777777
75775777775777775757577757577777577777577777775757577757775777775757777777577577575757577777575777775757577777777777777777777777
75775557755777775757555755577777555775577777755755577557755777775757777775577577555755577777575777775757555777777777777777777777
75777757775777775757575777577777775777577777775777577757775777775757777777577577775757577777575777775757575777777777777777777777
55575557555775775557555777577777555755577577555777575557555777775557757755575557775755577777555775775557555777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
75577557777775575757777755775557557777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
57775777777757775757777775777757757777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
55575777777757775557777775775557757777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77575777777757775757777775775777757777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
55777557777775575757777755575557555777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
75577557777755575577777755577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
57775777777757775757777777577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
55575777777755775757777775577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77575777777757775757777777577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
55777557777757775757777755577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
75577777555755575557777755577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
57577777575757577577777757577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
57577777555755777577777755577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
57577777577757577577777777577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
55777777577757575577777777577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
88777777888777777887777788878887777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
87877777787777778777777777878787777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
87877777787777778887777788878787777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
87877777787777777787777787778787777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
87877777787777778877777788878887777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777770777777777777777777777777777777777777777777777777777777777777777777777777777777
55777777555777775577777755575557777777777777777770777777777777777777777777777777777777777777777777777777777777777777777777777777
57577777757777775757777777575757777777777777777770777777777777777777777777777777777777777777777777777777777777777777777777777777
57577777757777775757777755575757777777777777777770777777777777777777777777777777777777777777777777777777777777777777777777777777
57577777757777775757777757775757777777777777777770777777777777777777777777777777777777777777777777777777777777777777777777777777
57577777757777775557777755575557777777777777777700777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777700177777777777777777777777777777777777777777777777777777777777777777777777777777
bbb77777bbb777777777777777777777777777777777777700177777777777777777777777777777777777777777777777777777777777777777777777777777
b7b77777b7b777777777777777777777777777777777777700177777777777777777777777777777777777777777777777777777777777777777777777777777
b7b77777b7b777777777777777777777777777777777777700177777777777777777777777777777777777777777777777777777777777777777777777777777
b7b77777b7b777777777777777777777777777777777777700177777777777777777777777777777777777777777777777777777777777777777777777777777
bbb77777bbb777777777777777777777777777777777777700177777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777000117777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777000117777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777000017777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777000017777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777000017777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777000017777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777000011777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777000011777770777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777770000011777770777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777770000011777770777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777770000011777770777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777770000011777770177777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777770000011177770177777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777770000011177770177777777777777777777777777777770777777777777777777777777777777777777
77777777777777777777777777777777777777777777770000011177770077777777777777777777777777777770777777777777777777777777777777777777
77777777777777777777777777777777777777777777770000011177770077777777777777777777777777777770777777777777777777777777777777777777
77777777777777777777777777777777777777777777700000011177770017777777777777777777777777777770777777777777777777777777777777777777
77777777777777777777777777777777777777777777700000001177770017777777777777777777777777777770777777777777777777777777777777777777
77777777777777777777777777777777777777777777700000001117770017777777777777777777777777777700777777777777777777777777777777777777
77777777777777777777777777777777777777777777700000001117770017777777777777777777777777777700777777777777777777777777777777777777
77777777777777777777777777777777777777777777700000001117770011777777777777777777777777777700777777777777777777777777777777777777
77777777777777777777777777777777777777777777700000001117770001777777777777777777777777777700777777777777777777777777777777777777
77777777777777777777777777777777777777777777700000001117770001777777777777777777777777777700177777777777777777777777777777777777
77777777777777777777777777777777777777777777000000001117770001777777777777777777777777777700177777777777777777777777777777777777
77777777777777777777777777777777777777777777000000001111770001177777777777777777777777777000177777777777777777777777777777777777
77777777777777777777777777777777777777777777000000001111770001177777777777777777777777777000177777777777777777777777777777777777
77777777777777777777777777777777777777777777000000001111770001177777777777777777777777777000177777777777777777777777777777777777
77777777777777777777777777777777777777777777000000001111770001177777777777777777777777777000177777777777777777777777777777777777
77777777777777777777777777777777777777777777000000001111770000177777777777777777777777777000177777777777777777777777777777777777
77777777777777777777777777777777777777777777000000001111700000117777777777777777777777770000177777777777777777777777777777777777
77777777777777777777777777777777777777777777000000001111100000117777777777777777777777770000177777777777777777777777777777777777
77777777777777777777777777777777777777777770000000001111100000117777777777777777777777770000117777777777777777777777777777777777
77777777777777777777777777777777777777777770000000000111100000117777777777777777777777770000117777777777777777777777777777777777
77777777777777777777777777777777777777777770000000000111100000111777777777777777777777770000017777777777777777777777777777777777
77777777777777777777777777777777777777777770000000000111100000011777777777777777777777770000017777777777777777777777777777777777
77777777777777777777777777777777777777777770000000000111100000011777777777777777777777700000017777777777777777777777777777777777
77777777777777777777777777777777777777777770000000000111110000011777777777777777777777700000017777777777777777777777777777777777
77777777777777777777777777777777777777777770000000000111110000011177777777777777777777700000017777777777777777777777777777777777
77777777777777777777777777777777777777777770000000000111110000011177777777777777777777700000017777777777777777777777777777777777
77777777777777777777777777777777777777777700000000000111110000011177777777777777777777700000017777777777777777777777777777777777
77777777777777777777777777777777777777777700000000000111110000011177777777777777777777700000011777777777777777777777777777777777
77777777777777777777777777777777777777777700000000000111110000001177777777777777777777000000011777777777777777777777777777777777
77777777777777777777777777777777777777777700000000000111111000001117777777777777777777000000011777777777777777777777777777777777
77777777777777777777777777777777777777777700000000000111111000001117777777777777777777000000011777777777777777777777777777777777
77777777777777777777777777777777777777777700000000000111111000001117777777777777777777000000011777777777777777777777777777777777
77777777777777777777777777777777777777777700000000000111111000001117777777777777777777000000011777777777777777777777777777777777
77777777777777777777777777777777777777777000000000000011111000001111777777777777777770000000011777777777777777777777777777777777
77777777777777777777777777777777777777777000000000000011111000001111777777777777777770000000011777777777777777777777777777777777
77777777777777777777777777777777777777777000000000000011111000000111777777777777777770000000011777777777777777777777777777777777
77777777777777777777777777777777777777777000000000000011111100000111777777777777777770000000011177777777777777777777777777777777
77777777777777777777777777777777777777777000000000000011111100000111177777777777777770000000011177777777777777777777777777777777
77777777777777777777777777777777777777777000990000000011111100000111177777777777777770000000011177777777777777777777777777777777
77777777777777777777777777777777777777777009090090000011111100000111177777777777777700000000011177777777777777777777777777777777
77777777777777777777777777777777777777777009090090000011111100000111177777777777777700000000011177777777777777777777777777777777
77777777777777777777777777777777777777770099090990000011111100000111177777777777777700000000001177777777777777777777777777777777
77777777777777777777777777777777777777770900000090000011111110000011117777777777777700000000001177777777777777777777777777777777
77777777777777777777777777777777777777770990000990000011111110000011117777777777777700000000001177777777777777777777777777777777
77777777777777777777777777777777777777770990000900000011111110000011117777777777777700000000001177777777777777777777777777777777
77777777777777777777777777777777777777770009090990000011111110000011117777777777777000000000001117777777777777777777777777777777
77777777777777777777777777777777777777770099090990000011111110000011111777777777777000000000001117777777777777777777777777777777
77777777777777777777777777777777777777770009090900000011111110000011111777777777777000000000001117777777777777777777777777777777
77777777777777777777777777777777777777770000900000000001111111000011111777777777777000000000001117777777777777777777777777777777
77777777777777777777777777777777777777700000000000000001111111000001111777777777777000000000001117777777777777777777777777777777
77777777777777777777777777777777777777700000000000000001111111000001111177777777770000000000001117777777777777777777777777777777
77777777777777777777777777777777777777700000000000000001111111000001111177777777770000000000001117777777777777777777777777777777
77777777777777777777777777777777777777700000000000000001111111000001111177777777770000000000001117777777777777777777777777777777
77777777777777777777777777777777777777700000000000000001111111000001111177777777770000000000001117777777777777777777777777777777
77777777777777777777777777777777777777700000000000000001111111100001111177777777770000000000001111777777777777777777777777777777
77777777777777777777777777777777777777700000000000000001111111100001111117777777770000000000001111777777777777777777777777777777
77777777777777777777777777777777777777000000000000000001111111100000111117777777700000000000001111777777777777777777777777777777
77777777777777777777777777777777777777000000000000000001111111100000111117777777700000000000001111777777777777777777777777777777
77777777777777777777777777777777777777000000000000000001111111100000111117777777700000000000001111777777777777777777777777777777
77777777777777777777777777777777777777000000000000000001111111100000111111777777700000000000001111777777777777777777777777777777
77777777777777777777777777777777777777000000000000000001111111110000111111777777700000000000001111777777777777777777777777777777
77777777777777777777777777777777777777000000000000000001111111110000111111777777700000000000001111777777777777777777777777777777
77777777777777777777777777777777777777000000000000000001111111110000011111777777000000000000001111777777777777777777777777777777
77777777777777777777777777777777777777000000000000000000111111110000011111177777000000000000001111177777777777777777777777777777
77777777777777777777777777777777777770000000000000000000111111110000011111177777000000000000001111177777777777777777777777777777
fffffffffffffffffffffffffffffffffffff00000000000000000001111111100000111111fffff0000000000000011111fffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffff00000000000000000001111111110000111111fffff0000000000000011111fffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffff000000000000000000011111111100001111111fff00000000000000011111fffffffffffffffffffffffffffff

__sfx__
0b1000000017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170
930c00003f65500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
934000003f65500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
900600003e6453e645000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9005000023624236302d6302d6253960039600000000000021624216302b6302b625376000000000000000001f6241f6302d6302d625000000000000000000001d6241d6302b6302b62500000000000000000000
950c00002321423220232302324023250232502325023250232502325023250232502324023230232202321023210232102321023210232102321023210232102321023210232102321523200232002320023200
150c00000a8000a8000a8000a80009844098400985009850098600986009860098600986009860098600986009850098500984009840098300983009820098200981009810098100981009810098100981009815
900c00010062000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
910c00000060000600006000060000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000610006100061000615
5d0c00001c0001c0001c0001c00010014100201002010020100201002010020100201002010020100201001010010100101001010010100101001010010100101001010010100101001510000100002300023000
010c00000785007850078500785007840078400784007840078300782007820078200781007810078100781509800098000980009800098000980009800098000980009800098000980009800098000980009800
0d0c00010582010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010682010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010883010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010983010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010b84010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010c84010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010d85010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
150c00010d85010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
150c00010d86010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
150c00010d86010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
ad0c00010b22523200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200
ad0c00010b24523200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200
ad0c00011726523200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200
4509000016860168611586114861138611286111861108610f8610e8610d8610c8610b8510a851098510885107841068410584104841038310283202822028220281202812028120281202812028120281202815
0512001c0c8400c8400c8300c8200c8150c8000c8300c8300c8200c8100c8100c8100c8150c8000c8300c8300c8200c8100c8150c8000c8000c8000c8200c8200c8100c8100c8150c80009800098000980000000
93121c000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000061400610006100061009800098000980000000
93121c000061000610006100061000610006100061000610006100061000610006100061000610006100061000610006100061000610006100061000610006100061000610006100061009800098000980000000
a51200010005007000070000700007000070000700007000162001620016200162001620016200162001620016200162001620016200162001620016200162001720017200172001720017200092000920009200
93121c000061000610006100061500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060009800098000980000000
0512001c0c8000c8000c8400c8400c8300c8200c8150c8000c8300c8300c8200c8100c8100c8100c8150c8000c8300c8300c8200c8100c8150c8000c8000c8000c8000c8000c8000c80009800098000980000000
a5121c000000007000070000700007000070000700007000162001620016200162001620016200162001620016200162001620016200000140002000030000400005000050000500005017200092000920009200
111200010a01007000070000700007000070000700007000162001620016200162001620016200162001620016200162001620016200162001620016200162001720017200172001720017200092000920009200
001200000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c60009800000000000000000
__music__
00 08060509
04 470a4344
01 1a195c5d
00 1b1e1f5d
00 1b191c60
00 1b1e1c60
00 1b191c61
00 1b195c5d
00 1d195c5d
00 1a1e5c5d
00 1b5e5f5d
00 1b5e5f5d
00 1b5e1f5d
00 1b591c5d
00 1b591c60
02 1d591c20

