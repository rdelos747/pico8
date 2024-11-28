pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- jumper 2
-- 2024-11-27
ver="0.1.6"

--constants and globals
p_spd=1
p_accel=0.3		 --fall accel (0.3)
p_f_max=4				 --fall spd max (4)
p_j_max=-2.5	 --jump spd max (-2.5)
p_j_fre=1   	 --num free jumps
p_j_t_max=5 	 --jump frames
p_w_spd=0.3 		--water fill speed

chl=0 --checkpoint lvl
crl=0 --current lvl

-- enemy constants
ice_t_slow=70 --ice spawn time slow
ice_t_fast=30 --ice spawn time fast

cltb=0 --cloud time back
cltf=0 --cloud time front

logo_t=0
auto_save=1
tot_d=0

function _init()
	printh("=====start=====")
	cartdata("gt_jump_correctly_1")
	
	pp=obj(-1,-1,3,5)
	chl=dget(0)
	auto_save=dget(1)
	tot_d=dget(2)
	printh("load save 0 "..chl)
	printh("load save 1 "..auto_save)
	printh("load save 2 "..tot_d)
	
	reset_checkpoint()
	
	menuitem(
		1,
		"save game",
		save_game
	)
	
	menuitem(
		2,
		"auto save "..(auto_save==1 and "on" or "off"),
		toggle_auto_save
	)
	
	menuitem(
		3,
		"clear save data",
		clear_save
	)
end

function reset_checkpoint()
	printh("reseting from checkpoint")
	uits,l_uits=-0.1,-1 --ui time slow
	uitf,l_uitf=-0.1,-1 --ui time fast
	
	pvy=0  			   --vel y
	pdrx=1 			   --dir x
	pdry=0 			   --dir y
	pmt=0  			   --move time
	pjmp=0 			   --current jump
	pjp=true     --jump pressed
	pjmpt=0      --jump time
	ptank=1 		   --num water tanks (this will probably never get higher)
	pwater=0 	   --amt water
	pst=false    --show empty tank icon
	pwt=0					   --water time
	ptw=false    --touching water
	pdig=false   --is digging
	pdt=0				 	  --digging time
	pseed=0				  --seeds
	psht=false   --shooting
	ptswch=false --touching switch
	
	dth_t=-1					--death time
	dth_e=nil				--death object
	
	crl=chl
	if(auto_save==1)save_game()
		
	init_lvl()	
end

function _draw()
	cls()
	camera(cmx,cmy)
	
	draw_clouds()
	
	if logo_t<50 then
		draw_logo()
		return
	end
	
	if dth_t!=-1 then
		if dth_e and dth_e.draw then
			dth_e.draw(dth_e)
		end
		for e in all(effs)do
			e.draw(e)
		end
		return
	end
	
	draw_bk()
	
	for e in all(enemies)do
		if(e.draw)e.draw(e)
	end
	
	map(0,0)
	
	if not tp_out then
		draw_player()
	end
	//printh(cmi.." "..cmj.." "..cmx.." "..cmy)
	
	draw_fg()
	for b in all(bullets)do
		b.draw(b)
	end
	
	
	for e in all(effs)do
		e.draw(e)
	end
	
	draw_water_tanks()
	
	draw_hud()
end

function _update()
	l_uits,uits=uits,(uits+0.1)%30
	l_uitf,uitf=uitf,(uitf+0.2)%30
	cltb=(cltb+0.7)%136
	cltf=(cltf+1)%136
	
	if scr_wrap and 
				flr(uits%3)==0 and
				flr(l_uits%3)!=0 then
		for i=0,16 do
			add_wrap(cmx,cmy+i*8,1)
			add_wrap(cmx+127,cmy+i*8,-1)
		end
	end
	
	if logo_t<50 then
		logo_t+=1
		if(btnp(❎))logo_t+=25
		return
	end
	
	update_clds()
	
	for e in all(effs)do
		e.update(e)
	end
	
	if dth_t>=0 then
		dth_t-=1
		if(dth_t==0)reset_checkpoint()
		return
	end
	
	for e in all(enemies)do
		e.tswch=false
		if(e.update)e.update(e)
	end
	
	update_lvl()
	update_bullets()
	
	if tp_out then
		update_tp_out()
	else
		update_player()
	end
end

function comb(a,b)
	for k,v in pairs(b)do
		a[k]=v
	end
end

function obj(x,y,w,h,ext)
	o={x=x,y=y,w=w,h=h}
	comb(o,ext)
	return o
end

function eff(x,y,d,u,ext)
	o={x=x,y=y,draw=d,update=u}
	comb(o,ext)
	return o
end

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function draw_bb(o)
	rect(
		o.x-o.w/2,
		o.y-o.h/2,
		o.x+o.w/2,
		o.y+o.h/2,
		8)	
end

function col_bb(a,b)
	if b.w==0 or b.h==0 then
		return false
	end
	local ax=a.x-a.w/2
	local ay=a.y-a.h/2
	local bx=b.x-b.w/2
	local by=b.y-b.h/2
	
	return ax<=bx+b.w and
		ax+a.w>=bx and ay<=by+b.h and
		ay+a.h>=by
end

