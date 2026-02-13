pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- set
-- 2026-02-10
-- same as 0.0.0
-- happy birthday ryan
ver="1.0.0"

-- constants
card_w=29
card_h=17
card_f_tm=15

str_t_min=30
str_t_max=100
str_t_shn=20

c_pal_idx=1
c_pals={
	{8,11,13,2,3,5},
	{8,9,10},
	{1,5,6}
}

mode="title"
g_seed=-29

g_idx=0

allow_skip=false

-- settings
s_idx=nil
s_time=true
s_posb=true
s_aest=true

logo_t=0
uits,uitf=0,0
mx,my,lmx,lmy=-1,-1,-1,-1
is_m=false

tit_idx=0
tit_tm=-10
tit_l_tm=-1 -- load time

effs={}
leafs={}
stars={}


function _init()
	printh("===== start set =====")
	poke(0x5f2d,1)
	
	mx,my=stat(32),stat(33)
	lmx,lmy=mx,my
	
	init_stars()
	music(0)
	
	//testing
	--[[
	init_game()
	for i=1,27 do
	add(n_sets,{
			cards[rand(1,12)],
			cards[rand(1,12)],
			cards[rand(1,12)]
		})
	end
	init_garden()
	]]--
end

function _draw()
	cls()
	
	draw_bk()

	if logo_t<90 then
		draw_logo()
		return
	end
	
	if mode=="title" then
		draw_title()
	elseif mode=="game" then
		draw_game()
		draw_effs()
	elseif mode=="tutorial" then
		draw_tut()
	elseif mode=="about" then
		draw_about()
	elseif mode=="garden" then
		draw_garden()
	end
	
	if(is_m)draw_mouse()
end

function _update()
	uits=(uits+0.1)%30
	uitf=(uitf+0.2)%30
	
	update_bk()
	
	if logo_t<90 then
		logo_t+=1
		if btnp(❎) then
			if logo_t<30 then
				logo_t=30
			elseif logo_t<75 then
				logo_t=75
			end
		end
		return
	end
	
	mx,my=stat(32),stat(33)
	if lmx!=mx or lmy!=my then
		is_m=true
	elseif btn()>0 then
		is_m=false
		uitr()
	end
	lmx,lmy=mx,my
	
	if btnp(⬅️) or
				btnp(➡️) or
				btnp(⬆️) or
				btnp(⬇️) then
		sfx(3,-1,0,8)
	end
	
	if s_idx!=nil then
		update_settings()
	elseif mode=="title" then
		update_title()
	elseif mode=="game" then
		update_game()
		update_effs()
	elseif mode=="tutorial" then
		update_tut()
	elseif mode=="about" then
		update_ab()
	elseif mode=="garden" then
		update_garden()
	end
end

function draw_logo()
	//line(64,0,64,127,1)
	if logo_t>15 and logo_t<75 then
		spr(120,32,60,8,1)
	end
	
	//sspr(
	//	64,56,
	//	mid(0,logo_t-30,64),8,
	//	32,60)
end

function draw_mouse()
	spr(3,mx,my)
end

function init_title()
	if mode=="game" then //or 
				//mode=="garden" then
		music(0)
	end
	mode="title"
	s_idx=nil
	tit_l_tm=-1
	g_idx=0
end

function draw_title()
	print(ver,1,1,1)
	//line(64,0,64,127,1)
	//line(54,0,54,127,1)
	//line(74,0,74,127,1)
	spr(64+max(flr(tit_tm),0)*2,
		28,21,
		2,1)
	//spr(90,40,40,6,2)
	for i=0,2 do
		spr(
			84+i*2,
			40+i*16+(i-1)*1,
			30,
			2,2)
	end
	
	if s_idx!=nil then
		draw_settings()
	else
		if tit_l_tm==-1 or 
					flr(uits)%2==0 then
		t2(
			"play",
			57,80,
			tit_idx==0 and 15 or 1,0)
		end
		if tit_l_tm==-1 then
			t2(
				"settings",
				49,90,
				tit_idx==1 and 15 or 1,0)
			t2(
				"tutorial",
				49,100,
				tit_idx==2 and 15 or 1,0)
			t2(
				"about",
				55,110,
				tit_idx==3 and 15 or 1,0)
			if not is_m then
				dhand(
					1,
					38+uits%2,
					79+tit_idx*10
				)
			end
		end
	end
end

function update_title()
	if tit_l_tm>0 then
		tit_l_tm-=1
		if(tit_l_tm==0)init_game()
		return
	end
	
	tut_idx=0
	
	if tit_tm<7 then
		tit_tm+=0.4
	else
		tit_tm=rand(30,90)*-1
	end
	
	if btnp() then
		tit_idx=max(tit_idx,0)
	end
	
	if btnp(⬇️) then
		tit_idx=min(tit_idx+1,3)
	elseif btnp(⬆️) then
		tit_idx=max(tit_idx-1,0)
	end
	
	-- mouse hover
	if is_m then
		tit_idx=-1
		if pt_m(57,80,16,5)then
			tit_idx=0
		elseif pt_m(49,90,32,5)then
			tit_idx=1
		elseif pt_m(49,100,32,5)then
			tit_idx=2
		elseif pt_m(55,110,19,5)then
			tit_idx=3
		end
	end
	
	if click() and tit_idx>=0 then
		if tit_idx==0 then
			sfx(24)
			music(-1)
		else
			sfx(3,-1,8,8)
		end
		if(tit_idx==0)tit_l_tm=45
		if(tit_idx==1)s_idx=1
		if(tit_idx==2)mode="tutorial"
		if(tit_idx==3)mode="about"
	end
end

function draw_settings()
	if mode=="game" then
		t2(
			"go back",
			51,40,
			s_idx==-1 and 15 or 1,0)

		t2(
			"get hint",
			49,50,
			s_idx==0 and 15 or 1,0)
		
		--[[
		if not p_over then
			t2(
				"end game",
				49,50,
				s_idx==0 and 15 or 1,0)
		end
		]]--
	end
		
	t2(
		"show time",
		25,70,
		s_idx==1 and 15 or 1,0)
	t2(
		s_time and "yes" or "no",
		90,70, 
		s_time and 11 or 3,0)
		
	t2(
		"show possible\n         sets",
		9,80,
		s_idx==2 and 15 or 1,0)
	t2(
		s_posb and "yes" or "no",
		90,80, 
		s_posb and 11 or 3,0)
		
	t2(
		"card style",
		21,95,
		s_idx==3 and 15 or 1,0)
	t2(
		s_aest and "pretty" or "norm",
		90,95, 
		s_aest and 11 or 3,0)
		
	t2(
		"return to title",
		35,107,
		s_idx==4 and 15 or 1,0)
	
	if not is_m then
		local hx,hy=39,39
		//if(s_idx==-1)hx,hy=39,39
		if(s_idx==0)hx,hy=39,49
		//if(s_idx==1)hx,hy=15,59
		if(s_idx==1)hx,hy=15,69
		if(s_idx==2)hx,hy=-1,79
		if(s_idx==3)hx,hy=11,94
		if(s_idx==4)hx,hy=25,106
		dhand(1,hx+uits%2,hy)
	end
end

function update_settings()
	if btnp() then
		s_idx=max(
			s_idx,
			mode=="game" and -1 or 1
		)
	end
	if btnp(⬇️) then
		s_idx=min(s_idx+1,4)
		if p_over and s_idx==0 then
			s_idx=1
		end
	elseif btnp(⬆️) then
		s_idx=max(
			s_idx-1,
			mode=="game" and -1 or 1
		)
		if p_over and s_idx==0 then
			s_idx=-1
		end
	end
	
	-- mouse hover
	if is_m then
		s_idx=-3
		if mode=="game" then
			if pt_m(49,40,32,5)then
				s_idx=-1
			elseif pt_m(49,50,32,5) then
				s_idx=0
			end
		end
		if pt_m(22,70,80,5)then
			s_idx=1
		elseif pt_m(10,80,96,11)then
			s_idx=2
		elseif pt_m(21,95,91,5)then
			s_idx=3
		elseif pt_m(35,107,60,5)then
			s_idx=4
		end
	end
	
	if click() and s_idx>=-2 then
		sfx(3,-1,16,8)
		if s_idx==-1 then
			s_idx=nil	
		elseif s_idx==0 then
			s_idx=nil
			check_cards(true)
		elseif s_idx==1 then
			s_time=not s_time
		elseif s_idx==2 then
			s_posb=not s_posb
		elseif s_idx==3 then 
				s_aest=not s_aest
		elseif s_idx==4 then
			init_title()
		end
	end
end

function draw_tut()
	//rect(0,0,127,127,1)
	if tut_idx<2 then
		local d=d_tut[tut_idx+1]
		for i=0,#d-1 do
			t2(d[i+1],1,i*6+1,13,0)
		end
		
		t2(
			"next page",
			35,122,
			1,0)
	elseif tut_idx==2 then
		t2("valid set examples",18,10,13,0)
		draw_tut_cards(1)
		t2(
			"next page",
			35,122,
			1,0)
	else
		t2("invalid set examples",18,10,13,0)
		draw_tut_cards(4)
		t2(
			"return to title",
			35,122,
			1,0)
	end
		
	if not is_m then
		dhand(1,25+uits%2,121)
	end
