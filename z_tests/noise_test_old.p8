pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- procedurally generated
-- map using simplex noise
-- that allows for chunk style
-- "rooms".

-- because simplex is used for
-- generating tiles, we do not
-- need to worry about
-- combining the chunk seed
-- with the world seed to
-- create them.

-- each chunk has a "fade"
-- around the edges which
-- guarantees connectivity.

-- we can still control 
-- chunk types by generating
-- a specific tile in the
-- chunk and using that value
-- as a separate seed for that
-- chunk.

c_size=16
half=flr(c_size/2)
num_chunks=flr(128/c_size)
fade={}

chunks={}
lvl={}

noise_seed=0

g_min=1000
g_max=-1000

function _init()
	printh("")
	printh("-----start-----")
	init_fade()
	//noise_seed=0
	noise_seed=(rand(0,100))
	os2d_noise(noise_seed)
	create_level()
	printh("min "..g_min)
	printh("max "..g_max)
end

draw=true
function _draw()
	if draw then
		cls()
		//draw_grid()
		for j=0,127 do
		for i=0,127 do
			local c=lvl[j][i]
			if c>0 then
			pset(i,j,lvl[j][i])
				end
		end end
	end
	draw=false
end

function draw_grid()
	local i=c_size
	while i<=128-c_size do
		line(i,0,i,128,15)
		line(0,i,128,i,15)
		i+=c_size
	end
end

function _update()
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

function init_fade()
	for j=0,c_size-1 do
	fade[j]={}
	for i=0,c_size-1 do
		local d=max(
			abs(i-half),
			abs(j-half)
		)
		d=abs(half-d)+1
		fade[j][i]=min(1,d/3)
	end end
end

test=0
function get_noise(x,y)
	//local c=os2d_eval(x/32,y/32)
	local c=0
	c+=os2d_eval(x,y)
	//c+=os2d_eval(x/6,y/6)
	//c+=os2d_eval(x/4,y/4)/4
	//c+=os2d_eval(x/16,y/16)/2

	//return mid(0,flr(c*10),9)
	g_min=min(g_min,c)
	g_max=max(g_max,c)
	return c
end

function decode_noise(n)
	//if(n>=0.9)return 7 	//white
	if(n>=0.8)return 8 	//red
	//if(n>=0.7)return 9 	//orange
	//if(n>=0.6)return 10 //yellow
	//if(n>=0.5)return 11 //green
	//if(n>=0.4)return 3 	//d green
	if(n>=0.3)return 12 //cyan
	//if(n>=0.2)return 13 //purple
	if(n>=0.2)return 1 	//d blue
	return 0
end

function create_level()
	for j=0,127 do
		lvl[j]={}
	end
	
	for j=0,num_chunks-1 do
	for i=0,num_chunks-1 do
		
		local ch=get_chunk_type(
			i*c_size,
			j*c_size
		)
		
		--revert seed
		srand(noise_seed)
		
		create_chunk(i,j)
	end end
end

function get_chunk_type(x,y)
	local cs=os2d_eval(x,y)
	cs=(cs - -8.7)/(8.7 - -8.7)
	printh(cs)
	srand(cs)
	// todo: compute chunk type
	return {}
end

function create_chunk(cx,cy)
	local min_n=1000
	local max_n=-1000
	local t={}
	
	for j=0,c_size-1 do
	t[j]={}
	for i=0,c_size-1 do
		local x=cx*c_size+i
		local y=cy*c_size+j
		local n=get_noise(x,y)
		min_n=min(min_n,n)
		max_n=max(max_n,n)
		t[j][i]=n
	end end
	
	for j=0,c_size-1 do
	for i=0,c_size-1 do
		local x=cx*c_size+i
		local y=cy*c_size+j
		local c=t[j][i]
		local norm=(c-min_n)/(max_n-min_n)
		local f=fade[j][i]
		lvl[y][x]=decode_noise(norm*f)
	end end
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
