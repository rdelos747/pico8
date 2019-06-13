pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- vars
-- =================
--constants
b_speed=6
hud_h=8
--start,instructions,game
mode=0

--game stuff
pause=0
hit=0

--cam
cam={x=0,y=0,sx=0,sy=0,s_tm=0}
samt=2
--level
lvl={}
num_b=30
xmax=16
ymax=16

--player
pp={x=20,y=20,
	walk=0,--walking counter
	shoot=0,--shooting counter
	sp_ft=6,	--feet sprite
	sp_hd=1,	--head sprite
	drr={0,1},--direction
	hp=1,
	max_hp=10
}

--drop
drop={
	x=-1,tm=0,y_end=-1,
	dy_bot=0,dy_top=0,
	go=false,landed=false
}

--arrays
bullets={}
sprinkles={}
explosions={}
sheets={}
	
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

-- init
-- =================
function _init()
	new_level()
	place_player()
	update_opens()
end

-- draw
-- =================
function _draw()
	//if(pause>0)return
	cls()
	draw_game()
end

function draw_game()
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
	--objects
	draw_hud()
	draw_player()
	draw_bullets()
	draw_sprinkles()
	draw_explosions()
	draw_sheets()
end

function draw_hud()
	local hud_t=cam.y+120
	local hp_x=cam.x+4
	rectfill(cam.x,hud_t,cam.x+128,
		hud_t+8,0)
	draw_hp(hp_x,hud_t+2)
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
	spr(pp.sp_ft,pp.x-4,pp.y-4)
	spr(pp.sp_hd,pp.x-4,pp.y-4)
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

-- update
-- =================
function _update()
	--update cam
	update_cam()
	
	--counter updates
	if pause>0 then
		pause-=1
		return
	end
	if(hit>0)hit-=0.5
	
	--drop update
	if drop.go then
		update_drop()
		if not drop.landed then
			return
		end
	end
	
	--main update
	local drr=nil
	local sht=false
	if(btn(0))drr={x=-1,y=0}
	if(btn(1))drr={x=1,y=0}
	if(btn(2))drr={x=0,y=-1}
	if(btn(3))drr={x=0,y=1}
	if(btn(5))sht=true
	player_move(drr)
	player_shoot(sht)
	update_bullets()
	update_sprinkles()
	update_explosions()
	update_sheets()
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
	if place_free(nx,ny) then
		pp.x+=drr.x
		pp.y+=drr.y
	end
		
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
	if sht==false then
		return
	elseif pp.shoot==0 then
		pp.shoot=5
		add(bullets,{
			x=pp.x,y=pp.y,
			drr=pp.drr,tm=0
		})
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
			set_shake()
			add_sprinkle(b.x-4,b.y-4)
			del(bullets,b)
		end
		if b.x<cam.x or b.x>cam.x+128 or
					b.y<cam.y or b.y>cam.y+128
					then
			del(bullets,b)
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
			open_bomb(j,i)
		else
			open_tile(i,j)
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

-- drop stuff
-- =================

function place_player()
	--at this time,all tiles should
	--be closed, so create opening
	local ri=rand(0,xmax-1)
	local rj=rand(0,ymax-1)
	while true do
		if lvl[rj][ri].val==0 then
			//open_tile(ri,rj)
			break
		else
			ri=rand(0,xmax-1)
			rj=rand(0,ymax-1)
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

-- minesweeper stuff
-- =================
function open_tile(i,j)
	lvl[j][i].open=true
	add_explosion(i*8,j*8)
	if lvl[j][i].val>0 then
		return
	end
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
			elseif lvl[j][i].val>0 then
				mset(i,j,lvl[j][i].val+55)
			end
		elseif lvl[j][i].val==-1 then
			check_bomb(j,i)
		end
	end end
end

function open_bomb(j,i)
	lvl[j][i].open=true
	mset(i,j,22)
end

function check_bomb(j,i)
	local n = get_surr_c(j,i)
	if n==0 then
		lvl[j][i].open=true
		mset(i,j,21)
		add_sheet(i*8,j*8)
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
1000000007777770022222200eeeeee0088888800bbbbbb008888880000000000000000010000000100000000000000000000000000000000000000000000000
000000007000000720000002e000000e80000008bb1111bb88111188000000000000000000000000000000000000000000000000000000000000000000000000
000000007000000720000002e000000e80000008b333333b82222228000000000000000000055500000555000000000000000000000000000000000000000000
000000007000005720000012e00000de80000028b333333b82222228000000000000000000000500000505000000000000000000000000000000000000000000
0000000070000567200001d2e0000d2e800002e8bb3333bb88222288000000000000000000000500000555000000000000000000000000000000000000000000
000000007000566720001dd2e000d22e80002ee83bbbbbb328888882777777777777777700005000000505000000000000000000000000000000000000000000
00000000700566772001dd22e00d22ee8002ee881333333112222221777777777777777700005000000555000000000000000000000000000000000000000000
0000000007777770022222200eeeeee0088888800111111001111110000000000000000000000000000000000000000000000000000000000000000000000000
100000010777777000000d0d08800000000088000220000000002200000000001000000010000000100000001000000010000000100000001000000010000000
0000000070000007000000d082280000000088802002000000000020000000000000000000000000000000000000000000000000000000000000000000000000
000000007000000700dd0d0d82880000000088802000000000000020000000000005500000055500000555000005050000055500000500000005550000055500
00000000700000570d00d00008880000000088000200000000000200000000000000500000000500000005000005050000050000000500000000050000050500
0000000070000567d0000d0000880000000080000020000000002000000000000000500000055500000055000005550000055500000555000000050000055500
0000000070005667d0000d0000080000000000000002000000000000000000000000500000050000000005000000050000000500000505000000500000050500
00000000700566770d00d00000000000000000000000000000000000000000000005550000055500000555000000050000055500000555000000500000055500
100000010777777000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001000000010000000100000001000000010000000100000001000000010000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000cc000000bbb0000088800000d0d0000022200000300000001110000055500
00000000000000000000000000000000000000000000000000000000000000000000c00000000b0000000800000d0d0000020000000300000000010000050500
00000000000000000000000000000000000000000000000000000000000000000000c000000bbb0000008800000ddd0000022200000333000000010000055500
00000000000000000000000000000000000000000000000000000000000000000000c000000b00000000080000000d0000000200000303000000100000050500
0000000000000000000000000000000000000000000000000000000000000000000ccc00000bbb000008880000000d0000022200000333000000100000055500
__gff__
0000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
