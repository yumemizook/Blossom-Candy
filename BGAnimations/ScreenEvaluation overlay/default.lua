-- Blossom Candy Theme - Evaluation Screen
-- File: BGAnimations/ScreenEvaluation overlay/default.lua

local t = Def.ActorFrame {}

-- Background
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:FullScreen()
        :diffuse(BCColors.background)
  end
}

-- Helper to get stats at runtime (not file load)
local function GetPlayerStageStats()
  local stageStats = STATSMAN:GetCurStageStats()
  if stageStats then
    return stageStats:GetPlayerStageStats(PLAYER_1)
  end
  return nil
end

-- ============================================================================
-- Main Evaluation Card (centered)
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:Center()
        :diffusealpha(0)
  end,
  OnCommand = function(self)
    self:decelerate(0.5)
        :diffusealpha(1)
  end,

  -- Card background
  Def.Quad {
    InitCommand = function(self)
      self:setsize(500, 420)
          :align(0.5, 0.5)
          :diffuse(BCColors.panel)
    end
  },

  -- Header: Song title + artist
  LoadFont("hatsukoi Bold 48px") .. {
    Name = "SongTitle",
    InitCommand = function(self)
      self:y(-180)
          :maxwidth(460)
          :settext("")
          :diffuse(BCColors.text)
          :zoom(0.51)
    end,
    OnCommand = function(self)
      local song = GAMESTATE:GetCurrentSong()
      if song then
        self:settext(song:GetDisplayMainTitle())
      end
    end
  },

  LoadFont("hatsukoi 48px") .. {
    Name = "Artist",
    InitCommand = function(self)
      self:y(-155)
          :maxwidth(460)
          :settext("")
          :diffuse(BCColors.textMuted)
          :zoom(0.34)
    end,
    OnCommand = function(self)
      local song = GAMESTATE:GetCurrentSong()
      if song then
        self:settext(song:GetDisplayArtist())
      end
    end
  },

  -- Difficulty pill
  Def.ActorFrame {
    InitCommand = function(self)
      self:y(-120)
    end,

    -- Background pill
    Def.Quad {
      Name = "DiffBG",
      InitCommand = function(self)
        self:setsize(140, 28)
            :align(0.5, 0.5)
            :diffuse(BCColors.panel)
      end,
      OnCommand = function(self)
        local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
        local song = GAMESTATE:GetCurrentSong()
        if steps and song then
          local stars = steps:GetMeter()
          if BCGetRating then
            local ratingTable = BCGetRating(steps, song)
            stars = type(ratingTable) == "table" and ratingTable.Overall or ratingTable or stars
          end
          local color = BCColors.perfect
          if BCGetRatingColor then
            color = BCGetRatingColor(stars)
          end
          self:diffuse(color)
        end
      end
    },

    -- Difficulty text
    LoadFont("hatsukoi 48px") .. {
      Name = "DiffText",
      InitCommand = function(self)
        self:settext("")
            :diffuse(BCColors.text)
            :zoom(0.34)
      end,
      OnCommand = function(self)
        local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
        local song = GAMESTATE:GetCurrentSong()
        if steps and song then
          local diff = steps:GetDifficulty()
          local diffName = ToEnumShortString(diff)
          local stars = steps:GetMeter()
          if BCGetRating then
            local ratingTable = BCGetRating(steps, song)
            stars = type(ratingTable) == "table" and ratingTable.Overall or ratingTable or stars
          end
          self:settext(diffName .. " " .. string.format("%.2f★", stars))
        end
      end
    }
  },

  -- Grade Display (large)
  LoadFont("hatsukoi Bold 48px") .. {
    Name = "GradeLabel",
    InitCommand = function(self)
      self:y(-50)
          :settext("")
          :zoom(1.275)
          :diffusealpha(0)
    end,
    OnCommand = function(self)
      local pct = BCState:GetPercent()
      local label, color = BCGradeFromPercent(pct)

      self:settext(label)
          :diffuse(color)
          :finishtweening()
          :zoom(0.68)
          :diffusealpha(0)
          :sleep(0.3)
          :decelerate(0.35)
          :zoom(1.275)
          :diffusealpha(1)
          :decelerate(0.15)
          :zoom(0.884)
          :decelerate(0.1)
          :zoom(0.85)
    end
  },

  -- Score section
  Def.ActorFrame {
    InitCommand = function(self)
      self:y(40)
    end,

    -- BlossomCandy Score
    LoadFont("hatsukoi 48px") .. {
      Name = "BCScore",
      InitCommand = function(self)
        self:y(-20)
            :settext("0.0000%")
            :diffuse(BCColors.text)
            :zoom(0.595)
      end,
      OnCommand = function(self)
        local pct = BCState:GetPercent()
        self:settext(string.format("%.4f%%", pct))
      end
    },

    -- Score label
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self)
        self:y(-45)
            :settext("BlossomCandy Score")
            :diffuse(BCColors.textMuted)
            :zoom(0.298)
      end
    },

    -- DP Score (secondary)
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self)
        self:y(20)
            :settext("DP: 0.00%")
            :diffuse(BCColors.textMuted)
            :zoom(0.425)
      end,
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if pss then
          local dp = pss:GetPercentDancePoints() * 100
          self:settext(string.format("DP: %.2f%%", dp))
        end
      end
    }
  },

  -- BC Rating section (Bloom Rating + Player Tier)
  Def.ActorFrame {
    InitCommand = function(self)
      self:y(110)
    end,

    -- Chart Bloom Rating label
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 0):align(0, 0.5):zoom(0.298):settext("Bloom Rating"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 24px") .. {
      Name = "BloomRating",
      InitCommand = function(self) self:xy(-30, 0):align(1, 0.5):settext("0.0★"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
        local song = GAMESTATE:GetCurrentSong()
        if steps and song and BCGetRating then
          local ratingTable = BCGetRating(steps, song)
          local bloomRating = ratingTable and ratingTable.Overall or steps:GetMeter()
          self:settext(string.format("%.2f★", bloomRating))
        end
      end
    },

    -- Player BP Tier label
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 22):align(0, 0.5):zoom(0.298):settext("Player Tier"):diffuse(BCColors.textMuted) end
    },
    LoadFont("hatsukoi 24px") .. {
      Name = "PlayerTier",
      InitCommand = function(self) self:xy(-30, 22):align(1, 0.5):settext("Seed"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        if LoadBCProfile and BCTierFromTotal then
          local profile = LoadBCProfile()
          local tierName, tierColor = BCTierFromTotal(profile.totalBP)
          self:settext(tierName):diffuse(tierColor or BCColors.text)
        end
      end
    }
  },

  -- Judgment Breakdown
  Def.ActorFrame {
    InitCommand = function(self)
      self:y(154)
    end,

    -- Label row 1: Marvelous
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 0):align(0, 0.5):zoom(0.298):settext("Marvelous"):diffuse(BCColors.marvelous) end
    },
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self) self:xy(-30, 0):align(1, 0.5):settext("0"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if not pss then return end
        local target = pss:GetTapNoteScores('TapNoteScore_W1')
        self:sleep(0.5):linear(1):settext(tostring(target))
      end
    },

    -- Label row 2: Perfect
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 22):align(0, 0.5):zoom(0.298):settext("Perfect"):diffuse(BCColors.perfect) end
    },
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self) self:xy(-30, 22):align(1, 0.5):settext("0"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if not pss then return end
        local target = pss:GetTapNoteScores('TapNoteScore_W2')
        self:sleep(0.55):linear(1):settext(tostring(target))
      end
    },

    -- Label row 3: Great
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 44):align(0, 0.5):zoom(0.298):settext("Great"):diffuse(BCColors.great) end
    },
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self) self:xy(-30, 44):align(1, 0.5):settext("0"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if not pss then return end
        local target = pss:GetTapNoteScores('TapNoteScore_W3')
        self:sleep(0.6):linear(1):settext(tostring(target))
      end
    },

    -- Label row 4: Good
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 66):align(0, 0.5):zoom(0.298):settext("Good"):diffuse(BCColors.good) end
    },
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self) self:xy(-30, 66):align(1, 0.5):settext("0"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if not pss then return end
        local target = pss:GetTapNoteScores('TapNoteScore_W4')
        self:sleep(0.65):linear(1):settext(tostring(target))
      end
    },

    -- Label row 5: Bad
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 88):align(0, 0.5):zoom(0.298):settext("Bad"):diffuse(BCColors.bad) end
    },
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self) self:xy(-30, 88):align(1, 0.5):settext("0"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if not pss then return end
        local target = pss:GetTapNoteScores('TapNoteScore_W5')
        self:sleep(0.7):linear(1):settext(tostring(target))
      end
    },

    -- Label row 6: Miss
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 110):align(0, 0.5):zoom(0.298):settext("Miss"):diffuse(BCColors.miss) end
    },
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self) self:xy(-30, 110):align(1, 0.5):settext("0"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if not pss then return end
        local target = pss:GetTapNoteScores('TapNoteScore_Miss')
        self:sleep(0.75):linear(1):settext(tostring(target))
      end
    },

    -- Label row 7: Max Combo
    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self) self:xy(-150, 132):align(0, 0.5):zoom(0.298):settext("Max Combo"):diffuse(BCColors.accent) end
    },
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self) self:xy(-30, 132):align(1, 0.5):settext("0"):diffuse(BCColors.text):zoom(0.34) end,
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if pss == nil then return end
        local maxComboFn = pss.GetMaxCombo
        if maxComboFn == nil then return end
        local target = maxComboFn(pss) or 0
        self:sleep(0.8):linear(1):settext(tostring(target))
      end
    }
  }
}

  -- Offset Scatter Plot (right side)
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(SCREEN_CENTER_X + 320, SCREEN_CENTER_Y)
        :diffusealpha(0)
  end,
  OnCommand = function(self)
    self:decelerate(0.6)
        :diffusealpha(1)
  end,

  -- Plot label
  LoadFont("hatsukoi 24px") .. {
    InitCommand = function(self)
      self:y(-70)
          :settext("Hit Timing")
          :diffuse(BCColors.textMuted)
          :zoom(0.298)
    end
  },

  -- Plot background
  Def.Quad {
    InitCommand = function(self)
      self:setsize(240, 120)
          :align(0.5, 0.5)
          :diffuse(0, 0, 0, 0.2)
    end
  },

  -- Center line (perfect timing)
  Def.Quad {
    InitCommand = function(self)
      self:setsize(240, 1)
          :align(0.5, 0.5)
          :diffuse(BCColors.textMuted)
          :diffusealpha(0.3)
    end
  },

  -- Offset points
  Def.ActorMultiVertex {
    Name = "OffsetPlot",
    InitCommand = function(self)
      self:SetDrawState({ Mode = "DrawMode_Quads" })
    end,
    OnCommand = function(self)
      local song = GAMESTATE:GetCurrentSong()
      if not song then return end

      local songLen = song:GetLastSecond()
      if songLen <= 0 then return end

      -- Get judgment colors
      local colors = {
        TapNoteScore_W1 = BCColors.marvelous,
        TapNoteScore_W2 = BCColors.perfect,
        TapNoteScore_W3 = BCColors.great,
        TapNoteScore_W4 = BCColors.good,
        TapNoteScore_W5 = BCColors.bad
      }

      local verts = {}
      local plotWidth = 220
      local plotHeight = 100
      local maxOffsetMs = 100  -- ±100ms range

      -- Build vertices for each hit (small quads as dots)
      if BCHitOffsets and #BCHitOffsets > 0 then
        for _, hit in ipairs(BCHitOffsets) do
          local x = (hit.time / songLen) * plotWidth - plotWidth / 2
          local y = (hit.offset / maxOffsetMs) * (plotHeight / 2)
          y = math.max(-plotHeight/2 + 2, math.min(plotHeight/2 - 2, y))  -- clamp to plot bounds

          local color = colors[hit.judgment] or BCColors.text
          local dotSize = 2

          -- Create a small quad for each point
          table.insert(verts, { { x - dotSize, y - dotSize, 0 }, color })
          table.insert(verts, { { x + dotSize, y - dotSize, 0 }, color })
          table.insert(verts, { { x + dotSize, y + dotSize, 0 }, color })
          table.insert(verts, { { x - dotSize, y + dotSize, 0 }, color })
        end
      end

      if #verts > 0 then
        self:SetVertices(verts)
      end
    end
  }
}

