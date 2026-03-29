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

-- Get stats once
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)

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
    OnCommand = function(self)
      local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
      local song = GAMESTATE:GetCurrentSong()
      if steps and song then
        local diff = steps:GetDifficulty()
        local diffName = ToEnumShortString(diff)
        local stars = steps:GetMeter()
        local ratingTable = nil
        if BCGetRating then
          ratingTable = BCGetRating(steps, song)
          stars = type(ratingTable) == "table" and ratingTable.Overall or ratingTable or stars
        end
        local color = BCColors.perfect
        if BCGetRatingColor then
          color = BCGetRatingColor(stars)
        end

        -- Background pill
        self:AddChild(Def.Quad {
          InitCommand = function(q)
            q:setsize(140, 28)
                :align(0.5, 0.5)
                :diffuse(color)
          end
        })

        -- Difficulty text
        self:AddChild(LoadFont("hatsukoi 48px") .. {
          InitCommand = function(txt)
            txt:settext(diffName .. " " .. string.format("%.2f★", stars))
                :diffuse(BCColors.text)
                :zoom(0.34)
          end
        })
      end
    end
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
      -- Get grade from BC% (or Wife3% if that mode is active)
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
          -- Spring overshoot
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
        if pss then
          local dp = pss:GetPercentDancePoints() * 100
          self:settext(string.format("DP: %.2f%%", dp))
        end
      end
    }
  },

  -- Judgment Breakdown
  Def.ActorFrame {
    InitCommand = function(self)
      self:y(110)
    end,
    OnCommand = function(self)
      if not pss then return end

      local counts = {
        w1 = pss:GetTapNoteScores('TapNoteScore_W1'),
        w2 = pss:GetTapNoteScores('TapNoteScore_W2'),
        w3 = pss:GetTapNoteScores('TapNoteScore_W3'),
        w4 = pss:GetTapNoteScores('TapNoteScore_W4'),
        w5 = pss:GetTapNoteScores('TapNoteScore_W5'),
        ms = pss:GetTapNoteScores('TapNoteScore_Miss'),
      }
      local maxCombo = pss:GetMaxCombo()

      local labels = {
        { "Marvelous", counts.w1, BCColors.marvelous },
        { "Perfect",   counts.w2, BCColors.perfect },
        { "Great",     counts.w3, BCColors.great },
        { "Good",      counts.w4, BCColors.good },
        { "Bad",       counts.w5, BCColors.bad },
        { "Miss",      counts.ms, BCColors.miss },
        { "Max Combo", maxCombo,  BCColors.accent },
      }

      local xOffset = -150
      for i, data in ipairs(labels) do
        local label, count, color = data[1], data[2], data[3]

        -- Label
        self:AddChild(LoadFont("hatsukoi 48px") .. {
          InitCommand = function(txt)
            txt:xy(xOffset, (i-1) * 22)
                :align(0, 0.5)
                :settext(label)
                :diffuse(color)
                :zoom(0.298)
          end
        })

        -- Count (animated)
        self:AddChild(LoadFont("hatsukoi 24px") .. {
          InitCommand = function(txt)
            txt:xy(xOffset + 120, (i-1) * 22)
                :align(1, 0.5)
                :settext("0")
                :diffuse(BCColors.text)
                :zoom(0.34)
          end,
          OnCommand = function(txt)
            local current = 0
            local target = count
            local duration = 1.0
            local steps = 30
            local stepTime = duration / steps
            local increment = target / steps

            txt:sleep(0.5 + i * 0.05)

            for s = 1, steps do
              txt:sleep(stepTime)
                   :queuecommand("Increment")
            end

            txt.SetCountCommand = function(subself)
              current = math.min(target, current + increment)
              subself:settext(math.floor(current))
            end
          end,
          IncrementCommand = function(txt)
            txt:playcommand("SetCount")
          end
        })
      end
    end
  },

  -- Life graph placeholder (would go here if enabled)
  -- SM5 provides GetLifeRecord for this

  -- Footer buttons info
  LoadFont("hatsukoi 24px") .. {
    InitCommand = function(self)
      self:y(180)
          :settext("Enter: Retry  |  ←: Song Select  |  Esc: Quit")
          :diffuse(BCColors.textMuted)
          :zoom(0.298)
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

    -- Life line (simple representation)
    Def.ActorMultiVertex {
      OnCommand = function(self)
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
-- Footer buttons (visual representation)
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(SCREEN_CENTER_X, SCREEN_HEIGHT - 50)
  end,

  -- Retry button
  Def.ActorFrame {
    InitCommand = function(self)
      self:x(-120)
    end,

    Def.Quad {
      InitCommand = function(self)
        self:setsize(100, 36)
            :diffuse(BCColors.accent)
            :diffusealpha(0.3)
      end
    },

    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self)
        self:settext("Retry")
            :diffuse(BCColors.text)
            :zoom(0.383)
      end
    }
  },

  -- Song Select button
  Def.ActorFrame {
    InitCommand = function(self)
    end,

    Def.Quad {
      InitCommand = function(self)
        self:setsize(120, 36)
            :diffuse(BCColors.panel)
      end
    },

    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self)
        self:settext("Song Select")
            :diffuse(BCColors.text)
            :zoom(0.383)
      end
    }
  },

  -- Quit button
  Def.ActorFrame {
    InitCommand = function(self)
      self:x(140)
    end,

    Def.Quad {
      InitCommand = function(self)
        self:setsize(80, 36)
            :diffuse(BCColors.panel)
            :diffusealpha(0.5)
      end
    },

    LoadFont("hatsukoi 48px") .. {
      InitCommand = function(self)
        self:settext("Quit")
            :diffuse(BCColors.textMuted)
            :zoom(0.383)
      end
    }
  }
}

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
    self:decelerate(0.5)
        :diffusealpha(0)
  end,
  OffCommand = function(self)
    self:accelerate(0.3)
        :diffusealpha(1)
  end
}

return t
