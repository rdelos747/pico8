pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--constants
t=true
f=false
xmn=0
xmx=0//896
ymn=0
ymx=0//128

--game
--0:start,1:game
mode=0

--start menu
sm={
pl=1,
press=f,
}

--cam
cam={
x=0,
y=0,
xdir=0,
ydir=0,
shake=0,
samt=1,
tm=1000
}

--player
pp={
x=100,
y=100,
rot={f,f},
mov={0,0},
drr={0,-1},
sp=1,
lzr=0,
}
p_spd=1

lzrs={}

-- helpers
function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function chance(n)
	return rand(0,100) < n
end

function _init()	
end

--draw
function _draw()
	cls()
	rectfill(0,0,128,128,14)
	camera(cam.x,cam.y)
	if(mode==0)start_draw()
	if(mode==1)game_draw()
end

function start_draw()
	if sm.pl==1 then
		line(50,70,81,70,12)
		line(82,70,82,66,12)
		print("1 player", 50,64,12)
		print("2 player", 50,76,6)
	else
		line(50,82,81,82,11)
		line(82,82,82,78,11)
		print("1 player", 50,64,6)
		print("2 player", 50,76,11)
	end
end

function game_draw()
	m_x=flr(cam.x/8)-1
	m_y=flr(cam.y/8)-1
	map(m_x,m_y,m_x*8,m_y*8,18,17)
	--hud
	line(cam.x+1,cam.y+127,
		cam.x+127,cam.y+127,8)
	line(cam.x+1,cam.y+119,
		cam.x+127,cam.y+119,8)
	--lazers
	for l in all(lzrs) do
		line(l.x1,l.y1,l.x2,l.y2,8)
		line(l.x1-1,
			l.y1-1,
			l.x2-1,
			l.y2-1)
	end
	--player
	spr(pp.sp,pp.x,pp.y,
	1,1,pp.rot[1],pp.rot[2])
end

function _update()
	if(mode==0)start_update()
	if(mode==1)game_update()
	shake()
end

function start_update()
	if not sm.press then
		if btn(3) and sm.pl<2 then
			sm.pl=2
			sm.press=t
			shake_s()
		elseif btn(2) and sm.pl>1 then
			sm.pl=1
			sm.press=t
			shake_s()
		end
	elseif not btn(2) and 
								not btn(3) then
		sm.press=f	
	end
	if btn(4) or btn(5) then
		mode=1
		game_init()
	end
end

--game
function game_init()
	//cam.x=rand(0,896)
	//cam.y=rand(0,128)
	//pp.x=rand(cam.x+20,
	//	(cam.x+128)-20)
	//pp.y=rand(cam.y+20,
	//	(cam.y+128)-20)
end

function game_update()
	-- get button press
	pp.mov={0,0}
	local press_lzr=f
	if btn(2)then
		pp.rot[2]=f
		pp.mov[2]=-1
	end
	if btn(3)then
		pp.rot[2]=t
		pp.mov[2]=1
	end
	if btn(0)then
		pp.rot[1]=t
		pp.mov[1]=-1
	end
	if btn(1)then
		pp.rot[1]=f
		pp.mov[1]=1
	end
	
	if (btn(5))press_lzr=t
	
	--move and rotate player
	pp.x+=pp.mov[1]
	pp.y+=pp.mov[2]
	if pp.mov[1] != 0 or
				pp.mov[2] != 0 then
		pp.drr=pp.mov
		if pp.mov[1] ==0 and 
					pp.mov[2] !=0 then
			pp.sp=1
		elseif pp.mov[1] !=0 and 
									pp.mov[2] ==0 then
			pp.sp=2
		else
			pp.sp=3
		end
	end
	
	if pp.lzr > 0 then
		pp.lzr-=1
	elseif press_lzr then
		pp.lzr=5
		shoot(pp.x+4,pp.y+4,pp.drr)
	end

	move_cam()
	update_lzrs()
end

function shoot(x,y,drr)
	local l={
	x1=x,
	y1=y,
	x2=x,
	y2=y,
	tim=5
	}
	local draw=t
	while draw do
		l.x2+=drr[1]*8
		l.y2+=drr[2]*8
		if(l.x2<cam.x)draw=f
		if(l.x2>cam.x+128)draw=f
		if(l.y2<cam.y)draw=f
		if(l.y2>cam.y+128)draw=f
		local mx=flr((cam.x+l.x2)/8)
		local my=flr((cam.y+l.y2)/8)
		if mget(mx,my)>=64then
			draw=f
		end
	end
	add(lzrs,l)
end

function update_lzrs()
	for l in all(lzrs) do
		l.tim-=1
		if(l.tim==0)del(lzrs,l)
	end
end

