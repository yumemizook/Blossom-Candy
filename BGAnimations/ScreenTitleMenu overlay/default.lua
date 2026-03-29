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

-- Title screen menu options
local choices = {"Play", "Options", "Exit"}
local currentChoice = 1

local function updateMenu(self)
    for i = 1, #choices do
        local item = self:GetChild("Choice" .. i)
        if i == currentChoice then
            item:stopeffect():glow(1,1,1,0.2):zoom(0.45):diffuse(BCColors.accent)
        else
            item:stopeffect():glow(1,1,1,0):zoom(0.383):diffuse(BCColors.textMuted)
        end
    end
end

    local leaving = false
    t[#t+1] = Def.ActorFrame {
    Name = "MenuFrame",
    InitCommand = function(self)
        self:x(SCREEN_CENTER_X):y(SCREEN_HEIGHT - 100)
    end,
    OnCommand = function(self)
        updateMenu(self)
        SCREENMAN:GetTopScreen():AddInputCallback(function(event)
            if leaving then return end
            if event.type == "InputEventType_FirstPress" then
                if event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
                    currentChoice = math.max(1, currentChoice - 1)
                    SOUND:PlayOnce(THEME:GetPathS("_common", "row"))
                    updateMenu(self)
                elseif event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
                    currentChoice = math.min(#choices, currentChoice + 1)
                    SOUND:PlayOnce(THEME:GetPathS("_common", "row"))
                    updateMenu(self)
                elseif event.GameButton == "Start" then
                    leaving = true
                    SOUND:PlayOnce(THEME:GetPathS("Common", "start"))
                    local choice = choices[currentChoice]
                    if choice == "Play" then
                        GAMESTATE:ApplyGameCommand("applydefaultoptions;screen,ScreenSelectMusic")
                    elseif choice == "Options" then
                        GAMESTATE:ApplyGameCommand("screen,ScreenOptionsService")
                    elseif choice == "Exit" then
                        GAMESTATE:ApplyGameCommand("screen,ScreenExit")
                    end
                end
            end
        end)
    end,

    -- Menu Items
    LoadFont("hatsukoi Bold 48px") .. {
        Name = "Choice1",
        Text = "PLAY",
        InitCommand = function(self) self:x(-120) end
    },
    LoadFont("hatsukoi Bold 48px") .. {
        Name = "Choice2",
        Text = "OPTIONS",
        InitCommand = function(self) self:x(0) end
    },
    LoadFont("hatsukoi Bold 48px") .. {
        Name = "Choice3",
        Text = "EXIT",
        InitCommand = function(self) self:x(120) end
    }
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
