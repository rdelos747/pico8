pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- snow game with first person
--[[
should include negative simplex
values, and player falls/slips
down when they touch a lower
value than their current
]]--

s_seed=0
c_size=64
half=flr(c_size/2)
chunk={x=0,y=0}
b_down=false
mode_pov=false
pp={
	x=0,y=0,
	dx=1,dy=0,
	mx=0,my=0,
	sp=48
}

function _init()
	printh("------start------")
	os2d_noise(rand(0,100))
	init_chunk()
end

function _draw()
	cls()
	if mode_pov then
		draw_pov()
	else
		draw_lvl()
	end
end


function draw_lvl()
	rectfill(0,0,128,128,6)
	local sx=pp.x%8
	local sy=pp.y%8
	for j=-1,16 do
	for i=-1,16 do
		local ox=(half+i)-flr(15/2)
		local oy=(half+j)-flr(15/2)
		if lvl[oy][ox]<lvl[oy][ox-1] then
			spr(2,(i*8)-sx,(j*8)-sy)
		end
		if lvl[oy][ox]<lvl[oy-1][ox] then
			spr(3,(i*8)-sx,(j*8)-sy)
		end
		if lvl[oy][ox]<lvl[oy+1][ox] then
			spr(4,(i*8)-sx,(j*8)-sy)
		end
		if lvl[oy][ox]<lvl[oy][ox+1] then
			spr(5,(i*8)-sx,(j*8)-sy)
		end
	end end
	spr(pp.sp,56,56)
	color(8)
	print('x:'..pp.x..' y:'..pp.y)
	print('mx:'..pp.mx..' my:'..pp.my)
	print('dx:'..pp.dx..' dy:'..pp.dy)
end

function draw_pov_at(c,mx,my,hz)
	local w=c-1
	local s=128/((w*2)+1)
	local last=-1
	for i=-(w+1),(w+1) do
		local x=mx-(i*pp.dy)--flipx
		local y=my-(i*(-pp.dx))--flipy
		local val=lvl[y][x]
		
		for z=0,val-1 do
			local sp=16
			if(pp.dx==1)sp=20
			local cur=lvl[half][half]
			if z==val-1 then
				if(val>last)sp+=1
				if(val<last)sp+=2
			end
			local h=z*s
			h-=cur*s
			if(z==cur-1)sp=19
			sspr(
				(sp*8)%128,--sx
				flr((sp*8)/128)*8,--sy
				8,8,--sw,sh
				(i+w)*s,
				(((128-s)/2)-h)+hz,
				s,s
			)
		end
		
		last=val
	end
end

function draw_pov()
	rectfill(0,0,128,64,0)
	local c=20
	while c>=0 do
		c-=1
		local my=half+(c*pp.dy)
		local mx=half+(c*pp.dx)
		local hz=c-15
		if hz>=0 then
			draw_pov_at(c,mx,my,hz)
			if hz==0 then
				rectfill(0,64,128,128,6)
			end
		else
			draw_pov_at(c,mx,my,0)
		end
	end	
	print('x:'..pp.x..' y:'..pp.y)
	print('dx:'..pp.dx..' dy:'..pp.dy)
	print('c:'..c)
end

function _update()
	if not mode_pov then
	if btn(⬆️) then 
		pp.dy=-1;pp.dx=0;pp.y-=1;
		pp.sp=50+(pp.y%3)
	elseif btn(⬇️) then
	 pp.dy=1;pp.dx=0;pp.y+=1;
	 pp.sp=55+(pp.y%3)
	elseif btn(⬅️) then
		pp.dy=0;pp.dx=-1;pp.x-=1;
		pp.sp=53+(pp.x%2)
	elseif btn(➡️) then
		pp.dy=0;pp.dx=1;pp.x+=1;
		pp.sp=48+(pp.x%2)
	end end
	
	local lastmx=pp.mx
	local lastmy=pp.my
	pp.mx=flr(pp.x/8)
	pp.my=flr(pp.y/8)
	if lastmx !=pp.mx or
				lastmy !=pp.my then
		update_chunk()
	end
		
	if btn(🅾️) then
		if not b_down then
			mode_pov= not mode_pov
		end
		b_down=true
	else
		b_down=false
	end
end

function init_chunk()
	lvl={}
	for j=0,c_size-1 do
		lvl[j]={}
	for i=0,c_size-1 do
		local x=i-half
		local y=j-half
		lvl[j][i]=get_noise(x,y)
	end end
end

function update_chunk()
	-- shift chunk
	n_lvl={}
	for j=0,c_size-1 do
		n_lvl[j]={}
	for i=0,c_size-1 do
		local jj=(j+pp.dy)%c_size
		local ii=(i+pp.dx)%c_size
		n_lvl[j][i]=lvl[jj][ii]
	end end
	lvl=n_lvl
	
	-- generate right
	if pp.dx==1 then
		for j=0,c_size-1 do
			lvl[j][c_size-1]=get_noise(
				pp.mx+half,
				pp.my+(j-half)
			)
		end
	-- generate left
	elseif pp.dx==-1 then
		for j=0,c_size-1 do
			lvl[j][0]=get_noise(
				pp.mx-half,
				pp.my+(j-half)
			)
		end
	-- generate down
	elseif pp.dy==1 then
		for i=0,c_size-1 do
			lvl[c_size-1][i]=get_noise(
				pp.mx+(i-half),
				pp.my+half
			)
		end
	-- generate up
	elseif pp.dy==-1 then
		for i=0,c_size-1 do
			lvl[0][i]=get_noise(
				pp.mx+(i-half),
				pp.my-half
			)
		end
	end
		
	