function on_layer(o,ox,oy,lrs)
	if type(lrs)!="table" then
		lrs={lrs}
	end
	
	local a=obj(o.x+ox,o.y+oy,o.w,o.h)
	local mi=flr(a.x/8)
	local mj=flr(a.y/8)
	
	for j=min(cmj+15,mj+1),max(cmj,mj-1),-1 do
	for ii=mi-1,mi+1 do
		local i=ii%16+cmi
		for f in all(lrs) do
			local s=mget(i,j)
			if fget(s,f) then
				local aa=a
				if scr_wrap then
					aa=obj(
						a.x%128+cmx,
						a.y,a.w,a.h)
				end
				local b=obj(
					i*8+4,j*8+4,8,8,{s=s}
				)
				if col_bb(aa,b) then
					return b
				end
			end
		end
	end end
	return nil
end

function on_scr(o)
	return o.y<cmy+137 and 
								o.y>cmy-4 and
			 				o.x<cmx+137 and 
			 				o.x>cmx-4
end

function round(n)
	if n-flr(n)>=0.5 then
		return flr(n)+1
	end
	return flr(n)
end

function lerp(a,b,t)
 return a+(b-a)*t
end

function clear_map_at(x,y)
	mset(flr(x/8),flr(y/8),0)
end

function draw_logo()
	local f=min(logo_t/25,1)
	for i=1,4 do
		spr(
			124+i-1,
			cmx+60+f*8*i-4*f,
			cmy+60)
		spr(
			124-i,
			cmx+60-f*8*i+4*f,
			cmy+60)
	end
end

function toggle_auto_save(i)
	if i==1 or i==2 then
		return
	end
	auto_save=(auto_save+1)%2
	printh("set auto save ")
	printh(auto_save)
	dset(1,auto_save)
	//add sfx here
	menuitem(
		2,
		"auto save "..(auto_save==1 and "on" or "off"),
		toggle_auto_save
	)
end

function save_game(i)
	if i==1 or i==2 then
		return
	end
	printh("set save 0 "..chl)
	printh("set save 2 "..tot_d)
	dset(0,chl)
	dset(2,tot_d)
	//add sfx here
end

function clear_save(i)
	if i==1 or i==2 then
		return
	end
	
	printh("clear save 0")
	printh("clear save 2")
	dset(0,0)
	dset(2,0)
end
-->8
--player
function draw_player()
	local off=(ptswch and 2 or 0)
	sspr(
		8,pdry*4+12,
		4,4,
		pp.x-2,pp.y-3+flr(pdt/3)%2-off,
		4,4,
		pdrx==-1
	)
	
	sspr(
		12,flr(pmt)%2*2+8,
		4,2,
		pp.x-2,pp.y+1-off,
		4,2,
		pmt<2
	)	
	//draw_bb(pp)
		
	if pp.x>cmx+128 then
		spr(13,cmx+120,pp.y-4)
	elseif pp.x<cmx-1 then
		spr(13,cmx+2,pp.y-4,1,1,true)
	end
	
	if ptw then
		sspr(
			16,13+flr(uitf)%3*3,
			8,3,
			pp.x-4,pp.y-5)	
	end
	
	--[[
	draw_bb(
		{x=pp.x,y=pp.y+4,w=3,h=1}
	)
	]]--
end

function update_player()
	local move=false
	pdry=0
	if(btn(➡️))move,pdrx=true,1
	if(btn(⬅️))move,pdrx=true,-1
	if(btn(⬆️))pdry=-1
	if(btn(⬇️))pdry=1
	
	if move then
		pmt-=0.15
		if(pmt<0)pmt=4
		if not on_layer(pp,pdrx,0,0) then
			pp.x+=p_spd*pdrx
		end
	else
		pmt=0
		pp.x=flr(pp.x)
	end
	
	if scr_wrap then
		if(pp.x<cmx-1)pp.x=cmx+127
		if(pp.x>cmx+127)pp.x=cmx
	end
	
	--jump
	if btn(🅾️) then
		if not pjp then
			pjp=true
			if (pjmp<p_j_fre or
							flr(pwater/3)>0) then
				if pjmp>=p_j_fre and pwater>2 then
					pwater-=3
					if pwater==0 then
						pst=true
					end
				end
				pjmpt=p_j_t_max
				//pvy=p_j_max
				pjmp+=1
				add_jump(pp.x-1,pp.y)
			end
		end
		if pjmpt>0 then
			pvy=p_j_max
		end
		pjmpt=max(0,pjmpt-1)
	else
		pjmpt=0
		pjp=false
	end
	
	--fall
	pvy=min(p_f_max,pvy+p_accel)
	if pvy<0 then 
		if on_layer(pp,0,-2,0) then
			pvy=0.5
		end
	else 
		local t=on_layer(
			pp,0,max(1,pvy),{0,1})
		if t!=nil and t.y-pp.y>4 then
			if pvy>p_accel then
				//printh("landed")
			end
			pp.y=(flr(pp.y/8)*8)+5	
			pjmp=0
			pvy=0
			pst=false
			
			if t.s==76 then
				set_cld(t.x,t.y)
			end
		end
	end
	pp.y+=pvy
	
	--shoot
	if btn(❎) then
		if not psht and pseed>0 then
			psht=true
			pseed-=1
			local dx=pdrx
			if(pdry!=0)dx=0	
			add_get(pp.x+2,pp.y,pseed)
			add_bullet(
				pp.x+dx*5,pp.y+pdry*5,
				dx*4,pdry*4,false,7,true)
		end
	else
		psht=false
	end
	
	--touch water
	--note: timer doesnt
	--reset when player
	--leaves water
	ptw=false
	for w in all(waters) do
		if(col_bb(pp,w))ptw=true
	end
	if ptw then
		pwt+=p_w_spd
		if pwt>=1 then
			pwt=0
			if pwater/3<ptank then
				pwater+=1
				pst=false
			end
		end
	end
	
	if pp.y>cmy+136 then
		//reset_checkpoint()
		kill_plr()
		return
	end
	
	--touch enemy
	for e in all(enemies)do
		if e.can_hurt and col_bb(pp,e) then
			//reset_checkpoint()
			kill_plr(e)
			return
		end
	end
	
	for b in all(bullets)do
		if col_bb(pp,b) then
			//reset_checkpoint()
			kill_plr(b)
			return
		end
	end
	
	--touch key
	for k in all(keys)do
		if not k.p and col_bb(pp,k) then
			k.p=true
		end
	end
	
	--touch door
	for d in all(doors)do
		if col_bb(pp,d) and (btn(⬇️) or btn(⬆️))then
			local can=true
			for k in all(keys)do
				if k.p==false then
					can=false
				end
			end
			
			if can then
				for k in all(keys)do
					del(keys,k)
				end
				crl+=1
				tp_out=true
				tpt=10
				add_b_exp(pp.x,pp.y,10,10)
				
				return
			end
		end
	end
	
	--touch flower
	local flwr=nil
	for f in all(flwrs)do
		if col_bb(pp,f) and pdry==1 then
			flwr=f
		end
	end
	
	if flwr==nil then
		pdig=false
		pdt=0
	else
		if pdig==false then
			pdt=10
		end
		pdig=true
		if pdt%5==0 then
			add_dig(pp.x,pp.y+4)
		end
		if pdt<=0 then
			del(flwrs,flwr)
			pseed+=flwr.s
			add_get(pp.x,pp.y,"+"..flwr.s)
		end
		pdt-=1
	end
