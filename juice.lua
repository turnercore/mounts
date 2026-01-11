function add_explosion(x, y, size, duration, col)
  local e = {
    x = x,
    y = y,
    t = duration,
    dec = true,
    size = size or 1,
    col = col,
    draw = function(self)
      local r = self.t
      if r <= 0 then return end
      local c = self.col or 8
      for i = 1, self.size do
        local ox = flr(rnd(3)) - 1
        local oy = flr(rnd(3)) - 1
        circfill(self.x + ox, self.y + oy, r, c)
        if r > 2 then
          circfill(self.x + ox, self.y + oy, r - 2, 7)
        end
      end
    end
  }
  add(state.explosions, e)
  return e
end

function add_screen_flash(duration, col)
  local f = {
    t = duration or 8,
    dec = true,
    col = col or 7,
    draw = function(self)
      rectfill(0, 0, 127, 127, self.col)
    end
  }
  add(state.screen_flashes, f)
  return f
end

-- screenshake helpers
function ss(frames, mag)
  frames = frames or 0
  if frames <= 0 then
    return
  end
  state.ss_t = max(state.ss_t or 0, frames)
  state.ss_mag = max(state.ss_mag or 0, mag or 1)
end

function update_ss()
  local t = state.ss_t or 0
  if t > 0 then
    t -= 1
    state.ss_t = t
    if t <= 0 then
      state.ss_mag = nil
    end
  end
end

function apply_ss()
  local t = state.ss_t or 0
  if t <= 0 then
    camera()
    return
  end
  local mag = state.ss_mag or 1
  local ox = flr(rnd(mag * 2 + 1)) - mag
  local oy = flr(rnd(mag * 2 + 1)) - mag
  camera(ox, oy)
end

-- hitstop helper (freeze frames)
function hitstop(duration)
  if duration <= 0 then
    return
  end
  state.pause_t = max(state.pause_t or 0, duration)
  state.paused = true
end