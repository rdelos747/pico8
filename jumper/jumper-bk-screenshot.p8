pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- constants
ver="0.25.0"

--xmax=16
--ymax=16
cell_chance=30
cell_pad_h=3
cell_pad_v=5
cell_birth=3
cell_death=1
cell_autos=3

--passives
pas_watr=27

--solids
ter_rock=16
ter_pipe=17
ter_watr=18

--biome specific
cb=nil -- cur biome
--cb_idx=1
biome={
	grass={
		name="grass",
		icon=89,
		blk_s=128
	},
	ice={
		name="ice",
		icon=92,
		blk_s=144
	},
	desert={
		name="desert",
		icon=91,
		blk_s=160
	},
	fungi={
		name="fungi",
		icon=106,
		blk_s=176
	},
	heaven={
		name="heaven",
		icon=141,
		blk_s=136
	},
	dark={
		name="dark",
		icon=93,
		blk_s=152
	}
}

biome_order={
	biome.grass,
	biome.desert,
	biome.ice,
	biome.fungi,
	biome.dark,
	biome.heaven
}

--coins
--coin_chance=5
--s_coin_hud=48
--val_yellow=1
--val_green=5
--val_red=10

--enmies
--hp_bat=2
--hp_blob=1
--hp_cac=2
--hp_flame=1
--flame_t=0.1
--flame_s=0.28
--flame_spawn_t=20

--hp
--hpc_high=10 //hp spawn chance
--hpc_mid=5
--hpc_low=1
--hp_loss_hit=2
--hp_loss_bot=2

--player
--p_max_coin=9999
--p_jump_min=2
--b_spread=5
--b_speed=4
--b_fall_decel_h=0.2
--b_fall_accel_v=1
--b_fall_max=2
--p_shoot_delay=4

--hud
--hud_top=1
--hud_bot=122

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
--play_music=true

--init