end

function draw_tut_cards(s)
	for j=0,2 do
		local r=tut_d[j+s]
		for i=0,#r-1 do
			local d=tut_d[j+s][i+1]
			local c=get_card(d)
			c.x=i*card_w+i*3+18
			c.y=j*card_h+j*15+20
			draw_card(c)
		end
	end
end

function update_tut()
	if click() then
		sfx(3,-1,8,8)
		if tut_idx<3 then
			tut_idx+=1
		else
			mode="title"
		end
	end
end

function draw_about()
	t2(
		"return to title",
		35,122,
		1,0)
	if not is_m then
		dhand(1,25+uits%2,121)
	end
	
	for i=0,#d_ab-1 do
		t2(d_ab[i+1],1,i*6+1,13,0)
	end
end

function update_ab()
	if click() then
		sfx(3,-1,8,8)
		mode="title"
	end
end
-->8
-- game

function init_game()
	music(16)
	for e in all(effs)do
		del(effs,e)
	end
	for d in all(deck)do
		del(deck,d)
	end
	for c in all(cards)do
		del(cards,c)
	end
	for s in all(n_sets)do
		del(n_sets,s)
		del(n_sets,s)
	end

	mode="game"
	game_st_tm=time()
	game_tm=game_st_tm
	
	g_idx=0 -- game idx
	r_idx=0 -- garden idx
	cards={}
	deck={}
	hint_sets={} -- hints
	//n_set=0	-- num sets made
	n_sets={}
	n_sel=0 -- num selected
	card_off_y=30
	
	sh_tm=0 -- shake time
	n_av_set=0 -- available sets
	p_over=false
	p_over_t=60
	
	local id=1
	for n=1,3 do
	for s in all({5,6,7}) do
	for f in all({0,1,2}) do
	for c in all({1,2,3}) do
		add(deck,{
			n=n,s=s,f=f,c=c,
			id=id
		})
		id+=1
	end end end end
	
	for i=0,11 do
		add(cards,get_deck_card(i*5))
		add_f_card(
			5,5,
			(i%4)*card_w+(i%4)*3+card_w/2,
			flr(i/4)*card_h+card_off_y,
			i*5,
			32
		)
	end
	
	move_cards()
	check_cards(false)
end