end

function kill_plr(o)
	tot_d+=1
	dth_e=o
	dth_t=30
	add_b_exp(
		mid(cmx,pp.x,cmx+127),
		mid(cmy,pp.y,cmy+127),
		10,10)
end
-->8
--hud/general

function draw_hud()
	--rectfill(cmx,cmy,cmx+127,cmy+6,0)
	--free jumps
	--[[
	for i=0,p_j_fre-1 do
		if pjmp>i then
			pal(7,1)
			pal(12,1)
		end
		sspr(44,8,3,6,cmx+i*5,cmy)
		pal()
	end
	]]--
	
	--tanks
	--[[
	for i=1,ptank do
		local nw=mid(
			0,
			pwater-(ptank*3-i*3),
			3)
		if nw==0 then
			sspr(0,8,6,6,cmx+8+(i*6),cmy+1)
		else
			sspr(
				16+8*(nw-1)+(flr(uits)%2)*4,8,
				5,5,cmx+8+i*6,cmy+1)
		end
	end
	]]--
	print(crl+1,cmx+64,cmy,7)
	print(tot_d,cmx+74,cmy,7)
	print(ver,cmx+100,cmy,7)
end

function draw_water_tanks()
	local ofx=3
	if(pdrx==-1)ofx=-8
	if pst then
		sspr(0,8,6,6,pp.x+ofx,pp.y-6)
	elseif pwater>0 then
		sspr(
			16+8*(pwater-1)+(flr(uits)%2)*4,8,
			5,5,pp.x+ofx,pp.y-6)
	end
end

clds_b={
"00000002234002000",
"00000031111631420",
"20034311111111114",
"14311111111111111"
}
clds_f={
"00000023400562000",
"20022311143111456",
"14311111111111111"
}
function draw_clouds()
	rectfill(cmx,cmy+112,cmx+128,cmy+128,1)
	draw_cloud_layer(clds_b,72,cltb)
	rectfill(cmx,cmy+120,cmx+128,cmy+128,13)
	pal(1,13)
	draw_cloud_layer(clds_f,88,cltf)
	pal()
end

function draw_cloud_layer(arr,y,t)
	for j=1,#arr do
		for i=0,16 do
			local x=i*8-t
			if(x<-8)x+=136
			spr(arr[j][i+1],cmx+x,cmy+y+j*8)
		end
	end
end
-->8
--map functions

key_cols={10,11,12,8}

