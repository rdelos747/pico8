pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- hike

secs=20

ppx,ppz,pp_ya=0,0,0

lvl={{}}
td_mode=true

function _init()
	loga({"==== start hike ===="})
end

function _draw()
	cls()
	camera(0,0)
	print(pp_ya,0,0,7)
	pria({
		flr(ppx),flr(ppz),sex,sez
		},0,6,7)
	
	if td_mode then
		draw_td()
	else
		draw_pov()
	end
end

l_sex,l_sez=-1,-1
function _update()
	if(btnp(🅾️))td_mode=not td_mode
	if(btn(⬅️))pp_ya-=0.01
	if(btn(➡️))pp_ya+=0.01
	pp_ya=pp_ya%1
	
	if btn(⬆️) then
		ppx+=cos(pp_ya)
		ppz+=sin(pp_ya)
	elseif btn(⬇️) then
		ppx-=cos(pp_ya)
		ppz-=sin(pp_ya)
	end
	
	sex=flr(ppx/secs)
	sez=flr(ppz/secs)
	
	if l_sex!=sex or l_sez!=sez then
		
	end
end
-->8
-- pov

function draw_pov()
	camera(0,0)
end

function draw_td()
	//pset(ppx,ppz,7)
	local z=2
	camera(ppx/z-64,ppz/z-64)
	
	for j=-2,2 do
	for i=-2,2 do
		local sx=(i+sex)*secs
		local sz=(j+sez)*secs
		rect(
			sx/z,sz/z,
			(sx+secs)/z,(sz+secs)/z,
			1)
	end end
	
	search_grid(function(
	i,j,x1,z1,x2,z2)
		line(
			x1/z,z1/z,
			x2/z,z2/z,
			7)
		
		local sx=i*secs
		local sz=j*secs
		rect(
			sx/z,sz/z,
			(sx+secs)/z,(sz+secs)/z,
			2)
	end)
	
	
	
	
	
	--[[
	line(
		ppx/z,ppz/z,
		ppx/z+cos(pp_ya)*10,
		ppz/z+sin(pp_ya)*10,
		7)
		]]--
end
-->8
-- temp
-->8
-- temp
-->8
--temp

function search_grid(cb)
	//loga("==search==")
	local va=0.25 --view angle
	local ns=5				--number of slices
	local sd=secs*0.5 --slice dist
	local fnd={}
	for n=0,0 do
		local a=pp_ya-va/2
		for s=0,ns do
			local aa=a+va/s
			local d=sd*n
			local d2=sd*(n+1)
			local x1=ppx+cos(aa)*d
			local z1=ppz+sin(aa)*d
			local x2=x1+cos(aa)*d2
			local z2=z1+sin(aa)*d2
			
			local i=flr(x2/secs)
			local j=flr(z2/secs)
			local id=i.."+"..j
			//loga({id})
			if fnd[id]==nil then
				fnd[id]=true
				
				cb(i,j,x1,z1,x2,z2)
			end
		end
	end
end

function create()
	
end
-->8
-- temp

--debug functions
--todo remove
function a_to_s(arr)
	local s=tostr(arr[1])
	for i=2,#arr do
		s=s.." "..tostr(arr[i])
	end
	return s
end

function loga(arr)
	printh(a_to_s(arr))
end

function pria(arr,x,y,c)
	print(a_to_s(arr),x,y,c)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