--cam
function move_cam()
	if(cam.shake>0)return
	cam.x+=cam.xdir*0.2
	cam.y+=cam.ydir*0.2
	cam.tm-=1
	if cam.x<=xmn then
		cam.x=xmn
		cam.tn=0
	elseif cam.x>=xmx then
		cam.x=xmx
		cam.tm=0
	end
	if cam.y<=ymn then
		cam.y=ymn
		cam.tm=0
	elseif cam.y>=ymx then
		cam.y=ymx
		cam.tm=0
	end
	if cam.tm<=0 then
		cam.tm=rand(100,500)
		cam.xdir=rand(-1,2)
		cam.ydir=rand(-1,2)
	end
end

--short shake
function shake_s()
	cam.shake=8
end

--long shake
function shake_l()
	cam.shake=16
end

--shake
function shake()
	if cam.shake>0 then
		if cam.shake%2==0 then
			cam.x+=cam.samt*2
			cam.samt*=-1
		end
		cam.shake-=1
	end
end
__gfx__
000000000220022002222220000220000000000000000000000000000000000000000000000000000000000000000000020000200000000000000000fffff200
000000002772277221177772002772000000000000000000000000000000000000000000000000000000000000000000200002000000000000000000fffff200
007007002772277221ccc7720277222000000000000000000000000000000000000000000000000000000000000000002002020000000200222222220ffff200
0007700027cccc7221ccc22027ccc27200000000000000000000000000000000000000000000000000000000002000000002000002000000eeeeeeee0ffff200
0007700027cccc7221ccc22021ccc77200000000000000000000000000000000000000000000000000000000020000000200002000000000ffffffff0ffff200
0070070021cccc1221ccc77221ccc72000000000000000000000000000000000000000000000000000000000020002000020020000000200ffffffff0ffff200
0000000021111112211777722211720000000000000000000000000000000000000000000000000000000000000002000200020000000000fffffffffffff200
0000000002222220022222200222200000000000000000000000000000000000000000000000000000000000000000000200000000000000ff0000fffffff200
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000ff002effff
0000000007700770011777700007700000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffff002effff
000000000770077001ccc7700077000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffff002efff0
0000000007cccc7001ccc00007ccc07000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffff002efff0
0000000007cccc7001ccc00001ccc77000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffff002efff0
0000000001cccc1001ccc77001ccc7000000000000000000000000000000000000000000000000000000000000000000000000000000000022222222002efff0
000000000111111001177770011170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002effff
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002effff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002efffffffff200
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002efffffffff200
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022effffffffffe22
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeffffffffffffee
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff22fffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff2002ffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff2002ffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff22fffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022efffffffffff22
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002efffffffff200
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002efffffffff200
002222000ff00ff00022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02ffff20000000000299992000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2eeffff20ff00ff02ee9999200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2ffffff20ff20ff22999999200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2eeffff2000000002ee9999200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2ffffff2000000002999999200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2eeefff2000000002eee999200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02222220000000000222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200200000ff0000020020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00222200000ff0000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff20000022222200000000002222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff200022ffff0022000000229999002200000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff2002ffffff0000200002999999000020000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222002ffffff0000200002999999000020000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff2002fffff00000200002999990000020000000000000000000000000000000000000000000000000000000000000000000000000000000000
20eeffeffeffeef2002ff22222200200002992222220020000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff2002222ffff222200002222999922220000000000000000000000000000000000000000000000000000000000000000000000000000000000
20eeffeffeffeef200222ffffff22200002229999992220000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff20020eeffffeef2000020ee9999ee920000000000000000000000000000000000000000000000000000000000000000000000000000000000
20eeffeffeffeef20020eefeefeef2000020ee9ee9ee920000000000000000000000000000000000000000000000000000000000000000000000000000000000
20fffffffffffff20020fffeeffff2000020999ee999920000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222220002222222222000000222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
09090e0e0e0e0e0e0e0e0e0e2e2f0e00000000002e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e
19001e1e1e1e1e1e1e1e1e1e3e3f1e212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e
1900606121196061210d21191f0f21212100000000000070707070707070707070707070707070707070707070707070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e
00217071404270714021400d1f0f00212100000000005555555555557070707070707070707070707070707070707070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e
1921002150522100500d50401f0f21210000000000005555555555550909000000000000090909000000000009090900000000000000000000000000000000000000000000000000002c00000000002c000000000000000000000000000000000000002c00000000000000000000002c0000002c00000000000000000000002e
09414141510909420d0042500900000000000000000000550909090900000000000000000021212121000000002121212100000000000000000000000000000000000000000000000000000000000000000000000000000000002c0000000000000000000000000000000000000000000000000000000000000000000000002e
0909626351430052400d520d000000000000000000000055190021212121000000000000002121212100000000212121210000000000000000002c0000000000002c000000000000000000000000000000002c0000000000000000002c000000000000000000000000000000000000000000000000000000002c00000000002e
1900727351530b005000002121215555000000000000005519002121212100000000000021000021210000002100002121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000002e
1900212151210c0c0c0b0b0b0000005555000000000055550021000021210000000000002100212100000000210021210000000000000000000000002c000000000000000000000000000000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000000000000000002e
00216465210b0b0c0c0b0c0b0b005555555500000000555519210021210000000000000009000000000000000900000000000000000000000000000000000000000000000000002c0000000000000000000000000000000000000000000000000000000000000000000000000000002c000000002c000000000000002c00002e
090974750000000b0c0c0b0c00005555555555555555555555550000000000000000000000000000000000000000000000000000000d000d2c000d0000000000002c000000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0000000000000000000000000000002c00000000000000000000000000000000000000000000000000002e
1900212121210b0b0b0b2100000055555555550000005500090000000000000000090000000000000000000021210000000000000000000000000000000d000d0d0d0d0d0d0d0000000000002c0000000000000000002c000000000000000000000000000000000000000000000000000000000000000000000000000000002e
19002121212100000b0000000000005555550909090000002121210000000000002121210000000900000019002121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c0000000000000000000000000000000000000000000000000000000000000000002e
00210000212100000000000000000000001900212121210000000000000019002121212100000021212100190021212121000000000000000000000000000000000000000000000000000000000000000000002c0000000000000000000000002c0000000000000000002c00000000000000000000000000000000000000002e
192100212100000000000000000000000019002121212100000009090900002100002121000000212121000021000021210000000000002c00000000002c0000000000000000000000000000000000000000000000000d0d0d0d0d0d0d0d0d0d0d0d000d000d00000000000d00000000000d0d0000000000000000000000002e
090900000000000000000000000000000000210000212100000009090909192100212100000000002121001921002121000000000d0000000000000000000000000000000000000000002c000000000000000d0d0d0d0d0000000000000000000000000000000000000000000000000000000000002c000d000d00000d0d0d2e
09000000000000000021210000000000001921002121000000001900212109090000000000000021210000090900000000000000000d0d0d0d0d0d0d0d000d000d000d00000d000d00000d00000d000d0d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000002c00000000002e
2121210000000000002121000000000000090900000000000000190021210900000000000000000000000009000000000000000000000000002c0000000000002c00000000002c00000000000000000000000000000000000000000000000000000000000000000000000000002c00000000000000000000000000000000002e
2e007070700021000021210000000000000900000000000000000021000021212100000000000000000000212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000000000000000000000000000000000002e
2e00700000192100212100000000000000212121000000000000192100212100190021212121210909090900000000007070700000000000000000000000000000000000000000000000000000000000000d0d0d0d00000000000000000000002c0000000000000000002c00000000000000000000000000000000000000002e
2e00700000090900000000000000000000002121000000000000090900000000002100002121000909090900000000000d700d000000000d0d000d0d0d0d000d000d000000000d00000d0000000d000d0d0d00000d0d0d0d0d0d0d0d0d0d0d0d0d000d000d000d000d0d000d0d000d000d0d0d0d0d0d000d000d000d0d0d0d2e
2e0070000009000000000000000000000000210000000000000009000909090900000000000000190021090909090000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c0000000000000000002e
2e007000002121210000000000000000000000000000000000002121190021212121000000000019002119002121212100000000002c000000000000000000000000000000000000000000000000000000000000000000000000002c00000000000000002c000000000000000000002c000000000000000000002c000000002e
2e00700000191919192121210000000000000000000000000000000019002121212100000021000021001900212121210000000000000000000000000000000000000000000000000000002c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e
2e00700000001919192119190021212121000000000000000000000000210000212100000021001921000021000021210000000000000000000000000000002c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e
2e0070000000191919001919002121212100000000000000000000001921002121000000002100090900192100212100000000000000000000000000000000000000000000000000000000000000000000002c00000000002c00000000000000000000000000002c0000000d0d0d0d0d0d00000000000000000000000000002e
2e00700000000000190000002100002121000000000000000000000009090000000000000000000900000909000000000000000d0d0d0d0d0d0d0d0d0d0d0000000000000d0d0d2c0d0d0d0d0d0d0d0d00000000000000000000000000002c000000000d0d0d000d000d0d0000000000000d0d0d0d0d000d000d0d0d0000002e
2e00700000191919191a19192100212100000000000000000000000009000000000000000000002121210900000000000000000d0d00000d00000d000d0d0d0d0d0d0d0d0d0000000d00000d000d0d0d0d0d0d0d0d0d0000000d0d0d0d0d0d0d0d0d0d0000000000000000000000000000002c00000000000000002c0d0d002e
2e0070707070707070700000191919191a19192100212100000000002121210000000000000000000070212121000000000000000000002c000000000000000000000000000000000000000000002c000000000000000d000d000d0d0d0d0000000000000000000000000000000000000000000000000d0d0d0d0d0d0000002e
2e000000000000000000000000000000000000000000000000000000000000002121210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000d000d0d000d0d0d000d0d0d00000d0d0d0d0d0d0d0000000000000000002e
2e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0d0d0000000000000000000000000000002e
2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e
