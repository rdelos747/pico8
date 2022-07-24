pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--[[
ideas:
- docking stations: enemies
	can maybe damage these
	
- map: player can only use map
	if they dock with a map station

- upgrades: player collects
	"things" that follow them.
	when docking with an upgrade
	ship, they can spend them on
	upgrades
	
- paralax bk: should be procedurally
	generated, player can use to
	navagate
]]--

cam={x=0,y=0,sx=0,sy=0,s_tm=0}
pp={
	x=0,y=0,dx=0,dy=-1
}
blts={}
strs={}
str_l_x=0
str_l_y=0

function rand(n,m)
	return flr(rnd((m+1)-n))+n
end

function _init()
	printh("=====start=====")
	os2d_noise(0)
	init_level()
end

test={}
function init_level()
	init_strs()
end

function _draw()
	cls()
	
	camera(cam.x+cam.sx,
		cam.y+cam.sy)
		
	update_strs()
	draw_player()
	draw_test()
	
	print("x: "..pp.x,cam.x,cam.y+116,7)
	print("y: "..pp.y,cam.x,cam.y+122,7)

	--[[
	for j=0,127 do
	for i=0,127 do
		pset(i,j,strs[j][i])
	end end
	]]--
end

function draw_player()
	if pp.dx==0 then
		spr(1,pp.x,pp.y,1,1,0,pp.dy==1)
	elseif pp.dy==0 then
		spr(2,pp.x,pp.y,1,1,pp.dx==-1,0)
	else
		spr(
		3,pp.x,pp.y,1,1,pp.dx==-1,pp.dy==1
		)
	end
	
	for b in all(blts) do
		spr(5,b.x,b.y)
	end
end

function draw_test()
	for i in all(test) do
		spr(4,i.x,i.y)
	end
end

c=0
function _update()
	update_player()
	update_blts()
	update_cam()
	
	c+=1
end

function update_cam()
	cam.x=pp.x-64
	cam.y=pp.y-64
end

function update_player()
	local dx=0
	local dy=0
	if(btn(⬆️))dy=-1
	if(btn(⬇️))dy=1
	if(btn(⬅️))dx=-1
	if(btn(➡️))dx=1
	if dx!=0 or dy!=0 then
		pp.dx=dx
		pp.dy=dy
	end
	pp.x+=pp.dx
	pp.y+=pp.dy
	
	if btnp(🅾️) then
		add(blts,{
			x=pp.x+4*pp.dx,
			y=pp.y+4*pp.dy,
			dx=pp.dx,
			dy=pp.dy
		})
	end
end

function update_blts()
	for b in all(blts) do
		b.x+=b.dx*5
		b.y+=b.dy*5
		if b.x<cam.x or b.x>cam.x+128 or
		b.y<cam.y or b.y>cam.y+128 then
			del(blts,b)
		end
	end
end

str_sz=66
function init_strs()
	for j=0,str_sz-1 do
		strs[j]={}
	for i=0,str_sz-1 do
		strs[j][i]=get_noise(10,10)
	end end
end


last_x=pp.x
last_y=pp.y
function update_strs()
	local x=flr(pp.x*0.5)
	local y=flr(pp.y*0.5)
	local dx=x-last_x
	local dy=y-last_y
	local ddx=pp.x*0.5-last_x
	local ddy=pp.y*0.5-last_y

	last_x=x
	last_y=y
	local n_lvl={}
	for j=0,str_sz-1 do
		n_lvl[j]={}
	for i=0,str_sz-1 do
		local jj=(j+dy)%str_sz
		local ii=(i+dx)%str_sz
		n_lvl[j][i]=strs[jj][ii]

		pset(
			(i*2)+ddx+(cam.x-1),
			(j*2)+ddy+(cam.y-1),
			n_lvl[j][i]
		)
	end end
	strs=n_lvl
	
	-- generate right
	if dx==1 then
		for j=0,str_sz-1 do
			strs[j][str_sz-1]=get_noise(
				x+str_sz*2,
				y+(j-str_sz*2)
			)
		end
	-- generate left
	elseif dx==-1 then
		for j=0,str_sz-1 do
			strs[j][0]=get_noise(
				x-str_sz*2,
				y+(j-str_sz*2)
			)
		end		
	-- generate down
	elseif dy==1 then
		for i=0,str_sz-1 do
			strs[str_sz-1][i]=get_noise(
				x+(i-str_sz*2),
				y+str_sz*2
			)
		end
	-- generate up
	elseif dy==-1 then
		for i=0,str_sz-1 do
			strs[0][i]=get_noise(
				x+(i-str_sz*2),
				y-str_sz*2
			)
		end
	end
end

--[[
function get_noise(x,y)
	local c=os2d_eval(x/4,y/4)
	//c+=os2d_eval(x/16,y/16)/2
	c+=os2d_eval(x/8,y/8)/4
	c=flr(c*10)
	if(c==0)return 1
	if(c==9)return 1
	return 0
	//return mid(0,flr(c*10),9)
end
--]]

function get_noise(x,y)
	local c=os2d_eval(x,y)
	c=(c- -0.8093)/(0.8551- -0.8093)
	c=flr(c*100)
	//if(c>95)return 14
	
	local d=os2d_eval(x/64,y/64)
	d+=os2d_eval(x/4,y/4)/2
	
	d=(d- -1.0591)/(1.162- -1.0591)
	d=flr(d*200)
	if d==90 then
		return 1
	end
	
	if d==91 then
		return 13
	end
	return 0
	
	
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
00000000000770008777800000800077900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000666000007706777090000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006776000566660077667770009009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000806776080057777786677760000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000766776670057777705577600000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700766556670566660000056678009009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000765005670666000000056770090000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800000088777800000008700900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
