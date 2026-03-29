-- Blossom Candy Theme - Title Screen Overlay
-- File: BGAnimations/ScreenTitleMenu overlay/default.lua

local t = Def.ActorFrame {
  InitCommand = function(self)
    -- Set default style to Normal, Single
    GAMESTATE:SetCurrentPlayMode("PlayMode_Regular")
    GAMESTATE:SetCurrentStyle("single")
  end
}


-- Background pastel shapes (drifting animation)
-- Multiple layers for parallax effect
for i = 1, 5 do
  t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
      self:x(SCREEN_CENTER_X + math.random(-200, 200))
          :y(SCREEN_CENTER_Y + math.random(-150, 150))
          :zoom(0.5 + i * 0.2)
          :diffusealpha(0.08 + i * 0.02)
    end,
    OnCommand = function(self)
      -- Set color based on pastel palette
      local colors = {
        BCColors.perfect,
        BCColors.great,
        BCColors.accent,
        BCColors.good,
        BCColors.marvelous,
      }
      self:diffuse(colors[i])
    end,
    Def.Quad {
      InitCommand = function(self)
        local size = 100 + i * 50
        self:setsize(size, size)
      end,
      UpdateCommand = function(self)
        -- Slow drift animation
        local time = self:GetSecsIntoEffect()
        local dx = math.sin(time * 0.1 + i) * 2
        local dy = math.cos(time * 0.08 + i) * 1.5
        self:addx(dx * 0.016)  -- per-frame movement
            :addy(dy * 0.016)
      end,
      OnCommand = function(self)
        self:effectperiod(1000)  -- long effect period for UpdateCommand
            :queuecommand("Update")
      end
    }
  }
end

-- Additional floating polygons (soft shapes)
for i = 1, 3 do
  t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
      self:x(math.random(50, SCREEN_WIDTH - 50))
          :y(math.random(50, SCREEN_HEIGHT - 50))
          :zoom(0.3 + i * 0.15)
          :diffusealpha(0.06)
    end,
    OnCommand = function(self)
      local colors = { BCColors.lavender, BCColors.mint, BCColors.peach }
      self:diffuse(colors[i] or BCColors.accent)
    end,
    Def.Quad {
      InitCommand = function(self)
        local w = 150 + i * 40
        local h = 80 + i * 20
        self:setsize(w, h)
      end,
      UpdateCommand = function(self)
        local time = self:GetSecsIntoEffect()
        local rot = math.sin(time * 0.05 + i * 2) * 5
        self:rotationz(rot)
      end,
      OnCommand = function(self)
        self:effectperiod(1000)
            :queuecommand("Update")
      end
    }
  }
end

-- Title text: "Blossom Candy"
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:Center()
        :y(SCREEN_CENTER_Y - 20)  -- slightly above center
        :zoom(0.808)
        :diffusealpha(0)
  end,
  OnCommand = function(self)
    -- Fade in with scale from 0.95 → 1.0 over 0.8s ease-out
    self:sleep(0.1)
        :decelerate(0.8)
        :zoom(0.85)
        :diffusealpha(1)
        -- Start breathing pulse after entrance
        :queuecommand("Pulse")
  end,
  PulseCommand = function(self)
    -- Breathing pulse: 1.0 → 1.012 → 1.0, period ~4s, looping
    self:smooth(2)
        :zoom(0.86)
        :smooth(2)
        :zoom(0.85)
        :queuecommand("Pulse")
  end,

  -- Main title text
  LoadFont("hatsukoi Bold 48px") .. {
    InitCommand = function(self)
      self:settext("Blossom Candy")
          :diffuse(BCColors.text)
          :strokecolor(0.85, 0.72, 0.92, 0.3)
    end
  }
}

-- Subtitle / tagline
t[#t+1] = LoadFont("hatsukoi 24px") .. {
  InitCommand = function(self)
    self:x(SCREEN_CENTER_X)
        :y(SCREEN_CENTER_Y + 35)
        :settext("a soft pastel rhythm experience")
        :diffuse(BCColors.textMuted)
        :zoom(0.425)
        :diffusealpha(0)
  end,
  OnCommand = function(self)
    self:sleep(0.5)
        :decelerate(0.6)
        :diffusealpha(1)
  end
}

-- "Press any key to start" prompt
t[#t+1] = LoadFont("hatsukoi Bold 48px") .. {
  InitCommand = function(self)
    self:x(SCREEN_CENTER_X)
        :y(SCREEN_HEIGHT - 80)
        :settext("press any key to start")
        :diffuse(BCColors.textMuted)
        :zoom(0.383)
  end,
  OnCommand = function(self)
    self:diffusealpha(0.4)
        -- Slow sine-wave opacity blink (~2.5s period)
        :queuecommand("Blink")
  end,
  BlinkCommand = function(self)
    self:smooth(1.25)
        :diffusealpha(0.9)
        :smooth(1.25)
        :diffusealpha(0.4)
        :queuecommand("Blink")
  end
}

-- Version string (bottom-right)
t[#t+1] = LoadFont("hatsukoi 24px") .. {
  InitCommand = function(self)
    self:xy(SCREEN_WIDTH - 20, SCREEN_HEIGHT - 20)
        :align(1, 1)  -- bottom-right
        :settext("v1.0.0")
        :diffuse(BCColors.textMuted)
        :zoom(0.298)
  end
}

-- StepMania version info (bottom-left, tiny)
t[#t+1] = LoadFont("hatsukoi 24px") .. {
  InitCommand = function(self)
    self:xy(20, SCREEN_HEIGHT - 20)
        :align(0, 1)  -- bottom-left
        :settext("StepMania 5.1")
        :diffuse(BCColors.textMuted)
        :zoom(0.255)
  end
}

return t
