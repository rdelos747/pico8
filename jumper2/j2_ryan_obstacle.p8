pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- jumper 2
-- 2024-09-02
ver="0.0.2"

--constants and globals
p_spd=1
p_accel=0.3		 --fall accel
p_f_max=4				 --fall spd max
p_j_max=-2.5	 --jump spd max
p_j_fre=1   	 --num free jumps
p_j_t_max=5 	 --jump frames
p_w_spd=0.3 --water fill speed

chl=0 --checkpoint lvl
crl=0 --current lvl

-- enemy constants
ice_t_slow=70 --ice spawn time slow
ice_t_fast=30 --ice spawn time fast

--timers
uits,l_uits=0,0 --ui time slow
uitf,l_uitf=0,0 --ui time fast
cltb=0 --cloud time back
cltf=0 --cloud time front

logo_t=0

function _init()
	printh("=====start=====")
	pp=obj(-1,-1,3,5)
	reset_checkpoint()
end

function reset_checkpoint()
	printh("reseting from checkpoint")
	pvy=0  			   --vel y
	pdrx=1 			   --dir x
	pdry=0 			   --dir y
	pmt=0  			   --move time
	pjmp=0 			   --current jump
	pjp=true     --jump pressed
	pjmpt=0      --jump time
	ptank=1 		   --num water tanks
	pwater=0 	   --amt water
	pwt=0					   --water time
	ptw=false    --touching water
	pdig=false   --is digging
	pdt=0				 	  --digging time
	pseed=0				  --seeds
	psht=false   --shooting
	ptswch=false --touching switch
	
	crl=chl
		
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
	draw_bullets()
	
	for e in all(effs)do
		e.draw(e)
	end
	
	draw_hud()
end

function _update()
	l_uits,uits=uits,(uits+0.1)%30
	l_uitf,uitf=uitf,(uitf+0.2)%30
	cltb=(cltb+0.7)%136
	cltf=(cltf+1)%136
	
	if logo_t<50 then
		logo_t+=1
		if(btnp(❎))logo_t+=25
		return
	end
	
	for e in all(effs)do
		e.update(e)
	end
	
	for e in all(enemies)do
		e.tswch=false
		if(e.update)e.update(e)
	end
	
	update_lvl()
	update_clds()
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
	for i=max(cmi,mi-1),min(cmi+15,mi+1) do
		for f in all(lrs) do
			local s=mget(i,j)
			if fget(s,f) then
				local b=obj(
					i*8+4,j*8+4,8,8,{s=s}
				)
				if col_bb(a,b) then
					return b
				end
			end
		end
	end end
	return nil
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
		spr(124+i-1,60+f*8*i-4*f,60)
		spr(124-i,60-f*8*i+4*f,60)
	end
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
	elseif pp.x<cmx then
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
	
	--jump
	if btn(🅾️) then
		if not pjp then
			pjp=true
			if (pjmp<p_j_fre or
							flr(pwater/3)>0) then
				if pjmp>=p_j_fre and pwater>2 then
					pwater-=3
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
				printh("landed")
			end
			pp.y=(flr(pp.y/8)*8)+5	
			pjmp=0
			pvy=0
			
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
			add(bullets,obj(
				pp.x+dx*5,pp.y+pdry*5,
				1,1,{vx=dx*4,vy=pdry*4}))
			add_get(pp.x,pp.y,pseed)
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
			end
		end
	end
	
	if pp.y>cmy+136 then
		reset_checkpoint()
		return
	end
	
	--touch enemy
	for e in all(enemies)do
		if col_bb(pp,e) then
			reset_checkpoint()
			return
		end
	end
	
	for b in all(bullets)do
		if col_bb(pp,b) then
			reset_checkpoint()
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
-->8
--hud/general

function draw_hud()
	rectfill(cmx,cmy,cmx+127,cmy+6,0)
	--free jumps
	for i=0,p_j_fre-1 do
		if pjmp>i then
			pal(7,1)
			pal(12,1)
		end
		sspr(44,8,3,6,cmx+i*5,cmy)
		pal()
	end
	
	--tanks
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
	
	print(ver,cmx+100,cmy)
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
	
	bullets={}
	effs={}	
	enemies={}	
	--current map tile i,j
	cmi=crl%8*16
	cmj=flr(crl/8)*16
	--current map x,y
	cmx,cmy=cmi*8,cmj*8
	
	printh("init lvl: "..crl..", "..cmi.." "..cmj)
	
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
					{f=f}
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
				if s==49 then
					chl=crl
				end
			elseif s==50 or s==51 then
				-- slimes
				add_enemy(
					x+4,y+4,4,6,
					draw_slime,
					update_slime,
					true,
					{fast=s==51}
				)
			elseif s==52 then
				-- cacti
				add_enemy(
					x+4,y+4,6,8,
					draw_cactus,
					update_cactus,
					true
				)
			elseif s==35 then
				-- switches
				add(swchs,obj(
					x+4,y+6,8,3))
			elseif s==37 then
				-- switch coins
				add(swch_cs,obj(
					x+4,y+6,8,8))
			elseif s==102 or s==103 then
				-- icicles
				add_enemy(
					x+4,y-4,0,0,
					nil,
					update_ice_spwn,
					false,
					{tm=s==102 and ice_t_slow or ice_t_fast}
				)
			end
		end
	end end
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
		sspr(24,19,8,2,s.x-4,s.y-(sw_state and 0 or 1))
		sspr(24,21,8,1,s.x-4,s.y+1)
		// draw_bb(s)
	end
	
	for s in all(swch_cs)do
		spr(37,s.x-4,s.y-4)
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
					f.x+4,f.y+4,4,8,{t=3,st=f.y+5}
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

