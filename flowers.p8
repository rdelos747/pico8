pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
c_size=16 //chunk size
half=flr(ch_size/2)

noise_seed=0

pp={x=0,y=0}
cam={x=0,y=0,sx=0,sy=0}
//chunk={} //current chunk
cx=0;cy=0 //chunk coords
chunks={} //chunk cache

function _init()
	printh("")
	printh("startup")
	printh("=======")
	noise_seed=0
	//noise_seed=(rand(0,100))
	os2d_noise(noise_seed)
	
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
	update_chunk()
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

function init_lvl()
	lvl={}
	for j=0,c_size-1 do
		lvl[j]={}
	for i=0,c_size-1 do
		lvl[j][i]=get_noise(j,i)
	end end
end

function update_chunk(i,j)
	local cx_cur=flr(pp.x/(ch_size*8))
	local cy_cur=flr(pp.y/(ch_size*8))
	
	if cx_cur==cx and cy_cur==cy then
		return
	end
	
	local cx_last=cx
	local cy_last=cy
	cx=cx_cur
	cy=cy_cur
end

function update_lvl()
	n_lvl={}
	for j=0,c_size-1 do
		n_lvl[j]={}
	for i=0,c_size-1 do
		local jj=(j+pp.dy)%c_size
		local ii=(i+pp.dx)%c_size
		n_lvl[j][i]=lvl[jj][ii]
	end end
	lvl=n_lvl
	
	// do left/right/up/down
	// generation here
	
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
