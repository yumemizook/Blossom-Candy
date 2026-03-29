-- Blossom Candy Theme - Song Select Underlay
-- File: BGAnimations/ScreenSelectMusic underlay/default.lua

local t = Def.ActorFrame {}

-- Background tint
-- Moved from overlay to underlay to prevent covering the MusicWheel
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:FullScreen()
        :diffuse(BCColors.background)
        :diffusealpha(0.98)
  end
}

return t
