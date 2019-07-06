pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--[[
jumper
- generate blob within 16x16
		map
- no scrolling (or maybe just
		a little above and below
		blob)
- when player jumps off blob and
		hits bottom of section,
			destroy current blob, and
			scroll player to top of
			screen.
		- then, generate new blob 
				below and drop player down.
- player should have double or
			tripple jump, so they can
			correct themselves in mid-air
- perhaps player cannot advance
		until they collect a special 
		item on the stage (eg, a key)
- player has a water gun. to
			refil, player must stand
			under water.
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
ter_rock=16
ter_bloc=17
ter_roc2=18
ter_blc2=19
ter_gras=20
ter_pipe=21
ter_watr=22
--passives
pas_flw1=23
pas_flw2=24
pas_stem=25
pas_tree=26
pas_watr=27

--coins
coin_chance=5
s_coin=52
s_coin_hud=48

--player
p_accel=0.3
p_max=4
p_num_jumps=3
p_max_water=12
p_max_coin=1000

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

function place_free(x,y)
	local i=flr(x/8)
	local j=flr(y/8)
	if x<=0 or x>=128 or 
				y<=0 or y>=128 then
		return true
	end
	return level[j][i]<ter_rock or
								level[j][i]>=pas_flw1
end

-- ==========
-- init
-- ===================
function _init()
	--vars
	last_level=nil
	scroll=0
	l_tm=0
	sprinkles={}
	bullets={}
	--functions
	init_parallax()
	init_level()
	init_player()
	init_hud()
end

-- ==========
-- draw
-- ===================

function _draw()
	cls()
	rectfill(0,0,128,128,0)
	map(0,0,0,-64,16,16)
	draw_parallax()
	
	if scroll==0 then
		draw_level()
		draw_sprinkles()
		draw_bullets()
	else
		draw_scroll()
	end
	draw_hud()
	draw_player()
end

-- ==========
-- update
-- ===================

function _update()
	update_parallax()
	if scroll>0 then
		update_scroll()
	else
		update_player()
		update_bullets()
	end
	//if(btnp(5))init_scroll()
end

-- ==========
-- hud
-- ===================
function init_hud()
	hud={tm=0}
end

function draw_hud()
	hud.tm+=0.2
	spr(flr(hud.tm)%4+s_coin_hud,
		2,2)
	print("=",11,3,7)
	local b=p_max_coin
	local s=""
	while b>pp.coin and b>10 do
		b=b/10
		if(b>pp.coin)s=s.."0"
	end
	print(s..pp.coin,16,3,7)
end

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
		drr=1, -- -1:left,1:right
		tm=0,
		jump=0,
		jump_press=false,
		dy=0,
		can_die=false,
		coin=0,
		water=p_max_water,
		shoot=0,
		w_tm=0
	}
end

function draw_player()
	if(pp.jump==2)pal(7,6)
	if(pp.jump==3)pal(7,5)
	if(pp.can_die)pal(7,8)
	spr(33+pp.drr,pp.x-4,pp.y-4)
	if pp.tm>0 then
	spr(36+(flr(pp.tm)%2),
		pp.x-4,pp.y-4)
	else
		spr(35,pp.x-4,pp.y-4)
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
	
	--water meter
	if pp.shoot>0 or btn(❎) or
				(touch_water() and 
					pp.water<p_max_water)
				then
		local ws=flr(p_max_water/4)+1
		if pp.water>0 or 
					flr(l_tm)%2==0 then
			rectfill(pp.x-(ws+1),pp.y-7,
				pp.x+ws,pp.y-5,0)
			rect(pp.x-(ws+1),pp.y-7,
				pp.x+ws,pp.y-5,7)
		end
		if pp.water>0 then
			line(pp.x-ws,pp.y-6,
				(pp.x-ws)+ceil(pp.water/2),
				pp.y-6,12)
		end
	end
end

function update_player()
	if pp.y>128 then
		init_scroll()
		return
	end
	
	-- left/right movement
	//pp.drr=0
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
		local nx=pp.x+pp.drr
		if place_free(nx,pp.y) then
			pp.x=nx
		end
	else
		pp.tm=0
	end
	
	player_jump()
	player_shoot()
	touch_coin()
	
	if(pp.w_tm>0)pp.w_tm-=1
	
	if touch_water() and 
				pp.w_tm==0 then
		pp.w_tm=5
		pp.water+=1
		if pp.water>p_max_water then
			pp.water=p_max_water
		end
	end
end

function player_jump()
	if btn(🅾️) then
		if not pp.jump_press then
			pp.jump_press=true
			pp.jump+=1
			if pp.jump<=p_num_jumps then
				pp.dy=-p_max
				add_sprinkles(pp.x,pp.y)
			end
		end
	else
		pp.jump_press=false
	end
	-- if jumping
	if pp.dy<0 then
		pp.dy+=p_accel
		local ny=pp.y+pp.dy
		if place_free(pp.x,ny-4) then
			pp.y=ny
		else
			pp.dy=1
			pp.y=ny-pp.dy
		end
	-- if falling
	elseif place_free(pp.x,
			(pp.y+pp.dy)+4) then
		pp.y=pp.y+pp.dy
		pp.dy+=p_accel
		if(pp.dy>p_max)pp.dy=p_max
	else
		pp.dy=0
		pp.y=(flr((pp.y/8))*8)+4
		pp.jump=0
		pp.can_die=false
	end
end

function player_shoot()
	if pp.shoot>0 then
		pp.shoot-=1
		return
	end
	if btn(❎) then
		pp.shoot=5
		if(pp.water==0)return
		pp.water-=1
		add_bullet(
			pp.x+(5*pp.drr),
			pp.y,pp.drr*3,0,10,12)
	end
end

function touch_coin()
	for c in all(coins)do
		if flr(pp.x/8)==c.i and
					flr(pp.y/8)==c.j then
			del(coins,c)
			pp.coin+=1
			return
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
		x=x+2,y=y,dx=1,dy=1,
		sp=43,tm=0
	})
	add(sprinkles,{
		x=x-2,y=y,dx=-1,dy=1,
		sp=43,tm=0
	})
	add(sprinkles,{
		x=x+2,y=y,dx=1,dy=-1,
		sp=43,tm=0
	})
	add(sprinkles,{
		x=x-2,y=y,dx=-1,dy=-1,
		sp=43,tm=0
	})
