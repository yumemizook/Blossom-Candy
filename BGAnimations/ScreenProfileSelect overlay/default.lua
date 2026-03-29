-- Blossom Candy Theme - Profile Select Screen
-- File: BGAnimations/ScreenProfileSelect overlay/default.lua

local t = Def.ActorFrame {}

-- Check if we should auto-select (only 1 profile exists)
local numProfiles = BCProfile:GetNumProfiles()
local profiles = BCProfile:GetAllProfiles()
local currentSelection = 1
local autoSelected = false

-- Check if there's a last used profile to select
local lastProfileId = BCGetPref("lastProfileId")
if lastProfileId and #profiles > 0 then
  for i, profile in ipairs(profiles) do
    if profile.id == lastProfileId then
      currentSelection = i
      break
    end
  end
end

-- Auto-select if only 1 profile
if BCProfile:ShouldAutoSelect() then
  local profile = BCProfile:AutoSelectProfile(PLAYER_1)
  if profile then
    autoSelected = true
    -- Save last used profile
    BCPrefs.lastProfileId = profile.id
    SaveBCPrefs()
  end
end

-- Background (matching other screens)
t[#t + 1] = Def.ActorFrame {
  InitCommand = function(self)
    self:Center()
  end,
  Def.Quad {
    InitCommand = function(self)
      self:setsize(SCREEN_WIDTH, SCREEN_HEIGHT)
          :diffuse(BCColors.background)
    end
  }
}

-- Floating background shapes (matching theme style)
for i = 1, 4 do
  t[#t + 1] = Def.ActorFrame {
    InitCommand = function(self)
      self:x(math.random(100, SCREEN_WIDTH - 100))
          :y(math.random(100, SCREEN_HEIGHT - 100))
          :zoom(0.4 + i * 0.15)
          :diffusealpha(0.05)
    end,
    OnCommand = function(self)
      local colors = {BCColors.lavender, BCColors.mint, BCColors.peach, BCColors.accent}
      self:diffuse(colors[i])
    end,
    Def.Quad {
      InitCommand = function(self)
        local size = 120 + i * 40
        self:setsize(size, size)
            :rotationz(20 * i)
      end
    }
  }
end

