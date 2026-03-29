-- Blossom Candy Theme - Music Wheel Item (Section Collapsed)

local t = Def.ActorFrame {
  SetCommand = function(self, params)
    self:name(tostring(params.Index))
  end
}

-- Background Pill (clean, semi-transparent)
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:setsize(340, 44)
        :align(0, 0.5)
        :diffuse(BCColors.panel)
        :diffusealpha(0.6)
  end,
   SetCommand = function(self, params)
     if params and params.HasFocus then
       self:diffusealpha(0.8):diffuse(BCColors.lavender)
     else
       self:diffusealpha(0.4):diffuse(BCColors.panel)
     end
   end
}

-- Section Title
t[#t+1] = LoadFont("hatsukoi Bold 48px") .. {
  InitCommand = function(self)
    self:x(15)
        :align(0, 0.5)
        :zoom(0.4)
        :maxwidth(280 / 0.4)
        :diffuse(BCColors.text)
  end,
   SetCommand = function(self, params)
     self:settext(params and params.Text or "Folder")
   end
}

-- Folder Icon (simple rectangle/indicator)
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:xy(330, 0)
        :setsize(10, 10)
        :align(1, 0.5)
        :diffuse(BCColors.textMuted)
  end
}

return t
