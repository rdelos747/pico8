pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--[[
jumper
- perhaps player cannot advance
		until they collect a special 
		item on the stage (eg, a key)
- pickups:
		- gems (just points for now)
		- unlimited jumps for x seconds
		- invincibility for x seconds
		- magnets!!!!
		- multi-dir-shoot 
- show number jumps in hud
- touching enemy decreases heart
			and jump num
- eat flowers to gain health?
- - or, just place hearts in hard
					areas?
- new power ups:
		- spread bubble bullets (3,5,etc)
- op jump+ solutions
  - just remove extra jumps
  - make jump+ more expensive
  - player can lose jump+ if hit
  - make terrain harder in late game
		- jump+ consumes water
- new enemy types
		- an ememy that speeds up time
- other ideas
		- end game after 100 levels
		- timers should be less common
		- once per world, player can 
				pick up an item that 
				follows you around, lasts 
				for 30s, eg magnet or 
				infinite jumps
		- blobs should move around,
				also more blobs in the end
]]--

-- ==========
-- constants
-- ===================
xmax=16
ymax=16
cell_chance=30
cell_pad_h=3
cell_pad_v=5
cell_birth=3
cell_death=1
cell_autos=3

--solids
cb=nil -- cur biome
biome={
	grass={
		ter_rock=16,
		ter_bloc=17,
		ter_roc2=18,
		ter_blc2=19,
		ter_gras=20,
		pas_flw1=23,
		pas_flw2=24,
		pas_stem=25,
		pas_tree=26
	},
	ice={
		ter_rock=144,
		ter_bloc=145,
		ter_roc2=146,
		ter_blc2=147,
		ter_gras=148,
		pas_flw1=149,
		pas_flw2=150,
		pas_stem=151,
		pas_tree=152
	},
	desert={
		ter_rock=160,
		ter_bloc=161,
		ter_roc2=162,
		ter_blc2=163,
		ter_gras=164,
		pas_flw1=165,
		pas_flw2=166,
		pas_stem=167,
		pas_tree=168
	}
}
ter_pipe=21
ter_watr=22
pas_watr=27

--coins
coin_chance=5
//s_coin=52
//s_coin2=80
//s_coin3=96
s_coin_hud=48
val_yellow=1
val_green=5
val_red=10

--time
time_chance=10
time_add=20
time_add_shop=50
time_add_blob=5
time_add_bat=10
time_loss=25
time_start=60

--enmies
hp_bat=2
hp_blob=1

--player
p_max_coin=1000
p_jump_min=2

--hud
hud_top=121

--prices
prices={50,100,150,200}

--logo
logo={
	x=32,y=56,
	w=9,t=-5,
	p={1,12,3,11,10,9,8,2},
	snd=0
}
show_logo=true

has_died=false
first_run=true
play_music=true

-- ==========
-- helpers
-- ===================
function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function chance(n)
	return rand(0,100) < n
end

function copy_table(t)
	local ll={}
	for j=0,ymax-1 do
		ll[j]={}
	for i=0,xmax-1 do
		ll[j][i]=t[j][i]
	end end
	return ll
end

function print_level()
	for j=0,ymax-1 do
		local s=""
		for i=0,xmax-1 do
			s=s..level[j][i]
		end 
		printh(s)
	end
	printh("")
end

function level_solid(i,j)
	local b=level[j][i]
	return (b>=cb.ter_rock and
						b<=cb.ter_gras) or
						b==ter_pipe or
						b==ter_water
end

function point_free(x,y)
	local i=flr(x/8)
	local j=flr(y/8)
	
	return not level_solid(i,j)
end

last_a=nil
last_b=nil
function place_free(o,ox,oy)
	local a={
		x=o.x+ox,y=o.y+oy,w=o.w,h=o.h
	}
	local free=true
	for j=0,ymax-1 do
	for i=0,xmax-1 do
		if level_solid(i,j) then
			local b={
				x=i*8+4,y=j*8+4,
				w=8,h=8
			}
			if col_bb(a,b) then
				//printh("found")
				free=false
				--last_a=a
				--last_b=b
			end
		end
	end end
	return free
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

function draw_bb(o)
	rect(
		o.x-o.w/2,
		o.y-o.h/2,
		o.x+o.w/2,
		o.y+o.h/2,
		8)	
end

function set_pause()
	pause=4
end

function set_hit()
	hit=12
end

function _music(n)
	if(play_music)music(n)
end

-- ==========
-- init
-- ===================
function _init()
	printh("------start------")
	//reset()
	init_parallax()
	_music(24)
end

function reset()
	--vars
	last_level=nil
	l_type="norm"
	l_num=1
	scroll=0
	l_tm=0
	sprinkles={}
	bullets={}
	flares={}
	flashes={}
	bats={}
	blobs={}
	--hearts={}
	times={}
	price_lvls={1,1,1,1}
	shop={x=78,y=200}
	pause=0
	hit=0
	perfect=0
	total_coin=0
	total_perf=0
	total_enim=0
	total_lvls=0
	cur_lvl_cns=0
	game_tm=time_start
	cb=biome.grass
	--functions
	clear_objects()
	//init_level()
	init_first()
	
	//temp
	//init_shop()
	//shop.y=72
	//scroll=0
	//temp
	
	init_player()
	init_hud()
	
	if not first_run then
		_music(24)
	end
	has_died=false
end

-- ==========
-- draw
-- ===================
function _draw()
	cls()
	rectfill(0,0,128,128,0)
	map(0,0,0,-64,16,16)
	draw_parallax()
	
	if show_logo then
		draw_logo()
		return
	end
	
	if perfect>0 then
		draw_perfect()
		return
	end
	
	--if pp.hp<=0 then
	if game_tm<=0 then
		draw_player_dead()
		return
	end
	
	if(l_num==1)draw_creds()
	
	draw_blobs()
	draw_bats()
	
	if scroll==0 then
		draw_level()
		draw_sprinkles()
		draw_bullets()
		draw_flares()
		draw_flashes()
		--draw_hearts()
	else
		draw_scroll()
	end
	if hit<=0 or flr(hit)%2==0 then
		draw_player()
		if(l_num>1)draw_hud()
		
	end
	if l_type=="shop" then
		draw_shop()
	elseif l_type=="frst" then
		draw_first()
	end
	
	if last_a!=nil then
		rect(
			last_a.x-last_a.w/2,
			last_a.y-last_a.h/2,
			last_a.x+last_a.w/2,
			last_a.y+last_a.h/2,
			12)
	end
		if last_b!=nil then
		rect(
			last_b.x-last_b.w/2,
			last_b.y-last_b.h/2,
			last_b.x+last_b.w/2,
			last_b.y+last_b.h/2,
			9)
	end
end

-- ==========
-- update
-- ===================
update_tm=30
function _update()
	update_parallax()
	if show_logo then
		if btn(❎) or btn(🅾️) then
			logo.t=25
		end
		return
	end
	
	if pause>0 then
		pause-=0.3
		return
	end
	
	if hit>0 and scroll==0 then
		hit-=0.3
	end
	
	if perfect>0 then
		return
	end
	
	if scroll>0 then
		update_scroll()
	else
		if pp.shopping then
			update_shopping()
			return
		end
		
		update_tm-=1
		if update_tm==0 then
			game_tm-=1
			update_tm=30
		end
		
		if game_tm<=0 then			
			if not has_died then
				_music(56)
			end
			first_run=false
			has_died=true
			player_dead()		
			return
		end
		
		update_player()
		update_bullets()
		update_bats()
		update_blobs()
	end
	
	if pp.y>128+8 then
		if pp.can_die then
			game_tm-=time_loss
			set_hit()
		end
		init_scroll()
		return
	end
end

-- ==========
-- hud
-- ===================
function init_hud()
	hud={tm=0}
end

function draw_creds()
	print("a game by",48,5,1)
	print("raf @ gold team",
		35,12,1)
end

function draw_hud()
	hud.tm+=0.2
	--rectfill(0,0,128,9,15)
	rectfill(0,hud_top,128,hud_top+8,0)
	draw_hud_coins()
	--draw_hud_hp()
	draw_hud_jump()
	draw_hud_time()
	print(l_num,120,hud_top+1,7)
end

function draw_hud_coins()
	spr(flr(hud.tm)%4+s_coin_hud,
		2,hud_top)
	print("=",11,hud_top+1,7)
	local b=p_max_coin
	local s_tot=""
	local s_cur=""
	while b>pp.coin and b>10 do
		b=b/10
		if(b>pp.coin)s_tot=s_tot.."0"
	end
	b=p_max_coin
	while b>cur_lvl_cns and b>10 do
		b=b/10
		if(b>cur_lvl_cns)s_cur=s_cur.."0"
	end
	print(s_tot..pp.coin,16,hud_top+1,7)
	print(s_cur..cur_lvl_cns,32,hud_top+1,7)
end

--[[
function draw_hud_hp()
	for i=1,pp.hp_max do
		if i>pp.hp then
			print("♥",30+(i*6),3,5)
		else
			print("♥",30+(i*6),3,8)
		end
	end
end
]]--

function draw_hud_jump()
	local ttl=p_jump_min+pp.tanks
	--[[
	rectfill(78,0,
		70+(8*ttl),6,0)
	]]--
	--printh("sss")
	for i=1,ttl do
		if i<=p_jump_min then
			if i<=pp.jump then
				pal(6,1)
				pal(7,1)
				pal(12,1)
			end
			spr(62,70+(i*6),hud_top)
			pal()
		else
			local ii=(i-p_jump_min)-1
			//local nw=ii-pp.water
			local nw=mid(0,pp.water-ii*3,3)
			local off=flr(hud.tm)%2
			if nw==0 then
				spr(105,70+(i*6),hud_top)
			else
				spr(
					105+(nw*2)-off,
					70+(i*6),hud_top)
			end
		end
	end
