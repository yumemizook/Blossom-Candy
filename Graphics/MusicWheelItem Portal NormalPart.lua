-- Blossom Candy Theme - Music Wheel Item (Portal)
local t = Def.ActorFrame {
  SetCommand = function(self, params)
    if not params then return end
    self:name(tostring(params.Index))
  end
}

t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:setsize(340, 40):align(0, 0.5):diffuse(BCColors.panel):diffusealpha(0.6)
  end,
  SetCommand = function(self, params)
    if params and params.HasFocus then
      self:diffuse(BCColors.accent):diffusealpha(0.8)
    else
      self:diffuse(BCColors.panel):diffusealpha(0.4)
    end
  end
}

t[#t+1] = LoadFont("hatsukoi Bold 48px") .. {
  InitCommand = function(self)
    self:x(15):align(0, 0.5):zoom(0.35):diffuse(BCColors.text):settext("PORTAL")
  end
}

return t
