pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- nuclear semiotics

ver="0.2.3"

-- constants
l_sfx={-1,-1,-1,-1}
l_sfx_cur=nil
l_sfx_lst=nil
rpso=-1	
walt=0	--walk time

rp1_us=2.4 --rad1 up speed
rp1_usb=5 --rad1 up spd boss
rp1_ds=1 		--rad1 down speed
rp2_s=1 			--rad2 up speed

hand_d=-3.5 	--hand delay
hand_up=0.07 --hand up speed
hand_dn=0.07 --hand down speed

sp_hs=1 	--spike hell speed
sp_hd=20 --spike hell dist

--explode dirs
exp_d={{1,0,0},{0,1,0},{0,0,1}}

--globals
//tita=rnd()
tita=0.1
titt=0

ppx,ppy,ppz=0,-8,-420
pp_pi,pp_ya=0,0
pp_rp,pp_rp2=0,0
pdd=30000
keys={}
keyi=-1
lock_i=nil
lock_j=nil
//pchrg=false

camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=0
cam_h=0

suni,sunj=0,0
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
	sp=10,
	sh=2,
	ky=5,
	//sy=5,
	tr=20
}

secr=25
secr2=50
sex,sez=0,0
s_map=false
mode="title"
story=0
alert=nil
boss,bossr=nil,nil
term=nil
in_term=false
t_idx_x=0 	--term idx left/right
t_idx_y=-1 --term idx up/down
t_pr_t=0 --term press time

keys_d={
	{ --green key
		n=0,
		c={3,11}
	},
	{ --red key
		n=0,
		c={8,2,14}
	},
	{ --blue key
		n=0,
		c={12,13,1}
	},
	{ --yellow spike
		n=-1,
		c={9,10,7}
	}
}

-- grayscale colors
gs_c={6,7,13}

function _init()
	printh("====== init ======")
	
	poke(0x5f5c,255)
	
	for t in all(hand_tris)do
		add(t,5)
	end
	
	term_h=obj(
		hand_tris,
		0,0,0,
		0,0,0,
		0,0,
	nil)
	deli(term_h.tris,18)
	deli(term_h.tris,15)
	deli(term_h.tris,12)
	
	hand=obj(
		hand_tris,
		0,0,0,
		0,0,0,
		0,0,
		nil)
	hand_t=hand_d
	l_hand_t=-1
	
	//lvl={}
	
	//init_title()
	init_story_0()
	init_title() --hack but w/e
end

function reset_vars()
	pdd=60						--death delay
	pdt=0							--death time
	pp_rp=0 				--rad psn temp
	pp_rp2=0 			--rad psn perm
	hand_t=-2 		--hand time
	l_hand_t=-2 --last hand time
	act_sp=nil 	--active spike
	key_t=0					--key get time
	atk_n=0					--num atks on boss
	b_spd=0.5			--boss speed
	
	atk_t=0					--attack time
	atk_t2=0				--attack time 2
	
	suni=-1
	sunj=0
end

function init_title()
	mode="title"
	ppx=(lock_i+2)*secr2
	ppy=-30
	ppz=lock_j*secr2
	pp_ya,pp_pi=0.2299,0
	
	//srand(2)
	//cur_me_key=0
	//add_lk_area(0,0)
	music(2)
end

function init_story_0()
	srand(time())
	
	--[[
	lock_ord term_ord area_ord 
	arrays store indexs into 
	keys_d list in random order
	]]--
	lock_ord=rar({1,2,3})
	term_ord=rar({1,2,3})
	area_ord=rar({1,2,3})
	loga({"lo",a_to_s(lock_ord)})
	loga({"to",a_to_s(term_ord)})
	loga({"ao",a_to_s(area_ord)})
	
	--[[
	assign a key number to each
	element of keys_d
	]]--
	key_ord={}
	for i=1,3 do
		add(key_ord,rand(1,3)*2+2)
	end
	loga({"ko",a_to_s(key_ord)})
	for i=1,3 do
		keys_d[i].n=key_ord[i]
		loga({
			"d",
			keys_d[i].c[1],
			keys_d[i].n
		})
	end
	
	srand(2)
	
	cur_me_key=1
	lvl={}	
	
	//add_me_area(0,-4,1)
	//add_me_area(0,4,1)
	//add_me_area(4,0,1)
	
	add_me_area(0,-7,2)
	add_me_area(4,-19,3)
	add_me_area(14,-24,3)
	add_lk_area(4,-12)
	add_me_sp(2,1)
	add_me_sp(0,1)
	add_me_sp(2,-2)
	
	srand(time())
	music(0)
	
	reset_vars()
	
	ppy=-8
	ppx,ppz=10,-10
	pp_pi,pp_ya=0,0.83
	mode="game"
	story=0
end

function init_story_1()
	srand(time())
	music(18)
	ppx,ppy,ppz=0,-100,0
	pp_pi,pp_ya=0,0.88
	mode="game"
	story=1
	
	lvl={}
	add_hell_area(0,0,2)
	
	menuitem(1,"map",function()
		s_map=not s_map
	end)
	
	reset_vars()
	loop_sfx(-1,1)
	
	--temp
	local swd=obj(
		swd_tris,
		0,0,0,
		0,0,0,
		0,0,
		nil
	)
	swd.ft=1
	swd.t=0
	swd.gs=true
	swd.key_idx=4
	add(keys,swd)
	keyi=1
	set_sun_pos()
end