function init_lvl()
	reload(0x2000, 0x2000, 0x1000)
	waters={}
	ftns={}
	keys={}
	doors={}
	flwrs={}
	swchs={}
	swch_cs={}
	sw_blks={}
	clds={}
	
	sw_state=false
	sw_state_c=false
	scr_wrap=false
	
	bullets={}
	effs={}	
	enemies={}	
	--current map tile i,j
	cmi=crl%8*16
	cmj=flr(crl/8)*16
	--current map x,y
	cmx,cmy=cmi*8,cmj*8
	
	printh("init lvl: "..crl..", "..cmi.." "..cmj)
	
	local inf_ftns={}
	
	for j=0,15 do
	for i=0,15 do
		local s=mget(cmi+i,cmj+j)
		local fl=fget(s)
		local sn=mget(cmi+i,cmj+max(j-1,0))
		local ss=mget(cmi+i,cmj+min(j+1,15))
		local sw=mget(cmi+max(i-1,0),cmj+j)
		local se=mget(cmi+min(i+1,15),cmj+j)

		local x,y=cmx+i*8,cmy+j*8
		
		if s>=93 and s<=95 then
			--fountains
			local on_t,off_t=7,0
			if(s==94)on_t,off_t=30,30
			if(s==95)on_t,off_t=10,10
			if(s==93)add(inf_ftns,{x=x,y=y})
			add(ftns,{
				x=x,y=y,
				t=-1,on_t=on_t,off_t=off_t
			})
			mset(cmi+i,cmj+j,79)
		elseif s==109 or s==110 then
			add(sw_blks,{
				cmi+i,cmj+j,s==110
			})
		elseif fl==0 then
			-- items created in this
			-- block will clear the
			-- original map tile
			mset(cmi+i,cmj+j,0)
			
			if s==107 then
				--spikes
				local off,f=5,false
				if fget(sn,0) then
					off,f=2,true
				end
				add_enemy(
					x+4,y+off,8,4,
					draw_spike,
					nil,
					false,
					true,
					{f=f}
				)
			elseif s==53 then
				--circle spikes
				add_enemy(
					x+4,y+4,7,7,
					draw_c_spike,
					nil,
					false,
					true
				)
			elseif s==22 then
				--keys
				add(keys,obj(
					x+4,y+4,4,4,
					{p=false}
				))
			elseif s==23 then
				--doors
				add(doors,obj(x+4,y+4,10,10))
			elseif s==24 or s==25 then
				--flower 5 seed
				add(flwrs,obj(x+4,y+4,6,8,{s=s==24 and 5 or 1}))
			elseif s==48 or s==49 then
				-- checkpoints and teleports
				pp.x,pp.y=x+4,y+5
				add_b_exp(pp.x,pp.y,10,10)
				--[[
				if s==49 then
					chl=crl
				end
				]]--
			elseif s==50 or s==51 then
				-- slimes
				add_enemy(
					x+4,y+4,4,6,
					draw_slime,
					update_slime,
					true,
					true,
					{fast=s==51}
				)
			elseif s==52 then
				-- cacti
				add_enemy(
					x+4,y+4,7,8,
					draw_cactus,
					update_cactus,
					true,
					true
				)
			elseif s==55 or s==56 then
				-- moles
				add_enemy(
					x+4,y+4,5,6,
					draw_mole,
					update_mole,
					true,
					true,
					{j=s==56,tm=15}
				)
			elseif s==35 then
				-- switches
				add(swchs,obj(
					x+4,y+6,8,3))
			elseif s==37 then
				-- switch coins
				add(swch_cs,obj(
					x+4,y+6,7,7))
			elseif s==102 or s==103 then
				-- icicles
				add_enemy(
					x+4,y-4,0,0,
					nil,
					update_ice_spwn,
					false,
					false,
					{tm=s==102 and ice_t_slow or ice_t_fast}
				)
			elseif (s>=40 and s<=44) or
										(s>=57 and s<=60) then
				-- flame spaner
				local drs={
					nil,
					{1,0},{-1,0},{0,-1},{0,1}
				}
				local spd=0.8 -- slow speed
				if s==40 then
					spd=2 -- tracker speed
				elseif s>45 then
					spd=1.6 -- fast speed
				end
				local e=add_enemy(
					x,y,0,0,
					draw_flame_spawn,
					update_flame_spawn,
					false,
					false,
					{
						tm=0,
						dr=s<45 and drs[s-39] or drs[s-55],
						flt=not fget(ss,0),
						spd=spd
					}
				)
				printh(s-39)
				printh(drs[s-39])
			elseif s==11 then
				scr_wrap=true
			elseif s==61 then
				add_enemy(
					x+4,y+4,8,6,
					draw_shroom,
					update_shroom,
					true,
					false,
					{tp=false}
				)
			end
		end
	end end
	
	for f in all(inf_ftns)do
		local j=flr(f.y/8)
		local i=flr(f.x/8)
		
		repeat
			add(waters,obj(
					f.x+4,f.y+3+(j-cmj)*8,4,8,{st=f.y+5}
				))
				j+=1
		until j>cmj+15 or fget(mget(i,j),0)
		
	end
end