function draw_bullets()
	for b in all(bullets)do
		rectfill(
			b.x-b.w/2,b.y-b.h/2,
			b.x+b.w/2,b.y+b.h/2,7)
		//draw_bb(b)
	end
end

function update_bullets()
	for b in all(bullets)do
		if b.fall then
			b.vy=min(p_f_max,b.vy+p_accel)
			if b.vx>0 then
				b.vx=max(0,b.vx-p_accel)
			elseif b.vx<0 then
				b.vx=min(0,b.vx+p_accel)
			end		
		end
	
		b.x+=b.vx
		b.y+=b.vy
		
		if b.x<cmx or b.x>cmx+128 or
					b.y<cmy or b.y>cmy+128 then
			add_b_exp(b.x,b.y,2,4)
			del(bullets,b)
		end
		
		local t=on_layer(b,0,0,0)
		if t!=nil then
			if t.s==77 then
				clear_map_at(t.x,t.y)
				add_gb(t.x,t.y)
			end
			add_b_exp(b.x,b.y,2,4)
			del(bullets,b)
		end	
		
		for e in all(enemies)do
			if e.can_hurt and col_bb(b,e) then
				add_b_exp(b.x,b.y,2,4)
				del(bullets,b)
				del(enemies,e)
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
	if s.y>128 or s.t==0 then
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
		init_lvl()
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



-->8
-- enemies

function add_enemy(x,y,w,h,d,u,hurt,ext)
	e=obj(
		x,y,w,h,
		{
			draw=d,update=u,
			drx=1,vy=0,t=0,
			can_hurt=hurt,
			tswch=false}
	)
	comb(e,ext)
	add(enemies,e)
end

function update_e_general(e,lrs)
	if(lrs==nil)lrs={0,1}
	e.vy=min(p_f_max,e.vy+p_accel)
	local t=on_layer(
		e,0,max(1,e.vy),lrs)
	if t!=nil and t.y-e.y>3 then
			if e.vy>p_accel then
				printh("enemy landed")
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
				not on_layer(s,s.drx*4,1,{0,1})then
		s.drx*=-1
	end
	
	s.x+=s.drx*(s.fast and 0.6 or 0.4)
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

-- cacti
function draw_cactus(c)
	spr(
		52,
		c.x-4,
		c.y-4+(uitf%2)-(c.tswch and 2 or 0),1,1,uitf%4/2>1)
	--draw_bb(c)
end

function update_cactus(c)
	update_e_general(c)
	if uitf%10<1 and l_uitf%10>1 then
		add(bullets,obj(
			c.x-5,c.y-5,
			1,1,{
				vx=-1.5,vy=-1,fall=true
			}))
		add(bullets,obj(
			c.x+5,c.y-5,
			1,1,{
				vx=1.5,vy=-1,fall=true
			}))
	end
end


function update_ice_spwn(s)
	if s.t==0 then
		s.t=s.tm
		add_enemy(
			s.x+1,s.y+3,5,7,
			draw_ice,
			update_ice,
			false
		)
	else
		s.t-=1
	end
end

function draw_ice(i)
	sspr(48,48,5,7,i.x-3,i.y-4)
	//draw_bb(i)
end

