pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- menacing earthworks

ver="0.3.5"

-- constants
l_sfx={-1,-1,-1,-1}
l_sfx_cur=nil
l_sfx_lst=nil
rpso=-1	
walt=0	--walk time

rp1_us=2.4 --rad1 up speed
rp1_usb=5 	--rad1 up spd boss
rp1_ds=1 		--rad1 down speed
rp2_s=1 			--rad2 up speed

sp_hs=0.112 	--spike hell speed
sp_hd=20 				--spike hell dist

--explode dirs
exp_d={{1,0,0},{0,1,0},{0,0,1}}

--globals
tita=0.1
titt=0

ppx,ppy,ppz=0,-8,-420
pp_pi,pp_ya=0,0
pp_rp,pp_rp2=0,0
pdd=30000
keys={}
keyi=-1

camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=0
cam_h=0
sh_t=0

suna=0
sunx,suny,sunz=0,-200,0

fov=0.15
fov_c=-2.778 //1/tan(fov/2)
zfar=500
znear=-14
lam=zfar/(zfar-znear)
pov_scr_t=0

src_dp=20				--search depth
src_ns=10				--search num slices
src_ag=0.1 		--search angle
src_sd=0.5			--search slice depth

sec_d={ //sec layer rend dists
	sp=17,
	sh=1,
	ky=10,
	tr=20,
	db=10
}

pltr,pltr2=25,50 -- plot size
secsz=2

sex,sez=0,0
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
	for i=1,#body_tris-1 do
		add(body_tris[i],0)
	end
	//loga({"aaa",#body_tris})
	
	--[[
	skl=obj(
		body_tris,
		0,0,0,
		0,0.25,0,
		0,0,
		nil
	)
	skl.ft=6
	for i=#skl.tris,9,-1 do
		deli(skl.tris,i)
	end
	set_key_c(skl,{8,7})
	]]--
	
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
	l_hand_t=-1
	
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
	
	spk_t=0					--spike time
	
	//suni=-1
	//sunj=0
	suna=0.5
	brkng=false
	
	hell_r=pltr2*sp_hd
	keys={}
end

function init_title()
	mode="title"
	//loga({lock_i,lock_j})
	ppy=-30
	pp_ya,pp_pi=0.2299,0
	tit_idx=0
	trn=0
	show_c=false
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
	add(area_ord,4)
	//loga({"lo",a_to_s(lock_ord)})
	//loga({"to",a_to_s(term_ord)})
	//loga({"ao",a_to_s(area_ord)})
	
	--[[
	assign a key number to each
	element of keys_d
	]]--
	key_ord={}
	for i=1,3 do
		add(key_ord,rand(1,3)*2+2)
	end
	//loga({"ko",a_to_s(key_ord)})
	for i=1,3 do
		keys_d[i].n=key_ord[i]
		//loga({
		//	"d",
		//	keys_d[i].c[1],
		//	keys_d[i].n
		//})
	end
	
	//srand(2)
	
	cur_me_key=1
	lvl={}
	lock_sps={}
	
	add_me_area(0,-7,2)
 add_me_area(-2,-21,3)
 add_me_area(10,-21,3)
	add_lk_area(4,-12)
	add_me_sp(2,1)
	add_me_sp(0,1)
	add_me_sp(2,-2)
	
	-- up spikes
	for i=-10,0 do
		add_me_sp(i*2,-12,true)
		add_me_sp(i*2,-13,true)
	end
	add_me_area(-22,-12,3,true)
	
	add_db(0,-2,0)
	add_db(-2,-15,0.9)
	add_db(2,-21,0.1)
	add_db(8,-16,0.15)
	add_db(10,-26,0.8)
	
	//srand(time())
	music(0)
	
	reset_vars()
	
	ppy=-8
	ppx,ppz=10,-10
	pp_pi,pp_ya=0,0.83
	mode="game"
	story=0
	
	--testing
	--ppx,ppz=194,-601
	--pp_pi,pp_ya=0,0.22
	
	hand_d=-3.5 	--hand delay
	hand_t=hand_d
	
	-- shrink the up spikes
	grow_pts(function(sec,p)
		for k in all({"x","y","z"})do
			//p[k]*=0.01
			local id=k.."2"
			local v=p[k]
			p[id]=v -- copy the values for later
			p[k]=v*0.1
		end
	end)
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
	
	hand_d=-1 	--hand delay
	hand_t=hand_d
end

function init_ending()
	mode="ending"
	story=2
	atk_t2=0
	ppx=0
	ppy=-30
	ppz=0
	pp_ya,pp_pi=0.2299,0
	edt=0
	add_me_area(0,-7,2)
	
	music(48)
end

function _draw()
	t_sorted_ll=nil
	n_t_sorted=0
	n_o_proj=0
	
	n_sec_chk=0
	n_sec_fnd=0
	
	if trn>0 then
		draw_trn()
		return
	end
	
	if mode=="title" then
		draw_title()
	elseif mode=="ending" then
		draw_ending()
	else
		draw_game()
	end
end

function draw_trn()
	cls(0)
	local of=mode=="title" and 0 or 7
	if trn>60 then
		local i=flr((trn-60)/90)+1
		t2(
			epls[i+of],
			10,60,15,1)
	end
end

