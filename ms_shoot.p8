pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--[[
todo:
	-add grayed out key icon to
			hud -> turns gold when
			key collected
		-can place key on map same way
				as door
		-add key door, same as door
				but shows a key sprite ontop
	-add cooldown on gun: if gun
			over heats the player has
			to wait until it cools off
	-add enemy berserk mode: if
			e.hp==1, increase their speed
			and render them red/black
	-or
	-press z to switch weapon:
		1.slow shooter: inf amo
		2.machine gun: limited/amo pickup
		3.bomb: limited/amo pickup
			-should bomb be throw, or
					drop?
]]--


-- vars
-- =================
--constants
b_speed=6
hud_h=8
num_b=30
--modes
mode_start=0
mode_game=1
mode_middle=2
mode_inst=3
mode=mode_game
--cam
cam={x=0,y=0,sx=0,sy=0,s_tm=0}
samt=2
--level
lvl={}
xmax=16
ymax=16
--level stats
l_stat={b_found=0,b_hit=0}
--total stats
t_stat={b_found=0}
--heart levels
h_lvl=1
h_levels={10,20,50,100}
--player
pp={x=20,y=20,
	walk=0,--walking counter
	shoot=0,--shooting counter
	sp_ft=6,	--feet sprite
	sp_hd=1,	--head sprite
	drr={x=-1,y=0},--direction
	hp=6,
	max_hp=6,
	h_tm=0,--hit time
	h_dx=0,--hit x direction
	h_dy=0,--hit y direction
	d_tm=0,--die time
	d_y=0, --die y offset
	d_dy=0,--die y direction
	ammo=20,
	max_ammo=50,
	r_tm=0,--reload time
	a_tm=0--ammo animation time
}
--middle helper
middle={
	p_tm=0,
	b_tm=0,
	t_tm=0
}
--drop/undrop
drop={
	x=-1,tm=0,y_end=-1,
	dy_bot=0,dy_top=0,
	go=false,landed=false
}
undrop={
	x=-1,tm=0,y_end=-1,
	dy_bot=0,dy_top=0,
	go=false
}
--door
door={
	i=-1,j=-1,tm=0,y=0,dy=-1,
	found=false
}
--arrays
bullets={}
sprinkles={}
explosions={}
sheets={}
hearts={}
spawners={}
enemies={}
ammo={}
	
-- helpers
--=============
function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function chance(n)
	return rand(0,100) < n
end

function place_free(x,y)
	local i=flr(x/8)
	local j=flr(y/8)
	local b=mget(i,j)
	return b<17 or b>22
end

function set_pause()
	pause=10
end

function set_shake()
	cam.s_tm=1
end

function set_hit()
	hit=10
end

function set_found()
	found=10
end

function set_message()
	message=100
end

-- init
-- =================
function _init()
	reset_level()
end

