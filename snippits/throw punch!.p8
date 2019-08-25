pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--throw punch!!
-- by davbo

--general flow control

--debugging
test=""

gamestate="opening"

function _init()
 music(0)
 hardreset()
 
 effects={}
end

function _update60()
 test=""

 if gamestate=="opening" then
  updateopening()
 elseif gamestate=="menu" then
  updatemenu()
 elseif gamestate=="roundover" then
  updateroundover()
 elseif gamestate=="gameover" then
  updategameover()
 elseif gamestate=="playing" then
  updateplaying()
 end
 
 updateparticles()
end

function _draw()
 cls(0)
 
 if gamestate=="opening" then
  drawopening()
 elseif gamestate=="menu" then
  drawmenu()
 elseif gamestate=="roundover" then
  drawroundover()
 elseif gamestate=="gameover" then
  drawgameover()
 elseif gamestate=="playing" then
  drawplaying()
 end
 
 print(test,0,0,8)
end

-->8
-- stages

function makestage(name,x,y,r,col,init,update,draw,p1xstart,p2xstart)
 s={}
 s.name=name
 s.x=x
 s.y=y
 s.r=r
 s.col=col
 s.init=init
 s.update=update
 s.draw=draw
 s.p1xstart=p1xstart
 s.p2xstart=p2xstart
 
 add(stages,s)
end

--basic stage
function initstage()
 hardreset()
end

function initsmallstage()
 hardreset()
 
 p1.x=sstage.p1xstart
 p1.fist.x=p1.x+arml
 p2.x=sstage.p2xstart
 p2.fist.x=p2.x-arml
end

function updatestage()
end

function drawstage()
 circfill(sstage.x,sstage.y,sstage.r,sstage.col)
end

function drawstripesstage()
 circfill(sstage.x,sstage.y,sstage.r,12)
 clip(64,0,64,128)
 
 circfill(sstage.x,sstage.y,sstage.r,11)
 clip()
end
-->8
-- utilities

--circle collision
function detectcollision(s1,s2)
 --prob only need 1d but w/e
 --get distance from cen to cen
 local dx=s1.x+s1.xvel-s2.x+s1.xvel
 local dy=s1.y-s2.y
 
 local distance=(dx*dx)+(dy*dy)
 
 --if radiuses less than c2c, collision
 if distance <= ((s1.r+s2.r)*(s1.r+s2.r)) then
  return true
 else
  return false
 end
end

function outline(s,x,y,c1,c2)
 for i=0,2 do
  for j=0,2 do
   print(s,x+i,y+j,c1)
  end
 end
 print(s,x+1,y+1,c2)
end

-->8
--gamestate

--arm length
arml=8

function makeactor(x,y,r,col)
 a={}
 a.x=x
 a.y=y
 a.r=r
 a.col=col
 a.xvel=0
 add(actors,a)
 return a
end

function hardreset()
 --empty for reset
 actors={}

 p1=makeactor(15,64,3,12)
 p1.fistconnected=true
 p1.fistcol=1

 f1=makeactor(p1.x+arml,64,4,p1.fistcol)
 p1.fist=f1
 p1.lives=5
 
 --all the buttons for p1 to punch
 p1.btns={
 {0,0},
 {1,0},
 {2,0},
 {3,0},
 {4,1},
 {5,1}}
 
 p2=makeactor(112,64,3,11)
 p2.fistconnected=true
 p2.fistcol=3
 
 f2=makeactor(p2.x-arml,64,4,p2.fistcol)
 p2.fist=f2
 p2.lives=5
 p2.btns={
 {0,1},
 {1,1},
 {2,1},
 {3,1},
 {4,0},
 {5,0}}
end

function softreset()
 deleteeffects("death")
 
 p1.x=sstage.p1xstart
 p1.xvel=0
 p1.y=64
 
 p1.fist.x=p1.x+arml
 p1.fist.y=p1.y
 p1.fist.xvel=0
 p1.fist.col=p1.fistcol
 p1.fistconnected=true
 
 p2.x=sstage.p2xstart
 p2.xvel=0
 p2.y=64
 
 p2.fist.x=p2.x-arml
 p2.fist.y=p2.y
 p2.fist.xvel=0
 p2.fist.col=p2.fistcol
 p2.fistconnected=true
