-- pico-8 joust-like prototype

function _init()
  gravity = 0.2
  flap_impulse = -2.6
  max_vx = 1.6
  max_vy = 3

  platforms = {
    {x=12, y=96, w=40},
    {x=76, y=84, w=40},
    {x=36, y=64, w=56},
    {x=0, y=120, w=128}
  }

  player = make_rider(24, 80, 9)
  enemy = make_rider(96, 72, 8)
  player.score = 0
  enemy.score = 0
end

function make_rider(x, y, c)
  return {
    x=x, y=y, vx=0, vy=0,
    w=8, h=8, col=c,
    facing=1,
    on_ground=false,
    dead=false, respawn=0,
    flap_cd=0,
    flap_anim=0
  }
end

function _update60()
  update_player(player)
  update_enemy(enemy, player)
  resolve_collision(player, enemy)
end

function update_player(p)
  if p.dead then
    tick_respawn(p)
    return
  end

  if btn(0) then p.facing = -1 end
  if btn(1) then p.facing = 1 end

  if not p.on_ground then
    if btn(0) then p.vx = max(p.vx-0.1, -max_vx) end
    if btn(1) then p.vx = min(p.vx+0.1, max_vx) end
  end

  if btnp(5) and p.flap_cd <= 0 then
    p.vy = flap_impulse
    p.flap_cd = 6
    p.flap_anim = 6
  end

  p.flap_cd = max(0, p.flap_cd-1)
  p.flap_anim = max(0, p.flap_anim-1)
  step_physics(p)
end

function update_enemy(e, target)
  if e.dead then
    tick_respawn(e)
    return
  end

  if target.x < e.x then
    e.facing = -1
  else
    e.facing = 1
  end

  if not e.on_ground then
    if e.facing < 0 then
      e.vx = max(e.vx-0.08, -max_vx)
    else
      e.vx = min(e.vx+0.08, max_vx)
    end
  end

  if e.flap_cd > 0 then
    e.flap_cd -= 1
  end

  if e.flap_cd <= 0 then
    if target.y < e.y-6 or (rnd() < 0.02 and not e.on_ground) then
      e.vy = flap_impulse
      e.flap_cd = 12
      e.flap_anim = 6
    elseif e.on_ground and rnd() < 0.2 then
      e.vy = flap_impulse
      e.flap_cd = 12
      e.flap_anim = 6
    end
  end

  e.flap_anim = max(0, e.flap_anim-1)
  step_physics(e)
end

function step_physics(r)
  r.vy = min(r.vy + gravity, max_vy)
  local old_x = r.x
  local old_y = r.y
  r.x += r.vx
  r.y += r.vy
  r.on_ground = false

  if r.x < -r.w then r.x = 128 + r.w end
  if r.x > 128 + r.w then r.x = -r.w end

  for p in all(platforms) do
    local hit_x = (r.x + r.w > p.x and r.x < p.x + p.w)
      or (r.x + r.w + 128 > p.x and r.x + 128 < p.x + p.w)
      or (r.x + r.w - 128 > p.x and r.x - 128 < p.x + p.w)
    if r.vy >= 0 and hit_x then
      local prev_feet = old_y + r.h
      local feet = r.y + r.h
      if prev_feet <= p.y and feet >= p.y then
        r.y = p.y - r.h
        r.vy = 0
        r.on_ground = true
      end
    end
  end

  r.vx *= 0.98
  if r.on_ground and r.flap_anim <= 0 then
    r.vx *= 0.3
    if abs(r.vx) < 0.05 then r.vx = 0 end
  end
end

function resolve_collision(a, b)
  if a.dead or b.dead then return end

  if abs(a.x - b.x) < 6 and abs(a.y - b.y) < 6 then
    if a.y < b.y - 2 then
      kill_rider(b, a)
    elseif b.y < a.y - 2 then
      kill_rider(a, b)
    else
      a.vx *= -1
      b.vx *= -1
      a.vy = min(a.vy + 0.5, max_vy)
      b.vy = min(b.vy + 0.5, max_vy)
    end
  end
end

function kill_rider(victim, winner)
  victim.dead = true
  victim.respawn = 90
  victim.vx = 0
  victim.vy = 0
  winner.score += 1
end

function tick_respawn(r)
  r.respawn -= 1
  if r.respawn <= 0 then
    r.dead = false
    r.x = rnd(120) + 4
    r.y = 24
    r.vx = 0
    r.vy = 0
  end
end

function _draw()
  cls(1)
  draw_platforms()
  draw_rider(player)
  draw_rider(enemy)
  draw_ui()
end

function draw_platforms()
  for p in all(platforms) do
    rectfill(p.x, p.y, p.x + p.w - 1, p.y + 3, 3)
  end
end

function draw_rider(r)
  if r.dead then return end
  rectfill(r.x, r.y, r.x + r.w - 1, r.y + r.h - 1, r.col)
  rectfill(r.x+2, r.y-2, r.x+r.w-3, r.y, 7)

  local wing_y = r.y + 3
  if r.flap_anim > 0 then
    local wing = sin(t() * 4) * 3
    wing_y = r.y + 3 + wing
  end
  line(r.x-2, r.y+3, r.x+1, wing_y, 7)
  line(r.x+r.w+1, r.y+3, r.x+r.w-2, wing_y, 7)
end

function draw_ui()
  print("p1 "..player.score, 4, 4, 7)
  print("cpu "..enemy.score, 84, 4, 7)
  print("x flap", 4, 120, 6)
end