function reset()
	--vars
	last_level=nil
	l_num=-1 // cannot change this
	b_num=1
	scroll=0
	l_tm=0
	sprinkles={}
	bullets={}
	flares={}
	flashes={}
	enemy={}
	hps={}
	price_lvls={1,1,1}
	shop={x=78,y=200}
	pause=0
	hit=0
	perfect=0
	--total_coin=0
	total_perf=0
	total_enim=0
	total_lvls=0
	cur_lvl_cns=0
	cb_idx=1
	cb=biome_order[cb_idx]
	--extra_e=-1
	extra_cac=false
	extra_mush=false
	extra_sword=false
	extra_beam=false
	extra_ice=false
	//cb=biome.dark//biome.grass
	--functions
	clear_objects()
	create_cb()
	init_level()
	//init_first()
	
	//init_player()
	init_hud()
	
	if not first_run then
		music(24)
	end
	has_died=false
	
	// init player
	local idx=rand(1,#player_start_points)
	local pt=player_start_points[idx]
	
	pp={
		x=(pt.i*8)+4,y=(pt.j*8)+4,
		w=3,h=6
	}
	
	pp_drr=1
	pp_drr_y=0
	pp_tm=0
	pp_jump_press=false
	pp_jump=0
	pp_landed=false
	pp_dy=0
 pp_can_die=false
	pp_coin=0
	pp_water=3
	pp_w_tanks=1
	--pp_bullet_size=0.5
	pp_bullet_num=1
	pp_shoot=0
	pp_w_tm=0
	pp_hp=8
	pp_hp_tanks=2
	pp_hit=0
	pp_hit_dx=0
	pp_hit_dy=0
	pp_shopping=false
	pp_can_shop=false
	pp_d_tm0=0 --die animation
	pp_d_tm1=0 --die rest animation
	pp_d_cntr=false
	pp_new_biome=false
end

-->8
-- general

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function chance(n)
	return rand(0,100) < n
end

function copy_table(t)
	local ll={}
	for j=0,15 do
		ll[j]={}
	for i=0,15 do
		ll[j][i]=t[j][i]
	end end
	return ll
end

--[[
function print_level()
	for j=0,ymax-1 do
		local s=""
		for i=0,xmax-1 do
			s=s..level[j][i].." "
		end 
		printh(s)
	end
	printh("")
end
]]--


function level_solid(i,j)
	local b=level[j][i]
	//return (b>=cb.ter_bloc and
	return (b>=cb.blk[0] and
						//b<=cb.ter_gras) or
						b<=cb.blk[3]) or
						b==ter_rock or
						b==ter_pipe or
						b==ter_water
end

function point_free(x,y)
	local i=flr(x/8)
	local j=flr(y/8)
	
	return not level_solid(i,j)
end

--last_a=nil
--last_b=nil
function place_free(o,ox,oy)
	local a={
		x=o.x+ox,y=o.y+oy,w=o.w,h=o.h
	}
	local free=true
	for j=0,15 do
	for i=0,15 do
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

function touch_water(o)
	local i=flr(mid(0,o.x,127)/8)
	local j=flr(mid(0,o.y,127)/8)
	return level[j][i]==pas_watr
end

--[[
function draw_bb(o)
	rect(
		o.x-o.w/2,
		o.y-o.h/2,
		o.x+o.w/2,
		o.y+o.h/2,
		8)	
end
]]--



function next_b_idx()
	return max(
		(cb_idx+1)%(7),
		1)
	--return max((b_num+1)%7,1)
end

function val_with_zero(v)
	--local c=min(pp.coin,9999)
	local b=9999//p_max_coin
	local s=""
	while b>v and b>10 do
		b=b/10
		if(b>v)s=s.."0"
	end
	return s..v
end

--[[
function set_pause()
	pause=4
end
]]--

function set_hit()
	hit=12
end

--[[
function _music(n)
	if(play_music)music(n)
end
]]--

-- ==========
-- init
-- ===================
function _init()
	printh("------start------")
	//reset()
	init_parallax()
	//_music(24)
	music(24)
	
	--[[
	local av=0
	for i=1,100 do
		av+=rand(25,54)
	end
	printh("ave: "..av/100)
	]]--
end

-- ==========
-- draw
-- ===================
function _draw()
	cls()
	rectfill(0,0,128,128,0)
	map(0,0,0,-64,16,16)
	draw_parallax()
	
	--[[
	if show_logo then
		draw_logo()
		return
	end
	
	if perfect>0 then
		draw_perfect()
		return
	end
	
	if pp_hp<=0 then
		draw_player_dead()
		return
	end
	
	//if(l_num==0)draw_creds()
	
	//draw_blobs()
	//draw_bats()
	//draw_enemies()
	
	if scroll==0 then
		draw_level()
		draw_sprinkles()
		draw_bullets()
		draw_flares()
		draw_flashes()
		draw_hps()
	else
		draw_scroll()
	end
	
	draw_enemies()
	
	if hit<=0 or flr(hit)%2==0 then
		draw_player()
		if(l_num>=0)draw_hud()
		
	end

	if l_num==-1 and scroll==0 then
		if b_num>6 then
			draw_first_last("its ok to keep going")
		else
			draw_first_last("its ok to jump down")
			print(ver,1,122,6)
		end
	elseif l_num==9 then
		draw_shop()
	end
	]]--
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
		if pp_shopping then
			update_shopping()
			return
		end
		
		if pp_hp<=0 then
			if not has_died then
				//_music(56)
				music(56)
			end
			first_run=false
			has_died=true
			player_dead()		
			return
		end
		
		update_player()
		update_bullets()
		//update_bats()
		//update_blobs()
		update_enemies()
		update_hps()
		
		
		// take out for stat tokens
		if b_num>6 and l_num==-1 then
			if spr_tm==0 then
				spr_tm=5
				add_sprinkles(
					rand(0,128),
					rand(0,128)
				)
				sfx(5)
			end
			spr_tm-=1
		end
	end
	
	if pp.y>128+8 then
		if pp_can_die then
			pp_hp-=2
			set_hit()
			sfx(16)
		end
		init_scroll()
		return
	end
end
spr_tm=0

-- ==========
-- hud
-- ===================
function init_hud()
	hud={tm=0}
end

function draw_creds()
	print("a game by",48,5,1)
	print("raf+ryan @ gold team",
		26,12,1)
end

function draw_hud()
	hud.tm+=0.2
	rectfill(0,122-1,128,122+6,0)
	draw_hud_coins()
	draw_hud_hp()
	draw_hud_jump()
	draw_hud_lvl()
end

hud_lvl_x=1
function draw_hud_lvl()
	--[[
	print("lvl",
		hud_lvl_x+1,
		hud_bot,
		3)
	print("lvl",
		hud_lvl_x,
		hud_bot,
		11)
	]]--
	--[[
	print(l_num,
		hud_lvl_x+1,hud_bot,3)
	]]--
	--[[
	local b=1000
	local l_tot=""
	while b>l_num and b>10 do
		b=b/10
		if(b>l_num)l_tot=l_tot.."0"
	end
	]]--
	
	--[[
	print(l_tot..l_num,
		hud_lvl_x+1,hud_bot,3)
	]]--
	--[[
	print(l_tot..l_num,
		hud_lvl_x+0,hud_bot,11)
	]]--
	print(b_num.."/6",
		hud_lvl_x,122,11)
	print(
			l_num+1,hud_lvl_x+22,122,3)
end

hud_c_x=112
function draw_hud_coins()
	--[[
	spr(flr(hud.tm)%4+s_coin_hud,
		hud_c_x,hud_top)
	print(":",hud_c_x+7,hud_top,7)
	]]--
	local c=min(pp_coin,9999)
	--[[
	local b=9999//p_max_coin
	local s_tot=""
	while b>c and b>10 do
		b=b/10
		if(b>c)s_tot=s_tot.."0"
	end
	]]--
	
	--[[`
	print(s_tot..pp.coin,
		hud_c_x+1,hud_bot,9)
	]]--
	print(val_with_zero(c),
		hud_c_x+0,122,10)
end

hud_hp_x=24
function draw_hud_hp()
	//palt(0,false)
	//palt(15,true)
	--[[
	print("hp",
		hud_hp_x+1,
		hud_bot,
		2)
	print("hp",
		hud_hp_x,
		hud_bot,
		14)
	]]--
	for i=1,pp_hp_tanks do
		local c=pp_hp/(i*4)
		local r=min((i*4)-pp_hp,4)
		local x=hud_hp_x+9+(i-1)*6
		if c>=1 then
			spr(33,x,122)
		else
			spr(34+r%4,x,122)
		end
	end
	//palt()
end

hud_j_x=56
function draw_hud_jump()
	local ttl=2+pp_w_tanks
	for i=1,2 do
		if i<=pp_jump then
			pal(6,1)
			pal(7,1)
			pal(12,1)
		end
		spr(19,
			hud_j_x+6+(i*5),
			122)
		pal()
	end
	for i=1,pp_w_tanks do
		local nw=mid(
			0,
			pp_water-(pp_w_tanks*3-i*3),
			3)
		if nw==0 then
			spr(20,
				hud_j_x+16+(i*6),
				122)
		else
			spr(
				20+(nw*2)-(flr(hud.tm)%2),
				hud_j_x+16+(i*6),
				122)
		end
	end
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
	tm,c,p,fall)
	add(bullets,{
		x=x,y=y,dx=dx,dy=dy,
		w=1,h=1,
		tm=tm,c=c,p=p,f=fall
	})
end

function update_bullets()
	for b in all(bullets)do
		b.tm-=1
		b.x+=b.dx
		b.y+=b.dy
		
		if b.f then
			if(b.dx>0)b.dx=max(0,b.dx-0.2)
			if(b.dx<0)b.dx=min(0,b.dx+0.2)
			b.dy=min(b.dy+1,2)
		end
		
		if(b.tm<=0)del(bullets,b)
		
		if not place_free(b,0,0) then
			add_flash(b.x,b.y)
			del(bullets,b)
		end

		if not b.p then
			if col_bb(pp,b) then
				player_hit(b.x,b.y)
				del(bullets,b)
			end
		else		
			for e in all(enemy)do
				if col_bb(b,e) and e.hp!=nil then
					del(bullets,b)
					damage_enemy(e)
				end
			end
		end
	end
end

function draw_bullets()
	for b in all(bullets)do		
		pal(6,b.c)
		--palt(0b0000000100000000)
		spr(80,b.x-4,b.y-4)
		pal()
		--draw_bb(b)
	end
end

function add_hps(x,y,c)
	if not chance(c) then
		return
	end
	local rn=rand(1,3)
	for i=1,rn do
		add(hps,{
			x=x,y=y,w=4,h=4,tm=0,
			a=rnd(1)%1,s=rand(1,2)
		})
	end
end

function draw_hps()
	for h in all(hps)do
		local hx=h.x-h.w/2
		local hy=h.y-h.h/2
		if flr(h.tm)%2==0 then
			pal(8,9)
			pal(2,8)
			pal(14,15)
		end
		spr(32,hx,hy)
		pal()
	end
end

function update_hps()
	for h in all(hps)do
		h.tm=(h.tm+0.2)%2
		local dx=cos(h.a)*h.s
		local dy=sin(h.a)*h.s
		if place_free(h,dx,0) then
			h.x+=dx
		end
		if place_free(h,0,dy) then
			h.y+=dy
		end
		if h.s>0.01 then
			h.s*=0.9
		else
			h.s=0
		end
	end
end 

--[[
function damage_bat(b)
	add_flash(b.x,b.y)
	b.hp-=1
	if b.hp<=0 then
		--if(chance(50))add_heart(b.x,b.y)
		-- game_tm+=time_add_bat
		-- add_flare(b.x,b.y,time_add_bat)
		add_hps(b.x,b.y)
		del(bats,b)
		total_enim+=1
	end
end
]]--

-- ==========
-- scrolling
-- ===================
function create_cb()
	cb.blk={}
	for i=0,7 do
		cb.blk[i]=cb.blk_s+i
	end
end

--final_shop=false
pp_last_coin=0
pre_shop_coin=0
function init_scroll()
	// stat
	if l_num==9 then
		// stat
		printh("biome "..b_num..": "..pre_shop_coin.." ("..pre_shop_coin-pp_last_coin..")".." -> "..pp_coin.." ("..pp_coin-pp_last_coin..")")
		pp_last_coin=pp_coin
	end
	cur_lvl_cns=0
	clear_objects()
	scroll=1
	//l_tot=min(l_num+1,999)
	l_num=(l_num+1)%10
	total_lvls+=1
	last_level=copy_table(level)
	if l_num==9 then
		--l_type="shop"
		init_shop()
		--[[
		if cb_idx==6 then
			if not final_shop then
				--pp.coin=min(pp.coin+1000,p_max_coin)
				pp_coin+=1000
				add_flare(42,50,"1000 coins")
				sfx(9)
			end
			final_shop=true
		
		end
		]]--
	else
	--[[
		if l_num!=1 and 
					l_num%10==1 and
					pp.new_biome then
	--]]
		if l_num==0 and pp_new_biome then
			--cb_idx+=1
			final_shop=false
			--if cb_idx>#biome_order then
			--	cb_idx=1
			--end
			if cb_idx==6 then 
				l_num=-1
				pp_coin+=1000
				add_flare(42,50,"1000 coins")
				sfx(9)
			end
			cb_idx=next_b_idx()
			b_num+=1
			cb=biome_order[cb_idx]
			create_cb()
		end
		
		pp_new_biome=false
		init_level()
	end
end

scr_spd=4
function update_scroll()
	if(scroll==0)return
	if scroll<128 then
		scroll+=scr_spd
		pp.y-=scr_spd
		pp_can_die=true
		shop.y-=scr_spd
		for e in all(enemy)do
			e.y-=scr_spd
		end
	else
		scroll=0
	end
end

function draw_scroll()
	for j=0,15 do
	for i=0,15 do
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
	for b in all(bullets)do
		del(bullets,b)
	end
	for f in all(flashes)do
		del(flashes,f)
	end
	for h in all(hps)do
		del(hps,h)
	end
	for e in all(enemy)do
		del(enemy,e)
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
	--l_type="shop"
	shop={
		x=78,y=200,tm=0,idx=0,
		labels={
		"next biome",
		"+1 heart",
		"+1 water tank",
		"+1 bullet spread",
		},
		err_tm=0,
		bought=false,
		bt_tm=0
	}
	level={}
	local gr=cb.blk[3]//cb.ter_gras
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
	for j=0,15 do
			level[j]={}
		for i=0,15 do
			level[j][i]=0
			if i>3 and i<12 and
						j>7 and j<16 then
				level[j][i]=s_level[j-7][i-3]
			end
	end end
	
	add_terrain()
	
	if(b_num>6)pp_new_biome=true
	
	//shop stat 
	pre_shop_coin=pp_coin //stat
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
	if pp_shopping then
		draw_shopping()
	elseif pp.y==shop.y+4 and
				pp.x<shop.x and
				pp.x>shop.x-20 then
		draw_shop_ask()
		pp_can_shop=true
		if btnp(❎) and 
					not pp_shopping and
					not shop.bought then
			pp_shopping=true
			sfx(13)
		else
			shop.bought=false
		end
	else
		if pp_can_shop then
			pp_can_shop=false
			shop.tm=20
		end
		draw_shop_yell()
	end
end

function update_shopping()
	if btnp(🅾️) then
		pp_shopping=false
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
		if(i>0 and price_lvls[i]>4)return
		if(i==0 and pp_new_biome)return
		//local p=b_prices[next_b_idx()]
		local p=200
		if i>0 then
			p=prices[price_lvls[i]]
		end
		if pp_coin>=p then
			if(i>0)price_lvls[i]+=1
			pp_coin-=p
			--printh("spent: "..p)
			shop.bought=true
			pp_shopping=false
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
		pp_new_biome=true
		--printh("  on biome")
	elseif i==1 then
	-- +1 hearts
		pp_hp_tanks+=1
		pp_hp=pp_hp_tanks*4
		-- game_tm+=time_add_shop
		--printh("  on heart")
	elseif i==2 then
	-- +1 water tank
		pp_w_tanks+=1
		--printh("  on tank")
	elseif i==3 then
	-- +1 bullet num
		pp_bullet_num+=1
		--printh("  on spread")
	end
end

function draw_shopping()
	rectfill(10,25,117,68,1)
	rect(9,24,118,69,7)
	
	--biome item
	local b_idx=next_b_idx()
	draw_shop_item(
		biome_order[b_idx].icon,
		17,
		30,
		not pp_new_biome and 200 or nil,
		shop.idx==0)
		
	line(37,30,37,45,0)
	
	--item
	for i=0,2 do
		local p=nil
		if price_lvls[i+1]<5 then
			p=prices[price_lvls[i+1]]
		end
		
		draw_shop_item(i+64,45+(i*26),
			30,p,(i+1==shop.idx))
	end
	
	--label
	if shop.err_tm>0 then
		if flr(shop.tm)%2==0 then
			print("need more coins",
				38,50,7)
			end
	elseif shop.idx>0 and price_lvls[shop.idx]>4 then
		print("sold out",52,50,7)
	elseif shop.idx==0  and pp_new_biome then
		print("biome got",50,50,7)
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
		for i=0,15 do
			pal(i,0)
		end
	end
	--icon
	spr(s,x,y)
	--printh(s)
	
	--price
	if p==nil then
		print("----",x-3,y+11,7)
	else
		spr(48,x-6,y+10)
		print(val_with_zero(p),
			x+2,y+11,7)
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

function draw_first_last(s)
	first.tm+=0.01
	first.y+=cos(first.tm)*0.3
	print(s,26,first.y+101,1)
	print(s,26,first.y+100,7)
	draw_creds()
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
-- slightly modified :)
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

function player_gold()
	--return (b_num==6 and l_num==9) or b_num>6
	return b_num>6
end

function draw_player()
	local pdx=pp.x-pp.w-1
	local pdy=(pp.y-pp.h/2)+1
	
	if(player_gold())pal(7,10)
	if pp_can_die then 
		pal(7,8)
		pal(10,8)
	end
	spr(13,pdx,pdy,1,1,pp_drr==-1,false)
	if pp_tm>0 then
		spr(15,pdx,pdy,1,1,flr(pp_tm)%2==0,false)
	else
		spr(14,pdx,pdy)
	end
	pal()
	
	--off screen
	if pp.x<0 then
		spr(38,0,pp.y)
	elseif pp.x>128 then
		spr(39,120,pp.y)
	end
	
	--water splash
	if touch_water(pp) then
		spr((flr(l_tm)%3)+40,
			pp.x-4,pp.y-4)
	end
	
	--bb
	//draw_bb(pp)
end

p_last_water=-1
function update_player()	
	if pp_hit>0 then
		pp_hit-=1
		if place_free(pp,pp_hit_dx,0) then
			pp.x+=pp_hit_dx
		end
		if place_free(pp,0,pp_hit_dy) then
			pp.y+=pp_hit_dy
		end
		if(pp_hit==3)set_hit()
		return
	end
	
	-- left/right movement
	local move=false
	if btn(⬅️) then
		pp_drr=-1
		move=true
	elseif btn(➡️) then
		pp_drr=1
		move=true
	end
	if move then
		pp_tm+=0.2
		if place_free(pp,1*pp_drr,0) then
			pp.x+=pp_drr
		end
	else
		pp_tm=0
	end
	
	-- vertical pointing
	pp_drr_y=0
	if(btn(⬆️))pp_drr_y=-1
	if(btn(⬇️))pp_drr_y=1
	
	player_jump()
	player_fall()
	player_shoot()
	touch_coin()
	--touch_time()
	touch_hps()
	
	if(pp_w_tm>0)pp_w_tm-=1
	
	if touch_water(pp) and 
				pp_w_tm==0 then
		pp_w_tm=5
		pp_water=min(
			pp_water+1,
			pp_w_tanks*3
		)
	
		if(pp_water%3==1)sfx(3)
		if(pp_water%3==2)sfx(5)
		if	p_last_water%3!=0 and
					pp_water%3==0 then
			sfx(20)
		end
		p_last_water=pp_water
	end
end

jump_t=0
jump_t_max=7
p_max=3
p_max_d=4
p_accel=0.3
function player_jump()
	if btn(🅾️) then
		if not pp_jump_press and 
					(pp_jump<2 or 
					flr(pp_water/3)>0) then
			if pp_water>2 and pp_jump>=2 then
				pp_water-=3
			end
			pp_jump+=1
			jump_t=jump_t_max
			add_sprinkles(pp.x,pp.y)
			sfx(1)
		end
		pp_jump_press=true
		if jump_t>0 then
			pp_dy=-p_max
		end
		jump_t=max(0,jump_t-1)
	elseif pp_jump_press==true then
		pp_jump_press=false
		jump_t=0
	end
end

function player_fall()
	pp_dy=min(p_max_d,pp_dy+p_accel)
	if pp_dy<0 then
		if not place_free(pp,0,min(-1,pp_dy)) then
			pp_dy=1
			sfx(4)
		end
	elseif place_free(pp,0,max(1,pp_dy)) then
		pp_landed=false
	else
		if not pp_landed then
			pp_jump=0
			pp_can_die=false
			add_stomp(pp.x,pp.y)
			pp.y=(flr(pp.y/8)*8)+4
			sfx(6)
		end
		pp_landed=true
		pp_dy=0
	end
	pp.y+=pp_dy
end

function player_shoot()
	if btn(❎) then
		if(pp_shoot!=0)return
		pp_shoot=4
		sfx(10)
		local spread=(pp_bullet_num-1)*5
		for i=0,pp_bullet_num-1 do
			local bx=pp.x+pp_drr
			local by=(pp.y-spread/2)+i*5
			local bdx,bdy=pp_drr*5,0
			
			if pp_drr_y !=0 then
				bx=(pp.x-spread/2)+i*5
				by=pp.y+pp_drr_y
				bdx,bdy=0,pp_drr_y*5
			end
			add_bullet(
				bx,//x
				by,//y
				bdx,//dx
				bdy,//dy
				12,//tm
				player_gold() and 10 or 7,//c
				true,//p
				false)//fall
		end
	end
	if pp_shoot>0 then
		pp_shoot-=1
	end
end

function player_hit(x,y)
	if hit>0 or 
				pp_hit>0 or 
				pp_can_die then
		return
	end
	-- pp.hp-=1
-- 	game_tm-=time_loss
	pp_hp-=2
	pp_hit=5
	//set_hit()
	if x>=pp.x then
		pp_hit_dx=-2
	else
		pp_hit_dx=2
	end
	if y>=pp.y then
		pp_hit_dy=-2
	else
		pp_hit_dy=2
	end
	sfx(16)
end

dead_fin=0
x_press=false
function player_dead()
	dead_fin=(b_num-1)*10+l_num
	
	if pp_d_tm0<3 then
		pp_d_tm0+=0.1
	else
		pp_d_tm1+=1
	end

	if pp_d_cntr==false then
		pp_d_cntr=true
		if flr(pp.x) != 64 then
			pp_d_cntr=false
			pp.x+=sgn(64-pp.x)*0.5
		end
		if flr(pp.y) != 90 then
			pp_d_cntr=false
			pp.y+=sgn(90-pp.y)*0.5
		end
	else
		pp.y+=sin((pp_d_tm1%50)/50)*0.4
	end
	
	if btn(❎) and not x_press then
		x_press=true
		if pp_d_tm1>dead_fin+50 then
			reset()
		elseif not pp_d_cntr then
			pp_d_cntr=true
			pp.x=64
			pp.y=90
			pp_d_tm0=3
			pp_d_tm1=10
		elseif pp_d_tm1<40 then
			pp_d_tm1=40
		elseif pp_d_tm1>50 then
			pp_d_tm1=dead_fin+50
		end
	end
	
	if(not btn(❎))x_press=false
end

-- double text
function dt(t,x,y,c1,c2)
	print(t,x,y+1,c1 or 5)
	print(t,x,y,c2 or 7)
end

function draw_player_dead()
	spr(100+flr(pp_d_tm0),
		pp.x-4,pp.y-4)

	dt("~game over~",42,11)
	
	-- totals
	if pp_d_tm1>10 then
		dt("~totals~",14,29)
	end
	-- total coins
	if pp_d_tm1>20 then
		dt("coins:",8,46)
		dt(pp_coin,32,46,9,10)
	end
	-- total enemies
	if pp_d_tm1>30 then
		dt("enemies:",8,56)
		dt(total_enim,40,56,2,8)
	end
	-- total perfects
	if pp_d_tm1>40 then
		dt("perfects:",8,66)
		dt(total_perf,44,66,13,12)
	end
	
	if(pp_d_tm1<50)return
	
	local tm=pp_d_tm1-50
	local fin=(b_num-1)*10+l_num
	local idx=flr(min(tm,fin)/60)*60
	for i=0,5 do
		for j=0,9 do
			if tm>idx then
				local s=175
				if idx==fin then
					s=185
				elseif idx<fin then
					s=186+i
				end					
				spr(s,62+j*6,40+i*6)
			end
			idx+=1
		end
	end
	
		-- total biomes
	if pp_d_tm1>50 then
		dt("biomes:",77,29)
		dt(min(flr(tm/10)+1,b_num),
			105,29,3,11)
	end
	
	if tm>fin then
		dt("press ❎ to continue",
			24,100,1,7)
	end
end

function touch_coin()
	for c in all(coins)do
		if col_bb(pp,c) then
					
			del(coins,c)
			pp_coin+=c.val
			cur_lvl_cns+=c.val
			--total_coin+=c.val
			add_flare(pp.x,pp.y,c.val)
			
			if #coins==0 then
				perfect=1
				total_perf+=1
				pp_coin+=cur_lvl_cns
				--total_coin+=cur_lvl_cns
				sfx(2)
			else
				if c.val==5 then
					sfx(17)
				elseif c.val==10 then
					sfx(18)
				else
					sfx(12)
				end
			end
			
			--pp.coin=min(pp.coin,p_max_coin)
			--total_coin=min(total_coin,p_max_coin)
			return
		end
	end
end

function touch_hps()
	for h in all(hps)do
		if col_bb(pp,h) then
			del(hps,h)
			pp_hp=min(pp_hp+1,pp_hp_tanks*4)
			sfx(22)
		end
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
-- first level
-- ===================

function init_first()
	--l_type="frst"
	first={tm=0,y=0}
	level={}
	local s_level={
		{1,1,1,1,1,1,1,1},
		{1,1,1,1,1,1,1,1},
		{0,1,1,1,1,1,1,0}
	}
	for j=0,15 do
			level[j]={}
		for i=0,15 do
			level[j][i]=0
			if i>3 and i<12 and
						j>6 and j<10 then
				level[j][i]=s_level[j-6][i-3]
			end
	end end
	create_cb()
	add_terrain()
end

function init_level()
	if l_num==-1 then
		init_first()
		return
	end
	--l_type="norm"
	perfect=0
	local too_small=true
	while too_small do
		level={}
		for j=0,15 do
			level[j]={}
		for i=0,15 do
			level[j][i]=0
		
			if j>cell_pad_v and 
						j<16-(1+cell_pad_v) and
						i>cell_pad_h and 
						i<16-(1+cell_pad_h) then
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

	--extra_e=-1
	extra_cac=false
	extra_mush=false
	extra_sword=false
	extra_beam=false
	extra_ice=false
	
	if b_num>12 then
		--extra_e=rand(0,2)
		if(chance(70))extra_cac=true
		if(chance(70))extra_mush=true
		if(chance(70))extra_sword=true
		if(chance(30))extra_ice=true
		if(chance(30))extra_beam=true
	elseif b_num>6 then
		local r=rand(0,4)
		
		--if r<3 then
		--	extra_e=r
		if r==0 then
			extra_cac=true
		elseif r==1 then
			extra_mush=true
		elseif r==2 then
			extra_sword=true
		elseif r==3 then
			extra_ice=true
		else
			extra_beam=true
		end
	end
	--printh("extra e "..extra_e)
	--printh("extra i "..(extra_ice and "y" or "n"))
	--printh("extra b "..(extra_beam and "y" or "n"))
	--printh(" ")
	local es={add_blob}
	--[[
	if(cb.name=="desert" or extra_e==0)add(es,add_cacti)
	if(cb.name=="dark" or extra_e==1)add(es,add_flame_s)
	if(cb.name=="fungi" or extra_e==2)add(es,add_blob_2)
	]]--
	if(cb.name=="desert" or extra_cac)add(es,add_cacti)
	if(cb.name=="dark" or extra_mush)add(es,add_flame_s)
	if(cb.name=="fungi" or extra_sword)add(es,add_blob_2)
	if l_num>4 or b_num>12 then
		for nyse=0,mid(0,flr(b_num/6)-1,5)do
			--
			--printh(nyse)
			local i=rand(1,#es)
			add(es,es[i])
		end
	end
	for f in all(es)do
		f()
	end 
end

function add_terrain()
	--do top
	if last_level then
	for i=0,15 do
		if level[0][i]==0 then
			--if below water
			if last_level[15][i]==ter_pipe or
						last_level[15][i]==ter_watr or
						last_level[15][i]==pas_watr then
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
	
	for j=1,14 do
	for i=1,14 do
		--if solid
		if level[j][i]==1 then
			level[j][i]=ter_rock
			--add random blocks
			if chance(10) then
				level[j][i]=cb.blk[0]//cb.ter_bloc
			elseif chance(10) then
				level[j][i]=ter_pipe
			end
			
			--add potential start point
			if level[j-1][i]==0 or 
						level[j-1][i]==pas_watr then
				add(player_start_points,{
					j=j-1,i=i
				})
			end
			
			--if top rock
			if level[j-1][i]==0 then
				level[j][i]=cb.blk[3]//cb.ter_gras
				if chance(10) then
					level[j][i]=cb.blk[0]//cb.ter_bloc
				end
				--add potential start point
				--[[
				add(player_start_points,{
					j=j-1,i=i
				})
				]]--
				--add flower
				if chance(30) then
					level[j-1][i]=
						//rand(cb.pas_flw1,cb.pas_flw2)
						rand(cb.blk[4],cb.blk[5])
				--add tree
				elseif chance(30) then
					local rh=rand(1,3)
					for k=1,rh do
						level[j-k][i]=cb.blk[6]//cb.pas_stem
					end
					--printh(i.." "..j)
					--printh(j-(rh+1))
					level[max(j-(rh+1),0)][i]=cb.blk[7]//cb.pas_tree
				end
			--if below grass
			//elseif level[j-1][i]==cb.ter_gras then
			elseif level[j-1][i]==cb.blk[3] then
				if level[j][i]==ter_rock then
					level[j][i]=cb.blk[1]//cb.ter_roc2
				else
					level[j][i]=cb.blk[2]//cb.ter_blc2
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
	for i=0,15 do
		if level[15][i]==0 then
			--if below water
			if level[14][i]==ter_pipe or
						level[14][i]==ter_watr or
						level[14][i]==pas_watr then
				level[15][i]=pas_watr
			end
		end
	end
end

function cell_auto()
	for k=0,cell_autos do
		//print_level()
		local a=copy_table(level)
		for j=1,14 do
		for i=1,14 do
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
	for j=0,15 do
	for i=0,15 do
		num+=level[j][i]
	end end
	return num<1
end

function get_surr(j,i)
	local n=0
	for jj=max(j-1,0),min(j+1,15) do
	for ii=max(i-1,0),min(i+1,15) do
		if(level[jj][ii]==1)n+=1
	end end
	if(level[j][i]==1)n-=1
	return n
end

function draw_level()
	l_tm+=0.2
	for j=0,15 do
	for i=0,15 do
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
	//draw_times()
end

function add_coins()
	coins={}

	local low,high=12,30
	if b_num>6 then
		low,high=25,45
	end
	local min_v=rand(low,high)

	while min_v>0 do
		local ri,rj=rand(0,15),rand(0,14)
		if level[rj][ri]==0 then
			level[rj][ri]=-1
			local v=1
			local red,green=13,30
			if b_num>6 then
				red,green=20,50
			end
			local c=rand(1,100)
			if c<=red then
				v=10
			elseif c<=green then
				v=5
			end
			min_v-=v
			
			add(coins,{
				x=ri*8+4,y=rj*8+4,w=8,h=8,
				tm=0,val=v
			})
		end
	end
end

function draw_coins()
	for c in all(coins)do
		c.tm+=0.1
		if c.val==5 then
			pal(9,3)
			pal(10,11)
		elseif c.val==10 then
			pal(9,2)
			pal(10,8)
		end
		spr((flr(c.tm)%4)+52,
			c.x-c.w/2,
			c.y-c.h/2)
		pal()
		--draw_bb(c)
	end
end

-->8
-- enemies

-- general
function draw_enemies()
	for e in all(enemy)do
		if e.hit_t!=nil and e.hit_t>0 then
			for i=0,15 do
				pal(i,7)
			end
		end
		if(e.tp=="blob")draw_blob(e)
		if(e.tp=="bat")draw_bat(e)
		if(e.tp=="cactus")draw_cactus(e)
		if(e.tp=="icicle")draw_icicle(e)
		if(e.tp=="flame")draw_flame(e)
		if(e.tp=="flame_s")draw_flame_s(e)
		if(e.tp=="beam")draw_beam(e)
		pal()
	end
end

function update_enemies()
	if(l_num==9)return
	
	for e in all(enemy)do
		if(e.tp=="blob")update_blob(e)
		if(e.tp=="bat")update_bat(e)
		if(e.tp=="cactus")update_cactus(e)
		if(e.tp=="icicle")update_icicle(e)
		if(e.tp=="flame")update_flame(e)
		if(e.tp=="flame_s")update_flame_s(e)
		if(e.tp=="beam")update_beam(e)
		if(e.hit_t!=nil and e.hit_t>0)e.hit_t-=1
	end
	if((cb.name=="ice" or extra_ice) and chance(2))add_icicles()
	--if((cb.name=="heaven" or extra_beam) and chance(1))add_beam()
		if((cb.name=="heaven" or extra_beam))spawn_beam()
end

function damage_enemy(e)
	add_flash(e.x,e.y)
	
	if(e.hp==nil)return
	
	e.hp-=1
	e.hit_t=5
	if e.hp<=0 then
		-- add_flare(b.x,b.y,time_add_blob)
		add_hps(e.x,e.y,e.hpc)
		total_enim+=1
		del(enemy,e)
	end
end

-- blobs
function add_blob()
	add_blob_hp(1)
end

function add_blob_2()
	add_blob_hp(3)
end

function add_blob_hp(hp)
	local idx=rand(1,#player_start_points)
	local bt=player_start_points[idx]
	--[[
	if bt==nil then
		for i=0,20 do
			printh("======= here =======")
		end
		printh("idx "..idx)
		printh("psp "..#player_start_points)
		return
	end
	]]--
	--printh("=here=")
	--printh(#player_start_points)
	--printh(idx)
	--printh(bt)
	--print_level()
	--printh(pp.hp)
	local bdx=1
	if(chance(50))bdx=-1
	add(enemy,{
		tp="blob",
		x=(bt.i*8)+4,
		y=((bt.j*8)+4)+128,
		w=6,h=6,dx=bdx,
		tm=0,hp=hp,
		dark=hp==3,
		shoot=false,
		hpc=10,
		hit_t=0
	})
end

function draw_blob(b)
	local bx=b.x-b.w/2
	local by=b.y-b.h/2
	local s=89
	if b.dark then
		//pal(2,8)
		//pal(14,9)
		s=105
	end
	spr(s+flr(b.tm)%2,
		bx,by,1,1,
		b.dx==-1,false)
	pal()
	--draw_bb(b)
end

function update_blob(b)
	b.tm+=0.1
	if(b.dark)b.tm+=0.1
	if(col_bb(pp,b))player_hit(b.x,b.y)
	b.x+=b.dx*(b.dark and 0.2 or 0.1)
	if point_free(b.x,b.y+4) or
				not place_free(b,b.dx*0.1,0) then
		b.dx*=-1
	end
	if(not b.dark)return
	if flr(b.tm)%6==0 and b.shoot==false then
		b.shoot=true
		add_bullet(
			b.x,b.y,0,-6,
			100,15,
			false,true)
		--[[
		add_bullet(
			b.x,b.y,-2,-5,
			100,1,11,
			false,true)
		]]--
		sfx(19)
	elseif flr(b.tm)%6!=0 then
		b.shoot=false
	end
end

-- bats

function add_bats()
	-- todo, should this chance
	-- be determined by the level
	-- gen code??
	local bc=(l_num-1)*10
	if not chance(bc) then
		return
	end
	local bmin,bmax=1,2
	if(l_num>5)bmin,bmax=2,3
	if(l_num>7)bmin,bmax=3,5
	for i=1,rand(bmin,bmax) do
		local finding=true
		while finding do
			local ri=rand(1,14)
			local rj=rand(1,14)
			if level[rj][ri]==0 then
				finding=false
				add(enemy,{
					tp="bat",
					x=ri*8,
					y=(rj*8)+128,
					w=7,h=7,
					oy=rj*8,
					tm=0,hp=2,
					ytm=0,xtm=0,
					hpc=10,
					hit_t=0
				})
				--y=((bt.j*8)+4)+128,
			end
		end
	end
end

function draw_bat(b)
	local bx=b.x-b.w/2
	local by=b.y-b.h/2
	spr(88,bx,by,1,1,
	sin(b.xtm)<0,false)
	spr(flr(b.tm)%4+84,bx,by-4)
	--draw_bb(b)
end

function update_bat(b)
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
	elseif bi>15 then
		b.xtm=0
	elseif pt>=ter_rock and 
				//pt<cb.pas_flw1 then
				pt<cb.blk[4] then
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
				100,14,false,false)
			sfx(19)
		end
	end
end

-- cactus
function add_cacti()
	local idx=rand(1,#player_start_points)
	local bt=player_start_points[idx]
	add(enemy,{
		tp="cactus",
		x=(bt.i*8)+4,
		y=((bt.j*8)+4)+128,
		w=8,h=8,
		tm=0,hp=2,
		shoot=false,
		hpc=10,
		hit_t=0
	})
end	

function draw_cactus(c)
	local cx=c.x-c.w/2
	local cy=c.y-c.h/2
	local ox=0
	if flr(c.tm)%4==1 or 
				flr(c.tm)%4==3 then
		ox=1
	end
	spr(91,
		cx,cy+ox,1,1,
		c.tm<2,false)
	--draw_bb(c)
end

function update_cactus(c)
	c.tm+=0.2
	if(col_bb(pp,c))player_hit(c.x,c.y)
	if flr(c.tm)%8==0 and c.shoot==false then
		c.shoot=true
		add_bullet(
			c.x,c.y,2,-5,
			100,11,
			false,true)
		add_bullet(
			c.x,c.y,-2,-5,
			100,11,
			false,true)
		sfx(19)
	elseif flr(c.tm)%8!=0 then
		c.shoot=false
	end
end

-- icicle
function add_icicles()
	local ri=rand(0,15)
	add(enemy,{
		tp="icicle",
		x=ri*8,y=4,dy=0,w=5,h=7,
		0,0,tm=0,falling=false,
		hpc=0,
		hp=10000
		})
end

function draw_icicle(i)
	local ix=i.x-i.w/2
	local iy=i.y-i.h/2
	if i.tm>=5 or flr(i.tm)%2==0 then
		spr(92,ix,iy)
	end
	--draw_bb(i)
end

icicle_fall_accel=0.1
icicle_fall_max=3
function update_icicle(i)
	i.tm+=0.2
	if i.tm<5 then
		return
	end
	if not i.falling then
		sfx(19)
	end
	i.falling=true
	if(col_bb(pp,i))player_hit(i.x,i.y)
	i.dy=min(
		i.dy+icicle_fall_accel,
		icicle_fall_max)
	i.y+=i.dy
	if i.y>180 then
		del(enemy,i)
	end
end

--[[
function spawn_icicles()
	if chance(2) then
		add_icicles()
	end
end
]]--

function add_flame(x,y)
	add(enemy,{
		tp="flame",
		x=x,y=y,
		w=8,h=8,tm=0,
		--hp=hp_flame,
		hpc=0,
		--a=atan2(pp.x-x,pp.y-y)
		a=0
	})
end

function draw_flame(f)
	local fx=f.x-f.w/2
	local fy=f.y-f.h/2
	if(f.tm<6 and flr(f.tm)%2==0)return
	spr(93+flr(f.tm%3),fx,fy)
	//pal()
	--draw_bb(i)
end

function update_flame(f)
	f.tm=f.tm+0.3
	if f.tm<6 then
		f.a=atan2(pp.x-f.x,pp.y-f.y)
		return
	end
	f.x+=1.5*cos(f.a)
	f.y+=1.5*sin(f.a)
	if(col_bb(pp,f))player_hit(f.x,f.y)
end

function add_flame_s()
	local idx=rand(1,#player_start_points)
	local bt=player_start_points[idx]
	add(enemy,{
		tp="flame_s",
		x=(bt.i*8)+4,
		y=((bt.j*8)+4)+128,
		w=8,h=8,
		tm=0,
		hpc=100
	})
end

function draw_flame_s(f)
	local fx=f.x-f.w/2
	local fy=f.y-f.h/2
	
	//palt(0,false)
	//palt(7,true)
	palt(0b0000000100000000)
	 
	// flame_spawn_t=20
	spr(123+max(
			flr(f.tm)-(20-5),
			0),
		fx,fy)
	--draw_bb(f)
	pal()
end

function update_flame_s(f)
	f.tm=f.tm+0.3
	if f.tm>20 then
		f.tm=0
		if chance(50) then
			add_flame(f.x,f.y)
		end
	end
end

function add_beam(d)
	local w,h,x,y=128,8,64,pp.y
	if(chance(50))w,h,x,y=8,128,pp.x,64
	add(enemy,{
		tp="beam",
		x=x,y=y,w=w,h=h,
		tm=0,
		hpc=0
		})
end

function draw_beam(b)
	if b.tm<5 then
		if(flr(b.tm)%2==0)return
		if b.x==64 then
			line(0,b.y,128,b.y,7)
		else
			line(b.x,0,b.x,128,7)
		end
	elseif b.tm>=6 then
		local of=flr(b.tm)
		if b.x==64 then
			line(0,b.y-of,128,b.y-of,7)
			line(0,b.y+of,128,b.y+of,7)
		else
			line(b.x-of,0,b.x-of,128,7)
			line(b.x+of,0,b.x+of,128,7)
		end
	else
		rectfill(
			b.x-b.w/2,b.y-b.h/2,
			b.x+b.w/2,b.y+b.h/2,10)
	end
	--draw_bb(b)
end

function update_beam(b)
	b.tm+=0.2
	if(b.tm>5 and b.tm<6 and col_bb(pp,b))player_hit(b.x,b.y)
	if(b.tm>8)del(enemy,b)
end

beam_st=150
function spawn_beam()
	//if(chance(2))add_beam()
	beam_st-=1
	if beam_st==50 and chance(30) then
		--printh("spawn 50")
		add_beam()
	end
	if beam_st==0 then
		--printh("spawn 100")
		beam_st=150
		add_beam()
	end
end

__gfx__
00000000111111110000000000000001110000000000000000000000dddddddd000000000000000ddd0000000000000000000000007777000000000000000000
00000000111111110000000000000111111000000000000000000000dddddddd0000000000000dddddd000000000000000000000007777000000000000000000
00000000111111110000000000001111111100000000000000000000dddddddd000000000000dddddddd00000000000000000000007c7c000000000000000000
00000000111111110000000000011111111110000000001111000000dddddddd00000000000dddddddddd000000000dddd000000007777000000000000000000
00000000111111110000000000011111111110000000111111110000dddddddd00000000000dddddddddd0000000dddddddd0000000000000070070000700700
00000000111111110011110000111111111111000001111111111000dddddddd00dddd0000dddddddddddd00000dddddddddd000000000000070070000000700
00000000111111110111111001111111111111000111111111111000dddddddd0dddddd00ddddddddddddd000dddddddddddd000000000000000000000000000
00000000111111111111111111111111111111101111111111111110ddddddddddddddddddddddddddddddd0ddddddddddddddd0000000000000000000000000
011111110555555005cccc50000777000001110000077700000777000007770000077700000777000007770000cc7c0000cccc0000c7770000cccc0000000000
10111000500ff00550cccc05000c7c000010001000700070007000700070007000700070007c0c700070c0700077c70000cc7c0000cccc000077770000000000
d05101dd50f00f0550cccc05000707000010001000700070007000700070cc70007c0070007ccc70007ccc7000cccc000077770000cccc0000cccc0000000000
dd0011dd5f00c0f55fccccf50000000000100010006cc06000600c60006ccc60006ccc60006ccc60006ccc6000cccc0000cccc00007c770000cccc0000000000
dd05011d5fccccf55fccccf5000060000001110000066600000666000006660000066600000666000006660000cccc0000cccc0000cccc00007cc70000000000
d015501150cccc0550cccc05000000000000000000000000000000000000000000000000000000000000000000cccc0000cccc0000cccc0000c77c0000000000
0111550150cccc0550cccc05000000000000000000000000000000000000000000000000000000000000000000c7770000cccc0000cccc0000cccc0000000000
1111111005cccc5005cccc50000000000000000000000000000000000000000000000000000000000000000000cccc00007c770000cccc0000cccc0000000000
0220000008080000010100000801000008010000080100000008000000008000070000c00c0000000c0007000000000004000000000000400000000000000000
2e8200008288800011111000828110008281100082811000008800000000880000c70c007000007c0000c000000000000400000000000040444d44d444d4d444
288200008288800011111000828880008281100082111000088888888888888000000000000000000000000c000070000400000000000040040d00d000d0d040
0220000008880000011100000888000008810000011100008888888888888888000000000000000070000000000777000c00b00000009040000d00d00000d000
000000000080000000100000008000000080000000100000088888888888888000000000000000000000000000007000ffddddfdffdffdff040d00d000000040
00000000000000000000000000000000000000000000000000880000000088000000000000000000000000000000000004ddd04d04dd0d40040000d000000040
000000000000000000000000000000000000000000000000000800000000800000000000000000000000000000000000000d0000000d00000400000000000040
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000040040000400400000000000040
000aaa000000a0000000a0000000a000009999000009900000099000000990000000000000000000000000000000000000000000071117000000000000000000
00a000a0000a0a000000a000000a0a0009aaaa90009aa900009aa900009aa900088088000000000000f0ff0000f0ff0000f0ff00007117000000000000000000
00a009a0000a9a000000a000000a9a009aaaaaa909aaaa90009aa90009aaaa908288888000f6ff00006666006066660600666600000717000000000000007700
00a099a0000a9a000000a000000a9a009aaaa9a909aa9a90009aa90009a9aa908288888000969600009696006096960600969600000070000000000000007700
000aaa000000a0000000a0000000a0009aaaa9a909aa9a90009aa90009a9aa900828880000666600006666000066660060666606000000000000000000000000
000000000000000000000000000000009aa99aa909aaaa90009aa90009aaaa900088800000666600006666000066660060666606000000000000000000000000
0000000000000000000000000000000009aaaa90009aa900009aa900009aa9000008000000666600006666000066660000666600000000000000000000000000
00000000000000000000000000000000009999000009900000099000000990000000000000600600006006000060060000600600000000000000000000000000
0700000007000000070000000700000000000000000000000000000000000000000000000000000000000000b0000000aaa00000ccc000008080000000000000
7770000077700000777000007770000007777700077777000777770007777700077777000077770007777770b0000000aaa000000c0000008880000000000000
07000000070077700700000007000000077cc770077ccc00077cc770077ccc00077ccc00077ccc000cc77cc0bb000000a0000000cc0000008080000000000000
000808000007000700000c0000000000077777c007777000077777c0077770000777700007700000000770000000000000000000000000000000000000000000
008288800007cc070777000007770000077ccc00077cc000077c7700077cc000077cc0000770000000077000b0b0b000aaa0aa00ccc0ccc08880000000000000
008288800007ccc70c7c0c000c7c0c0c07700000077777000770c77007700000077777000c77770000077000b0b0b0000a00a000c0c0ccc08880000000000000
000888000006ccc607070000070700000cc000000ccccc000cc00cc00cc000000ccccc0000cccc00000cc0000b00bb000a0aa000c0c0c0008000000000000000
000080000000666000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000070000000700000000000000000000000000000000000000000000000000000000000000000bb0000766dc0000000c000000c00000000000
000000000000000077700000777077700000000000000000000000000000000000111000000220000000000000b33b000766dc0000000c000000c00000c00000
0000000000000000070000000700c7c00111111000111100001111000011110001888100002ee2000022220000b33b0b0766dc0000c0c1c0000c1c0000cc000c
00066000000000000000ccc000007070188ee8810188e81000188100018e88100187871002eeee2002eeee20bbb7370b0076c0000c1c11c00cc111c00cc1c0cc
00066000000000007770ccc000000000011ee110001ee100001ee100001ee1001888881002e7e7202eeeeee2b0b33bbb0076c000c111111cc111111cc1111c1c
0000000000000000c7c0ccc000000600000110000001100000011000000110001888110002eeee202eee7e72b0b33b000077c000c11ff11cc11ff11cc11ff11c
00000000000000007070000000000000000000000000000000000000000000001811000000222200022222200b3bb3b0000700000c1ff1c00c1ff1c00c1ff1c0
00000000000000000000000000000600000000000000000000000000000000000100000000000000000000000bb00bb00000000000cccc0000cccc0000cccc00
000000000000000000000000000000000000000000000000000000000000000000000000000dd000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000006700000000000000000000d99d0000dddd000000000000000000000000000000000000000000
0000000000000000000000000000000000777700000677700007777000076770000000000d8888d00d8998d00099990000888800000000000000000000000000
0000000000000000000000000000000000777700007777700077677000777770000000000d9787d0d888888d0988889008999980000000000000000000000000
0000000000000000000000000000000000676700007767000777777000776770000000000d9888d0d998787d9888888989999998000000000000000000000000
00000000000000000000000000000000007777000077770007077000070700000000000000dddd000dddddd09888787989997978000000000000000000000000
00000000000000000000000000000000007007000070070007007000070700000000000000600600000660000999999008888880000000000000000000000000
00000000000000000000000000000000007007000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa000000000000000007777770777777707777777077777770777777707
000000000aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa00000000000000007707001077070010770700107707001077070060
00000000aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa00000000000000007010110770601107701011077010160770101107
00000000aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa00000000000000007701107777011077770610777701607777011077
00000000aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa00000000000000007701107777011077770610777701607777011077
00000000aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa00000000000000007010010770100107706001077010060770100107
00000000aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa00000000000000007010707770107077706070777010707770107077
000000000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa00000000000000000107777706077777010777770107777701077777
0555555003113113035535530131b1b000000000000000000004400000ffff00055555500911911a0a55a55a01a1a1a00000000000000a000007f00000777700
50dddd051311300353dd3d033b1b13300000000000000000000f90000f0000f05044440519119009594494099a1a19900000000f00a0a000000f700007000070
5d0dd0d5d05301d35d0dd3d3b331333d000000000000000000044000f00f000f54044045405a014954044949a991aaad00a000fa0a00a00a000ff00070070007
5dd00dd5dd0311dd53d03dd533b3b13b0000000000e0e00000094000f0f0007f54400445440911445940944599a9a1aa0faf0faf0a0a0aa00007f00070700077
5dd00dd5dd05011d5dd03dd3b303033d00000000000a000000044000f000707f544004454405011454409449a90909ad0fa00af00aa0a090000ff00070007077
5d0dd0d5d01550115d0dd0d5d3135b330008000000e0e00000099000f000077f540440454015501154044045d9194a9a09f0fa00a0a090a00007700070000777
50dddd050111550150dddd050113550300898000000300000004f0000f0777f05044440501115501504444050119440909f09f00909a0a00000f700007077770
0555555011111110055555501311311300080000003000000004400000ffff00055555501111111005555550191191190900900099a90909000ff00000777700
055555500611611676d67d7076767670000000000000000000077000007777000000000002112112021021220020202000000000000000000000100000000100
5066660516116006dddd777767777777000000000000000000077000077770700011110011111001111111012202011000000010000001000001000000001010
56066065d05601d67d7d7dc7707777c7000000000000000000047000777607070101101010510101110110112110111d00101100000011100000100000001001
56600665dd0611dddddc07d76c7c07070000000000e070000009d000776776d70110011015011101111011011121201200011000010001000000100000100101
56600665dd05011dd07ddc06607ccc0600000000000a0000000dd000d06076670110011005050111110011011101011d00011000000001000000100001010101
56066065d0155011dddd70d66c0c70c6000700000070700000099000d0007667010110100005501111011011d101511100100100010001000001000010001001
5066660501115501ddddddd667c607c60079700000636000000df0000d7d7dd70011110000005501101111010001550100100000010001000001000001000010
055555501111111067606760676067600668660006366600000dd00007dddd000000000000000110011111100100100101000000010001000001000000111100
0555555009ff9ff90fffff5f0fffff9f00000000003003000004400000ffff0000000000e000e000000000000000000000000000000000000000000000000000
50ffff05f9ff900959ff9dfff99ff9f90000000000b03b00000f90000f0000f0000000000e0e0e00000000000000000000000000000000000000000000111000
5f0ff0f5f9f90ff9fffff9f99ffff999000000000003330300044000f00f000f00000000e0900080000000000000000000000000000000000000000000001000
5ff00ff5ff99fff9f9ff9ff5ff99fff9000000000300b30b00094000f0f0007f0000000080090000000000000000000000000000000000000000000000010000
5ff00ff5df090ffdfdff9ff9f99f09ff40000400b330333000044000f000707f0800000000809800000000000000000000000000000000000000000000000000
5f0ff0f5d0155ff1fd0fd0f5ff9950f90400400033b0330000099000f000077f0800080000009000000000000000000000000000000000000000000000010000
50ffff050111550150dddd0509ff55f100440400b3303b000004f0000f0777f00000808000090000000000000000000000000000000000000000000000000000
055555501111111005555550191191900040000033b033000004400000ffff000808000000900000000000000000000000000000000000000000000000000000
055555500e11e11e0e55e55e0e12e21e00000000000000000004400000fefe000000000000000000000000000000000000000000000000000000000000000000
50dddd051211200e5edd2d0ee2e12e2e0000000000000000000f90009f000ef000111000081118000b3b3b000f9f9f00076767000e2e2e0001d1d1000a9a9a00
5d0dd0d5d05e01d25d0dd2de20eee222000000000000998000044000800f090e015551000185810003b3b30009f9f9000676760002e2e2000d1d1d0009a9a900
5dd00dd5d20211dd52d02dd5dd2e222e000000000809899900094000f0e0087e11555110015851000131310001919100016161000121210001d1d10001919100
5dd00dd5d202011d5dd02dd2de25eeed000000008880050000044000e0e0707e0155510001858100011111000111110001111100011111000111110001111100
5d0dd0d5d21550115d0dd0d5d02550ee006000000500060000099000e090077e0011100008111800001110000011100000111000001110000011100000111000
50dddd050211550150dddd050111550e06660000006000600004f0009f8777f90000000000000000000000000000000000000000000000000000000000000000
0555555011111110055555501121111000500000060000600004400080ffff080000000000000000000000000000000000000000000000000000000000000000
44444440444440004444400044444000004400004400440007000000000000000000000000000000000000000000000000000000000000000000000000000000
407700404fff40004666400046664000004640004f44640077700000000000000000000000000000000000000000000000000000000000000000000000000000
0470040004f4000004f4000004640000444664004ff6640007044444000000000000000000000000000000000000000000000000000000000000000000000000
004040000464000004f4000004f400004ff444004f4464000004fff4000000000000000000000000000000000000000000000000000000000000000000000000
004f40004666400046f640004fff400004f400004400440000004f40000000000000000000000000000000000000000000000000000000000000000000000000
04fff400444440004444400044444000004400000000000000004640000000000000000000000000000000000000000000000000000000000000000000000000
4fffff40000000000000000000000000000000000000000000046664000000000000000000000000000000000000000000000000000000000000000000000000
44444440000000000000000000000000000000000000000000044444000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777700
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007c7c00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700700
__label__
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cc7c0000cc7c0000000000000000000000000000cc7c0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000777700007777000000000000000000000000000077770000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
000000000000000000000000000000000000000000000000007c7700007c7700000000000000000000000000007c770000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000099000000000000009900000000000
00000000000000000000000000000000000000000000000000cc7c0000cc7c0000000000000000000000000000cc7c00009aa90000000000009aa90000000000
000000000000000000000000000000000000000000000000007777000077770000000000000000000000000000777700009aa90000000000009aa90000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc00009aa90000000000009aa90000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc00009aa90000000000009aa90000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc00009aa90000000000009aa90000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc00009aa90000000000009aa90000000000
000000000000000000000000000000000000000000000000007c7700007c7700000000000000000000000000007c770000099000000000000009900000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cc7c0000cc7c0000000000000000000000000000cc7c0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000777700007777000000000000000000000000000077770000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000000000000000000000000000000
000000000000000000000000000000000000000000000000007c7700007c7700000000000000000000000000007c770000000000000000000000000000000000
00000000000000000000000000099000000000000000000000cccc0000cccc0000000000000000000000000000cccc0000000100000000000009900000000000
000000000000000000000000009aa900000000000000000000cc7c0000cc7c0000000000000001000000010000cc7c000000101000000000009aa90000000000
000000000000000000000000009aa90000000000000000000077770000777700000000000000111000001110007777000000100100000000009aa90000000000
000000000000000000000000009aa900000000000000000000cccc0000cccc0000000000010001000100010000cccc000010010100000000009aa90000000000
000000000000000000000000009aa900000000000000000000cccc0000cccc0000000000000001000000010000cccc000101010100000000009aa90000000000
000000000000000000000000009aa900000000000000000000cccc0000cccc0000000000010001000100010000cccc001000100100000000009aa90000000000
000000000000000000000000009aa900000000000000000000cccc0000cccc0000000000010001000100010000cccc000100001000000000009aa90000000000
000000000000000000000000000990000000000000000000007c7700007c7700000000000100010001000100007c770000111100000000000009900000000000
00000000000000000000000000000000000000000000000000cccc0000cccc000000000000202020002020200111111100001000000000000009900000000000
00000000000000000000000000000000000000000000000000cc7c0000cc7c00000001002202011022020110101110000001006000000000009aa90000000000
0000000000000000000000000000000000000000000000000077770000777700000011102110111d2110111dd05101dd0010110000000000009aa90000000000
00000000000000000000000000000000000000000000000000cccc0000cccc00010001001121201211212012dd0011dd0001100000000000009aa90000000000
00000000000000000000000000000000000000000000000000cccc0000cccc00000001001101011d1101011ddd05011d0001100000000000009aa90000000000
00000000000000000000000000000000000000000000000000cccc0000cccc0001000100d1015111d1015111d01550110011010000000000009aa90000000000
00000000000000000000000000000000000000000000000000cccc0000cccc00010001000001550100015501011155010011000000000000009aa90000000000
000000000000000000000000000000000000000000000000007c7700007c77000100010001001001010010011111111001010000000000000009900000000000
00000000000000000000000000000000000000000000000000cccc0000cccc000020202002102122021121120000000000202020000000000000000000000000
00000000000000000000000000000000000000000000000000cc7c0000cc7c002202011011111101111110010011110022020110000000000000000000000000
00000000000000000000000000000000000000000000000000777700007777002110111d1101101110510101010110102110111d000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc001121201211101101150111010110011011212012000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc001101011d1100110105050111011001101101011d000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc00d1015111110110110005501101011010d1015111000000000000000000000000
00000000000000000000000000000000000000000000000000cccc0000cccc000001550110111101000055010011110000015501000000000000000000000000
000000000000000000000000000000000000000000000000007c7700007c77000100100101111110000001100000000001001001000000000000000000000000
00000000000000000000000000000000000000000000000000ccccc0007ccc000211211201111111011111110111111102112112000000000000000000000000
00000000000000000000000000000000000000000000001000cc7c000ccc7c001111100110111000101110001011100011111001000000000000000000000000
000000000000000000000000000000000000000000101100007777077777c70010510101d05101ddd05101ddd05101dd10510101000000000000000000000000
00000000000000000000000000000000000000000001100000ccc707777ccc0015011101dd0011dddd0011dddd0011dd15011101000000000000000000000000
00000000000000000000000000000000000000000001100000cccc07c7cccc0005050111dd05011ddd05011ddd05011d05050111000000000000000000000000
00000000000000000000000000000000000000000010010000cccc07777ccc0000055011d0155011d0155011d015501100055011000000000000000000000000
00000000000000000000000000000000000000000010000000cccc07007ccc000000550101115501011155010111550100005501000000000000000000000000
000000000000000000000000000000000000000001000000007c7707007c77000000011011111110111111101111111000000110000000000000000000000000
00000000000000000000000000000000000000000020202001111111011111110111111101111111011111110111111105555550000000000000000000000000
000000000000000000000000000000000000000022020110101110001011100010111000101110001011100010111000500ff005000000000000000000000000
00000000000000000000000000000000000000002110111dd05101ddd05101ddd05101ddd05101ddd05101ddd05101dd50f00f05000000000000000000000000
000000000000000000000000000000000000000011212012dd0011dddd0011dddd0011dddd0011dddd0011dddd0011dd5f00c0f5000000000000000000000000
00000000000000000000000000000000000000001101011ddd05011ddd05011ddd05011ddd05011ddd05011ddd05011d5fccccf5000000000000000000000000
0000000000000000000000000000000000000000d1015111d0155011d0155011d0155011d0155011d0155011d015501150cccc05000000000000000000000000
00000000000000000000000000000000000000000001550101115501011155010111550101115501011155010111550150cccc05000000000000000000000000
00000000000000000000000000000000000000000100100111111110111111101111111011111110111111101111111005cccc50000000000000000000000000
00000000000000000000000000000000000000000211211200000000000000000000000001111111011111110111111100cccc00000000000000000000000000
00000000000000000000000000000000000000001111100100111100000000000000000010111000101110001011100000cc7c00000000000000000000000000
000000000000000000000000000000000000000010510101010110100000000000000000d05101ddd05101ddd05101dd00777700000000000000000000000000
000000000000000000000000000000000000000015011101011001100000000000000000dd0011dddd0011dddd0011dd00cccc00000000000000000000000000
000000000000000000000000000000000000000005050111011001100000000000000000dd05011ddd05011ddd05011d00cccc00000000000000000000000000
000000000000000000000000000000000000000000055011010110100000000000000000d0155011d0155011d015501100cccc00000000000000000000000000
00000000000000000000000000000000000000000000550100111100000000000000000001115501011155010111550100cccc00000000000000000000000000
000000000000000000000000000000000000000000000110000000000000000000000000111111101111111011111110007c7700000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000011111110000000000cccc00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000101110000000000000cc7c00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000d05101dd0000000000777700000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000dd0011dd0000000000cccc00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000dd05011d0000000000cccc00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000d01550110000000000cccc00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000011155010000000000cccc00000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000007c7700000000000000000000000000
00000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000000000cccc00000000000000000000000000
00000000000000000000000000000000000000011111100000000000000000000000000000000000000000000000000000cc7c00000000000000000000000000
00000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000777700000000000000000000000000
00000000000000000000000000000000000001111111111000000000000000000000000000000000000000000000000000cccc00000000000000000000000000
00000000000000000000000000000000000001111111111000000000000000000000000000000000000000000000000000cccc00000000000000000000000000
00000000000000000000111100001111000011111111111100000000000000000000111100000000000000000000000000cccc00000000000000000000000000
00000000000000000001111110011111100111111111111100000000000000000001111110000000000000000000000000cccc00000000000000000000000000
000000000000000000111111111111111111111111111111100000000000000000111111110000000000000000000000007c7700000000000000000000000000
00000000000000000111111111111111111111111111111111000000000000000111111111110000000000000000000000cccc00000000000000000000099000
00000000000000011111111111111111111111111111111111000000000000011111111111111000000000000000000000cc7c000000000000000000009aa900
000000000000001111111111111111111111111111111111110000000000001111111111111111000000000000000000007777000000000000000000009aa900
00000000000001111111111111111111111111111111111111110000000001111111111111111110000000000000000000cccc000000000000000000009aa900
00000000000001111111111111111111111111111111111111111100000001111111111111111110000000000000000000cccc000000000000000000009aa900
00000000000011111111111111111111111111111111111111111110000011111111111111111111000000000000000000cccc000000000000000000009aa900
00000000000111111111111111111111111111111111111111111110000111111111111111111111000000000000000000cccc000000000000000000009aa900
000000000011111111111111111111111111111111111111111111111011111111111111111111111000000000000000007c7700000000000000000000099000
00000000011111111111111111111111111111111111111111111111111111111111111111111111111990000000000000cccc00000ddd000000000001110000
00000001111111111111111111111111111111111111111111111111111111111111111111111111119aa9000000000000cc7c000dddddd00000000111111000
00000011111111111111111111111111111111111111111111111111111111111111111111111111119aa9000000000000777700dddddddd0000001111111100
0000011111dddd111111111111111111111111111111111111111111111111111111111111111111119aa9100000000000cccc0dddddddddd000011111111110
00000111dddddddd1111111111111111111111111111111111111111111111111111111111111111119aa9100000000000cccc0dddddddddd000011111111110
0000111dddddddddd11111dddd111111111111111111111111111111111111111111111111111111119aa911000011ddddccccdddddddddddd00111111111111
00011dddddddddddd1111dddddd11111111111111111111111111111111111111111111111111111119aa91100011dddddccccdddddddddddd01111111111111
1011ddddddddddddddd1dddddddd1111111111111111111111111111111111111111111111111111111991111011dddddd7c77ddddddddddddd1111111111111
111ddddddddddddddddddddddddddd1111111111111111111111111111199111111111111111111111111111111dddddddccccdddddddddddddddd1111111111
1dddddddddddddddddddddddddddddd1111111111111111111111111119aa9111111111111111111111111111dddddddddcc7cddddddddddddddddd111111111
dddddddddddddddddddddddddddddddd111111111111111111111111119aa911111111111111111111111111dddddddddd7777dddddddddddddddddd11111111
ddddddddddddddddddddddddddddddddd111111111dddd1111111111119aa91111111111111111111111111dddddddddddccccddddddddddddddddddd111111d
ddddddddddddddddddddddddddddddddd1111111dddddddd11111111119aa91111111111111111111111111dddddddddddccccddddddddddddddddddd111111d
dddddddddddddddddddddddddddddddddd11111dddddddddd11111dddd9aa91111111111111111dddd1111ddddddddddddccccdddddddddddddddddddd1111dd
dddddddddddddddddddddddddddddddddd111dddddddddddd1111ddddd9aa9111111111111111dddddd11dddddddddddddccccdddddddddddddddddddd111ddd
ddddddddddddddddddddddddddddddddddd1ddddddddddddddd1ddddddd99111111111111111dddddddddddddddddddddd7c77ddddddddddddddddddddd1dddd
ddddddddddddddddddddddddddd99ddddddddddddddddddddddddddddddddd1111111111111dddddddddddddddddddddddccccdddddddddddddddddddddddddd
dddddddddddddddddddddddddd9aa9ddddddddddddddddddddddddddddddddd1111111111dddddddddddddddddddddddddcc7cdddddddddddddddddddddddddd
dddddddddddddddddddddddddd9aa9dddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddd7777dddddddddddddddddddddddddd
dddddddddddddddddddddddddd9aa9ddddddddddddddddddddddddddddddddddd111111dddddddddddddddddddddddddddccccdddddddddddddddddddddddddd
dddddddddddddddddddddddddd9aa9ddddddddddddddddddddddddddddddddddd111111dddddddddddddddddddddddddddccccdddddddddddddddddddddddddd
dddddddddddddddddddddddddd9aa9dddddddddddddddddddddddddddddddddddd1111ddddddddddddddddddddddddddddccccdddddddddddddddddddddddddd
dddddddddddddddddddddddddd9aa9dddddddddddddddddddddddddddddddddddd111dddddddddddddddddddddddddddddccccdddddddddddddddddddddddddd
ddddddddddddddddddddddddddd99dddddddddddddddddddddddddddddddddddddd1dddddddddddddddddddddddddddddd7c77dddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddccccdddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb000b0b000000000000000303000000000000008080008080008010000000000000000000007770077700077700077700000000000000aaa0aa00aaa0a0a0
0b0000b00b00000000000000030300000000000008288808288808281100000000000000000000c7c00c7c0070c07070c070000000000000a0a00a00a000a0a0
0bbb00b00bbb00000000000003330000000000000828880828880821110000000000000000000070700707007ccc707ccc70000000000000a0a00a00aaa0aaa0
000b00b00b0b00000000000000030000000000000088800088800011100000000000000000000000000000006ccc606ccc60000000000000a0a00a0000a000a0
0bbb0b000bbb0000000000000003000000000000000800000800000100000000000000000000000600006000066600066600000000000000aaa0aaa0aaa000a0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

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
920300001375015750187501a7501f750217500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480300000c7600f05013040131300070000700007000c700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
9203000015750177501c7501e75023750257500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480200000e6501f64012630006000060000600006000c640006000761000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000400002b650256501f65019650220601f0601906015060100500c0500904007040220501f0501905015050100400c0400903007030220401f0401904015040100300c0300902007020220301f0301903015030
00040000100200c0200901007010220201f0201902015020100100c0100901007010220101f0101901015010100100c0100901007010220001f0001900015000100000c0000900007000220001f0001900015000
460800000c0670c0671306713067160671606718067180671a0671a0671d0671d0671f0671f06722067220672406724067260672606729067290672b0672b0672e0572e057300523005230042300323002230012
00020000240502205018050130500a140051400a10007100041000610004100011000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000100001f5701a570135700e57009570055700257000570045000650004500015000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000300002305023030280502803000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002375023730287502873000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00040000130301a0401e0501e0401e0001e0001e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08040000137301a7401e7501e7401e7001e7001e70000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0003000026620216201913016130131300a1300613003100001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0803000026050260302b0502b03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080300002d0502d030320503203000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000000
000100000c0500c7000f0500f0001205012000150501500018050180001b0501b0001e0501e000210501370014700147002170000600006000060000600006000060000600006000060000600006000060000600
93030000187501a7501f7502175026750287500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
580200001375015750187501a7501f750217501510013700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100300000e5500e55015550155501a5501a5501355013550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