function draw_game()
	//rect(0,0,127,127,1)
	
	-- deck
	local dw=#deck>0 and 12 or 20
	if(g_idx==0)pal(7,15)
	rect(
		3,3,
		3+dw,#cards==21 and 9 or 11,
		7
	)
	rectfill(1,1,1+dw,9,0)
	rect(1,1,1+dw,9,7)
	if #deck>0 then
		print(#deck,4,3,7)
	else
		print("fin?",4,3,7)
	end
	pal()
	
	-- settings gear
	spr(
		s_idx!=nil and 18 or 
		g_idx==1 and 17 or 16,
		100,2
	)
	
	-- complete sets
	if(g_idx==2)pal(7,15)
	rect(
		114,3,
		126,#cards==21 and 9 or 11,
		7
	)
	rectfill(112,1,124,9,0)
	rect(112,1,124,9,7)
	print(#n_sets,115,3,7)
	pal()

	-- time	
	if s_time then
		local ts=ftime(game_tm)
		print(ts,64-(#ts*4)/2,3)
	end
	
	if not p_over then
		if s_posb and #cards<21 then
			t2(
				"possible sets:"..n_av_set,
				1,card_off_y-7,1,0)
		end
	
		if s_idx==nil then
			for n=0,#cards-1 do
				local i=n%4
				local j=flr(n/4)
				draw_card(cards[n+1])
			end
		end
	end
	
	if s_idx!=nil then
		draw_settings()
	end
	
	
	if #cards<21 then
		if is_m then
			print(
				"mouse:move         mouse:toggle",
				1,122,
				1
			) 
		else
		print(
			"⬆️⬇️⬅️➡️:move         ❎:toggle",
			1,122,
			1
		) 
		end
	end
	
	if not is_m then
		local hx,hy=5,10
		if g_idx==1 then
			hx,hy=102,10
		elseif g_idx==2 then
			hx,hy=112,10
		elseif g_idx>2 then
			local i=(g_idx-3)%4
			local j=flr((g_idx-3)/4)
			hx=i*card_w+i*3+14
			hy=j*card_h+j*3+card_off_y+card_h-1
		end

		if s_idx==nil then
			dhand(2,hx,hy+uits%2)
		end
	end
	
	if p_over and #effs==0 and
				s_idx==nil then
		if #n_sets==27 or 
					(#deck==0 and n_av_set==0) then
			t2("you win",51,60,1,0)
		else
			t2("game over",47,60,1,0)
		end
	end
end

function draw_card(c)
	if c=="dead" or c.t>0 then
		return
	end
	
	local cx=c.x+flr(c.sh_tm/2)%2
	local cy=c.y
	
	if c.ht_tm>0 and 
				flr(c.ht_tm/8)%2==0 then
		rectfill(
			cx,cy,
			cx+card_w,cy+card_h,
			7
		)
		return
	end
	
	if c.idx==g_idx-3 then
		rectfill(
			cx,cy,
			cx+card_w,cy+card_h,
			1
		)
	end
	
	rect(
		cx,cy,
		cx+card_w,cy+card_h,
		7
	)
	
	local cp=c_pals[c_pal_idx]	
	pal(15,c.idx==g_idx-3 and 1 or 0)
	for i=0,c.n-1 do
		local ccx=cx+card_w/2-3-(c.n-1)*4.5+i*9
		local ccy=cy+1
		local ccs=c.s+3*c.f
		if(s_aest)ccs+=32
		
		-- outline
		pal(6,c.idx==g_idx-3 and 1 or 0)
		pal(7,c.idx==g_idx-3 and 1 or 0)
		
		ospr(ccs,ccx,ccy,1,2)
		
		--card sprite
		pal(7,cp[c.c])
		pal(6,cp[c.c+3])
		spr(
			ccs,
			ccx,ccy,
			1,2)
	end
	pal()
	
	if c.sel then
		local o=flr(uitf)%3-1
		spr(14,cx-o,cy-o)
		spr(15,cx+card_w-7+o,cy-o)
		spr(30,cx-o,cy+card_h-7+o)
		spr(31,
			cx+card_w-7+o,
			cy+card_h-7+o)
	end
end

function update_game()
	if not p_over then
		game_tm=time()-game_st_tm
	else
		goto after_auto
	end
	
	-- update cards
	for c in all(cards)do
		if c!="dead" then
			if(c.sh_tm>0)c.sh_tm-=1
			if(c.ht_tm>0)c.ht_tm-=1
			if c.t>0 then
				c.t-=1
				if c.t==1 then
					sfx(3,-1,0+rand(0,2)*8,8)
				end
			end
		end
	end
	
	auto_clk=false
	if allow_skip and btn(🅾️) then
		update_auto()
		goto after_auto
	end
	
	--button inputs
	if btnp(➡️) then
		g_idx=min(g_idx+1,#cards-1+3)
	elseif btnp(⬅️) then
		g_idx=max(g_idx-1,0)
	elseif btnp(⬇️) then
		if g_idx==0 then
			g_idx=3
		elseif g_idx<3 then
			g_idx=5
		elseif g_idx<#cards-1 then
			g_idx=min(g_idx+4,#cards+3)
		end
	elseif btnp(⬆️) then
		g_idx=max(g_idx-4,0)
	end
	
	-- mouse hovering
	if is_m then
		g_idx=-1
		if pt_m(1,1,20,9) then
			g_idx=0
		elseif pt_m(97,1,8,8) then
			g_idx=1
		elseif pt_m(112,1,120,9) then
			g_idx=2
		end
		
		for i=1,#cards do
			local c=cards[i]
			//c.h=false
			if c.t==0 and
						c!="dead" and
						pt_m(c.x,c.y,
											card_w,card_h) then
				g_idx=c.idx+3
			end
		end
	end
	
	::after_auto::
	
	if p_over then
		g_idx=2
		//g_idx=min(g_idx,1)
		//g_idx=min(g_idx,2)
		if p_over_t==60 then
			-- consider a delay
			-- before this runs
			if #n_sets==27 or 
					(#deck==0 and n_av_set==0) then
				sfx(5)
				music(-1)
			else
				sfx(6)
				music(-1)
			end
		elseif p_over_t==0 then
			init_garden()
			music(0)
		end
		p_over_t-=1
		return
	end
	
	-- click deck
	if g_idx==0 and click() then
		if #deck==0 then
			p_over=true
		elseif #effs==0 and 
									#cards<21 then
			for i=0,2 do
				add(cards,get_deck_card(i*5))
					add_f_card(
					5,5,
					(i%4)*card_w+(i%4)*3+card_w/2,
					4*card_h+card_off_y,
					i*5,
					32
				)
			end
			move_cards()
			check_cards(false)
			sfx(3,-1,8,8)
		end
	end
	
	-- click settings
	if g_idx==1 and click() then
		//printh("clicked set todo")
		s_idx=-1
		sfx(3,-1,16,8)
	end
	
	-- click set
	if g_idx==2 and click() then
		printh("clicked set todo")
		init_garden()
	end
	
	-- click cards
	local can_check=false
	local c=cards[g_idx-2]
	if g_idx>2 and c!=nil and
				c!="dead" and c.t==0 and 
				click() then
		if c.sel then
			c.sel=false
			n_sel-=1
			sfx(3,-1,16,8)
		elseif n_sel<3 then
			can_check=true
			c.sel=true
			n_sel+=1
			if(n_sel<3)sfx(3,-1,8,8)
		end
	end
	
	if n_sel==3 and can_check then
		check_sel()
		g_idx=min(g_idx,#cards+2)
		if #n_sets==27 or 
					(#deck==0 and
						n_av_set==0) then
			p_over=true
		end
	end
end

function get_card(c)
	return {
		n=c.n,
		s=c.s,
		f=c.f,
		c=c.c,
		id=c.id,
		idx=-1,
		sel=false,
		sh_tm=0,
		ht_tm=0,
		t=0
	}
end

function get_deck_card(toff)
	local i=rand(1,#deck)
	local dc=deck[i]
	deli(deck,i)
	
	local c=get_card(dc)
	c.t=card_f_tm+toff
	return c
end

function move_cards()
	card_off_y=30
	if #cards==18 then
		card_off_y=20
	elseif #cards==21 then
		card_off_y=10
	end
	
	for n=0,#cards-1 do
		local c=cards[n+1]
		if c!="dead" then
			local i=n%4
			local j=flr(n/4)
			c.x=i*card_w+i*3+1
			c.y=j*card_h+j*3+card_off_y
			c.idx=n
		end
	end
end

function check_sel()
	printh("checking selection")
	local sel={}
	for i=1,#cards do
		if cards[i].sel then
			add(sel,i)
			cards[i].sel=false
		end
	end

	local is_set=check_set(
		cards[sel[1]],
		cards[sel[2]],
		cards[sel[3]]
	)
	
	if is_set then
		add(n_sets,{
			cards[sel[1]],
			cards[sel[2]],
			cards[sel[3]]
		})
		
		for i=#sel,1,-1 do
			local c=cards[sel[i]]
			add_f_card(
				c.x,c.y,
				122,
				5,
				0,
				48
			)
		end
	
		if #cards>12 then
			for i=#sel,1,-1 do
				deli(cards,sel[i])
			end
		else 
			for i=#sel,1,-1 do
				if #deck>0 then
					add_f_card(
						5,5,
						cards[sel[i]].x,
						cards[sel[i]].y,
						i*5,
						32
					)
					cards[sel[i]]=get_deck_card(i*5)
				else
					cards[sel[i]]="dead"
				end
			end
		end
		
		//n_set+=1
		move_cards()
		check_cards(false)
		sfx(4)
	else
		sh_tm=20
		for i=#sel,1,-1 do
			cards[sel[i]].sel=false
			cards[sel[i]].sh_tm=20
		end
		sfx(6)
	end
	
	n_sel=0
end

function check_set(c1,c2,c3)
	if c1=="dead" or
				c2=="dead" or
				c3=="dead" then
		return false
	end
	
	local is_set=true
	for k in all({"n","s","f","c"})do
		//loga({"checking key",k})
		//loga({" ",c1[k],c2[k],c3[k]})
		if c1[k]!=c2[k] and
					c1[k]!=c3[k] and
					c2[k]!=c3[k] then
			//loga({"  all diff for",k})
		elseif c1[k]==c2[k] and
									c2[k]==c3[k] then
			//loga({"  all same for",k})
		else
			//loga({"  not vald for",k})
			return false
		end
	end
	
	return true
end


function check_cards(show)
	hint_sets={} --testing
	
	local g={}
	for i=1,#cards do
	for j=i+1,#cards do
	for k=j+1,#cards do 
		add(g,{i,j,k})
	end end end

	local n=0
	//local f={}
	for i in all(g) do
		//loga({i,unpack(g[i])})
		if check_set(
						cards[i[1]],
						cards[i[2]],
						cards[i[3]]
		) then
			n+=1
			add(hint_sets,{
				cards[i[1]],
				cards[i[2]],
				cards[i[3]]
			})
			
			//debugging
			loga({
				"  set",
				cards[i[1]].idx,
				cards[i[2]].idx,
				cards[i[3]].idx
			})
		end
	end
	n_av_set=n
	//loga({"checked all",n})
	
	if show then
		local i=rand(1,#hint_sets)
		local c=hint_sets[i][1]
		c.ht_tm=90
	end
	//loga({"nnnn",#g})
end

auto_t=0
auto_s=nil
auto_s_idx=0
auto_clk=false
function update_auto()
	//auto_clk=false
	if #effs>0 then
		return
	end
	
	if auto_t>0 then
		auto_t-=1
		return
	else
		auto_t=2
	end
	
	printh("==running auto==") 
	
	if auto_s==nil then
		if #hint_sets>0 then
			local i=rand(1,#hint_sets)
			auto_s=hint_sets[i]
			loga({"auto: use hint",i})
			//deli(hint_sets,i)
		else
			g_idx=0
			auto_clk=true
			loga({"auto: click deck"})
			return
		end
	end
	
	if auto_s_idx<3 then
		auto_s_idx+=1
		local c=auto_s[auto_s_idx]
		g_idx=c.idx+3
		auto_clk=true
		loga({"auto: sel",c.idx})
		
		if auto_s_idx==3 then
			auto_s=nil
			auto_s_idx=0
			loga({"auto: reset"})
		end
	end
end
-->8
-- effects

function draw_effs()
	for e in all(effs)do
		e.draw(e)
	end
end

function update_effs()
	for e in all(effs)do
		e.update(e)
	end
end

function add_f_card(x1,y1,x2,y2,toff,s)
	add(effs,{
		x1=x1,
		y1=y1,
		x2=x2,
		y2=y2,
		s=s,
		t=card_f_tm+toff,
		draw=draw_f_card,
		update=update_f_card
	})		
end

function draw_f_card(f)
	if f.t<=card_f_tm then
		local d=(card_f_tm-f.t)/card_f_tm
		
		//pal(7,(f.t%8)+8)
		spr(
			f.s+(f.t*0.5)%4,
			f.x1+(f.x2-f.x1)*d,
			f.y1+(f.y2-f.y1)*d
		)
		//pal()
	end
end

function update_f_card(f)
	f.t-=1
	if(f.t==0)del(effs,f)
end

l_cols={14,14,14,14,7,7,7,2}
function add_leaf()
	add(leafs,{
		x=rand(80,115),
		y=rand(88,95),
		dx=rnd(),
		dy=rnd(),
		c=l_cols[rand(1,#l_cols)],
		t=rand(60,300)
	})	
end

function draw_leaf(l)
	pset(l.x,l.y,l.c)
end

function update_leaf(l)
	l.x-=l.dx*0.5
	l.y+=l.dy*0.5
	l.t-=1
	
	if l.t==0 then
		del(leafs,l)
	end
end

bk_t=0
function draw_bk()
	//rect(0,0,127,127,1)
	draw_stars()
	
	if mode!="garden" then
		spr(
			flr(bk_t)==0 and 139 or 171,
			80,78,
			5,2
		)
		spr(137,94,90,2,2)
		spr(167,81,106,3,2)
		spr(167,105,106,3,2,true)
		//spr(128,81,106,3,3)
		//spr(128,105,106,3,3,true)
	
		for l in all(leafs)do
			draw_leaf(l)
		end
	end
end

function update_bk()
	update_stars()
	
	bk_t+=0.03
	if(bk_t>2)bk_t=0
	
	if rand(0,100)<20 then
		add_leaf()
	end
	
	for l in all(leafs)do
		update_leaf(l)
	end
end

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
		if s.s==nil then
			pset(s.x,s.y,7)
		else
			spr(47,s.x-1,s.y-1)
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
-- garden

function init_garden()
	mode="garden"
	r_idx=0
	l_r_idx=0
	if(#n_sets>0)r_idx=1
end

function draw_garden()
	//line(64,0,64,127,1)
	//line(0,64,127,64,1)
	//rect(0,0,127,127,1)
	
	t2(
		p_over and "return to title" or "go back",
		12,120,
		r_idx==0 and 15 or 1,0)
	if r_idx==0 then
		dhand(1,1+flr(uits)%2,119)
	end
	
	//rect(40,40,87,87,1)
	pal(15,0) --testing
	spr(128,40,40,3,3)
	spr(128,64,40,3,3,true)
	spr(131,40,64,3,3)
	spr(131,64,64,3,3,true)
	pal()
	
	for i=1,#n_sets do
		local a=i/-28+0.25
		pset(
			64+cos(a)*24,
			64+sin(a)*24,
			7
		)
		if i==r_idx then
			circ(
				64+cos(a)*24,
				64+sin(a)*24,
				flr(uits)%2==0 and 3 or 5,
				7)
		end
	end
	
	spr(181,59,32)
	if r_idx>0 then 
		srand(g_seed)
		draw_flower()
		srand(time())
		
		draw_dna()
	end
end

function draw_flower()	
	local flrx,flry=105,32
	
	pset(flrx,flry,7)
	
	//fillp(▒)
	rect(
		flrx-15,flry-23,
		flrx+15,flry+7,
		5
	)
	fillp()
	spr(135,flrx-8,flry)
	spr(135,flrx,flry,1,1,true)
	pal(15,0)
	spr(224,flrx-15,flry+7,4,1)
	pal()
	
	-- pedals and pistol
	local npd=rand(1,10)	--n pedls
	//local npd=rand(1,2)	--n pedls
	
	local pdl=rand(4,10)	--pdl l
	local pdt=rand(5,9)	--pdl thk
	local nps=rand(0,10)	--n pistl
	local psr=rand(1,4)		--pstl r
	local psc=rand(2,15)	--pstl c
	
	-- petal colors
	local pdcs={}
	local nc=1 -- n pet cols
	if npd<3 then
		nc=rand(2,pdt)
	elseif npd>3 then
		nc=rand(2,3)
	end
	for _=1,nc do
		add(pdcs,rand(2,15))
	end
	
	-- stems
	local stms={}
	local ns=rand(1,2) --n stem
	if npd<3 and rnd()>0.5 then
		ns+=rand(1,2)
	end
	for _=1,ns do
		add(stms,{
			sh=rand(10,20), --stem h
			nw=rand(0,5),			--n wave
			ww=rand(0,5),			--wave w
			sb=rand(-10,10) --stm bnd
		})
	end
	
	if g_seed != l_g_seed then
		loga({
			"\ncreating flower:",
			g_seed
		})
		loga({" num pedals ", npd})
		loga({" pedal lengt", pdl})
		loga({" pedal thick", pdt})
		loga({" pedal cols", pdc1})
		for i=1,#pdcs do
			loga({"  ",pdcs[i]})
		end
		loga({" num pistol ", nps})
		loga({" pistol rad ", psr})
		loga({" pistol colr", psc})
		loga({" num stems  ", ns})
		for i=1,#stms do
			local s=stms[i]
			loga({"  stem       ", i})
			loga({"   stem height", s.sh})
			loga({"   num waves  ", s.nw})
			loga({"   waves width", s.ww})
			loga({"   stem bend  ", s.sb})
		end
	end
	
	for si=1,#stms do
		local s=stms[si]
		local sh=s.sh
		local nw=s.nw
		local ww=s.ww
		local sb=s.sb
		
		local px=flrx+cos(1/4)*sb-sb
		local py=flry-sh
		
		-- stem
		for i=1,sh do
			s1,b1=stem_pt(i-1,sh,nw,ww,sb)
			s2,b2=stem_pt(i,sh,nw,ww,sb)
			line(
				flrx+s1+b1,flry-i-1,
				flrx+s2+b2,flry-i,
				si<=#stms/2 and 3 or 11)
		end
	
		if npd>2 then
			-- petals
			for j=0,pdl do // length
			for i=1,npd do	// num
				for k=0,pdt do	//thick
					local ii=i/npd+k*0.01
					pset(
						px+cos(ii%1)*j,
						py+sin(ii%1)*j,
						agw(pdcs,i)
					)
				end
			end end
		else
			-- berries
			for i=0,pdl do // num ber		
				local ry=rand(-2,2)
				local rx=rand(-2,2)
				local tt=rand(pdt-npd,pdt)*0.25
				circfill(
					px+rx,py+ry,
					tt,
					agw(pdcs,i)
				)
			end
		end
	
		--pistil
		for i=1,nps do
			local a=rnd()
			local d=rnd()*psr
			local rx=cos(a)*d
			local ry=sin(a)*d
			pset(px+rx,py+ry,psc)
		end
	end
end

function stem_pt(i,sh,nw,ww,sb)			
	local s=sin(i/(sh/nw))*ww
	local b=cos((i/sh)/4)*sb-sb
	return s,b
end

function draw_dna()
	local dnax,dnay=105,105
	
	rect(
		dnax-15,dnay-14,
		dnax+15,dnay+17,
		5
	)
	pal(15,0)
	spr(240,dnax-15,dnay-21,4,1)
	pal()
	local cs=n_sets[r_idx]
	for j=0,#cs-1 do
		draw_mini_card(
			cs[j+1],
			dnax-14,dnay+j*9-12)
	end
end

function draw_mini_card(c,x,y)
	local cp=c_pals[c_pal_idx]
	pal(15,0)
	for i=0,c.n-1 do
		local ccx=x+card_w/2-3-(c.n-1)*4.5+i*9
		local ccy=y+1
		local ccs=(c.s+187)+3*c.f
		
		--card sprite
		pal(7,cp[c.c])
		spr(
			ccs,
			ccx,ccy,
			1,1)
	end
	pal()
end

l_g_seed=nil
function update_garden()
	if is_m then
		if pt_m(12,120,60,5)then
			r_idx=0
		else
			for i=1,#n_sets do
				local a=i/-28+0.25
				local x=64+cos(a)*24
				local y=64+sin(a)*24
				if pt_m(x-4,y-4,8,8)then
					r_idx=i
				end
			end
		end
	end
	if click() then
		if r_idx==0 then 
			if p_over then
				init_title()
			else
				mode="game"
			end
		end
	end
	
	if l_g_seed!=g_seed then
		l_g_seed=g_seed
	end
	
	if btnp(⬅️) or btnp(⬆️) then
		r_idx=max(r_idx-1,0)
		if r_idx>0 then
			//calc_seed(r_idx)
		end
	elseif #n_sets>0 and
								(btnp(➡️) or 
								btnp(⬇️)) then
		r_idx=min(r_idx+1,#n_sets)
		//calc_seed(r_idx)
	end
	
	//if(btnp(⬅️))g_seed-=1
	//if(btnp(➡️))g_seed+=1
	if r_idx>0 and 
				r_idx!=l_r_idx then
		calc_seed(r_idx)		
	end
	l_r_idx=r_idx
end

function calc_seed(i)
	loga({"calc seed for idx",i})
	local s=n_sets[i]
	
	for c in all(s) do
		loga({c.id, dtb2(c.id)})
		loga({c.n,c.s})
	end
	
	local sd=(s[1].id<<8)+s[2].id
	sd=sd+(s[3].id>>8)
	loga({"seed",sd,dtb2(sd)})
	g_seed=sd
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
-- helpers

l_click=false
function click()
	if auto_clk and not p_over then
		return true
	end
	
	if(btnp(❎))return true
	if stat(34)>0 then
		if not l_click then
			l_click=true
			return true
		end
	else
		l_click=false
	end
	return false
end

function uitr()
	_uits,_uitf=0,0
end

function pt_bb(ax,ay,aw,ah,px,py)
	return px>=ax and px<=ax+aw and
								py>=ay and py<=ay+ah
end

function pt_m(ax,ay,aw,ah)
	return pt_bb(ax,ay,aw,ah,mx,my)
end

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function ftime(t)
	if type(t)!="number" then
		return t
	end
	local mins=flr(t/60)
	local s=""
	if mins<1 then
		s=s.."00:"
	elseif mins<10 then
		s=s.."0"..mins..":" 
	else
		s=s..mins..":"
	end
	local sec=flr(t%60)
	if sec<10 then 
		s=s.."0"..sec
	else
		s=s..sec
	end
	return s//sub(s,1,4)
end

function ospr(s,x,y,w,h,fh,fv)
	w=w and w or 1
	h=w and h or 1
	fh=fh and fh or false
	fv=fv and fv or false
	for j in all({-1,1})do
	for i in all({-1,1})do
		spr(s,x+i,y+j,w,h,fh,hv)
	end end
end

function dhand(s,x,y)
	pal(7,0)
	pal(6,0)
	ospr(s,x,y)
	pal()
	spr(s,x,y)
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

-- array get wrap
function agw(a,i)
	return a[(i-1)%#a+1]
end

function loga(arr)
	printh(a_to_s(arr))
end

function a_to_s(arr)
	local s=arr[1]
	for i=2,#arr do
		s=s.." "..tostr(arr[i])
	end
	return s
end
-->8
-- data
d_tut={
{
"the goal of 'set' is to identify",
"groups of 3 cards, called a",
"'set'.",
"",
"each card has four features:",
"-color: red, green, or purple",
"-shade: open, solid, or stripe", 
"-symbol: pill, diamond, or",
"         squiggle",
"-number of symbols: 1, 2, or 3",
"",
"a set is valid if each feature",
"for each card is all the same,",
"or all different.",
"",
},
{
"12 cards are dealt at the start.",
"you can select the deck icon to",
"deal 3 more cards if you need.",
"",
"you can win in two ways:",
"",
"1) find all 27 sets.",
"",
"2) once all cards have been", 
"   dealt and you believe no more",
"   sets are possible, click the",
"   'fin' icon.",
}}

d_ab={
"zen set is a single player",
"interpretation of the card game",
"'set'.",
"",
"it is meant to be a relaxing",
"experience, and to help hone",
"your skills at 'set'.",
"",
"'set' was designed by marsha",
"falco in 1974 and published by",
"set enterprises in 1991.",
"zen set is not affiliated with",
"set enterprises, inc. or the",
"'set' card game. please consider",
"buying the phsyical 'set'",
"card game."
}

tut_d={
	// valid sets
	{
		{n=1,s=5,f=0,c=1},
		{n=1,s=5,f=1,c=1},
		{n=1,s=5,f=2,c=1},
	},
	{
		{n=1,s=6,f=0,c=2},
		{n=2,s=6,f=0,c=3},
		{n=3,s=6,f=0,c=1},
	},
	{
		{n=3,s=7,f=1,c=1},
		{n=1,s=5,f=2,c=2},
		{n=2,s=6,f=0,c=3},
	},
	// invalid sents
	{
		{n=3,s=7,f=1,c=2},
		{n=2,s=7,f=2,c=2},
		{n=1,s=7,f=1,c=2},
	},
	{
		{n=1,s=5,f=0,c=2},
		{n=1,s=6,f=0,c=3},
		{n=1,s=6,f=0,c=1},
	},
	{
		{n=2,s=7,f=1,c=1},
		{n=1,s=5,f=2,c=1},
		{n=2,s=6,f=1,c=3},
	},
}
__gfx__
00000000077700000660000001000000a00000000000000000000000000000000000000000000000000000000000000000000000000000009999900000099999
0000000077667776076000001a100000aa0000000007700000770000007777000007700000770000007777000007700000770000007777009000000000000009
0070070077676666076760001aa10000a9a000000007700007777700077777700007700007ff770007ffff700007700007ff770007ffff709000000000000009
0007700077777700076767601a9a1000a99a0000007777000777777007777770007ff7000777777007777770007ff70007ffff7007ffff709000000000000009
0007700077766600767767671a99a100a999a00000777700007777707777777700777700007fff707ffffff7007ff700007fff707ffffff79000000000000009
0070070077777000766777771a99aa00a99aaa0007777770007777777777777707ffff70007777777777777707ffff70007ffff77ffffff70000000000000000
0000000077766000777777771aaa1000aaa0000007777770007777777777777707777770007ffff77ffffff707ffff70007ffff77ffffff70000000000000000
00000000077700000777777001110000a00000007777777707777777777777777ffffff707777777777777777ffffff707fffff77ffffff70000000000000000
00076000000af000000d10000000000000000000777777777777777077777777777777777fffff707ffffff77ffffff77fffff707ffffff70000000000000000
077666600aaffff00dd11110000000000000000007777770777777007777777707ffff70777777007777777707ffff707ffff7007ffffff70000000000000000
076666600afffff00d1111100000000000000000077777707777770077777777077777707ffff7007ffffff707ffff707ffff7007ffffff70000000000000000
76600666aff00fffd11001110000000000000000007777000777770077777777007ff7000777770077777777007ff70007fff7007ffffff79000000000000009
66600665fff00ff91110011500000000000000000077770007777770077777700077770007fff77007ffff70007ff70007ffff7007ffff709000000000000009
066666500fffff90011111500000000000000000000770000077777007777770000770000077777007777770000770000077ff7007ffff709000000000000009
066665500ffff9900111155000000000000000000007700000007700007777000007700000007700007777000007700000007700007777009000000000000009
00055000000990000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999900000099999
07777770000070000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070700000
07000070000707007777777700707000000000000007700000770000007777000007700000770000007777000007700000770000007777000000000007000000
07000070007000707000000707000700000000000007700007777700067777700007700007ff770006ffff700007700007ff770006ffff700000000070700000
0700007007000007700000077000007000000000006777000667777006777770006ff7000667777006777770006ff70006ffff7006ffff700000000000000000
070000707000007070000007070000070000000000667700006677707677777700667700006fff707ffffff7006ff700006fff707ffffff70000000000000000
070000700700070070000007007000700000000007667770007677777667777707ffff70007677777667777707ffff70007ffff77ffffff70000000000000000
070000700070700077777777000707000000000007667770007767777667777707667770007ffff77ffffff707ffff70007ffff77ffffff70000000000000000
07777770000700000000000000007000000000007776777707776777776677777ff6fff707776777776677777ffffff707fffff77ffffff70000000000000000
000e0000000e000e00700000e000e00000000000777767777776777077776677777767777fffff707ffffff77ffffff77fffff707ffffff70000000000000000
e00e0e00000e0e0007070e0000e0e0000000000007776670777677007777766707ffff70777677007777766707ffff707ffff7007ffffff70000000000000000
0e000007070000e0007000000e00007000000000077766707777670077777667077766707ffff7007ffffff707ffff707ffff7007ffffff70000000000000000
00020770700020000e0020070002000700000000007766000777660077777767007ff6000777660077777767007ff60007fff6007ffffff70000000000000000
0e002007070200000002077000002070000000000077760007777660077777600077760007fff66007ffff60007ff60007ffff6007ffff600000000000000000
00700000000070700e0000070707000000000000000770000077777007777760000770000077777007777760000770000077ff7007ffff600000000000000000
07070e000e0e0000e00e0e000000e0e0000000000007700000007700007777000007700000007700007777000007700000007700007777000000000000000000
0070000000e00070000e000007000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb3b3333333300077b3bb3333333000bbb77b3333333000b7bbb33b77b33000bbb777b33bb77000bbb3b3377b333000bbb3b3333b777000bbb3b3333333300
b0000000000000307000000000000030b000000000000030b000000000000030b000000000000070b000000000000030b0000000000000b0b000000000000030
b0333033303330307033303330333030b077b0b33033303070b330b770b33030b0bb7033b077b070b0333077b0333030b0333033b077b0b0b0333033303330b0
b000303300303030b000303300303030b000b03300303030700030b700303030b00070330070b0b0b000307b003030b0b00030330070b030b000303300303070
3030003000303030b0300030003030303070003000303030b0b0007000303030b0b0003000b030b030300070003030b03030003000703030303000300030b070
30333033303030303033303330303030707b3033303030303033307bb0303030b0b7b03b70303030303330bb3030b07030333033b07030303033303330b0b070
b000000000000030b0000000000000307000000000000030b0000000000000307000000000000030b000000000000070b000000000000030b000000000000070
03333333333333000b333333333333000bbb33333333330003377bb3b333330007bb33b77b333300033b777b33bb77000333333377bb3300033333333bb77700
077777777777777777000000000000000000666777777770000066777777777007777777777777700000ddddddddddd00000bbbbbbbbbbb00888888888888880
700000000000000000700000000000000066666ffffffff70066000000000007700000000000000700dd22222222222d00bb00000000000b8000000000000008
707770666077706660700000000000000666666ffffffff706000000000000077fff6666fffffff70d2222222222222d0b0000000000000b8222222222222228
707070060070006060700000000000007f66666ffffffff770000000000000077000000000000007d22222222222222db00000000000000b8000000000000008
707770060070006060700000000000007ff6666f7777777070000000777777700777ff66ffff7770d2222222ddddddd0b0000000bbbbbbb00888222222228880
707000666077706660700000000000007fff66670000000070000006000000000000700000070000d222222d00000000b000000b000000000000800000080000
700000000000000000700000000000007ffff666777777007000000077777000000007f6ff700000d2222222dddddd00b0000000bbbbb0000000082222800000
077777777777777777000000000000007fffff66ffffff7070000000000007000000070000700000d2222222222222d0b000000000000b000000080000800000
0777777777777777777777777700000007ffffff66fffff77000000000000700000007ff6f7000000d2222222222222db000000000000b000000082222800000
7000000000000000000000000070000000777777666ffff77000000077777000000007000070000000dddddd2222222db0000000bbbbb0000000080000800000
70777066607770666070006660700000000000007666fff77000000700000000000007ff6f70000000000000d222222db000000b000000000000082222800000
7070000600707060007000660070000007777777f6666ff7700000007766666000000700007000000ddddddd2222222db0000000bbbbbbb00000080000800000
700070060070706060700060007000007ffffffff66666f77000000000000006000007ff66700000d22222222222222db00000000000000b0000082222800000
707770666070706660777066607000007ffffffff666666007000000000000060000070000700000d2222222222222d00b0000000000000b0000080000800000
700000000000000000000000007000007ffffffff66666000077000000000006000007fff6700000d22222222222dd0000bb00000000000b0000082222800000
077777777777777777777777770000000777777776660000000077666666666000000077770000000ddddddddddd00000000bbbbbbbbbbb00000008888000000
007777770077777007777770000000000000000000000000000000000000000000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
07000007070000077000000700000000000000000000000000000000000000000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
7000777070007770700000070000000000000000000000000000000000000000aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
7000000770000007077007700000000000000000000000000000000000000000aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
7000000770000007007007000000000000000000000000000000000000000000aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
0777000770007770007007000000000000000000000000000000000000000000aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
7000007007000007007007000000000000000000000000000000000000000000aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
77777700007777700007700000000000000000000000000000000000000000000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
0000000000000000000bbbbb1fffffffffffffffffffffff00000000000033330000000004000000004000000000000000000000000060006700000000000000
0000000000000000bbbbb33bffffffffffffffffffffffff000000000033353300000000040000004440005000000000000000000066e706ee77700000000000
0000000000000bbbbbb333331fffffffffffffffffffffff0000000003355555000000000044000040000500000000000000006666eeee6ee7eee70000000000
000000000000bb3b33335535ffffffffffffffffffffffff000000005550010100000000400440040000540000000000000066eeeeeeeeee7eeeee7700000000
0000000000bbb33355551111ffffffffffffffffffffffff0000000011010000000000000400440500454000000000000006eeeeeeeeeeeeeee7eeee77000000
000000000bb333551111ff1f01ffffffffffffffffffffff000000000000000000000000005004544450000000000000006eeeeeee77eeeeee77eeeeee700000
00000000333311111f1f1ff10fffffffffffffffffffffff000000000000000000000000000544444000000000000000006ee77eeeeeeeeeeeee777e7ee70000
0000000b31110000f1fff1ff01ffffffffffffffffffffff00000000000000000000000000005544000000000000000006eeeee77eeee77eeeeeeee7eee70000
000000331f1f1ffff1fff1ff00ffffffffffffffffffffff0000000000000000000000000000005440000000000000006eeeeeeee7eeeee7eeeeee2eeeee7000
00000331fff1ff1ffffffff1001fffffffffffffffffffff000000000000000000000000000000044400000000000066eeeeeeeeeeeeeee72eee22eee7ee7000
000031ff1f1ffff1fff1ffff00ff1fffffffffffffffffff0000000000000000000000000000000044400000000066eeeeeeee2eeeeeeeeee222eeeeeee27000
00003f1ffffff1fff1ffff1f0001ffffffffffffffffffff00000000000000000000000000000000444000000002eeeee2ee2eeee2eee2ee2eeee2e2ee270000
00031ff1f1ff1ff1ffffffff00001fffffffffffffffffff000000000000000000000000000000005444000000002eeeee22e2222e222eee22222e2222270000
0031f1ffffffffff1fff1ff10000ff1fffffffffffffffff00000000000000000000000000000000544440000002e22ee2222eee222e22e2e22ee22222600000
003f1fffffffff1fffffffff000001f1ffffffffffffffff000000000000000000000000000000054b454440000022222e222222222220220202222266000000
01fffff1ff1ffffffffff1ff0000001fffffffffffffffff00000000000000000000000000000054bb4454b40000002222222200220000002020226600000000
f11fffffffffffffffffffff00000001f1ffffffffffffff00000000000000000000000000bbbbbb000000000000000000000000000660007700000000000000
f1ffffffff1ffffff1ffffff000000001f1f1fffffffffff00000000000000000000000bbbb3b33b00000000000000000000000000667606ee77000000000000
fffffffffffffffffffff1ff0000000001fffff1ffffffff000000000000000000000bbb3b33333300000000000000000000066666eeee6ee7ee770000000000
1ffff1ffffffffffffffffff000000000011f1ff1fffffff0000000000000000000bbb3333333535000000000000000000066eeeeeeeeeee7eeeee7700000000
ffffffffffffffffffffffff00000000000011ffff1f1ff1000000000000000000b3b333335550000000000000000000006eeeeeeeeeeeeeeee7eeee70000000
ffffffff1fff1fffffffffff00000000000001111111f1ff0000000000000000033b3355551100000000000000000000006eeeeeee7eeeeeee77eeeee7700000
ffffffffffffffffffffffff0000000000000000111111110000000000000000b335551111000000000000000000000006ee7eeeeeeeeeeeeee7777e7ee70000
1ffff1ffffffffffffffffff00000000000000000001111100000000000000033551110000101001000000000000000006eeee77eeee777eeeeeeee7eee70000
0000000000000000000000000000000000000000000e77000000000000000033511000000001001000000000000000666eeeeeee7eeee7eeeeee22eeeeee7000
000000000000000000000000000000000000000000eeee7000000000000000351001001010000000000000000000662ee2eeee2eeeeeeee2ee22eeeee7e27000
000000000000000000000000000000000000000002eee7e70000000000000300000000000010000000000000000222eeeeee2eeee2eeeeee22eeeeeeee227000
0000000000000000000000000000000000000000222eeee7000000000000030001000000000000000000000000002eeeee22e222e2eee2eeeeee2e22e2270000
00000000000000000000000000000000000000000242042000000000000030000000000000000001000000000000222ee2222eee2e222eee2222e22222270000
00000000000000000000000000000000000000000004400000000000000000000000001000000000000000000000022222222222222e22e222ee222222600000
00000000000000000000000000000000000000000000540000000000000000000000000000001000000000000000002200222222222222222222222666000000
00000000000000000000000000000000000000000005444000000000000300010001000000000000000000000000000000000000220222202222266000000000
00070000007700000077700000070000007700000077700000070000007700000077700000000000000000000000000000000000000000000000000000000000
007f700007ff7700007f7000007f700007ff7700007f700000777000077777000077700000000000000000000000000000000000000000000000000000000000
007f7000007fff7007fff70000777000007777700777770000777000007777700777770000000000000000000000000000000000000000000000000000000000
07fff700007fff7007fff70007fff700007fff7007fff70007777700007777700777770000000000000000000000000000000000000000000000000000000000
07fff70007fff70007fff70007777700077777000777770007777700077777000777770000000000000000000000000000000000000000000000000000000000
007f700007fff70007fff700007f700007fff70007fff70000777000077777000777770000000000000000000000000000000000000000000000000000000000
007f70000077ff70007f700000777000007777700077700000777000007777700077700000000000000000000000000000000000000000000000000000000000
00070000000077000077700000070000000077000077700000070000000077000077700000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5f666f6fff666f6f6f666f66ffffff50000000000000000000000000000e0000000e000e00700000e000e0000000000000000000000000000000000000000000
50600060006060606060006060000500000000000000000000000000e00e0e00000e0e0007070e0000e0e0000000000000000000000000000000000000000000
506600600060606660660066000050000000000000000000000000000e000007070000e0007000000e0000700000000000000000000000000000000000000000
5060006660666066606660606005000000000000000000000000000000020770700020000e002007000200070000000000000000000000000000000000000000
500000000000000000000000005000000000000000000000000000000e0020070702000000020770000020700000000000000000000000000000000000000000
5555555555555555555555555500000000000000000000000000000000700000000070700e000007070700000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000007070e000e0e0000e00e0e000000e0e00000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000070000000e00070000e000007000e000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000220000002200000ee2200000220000003300000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000e772000e277e000e77e72000e772e00030030000000000000000000000000000000000
555555555555500000000000000000000000000000000000000000000ee772e0e7277ee00227e7200ee7727e0bb003b000000000000000000000000000000000
50000000000005000000000000000000000000000000000000000000277ff77ee77ff772277ff27e277ff77eb00b300b00000000000000000000000000000000
50660066600600500000000000000000000000000000000000000000277ff27e2eeff772277ff77e277ffee2b00bcc0b00000000000000000000000000000000
506060606060600500000000000000000000000000000000000000000227e720277272200ee772e0022727720bb020c000000000000000000000000000000000
506060606066600050000000000000000000000000000000000000000e77e72002277e0000e7720000e77220020020c000000000000000000000000000000000
5f66ff6f6f6f6ffff50000000000000000000000000000000000000000ee2200000ee00000022000000ee0000022cc0000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01110000011100000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010000010100000101000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000
01010000010100000111000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000
01010000010100000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01110010011100100111000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000100bbb777b33bb7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000101b000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000b0bb7033b077b070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000b00070330070b0b0000000000000000000000000000000000000000000000000000000000000010100000000000000000000
0000000000000000000000000000b0b0003000b030b0000000000000000000000000000000000000000000000000000000000000001000000000000000000000
0000000000000000000000000000b0b7b03b70303030000000000000000000000000000000000000000000000000000000000000010100000000000000000000
00000000000000100000000000007000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000007bb33b77b333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000006667777777700000066777777777000777777777777770000000000000000000000000000000000000000
0000000000000000000000000000000000000000066666ffffffff70006600000000000707000000000000007000000000000000000000000000000000000000
0000000000000000000000000000000000000000666666ffffffff70060000000000000707fff6666fffffff7000000000000000000000000000000000000000
0000000000000000000000000000000000000007f66666ffffffff70700000000000000707000000000000007000000000000000000000000000000000000000
0000000000000000000000000000000000000007ff6666f777777700700000007777777000777ff66ffff7770000000000000000000000000000000000000000
0000000000000000000000000000000000000007fff6667000000000700000060000000000000700000070000000000000000000000000000000000000000000
0000000000000000000000000000000000000007ffff66677777700070000000777770000000007f6ff700000000000000000000000000000000000000000000
0000000000000000000000000000000000000007fffff66ffffff700700000000000070000000070000700000000000000000000101000000000000000000000
00000000000000000000000000050000000000007ffffff66fffff7070000000000007000000007ff6f700000000000000000000010000000000000000000000
00000000000000000000000000000000000000000777777666ffff70700000007777700000000070000700000000000000000000101000000000000000000000
000000000000000000000000000000000000000000000007666fff7070000007000000000000007ff6f700000000000000000000000000000000000000000000
00000000000000000000000000000000000101007777777f6666ff70700000007766666000000070000700000000000000000000000000000000000000000000
0000000000000000000000000000000000001007ffffffff66666f7070000000000000060000007ff66700000000000000000000000000000000000000000000
0000000000000000000000000000000000010107ffffffff66666600070000000000000600000070000700000000000000000000000000000000000000000000
0000000000000000000000000010000000000007ffffffff6666600000770000000000060000007fff6700000000000000000000000000000000000000000000
00000000000000000000000000000000000000007777777766600000000077666666666000000007777000000000000000010000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000670000000000000000000000
0000000000000000000000000000000000000007770000000000000000000000000000000000000000000000000010000066e706ee7770000000000000000000
000000000000000000000000000000000000007766777600000000000fff0f000fff0f0f00000000000000000000006666eeee6ee7eee7000000000000000000
000000000000000000000000000000000000007767666600000000000f0f0f000f0f0f0f0000000000000000000066eeeeeeeeee7eeeee770000000000000000
000000000000000000000000000000000000007777770000000000000fff0f000fff0fff00000000000000000006eeeeeeeeeeeeeee7eeee7700000000000000
000000000000000000000000000000000000007776660000000000000f000f000f0f000f0000000000000000006eeeeeee77eeeeee77eeeeee70000000000000
000000000000000000000000000000000000007777700000000000000f000fff0f0f0fff0000000000000000006ee77eeeeeeeeeeeee777e7ee7000000000000
000000000000000000000000000000000000007776600000000000000000000000000000000000000000000006eeeee77eeee77eeeeeeee7eee7000000000000
00000000000000000000000000000000000000077700000000000000000000000000000000000000000000006eeeeeeee7eeeee7eeeeee2eeeee700000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000066eeeeeeeeeeeeeee72eee22eee7ee700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000066eeeeeeee2eeeeeeeeee222eeeeeee2700000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000002eeeee2ee2eeee2eee2ee2eeee2e2ee27000000000000
0000000100000000000000000000000000000000000000000011011101110111011101100011001100002eeeee22e2242e222eee42222e222227000000000000
000000000000000000000000000000000000000000000000010001000010001000100101010001000002e22ee2222ee422272244422e52222260000000000000
00000000000000000000000000000000000000000000000001110110001000100010010101000111000022222e22222244222042020522226600000000000000
00000000000000000000000000000000000000000000000000010100001000100010010101010001000007222222224027400400205422660000000000000000
00000000010000000000000000000000000000000000000001100111001000100111010101110110000000000000000400440500454700000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050045444500000000000000000000000
00000000000000000000000000000000000000000000000200000000000000000000000010100000000000000000000005444440000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000554400000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005440000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444000000000000000000000000
00000000000000000000000000000000000000000000000001110101011100110111011101110100000000000000000000000044400000000000000000000000
0000000000000000000000000000000000000000000000000010010100100101010100100101010000000000e000000000000044400000000000000000000000
00000000000000000000000000000000000000000000000000100101001001010110001001110100000000000000000000000054440000000000000000000000
000000000000000000000000000000000000000000000000001001010010010101010010010101000000000000000000000000544440000e0000000000000000
0000000000000000000000000000000000000000000000000010001100100110010101110101011100000000000000000000054b454440000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000054bb4454b4000000000000000000
00000000000000000000000000000000000000000000000000000000000000e000000000000000000e00000000000000000bbbbbbbbbbbb00000000000000000
000000000000000000000000000000000000000000000000000000000000000000e000e0000000000000000000000000bbbb3b33bb33b3bbbb00000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb3b333333333333b3bbb000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb33333335355353333333bbb0000000000
0000000000000000000000000000000000000000000000000000000111011100110101011100000000000000000b3b3333355500000055533333b3b000000000
00000000000000000000000000000000000000000000000000000001010101010101010010000000000000000033b335555110000000011555533b3300000000
000000000000000000000000e0000000000000000000000000000001110110010101010010000010000000000b335551111000000000000111155533b0000000
00000000000000000000000000000000000000000000000000000001010101010101010010000000000000003355111000010100110010100001115533000000
00000000000000000000000070000000000000000000000000000001010111011000110010000000000000033511000000001001001001000000001153300000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000035100100101000000000000001010010015300000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000300000000000010000000000100000000000030000
00000000000000000000000000000000000000000000000000000000000000000000000000e00000000000300010000000000000000000000000000100030000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000110000000000000000003000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000010000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000010000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000030001000100000000000000000000000010001000300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000009c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a0b100898a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0a100a0a0a100999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0b0a1b0b0a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0b1100000c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c1700c170
930c00003f64500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
934000003f65500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a80400002136521315213352131500000000000000000000283652831528335283150000000000000000000024365243152433524315000000000000000000000000000000000000000000000000000000000000
680300001a0721a0721f0721f072210622106226062260622d0522d0522d0522d0522d0422d0422d0322d0222d0122d0122d0002d000260002600026000260000000000000000000000000000000000000000000
700500001a0621a0621a0621f0621f0621f0622106221062210622606226062260622b0622b0622b0622d0622d0622d0622d0622d0522d0522d0422d0422d0322d0222d0122d0122d0122d0122d0120000000000
0a030000130701307013070160000c0700c0700c0700c070210001a0001a0001a0001a0001a0001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90100018376103761035610306102a610226101d61019610166101461011610106100f6100f6100f6101261014610176101b6101f610266102c6103261039610266002c600306003260033600346003560036600
0b1000010c8300c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c8000c800118001380013800118000c8000c8000c8000b8001180011800118000000000000000000000000000
b510180026055260251f0551f0251c0551c02526055260251f0551f0251c0551c02526045260251f0451f0251c0451c02526035260151f0351f0151c0351c0152500520005200050000500005000050000500005
0b1000010a8300a8000a8000a8000a8000a8000a8000a8000a8000a8001580016800158001580015800158001180011800118000f8000a8000a8000a8000a8000480004800000000000000000000000000000000
b5101800260552602521055210251d0551d025260552602521055210251d0551d025260452602521045210251f0451f025260352601521035210151f0351f0152500520005200050000500005000050000500005
051018001f0001f00017000170001a0001a0001f0001f00017000170001a0001a0001f0001f00017000170001a0001a0001f0001f00017000170001f0351f0122500220002200020000200002000020000200002
0510180017035170121a0351a0121f0251f01217025170121a0251a0121f0251f01217025170121a0251a0121f0251f01217025170121a0251a0121f0251f0122000500005000050000500005000050000500005
05101800150351501218035180121f0251f012150251501218025180121f0251f012150251501218025180121f0251f012150251501218025180121f0221d0112000500005000050000500005000050000500005
0b1018000c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c8300c830118301383113830118310c8300c8300c8300b8311180011800118000000000000000000000000000
0b1018000a8300a8300a8300a8300a8300a8300a8300a8300a8300a8301582016821158211582015820158201183011830118300f8310a8300a8300a830098310480004800000000000000000000000000000000
901018003761037610356102e6102961025610216101d6101b6101961017610156101461012610126101161011610106100f6100d6100b610076100461000610266002c600306003260033600346003560036600
0b1018000a8300a8300a8300a8300a8300a8300a8300a8300a8300a8301582016821188211882018820188201183011830118300f8310a8300a8300a830098310480004800000000000000000000000000000000
61101800261002610024100241002110021100241002410024100241001d1001f10021100211001a1001c1001d1001c10018100181001f1221f11221122211120010000100001000010000100001000010000100
611018002613226122261122611226112261121f1321f1221f1121f1121f1121f1122413224122241122411224112241121d1321d1221d1121d1121d1121d1120010000100001000010000100001000010000100
611018002213222132221222212222112221121d1221d1121d1321d1121c1221c1121c1321c1121a1221a1121a1321a1121512215112151321513213131131320010000100001000010000100001000010000100
6110180013122131221312213122131121311217122171121713217112181221811218132181121a1221a1121a1321a112151221511215132151120e1320c1310010000100001000010000100001000010000100
611018000c1420c1320c1220c1120c1120c1121c1221c1121c1221c1121d1221d1121d1321d1121f1321f1121f1321f11218132181121a1321a1321d1311d1220010000100001000010000100001000010000100
380400000e052130521505213052150521805215052180521a052180521a0521f0521a0521f052210521f052210422404221042240422603224032260322b032260222b0222d0222b0222d012320122d01232012
491100201893019910189101a9001892019900189101a910189201a900189101a9001892019910189100c0231893019900189101a9001892019900189101a910189201a900189101a90018920199100c0230c013
751100201503015020150101501015020150101502015010150201501015020150101502015010160201602016020160101602016010160201601016020160101602016010160201601016020160101602016010
751100201f0301f0301f0201f0101f0201f0101f0201f0101f0201f0101f0201f0101f0201f0101f0301f0301f0201f0101f0201f0101f0201f0101f0201f0101f0201f0101f0201f0101f0201f0201d0211d020
7511002018030180301802018010180201801018020180101802018010180201801018020180101b0201b0201b0201b0101b0201b0101b0201b0101b0201b0101b0201b0101b0201b0101b0201b0101b0201b010
751100202103021030210202101021020210102102021010210202101021020210102102021010240302403024020240102402024010240202401024020240102402024010240202401024020240202602126020
6d11002026005260051f0051f00500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000052b04526035
6d110020240451f0352b04526035240451f0352b03526025240351f0252b02526015240251f0152904524035220451d0352904524035220451d0352903524025220451d0252902524015220451d0151b03518025
6d110020240451f0352b04526035240451f0352b03526025240351f0252b02526015240251f015300452e0352b04526045300452e0352b04526045300352f0252b03526025300252f0252b02526015240351f025
751100201303013020130101301013020130101302013010130201301013020130101302013010120201202012020120101202012010120201201012020120101202012010120201201012020120101202012010
751100201b0301b0301b0201b0101b0201b0101b0201b0101b0201b0101b0201b0101b0201b0101b0301b0301b0201b0101b0201b0101b0201b0101b0201b0101b0201b0101b0201b0101b0201b0201902119020
7511002010030100201001010010100201001010020100101002010010100201001010020100100f0200f0200f0200f0100f0200f0100f0200f0100f0200f0100f0200f0100f0200f0100f0200f0100f0200f010
751100201303013030130201301013020130101302013010130201301013020130101302013010130301303013020130101302013010130201301013020130101302013010130201301013020130201102111020
0b110020240451f0352b04526035240451f0352b03526025240351f0252b02526015240251f0152904524035220451d0352904524035220451d0352903524025220351d02529025240150c8300e8310e8300c831
0b11002007840078400784007840078400784007840078400783007830078300783007830078300b8400b8400b8400b8400b8400b8400b8400b8400b8400b8400b8300b8300b8300b8300b8300b8300b8300b830
0b1100200c8400c8400c8400c8400c8400c8400c8400c8400c8300c8300c8300c8300c8300c830038400384003840038400384003840038400384003840038400383003830038300383003830038300383003830
491100201893019910189101a9001892019900189101a9101a900189101b0231890019910189101a9100f023189101a9001892013013130132202318920220131a900189101b0131890019910189101802318023
0111002022a1322a130c0230c0002b6251a9000c0132c6150c0132c6150c0230c0132b615336000c0130c0000c023189200c0230c0132b625199000c0132c6150c0132c6151b9001a9202b615189201b9100c023
0b1100200984009840098300982009840098200984009820098400982009840098200984009820078400784007830078200784007820078400782007840078200784007820078400782007840078200784007820
0b1100200c8400c8400c8300c8200c8400c8200c8400c8200c8400c8200c8400c8200c8400c820038400384003830038200384003820038400382003840038200384003820038400382005841058200584005820
011100200c023189101a9200c0132c625189100c013199000c0131a920199100c0132b615189201a9100c0130c023189101a9200c0132c6252b615130131a90018920199100c0130c0132b6150c01322a1322a13
7511002018030180301802018010180201801018010180201801018020180101802018010180201c0211c0201c0201c0101c0201c0101c0201c0101c0101c0201c0101c0201c0101c0201c0101c0201c0101c020
7511002022030220302202022010220202201022010220202201022020220102202022010220301f0311f0301f0201f0101f0201f0101f0201f0101f0101f0201f0101f0201f0101f0201f0101f0201f0101f020
751100201b0301b0301b0201b0101b0201b0101b0101b0201b0101b0201b0101b0201b0101b0201d0211d0201d0201d0101d0201d0101d0201d0101d0101d0201d0101d020180101802016010160201801018020
751100201f0301f0301f0201f0101f0201f0101f0101f0201f0101f0201f0101f0201f0101f0302103121030210202101021020210102102021010210102102021010210201c0101c0201a0101a0201c0101c020
751100201b0301b0301b0201b0101b0201b0101b0101b0201b0101b0201b0101b0201b0101b020190211902019020190101902019010190201901019010190201901019020140101402012010120201401014020
751100201f0301f0301f0201f0101f0201f0101f0101f0201f0101f0201f0101f0201f0101f0301d0311d0301d0201d0101d0201d0101d0201d0101d0101d0201d0101d020180101802016010160201801018020
0b1100200c8400c8400c8300c8200c8400c8200c8400c8200c8400c8200c8400c8200c8400c820048400484004830048200484004820048400482004840048200484004820048400482004840048200484004820
0b1100200f8400f8400f8300f8200f8400f8200f8400f8200f8400f8200f8400f8200f8400f820058400584005830058200584005820058400582005840058200584005820058400582005840058200784007820
0b1100200f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f8000f800058000580005800058000580005800058000580005800058000580005800058000580006840088410b8410b840
0b1100201684018840188301882018840188201884018820188401882011840118200c8400c8200a8400a8400a8300a8200a8400a8200a8400a8200a8400a8200a8400a8200a8400a8200c8410c8200c8400c820
491100201a9201991018910199101a9101991018910199101a92019910189101a92019910189100c023199101a9201991018910199101a9201991018910199101a920199100c023189101a910199100c0230c013
491100201a9201991018910199101a9101991018910199101a92019910189101a92019910189100c023199101a9201991018910199101a9101991024023240131a9201f023199101a0131a910199101302313023
0b1100200c8400c8400c8300c8200c8100c8100e8400e8400e8300e8200f8400f8400f8300f820048400484004830048200484004820048400482004840048201384015841158401384104840048200484004820
0b1100201683016830168201681016830168101683016810168301683018831188101883018810058300583005830058200584005820058400582005840058200584005820078400782005840058200784007820
751100201803018030180201801018020180101801018020180101802018010180201801018020170211702017020170101702017010170201701017010170201701017020170101702017010170201701017020
751100201b0301b0301b0201b0101b0201b0101b0101b0201b0101b0201b0101b0201b0101b0201b0211b0201b0201b0101b0201b0101b0201b0101b0101b0201b0101b0201b0101b0201b0101b0201901019020
6d1100202b0252a015260251f0152b0352a025260351f0252b0352a025260351f0252b0352a0252b03529025260351f02526035290252b03529025260351f0252b02529015260251f0152b02526015220251d015
6d11002026025240151f0251a01526035240251f0351a02526035240251f0351a025260352402526035210251f0351a0251f0352102526035210251f0351a02526035210251f0351a02526035210251d03518025
0b1100200c8400c8400c8300c8200c8400c8200c8400c8200c8400c8200c8400c8200c8400c820068400684006830068200684006820068400682006840068200684006820068400682006840068200684006820
__music__
00 47080944
00 470a0b44
01 0708094c
00 110a0b0c
00 470f090d
00 47100b0e
00 470f090d
00 13120b0e
00 540f0914
00 55100b15
00 560f0916
00 0c120b17
00 0d0f0914
00 0e100b15
00 0d0f0916
02 0e120b17
01 191a1b5b
00 191c1d1e
00 191a1b1f
00 191c1d20
00 281a1b1f
00 281c1d20
00 19251a1b
00 19262122
00 19262122
00 19272324
00 28272324
00 292a1a1b
00 292b1c1d
00 292a1a1b
00 29361c1d
00 292a1a1b
00 292b1c1d
00 291a1b1f
00 291c1d20
00 19251a1b
00 59262122
00 51262122
00 19272324
00 28272324
00 592d2e6e
00 372f3070
00 372d2e6e
00 37353132
00 37332d2e
00 37342f30
00 37332d2e
00 38743132
00 2c392d2e
00 2c342f30
00 2c392d2e
00 2c3a2f30
00 2c392d2e
00 38342f30
00 1923243d
00 2823243e
00 373f3b3c
00 383f3b3c
00 1923243d
00 2823243e
00 373f3b3c
00 373f3b3c
00 373f3b3c
02 777f3b3c

