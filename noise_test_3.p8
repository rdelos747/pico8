pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
colors={
		0,1,5,2,13,3,9,10,8,7
//0,1,2,3,4, 5,6, 7,8,9
}

function rand(n,m)
	return flr(rnd((m+1)-n))+n
end

function _init()
	printh("===starting===")
	//os2d_noise(rand(0,100))
	os2d_noise(0)
end

go=0
function _draw()
	if(go==1)return
	go=1
	
	cls()
	local lvl={}
	local c_min=1000
	local c_max=-1000
	
	for j=0,127 do
		lvl[j]={}
	for i=0,127 do
		local c=get_noise(i,j)
		c_min=min(c,c_min)
		c_max=max(c,c_max)
		lvl[j][i]=c
	end end
	
	printh("c min: "..c_min)
	printh("c max: "..c_max)
	
	local d_min=1
	local d_max=-1
	local v_min=10
	local v_max=0
	for j=0,127 do
	for i=0,127 do
		local d=lvl[j][i]
		d=(d-c_min)/(c_max-c_min)
		d_min=min(d,d_min)
		d_max=max(d,d_max)
		
		v=flr(d*500)
		v_min=min(v,v_min)
		v_max=max(v,v_max)
		
		//print(v,i*4,j*6,colors[v+1])
		//pset(i,j,colors[v+1])
		
		if v==200 then
			pset(i,j,2)
		end
		
		--[[
		if (v>=51 and v<=51)  then
			pset(i,j,13)
		end
		]]--
	end end
	printh("d min: "..d_min)
	printh("d max: "..d_max)
	printh("v min: "..v_min)
	printh("v max: "..v_max)
end

function _update()
end

-- scattered:
-- many low/mid values
-- med high values
-- -0.8093,0.8551
--[[
function get_noise(x,y)
	local c=os2d_eval(x,y)
	return c
end
--]]

-- giant blob:
-- big rings of 7,8s
-- maybe a 9 in the center
--[[
function get_noise(x,y)
	local c=os2d_eval(x/32,y/32)
	//c+=os2d_eval(x/16,y/16)/2
	//c+=os2d_eval(x/8,y/8)/4
	return c
end
]]--

-- many smaller blobs:
-- rings surrounding either
-- low or high values
--[[
function get_noise(x,y)
	local c=os2d_eval(x/32,y/32)
	c+=os2d_eval(x/16,y/16)/2
	c+=os2d_eval(x/8,y/8)/4
	c+=os2d_eval(x/8,y/8)/4
	c+=os2d_eval(x/8,y/8)/4
	return c
end
--]]

--[[
it appears that the scale of
the rings is determined by
the first denominator, eg
	- (x/64,y/64) => huge rings
	- (x/8,y/8) => small rings

a trailing denom in the first 
call doesn't seem to affect 
anything

smaller trailing denom seems
to add more noise?
]]--

function get_noise(x,y)
	local c=os2d_eval(x/64,y/64)
	c+=os2d_eval(x/4,y/4)/2
	return c
end


--[[
function get_noise(x,y)
	local c=os2d_eval(x/64,y/64)
	c+=os2d_eval(x/32,y/32)/2
	c+=os2d_eval(x/16,y/16)/2
	c+=os2d_eval(x/8,y/8)/2
	return c
end
]]--
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