-- Title
local screenTitle = Def.ActorFrame {
  InitCommand = function(self)
    self:x(SCREEN_CENTER_X)
        :y(80)
        :diffusealpha(0)
  end,
  OnCommand = function(self)
    self:decelerate(0.5)
        :diffusealpha(1)
  end,
  LoadFont("hatsukoi Bold 48px") .. {
    Text = "SELECT PROFILE",
    InitCommand = function(self)
      self:diffuse(BCColors.text)
          :zoom(0.6)
    end
  }
}
t[#t + 1] = screenTitle

-- Auto-select notification (if applicable)
if autoSelected then
  t[#t + 1] = Def.ActorFrame {
    InitCommand = function(self)
      self:x(SCREEN_CENTER_X)
          :y(130)
          :diffusealpha(0)
    end,
    OnCommand = function(self)
      self:sleep(0.3)
          :decelerate(0.4)
          :diffusealpha(1)
          :sleep(1.0)
          :queuecommand("Continue")
    end,
    ContinueCommand = function(self)
      -- Auto-proceed to next screen after showing notification
      SCREENMAN:GetTopScreen():SetNextScreenName("ScreenSelectMusic")
      SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
    end,
    LoadFont("hatsukoi 24px") .. {
      Text = "Auto-selected profile: " .. (profiles[1] and profiles[1].name or "Player 1"),
      InitCommand = function(self)
        self:diffuse(BCColors.accent)
            :zoom(0.4)
      end
    }
  }
  return t
end

-- No profiles message
if numProfiles == 0 then
  t[#t + 1] = Def.ActorFrame {
    InitCommand = function(self)
      self:x(SCREEN_CENTER_X)
          :y(SCREEN_CENTER_Y)
          :diffusealpha(0)
    end,
    OnCommand = function(self)
      self:decelerate(0.5)
          :diffusealpha(1)
    end,
    LoadFont("hatsukoi 24px") .. {
      Text = "No local profiles found.",
      InitCommand = function(self)
        self:diffuse(BCColors.textMuted)
            :zoom(0.5)
            :y(-30)
      end
    },
    LoadFont("hatsukoi 24px") .. {
      Text = "Create a profile in Options > Profiles",
      InitCommand = function(self)
        self:diffuse(BCColors.textMuted)
            :zoom(0.35)
            :y(10)
      end
    },
    LoadFont("hatsukoi 24px") .. {
      Text = "Press START to continue as Guest",
      InitCommand = function(self)
        self:diffuse(BCColors.good)
            :zoom(0.35)
            :y(50)
      end
    }
  }

  -- Input handling for no profiles case
  t[#t + 1] = Def.ActorFrame {
    OnCommand = function(self)
      SCREENMAN:GetTopScreen():AddInputCallback(function(event)
        if event.type == "InputEventType_FirstPress" then
          if event.GameButton == "Start" then
            SOUND:PlayOnce(THEME:GetPathS("Common", "start"))
            -- Continue as guest (no profile loaded)
            SCREENMAN:GetTopScreen():SetNextScreenName("ScreenSelectMusic")
            SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
          end
        end
      end)
    end
  }

  return t
end

-- Profile list container
local profileListY = SCREEN_CENTER_Y - 50
local profileSpacing = 60
local selectedProfileFrame = nil

local function updateSelection(self)
  for i = 1, #profiles do
    local item = self:GetChild("Profile" .. i)
    if i == currentSelection then
      item:stopeffect()
          :glow(1, 1, 1, 0.15)
          :zoom(1.0)
      -- Update the highlight frame position
      if selectedProfileFrame then
        selectedProfileFrame:stoptweening()
            :smooth(0.15)
            :y(profileListY + (i - 1) * profileSpacing)
            :diffusealpha(1)
      end
    else
      item:stopeffect()
          :glow(1, 1, 1, 0)
          :zoom(0.9)
          :diffusealpha(0.6)
    end
  end
end

-- Selection highlight frame
local highlightFrame = Def.ActorFrame {
  Name = "HighlightFrame",
  InitCommand = function(self)
    self:x(SCREEN_CENTER_X)
        :y(profileListY)
        :diffusealpha(0)
    selectedProfileFrame = self
  end,
  OnCommand = function(self)
    self:decelerate(0.3)
        :diffusealpha(1)
  end,
  Def.Quad {
    InitCommand = function(self)
      self:setsize(400, 50)
          :diffuse(BCColors.accent)
          :diffusealpha(0.2)
          :xy(0, 0)
    end
  },
  Def.Quad {
    InitCommand = function(self)
      self:setsize(400, 2)
          :diffuse(BCColors.accent)
          :y(-25)
    end
  },
  Def.Quad {
    InitCommand = function(self)
      self:setsize(400, 2)
          :diffuse(BCColors.accent)
          :y(25)
    end
  }
}
t[#t + 1] = highlightFrame

-- Profile items
local profilesContainer = Def.ActorFrame {
  Name = "ProfilesContainer",
  InitCommand = function(self)
    self:x(SCREEN_CENTER_X)
        :y(profileListY)
  end
}

for i, profile in ipairs(profiles) do
  local profileY = (i - 1) * profileSpacing

  profilesContainer[#profilesContainer + 1] = Def.ActorFrame {
    Name = "Profile" .. i,
    InitCommand = function(self)
      self:y(profileY)
          :diffusealpha(0)
    end,
    OnCommand = function(self)
      self:sleep(i * 0.05)
          :decelerate(0.3)
          :diffusealpha(i == currentSelection and 1 or 0.6)
    end,
    -- Profile name
    LoadFont("hatsukoi Bold 48px") .. {
      Text = profile.name,
      InitCommand = function(self)
        self:diffuse(BCColors.text)
            :zoom(0.45)
            :halign(0)
            :x(-180)
      end
    },
    -- High score count
    LoadFont("hatsukoi 24px") .. {
      Text = profile.highscore .. " High Scores",
      InitCommand = function(self)
        self:diffuse(BCColors.textMuted)
            :zoom(0.3)
            :halign(1)
            :x(180)
      end
    }
  }
end

t[#t + 1] = profilesContainer

-- Instructions
local instructions = Def.ActorFrame {
  InitCommand = function(self)
    self:x(SCREEN_CENTER_X)
        :y(SCREEN_HEIGHT - 100)
        :diffusealpha(0)
  end,
  OnCommand = function(self)
    self:sleep(0.5)
        :decelerate(0.4)
        :diffusealpha(1)
  end,
  LoadFont("hatsukoi 24px") .. {
    Text = "UP/DOWN: Select  |  START: Confirm  |  BACK: Guest",
    InitCommand = function(self)
      self:diffuse(BCColors.textMuted)
          :zoom(0.32)
    end
  }
}
t[#t + 1] = instructions

-- Guest option at bottom
local guestOption = Def.ActorFrame {
  Name = "GuestOption",
  InitCommand = function(self)
    self:x(SCREEN_CENTER_X)
        :y(SCREEN_HEIGHT - 50)
        :diffusealpha(0)
  end,
  OnCommand = function(self)
    self:sleep(0.6)
        :decelerate(0.4)
        :diffusealpha(1)
  end,
  LoadFont("hatsukoi 24px") .. {
    Text = "Continue as Guest",
    InitCommand = function(self)
      self:diffuse(BCColors.textMuted)
          :zoom(0.35)
    end
  }
}
t[#t + 1] = guestOption

-- Input handling
t[#t + 1] = Def.ActorFrame {
  OnCommand = function(self)
    local container = self:GetParent():GetChild("ProfilesContainer")

    SCREENMAN:GetTopScreen():AddInputCallback(function(event)
      if event.type == "InputEventType_FirstPress" then
        if event.GameButton == "MenuUp" or event.GameButton == "MenuLeft" then
          if currentSelection > 1 then
            currentSelection = currentSelection - 1
            SOUND:PlayOnce(THEME:GetPathS("_common", "row"))
            updateSelection(container)
          end
        elseif event.GameButton == "MenuDown" or event.GameButton == "MenuRight" then
          if currentSelection < #profiles then
            currentSelection = currentSelection + 1
            SOUND:PlayOnce(THEME:GetPathS("_common", "row"))
            updateSelection(container)
          end
        elseif event.GameButton == "Start" then
          SOUND:PlayOnce(THEME:GetPathS("Common", "start"))
          -- Load the selected profile
          local profile = BCProfile:LoadProfileByIndex(PLAYER_1, currentSelection - 1)
          if profile then
            -- Save the profile ID for persistence
            BCPrefs.lastProfileId = profile.id
            SaveBCPrefs()
          end
          SCREENMAN:GetTopScreen():SetNextScreenName("ScreenSelectMusic")
          SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
        elseif event.GameButton == "Back" then
          SOUND:PlayOnce(THEME:GetPathS("Common", "cancel"))
          -- Continue as guest (no profile loaded)
          -- Clear last profile preference
          BCPrefs.lastProfileId = nil
          SaveBCPrefs()
          SCREENMAN:GetTopScreen():SetNextScreenName("ScreenSelectMusic")
          SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
        end
      end
    end)

    -- Initial selection update
    updateSelection(container)
  end
}

return t
