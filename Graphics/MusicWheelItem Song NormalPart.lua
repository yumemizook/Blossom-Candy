-- Blossom Candy Theme - Music Wheel Item (Song)
-- Based on spawncamping-wallhack style but with Blossom Candy branding

local t = Def.ActorFrame {
  SetCommand = function(self, params)
    self:name(tostring(params.Index))
  end
}

-- Background Pill (clean, semi-transparent)
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:setsize(340, 40)
        :align(0, 0.5)
        :diffuse(BCColors.panel)
        :diffusealpha(0.6)
  end,
   SetCommand = function(self, params)
     if params.HasFocus then
       self:diffusealpha(0.8):diffuse(BCColors.accent)
     else
       self:diffusealpha(0.4):diffuse(BCColors.panel)
     end
   end
}

-- Selection Indicator (left side line)
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:setsize(4, 40)
        :align(0, 0.5)
        :diffuse(BCColors.accent)
        :visible(false)
  end,
   SetCommand = function(self, params)
     self:visible(params and params.HasFocus or false)
   end
}

-- Song Title
t[#t+1] = LoadFont("hatsukoi Bold 48px") .. {
  InitCommand = function(self)
    self:x(15)
        :align(0, 0.5)
        :zoom(0.35)
        :maxwidth(280 / 0.35)
        :diffuse(BCColors.text)
  end,
   SetCommand = function(self, params)
     if not params then return end
     local song = params.Song
     if song then
       self:settext(song:GetDisplayMainTitle())
     else
       self:settext("")
     end
   end
}

-- Artist (optional, if we want it on the wheel too)
t[#t+1] = LoadFont("hatsukoi 24px") .. {
  InitCommand = function(self)
    self:xy(330, 0)
        :align(1, 0.5)
        :zoom(0.3)
        :maxwidth(100 / 0.3)
        :diffuse(BCColors.textMuted)
  end,
   SetCommand = function(self, params)
     if not params then return end
     local song = params.Song
     if song then
       self:settext(song:GetDisplayArtist())
     else
       self:settext("")
     end
   end
}

return t
