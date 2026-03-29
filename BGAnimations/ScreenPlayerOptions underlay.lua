local t = Def.ActorFrame {}

-- Shared pastel background elements (moved from overlay to render behind options)
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:Center()
  end,
  -- Large soft circle
  Def.Quad {
    InitCommand = function(self)
      self:setsize(SCREEN_WIDTH, SCREEN_HEIGHT)
          :diffuse(BCColors.background)
    end
  },
  -- Floating pastel shapes (matching title screen style)
  Def.ActorFrame {
    InitCommand = function(self) self:xy(-200, -150) end,
    Def.Quad {
      InitCommand = function(self)
        self:setsize(300, 300)
            :diffuse(BCColors.lavender)
            :diffusealpha(0.05)
            :rotationz(45)
      end
    }
  },
  Def.ActorFrame {
    InitCommand = function(self) self:xy(250, 100) end,
    Def.Quad {
      InitCommand = function(self)
        self:setsize(200, 200)
            :diffuse(BCColors.mint)
            :diffusealpha(0.05)
            :rotationz(-20)
      end
    }
  }
}

return t
