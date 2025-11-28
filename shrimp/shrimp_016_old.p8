pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- shrimp
ver="016"

acx=0.2 --x accel
p_x_max=1.5 --x speed max

acy=0.2 --y fall accel (grav)
acyj=0.1 --y float accel
p_f_max=2 --fall speed max
p_j_max=-2 --float speed max
p_c_ref=100 --charge refresh spd
p_c_max=80 --charge max
ifrm_max=45 --iframes

f_spd=0.3		--frog anim speed
f_t_max=16.55	--frog time max
dk_spd=1.7				--duck speed
dv_spd=1.2			--dvd speed

str_t_min=30
str_t_max=100
str_t_shn=20

crl=9

logo_t=0
expo_t=0
mode="expo"

uits,l_uits=-0.1,-1 --ui time slow
uitf,l_uitf=-0.1,-1 --ui time fast

p_scrs={}

function _init()
	printh("=======start=======")
	//reset_lvl()
	reset_cam()
	for i=1,#lvls do
		p_scrs[i]=0
	end
	
	init_stars()
end

function _draw()
	cls(0)
	camx=mid(cmi*8,camx,(cmi+cmw)*8-128)
	camy=mid(cmj*8,camy,(cmj+cmh)*8-128)
	camera(flr(camx),flr(camy))
	
	draw_stars()
	
	if logo_t<180 then
		draw_logo()
		return
	end
	
	if mode=="expo" then
		draw_expo()
	elseif mode=="title" then
		draw_title()
	else
		draw_game()
	end
	
	//
	//print("scr:"..scr,camx,camy,7)
end

function reset_cam()
	camx,camy=0,0
	cmi,cmj=0,0
	cmw,cmh=16,16
end

function _update()
	l_uits,uits=uits,(uits+0.1)%30
	l_uitf,uitf=uitf,(uitf+0.2)%30
	
	update_stars()
	
	if logo_t<180 then
		logo_t+=2
		if logo_t<90 and btnp(❎) then
			logo_t=90
		elseif btnp(❎) then
			logo_t=180
		end
		
		if logo_t==180 then
			music(0)
		end
		return
	end
	
	if mode=="expo" then
		update_expo()
	elseif mode=="title" then
		update_title()
	else
		update_game()
	end
end

function draw_expo()
	//line(10,0,10,127,1)
	//line(64,0,64,127,1)
	//line(120,0,120,127,1)
	print(expo_s,10,128-expo_t,6)
	if expo_t>220 then
		print(
			"press ❎ to continue",
			25,110,1)
	end
end

function update_expo()
	expo_t+=0.3
	if btnp(❎) then
		init_title()
	end
end

