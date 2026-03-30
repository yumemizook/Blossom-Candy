-- Blossom Candy Theme - Profile Load Screen
-- Handles automatic profile loading and persistence

local t = Def.ActorFrame {}

-- Background (matching theme style)
t[#t + 1] = Def.ActorFrame {
  Def.Quad {
    InitCommand = function(self)
      self:setsize(SCREEN_WIDTH, SCREEN_HEIGHT)
          :diffuse(BCColors.background)
    end
  }
}

-- Loading text
t[#t + 1] = Def.ActorFrame {
  InitCommand = function(self)
    self:x(SCREEN_CENTER_X)
        :y(SCREEN_CENTER_Y)
        :diffusealpha(0)
  end,
  OnCommand = function(self)
    self:decelerate(0.3)
        :diffusealpha(1)
  end,
  LoadFont("hatsukoi Bold 48px") .. {
    Text = "LOADING PROFILES",
    InitCommand = function(self)
      self:diffuse(BCColors.text)
          :zoom(0.6)
    end
  }
}

-- Profile loading logic - let the engine handle profile loading
t[#t + 1] = Def.Actor {
  BeginCommand = function(self)
    -- Check if we have profiles to load
    if SCREENMAN:GetTopScreen():HaveProfileToLoad() then
      -- Brief delay for visual feedback
      self:sleep(0.8)
    else
      -- No profiles to load, continue immediately
      self:sleep(0.3)
    end
    self:queuecommand("Continue")
  end,
  
  ContinueCommand = function(self)
    -- Let the engine continue - it will handle profile loading internally
    SCREENMAN:GetTopScreen():Continue()
  end
}

return t