--reset
function reset_level()
	--clear arrays :(
	for b in all(bullets)do
		del(bullets,b)
	end
	for s in all(sprinkles)do
		del(sprinkles,s)
	end
	for e in all(explosions)do
		del(explosions,e)
	end
	for s in all(sheets)do
		del(sheets,s)
	end
	for h in all(hearts)do
		del(hearts,h)
	end
	for s in all(spawners)do
		del(spawners,s)
	end
	for e in all(enemies)do
		del(enemies,e)
	end
	for a in all(ammo)do
		del(ammo,a)
	end
	--reset player stuff
	pp.h_tm=0
	pp.h_dx=0
	pp.h_dy=0
	pp.d_tm=0
	pp.d_y=0
	pp.d_dy=-1
	pp.ammo=pp.max_ammo
	--reset drop
	drop.tm=0
	drop.dy_bot=0
	drop.dy_top=0
	drop.go=false
	drop.landed=false
	--reset undrop
	undrop.tm=0
	undrop.dy_bot=0
	undrop.dy_top=0
	undrop.go=false
	--reset door
	door.tm=0
	door.y=0
	door.dy=-1
	door.found=false
	--reset middle stuff
	middle.b_tm=0
	middle.p_tm=0
	middle.t_tm=0
	--reset l_stat
	l_stat.b_found=0
	l_stat.b_hit=0
	--reset game stuff
	spawn_tm=100
	spawn_max=100
	pause=0
	hit=0
	found=0
	message=0
	die=0
	--generate stuff
	new_level()
	place_player()
	place_door()
end

-- draw
-- =================
function _draw()
	cls()
	if mode==mode_game then
		draw_game()
	elseif mode==mode_middle then
		draw_middle()
	end
end

--debug
function draw_grid()
	for i=1,16 do
		line(i*8,0,i*8,127,1)
		line(0,i*8,127,i*8,1)
	end
	for i=1,8 do
		line(i*16,0,i*16,1,2)
		line(0,i*16,127,i*16,2)
	end
end

function draw_middle()
	//draw_grid()
	--draw bombs found
	local b_left=24
	local b_top=10
	for b=0,flr(middle.b_tm) do
		local bs=51
		if b<l_stat.b_found then
			bs=49
		elseif b<l_stat.b_found+
					l_stat.b_hit then
			bs=50
		end
		spr(bs,
			b_left+(b%10)*8,
			b_top+flr(b/10)*8)
	end
	--totals
	if middle.t_tm==1 then
		print("total",24,50,7)
		spr(49,45,48)
		print("=",55,50,7)
		print(t_stat.b_found,
			61,50,11)
		if h_lvl<=#h_levels then
			print("next",24,60,7)
			spr(35,43,59)
			spr(36,43,59)
			print("in",54,60,7)
			print(h_levels[h_lvl]-t_stat.b_found,
				64,60,11)
		else
			print("all",24,60,7)
			spr(35,43,59)
			spr(36,43,59)
			print("acquired",54,60,7)
		end
	end
	--player
	spr(4,60,103)
	if flr(middle.p_tm)%2==0 then
		spr(5,60,103)
	else
		spr(6,60,103)
	end
	--continue
	print("press ❎ to continue", 
		25,112,7)
end

function draw_game()
	--die
	if die>0 then
		draw_player()
		draw_die()
		return
	end
	--map
	camera(cam.x+cam.sx,
		cam.y+cam.sy)
	m_x=flr(cam.x/8)-1
	m_y=flr(cam.y/8)-1
	local m_filter=0
	if(pause>0)m_filter=1	
	map(m_x,m_y,m_x*8,m_y*8,
		18,18,m_filter)
	--drop
	if drop.go then
		draw_drop()
		if not drop.landed then
			return
		end
	end
	
	if undrop.go then
		draw_undrop()
		return
	end
	
	--objects
	draw_player()
	draw_bullets()
	draw_sprinkles()
	draw_explosions()
	draw_sheets()
	draw_door()
	draw_hearts()
	draw_spawners()
	draw_enemies()
	--hud
	draw_hud()
	--message
	if(message>0)draw_message()
end

function draw_hud()
	local hud_t=cam.y+120
	local hp_x=cam.x+4
	--border
	rectfill(cam.x,hud_t,cam.x+128,
		hud_t+8,0)
	draw_ammo(hp_x+50,hud_t)
	draw_found(hp_x+98,hud_t)
	draw_hp(hp_x,hud_t+1)
end

function draw_ammo(x,y)
	local a_clr=7
	if(pp.ammo<=10)a_clr=8
	if(flr(pp.a_tm)%2==1)a_clr=10
	if pp.ammo>0 then
		print("ammo:"..pp.ammo.."/"..
			pp.max_ammo,x,y+2,a_clr)
	elseif flr(pp.r_tm)%2==0 then
		print("reloading",x,y+2,7)
	end
end

function draw_found(x,y)
	--found bombs
	if flr(found)%2==1 then
		pal(7,10)
		pal(11,10)
		pal(3,10)
	end
	spr(49,x,y)
	print("=",x+9,y+2,7)
	print(t_stat.b_found,
		x+14,y+2,11)
	pal()
end

function draw_hp(x,y)
	--hp♥
	local hx=x
	if flr(hit)%2==1 then
		pal(8,10)
		pal(2,10)
	end
	
	for i=1,pp.max_hp do
		if i%2==1 then
			if(i<=pp.hp)spr(35,hx,y)
			if(i>pp.hp)spr(37,hx,y)
		else
			if(i<=pp.hp)spr(36,hx,y)
			if(i>pp.hp)spr(38,hx,y)
			hx+=8
		end
	end
	pal()
end

function draw_player()
	if die==2 then
		spr(55,pp.x-4,
				(pp.y-4)+pp.d_y)
		return
	elseif die==1 then
		if pp.d_tm<3 then
			spr(52+flr(pp.d_tm),
				pp.x-4,pp.y-4)
		else
			spr(55,pp.x-4,pp.y-4)
		end
		return
	end
	if	flr(pp.h_tm)%2==1 then
		pal(7,0)
		pal(12,0)
	end
	spr(pp.sp_ft,pp.x-4,pp.y-4)
	spr(pp.sp_hd,pp.x-4,pp.y-4)
	pal()
end

function draw_bullets()
	for b in all(bullets) do
		pal(7,(b.tm%8)+8)
		spr(11,b.x-4,b.y-4)
	end
	pal()
end

function draw_sprinkles()
	for s in all(sprinkles) do
		spr(12,s.x,s.y)
	end
end

function draw_explosions()
	for e in all(explosions) do
		if e.tm>=0 then
			pal(7,flr(e.tm)+8)
			spr(13,e.x,e.y)
		end
	end
	pal()
end

function draw_sheets()
	for s in all(sheets) do
		if s.tm>=0 then
			pal(7,flr(s.tm)+8)
			spr(14,s.x,s.y)
		end
	end
	pal()
end

function draw_door()
	if(not door.found)return
	pal(7,(door.tm%8)+8)
	spr(26,door.i*8,
		(door.j*8)+door.y)
	pal()
end

function draw_hearts()
	for h in all(hearts)do
		h.tm+=0.1
		if(flr(h.tm)%2==0)pal(8,10)
		spr(35,h.x-4,h.y-4)
		spr(36,h.x-4,h.y-4)
		pal()
	end
end

function draw_drop()
	pal(7,flr(drop.tm)+8)
		rectfill(
			drop.x,
			cam.y+drop.dy_top,
			drop.x+8,
			cam.y+drop.dy_bot,
			7
		)
	pal()
end

function draw_undrop()
	pal(7,flr(undrop.tm)+8)
		rectfill(
			undrop.x,
			cam.y+undrop.dy_top,
			undrop.x+8,
			cam.y+undrop.dy_bot,
			7
		)
	pal()
end

function draw_spawners()
	for s in all(spawners)do
		circ((s.i*8)+4,(s.j*8)+4,
			flr(s.tm)%3,7)
	end
end

function draw_enemies()
	for e in all(enemies)do
		if flr(e.p_tm)%2==1 then
			pal(7,8)
		end
		spr(e.sp+flr(e.tm)%2,
			e.x-4,e.y-4)
		pal()
	end
end

function draw_message()
	rectfill(32,48,96,80,0)
	rect(32,48,96,80,1)
	print("new",37,56,7)
	spr(35,51,55)
	spr(36,51,55)
	print("acquired",62,56,7)
	if h_lvl<=#h_levels then
		print("next at",39,66,7)
		print(h_levels[h_lvl],70,66,11)
		spr(49,83,64)
	else
		print("all",39,66,7)
		spr(35,51,65)
		spr(36,51,65)
		print("acquired",62,66,7)
	end
end

function draw_die()
	if(die<2)return
	--totals
	print("total",24,50,7)
	spr(49,45,48)
	print("=",55,50,7)
	print(t_stat.b_found,
		61,50,11)
	--continue
	print("press ❎ to continue", 
		25,112,7)
end

-- update
-- =================
function _update()
	if mode==mode_game then
		update_game()
	elseif mode==mode_middle then
		update_middle()
	end
end

function update_middle()
	middle.p_tm+=0.1
	if middle.b_tm<num_b-1 then
		middle.b_tm+=0.5
	else
		middle.t_tm=1
	end
	
	if btnp(5) then
		if middle.t_tm==0 then
			middle.b_tm=num_b-1
			middle.t_tm=1
		else
			reset_level()
			mode=mode_game
		end
	end
end

function update_game()
	--die animation
	if die>0 then
		player_die()
		return
	end
	--update cam
	update_cam()
	
	--counter updates
	if pause>0 then
		pause-=1
		return
	end
	if(hit>0)hit-=0.5
	if(found>0)found-=0.5
	
	--drop update
	if drop.go then
		update_drop()
		if not drop.landed then
			return
		end
	end
	--undrop update
	if undrop.go then
		update_undrop()
		return
	end
	
	if message>0 then
		message-=1
		return
	end
	
	--main update
	local drr=nil
	local sht=false
	if(btn(0))drr={x=-1,y=0}
	if(btn(1))drr={x=1,y=0}
	if(btn(2))drr={x=0,y=-1}
	if(btn(3))drr={x=0,y=1}
	if(btn(5))sht=true
	
	--player stuff
	if(pp.h_tm>0)pp.h_tm-=0.5
	if pp.h_tm>17 then
		player_hit()
	else
		if pp.hp<=0 then
			die=1
			return
		end
		player_move(drr)
		player_shoot(sht)
	end
	if(pp.h_tm<=0)touch_enemy()
	if(pp.a_tm>0)pp.a_tm-=0.5
	if pp.r_tm>0 then
		pp.r_tm-=0.1
		if(pp.r_tm<=0)pp.ammo=pp.max_ammo
	end
	
	--object updates
	update_bullets()
	update_sprinkles()
	update_explosions()
	update_sheets()
	update_door()
	update_spawners()
	update_enemies()
end

function update_cam()
	update_shake()
	cam.x=pp.x-64
	cam.y=pp.y-64
	if(cam.x<0)cam.x=0
	if(cam.y<0)cam.y=0
	if cam.x>(xmax*8)-128 then 
		cam.x=(xmax*8)-128
	end
	if cam.y>((ymax*8)-128)+hud_h then 
		cam.y=((ymax*8)-128)+hud_h
	end
end

function update_shake()
	if cam.s_tm>0.05 then
		cam.sx=rand(-2,2)*cam.s_tm
		cam.sy=rand(-2,2)*cam.s_tm
		cam.s_tm*=0.8
	else
		cam.s_tm=0
		cam.sx=0
		cam.sy=0
	end
end

function player_move(drr)
	--return if no movement
	if drr==nil then
		pp.walk=0
		return
	end	
	--get direction
	if(drr.x==-1)pp.sp_hd=1
	if(drr.x==1)pp.sp_hd=2
	if(drr.y==-1)pp.sp_hd=3
	if(drr.y==1)pp.sp_hd=4
	--move
	local nx=pp.x+(drr.x*4)
	local ny=pp.y+(drr.y*4)
	if flr(nx/8)==door.i and
				flr(ny/8)==door.j then
	 undrop.x=door.i*8
		undrop.y_end=cam.x
		undrop.dy_top=door.j*8
		undrop.dy_bot=door.j*8
		undrop.go=true
	end
	if place_free(nx,ny) and
				nx>=0 and nx<=xmax*8 and
				ny>=0 and ny<=ymax*8 then
		pp.x+=drr.x
		pp.y+=drr.y
	end
	
	--touch stuff
	touch_heart()
		
	--update feet anim
	if pp.walk==0 then
		pp.walk=5
		if pp.sp_ft==6 then
			pp.sp_ft=5
		else
			pp.sp_ft=6
		end
	else
		pp.walk-=1
	end
	
	pp.drr=drr
end

function player_shoot(sht)
	if pp.shoot>0 then
		pp.shoot-=1
	end
	if sht==false or
		pp.r_tm>0 then
		return
	elseif pp.shoot==0 then
		pp.ammo-=1
		if pp.ammo==0 then
			pp.r_tm=10
			return
		end
		pp.shoot=5
		add(bullets,{
			x=pp.x,y=pp.y,
			drr=pp.drr,tm=0
		})
	end
end

function touch_heart()
	for h in all(hearts)do
		if abs(pp.x-h.x)<4 and
					abs(pp.y-h.y)<4 then
			del(hearts,h)
			add_sheet(pp.x-4,pp.y-4)
			pp.hp+=2
			if(pp.hp>pp.max_hp)pp.hp=pp.max_hp
		end
	end
end

function touch_enemy()
	for e in all(enemies)do
		if in_enemy(e,pp.x,pp.y) then
			pp.h_tm=20
			pp.hp-=1
			if(pp.x>e.x)pp.h_dx=1
			if(pp.x<e.x)pp.h_dx=-1
			if(pp.y>e.y)pp.h_dy=1
			if(pp.y<e.y)pp.h_dy=-1
		end
	end
end

function player_hit()
	local nx=pp.x+(pp.h_dx*2)
	local ny=pp.y+(pp.h_dy*2)
	if place_free(nx,ny) and
				nx>=0 and nx<=xmax*8 and
				ny>=0 and ny<=ymax*8 then
		pp.x=nx
		pp.y=ny
	end
end

function player_die()
	pp.d_tm+=0.1
	die=2
	if flr(pp.x)>cam.x+64 then
		pp.x-=0.5 
		die=1 end
	if flr(pp.x)<cam.x+64 then
		pp.x+=0.5
		die=1 end
	if flr(pp.y)>cam.y+64 then
		pp.y-=0.5
		die=1 end
	if flr(pp.y)<cam.y+64 then
		pp.y+=0.5 
		die=1 end
	
	if die==2 then
		if pp.d_y<=0 and 
					pp.d_dy==-1 then
			pp.d_dy=1 
		end
		if pp.d_y>=8 and 
					pp.d_dy==1 then
			pp.d_dy=-1 
		end
		pp.d_y+=(pp.d_dy)*0.3
		if btnp(5) then
			mode=mode_game
			pp.max_hp=6
			pp.hp=6
			reset_level()
		end
	end
end

function update_bullets()
	for b in all(bullets) do
		local nx=b.x+(b.drr.x*b_speed)
		local ny=b.y+(b.drr.y*b_speed)
		if place_free(nx,ny) then
			b.x+=b.drr.x*b_speed
			b.y+=b.drr.y*b_speed
			b.tm+=1
		else
			//set_pause()
			damage_block(nx,ny)
			//set_shake()
			add_sprinkle(b.x-4,b.y-4)
			del(bullets,b)
		end
		if b.x<cam.x or b.x>cam.x+128 or
					b.y<cam.y or b.y>cam.y+128
					then
			del(bullets,b)
		end
		for e in all(enemies)do
			if in_enemy(e,b.x,b.y) then
				damage_enemy(e)
				del(bullets,b)
			end
		end
	end
end

function damage_block(x,y)
	local i=flr(x/8)
	local j=flr(y/8)
	local b=mget(i,j)
	if b>=17 and b<=19 then
		mset(i,j,b+1)
	elseif b==20 then
		if lvl[j][i].val==-1 then
			set_pause()
			set_hit()
			hit_bomb(j,i)
			set_shake()
		else
			open_tile(i,j)
			set_shake()
		end
		//set_pause()
		update_opens()
	end
end

function update_sprinkles()
	for s in all(sprinkles) do
		s.x+=s.dx
		s.y+=s.dy
		s.dy+=1
		if(s.dy>5)del(sprinkles,s)
	end
end

function update_explosions()
	for e in all(explosions) do
		if e.tm>8 then
			del(explosions,e)
		elseif e.tm>=0 then
			e.x+=e.dx
			e.y+=e.dy
		end
		e.tm+=1
	end
end

function update_sheets()
	for s in all(sheets) do
		if s.tm>8 then
			del(sheets,s)
		elseif s.tm>=0 then
			s.y-=1
		end
		s.tm+=1
	end
end

-- enemy stuff
-- =================
function add_spawner()
	local ri=rand(0,xmax-1)
	local rj=rand(0,ymax-1)
	while true do
		if lvl[rj][ri].open and
					lvl[rj][ri].val>=0 then
			add(spawners,{
				i=ri,
				j=rj,
				tm=0
			})
			break
		else
			ri=rand(0,xmax-1)
			rj=rand(0,ymax-1)
		end
	end
end

function update_spawners()
	if spawn_tm==0 then
		spawn_tm=spawn_max
		spawn_max-=1
		if(spawn_max<20)spawn_max=20
		add_spawner()
	else
		spawn_tm-=1
	end
	for s in all(spawners)do
		s.tm+=0.5
		if s.tm>24 then
			add_enemy((s.i*8)+4,(s.j*8)+4)
			del(spawners,s)
		end
	end
end

function add_enemy(x,y)
	if chance(60) then
		add(enemies,{
			sp=7,hp=3,x=x,y=y,
			tm=1,p_tm=0,
			shoot=false
		})
	else
		add(enemies,{
			sp=9,hp=6,x=x,y=y,
			tm=1,p_tm=0,
			shoot=true
		})
	end
end

function update_enemies()
	for e in all(enemies)do
		e.tm+=0.1
		-- shooting
		if e.shoot and chance(1) then
			//enemy shooting
		end
		-- paused
		if e.p_tm>0 then
			e.p_tm-=0.5
		else
		-- movement
			local nx=e.x
			local ny=e.y
			if(pp.x>flr(e.x))nx+=0.2
			if(pp.x<flr(e.x))nx-=0.2
			if(pp.y>flr(e.y))ny+=0.2
			if(pp.y<flr(e.y))ny-=0.2
			local horz=place_free(nx,e.y)
			local vert=place_free(e.x,ny)
			if horz and nx>=0 and 
						nx<=xmax*8 then 
				e.x=nx
			end
			if vert and ny>=0 and 
						ny<=ymax*8 then
				e.y=ny
			end
		end
	end
end

function in_enemy(e,x,y)
	return (x>=e.x-4 and x<=e.x+4
		and y>=e.y-4 and y<=e.y+4)
end

function damage_enemy(e)
	add_sprinkle(e.x-4,e.y-4)
	e.hp-=1
	//e.p_tm=5
	if	e.hp<=0 then
		add_explosion(e.x-4,e.y-4)
		set_shake()
		place_heart(e.x,e.y)
		del(enemies,e)
	end
end

-- drop stuff
-- =================
function place_player()
	--at this time,all tiles should
	--be closed, so create opening
	local ri=rand(1,xmax-2)
	local rj=rand(1,ymax-2)
	while true do
		if lvl[rj][ri].val==0 then
			//open_tile(ri,rj)
			break
		else
			ri=rand(1,xmax-2)
			rj=rand(1,ymax-2)
		end
	end
	pp.x=ri*8
	pp.y=rj*8
	drop.x=pp.x-4
	drop.y_end=pp.y-12
	drop.go=true
end

function update_drop()
	if drop.dy_bot<drop.y_end then
		drop.dy_bot+=8
	elseif drop.dy_top<drop.y_end then
		if not drop.landed then
			drop.landed=true
			open_tile(flr(pp.x/8),
				flr(pp.y/8))
			update_opens()
			set_shake()
		end
		drop.dy_top+=5
	else
		drop.go=false
	end
	drop.tm+=1
end

function update_undrop()
	if undrop.dy_top>undrop.y_end then
		undrop.dy_top-=8
	elseif undrop.dy_bot>undrop.y_end then
		undrop.dy_bot-=5
	else
		undrop.go=false
		//reset_level()
		mode=mode_middle
	end
	undrop.tm+=1
end

--door stuff
function place_door()
	local pi=flr(pp.x/8)
	local pj=flr(pp.y/8)
	local ri=rand(0,xmax-1)
	local rj=rand(0,ymax-1)
	while true do
		if lvl[rj][ri].val==0 and
			rj != pj and ri != pi then
			break
		else
			ri=rand(0,xmax-1)
			rj=rand(0,ymax-1)
		end
	end
	door.i=ri
	door.j=rj
end

function update_door()
	if(not door.found)return
	if door.dy==-1 and door.y<-8 then
		door.dy=1
	end
	if door.dy==1 and door.y>0 then
		door.dy=-1
	end
	
	door.y+=door.dy*0.75
	door.tm+=0.5
end

--hearts stuff
function place_heart(x,y)
	if(chance(90))return
	add(hearts,{x=x,y=y,tm=0})
end

-- minesweeper stuff
-- =================
function open_tile(i,j)
	lvl[j][i].open=true
	add_explosion(i*8,j*8)
	if lvl[j][i].val>0 then
		return
	end
	//place_heart(i,j)
	
	local imin=max(i-1,0)
	local imax=min(i+1,xmax-1)
	local jmin=max(j-1,0)
	local jmax=min(j+1,ymax-1)
	for jj=jmin,jmax do
	for ii=imin,imax do
		if lvl[jj][ii].open==false and
					lvl[jj][ii].val!=-1 then
			open_tile(ii,jj)
		end
	end end
end

function update_opens()
	for j=0,ymax-1 do
	for i=0,xmax-1 do
		if lvl[j][i].open then
			if lvl[j][i].val==0 then
				mset(i,j,16)
				if i==door.i and j==door.j then
					door.found=true
				end
			elseif lvl[j][i].val>0 then
				mset(i,j,lvl[j][i].val+55)
			end
		elseif lvl[j][i].val==-1 then
			check_bomb(j,i)
		end
	end end
end

function hit_bomb(j,i)
	lvl[j][i].open=true
	mset(i,j,22)
	l_stat.b_hit+=1
end

function check_bomb(j,i)
	local n = get_surr_c(j,i)
	if n==0 then
		lvl[j][i].open=true
		mset(i,j,21)
		add_sheet(i*8,j*8)
		set_found()
		l_stat.b_found+=1
		t_stat.b_found+=1
		
		pp.a_tm=10
		pp.ammo+=10
		if pp.ammo>pp.max_ammo then
			pp.ammo=pp.max_ammo
		end
	end
	check_level()
end

function check_level()
	if h_lvl>#h_levels then
		return
	end
	if t_stat.b_found>=
				h_levels[h_lvl] then
		h_lvl+=1
		pp.max_hp+=2
		set_message()
		set_hit()
	end
end

-- creators
-- =================
function new_level()
	--get empty level
	lvl=empty_lvl()
	--add random bombs
	add_bombs()
	--get level vals
	add_vals()
	--set map
	set_map()
end

function new_cell()
	return {
		val=0,
		open=false
	}
end

function empty_lvl()
	local ll={}
	for j=0,ymax-1 do
	ll[j]={}
	for i=0,xmax-1 do
		ll[j][i]=new_cell()
	end end
	return ll
end

function add_bombs()
	local n=0
	while n<num_b do
		local rx=rand(0,xmax-1)
		local ry=rand(0,ymax-1)
		if lvl[ry][rx].val==0 then
			lvl[ry][rx].val=-1
			n+=1
		end
	end
end

function add_vals()
	for j=0,ymax-1 do
	for i=0,xmax-1 do
		if lvl[j][i].val != -1 then
			lvl[j][i].val=get_surr_b(j,i)
		end
	end end
end

function get_surr_b(j,i)
	local imin=max(i-1,0)
	local imax=min(i+1,xmax-1)
	local jmin=max(j-1,0)
	local jmax=min(j+1,ymax-1)
	local n=0
	for jj=jmin,jmax do
	for ii=imin,imax do
		if lvl[jj][ii].val==-1 then
			n+=1
		end
	end end
	return n
end

function get_surr_c(j,i)
	local imin=max(i-1,0)
	local imax=min(i+1,xmax-1)
	local jmin=max(j-1,0)
	local jmax=min(j+1,ymax-1)
	local n=0
	for jj=jmin,jmax do
	for ii=imin,imax do
		if lvl[jj][ii].val>-1 and
					lvl[jj][ii].open==false then
			n+=1
		end
	end end
	return n
end

function set_map()
	for j=0,ymax-1 do
	for i=0,xmax-1 do
		--clear the current
		mset(i,j,0)
		--set all closed tiles
		if lvl[j][i].open==false then
			mset(i,j,17)
		end
	end end
end

-- sprinkles
function add_sprinkle(x,y)
	add(sprinkles,{
		x=x+4,y=y+4,dx=1,dy=-2})
	add(sprinkles,{
		x=x+4,y=y-4,dx=1,dy=-2})
	add(sprinkles,{
		x=x-4,y=y+4,dx=-1,dy=-2})
	add(sprinkles,{
		x=x-4,y=y-4,dx=-1,dy=-2})
end

-- block explosions
function add_explosion(x,y)
	local tm=rand(-4,0)
	add(explosions,{
		x=x+0,y=y+0,dx=1,dy=1,tm=tm
	})
	add(explosions,{
		x=x+0,y=y+0,dx=-1,dy=1,tm=tm
	})
	add(explosions,{
		x=x+0,y=y+0,dx=1,dy=-1,tm=tm
	})
	add(explosions,{
		x=x+0,y=y+0,dx=-1,dy=-1,tm=tm
	})
end

function add_sheet(x,y)
	for c=0,5 do
		add(sheets,{
			x=x+0,y=y+3,tm=c*-1
		})
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c7770000777c0000c77c00007777000000000000000000000000000000000000777700007777000000000000000000000000000000000000000000
00700700007777000077770000777700007777000000000000000000007777000077770000877800008778000000000000000000007777000000000000000000
0007700000c7770000777c000077770000c77c0000000000000000000087780000877800007777000077770000077000000f0000007777000000000000000000
00077000000000000000000000000000000000000077770000777700007887000078870000788700007887000007700000000000007777000000000000000000
00700700000000000000000000000000000000000070070000700700007000000000070000777700007777000000000000000000007777007777777700000000
00000000000000000000000000000000000000000000070000700000000000000000000000700000000007000000000000000000000000007777777700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000007777770022222200eeeeee0088888800bbbbbb008888880000000000000000001111110000000000111000001110000111100000000070000000000
000000007000000720000002e000000e80000008bb1111bb881111880000000000000000110000110000000010000000101010001000100000f0777000000000
000000007000000720000002e000000e80000008b333333b82222228000000000000000010000001000000001001100010101000101100000f99070000000000
000000007000005720000012e00000de80000028b333333b82222228000000000000000010000001000000001000100010001000100010000f99000000000000
0000000070000567200001d2e0000d2e800002e8bb3333bb88222288000000000000000011000011777777770111000010001000111100000999000000000000
000000007000566720001dd2e000d22e80002ee83bbbbbb328888882777777777777777710111101700000070000000000000000000000000000000000000000
00000000700566772001dd22e00d22ee8002ee881333333112222221777777777777777710000001700000070000000000000000000000000f99000000000000
0000000007777770022222200eeeeee0088888800111111001111110000000000000000001111110777777770000000000000000000000000000000000000000
100000000777777000000d0d08800000000088000220000000002200000000001000000010000000100000001000000010000000100000001000000010000000
0000000070000007000000d082280000000088802002000000000020000000000000000000000000000000000000000000000000000000000000000000000000
000000007000000700dd0d0d82880000000088802000000000000020000000000005500000055500000555000005050000055500000500000005550000055500
00000000700000570d00d00008880000000088000200000000000200000000000000500000000500000005000005050000050000000500000000050000050500
0000000070000567d0000d0000880000000080000020000000002000000000000000500000055500000055000005550000055500000555000000050000055500
0000000070005667d0000d0000080000000000000002000000000000000000000000500000050000000005000000050000000500000505000000500000050500
00000000700566770d00d00000000000000000000000000000000000000000000005550000055500000555000000050000055500000555000000500000055500
000000000777777000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001000000010000000100000001000000010000000100000001000000010000000
0000000000bbbb000088880005111150007777000007777000000700000000000000000000000000000000000000000000000000000000000000000000000000
000000000b3333b0082222800151151000777700000c77700000c77000007c70000cc000000bbb0000088800000d0d0000022200000300000001110000055500
000000000b0000b0080000800105501000c77c0000777c0000077777000777700000c00000000b0000000800000d0d0000020000000300000000010000050500
0000000003bbbb3002888820011551100077770000777700007777c000777c700000c000000bbb0000008800000ddd0000022200000333000000010000055500
00000000030000300200002001500510007007000070070000707700070770000000c000000b00000000080000000d0000000200000303000000100000050500
0000000000333300002222000511115000700700070007000700700007007000000ccc00000bbb000008880000000d0000022200000333000000100000055500
00000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000320503205032050320503105031050300502e0502d0502b05027050240501e0501a0501805015050110500e0500a050070500205001050020500105001050207501c6501f7501b6501a6500000018650
