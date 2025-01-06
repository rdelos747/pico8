pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
poke(0x5f5d, 2)
end

function _draw()
	cls()
	color(7)
	print("y "..y.." ("..yy..") "..dtb2(yy))
	print("x "..x.." ("..xx..") "..dtb2(xx))
	print("c "..c.." "..dtb2(c))
	
	--new testing of decimal
	--and overflow
	print("")
	//print("d "..d.." "..dtb2(d))
	print(d)
	p_dtb32(d)
	
	rect(64,64,127,127,1)
	srand(1)
	for i=0,10 do
		pset(
			flr(rnd()*62)+65,
			flr(rnd()*62)+65,
			11)
	end
	srand(1.1)
	for i=0,10 do
		pset(
			flr(rnd()*62)+65,
			flr(rnd()*62)+65,
			12)
	end
end

d=1.123


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

-- this doesnt work
function p_dtb32(num)
 local bin=""
 for i=1,32 do
  bin=num %2\1 ..bin
  num>>>=1
  if i%4==0 and i<32 then
   bin=" "..bin
  end
  if i%16==0 then
  	print(bin)
  	bin=" "
  end
	end
 
 //return bin
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