function init_ending()
	atk_t2=0
	init_story_0()
	init_title()
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

	//draw_log()
	if titt>180 then
		print(ver,1,1,1)
		print("press ❎ to start",1,7,2)
	elseif titt>60 then
		spr(120,32,60,8,1)
	end
	
end

function draw_game()
	if s_map then
		draw_top_down()
		return
	end
	
	if in_term then
		proj_term()
	else
		proj_pov()
		if atk_t2>-210 then
			proj_hand()
		end
	end
	
	if pdd>0 then
		draw_sorted()
	end
		
	proj_sun_rays()
	
	if in_term then
		draw_crt()
	end
	
	draw_rad()
	draw_log()
	
	if pdd==0 then
		print(
			"press ❎ to retry",
			1,120,
			7)
	elseif alert then
		print(
			alert,
			64-#tostr(alert)*2.5,
			80,
			11)
	end
end

function _update()
	alert=nil
	
	if mode=="title" then
		tita+=0.0001
		ppx=(lock_i-1)*secr2
		ppz=(lock_j)*secr2
	
		ppx+=cos(tita)*200
		ppz+=sin(tita)*200
		pp_ya=-tita-0.75
	
		sex=round((ppx)/secr2)
		sez=round((ppz)/secr2)
		update_cam()
		
		titt+=1
		if(btn(❎))init_story_0()
		return
	end
 
 if in_term then
		update_term()
		return
	end

	if pp_rp2>=100 then
		update_dead()
	elseif atk_n<5 then
		update_player()
	end
	
	update_cam()
	
	sunx=ppx+suni*1000
	sunz=ppz+sunj*1000
	
	boss_on=false
	if story==1 then
		local bx,by=proj(
			boss.x,boss.y,boss.z
		)
		if bx>40 and bx<88 then
			boss_on=true
		end
	end
	
	-- update hand
	if ray_pts==0 and
				key_t==0 and
				not boss_on then
		hand_t=max(hand_d,hand_t-hand_dn)
	elseif ray_pts>2 or 
								hand_t>hand_d or 
								key_t>0 or
								boss_on then
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
				k.ya+=0.01
				if term.act_t==0 then
					k.pi+=0.01 
					k.ro+=0.01
				end
			end
		end
	end end
	
	for k in all(keys) do
		k.x=ppx
		k.z=ppz
	end
	
	if story==0 then
		update_story_0()
		update_hand_key_s0()
	elseif story==1 and atk_n<5 then
		update_hell()
		update_hand_key_s1()
	end
	
	if atk_t2>0 or atk_n==5 then
		atk_t2-=1
		loga({atk_t2})
		if atk_t2<=-300 then
			init_ending()
		end
	end
	
	if l_hand_t==1 and hand_t!=1 then
		loop_sfx(-1,1)
	end
	
	l_hand_t=hand_t
end

function update_story_0()
	l_sfx_cur="story 0"
	act_sp=nil
	
	-- check if at lock spike
	for j=lock_j-1,lock_j+1 do
		local s=lvl[j][lock_i].sp[1]
		if dist(ppx,ppz,s.x+10,s.z)<20 then
			alert=s.lock_n
			act_sp=s
		end
	end
end

function update_hell()
	l_sfx_cur="hell"
	--move boss
	local a=atan2(
		ppx-boss.x,
		ppz-boss.z)
	boss.x+=cos(a)*b_spd
	boss.z+=sin(a)*b_spd
	bossr.x=boss.x
	bossr.z=boss.z
	

	for s in all(lvl[0][0].sp)do
		local a=atan2(s.x,s.z,0,0)
		--temp comment
		//s.x-=cos(a)*sp_hs
		//s.z-=sin(a)*sp_hs
	end
	
	for s in all(lvl[0][0].sh)do
		local a=atan2(s.x,s.z,0,0)
		--temp comment
		//s.x-=cos(a)*sp_hs
		//s.z-=sin(a)*sp_hs
	end
end

function update_hand_key_s0()
	local k=keys[keyi]
	if(not k)return
	
	-- change key color in
	-- sunlight
	if k.gs and 
				ray_pts>2 and
				hand_t==1 then
		k.gs=false
		set_key_c(
			k,
			keys_d[k.key_idx].c
		)
	elseif not k.gs and
								ray_pts<=2 then
		k.gs=true
		set_key_c(k,gs_c)
	end 
	
	-- change key spin speed
	if hand_t==1 and
				term.act_t>0 and
				((
					act_sp!=nil and
					act_sp.lock_n==k.key_idx
				) or
				k.key_idx==4) then
		k.t=k.t+0.001
		if l_hand_t!=1 then
			loop_sfx(37,1)
		end
	else
		k.t=max(0,k.t-0.01)
	end
		
	-- spin key
	k.ya+=max(0.01,k.t)
	if k.key_idx!=4 then
		k.pi+=max(0.01,k.t)
		k.ro+=mid(0.01,k.t,1)/2
	end
	
	
	if k.t>0.13 then
		deli(keys,keyi)
		inc_key()
		hand_t=0
			
		-- all keys destroyed,
		-- add spike
		if #keys==0 then
			local swd=obj(
				swd_tris,
				term.x,-5,term.z,
				0,0,0,
				0,0,
			nil
			)
			swd.ft=1
			swd.t=0
			swd.gs=true
			swd.key_idx=4
					
			add(
				lvl[lock_j][lock_i-1].ky,
				swd
			)
			deli(
				lvl[lock_j][lock_i-1].tr,
				1
			)
				
			keyi=1 --idx of spike
		end
	elseif k.t>=0.1 then
		-- explode key
		if k.key_idx==4 then
			set_key_c(k,gs_c)
			init_story_1()
			return
		end
			
		for ti=1,#k.tris do
			local d=agw(exp_d,ti)
			for p in all(k.tris[ti].pts) do
				p.x+=0.5*d[1]
				p.y+=0.5*d[2]
				p.z+=0.5*d[3]
			end
		end
	end
