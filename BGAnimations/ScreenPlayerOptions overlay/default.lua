local t = Def.ActorFrame {}

-- Screen Title
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(SCREEN_CENTER_X, 50)
  end,
  LoadFont("hatsukoi Bold 48px") .. {
    Text = "PLAYER OPTIONS",
    InitCommand = function(self)
      self:diffuse(BCColors.accent)
          :zoom(0.6)
    end
  }
}

-- Helpful instructions at the bottom
t[#t+1] = LoadFont("hatsukoi 24px") .. {
  Text = "&MENULEFT; &MENURIGHT; Move  &START; Select  &BACK; Back",
  InitCommand = function(self)
    self:xy(SCREEN_CENTER_X, SCREEN_HEIGHT - 30)
        :diffuse(BCColors.textMuted)
        :zoom(0.4)
  end
}

return t
