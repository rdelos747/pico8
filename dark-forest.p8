pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- dark forest

function _init()
	printh("==== start ====")
	reset()
end

function reset()
	level={}
	trees={}
	leaves={}
	grass={}
	--solids={}
	wind_t=-1
	pov=false
	
	get_level()
	px,py=-1,1
	pdx,pdy=1,0
	while px==-1 do
		local ri=flr(rnd(15))+1
		local rj=flr(rnd(15))+1
		if leaves[rj][ri]==0 then
			px=ri*8
			py=rj*8
		end
	end
end

function _draw()
	cls()
	if pov then
		draw_pov()
	else
		draw_game()
	end
end

function draw_game()
		--draw_thing(draw_floor)
	draw_thing(draw_root)
	for j=0,flr((py-4)/8)do
	for i=0,15 do
		draw_grass(i,j)
	end end
	spr(1,px-4,py-4)
	for j=flr((py-4)/8)+1,15 do
	for i=0,15 do
		draw_grass(i,j)
	end end
	draw_thing(draw_tree)
	draw_thing(draw_leaf)
	draw_thing(draw_top_leaf)
end

function draw_thing(f)
	for j=0,15 do
	for i=0,15 do
		f(i,j,i*8,j*8)
	end end
end

function draw_tree(i,j,x,y)
	if trees[j][i]==1 then
		palt(7,true)
		palt(0,false)
		spr(3,x-8,y)
		spr(4,x,y)	
		spr(5,x+8,y)
		pal()	
	elseif trees[j][i]>1 then
		spr(20,x,y)
	end
end

function draw_floor(i,j,x,y)
	--spr(48,x,y)
end

// old small tree
function draw_root(i,j,x,y)
	if trees[j][i]==3 then
		spr(35,x-8,y+8)
		spr(36,x,y+8)
		spr(37,x+8,y+8)
		pal()
	end
end

function draw_top_leaf(i,j,x,y)
	if leaves[j][i]==-1 then
		local dx=abs(flr(px/8)-i)
		local dy=abs(flr(py/8)-j)
		if dx<3 and dy<3 then
			pal(3,1)
			palt(11,true)
		else
			spr(22,x,y)
		end
		spr(6,x,y-8)
		spr(21,x-8,y)
		spr(23,x+8,y)
		spr(38,x,y+8)
		pal()
	end
end

function draw_leaf(i,j,x,y)
	if leaves[j][i]>0 then
		local dx=abs(px/8-i)
		local dy=abs(py/8-j)
		local s=7
		if dx<2.5 and dy<2.5 then
			//spr(6,x,y)
			s=2
		elseif flr(wind_t)==i then
			s=8
		end
		spr(s,x,y)
	end
end

function draw_grass(i,j)
	if grass[j][i]!=0 then
		local s=9
		if grass[j][i]==1 then
			s=11
		end
		spr(s,i*8,j*8)
	end
end

function _update()
	if	btn(⬆️)and free(px,py-4) then 
		py-=1
		pdx,pdy=0,-1
	elseif	btn(⬇️)and free(px,py+1) then 
		py+=1
		pdx,pdy=0,1
	elseif	btn(⬅️)and free(px-1,py) then 
		px-=1
		pdx,pdy=-1,0
	elseif	btn(➡️)and free(px+1,py) then 
		px+=1
		pdx,pdy=1,0
	end

	if(btnp(❎))reset()
	
	pov=false
	if(btn(🅾️))pov=true
	
	if wind_t>=0 then
		wind_t+=0.25
		//printh(flr(wind_t)%2)
		if(wind_t>=16)wind_t=-1
	else
		wind_t=-1
		if rnd(1000)<5 then
			wind_t=0
		end
	end
end

function free(x,y)
	local i=mid(0,flr(x/8),15)
	local j=mid(0,flr(y/8),15)
	return trees[j][i]!=3
end
-->8
-- cell auto
function get_level()
	--srand(1)
	for j=0,15 do
		leaves[j]={}
		trees[j]={}
		grass[j]={}
	for i=0,15 do
		trees[j][i]=0
		leaves[j][i]=0
		grass[j][i]=0

		if rnd(100)<1 then
			leaves[j][i]=-1
		end
	end end
	
	for c=0,10 do
		local ri=flr(rnd(15))
		local rj=(flr(rnd(5))+14)%16
		leaves[rj][ri]=-1
	end
	
	for c=0,10 do
		local ri=(flr(rnd(5))+14)%16
		local rj=flr(rnd(15))
		leaves[rj][ri]=-1
	end
	
	for j=0,15 do
	for i=0,15 do
		leaves[j][i]=get_sur(leaves,i,j)
		if leaves[j][i]==-1 and
					trees[j][i]==0 then
			local n=1
			for jj=j,min(j+2,15) do
				trees[jj][i]=n
				n+=1
			end
		end
		if trees[j][i]!=3 and rnd(100)<2 then
			grass[j][i]=-1
		end
	end end
		
	for j=0,15 do
	for i=0,15 do
		grass[j][i]=get_sur(grass,i,j)
	end end
	
	for c=0,100 do
		local ri=flr(rnd(16))
		local rj=flr(rnd(16))
		if get_border(leaves,ri,rj)>1 then
			leaves[rj][ri]=1
		end
		
		if get_border(grass,ri,rj)>1 then
			grass[rj][ri]=1
		end
	end