end


function update_hand_key_s1()
	local k=keys[1]
	
	if hand_t==1 and ray_pts>2 then
		k.t=k.t+0.001
		
		if l_hand_t!=1 then
			loop_sfx(37,1)
		end
	elseif k.t<0.13 then
		k.t=max(0,k.t-0.01)
		if(k.t==0)key_t=0
	end
		
	-- spin key
	k.ya+=max(0.01,k.t)
	
	if k.t>0.13 then
		if key_t==0 then
			loga({"locking charge"})
			set_key_c(
				k,
				keys_d[k.key_idx].c
			)
		end
		key_t=30
		
		if boss_on then
			atk_t+=1
			if atk_t==30 then
				loga({"releasing charge"})
				set_key_c(k,gs_c)
				k.t=0.12
				
				set_sun_pos()
				atk_n+=1
				if atk_n==5 then
					atk_t2=60
				else
					atk_t2=60
				end
	
				b_spd+=0.1
			end
		else
			atk_t=0
		end
	end
end

function set_sun_pos()
	local ni,nj=suni,sunj
	while (ni==suni and nj==sunj) 
							or
							(ni==0 and nj==0)
							do
		ni=rand(-1,1)
		nj=rand(-1,1)
	end
	loga({"set sun",ni,nj})
	suni=ni
	sunj=nj
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
	local ddz=min(ceil(dz/200),4)
	if story==0 and ddz>1 then
		c=dz_cols[ddz-1]
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
-- proj

function proj_pov()
	if pp_rp2<100 then
		cls(story==0 and 7 or 0)
	end
	
	-- scrolling sky
	if story==1 and
				atk_t2>-90 then
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
	
	if pp_rp2<100 and 
				atk_t2>-120 then
		local gh=64+pp_pi*1024
		gh=mid(0,gh,128)
		rectfill(
			0,gh,
			127,gh+127,
			story==0 and 15 or 1)
	end
	
	//n_t_sort=0
	if atk_t2>-90 then
		proj_spr(
			obj(
				draw_sun,
				sunx,suny,sunz,
				0,0,0,0,0,
				nil
			)
		)
	end
	
	if atk_t2>-160 then
		proj_secs()
	end
	//draw_sorted()
	
	if atk_t2>0 then
		if (atk_t2/2)%2==0 then
			set_key_c(boss,{9})
		else
			set_key_c(boss,{0,1,1,0})
		end
	
		local bx,by=proj(
			boss.x,boss.y,boss.z) 
		local sx,sy=proj(
			keys[1].x,
			keys[1].y-0.5,
			keys[1].z)
		
		for _=1,10 do
			local rx=sx+rand(-30,30)
			local ry=sy+rand(-30,30)
			line(
				sx+rand(-10,10),
				sy+rand(-10,10),
				rx,
				ry,
				10)
			line(
				rx,
				ry,
				bx+rand(-2,2),
				by+rand(-2,2),
				10)
		end
	end
end

function proj_secs()	
	//loga({"checking"})
	local chkd={}	
	local dpt=12
	if(hand_t>0)dpt=8
	for n=0,dpt do
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
			
		if n_t_sorted>60 then
			return
		end
		
	end end
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

function draw_sun(s)
	if story==0 then
		local c=9
		if term.act_t>0 and
					act_sp!=nil then
			c=keys_d[act_sp.lock_n].c[1]
		end
		circfill(
			s.pts[1].x,
			s.pts[1].y,
			10,
			c
		)
	else
		circfill(
			s.pts[1].x,
			s.pts[1].y,
			10,
			0
		)
		spr(7,
			s.pts[1].x-8,
			s.pts[1].y-8,
			2,2
		)
	end
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
			local sc=pget(
				sx+cos(a)*9,
				sy+sin(a)*9
			)
			if story==1 and sc==0 then
				ray_pts+=1
			elseif sc==5 then
				ray_pts_h+=1
				//ray_pts+=1
			elseif sc==9 or 
										sc==3 or
										sc==8 or
										sc==12 then
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
		
		ray_pts+=ray_pts_h	
		
		if pget(sx,sy)==9 then
			local fx=sx-64
			circ(64+fx/16,55,10,7)
			circ(64-fx/2,60,30,7)
		end
	end
end

