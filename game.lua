-- pico-8 joust-like prototype

function _init()
  gravity = 0.2
  flap_impulse = -2.6
  max_vx = 1.6
  max_vy = 3

  platforms = {
    { x = 12, y = 96, w = 40 },
    { x = 76, y = 84, w = 40 },
    { x = 36, y = 64, w = 56 },
    { x = 0, y = 120, w = 128 }
  }

  player = make_rider(24, 80, 9)
  enemy = make_rider(96, 72, 8)
  player.score = 0
  enemy.score = 0

  state = {
    explosions = {},
    screen_flashes = {},
    projectiles = {},
    paused = false,
    pause_t = 0,
    ss_t = 0,
    ss_mag = 0
  }
end

function make_rider(x, y, c, mount_name)
  local r = {
    x = x, y = y, vx = 0, vy = 0,
    w = 8, h = 8, col = c,
    facing = 1,
    on_ground = false,
    dead = false, respawn = 0,
    flap_cd = 0,
    flap_anim = 0,
    shoot_cd = 0,
    mount = nil,
    flap_impulse = flap_impulse,
    max_vx = max_vx
  }
  set_mount(r, mount_name or random_mount_name())
  return r
end

function random_mount_name()
  local names = { "joust_bird", "joust_bat", "joust_tank", "joust_ball", "joust_jet", "joust_glider" }
  return names[flr(rnd(#names)) + 1]
end

function set_mount(r, mount_name)
  r.mount = mounts[mount_name]
  apply_mount_hitbox(r)
end

function _update60()
  update_pause()
  update_juice()
  update_ss()
  if not state.paused then
    update_player(player)
    update_enemy(enemy, player)
    resolve_collision(player, enemy)
    update_projectiles()
  end
end

function update_player(p)
  if p.dead then
    tick_respawn(p)
    return
  end

  local dx = 0
  if btn(0) then
    p.facing = -1
    dx = -1
  end
  if btn(1) then
    p.facing = 1
    dx = 1
  end

  mount_call(p, "move", dx, 0)

  if btnp(5) then
    mount_call(p, "flap")
  end
  if btnp(4) then
    mount_call(p, "alt")
  end

  mount_call(p, "tick")
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

  mount_call(e, "move", e.facing, 0)

  if e.flap_cd <= 0 then
    if target.y < e.y - 6 or (rnd() < 0.02 and not e.on_ground) then
      mount_call(e, "flap")
    elseif e.on_ground and rnd() < 0.2 then
      mount_call(e, "flap")
    end
  end

  mount_call(e, "tick")
  step_physics(e)
end

function step_physics(r)
  r.vy = min(r.vy + gravity, max_vy)
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

  if aabb(a.x, a.y, a.w, a.h, b.x, b.y, b.w, b.h) then
    if a.y + a.h * 0.5 < b.y + b.h * 0.5 - 2 then
      kill_rider(b, a)
    elseif b.y + b.h * 0.5 < a.y + a.h * 0.5 - 2 then
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
  mount_call(victim, "ondeath")
  winner.score += 1
  add_explosion(victim.x + victim.w / 2, victim.y + victim.h / 2, 2, 4, 8)
  add_screen_flash(4, 7)
  ss(8, 2)
  hitstop(6)
end

function tick_respawn(r)
  r.respawn -= 1
  if r.respawn <= 0 then
    r.dead = false
    r.x = rnd(120) + 4
    r.y = 24
    r.vx = 0
    r.vy = 0
    r.flap_cd = 0
    r.flap_anim = 0
    r.shoot_cd = 0
    set_mount(r, random_mount_name())
  end
end

function _draw()
  cls(1)
  apply_ss()
  draw_platforms()
  draw_projectiles()
  draw_actor(player)
  draw_actor(enemy)
  draw_juice()
  draw_ui()
end

function draw_platforms()
  for p in all(platforms) do
    rectfill(p.x, p.y, p.x + p.w - 1, p.y + 3, 3)
  end
end

function draw_actor(r)
  local m = r.mount
  if m and m.draw then
    m.draw(r)
  end
end

function update_pause()
  if not state.paused then return end
  state.pause_t = max(0, state.pause_t - 1)
  if state.pause_t <= 0 then
    state.paused = false
  end
end

function update_juice()
  tick_juice_list(state.explosions)
  tick_juice_list(state.screen_flashes)
end

function tick_juice_list(list)
  for i = #list, 1, -1 do
    local e = list[i]
    if e.dec then e.t -= 1 end
    if e.t <= 0 then
      deli(list, i)
    end
  end
end

function draw_juice()
  for e in all(state.explosions) do
    if e.draw then e:draw() end
  end
  for f in all(state.screen_flashes) do
    if f.draw then f:draw() end
  end
end

function add_bullet(x, y, vx, owner)
  local b = { x = x, y = y, vx = vx, w = 2, h = 2, owner = owner }
  add(state.projectiles, b)
  return b
end

function update_projectiles()
  for i = #state.projectiles, 1, -1 do
    local b = state.projectiles[i]
    b.x += b.vx
    if is_offscreen_xy(b.x, b.y, b.w, b.h, 2) then
      deli(state.projectiles, i)
    else
      local target = b.owner == player and enemy or player
      if not target.dead and aabb(b.x, b.y, b.w, b.h, target.x, target.y, target.w, target.h) then
        kill_rider(target, b.owner)
        deli(state.projectiles, i)
      end
    end
  end
end

function draw_projectiles()
  for b in all(state.projectiles) do
    rectfill(b.x, b.y, b.x + b.w - 1, b.y + b.h - 1, 10)
  end
end

function mount_call(r, fn, ...)
  local m = r.mount
  if m and m[fn] then
    return m[fn](r, ...)
  end
end

function draw_ui()
  print("p1 " .. player.score, 4, 4, 7)
  print("cpu " .. enemy.score, 84, 4, 7)
  print("x flap", 4, 120, 6)
end
