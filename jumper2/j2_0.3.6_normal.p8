pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- jumper 2
-- 2025-01-17
ver="0.3.6"

hide_t=false //remove later
p_win=false //keep this
last_lvl=31

--constants and globals
p_spd=1
p_accel=0.3		 --fall accel (0.3)
p_f_max=4				 --fall spd max (4)
p_j_max=-2.5	 --jump spd max (-2.5)
p_j_fre=1   	 --num free jumps
p_j_t_max=5 	 --jump frames
p_w_spd=0.3 		--water fill speed

l_toucht=nil

chl=0 --checkpoint lvl
crl=0 --current lvl

-- enemy constants
ice_t_slow=70 --ice spawn time slow
ice_t_fast=30 --ice spawn time fast

cltb=0 --cloud time back
cltf=0 --cloud time front
key_cols={10,11,12,8} --keys

logo_t=0
auto_save=1
tot_d=0
aut=0

function _init()
	printh("=====start=====")
	cartdata("gt_jump_correctly_1")
	
	mplay=false
	pp=obj(-1,-1,3,5)
	chl=dget(0)
//chl=31
	auto_save=dget(1)
	tot_d=dget(2)
	printh("load save 0 "..chl)
	printh("load save 1 "..auto_save)
	printh("load save 2 "..tot_d)
	
	reset_checkpoint(0)
	
	menuitem(
		1,
		"save game",
		save_game
	)
	
	menuitem(
		2,
		"auto save "..(auto_save==1 and "is on" or "is off"),
		toggle_auto_save
	)
	
	menuitem(
		3,
		"clear save data",
		clear_save
	)
end

