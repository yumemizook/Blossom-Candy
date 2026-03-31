-- Blossom Candy Theme - Song Select Screen
-- File: BGAnimations/ScreenSelectMusic overlay/default.lua
-- Redesigned: Static center highlight, right-side difficulty selector, reorganized song info

local t = Def.ActorFrame {}

-- ============================================================================
-- HIDE DEFAULT SM5 BANNER (prevent duplicate)
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    -- Hide the default banner actor that SM5 creates
    local screen = SCREENMAN:GetTopScreen()
    if screen then
      local banner = screen:GetChild("Banner")
      if banner then
        banner:visible(false)
      end
    end
  end,
  OnCommand = function(self)
    local screen = SCREENMAN:GetTopScreen()
    if screen then
      local banner = screen:GetChild("Banner")
      if banner then
        banner:visible(false)
      end
    end
  end
}

-- ============================================================================
-- STATIC CENTER HIGHLIGHT (spawncamping-wallhack style)
-- Fixed highlight aligned with MusicWheel at SCREEN_WIDTH-280
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(SCREEN_WIDTH - 180, SCREEN_CENTER_Y)
  end,

  -- Main highlight background
  Def.Quad {
    InitCommand = function(self)
      self:setsize(360, 42)
          :align(0.5, 0.5)
          :diffuse(BCColors.accent)
          :diffusealpha(0.3)
          :glow(BCColors.accent)
          :glowshift()
          :effectcolor1(Color.Alpha(BCColors.accent, 0.2))
          :effectcolor2(Color.Alpha(BCColors.accent, 0))
          :effectperiod(2.0)
    end
  },

  -- Left accent line
  Def.Quad {
    InitCommand = function(self)
      self:setsize(4, 42)
          :x(-180)
          :align(0, 0.5)
          :diffuse(BCColors.lavender)
    end
  },

  -- Right accent line
  Def.Quad {
    InitCommand = function(self)
      self:setsize(4, 42)
          :x(166)
          :align(0, 0.5)
          :diffuse(BCColors.lavender)
    end
  }
}

-- ============================================================================
-- TOP BAR WITH PLAYER INFO
-- ============================================================================
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

