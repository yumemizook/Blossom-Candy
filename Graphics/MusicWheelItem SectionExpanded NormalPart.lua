-- Blossom Candy Theme - Music Wheel Item (Section Expanded)

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
        :diffusealpha(1.0) -- more opaque when expanded
  end,
   SetCommand = function(self, params)
     if params and params.HasFocus then
       self:diffuse(BCColors.lavender):diffusealpha(0.8)
     else
       self:diffuse(BCColors.panel):diffusealpha(0.6)
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

-- Open Icon
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:xy(330, 0)
        :setsize(15, 4)
        :align(1, 0.5)
        :diffuse(BCColors.text)
  end
}

return t
