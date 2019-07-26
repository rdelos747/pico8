pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--[[
jumper`
- perhaps player cannot advance
		until they collect a special 
		item on the stage (eg, a key)
- pickups:
		- gems (just points for now)
		- unlimited jumps for x seconds
		- invincibility for x seconds 
- show number jumps in hud
- touching enemy decreases heart
			and jump num
- eat flowers to gain health?
- - or, just place hearts in hard
					areas?
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
s_coin2=80
s_coin3=96
s_coin_hud=48

--player
p_accel=0.3
p_max=4
//p_num_jumps=3
//p_max_water=12
p_max_coin=1000

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

function set_pause()
	pause=4
end

function set_hit()
	hit=12
end
-- ==========
-- init
-- ===================
function _init()
	//printh("------start------")
	//reset()
	init_parallax()
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
	hearts={}
	price_lvls={1,1,1,1}
	shop={x=78,y=200}
	pause=0
	hit=0
	perfect=0
	total_coin=0
	total_perf=0
	total_enim=0
	total_lvls=0
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
	
	if pp.hp<=0 then
		draw_player_dead()
		return
	end
	
	if(l_num==1)draw_creds()
	
	if scroll==0 then
		draw_level()
		draw_sprinkles()
		draw_bullets()
		draw_flares()
		draw_bats()
		draw_blobs()
		draw_flashes()
		draw_hearts()
	else
		draw_scroll()
	end
	if hit<=0 or flr(hit)%2==0 then
		if(l_num>1)draw_hud()
		draw_player()
	end
	if l_type=="shop" then
		draw_shop()
	elseif l_type=="frst" then
		draw_first()
	end
end

-- ==========
-- update
-- ===================

function _update()
	update_parallax()
	if(show_logo)return
	
	if pause>0 then
		pause-=0.3
		return
	end
	
	if hit>0 and scroll==0 then
		hit-=0.3
	end
	
	if perfect>0 then
		//draw_perfect()
		return
	end
	if scroll>0 then
		update_scroll()
	else
		if pp.shopping then
			update_shopping()
			return
		end
		
		if pp.hp<=0 then
			player_dead()
			return
		end
		
		update_player()
		update_bullets()
		update_bats()
		update_blobs()
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
	draw_hud_coins()
	draw_hud_hp()
	draw_hud_jump()
	print(l_num,120,3,7)
end

function draw_hud_coins()
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

function draw_hud_hp()
	for i=1,pp.hp_max do
		if i>pp.hp then
			print("♥",30+(i*6),3,5)
		else
			print("♥",30+(i*6),3,8)
		end
	end
end

function draw_hud_jump()
	rectfill(78,2,
		70+(8*pp.jump_max),8,0)
	for i=1,pp.jump_max do
		if i>pp.jump then
			pal(6,1)
			pal(7,1)
			pal(12,1)
		end
		spr(62,70+(i*6),2)
		pal()
	end
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
		drr_y=0,
		tm=0,
		jump_press=false,
		jump=3,
		jump_max=3,
		landed=false,
		dy=0,
		can_die=false,
		coin=0,
		water=12,
		water_max=12,
		water_dist=10,
		shoot=0,
		w_tm=0,
		hp=3,
		hp_max=3,
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
	if pp.shoot>0 or 
				(btn(❎) and not pp.shopping) or
				(touch_water() and 
					pp.water<pp.water_max)
				then
		local ws=flr(pp.water_max/4)+1
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
		if pp.can_die then
			pp.hp-=1
			//set_pause()
			set_hit()
		end
		init_scroll()
		return
	end
	
	if pp.hit>0 then
		pp.hit-=1
		local dx=pp.x+pp.hit_dx
		local dy=pp.y+pp.hit_dy
		if place_free(dx,pp.y) then
			pp.x=dx
		end
		if place_free(pp.x,dy) then
			pp.y=dy
		end
		if(pp.hit==3)set_hit()
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
	
	-- vertical pointing
	pp.drr_y=0
	if(btn(⬆️))pp.drr_y=-1
	if(btn(⬇️))pp.drr_y=1
	
	player_jump()
	player_shoot()
	touch_coin()
	touch_heart()
	
	if(pp.w_tm>0)pp.w_tm-=1
	
	if touch_water() and 
				pp.w_tm==0 then
		pp.w_tm=5
		pp.water+=1
		if pp.water>pp.water_max then
			pp.water=pp.water_max
		end
	end
end

function player_jump()
	if btn(🅾️) then
		if not pp.jump_press then
			pp.jump_press=true
			if pp.jump>0 then
				pp.jump-=1
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
		pp.landed=false
	else
		pp.dy=0
		pp.y=(flr((pp.y/8))*8)+4
		pp.jump=pp.jump_max
		pp.can_die=false
		if not pp.landed then
			pp.landed=true
			add_stomp(pp.x,pp.y)
		end
	end
end

function player_shoot()
	if(l_type=="shop")return
	if pp.shoot>0 then
		pp.shoot-=1
		return
	end
	if btn(❎) then
		pp.shoot=5
		if(pp.water==0)return
		pp.water-=1
		if pp.drr_y !=0 then
			add_bullet(
				pp.x,
				pp.y+(5*pp.drr_y),
				0,pp.drr_y*3,10,12,
				pp.attack)
		else
			add_bullet(
				pp.x+(5*pp.drr),
				pp.y,pp.drr*3,0,10,12,
				pp.attack)
		end
	end
end

function player_hit(x,y)
	if hit>0 or 
				pp.hit>0 or 
				pp.can_die then
		return
	end
	pp.hp-=1
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
	
	-- totals
	if pp.d_tm1>0.1 then
		print("~totals~",48,21,5)
		print("~totals~",48,20,7)
	end
	-- total coins
	if pp.d_tm1>0.2 then
		print("coins:",43,31,5)
		print("coins:",43,30,7)
		print(total_coin,70,31,9)
		print(total_coin,70,30,10)
	end
	-- total enemies
	if pp.d_tm1>0.3 then
		print("enemies:",35,41,5)
		print("enemies:",35,40,7)
		print(total_enim,70,41,2)
		print(total_enim,70,40,8)
	end
	-- total perfects
	if pp.d_tm1>0.4 then
		print("perfects:",31,51,5)
		print("perfects:",31,50,7)
		print(total_perf,70,51,13)
		print(total_perf,70,50,12)
	end
	-- total levels
	if pp.d_tm1>0.5 then
		print("levels:",39,61,5)
		print("levels:",39,60,7)
		print(total_lvls,70,61,3)
		print(total_lvls,70,60,11)
		print("press ❎ to continue",
			24,101,1)
		print("press ❎ to continue",
			24,100,7)
	end
end

function touch_coin()
	for c in all(coins)do
		if flr(pp.x/8)==c.i and
					flr(pp.y/8)==c.j then
			del(coins,c)
			pp.coin+=c.val
			total_coin+=c.val
			add_flare(pp.x,pp.y,c.val)
			if #coins==0 then
				perfect=1
				total_perf+=1
				pp.coin+=50
			end
			if pp.coin>p_max_coin then
				pp.coin=p_max_coin
			end
			return
		end
	end
end

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
	tm,c)
	add(bullets,{
		x=x,y=y,dx=dx,dy=dy,
		tm=tm,c=c
	})
end

function update_bullets()
	for b in all(bullets)do
		b.tm-=1
		b.x+=b.dx
		b.y+=b.dy
		if(b.tm<=0)del(bullets,b)
		
		if not place_free(b.x,b.y) then
			add_flash(b.x,b.y)
			del(bullets,b)
		end
		
		if b.x>pp.x-4 and b.x<pp.x+4 and
					b.y>pp.y-4 and b.y<pp.y+4 then
			player_hit(b.x,b.y)
		end
		
		for ba in all(bats) do
			if b.x>ba.x-4 and b.x<ba.x+4 and
						b.y>ba.y-4 and b.y<ba.y+4 then
				del(bullets,b)
				damage_bat(ba)
			end
		end
		
		for bl in all(blobs) do
			if b.x>bl.x-4 and b.x<bl.x+4 and
						b.y>bl.y-4 and b.y<bl.y+4 then
				del(bullets,b)
				damage_blob(bl)
			end
		end
	end
end

function draw_bullets()
	for b in all(bullets)do
		rectfill(b.x,b.y,b.x+1,
			b.y+1,b.c)
	end
end

-- ==========
-- add hearts
-- ===================
function add_heart(x,y)
	add(hearts,{x=x,y=y})
end

function draw_hearts()
	for h in all(hearts)do
		spr(56,h.x-4,h.y-4)
	end
end

-- ==========
-- blobs
-- ===================
function add_blobs()
	local idx=rand(1,#player_start_points)
	local bt=player_start_points[idx]
	add(blobs,{
		x=(bt.i*8)+4,
		y=(bt.j*8)+4,
		tm=0,hp=2
	})
end

function draw_blobs()
	for b in all(blobs)do
		spr(89+flr(b.tm)%2,
			b.x-4,b.y-4)
	end
end

function update_blobs()
	for b in all(blobs)do
		b.tm+=0.1
		
		--player collision
		if b.x>pp.x-4 and b.x<pp.x+4 and
					b.y>pp.y-4 and b.y<pp.y+4 then
			player_hit(b.x,b.y)
		end
	end
end

function damage_blob(b)
	add_flash(b.x,b.y)
	b.hp-=1
	if b.hp<=0 then
		if(chance(50))add_heart(b.x,b.y)
		del(blobs,b)
		total_enim+=1
	end
end

-- ==========
-- bats
-- ===================
function add_bats()
	for i=1,rand(3,4) do
		local finding=true
		while finding do
			local ri=rand(1,xmax-2)
			local rj=rand(1,ymax-2)
			if level[rj][ri]==0 then
				finding=false
				add(bats,{
					x=ri*8,y=rj*8,oy=rj*8,
					tm=0,hp=3,
					ytm=0,xtm=0
				})
			end
		end
	end
end

function draw_bats()
	for b in all(bats) do
		spr(88,b.x-4,b.y-4,1,1,
			sin(b.xtm)<0,false)
		spr(flr(b.tm)%4+84,b.x-4,b.y-8)
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
		elseif pt>=ter_rock and 
					pt<pas_flw1 then
			if sin(b.xtm)>0 then
				b.x-=2
				b.xtm=0
			elseif sin(b.xtm)<0 then
				b.x+=2
				b.xtm=0.5
			end
		end
		
		--player collision
		if b.x>pp.x-4 and b.x<pp.x+4 and
					b.y>pp.y-4 and b.y<pp.y+4 then
			player_hit(b.x,b.y)
		end
		
		--shoot
		if (b.x<pp.x and 
					sin(b.xtm)>0) or
					(b.x>pp.x and
					sin(b.xtm)<0) then
			if chance(1) then
				local a=atan2(pp.x-b.x,pp.y-b.y)
				local dx=cos(a)*2
				local dy=sin(a)*2
				add_bullet(b.x+(dx*2),
					b.y+(dy*2),
					dx,dy,100,8,1)
			end
		end
	end
end

function damage_bat(b)
	add_flash(b.x,b.y)
	b.hp-=1
	if b.hp<=0 then
		if(chance(50))add_heart(b.x,b.y)
		del(bats,b)
		total_enim+=1
	end
end

-- ==========
-- scrolling
-- ===================
function init_scroll()
	clear_objects()
	scroll=1
	l_num+=1
	total_lvls+=1
	last_level=copy_table(level)
	if l_num%10==0 then
		l_type="shop"
		init_shop()
	else
		l_type="norm"
		init_level()
	end
end

function update_scroll()
	if(scroll==0)return
	if scroll<128 then
		scroll+=2
		pp.y-=2
		pp.can_die=true
		shop.y-=2
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
	for h in all(hearts)do
		del(hearts,h)
	end
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
	print("+50 coins!",43,70,12)
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
		"+1 heart",
		"+2 water tank",
		"+1 jump",
		"+1 water distance"
		},
		err_tm=0,
		bought=false,
		bt_tm=0
	}
	level={}
	local s_level={
		{0,0,0,0,46,47,0,0},
		{0,0,0,0,44,45,0,0},
		{0,1,1,1,20,20,1,1},
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
		else
			shop.err_tm=35
		end
	end
	if btnp(⬅️) and shop.idx>0 then
		shop.idx-=1
		shop.err_tm=0
	elseif btnp(➡️) and shop.idx<3 then
		shop.idx+=1
		shop.err_tm=0
	end
end

function apply_upgrade(i)
	if i==0 then
	-- +1 hearts
		pp.hp_max+=1
	elseif i==1 then
	-- +2 water tank
		pp.water_max+=2
	elseif i==2 then
	-- +1 jump
		pp.jump_max+=1
	elseif i==3 then
	-- +1 attack
		pp.water_dist+=5
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
		pal(6,0)
		pal(7,0)
		pal(8,0)
		pal(9,0)
		pal(10,0)
		pal(12,0)
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
			local sp=s_coin
			local val=1
			if chance(10) then
				sp=s_coin2
				val=5
			elseif chance(10) then
				sp=s_coin3
				val=10
			end
			add(coins,{
				i=i,j=j,tm=0,sp=sp,val=val
			})
		end
	end end
end

function draw_coins()
	for c in all(coins)do
		c.tm+=0.1
		spr((flr(c.tm)%4)+c.sp,
			c.i*8,c.j*8)
	end
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
0000000000000000000000000000000000000000000000000008000000008000070000c00c0000000c0007000000000004000000000000400000000000000000
000000000000000000000000000000000000000000000000008800000000880000c70c007000007c0000c000000000000400000000000040444d44d444d4d444
007777000077770000777700000000000000000000000000088888888888888000000000000000000000000c000070000400000000000040040d00d000d0d040
0077770000777700007777000000000000000000000000008888888888888888000000000000000070000000000777000c00b00000009040000d00d00000d000
00c7c70000c77c00007c7c00000000000000000000000000088888888888888000000000000000000000000000007000ffddddfdffdffdff040d00d000000040
00777700007777000077770000000000000000000000000000880000000088000000000000000000000000000000000004ddd04d04dd0d40040000d000000040
000000000000000000000000007007000070070000700700000800000000800000000000000000000000000000000000000d0000000d00000400000000000040
00000000000000000000000000700700007000000000070000000000000000000000000000000000000000000000000004000040040000400400000000000040
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071117000000000000000000
000aaa000000a0000000a0000000a00000aaaa00000aa000000aa000000aa000088088000000000000f0ff0000f0ff0000f0ff00007117000007770000000000
00a000a0000a0a000000a000000a0a000aaaaaa000aaaa00000aa00000aaaa008288888000f6ff0000666600606666060066660000071700000c7c0000007700
00a009a0000a9a000000a000000a9a000aaaa9a000aa9a00000aa00000a9aa008288888000969600009696006096960600969600000070000007070000007700
00a099a0000a9a000000a000000a9a000aaaa9a000aa9a00000aa00000a9aa000828880000666600006666000066660060666606000000000000000000000000
000aaa000000a0000000a0000000a0000aa99aa000aaaa00000aa00000aaaa000088800000666600006666000066660060666606000000000000600000000000
0000000000000000000000000000000000aaaa00000aa000000aa000000aa0000008000000666600006666000066660000666600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000600600006006000060060000600600000000000000000000000000
07000000070000000700000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000777000007770777077700000077777000777770007777700077777000777770000777700077777700000000000000000000000000000000000000000
07000000070000000700c7c007000000077cc770077ccc00077cc770077ccc00077ccc00077ccc000cc77cc00000000000000000000000000000000000000000
00080800000000000000707000000000077777c007777000077777c0077770000777700007700000000770000000000000000000000000000000000000000000
00828880077777770000000007770000077ccc00077cc000077c7700077cc000077cc00007700000000770000000000000000000000000000000000000000000
0082888007cccc07000006000c7c0c0c07700000077777000770c77007700000077777000c777700000770000000000000000000000000000000000000000000
000888000777777700000000070700000cc000000ccccc000cc00cc00cc000000ccccc0000cccc00000cc0000000000000000000000000000000000000000000
00008000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800000880000008800000088000000000000000000000000000000000000011100000000000000000000000000000000000000000000000000000000000
08888880008888000008800000888800011111100011110000111100001111000188810000022000000000000000000000000000000000000000000000000000
08888280008828000008800000828800188ee8810188e81000188100018e881001878710002ee200002222000000000000000000000000000000000000000000
08888280008828000008800000828800011ee110001ee100001ee100001ee1001888881002eeee2002eeee200000000000000000000000000000000000000000
08822880008888000008800000888800000110000001100000011000000110001888110002e7e7202eeeeee20000000000000000000000000000000000000000
00888800000880000008800000088000000000000000000000000000000000001811000002eeee202eee7e720000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000222200022222200000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbb00000bb000000bb000000bb000000000000000700000006700000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbb000bbbb00000bb00000bbbb00007777000006777000077770000767700000000000000000000000000000000000000000000000000000000000000000
0bbbb3b000bb3b00000bb00000b3bb00007777000077777000776770007777700000000000000000000000000000000000000000000000000000000000000000
0bbbb3b000bb3b00000bb00000b3bb00006767000077670007777770007767700000000000000000000000000000000000000000000000000000000000000000
0bb33bb000bbbb00000bb00000bbbb00007777000077770007077000070700000000000000000000000000000000000000000000000000000000000000000000
00bbbb00000bb000000bb000000bb000007007000070070007007000070700000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007007000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa000000000000000000000000000000000000000000000000000000000
000000000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa00000000000000000000000000000000000000000000000000000000
00000000aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa00000000000000000000000000000000000000000000000000000000
00000000aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa00000000000000000000000000000000000000000000000000000000
00000000aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa00000000000000000000000000000000000000000000000000000000
00000000aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa00000000000000000000000000000000000000000000000000000000
00000000aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa00000000000000000000000000000000000000000000000000000000
000000000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa00000000000000000000000000000000000000000000000000000000
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
