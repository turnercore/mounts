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
    mount_pickups = {},
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
    naked = false,
    parachute = false,
    mount_pickup = nil,
    invuln = 0,
    aim_up = false,
    aim_down = false,
    aim_ang = 0,
    gravity = gravity,
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
  if mount_name == "joust_tank" then
    r.aim_ang = 90
  end
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
    update_mount_pickups()
  end
end

function update_player(p)
  if p.dead then
    tick_respawn(p)
    return
  end
  if p.naked then
    update_naked_player(p)
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
  p.aim_up = btn(2)
  p.aim_down = btn(3)

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
  if e.naked then
    update_naked_enemy(e, target)
    return
  end

  if target.x < e.x then
    e.facing = -1
  else
    e.facing = 1
  end
  e.aim_up = false
  e.aim_down = false

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
  local g = r.gravity or gravity
  r.vy = min(r.vy + g, max_vy)
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
    if a.naked and b.naked then
      a.vx *= -1
      b.vx *= -1
      a.vy = min(a.vy + 0.3, max_vy)
      b.vy = min(b.vy + 0.3, max_vy)
    elseif a.naked and not b.naked then
      if a.invuln <= 0 then
        kill_rider(a, b)
      end
    elseif b.naked and not a.naked then
      if b.invuln <= 0 then
        kill_rider(b, a)
      end
    elseif not a.naked and not b.naked then
      if a.y + a.h * 0.5 < b.y + b.h * 0.5 - 2 then
        knock_off(b, a)
      elseif b.y + b.h * 0.5 < a.y + a.h * 0.5 - 2 then
        knock_off(a, b)
      else
        a.vx *= -1
        b.vx *= -1
        a.vy = min(a.vy + 0.5, max_vy)
        b.vy = min(b.vy + 0.5, max_vy)
      end
    else
      kill_rider(a, b)
    end
  end
end

function kill_rider(victim, winner)
  victim.dead = true
  victim.respawn = 90
  victim.vx = 0
  victim.vy = 0
  if victim.mount_pickup then
    remove_mount_pickup(victim.mount_pickup)
    victim.mount_pickup = nil
  end
  mount_call(victim, "ondeath")
  winner.score += 1
  add_explosion(victim.x + victim.w / 2, victim.y + victim.h / 2, 2, 4, 8)
  add_screen_flash(4, 7)
  ss(8, 2)
  hitstop(6)
end

function knock_off(victim, winner)
  if victim.naked then return end
  victim.naked = true
  victim.parachute = true
  victim.gravity = 0.08
  victim.vx = 0
  victim.vy = 0
  victim.invuln = 20
  victim.mount_pickup = spawn_mount_pickup(victim.mount)
  victim.mount = nil
  victim.w = 4
  victim.h = 6
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
    r.naked = false
    r.parachute = false
    r.gravity = gravity
    r.mount_pickup = nil
    r.invuln = 0
    set_mount(r, random_mount_name())
  end
end

function _draw()
  cls(1)
  apply_ss()
  draw_platforms()
  draw_mount_pickups()
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
  if r.naked then
    draw_naked(r)
    return
  end
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

function add_bullet(x, y, vx, vy, owner)
  local b = { x = x, y = y, vx = vx, vy = vy, w = 2, h = 2, owner = owner }
  add(state.projectiles, b)
  return b
end

function update_projectiles()
  for i = #state.projectiles, 1, -1 do
    local b = state.projectiles[i]
    b.x += b.vx
    b.y += b.vy or 0
    if is_offscreen_xy(b.x, b.y, b.w, b.h, 2) then
      deli(state.projectiles, i)
    else
      local target = b.owner == player and enemy or player
      if not target.dead and aabb(b.x, b.y, b.w, b.h, target.x, target.y, target.w, target.h) then
        if target.naked then
          if target.invuln <= 0 then
            kill_rider(target, b.owner)
          end
        else
          knock_off(target, b.owner)
        end
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

function update_naked_player(p)
  local dx = 0
  if btn(0) then dx = -1 end
  if btn(1) then dx = 1 end

  if p.parachute then
    p.vx = dx * 0.5
  else
    p.vx = dx * 0.7
    if btnp(5) and p.on_ground then
      p.vy = flap_impulse * 0.8
    end
  end

  step_physics(p)
  p.invuln = max(0, p.invuln - 1)
  if p.parachute and p.on_ground then
    p.parachute = false
    p.gravity = gravity
  end

  try_remount(p)
end

function update_naked_enemy(e, target)
  local dx = 0
  if e.mount_pickup then
    if e.mount_pickup.x < e.x then dx = -1 else dx = 1 end
  else
    if target.x < e.x then dx = -1 else dx = 1 end
  end

  if e.parachute then
    e.vx = dx * 0.5
  else
    e.vx = dx * 0.7
    if e.on_ground and rnd() < 0.05 then
      e.vy = flap_impulse * 0.8
    end
  end

  step_physics(e)
  e.invuln = max(0, e.invuln - 1)
  if e.parachute and e.on_ground then
    e.parachute = false
    e.gravity = gravity
  end

  try_remount(e)
end

function draw_naked(r)
  if r.dead then return end
  rectfill(r.x, r.y, r.x + r.w - 1, r.y + r.h - 1, 6)
  if r.parachute then
    circfill(r.x + r.w / 2, r.y - 4, 4, 7)
    line(r.x, r.y, r.x + r.w / 2, r.y - 2, 7)
    line(r.x + r.w - 1, r.y, r.x + r.w / 2, r.y - 2, 7)
  end
end

function spawn_mount_pickup(mount_ref)
  local name = "joust_bird"
  for k, v in pairs(mounts) do
    if v == mount_ref then
      name = k
      break
    end
  end
  local ground = platforms[#platforms]
  local m = {
    x = ground.x + rnd(ground.w - 6),
    y = ground.y - 6,
    vx = 0, vy = 0,
    w = 6, h = 6,
    mount_name = name,
    on_ground = false
  }
  add(state.mount_pickups, m)
  return m
end

function update_mount_pickups()
  for m in all(state.mount_pickups) do
    m.vy = min(m.vy + gravity, max_vy)
    local old_y = m.y
    m.y += m.vy
    m.on_ground = false

    for p in all(platforms) do
      if m.vy >= 0 and m.x + m.w > p.x and m.x < p.x + p.w then
        local prev_feet = old_y + m.h
        local feet = m.y + m.h
        if prev_feet <= p.y and feet >= p.y then
          m.y = p.y - m.h
          m.vy = 0
          m.on_ground = true
        end
      end
    end
  end
end

function draw_mount_pickups()
  for m in all(state.mount_pickups) do
    rectfill(m.x, m.y, m.x + m.w - 1, m.y + m.h - 1, 11)
    rect(m.x, m.y, m.x + m.w - 1, m.y + m.h - 1, 7)
  end
end

function try_remount(r)
  for i = #state.mount_pickups, 1, -1 do
    local m = state.mount_pickups[i]
    if aabb(r.x, r.y, r.w, r.h, m.x, m.y, m.w, m.h) then
      set_mount(r, m.mount_name)
      r.naked = false
      r.parachute = false
      r.gravity = gravity
      r.mount_pickup = nil
      deli(state.mount_pickups, i)
      break
    end
  end
end

function remove_mount_pickup(pickup)
  for i = #state.mount_pickups, 1, -1 do
    if state.mount_pickups[i] == pickup then
      deli(state.mount_pickups, i)
      return
    end
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