end

function draw_sprinkles()
	for s in all(sprinkles)do
		s.tm+=1
		s.y+=s.dy
		s.x+=s.dx
		s.dx*=0.9
		s.dy+=0.1
		pal(7,8+(s.tm%8))
		spr(s.sp,s.x-4,s.y-4)
		pal()
		if(s.tm>16)del(sprinkles,s)
	end
end

-- ==========
-- bullets
-- ===================

function add_bullet(x,y,dx,dy,tm,c)
	add(bullets,{
		x=x,y=y,dx=dx,dy=dy,tm=tm,c=c
	})
end

function update_bullets()
	for b in all(bullets)do
		b.tm-=1
		b.x+=b.dx
		b.y+=b.dy
		if(b.tm<=0)del(bullets,b)
	end
end

function draw_bullets()
	for b in all(bullets)do
		rectfill(b.x,b.y,b.x+1,
			b.y+1,b.c)
	end
end

-- ==========
-- scrolling
-- ===================

function init_scroll()
	scroll=1
	for c in all(coins)do
		del(coins,c)
	end
	last_level=copy_table(level)
	init_level()
end

function update_scroll()
	if(scroll==0)return
	if scroll<128 then
		scroll+=2
		pp.y-=2
		pp.can_die=true
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

-- ==========
-- level generation
-- ===================
function init_level()
	-- clear level
	-- all cells initialized to 0.
	-- solids assigned 1, then are
	-- set to a terrain or passive
	-- value.
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
	-- placement
	player_start_points={}
	
	for j=1,ymax-2 do
	for i=1,xmax-2 do
		--if solid
		if level[j][i]==1 then
			level[j][i]=ter_rock
			--add random blocks
			if chance(10) then
				level[j][i]=ter_bloc
			elseif chance(10) then
				level[j][i]=ter_pipe
			end
			--if top rock
			if level[j-1][i]==0 then
				level[j][i]=ter_gras
				if chance(10) then
					level[j][i]=ter_bloc
				end
				--add potential start point
				add(player_start_points,{
					j=j-1,i=i
				})
				--add flower
				if chance(30) then
					level[j-1][i]=
						rand(pas_flw1,pas_flw2)
				--add tree
				elseif chance(30) then
					local rh=rand(1,3)
					for k=1,rh do
						level[j-k][i]=pas_stem
					end
					level[j-(rh+1)][i]=pas_tree
				end
			--if below grass
			elseif level[j-1][i]==ter_gras then
				if level[j][i]==ter_rock then
					level[j][i]=ter_roc2
				else
					level[j][i]=ter_blc2
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
end

