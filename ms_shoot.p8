pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- vars
-- =================
--constants
b_speed=6
--start,instructions,game
mode=0

--game stuff
pause=0

--cam
cam={x=0,y=0,tm=0}

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
	drr={0,1}--direction
}

--arrays
bullets={}
sprinkles={}
	
-- helpers
--=============
function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function chance(n)
	return rand(0,100) < n
end

function place_free(x,y)
	return mget(flr(x/8),
		flr(y/8))!=17
end

function set_pause()
	pause=2
end

function set_shake()
	shake=4
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
	if(pause>0)return
	cls()
	draw_game()
end

function draw_game()
	--map
	camera(cam.x,cam.y)
	m_x=flr(cam.x/8)-1
	m_y=flr(cam.y/8)-1
	map(m_x,m_y,m_x*8,m_y*8,18,18)
	--player
	draw_player()
	--bullets
	draw_bullets()
	--sprinkles
	draw_sprinkles()
end

function draw_player()
	spr(pp.sp_ft,pp.x-4,pp.y-4)
	spr(pp.sp_hd,pp.x-4,pp.y-4)
end

function draw_bullets()
	for b in all(bullets) do
		spr(11,b.x-4,b.y-4)
	end
end

function draw_sprinkles()
	for s in all(sprinkles) do
		spr(12,s.x,s.y)
	end
end

-- update
-- =================
function _update()
	if pause>0 then
		pause-=1
		return
	end
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
	update_cam()
end

function update_cam()
	cam.x=pp.x-64
	cam.y=pp.y-64
	if(cam.x<0)cam.x=0
	if(cam.y<0)cam.y=0
	if cam.x>(xmax*8)-128 then 
		cam.x=(xmax*8)-128
	end
	if cam.y>(ymax*8)-128 then 
		cam.y=(ymax*8)-128
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
		pp.shoot=10
		add(bullets,{
			x=pp.x,y=pp.y,
			drr=pp.drr
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
		else
			set_pause()
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

function update_sprinkles()
	for s in all(sprinkles) do
		s.x+=s.dx
		s.y+=s.dy
		s.dy+=1
		if(s.dy>5)del(sprinkles,s)
	end
end

function place_player()
	--at this time,all tiles should
	--be closed, so create opening
	local ri=rand(0,xmax-1)
	local rj=rand(0,ymax-1)
	while true do
		if lvl[rj][ri].val==0 then
			open_tile(ri,rj)
			break
		else
			ri=rand(0,xmax-1)
			rj=rand(0,ymax-1)
		end
	end
	pp.x=ri*8
	pp.y=rj*8
end

-- minesweeper stuff
-- =================
function open_tile(i,j)
	lvl[j][i].open=true
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
		end
	end end
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
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c7770000777c0000c77c00007777000000000000000000000000000000000000777700007777000000000000000000000000000000000000000000
00700700007777000077770000777700007777000000000000000000007777000077770000877800008778000000000000000000000000000000000000000000
0007700000c7770000777c000077770000c77c00000000000000000000877800008778000077770000777700000aa000000f0000000000000000000000000000
0007700000000000000000000000000000000000007777000077770000788700007887000078870000788700000aa00000000000000000000000000000000000
00700700000000000000000000000000000000000070070000700700007000000000070000777700007777000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000070000700000000000000000000000700000000007000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100000007777777700000d0d10000000100000001000000010000000100000001000000010000000100000000000000000000000000000000000000000000000
0000000076666667000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007666666700dd0d0d00055000000555000005550000050500000555000005000000055500000555000000000000000000000000000000000000000000
00000000766666670d00d00000005000000005000000050000050500000500000005000000000500000505000000000000000000000000000000000000000000
0000000076666667d0000d0000005000000555000000550000055500000555000005550000000500000555000000000000000000000000000000000000000000
0000000077777777d0000d0000005000000500000000050000000500000005000005050000005000000505000000000000000000000000000000000000000000
00000000766666670d00d00000055500000555000005550000000500000555000005550000005000000555000000000000000000000000000000000000000000
000000007777777700dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000001077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700005670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700056670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700566770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000001077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001000000110000001100000011000000110000001100000011000000110000001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000cc000000bbb0000088800000d0d0000022200000300000001110000055500
00000000000000000000000000000000000000000000000000000000000000000000c00000000b0000000800000d0d0000020000000300000000010000050500
00000000000000000000000000000000000000000000000000000000000000000000c000000bbb0000008800000ddd0000022200000333000000010000055500
00000000000000000000000000000000000000000000000000000000000000000000c000000b00000000080000000d0000000200000303000000100000050500
0000000000000000000000000000000000000000000000000000000000000000000ccc00000bbb000008880000000d0000022200000333000000100000055500
00000000000000000000000000000000000000000000000000000000000000001000000110000001100000011000000110000001100000011000000110000001