end

function draw_hud_time()
	--local l=65
	--if(game_tm>9)l=69
	--if(game_tm>99)l=73
	--rectfill(61,0,l,6,0)
	local s=flr(hud.tm)%12
	if s==10 or s==11 then
		spr(78,55,hud_top-1,1,1,false,true)
	else
		spr(75+s/2,55,hud_top+1)
	end
	print(game_tm,62,hud_top+1,7)
end

--[[
function draw_hit()
	local x=62-((pp.hp_max*8)/2)
	for i=1,pp.hp_max do
		if hit>3 then
			if i-1>pp.hp then
				print("♥",x+(i*6),64,5)
			else
				print("♥",x+(i*6),64,8)
			end
		else
			if i>pp.hp then
				print("♥",x+(i*6),64,5)
			else
				print("♥",x+(i*6),64,8)
			end
		end
	end
end
]]--

function draw_sprinkles()
	for s in all(sprinkles)do
		s.tm+=1
		s.y+=s.dy
		s.x+=s.dx
		s.dx*=0.9
		s.dy+=s.ddy
		pal(7,8+(s.tm%8))
		spr(s.sp,s.x-4,s.y-4)
		pal()
		if(s.tm>16)del(sprinkles,s)
	end
end

function add_flash(x,y)
	for i=1,rand(1,5)do
		add(flashes,{
			tm=rand(-2,5),
			x=rand(x-4,x+4),
			y=rand(y-4,y+4),
			dx=rand(-1,1),
			dy=rand(-1,1),
			c=rand(12,15)
		})
	end
end

function draw_flashes()
	for f in all(flashes)do
		f.tm+=1
		f.x+=f.dx
		f.y+=f.dy
		f.dx*=0.9
		f.dy*=0.9
		pal(7,f.c)
		spr(43,f.x,f.y)
		pal()
		if(f.tm>16)del(flashes,f)
	end
end

-- ==========
-- bullets
-- ===================
function add_bullet(x,y,dx,dy,
	tm,rad,c)
	add(bullets,{
		x=x,y=y,dx=dx,dy=dy,
		w=rad*2,h=rad*2,
		tm=tm,sz=sz,c=c
	})
end

function update_bullets()
	for b in all(bullets)do
		b.tm-=1
		b.x+=b.dx
		b.y+=b.dy
		if(b.tm<=0)del(bullets,b)
		
		if not place_free(b,0,0) then
			add_flash(b.x,b.y)
			del(bullets,b)
		end

		if col_bb(pp,b) then
			player_hit(b.x,b.y)
			del(bullets,b)
		end
		
		for ba in all(bats) do
			if col_bb(b,ba) then
				del(bullets,b)
				damage_bat(ba)
			end
		end
		
		for bl in all(blobs) do
			if col_bb(b,bl) then
				del(bullets,b)
				damage_blob(bl)
			end
		end
	end
end

function draw_bullets()
	for b in all(bullets)do
		local w=max(0.5,flr(b.w/2))
		local h=max(0.5,flr(b.h/2))
		rectfill(
			b.x-w,
			b.y-h,
			b.x+w,
			b.y+h,
			b.c)
		--draw_bb(b)
	end
end

-- ==========
-- add hearts
-- ===================
--[[
function add_heart(x,y)
	add(hearts,{x=x,y=y})
end

function draw_hearts()
	for h in all(hearts)do
		spr(56,h.x-4,h.y-4)
	end
end
]]--