end

function get_noise(x,y)
	local c=os2d_eval(x/32,y/32)
	//c+=os2d_eval(x/16,y/16)/2
	c+=os2d_eval(x/8,y/8)/4
	return mid(0,flr(c*10),9)
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
-- opensimplex noise

-- adapted from public-domain
-- code found here:
-- https://gist.github.com/kdotjpg/b1270127455a94ac5d19

--------------------------------

-- opensimplex noise in java.
-- by kurt spencer
-- 
-- v1.1 (october 5, 2014)
-- - added 2d and 4d implementations.
-- - proper gradient sets for all dimensions, from a
--   dimensionally-generalizable scheme with an actual
--   rhyme and reason behind it.
-- - removed default permutation array in favor of
--   default seed.
-- - changed seed-based constructor to be independent
--   of any particular randomization library, so results
--   will be the same when ported to other languages.

-- (1/sqrt(2+1)-1)/2
local _os2d_str=-0.211324865405187
-- (  sqrt(2+1)-1)/2
local _os2d_squ= 0.366025403784439

-- cache some constant invariant
-- expressions that were 
-- probably getting folded by 
-- kurt's compiler, but not in 
-- the pico-8 lua interpreter.
local _os2d_squ_pl1=_os2d_squ+1
local _os2d_squ_tm2=_os2d_squ*2
local _os2d_squ_tm2_pl1=_os2d_squ_tm2+1
local _os2d_squ_tm2_pl2=_os2d_squ_tm2+2

local _os2d_nrm=47

local _os2d_prm={}

-- gradients for 2d. they 
-- approximate the directions to
-- the vertices of an octagon 
-- from the center
local _os2d_grd = 
{[0]=
     5, 2,  2, 5,
    -5, 2, -2, 5,
     5,-2,  2,-5,
    -5,-2, -2,-5,
}

-- initializes generator using a 
-- permutation array generated 
-- from a random seed.
-- note: generates a proper 
-- permutation, rather than 
-- performing n pair swaps on a 
-- base array.
function os2d_noise(seed)
    local src={}
    for i=0,255 do
        src[i]=i
        _os2d_prm[i]=0
    end
    srand(seed)
    for i=255,0,-1 do
        local r=flr(rnd(i+1))
        _os2d_prm[i]=src[r]
        src[r]=src[i]
    end
end