function draw_title()
	print(ver,0,0,1)
	rectfill(0,64,127,127,0)
	rectfill(0,124,127,127,13)
	
	--shrimp
	if crl<9 then
		print("z",
			23,
			100+((uits/2)%2),
			1)
		print("z",
			27,
			105-((uits/2)%2),
			1)
	end
	if crl==9 then
		pal(3,1)
		pal(4,2)
	end
	spr(
		tit_t<8 and 25 or 23,
		6,102,2,3)
	pal()
	
	--window
	if crl==4 then
		if flr(uits)%2==0 then
			pal(1,12)
			pal(15,12)
		else
			pal(1,8)
			pal(15,8)
		end
	else
		pal(15,0)
		if tit_t<8 then
			pal(1,5)
		end
	end
	spr(29,72,90,2,2)
	pal()
	
	--tv
	if(tit_t<8)pal(13,6)
	spr(27,100,102,2,3)
	pal()
	
	if tv_s[crl] and
				tv_idx<=#tv_s[crl] then
		if tv_tm>=0 then
		
			rectfill(38,62,105,100,0)
			rect(38,62,105,100,7)
	
			pal(15,0)
			pal(0,false)
			spr(31,95,100)
			pal()
			local ts=tv_s[crl][tv_idx]
			print(
				sub(ts,0,min(tv_tm,#ts)),
				40,64)
		end
	elseif crl<9 and
		(tit_st==0 or flr(uitf)%2==0) then
		print(
			"press ❎ to start",
			28,114,1)
	end
	
	if crl==9 then
		//line(64,0,64,128,1)
		print("~ fin ~",51,30,12)
		if tit_m_t>60 then
			print("play again", 45,70,1)
			print("quit", 57,80,1)
			if flr(uitf)%2==0 then
				spr(63,30,69+tit_m_idx*10)
			end
		end
		
		spr(61,115,118)
		spr(62,92,118)
		spr(61,14,112)
		spr(62,0,118)
	end
end

function init_title()
	mode="title"
	tit_t=0
	tit_st=0
	tv_tm=-10
	tv_idx=1
	tit_m_idx=0
	tit_m_t=0
	reset_cam()
	camera(0,0)
	if clr==9 then
		music(-1)
	end
end

function update_title()
	if tit_st>0 then
		tit_st-=1
		if tit_st==0 then
			mode="game"
			init_lvl()
			if(crl==0)music(8)
		end
	elseif crl<9 and btnp(❎) then
		if tv_s[crl] and
					tv_idx<=#tv_s[crl] then
			if tv_tm<#tv_s[crl][tv_idx] then
				tv_tm=#tv_s[crl][tv_idx]
			else
				tv_idx+=1
				tv_tm=-10
			end
		else
			tit_st=40
			if crl==0 then
				music(-1)
				sfx(48)
			end
		end
	end
	
	if tit_t==0 then
		tit_t=rand(10,50)
	else
		tit_t-=1
	end
	if(crl==9)tit_t=100
	
	tv_tm+=0.5
	if tv_s[crl] and
				tv_idx<=#tv_s[crl] and
				tv_tm>#tv_s[crl][tv_idx]+20 then
		tv_idx+=1
		tv_tm=-10
	end
	
	if crl==9 then
		tit_m_t+=1
		if tit_m_t>=60 then
			if btnp(⬆️) or btnp(⬇️) then
				uitf,uits=0,0
			end
			if(btnp(⬆️))tit_m_idx=0
			if(btnp(⬇️))tit_m_idx=1
			if btnp(❎) then
				if tit_m_idx==0 then
					extcmd("reset")
				else
					stop()
				end
			end
		end
	end
end

function draw_game()
	//loga({cmi*8,camx,(cmi+cmw)*8-64})
	
	local cx64=camx+64
	local cy64=camy+64
	local lt="channel "..crl+1
	local ps="par: "..lvls[crl+1][5]

	if l_st_t<60 then
		print(
			lt,
			cx64-txt_cen(lt),
			camy+60,
			7)
		print(
			ps,
			cx64-txt_cen(ps),
			camy+70,
			7)
		return
	end
	
	
	if l_ed_t<60 then
		map(0,0)
	
		--[[
		for t in all(tris)do
			local c=t.test and 11 or 7
			for i=1,3 do
				t1=t[i]
				t2=t[i%3+1]
			end
		end
		]]--
	
		draw_bg()
		draw_enemies()
		draw_fg()
	
		if pdt==0 then
			draw_player()
		else
			draw_die()
		end
	
		draw_effs()
	end
	
	if l_ed_t>-1 then
		--draw title and par
		print(
			lt,
			cx64-txt_cen(lt),
			camy+20,
			7)
		print(
			ps,
			cx64-txt_cen(ps),
			camy+30,
			7)
	end
	if l_ed_t>80 then 
		-- player strokes
		local ss="strokes: "..scr
		print(
			ss,
			cx64-txt_cen(ss),
			camy+40,
			7)
	end
	if l_ed_t>90 then 
		-- collected tapes
		for i=1,l_tape do
			if i>n_tape then
				pal(5,1)
				pal(6,1)
				pal(7,1)
				pal(13,1)
			end
			spr(
				48+flr(uitf)%4,
				cx64-(l_tape*10)/2+(i-1)*10+1,
				camy+50)
			pal()
		end
	end
	if l_ed_t>100 then
		-- totals
		local tlscr=0
		local tpscr=0
		//for i=1,#lvls do
		//	tscr+=lvls[i][5]
		//end
		
		//line(camx,0,camx,128,1)
		print("par",cx64-50,camy+54,7)
		print("shrimp",cx64-50,camy+82,7)
		for i=1,#lvls+1 do
			if i<=crl+1 then
				tlscr+=lvls[i][5]
				tpscr+=p_scrs[i]
			end
			local xx=cx64-((#lvls+1)*10)/2+(i-1)*10
			
			rect(
				xx,camy+60,
				xx+10,camy+70,7
			)
			local cc=0
			if i<=crl+1 then
				cc=13
				if p_scrs[i]<lvls[i][5] then
					cc=3
				elseif p_scrs[i]>lvls[i][5] then
					cc=2
				end
			elseif i==#lvls+1 then
				cc=13
				if tpscr<tlscr then
					cc=3
				elseif tpscr>tlscr then
					cc=2
				end
			end
			rectfill(
				xx,camy+70,
				xx+10,camy+80,
				cc
			)
			rect(
				xx,camy+70,
				xx+10,camy+80,7
			)
			
			if i==#lvls+1 then
				print(tlscr,xx+2,camy+63,7)
				print(tpscr,xx+2,camy+73,7)
			elseif i<=crl+1 then
				print(lvls[i][5],xx+2,camy+63,7)
				print(p_scrs[i],xx+2,camy+73,7)
			else
				//print("?",xx+2,camy+63,7)
			end
		end
		
	end
	if l_ed_t>110 then 
		-- continue
		local ss1="continue"
		print(
			ss1,
			cx64-txt_cen(ss1),
			camy+100,
			7)
		local ss2="retry"
		print(
			ss2,
			cx64-txt_cen(ss2),
			camy+107,
			7)
		if flr(uitf)%2==0 then
			spr(
				63,
				cx64-30,
				camy+99+7*l_ed_idx)
		end
	end
	
	draw_npc_txt()
end

function update_game()
	if l_st_t<60 then
		l_st_t+=1
		return
	end
	
	update_effs()
	
	if npc then
		npc.t+=0.15
		if(npc.t>4)npc.t=0
		if not ptn then
			npc_t=0
		elseif npc_t>0 then
			npc_t+=0.5
		end
	end
	
	if l_ed_t>-1 then
		l_ed_t+=1
		
		if btnp(❎) then
			if l_ed_t>=100 then
				if(l_ed_idx==0)crl+=1
				if tv_s[crl] or crl==9 then
					init_title()
				else
					init_lvl()
				end
			else
				l_ed_t=100
			end
		end
		
		if l_ed_t>=100 then
			if btnp(⬆️) or btnp(⬇️) then
				uitf,uits=0,0
			end
			if(btnp(⬆️))l_ed_idx=0
			if(btnp(⬇️))l_ed_idx=1
		end
		return
	end
	
	camx=flr(pp.x)-64
	camy=flr(pp.y)-64
	
	if npc_t==0 then
		update_enemies()
	
		if pdt==0 then
			update_player()
		else
			update_die()
		end
	end
	
	--touch npc
	ptn=false
	if npc and col_bb(pp,npc) then
		ptn=true
		if btnp(❎) then
			if npc_t==0 then
				npc_t=1
			elseif npc_t<#npc_txt then
				npc_t=#npc_txt
			else
				npc_t=0
			end
		end
	end
end
-->8
-- player
dss={1,5,6,7}
dtexts={
	"you died",
	"shrimp dead",
	"career over"
}
function draw_die()
	idx=min(flr(pdt),#dss)
	spr(
		dss[idx],
		pp.x-4,pp.y-4,
		1,1,
		pvx<0)
	
	local ds=dtexts[didx]
	print(
		ds,
		camx+64-(#ds*4)/2,
		camy+60,
		8)
end

spt=0
function draw_player()
	spt+=0.5*abs(pvx)
	if(spt>=4)spt=0
	if ifrm%2==0 then
	spr(
		1+(proll and spt or 0),
		pp.x-4,pp.y-4,
		1,1,pvx<0)
	end
	
	if ppf then	
		draw_meter(ppc/p_c_max)
	elseif prt>0 then
		draw_meter(prt/30)
	end
end

function draw_meter(per)
	line(
		pp.x-5,pp.y-7,
		pp.x-5+per*8,pp.y-7,
		8)
	rect(
		pp.x-5,pp.y-8,
		pp.x+4,pp.y-6,
		7)
end

function reset_player()
	pp.x,pp.y=chx,chy
	pvx,pvy=0,0
	pdo=true
	ppc=min(ppc+p_c_ref,p_c_max)
	for b in all(bats)do
		b.got=false
	end
	ifrm=ifrm_max
end

function update_player()
	if(ifrm>0)ifrm-=1
	
	ppf=false --player flying
	if(not btn(🅾️))pdo=false
	if btn(🅾️) and
				ppc>0 and
				not pdo then
				//and pcdn==0 then
		-- jumping
		pvy=max(pvy-acyj,p_j_max)
		ppc-=1
		ppf=true
		dpo=true
		proll=false
		add_fdot(pp.x,pp.y)
		
		if not ipo then
			sfx(44)
		end
		ipo=true
	else
		-- gravity
		pvy=min(pvy+acy,p_f_max)
		ipo=false
	end
	
	if not pp_ong then
		if btn(➡️) then
			pvx=min(pvx+acx,p_x_max)
		elseif btn(⬅️) then
			pvx=max(pvx-acx,p_x_max*-1)
		end
	end	
	
	pp.x+=pvx
	pp.y+=pvy
	//loga({pvx,pvy})
	
	-- speed
	pps=sqrt(pvx^2+pvy^2)	
	-- angle
	ppa=atan2(pvx,pvy)
	
	-- triangle collision
	local tch_tri=false
	for t in all(tris)do
		-- resolve the collision
		t.test=false
		local ox,oy=0,0
		while c_in_tri(
				pp.x+ox,
				pp.y+oy,
				t
		) do
			t.test=true
			tch_tri=true
			proll=true
			ox+=cos(t.n)
			oy+=sin(t.n)
			printh("here tri")
		end
		
		-- find new direction
		if ox!=0 or oy!=0 then
			pp.x+=ox
			pp.y+=oy
			
			reflect(t.n,t.frx,t.fry,proll,"tri")
		
			if oy>0 then
				sfx(4,1)
			else
				sfx(3)
			end
		end
	end
	
	-- vert solid colision
	if not tch_tri then
		local cv=c_on_sol(pp.x,pp.y)
		if cv then
			pp.y=(flr(pp.y/8)*8)+4
			//printh("here vert")
			local f=sols_m[cv.s]
			reflect(0.25,f[1],f[2])
			if cv.y>pp.y then
				if not pp_ong then
					sfx(f[3],1)
					if cv.s==96 then
						-- add sand dust
						local nd=rand(2,5)
						for i=0,nd do
							add_dust(
								pp.x+sgn(pvx)*3,
								pp.y+4,
								pvx*rand(1,3),
								rand(1,2)*-1,
								15
							)
						end
					elseif cv.s>=112 and
												cv.s<=114 then
						-- add couch dust
						local nd=rand(2,5)
						for i=0,nd do
							add_dust(
								pp.x+sgn(pvx)*3,
								pp.y+4,
								pvx*rand(1,3),
								rand(1,2)*-1,
								13
							)
							add_dust(
								pp.x-sgn(pvx)*3,
								pp.y+4,
								pvx*rand(1,3),
								rand(1,2)*-1,
								13
							)
						end
					end
				end
				pp_ong=true
				proll=true
			else
				sfx(4,1)
			end
		else
			pp_ong=false
		end
	end
	
	-- horz solid colision
	local ch=c_on_sol(pp.x+pvx,pp.y)
	if ch and 
				abs(ch.y-pp.y)<=5 then
		pp.x=(flr(pp.x/8)*8)+4
		printh("here hh")
		local fr=sols_m[ch.s]
		reflect(0.5,fr[1],fr[2])
		pvx=max(abs(pvx),1)*sgn(pvx)
		sfx(4,1)
	end
	
	-- recharge
	if pp_ong then
		if pps<=0.5 then
			if dpo then
				//printh(ppc)
				pscr()
				//add_fanf(scr)
				chx,chy=pp.x,pp.y
				prt=1
				sfx(49)
			end
			dpo=false
			ppc=min(ppc+p_c_ref,p_c_max)
		end
	end
	
	-- aesthetic recharge time
	if prt>=30 then
		prt=0
	elseif prt>0  then
		prt=min(prt+2,30)
	end
	
	-- die off screen
	//if pp.y>cmy+cmh*8+8 then
	//	kill_player()
	//	return
	//end
	
	-- touch flag
	if col_bb(pp,flag) then
		printh("touch flag")
		pscr()
		l_ed_t=0
		sfx(7)
	end
	
	-- touch enemy
	if ifrm==0 then
		for e in all(enemies)do
			if col_bb(pp,e) then
				kill_player()
				local d=e.x-chx
				if abs(d)<8 then
					loga({"ouch",d})
					chx-=1*sgn(d)
				end
				return
			end
		end
	end
	
	--touch tape
	for t in all(tapes)do
		if col_bb(pp,t) then
			del(tapes,t)
			n_tape+=1
			sfx(50)
		end
	end
	
	--touch battery
	for b in all(bats)do
		if not b.got and 
					col_bb(pp,b) then
			//del(bats,b)
			b.got=true
			ppc=p_c_max
			prt=1
		end
	end
end

function kill_player()
	pdt=1
	didx=rand(1,#dtexts)
	sfx(5)
	pscr()
	dpo=false
end

function update_die()
	if pdt<20 then
		pdt+=0.5
	else
		pdt=0
		reset_player()
	end
end

function pscr()
	scr+=1
	p_scrs[crl+1]=scr
	add_fanf(scr)
end

function reflect(n,frx,fry,roll)
	local d=(ppa+0.5)%1
	local d2=d-n
	local ra=n-d2
	
	pvx=cos(ra)*pps
	pvy=sin(ra)*pps
	pvx*=1-frx
	pvy*=1-fry
end

-- test points around circle
-- for triangle collision
function c_in_tri(x,y,t)
	for i=0,15 do
		local a=i/16
		local ox=cos(a)*4
		local oy=sin(a)*4
		local f=pt_in_tri(
			x+ox,
			y+oy,
			t
		)
		if(f)return f
	end
	return nil
end

function c_on_sol(x,y)
	for i=0,15 do
		local a=i/16
		local ox=cos(a)*4
		local oy=sin(a)*4
		
		local mi=flr((x+ox)/8)
		local mj=flr((y+oy)/8)
		
		for j=min(cmj+cmh,mj+1),max(cmj,mj-1),-1 do
		for i=min(cmi+cmw,mi+1),max(cmi,mi-1),-1 do
			local s=mget(i,j)
			if fget(s,0) then
				local b=obj(
					i*8+4,
					j*8+4,
					8,8
				)
				b.s=s
				if pt_bb(x+ox,y+oy,b) then
					return b
				end
			end
		end end
		
	end
	return nil
end
-->8
-- level

function init_lvl()
	reload(0x1000,0x1000,0x2000)
	
	for t in all(tris)do
		del(tris,t)
	end
	
	for e in all(enemies)do
		del(enemies,e)
	end
	
	for e in all(effs)do
		del(effs,e)
	end
	
	for t in all(tapes)do
		del(tapes,t)
	end
	
	uits,l_uits=-0.1,-1
	uitf,l_uitf=-0.1,-1
	
	l_st_t=-1 --level start time
	l_ed_t=-1 --level end time
	l_ed_idx=0
	
	tris={}
	enemies={}
	effs={}
	tapes={}
	bats={}
	flag=nil
	
	npc=nil
	npc_t=0
	npc_txt=":)"
	if npc_txts[crl] then
		npc_txt=npc_txts[crl]
	end
	
	ppa,pps=0,0 	--angle,speed
	pvx,pvy=0,0 	--velocity
	chx,chy=0,0		--checkpoint
	ipo=false				--is press 🅾️
	dpo=false				--did press 🅾️
	pdo=false				--press 🅾️ after death
	pdt=0								--die time
	prt=0								--recharge time (for show)
	ptn=false				--touch npc
	
	//pcdn=0							--jump cooldown
	ppc=p_c_max		--charge
	ifrm=0							--i frames
	pp_ong=false	--on ground
	pr0ll=true			--rolling
	scr=0								--strokes
	l_tape=0					--total tapes
	n_tape=0					--tapes collected
	
	lvl=lvls[crl+1]
	p_scrs[crl+1]=0
	
	printh("cur lvl")
	loga(lvl)
	loga({cmi,cmj,cmw,cmh})
	
	cmi,cmj=lvl[1],lvl[2]
	cmw,cmh=lvl[3],lvl[4]
	cmx,cmy=cmi*8,cmj*8
	
	for j=cmj,cmj+cmh-1 do
	for i=cmi,cmi+cmw-1 do
		local s=mget(i,j)
		local fl=fget(s)
		//local sn=mget(cmi+i,cmj+max(j-1,0))
		//local ss=mget(cmi+i,cmj+min(j+1,15))
		//local sw=mget(cmi+max(i-1,0),cmj+j)
		//local se=mget(cmi+min(i+1,15),cmj+j)

		local x,y=i*8,j*8
		
		if fl==0 then
			mset(i,j,0)
			
			if s==1 then
				-- player
				pp={x=x+4,y=y+4,w=8,h=8}
				chx,chy=pp.x,pp.y
			elseif s==16 then
				-- spark ball
				add_enemy(
					x+4,
					y+4,
					7,7,
					draw_spark,
					update_spark
				)
			elseif s==48 then
				-- tape
				add(tapes,obj(x+4,y+4,8,6))
				l_tape+=1
			elseif s==13 then
				-- flag
				flag=obj(x+4,y+4,4,8)
			elseif s==32 then
				-- batteries
				local b=obj(x+4,y+4,6,8)
				b.got=false
				add(bats,b)
			elseif s>=18 and s<=20 then
				-- dvds
				local d=add_enemy(
					x+4,
					y+4,
					7,7,
					draw_dvd,
					update_dvd
				)
				d.s=s
				d.dx=s>18 and 1 or 0
				d.dy=s!=19 and 1 or 0
			elseif s>=35 and s<=36 then
				-- frog
				local f=add_enemy(
					x+4,
					y+4,
					7,7,
					draw_frog,
					update_frog
				)
				f.t=f_t_max
				f.sht=false
				f.dx=s==35 and 1 or -1
			elseif s==8 then
				npc=obj(x+4,y+4,6,8)
				npc.t=0
				//if npc_txts[crl]
			end
		end
	end end
	
	get_tris()
end

function draw_bg()
	--flag
	line(
		flag.x-1,flag.y,
		flag.x-1,flag.y+3,
		13)
	spr(13+flr(uitf)%3,flag.x-4,flag.y-8)
end


npc_f={8,9,8,10}
function draw_fg()
	for t in all(tapes)do
		spr(48+uitf%4,t.x-4,t.y-4)
	end
	
	for b in all(bats)do
		if not b.got then
			spr(
				32+uitf%3,
				b.x-4,
				b.y-4+mid(
					-1.9,
					cos((uits)/5)*2,
					1.9
				))
		end
	end
	
	if npc then
		spr(
			npc_f[flr(npc.t)+1],
			npc.x-4,npc.y-4,
			1,1,
			npc.x>pp.x
		)
	end
end

function draw_npc_txt()
	if npc_t>0 then
		rectfill(
			camx+18,camy+29,
			camx+110,camy+105,0)
		rect(
			camx+18,camy+29,
			camx+110,camy+105,7)
		print(
			sub(npc_txt,0,min(npc_t,#npc_txt)),
			camx+21,camy+32,7
		)
	elseif ptn then
		if flr(uits)%2==0 then
			print("❎",npc.x-3,npc.y-12,6)
		else
			print("❎",npc.x-3,npc.y-12,1)
			print("❎",npc.x-3,npc.y-13,6)
		end
	end
end

stars={}
function init_stars()
	for s in all(stars)do
		del(stars,s)
	end
	
	local ns=rand(20,30)
	for i=1,ns do
		local rx=rand(0,127)
		local ry=rand(0,127)
		add(stars,{
			x=rx,y=ry,
			s=rnd()<0.2 and 47 or nil,
			t=rand(str_t_min,str_t_max)
		})
	end
end

function draw_stars()
	for s in all(stars)do
		if s.t>str_t_shn then
			pal(7,1)
		elseif s.t<str_t_shn/2-4 or
									s.t>str_t_shn/2+4 then
			pal(7,5)
		end
		local cx=camx
		local cy=camy
		if s.s==nil then
			pset(cx+s.x,cy+s.y,7)
		else
			spr(47,cx+s.x-1,cy+s.y-1)
		end
		pal()
	end
end

function update_stars()
	for s in all(stars)do
		s.t-=1
		if s.t==str_t_shn and
					rnd()<0.5 then
			s.t=0
		end
		if s.t==0 then
			s.t=rand(str_t_min,str_t_max)
		end
	end
end

-->8
-- enemies and effects

function draw_logo()
	local t=flr(logo_t/6)
	sspr(
		64,56,
		mid(0,logo_t-30,64),8,
		32,60)
	spr(
		1+(logo_t/5)%4,
		logo_t,60)
end

function draw_effs()
	for e in all(effs) do
		if(e.draw)e.draw(e)
	end
end

function update_effs()
	for e in all(effs) do
		if(e.update)e.update(e)
	end
end

function add_fdot(x,y)
	add(effs,{
		x=x,y=y,
		t=rand(10,20),
		s=rand(1,3),
		update=update_fdot,
		draw=draw_fdot
	})
end

function draw_fdot(f)
	pset(f.x,f.y,7)
end

function update_fdot(f)
	f.t-=1
	f.y+=f.s*0.1
	if f.t<=0 then
		del(effs,f)
	end
end

function add_fanf(s,x,y)
	if(x==nil)x=pp.x
	if(y==nil)y=pp.y-8
	add(effs,{
		x=x,y=y,
		t=10,
		s=""..s,
		update=update_fanf,
		draw=draw_fanf
	})
end

function draw_fanf(f)
	print(
		f.s,
		f.x-(#f.s*4)/2,
		f.y,
		f.t%8+8
	)
end

function update_fanf(f)
	f.t-=1
	f.y-=0.7
	
	if(f.t<=0)del(effs,f)
end

function add_dust(x,y,vx,vy,c)
	add(effs,{
		x=x,y=y,
		vx=vx,vy=vy,
		c=c,
		t=rand(10,20),
		update=update_dust,
		draw=draw_dust
	})
end

function draw_dust(d)
	pset(d.x,d.y,d.c)
end

function update_dust(d)
	d.t-=1
	d.x+=d.vx
	d.y+=d.vy
	d.vx-=0.1*sgn(d.vx)
	if(abs(d.vx)<=0.5)d.vx=0
	d.vy=min(d.vy+0.3,2)
	if d.t<=0 then
		del(effs,d)
	end
end

function add_enemy(x,y,w,h,d,u)
	local o=obj(x,y,w,h)
	o.draw=d
	o.update=u
	add(enemies,o)
	return o
end

function draw_enemies()
	for e in all(enemies) do
		if(e.draw)e.draw(e)
	end
end

function update_enemies()
	for e in all(enemies) do
		if(e.update)e.update(e)
	end
end

function draw_spark(s)
	spr(
		16+uitf%2,
		s.x-4,s.y-4,
		1,1,
		pp.x<s.x)
	//draw_bb(s)
end

function draw_dvd(d) 
	spr(d.s,d.x-4,d.y-4)
end

function update_dvd(d)
	d.y+=d.dy*dv_spd
	d.x+=d.dx*dv_spd
	local cv=bb_on_sol(d,0,d.dy)
	if cv and abs(cv.x-d.x)<5 then
		//d.y-=d.dy
		d.y=(flr(d.y/8)*8)+4
		d.dy*=-1
	end
	local ch=bb_on_sol(d,d.dx,0)
	if ch and abs(ch.y-d.y)<5 then
		//d.x-=d.dx
		d.x=(flr(d.x/8)*8)+4
		d.dx*=-1
	end
end

function draw_frog(f)
	local flp=f.dx==-1
	if f.t<3 then
		local i=flr(3-abs(f.t))
		spr(52+i,f.x-4,f.y-4,1,1,flp)
	else
		spr(35+uits%2,f.x-4,f.y-4,1,1,flp)
	end
end

function update_frog(f)
	f.t-=f_spd
	if f.t<=0 and not f.sht then
		f.sht=true
		local d=add_enemy(
			f.x,f.y,
			4,4,
			draw_duck,
			update_duck
		)
		d.dx=f.dx
		sfx(6)
	end
	if f.t<=-3 then
		f.t=f_t_max
		f.sht=false
	end
end

function draw_duck(d)
	spr(
		37+uits%2,
		d.x-4,d.y-4,
		1,1,
		d.dx<0)
end

function update_duck(d)
	d.x+=d.dx*dk_spd
	if d.x<cmx or d.x>cmx+cmw*8 then
		del(enemies,d)
	end
end
-->8
-- helpers

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function obj(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
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

function pt_bb(x,y,b)
	if b.w==0 or b.h==0 then
		return false
	end
	
	local bx=b.x-b.w/2
	local by=b.y-b.h/2
	
	return x<=bx+b.w and
		x>=bx and y<=by+b.h and
		y>=by
end

function bb_on_sol(o,x,y)
	//for i=0,15 do
		local a=obj(o.x+x,o.y+y,o.w,o.h)
		
		local mi=flr(a.x/8)
		local mj=flr(a.y/8)
		
		for j=min(cmj+cmh,mj+1),max(cmj,mj-1),-1 do
		for i=min(cmi+cmw,mi+1),max(cmi,mi-1),-1 do
			local s=mget(i,j)
			if fget(s,0) then
				local b=obj(
					i*8+4,
					j*8+4,
					8,8
				)
				b.s=s
				if col_bb(a,b) then
					return b
				end
			end
		end end
		
	//end
	return nil
end

function pt_in_tri(x,y,tr)
	local p0x,p0y=tr[1][1],tr[1][2]
	local p1x,p1y=tr[2][1],tr[2][2]
	local p2x,p2y=tr[3][1],tr[3][2]
	
	local dx=x-p2x
	local dy=y-p2y
	local dx21=p2x-p1x
	local dy12=p1y-p2y
	local d=dy12*(p0x-p2x)+dx21*(p0y-p2y)
	local s=dy12*dx+dx21*dy
	local t=(p2y-p0y)*dx+(p0x-p2x)*dy
	if d<0 then
		return s<=0 and t<=0 and s+t>=d
	end
	
	return s>=0 and t>=0 and s+t<=d
end

function get_tris()
	//local ii,jj=cmi*16,cmj*16
	for j=cmj,cmj+cmh-1 do
	for i=cmi,cmi+cmw-1 do
		local s=mget(i,j)
		if tris_m[s]!=nil then
			local t={}
			local td=tris_d[tris_m[s]]
			for k=1,3 do
				add(t,{
					i*8+td[k][1],
					j*8+td[k][2]
				})
			end
			t.n=td[4]
			t.frx=t_fric
			t.fry=t_fric
			add(tris,t)
		end
	end end
end

function txt_cen(s)
	return (#s*4)/2
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

function draw_bb(o)
	rect(
		o.x-o.w/2,
		o.y-o.h/2,
		o.x+o.w/2,
		o.y+o.h/2,
		8)	
end

-->8
-- data

tris_d={
	{ //nw-se
		{0,0},
		{8,8},
		{0,8},
		0.125 //norm
	},
	{ --ne-sw
		{0,8},
		{8,0},
		{8,8},
		0.375
	},
	{ --sw-ne
		{0,0},
		{8,0},
		{0,8},
		0.875
	},
	{ --sw-ne
		{0,0},
		{8,0},
		{8,8},
		0.625
	},
}

tris_m={}
tris_m[65]=1
tris_m[66]=2
tris_m[67]=3
tris_m[68]=4
tris_m[70]=1
tris_m[71]=2
tris_m[72]=3
tris_m[73]=4

t_fric=0.3

fric_norm={0.3,0.3,3}

sols_m={}
-- fric							x,y,sfx
-- regular
sols_m[64]=fric_norm
sols_m[69]=fric_norm
-- sand
sols_m[80]={0.01,0.5,46}
-- ice
sols_m[96]={0.6,0.8,45}
-- couches
sols_m[112]={0.5,-1,43}
sols_m[113]={0.5,-1,43}
sols_m[114]={0.5,-1,43}
//sols_m[64]={0.1,-0.2}

lvls={
//i, j, w, h, par, goto tv
	{0, 0, 32, 16, 2},//1
	{32,0, 48, 16, 3},//2
	{80,0, 48, 16, 2},//3
 {16,16, 48, 16, 2},//4
 {64,16, 64, 16, 4},//5
 {0,16, 16, 48, 3},//6
 {16,32, 64, 16, 4},//7
 {16,48, 64, 16, 4},//8	
 {80,32, 48, 32, 5},//9
}

expo_s="so this is it, huh?\n\nwent from flopping upward to\nhigh heaven to the\ncrestfallen depths of rock\nbottom, fated to die a\npathetic washed-up tv dinner\nmascot.\n\nmy countless brethren,\nslaughtered by insatiable\nappetites and radioactivity,\nand all i managed to do with\nmy life was dance my happy\nshrimptail for the masses.\n\nit's taken 5 divorces for me\nto learn the true meaning of\nremorse, an unfathomable\nvisceral suffering. all that\nmakes sense now is this\ndrink and wallowing in the\ntelevision commercials of\nyesteryear. this is no way\nfor a shrimp to live.\n\noh please, take me back to\nthat sweet dream..."

tv_s={}
//tv_s[0]={
	//"this is some\ntext that the tv\nwill play before\nthe level starts\nblah blah\nblah",
	//"here is some more text hehe"
//}
tv_s[1]={
	"shrimp are\ngenerally docile\nlittle water\nbugs that\nsubsist on\nvarious crud...",
	"they are\nalso good with \ndipping sauce!" 
}
tv_s[2]={
	"thanks\nshrimp-xibit\nfor shrimping\nmy ride! now\ni can shrimp\nin style!",
	"shrimp my ride\nwill be right\nback after\na word from\nour sponsor."
}

tv_s[3]={
	"*shramer enters*",
	"jerry, can i\nborrow some\nkrill?\ni have a beluga\nover at my place\nand she's hungry!",
	"but shramer...\n\nmy cousins\na krill!",
	"*laugh track*"
}

tv_s[4]={
	"breaking news!\nwashed up tv\ndinner mascot\nshell shrimpson\nwanted for\ntax evasion!",
	"more on this\nat 11."
}

npc_txts={}
npc_txts[0]="hey uhm could you help\nme collect the vhs\ntapes that are\nscattered around?\nit's my first day at\nblonk blunster video\nand my mom wants me to\nbe employee of the\nmonth. even if you\ndon't get all the \ntapes, can you rewind\n'em?"
npc_txts[0]="*omngh munch crunch*\n\nthis pizza from\npizza joes\nis... uhm... pretty\nfilling.\ni feel like i could\ngo on forever\nnow that i have\ningested this crispy\ngolden cheese crust."
npc_txts[0]="my, uhm, mom told me\nif i don't become\nemployee of the month\ni'll be failure of\nthe year and end up in\nthe trash!"
npc_txts[0]="another night asleep\nin front of the tv\nagain eh?\nyour tv frozen shrimp\ndinners were good,\nbut too much tv will\ndampen the soul\nand rot the brain\nmy friend."
__gfx__
000000000099888000eeee0000eeee000000ee0000088000008800000000000000000000000caa00000caa000000000000000000d0bbb00bd0bbb000d00bbb00
000000000e9590000e9999e00e9999e000000ee0098800000800000000000000000caa00000cccc0000cccc00000000000000000dbbbbbbbdbbbbbbbdbbbbbb0
00700700e9940000e9944999ee04499e8000099ee95900008990000000000000000cccc0000757500007575000000000000000000dbbbbb00dbbbbbb0dbbbbb0
00077000e9499000e9409459e009049e8909949ee9000000959000008000090900075750000c7700000c770000000000000000000dbbbb000db0bbb00db000bb
00077000e940900ee94990980009949e9549049ee9990000e9090090899090900007770000dcc9d000dcc9d000000000000000000dbb00000db000000d00000b
00700700e99440eee99000080000499e9994499ee99444eee99449408594949900dcc9d0000ccc00000ccc00000000000000000000d0000000d0000000d00000
000000000e9999e00ee00000000959e00e9999e00e99999ee999999ee999999e000444000004440000044400000000000000000000d0000000d0000000d00000
0000000000eeee0000ee00000888990000eeee0000eeeee00eeeeee00eeeeee0000404000000040000040000000000000000000000d0000000d0000000d00000
00a00a00a000a000ccd00dc0bb3003b088200280000000000000000000000000000000000000000000000000000000000000000011111111111111117fff7000
0a0990a00a099000c0d00d0cb030030b802002080000000000000000000000000000000000000000000000000000000000000000100000010006600107ff7000
a098a8000098a80ac0d0dc0cb0303b0b80202808000000000000000000000000000000000000000000000000000000000000000010000f0100006601007f7000
09aaaa9a09aaaa90cc0d0cc0bb030bb08802088000000000000000000000000002000000000000000900000000001000000010001000f001000f660100077000
09a88890a9a888900000000000000000000000000000000000000000000000002040000000000000909000000000010000010000100f000100f066f100007000
a09aa9000a98890a0dddccc00333bbb002228880000000000000000000000002000002200000000900000990000000100010000010f000f10f066f0100000000
000990a0000990a0ddd00ddd3330033322200222000000000000000000000040000240040000009000099009000000011100000010000f01f066f00100000000
00a00a000a00a00a0cccddd00bbb33300888222000000000000000000000002000200000000000900090000000000011111000001000f001000f000100000000
0004440000044400000444000bb00bb00bb00bb00000aa000000aa00000000220400000000000024090000000111111111111110111111111111111170700000
000a9940000a9940000a9940075bb750075bb750000a5a50000a5a50000002224000000000000224900000001555555555511111100000010f00000107000000
00a8899400a8899400a88994b77bb77bb77bb77b000aa990000aa990011122224000000001112224900000001ddddddd5551111110000f01f0000f0170700000
0a9999940a9999940a99999433bbffff33bbffffa00aa999a66aa99911132222240000001113225545000000ddddddddd52111111000f0010000f00100000000
a9998a94a9998a94a9998a94333fffff333fffffaaaaaa00a6a6aa0011322222240000001132222249000000ddddddddd5511111100f0001000f000100000000
a88a0000a8890a000889000033fff00033ffffffa6aa6a00a6aa6a0011122222240000001332222249000000ddddddddd521111110f0000100f0000100000000
08000000a80a000008000a0033ff000033fffff06aa6aa00aaaaaa0011122222400000001332222490000000ddddddddd5511111100000010000000100000000
0900000009000000a90a00003fff00003ffff000066aa0000aaaa00011122222411000001332222491100000ddddddddd5211111111111111111111100000000
000000000000000000000000000000000bb00bb0077007700750075011111132241300001111333249330000ddddddddd5511111500000000000000500008000
55555555055555500005500005555550075bb750075bb750077bbbbb11111113224402401111133324990990ddddddddd5511111050000000000005000008800
d165561d05d151d0000550000d151d50b77bbbbbb77bbbbbb77b000011111113222222241111113322444449ddddddddd5511111050000000000005088888880
d675576d05d656d0000550000d656d5033bb000033bb000033b00000111111122222224011111112222222901ddddddd55511111005000000000050088888888
d165561d05d151d0000550000d151d5033b00fff33f0000033f00000111111132222222411111113222224491555555555511111550500000000505588888880
555555550555555000055000055555503ff0f0003ff000003ff00000111111111122224011111133112222901555555555511111005050000005050000008800
000000000000000000000000000000003fff00003ffffff03fff0000111111111102222411133333110244491111111111111111050505500550505000008000
000000000000000000000000000000003fff00003fff00003ffffff0110000110000244011000033000029901100000000110011500500055000500500000000
0dddddd02000000000000002222222222222222202222220d00000000000000ddddddddddddddddd000000000000000000000000000000000000000000000000
d000000d2200000000000022268886200268886226888862dd000000000000ddd00000d00d00000d000000000000000000000000000000000000000000000000
d0d0000d2620000000000262288882000028888228888882d0d0000000000d0dd0000d0000d0000d000000000000000000000000000000000000000000000000
d00d000d2882000000002882288820000002888228888882d00d00000000d00dd000d000000d000d000000000000000000000000000000000000000000000000
d000d00d2888200000028882288200000000288228888882d000d000000d000dd00d00000000d00d000000000000000000000000000000000000000000000000
d0000d0d2888820000288882262000000000026228888882d0000d0000d0000dd0d0000000000d0d000000000000000000000000000000000000000000000000
d000000d2688862002688862220000000000002226888862d00000d00d00000ddd000000000000dd000000000000000000000000000000000000000000000000
0dddddd02222222222222222200000000000000202222220ddddddddddddddddd00000000000000d000000000000000000000000000000000000000000000000
077767600000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccdcdcdddcddcddddd000999999900000000
70000006000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccdcdcccdccdccdddd09cccaaac99999999
70070006000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccaaccaaccaaccaacddd009ccacacaaaccc90
6070000600000000000000000000000000000000000000000000000000000000000000000000000000000000cccccaaccaaccaaccaacdddd9cccaaccacacc900
6000070600000000000000000000000000000000000000000000000000000000000000000000000000000000cccccaadcaaccaacdaaddddd09ccacacaaccc900
6000700700000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddcdcdddcddcddddddd9cccaaacacaccc90
600000070000000000000000000000000000000000000000000000000000000000000000000000000000000000557777777577777777550009999999aaacccc9
0666677000000000000000000000000000000000000000000000000000000000000000000000000000000000005566666335333666665500000c000099999999
fff9fff900000000000000000000000000000000000000000000000000000000000000000000000000000000004566666335333666665500000c00000000c000
ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000004526662234333622625500000c00000000c000
f9f9f9f900000000000000000000000000000000000000000000000000000000000000000000000000000000004521662214333622125500000c00000000c000
9f9f9f9f00000000000000000000000000000000000000000000000000000000000000000000000000000000004421662214666622125500000c00000000c000
9999999900000000000000000000000000000000000000000000000000000000000000000000000000000000004421662214666622125500000c00000000c000
9994994900000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444555500000c00000000c000
4944944900000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444445555500000c00000000c000
4444444400000000000000000000000000000000000000000000000000000000000000000000000000000000666666666666666666666666000c00000000c000
003333330333333033333300000000000000000000000000000000000000000000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
03bbbbbb3bbbbbb3bbbbbb3000000000000000000000000000000000000000000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
033bb3bbbbb3bbbbbb3bb3300000000000000000000000000000000000000000aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
3bb3bbbb3bbbbbb3bbbb3bb30000000000000000000000000000000000000000aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
33b3bbbb3bbbbbb3bbbb3b330000000000000000000000000000000000000000aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
03b33333b333333b33333b300000000000000000000000000000000000000000aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
3bb3bbbbbbbbbbbbbbbb3bb30000000000000000000000000000000000000000aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
33333333333333333333333300000000000000000000000000000000000000000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
04040404040404040404000000000004040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04340000000000000100000000000004040000000000000000000000000000000044040404000000000004000000000000004404040404040404040000000000
00000000000000040000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000100000000000004040000000000000000000000000000000000040404000200000004000000000000000000000000000004040000000000
00000000000000040003000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000200000000000100000000000004040000000000000000000000000000000000040404000000000004000000000000000000000000000004040000000000
00000000000000040000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000000000004040404040003000000000000000000040400000000040404000000000000000000000000000000000000000004040000000004
04000000000000040000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000000000000004404040000000000000000000042040400000000040404000000000000000000000042040404040400000004320000000004
32000000000000040000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000000000000000004040404040400000000000004040400000000040404000000000000000000000004040400000000000004040000000004
04000000000000040404040400000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000000000000020004043400000000000000000004040400000000040404000000000000000000000004040400000000000004040002000004
04000000000000440404040400000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04040404000000000000000000000004040000000000000000000004040400000000040404000000000404040000000004040400000000000004040000000004
04000000000000000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04340000000000000100000000000004040000000000000000000042040400000000420404000000004204040000000042040400000004040404320000000004
32000000000000000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000100000000000004040010000000000000000004040400000000000000000000000404040000000004040400000000000000000000000004
04050505050505050505050500000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000100000000000004040000000000000000000004040400000000000000000000000404040003000004040400000000000000000000000004
04040404040404040404040400000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000707070707070700000004040000000000000000000004040400000000000000000000000404040000000004040405050505050500000000000004
04040404040404040404040400000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000404040404040400000004040404040404040404040404040404040400000000000404040404040404040404040404040404040400000000000004
04040404040404040404040400000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000440434000000000004040404040404040404040404040404040406060606060404040404040404040404040404040404040404040707070704
04040404040404040404040400d00004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000000000004040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000000000004040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000404040404040404
04040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000404040404040434
00000000440404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
07070700000000000400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000404040404043400
00000000004404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04040404040000000400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000404040404340000
00000000000044040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000001010104040000000000000000000000000000000000000000000000000000000000000000000000000000000404040434000000
00000000000000440404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000404043400000024
04041400000000004404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000000030004040000000000000000000000000000000000000000000000000000000000000000000000000000000404340000002404
04040414000000000044040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000240404
04040404140000000000440404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000024040404
04040404041400000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000707070707070707070704040000000000000000000000000000000000000000000000000000000000000000000000000000000000002404040404
04040404040414000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000240404040404
04040404040404140000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000004040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000024040404040404
04040404040404041400000000100004040010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04000000000000000004040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000004040404040404
04040404040404040414000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
0400000000000010000404040404040404d000000000000000000000000000000000000000000000000000000000000404040101010101010104040404040404
040404040404040404041400000000040400d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
04070707070404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001020202020102020202000000000000010000000000000000000080808080800100000000000000000000808080808001010101000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040400000000000000000000000000000000000004040404040404040404040404040404040404040404040404040404040430000000000000000000000000000000000000000004440404043000000000000000000444040000000000000000000000000004440404040404040404040400000000000004440
4000000000004040400000000100000000000000000000000030004040404040404043000000000000000000444040404040404040404040000000000000000000000000000000000000000000000040404300000000000000000000004440003000000000000000000000000044404040404040404040400030000000000040
4000000000004040400000000000000000000000000000000000004040404040404300000000000000000000004040404040404040404040000000000000000000000000000000000000000000000040400000000000000000000000000040000000000000000000000000000000404043000000000044400000000000000040
4000000000004040400008000000000000000000000000000000004040404040400000000000000000000000000000000000000000000000000000505050505050500000000000004040404000000040400000000000000000000000000040000000000000000000000000000000404300000000000000404040404000000040
4000000000004040404040404000000040404000000040404040404040404040400000000000000000000000000000000000000000000000000000404040404040406060606060604040404000000040400000006060606060606000000040707070700000007070700000000000400000000000000000000000004000000040
4000000000004040404040404000000040404000000040404040404040404040400000010000000000000050505050505000000000000000000000000000444040404040404040404040404000000040400000004040404040404000000040404040401010104040400000000000400000000000000000000000004000000040
40000000000040404040430000000000404040000000000044404040404040404000000000000000000000404040404040000000000000000000000000000040005e5f00000000000000444000000040400000000000000044404000000040404040404040404040400000000000400000000000404040000000004000000040
40000000000040404043000000000000404040000000000000444040404040404000000000000000000000404300000000000000000000000000000000000040006e5b5c5d0000000000004000000040400000000000000000404000000000000000000000000000000000000000400000000000404040000000000000000040
400000000000404043000000000000004040400000000000000000005e5f004040404040404000000000004000000000000000000000000000000000000000400d6e6b6c6d0000000000004000000040400000000000000000404000000000000000000000000000000000000000000000000000404040000000000000000040
40000000000000000000000000000042404040000000000000005b5c5d6f0040400000000000000000000040000030000000000000000000000000404040404040404040400000000000000000000040400000000000000100404000000000000000000000000000000000000000000000000000404040000000000000000040
40000000000000000000000000004240404040000000000000006b6c6d6f0d40400030000000000000000040000000000000000000000000000000000000444043000000400000000000000000000040400000000000000000404000000000000000000000000000707070700000000000707070404040000000004000000040
4000000000000000000042404040404040404000000000000000404040404040400000000000000000000040000000000000001010101000000000000000000000003000400000000000000000000040400000000000000000404040404000000010100000001010404040400000000000404040404040000000004000000040
4000000000000000004240404040404040404000000000000000404040404040400000000000000000000040000000000000004040404000000000000000000000000000400000005050505050404040400000000000000000404040404000000040400000004040404040400000000000404040404040000000004000000040
23000000000000004240404040404040404040606060606060604040404040404040404040406060606060400000000000000040404040404040405050505050505050504060606040404040404040404000000070707070704040404040707070404070707040404040404040404040404040404040407070707040000d0040
4045454545454540404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4000000000000000000040000000004040404300000000000000444040404043000000000000001010101010101040101010404043000000001000000000444040430000000012000000120000000000000000004440430000000000000000000040000000000000000000400000000000000044404040404040404040404040
40000000000000000000400000300040404300000000000000000044404043000000000000000000000000000000400000004043000000000000000000000040400000000000000000000000000000000000000000400000200000000000003000400d0000000000000000400000000000000000444040404040404000000040
4000000000000000000010000000004040000000000000000000000040400000000000000000000000003000200040003000400000000000000000000000004040000000000000000000000000000000000000000040000000000000000000000040404040130000000000400000000000000000000000000040404000300040
4000000000000000000000000000004040000000000000000000000040400000000000000000000000000000000040000000400000000000000000000000004040000000000000000000000000000000000000000040000000000000000000000040404040000000000000000000000000000000000020000040404000000040
4000000010000000000000000000004040000000000000101000000040400000000010100000000000000000000040000000400000000000001000000000004040000100000000000000000000004000000000000040130000000000404040404040404040000000000000000000000000000000000000000040404000000040
400000004000000000000000000000404000000000000040400000004040000000004040000000101010101010104000000000000000000000400000000d004040000000000000000000000000004013000000000040000000000000404040404040404040505050505050505050504040400000000000000012121200000040
4000000040000000000000000000004040000000000000404000000040400000000040400000004040404040404040000000000000000000004040404040404040000000000000000000000000004000000000000040130000000000404040404040404040404040404040404040404040400000000000000000000000000040
40000d0070707000000000007070704040000000000000404000200040400020000040400000004040404040404040000000000000000000001000000000004040404040404040404040404040404000000000000040000000000000000000004440000000140000400000001400004043000000000000000000000000000040
4040404040404040400000004040404040000001000000404000000040400000000040400000004440404040404043000000000000000000000000000030004040430000000000004440404040404000000000000040000000000000000000000040000000000000400000000000004000000000000000000000000000000040
4010101000000000000000000000444040000000000000404000000010100000000010100000000000000000000000000000000000000000000000000000004040000000000000000040404040404013000000000040000000000000000000000040000000000000400000000000004000000000000000000000000000000040
4000000000000000000000000000004040000000000000404000000000000000000000000000000000000000000000000000000000000000000000000000004040000000000012000040430000000000000000000000000000000000000000000040000000000000400000000000004000000000000000000000000000000040
4000300000000000000000000000004040404040404040404000000000000000000000000000000000002000000000000000000040404000000000004040404040000000000000000040000000000000000000000000000000404040000000000000000000000000000000000000000000000000007070707070707070707040
4000000000000000000000000000004040404040404040404000000000000000000000000000005050505050505000000000000040404000000000004040404040003000000000000000000000000000000000000000000000404040000000000000000000000000000000000000000000000000004040404040404040404040
4000000000000000000000000000004040404040404040404000000000000000000000000000004040404040404060606060606040404060606060604040404040000000000000000000000000000000004040404040000000404040505050505050505050505050505050505050505050504040404040404040404040404040
4010101040404070707000000020004040404040404040404060606060606060606060606060604040404040404040404040404040404040404040404040404040505050505050505050505040404040404040404040606060404040404040404040404040404040404040404040404040404040404040404040404040404040
__sfx__
0b0f00000c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c170
930c00003f64500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
934000003f65500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9002000015150181501a1501c1401e1301f1202111021110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480300000c5700e060050501114000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e0500001887117871168611586114851138511284111841108310f8310e8210d8210c8110b8110a8110981116851168511587114871158701487008100020000200002000020000200000000000000000000000
4c030000081600b1601416017150191401b130201122111222112231122010020100081300b1301413017130191301b130201122111222112231120b1000b100081100b1101411017110191101b110231120b100
200500000c0620f062110621306216062180621b0621d0621f0622206224062260622705227042270322702227012270122701227012020000200002000020000200002000020000200002000020000200002000
540200000c5720f5721157215572185621b5621d56221562245522755228542295422b5322e522325220050200502005020050200502005020050200502005020050200502005020050200502005020050200502
090e1400200420c002200120c002200120c002200320c002200120c002200120c002200420c0021e0220c002200320c0021b0220c0020c0020c0020c0020c0020c0020c0020c0020c0020c0020c0020c0020c002
090e14001e0420a0021e0120a0021e0120a0021e0320a0021e0120a0021e0120a0021c0420a0021b0220a002170320a002160220a0020a0020a0020a0020a0020a0020a0020a0020a0020a0020a0020a0020a002
090e1400230420c000230120c000230120c000230320c000230120c000230120c000230420c000230220c000230320c000210220c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c000
0b0e00010f8300f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f800000000000000000000000000000000000000000000000000000000000000
0b0e00010784007800078000780007800078000780007800078000780007800078000780007800078000780007800078000780007800000000000000000000000000000000000000000000000000000000000000
0b0e00010b8400b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b8000b800000000000000000000000000000000000000000000000000000000000000
090e14001c0420c0021c0120c0021c0120c0021c0320c0021c0120c0021a0120c0021c0420c0021a0220c0021c0320c0021e0220c0020c0020c0020c0020c0020c0020c0020c0020c0020c0020c0020c0020c002
090e14001f042080001f012080001f012080001f032080001f012080001e012080001f042080001e022080001f032080002102208000080000800008000080000800008000080000800008000080000800008000
480400000f150111501515115150121510b1500900009000090000900009000090000900009000090000900009000090000900009000090000900009000090000900009000090000900009000090000900009000
010f000021a3021a3018940191001c9500f1001d9501a940199001c9401a9301a900189500c043189401a9300c0430c02318950191001c9501b940189001c9400c0000d033189501a9400c0430c023189500e023
0f0f0000008500085000850008500085000850008500085000850008500085000850008500584007841078400f8400f8400f8400f8400f8400f8400f8400f8400f8400f8400f8400f8400f840058400784107840
810f00001f0451f02518045180251a0451a0251d0451d0251f0451f02518045180251a0451a0251d0451d025260552603518045180251a0451a0251d0451d025240552403518045180251a0451a0251d0451d025
250f00001a7001a7001a7000c80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b7001b7001b7001b7001b7521b7521b76224761
250f00002476524765247622476524762247322776227732267622676226752267422276122762227521f7411f7651f7651f7621f7651f7621f7322276222732217622176221752217421d7611d7621d7521a741
c10f00001a2421a2121a2321a2121a2421a2121b2421b2121d242162321b242162321a2421b2321b2321a2421a2121a2121a2321a2121a2421a2121b2421b2121d242162321b242162321a242132321123111232
c10f00001a2421a2121a2321a2121a2421a2121b2421b2121d242162321b242162321a2421b2321b2321a2421a2121a2121a2321a2121a2421a2121b2421b2121d242162321b242162321a2421b2321624213242
c90f00001324211241132411324213242132421324213242132321323213232132321322213222132221322213212132121321213212072000720007200072001d200162001b200162001a2001b2001620013200
010f000021a3021a3018940191001c9500f100189501a940199001c9401a9301a900189500c043189401a9300c053210000c023191000c04326033260230c03321033210230c04318043336350c0331a04315033
0f0f00000085000850008500085000850008500085000850008500085000850008500085005840078410784003850038500385003820038500382003850038200385003820038500382003850038200385003820
010f002021a3021a300c0330c02333635346251a0330c023199000c03321a3021a30346250c03335625336150c033199401b9300c023336251a0331502315033210000c03320a300c02334625336150c0331e033
010f00200c0330c0231b9300c023326350c0330c023336250c0231a033150230c043336250c04321a4021a400c033199401b9300c023336251a0331502315033210000c03320a300c0233362534615150330c023
0f0f00000585005820058500582005850058200585005820058500582005850058200585005820058500582005850058200585005820058500582005850058200a8400c8410c8400a84105850058500585003851
0f0f00000385003820038500382003850038200385003820038500382003850038200385003820038500382003850038200385003820038500382003850038200d8400f8410f8400d84103850038500385001851
d10f00001f3421f3121334213312163421631213342133121834218322133421a3421a322133421d3421e3421f3421f3121334213312163421631213342133121834218322133421a3421a3421d3421134211322
0f0f0000038500382003850038200385003820038500382003850038200385003820008500082000850008200085000820008500082000850008200085000820118401384113840118410c8400c8400c8400a841
d10f00001f3421f3121334213312163421631213342133121834218322133421a3421a322133421d342223421f3421f312133421331216342163121334213312223421632221342213221d3421d3222134221322
c90f00201a4551a4251a4551a4251a4451a4251344513435134551342513445134251344513425184451843518455184251844518425184451842513445154351645516425154551542516445164251544515425
c90f00201a4551a4251a4551a4251a4451a425134451343513455134251345513425134451342511445114351145511425114551142511445114250c4450e4350f4550f42511455114250f4450f4251144511435
c90f00201345513435134551343513445134351344513435134551343513455134351344513435134451343513455134351345513435134551343513455134351344513425134451342513445134251344513425
d10f00001f3421f3121334213312163421631213342133121834218322133421a3421a322133421d3421e3421f3421f3121334213312163421631213342133122234216322243422534126341263221d3421d322
c90f00201a4001a4001a4001a4001a4001a400134001340013400134001340013400134001340018400184001840018400184001840018400184001340015400164001640015400154001a4351a4151a4451a425
d10f00001f3421f3121334213312163421631213342133121834218322133421a3421a322133421d342223421f3421f3121334213312163421631213342163421834224332133421a342263321d3421133211322
010f00200c0330c0231b9300c023326350c0330c023336250c0231a033150230c04321a4021a4021043210330c033199401b9300c023336251a0331502315033346350c04324033270430c0430c0331f04313043
c90f00201344513425134451342513445134251344513425134451342513445134250c4450c4250c4450c4250c4450c4250c4450c4250c4350c4150c4350c4150c4000c4000c4000c4000c4000c4000c4000c400
540400000b1700d1710f1711016112151141400f1611015112141141300f151101411213114122141121411214100141001410000000000000000000000000000000000000000000000000000000000000000000
500700000c1300c1410f151111611415116141191311b1211d1111e11120111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9005000018a5018a5018a4018a3018a2018a1018a1018a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a80200002e4552e4452e4252e4152e4352e4252e4152e41518a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c0200000d1520d1520d1520d15216152161521615216152181421814218132181321812218122181121811200000000000000000000000000000000000000000000000000000000000000000000000000000000
46040000071320c1320e1320c1320e132131320e132131321813213132181321a132181321a1321f1321a1321f132241321f132241322912224122291222b1222b112301122b112301122b112291122b11224112
200500001f0621f062180521802218052180221801218012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20050000180621d0621f0622206224062240622405224052240422404224032240322402224022240122401224012240120000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 410c490b
00 410d4a0b
00 410c490b
00 410e4a10
01 410c090b
00 410d0a0b
00 410c090b
02 410e0f10
01 12135444
00 12135444
00 12131444
00 12131415
00 12131416
00 12131417
00 12131416
00 12131418
00 12131419
00 1a1b146a
00 1c1e2063
00 1c1f2866
00 1c1e2044
00 1d212227
00 1c1e2023
00 1c1f2824
00 1c1e2023
00 1d212225
02 2921262a