end

function get_sur(a,i,j)
	if(a[j][i]==-1) return -1
	local n=0
	for jj=max(j-1,0),min(j+1,15) do
	for ii=max(i-1,0),min(i+1,15) do
		if(a[jj][ii]==-1)n+=1
	end end
	return n
end

function get_border(a,i,j)
	if(a[j][i]!=0) return -1
	local n=0
	for jj=max(j-1,0),min(j+1,15) do
	for ii=max(i-1,0),min(i+1,15) do
		if(a[jj][ii]!=0)n+=1
	end end
	return n
end
-->8
-- pov
half=flr(15/2)

function draw_pov_at(c,mx,my,hz)
	local w=c-1
	local s=128/((w*2)+1)
	local last=-1
	for i=-(w+1),(w+1) do
		local x=mx-(i*pdy)--flipx
		local y=my-(i*(-pdx))--flipy
		printh(x.." "..y)
		local val=leaves[y][x]
		
		for z=0,val-1 do
			local sp=16
			if(pdx==1)sp=20
			local cur=leaves[half][half]
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
	local c=3
	while c>=0 do
		c-=1
		local my=half+(c*pdy)
		local mx=half+(c*pdx)
		local hz=c-7
		if hz>=0 then
			draw_pov_at(c,mx,my,hz)
			if hz==0 then
				rectfill(0,64,128,128,6)
			end
		else
			draw_pov_at(c,mx,my,0)
		end
	end	
	print('x:'..px..' y:'..py,7)
	print('dx:'..pdx..' dy:'..pdy)
	print('c:'..c)
end
__gfx__
000000000000000000010100777777777707077777777777000000000003330000030b0b000b0b0000000bb00000000000000000000000000000000000000000
0000000000777700010000107777770770504077777777770000000003bbbb30033bbbb0b03b0b3000b3b0b30000000000000000000000000000000000000000
007007000077770010000001777770507050407777077777000000003bbbbbb303bbbbbb0b303b300bbb3b03b00b0b0000000000000000000000000000000000
00077000007c7c0000000000777770507705407770507777000000003bbb3b300bbbb3b03bb3b3b00b0b30300b00bb0000000000000000000000000000000000
00077000007777000000000077777055000540700540777700033000033bbbb303b3bbbb33b3b30b030b330b3b030b0000000000000000000000000000000000
007007000070070000000001777770055404440554077777033bb33033b33b33b3bbb3b033b3333333b033333033303000000000000000000000000000000000
0000000000700700100000107777777054444554407777773bbbbbb3333333300333333033333333333333330303330300000000000000000000000000000000
0000000000000000010010007777777705455447077777773bbbbbb30333300003b3300003333303033333030303030300000000000000000000000000000000
000000000000000000000000000000000554545000000033b3b33b33b300000000000000000b0b00000000000000000000000000000000000000000000000000
00000000000000000000000000000000055454500000003b3bbb333bbb30000000000000b03b0b30000000000000000000000000000000000000000000000000
0000000000000000000000000000000005544450000003b333bb33b3bb300000000000000b303b30000000000000000000000000000000000000000000000000
000000000000000000000000000000000554545000003bbbbbbbb3b3bbb30000000000003bb3b3b0000000000000000000000000000000000000000000000000
000000000000000000000000000000000554545000003bbbb3b33bbb3bb30000000000003db3b30b000000000000000000000000000000000000000000000000
000000000000000000000000000000000554545000003bbb33bbbbb3bb3000000000000023b0b323000000000000000000000000000000000000000000000000
0000000000000000000000000000000005545450000003bbbbbb3b33bb300000000000000d22b232000000000000000000000000000000000000000000000000
00000000000000000000000000000000055454500000003b3bbb3bb33300000000000000022db222000000000000000000000000000000000000000000000000
0000000000000000000000000000004444544454440000003b3bbbb3000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000044445545444445000003bbbbbb3000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000004455055454505555000003bbbb30000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005445000000000000333300000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000030003330000030b0b
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b3303003bbbb30033bbbb0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000005b00000055000000000033bb30003bbbbbb303bbbbbb
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b56350006666600000000003b300003bbb3b300bbbb3b0
000000000000000000000000000000000000000000000000000000000000000000000000000000000b3366b5055666650000000000330330033bbbb303b3bbbb
00000000000000000000000000000000000000000000000000000000000000000000000000000000533553535555555500000000000003bb33b33b33b3bbb3b0
0000000000000000000000000000000000000000000000000000000000000000000000000000000055665355556655550000000003b003b33333333003333330
00000000000000000000000000000000000000000000000000000000000000000000000000000000055555000555550000000000033000000333300003b33000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000037001a003700370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000037263700372637270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001a000037262600372637273737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000040000002626370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000371314151a003726261900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000372600000000042637001a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000263737262637131437263700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000037003737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