-- ==========
-- blobs
-- ===================
function add_blobs()
	local idx=rand(1,#player_start_points)
	local bt=player_start_points[idx]
	if bt==nil then
		for i=0,20 do
			printh("======= here =======")
		end
		printh("idx "..idx)
		printh("psp "..#player_start_points)
		return
	end
	local bdx=1
	if(chance(50))bdx=-1
	add(blobs,{
		x=(bt.i*8)+4,
		y=((bt.j*8)+4)+128,
		w=6,h=6,dx=bdx,
		tm=0,hp=hp_blob
	})
end

function draw_blobs()
	for b in all(blobs)do
		local bx=b.x-b.w/2
		local by=b.y-b.h/2
		spr(89+flr(b.tm)%2,
			bx,by,1,1,
			b.dx==-1,false)
		--draw_bb(b)
	end
end

function update_blobs()
	for b in all(blobs)do
		b.tm+=0.1
		if(col_bb(pp,b))player_hit(b.x,b.y)
		b.x+=b.dx*0.1
		if point_free(b.x,b.y+4) or
					not place_free(b,b.dx*0.1,0) then
			b.dx*=-1
		end 
	end
end

function damage_blob(b)
	add_flash(b.x,b.y)
	b.hp-=1
	if b.hp<=0 then
	--	if(chance(50))add_heart(b.x,b.y)
		game_tm+=time_add_blob
		add_flare(b.x,b.y,time_add_blob)
		del(blobs,b)
		total_enim+=1
	end
end

-- ==========
-- bats
-- ===================
function add_bats()
	local bc=((l_num-1)%10)*10
	if not chance(bc) then
		return
	end
	local bmin,bmax=1,2
	if(l_num%10>5)bmin,bmax=2,3
	if(l_num%10>7)bmin,bmax=3,5
	for i=1,rand(bmin,bmax) do
		local finding=true
		while finding do
			local ri=rand(1,xmax-2)
			local rj=rand(1,ymax-2)
			if level[rj][ri]==0 then
				finding=false
				add(bats,{
					x=ri*8,
					y=(rj*8)+128,
					w=7,h=7,
					oy=rj*8,
					tm=0,hp=hp_bat,
					ytm=0,xtm=0
				})
				--y=((bt.j*8)+4)+128,
			end
		end
	end
end

function draw_bats()
	for b in all(bats) do
		local bx=b.x-b.w/2
		local by=b.y-b.h/2
		spr(88,bx,by,1,1,
			sin(b.xtm)<0,false)
		spr(flr(b.tm)%4+84,bx,by-4)
		--draw_bb(b)
	end
end

function update_bats()
	for b in all(bats) do
		b.tm+=0.2
		b.ytm+=0.02
		b.xtm+=0.005
		b.y+=cos(b.ytm)*0.3
		b.x+=sin(b.xtm)*0.5//*b.xdr
		
		-- collision
		local bi=flr(b.x/8)
		local bj=flr(b.oy/8)
		local pt=level[bj][bi]
		if bi<0 then
			b.xtm=0.5
		elseif bi>xmax-1 then
			b.xtm=0
		elseif pt>=cb.ter_rock and 
					pt<cb.pas_flw1 then
			if sin(b.xtm)>0 then
				b.x-=2
				b.xtm=0
			elseif sin(b.xtm)<0 then
				b.x+=2
				b.xtm=0.5
			end
		end
		
		--player collision
		if(col_bb(pp,b))player_hit(b.x,b.y)
		
		--shoot
		if (b.x<pp.x and 
					sin(b.xtm)>0) or
					(b.x>pp.x and
					sin(b.xtm)<0) then
			if chance(1) then
				local a=atan2(pp.x-b.x,pp.y-b.y)
				local dx=cos(a)*2
				local dy=sin(a)*2
				add_bullet(
					b.x+(dx*2),
					b.y+(dy*2),
					dx,dy,
					100,1,14)
				sfx(19)
			end
		end
	end
end

function damage_bat(b)
	add_flash(b.x,b.y)
	b.hp-=1
	if b.hp<=0 then
		--if(chance(50))add_heart(b.x,b.y)
		game_tm+=time_add_bat
		add_flare(b.x,b.y,time_add_bat)
		del(bats,b)
		total_enim+=1
	end
end

-- ==========
-- scrolling
-- ===================
function init_scroll()
	pp.coin+=cur_lvl_cns
	total_coin+=cur_lvl_cns
	cur_lvl_cns=0
	clear_objects()
	scroll=1
	l_num+=1
	total_lvls+=1
	last_level=copy_table(level)
	if l_num%10==0 then
		l_type="shop"
		init_shop()
	else
		if(l_num==11)cb=biome.desert
		if(l_num==21)cb=biome.ice
		l_type="norm"
		init_level()
	end
end

scr_spd=4
function update_scroll()
	if(scroll==0)return
	if scroll<128 then
		scroll+=scr_spd
		pp.y-=scr_spd
		pp.can_die=true
		shop.y-=scr_spd
		for b in all(blobs)do
			b.y-=scr_spd
		end
			for b in all(bats)do
			b.y-=scr_spd
		end
	else
		scroll=0
	end
end

function draw_scroll()
	for j=0,ymax-1 do
	for i=0,xmax-1 do
		if level[j][i]>1 then
			spr(level[j][i],i*8,
				(j*8)+(128-scroll))
		end
		if last_level[j][i]>1 then
			spr(last_level[j][i],i*8,
				(j*8)-scroll)
		end
		if last_level[j][i]==pas_watr or
					last_level[j][i]==ter_watr then
			spr((flr(l_tm)%4)+pas_watr,
				i*8,j*8-scroll)
		end
	end end
	
	
end

function clear_objects()
	for c in all(coins)do
		del(coins,c)
	end
	for f in all(flares)do
		del(flares,f)
	end
	for b in all(bats)do
		del(bats,b)
	end
	for b in all(bullets)do
		del(bullets,b)
	end
	for f in all(flashes)do
		del(flashes,f)
	end
	--[[
	for h in all(hearts)do
		del(hearts,h)
	end
	]]--
	for b in all(blobs)do
		del(blobs,b)
	end
end

-- ==========
-- perfect
-- ===================
function draw_perfect()
	local ps="perfect!"
	if perfect>14 then
		perfect=0
		return
	end
	pal(12,8+flr(perfect)%8)
	for i=0,6 do
		local y=60
		if(i==flr(perfect)%7)y-=8
		if(i==flr(perfect)%7-1)y-=4
		if(i==flr(perfect)*7+1)y-=4
		spr(68+i,36+(i*8),y)
	end
	print("+"..cur_lvl_cns.." coins!",43,70,12)
	pal()
	perfect+=0.4
end

function draw_flares()
	for f in all(flares) do
		f.tm+=0.5
		f.y-=f.dy
		f.dy*=0.95
		print("+"..f.v,f.x,f.y,
			8+(flr(f.tm)%8))
		if f.dy<0.4 then
			del(flares,f)
		end
	end
end

function add_flare(x,y,v)
	add(flares,{
		x=x,y=y,v=v,tm=0,dy=1
		})
end

-- ==========
-- shop
-- ===================
function init_shop()
	l_type="shop"
	shop={
		x=78,y=200,tm=0,idx=0,
		labels={
		"+"..time_add_shop.." time",
		"+1 water tank",
		"+1 bullet size",
		"+1 bullet distance"
		},
		err_tm=0,
		bought=false,
		bt_tm=0
	}
	level={}
	local gr=cb.ter_gras
	local s_level={
		{0,0,0,0,46,47,0,0},
		{0,0,0,0,44,45,0,0},
		{0,1,1,1,gr,gr,1,1},
		{1,1,1,1,1,1,1,1},
		{1,1,1,1,1,1,1,0},
		{0,1,1,1,1,1,1,0},
		{0,0,1,1,1,0,0,0},
		{0,0,0,1,0,0,0,0}
	}
	for j=0,ymax-1 do
			level[j]={}
		for i=0,xmax-1 do
			level[j][i]=0
			if i>3 and i<12 and
						j>7 and j<16 then
				level[j][i]=s_level[j-7][i-3]
			end
	end end
	
	add_terrain()
end

function draw_shop()
	if scroll!=0 then
		spr(57,shop.x,shop.y)
		return
	end
	-- animate shop guy
	shop.tm+=0.2
	local shop_s=57
	if shop.tm>5 and 
				shop.tm<9 and
				flr(shop.tm)%2==0 then
		shop_s=58
	elseif shop.tm>12 and
								shop.tm<16 then
		if flr(shop.tm)%2==0 then
			shop_s=59
		else
			shop_s=60
		end
	elseif shop.tm>30 then
		shop.tm=0
	end
	spr(shop_s,shop.x,shop.y)
	
	-- bought item
	if shop.bought and
				shop.bt_tm<30 then
		shop.bt_tm+=1
		spr(shop.idx+64,
			64,60-shop.bt_tm)
	end
	
	-- shop box
	//if(shop.bought)return
	if pp.shopping then
		draw_shopping()
	elseif pp.y==shop.y+4 and
				pp.x<shop.x and
				pp.x>shop.x-20 then
		draw_shop_ask()
		pp.can_shop=true
		if btnp(❎) and 
					not pp.shopping and
					not shop.bought then
			pp.shopping=true
			sfx(13)
		else
			shop.bought=false
		end
	else
		if pp.can_shop then
			pp.can_shop=false
			shop.tm=20
		end
		draw_shop_yell()
	end
end

function update_shopping()
	if btnp(🅾️) then
		pp.shopping=false
		shop.tm=20
		shop.err_tm=0
		return
	end
	if shop.err_tm>0 then 
		shop.err_tm-=1
		return
	end
	if btnp(❎) then
		local i=shop.idx
		if(price_lvls[i+1]>4)return
		local p=prices[price_lvls[i+1]]
		if pp.coin>=p then
			pp.coin-=p
			price_lvls[i+1]+=1
			shop.bought=true
			pp.shopping=false
			shop.tm=20
			apply_upgrade(i)
			sfx(13)
		else
			shop.err_tm=35
			sfx(14)
		end
	end
	if btnp(⬅️) and shop.idx>0 then
		shop.idx-=1
		shop.err_tm=0
		sfx(13)
	elseif btnp(➡️) and shop.idx<3 then
		shop.idx+=1
		shop.err_tm=0
		sfx(13)
	end
end

function apply_upgrade(i)
	if i==0 then
	-- +1 hearts
		--pp.hp_max+=1
		game_tm+=time_add_shop
	elseif i==1 then
	-- +1 water tank
		pp.tanks+=1
	elseif i==2 then
	-- +1 bullet size
		pp.bullet_size+=1
	elseif i==3 then
	-- +1 bullet dist
		pp.bullet_dist+=5
	end
end

function draw_shopping()
	rectfill(22,25,112,68,1)
	rect(22,25,112,68,7)
	--item
	for i=0,3 do
		local p=nil
		if price_lvls[i+1]<5 then
			p=prices[price_lvls[i+1]]
		end
		draw_shop_item(i+64,30+(i*22),
			30,p,(i==shop.idx))
	end
	--label
	if shop.err_tm>0 then
		if flr(shop.tm)%2==0 then
			print("need more coins",
				38,50,7)
			end
	elseif price_lvls[shop.idx+1]>4 then
		print("sold out",52,50,7)
	else
		local ll=shop.labels[shop.idx+1]
		print(ll,66-#ll*2,50,7)
	end
	
	--actions
	print("❎:buy 🅾️:cancel",
		36,60,13)	
	
	spr(61,72,68)
end

function draw_shop_item(
s,x,y,p,active)
	if not active then
		pal(2,0)
		pal(4,0)
		pal(6,0)
		pal(7,0)
		pal(8,0)
		pal(9,0)
		pal(10,0)
		pal(12,0)
		pal(15,0)
	end
	--icon
	spr(s,x,y)
	
	--price
	if p==nil then
		print("----",x-3,y+11)
	else
		spr(48,x-6,y+10)
		local b=p_max_coin
		local s=""
		while b>p and b>10 do
			b=b/10
			if(b>p)s=s.."0"
		end
		print(s..p,x+2,y+11)
	end
	pal()
end

function draw_shop_ask()
	rectfill(35,55,107,68,1)
	rect(35,55,107,68,7)
	spr(61,72,68)
	print("press ❎ to shop",
		40,60,7)
end

function draw_shop_yell()
	if shop.tm<10 then
		rectfill(50,55,82,68,1)
		rect(50,55,82,68,7)
		spr(61,72,68)
		print("hey!",60,60,7)
	elseif shop.tm<20 then
		rectfill(40,55,102,68,1)
		rect(40,55,102,68,7)
		spr(61,72,68)
		print("buy something!",
			45,60,7)
	end
end

-- ==========
-- first level
-- ===================

function init_first()
	l_type="frst"
	first={tm=0,y=0}
	level={}
	local s_level={
		{1,1,1,1,1,1,1,1},
		{1,1,1,1,1,1,1,1},
		{0,1,1,1,1,1,1,0}
	}
	for j=0,ymax-1 do
			level[j]={}
		for i=0,xmax-1 do
			level[j][i]=0
			if i>3 and i<12 and
						j>6 and j<10 then
				level[j][i]=s_level[j-6][i-3]
			end
	end end
	
	add_terrain()
end

function draw_first()
	first.tm+=0.01
	first.y+=cos(first.tm)*0.3
	print("its ok to jump down",
		26,first.y+101,1)
	print("its ok to jump down",
		26,first.y+100,7)
end



-- logo
function draw_logo()
	if	logo.t<25 then
		logo.t+=0.4
		if logo.t<0 or logo.t>17 then
			return
		end
	else
		show_logo=false
		reset()
		return
	end
	
	for i=0,logo.w do
		local y=logo.y
		if(i+1==flr(logo.t))y-=2
		if(i==flr(logo.t))y-=7
		if(i==ceil(logo.t))y-=2
		if y != logo.y then
			pal(10,logo.p[i+1])
		end
		spr(i+113,logo.x+(i*8),y)
		pal()
	end
	--[[
	if	logo.snd%8==0 then
		sfx(0)
	end
	]]--
	//logo2.snd+=1
end

-- ==========
-- parallax
-- ===================
-- original parallax code by
-- andy latham (andylatham82)
-- cart: 25597
--
-- slightly modified for my
-- usecase :)
function init_parallax()
	--tables to hold map pieces
	//map_bg={} --bg layer 1
	map_mg={}	--mg layer 2
	map_fg={} --fg layer 3
	
	--spawn initial map. index i
	--creates copy of map at right
	--of screen, ready to move into
	--view.
	for i=0,1 do
		//spawn_map(i*128,0,1)
		spawn_map(i*128,0,1)
		spawn_map(i*128,0,2)
	end
end

function update_parallax()
	//foreach(map_bg,update_map)
	foreach(map_mg,update_map)
	foreach(map_fg,update_map)
end

function draw_parallax()
		//foreach(map_bg,draw_map)
		foreach(map_mg,draw_map)
		foreach(map_fg,draw_map)
end

function update_map(m)
	m.x-=m.l --move map to left
	
	--if map off edge of screen
	if m.x<-128 then
		//if m.l==1 then
		//	del(map_bg,m) --delete map
		//end
		if m.l==1 then
			del(map_mg,m) --delete map
		end
		if m.l==2 then
			del(map_fg,m)
		end
		--add new map to right
		spawn_map(16*8,0,m.l)
	end
end

function spawn_map(x,y,l)
	local m={}
	m.x=x
	m.y=y
	m.l=l
	--add map bit to correct layer
	//if l==1 then
	//	add(map_bg,m)
	//end
	if l==1 then
		add(map_mg,m)
	end
	if l==2 then
		add(map_fg,m)
	end
end

function draw_map(m)
	//if m.l==1 then
	//	map(0,0,m.x,m.y,16,16)
	//end
	if m.l==1 then
		map(16,0,m.x,m.y,16,16)
	end
	if m.l==2 then
		map(32,0,m.x,m.y,16,16)
	end
end
-->8
-- player

-- ==========
-- player
-- ===================
function init_player()
	--player_start_points should be
	-- initialized by now
	local idx=rand(1,#player_start_points)
	local pt=player_start_points[idx]
	pp={
		x=(pt.i*8)+4,
		y=(pt.j*8)+4,
		w=3,h=6,
		drr=1, -- -1:left,1:right
		drr_y=0,
		tm=0,
		jump_press=false,
		jump=0,
		tanks=2,
		landed=false,
		dy=0,
		can_die=false,
		coin=0,
		water=3,
		bullet_dist=10,
		bullet_size=0.5,
		shoot=0,
		w_tm=0,
		--hp=3,
		--hp_max=3,
		hit=0,
		hit_dx=0,
		hit_dy=0,
		shopping=false,
		can_shop=false,
		d_tm0=0, --die animation
		d_tm1=0, --die rest animation
		d_cntr=false
	}
end

function draw_player()
	local pdx=pp.x-pp.w/2
	local pdy=(pp.y-pp.h/2)+1
	
	if(pp.can_die)pal(7,8)
	spr(33+pp.drr,pdx,pdy)
	if pp.tm>0 then
		spr(36+(flr(pp.tm)%2),
			pdx,pdy)
	else
		spr(35,pdx,pdy)
	end
	pal()
	--off screen
	if pp.x<0 then
		spr(38,0,pp.y)
	elseif pp.x>128 then
		spr(39,120,pp.y)
	end
	
	--water splash
	if touch_water() then
		spr((flr(l_tm)%3)+40,
			pp.x-4,pp.y-4)
	end
	
	--bb
	//draw_bb(pp)
end

function update_player()
	--[[
	if pp.y>128+8 then
		if pp.can_die then
			--pp.hp-=1
			game_tm-=time_loss
			//set_pause()
			set_hit()
		end
		init_scroll()
		return
	end
	]]--
	
	if pp.hit>0 then
		pp.hit-=1
		if place_free(pp,pp.hit_dx,0) then
			pp.x+=pp.hit_dx
		end
		if place_free(pp,0,pp.hit_dy) then
			pp.y+=pp.hit_dy
		end
		if(pp.hit==3)set_hit()
		return
	end
	
	-- left/right movement
	local move=false
	if btn(⬅️) then
		pp.drr=-1
		move=true
	elseif btn(➡️) then
		pp.drr=1
		move=true
	end
	if move then
		pp.tm+=0.2
		if place_free(pp,1*pp.drr,0) then
			pp.x+=pp.drr
		end
	else
		pp.tm=0
	end
	
	-- vertical pointing
	pp.drr_y=0
	if(btn(⬆️))pp.drr_y=-1
	if(btn(⬇️))pp.drr_y=1
	
	player_jump()
	player_fall()
	player_shoot()
	touch_coin()
	touch_time()
	--touch_heart()
	
	if(pp.w_tm>0)pp.w_tm-=1
	
	if touch_water() and 
				pp.w_tm==0 then
		pp.w_tm=5
		pp.water=min(
			pp.water+1,
			pp.tanks*3
		)
	end
end

jump_t=0
jump_t_max=7
p_max=3
p_max_d=4
p_accel=0.3
function player_jump()
	if btn(🅾️) then
		if not pp.jump_press and 
					(pp.jump<p_jump_min or 
					flr(pp.water/3)>0) then
			if pp.water>2 and pp.jump>=p_jump_min then
				pp.water-=3
			end
			pp.jump+=1
			jump_t=jump_t_max
			add_sprinkles(pp.x,pp.y)
			sfx(1)
		end
		pp.jump_press=true
		if jump_t>0 then
			pp.dy=-p_max
		end
		jump_t=max(0,jump_t-1)
	elseif pp.jump_press==true then
		pp.jump_press=false
		jump_t=0
	end
end

function player_fall()
	pp.dy=min(p_max_d,pp.dy+p_accel)
	if pp.dy<0 then
		if not place_free(pp,0,min(-1,pp.dy)) then
			pp.dy=1
			sfx(4)
		end
	elseif place_free(pp,0,max(1,pp.dy)) then
		pp.landed=false
	else
		if not pp.landed then
			pp.jump=0
			pp.can_die=false
			add_stomp(pp.x,pp.y)
			pp.y=(flr(pp.y/8)*8)+4
			sfx(6)
		end
		pp.landed=true
		pp.dy=0
	end
	pp.y+=pp.dy
end

function player_shoot()
	// if(l_type=="shop")return
	if pp.shoot>0 then
		pp.shoot-=1
		return
	end
	if btn(❎) then
		pp.shoot=5
		sfx(10)
		local bx=pp.x+(pp.bullet_size*pp.drr)
		local by=pp.y
		local bdx=pp.drr*3
		local bdy=0
		if pp.drr_y !=0 then
			bx=pp.x
			by=pp.y+(5*pp.drr_y)
			bdx=0
			bdy=pp.drr_y*3
		end
		add_bullet(
			bx,
			by,
			bdx,
			bdy,
			pp.bullet_dist,
			pp.bullet_size,
			12)
	end
end

function player_hit(x,y)
	if hit>0 or 
				pp.hit>0 or 
				pp.can_die then
		return
	end
	-- pp.hp-=1
	game_tm-=time_loss
	pp.hit=5
	//set_hit()
	if x>=pp.x then
		pp.hit_dx=-2
	else
		pp.hit_dx=2
	end
	if y>=pp.y then
		pp.hit_dy=-2
	else
		pp.hit_dy=2
	end
	sfx(16)
end

function player_dead()
	if pp.d_tm0<3 then
		pp.d_tm0+=0.1
	else
		pp.d_tm1+=0.01
	end
	//elseif pp.d_cntr then
	//	pp.d_tm1+=0.01
	//end
	if pp.d_cntr==false then
		pp.d_cntr=true
		if flr(pp.x) != 64 then
			pp.d_cntr=false
			pp.x+=sgn(64-pp.x)*0.5
		end
		if flr(pp.y) != 84 then
			pp.d_cntr=false
			pp.y+=sgn(84-pp.y)*0.5
		end
	else
		pp.y+=sin(pp.d_tm1)*0.4
	end
	
	if btnp(❎) then
		if pp.d_tm1>0.5 then
			reset()
		elseif not pp.cntr then
			pp.cntr=true
			pp.x=64
			pp.y=84
			pp.d_tm1=0.1
		elseif pp.d_tm1<0.5 then
			pp.d_tm1=0.6
		end
	end
end

function draw_player_dead()
	spr(100+flr(pp.d_tm0),
		pp.x-4,pp.y-4)
		
	print("~time's up~",42,12,5)
	print("~time's up~",42,11,7)
	
	-- totals
	if pp.d_tm1>0.1 then
		print("~totals~",48,29,5)
		print("~totals~",48,28,7)
	end
	-- total coins
	if pp.d_tm1>0.2 then
		print("coins:",43,39,5)
		print("coins:",43,38,7)
		print(total_coin,70,39,9)
		print(total_coin,70,38,10)
	end
	-- total enemies
	if pp.d_tm1>0.3 then
		print("enemies:",35,49,5)
		print("enemies:",35,48,7)
		print(total_enim,70,49,2)
		print(total_enim,70,48,8)
	end
	-- total perfects
	if pp.d_tm1>0.4 then
		print("perfects:",31,59,5)
		print("perfects:",31,58,7)
		print(total_perf,70,59,13)
		print(total_perf,70,58,12)
	end
	-- total levels
	if pp.d_tm1>0.5 then
		print("levels:",39,69,5)
		print("levels:",39,68,7)
		print(total_lvls,70,69,3)
		print(total_lvls,70,68,11)
		print("press ❎ to continue",
			24,101,1)
		print("press ❎ to continue",
			24,100,7)
	end
end

function touch_coin()
	for c in all(coins)do
		--[[
		if flr(pp.x/8)==c.i and
					flr(pp.y/8)==c.j then
		]]--
		if col_bb(pp,c) then
					
			del(coins,c)
			--pp.coin+=c.val
			cur_lvl_cns+=c.val
			--total_coin+=c.val
			add_flare(pp.x,pp.y,c.val)
			
			if #coins==0 then
				perfect=1
				total_perf+=1
				pp.coin+=cur_lvl_cns
				sfx(2)
			else
				if c.val==val_green then
					sfx(17)
				elseif c.val==val_red then
					sfx(18)
				else
					sfx(12)
				end
			end
			if pp.coin>p_max_coin then
				pp.coin=p_max_coin
			end
			return
		end
	end
end

--[[
function touch_heart()
	for h in all(hearts)do
		if h.x>pp.x-4 and h.x<pp.x+4 and
					h.y>pp.y-4 and h.y<pp.y+4 then
			pp.hp+=1
			if(pp.hp>pp.hp_max)pp.hp=pp.hp_max
			add_flare(pp.x-4,pp.y,"♥")
			del(hearts,h)
		end
	end
end
]]--

function touch_time()
	for t in all(times)do
		--[[
		if t.x>pp.x-8 and t.x<pp.x+0 and
					t.y>pp.y-8 and t.y<pp.y+0 then
		]]--
		if col_bb(pp,t) then
			game_tm+=time_add
			add_flare(pp.x,pp.y,time_add)
			del(times,t)
			sfx(22)
		end
	end
end

function touch_water()
	if pp.x>0 and pp.x<128 and
				pp.y>0 and pp.y<128 then
		local pi=flr(pp.x/8)
		local pj=flr(pp.y/8)
		return level[pj][pi]==pas_watr
	else
		return false
	end
end

function add_sprinkles(x,y)
	add(sprinkles,{
		x=x+2,y=y,dx=1,dy=1,ddy=0.1,
		sp=43,tm=0
	})
	add(sprinkles,{
		x=x-2,y=y,dx=-1,dy=1,ddy=0.1,
		sp=43,tm=0
	})
	add(sprinkles,{
		x=x+2,y=y,dx=1,dy=-1,ddy=0.1,
		sp=43,tm=0
	})
	add(sprinkles,{
		x=x-2,y=y,dx=-1,dy=-1,ddy=0.1,
		sp=43,tm=0
	})
end

function add_stomp(x,y)
	add(sprinkles,{
		x=x+2,y=y+4,dx=1,dy=0,ddy=0,
		sp=63,tm=8
	})
	add(sprinkles,{
		x=x-4,y=y+4,dx=-1,dy=0,ddy=0,
		sp=63,tm=8
	})
end

-->8
-- level

-- ==========
-- level generation
-- ===================
function init_level()
	-- clear level
	-- all cells initialized to 0.
	-- solids assigned 1, then are
	-- set to a terrain or passive
	-- value.
	l_type="norm"
	perfect=0
	local too_small=true
	while too_small do
		level={}
		for j=0,ymax-1 do
			level[j]={}
		for i=0,xmax-1 do
			level[j][i]=0
		
			if j>cell_pad_v and 
						j<ymax-(1+cell_pad_v) and
						i>cell_pad_h and 
						i<xmax-(1+cell_pad_h) then
				if chance(cell_chance) then
					level[j][i]=1
				end
			end
		end end
	
		too_small = cell_auto()
		-- cell_auto will return if
		-- level is too small. if so,
		-- restart this process
	end
	add_terrain()
	add_coins()
	add_bats()
	add_blobs()
	add_times()
end

function add_terrain()
	--do top
	if last_level then
	for i=0,xmax-1 do
		if level[0][i]==0 then
			--if below water
			if last_level[ymax-1][i]==ter_pipe or
						last_level[ymax-1][i]==ter_watr or
						last_level[ymax-1][i]==pas_watr then
				level[0][i]=pas_watr
			end
		end
	end
	end
	
	-- player_start_points is onlu
	-- used on ititial player
	-- placement.
	-- jk - also use this for blobs
	player_start_points={}
	

	
	for j=1,ymax-2 do
	for i=1,xmax-2 do
		--if solid
		if level[j][i]==1 then
			level[j][i]=cb.ter_rock
			--add random blocks
			if chance(10) then
				level[j][i]=cb.ter_bloc
			elseif chance(10) then
				level[j][i]=ter_pipe
			end
			--if top rock
			if level[j-1][i]==0 then
				level[j][i]=cb.ter_gras
				if chance(10) then
					level[j][i]=cb.ter_bloc
				end
				--add potential start point
				add(player_start_points,{
					j=j-1,i=i
				})
				--add flower
				if chance(30) then
					level[j-1][i]=
						rand(cb.pas_flw1,cb.pas_flw2)
				--add tree
				elseif chance(30) then
					local rh=rand(1,3)
					for k=1,rh do
						level[j-k][i]=cb.pas_stem
					end
					level[j-(rh+1)][i]=cb.pas_tree
				end
			--if below grass
			elseif level[j-1][i]==cb.ter_gras then
				if level[j][i]==cb.ter_rock then
					level[j][i]=cb.ter_roc2
				else
					level[j][i]=cb.ter_blc2
				end
			--if below water
			elseif level[j-1][i]==ter_pipe or
										level[j-1][i]==ter_watr then
				level[j][i]=ter_watr
			end
		elseif level[j][i]==0 then
			--if below water
			if level[j-1][i]==ter_pipe or
						level[j-1][i]==ter_watr or
						level[j-1][i]==pas_watr then
				level[j][i]=pas_watr
			end
		end
	end end
	
	--do bottom
	for i=0,xmax-1 do
		if level[ymax-1][i]==0 then
			--if below water
			if level[ymax-2][i]==ter_pipe or
						level[ymax-2][i]==ter_watr or
						level[ymax-2][i]==pas_watr then
				level[ymax-1][i]=pas_watr
			end
		end
	end
end

function cell_auto()
	for k=0,cell_autos do
		//print_level()
		local a=copy_table(level)
		for j=1,ymax-2 do
		for i=1,xmax-2 do
			-- get surrounding 1's
			local n=get_surr(j,i)
			-- if solid and few neighbors
			if level[j][i]==1 and
						n<=cell_death then
				a[j][i]=0
			end
			-- if empty and many neighbors
			if level[j][i]==0 and
						n>=cell_birth then
				a[j][i]=1
			end
		end end
		level=copy_table(a)
	end
	-- check if empty level
	local num=0
	for j=0,ymax-1 do
	for i=0,xmax-1 do
		num+=level[j][i]
	end end
	return num<1
end

function get_surr(j,i)
	local imin=max(i-1,0)
	local imax=min(i+1,xmax-1)
	local jmin=max(j-1,0)
	local jmax=min(j+1,ymax-1)
	local n=0
	for jj=jmin,jmax do
	for ii=imin,imax do
		if(level[jj][ii]==1)n+=1
	end end
	if(level[j][i]==1)n-=1
	return n
end

function draw_level()
	l_tm+=0.2
	for j=0,ymax-1 do
	for i=0,xmax-1 do
		if level[j][i]>1 then
			spr(level[j][i],i*8,
				(j*8)-scroll)
		end
		if level[j][i]==pas_watr or
					level[j][i]==ter_watr then
			spr((flr(l_tm)%4)+pas_watr,
				i*8,j*8-scroll)
		end
	end end
	draw_coins()
	draw_times()
end

function add_coins()
	coins={}
	for j=0,ymax-2 do
	for i=0,xmax-1 do
		if level[j][i]==0 and
					chance(coin_chance) then
			level[j][i]=-1 -- keep track of cells with items
			local sp=s_coin
			local val=val_yellow
			if chance(10) then
				sp=s_coin2
				val=val_green
			elseif chance(10) then
				sp=s_coin3
				val=val_red
			end
			add(coins,{
				x=i*8+4,y=j*8+4,w=8,h=8,
				tm=0,val=val
			})
		end
	end end
end

function draw_coins()
	for c in all(coins)do
		local cx=c.x-c.w/2
		local cy=c.y-c.h/2
		c.tm+=0.1
		if c.val==val_green then
			pal(9,3)
			pal(10,11)
		elseif c.val==val_red then
			pal(9,2)
			pal(10,8)
		end
		spr((flr(c.tm)%4)+52,cx,cy)
		pal()
		--draw_bb(c)
	end
end

function add_times()
	times={}
	if not chance(100) then
		return
	end
	local nt=rand(1,2)
	local i=50*nt
	while i>0 do
		local rx=rand(0,xmax-1)
		local ry=rand(0,ymax-2)
		if level[ry][rx]==0 then
			level[ry][rx]=-1
			add(times,{
				x=rx*8+4,y=ry*8+4,
				w=8,h=8,
				off=0,tm=0})
			i-=50
		end
		i-=1
	end
end

function draw_times()
	for t in all(times)do
		local tx=t.x-t.w/2
		local ty=t.y-t.h/2
		t.tm+=0.01
		t.off=sin(t.tm)
		spr(91,tx,ty+flr(t.off*2))
	end
end

__gfx__
00000000111111110000000000000001110000000000000000000000dddddddd000000000000000ddd0000000000000000000000000000000000000000000000
00000000111111110000000000000111111000000000000000000000dddddddd0000000000000dddddd000000000000000000000000000000000000000000000
00000000111111110000000000001111111100000000000000000000dddddddd000000000000dddddddd00000000000000000000000000000000000000000000
00000000111111110000000000011111111110000000001111000000dddddddd00000000000dddddddddd000000000dddd000000000000000000000000000000
00000000111111110000000000011111111110000000111111110000dddddddd00000000000dddddddddd0000000dddddddd0000000000000000000000000000
00000000111111110011110000111111111111000001111111111000dddddddd00dddd0000dddddddddddd00000dddddddddd000000000000000000000000000
00000000111111110111111001111111111111000111111111111000dddddddd0dddddd00ddddddddddddd000dddddddddddd000000000000000000000000000
00000000111111111111111111111111111111101111111111111110ddddddddddddddddddddddddddddddd0ddddddddddddddd0000000000000000000000000
011111110555555003113113035535530131b1b00555555005cccc5000000000000000000004400000ffff0000cc7c0000cccc0000c7770000cccc0000000000
1011100050dddd051311300353dd3d033b1b1330500ff00550cccc050000000000000000000f90000f0000f00077c70000cc7c0000cccc000077770000077700
d05101dd5d0dd0d5d05301d35d0dd3d3b331333d50f00f0550cccc05000000000000000000044000f00f000f00cccc000077770000cccc0000cccc00007ccc70
dd0011dd5dd00dd5dd0311dd53d03dd533b3b13b5f00c0f55fccccf50000000000e0e00000094000f0f0007f00cccc0000cccc00007c770000cccc00007ccc70
dd05011d5dd00dd5dd05011d5dd03dd3b303033d5fccccf55fccccf500000000000a000000044000f000707f00cccc0000cccc0000cccc00007cc700007ccc70
d01550115d0dd0d5d01550115d0dd0d5d3135b3350cccc0550cccc050008000000e0e00000099000f000077f00cccc0000cccc0000cccc0000c77c00006ccc60
0111550150dddd050111550150dddd050113550350cccc0550cccc0500898000000300000004f0000f0777f000c7770000cccc0000cccc0000cccc0000066600
111111100555555011111110055555501311311305cccc5005cccc5000080000003000000004400000ffff0000cccc00007c770000cccc0000cccc0000000000
7777000000000000777700000000000000000000000000000008000000008000070000c00c0000000c0007000000000004000000000000400000000000000000
777700000000000077770000000000000000000000000000008800000000880000c70c007000007c0000c000000000000400000000000040444d44d444d4d444
c7c70000007777007c7c0000000000000000000000000000088888888888888000000000000000000000000c000070000400000000000040040d00d000d0d040
7777000000777700777700000000000000000000000000008888888888888888000000000000000070000000000777000c00b00000009040000d00d00000d000
0000000000c77c0000000000700700007007000070070000088888888888888000000000000000000000000000007000ffddddfdffdffdff040d00d000000040
00000000007777000000000070070000700000000007000000880000000088000000000000000000000000000000000004ddd04d04dd0d40040000d000000040
000000000000000000000000000000000000000000000000000800000000800000000000000000000000000000000000000d0000000d00000400000000000040
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000040040000400400000000000040
00000000000000000000000000000000009999000009900000099000000990000000000000000000000000000000000000000000071117000000000000000000
000aaa000000a0000000a0000000a00009aaaa90009aa900009aa900009aa900088088000000000000f0ff0000f0ff0000f0ff00007117000007770000000000
00a000a0000a0a000000a000000a0a009aaaaaa909aaaa90009aa90009aaaa908288888000f6ff0000666600606666060066660000071700000c7c0000007700
00a009a0000a9a000000a000000a9a009aaaa9a909aa9a90009aa90009a9aa908288888000969600009696006096960600969600000070000007070000007700
00a099a0000a9a000000a000000a9a009aaaa9a909aa9a90009aa90009a9aa900828880000666600006666000066660060666606000000000000000000000000
000aaa000000a0000000a0000000a0009aa99aa909aaaa90009aa90009aaaa900088800000666600006666000066660060666606000000000000600000000000
0000000000000000000000000000000009aaaa90009aa900009aa900009aa9000008000000666600006666000066660000666600000000000000000000000000
00000000000000000000000000000000009999000009900000099000000990000000000000600600006006000060060000600600000000000000000000000000
07000000070000000700000007000000000000000000000000000000000000000000000000000000000000004444400044444000444440000044000044004400
77700000777000007770000077700000077777000777770007777700077777000777770000777700077777704fff40004666400046664000004640004f446400
07044444070077700700000007000000077cc770077ccc00077cc770077ccc00077ccc00077ccc000cc77cc004f4000004f4000004640000444664004ff66400
0004fff4000700070000ccc000000000077777c007777000077777c0077770000777700007700000000770000464000004f4000004f400004ff444004f446400
00004f400007cc077770ccc007770000077ccc00077cc000077c7700077cc000077cc00007700000000770004666400046f640004fff400004f4000044004400
000046400007ccc7c7c0ccc00c7c0c0c07700000077777000770c77007700000077777000c777700000770004444400044444000444440000044000000000000
000466640006ccc670700000070700000cc000000ccccc000cc00cc00cc000000ccccc0000cccc00000cc0000000000000000000000000000000000000000000
00044444000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000700000007000000000000000000000000000000000000000000000000000000000000004444444000000000000000000000000000000000
77700000000000007770777077700000000000000000000000000000000000000011100000022000000000004077004000000000000000000000000000000000
07000000000000000700c7c0070000000111111000111100001111000011110001888100002ee200002222000470040000000000000000000000000000000000
00080800000000000000707000000000188ee8810188e81000188100018e88100187871002eeee2002eeee200040400000000000000000000000000000000000
00828880000000000000000007770000011ee110001ee100001ee100001ee1001888881002e7e7202eeeeee2004f400000000000000000000000000000000000
0082888000000000000006000c7c0c0c000110000001100000011000000110001888110002eeee202eee7e7204fff40000000000000000000000000000000000
00088800000000000000000007070000000000000000000000000000000000001811000000222200022222204fffff4000000000000000000000000000000000
00008000000000000000060000000000000000000000000000000000000000000100000000000000000000004444444000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000007000000067000000000000000000000ddd00000777000007770000077700000777000007770000077700
00000000000000000000000000000000007777000006777000077770000767700000000000d000d000700070007000700070007000700070007c0c700070c070
00000000000000000000000000000000007777000077777000776770007777700000000000d000d000700070007000700070cc70007c0070007ccc70007ccc70
00000000000000000000000000000000006767000077670007777770007767700000000000d000d0007cc07000700c70007ccc70007ccc70007ccc70007ccc70
00000000000000000000000000000000007777000077770007077000070700000000000000100010006ccc60006ccc60006ccc60006ccc60006ccc60006ccc60
00000000000000000000000000000000007007000070070007007000070700000000000000011100000666000006660000066600000666000006660000066600
00000000000000000000000000000000007007000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa000000000000000000000000000000000000000000000000000000000
000000000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa00000000000000000000000000000000000000000000000000000000
00000000aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa00000000000000000000000000000000000000000000000000000000
00000000aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa00000000000000000000000000000000000000000000000000000000
00000000aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa00000000000000000000000000000000000000000000000000000000
00000000aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa00000000000000000000000000000000000000000000000000000000
00000000aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa00000000000000000000000000000000000000000000000000000000
000000000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa00000000000000000000000000000000000000000000000000000000
011111110555555003113113035535530131b1b000000000000000000004400000ffff0000000000000000000000000000000000000000000000000000000000
1011100050dddd051311300353dd3d033b1b13300000000000000000000f90000f0000f000000000000000000000000000000000000000000000000000000000
d05101dd5d0dd0d5d05301d35d0dd3d3b331333d000000000000000000044000f00f000f00000000000000000000000000000000000000000000000000000000
dd0011dd5dd00dd5dd0311dd53d03dd533b3b13b0000000000e0e00000094000f0f0007f00000000000000000000000000000000000000000000000000000000
dd05011d5dd00dd5dd05011d5dd03dd3b303033d00000000000a000000044000f000707f00000000000000000000000000000000000000000000000000000000
d01550115d0dd0d5d01550115d0dd0d5d3135b330008000000e0e00000099000f000077f00000000000000000000000000000000000000000000000000000000
0111550150dddd050111550150dddd050113550300898000000300000004f0000f0777f000000000000000000000000000000000000000000000000000000000
111111100555555011111110055555501311311300080000003000000004400000ffff0000000000000000000000000000000000000000000000000000000000
01111111055555500611611676d67d70767676700000000000000000000770000077770000000000000000000000000000000000000000000000000000000000
101110005066660516116006dddd7777677777770000000000000000000770000777707000000000000000000000000000000000000000000000000000000000
d05101dd56066065d05601d67d7d7dc7707777c70000000000000000000470007776070700000000000000000000000000000000000000000000000000000000
dd0011dd56600665dd0611dddddc07d76c7c07070000000000e070000009d000776776d700000000000000000000000000000000000000000000000000000000
dd05011d56600665dd05011dd07ddc06607ccc0600000000000a0000000dd000d060766700000000000000000000000000000000000000000000000000000000
d015501156066065d0155011dddd70d66c0c70c6000700000070700000099000d000766700000000000000000000000000000000000000000000000000000000
011155015066660501115501ddddddd667c607c60079700000636000000df0000d7d7dd700000000000000000000000000000000000000000000000000000000
11111110055555501111111067606760676067600668660006366600000dd00007dddd0000000000000000000000000000000000000000000000000000000000
011111110555555009ff9ff90fffff5f0fffff9f00000000003003000004400000ffff0000000000000000000000000000000000000000000000000000000000
1011100050ffff05f9ff900959ff9dfff99ff9f90000000000b03b00000f90000f0000f000000000000000000000000000000000000000000000000000000000
d05101dd5f0ff0f5f9f90ff9fffff9f99ffff999000000000003330300044000f00f000f00000000000000000000000000000000000000000000000000000000
dd0011dd5ff00ff5ff99fff9f9ff9ff5ff99fff9000000000300b30b00094000f0f0007f00000000000000000000000000000000000000000000000000000000
dd05011d5ff00ff5df090ffdfdff9ff9f99f09ff40000400b330333000044000f000707f00000000000000000000000000000000000000000000000000000000
d01550115f0ff0f5d0155ff1fd0fd0f5ff9950f90400400033b0330000099000f000077f00000000000000000000000000000000000000000000000000000000
0111550150ffff050111550150dddd0509ff55f100440400b3303b000004f0000f0777f000000000000000000000000000000000000000000000000000000000
11111110055555501111111005555550191191900040000033b033000004400000ffff0000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000a000000000770077707770000077707770777000000000000444440077707770000000000777000777000777000ddd0000000000000000000077007770
00000a0a00077700070070707070000070707070707000000000000466640070007000000000000c7c000c7c007c0c70d000d000000000000000000007007070
00000a9a00000000070070707070000070707070707000000000000046400077707770000000000707000707007ccc70d000d000000000000000000007007070
00000a9a0007770007007070707000007070707070700000000000004f400000700070000000000000000000007ccc70d000d000000000000000000007007070
000000a0000000007770777077700000777077707770000000000004fff40077707770000000000060000060006ccc6010001000000000000000000077707770
00000000000000000000000000000000000000000000000000000004444400000000000000000000000000000006660001110000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111110111111111111111111111011111111111111111111171111111111111111111110111111111111117000000000000000
00000000000000000000007111111100011111111111111111110001111111111111111111777111111111111111111100011111111111117000000000000000
00000000000000000000007111111110100000111111111111111011000111111111111111171111111111111111111110111111111111117000000000000000
00000000000000000000007111111111100000111111111111111110111011111111111111111cc1cc1111111111111111111111111111117000000000000000
00000000000000000000007111111111110001111111111111111110001011111111111111777cc1cc1111111111111110001111111111117000000000000000
00000000000000000000007111111111110001111111111111111110000011111111111111c7c111111111111111111110001010111111117000000000000000
00000000000000000000007111111111100000111111111111111110000011111111111111717111111111111111111110101111111111117000000000000000
00000000000000000000007111111111100000111111111111111111000111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111100011000100010001111110001100010001000111111aaa117771777177711111100011000100010001117000000000000000
0000000000000000000000711101110101010111010111110111010101011101011111a111a17171711171711111011101010101110101117000000000000000
0000000000000000000000711101100101010001010111110110010101000101011111a119a17171777171711111011001010100010101117000000000000000
0000000000000000000000711101000101011101010111110100010101110101011111a199a17171117171711111010001010111010101117000000000000000
00000000000000000000007111100011000100010001111110001100010001000111111aaa117771777177711111100011000100010001117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111771111117771717177717771111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111711171111111711717177717171111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111117771171111111711717171717771111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111711171111111711717171717111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111777111117711177171717111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
0000000000000000000000711111111111111ddddd111111ddd1d1d1d1d111111ddddd1111111dd1ddd1dd111dd1ddd1d1111111111111117000000000000000
000000000000000000000071111111111111dd1d1dd11d11d1d1d1d1d1d11111dd111dd11d11d111d1d1d1d1d111d111d1111111111111117000000000000000
000000000000000000000071111111111111ddd1ddd11111dd11d1d1ddd11111dd1d1dd11111d111ddd1d1d1d111dd11d1111111111111117000000000000000
000000000000000000000071111111111111dd1d1dd11d11d1d1d1d111d11111dd111dd11d11d111d1d1d1d1d111d111d1111111111111117000000000000000
0000000000000000000000711111111111111ddddd111111ddd11dd1ddd111111ddddd1111111dd1d1d1d1d11dd1ddd1ddd11111111111117000000000000000
00000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
70000000888800000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
07000000888800000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117000000000000000
00700000888800000000007777777777777777777777777777777777777777777777777777111777777777777777777777777777777777777000000000000000
0700000088880000000000000000000000000000000000000000000000099000040000d000711740000000000000000000000000000000000000000000000000
700000008888000000000000000000000000000000000000000000000004f0000400000000071740000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000440000400000000007040000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000440000400000000000040000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000f90000400000000000040000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000440000407777000000040f6ff00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000940000c07777000009040969600000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000044000ffd7c7cdffdffdff666600000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000800000009900004d7777d04dd0d40666600000008000000000000000000000000000000000000
000000000000000000000000000000000000000000000000008980000004f00000070070000d0000666680000089800000000000000000000000000000000000
00000000000000000000000000000000000000000000000000080000000440000407007004000040600600000008000000000000000000000000000000000000
00111000000000000000000000000000000000000131b1b00131b1b00131b1b00131b1b00131b1b00131b1b00131b1b000000000000000000000000000000000
11111100000000000000000000000000000000003b1b13303b1b13303b1b13303b1b13303b1b13303b1b13303b1b133000000000000000000000000000000000
1111111000000000000000000000000000000000b331333db331333db331333db331333db331333db331333db331333d00000000000000000000000000000001
111111110000000000000000000000000000000033b3b13b33b3b13b33b3b13b33b3b13b33b3b13b33b3b13b33b3b13b00000000000000000000000000000011
1111111100000000000000000000000000000000b303033db303033db303033db303033db303033db303033db303033d00000000000000000000000000000011
1111111110000000000000000000011110000000d3135b33d3135b33d3135b33d3135b33d3135b33d3135b33d3135b3300000000000001111000011110000111
11111111100000000000000000001111110000000113550301135503011355030113550301135503011355030113550300000000000011111100111111001111
11111111110000000000000000011111111000001311311313113113131131131311311313113113131131131311311300000000000111111111111111111111
111111111110000000000000001111111131b1b00311311303113113035535530311311303113113031131130311311300000000001111111111111111111111
111111111110000000000000111111113b1b1330131130031311300353dd3d031311300313113003131130031311300300000000111111111111111111111111
11111111111000000000000111111111b331333dd05301d3d05301d35d0dd3d3d05301d3d05301d3d05301d3d05301d300000001111111111111111111111111
1111111111111000000000111111111133b3b13bdd0311dddd0311dd53d03dd5dd0311dddd0311dddd0311dddd0311dd00000011111111111111111111111111
11111111111111100000001111111111b313133ddd05011ddd05011d5dd03dd3dd05011ddd05011ddd05011ddd05011d00000011111111111111111111111111
11111111111111110000011111111111d3135b33d0155011d01550115d0dd0d5d0155011d0155011d0155011d015501100000111111111111111111111111111
1111111111111111000011111111111111135513111155010111550150dddd050111550101115501011155010111550100001111111111111111111111111111
11111111111111111101111111111111131131131111111011111110055555501111111011111110111111101111111000011111111111111111111111111111
11111111111111111111111111111ddd131131131111111101111111011111110111111101111111011111110000000000111111111111111111111111111111
111111111111111111111111111ddddd131131131111110010111000101110001011100010111000111111000000000011111111111111111111111111111111
11111111111111111111111111dddddddd5311d3d15111ddd05101ddd05101ddd05101ddd05101ddd15111dd0000000111111111111111111111111111111111
1111111111111111111111111dddddddddd311dddd1111dddd0011dddd0011dddd0011dddd0011dddd1111dd0000001111111111111111111111111111111111
1111111111111111111111111dddddddddd5111ddd15111ddd05011dddd5d11ddd05011ddd05011ddd15111d0000001111111111111111111111111111111111
1111111111111111dddd1111dddddddddd155111d1155111d0155111dd155d11dd155011dd155111d11551111000011111111111111111111111111111111111
111111111111111dddddd11dddddddddd11155111111551111115511d11155d1d1115501d1115511111155111000111111111111111111111111111111111111
11111111111111dddddddddddddddddd11111111111111111111111d1111111d1111111d11111111111111111101111111111111111111111111111111111111
1111111111111ddddddddddddddddddddddddddd111111111555555dd1111111d555555dd1111111111111111111111111111111111111111111111111111111
11111111111ddddddddddddddddddddddddddddd11111111511ffdd51d111ddd5dddddd51d111ddd111111111111111111111111111111111111111111111111
1111111111dddddddddddddddddddddddddddddddd5111dd51fddfd5dd51d1dd5dddddd5dd51d1dddd5111dd1111111111111111111111111111111111111111
111111111dddddddddddddddddddddddddddddddddd111dd5fddcdf5dddd11dd5dddddd5dddd11ddddd111dd1111dddd11111111111111111111111111111111
111111111dddddddddddddddddddddddddddddddddd5111d5fccccf5ddd5d11d5dddddd5ddd5d11dddd5111d11dddddddd111111111111111111111111111111
dddd1111dddddddddddddddddddddddddddddddddd1551115dccccd5dd155d115dddddd5dd155d11dd1551111dddddddddd11111dddd11111111111111111111
ddddd11dddddddddddddddddddddddddddddddddd11155115dccccd5d11155d15dddddd5d11155d1d1115511ddddddddddd1111dddddd111111111111111111d
dddddddddddddddddddddddddddddddddddddddd1111111dd5cccc5d1111111dd555555d1111111d1111111dddddddddddddd1dddddddd1111111111111111dd
ddddddddddddddddddddddddddddddddddddddddddddddddd5c7775dd1111111d1111111dddddddddddddddddddddddddddddddddddddddd1111111111111ddd
dddddddddddddddddddddddddddddddddddddddddddddddd5dccccd51d111ddd1d111dddddddddddddddddddddddddddddddddddddddddddd1111111111ddddd
dddddddddddddddddddddddddddddddddddddddddddddddd5dccccd5dd51d1dddd51d1dddddddddddddddddddddddddddddddddddddddddddd11111111dddddd
dddddddddddddddddddddddddddddddddddddddddddddddd5f7c77f5dddd11dddddd11ddddddddddddddddddddddddddddddddddddddddddddd111111ddddddd
dddddddddddddddddddddddddddddddddddddddddddddddd5fccccf5ddd5d11dddd5d11dddddddddddddddddddddddddddddddddddddddddddd111111ddddddd
dddddddddddddddddddddddddddddddddddddddddddddddd5dccccd5dd155d11dd155d11dddddddddddddddddddddddddddddddddddddddddddd1111dddddddd
dddddddddddddddddddddddddddddddddddddddddddddddd5dccccd5d11155d1d11155d1dddddddddddddddddddddddddddddddddddddddddddd111ddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddd5cccc5d1111111d1111111dddddddddddddddddddddddddddddddddddddddddddddd1dddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddc777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddccccdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddccccdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddd7c77dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddccccdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddccccdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddccccdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddccccdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__map__
0000000000000000000000630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000020203040000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000003010101010603010400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000003040301010101010101010104000000000008090a00000b0c080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000104030101010101010101010101010108000008090707070a090707070a0b0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010101010101010101010101010101070a09070707070707070707070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010101010101010101010101010101070707070707070707070707070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
920300003f6650f000110001300015000160001800018000150001500016000190001b0001e000200002200023000260000000000000000000000000000000000000000000000000000000000000000000000000
480300000c1600f150111401313015120161101811018110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
200600000c0670c0671306713067160671606718067180671a0671a0671d0671d0671f0671f067220672206724062240622405224052240422404224032240322402224022240122401200002000020000200002
20060000005670056707567075670a5670a5670c5670c5670e5670e56711567115671356713567165671656718562185621855218552185421854218532185321852218522185121851200502005020050200402
480300000c7600f05013040131300070000700007000c700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310500000c7650c7650d7000d7000e7000e7000f7000f700107001070011700117001270012700137001370014700147002170000600006000060000600006000060000600006000060000600006000060000600
490200000e6501f64012630006000060000600006000c640006000761000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000400002b650256501f65019650220601f0601906015060100500c0500904007040220501f0501905015050100400c0400903007030220401f0401904015040100300c0300902007020220301f0301903015030
00040000100200c0200901007010220201f0201902015020100100c0100901007010220101f0101901015010100100c0100901007010220001f0001900015000100000c0000900007000220001f0001900015000
0001000028750237501c75017750137400e7400973004730047000670004700017000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00020000240502205018050130500a140051400a10007100041000610004100011000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000100001f5701a570135700e57009570055700257000570045000650004500015000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000300002305023030280502803000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002375023730287502873000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00040000130301a0401e0501e0401e0001e0001e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08040000137301a7401e7501e7401e7001e7001e70000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0003000026620216201913016130131300a1300613003100001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002405024030290502903000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000026050260302b0502b03000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000000
000100000c0500c7000f0500f0001205012000150501500018050180001b0501b0001e0501e000210501370014700147002170000600006000060000600006000060000600006000060000600006000060000600
0001000007750077500f7500f75011750117501375013750167501675018750187501b7501b7501d7501d75014700147002170000600006000060000600006000060000600006000060000600006000060000600
0001000000750007500c7500c7501175011750137501375018750187501d7501d7501f7501f750247502475014700147002170000600006000060000600006000060000600006000060000600006000060000600
100300000e5500e55015550155501a5501a5501355013550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000c0600f050110401303015020160101801018010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c002018023000000f3001a8000f3001a800180230000019800000000c0000c00018023000000f3000c0000c00019800180231a8000f3001a8000c0430000026645000002664500000266450c0430c0000c000
010c00200c04300000198501a800266451a8000c0430000019850000000c0430000026645000000c0430c0430c043198001a8501a800266451a8000c0430000019850000000c04300000266450c0430c0000c043
010c00000c04300000188501a800266451a8000c0430000019850000000c043000002664500000103230c0000c043198001a8501a800266451a8000c0430000019850000000c04300000266450c053103230c000
490c00200a1300a1300a1300a1300a1200a1200a1200a1200a1100a1100a1100a1100c1300c1300c1300c1300c1200c1200c1200c1200c1100c1100c1100c1100213002100021300210002130021300212002110
310c0020165301653018530185301d5301d53021530215302153221532215222152218530185301c5301c53021530215302853028530285322853228522285222900026000260000000000000000000000000000
490c00200313003130031200312003120031200f1300f1300f1200f1200a1300a1300e1300f1300f1300f1200f1200f12005130051300512005120111301113011120111200c1300c13010130111301113011120
490c0020071300713007120071200712007120131301313013120131200e1300e130111301313013130131201312013120071300713007120071201313013130131201312011130111300e1300e1300213002130
490c00000013000130001200012000120001200c1300c1300c1200c12007130071300a1300c1300c1300c1200c1200c1210e1310e1300e1200e1210c1310c1300c1200c1200a1300a12002130021000213002100
010c00200c04300000198501a800266451a8000c0430000019850000000c0430000026645000000c043103000c04319800266250c000266350c0000c0430c00026645000000c04300000266450c0430c0430c000
c10c00202b0302b0102603026010240302401022030220102b0302b01026030260102403024010220302203022020220102903029010240302401022030220102903029010240302401022030220102103021010
c10c002026030260101f0301f0102203022010240302401026030260101f0301f01022030220102403024030240222401226030260101f0301f01024030240101a0301a0101d0301d0101f0301f0201f0101f010
c10c002026030260101a0301a0102103021010220302201026030260101a0301a01021030210102203022030220222201226030260102103021010220302201018030180101d0301d0101f0301f0201f0101f010
310c0020225002250021500215001d5001d5001a5001a5002150021500215002150018500185001c5001c5002150021500285002850028500285002850028500225322251221532215121d5321d5121a5321a512
310c00201f5321f5321f5221f5221f5121f5121853218532185221852218532185321a5321a53213532135321352213522135321353213522135222253222532225222252224532245121d5321d5121a5321a512
310c00201f5321f5321f5221f5221f5121f512265322653226522265221f5321f532215322153226532265322652226522265122651226512265122253222532225222252221532215121d5321d5121a5321a512
310c00201f5321f5321f5221f5221f5121f5121853218532185221852218532185321a5321a532135321353213522135221353213532135221352111531115321153211532165321653218532185320c5320c532
310c00200c5220c5220c5220c5220c5220c5220c5220c5220c5120c5120c5120c5120c5120c5120c5120c5120c5000c5000c5000c5000c5000c5000c5000c500225322251221532215121d5321d5121a5321a512
c10c00202202222022220222202222022220222201222012220122201222012220122402224022240222402224022240222401224012240122401224012240121a000290001a000240001a000220002100021000
c10c00202b0352b0252603526025240352402522035220252b0352b02526035260252403524025220352202522000220002903529025240352402522035220252903529025240352402522035220252103521025
c10c002026035260251f0351f0252203522025240352402526035260251f0351f02522035220252403524025240002400026035260251f0351f02524035240251a0351a0251d0351d0251f0351f0251f0151f015
c10c002026035260251a0351a0252103521025220352202526035260251a0351a02521035210252203522025220002200026035260252103521025220352202518035180251d0351d0251f0351f0251f0151f015
310c00201f5321f5321f5221f5221f5121f5121853218532185221852218532185321a5321a532135321353213522135221353213532135221352111531115321153211532165321653218532185311a5311a532
310c00201a5221a5221a5221a5221a5221a5221a5221a5221a5121a5121a5121a5121a5121a5121a5121a5120c5000c5000c5000c5000c5000c5000c5000c500225002250021500215001d5001d5001a5001a500
010c002027023270230c0231a8000c0231a800270230000019800000000c0230c00029023290230c0230c0000c02319800290231a8000f3001a8000c0430000026635266450c04300000266450c0430c0000c000
490c00200313003130031300313003120031200312003120031100311003110031100513005130051300513005120051200512005120051100511005110051100713002100071300210007130071300712007110
310c002013530135301a5301a5301d5301d53024530245302453224532245222452215530155301f5301f53024530245302953029530295322953229522295222900026000260000000000000000000000000000
c10c00202602226022260222602226022260222601226012260122601226012260121f0221f0221f0221f0221f0221f0221f0121f0121f0121f0121f0121f0121a000290001a000240001a000220002100021000
490c0020081300813008120081200812008120141301413014120141200f1300f13013130141301413014120141201412007130071300712007120131301313013120131200e1300e13011130131301313013120
490c0020051300513005120051200512005120111301113011120111200c1300c130101301113011130111201112011120071300713007120071201313013130131201312011130111300e1300e1300213002120
790c00202003520025240352402527035270252b0352b0252003520025240352402527035270252b0352b02522000220001f0351f0252203522025240352402526035260251f0351f02522035220252403524025
790c00202603526025220352202521035210251d0351d0252603526025220352202521035210251d0351d02522000220001f0351f0252203522025240352402526035260251f0351f02522035220252403524025
310c00202453224532245222452224512245122453224532265322653227532275322653226532225322253222522225221f5321f5321f5221f5221f5321f5321f5221f5221f5221f5221f5121f5111a5311a532
310c00201d5321d5321d5221d5221d5121d5121d5321d5322253222532245322453226532265321f5321f5321f5321f5321f5221f5221f5221f5221f5121f5121f5121f5121f5121f51213500135001350013500
310c00202453224532245222452224512245122454524545275322753224532245322753227531295312953229522295222653226532265222652222532225322252222522225222252222512225122453226532
310c0020275322753229532295322c5322c5322b5322b5322b5222b5221d532115001f532135001d532115001f5321f5321f5321f5321f5221f5221f5221f5221f5121f5121f5121f5121350013500185001a500
c10c00202003020010240302401027030270102b0302b0102003020010240302401027030270102b0322b0222b0122b0121f0301f0102203022010240302401026030260101f0301f01022030220102403024010
c10c00202603026010220302201021030210101d0301d0102603026010220302201021030210101d0321d0221d0121d0121f0301f0102203022010240302401026030260101f0301f01022030220102403024010
310c002029500245002450024500245002450024500265002950029500265002650022500225001f5001f500225001f5001f5001f5001f5001f50029500265312953229532265322653222532225321f5321f532
010c00200c04300000198501a800266451a8000c0430000019850000000c0430000026645000000c043103000c04319800266250c000266350c0000c0430c00026645000000c0432400024023240230c0430c000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 47424344
00 48424344
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
00 181b291c
01 191d2144
00 1a1e2244
00 191d2144
00 201f2324
00 191d6125
00 1a1e6226
00 191d6127
00 201f2c28
00 191d2a25
00 1a1e2b26
00 191d2a2d
00 201f2c2e
00 2f303231
00 19333b77
00 1a343c78
00 19333b7e
00 20343c3d
00 19337537
00 1a347638
00 19337539
00 2034363a
00 19333537
00 1a343638
00 19333539
00 3e34363a
00 591d2a65
00 5a1e2b66
00 591d2a6d
02 181f2c6e
00 41424344
00 41424344
00 07424344
00 08424344