function reset_checkpoint(ll)
	printh("reseting from checkpoint")
	uits,l_uits=-0.1,-1 --ui time slow
	uitf,l_uitf=-0.1,-1 --ui time fast
	
	tpt=0								--lvl trans time
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
	ptswch=false --touching switch player
	etswch=false --touching switch any ememy
	pto=false 	 	--near old man :(
	pio=false    --interact old man
	og_text=":)" --old guy text
	ptn=false				--touching ng cpu
	pin=false				--interact ng cpu
	ptd=0    				--touching door (0 no, 1 yes, 2 yes+interact)
	pbnk=false   --did bonk
	prst=0							--restart time
	
	ogidx=0
	ogt=0
	
	dth_t=-1					--death time
	dth_e=nil				--death object
	
	if ll then
		crl=ll
	else
		crl=chl
		if(auto_save==1)save_game()
	end
	
	if crl==0 then
		mplay=false
		music(63)// test no music
	elseif not mplay then
		mplay=true
		music(0)// test start music
	end
	
		
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
	
	if tpt>0 and tpt<40 then
		local t,c="computer "..crl,5
		if crl==0 then
			t="correct!"
			c=cltb%8+8
		end
		
		print(
			t,
			cmx+cen_txt(t),
			cmy+62,
			c)
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
	
	draw_hud()
	if aut>0 then
		for i=0,flr((30-aut)/10)do
			pset(cmx+2+i*2,cmy+126,7)
		end
	end
	
	if pio then
		draw_old_guy_prompt()
	end
end

function _update()
	l_uits,uits=uits,(uits+0.1)%30
	l_uitf,uitf=uitf,(uitf+0.2)%30
	cltb=(cltb+0.7)%136
	cltf=(cltf+1)%136
	
	if aut>0 then
		aut-=1
	end
	
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
		//if dth_e and dth_e.update then
			//dth_e.update(dth_e)
		//end
		if(dth_t==0)reset_checkpoint(crl)
		return
	end
	
	if pio then
		update_old_guy_prompt()
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

function test_w_wrap(a,b)
	local aa=a
	if scr_wrap then
		aa=obj(
			a.x%128+cmx,
			a.y,a.w,a.h)
	end
	if col_bb(aa,b) then
		return b
	end
	return nil
end

function on_layer(o,ox,oy,lrs,t_spk,hb_mod)
	if type(lrs)!="table" then
		lrs={lrs}
	end
	if(hb_mod==nil)hb_mod=0
	
	local a=obj(o.x+ox,o.y+oy,o.w+hb_mod,o.h+hb_mod)
	local mi=flr(a.x/8)
	local mj=flr(a.y/8)
	
	for j=min(cmj+15,mj+1),max(cmj,mj-1),-1 do
	for ii=mi-1,mi+1 do
		local i=ii%16+cmi
		for f in all(lrs) do
			local s=mget(i,j)
			if fget(s,f) then
				--[[
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
				]]--
				local b=obj(
					i*8+4,j*8+4,8,8,{s=s}
				)
				if test_w_wrap(a,b) then
					return b
				end
			end
		end
	end end
	
	if t_spk then
		for s in all(spks) do
			if test_w_wrap(a,s) then
				return s
			end
		end
	end
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
		"auto save "..(auto_save==1 and "is on" or "is off"),
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
	aut=30
end

function clear_save(i)
	if i==1 or i==2 then
		return
	end
	
	printh("clear save 0")
	printh("clear save 2")
	dset(0,0)
	dset(2,0)
	chl=0
end

music(0)

-->8
--player
function draw_player()
	local off=(ptswch and 2 or 0)
	
	--legs
	sspr(
		12,flr(pmt)%2*2+8,
		4,2,
		pp.x-2,pp.y+1-off,
		4,2,
		pmt<2
	)	

	--ducking
	local dt=flr(pdt/3)%2
	if dt==0 and 
				pdry==1 and 
				pvy==0 and
				not pdig then
		dt=1
	end

	--head
	if(pjmp>=p_j_fre)pal(12,5)
	sspr(
		8,pdry*4+12,
		4,4,
		pp.x-2,pp.y-3+dt-off,
		4,4,
		pdrx==-1
	)
	pal()
		
	--off screen arrow
	if pp.x>cmx+128 then
		spr(13,cmx+120,pp.y-4)
	elseif pp.x<cmx-1 then
		spr(13,cmx+2,pp.y-4,1,1,true)
	end
	
	--water drops
	if ptw then
		draw_splash(pp.x-4,pp.y-5)
	end
	
	--water tank
	local ofx=3
	if(pdrx==-1)ofx=-8
	if pst then
		sspr(0,8,6,6,pp.x+ofx,pp.y-6)
	elseif pwater>0 then
		if ptw then
			--tank shadow
			sspr(
				0,8,6,6,
				pp.x+ofx+1,pp.y-5)
		end
		sspr(
			16+8*(pwater-1)+(flr(uits)%2)*4,8,
			5,5,pp.x+ofx,pp.y-6)
	end
	
	--seeds
	for i=1,pseed do
		local a=uitf/7.5+i/pseed
		local x=pp.x+cos(a)*6
		local y=pp.y+sin(a)*6
		rectfill(
			x,y,
			x+sgn(cos(a)),
			y+sgn(sin(a)),7)
	end
	
	if prst>15 then
		draw_int(
			4-flr(prst/15),
			pp.x+2,
			pp.y-2)
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
		pmt-=0.3
		if(pmt<0)pmt=4
		if not on_layer(pp,pdrx,0,0) then
			pp.x+=p_spd*pdrx
		end
	else
		pmt=0
		pp.x=flr(pp.x)
	end
	
	if scr_wrap then
		local wr=false
		if(pp.x<cmx-1)pp.x,wr=cmx+127,true
		if(pp.x>cmx+127)pp.x,wr=cmx,true
		if(wr)sfx(3,-1,12,14)
	end
	
	--touch enemy
	local ts=false --touch shroom
	for e in all(enemies)do
		if col_bb(pp,e) then
			if e.draw==draw_shroom then
				ts=true
				//printh(pp.x.." "..pp.y.." touch shroom")
			elseif e.can_hurt then
				//reset_checkpoint()
				kill_plr(e)
				return
			end
		end
	end
	
	--jump
	if btn(🅾️) then
		if not pjp then
			pjp=true
			--  bank,chnl,off, len
			--sfx(0,   0,   0,   0)
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
				if not ptn then
					sfx(3,-1,0,8)
				end
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
		local b=on_layer(pp,0,pvy,0) 
		if b then
			if not pbnk then
				sfx(3,-1,8,4)
			end
			pbnk=true
			pp.y=b.y+7
			pvy=0.5 --y vel of player after bonk
		end
	else 
		local t=on_layer(
			pp,0,max(1,pvy),{0,1})
		if t!=nil and t.y-pp.y>4 then
			if pvy>p_accel then
				//printh(
				//	"landed "..(
				//		ts and "true" or "false")
				//	)
				add_landed(pp.x,pp.y+4)
				pbnk=false
				sfx(5,-1,0,10)
			end
			pp.y=(flr(pp.y/8)*8)+5
			pvy=0
			pst=false
			
			if not ts then
				pjmp=0
			end
			
			if t and t.s==76 then
				set_cld(t.x,t.y)
			end
		end
	end
	pp.y+=pvy
	
	local sq=on_layer(pp,0,0,0)
	if sq then
		//printh(sq.x.." "..sq.y)
		local o=obj(
			sq.x,sq.y,0,0,
			{
				draw=function()
					spr(sq.s,sq.x-4,sq.y-4)
				end
			})
		kill_plr(o)
	end
	
	--shoot
	if btn(❎) then
		if not pto and 
					not psht and 
					pseed>0 then
			psht=true
			pseed-=1
			sfx(6,-1,0,6)
			local dx=pdrx
			if(pdry!=0)dx=0	
			//add_get(pp.x+2,pp.y,pseed)
			add_bullet(
				pp.x+dx*5,pp.y+pdry*5,1,
				dx*4,pdry*4,false,7,true)
		end
	else
		psht=false 
	end
	
	if btn(❎) and 
				btn(⬇️) and 
				pvy==0 then
		prst+=1
		if prst==15*4 then
			kill_plr()
		end
	else
		prst=0
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
				sfx(4,-1,(pwater-1)*6,6)
			end
		end
	end
	
	//printh(pov)
	
	if pp.y>cmy+136 then
		//reset_checkpoint()
		kill_plr()
		return
	end
	
	for b in all(bullets)do
		if col_bb(pp,b) then
			//reset_checkpoint()
			kill_plr(b)
			return
		end
	end
	
	--touch key
	for k in all(l_keys)do
		if not k.p and col_bb(pp,k) then
			k.p=true
			add(p_keys,k)
			sfx(10)
		end
	end
	
	--touch door
	//for d in all(doors)do
	if door then
		if col_bb(pp,door) then
			//ptd=true
			if btn(⬇️) or btn(⬆️) then
				local can=true
			
				//sfx(11)
				//sfx(17)
				//sfx(7,-1,4,4)
				for k in all(l_keys)do
					if k.p==false then
						can=false
					end
				end
			
				if can then
					for k in all(keys)do
						del(keys,k)
					end
					if crl==last_lvl then
						crl=0
						p_win=true
					elseif crl==chl then
						crl+=1
					else
						crl=chl
					end
					sfx(11)
					init_tp_out()
				
					return
				elseif ptd<2 then
					sfx(7,-1,4,4)
					ptd=2
				end
			else
				ptd=1
			end
		else
			ptd=0
		end
	end
	
	--touch flower
	local flwr=nil
	for f in all(flwrs)do
		if col_bb(pp,f) and pdry==1 then
			flwr=f
		end
	end
	
	if pvy!=0 or flwr==nil then
		pdig=false
		pdt=0
	else
		if pdig==false then
			pdt=10
		end
		pdig=true
		if pdt%5==0 then
			add_dig(pp.x,pp.y+4)
			sfx(8,-1,27,4)
		end
		if pdt<=0 then
			del(flwrs,flwr)
			pseed+=flwr.s
			add_get(pp.x,pp.y,"+"..flwr.s)
			sfx(14)
		end
		pdt-=1
	end
	
	-- touch teleporter
	local toucht=nil
	for tt in all(tps)do
	for i=0,1 do
		local t=tt[i+1]
		if t then
			if col_bb(pp,t) then
				//printh((i+1%2)+1)
				toucht=tt[(i+1)%2+1]
			end
		end 
	end end
	if l_toucht==nil and
				toucht!=nil then
		pp.x=toucht.x
		pp.y=toucht.y+1
		pvy*=-1
		--[[
		because of long pressing jumps,
		if the player enters this while
		holding jump before the max hold
		time, their velocity wont flip
		]]--
		add_b_exp(pp.x,pp.y,5,5,toucht.c)
		sfx(7,-1,8,24)
	end
	l_toucht=toucht
	
	-- old man
	pto=false
	if old_guy and 
				col_bb(pp,old_guy)then
		pto=true
		if btnp(❎) then
			sfx(7,-1,0,4)
			pio=true
			ogt=0
			l_ogt=-1
			if og_texts[crl]!=nil then
				og_text=og_texts[crl]
			end
		end
	end
	
	-- touch ng cpu
	ptn=false
	if ng_cpu and
				col_bb(pp,ng_cpu)then
		ptn=true
		if btnp(❎) then
			if pin then
				clear_save()
				//kill_plr(ng_cpu)
				crl=1
				init_tp_out()
				sfx(17)
			else
				sfx(7,-1,0,4)
			end
			pin=true
		elseif btnp(🅾️) then
			sfx(7,-1,4,4)
			pin=false
		end
	else
		pin=false
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
		sfx(8,-1,0,27)
end

-->8
--hud/general

function draw_hud()
	print(ver,100,120,7)
	if(hide_t)return
	--[[
	// uncomment for testing
	print("lvl:"..crl+1,cmx+31,cmy+1,1)
	print("lvl:"..crl+1,cmx+30,cmy,7)
	print("dth:"..tot_d,cmx+61,cmy+1,1)
	print("dth:"..tot_d,cmx+60,cmy,7)
	]]--
	
	if crl==0 then
		local t="jump correctly"
		//t="you jumped correctly"
		local off=mid(
			-2.9,
			cos((cltf%136)/136)*3,
			2.9
		)
		print(
			t,cen_txt(t),10+off,5)
		print(
			t,cen_txt(t),9+off,7)
		print("a game by",46,20,1)
		print("raf+ryan @ gold team",
			24,26,1)
		
		if p_win then
		 t1="times jumped"
		 t2="incorrectly: "..tot_d
		 //t2="incorrectly: "..19999
		 print(
			 t1,
			 cen_txt(t1),40,13)
		 print(
			 t2,
			 cen_txt(t2),46,13)
			
			print("rank:",49,58,7)
			//tot_d=50
			local r,c=rank()
			if c==nil then
				pal(7,(uitf%8)+8)
			elseif flr(uitf)%2==0 then
				pal(7,c)
			end
			print(r,72,58,7)
			pal()
		end	
	end
end

function cen_txt(t)
	return 64-(#t*4)/2
end

function draw_splash(x,y)
	sspr(
		16,13+flr(uitf)%3*3,
		8,3,
		x,y)	
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

function draw_old_guy()
	local s=0
	if cltf>68 or 
				cltf<30 and cltf%12>6 then
		s=4
	end
	sspr(
		64+s,0,
		4,8,
		old_guy.x-2,old_guy.y-4,
		4,8,
		pp.x<old_guy.x)
	if cltf>68 then
		local off=old_guy.y
		if(cltf%12>6)off-=1
		line(
			old_guy.x-4,off-1,
			old_guy.x-4,off,6)
		line(
			old_guy.x+3,off-1,
			old_guy.x+3,off,6)
	end
	//draw_bb(old_guy)
end

function draw_old_guy_prompt()
	local top=cmy+40
	local lft=cmx+20
	
	rectfill(
		lft,top,
		lft+86,top+48,0)
	rect(
		lft,top,
		lft+86,top+48,7)
	
	print(sub(og_text,0,ogt),
		lft+2,top+2,7)
end

l_ogt=-1
function update_old_guy_prompt()
	if ogt<#og_text then
		ogt+=0.5
		if l_ogt!=flr(ogt) and flr(ogt)%2==0 then
			local off=rand(0,1)
			sfx(18,-1,off*3,3)
			//sfx(18,-1,0,2)
		end
		l_ogt=flr(ogt)
	end

	if btnp(🅾️) then
		pio=false
		sfx(7,-1,4,4)
	elseif btnp(❎) then
		if ogt<#og_text then
			ogt=#og_text
		else
			pio=false
			sfx(7,-1,4,4)
		end
	end
end

function draw_ng_cpu()
	if ptd>0 then
		print(
			"continue",
			door.x-15,
			door.y-20,
			7)
		draw_int("⬆️",door.x+1,door.y-2)
	end
	
	spr(7,ng_cpu.x-4,ng_cpu.y-4)
	if(not ptn)return
		
	if pin then
		print(
			"are you sure?",
			ng_cpu.x-23,
			ng_cpu.y-20,
			7)
		print(
			"no:    yes:",
			ng_cpu.x-23,
			ng_cpu.y-12,
			7)
		draw_int("🅾️",ng_cpu.x-7,ng_cpu.y-2)
		draw_int("❎",ng_cpu.x+25,ng_cpu.y-2)
	else
		print(
			"new game",
			ng_cpu.x-15,
			ng_cpu.y-20,
			7)
		draw_int("❎",ng_cpu.x,ng_cpu.y-2)
	end
end

-- draw interact
function draw_int(s,x,y)
	print(s,x-4,y-10,5)
	print(
		s,
		x-4,
		y-(
			flr(uits)%2==0 and 11 or 10
		),
		6
	)
end


og_texts={}
og_texts[0]="bad news. one of the\ninterns spilled their\nlatte on the\nmainframe console and\nscrambled our\nencrypted data. make\nhaste and retrieve\nour floppy disks!"
og_texts[2]="if you look down,\nyou'll notice these\ndancing flowers.\nthey're extra tasty\nthis time of year!"
og_texts[8]="oh boy, i can't wait\nto get back to work!"
og_texts[15]="i feel a temporal\nshift when i pass\nthe particles."
og_texts[16]="these mushrooms\nreally get me. they\ncan help us reach\nhigh and low places!"
og_texts[21]="my forehead feels\nrather warm!\nfortunately, the\nsource of the heat\nmay not harm you."
og_texts[28]="some jerk once\ncompared me to a\ntalking paper clip."
og_texts[31]="almost there, kid!\nuse your final\nresources wisely."

function rank()
	if(tot_d==0)return "s+",nil
	if(tot_d<=40)return "s",8
	if(tot_d<=100)return "a",9
	if(tot_d<=200)return "b",11
	if(tot_d<=400)return "c",13
	return "d",2
end
-->8
--map functions

function init_lvl()
	reload(0x1000, 0x1000, 0x2000)
	waters={}
	ftns={}
	l_keys={}
	p_keys={}
	door=nil
	flwrs={}
	swchs={}
	swch_cs={}
	sw_blks={}
	clds={}
	spks={}
	tps={
		{nil,nil},
		{nil,nil}
	}
	old_guy=nil
	ng_cpu=nil
	
	sw_state=false
	sw_state_c=false
	sw_state_l=false
	scr_wrap=false
	flip_d=false
	
	bullets={}
	effs={}	
	enemies={}	
	--current map tile i,j
	cmi=crl%8*16
	cmj=flr(crl/8)*16
	--current map x,y
	cmx,cmy=cmi*8,cmj*8
	
	--debug for when no checkpoint
	pp.x,pp.y=cmx+64,cmy+64
	
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
		
		if s>=93 and s<=94 then
			--fountains
			local on_t,off_t=7,0
			if(s==94)on_t,off_t=30,30
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
				if sn!=77 and 
							sn!=109 and
							sn!=110 and
							fget(sn,0) then
					off,f=2,true
				end
				local sp=add_enemy(
					x+4,y+off,8,4,
					draw_spike,
					nil,
					false,
					true,
					{f=f}
				)
				add(spks,sp)
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
				--keys/floppy
				add(l_keys,obj(
					x+4,y+4,4,4,
					{p=false}
				))
			elseif s==23 then
				--door
				door=obj(x+4,y+4,8,8)
			elseif s==24 or s==25 then
				--flower 5 seed
				add(flwrs,obj(x+4,y+4,6,8,{s=s==24 and 5 or 1}))
			elseif s==48 or s==49 then
				-- checkpoints
				printh("cp "..x.." "..y)
				pp.x,pp.y=x+4,y+5
				add_b_exp(pp.x,pp.y,10,10)
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
					true,
					{t=60}
				)
			elseif s==55 or s==56 then
				-- moles
				add_enemy(
					x+4,y+4,5,6,
					draw_mole,
					update_mole,
					true,
					true,
					{j=s==56,tm=15,htm=0}
				)
			elseif s==35 then
				-- switches
				add(swchs,obj(
					x+4,y+6,7.5,3))
			elseif s==37 then
				-- switch coins
				add(swch_cs,obj(
					x+4,y+4,7,6))
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
					spd=1.8 -- tracker speed
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
				//printh(s-39)
				//printh(drs[s-39])
			elseif s==11 then
				scr_wrap=true
			elseif s==61 then
				-- mushroom
				add_enemy(
					x+4,y+4,7,6,
					draw_shroom,
					update_shroom,
					true,
					false,
					{tp=false}
				)
			elseif s==31 then
				--eye
				add_enemy(
					x+4,y+4,7,6,
					draw_eye,
					update_eye,
					false,
					false,
					{t=0}
				)
			elseif s==120 then
				flip_d=true
			elseif s>=116 and s<=119 then
				--teleporters
				local i1=ceil(abs(115-s)/2)
				local i2=(s%2)+1
				local cs={{3,11},{2,8}}
				tps[i1][i2]=obj(
					x+4,y+4,6,6,
					{c=cs[i1]}
				)
			elseif s==8 then
				old_guy=obj(
					x+4,y+4,8,8,
					{draw=draw_old_guy}
				)
			elseif s==7 then
				ng_cpu=obj(
					x+4,y+4,8,8)
			end
		end
	end end
	
	for f in all(inf_ftns)do
		local j=flr(f.y/8)
		local i=flr(f.x/8)
		
		repeat
			add(
				waters,
				obj(
					f.x+4,
					cmy+3+(j-cmj)*8,
					8,8,
					{st=f.y+5}
				)
			)
			j+=1
		until j>cmj+15 or fget(mget(i,j),0)
	end
	
	--[[
	// title test, use moles
	// to
	if crl==0 then
		local ss="jump correctly"
		printh("lvl 1")
		for i=0,#ss-1 do
			local s=ss[i+1]
			local x,y=24+i*4,20-i*2
			add_enemy(
				x+4,y+4,3,5,
				draw_title_text,
				update_mole,
				true,
				true,
				{j=true,tm=15,htm=0,s=s}
			)
		end
	end
	]]--
end

function draw_bk()
	for w in all(waters)do
		local off=0
		if w.ct and w.ct.y>w.st then
			//printh(w.ct.y-w.y)
			off=7-(w.ct.y-w.y)
		end
		sspr(
			14*8+flr(uits)%4*4,0,
			4,8-off,
			w.x-2,w.y-4)
		//end
		//draw_bb(w)
		if w.ct and off!=0 then

			draw_splash(w.ct.x-4,w.ct.y-5)
		end
		
		for e in all(enemies)do
			if col_bb(w,e) then
				sspr(
					16,13+flr(uitf)%3*3,
					8,3,
					e.x-4,e.y-5)
			end
		end
	end
	
	//for d in all(doors)do
	if door then
		if #p_keys==#l_keys and 
					uits-flr(uits)>0.5 then
			pal(5,key_cols[flr(uits)%#l_keys+1])
		end
		spr(
			23,
			door.x-4,
			door.y-4,
			1,1,
			flip_d
		)
		pal()
		//draw_bb(door)
	end
	
	if old_guy then
		draw_old_guy()
	end
	
	if ng_cpu then
		draw_ng_cpu()
	end
end

function draw_fg()
	local ft=cltf%68
	if ft>0 and ft<7 or 
				ft>14 and ft<21 then
		pal(3,7)
		pal(10,7)
		pal(14,7)
	end
	for f in all(flwrs)do
		local fx=mid(0,flr(uits)%4-1,1)
		local oy=flr(uits)%4%2
		if f.s==5 then
			sspr(
				64,13,6,3,
				f.x-3+fx,f.y+1,
				6,3,fx>0)
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
		//draw_bb(f)
	end
	pal()
	
	for i=1,#l_keys do 
		local k=l_keys[i]
		pal(7,key_cols[i])
		spr(
			22,
			k.x-4,
			k.y-4+mid(
				-1.9,
				cos((uits+i)/5)*2,
				1.9
			)
		)
		pal()
		//draw_bb(k)
	end
	
	for s in all(swchs)do
		
		sspr(24,
			sw_state and 21 or 17,
			8,3,s.x-4,s.y-1)
		//draw_bb(s)
	end
	
	for s in all(swch_cs)do
		if ptswch or etswch then
			palt(5,true)
			pal(7,13)
			pal(8,13)
			pal(11,13)
		end
		spr(sw_state and 37 or 38,
			s.x-4,s.y-4+cos(uits/6)*2)
		//draw_bb(s)
		pal()
	end
	
	for ti=1,#tps do
	for t in all(tps[ti]) do
	if t then
		//draw_bb(t)
		local d=ti<2 and 1 or -1
		for i=0,2 do
			local f=max(1,i*2)
			local a=0
			while a<1 do
				local aa=a+(cltf/(136/f))
				
				pset(
					t.x+cos(aa)*(2+i),
					t.y+sin(aa)*(2+i)*d,
					i%2==0 and t.c[2] or t.c[1]
				)
				a+=1/5
			end
		end
	end end end
	
	if pto then
		draw_int("❎",old_guy.x,old_guy.y)
	end
end

function update_lvl()
	for w in all(waters)do
		w.y+=1
		local t=on_layer(w,0,0,0,false,-2)
		w.ct=t
		if w.y>cmy+136 or 
					(t!=nil and t.y>w.st and t.y-w.y<1)  then
			del(waters,w)
		end
	end
	
	for f in all(ftns)do
		f.t+=1
		if f.t<f.on_t then
			if f.t%8==0 then
				add(waters,obj(
					f.x+4,f.y+4,8,8,{st=f.y+5}
				))
			end
		elseif f.t==f.on_t+f.off_t then
			f.t=-1
		end
	end
	
	for i=1,#p_keys do
		local k=p_keys[i]
		//if k.p then
			local tx=pp.x+4*i*1.2*pdrx*-1
			local ty=pp.y-3
			k.x=lerp(k.x,tx,0.2)
			k.y=lerp(k.y,ty,0.2)
		//end
	end
	
	sw_state=sw_state_c
	ptswch=false
	etswch=false
	for s in all(swchs)do
		if col_bb(s,pp) then
			ptswch=true
			sw_state=true
		end
		
		for e in all(enemies)do
			if col_bb(s,e) then
				e.tswch=true
				etswch=true
				sw_state=true
			end
		end
	end
	
	if not ptswch and not etswch then 
	for s in all(swch_cs)do
		if col_bb(s,pp) then
			del(swch_cs,s)
			sw_state_c=not sw_state_c
			sfx(13,-1,0,16)
		end
	end end
	
	for s in all(sw_blks)do
		if s[3]==sw_state then
			mset(s[1],s[2],sw_state and 110 or 109)
		else
			mset(s[1],s[2],111)
		end
	end
	
	if sw_state!=sw_state_l then
		sfx(12,-1,0,2)
	end
	sw_state_l=sw_state
end
-->8
--effects and bullets

function add_bullet(
	x,y,w,
	vx,vy,
	fall,
	c,
	p,
	draw)
	add(bullets,obj(
		x,y,
		w,w,{
			vx=vx,
			vy=vy,
			fall=fall,
			c=c,
			p=p,
			draw=draw and draw or draw_bullet
		}))
end

function draw_bullet(b)
		rectfill(
			b.x-b.w/2,b.y-b.h/2,
			b.x+b.w/2,b.y+b.h/2,
			b.c and b.c or 7)
		//draw_bb(b)
end

function draw_c_bullet(b)
	spr(
		26,b.x-1,b.y-1,
		1,1,
		false,
		b.vy>1
	)
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
		if t!=nil and 
					(b.draw!=draw_c_bullet or 
						t.y>b.y
					)then
			if b.p and t.s==77 then
				clear_map_at(t.x,t.y)
				add_gb(t.x,t.y)
				sfx(15,-1,0,27)
			end
			add_b_exp(b.x,b.y,2,4)
			del(bullets,b)
		end	
		
		if b.p then
			for e in all(enemies)do
				local tbw=b.w
				b.w+=2
				b.h+=2
				if e.can_hit and 
							col_bb(b,e) then
					add_b_exp(b.x,b.y,2,4)
					del(bullets,b)
					del(enemies,e)
				end
				b.w,b.h=tbw,tbw
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

function add_jump(x,y,c)
	local dirs={
		{1.2,-0.5},
		{-1.2,-0.5},
		{1.2,-1.5},
		{-1.2,-1.5},
	}
	
	for dir in all(dirs)do
		add(effs,eff(
			x,y,draw_jump,update_spkl,
			{dx=dir[1],dy=dir[2],t=10,c=c}
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

function add_landed(x,y)
	//printh("added landed")
	for d in all({-1,1})do
		add(effs,eff(
			x+2*d,y,draw_landed,update_landed,
			{dx=d}
		))
	end
end

function draw_landed(l)
	rectfill(
		l.x,l.y,
		l.x+1*sgn(l.dx),l.y+1,
		flr(cltf)%8+8)
end

function update_landed(l)
	l.x+=l.dx
	l.dx*=0.90
	if abs(l.dx)<0.5 then
		del(effs,l)
	end
end

function init_tp_out()
	tp_out=true
	tpt=60
	add_b_exp(pp.x,pp.y,10,10)
end

function update_tp_out()
	tpt-=1
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
			sfx(6,-1,6,15)
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
		e,0,max(1,e.vy),lrs,true)
	if t!=nil then
		if e.vy<0 and fget(t.s,0) then
			e.vy=0
		elseif t.y-e.y>4 then
			if e.vy>p_accel then
				//printh("enemy landed")
				//printh(t.y.." "..t.h)
			end
			e.y=flr(t.y-t.h/2)-flr(e.h/2)-1
			e.vy=0
		end
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
	
	if on_layer(s,s.drx,0,0,true) or
				(not s.fast and 
					not on_layer(s,s.drx*4,1,{0,1},true))then
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
	local s=(uits)%2
	if(m.vy<0)s=0
	if(m.vy>0)s=1
	spr(
		55+s,
		m.x-4,
		m.y-4-(m.tswch and 2 or 0),
		1,1,pp.x>m.x)
	//draw_bb(m)
end

function update_mole(m)
	update_e_general(m)
	if m.vy==0 and m.htm==0 then
		if m.tm==0 then
			m.tm=15
			m.htm=10
			if m.j then
				m.vy=-3
				m.y-=1
				sfx(5,-1,10,8)
			end
		else
			m.tm-=1
		end
	elseif m.vy>=-p_accel and
								m.vy<=p_accel then
		if m.htm>0 then
			m.vy=-p_accel
			m.htm-=1
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
	//draw_bb(s)
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
	c.t+=1
	if c.t>=60 then
		c.t=0
		add_bullet(
			c.x-2,
			c.y-1,
			3,
			-1.7, --h vel
			-2,   --v vel
			true,
			11,
			false,
			draw_c_bullet
		)
		
		add_bullet(
			c.x+2,
			c.y-1,
			3,
			1.7, --h vel
			-2,  --v vel
			true,
			11,
			false,
			draw_c_bullet
		)
		sfx(9,-1,0,16)
	end
end


function update_ice_spwn(s)
	if s.t==0 then
		s.t=s.tm
		add_enemy(
			s.x,s.y+3,7,7,
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
			sfx(15,-1,10,6)
			//sfx(15,-1,16,4)
			if i==dth_e then
				dth_e=nil
			end
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
	//draw_bb(s)
end

function update_shroom(s)
	update_e_general(s)
	if col_bb(s,pp) then
		s.t=10
		local v,sv=1.6,1
		if(btn(⬇️))v,sv=1.1,0
		if(btn(⬆️))v,sv=2.1,2
		sfx(16,-1,sv*6,6)
		//sfx(16,-1,0,6+sv*6)
		pvy=p_j_max*v
		add_jump(pp.x-1,pp.y,{13,14})
	end
	if s.t>1 then
		s.t-=1
	elseif s.t==1 and 
								flr(uits%2)==1 and
								flr(l_uits%2)!=1 then
		s.t=0
	end
end

eye_blk_t=6
eye_blk_s=0.24
function draw_eye(e)
	local s=0
	if e.t>=-eye_blk_t then
		local pc=5
		
		if e.t<0 and flr(e.t)%2==0 then
			pc=7
		end
		
		pal(7,pc)	
		pal(9,pc)
		pal(10,0)
		pal(15,pc)
		
		s=28+mid(
			0,
			abs(10-flr(e.t)),
			3)
	else
		s=31-mid(
			0,
			abs(eye_blk_t+4+flr(e.t)),
			3)
	end
	spr(s,e.x-4,e.y-4,1,1,e.x<pp.x)
	pal()
end

function update_eye(e)
	if e.t>=0 then
		e.t+=eye_blk_s
		if(e.t>14)e.t=0
		e.can_hurt=false
		if col_bb(e,pp) then
			e.t=-1
		end
	else
		e.t-=eye_blk_s
		if e.t<=-eye_blk_t then
			e.can_hurt=true
		end
		if(e.t<-eye_blk_t-7)e.t=11
	end
end

--this is a crazy hack
function draw_title_text(t)
	print(t.s,t.x-2,t.y-3)
	//draw_bb(t)
end
__gfx__
000000001111111100000000000000011100000000000000000000000d555550000000000000000000000000009009000000000000008000cc7cccccc777cccc
00000000111111110000000000000111111000000000000000000000d58888500000ff0f000000000000000009009000000000000000880077c7cc7ccccc7777
00000000111111110000000000001111111100000000000000000000d5888850ff6f66660050500000000000999900000000000088888880cccc7777cccccccc
00000000111111110000000000011111111110000000001111000000d5888850696969690005000000000000090009000000000088888888cccccccc7c77cccc
00000000111111110000000000011111111110000000111111110000d5555555666666660050500000000000009000900000000088888880cccccccccccc7cc7
00000000111111110011110000111111111111000001111111111000d555d5d5666666660000000000000000000099990000000000008800ccccccccccccc77c
00000000111111110111111001111111111111000111111111111000dd5d5d55666666660000000000000000000900900000000000008000c777cccccccccccc
00000000111111111111111111111111111111101111111111111110dd555555600660060000000000000000009009000000000000000000cccc7c77cccccccc
01110000777770070777077707770777077707770000000000000000066666d0000a000000000000030000000000000000000000000000000000000000000000
100010007c7c700770007000700070007c0c70c070007770000000000655556d00aaa000000000003b3000000000000000ffff0000ffff0000ffff0000ffff00
100010007777700770007000705575007ccc7ccc7000c7c0000555000655556d0aa1aa000000000030300000000000000f9999f00f9999f00f9999f00f0000f0
110110007777700065506005655565556ccc6ccc60007070005775000655556d00aaa00000e0e0000000000000000000f999999ff999999ff077000ff077000f
011100007777000006660666066606660666066600000000005775006666666d000a0000000a00000000000000000000f999999ff799990ff7aa700ff7aa700f
00000000777700700700000c000000000000000000000700005665006d6d666d0030000000e0e0000000000000000000f799990ff7aa700ff7aa700ff7aa700f
000000007c7c077700c007000000000000000000000000000000000066d6d6dd003000000003000000000000000000000f7700f00f7700f00f7700f00f7700f0
0000000077770070700000c000000000000000000000000000000000666666dd0003000000300000000000000000000000ffff0000ffff0000ffff0000ffff00
77700000777700000c00000000000000000000000077700000777000000000007777770799999909888889098999990999999909101000101010001001000101
76070770777700007000007c0eeeded0000000000755570007555700000670007707001099090010980900108809001099090060000010000000100000010000
07677067777700000000c00000dd5d00000000007558557075555570006677007010110790601109901011098010160990101109000000100000001001000000
006707677c7c0000700c0000888828220ddd5d507588857075bbb570066556607701107799011099990610998901609999011098000010001010100000010000
00700000000000000000700000000000005515007558557075555570066506607701107799011099990610998901609999011098000001000000010000100000
070707700000000000c000c000000000ccccdcdd0755570007555700007766007010010790100109906001099010060990100108000000100001001001000000
7607076700000000000000000333d3d0000000000077700000777000000760007010707790109089906090999010909990109088000000001000000000000000
677000770000000000000000bbbb3b33000000000000000000000000000000000107777706088888010999990109999901099998000000000100010000000000
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
5d0dd0d5d01550115d0dd0d5d3135b33000800000060000000099000f000077f540440454015501154044045d9194a9a09909900706660070000000051cccc15
50dddd050111550150dddd050113550300898000066600000004f0000f0777f05044440501115501504444050119440900000000700000070000000051cccc15
0555555011111110055555501311311300080000005000000004400000ffff000555555011111110055555501911911900000000077777700000000005cccc50
055555500611611676d67d7076767670000000000000000000077000007777000000000002112112021021220020202000000a0000000bbb00000bbb00000000
5066660516116006dddd777767777777000000000000000000077000077770700011110011111001111111012202011000a0a0000ccc03330eee033300000000
56066065d05601d67d7d7dc7707777c7000000000000000000047000777607070101101010510101110110112110111d0a00a00a0c0c0f440e000f4400000000
56600665dd0611dddddc07d76c7c07070000000000e070000009d000776776d7011001101501110111101101112120120a0a0aa00c0c01f400ee01f400000000
56600665dd05011dd07ddc06607ccc0600000000000a0000000dd000d06076670110011005050111110011011101011d0aa0a0900ccc01f40eee01f400000000
56066065d0155011dddd70d66c0c70c6000700000070700000099000d0007667010110100005501111011011d1015111a0a090a000000f4400000f4400000000
5066660501115501ddddddd667c607c60079700000636000000df0000d7d7dd700111100000055011011110100015501909a0a00555ff555555ff55500000000
055555501111111067606760676067600668660006366600000dd00007dddd000000000000000110011111100100100199a90909111111111111111100000000
0555555009ff9ff90fffff5f0fffff9f0000000000300300000766dc000766dc00000000030003030000000000000000000000000e8888e003bbbb3005055050
50ffff05f9ff900959ff9dfff99ff9f90000000000b03b00706766dc706766dc0000000003003003000001000060000000000060e000000e3000000350000005
5f0ff0f5f9f90ff9fffff9f99ffff9990000000000033303766766dc766766dc000099800000300000001110006000000000006080088008b000000b00000000
5ff00ff5ff99fff9f9ff9ff5ff99fff9000000000300b30b07c076c007c076c008098999000003000000010005d000600060056080888808b0bbbb0b50000005
5ff00ff5df090ffdfdff9ff9f99f09ff40000400b3303330070076c0070076c088800500000000000000010005d60060006005d680888808b0bbbb0b50000005
5f0ff0f5d0155ff1fd0fd0f5ff9950f90400400033b03300000077c0000077c005000600000000000100010055d605d005605dd680088008b000000b00000000
50ffff050111550150dddd0509ff55f100440400b3303b0000000700000007000060006000000000010001005dd605d605d65dd6e000000e3000000350000005
055555501111111005555550191191900040000033b03300ee0000008800000006000060000000000100010000000000000000000e8888e003bbbb3005055050
011111110e11e11e0e55e55e0e12e21e33000033bb0000bb220000228800008800aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
111110011211200e5edd2d0ee2e12e2e3bbb0003b333000b28880002822200080aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
d05101ddd05e01d25d0dd2de20eee22200b0bbb0003033300080888000202220aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
dd0511ddd20211dd52d02dd5dd2e222e00b0b0b0003030300080808000202020aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
dd05011dd202011d5dd02dd2de25eeed00b0bbb0003033000080888000202200aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
d0155011d21550115d0dd0d5d02550ee0000b0b0000030300000808000002020aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
011155010211550150dddd050111550e3000b0b3b000333b2000808280002228aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
1111111011111110055555501121111033000033bb0000bb22000022880000880aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
00000000000000000086860000000000001717171717378600000000171727170000171717000000001700000000373717171717170000d31717171717373737
172717171700000000000017271717179595959595959595959595a5959595959595959595959595959595959595a5959595959595959595a595959595959595
00000000000000000037373737860000001717271717173700006100b6b6b6170000b6b6b60000000027000000001727177727b6170000d627d3274717171717
000000271700740000000017000000009500000000b20000b2619595959595a59500000000710000959595a59595958595000000a300000000009595a5959585
0000000000000000371717171737000000b6b6b6b6b6001700000000000000170000000000000000001700000091171717002752170000e627d6270017172717
0000000017836400000000270000000095007400b5b5b5b5b5b5959595a59595950000c2c2b5b5008595959595959595a5610000a3007400000000959595a595
00000000000000001727171727170000000000000000001700000000860000170000000000000000001700000037b6171700b600270000002700270000001717
007300001747648600007317000000009500640000950000000095a5959595959513000000959500955200d40000959595d4b5b5b50064000000009595959595
740000000000000000172727170000000000000000000027000000002737d317000000000000000000170000b617711717000000176100000000000000000017
00c40000173737370037e41700b6c4009500b50000b60000000000959595a59595b5b500b59595e495b5b5b500740095950000959500640000009195959595a5
640000000000000000b6b6b6b60000000000d3d3d3000017000000000017e41700b6000091000000730000003723e41717000000170000000000000000000017
00b60073171717000017000000370000950000000000000000a200000000a29595959500009595b26100009500640095a500009595b5b5d4d4b5b59500009595
6471860000000000000000000000000000003737370000b6000000000017d3170037b6d3370000003737000017e4e42717d3d3d317000000000000d300711317
002700c4171700000017c400001700009500b5000000b50000a200000000a295959595b5009595b5b5b5009500b5b59595009195859595b3b395959500919595
373737000000000000000000000000000000002717000000000000000027e417611717171700830027170000270000171737373737000000b6b6b637b6373737
00000000171783740017000073270000950095000000950000a200b60000a29595a595000095a595959500d6000000959500b595959595d4b595959500b59595
17171700000000008600d3d3000061000000000017000000000000000017d317002700000000e400001700001700001717171717170000003737371717171717
0000c4001727006486000000c4170000950000b5000095b50000b5a5b5b5009595859500b59595959595b5b5b5b500959500710000959500009595950000a395
172700000000003737b63737b6272700d30000001700d3d3d30000000017d4170000000000860000001700d30086001717271727170000001717175727671717
0000b6b61717d43737b6b6b6b617810095006195000000000000000000000095a59595000000959100000000950000a595b5b500000095b5e4959595b5b50095
17000000000000171717171717270000270000000053373737000000000000000000008300272700000000373737d31717172717000000001717170027001717
e4b6373717170017172717171717e4e49500b59500000000000000000000b595959595b5000095b50000000095b50095a5959500000095950000000000000095
0000000000000000173737371700000000000000000017171700000000000000000000d4000000000000000000171717520000000074003737171700b6001727
003717172717001717171727170000009592000000009200000000740000009595950000000095000000000000000095959595e400009595b500740000b5b595
00000000000000000017171717000000000000000000002717007400008600000000373700000074000000000000172700000000006486000017270000002717
0017000000170000000000000000000095920000000092b5b500006400b50095a50000007400950000e4e40000e4e495959395000000000000006400a600a395
80130000d3d3d30000271717000000000000d3008613711717916400003737000000271700861364000083910000000083d3d3d3373737000000170000001717
00270000831700000000000000000000959200000000929595a60064a600a695950000916400d400a6000000a600009595a595e40000000000b5b5b5b50000a5
3737370037373700000000000000000000002700272737373737370000172700000017000037373700373737370000002727272717170000000017d3d3d31717
d31761005717d300000000867113860095801371a6b5b59595b5b5b5b5b5b595a500b5b5b5b5b5b5b50000b5b50000a59595950000a613a6000000a595000095
17271700271717000000000000000087000000000000171717271700001700000000000000171717001727170000000000000000270000000000373737373737
273737373737270000000037373737b095b5b5b5b5959595959595a59595959595879585959595a595b2b29595b2009595950000b5b5b5b5b500000095000095
95a5d5959595a5959595959595959595959595a5959595859595959595959595000000000000009400000000b4b4b4b4b0000000b4b4b40000000000000000a4
c500b4b4b4b4b4000000949494949494b4b4b4c5007400000000009494949494949494000000949494a4949494949494b4b4b40000e600172717731576252525
95950095959595910000579595a561959595000000959595950000000095a595000000000000009400000000949400008700000094a4000000000000000000a4
b400009494949400000094a49477949494a494b4b464c500000000946794b4b4b4b4b4000000946794949494d59457949494940000e600171717d41500000000
a5000000619595b5b5b5b595959500959500000000009595a500000000009595000000a40061009400f1000094000000007400009400000023000000000000a4
94000000a467940000009494f1f1f1a49494949494b4b4000000009400949494949494000000e60000d60094000000a484f1f1f1f1b600d60000001500000061
9500000000a29595b3b3b395a59500959574006100008595956100b2000095a5000000a4000000b600a4007494000000006413c594000000f1f1f10000000000
940000c5f1f1940000009494e4a46194b6c50033d4009400000000a400f100a494a494000000e691c5d671a400f1f19495e4a4a4a4a400d6d300001500000000
95000000a6959595959595959595c49595640000000095a595b5b5b500749595000000a4f100f1f1f1a400649461000000b4d4b4b4007400b4b4b40000000000
940000b4b4b4946100009494f1f1f194b4b4b4e4b40094000000009400a40094944794000000b4b4b4b4b49400b4b494956153a300000053d400325300000000
850000b5b5959595a595000093950095956400000000000000000000006495a5000000b4b4b6b4b4b4b4f1b4b400000000940094948164009494a4000000f1f1
94f1000000949400000094949494949494130091940000f10000719400a4f1940000d6000000949494949494f100949495e400000000003700373700e4e40000
950000959595a595959571009395009595b5b5000000000000000000b5b59595000000009494a49400f1f194a4f100000094f1f194b4b4009494b4b40000b4b4
9484000000009400f100a40000000000b4b4b4b4b40000a40000e494f100e4940000d600730094a4940000a4a4009494a5000083000000170000170075000000
9500009595a295959595b5b59395779595000000000000130000000000009595000000000094949400b4b4b494840000b69484d4949494b694949494b6b69494
94d57400000094008400a40000740000940000d4e60000a400000094b400009400e4e4b653b6009494910000a40094a495740000830000170000000565000000
9500000095959547000000c30095b595958200e4e40000b50000e4e40082959500000000000000a400f1f19494f10000b4b4f1f1a49494a49494b4b4b4b4b4b4
94d66400000094f1f1f10000006471c5947400a4a4a4a4a400470094940000a4830000a4d4a4000094b40000a400949495640000868300276100000065d40000
9500000000959500000074000095959595000000000000000000000000009595000000000000000000b4f194948400009494d4b49400000094a40000c5d49494
94136400008094b4b4b4000000b4b4b494640000000000a4b6b6b6a494005794c40000a432a40000000000f1f1f1949495b5b5373737e6170000000035350000
950000000095950000a66400009595a595000000e4e4000000e4e4000000859500000000000000000094f1f1c500f100f1f1f1949400520000a400b4b4f1f1f1
94b4b400e4e4a4949494e6e6e694009494b4b400000000b4b4b4b49494b6b69400000000e4000000000000b4b4b4a4943487000017174717b600000000430061
9500000000a2950000b5b5d50095959595000000000000000000000000009595000000000000f1f10094b4e4b4b4b400b4b4b49494e4840000a4009494b4b4b4
9494000000c500000000e4e4e4945294a49494000000919494a4949494b4b4b400e600000000000074000094949477941400740000d5343434000000000600c4
95130000a6000000009595d4006795959500e4e4000000007400b5e4e4d495957113c5f10000b4b40000f1f10094a400f1000000a4d4000000a400d6000000f1
9400000000b4b40000000000009452a49494940084e4b4b4b494a4947794a400000000f1f1f183006400009473a400002471641380819696240000d446005600
95b500b5b5b500000095a5b5b5b59595959100a600000000640095a600006195b4b4b4b4000094940000b4b400009400b4330000b4b40000000033d6000000b4
0000000000a4940000000000009400949494005300d400c50094949400940000000000b4b4b4b40064000094d453610014e43434343400009600003636363600
a5950095a5950000009595959595958595b5b5b5b500a67164a695b5b5b5b5959494a4000000a494000094940000000094c50061a4a4f1f1f1f1f1a4c571c594
000000470094a4000000000000a45794940000b4b4b4b4b432a491e6f1d6610000130094949400c56491009432a4c40014001424149600000023440000262600
959587a59500000000959595a59595959595859595b5b5b5b5b595959595959594948700000094940000a4000000000094b4b4b4a4a4b4b4b4b4b4b4b4b4b494
000000000094000000000000009400940000000094949494b4b4b4b4b4b4b400008400a4940000b4b4b400949494000014571414960000000034343400160000
__gff__
0000000000000000000000000000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101808080800101010102010201010101018080808001010101800101000101010180800000808080000001010001010101000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000000000000000004141415d414241410078000000000000414141410000004170417041000000434343434300000000007841000000000041334170417041000000410000000000000070000000000041700000000000000000000000000000007800000000000000000000000000000078
00000000000031000000000000000000434300000000004141004141696900004443430000007041690000000070417041420000006941417041000000000000410000000000416d44006e0069000000700000000000000041000000000041410000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004141470016000069410042000000000043434100000042000000000000705d417041000000005d5d414200000000000070160000000070434343430000000000410000000016000070170000000041410000000000000000000000000000000000001600000000000000000000000000
0000000000000000000000000000000042414600000000007000000000000000704141001600420000000047006900694141180000000000694100320000000041000000420041414141410000000000410032000043000041421833440075410000000000000000000000000016000000000000000000000000003400340000
00000000000000000000000000004700414143004400000041000000000000004343430000004200000000460000000041414343000000000043434d430043004100003342004143434370000000000070334d004542000041434343434341410000000000000000000000000000000000000000000000000064004e004e0000
00000000000000000000000000004600704141434343000000434300000000004170410000006900320000461744000070321642004700000070691642324200414e4e4e000041414141700000004700414d4242424200006969696941414241000000000034000000000000003400000000004c00004c000063630000340000
00000000000000000000000000084600694041704169004700696900320000004341410000470000424200434343000041414d420046000000410042424e42007000000000006d6900006e0000004600410069690069000000004400417041700000004e4e604e4e0000004e4e4e4e4e0000004c00006b6b6b62610000630000
000000000000000000000000434343000000006900000046000000004e4e4e0041704133004644004269004041690000417044000046000000410042004d69006900004200006d0000006e000017460041434343000000000043434d41414141000000641634170000000000000000000000004c006b63636362621965620000
000000000000000000004e4e425d41000000000000000046324400000000000070414343434343434300000069000000434343434343000000410000004d0000000000690000430000004300434343000032694d000042000069403316444170000000636363636300000000006000000000006b6b6362626261626363630000
00000000000000000000000000006900000000000000434343430000004200004170417041426900690000000000004541004d00694100000069004500000000000047000000410000004123417041000043434d0000690000004343434341700000000000000000000000000000650000006363636260620000006262610000
00000000000000004700000000000000000000000000414169000000000000004169000000690000000000000000434341174d0000410000000000434300000000314644000070004200704e704141000032004d0000000000006900690041410000000000000000000000000063630000000000000000000000005d61620000
00004407000000444600170044000000451731440000416900470000004200006900000000000000000000000000414170434300000000004700006941000000004343430000003340004100414269000043434d0000000000000000000041700031650000000000000000006400000000000000000000000000000000000000
004343434343434343434343434300004343434300000000004600003200000000000819000000470000443100005d41704169000000000046000000690000000041704343434e4e0000000069700000007041000044310000000000000041410063630000000000000000006363000064310000000000000000006517000000
000042414343705d705d7041690000004170424100000000454600004343430000434343430032460000434300004d704100000044310000464400000000000000694241417000190000004400410000004169000043434300420033440074410061616400340065003464006100000063630000000000000000636363000000
00000040414141007000700000000000704170000000004343430000414241000041704169004343430069434343434169000000434300004343000000000000000000690040004343000043006900000000000000417041004343434343414100006363636363636363630000000000626200004c4c004c4c00006062000000
0000000000700000690000000000000041706900000000694170000000417000000000000000704170000069694141700000000070410000417000000000000000000000000000417000004100000000780000000069410000696969414170700000000061616162616200000000000061000000000000000000000000000000
6261626261626262000000000000007800000000000000006162326363636300626262610000000062626162006363635252525252525252525252525252525151525252525252525252525252525252525252525252525353535251515151515151515152525267525252525252525252525252525252525252525151515151
6162625e626261623400000034000000000000000000000062616d6261000000626363630000000063636362346261625266666652525252000000666666005151000000175252525252520000000000526666005252525252525200000067515151515100000000000000000052535300525252000066525252665151515167
62620000000000354d00000060000065000000340000000061620062620000006262616200000000616262614d6262615200000052535300005700000000005151000053535352525252000000322355520000005253535353520000000000515166666600000000000000000052525200525252000000525252005151515100
000000000000006300000000000000630025644e0000000062616e00000000006363636200000000626162623461626252160000525252175456000000000051510000000000006766000000005353535216550052525252525200000054005151000000000000000000325416525252004d176d0000006d0000005125515116
0008000000006462230000000000006200636363636b6e0062610000000016006262756200000000350000004d6274615200000000525252525200005050005353006e000000000000000000000000525353530052526700006700005353005151000057000000500000535353525252535353530000006d0000005100675153
636300000063636363000000000000620000616261630000616200000000000062620061004c00006000000000626d625200540000000066666600005016555151000000000055005400000000001652525252005d52000000005700515100515177005600536b506b6b525266666652006666660000196d00000051004d0000
62000000006261626000000064001962000000000062004c00000000320035006200166200000000350000004d0000005253535300005700000000505353535151006d00000053535353000000000052525252004d52000000005600515100515100555600525353535352000000005200000000570053530000005151000000
000000000062620000000000634e63630000000000600000000000004e4e4e006200636200004c006000000000004c0052525252000056005500000051515151510000000000005252520000000000525200660000005400000056195100005153535353535252525200000057000052000054005600665200004e5151005400
00004c000062000000006e00621600620000000000626d004c000000646500646200626200000000350000004d000019525252526b5353535353000051515151510000006e00000052526b00006e6e5352000000535353536b535353510050515166666600000000500000005600765200535353530000520000005151535300
000000000061000000006b00614e4e6200340025006100000000340063636363620000620000004c6000000000000063525252525352525252000000515353535300000000000000525250000000005252004d00665252665252525251006651510000001700000050000000565500526b5252525200005200004e515151516b
00000000006200004c00630062000061004e4e4e0062006e006d6d00006261623418006100000000000000004d000000525252525252666600000050515151515100570000006d00525250000000005252004d00000000000000000051500051510000005353000053536d6d5353535353525252670050520000005151515153
000000004c0000000000620000006d61000000340062000000000000006e00616363006200004c000000000000006d0000000052520000000054000000675151510056000000000000006b000000005252000000000000000000570051660051510000556e00000052520000006e3152000008520000005200004e5151000000
00000000000000000000620000000000004e4e4e00000000006e6e00006e17621731640000000000000000002300000000000066660000535353000057005151510056006e000000534e0000000000525200000053000053000056195100505151005353530000005252000000535352000b535200004e520019005151005700
653164000017190000006100006d6d000000656400006431000000000063636363636300004c0000006e6e0063000000003155000000005252000000560016515131560000000000520000000000005252315400520000520000535351001751510025500000000052000000000052520000314d000000520053005151195600
6363630000636300006d6200000000000063636300006363000000000061626262620000000000000000000062000000005353535353005252000053535353535353530000000000526d00006e6b6b52535353005200005200000051515353535353530000007400520000750000525200535353530000520052000051535300
6262000000626200000061000000000000626262000062610000000000626261000000000000000000000000610000787852525252000052000000000051515151515100000000005200000000535353525200005200005200000000515151515151000000000000520000000000785200525252000000520052000051515100
__sfx__
0b0f00000c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c17000000000000000000000000000000000000000000000000000000000000000000000000000000000
930c00003f64500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
934000003f65500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480300000c1600f1501114013130151201611018110181100c7600d05013040131300456004510045600451004550045100454004510045300451004520045100451004510000000000000000000000000000000
920300001375015750187501a7501f7502175015750177501c7501e7502375025750187501a7501f7502175026750287500000000000000000000000000000000000000000000000000000000000000000000000
480200000e6501f64012630000000000000000000000c64000000076101316016150181401a1301c1201d1101f1101f1100000000000000000000000000000000000000000000000000000000000000000000000
00020000240502205018050130500a04005040155700000013560000000e550000000c54000000095300000007520000000251000000005100000000000000000000000000000000000000000000000000000000
000300002375023730287502873021750217301c7501c730190600000019060000001905000000190500000019040000001904000000190300000019030000001902000000190200000019010000001901000000
0003000026620216201913016130131300a1300613000000000001910016100131001912016120131200a120061200a100061000000000000000001911016110131100a110061100457006560095500e54000000
000100000c050000000f050000000605000000150500000018050000001b050000001d05000000210500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080400001a0401a040260402604026030260202601026010260102601000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480600000e073150731a0732107321063210632105321053210432104321033210332102321023210132101321013210130000000000000000000000000000000000000000000000000000000000000000000000
480500003262532625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040200000f1000f1000f1400f1400f1400f1401414014140141301413016120161201611016110161101611000100001000010000100001000010000100001000010000100001000010000100001000010000100
100400000e55013550155501a5501a5401a5301a5201a5101a5101a51000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020200001a0631a0631f0530000021000000002b0002b0432d0332d0002d033320233200032000320132d01300000000000000000000000000000000000000000000000000000000000000000000000000000000
0403000007170091710a1610c1510e1410e1300c1700e1710f161111511314113130131601516116161181511a1411a1300000000000000000000000000000000000000000000000000000000000000000000000
000500000e142131421514213142151421a142151421a1421f1421a1421f142211421f142211422614221142261422b1422d1422b1422d132321322d1322b1322d122321222d122321222d1122b1122d11232112
040500000215004150091510915007150001510010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000
0b0f00010983009800098000980009800098000980009800098000980009800098000980009800098000980009800098000980009800098000980009800098000980009800098000980009800098000980009800
010f00201fa301fa301993019900189400000019920189001994019900189200c000199300c0000c0430c03319930199001892033600199300c0001892018900199300c043189200c000199300c0001894019930
0b0f00200a8300a8300a8300a8300a8300a8300a8300a8300a8300a8300a8300a8300a8300a8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c83011830138311383013830
0b0f00200e8300e8300e8300e8300e8300e8300e8300e8300e8300e8300e8300e8300e8300e830078400784007840078400784007840078400784007840078400784007840078400784005850058500585005850
810f0020210452102515045150251a0451a0251d0451d0251c0321c02218032180221503215022210452102515045150251a0451a0251d0451d0251c0421c02218032180221a0321a02215032150221303213022
010f00200c043336000c0231fa001fa301fa300c03318900336351fa00326150c0001fa201fa200c0330c0000c013189000c03318900199401a9400c0430c023336351fa0032615336001fa301fa300c0331a000
810f00201c0001c000230452302517055170351e0551e0351e0451e0251d0001d0001e0351e01526000260001e0351c000230452302517055170351c0551c0351e0521f0521e0521c0321a0521a0321505215032
0b0f00010c8300c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c80009800098000980009800098000980009800098000980009800098000980009800098000980009800
010f00200c033336001fa301fa30326250000019940189300c03319940189300c033326250c023189300c0230c033199400c02333615326250c02319940189300c03319940189300c033326250c0231fa301fa30
810f00201c0001c00015045150251a0551a0351c0551c0351c0451c0251d0001d0001c0351c01526000260001c0151c00015045150251a0551a0351c0551c0351805518035150551503517055170351305513035
010f00200c033336251fa301fa30326250000019940189300c03319940189300c033326250c023189300c0230c033199400c02333615326250c02319940189300c03319940189303361532625336251a0431a043
310f00201a5321b5311c5311c5321c5321c5321c5321c5321c5321c5321c5321c5321c5321c5321a5311a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321353213532
310f002013532135321353213532135321353213532135321353213532135321353210532115311053110532105321053210532105321053210532105321053210532105310f5310f5310e5310e5310d5310d531
0b0f00200a8550a855168551185515855168550a8550a8550a8550a855168551185515855168550a8550a8550c8550c855188551385516855188550c8550c8550c8550c855188551385516855188550c8550c855
0b0f00200e8550e8551a85515855188551a8550e8550e8550e8550e8551a85515855188551a8550e8550e8550785507855138550e855118551385507855078550785507855138550e85511855138550785507855
0b0f00010484004800048000480004800048000480004800048000480004800048000480004800048000480009800098000980009800098000980009800098000980009800098000980009800098000980009800
550f00011701017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000
810f00201c0001c00015045150251a0551a0351c0551c0351c0451c0251d0001d0001c0351c01526000260001c0151c00015045150251a0551a0351c0551c0352404224022260422602223042230221f0421f022
810f0020210452102515045150251a0451a0251d0451d0251c0321c02218032180221503215022210452102515045150251a0451a0251d0451d0251c0421c0222403224022260322602223032230221f0321f022
310f00201e0001e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000026042260222601226012280422802224042240222104221022
c10f0020132001e2001c2521c2321c2121c2121c2521c2321c2121c2121e2521e2321e2121e2121e2521e2321e2121e2121f2521f2321f2121f2121e2421f24221252212321f2521f2321e2521e2321a2521a232
310f00201c5421c5421c5321c5221c5121c512185421852218542185421853218522185121851217542175221754217542175321752217512175120e5420e5220e5420e5420e5320e5220e5120e5120e5120e512
c10f00200c2000c2001c2521c2321c2121c2121c2521c2321c2121c2121e2521f2511e2521e2320e2520e2320e2220e2220e2220e2220e2120e2120e2120e2120e2120e21223200232001f2001f2001a2001a200
c10f0020134001e40018452184321841218412174521743217412174121045210432104121041218452184321841218412174521743217412174121e4421f442244522443223452234321f4521f4322144221422
310f0020135001e5001c5001c5001c5001c5001c5001c5001c5001c5001e5001e5001e5001e5001e5001e5001e5001e5001f5001f5001f5001f5001d5521f5521d5521d5121c5421c51218552185121554215512
310f00201a5521a5121a5221a5121a5121a51213542135121352213512155421551215522155120e5520e5120e5220e5120e5120e5120e5120e5121d5521f5521d5521d5121c5421c51218552185121554215512
310f00201a5521a5121a5221a5121a5121a51221542215122152221512225422251221542215121f5421f5121f5221f5121f5121f5121f5121f5121d5521f5521d5521d5121c5421c51218552185121554215512
310f00201a5521a5121a5221a5121a5121a51213552135121352213512155421551215522155120e5520e5120e5220e5120e5420e5420e5320e5320c5410c5420c5320c532115521151213552135121555215512
310f0020155521551215522155121551215512155121551215512155120e5520e5121555215512135521351213522135120e5520e5121355213512115521355211552115120e5420e5120c5520c5120954209512
0f0f00011a0351a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a000
0b0f00010b8300b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b800
0b0f00200784007840078400784007840078400784007840078400784007840078400784007840078400784006840068400684006840068400684006840068400684006840068400684006840068400684006840
0b0f00010e8300e8000e8000e8000e8000e8000e8000e8000e8000e8000e8000e8000e8000e8000e8000e8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b800
310f00200e5520e5120e5220e5120e5120e5120e5120e5120e5000e5000e5000e5000e5000e5000e5000e5001e5001e5001f5001f5001f5001f5001d5001f5001d5001d5001c5001c50018500185001550015500
810f00201c0001c00017055170351c0551c0351e0551e0351e0451e0251d0001d0001e0351e01526000260001e0151c00017045170251c0551c0351e0551e0351a0521a052170521703219052190321505215032
810f00201c0001c00023055230351e0551e0352a0552a0352a0452a0251d0001d0002a0352a01526000260002a0151c00023045230251e0551e03523055230352505226052250522303221052210321e0521e032
0f0f00011a0251a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a0001a000
0d0f00011e0101e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e0001e000
010f00200c043336000c0231fa001fa301fa300c03318900336351fa00326150c0001fa201fa200c0330c0000c013189000c03318900199401a9400c0430c02333635199000c0231a0001a0431a0430e0531a000
310f00201c5001c5001c5001c5001c5001c5001c5001c5001c5001c5001c5001c5001c5001c5001a5001a5001a5001a5001a5001a5001a5001c500205422154220542205121e5421e5121c5421c5121954219512
310f00201e5421e5121e5221e5121e5121e51217542175121754217512175221751217512175121751217512175121751217512175121a5001c500195421a5521954219522175421752215542155221254212522
310f002017542175121752217512175121751210542105121054210512105221051210512105121051210512105121051210512105121a5001c5000e5420e5221254212522155421552219542195221c5421c522
310f002021542215122152221512215122151221512215122151221512215122151219542195221e5421e5121e5221e5121e5121e5121e5121e5121e5121e51219542195221c5421c522195421c5421954215542
310f00201254212512125221251212512125121251212512125121251212512125121251212512125121251212512125121251212512125001e5000e5420e5221054210522155421552217542175221a5421a522
810f00201c0001c00023055230351e0551e0352a0552a0352a0452a0251d0001d0002a0352a01526000260002a0152a0152a000230002a0152a01523000230002a0152a000250002300021000210001e0001e000
__music__
00 54131c5e
00 541a1c5f
01 14131c54
00 141a1c26
00 14131c27
00 141a1c28
00 14131c2a
00 141a2429
00 1b15175b
00 1b16175b
00 1b15175b
00 1d16172b
00 1b15302c
00 1b16302d
00 1b15302e
00 1b16172f
00 1b15172c
00 1b16172d
00 1b15172e
00 1b16172f
00 1b151734
00 1b161737
00 1b151737
00 1d161778
00 18311944
00 18131944
00 18323544
00 1833367a
00 18311944
00 18131944
00 18323544
00 18333f3a
00 1831383b
00 1813383c
00 1832383d
00 1833363e
00 1831193b
00 1813193c
00 1832353d
00 39333f3e
00 5413171e
02 541a171f
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 62222344