-- 2d opensimplex noise.
function os2d_eval(x,y)
    -- put input coords on grid
    local sto=(x+y)*_os2d_str
    local xs=x+sto
    local ys=y+sto
   
    -- flr to get grid 
    -- coordinates of rhombus
    -- (stretched square) super-
    -- cell origin.
    local xsb=flr(xs)
    local ysb=flr(ys)
   
    -- skew out to get actual 
    -- coords of rhombus origin.
    -- we'll need these later.
    local sqo=(xsb+ysb)*_os2d_squ
    local xb=xsb+sqo
    local yb=ysb+sqo

    -- compute grid coords rel.
    -- to rhombus origin.
    local xins=xs-xsb
    local yins=ys-ysb

    -- sum those together to get
    -- a value that determines 
    -- which region we're in.
    local insum=xins+yins

    -- positions relative to 
    -- origin point.
    local dx0=x-xb
    local dy0=y-yb
   
    -- we'll be defining these 
    -- inside the next block and
    -- using them afterwards.
    local dx_ext,dy_ext,xsv_ext,ysv_ext

    local val=0

    -- contribution (1,0)
    local dx1=dx0-_os2d_squ_pl1
    local dy1=dy0-_os2d_squ
    local at1=2-dx1*dx1-dy1*dy1
    if at1>0 then
        at1*=at1
        local i=band(_os2d_prm[(_os2d_prm[(xsb+1)%256]+ysb)%256],0x0e)
        val+=at1*at1*(_os2d_grd[i]*dx1+_os2d_grd[i+1]*dy1)
    end

    -- contribution (0,1)
    local dx2=dx0-_os2d_squ
    local dy2=dy0-_os2d_squ_pl1
    local at2=2-dx2*dx2-dy2*dy2
    if at2>0 then
        at2*=at2
        local i=band(_os2d_prm[(_os2d_prm[xsb%256]+ysb+1)%256],0x0e)
        val+=at2*at2*(_os2d_grd[i]*dx2+_os2d_grd[i+1]*dy2)
    end
   
    if insum<=1 then
        -- we're inside the triangle
        -- (2-simplex) at (0,0)
        local zins=1-insum
        if zins>xins or zins>yins then
            -- (0,0) is one of the 
            -- closest two triangular
            -- vertices
            if xins>yins then
                xsv_ext=xsb+1
                ysv_ext=ysb-1
                dx_ext=dx0-1
                dy_ext=dy0+1
            else
                xsv_ext=xsb-1
                ysv_ext=ysb+1
                dx_ext=dx0+1
                dy_ext=dy0-1
            end
        else
            -- (1,0) and (0,1) are the
            -- closest two vertices.
            xsv_ext=xsb+1
            ysv_ext=ysb+1
            dx_ext=dx0-_os2d_squ_tm2_pl1
            dy_ext=dy0-_os2d_squ_tm2_pl1
        end
    else  //we're inside the triangle (2-simplex) at (1,1)
        local zins = 2-insum
        if zins<xins or zins<yins then
            -- (0,0) is one of the 
            -- closest two triangular
            -- vertices
            if xins>yins then
                xsv_ext=xsb+2
                ysv_ext=ysb
                dx_ext=dx0-_os2d_squ_tm2_pl2
                dy_ext=dy0-_os2d_squ_tm2
            else
                xsv_ext=xsb
                ysv_ext=ysb+2
                dx_ext=dx0-_os2d_squ_tm2
                dy_ext=dy0-_os2d_squ_tm2_pl2
            end
        else
            -- (1,0) and (0,1) are the
            -- closest two vertices.
            dx_ext=dx0
            dy_ext=dy0
            xsv_ext=xsb
            ysv_ext=ysb
        end
        xsb+=1
        ysb+=1
        dx0=dx0-_os2d_squ_tm2_pl1
        dy0=dy0-_os2d_squ_tm2_pl1
    end
   
    -- contribution (0,0) or (1,1)
    local at0=2-dx0*dx0-dy0*dy0
    if at0>0 then
        at0*=at0
        local i=band(_os2d_prm[(_os2d_prm[xsb%256]+ysb)%256],0x0e)
        val+=at0*at0*(_os2d_grd[i]*dx0+_os2d_grd[i+1]*dy0)
    end
   
    -- extra vertex
    local atx=2-dx_ext*dx_ext-dy_ext*dy_ext
    if atx>0 then
        atx*=atx
        local i=band(_os2d_prm[(_os2d_prm[xsv_ext%256]+ysv_ext)%256],0x0e)
        val+=atx*atx*(_os2d_grd[i]*dx_ext+_os2d_grd[i+1]*dy_ext)
    end
    return val/_os2d_nrm
end

-- note kurt's original code had
-- an extrapolate() function
-- here, which was called in 
-- four places in eval(), but i
-- found inlining it to produce
-- good performance benefits.
__gfx__
00000000000330001110100111111111000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000033330011000100010101010000000000000707000000000000100000011000000220000000d00000eeee00000ff0000088880000099000000aa000
00700700003333001110100100000000000000000070007700000000000110000010010000200200000dd00000e0000000f00000000008000090090000a00a00
0007700000033000110001000000000000000000000000070000000000001000000001000000200000d0d00000eee00000fff000000008000009900000a00a00
0007700000333300111010011010101000100010000000770000000000001000000010000000020000dddd0000000e0000f00f000000800000900900000aaa00
007007000033330011000100000000000000000000000707000000000000100000010000002002000000d00000000e0000f00f00000800000090090000000a00
000000000033330011101001000000000000000000700077000000000001110000111100000220000000d00000eee000000ff0000008000000099000000aa000
00000000003333001100010000000000010101010000000700000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000011000000066666666777777770000000770000000000000000000000000000000000000000000000000000000000000000000000000000000
16161616000000166100000066666666676766760000007667000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000001666610000066666666666667660000076666700000000000000000000000000000000000000000000000000000000000000000000000000000
61666166000016666661000066666666667666660000766666670000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000166666666100066666666666666660007666666667000000000000000000000000000000000000000000000000000000000000000000000000000
66666666001666666666610066666666666666660076666666666700000000000000000000000000000000000000000000000000000000000000000000000000
66666666016666666666661066666666666666660766666666666670000000000000000000000000000000000000000000000000000000000000000000000000
66666666166666666666666166666666666666667666666666666667000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d0dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dccd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000700000007000000dd000000dd000000dd0000007000000700000000dd000000dd000000dd000000000000000000000000000000000000000000000000000
00cdd00000cdd000000cc000000cc000000cc000000ddc00000dc000000770000007700000077000000000000000000000000000000000000000000000000000
00cd000000cdd000000cc000000cc000000cc0000000dc00000ddc00000dd000000dd000000dd000000000000000000000000000000000000000000000000000
000dd000000dd000000d0000000dd0000000d000000dd000000dd000000d0000000dd0000000d000000000000000000000000000000000000000000000000000
00d0d000000dd000000d0000000dd0000000d000000d0d00000dd000000d0000000dd0000000d000000000000000000000000000000000000000000000000000
__map__
1616161616161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1616161616161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
161616181b161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
161618161c1b1616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
161617292b1c1b16000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16161917161c1c16000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16161619161c1a16000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1616161616161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000011000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