function add_coins()
	coins={}
	for j=0,ymax-1 do
	for i=0,xmax-1 do
		if level[j][i]==0 and
					chance(coin_chance) then
			add(coins,{
				i=i,j=j,tm=0
			})
		end
	end end
end

function draw_coins()
	for c in all(coins)do
		c.tm+=0.1
		spr((flr(c.tm)%4)+s_coin,
			c.i*8,c.j*8)
	end
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
1011100050dddd051311300353dd3d033b1b1330500ff00550cccc050000000000000000000f90000f0000f00077c70000cc7c0000cccc000077770000000000
d05101dd5d0dd0d5d05301d35d0dd3d3b331333d50f00f0550cccc05000000000000000000044000f00f000f00cccc000077770000cccc0000cccc0000000000
dd0011dd5dd00dd5dd0311dd53d03dd533b3b13b5f00c0f55fccccf50000000000e0e00000094000f0f0007f00cccc0000cccc00007c770000cccc0000000000
dd05011d5dd00dd5dd05011d5dd03dd3b303033d5fccccf55fccccf500000000000a000000044000f000707f00cccc0000cccc0000cccc00007cc70000000000
d01550115d0dd0d5d01550115d0dd0d5d3135b3350cccc0550cccc050008000000e0e00000099000f000077f00cccc0000cccc0000cccc0000c77c0000000000
0111550150dddd050111550150dddd050113550350cccc0550cccc0500898000000300000004f0000f0777f000c7770000cccc0000cccc0000cccc0000000000
111111100555555011111110055555501311311305cccc5005cccc5000080000003000000004400000ffff0000cccc00007c770000cccc0000cccc0000000000
0000000000000000000000000000000000000000000000000008000000008000070000c00c0000000c0007000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000008800000000880000c70c007000007c0000c0000000000000007000000000000000000000000000
007777000077770000777700000000000000000000000000088888888888888000000000000000000000000c0000700000077700000000000000000000000000
00777700007777000077770000000000000000000000000088888888888888880000000000000000700000000007770000770770000000000000000000000000
00c7c70000c77c00007c7c0000000000000000000000000008888888888888800000000000000000000000000000700000077700000000000000000000000000
00777700007777000077770000000000000000000000000000880000000088000000000000000000000000000000000000007000000000000000000000000000
00000000000000000000000000700700007007000070070000080000000080000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700700007000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aaa000000a0000000a0000000a00000aaaa00000aa000000aa000000aa0000000000000000000000000000000000000000000000000000000000000000000
00a000a0000a0a000000a000000a0a000aaaaaa000aaaa00000aa00000aaaa000000000000000000000000000000000000000000000000000000000000000000
00a009a0000a9a000000a000000a9a000aaaa9a000aa9a00000aa00000a9aa000000000000000000000000000000000000000000000000000000000000000000
00a099a0000a9a000000a000000a9a000aaaa9a000aa9a00000aa00000a9aa000000000000000000000000000000000000000000000000000000000000000000
000aaa000000a0000000a0000000a0000aa99aa000aaaa00000aa00000aaaa000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000aaaa00000aa000000aa000000aa0000000000000000000000000000000000000000000000000000000000000000000
__label__
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
00000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000cc0000000000000000000
00000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000cc0000000700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777000000000000000000000070000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007700000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007700000000000000000000000000000000000000770000000c00000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000c0000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080000000000000007000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc000000000000000000000000000000000000000000
0000000000000000000000000000000000007000000000000000000000000000000000000000000000cccc000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000007000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007777000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000
00007000000000000000000000000000000000000000000000000000000000000000000000007000000000000000800000000000000770000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
