pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
poke(0x5f5d, 2)
end

function _draw()
	cls()
	
	print("y "..y.." ("..yy..") "..dtb2(yy))
	print("x "..x.." ("..xx..") "..dtb2(xx))
	print("c "..c.." "..dtb2(c))
end


x=0
y=0
xx=0
yy=0
c=0
function _update()
	if btnp(⬅️) then
		x=mid(-128,x-1,127)
	end
	if btnp(➡️) then
		x=mid(-128,x+1,127)
	end
	if btnp(⬆️) then
		y=mid(-128,y-1,127)
	end
	if btnp(⬇️) then
		y=mid(-128,y+1,127)
	end
	xx=x+128
	yy=y+128
	c=(yy<<8)+xx
end


function dtb2(num)
 local bin=""
 for i=1,16 do
  bin=num %2\1 ..bin
  num>>>=1
  if i%4==0 and i<16 then
   bin=" "..bin
  end
	end
 
 return bin
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000