titp={6,13,5,1,0}
fat=8
function fade_in(st,cb)
	if(titt<st)return
	local i=flr((titt-(st-fat))/fat)
	pal(7,titp[mid(1,i,#titp)])
	pal(1,15) --todo remove, change color in sprite
	cb()
	pal()
end


function draw_title()
	proj_pov()
	
	draw_sorted()
	proj_sun_rays()
	
	if titt>=180 then
		//local i=flr((titt-160)/20)
		//pal(7,titp[mid(1,i,#titp)])
		if(titt>=280)spr(130,66,24,7,3)
		fade_in(180,function()
			spr(128,56,10,2,3)
		end)
		
		fade_in(210,function()
			spr(192,12,16,13,2)
		end)
		
		fade_in(240,function()
			spr(224,12,32,13,2)
		end)
		
		pal()
	end
	
	if titt>=300 then
		if show_c then
			t2(
				"⬆️⬇️⬅️➡️    move",
				4,50,2,7)
			t2(
				"❎          interact",
				4,58,2,7)
			t2(
				"❎+⬅️➡️     strafe",
				4,66,2,7)
			t2(
				"🅾️          cancel/cycle item",
				4,74,2,7)
			t2(
				"🅾️+⬆️⬇️⬅️➡️ free look",
				4,82,2,7)
				
		else
			print(ver,108,122,1)
		
			local of=tit_idx*8
			local tm=(titt%20)<10
			if tm then
			rectfill(
				4,79+of,50,85+of,1)
			end
			print(
				"start game",
				5,80,
				(tit_idx==0 and tm) and 15 or 2)
			print(
				"controls",
				5,88,
				(tit_idx==1 and tm) and 15 or 2)
		end
	elseif titt>=60 and titt<150 then
		spr(120,32,60,8,1)
	end
end

function draw_ending()
	proj_pov()
	draw_sorted()
	proj_sun_rays()
	
	local of=0
	local c1,c2=2,0
	for i,v in ipairs(epls)do
		if(i>32)c1,c2=7,13
		t2(v,2,128+(i+of)*6-edt,c1,c2)
		local ns=split(v,"\n")
		//loga({v,#ns})
		of+=#ns
	end
	
	if edt>=791 then
		t2("goldteam mmxxvi",66,120,10,1)
	end
end

function draw_game()
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
	//draw_log()
	
	if pdd==0 then
		t2(
			"press ❎ to retry",
			1,120,
			7,0)
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
	
	if sh_t>0.05 then
		sh_t*=0.9
	else
		sh_t=0
	end
	
	if trn>0 then
		trn+=1
		
		// temp for testing
		// remove after
		-- if(btnp(❎))trn=331
		
		if trn>330 then
			trn=0
			if mode=="title" then
				init_story_0()
				//init_story_1()
				//init_ending()
			else
				init_story_1()
			end
		end
		return
	end
	
	if mode!="game" then
		tita+=0.0001
		ppx=3*pltr2
		ppz=-12*pltr2
	
		ppx+=cos(tita)*200
		ppz+=sin(tita)*200
		pp_ya=-tita-0.75

		sex=flr((ppx)/(pltr2*secsz))
		sez=flr((ppz)/(pltr2*secsz))
		update_cam()
		
		if mode=="title" then
			update_title()
		elseif mode=="ending" then
			update_ending()
		end
		
		return
	end
 
 if in_term then
		update_term()
		return
	end

	if pp_rp2>=100 then
		update_dead()
	elseif atk_n<5 and not brkng then
		update_player()
	end
	
	update_cam()
	//suna+=0.01
	sunx=ppx+1000*cos(suna)
	sunz=ppz+1000*sin(suna)
	
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
				atk_t2<=0 then
		hand_t=max(hand_d,hand_t-0.07)
	elseif ray_pts>2 or 
								hand_t>hand_d or 
								key_t>0 or 
								atk_t2>0 then
		hand_t=min(1,hand_t+0.07)
	end
		
	if story==1 then
		sex=0
		sez=0
	else
		sex=flr((ppx)/(pltr2*secsz))
		sez=flr((ppz)/(pltr2*secsz))
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
	elseif story==1 and 
								atk_n<5 and 
								pdt==0 then
		update_hell()
		update_hand_key_s1()
	end
	
	if atk_t2>0 or atk_n==5 then
		atk_t2-=1
		//loga({atk_t2})
		if atk_t2<=-300 then
			init_ending()
		end
	end
	
	if l_hand_t==1 and hand_t!=1 then
		loop_sfx(-1,1)
	end
	
	l_hand_t=hand_t
end

function update_title()
	//if(btnp(❎))titt=180
	titt+=1
	if titt>=300 then
		if btnp()>0 then
			sfx(7,-1,0,8)
			titt=300
		end
		if not show_c then
			if(btnp(⬆️))tit_idx=0
			if(btnp(⬇️))tit_idx=1
		end
		
		if btnp(❎) then
			if tit_idx==0 then 
				trn=1
				music(-1)
				sfx(7,-1,8,27)
			else
				show_c=true
			end
		elseif btnp(🅾️) and show_c then
			show_c=false
		end
	end
end

function update_story_0()
	l_sfx_cur="story 0"
	act_sp=nil
	
	-- check if at lock spike
	for s in all(lock_sps)do
		if dist(ppx,ppz,s.x+10,s.z)<20 then
			//alert=s.lock_n
			act_sp=s
		end
	end
	
	if spk_t>0 and spk_t<150 do
		spk_t+=0.2
		
		grow_pts(function(sec,p)
			for k in all({"x","y","z"})do
				local id=k.."2"
				local per=spk_t/150
				p[k]=p[id]*per
			end
		end)
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
	boss.ya=a
	
	--[[
	if atk_t2>0 then
		local tt=30-(60-atk_t2)
		
		skl.x=ppx+sin(pp_ya)*tt
		skl.z=ppz+cos(pp_ya)*tt
	end
	skl.ya=-cam_ya+0.5//a+0.25
	]]--
	//loga({boss.ya})
	
	-- boss should always be the
	-- first spike, update all
	-- others after.
	//local lv=lvl[0][0]
	local lv=get_sec(0,0)
	for i=2,#lv.sp do
		local s=lv.sp[i]
		local sh=lv.sh[i-1]
		local sr=lv.rs[i-1]
		local a=atan2(s.x,s.z,0,0)
		local cx=cos(a)*sp_hs
		local cz=sin(a)*sp_hs
		
		s.x-=cx
		s.z-=cz
		sh.x-=cx
		sh.z-=cz
		
		sr.x-=cx
		sr.z-=cz
	end
	
	hell_r-=sp_hs
	
	if atk_n==3 then
		suna+=0.001
	elseif atk_n==4 then
		suna+=0.002
	end
end

function update_hand_key_s0()
	brkng=false
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
		brkng=k.key_idx!=4
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
		loop_sfx(-1,0)
		deli(keys,keyi)
		inc_key()
		hand_t=0
			
		-- all keys destroyed,
		-- add spike
		if #keys==0 then
			music(2)
			spk_t=1
			keyi=1 --idx of spike
		end
	elseif k.t>=0.1 then
		-- explode key
		loop_sfx(2,0)
		sh_t=4
		if k.key_idx==4 then
			set_key_c(k,gs_c)
			//init_story_1()
			trn=1
			clear_sfx()
			sfx(7,-1,8,27)
			music(-1)
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
	
	if not boss_on and
				hand_t==1 and 
				ray_pts>2 then
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
			//loga({"locking charge"})
			set_key_c(
				k,
				keys_d[k.key_idx].c
			)
		end
		key_t=30
		
		local bd=dist(
			ppx,ppz,boss.x,boss.z)
		//loga({"bd",bd})
		if boss_on and bd<200 then
			//atk_t+=1
			//if atk_t==30 then
				//loga({"releasing charge"})
				set_key_c(k,gs_c)
				k.t=0.12
				//k.t=0
				
				set_sun_pos()
				atk_n+=1
				atk_t2=60
				sh_t=20
				sfx(1)
				
				if atk_n==5 then
					music(-1)
					clear_sfx()
					sfx(1)
				end
	
				b_spd+=0.1
			//end
		//else
			//atk_t=0
		end
	end
end

function set_sun_pos()
	suna=rnd()
end
--[[
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
]]--

function update_ending()
	if edt<791 then
		edt+=0.2
		//if(btn(❎))edt+=3
		//loga({edt})
	end
end

function grow_pts(cb)
	for _,sec in pairs(lvl)do
	if sec.up then
	for k in all({"sp","sh"})do
	for s in all(sec[k])do
	for t in all(s.tris)do
	for p in all(t.pts)do
		cb(sec,p)
		--[[
		if sec.up then
				//p[k]/=0.99
			else
				p[k]*=0.99
			end
			
		end
		]]--
	end end end end end end
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

function proj_obj(o,nf)
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
		
		add(ts,{
			pts=pts,
			col=t.c,
			dz=dz_max
		})
		
		--[[
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
		]]--
	end
	
	//printh(#ts)
	
	--[[
	local imin=1
	if(f)imin=#ts-1
	//if(nf==nil)nf=1
	for i=max(1,imin),#ts do
		//local t=ts[i]
		sort_itm(ts[i])
	end
	]]--
	//if(nf==nil)nf=#ts
	//for i=#ts+1-nf,#ts do
		//local t=ts[i]
	//	sort_itm(ts[i])
	//end
	
	for t in all(ts)do
		sort_itm(t)
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
dz_cols2={1,6,2}
function draw_tri(t,c,dz)
	local ddz=min(ceil(dz/200),4)
	if story==0 and ddz>1 then
		if spk_t>0 then
			c=dz_cols2[ddz-1]
		else
			c=dz_cols[ddz-1]
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
-- proj
function proj_pov()
	if pp_rp2<100 then
		local c=7
		if story>0 then
			c=0
		elseif spk_t>0 then
			c=13
		end
		cls(c)
	end
	
	-- scrolling sky
	if story==1 and
				atk_t2>-90 then
		pov_scr_t=(pov_scr_t+1)%8
		for j=0,16 do
		for i=0,16 do
			spr(
				3,
				i*8-pov_scr_t,
				j*8-pov_scr_t)
		end end
	end
	
	local shx,shy=0,0
	if sh_t>0 then
		shx,shy=rnd()*sh_t,rnd()*sh_t
	end
	camera(shx,min(shy,0))
	
	if pp_rp2<100 and 
				atk_t2>-120 then
		local gh=64+pp_pi*1024
		gh=mid(0,gh,128)
		local c=15
		if(story==1)c=1
		if(story==2)c=5
		rectfill(
			-10,gh,
			137,gh+127,
			c)
			
		if story==0 then
			fillp(0b0111111110100001.1)
			rectfill(
				-10,gh-8,
				137,gh-5,
				15)
			fillp()
		
			map(
				0,
				0,
				-32+(pp_ya*256)%32,
				gh-8
			)
		end
	end
	
	if atk_t2>-90 and 
				mode!="ending" then
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
			//set_key_c(skl,{8,7})
			//proj_obj(skl)
			
	
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
	local fnd={}
	for j=sez-2,sez+2 do
	for i=sex-2,sez+2 do
		local id=i.."+"..j
		//loga({"id", id, rnd()})
		fnd[id]=true
		proj_s(i,j,min(abs(i),abs(j)))
	end end
	
	local sd=pltr2*src_sd
	for n=0,src_dp do
		local a=pp_ya-src_ag/2
		local am=src_ag/src_ns
		for s=0,src_ns do
			local aa=a+am*s
			local d=sd*n
			local d2=sd*(n+1)
			local x1=ppx+sin(aa)*d
			local z1=ppz+cos(aa)*d
			local x2=x1+sin(aa)*d2
			local z2=z1+cos(aa)*d2
			
			local i=flr(x2/(pltr2*secsz))
			local j=flr(z2/(pltr2*secsz))
			local id=i.."+"..j
			//loga({id})
			if fnd[id]==nil then
				fnd[id]=true
				
				proj_s(i,j,n)
			end
			
			if stop_rend() then
				return
			end
		end
	end
end

function proj_s(i,j,n)
	local sec=get_sec(i,j)
	if sec then
		for k,v in pairs(sec_d) do
			if n<v then
				for o in all(sec[k]) do
					sx,sy,dz=proj(o.x,o.y,o.z)
					if k=="sh" or 
								on_scr_x(sx) then
						//proj_obj(o,k=="sp")
						//proj_obj(o)
						//`local nf=
						proj_obj(o)
					end
					
					if stop_rend() then
						return
					end
				end
			end
		end
	end
end

--[[
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
]]--

function draw_sun(s)
	if story==0 then
		if spk_t>0 then
			circfill(
				s.pts[1].x,
				s.pts[1].y,
				10,
				9
			)
			circfill(
				s.pts[1].x,
				s.pts[1].y,
				8,
				0
			)	
		else
			c=9
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
		end
	else
		local k=keys[1]
		local sp=6
		if k.t<0.13 then
		sp=4
		circfill(
			s.pts[1].x,
			s.pts[1].y,
			10,
			0
		)
		end
		
		spr(
			sp,
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
		proj_obj(hand)
		if #keys>0 then
			proj_obj(keys[keyi])
		end
	end
end

function draw_rad()
	for i=1,pp_rp do
		pset(
			rand(0,127),
			rand(0,127),
			11)
	end
	for i=1,pp_rp2*5 do
		pset(
			rand(0,127),
			rand(0,127),
			0)
	end
end

function stop_rend()
	local tmax=80
	if hand_t>0 then
		if story==1 then
			tmax=40
		else
			tmax=60
		end
	end
	return n_t_sorted>tmax
end

--[[
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
	
	local chkd={}	
	local dpt=12
	if(hand_t>0)dpt=8
	for n=0,dpt do
		//local n=nn*1
		if n<2 then
			sec_s_n=20
			sec_s_a=0.25
		else
			sec_s_n=11
			sec_s_a=0.15
		end
	for ai=0,sec_s_n-1 do
		local a=sec_s_a*(ai/(sec_s_n-1))-(sec_s_a/2)
		n_sec_chk+=1
		
		line(
			pmx,pmz,
			pmx+sin(pp_ya-a)*n*10,
			pmz+cos(pp_ya-a)*n*10,
			1)
			
		local i=round(
			sex+sin(pp_ya+a)*n)
		local j=round(
			sez+cos(pp_ya+a)*n)
		
		local id=(j>>8)+i
		local sec=get_sec(i,j)
		if chkd[id] then
			//lol
		elseif sec then
			loga({"found",i,j,id})
			n_sec_fnd+=1
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
		
				for o in all(sec.sp)do
					sx,sy,dz=proj(o.x,o.y,o.z)
					loga({sx})
					if on_scr_x(sx) then
						pset(
							o.x/zm,
							o.z/zm,
							5)
					end
				end
				
				for sp in all(sec.ky)do
					pset(
						sp.x/zm,
						sp.z/zm,
						12)
				end
			end
		end
	end
	
	pria({ppx,ppz},
		pmx-64,pmz-64,8)
	pria({sex,sez},
		pmx-64,pmz-58,8)
end
]]--


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
		if story==0 then
		for o in all(sec.sp)do
			if(col_bb(po,o,-dx,0))can_x=false
			if(col_bb(po,o,0,-dz))can_z=false
		end end
		
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
			
			if dist(ppx,ppz,0,0)>hell_r then
				touch_r=true
				pp_rp+=1
			end
		end
		
		-- check term
		for t in all(sec.tr)do
			local d=dist(ppx,ppz,t.x,t.z)
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
				add(keys,k)
				del(sec.ky,k)
				key_t=60
				hand_t=0
				keyi=#keys
				if k.key_idx!=4 then
					music(16)
				end
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
	//camera(0,0)
	//spr(41,60,60,2,2)
	srand(term.seed)
	//fillp(0b0011001111001100)
	  //fillp(0b1111000000000000)
	rectfill(10,10,117,50,0)
	//fillp()
	
	for j=0,4 do
	for i=0,1 do
		spr(
			86+rand(0,3),
			2+i*116,
			13+j*8,
			1,1,
			i==1)
	end
	end
	
	for j=0,1 do
	for i=0,1 do
		spr(
			66+rand(0,3),
			5+110*i,
			5+43*j,
			1,1,
			i==1,j==1)
		spr(70+rand(0,3),5+111*i,5+44*j)
	end end
	
	for j=0,1 do
	for i=0,12 do
		spr(
			82+rand(0,3),
			13+i*8,
			5+43*j,
			1,1,
			false,j==1)
	end end
	
	-- lights
	for i=0,2 do
		spr(86+rand(0,3),5,67+i*8)
		spr(86+rand(0,3),4,67+i*8,1,1,true)
	end
	spr(100,4,62,2,1)
	spr(70,5,62)
	spr(100,4,88,2,1,false,true)
	spr(70,5,89)
	spr(
		term.act_t==0 and t_crt_t<15 and 114 or 115,
		5,70)
	spr(
		term.act_t>0 and flr(term.act_t/8)%2==0 and 98 or 99,
		5,81)
	
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
			proj_obj(o)
		end
	end
	
	proj_obj(term_h)
	
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
			//loga({"win"})
			
			-- change colors of 
			-- lock spikes
			for s in all(lock_sps)do
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

function spike(x,z,st,h,r,c1,c2)
	rx,rz=rand(-40,40),rand(-40,40)
	h=(h==nil and rand(-150,-80) or h)
	r=(r==nil and 10 or r)
	c1=(c1==nil and 0 or c1)
	c2=(c2==nil and 1 or c2)
	
	if st then
		rx,rz=0,0
	end
	
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
			p_to_s(0,0,-r),
			p_to_s(0,0,r),
			p_to_s(-h,0,0),
			5
		}
	}
	
	local o_sp=obj(
		sp_tris,
		x,0,z,
		0.75,0,0,
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
		x+r,0,z,
		0,0,0,
		0,0,
		nil
	)
	o_sh.h=h
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
		add(tri,""..x..","..y..",0")
	end
	add(tri,col)
	return tri
end

function add_me_area(ci,cj,r,up)
	local imin,imax=ci-r,ci+r
	local jmin,jmax=cj-r,cj+r
	
	local kr=max(0,r-2)
	local ki=ci+rand(-kr,kr)
	local kj=cj+rand(-kr,kr)
	
	for j=jmin,jmax do
		for i=imin,imax do
			//local sec=nsec()
		
			local sx=i*pltr2
			local sy=j*pltr2
			local rx=rand(-pltr,pltr)+sx+pltr
			local rz=rand(-pltr,pltr)+sy+pltr
			
			if j==kj and i==ki then
				if cur_me_key>0 then
					local kidx=area_ord[cur_me_key]
					local lk=keys_d[kidx]
					//loga({"lk",i,j,lk.n})
					local t=nil
					if lk then
						if(lk.n==4)t=pyr_tris
						if(lk.n==6)t=cube_tris
						if(lk.n==8)t=diam_tris
						if(lk.n==-1)t=swd_tris
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
					
						//add(sec.ky,o_key)
						place(i,j,"ky",o_key)
						cur_me_key+=1
					end
				end
			else
				local sp,sh=spike(rx,rz)
				sp.per=1
				sh.per=1
				if up==true then
					sp.per=0
					sh.per=0
				end
				//add(sec.sp,sp)
				//add(sec.sh,sh)
				place(i,j,"sp",sp,up)
				place(i,j,"sh",sh)
				
				place(i,j,"rs",{
					x=rx,z=rz,
					r=rand(20,30)
				})
			end
			
			//add(sec.rs,{
			//	x=rx,z=rz,
			//	r=rand(20,30)
			//})
			
			
			//if(lvl[j]==nil)lvl[j]={}
			//lvl[j][i]=sec
		end
	end
end

function add_me_sp(i,j,up)
	local rx=i*pltr2+pltr
	local rz=j*pltr2+pltr
	if up!=true then
		rx+=rand(-pltr,pltr)
		rz+=rand(-pltr,pltr)
	end
	//local sec=nsec()
	local sp,sh=spike(rx,rz,true)
	if up==true then
		sp.per=0
		sh.per=0
	end
	place(i,j,"sp",sp,up)
	place(i,j,"sh",sh)
	place(i,j,"rs",{
		x=rx,z=rz,
		r=rand(20,30)
	})
end

function add_lk_area(ci,cj)	
	local secs={{-1,0},{0,0},{1,0}}
	for c=1,3 do
		local s=secs[c]
		local j,i=s[1]+cj,s[2]+ci
		//local sec=nsec()
		local sp,sh,sy=spike(
			i*pltr2+pltr,
			j*pltr2+pltr,
			true,-10,2)
		sp.lock_n=lock_ord[c]
		sp.ft=1
		place(i,j,"sp",sp)
		place(i,j,"sh",sh)
		add(lock_sps,sp)
	end
	
	-- add terminal
	term=obj(
		tr_tris,
		(ci-1)*pltr2+pltr,0,cj*pltr2+pltr,
		0.75,0,0,
		5,5,
		nil
	)
	term.inpt={3,3,3}
	term.act_t=0
	place(
		ci-1,
		cj,
		"tr",
		term
	)
	term.seed=rand(0,30000)
	
	place(ci-1,cj,"sh",obj(
		tr_sh_tri,
		(ci-1)*pltr2+14+pltr,0,cj*pltr2+pltr,
		0,0,0,
		0,0,
		nil
	))
end

function add_hell_area()
	local sec=nsec()
	
	local bp,bs=spike(
		100,100,
		true,
		-100
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
			sx*pltr2*sp_hd,
			sz*pltr2*sp_hd,
			true,
			-100,nil,
			8,2)
		add(sec.sp,sp)
		add(sec.sh,sh)
		add(sec.rs,{
			x=sp.x,z=sp.z,
			r=20
		})
	end
	
	
	lvl["0+0"]=sec
	//lvl[0]={}
	//lvl[0][0]=sec
end

function add_db(i,j,a)
	local sx=i*pltr2+pltr
	local sy=j*pltr2+pltr
	local rx=rand(-pltr,pltr)+sx
	local rz=rand(-pltr,pltr)+sy
	//local sec=nsec()
	local db=obj(
		body_tris,
		rx,0,rz,
		a,0,0,
		0,0,
		nil
	)
	place(i,j,"db",db)
	place(i,j,"rs",{
		x=rx,z=rz,
		r=10
	})
	--[[
	add(sec.db,db)
	add(sec.rs,{
		x=rx,z=rz,
		r=10
	})
	if(lvl[j]==nil)lvl[j]={}
	lvl[j][i]=sec
	]]--
end

function place(i,j,k,o,up)
	i=flr(i/secsz)
	j=flr(j/secsz)
	local key=i.."+"..j
	if lvl[key]==nil then
		lvl[key]=nsec()
	end
	
	if(up==true)lvl[key].up=true
		
	add(lvl[key][k],o)
	
	return lvl[key],i,j
end
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

function clear_sfx()
	for i=0,63 do
		sfx(i,-2)
	end
end

function nsec()
	return {
		sp={},
		sh={},
		rs={},
		ky={},
		tr={},
		db={},
		up=false
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
	local id=i.."+"..j
	if lvl[id] then
		
		if lvl[id].up and spk_t==0 then
			return nil
		end
		
		return lvl[id]
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
	return x>-40 and 
								x<168 
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

function t2(s,x,y,c1,c2)
	for j in all({-1,1})do
		print(s,x,y+j,c2)
	end
	for i in all({-1,1})do
		print(s,x+i,y,c2)
	end
	print(s,x,y,c1)
end

--debug functions
--todo remove
--[[
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
]]--

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
	--[[
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
	]]--
	{ --arm 1
		"-1.5,2.5,0",
		"-1.2,8,0",
		"1.2,2.5,0"
	},
	{ --arm 2
		"1.2,2.5,0",
		"-1.2,8,0",
		"1.2,8,0"
	},
	{ --palm 1
		"-2,0,0",
		"2,0,0",
		"-1.5,2.5,0"
	},
	{ --palm 2
		"2,0,0",
		"1.2,2.5,0",
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
		"1.2,-3,0",
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
		13
	},
	{--front 2
		"-4,0,-4",
		"-4,-10,-4",
		"4,-10,-4",
		13
	},
	{--back 1
		"-4,0,4",
		"4,0,4",
		"4,-10,4",
		1
	},
	{--back 2
		"-4,0,4",
		"-4,-10,4",
		"4,-10,4",
		1
	},
	{--left 1
		"-4,0,-4",
		"-4,0,4",
		"-4,-10,-4",
		1
	},
	{--left 2
		"-4,0,4",
		"-4,-10,4",
		"-4,-10,-4",
		1
	},
	{--right 1
		"4,0,-4",
		"4,0,4",
		"4,-10,-4",
		13
	},
	{--right 2
		"4,0,4",
		"4,-10,4",
		"4,-10,-4",
		13
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
	},
	{--top 1
		"-1,1,-1",
		"-1,1,1",
		"1,1,1",
		6
	},
	{--top 2
		"-1,1,-1",
		"1,1,-1",
		"1,1,1",
		6
	},
	{--bot 1
		"-1,-1,-1",
		"-1,-1,1",
		"1,-1,1",
		6
	},
	{--bot 2
		"-1,-1,-1",
		"1,-1,-1",
		"1,-1,1",
		6
	},
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

epls={
	"this place is a message.",
	"and part of a system\nof messages.",
	"pay attention to it.",
	"",
	"sending this message was\nimportant to us.",
	"we considered ourselves to\nbe a powerful culture.",
	"", 
	"this place is not a place\nof honor.",
	"no highly esteemed deed is\ncommemorated here.",
	"nothing valued is here.",
	"",
	"what is here was dangerous\nand repulsive to us.",
	"this message is a warning\nabout danger.", 
	"",
	"the danger is in a particular\nlocation.",
	"it increases towards a\ncenter.",
	"the center of\ndanger is here.",
	"of a particular size and shape,\nand below us.",
	"",
	"the danger is still present\nin your time, as it was\nin ours.",
	"",
	"the danger is to the body,\nand it can kill.",
	"",
	"the form of the danger is\nan emanation of energy.",
	"",
	"the danger is unleashed\nonly if you substantially\ndisturb this place physically.",
	"",
	"this place is best shunned\nand left uninhabited.",
	"",
	"",
	"",
	"",
	"      menacing earthworks",
	"",
	"",
	"a game by\nraf & ryan @ goldteam",
	"",
	"playtesters:",
	"jacob    nick\njane     ana",
	"",
	"",
	"inspired by studies on nuclear\nsemiotics by the american\ninterference task force.",
	"text is credited to the 1993\nreport on nuclear semiotics by\nsandia national laboratories.",
	"",
	"",
	"",
	"",
	"",
	"thanks for playing."
}

body_tris={
	{ -- left forearm
		"-7,0,-8",
		"-5,0,-4.5",
		"-5,0,-4.5",
		"-5,0,-5"
	},
	{ --left upper arm
		"-5,0,-4.5",
		"-5,0,-5",
		"-2,0,-6"
	},
	{ -- right forearm
		"6,0,0",
		"4.5,0,-3",
		"5,0,-3.5"
	},
	{ -- right upper arm
		"4.5,0,-3",
		"5,0,-3.5",
		"2,0,-6"
	},
	{ -- spine
		"-0.2,0,0",
		"-0.2,0,-7",
		"0.2,0,0"
	},
	{
		"-0.2,0,-7",
		"0.2,0,-7",
		"0.2,0,0"
	},
	{ -- collar
		"-2,0,-6",
		"2,0,-6",
		"0,0,-5"
	},
	{ -- left ribs
		"-2,-0.5,-5",
		"0,0,-5",
		"0,0,-4.5"
	},
	{
		"-2,-0.6,-4.5",
		"0,0,-4.5",
		"0,0,-4"
	},
	{
		"-2,-0.5,-4",
		"0,0,-4",
		"0,0,-3.5"
	},
	{
		"-2,-0.6,-3.5",
		"0,0,-3.5",
		"0,0,-3"
	},
	{
		"-2,-0.5,-3",
		"0,0,-3",
		"0,0,-2.5"
	},
	{ -- right ribs
		"2,-0.6,-5",
		"0,0,-5",
		"0,0,-4.5"
	},
	{
		"2,-0.7,-4.5",
		"0,0,-4.5",
		"0,0,-4"
	},
	{
		"2,-0.5,-4",
		"0,0,-4",
		"0,0,-3.5"
	},
	{
		"2,-0.7,-3.5",
		"0,0,-3.5",
		"0,0,-3"
	},
	{
		"2,-0.5,-3",
		"0,0,-3",
		"0,0,-2.5"
	},
	{ -- left pelvis
		"-2,0,-1.5",
		"0,0,-1",
		"0,0,0",
	},
	{
		"-0.8,0,-1",
		"0,0,0",
		"-1.5,0,0.5"
	},
	{ -- right pelvis
		"2,0,-1.5",
		"0,0,-1",
		"0,0,0",
	},
	{
		"0.8,0,-1",
		"0,0,0",
		"1.5,0,0.5"
	},
	{ -- left upper leg
		"-1,0,0",
		"-6,0,1",
		"-5,0,1.5"
	},
	{ -- left lower leg
		"-6,0,1",
		"-5,0,1",
		"-7,0,6"
	},
	{ -- right upper leg
		"1,0,0",
		"2.25,0,6",
		"3,0,6"
	},
	{ -- right lower leg
		"2.25,0,6",
		"3,0,6",
		"4,0,10"
	},
	{ -- left skull
		"0,0,-9.5",
		"-1,0,-9",
		"0,0,-7.5"
	},
	{
		"-1,0,-9",
		"0,0,-7.5",
		"-1,0,-8"
	},
	{
		"-1,0,-7.7",
		"0,0,-7.3",
		"0,0,-7"
	},
	{ -- right skull
		"0,0,-9.5",
		"1,0,-9",
		"0,0,-7.5"
	},
	{
		"1,0,-9",
		"0,0,-7.5",
		"1,0,-8"
	},
	{
		"1,0,-7.7",
		"0,0,-7.3",
		"0,0,-7"
	},
	{	-- left eye
		"-0.8,-0.1,-8.8",
		"-0.4,-0.1,-8.8",
		"-0.6,-0.1,-8.4",
		11
	},
	{	-- right eye
		"0.8,-0.1,-8.8",
		"0.4,-0.1,-8.8",
		"0.6,-0.1,-8.4",
		11
	}
}

--[[
body_tris_f={
	{ -- left forearm
		"-6,0,-8",
		"-5,0,-8",
		"-4,0,-4"
	},
	{ -- left upper arm
		"-4,0,-4",
		"-4,0,-5",
		"-1,0,-6"
	},
	{
		"-4,0,-4",
		"-1,0,-6",
		"-1,0,-5"
	},	
	{ -- torso
		"-1,0,-6",
		"-1,0,-1",
		"2,0,-1"
	},
	{
		"-1,0,-6",
		"1,0,-6",
		"2,0,-1"
	},
	{ -- right arm
		"1,0,-6",
		"1,0,-5",
		"6,0,-1"
	},
	{
		"1,0,-6",
		"6,0,-1",
		"6,0,-2"
	},
	{ -- left upper leg
		"-1,0,-1",
		"2,0,-1",
		"-3,0,1"
	},
	{ -- left lower leg
		"-2,0,0",
		"-3,0,1",
		"-2,0,6"
	},
	{
		"-3,0,1",
		"-3,0,5",
		"-2,0,6"
	},
	{ -- left foot
		"-5,0,6",
		"-3,0,5",
		"-2,0,6"
	},
	{ -- right leg
		"1,0,-1",
		"3,0,7",
		"4,0,7"
	},
	{
		"1,0,-1",
		"2,0,-1",
		"4,0,7"
	},
	{ -- right foot
		"3,0,7",
		"4,0,7",
		"6,0,8"
	},
	{ -- head
		"1,0,-7",
		"1,0,-9",
		"-1,0,-9"
	},
	{
		"1,0,-7",
		"-1,0,-7",
		"-1,0,-9"
	}
}
]]--

__gfx__
00000000009999000000800001100000000000555550000000000011111000000000000000000000000000000000000000000000000000000000000000000000
00000000090000900000880000110000000055555555000000001111111100000000900000090000000000000000000000000000000000000000000000000000
00700700900990098888888000110000000555555555500000011111111110000009900000099000000000000000000000000000000000000000000000000000
00077000909009098888888800011110005555555555500000111111111110000099990000999900000000000000000000000000000000000000009000000000
0007700090900909888888800000111100555000000005000011100000000100099999000099999000000000000000000000000000000000009000f900000000
007007009009909000008800100000010055500000000500001110000000010009999900009999900000000000000000000000000000000009900fff00000000
0000000009000000000080001000000100550000000005000011000000000100999990099009999900000000000000000000000000000000ff990fff00000000
0000000000999990000000001000000000550555055505000011001000100100000000999900000000000000000000000000000000000000fff99fff00000000
00000000000000000666666000000000005000500050050000100111011101000000009999000000000000000000000044444444444444440000000000000000
00000000000000006000000600000000005000005000050000100000100001000000000990000000000000000000000040000000000000040000900000090000
00000000000000006066066600000000000550005000550000010000000001000000000000000000000000000000000040009000000900040009900000099000
00000000000000006007007600000000000505000005050000010001110001000000009999000000000000000000000040099900009990040099990000999900
00000000000000006000000600000000000500555550050000010010001001000000099999900000000000000000000040099990099990040999990000999990
00000000000000000607777600000000000050000000500000001011111010000000999999990000000000000000000040099909909990040999990000999990
00000000000000000600000600000000000050000000500000001000000010000000999999990000000000000000000040000009900000049999900990099999
00000000000000000066666000000000000005555555000000000111111100000000009999000000000000000000000040000000000000040000009999000000
00010000000700000007000000070000000700000007000000070000000700000007000000070000000700000000000040000009900000040000009999000000
01010100000000000000000000000000000000000700070007070700070707000707070007070700070007000000000040000099990000040000000990000000
00111000000700000007000000070000000700000007000000077000000770000007700000777000000000000000000040000099990000040000000000000000
11111110007770000077707000777070707770707077707077777770777777707777777077777770700000700000000040000000000000040000009999000000
00111000000700000007000000070000000700000007000000070000000770000077700000777000000000000000000044444444444444440000099999900000
01010100000000000000000000000000000000000700070007070700070707000707070007070700070007000000000000000000000000000000999999990000
00010000000000000000000000070000000700000007000000070000000700000007000000070000000700000000000000000000000000000000999999990000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999000000
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
000000000000000000ddd00000ddd000005555500000000000ddd00000ddd0000000000000000000000000000000000000000000000000000000000000000000
00022222222220000dbbbd000d333d0005555555000000000d666d000dcccd000000000000009000000000000000000000000000000000000000000000000000
0022222222222200dbbbbbd0d33333d05555555550000000d66666d0dcccccd00000000000f99900000000000000000000000000000000000000000000000000
0222222222222220dbbb7bd0d33353d05555555550000000d66656d0dccc7cd000090000ffff9900000000900000000900000000000000000000000000000000
0222eeeeeeee2220dbb77bd0d33553d05555555550000000d66556d0dcc77cd000f99009fffff990009000f9000000f900000000000000000000000000000000
0222e222222e22200dbbbd000d333d0000000000000000000d666d000dcccd000f99990f9fffff9909900fff99000ff900000000000000000000000000000000
02222e2222e2222000ddd00000ddd000000000000000000000ddd00000ddd0000fff999ff9fffff9ff990fff9fff9fff00000000000000000000000000000000
022222e22e222220000000000000000000000000000000000000000000000000ffffffffff9ffffffff99ffffffff9ff00000000000000000000000000000000
0222222ee222222000ddd00000ddd0000000000000000000000000000000000000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
02222222222222200d888d000d222d00000000000000600000000000000000000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
0d22222222222210d88888d0d22222d0000000000066f6000000000000000000aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
0dd2222222222110d88878d0d22252d000060000fffff6000000006000000060aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
00ddddd1d11d1100d88778d0d22552d0006f600fffffff60006000f600000f60aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
000dddd1d11d10000d888d000d222d000fff6fffffffff600f600fff6000fff6aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
000000000000000000ddd00000ddd0000ffff6fffffffff6fff60ffff6ffffffaaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
00000000000000000000000000000000ffffff6ffffffff6ffffffffffffffff0aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111700000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111700000000002222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111170000000022222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111170000000222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111177000002222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111177000000002222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111177000000000000222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111177700000000000000022222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111177700000000000000000002222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111177700000000000000000000000222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111117770000000000000000000000000022222222222200000000000000000000000000000000000000000000000000000000000000000000000000000
01111111117770000000000000000000000000000002222222222200000000000000000000000000000000000000000000000000000000000000000000000000
11111111117770000000000000000000000000000000000222222222200000000000000000000000000000000000000000000000000000000000000000000000
11111111117777000000000000000000000000000000000000022222222000000000000000000000000000000000000000000000000000000000000000000000
11111111117777000000000000000000000000000000000000000002222222000000000000000000000000000000000000000000000000000000000000000000
11111111117770000000000000000000000000000000000000000000000222222000000000000000000000000000000000000000000000000000000000000000
00001111117700000000000000000000000000000000000000000000000000022222000000000000000000000000000000000000000000000000000000000000
00000000117000000000000000000000000000000000000000000000000000000002220000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777100000007777777777777777177777100077777710000000000000007777777777777777777710007777771077777777710000000000000000000000000
07777100000077771007777100777107777100000771000000000000000077777777771777710777710000077100777777777710000000000000000000000000
00777710000077771000777100007100777710000771000000000000000777100007771077710077771000077107771000077710000000000000000000000000
00777710000777771000777100000000777771000771000000000000007771000000771077710077777100077177710000007710000000000000000000000000
00777771000777771000777100071000777777100771000000000000007771000000771077710077777710077177710000000710000000000000000000000000
00777771000777771000777100771000771777100771000000000000007771000000071077710077177710077777710000000000000000000000000000000000
00777777007717771000777777771000771777710771000000000000077771000000000077710077177771077777710000777777000000000000000000000000
00771777007717771000777777771000771077770771000000000000077771000000000077710077107777177777710000777771000000000000000000000000
00771777777107771000777100071000771007777771000000000000077771000000000077710077100777777777710000077710000000000000000000000000
00771077777107771000777100000000771000777771000000000000007771000000000077710077100077777177710000077710000000000000000000000000
00771077771007771000777100000710771000077771000000000000007771000000000077710077100007777177710000077710000000000000000000000000
00771077771007771000777100007710771000077771000000000000007777100000077177710077100007777107771000077710000000000000000000000000
00771007771007771007777100777710771000007771000000000000000777777107771077710077710000777107777710077710000000000000000000000000
77777717710777777777777777777777777710000771000000000000000007777777710777771777771000077100077777777100000000000000000000000000
77777710710777777777777777777177777710000071000000000000000000000000777777771777771000007100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007777710000000000000000000000000000000000000000000000000000000
77777777710007710000777777771077777777777777177777777777777007777177777777177777777107777777777177777710000000000000000000000000
07771007710007771000077717771077177717717771007771077710770007710771000777107771777100777107710077107710000000000000000000000000
07771007710007771000077710777171077710717771007771077710777007717771000077717771077710777177100777100710000000000000000000000000
07771077100077777100077710777100077710007771007771007710777007717771000077717771077710777771000077710710000000000000000000000000
07777777100070777100077777771000077710007777777771007771777777107771000077717777777100777771000077771000000000000000000000000000
07777777100770077100077777710000077710007777777771007777777777107771000077717777771000777771000007777710000000000000000000000000
07771007100777777710077777710000077710007771007771000777717771007771000077717777771000777777100000077710000000000000000000000000
07771000717710007710077717771000077710007771007771000777107771000771000077107771777100777177710710007771000000000000000000000000
07771007717710007771077710777100077710007771007771000777107771000777100777107771077710777107771771007771000000000000000000000000
77777777777771077777777771777710777771077777177777100077100710000077777771077777177777777777777777777710000000000000000000000000
77777777777771077777777771077710777771077777177777100071000710000000000000077777107777777777777777777100000000000000000000000000
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

__map__
68696a6b68696a6b68696a6b68696a6b68696a6b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0b1000000017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170
260800003f6503f6503e6403d630336303263031630246302c63018630206300c6300863000630006300063000620006200062000620006100061000610006100061000610006100061000610006000060000600
420600003c6533c600376433760030653306002b6432b60024643246001f6331f60018643186001363313600186231860013623136000c6230c60007613076000061024000006102400000610000000000000000
900600003e6453e645000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9005000023624236302d6302d6253960039600000000000021624216302b6302b625376000000000000000001f6241f6302d6302d625000000000000000000001d6241d6302b6302b62500000000000000000000
950c00002321423220232302324023250232502325023250232502325023250232502324023230232202321023210232102321023210232102321023210232102321023210232102321523200232002320023200
150c00000a8000a8000a8000a80009844098400985009850098600986009860098600986009860098600986009850098500984009840098300983009820098200981009810098100981009810098100981009815
a9060000003750034500325003150c3053630537305363050c8700c8700b8610b8610a8610a861098510985108851088510784107831068210681105821048110381102811018110081000800008000080000800
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
2d1200010107007000070000700007000070000700007000162001620016200162001620016200162001620016200162001620016200162001620016200162001720017200172001720017200092000920009200
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