-- SONG INFO PANEL (LEFT SIDE) - Wider with banner on top
local songInfoPanel = Def.ActorFrame {
  Name = "SongInfoPanel",
  InitCommand = function(self)
    self:xy(30, SCREEN_CENTER_Y)
  end,
  OnCommand = function(self)
    self:diffusealpha(0)
        :decelerate(0.4)
        :diffusealpha(1)
  end,

  -- Panel background - widened
  Def.Quad {
    InitCommand = function(self)
      self:setsize(340, 480)
          :align(0, 0.5)
          :diffuse(BCColors.panel)
    end
  },

  -- ============================================================================
  -- BANNER (at top of panel)
  -- ============================================================================
  Def.ActorFrame {
    InitCommand = function(self)
      self:xy(170, -180)
    end,

    -- Banner background (placeholder when no banner)
    Def.Quad {
      InitCommand = function(self)
        self:setsize(300, 112)
            :align(0.5, 0.5)
            :diffuse(Color.Black)
            :diffusealpha(0.3)
      end
    },

    -- Actual banner sprite
    Def.Sprite {
      Name = "BannerSprite",
      InitCommand = function(self)
        self:align(0.5, 0.5)
            :scaletoclipped(300, 112)
      end,
      CurrentSongChangedMessageCommand = function(self)
        local song = GAMESTATE:GetCurrentSong()
        if song then
          local bannerPath = song:GetBannerPath()
          if bannerPath and bannerPath ~= "" then
            self:Load(bannerPath)
            self:visible(true)
          else
            self:visible(false)
          end
        else
          self:visible(false)
        end
      end
    }
  },

  -- ============================================================================
  -- METADATA (title, artist, BPM, length)
  -- ============================================================================
  -- Song title
  LoadFont("hatsukoi Bold 48px") .. {
    Name = "Title",
    InitCommand = function(self)
      self:xy(20, -105)
          :align(0, 0.5)
          :maxwidth(300)
          :settext("Select a song")
          :diffuse(BCColors.text)
          :zoom(0.45)
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
      self:xy(20, -70)
          :align(0, 0.5)
          :maxwidth(300)
          :settext("")
          :diffuse(BCColors.textMuted)
          :zoom(0.32)
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
      self:xy(20, -40)
          :align(0, 0.5)
          :settext("")
          :diffuse(BCColors.textMuted)
          :zoom(0.32)
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
      self:xy(20, -18)
          :align(0, 0.5)
          :settext("")
          :diffuse(BCColors.textMuted)
          :zoom(0.32)
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

  -- ============================================================================
  -- RATING DISPLAY (Overall stars)
  -- ============================================================================
  LoadFont("hatsukoi Bold 48px") .. {
    Name = "RatingDisplay",
    InitCommand = function(self)
      self:xy(20, 20)
          :align(0, 0.5)
          :settext("")
          :diffuse(BCColors.text)
          :zoom(0.42)
    end,
    OnCommand = function(self)
      -- Force initial update with delay
      self:playcommand("Update")
      self:sleep(0.12):queuecommand("Update")
    end,
    CurrentSongChangedMessageCommand = function(self) self:playcommand("Update") end,
    CurrentStepsChangedMessageCommand = function(self) self:playcommand("Update") end,
    UpdateCommand = function(self)
      local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
      local song = GAMESTATE:GetCurrentSong()

      -- Verify we have valid song and steps before displaying rating
      if not steps or not song then
        self:settext("")
        return
      end

      -- Validate that steps belongs to the current song (prevent race condition)
      local stepsBelongsToSong = false
      local songSteps = song:GetAllSteps()
      for _, s in ipairs(songSteps) do
        if s == steps then
          stepsBelongsToSong = true
          break
        end
      end

      if not stepsBelongsToSong then
        self:settext("")
        -- Retry after a short delay when wheel settles
        self:sleep(0.1):queuecommand("Update")
        return
      end

      local stars = steps:GetMeter()
      if BCGetRating then
        local ratingTable = BCGetRating(steps, song)
        stars = type(ratingTable) == "table" and ratingTable.Overall or ratingTable or stars
      end

      -- Blue -> Green -> Yellow -> Red -> Purple color scale function for overall rating
      local function GetRatingColor(value)
        local t = math.max(0, math.min(1, value / 10))
        local r, g, b
        if t < 0.25 then
          -- Blue to Green
          local p = t / 0.25
          r = 0.25 + (0.20 - 0.25) * p
          g = 0.45 + (0.80 - 0.45) * p
          b = 0.90 + (0.25 - 0.90) * p
        elseif t < 0.50 then
          -- Green to Yellow
          local p = (t - 0.25) / 0.25
          r = 0.20 + (0.95 - 0.20) * p
          g = 0.80 + (0.85 - 0.80) * p
          b = 0.25 + (0.20 - 0.25) * p
        elseif t < 0.75 then
          -- Yellow to Red
          local p = (t - 0.50) / 0.25
          r = 0.95 + (0.90 - 0.95) * p
          g = 0.85 + (0.20 - 0.85) * p
          b = 0.20 + (0.25 - 0.20) * p
        else
          -- Red to Purple
          local p = (t - 0.75) / 0.25
          r = 0.90 + (0.50 - 0.90) * p
          g = 0.20 + (0.10 - 0.20) * p
          b = 0.25 + (0.90 - 0.25) * p
        end
        return color(string.format("%.3f,%.3f,%.3f,1", r, g, b))
      end

      local isBlossom = stars >= 10.0
      local prefix = isBlossom and "✦ " or ""
      self:settext(string.format("%s%.2f ★", prefix, stars))
      if isBlossom then
        self:stopeffect()
            :diffuse(GetRatingColor(stars))
            :diffuseshift()
            :effectcolor1(GetRatingColor(stars))
            :effectcolor2(color("0.55,0.15,0.95,1"))
            :effectperiod(1.5)
      else
        self:stopeffect():diffuse(GetRatingColor(stars))
      end
    end
  },

  -- ============================================================================
  -- SKILLSET RADAR (7 Skillsets: Stream, Jumpstream, Handstream, Jackseed, Chordjack, Technical, Stamina)
  -- ============================================================================
  Def.ActorFrame {
    Name = "SkillsetRadar",
    InitCommand = function(self)
      self:xy(20, 75)
    end,
    OnCommand = function(self)
      -- Force initial update with delay to catch initial song/steps
      self:playcommand("UpdateSkills")
      self:sleep(0.15):queuecommand("UpdateSkills")
    end,
    CurrentSongChangedMessageCommand = function(self) self:playcommand("UpdateSkills") end,
    CurrentStepsChangedMessageCommand = function(self) self:playcommand("UpdateSkills") end,

    -- ROW 1: Stream | Jumpstream | Handstream | Jackseed
    -- STREAM
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(12, -22):align(0, 0.5):zoom(0.22):settext("Stream"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 48px") .. {
      Name = "StreamVal",
      InitCommand = function(self) self:xy(12, -8):align(0, 0.5):zoom(0.30):diffuse(BCColors.text) end
    },

    -- JUMPSTREAM
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(88, -22):align(0, 0.5):zoom(0.22):settext("Jump"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 48px") .. {
      Name = "JumpstreamVal",
      InitCommand = function(self) self:xy(88, -8):align(0, 0.5):zoom(0.30):diffuse(BCColors.text) end
    },

    -- HANDSTREAM
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(162, -22):align(0, 0.5):zoom(0.22):settext("Hand"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 48px") .. {
      Name = "HandstreamVal",
      InitCommand = function(self) self:xy(162, -8):align(0, 0.5):zoom(0.30):diffuse(BCColors.text) end
    },

    -- JACKSEED
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(236, -22):align(0, 0.5):zoom(0.22):settext("Jack"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 48px") .. {
      Name = "JackseedVal",
      InitCommand = function(self) self:xy(236, -8):align(0, 0.5):zoom(0.30):diffuse(BCColors.text) end
    },

    -- ROW 2: Chordjack | Technical | Stamina
    -- CHORDJACK
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(12, 10):align(0, 0.5):zoom(0.22):settext("ChordJ"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 48px") .. {
      Name = "ChordjackVal",
      InitCommand = function(self) self:xy(12, 24):align(0, 0.5):zoom(0.30):diffuse(BCColors.text) end
    },

    -- TECHNICAL
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(88, 10):align(0, 0.5):zoom(0.22):settext("Tech"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 48px") .. {
      Name = "TechnicalVal",
      InitCommand = function(self) self:xy(88, 24):align(0, 0.5):zoom(0.30):diffuse(BCColors.text) end
    },

    -- STAMINA
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(162, 10):align(0, 0.5):zoom(0.22):settext("Stam"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 48px") .. {
      Name = "StaminaVal",
      InitCommand = function(self) self:xy(162, 24):align(0, 0.5):zoom(0.30):diffuse(BCColors.text) end
    },

    UpdateSkillsCommand = function(self)
      local song = GAMESTATE:GetCurrentSong()
      local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)

      -- Verify we have valid song and steps, and steps belongs to song
      if not steps or not song then
        self:visible(false)
        return
      end

      -- Validate that steps belongs to the current song (prevent race condition)
      local stepsBelongsToSong = false
      local songSteps = song:GetAllSteps()
      for _, s in ipairs(songSteps) do
        if s == steps then
          stepsBelongsToSong = true
          break
        end
      end

      if not stepsBelongsToSong then
        self:visible(false)
        -- Retry after a short delay when wheel settles
        self:sleep(0.1):queuecommand("UpdateSkills")
        return
      end

      self:visible(true)

      -- Blue -> Green -> Yellow -> Red -> Purple color scale function
      local function GetSkillsetColor(value)
        local t = math.max(0, math.min(1, value / 10))
        local r, g, b
        if t < 0.25 then
          -- Blue to Green
          local p = t / 0.25
          r = 0.25 + (0.20 - 0.25) * p
          g = 0.45 + (0.80 - 0.45) * p
          b = 0.90 + (0.25 - 0.90) * p
        elseif t < 0.50 then
          -- Green to Yellow
          local p = (t - 0.25) / 0.25
          r = 0.20 + (0.95 - 0.20) * p
          g = 0.80 + (0.85 - 0.80) * p
          b = 0.25 + (0.20 - 0.25) * p
        elseif t < 0.75 then
          -- Yellow to Red
          local p = (t - 0.50) / 0.25
          r = 0.95 + (0.90 - 0.95) * p
          g = 0.85 + (0.20 - 0.85) * p
          b = 0.20 + (0.25 - 0.20) * p
        else
          -- Red to Purple
          local p = (t - 0.75) / 0.25
          r = 0.90 + (0.50 - 0.90) * p
          g = 0.20 + (0.10 - 0.20) * p
          b = 0.25 + (0.90 - 0.25) * p
        end
        return color(string.format("%.3f,%.3f,%.3f,1", r, g, b))
      end

      local ratingTable = nil
      if BCGetRating then
        ratingTable = BCGetRating(steps, song)
      end

      if type(ratingTable) == "table" and ratingTable.Stream then
        local streamVal = self:GetChild("StreamVal")
        streamVal:settext(string.format("%.1f", ratingTable.Stream or 0))
        streamVal:diffuse(GetSkillsetColor(ratingTable.Stream or 0))

        local jumpVal = self:GetChild("JumpstreamVal")
        jumpVal:settext(string.format("%.1f", ratingTable.Jumpstream or 0))
        jumpVal:diffuse(GetSkillsetColor(ratingTable.Jumpstream or 0))

        local handVal = self:GetChild("HandstreamVal")
        handVal:settext(string.format("%.1f", ratingTable.Handstream or 0))
        handVal:diffuse(GetSkillsetColor(ratingTable.Handstream or 0))

        local jackVal = self:GetChild("JackseedVal")
        jackVal:settext(string.format("%.1f", ratingTable.Jackseed or 0))
        jackVal:diffuse(GetSkillsetColor(ratingTable.Jackseed or 0))

        local chordVal = self:GetChild("ChordjackVal")
        chordVal:settext(string.format("%.1f", ratingTable.Chordjack or 0))
        chordVal:diffuse(GetSkillsetColor(ratingTable.Chordjack or 0))

        local techVal = self:GetChild("TechnicalVal")
        techVal:settext(string.format("%.1f", ratingTable.Technical or 0))
        techVal:diffuse(GetSkillsetColor(ratingTable.Technical or 0))

        local stamVal = self:GetChild("StaminaVal")
        stamVal:settext(string.format("%.1f", ratingTable.Stamina or 0))
        stamVal:diffuse(GetSkillsetColor(ratingTable.Stamina or 0))
      else
        self:GetChild("StreamVal"):settext("--"):diffuse(BCColors.textMuted)
        self:GetChild("JumpstreamVal"):settext("--"):diffuse(BCColors.textMuted)
        self:GetChild("HandstreamVal"):settext("--"):diffuse(BCColors.textMuted)
        self:GetChild("JackseedVal"):settext("--"):diffuse(BCColors.textMuted)
        self:GetChild("ChordjackVal"):settext("--"):diffuse(BCColors.textMuted)
        self:GetChild("TechnicalVal"):settext("--"):diffuse(BCColors.textMuted)
        self:GetChild("StaminaVal"):settext("--"):diffuse(BCColors.textMuted)
      end
    end
  },

  -- ============================================================================
  -- PERSONAL BEST DISPLAY (Compact Layout)
  -- ============================================================================
  Def.ActorFrame {
    Name = "PersonalBest",
    InitCommand = function(self)
      self:xy(20, 140)
    end,
    OnCommand = function(self)
      self:playcommand("UpdatePB")
      self:sleep(0.2):queuecommand("UpdatePB")
    end,
    CurrentSongChangedMessageCommand = function(self) self:playcommand("UpdatePB") end,
    CurrentStepsChangedMessageCommand = function(self) self:playcommand("UpdatePB") end,

    -- PB Label
    LoadFont("hatsukoi 48px") .. {
      Name = "PBLabel",
      InitCommand = function(self)
        self:align(0, 0.5)
            :settext("Personal Best")
            :diffuse(BCColors.textMuted)
            :zoom(0.26)
      end
    },

    -- Main Score
    LoadFont("hatsukoi Bold 48px") .. {
      Name = "PBScore",
      InitCommand = function(self)
        self:xy(0, 20)
            :align(0, 0.5)
            :settext("--")
            :diffuse(BCColors.text)
            :zoom(0.40)
      end
    },

    -- Judge/Scoring superscript
    LoadFont("hatsukoi 48px") .. {
      Name = "PBJudgeInfo",
      InitCommand = function(self)
        self:xy(0, 20)
            :align(0, 0.5)
            :settext("")
            :diffuse(BCColors.textMuted)
            :zoom(0.18)
      end
    },

    -- BP Display (inline with score area)
    LoadFont("hatsukoi Bold 48px") .. {
      Name = "PBBP",
      InitCommand = function(self)
        self:xy(140, 20)
            :align(0, 0.5)
            :settext("")
            :diffuse(BCColors.accent)
            :zoom(0.30)
      end
    },

    -- Judgement Tally - Compact 2x3 Grid Layout
    -- Row 1: MA | PR | GR
    LoadFont("hatsukoi 48px") .. {
      Name = "LabelW1",
      InitCommand = function(self)
        self:xy(0, 42)
            :align(0, 0.5)
            :settext("MA")
            :diffuse(color("1,0.85,0.4,1"))
            :zoom(0.20)
      end
    },
    LoadFont("hatsukoi Bold 48px") .. {
      Name = "ValW1",
      InitCommand = function(self)
        self:xy(22, 42)
            :align(0, 0.5)
            :settext("")
            :diffuse(BCColors.text)
            :zoom(0.24)
      end
    },

    LoadFont("hatsukoi 48px") .. {
      Name = "LabelW2",
      InitCommand = function(self)
        self:xy(70, 42)
            :align(0, 0.5)
            :settext("PR")
            :diffuse(color("0.9,0.5,0.9,1"))
            :zoom(0.20)
      end
    },
    LoadFont("hatsukoi Bold 48px") .. {
      Name = "ValW2",
      InitCommand = function(self)
        self:xy(92, 42)
            :align(0, 0.5)
            :settext("")
            :diffuse(BCColors.text)
            :zoom(0.24)
      end
    },

    LoadFont("hatsukoi 48px") .. {
      Name = "LabelW3",
      InitCommand = function(self)
        self:xy(140, 42)
            :align(0, 0.5)
            :settext("GR")
            :diffuse(color("0.2,0.8,0.4,1"))
            :zoom(0.20)
      end
    },
    LoadFont("hatsukoi Bold 48px") .. {
      Name = "ValW3",
      InitCommand = function(self)
        self:xy(162, 42)
            :align(0, 0.5)
            :settext("")
            :diffuse(BCColors.text)
            :zoom(0.24)
      end
    },

    -- Row 2: GD | BD | MS
    LoadFont("hatsukoi 48px") .. {
      Name = "LabelW4",
      InitCommand = function(self)
        self:xy(0, 58)
            :align(0, 0.5)
            :settext("GD")
            :diffuse(color("0.3,0.6,0.9,1"))
            :zoom(0.20)
      end
    },
    LoadFont("hatsukoi Bold 48px") .. {
      Name = "ValW4",
      InitCommand = function(self)
        self:xy(22, 58)
            :align(0, 0.5)
            :settext("")
            :diffuse(BCColors.text)
            :zoom(0.24)
      end
    },

    LoadFont("hatsukoi 48px") .. {
      Name = "LabelW5",
      InitCommand = function(self)
        self:xy(70, 58)
            :align(0, 0.5)
            :settext("BD")
            :diffuse(color("0.9,0.4,0.2,1"))
            :zoom(0.20)
      end
    },
    LoadFont("hatsukoi Bold 48px") .. {
      Name = "ValW5",
      InitCommand = function(self)
        self:xy(92, 58)
            :align(0, 0.5)
            :settext("")
            :diffuse(BCColors.text)
            :zoom(0.24)
      end
    },

    LoadFont("hatsukoi 48px") .. {
      Name = "LabelMiss",
      InitCommand = function(self)
        self:xy(140, 58)
            :align(0, 0.5)
            :settext("MS")
            :diffuse(color("0.7,0.2,0.2,1"))
            :zoom(0.20)
      end
    },
    LoadFont("hatsukoi Bold 48px") .. {
      Name = "ValMiss",
      InitCommand = function(self)
        self:xy(162, 58)
            :align(0, 0.5)
            :settext("")
            :diffuse(BCColors.text)
            :zoom(0.24)
      end
    },

    UpdatePBCommand = function(self)
      local song = GAMESTATE:GetCurrentSong()
      local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
      local smProfile = PROFILEMAN:GetProfile(PLAYER_1)

      if not song or not steps then
        self:GetChild("PBScore"):settext("--")
        self:GetChild("PBJudgeInfo"):settext("")
        self:GetChild("PBBP"):settext("")
        self:GetChild("ValW1"):settext("")
        self:GetChild("ValW2"):settext("")
        self:GetChild("ValW3"):settext("")
        self:GetChild("ValW4"):settext("")
        self:GetChild("ValW5"):settext("")
        self:GetChild("ValMiss"):settext("")
        return
      end

      -- Load saved data from BCProfile (profile-specific storage)
      local bcProfile = nil
      local savedEntry = nil
      
      -- Validate song and steps exist
      if not song or not steps then
        self:GetChild("PBScore"):settext("--")
        self:GetChild("PBJudgeInfo"):settext("")
        self:GetChild("PBBP"):settext("")
        return
      end
      
      if LoadBCProfile and BCScoreKey and getCurRateValue then
        bcProfile = LoadBCProfile()
        local rateVal = getCurRateValue()
        local rateStr = string.format("%.2fx", rateVal)
        local key = BCScoreKey(song, steps, rateStr)
        
        if bcProfile and bcProfile.scores then
          savedEntry = bcProfile.scores[key]
          
          -- If no entry for exact key, try to find any entry for this chart
          -- Match on song dir + steps type + difficulty (ignore description and rate)
          if not savedEntry then
            local stepsType = tostring(steps:GetStepsType())
            local diff = tostring(steps:GetDifficulty())
            for k, v in pairs(bcProfile.scores) do
              -- Check if key matches song dir, steps type, and difficulty
              if string.find(k, song:GetSongDir()) 
                and string.find(k, stepsType)
                and string.find(k, diff) then
                savedEntry = v
                break
              end
            end
          end
        end
      end

      -- Get SM highscore for judgment tallies (fallback if no BC data)
      local highScore = nil
      if smProfile then
        highScore = smProfile:GetHighScoreList(song, steps):GetHighScores()[1]
      end

      local scoringSystem = BCPrefs.scoringSystem or "BC"
      local score = 0
      local scoreText = "--"
      local hasData = false

      if savedEntry then
        -- Use saved score from BCProfileData based on active scoring system
        hasData = true
        if scoringSystem == "Wife3" then
          score = (savedEntry.wife3Pct or 0) / 100
        elseif scoringSystem == "EX" then
          score = (savedEntry.exPct or 0) / 100
        elseif scoringSystem == "Simple" then
          score = (savedEntry.simplePct or 0) / 100
        elseif scoringSystem == "ComboOnly" then
          scoreText = (savedEntry.comboMax or 0) .. "x"
        else
          -- BC or default: use BC%
          score = (savedEntry.bcPct or 0) / 100
        end
        
        if scoringSystem ~= "ComboOnly" then
          scoreText = string.format("%.2f%%", score * 100)
        end
      elseif highScore then
        -- Fallback: compute from SM highscore (DP-based since SM5 only stores DP)
        local w1 = highScore:GetTapNoteScore("TapNoteScore_W1") or 0
        local w2 = highScore:GetTapNoteScore("TapNoteScore_W2") or 0
        local w3 = highScore:GetTapNoteScore("TapNoteScore_W3") or 0
        local w4 = highScore:GetTapNoteScore("TapNoteScore_W4") or 0
        local w5 = highScore:GetTapNoteScore("TapNoteScore_W5") or 0
        local miss = highScore:GetTapNoteScore("TapNoteScore_Miss") or 0
        local totalNotes = w1 + w2 + w3 + w4 + w5 + miss

        hasData = true
        if scoringSystem == "Wife3" then
          -- SM5 only stores DP, but we can use it as a reasonable approximation for Wife3
          score = highScore:GetPercentDP()
        elseif scoringSystem == "EX" then
          if totalNotes > 0 then
            local exScore = w1 * 3 + w2 * 2 + w3 * 1
            score = (exScore / (totalNotes * 3))
          end
        elseif scoringSystem == "Simple" then
          if totalNotes > 0 then
            local hits = w1 + w2 + w3 + w4 + w5
            score = hits / totalNotes
          end
        elseif scoringSystem == "ComboOnly" then
          scoreText = highScore:GetMaxCombo() .. "x"
        else
          -- BC or default: use DP percentage
          score = highScore:GetPercentDP()
        end
        
        if scoringSystem ~= "ComboOnly" then
          scoreText = string.format("%.2f%%", score * 100)
        end
      end

      self:GetChild("PBScore"):settext(scoreText)

      -- Calculate width for superscript positioning
      local scoreWidth = self:GetChild("PBScore"):GetWidth() * 0.40

      -- Get judge and scoring info from theme preferences
      local judgeInfo = BCPrefs.scoringSystem or "BC"

      local judgeActor = self:GetChild("PBJudgeInfo")
      judgeActor:settext(judgeInfo)
      judgeActor:x(scoreWidth + 6)

      -- Load saved BP from BCProfileData (if available)
      local bp = 0
      if savedEntry then
        bp = math.floor(savedEntry.rawBP or 0)
      end
      self:GetChild("PBBP"):settext(tostring(bp))

      -- Display judgment tallies from saved data or highscore
      if savedEntry then
        -- Use saved values if available
        self:GetChild("ValW1"):settext(tostring(savedEntry.w1 or ""))
        self:GetChild("ValW2"):settext(tostring(savedEntry.w2 or ""))
        self:GetChild("ValW3"):settext(tostring(savedEntry.w3 or ""))
        self:GetChild("ValW4"):settext(tostring(savedEntry.w4 or ""))
        self:GetChild("ValW5"):settext(tostring(savedEntry.w5 or ""))
        self:GetChild("ValMiss"):settext(tostring(savedEntry.miss or ""))
      elseif highScore then
        local w1 = highScore:GetTapNoteScore("TapNoteScore_W1") or 0
        local w2 = highScore:GetTapNoteScore("TapNoteScore_W2") or 0
        local w3 = highScore:GetTapNoteScore("TapNoteScore_W3") or 0
        local w4 = highScore:GetTapNoteScore("TapNoteScore_W4") or 0
        local w5 = highScore:GetTapNoteScore("TapNoteScore_W5") or 0
        local miss = highScore:GetTapNoteScore("TapNoteScore_Miss") or 0
        self:GetChild("ValW1"):settext(tostring(w1))
        self:GetChild("ValW2"):settext(tostring(w2))
        self:GetChild("ValW3"):settext(tostring(w3))
        self:GetChild("ValW4"):settext(tostring(w4))
        self:GetChild("ValW5"):settext(tostring(w5))
        self:GetChild("ValMiss"):settext(tostring(miss))
      else
        self:GetChild("ValW1"):settext("")
        self:GetChild("ValW2"):settext("")
        self:GetChild("ValW3"):settext("")
        self:GetChild("ValW4"):settext("")
        self:GetChild("ValW5"):settext("")
        self:GetChild("ValMiss"):settext("")
      end
    end
  }
}