function update_ice(i)
	i.t+=1
	if i.t<20 then
		i.y+=0.15
	elseif i.t>30 then
		update_e_general(i,{0})
		if i.vy==0 then
			add_gb(i.x,i.y)
			del(enemies,i)
		end
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
77700000777700000c00000000000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000
76070770777700007000007c00000000000000000022220000067000000000000000000000000000000000000000000000000000000000000000000000000000
07677067777700000000c00000000000000000000228822000667700000000000000000000000000000000000000000000000000000000000000000000000000
006707677c7c0000700c00000eeeded00ddd5d502288882206655660000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000700000dd5d00005515002288882206650660000000000000000000000000000000000000000000000000000000000000000000000000
070707700000000000c000c088882822ccccdcdd0228822000776600000000000000000000000000000000000000000000000000000000000000000000000000
76070767000000000000000000000000000000000022220000076000000000000000000000000000000000000000000000000000000000000000000000000000
67700077000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000
33000033990000990000000000000000000bb0000000000000000000005050500000000000000000000000000000000000000000000000000000000000000000
3bbb00039aaa0009000000000002200000b33b000000000000000000500000050000000000000000000000000000000000000000000000000000000000000000
00b000000a00000000222200002ee20000b33b0b0000000000000000050505000000000000000000000000000000000000000000000000000000000000000000
00b0bbb00a00aaa002eeee2002eeee20bbb7370b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b0b0b00aaaa0a02eeeeee202e7e720b0b33bbb0000000000000000000050000000000000000000000000000000000000000000000000000000000000000000
0000bbb00000aaa02eee7e7202eeee20b0b33b000000000000000000500000050000000000000000000000000000000000000000000000000000000000000000
3000b0039000a00902222220002222000b3bb3b00000000000000000000500000000000000000000000000000000000000000000000000000000000000000000
330000339900009900000000000000000bb00bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0555555003113113035535530131b1b000000000000000000004400000ffff00055555500911911a0a55a55a01a1a1a00ff90f900777777009049090bbbbbbbb
50dddd051311300353dd3d033b1b13300000000000000000000f90000f0000f05044440519119009594494099a1a1990ffff9f997000000740400404333ff333
5d0dd0d5d05301d35d0dd3d3b331333d000000000000000000044000f00f000f54044045405a014954044949a991aaad9fff9ff9706660070404904044f11f44
5dd00dd5dd0311dd53d03dd533b3b13b000000000000000000094000f0f0007f54400445440911445940944599a9a1aa0ffffff970600007000000004f1111f4
5dd00dd5dd05011d5dd03dd3b303033d000000000000000000044000f000707f544004454405011454409449a90909ad9ff9ff9070600007000000004fccccf4
5d0dd0d5d01550115d0dd0d5d3135b33000800000000000000099000f000077f540440454015501154044045d9194a9a09909900700006070000000044cccc44
50dddd050111550150dddd050113550300898000000000000004f0000f0777f05044440501115501504444050119440900000000700000070000000055cccc55
0555555011111110055555501311311300080000000000000004400000ffff000555555011111110055555501911911900000000077777700000000011cccc11
055555500611611676d67d707676767000000000000000000007700000777700000000000211211202102122002020200000000000000bbb00000bbb00000bbb
5066660516116006dddd7777677777770000000000000000000770000777707000111100111110011111110122020110000000000ccc03330eee033308880333
56066065d05601d67d7d7dc7707777c7000000000000000000047000777607070101101010510101110110112110111d000000000c0c0f440e000f4408000f44
56600665dd0611dddddc07d76c7c07070000000000e070000009d000776776d701100110150111011110110111212012000000000c0c01f400ee01f4088001f4
56600665dd05011dd07ddc06607ccc0600000000000a0000000dd000d06076670110011005050111110011011101011d000000000ccc01f40eee01f4080001f4
56066065d0155011dddd70d66c0c70c6000700000070700000099000d0007667010110100005501111011011d10151110000000000000f4400000f4400000f44
5066660501115501ddddddd667c607c60079700000636000000df0000d7d7dd70011110000005501101111010001550100000000555ff555555ff555555ff555
055555501111111067606760676067600668660006366600000dd00007dddd000000000000000110011111100100100100000000111111111111111111111111
0555555009ff9ff90fffff5f0fffff9f0000000000300300766dc000766dc00000000000000000000000000000000000000000000e8888e00e8888e005055050
50ffff05f9ff900959ff9dfff99ff9f90000000000b03b00766dc000766dc0000000000000000000000000000060000000000060e000000ee000000e50000005
5f0ff0f5f9f90ff9fffff9f99ffff9990000000000033303766dc000766dc0000000000000000000000000000060000000000060800880088000000800000000
5ff00ff5ff99fff9f9ff9ff5ff99fff9000000000300b30b076c0000076c000000000000000000000000000005d0006000600560808888088088880850000005
5ff00ff5df090ffdfdff9ff9f99f09ff40000400b3303330076c0eee076c088800000000000000000000000005d60060006005d6808888088088880850000005
5f0ff0f5d0155ff1fd0fd0f5ff9950f90400400033b03300077c0e00077c080000000000000000000000000055d605d005605dd6800880088000000800000000
50ffff050111550150dddd0509ff55f100440400b3303b000070000e007008800000000000000000000000005dd605d605d65dd6e000000ee000000e50000005
055555501111111005555550191191900040000033b0330000000eee0000080000000000000000000000000000000000000000000e8888e00e8888e005055050
000000000e11e11e0e55e55e0e12e21e000000000000000000000000ffffffff00aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
000000001211200e5edd2d0ee2e12e2e000000000000000000000000f000000f0aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
00000000d05e01d25d0dd2de20eee222000000000000998000000000f0000f0faaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
00000000d20211dd52d02dd5dd2e222e000000000809899900000000f000f00faa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
00000000d202011d5dd02dd2de25eeed000000008880050000000000f00f000faa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
00000000d21550115d0dd0d5d02550ee006000000500060000000000f0f0000faaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
000000000211550150dddd050111550e066600000060006000000000f000000faaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
00000000111111100555555011211110005000000600006000000000ffffffff0aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
__gff__
0000000000000000000000000200808000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000001010101800080800101010102010201010101018080808001010102020101010101010180800000000000000001010000010101808000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005d0000000000170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004d0000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001600004c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000004c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000004c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0031190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00404000004c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