function proj_hand()
	local ht=max(hand_t,0)
	hand.x=ppx
	hand.z=ppz
	if #keys>0 then
		hand.y=-2-5*ht+pp_pi*50
		hand.ro=0.35//0.07+0.08*ht
		hand.ya=pp_ya-0.1
		hand.pi=0.65
		
		keys[keyi].y=-2-7*ht+pp_pi*50
	else
		hand.y=-2-7*ht+pp_pi*50
		hand.ro=0.07+0.08*ht
		hand.ya=pp_ya
		hand.pi=0//pp_pi
	end
		
	if ht>0 then
		proj_obj(hand,false)
		if #keys>0 then
			proj_obj(keys[keyi],false)
		end
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
	
	if btnp(❎) and
				story==0 and
				#keys>0 and
				ppvs==0 then
		inc_key()
		hand_t=0
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
		
		if story==1 then
			local d=dist(
				ppx,ppz,
				bossr.x,bossr.z)
			if d<=bossr.r then
				touch_r=true
				pp_rp+=((bossr.r-d)/bossr.r)*rp1_usb
			end
		end
		
		-- check term
		for t in all(sec.tr)do
			local d=dist(ppx,ppz,t.x-15,t.z)
			if d<15 and 
						term.act_t==0 and
						pp_ya>=0.68 and
						pp_ya<=0.82 then
				alert="❎ interact"
				if btnp(❎) then
					init_term()
				end
			end
		end
		
		-- check touch map keys
		for k in all(sec.ky)do
			local d=dist(ppx,ppz,k.x,k.z)
			if d<10 do
				//init_story_1()
				add(keys,k)
				del(sec.ky,k)
				key_t=60
				hand_t=0
				keyi=#keys
				music(16)
			end
		end
		
		::update_continue::
	end end
	//end end end
	
	if key_t>0 then
		key_t-=1
	end
	//loga({key_t, hand_t})
	
	if touch_r and pp_rp>=100 then
		pp_rp=100
		pp_rp2+=rp2_s
	elseif not touch_r then
		pp_rp=max(0,pp_rp-rp1_ds)
	end
	
	l_sfx_cur="rad"
	local rps=flr(pp_rp/10)
	local rps2=flr(rps/2)
	if pp_rp==0 or pp_rp2>=100 then
		loop_sfx(-1,1)
		loop_sfx(-1,2)
		if pp_rp2>=100 then
			loop_sfx(24,2)
		end
	elseif rps!=rpso then
		loop_sfx(rps+10,1)
		if rps>5 then
			loop_sfx(rps2+18,2)
		else
			loop_sfx(-1,2)
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
		if story==0 then 
			init_story_0()
		else
			init_story_1()
		end
	else
		pdd-=1
	end
end

function init_term()
	in_term=true
	t_crt_t=0
	t_crt_l={}
	
	term_h.ro=0.1
	term_h.ya=0.05
	term_h.pi=0.05
end

function proj_term()
	cls(1)
	camera(0,0)
	//spr(41,60,60,2,2)
	srand(term.seed)
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
		
		local s=term.inpt[i+2]
		local o=symb(
			10*i,
			-10,
			40,
			s,
			keys_d[term_ord[i+2]].c[1]
		)
		if term.act_t==0 or 
					flr(term.act_t/8)%2==0 then
			proj_obj(
				o,
				false
			)
		end
	end
	
	proj_obj(term_h,false)
	
	srand(time())
end

function draw_crt()
	--scan lines
	for l in all(t_crt_l)do
		for i=10,117 do
		for j=-1,1 do
			local c=pget(i,l.y+11+j)
			if c!=0 then
				pset(i-2,l.y+10+j,c)
			end
		end end
	end
end

function update_term()
	cam_ya=0
	cam_pi=0
	camz=0
	camx=0
	camy=0
	
	local win=true
	for i=1,#term.inpt do
		local inpt=term.inpt[i]
		local ansr=keys_d[term_ord[i]].n
		if(inpt!=ansr)win=false
	end
	if win then
		term.act_t+=1
		if term.act_t==1 then
			music(17)
		end
		if term.act_t>=60 then
			in_term=false
			loga({"win"})
			
			-- change colors of 
			-- lock spikes
			for j=lock_j-1,lock_j+1 do
				local s=lvl[j][lock_i].sp[1]
				set_key_c(s,{9})
			end
		end
		
		return
	end
	
	if(btnp(🅾️))in_term=false
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
		local val=term.inpt[t_idx_x+2]
		val=mid(
			1,
			9,
			val+t_idx_y)
		term.inpt[t_idx_x+2]=val
		sfx(3)
	end
	
	if t_pr_t>0 then
		t_pr_t-=1
	end
	
	term_h.x=2.7*t_idx_x+4.2
	local off=1-abs(t_pr_t-5)/5
	term_h.y=t_idx_y+3+0.5*off
	term_h.z=0
	
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

function inc_key()
	keyi+=1
	keyi=(keyi-1)%#keys+1
end

function set_key_c(k,c)
	for ti=1,#k.tris do
		local t=k.tris[ti]
		t.c=agw(c,flr((ti-1)/k.ft))
	end
end
-->8
-- lvl generation

