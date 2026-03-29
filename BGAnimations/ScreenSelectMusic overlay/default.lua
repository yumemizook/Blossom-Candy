-- Blossom Candy Theme - Song Select Screen
-- File: BGAnimations/ScreenSelectMusic overlay/default.lua

local t = Def.ActorFrame {}

-- Top bar with player info
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(SCREEN_WIDTH - 20, 30)
  end,

  -- Player name background pill
  Def.Quad {
    InitCommand = function(self)
      self:setsize(200, 32)
          :align(1, 0.5)
          :diffuse(BCColors.panel)
    end
  },

  -- Player name text
  LoadFont("hatsukoi Bold 48px") .. {
    InitCommand = function(self)
      self:align(1, 0.5)
          :x(-15)
          :settext("Player 1")
          :diffuse(BCColors.text)
          :zoom(0.425)
    end,
    OnCommand = function(self)
      -- Try to get profile name
      local profile = PROFILEMAN:GetProfile(PLAYER_1)
      if profile then
        local name = profile:GetDisplayName()
        if name and name ~= "" then
          self:settext(name)
        end
      end
    end
  }
}

-- Song Info Panel (right side)
 t[#t+1] = Def.ActorFrame {
   InitCommand = function(self)
     self:xy(20, SCREEN_CENTER_Y)
   end,
   OnCommand = function(self)
     self:diffusealpha(0)
         :decelerate(0.4)
         :diffusealpha(1)
   end,
 
   -- Panel background
   Def.Quad {
     InitCommand = function(self)
       self:setsize(280, 420) -- increased height to fit more pills
           :align(0, 0.5)
           :diffuse(BCColors.panel)
     end
   },

   -- Song title
   LoadFont("hatsukoi Bold 48px") .. {
     Name = "Title",
     InitCommand = function(self)
       self:xy(15, -160)
           :align(0, 0.5)
           :maxwidth(250)
           :settext("Select a song")
           :diffuse(BCColors.text)
           :zoom(0.468)
     end,
     CurrentSongChangedMessageCommand = function(self)
       local song = GAMESTATE:GetCurrentSong()
       if song then
         self:settext(song:GetDisplayMainTitle())
       else
         self:settext("Select a song")
       end
     end
   },
 
   -- Artist
   LoadFont("hatsukoi 48px") .. {
     Name = "Artist",
     InitCommand = function(self)
       self:xy(15, -125)
           :align(0, 0.5)
           :maxwidth(250)
           :settext("")
           :diffuse(BCColors.textMuted)
           :zoom(0.34)
     end,
     CurrentSongChangedMessageCommand = function(self)
       local song = GAMESTATE:GetCurrentSong()
       if song then
         self:settext(song:GetDisplayArtist())
       else
         self:settext("")
       end
     end
   },
 
   -- BPM
   LoadFont("hatsukoi 24px") .. {
     Name = "BPM",
     InitCommand = function(self)
       self:xy(15, -95)
           :align(0, 0.5)
           :settext("")
           :diffuse(BCColors.textMuted)
           :zoom(0.34)
     end,
     CurrentSongChangedMessageCommand = function(self)
       local song = GAMESTATE:GetCurrentSong()
       if song then
         local bpm = song:GetDisplayBpms()
         if bpm[1] == bpm[2] then
           self:settext(string.format("BPM: %d", bpm[1]))
         else
           self:settext(string.format("BPM: %d-%d", bpm[1], bpm[2]))
         end
       else
         self:settext("")
       end
     end
   },
 
   -- Song length
   LoadFont("hatsukoi 24px") .. {
     Name = "Length",
     InitCommand = function(self)
       self:xy(15, -75)
           :align(0, 0.5)
           :settext("")
           :diffuse(BCColors.textMuted)
           :zoom(0.34)
     end,
    CurrentSongChangedMessageCommand = function(self)
      local song = GAMESTATE:GetCurrentSong()
      if song then
        local seconds = song:GetLastSecond()
        local mins = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        self:settext(string.format("Length: %d:%02d", mins, secs))
      else
        self:settext("")
      end
    end
  },

   -- Difficulty pills (up to 10 static pills that update visibility/properties)
   Def.ActorFrame {
     InitCommand = function(self)
       self:xy(20, -10) -- move pills area down a bit
       self.pills = {}
       -- Create up to 10 pill containers
       for i = 1, 10 do
         local pill = self:GetChild("Pill" .. i)
         if pill then
           self.pills[i] = pill
           pill:visible(false)
         end
       end
     end,
     OnCommand = function(self)
       self:playcommand("UpdatePills")
     end,
     CurrentSongChangedMessageCommand = function(self)
       self:playcommand("UpdatePills")
     end,
     CurrentStepsChangedMessageCommand = function(self)
       self:playcommand("UpdatePills")
     end,
 
     UpdatePillsCommand = function(self)
       local song = GAMESTATE:GetCurrentSong()
       
       -- Hide all pills first
       for i = 1, 10 do
         if self.pills[i] then
           self.pills[i]:visible(false)
         end
       end
       
       if not song then return end
 
       local stepsList = song:GetAllSteps()
       local currentSteps = GAMESTATE:GetCurrentSteps(PLAYER_1)
       
       for i, steps in ipairs(stepsList) do
         if i > 10 then break end
         
         local pill = self.pills[i]
         if not pill then break end
         
         -- Get rating
         local stars = steps:GetMeter()
         local ratingTable = nil
         if BCGetRating then
           ratingTable = BCGetRating(steps, song)
           stars = type(ratingTable) == "table" and ratingTable.Overall or ratingTable or stars
         end
         
         -- Get difficulty info
         local diff = steps:GetDifficulty()
         local diffName = ToEnumShortString(diff)
         
         -- Get color
         local pillColor = BCColors.perfect
         if BCGetRatingColor then
           pillColor = BCGetRatingColor(stars)
         end
         
         local isSelected = currentSteps and currentSteps == steps
         
         -- Update pill visibility and properties
         pill:visible(true)
         pill:y((i-1) * 36) -- condensed spacing
         pill:zoom(isSelected and 1.05 or 1.0)
         
         -- Update pill children
         local bg = pill:GetChild("Bg")
         local ratingText = pill:GetChild("Rating")
         local nameText = pill:GetChild("Name")
         local isBlossom = stars >= 10.0
         
         if bg then
           bg:diffuse(pillColor)
           bg:diffusealpha(isSelected and 0.9 or 0.5)
           
           -- Glowing pulse for Blossom
           if isBlossom then
             bg:stopeffect()
                :glow(BCColors.gradeBlossom)
               :glowshift()
               :effectcolor1(Color.Alpha(BCColors.gradeBlossom, 0.4))
               :effectcolor2(Color.Alpha(BCColors.gradeBlossom, 0))
               :effectperiod(2.0)
           else
              bg:stopeffect():glow(color("0,0,0,0"))
           end
         end
         
         if nameText then
           nameText:settext(diffName)
         end

         if ratingText then
           local prefix = isBlossom and "✦ " or ""
           ratingText:settext(string.format("%s%.2f ★", prefix, stars))
           
           -- Apply effects for Blossom tier
           if isBlossom then
             ratingText:stopeffect()
                       :diffuse(BCColors.gradeBlossom)
                       :diffuseshift()
                       :effectcolor1(BCColors.gradeBlossom)
                       :effectcolor2(BCColors.marvelous)
                       :effectperiod(1.5)
           else
             ratingText:stopeffect():diffuse(BCColors.text)
           end
         end
       end -- end for
     end,

    -- Pre-create 10 pill actors
    Def.ActorFrame { Name = "Pill1", InitCommand = function(self) self:xy(0, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill2", InitCommand = function(self) self:xy(0, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill3", InitCommand = function(self) self:xy(0, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill4", InitCommand = function(self) self:xy(0, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill5", InitCommand = function(self) self:xy(-140, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill6", InitCommand = function(self) self:xy(-140, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill7", InitCommand = function(self) self:xy(-140, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill8", InitCommand = function(self) self:xy(-140, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill9", InitCommand = function(self) self:xy(-140, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    },
    Def.ActorFrame { Name = "Pill10", InitCommand = function(self) self:xy(-140, 0) end,
      Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(240, 32):align(0, 0.5) end },
      LoadFont("hatsukoi 48px") .. { Name = "Name", InitCommand = function(self) self:xy(15, 0):align(0, 0.5):zoom(0.383):diffuse(BCColors.text) end },
      LoadFont("hatsukoi 24px") .. { Name = "Rating", InitCommand = function(self) self:x(220):align(1, 0.5):zoom(0.34):diffuse(BCColors.text) end }
    }
  }
}

-- Footer with keybind hints
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(20, SCREEN_HEIGHT - 20)
  end,

  LoadFont("hatsukoi 48px") .. {
    InitCommand = function(self)
      self:align(0, 1)
          :settext("↑/↓: Select  |  Enter: Play  |  Esc: Back")
          :diffuse(BCColors.textMuted)
          :zoom(0.298)
    end
  }
}

-- Music preview handling (auto-preview after delay)
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self.previewTimer = 0
    self.previewDelay = BCGetPref("previewDelay") or 1.2
  end,
  OnCommand = function(self)
    self:SetUpdateFunction(function(af, delta)
      af.previewTimer = af.previewTimer + delta
      if af.previewTimer >= af.previewDelay then
        af.previewTimer = 0
        -- Preview is handled by SM5 engine automatically
      end
    end)
  end,
  CurrentSongChangedMessageCommand = function(self)
    self.previewTimer = 0
  end
}

-- Soft transition overlay (fades in/out)
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:FullScreen()
        :diffuse(BCColors.background)
        :diffusealpha(1)
  end,
  OnCommand = function(self)
    self:decelerate(0.5)
        :diffusealpha(0)
  end,
  OffCommand = function(self)
    self:accelerate(0.3)
        :diffusealpha(1)
  end
}

-- ============================================================================
-- Skillset Radar Panel (Extracted from BCAnalyzeIntervals)
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    -- Positioned horizontally right above the dynamic pill selector list
    self:xy(40, SCREEN_CENTER_Y - 30)
  end,
  CurrentSongChangedMessageCommand = function(self)
    self:playcommand("UpdateSkills")
  end,
  CurrentStepsChangedMessageCommand = function(self)
    self:playcommand("UpdateSkills")
  end,
  
  -- Minimalist dark backing
  Def.Quad {
    InitCommand = function(self)
      self:setsize(240, 42):align(0, 0.5):diffuse(Color.Black):diffusealpha(0.65)
    end
  },
  
  -- STREAM COLUMN
  LoadFont("hatsukoi 48px") .. {
    InitCommand = function(self) self:xy(15, -10):align(0, 0.5):zoom(0.25):settext("Stream"):diffuse(BCColors.textMuted) end
  },
  LoadFont("hatsukoi 48px") .. {
    Name = "StreamVal",
    InitCommand = function(self) self:xy(15, 8):align(0, 0.5):zoom(0.35):diffuse(BCColors.text) end
  },
  
  -- TECH COLUMN
  LoadFont("hatsukoi 48px") .. {
    InitCommand = function(self) self:xy(75, -10):align(0, 0.5):zoom(0.25):settext("Tech"):diffuse(BCColors.textMuted) end
  },
  LoadFont("hatsukoi 48px") .. {
    Name = "TechVal",
    InitCommand = function(self) self:xy(75, 8):align(0, 0.5):zoom(0.35):diffuse(BCColors.text) end
  },

  -- JACK COLUMN
  LoadFont("hatsukoi 48px") .. {
    InitCommand = function(self) self:xy(135, -10):align(0, 0.5):zoom(0.25):settext("Jack"):diffuse(BCColors.textMuted) end
  },
  LoadFont("hatsukoi 48px") .. {
    Name = "JackVal",
    InitCommand = function(self) self:xy(135, 8):align(0, 0.5):zoom(0.35):diffuse(BCColors.text) end
  },

  -- STAMINA COLUMN
  LoadFont("hatsukoi 48px") .. {
    InitCommand = function(self) self:xy(195, -10):align(0, 0.5):zoom(0.25):settext("Stamina"):diffuse(BCColors.textMuted) end
  },
  LoadFont("hatsukoi 48px") .. {
    Name = "StaminaVal",
    InitCommand = function(self) self:xy(195, 8):align(0, 0.5):zoom(0.35):diffuse(BCColors.text) end
  },
  
  UpdateSkillsCommand = function(self)
    local song = GAMESTATE:GetCurrentSong()
    local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
    
    if not song or not steps then
      self:visible(false)
      return
    end
    
    self:visible(true)
    
    local ratingTable = nil
    if BCGetRating then
      ratingTable = BCGetRating(steps, song)
    end
    
    if type(ratingTable) == "table" and ratingTable.Stream then
      self:GetChild("StreamVal"):settext(string.format("%.1f", ratingTable.Stream))
      self:GetChild("TechVal"):settext(string.format("%.1f", ratingTable.Tech))
      self:GetChild("JackVal"):settext(string.format("%.1f", ratingTable.Jack))
      self:GetChild("StaminaVal"):settext(string.format("%.1f", ratingTable.Stamina))
    else
      self:GetChild("StreamVal"):settext("--")
      self:GetChild("TechVal"):settext("--")
      self:GetChild("JackVal"):settext("--")
      self:GetChild("StaminaVal"):settext("--")
    end
  end
}

return t