end

function updateplaying()
 updateplayer(p1, 1)
 updateplayer(p2, -1)
 
 if detectcollision(p1.fist, p2.fist) then
  --swap velocities   
  local temp = p1.fist.xvel
  p1.fist.xvel=p2.fist.xvel
  p2.fist.xvel=temp
  sfx(0)
 end
end

function updateplayer(p, sign)
 if p.fistconnected then
  --move fist
  p.fist.xvel+=(0.005*sign)
  p.fist.x+=p.fist.xvel
 
  --move plr to fist
  p.x=p.fist.x-(arml*sign)
 else
  --move plr
  p.xvel+=(0.005*sign)
  p.x+=p.xvel
 
  --move fist
  p.fist.xvel-=0.025*sign
  p.fist.x+=p.fist.xvel
 end
 
 --reattach fist
 if not p.fistconnected and
    detectcollision(p, p.fist) then
  -- bump!
  p.fist.xvel=p.fist.xvel*0.5
  
  --reset
  p.fistconnected=true
  p.xvel=0
  p.fist.col=p.fistcol
  sfx(1)
 end
 
 --throw fist
 if punchpressed(p) and
    p.fistconnected then
  p.fistconnected=false
  
  --instead of this...
  p.xvel=p.fist.xvel
  
  --...have some kind of
  -- bounce back?
  --p.velx=(p.fist.velx*0.3*-1)
  
  p.fist.xvel=(p.fist.xvel)+(0.5*sign)
  p.fist.col=8
  sfx(2)
 end
 
 --stage out!
 if not detectcollision(p, stages[ssid]) then
  p.lives-=1
  initdeath(p)
  
  -- want the transition colour
  --to be the surviving player's
  local transitioncol=0
  
  if p==p1 then
   transitioncol=p2.col
  else
   transitioncol=p1.col
  end
  
  if p.lives>0 then
   gamestate="roundover"
   initroundover()
  else -- game over
   gamestate="gameover"
   initgameover()
  end
  inittransition(p,transitioncol)
  p.x=-10
  p.fist.x=-20
 end
end

--check the many punch buttons
function punchpressed(p)
 for butn in all(p.btns) do
  if btnp(butn[1],butn[2]) then
   return true
  end
 end
 
 return false
end

function drawplaying()
 sstage.draw()
 drawactors()
 drawlives()
end

function drawactors()
 for a in all(actors) do
  circfill(a.x,a.y,a.r,a.col)
 end
end

function drawlives()
 outline(p1.lives,3,1,p1.col,1)
 outline(p2.lives,120,1,p2.col,3)
end
-->8
--menu

function initmenu()
 -- [re]create all the stages
 
 --selected stage identification
 ssid=1
 --selected stage
 sstage=nil
 stages={}

 makestage("simple",63.5,63.5,60,7,
  initstage,updatestage,drawstage,
  15,112)

 makestage("camo",63.5,63.5,60,8,
  initstage,updatestage,drawstripesstage,
  15,112)

 makestage("small",63.5,63.5,30,5,
  initsmallstage,updatestage,drawstage,
  64-23,64+20)
  
 sstage=stages[ssid]
end

function updatemenu()
 if btnp(0) then
  ssid-=1
  if ssid==0 then
   --todo:options menu
   ssid=#stages
  end
  sstage=stages[ssid]
  sstage.init(sstage)
 elseif btnp(1) then
  ssid+=1
  if ssid>#stages then
   ssid=1
  end
  sstage=stages[ssid]
  sstage.init()
 end
 
 if btnp(🅾️) or btnp(❎) then
  initroundover()
  gamestate="roundover"
 end
end

