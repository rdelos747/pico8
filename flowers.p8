pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
w_seed=0
ch_size=32 //chunk size
half=flr(ch_size/2)
ca_rad=1 //cache radius

pp={x=0,y=0}
cam={x=0,y=0,sx=0,sy=0}
//chunk={} //current chunk
cx=0;cy=0 //chunk coords
chunks={} //chunk cache

function _init()
	printh("")
	printh("startup")
	printh("=======")
	for j=-1,1 do
	for i=-1,1 do
		add(chunks,update_chunk(i,j))		
	end end
end

function _draw()
	cls()
	spr(1,pp.x-4,pp.y-4)
	camera(cam.x+cam.sx,
		cam.y+cam.sy)
		
	for ch in all(chunks) do
		for j=0,ch_size-1 do
		for i=0,ch_size-1 do
			local t=ch[j][i]
			spr(t.s,t.x*8,t.y*8)
		end end
		print(count(ch))
	end
	
	draw_hud()
end

function draw_hud()
	local hx=cam.x
	local hy=cam.y
	rectfill(hx+0,hy+112,hx+128,hy+128,0)
	color()
	print("px "..pp.x,hx+0,hy+112)
	print("py "..pp.y,hx+30,hy+112)
	
	print("cx "..cx,hx+0,hy+120)
	print("cy "..cy,hx+30,hy+120)
	print("nc "..count(chunks),hx+60,hy+120)
end

function _update()
	update_player()
	update_cam()
	update_cache()
end

function update_player()
	if btn(⬅️)then
		pp.x-=1
	elseif btn(➡️)then
		pp.x+=1
	end
	if btn(⬆️)then
		pp.y-=1
	elseif btn(⬇️)then
		pp.y+=1
	end
end

function update_cam()
	//update_shake()
	cam.x=pp.x-64
	cam.y=pp.y-64
	//if(cam.x<0)cam.x=0
	//if(cam.y<0)cam.y=0
	//if cam.x>(xmax*8)-128 then 
	//	cam.x=(xmax*8)-128
	//end
	//if cam.y>((ymax*8)-128)+hud_h then 
	//	cam.y=((ymax*8)-128)+hud_h
	//end
end

-- ==========
-- helpers
-- ==========
function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function chance(n)
	return rand(0,100)<n
end
-->8
function update_cache()
	local cx_cur=flr(pp.x/(ch_size*8))
	local cy_cur=flr(pp.y/(ch_size*8))
	
	if cx_cur==cx and cy_cur==cy then
		return
	end
	
	local cx_last=cx
	local cy_last=cy
	cx=cx_cur
	cy=cy_cur
	printh("=====")
	printh("new chunk "..cx..","..cy)
	printh("")
	
	local old={}
	for ch in all(chunks) do
		local i=ch[0][0].x/ch_size
		local j=ch[0][0].y/ch_size
		
		if abs(i-cx)>1 or abs(j-cy)>1 then
			add(old,{
				x=cx_last+(cx-i),
				y=cy_last+(cy-j)
			})
			del(chunks,ch)
		end		
	end
	
	for ch in all(old) do
		nc=update_chunk(ch.x,ch.y)
		add(chunks,nc)
	end
end

function update_chunk(x,y)
	local seed=(x<<8)+y
	local ch={}
	for j=0,ch_size-1 do
		ch[j]={}
	for i=0,ch_size-1 do
		local s=0
		if j==0 or j==ch_size-1 or
					i==0 or i==ch_size-1 then
			s=2
		end
		ch[j][i]={
			x=(ch_size*x)+i,
			y=(ch_size*y)+j,
			s=s
		}
	end end
	return ch
end
__gfx__
0000000000000000b0000bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000b00bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777000bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000777700000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c77c0000bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777000bb00b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007000b0000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000700700b000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0200000000000000020000000000000002000000000000000200000000000000020000000000000002000000000000000200000000000000020000000000000002000000000000000200000000000000020000000000000002000000000000000200000000000000020000000000000002000000000000000200000000000002