//function spike(x,z,s_num,dr,h,r)
function spike(x,z,st,h,r,c1,c2)
	rx,rz=rand(-40,40),rand(-40,40)
	h=(h==nil and -100 or h)
	r=(r==nil and 10 or r)
	c1=(c1==nil and 0 or c1)
	c2=(c2==nil and 1 or c2)
	
	if st then
		rx,rz=0,0
	end
	
	--[[
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
	]]--
	
	local sp_tris={
		{ -- west face
			"-1,0,-1",
			"-1,0,1",
			p_to_s(rx-0.1,h,rz),
			c1
		},
		{ -- east face
			"1,0,1",
			"1,0,-1",
			p_to_s(rx+0.1,h,rz),
			c2
		},
		{ -- north face
			"1,0,-1",
			"-1,0,-1",
			p_to_s(rx,h,rz-0.1),
			c2
		},
		{ --south face
			"-1,0,1",
			"1,0,1",
			p_to_s(rx,h,rz+0.1),
			c1
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
		2*r,2*r,
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
	//return o_sp,o_sh,s
	return o_sp,o_sh
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


function add_me_area(ci,cj,r)
	local imin,imax=ci-r,ci+r
	local jmin,jmax=cj-r,cj+r
	
	local kr=max(0,r-2)
	local ki=ci+rand(-kr,kr)
	local kj=cj+rand(-kr,kr)
	
	//local symbs={}
	--temp, key goes in center
	//symbs[0]={i=ci,j=cj,n=-1}
	--[[
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
				
		loga({
			"symb",
			symbs[k].i,
			symbs[k].j,
			symbs[k].n,
		})
	end
	]]--
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
			
			--[[
			local symb_n=-1
			for sm in all(symbs)do
				if j==sm.j and i==sm.i then
					symb_n=sm.n
				end
			end
			]]--
		
			local sx=i*secr2
			local sy=j*secr2
			local rx=rand(-secr,secr)+sx
			local rz=rand(-secr,secr)+sy
			
			if j==kj and i==ki then
				if cur_me_key>0 then
					local kidx=area_ord[cur_me_key]
					local lk=keys_d[kidx]
					loga({"lk",i,j,lk.n})
					local t=nil
					if(lk.n==4)t=pyr_tris
					if(lk.n==6)t=cube_tris
					if(lk.n==8)t=diam_tris
					local o_key=obj(
						t,
						rx,-5,rz,
						0,0,0,
						5,5,
						nil
					)
					o_key.ft=lk.n==6 and 2 or 1
					o_key.key_idx=kidx
					o_key.t=0
					o_key.gs=true
					
					add(sec.ky,o_key)
					cur_me_key+=1
				end
			else
				local sp,sh=spike(rx,rz)
				add(sec.sp,sp)
				add(sec.sh,sh)
			end
			
			add(sec.rs,{
				x=rx,z=rz,
				r=rand(20,30)
			})
			
			if(lvl[j]==nil)lvl[j]={}
			lvl[j][i]=sec
		end
	end
end

function add_me_sp(i,j)
	local sx=i*secr2
	local sy=j*secr2
	local rx=rand(-secr,secr)+sx
	local rz=rand(-secr,secr)+sy
	local sec=nsec()
	local sp,sh=spike(rx,rz,true)
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
			i*secr2,j*secr2,true,-10,2)
		sp.lock_n=lock_ord[c]
		sp.ft=1
		add(sec.sp,sp)
		add(sec.sh,sh)
		lvl[j]={}
		lvl[j][i]=sec
	end
	
	-- add terminal
	local sec=nsec()
	term=obj(
		tr_tris,
		(ci-1)*secr2,0,cj*secr2,
		0.75,0,0,
		5,5,
		nil
	)
	term.inpt={3,3,3}
	term.act_t=0
	add(sec.tr,term)
	
	add(sec.sh,obj(
		tr_sh_tri,
		(ci-1)*secr2+14,0,cj*secr2,
		0,0,0,
		0,0,
		nil
	))
	lvl[cj][ci-1]=sec
end

function add_hell_area()
	local sec=nsec()
	
	local bp,bs=spike(
		100,100,
		true
	)
	add(sec.sp,bp)
	boss=bp
	boss.ft=1
	bossr={
		x=bp.x,z=bp.z,
		r=80
	}
	
	for i=0,29 do
		local a=i/30
		local sx,sz=cos(a),sin(a)
		local sp,sh=spike(
			sx*secr2*sp_hd,
			sz*secr2*sp_hd,
			true,
			nil,nil,
			8,2)
		add(sec.sp,sp)
		add(sec.sh,sh)
	end
	
	
	
	lvl[0]={}
	lvl[0][0]=sec
end

--[[
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
]]--
-->8
-- helpers

function loop_sfx(n,c)
	if n>-1 then
		l_sfx_lst=l_sfx_cur
	elseif l_sfx_lst!=l_sfx_cur then
		return
	end
	
	if l_sfx[c+1]!=n then
		l_sfx[c+1]=n
		sfx(n,c)
	end
end

function nsec()
	return {
		sp={},
		sh={},
		rs={},
		ky={},
		tr={}
	}
end

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
		local pts={}
		for pi=1,3 do //evry pt
			local sp=split(t[pi],",")
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

function rar(a)
	local o={}
	for _=1,#a do
		add(o,deli(a,rand(1,#a)))
	end
	return o
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

-- array get wrap
function agw(a,i)
	return a[(i-1)%#a+1]
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

--[[
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
]]--
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

tr_tris={
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
	}
}
	
tr_sh_tri={
	{
		"-10,0,-4",
		"-10,0,4",
		"10,0,0",
		5
	}
}

pyr_tris={
	{
		"-1,-1,1",
		"0,-1,-1",
		"1,-1,1",
		6
	},
	{
		"-1,-1,1",
		"0,-1,-1",
		"0,1,0",
		7
	},
	{
		"0,-1,-1",
		"1,-1,1",
		"0,1,0",
		13
	},
	{
		"-1,-1,1",
		"1,-1,1",
		"0,1,0",
		6
	},
}

cube_tris={
	{--front 1
		"-1,1,-1",
		"1,1,-1",
		"1,-1,-1",
		6
	},
	{--front 2
		"-1,1,-1",
		"-1,-1,-1",
		"1,-1,-1",
		6
	},
	{--back 1
		"-1,1,1",
		"1,1,1",
		"1,-1,1",
		7
	},
	{--back 2
		"-1,1,1",
		"-1,-1,1",
		"1,-1,1",
		7
	},
	{--left 1
		"-1,1,-1",
		"-1,1,1",
		"-1,-1,-1",
		13
	},
	{--left 2
		"-1,1,1",
		"-1,-1,1",
		"-1,-1,-1",
		13
	},
	{--right 1
		"1,1,-1",
		"1,1,1",
		"1,-1,-1",
		6
	},
	{--right 2
		"1,1,1",
		"1,-1,1",
		"1,-1,-1",
		6
	}
}

diam_tris={
	{
		"-1,0,-1",
		"1,0,-1",
		"0,-1,0",
		6
	},
	{
		"1,0,-1",
		"1,0,1",
		"0,-1,0",
		7
	},
	{
		"1,0,1",
		"-1,0,1",
		"0,-1,0",
		13
	},
	{
		"-1,0,1",
		"-1,0,-1",
		"0,-1,0",
		6
	},
	{
		"-1,0,-1",
		"1,0,-1",
		"0,1,0",
		6
	},
	{
		"1,0,-1",
		"1,0,1",
		"0,1,0",
		7
	},
	{
		"1,0,1",
		"-1,0,1",
		"0,1,0",
		13
	},
	{
		"-1,0,1",
		"-1,0,-1",
		"0,1,0",
		6
	},
}

swd_tris={
	{
		"-0.5,0,0.5",
		"0,0,-0.5",
		"0,-4,0",
		7
	},
	{
		"0,0,-0.5",
		"0.5,0,0.5",
		"0,-4,0",
		13
	},
	{
		"-0.5,0,0.5",
		"0.5,0,0.5",
		"0,-4,0",
		6
	},
}

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
00000000000000000055555500500555004555550055151500000000000000000000000000000000000000000000000000000000000000000222222222222220
0002222222222000055555550550555504555555055555550066d0000066d0000066d000004440000066d0000000000000000002200000000d222222222222d0
0022222222222200555555555555555555555555155555510661dd0006161d0006614d00041114000661dd000000000000000022220000005dd2222222222dd5
02222222222222205555555555555555455555554555555406111d000661dd0006141d000111110006111d000000000000555222222555005ddd22222222ddd5
0222222ee2222220555555555555555545555454455555450661dd00061d1d0006414d000111110006611d0000000000055522222222555055ddd222222ddd55
022222e22e2222205555555055555550555554405555555000ddd00000ddd00000dd40000011100000ddd000000000005552222222222555555ddd2222ddd555
02222e2222e222205555550005555500555544005555550000000000000000000000000000000000000000000000000055222222222222555555ddd22ddd5555
0222e222222e222055555000505550005554400055454000000000000000000000000000000000000000000000000000522222222222222555555dddddd55555
0222eeeeeeee2220555555555055500555555555500050050005555500055555000555540005555500000000000000005dddddddddddddd5555555dddd555555
0222222222222220555555555555550555555555500555550005555500005555000555440005554400000000000000005dddddddddddddd50555555dd5555550
0d222222222222105555555555555555554554555555545500055555000505550005555500055514000000000000000005555555555555500055555555555500
0dd22222222221105555555555555555555454555555555400055555000555550005555500055551000000000000000000000000000000000000000000000000
00ddddd1d11d11005555555555555555454454445545545400055555000055550005544500055455000000000000000000000000000000000000000000000000
000dddd1d11d10000000000000000000000000000000000000055555000555550005555400055554000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055555000555550005555500055544000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055555000005550005554400055555000000000000000000000000000000000000000000000000
000000000000000000ddd00000ddd000005555500000000000ddd00000ddd00000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
00022222222220000dbbbd000d333d0005555555000000000d666d000dcccd000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
0022222222222200dbbbbbd0d33333d05555555550000000d66666d0dcccccd0aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
0222222222222220dbbb7bd0d33353d05555555550000000d66656d0dccc7cd0aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
0222eeeeeeee2220dbb77bd0d33553d05555555550000000d66556d0dcc77cd0aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
0222e222222e22200dbbbd000d333d0000000000000000000d666d000dcccd00aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
02222e2222e2222000ddd00000ddd000000000000000000000ddd00000ddd000aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
022222e22e2222200000000000000000000000000000000000000000000000000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
0222222ee222222000ddd00000ddd0000000000000000000000000000000000000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
02222222222222200d888d000d222d00000000000000000000000000000000000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
0d22222222222210d88888d0d22222d000000000000000000000000000000000aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
0dd2222222222110d88878d0d22252d000000000000000000000000000000000aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
00ddddd1d11d1100d88778d0d22552d000000000000000000000000000000000aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
000dddd1d11d10000d888d000d222d0000000000000000000000000000000000aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
000000000000000000ddd00000ddd00000000000000000000000000000000000aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
00000000000000000000000000000000000000000000000000000000000000000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
01100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
71117777711177777117711777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
71717777717177777717771777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
71717777717177777717771777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
71717777717177777717771777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
71117717711177177111711177777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
72227222722277227722777777222227777772227722777777227222722272227222777777777777777777777777777777777777777777777777777777777777
72727272727772777277777772272722777777277272777772777727727272727727777777777777777777777777777777777777777777777777777777777777
72227227722772227222777772227222777777277272777772227727722272277727777777777777777777777777777777777777777777777777777777777777
72777272727777727772777772272722777777277272777777727727727272727727777777777777777777777777777777777777777777777777777777777777
72777272722272277227777777222227777777277227777772277727727272727727777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777779999977777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777779999999999977777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777799999999999997777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777999999999999999777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777779999999999999999777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777779999999999999999977777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777799999999999999999997777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777999999999999999999999777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777999999999999999999999777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777999999999999999999999777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777999999999999999999999777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777999999999999999999999777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777999999999999999999999777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777999999999999999999999777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777799999999999999999997777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777799999999999999999997777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777779999999999999999977777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777999999999999999777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777799999999999997777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777779999999999977777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777799999997777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777771777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777177777777777717777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777177777777777711777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777177777777777111777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771177777777777111777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771177777777777111777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771177777777771111177777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771177777777771111177777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771177777777771111177777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771117777777711111177777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771117777777711117117777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771117777777111117117777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771117777777111117117777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777771117777777111111117777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711117777771111111111777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711117777771111171111777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711117777711111171111777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711111777711111171111777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711111777711111171111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711111777111111171111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711111777111111771111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711111771111111711111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711111771111111711111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777711111771111111711111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777111111711111111711111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777111111111111117711111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777111111111111117711111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777111111111111117711111177777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777111111111111117711111117777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777111111111111117111111117777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777111111111111177111111117777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777111111111111177111111117777777777777777777777777777777777777777777777777777777777777
ffffffff777f7777f7777fffffffffffffffffffffff1111111111111ff11111111ff7f77777f777f77fffffffffffffffffffffffffffffffffffffffffffff
fffffff77f77f7f77f777fffffffffffffffffffffff1111111111111ff11111111ff7f77f7f777f77f7ffffffffffffffffffffffffffffffffffffffffffff
fffffff777f777f77f777ffffffffffffffffffffff11111111111111ff11111111fff777f7777f777f7ffffffffffffffffffffffffffffffffffffffffffff

__sfx__
0b1000000017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170
930c00003f65500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
934000003f65500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
900600003e6453e645000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9005000023624236302d6302d6253960039600000000000021624216302b6302b625376000000000000000001f6241f6302d6302d625000000000000000000001d6241d6302b6302b62500000000000000000000
950c00002321423220232302324023250232502325023250232502325023250232502324023230232202321023210232102321023210232102321023210232102321023210232102321523200232002320023200
150c00000a8000a8000a8000a80009844098400985009850098600986009860098600986009860098600986009850098500984009840098300983009820098200981009810098100981009810098100981009815
910100010061536400374003640037400364003740036400374003640037400364003740036400374003640037400364003740036400374003640037400364003740036400374003640037400364003740036400
910c00000060000600006000060000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000610006100061000615
5d0c00001c0001c0001c0001c00010014100201002010020100201002010020100201002010020100201001010010100101001010010100101001010010100101001010010100101001510000100002300023000
010c00000785007850078500785007840078400784007840078300782007820078200781007810078100781509800098000980009800098000980009800098000980009800098000980009800098000980009800
0d0c00010582010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010682010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010883010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010983010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010b84010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010c84010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
0d0c00010d84010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
150c00010d85010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
150c00010d86010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
150c00010d87010800108001080012800148001580010800158001880018000098000980009800098000980009800098000980009800098000980009800098000980009800000000000000000000000000000000
ad0c00010b22523200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200
ad0c00010b24523200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200
ad0c00011726523200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200232002320023200
4509000016860168611586114861138611286111861108610f8610e8610d8610c8610b8510a851098510885107841068410584104841038310283202822028220281202812028120281202812028120281202815
05121c000c8400c8400c8300c8200c8150c8000c8300c8300c8200c8100c8100c8100c8150c8000c8300c8300c8200c8100c8150c8000c8000c8000c8200c8200c8100c8100c8150c80009800098000980000000
350b1c000c0630d8000c0430d8000c0330d8000c0130d8000c0530c0000c0430d8000c0330d8000c0130d8000c0130d8000c0130d8000c0630d8000c0430d8000c0330d8000c0130d80009800098000980009800
0d0b1c0013850138501383013810138301383013820138102084020840208302081020830208302082020810208202082020810208101784017841188211881119831198311a8111a81109800098000980009800
a51200010005007000070000700007000070000700007000162001620016200162001620016200162001620016200162001620016200162001620016200162001720017200172001720017200092000920009200
0d0b1c001385013850138301381013830138301382013810208402084020830208102083020830208202081020820208202081020810178401784116821168111583115831148211481109800098000980009800
05121c000c8000c8000c8400c8400c8300c8200c8150c8000c8300c8300c8200c8100c8100c8100c8150c8000c8300c8300c8200c8100c8150c8000c8000c8000c8000c8000c8000c80009800098000980000000
a5121c000000007000070000700007000070000700007000162001620016200162001620016200162001620016200162001620016200000140002000030000400005000050000500005017200092000920009200
01131c001a8401a8401a8201a8101a8301a8301a8201a8101a8301a8301a8201a8101a8301a8301a8201a8101a8301a8301a8201a8100e8500e8400e8200e8100e8500e8400e8200e81012800128001280012800
911000001c8141c8101c8201c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8301c8201c81528100281002810028100
991000001701417010170201703017030170301703017030170301703017030170301703017030170301703017030170301703017030170301703017030170301703017030170201701528800000000000000000
911000000701407010070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200701528800000000000000000
a11300001705017050170401703017020170101704017040170301702017010170101703017030170201701017010170101702017020170101701017010170151700017000170001700017000170001700017000
300800200271002710027200273002730027200271002710027100272002730027400274002730027200271002720027300274002750027500274002730027200273002740027500275002740027300272002710
0d0b1c000d8600d8600d8300d8100d8500d8500d8200d8100d8600d8600d8300d8100d8500d8500d8200d8100d8600d8600d8300d8100d8500d8500d8200d8100d8500d8500d8200d81009800098000980009800
4f02002026610046102b61006610256102761027610046102d610056102861000610266100561026610026102861005610286100361025610026102461025610296100b61024610026102b610026102861005610
350b1c000c0630d8000c0230d8000c0330d8000c0230d8000c0530d8000c0230d8000c0330d8000c0230d8000c0630d8000c0230d8000c0330d8000c0230d8000c0630d8000c0230d80009800098000980009800
2d1200010105007000070000700007000070000700007000162001620016200162001620016200162001620016200162001620016200162001620016200162001720017200172001720017200092000920009200
350b1c000c0630d8000c0230d8000c0330d8000c0230d8000c0530d8000c0230d8000c0330d8000c0230d8000c0630d8000c0430d8000c0630d8000c0230d8000c0630c0430c0530c05309800098000980009800
270e1c0023044230102303423014230342301423044230141d0341d01423044230141d0141d03423034230141d0341d01423014230341d0341d0150d0000d0000d0000d0000d0000d00009000090000900009000
270e1c0021044210102103421014210342101421014210341b0341b01421044210141b0341b01421034210141b0341b01421034210141b0341a0210b0000b0000b0000b0000b0000b00007000070000700007000
270e1c001e0441e0101e0341e0141e0341e0141e0441e01417034170141e0441e01416044160341e0341e01416034160241e0241e04415044150340d0000d0000d0000d0000d0000d00009000090000900009000
150b00010d045230002300023000230002300023000230001d0001d00023000230001d0001d00023000230001d0001d00023000230001d0001d0000d0000d0000d0000d0000d0000d00009000090000900009000
070200202d6100b610326100d6102c6102e6102e6100b610346100c6102f610076102d6100c6102d610096102f6100c6102f6100a6102c610096102b6102c61030610126102b6100961032610096102f6100c610
0d0b00010d8400d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d8000d80009800098000980009800
350b1c00130530d8000c0230d8000c0330d8000c0230d8000c0630c0530c0530d8000c0330d8000c0230d8000c0630d8000c0230d8000c0330d8000c0230d8000c053180000c0530d80009800098000980009800
a1131c000c0300c0300c0200c0100c0300c0300c0200c0100c0100c0100c0200c0200c0100c0100c0300c0300c0200c0100c0300c0300c0200c0100c0200c0200c0100c0100c0100c01015000150000900009000
a5131c001403014030140201401014030140301402014010140101401014020140201401014010140301403014020140101403014030140201401014020140201401014010140101401011000110001100011000
01131c001184011840118201181011830118301182011810118301183011820118101183011830118201181011830118301182011810118201182011810118101182011820118101181009800098000980009800
a1131c000b0300b0300b0200b0100b0300b0300b0200b0100b0100b0100b0200b0200b0100b0100b0300b0300b0200b0100b0300b0300b0200b0100b0200b0200b0100b0100b0100b01014000140000800008000
a5131c001303013030130201301013030130301302013010130101301013020130201301013010130301303013020130101303013030130201301013020130201301013010130101301010000100001000010000
01131c001084010840108201081010830108301082010810108301083010820108101083010830108201081010830108301082010810108201082010810108101082010820108101081009800098000980009800
01131c001784017840178201781017830178301782017810178301783017820178101783017830178201781017830178301782017810178201782017810178101084010840108201081015000098000980009800
a11300001403014030140201401014030140301402014010140101401014020140201401014010140201401013030130301302013010130301303013020130101301013010130201302013010130101301013010
a51300001c0301c0301c0201c0101c0301c0301c0201c0101c0101c0101c0201c0201c0101c0101c0201c0101c0301c0301c0201c0101c0301c0301c0201c0101c0101c0101c0201c0201c0101c0101c0101c010
011300001484014840148201481014810148101484014840148201481014830148301482014810138401384013820138101381013810138101381013840138401382013810138301383013820138101381013810
0113000014840148401482014810148101481014840148401482014810148301483014820148101f8301f8301f8201f8101f8301f8201f8101f81026820268202681026810158401583015820158101084010840
a1131c000e0300e0300e0200e0100e0300e0300e0200e0100e0100e0100e0200e0200e0100e0100e0300e0300e0200e0100e0300e0300e0200e0100e0200e0200e0100e0100e0100e01017000170000b0000b000
a5131c001603016030160201601016030160301602016010160101601016020160201601016010160301603016020160101603016030160201601016020160201601016010160101601013000130001300013000
01131c00138401384013820138101383013830138201381013830138301382013810138301383013820138101383013830138201381013820138201381013810138201382013810138100b8000b8000b8000b800
__music__
00 08060509
04 470a4344
01 5a195c5d
00 5b1e1f5d
00 5b191c60
00 5b1e1c60
00 5b191c61
02 5b195c5d
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
04 41212223
04 62212423
00 2826276a
00 28262769
00 28262769
00 2a262769
01 28262729
00 28262729
00 28262729
00 28262729
00 28262748
00 2a262748
00 31302b2e
00 31302c2e
00 31302d2e
00 31302f2e
00 31302b2e
00 31302c2e
00 31302d2e
00 31302f2e
00 28262f08
00 28262f31
00 28262f08
00 2a262f31
00 1a1b482e
00 1a1d482e
00 1a1b672e
00 1a1d082e
00 1a1b272e
00 1a1d272e
00 1a1b2f2e
02 2a1d2f2e
01 41343233
00 41343233
00 41373536
00 41383536
00 41343233
00 41343233
00 413f3d3e
00 41203d3e
00 413b393a
00 413c393a
00 413b393a
00 413c393a
00 413b393a
00 413c393a
00 413b393a
02 6565393a