t[#t+1] = songInfoPanel

-- Create difficulty items container
t[#t+1] = Def.ActorFrame {
  Name = "DiffContainer",
  InitCommand = function(self)
    self.items = {}
    self:xy(400, SCREEN_CENTER_Y - 80)
  end,
  OnCommand = function(self)
    -- Initialize items table in OnCommand when children exist
    local diffs = {"Beginner", "Easy", "Medium", "Hard", "Challenge", "Edit"}
    local colors = {
      Beginner = {0.40, 0.80, 0.40, 1},   -- Green
      Easy = {0.40, 0.70, 0.90, 1},       -- Blue
      Medium = {0.95, 0.85, 0.40, 1},    -- Yellow
      Hard = {0.95, 0.50, 0.30, 1},      -- Orange
      Challenge = {0.90, 0.35, 0.50, 1}, -- Red
      Edit = {0.70, 0.50, 0.90, 1}       -- Purple
    }

    for i, diffName in ipairs(diffs) do
      local item = self:GetChild("Diff" .. diffName)
      if item then
        self.items[diffName] = item
        item:y((i - 1) * 44)

        -- Set color on background
        local bg = item:GetChild("Bg")
        if bg then
          bg:diffuse(colors[diffName] or BCColors.text)
        end

        -- Set name
        local nameText = item:GetChild("Name")
        if nameText then
          nameText:settext(diffName)
        end
      end
    end

    -- Force initial update
    self:playcommand("UpdateDiffs")
    -- Delayed update to catch initial song/steps
    self:sleep(0.1):queuecommand("UpdateDiffs")
  end,
  CurrentSongChangedMessageCommand = function(self) self:playcommand("UpdateDiffs") end,
  CurrentStepsChangedMessageCommand = function(self) self:playcommand("UpdateDiffs") end,

  UpdateDiffsCommand = function(self)
    local song = GAMESTATE:GetCurrentSong()
    local currentSteps = GAMESTATE:GetCurrentSteps(PLAYER_1)

    -- Hide all first
    for diffName, item in pairs(self.items) do
      if item then
        item:visible(false)
      end
    end

    if not song then return end

    local stepsList = song:GetAllSteps()
    local diffMap = {}

    -- Group steps by difficulty
    for _, steps in ipairs(stepsList) do
      local diff = steps:GetDifficulty()
      local diffName = ToEnumShortString(diff)
      if not diffMap[diffName] then
        diffMap[diffName] = steps
      end
    end

    -- Update visibility and selection state
    local order = {"Beginner", "Easy", "Medium", "Hard", "Challenge", "Edit"}
    local visibleIndex = 0

    for _, diffName in ipairs(order) do
      local item = self.items[diffName]
      if item and diffMap[diffName] then
        visibleIndex = visibleIndex + 1
        item:visible(true)
        item:y((visibleIndex - 1) * 44)

        local isSelected = currentSteps and currentSteps:GetDifficulty() == diffMap[diffName]:GetDifficulty()

        -- Update selection indicator
        local indicator = item:GetChild("Indicator")
        if indicator then
          indicator:visible(isSelected)
        end

        -- Update background alpha
        local bg = item:GetChild("Bg")
        if bg then
          bg:diffusealpha(isSelected and 0.9 or 0.4)
        end

        -- Update text
        local nameText = item:GetChild("Name")
        if nameText then
          nameText:diffusealpha(isSelected and 1.0 or 0.7)
        end
      end
    end
  end,

  -- Beginner
  Def.ActorFrame { Name = "DiffBeginner",
    Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(140, 36):align(0.5, 0.5) end },
    Def.Quad { Name = "Indicator", InitCommand = function(self) self:setsize(4, 36):x(-70):align(0, 0.5):diffuse(Color.White):visible(false) end },
    LoadFont("hatsukoi Bold 48px") .. { Name = "Name", InitCommand = function(self) self:align(0.5, 0.5):zoom(0.35):diffuse(Color.White) end }
  },

  -- Easy
  Def.ActorFrame { Name = "DiffEasy",
    Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(140, 36):align(0.5, 0.5) end },
    Def.Quad { Name = "Indicator", InitCommand = function(self) self:setsize(4, 36):x(-70):align(0, 0.5):diffuse(Color.White):visible(false) end },
    LoadFont("hatsukoi Bold 48px") .. { Name = "Name", InitCommand = function(self) self:align(0.5, 0.5):zoom(0.35):diffuse(Color.White) end }
  },

  -- Medium
  Def.ActorFrame { Name = "DiffMedium",
    Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(140, 36):align(0.5, 0.5) end },
    Def.Quad { Name = "Indicator", InitCommand = function(self) self:setsize(4, 36):x(-70):align(0, 0.5):diffuse(Color.White):visible(false) end },
    LoadFont("hatsukoi Bold 48px") .. { Name = "Name", InitCommand = function(self) self:align(0.5, 0.5):zoom(0.35):diffuse(Color.White) end }
  },

  -- Hard
  Def.ActorFrame { Name = "DiffHard",
    Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(140, 36):align(0.5, 0.5) end },
    Def.Quad { Name = "Indicator", InitCommand = function(self) self:setsize(4, 36):x(-70):align(0, 0.5):diffuse(Color.White):visible(false) end },
    LoadFont("hatsukoi Bold 48px") .. { Name = "Name", InitCommand = function(self) self:align(0.5, 0.5):zoom(0.35):diffuse(Color.White) end }
  },

  -- Challenge
  Def.ActorFrame { Name = "DiffChallenge",
    Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(140, 36):align(0.5, 0.5) end },
    Def.Quad { Name = "Indicator", InitCommand = function(self) self:setsize(4, 36):x(-70):align(0, 0.5):diffuse(Color.White):visible(false) end },
    LoadFont("hatsukoi Bold 48px") .. { Name = "Name", InitCommand = function(self) self:align(0.5, 0.5):zoom(0.35):diffuse(Color.White) end }
  },

  -- Edit
  Def.ActorFrame { Name = "DiffEdit",
    Def.Quad { Name = "Bg", InitCommand = function(self) self:setsize(140, 36):align(0.5, 0.5) end },
    Def.Quad { Name = "Indicator", InitCommand = function(self) self:setsize(4, 36):x(-70):align(0, 0.5):diffuse(Color.White):visible(false) end },
    LoadFont("hatsukoi Bold 48px") .. { Name = "Name", InitCommand = function(self) self:align(0.5, 0.5):zoom(0.35):diffuse(Color.White) end }
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

return t