function drawmenu()
 sstage.draw()
 drawactors()
 outline("⬅️ "..sstage.name.." ➡️",(52-#stages[ssid].name*2),5,10,8)

 outline("blue press d-pad to punch!",5,52,12,1)
 outline("green press x to punch!",30,70,11,3)
end

-->8
--round/game over

function initroundover()
 transitiontimer=240
 music(-1)
 sfx(5)
end

function updateroundover()
 transitiontimer-=1

 if transitiontimer==180 then
  softreset()
  sfx(5)
 end
 
 if transitiontimer==120 then
  sfx(6)
 end
 
 if transitiontimer<=60 then
  effects={}
  gamestate="playing"
 end
end

function drawroundover()
 sstage.draw()
 drawactors()
 drawlives()
 
 drawparticles()
 
 if transitiontimer>180 then
  local s="ready?"
  outline(s,hw(s),64,8,10)
 elseif transitiontimer>120 then
  local s="let's"
  outline(s,hw(s),64,8,10)
 else
  sspr(9*8,0,4*8,2*8,0,40,128,128-80)
 end
end

function initgameover()
 transitiontimer=240
 sfx(7)
end

function updategameover()
 transitiontimer-=1

 if transitiontimer==180 then
  deleteeffects("death")
  softreset()
 end
 
 if transitiontimer<=0 then
  effects={}
  hardreset()
  gamestate="menu"
  initmenu()
  music(0)
 end
end

function drawgameover()
 sstage.draw()
 drawactors()
 
 drawparticles()
 
 local s="winner!"
 outline(s,hw(s),64,8,10)
end

function hw(s)
 return 64-#s*2
end

-->8
--opening

function initopening()

end

function updateopening()
 if btnp() != 0 then
  initmenu()
  gamestate="menu"
 end
end

function drawopening()
 --volcano
 --sspr(1*8,0,8*8,8*8,0,0,128,128)
 
 map(0,0,0,0,16,16)
 --logo
 sspr(9*8,0,4*8,2*8,0,80,128,128-80)
end
-->8
--particles

function createeffect(update,id)
 e={
  id=id,
  update=update,
  particles={}
 }
 add(effects,e)
 return e
end

function updateparticles()
 for e in all(effects) do
  e.update(e)
 end
end

function drawparticles()
 for e in all(effects) do
  for p in all(e.particles) do
   circfill(p.x,p.y,p.r,p.col)
  end
 end
end

function deleteeffects(id)
 for e in all(effects) do
  if e.id==id then
   del(effects,e)
  end
 end
end

function createparticle(x,y,xvel,yvel,r,col)
 p={
  x=x,
  y=y,
  xvel=xvel,
  yvel=yvel,
  r=r,
  col=col
 }
 return p
end

function initdeath(a)
 local e=createeffect(updatestraight,"death")
 
 local cols={a.col,a.fistcol,6}
 
 for i=0,8 do
  local p=createparticle(
   a.x,a.y,
   (a.fist.xvel*rnd(3))*-1,
   rnd(1)-0.5,
   1+rnd(2),cols[ceil(rnd(#cols))])
  add(e.particles,p)
 end
end

function updatestraight(e)
 local onscreen=false

 for p in all(e.particles) do
  p.x+=p.xvel
  p.y+=p.yvel
  
  if p.x-p.r>-10 and p.x+p.r<140 and
     p.y-p.r>-10 and p.y+p.r<140 then
   onscreen=true
  end
 end
 
 if not onscreen then
  --del(effects,e)
 end
end

function inittransition(a,transitioncol)
 local e=createeffect(updatestraight,"transition")
 
 local p=createparticle(
  64,200,
  0,-2,
  90,transitioncol)
 add(e.particles,p)
end

__gfx__
00000000ccc77ccccccccccc454ccccc444445cccccccccc444ccccc444444444444444400555555555555555555555555555500000000000000000000000000
00000000cc7777cccccccccc4444cccc454444cccccccccc445ccccc444444444454444403339999999999991199999999999950000000000000000000000000
00700700c777777ccccccccc4444cccc4444444ccccccccc444ccccc444444444444444459391913399113931913931199331915000000000000000000000000
000770007777777ccccccccc4444cccc4444454ccccccccc444ccccc444444444444445459391913931913931913931913991915000000000000000000000000
0007700077777ff7cccccccc44454ccc445444444ccccccc454ccccc444444444444444459391913931913931913931913991915000000000000000000000000
00700700777fff77cccccccc44444ccc444444544ccccccc444ccccc444444444444544459391913391913931913931913991915000000000000000000000000
00000000c77777fccccccccc44444ccc4445444445cccccc444ccccc444444444544444459391913931913931193931913991915000000000000000000000000
00000000cc77ffcccccccccc444445cc4444444544cccccc445ccccc444444444444444459391113931913931993931913991115000000000000000000000000
00000000cccccccc00000000ccccc444cccccccccc44d444ccccc444444444544444444459391913931913931993931913991915000000000000000000000000
00000000ccc77ccc00000000ccccc444cccccccccc444444cccc44d4444444444444544459391913931913931993931913991915000000000000000000000000
00000000c77777cc00000000ccccc4d4ccccccccc4444444cccc4444454445444444444459391913931913931993931913991915000000000000000000000000
000000007777777c00000000ccccc444ccccccccc44d4444cccc4444444444444444444459391913931913331993931913991915000000000000000000000000
00000000777777fc00000000ccccc444ccccccc444444444ccc44d44444454444444444459391913931913331993931913991915000000000000000000000000
00000000c77fff7c00000000ccccc444ccccccc4444444d4ccc44444444444444444445459391913931193931999331919331915000000000000000000000000
00000000cc7777cc00000000ccccc44dcccccc4d4d444444ccc4444d445444544444444405399999999999991999999999999950000000000000000000000000
00000000ccc7ffcc00000000ccccc444cccccc4444444444cc444444544444444444444400555555555555555555555555555500000000000000000000000000
000000000000000000000000ccccccc44444444444cccccccccccccc444444444444444400000000000000000000000000000000000000000000000000000000
000000000000000000000000cccc4444666666666644444ccccccccc444d4444444d444400000000000000000000000000000000000000000000000000000000
000000000000000000000000cccc46666666666666666664444444cc444444444444444400000000000000000000000000000000000000000000000000000000
000000000000000000000000ccc4666666666666666666666666444c444444444444444400000000000000000000000000000000000000000000000000000000
000000000000000000000000cc46666666666666666666666666644444444d444444444400000000000000000000000000000000000000000000000000000000
000000000000000000000000c4666666666666666666633666666644444444444444444400000000000000000000000000000000000000000000000000000000
000000000000000000000000466666666666666666666336666666644d44444444d4444400000000000000000000000000000000000000000000000000000000
00000000000000000000000046666666666666666886666666666664444444444444444400000000000000000000000000000000000000000000000000000000
00000000000000000000000046666666666666668888666666666664000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044666666666116666886666666666664000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044666666661111666666666666666644000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000444466666cc116666666666666666644000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000444446666cc666666666666666666644000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044444466666666666666666666666444000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044444446666666666666666666444444000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044444444666666666666666444444444000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77fff7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc77cccccccccccccccccccccccccccccc77cccccccccccccccccccccccccccccccccccccccccccccc77ccccccccccccccccccccccccccccccccccc
cccccccccc7777cccccccccccccccccccccccccccc7777cccccccccccccccccccccccccccccccccccccccccccc7777ccccccccccccccccccccc77ccccccccccc
ccccccccc777777cccccccccccccccccccccccccc777777cccccccccccccccccccccccccccccccccccccccccc777777cccccccccccccccccc77777cccccccccc
cccccccc7777777ccccccccccccccccccccccccc7777777ccccccccccccccccccccccccccccccccccccccccc7777777ccccccccccccccccc7777777ccccccccc
cccccccc77777ff7cccccccccccccccccccccccc77777ff7cccccccccccccccccccccccccccccccccccccccc77777ff7cccccccccccccccc777777fccccccccc
cccccccc777fff77cccccccccccccccccccccccc777fff77cccccccccccccccccccccccccccccccccccccccc777fff77ccccccccccccccccc77fff7ccccccccc
ccccccccc77777fcccccccccccccccccccccccccc77777fcccccccccccccccccccccccccccccccccccccccccc77777fccccccccccccccccccc7777cccccccccc
cccccccccc77ffcccccccccccccccccccccccccccc77ffcccccccccccccccccccccccccccccccccccccccccccc77ffccccccccccccccccccccc7ffcccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccc77ccccccccccccccccccccccc4444666666666644444ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccc77777cccccccccccccccccccccc46666666666666666664444444cccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc7777777cccccccccccccccccccc4666666666666666666666666444ccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc777777fccccccccccccccccccc4666666666666666666666666664444ccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccc77fff7cccccccccccccccccc46666666666666666666336666666444ccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc7777cccccccccccccccccc4666666666666666666663366666666445cccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccc7ffcccccccccccccccccc4666666666666666688666666666666444cccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc46666666666666668888666666666664444ccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc44666666666116666886666666666664445cccccccccccccccc77ccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc44666666661111666666666666666644444cccccccccccccc77777cccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc444466666cc116666666666666666644444ccccccccccccc7777777ccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444446666cc666666666666666666644454ccccccccccccc777777fccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444466666666666666666666666444444cccccccccccccc77fff7ccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc4d44444446666666666666666666444444444ccccccccccccccc7777cccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444444666666666666666444444444445cccccccccccccccc7ffcccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444454454ccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc77ccccccccccccccccccccccccccccccc44d4444d44444444444444444444444444444444cccccccccccccccccccccccccccccccccccc
ccccccccccccccccc77777cccccccccccccccccccccccccccccc4444444444444444444444444444454445444444cccccccccccccccccccccccccccccccccccc
cccccccccccccccc7777777ccccccccccccccccccccccccccccc4444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccc
cccccccccccccccc777777fcccccccccccccccccccccccccccc44d4444444d4444444444444444444444544444454ccccccccccccccccccccccccccccccccccc
ccccccccccccccccc77fff7cccccccccccccccccccccccccccc444444444444444444444444444444444444444444ccccccccccccccccccccccccccccccccccc
cccccccccccccccccc7777ccccccccccccccccccccccccccccc4444d4d44444444444444444444444454445444444ccccccccccccccccccccccccccccccccccc
ccccccccccccccccccc7ffcccccccccccccccccccccccccccc44444444444444444444444444444454444444444445cccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc44d44444444444444444444444444444444444444445ccccccccccccc77ccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc444444444d4444444444444444444444544444454444cccccccccccc7777cccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444444444cccccccccc777777ccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccc44d4444444444444444444444444444444444544444454ccccccccc7777777ccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444444444444445444444ccccccc77777ff7cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc4444444d444444444444444444444444444445444444444544ccccccc777fff77cccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc4d4d44444444d444444444444444444444454444444445444445ccccccc77777fccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444444444444544cccccccc77ffcccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444444454ccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc444444d4444444d4444444444444444444444445444445444444444cccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc4d44444444444444444444444444444444444444444444444444444cccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444444444444544444cccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc44444444d44444444444444444444444444444444444444444444454ccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444444444444544444544444444ccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc44d4d44444444d444444444444444444444444444444544444444444ccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444444444445cccccccccccccccccccccccccc
ccccccccccc77cccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444444444445cccccccccccccccccccccccccc
cccccccccc7777ccccccccccccccccccccccccccccccc444444d44444444444444444444444444444444444444445444454444cccccccccccccccccccccccccc
ccccccccc777777cccccccccccccccccccccccccccccc4d44444444444444444444444444444444444444444444444444444444ccccccccccccccccccccccccc
cccccccc7777777cccccccccccccccccccccccccccccc4444444444444444444444444444444444444444444444444444444454ccccccccccccccccccccccccc
cccccccc77777ff7ccccccccccccccccccccccccccccc44444444d444444444444444444444444444444444444444444445444444ccccccccccccccccccccccc
cccccccc777fff77ccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444454444444544ccccccccccccccccccccccc
ccccccccc77777fcccccccccccccccccccccccccccccc44d4d44444444444444444444444444444444444444444444444445444445cccccccccccccccccccccc
cccccccccc77ffccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444444444444444444444544cccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444454444ccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc44d4444d4444444444444444444444444444444444444444444444444444445ccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444444445444544444ccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444444444444444444ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc44d4444444d44444444444444444444444444444444444444444444445444454ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444444444444444444444444444ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc4444d4d444444444444444444444444444444444444444444444444544454444ccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444454444444445ccccccccccccccccccccc
cccccccc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555cccccccc
cccccccc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555cccccccc
cccccccc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555cccccccc
cccc333333333333999999999999999999999999999999999999999999999999111111119999999999999999999999999999999999999999999999995555cccc
cccc333333333333999999999999999999999999999999999999999999999999111111119999999999999999999999999999999999999999999999995555cccc
cccc333333333333999999999999999999999999999999999999999999999999111111119999999999999999999999999999999999999999999999995555cccc
55559999333399991111999911113333333399999999111111113333999933331111999911113333999933331111111199999999333333331111999911115555
55559999333399991111999911113333333399999999111111113333999933331111999911113333999933331111111199999999333333331111999911115555
55559999333399991111999911113333333399999999111111113333999933331111999911113333999933331111111199999999333333331111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333333399991111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333333399991111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333333399991111999911113333999933331111999911113333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111111199993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111111199993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111111199993333999933331111999911113333999999991111999911115555
55559999333399991111111111113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111111111115555
55559999333399991111111111113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111111111115555
55559999333399991111111111113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111111111115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333999933331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333333333331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333333333331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333333333331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333333333331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333333333331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111999911113333333333331111999999993333999933331111999911113333999999991111999911115555
55559999333399991111999911113333999933331111111199993333999933331111999999999999333333331111999911119999333333331111999911115555
55559999333399991111999911113333999933331111111199993333999933331111999999999999333333331111999911119999333333331111999911115555
55559999333399991111999911113333999933331111111199993333999933331111999999999999333333331111999911119999333333331111999911115555
cccc555533339999999999999999999999999999999999999999999999999999111199999999999999999999999999999999999999999999999999995555cccc
cccc555533339999999999999999999999999999999999999999999999999999111199999999999999999999999999999999999999999999999999995555cccc
cccc555533339999999999999999999999999999999999999999999999999999111199999999999999999999999999999999999999999999999999995555cccc
cccccccc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555cccccccc
cccccccc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555cccccccc
cccccccc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555cccccccc

__map__
0202020202020211020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201020202010202020202010202110200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020211020223242526050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202021433343536060211020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202110202021627070717030202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202141528070708040501020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202132728070718080302020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201020202132707070707180405020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202162707070707071706020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202010214152807070707070806020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020213270707070707071806020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020213280707070707071806020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020213070707070707071806020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020213070707070707070703020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020216070707070707071804050200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002105022050220502105021050200501c05018050140500f0500b050060500205000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f0501e0501d0501a0501805014050110500c050020500105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000b0500b0300b0300b0200b0200b0100002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000100530000010053000001c053000001005300000100530000010053000001c053000000000000000100530000010053000001c053000001005300000100530000010053000001c053000000000000000
01100000130521a0520000013052000000000000000000001a0521b0521c0521d05200000000001f05200000130521a0520000013052000000000000000000001305200000110521005200000000000e05200000
000200001d0501d0501b0501905017050120500f05001050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000028050240502405023050200501a050110501f000170000f00001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00001a050000001a050000001a050000001f0501f0501f050000001f050000001e050000001f0500000024050240502405024050240500000023050240500000000000000000000000000000000000000000
__music__
01 03424344
00 03044344
02 03044344
00 03044344
00 41424344
00 41424344
00 06424344

