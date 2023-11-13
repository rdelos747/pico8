pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- track gen test

--[[
pts={
	{-100,-100},
	{100,-100},
	{100,100},
	{-100,100}
}
]]--


pts={
	{-100,100},
	{-100,0},// start
	{-100,-100},//start chicane
	{0,-100},
	{0,-200},
	{40,-240},
	{150,-240},
	{400,-210},
	{400,200},
	{370,300},
	{300,300},
	{270,270},
	{270,200},
	{230,170},
	{200,170}
	//{270,330},
	//{230,360}
	//{270,370},
	//{250,390},
	//{230,400}
	//{
}

crnrs={}
apexs={}
tris={}
size=0

function _init()
	printh("===== start =====")
	
	maxpt=0
	-- calculate corners and apexes
	for i=1,#pts do
	
		local prv=pts[i==1 and #pts or i-1]
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
			
		local px,py=prv[1],prv[2]
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		
		printh("processing "..cx.." "..cy)
		printh(" prv "..px.." "..py)
		printh(" nxt "..nx.." "..ny)
		
		local a=atan2(nx-px,ny-py)
		local amtx=abs(30/cos(a+0.25))
		local amty=abs(30/sin(a+0.25))
		local crx=cx+cos(a+0.25)*amtx
		local cry=cy+sin(a+0.25)*amty
		maxpt=max(abs(crx),maxpt)
		maxpt=max(abs(cry),maxpt)
		
		add(crnrs,{crx,cry})
		
		amtx=abs(30/cos(a+0.75))
		amty=abs(30/sin(a+0.75))
		
		add(apexs,{
			cx+cos(a+0.75)*amtx,
			cy+sin(a+0.75)*amty
		})
		
		printh(cos(a+0.75)*30)
	end
	
	-- calculate triangles
	for i=1,#crnrs do
		local cur_c=crnrs[i]
		local cur_p=apexs[i]
		local nxt_c=crnrs[i%#crnrs+1]
		local nxt_p=apexs[i%#apexs+1]
		
		add(tris,{
			{cur_c[1],cur_c[2]},
			{nxt_c[1],nxt_c[2]},
			{cur_p[1],cur_p[2]},
		})
		add(tris,{
			{nxt_c[1],nxt_c[2]},
			{nxt_p[1],nxt_p[2]},
			{cur_p[1],cur_p[2]},
		})
	end
	
	size=(maxpt+10)*2
end


function _draw()
	cls()
	camera(-64,-64)
	
	for i=1,#pts do
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
		
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		line(
			(cx/size)*128,
			(cy/size)*128,
			(nx/size)*128,
			(ny/size)*128,
			7)
		
		pset(
			(crnrs[i][1]/size)*128,
			(crnrs[i][2]/size)*128,
			11)
		
		pset(
			(apexs[i][1]/size)*128,
			(apexs[i][2]/size)*128,
			9)
		
		pset((cx/size)*128,
			(cy/size)*128,10)
	end
	
	if show_t then
		for t in all(tris) do
			for i=1,#t do
				local cur=t[i]
				local nxt=t[i%#t+1]
			
				local cx,cy=cur[1],cur[2]
				local nx,ny=nxt[1],nxt[2]
				line(
					(cx/size)*128,
					(cy/size)*128,
					(nx/size)*128,
					(ny/size)*128,
					1)
			end
		end
		
		for i=1,#crnrs do
			local cur=crnrs[i]
			local nxt=crnrs[i%#pts+1]
		
			local cx,cy=cur[1],cur[2]
			local nx,ny=nxt[1],nxt[2]
			line(
				(cx/size)*128,
				(cy/size)*128,
				(nx/size)*128,
				(ny/size)*128,
				12)
		end
		
		for i=1,#apexs do
			local cur=apexs[i]
			local nxt=apexs[i%#pts+1]
		
			local cx,cy=cur[1],cur[2]
			local nx,ny=nxt[1],nxt[2]
			line(
				(cx/size)*128,
				(cy/size)*128,
				(nx/size)*128,
				(ny/size)*128,
				13)
		end
	end
	
	if show_c then
		local last_y=nil
		for p in all(pts)do
			local cx=(p[1]/size)*128
			local cy=(p[2]/size)*128
			print(p[1]..","..p[2],
				cx-15,
				last_y==cy and cy-8 or cy,
				12)
			last_y=cy
		end
	end
end

show_c=true
show_t=true
function _update()
	if btnp(❎) then
		show_c=not show_c
	end
	if btnp(🅾️) then
		show_t=not show_t
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
