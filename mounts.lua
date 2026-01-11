mounts = {
  joust_bird = {
    hitbox = { w = 8, h = 8 },
    draw = function(self)
      if self.dead then return end
      rectfill(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.col)
      rectfill(self.x + 2, self.y - 2, self.x + self.w - 3, self.y, 7)

      local wing_y = self.y + 3
      if self.flap_anim > 0 then
        local wing = sin(t() * 4) * 3
        wing_y = self.y + 3 + wing
      end
      line(self.x - 2, self.y + 3, self.x + 1, wing_y, 7)
      line(self.x + self.w + 1, self.y + 3, self.x + self.w - 2, wing_y, 7)
    end,
    flap = function(self)
      if self.flap_cd > 0 then return end
      self.vy = self.flap_impulse or flap_impulse
      self.flap_cd = 6
      self.flap_anim = 6
    end,
    alt = function(self)
    end,
    move = function(self, dx, dy)
      if self.on_ground then return end
      local mv = self.max_vx or max_vx
      if dx < 0 then self.vx = max(self.vx - 0.1, -mv) end
      if dx > 0 then self.vx = min(self.vx + 0.1, mv) end
    end,
    tick = function(self)
      self.flap_cd = max(0, self.flap_cd - 1)
      self.flap_anim = max(0, self.flap_anim - 1)
    end,
    ondeath = function(self)
    end
  },
  joust_bat = {
    hitbox = { w = 10, h = 6 },
    draw = function(self)
      if self.dead then return end
      rectfill(self.x, self.y + 1, self.x + self.w - 1, self.y + self.h - 2, self.col)
      rectfill(self.x + 2, self.y - 2, self.x + self.w - 3, self.y, 7)

      if self.flap_anim > 0 then
        local wing = sin(t() * 5) * 2
        line(self.x - 3, self.y + 2, self.x + 1, self.y + 2 + wing, 7)
        line(self.x + self.w + 2, self.y + 2, self.x + self.w - 2, self.y + 2 + wing, 7)
      else
        line(self.x - 2, self.y + 2, self.x + 1, self.y + 2, 7)
        line(self.x + self.w + 1, self.y + 2, self.x + self.w - 2, self.y + 2, 7)
      end
    end,
    flap = function(self)
      if self.flap_cd > 0 then return end
      self.vy = (self.flap_impulse or flap_impulse) * 0.8
      self.flap_cd = 4
      self.flap_anim = 4
    end,
    alt = function(self)
    end,
    move = function(self, dx, dy)
      if self.on_ground then return end
      local mv = (self.max_vx or max_vx) * 1.2
      if dx < 0 then self.vx = max(self.vx - 0.12, -mv) end
      if dx > 0 then self.vx = min(self.vx + 0.12, mv) end
    end,
    tick = function(self)
      self.flap_cd = max(0, self.flap_cd - 1)
      self.flap_anim = max(0, self.flap_anim - 1)
    end,
    ondeath = function(self)
    end
  },
  joust_tank = {
    hitbox = { w = 12, h = 6 },
    draw = function(self)
      if self.dead then return end
      rectfill(self.x, self.y + 2, self.x + self.w - 1, self.y + self.h - 1, self.col)
      rectfill(self.x + 1, self.y, self.x + self.w - 2, self.y + 2, 5)
      local cannon_x = self.facing < 0 and (self.x - 3) or (self.x + self.w + 2)
      line(self.x + self.w / 2, self.y + 2, cannon_x, self.y + 2, 7)
      rectfill(self.x + 1, self.y + self.h - 1, self.x + self.w - 2, self.y + self.h, 0)
    end,
    flap = function(self)
      if self.on_ground and self.flap_cd <= 0 then
        self.vy = self.flap_impulse or flap_impulse
        self.flap_cd = 10
      end
    end,
    alt = function(self)
      if self.shoot_cd and self.shoot_cd > 0 then return end
      local dir = self.facing < 0 and -1 or 1
      add_bullet(self.x + self.w / 2 + dir * 6, self.y + 2, dir * 2.4, self)
      self.shoot_cd = 12
    end,
    move = function(self, dx, dy)
      if self.on_ground then return end
      local mv = (self.max_vx or max_vx) * 0.9
      if dx < 0 then self.vx = max(self.vx - 0.08, -mv) end
      if dx > 0 then self.vx = min(self.vx + 0.08, mv) end
    end,
    tick = function(self)
      self.flap_cd = max(0, self.flap_cd - 1)
      if self.shoot_cd then
        self.shoot_cd = max(0, self.shoot_cd - 1)
      end
    end,
    ondeath = function(self)
    end
  },
  joust_ball = {
    hitbox = { w = 6, h = 6 },
    draw = function(self)
      if self.dead then return end
      circfill(self.x + self.w / 2, self.y + self.h / 2, 3, self.col)
      if self.on_ground then
        line(self.x + 1, self.y + self.h, self.x + self.w - 2, self.y + self.h, 0)
      end
    end,
    flap = function(self)
      if self.on_ground and not self.jump_used then
        self.vy = (self.flap_impulse or flap_impulse) * 0.9
        self.jump_used = true
      elseif not self.on_ground then
        self.vy = max_vy
      end
    end,
    alt = function(self)
    end,
    move = function(self, dx, dy)
      self.roll = self.roll or 0
      if self.on_ground and dx ~= 0 then
        self.roll = min(self.roll + 0.02, 1)
      else
        self.roll = max(self.roll - 0.05, 0)
      end
      local mv = (self.max_vx or max_vx) * (1 + self.roll)
      local accel = 0.08 + self.roll * 0.2
      if dx < 0 then self.vx = max(self.vx - accel, -mv) end
      if dx > 0 then self.vx = min(self.vx + accel, mv) end
    end,
    tick = function(self)
      if self.on_ground then
        self.jump_used = false
      end
    end,
    ondeath = function(self)
    end
  },
  joust_jet = {
    hitbox = { w = 8, h = 8 },
    draw = function(self)
      if self.dead then return end
      rectfill(self.x, self.y + 1, self.x + self.w - 1, self.y + self.h - 1, self.col)
      rectfill(self.x + 2, self.y - 2, self.x + self.w - 3, self.y, 7)
      if self.thrust_t and self.thrust_t > 0 then
        line(self.x + self.w / 2, self.y + self.h, self.x + self.w / 2, self.y + self.h + 2, 8)
      end
    end,
    flap = function(self)
      if self.flap_cd > 0 then return end
      self.vy = (self.flap_impulse or flap_impulse) * 0.7
      self.flap_cd = 3
      self.thrust_t = 3
    end,
    alt = function(self)
      if self.dash_cd and self.dash_cd > 0 then return end
      local dir = self.facing < 0 and -1 or 1
      self.vx = dir * ((self.max_vx or max_vx) * 2)
      self.dash_cd = 20
    end,
    move = function(self, dx, dy)
      if self.on_ground then return end
      local mv = (self.max_vx or max_vx) * 1.4
      if dx < 0 then self.vx = max(self.vx - 0.12, -mv) end
      if dx > 0 then self.vx = min(self.vx + 0.12, mv) end
    end,
    tick = function(self)
      self.flap_cd = max(0, (self.flap_cd or 0) - 1)
      self.thrust_t = max(0, (self.thrust_t or 0) - 1)
      if self.dash_cd then
        self.dash_cd = max(0, self.dash_cd - 1)
      end
    end,
    ondeath = function(self)
    end
  },
  joust_glider = {
    hitbox = { w = 9, h = 6 },
    draw = function(self)
      if self.dead then return end
      rectfill(self.x, self.y + 2, self.x + self.w - 1, self.y + self.h - 1, self.col)
      line(self.x - 2, self.y + 2, self.x + 1, self.y + 1, 7)
      line(self.x + self.w + 1, self.y + 2, self.x + self.w - 2, self.y + 1, 7)
    end,
    flap = function(self)
      if self.flap_cd > 0 then return end
      self.vy = (self.flap_impulse or flap_impulse) * 0.6
      self.flap_cd = 8
    end,
    alt = function(self)
      self.glide_t = 20
    end,
    move = function(self, dx, dy)
      if self.on_ground then return end
      local mv = (self.max_vx or max_vx) * 0.9
      if dx < 0 then self.vx = max(self.vx - 0.07, -mv) end
      if dx > 0 then self.vx = min(self.vx + 0.07, mv) end
    end,
    tick = function(self)
      self.flap_cd = max(0, (self.flap_cd or 0) - 1)
      self.glide_t = max(0, (self.glide_t or 0) - 1)
      if self.glide_t > 0 then
        self.vy -= 0.12
      end
    end,
    ondeath = function(self)
    end
  }
}