-- ============================================================================
-- Life Graph (if enabled in prefs)
-- ============================================================================
if BCGetPref("showLifeGraph") then
  t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
      self:xy(SCREEN_WIDTH - 150, SCREEN_CENTER_Y + 100)
          :diffusealpha(0)
    end,
    OnCommand = function(self)
      self:decelerate(0.6)
          :diffusealpha(1)
    end,

    -- Graph label
    LoadFont("hatsukoi 24px") .. {
      InitCommand = function(self)
        self:y(-60)
            :settext("Life Graph")
            :diffuse(BCColors.textMuted)
            :zoom(0.298)
      end
    },

    -- Graph background
    Def.Quad {
      InitCommand = function(self)
        self:setsize(200, 80)
            :align(0.5, 0.5)
            :diffuse(0, 0, 0, 0.2)
      end
    },

    -- Life line
    Def.ActorMultiVertex {
      OnCommand = function(self)
        local pss = GetPlayerStageStats()
        if not pss then return end

        local song = GAMESTATE:GetCurrentSong()
        if not song then return end

        local songLen = song:GetLastSecond()
        local lifeRecord = pss:GetLifeRecord(64, songLen)

        if lifeRecord and #lifeRecord > 0 then
          local verts = {}
          local width = 180
          local height = 60
          local stepX = width / (#lifeRecord - 1)

          for i, life in ipairs(lifeRecord) do
            local x = (i - 1) * stepX - width / 2
            local y = (1 - life) * height - height / 2
            table.insert(verts, { { x, y, 0 }, BCColors.great })
          end

          self:SetDrawState({ Mode = "DrawMode_LineStrip" })
              :SetVertices(verts)
        end
      end
    }
  }
end

-- ============================================================================
-- Transition overlay
-- ============================================================================
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:FullScreen()
        :diffuse(BCColors.background)
        :diffusealpha(1)
  end,
  OnCommand = function(self)
    -- Save BP to profile after song completion
    if UpdateBCProfile then
      UpdateBCProfile()
    end
    self:decelerate(0.5)
        :diffusealpha(0)
  end,
  OffCommand = function(self)
    self:accelerate(0.3)
        :diffusealpha(1)
  end
}

return t
