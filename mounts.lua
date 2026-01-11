mounts = {
  joust_bird = {
    hitbox = {w=8, h=8},
    draw = function(self)
      if self.dead then return end
      rectfill(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.col)
      rectfill(self.x+2, self.y-2, self.x+self.w-3, self.y, 7)

      local wing_y = self.y + 3
      if self.flap_anim > 0 then
        local wing = sin(t() * 4) * 3
        wing_y = self.y + 3 + wing
      end
      line(self.x-2, self.y+3, self.x+1, wing_y, 7)
      line(self.x+self.w+1, self.y+3, self.x+self.w-2, wing_y, 7)
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
      if dx < 0 then self.vx = max(self.vx-0.1, -mv) end
      if dx > 0 then self.vx = min(self.vx+0.1, mv) end
    end,
    tick = function(self)
      self.flap_cd = max(0, self.flap_cd-1)
      self.flap_anim = max(0, self.flap_anim-1)
    end,
    ondeath = function(self)
    end
  }
}