function draw_bk()
	for w in all(waters)do
		sspr(
			14*8+flr(uits)%4*4,0,
			4,8,
			w.x-2,w.y-4)
		//draw_bb(w)
		
		for e in all(enemies)do
			if col_bb(w,e) then
				sspr(
					16,13+flr(uitf)%3*3,
					8,3,
					e.x-4,e.y-5)
			end
		end
	end
	
	for d in all(doors)do
		local can=true
		for k in all(keys)do
			if(not k.p)can=false
		end
		if can and uits-flr(uits)>0.5 then
			pal(5,key_cols[flr(uits)%#keys+1])
		end
		spr(23,d.x-4,d.y-4)
		pal()
		//draw_bb(d)
	end
end

function draw_fg()	
	for f in all(flwrs)do
		local fx=mid(0,flr(uits)%4-1,1)
		local oy=flr(uits)%4%2
		if f.s==5 then
			sspr(
				64,13,6,5,
				f.x-3+fx,f.y+1,
				6,5,fx>0)
			sspr(
				8*8,8,6,5,f.x-3,f.y-4+oy)
		elseif f.s==1 then
			sspr(
				72,14,6,2,
				f.x-3+fx,f.y+1,
				6,3,fx>0)
			sspr(
				72,9,6,5,f.x-3,f.y-4+oy)
				
		end
		//raw_bb(f)
	end
	
	for i=1,#keys do
		local k=keys[i]
		pal(7,key_cols[i])
		spr(22,k.x-4,k.y-4+cos((uits+i)/5)*2)
		pal()
	end
	
	for s in all(swchs)do
		
		sspr(24,
			sw_state and 21 or 17,
			8,3,s.x-4,s.y-1)
		// draw_bb(s)
	end
	
	for s in all(swch_cs)do
		spr(sw_state and 37 or 38,
			s.x-4,s.y-4+cos(uits/6)*2)
		//draw_bb(s)
	end
end

function update_lvl()
	for w in all(waters)do
		w.y+=1
		local t=on_layer(w,0,0,0)
		if w.y>cmy+136 or 
					(t!=nil and t.y>w.st and t.y-w.y<2)  then
			del(waters,w)
		end
	end
	
	for f in all(ftns)do
		f.t+=1
		if f.t<f.on_t then
			if f.t%8==0 then
				add(waters,obj(
					f.x+4,f.y+4,6,8,{st=f.y+5}
				))
			end
		elseif f.t==f.on_t+f.off_t then
			f.t=-1
		end
	end
	
	for i=1,#keys do
		local k=keys[i]
		if k.p then
			local tx=pp.x+4*i*1.2*pdrx*-1
			local ty=pp.y-3
			k.x=lerp(k.x,tx,0.2)
			k.y=lerp(k.y,ty,0.2)
		end
	end
	
	sw_state=sw_state_c
	for s in all(swchs)do
		//s.on=false
		ptswch=false
		
		if col_bb(s,pp) then
			//s.on=true
			ptswch=true
			sw_state=true
		end
		
		for e in all(enemies)do
			//e.tswch=false
			if col_bb(s,e) then
				e.tswch=true
				//s.on=true
				sw_state=true
			end
		end
	end
	
	for s in all(swch_cs)do
		if col_bb(s,pp) then
			del(swch_cs,s)
			sw_state_c=not sw_state_c
		end
	end
	
	for s in all(sw_blks)do
		if s[3]==sw_state then
			mset(s[1],s[2],sw_state and 110 or 109)
		else
			mset(s[1],s[2],111)
		end
	end
end
-->8
--effects and bullets

function add_bullet(
	x,y,
	vx,vy,
	fall,
	c,
	p)
	add(bullets,obj(
		x,y,
		1,1,{
			vx=vx,
			vy=vy,
			fall=fall,
			c=c,
			p=p,
			draw=draw_bullet
		}))
end

function draw_bullet(b)
		rectfill(
			b.x-b.w/2,b.y-b.h/2,
			b.x+b.w/2,b.y+b.h/2,
			b.c and b.c or 7)
		//draw_bb(b)
end

function update_bullets()
	for b in all(bullets)do
		if b.fall then
			b.vy=min(p_f_max,b.vy+p_accel)
			if b.vx>0 then
				b.vx=max(0,b.vx-0.2)
			elseif b.vx<0 then
				b.vx=min(0,b.vx+0.2)
			end		
		end
	
		b.x+=b.vx
		b.y+=b.vy
		
		if b.x<cmx or b.x>cmx+128 or
					b.y<cmy or b.y>cmy+128 then
			//add_b_exp(b.x,b.y,2,4)
			del(bullets,b)
		end
		
		local t=on_layer(b,0,0,0)
		if t!=nil then
			if b.p and t.s==77 then
				clear_map_at(t.x,t.y)
				add_gb(t.x,t.y)
			end
			add_b_exp(b.x,b.y,2,4)
			del(bullets,b)
		end	
		
		if b.p then
			for e in all(enemies)do
				if e.can_hit and col_bb(b,e) then
					add_b_exp(b.x,b.y,2,4)
					del(bullets,b)
					del(enemies,e)
				end
			end	
		end
	end
end

function add_b_exp(x,y,m,n,c)
	for i=0,rand(m,n) do
		add(effs,eff(
			rand(x-4,x+4),rand(y-4,y+4),
			draw_jump,update_b_exp,
			{
				t=rand(10,15),
				vx=rand(-0.5,0.5),
				vy=rand(-0.5,0.5),
				c=c
			}
		))
	end
end

function update_b_exp(e)
	e.t-=1
	e.x+=e.vx
	e.y+=e.vy
	e.vx*=0.9
	e.vy*=0.9
	if(e.t==0)del(effs,e)
end

--sprinkle effect update
function update_spkl(s)
	s.dy=min(s.dy+p_accel,p_f_max)
	s.y+=s.dy
		
	if s.dx!=0 then
		s.dx-=sgn(s.dx)*0.1
	end
	s.x+=s.dx
		
	s.t-=1
	if s.y>cmy+128 or s.t==0 then
		del(effs,s)
	end
end

function add_dig(x,y)	
	for dx in all({1.2,-1.2})do
		add(effs,eff(
			x,y,draw_dig,update_spkl,
			{dx=dx,dy=-1,t=15}
		))
	end
end

function draw_dig(d)
	rectfill(d.x,d.y,d.x,d.y,15)
end

function add_gb(x,y)
	local dirs={
		{1.2,-1},
		{-1.2,-1},
		{1.2,-1.5},
		{-1.2,-1.5},
	}
	
	for dir in all(dirs)do
		add(effs,eff(
			x,y,draw_gb,update_spkl,
			{dx=dir[1],dy=dir[2],t=15,so=rand(0,3)}
		))
	end
end

function draw_gb(g)
	local sx=g.so%2*4
	local sy=flr(g.so/2)*4
	sspr(sx,16+sy,4,4,g.x,g.y)
end

function add_get(x,y,v)
	add(effs,eff(
		x-4,y-8,draw_get,update_get,
		{t=25,v=v}))
end

function draw_get(g)
	print(
		g.v,g.x,g.y,
		flr(g.t)%8+8
	)
end

function update_get(g)
	g.y-=0.6
	g.t-=1
	if g.t==0 then
		del(effs,g)
	end
end

function add_jump(x,y)
	local dirs={
		{1.2,-0.5},
		{-1.2,-0.5},
		{1.2,-1.5},
		{-1.2,-1.5},
	}
	
	for dir in all(dirs)do
		add(effs,eff(
			x,y,draw_jump,update_spkl,
			{dx=dir[1],dy=dir[2],t=10}
		))
	end
end

function draw_jump(j)
	if j.c then
		pal(7,j.c[flr(j.t)%#j.c+1])
	else
		pal(7,flr(j.t)%8+8)
	end
	sspr(13,13,3,3,j.x,j.y)
	pal()
end

function update_tp_out()
	tpt-=0.5
	if tpt==0 then
		tp_out=false
		chl=crl
		reset_checkpoint()
		//init_lvl()
	end
end

function set_cld(x,y)
	local can=true
	for c in all(clds) do
		if c[1]==x and c[2]==y then
			can=false
		end
	end
	if(can)add(clds,{x,y,7})
end

function update_clds()
	for c in all(clds)do
		c[3]-=1
		if c[3]==0 then
			add_b_exp(c[1],c[2],3,6,{13,14,15})
			clear_map_at(c[1],c[2])
			del(clds,c)
		end
	end
end

function add_wrap(x,y,d)
	add(effs,eff(
		x,y+rand(-2,2),
		draw_wrap,update_wrap,
		{
			dx=d*rnd()*0.2,
			dy=rnd()*0.09,
			
			t=rand(20,40),
			c=rnd({1,2,13,14})
		}
	))
end

w_cols={14,13,2,1}
function draw_wrap(w)
	//circ(
	//	w.x,
	//	w.y+sin(w.t),1*(w.t/40),2)
	pset(
		w.x,
		w.y+sin(w.t),
		w_cols[flr((w.t/40)*4)+1])
end

function update_wrap(w)
	w.t-=1
	w.x+=w.dx
	w.y-=w.dy
	if w.t==0 then
		del(effs,w)
	end
end



-->8
-- enemies

function add_enemy(x,y,w,h,d,u,hit,hurt,ext)
	e=obj(
		x,y,w,h,
		{
			draw=d,update=u,
			drx=1,vy=0,t=0,
			can_hit=hit,
			can_hurt=hurt,
			tswch=false}
	)
	comb(e,ext)
	add(enemies,e)
	return e
end

function update_e_general(e,lrs)
	if(lrs==nil)lrs={0,1}
	e.vy=min(p_f_max,e.vy+p_accel)
	local t=on_layer(
		e,0,max(1,e.vy),lrs)
	if t!=nil and t.y-e.y>3 then
			if e.vy>p_accel then
				//printh("enemy landed")
			end
			e.y=(flr(e.y/8)*8)+4	
			e.vy=0
	end
	e.y+=e.vy
end

-- slimes
function draw_slime(s)
	if s.fast then
		pal(2,3)
		pal(14,11)
	end
	spr(
		50+(s.fast and uitf or uits)%2,
		s.x-4,
		s.y-3-(s.tswch and 2 or 0),
		1,1,s.drx==-1)
	// draw_bb(s)
	pal()
end

function update_slime(s)
	update_e_general(s)
	if(s.vy!=0)return
	
	if on_layer(s,s.drx,0,0) or
				(not s.fast and 
					not on_layer(s,s.drx*4,1,{0,1}))then
		s.drx*=-1
	end
	
	-- speed 0.67 and 0.4
	-- dont cause sync issues
	s.x+=s.drx*(s.fast and 0.67 or 0.4)

	if s.y>cmy+136 then
		del(enemies,s)
	end
end

--moles
function draw_mole(m)
	spr(
		55+(uits)%2,
		m.x-4,
		m.y-4-(m.tswch and 2 or 0),
		1,1,pp.x>m.x)
	//draw_bb(m)
end

function update_mole(m)
	update_e_general(m)
	if m.vy==0 then
		if m.tm==0 then
			m.tm=15
			if m.j then
				m.vy=-3
				m.y-=1
			end
		else
			m.tm-=1
		end
	end
	if m.y>cmy+136 then
		del(enemies,m)
	end
end

-- spikes
function draw_spike(s)
	spr(
		107+flr(uits)%2,
		s.x-4,s.y-4,
		1,1,false,s.f
	)
	--draw_bb(s)
end

-- circle spikes
function draw_c_spike(s)
	spr(
		53+flr(uitf)%2,
		s.x-4,s.y-4,
		1,1,pp.x<s.x
	)
	--draw_bb(s)
end

-- cacti
function draw_cactus(c)
	spr(
		52,
		c.x-4,
		c.y-4+(uitf%2)-(c.tswch and 2 or 0),
		1,1,
		uitf%4/2>1)
	--draw_bb(c)
end

function update_cactus(c)
	update_e_general(c)
	if uitf%10<1 and l_uitf%10>1 then
		add_bullet(
		c.x-3,
		c.y-2,
		-1.5,
		-1,
		true,
		11,
		false)
		
		add_bullet(
			c.x+3,c.y-2,
			1.5,-1,
			true,
			11,
			false)
	end
end


function update_ice_spwn(s)
	if s.t==0 then
		s.t=s.tm
		add_enemy(
			s.x,s.y+3,8,7,
			draw_ice,
			update_ice,
			false,
			true
		)
	else
		s.t-=1
	end
end

function draw_ice(i)
	sspr(48,48,8,7,i.x-4,i.y-4)
	//draw_bb(i)
end

function update_ice(i)
	i.t+=1
	if i.t<20 then
		i.y+=0.15
	elseif i.t>30 then
		update_e_general(i,{0})
		if i.vy==0 or not on_scr(i) then
			add_gb(i.x,i.y)
			del(enemies,i)
		end
	end
end

function draw_flame_spawn(f)
	local off=0
	//if f.flt then
		off=(f.tm/15)%1
	//end
	palt(0b0000000111000000)
	spr(
		40+max(flr(f.tm),0),
		f.x,
		f.y+sin(off)*2)
	pal()
end

function update_flame_spawn(f)
	f.tm+=0.3
	if f.tm>=5 then
		f.tm=-10
		local dr=f.dr
		if dr==nil then
			local a=atan2(
				pp.x-f.x,
				pp.y-f.y)
			dr={
				cos(a),
				sin(a),
				true}
		end
		add_enemy(
			f.x+4,f.y+3,6,6,
			draw_flame,
			update_flame,
			true,
			true,
			{
				dr=dr,
				spd=f.spd
			}
		)
	end
end

function draw_flame(f)
	if not f.dr[3] then
		pal(1,13)
		pal(12,6)
	end
	spr(
		uitf%3+57,
		f.x-4,
		f.y-4)
	//draw_bb(f)
	pal()
end

function update_flame(f)
	f.x+=f.dr[1]*f.spd
	f.y+=f.dr[2]*f.spd
	if not on_scr(f) then
		del(enemies,f)
	end
end

function draw_shroom(s)
	spr(
		s.t>0 and 63 or 61+(uits)%2,
		s.x-4,
		s.y-4-(s.tswch and 2 or 0),
		1,1,pp.x>s.x)
	//draw_bb(m)
end

function update_shroom(s)
	update_e_general(s)
	if col_bb(s,pp) then
		s.t=10
		local v=1.8
		if(btn(⬇️))v=1.2
		if(btn(⬆️))v=2.2
		pvy=p_j_max*v
	end
	if s.t>1 then
		s.t-=1
	elseif s.t==1 and 
								flr(uits%2)==1 and
								flr(l_uits%2)!=1 then
		s.t=0
	end
end
__gfx__
0000000011111111000000000000000111000000000000000000000000000000000000000000000000000000009009000000000000008000cc7cccccc777cccc
000000001111111100000000000001111110000000000000000000000000000000000000000000000000000009009000000000000000880077c7cc7ccccc7777
0000000011111111000000000000111111110000000000000000000000000000000000000000000000000000999900000000000088888880cccc7777cccccccc
0000000011111111000000000001111111111000000000111100000000000000000000000000000000000000090009000000000088888888cccccccc7c77cccc
0000000011111111000000000001111111111000000011111111000000000000000000000000000000000000009000900000000088888880cccccccccccc7cc7
0000000011111111001111000011111111111100000111111111100000000000000000000000000000000000000099990000000000008800ccccccccccccc77c
0000000011111111011111100111111111111100011111111111100000000000000000000000000000000000000900900000000000008000c777cccccccccccc
0000000011111111111111111111111111111110111111111111111000000000000000000000000000000000009009000000000000000000cccc7c77cccccccc
01110000777770070777077707770777077707770000000000000000066666d0000a000000000000000000000000000000000000000000000000000000000000
100010007c7c700770007000700070007c0c70c070007770000000000655556d00aaa00000000000000000000000000000000000000000000000000000000000
10001000777770077000700070cc7c007ccc7ccc7000c7c0000555000655556d0aa1aa0000000000000000000000000000000000000000000000000000000000
10001000777770006cc0600c6ccc6ccc6ccc6ccc60007070005775000655556d00aaa00000e0e000000000000000000000000000000000000000000000000000
011100007777000006660666066606660666066600000000005775006666666d000a0000000a0000000000000000000000000000000000000000000000000000
00000000777700700700000c000000000000000000000700005665006d6d666d0030000000e0e000000000000000000000000000000000000000000000000000
000000007c7c077700c007000000000000000000000000000000000066d6d6dd0030000000030000000000000000000000000000000000000000000000000000
0000000077770070700000c000000000000000000000000000000000666666dd0003000000300000000000000000000000000000000000000000000000000000
77700000777700000c00000000000000000000000077700000777000000000007777770799999909888889098999990999999909000000000000000000000000
76070770777700007000007c0eeeded0000000000755570007555700000670007707001099090010980900108809001099090060000000000000000000000000
07677067777700000000c00000dd5d00000000007558557075555570006677007010110790601109901011098010160990101109000000000000000000000000
006707677c7c0000700c0000888828220ddd5d507588857075bbb570066556607701107799011099990610998901609999011098000000000000000000000000
00700000000000000000700000000000005515007558557075555570066506607701107799011099990610998901609999011098000000000000000000000000
070707700000000000c000c000000000ccccdcdd0755570007555700007766007010010790100109906001099010060990100108000000000000000000000000
7607076700000000000000000333d3d0000000000077700000777000000760007010707790109089906090999010909990109088000000000000000000000000
677000770000000000000000bbbb3b33000000000000000000000000000000000107777706088888010999990109999901099998000000000000000000000000
33000033990000990000000000000000000bb0000000000000007000000000000000000000000c000000c0000000000000000600000000000000000000000000
3bbb00039aaa0009000000000002200000b33b000000700000067000004440000000000000000c000000c00000c0000000000600000dd0000000000000000000
00b000000a00000000222200002ee20000b33b0b005fdf00005fdf00049994000044400000c0c1c0000c1c0000cc000c00606d6000d99d000000000000000000
00b0bbb00a00aaa002eeee2002eeee20bbb7370b07dddd0077dddd6004797940049994000c1c11c00cc111c00cc1c0cc06d6dd600d8888d000dddd0000000000
00b0b0b00aaaa0a02eeeeee202e7e720b0b33bbb00dddd7006dddd770499994004797940c111111cc111111cc1111c1c6dddddd60d7879d00d8998d000dddd00
0000bbb00000aaa02eee7e7202eeee20b0b33b00005dd500005dd5000444444004999940c11ff11cc11ff11cc11ff11c6ddffdd60d8889d0d888888d0d8998d0
3000b0039000a00902222220002222000b3bb3b0000700000007600000500500044444400c1ff1c00c1ff1c00c1ff1c006dffd6000dddd00d788799dd788879d
330000339900009900000000000000000bb00bb00000000000070000055055000550550000cccc0000cccc0000cccc0000666600000660000dddddd0dddddddd
0555555003113113035535530131b1b000000000000000000004400000ffff00055555500911911a0a55a55a01a1a1a00ff90f90077777700904909005555550
50dddd051311300353dd3d033b1b13300000000000000000000f90000f0000f05044440519119009594494099a1a1990ffff9f997000000740400404511ff115
5d0dd0d5d05301d35d0dd3d3b331333d000000000000000000044000f00f000f54044045405a014954044949a991aaad9fff9ff9700006070404904051f11f15
5dd00dd5dd0311dd53d03dd533b3b13b000000000000000000094000f0f0007f54400445440911445940944599a9a1aa0ffffff970600007000000005f11c1f5
5dd00dd5dd05011d5dd03dd3b303033d000000000000000000044000f000707f544004454405011454409449a90909ad9ff9ff9070600007000000005fccccf5
5d0dd0d5d01550115d0dd0d5d3135b33000800000000000000099000f000077f540440454015501154044045d9194a9a09909900706660070000000051cccc15
50dddd050111550150dddd050113550300898000000000000004f0000f0777f05044440501115501504444050119440900000000700000070000000051cccc15
0555555011111110055555501311311300080000000000000004400000ffff000555555011111110055555501911911900000000077777700000000005cccc50
055555500611611676d67d707676767000000000000000000007700000777700000000000211211202102122002020200000000000000bbb00000bbb00000bbb
5066660516116006dddd7777677777770000000000000000000770000777707000111100111110011111110122020110000000000ccc03330eee033308880333
56066065d05601d67d7d7dc7707777c7000000000000000000047000777607070101101010510101110110112110111d000000000c0c0f440e000f4408000f44
56600665dd0611dddddc07d76c7c07070000000000e070000009d000776776d701100110150111011110110111212012000000000c0c01f400ee01f4088001f4
56600665dd05011dd07ddc06607ccc0600000000000a0000000dd000d06076670110011005050111110011011101011d000000000ccc01f40eee01f4080001f4
56066065d0155011dddd70d66c0c70c6000700000070700000099000d0007667010110100005501111011011d10151110000000000000f4400000f4400000f44
5066660501115501ddddddd667c607c60079700000636000000df0000d7d7dd70011110000005501101111010001550100000000555ff555555ff555555ff555
055555501111111067606760676067600668660006366600000dd00007dddd000000000000000110011111100100100100000000111111111111111111111111
0555555009ff9ff90fffff5f0fffff9f0000000000300300000766dc000766dc00000000000000000000000000000000000000000e8888e003bbbb3005055050
50ffff05f9ff900959ff9dfff99ff9f90000000000b03b00706766dc706766dc0000000000000000000000000060000000000060e000000e3000000350000005
5f0ff0f5f9f90ff9fffff9f99ffff9990000000000033303766766dc766766dc000000000000000000000000006000000000006080088008b000000b00000000
5ff00ff5ff99fff9f9ff9ff5ff99fff9000000000300b30b07c076c007c076c000000000000000000000000005d000600060056080888808b0bbbb0b50000005
5ff00ff5df090ffdfdff9ff9f99f09ff40000400b3303330070076c0070076c000000000000000000000000005d60060006005d680888808b0bbbb0b50000005
5f0ff0f5d0155ff1fd0fd0f5ff9950f90400400033b03300000077c0000077c000000000000000000000000055d605d005605dd680088008b000000b00000000
50ffff050111550150dddd0509ff55f100440400b3303b0000000700000007000000000000000000000000005dd605d605d65dd6e000000e3000000350000005
055555501111111005555550191191900040000033b03300ee0000008800000000000000000000000000000000000000000000000e8888e003bbbb3005055050
000000000e11e11e0e55e55e0e12e21e0000000000000000000000000000000000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
000000001211200e5edd2d0ee2e12e2e000000000000000000000000000000000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
00000000d05e01d25d0dd2de20eee22200000000000099800000000000000000aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
00000000d20211dd52d02dd5dd2e222e00000000080989990000000000000000aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
00000000d202011d5dd02dd2de25eeed00000000888005000000000000000000aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
00000000d21550115d0dd0d5d02550ee00600000050006000000000000000000aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
000000000211550150dddd050111550e06660000006000600000000000000000aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
00000000111111100555555011211110005000000600006000000000000000000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
__gff__
0000000000000000000000000000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101800080800101010102010201010101018080808001010101020101010101010180800000000000000001010000010101808000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000004343434343434343434300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006b6b6b6b6b6b6b6b000000580b000000000000000000000000585858000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000003d000000000000005858580000000000000000000000000000000000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006d000000000000000000000000005831000000000000000000000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003100003d00002300003d000000000000000000000000000000000017005858000000000000000000000017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
484040404e00004e00004e484840404b4848484848480048484848484848484b0000000000004b4b4b4b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
