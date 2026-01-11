function apply_mount_hitbox(r)
  if r.mount and r.mount.hitbox then
    r.w = r.mount.hitbox.w or r.w
    r.h = r.mount.hitbox.h or r.h
  end
end
