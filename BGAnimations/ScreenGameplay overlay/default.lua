-- Blossom Candy Theme - Gameplay HUD Overlay
-- File: BGAnimations/ScreenGameplay overlay/default.lua
-- Note: SM5 renders the notefield itself — this handles the HUD only

local t = Def.ActorFrame {}

-- Current life value (tracked via LifeChangedMessageCommand)
local currentLife = 1.0

-- ============================================================================
-- Progress Bar (top edge, full width)
-- ============================================================================
t[#t+1] = Def.Quad {
  Name = "ProgressBar",
  InitCommand = function(self)
    self:xy(0, 1)
        :setsize(SCREEN_WIDTH, 2)
        :align(0, 0)
        :diffuse(BCColors.accent)
        :diffusealpha(0.7)
  end
}

-- Progress bar fill (grows as song progresses)
t[#t+1] = Def.Quad {
  Name = "ProgressFill",
  InitCommand = function(self)
    self:xy(0, 1)
        :setsize(0, 2)
        :align(0, 0)
        :diffuse(BCColors.perfect)
  end,
  OnCommand = function(self)
    self:playcommand("Update")
  end,
  UpdateCommand = function(self)
    local song = GAMESTATE:GetCurrentSong()
    if song then
      local songLen = song:GetLastSecond()
      local curSecs = GAMESTATE:GetCurMusicSeconds()
      local progress = math.min(1, math.max(0, curSecs / songLen))
      self:setsize(SCREEN_WIDTH * progress, 2)
    end
    self:sleep(0.05)
        :queuecommand("Update")
  end
}

-- ============================================================================
-- Score / Accuracy Display (top-right corner)
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(SCREEN_WIDTH - 20, 30)
  end,

  -- Panel background
  Def.Quad {
    InitCommand = function(self)
      self:setsize(180, 60)
          :align(1, 0)
          :diffuse(BCColors.panel)
    end
  },

  -- BlossomCandy Score (primary display)
  LoadFont("hatsukoi 48px") .. {
    Name = "BCScore",
    InitCommand = function(self)
      self:xy(-90, 18)
          :align(0.5, 0.5)
          :settext("0.0000%")
          :diffuse(BCColors.text)
          :zoom(0.51)
    end,
    OnCommand = function(self)
      self:playcommand("Update")
    end,
    UpdateCommand = function(self)
      local pct = BCState:GetPercent()
      self:settext(string.format("%.4f%%", pct))
      self:sleep(0.033)  -- ~30fps update
          :queuecommand("Update")
    end
  },

  -- DP% label (secondary)
  LoadFont("hatsukoi 24px") .. {
    Name = "DPScore",
    InitCommand = function(self)
      self:xy(-90, 42)
          :align(0.5, 0.5)
          :settext("DP: 0.00%")
          :diffuse(BCColors.textMuted)
          :zoom(0.34)
    end,
    OnCommand = function(self)
      self:playcommand("Update")
    end,
    UpdateCommand = function(self)
      local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
      if pss then
        local dp = pss:GetPercentDancePoints() * 100
        self:settext(string.format("DP: %.2f%%", dp))
      end
      self:sleep(0.1)
          :queuecommand("Update")
    end
  }
}

-- ============================================================================
-- Judgment Display (center screen)
-- ============================================================================
t[#t+1] = Def.Sprite {
  Texture = "../../Graphics/KanmojiJudgments 2x6.png",
  Name = "Judgment",
  InitCommand = function(self)
    self:Center()
        :y(SCREEN_CENTER_Y + 80)
        :animate(false)
        :zoom(0.45)
        :diffusealpha(0)
  end,
  JudgmentMessageCommand = function(self, param)
    -- Handle Hold/Roll drops (scoring only, no sprite)
    if param.HoldNoteScore then
      local hns = param.HoldNoteScore
      -- LetGo = dropped hold/roll
      if hns == 'HoldNoteScore_LetGo' then
        BCState:AddHoldRollDrop()
        Wife3State:AddHoldRollDrop()
        EXState:AddHoldRollDrop()
        SimpleState:AddHoldRollDrop()
      end
      return
    end
    
    -- Handle Mines (scoring only, no sprite)
    if param.TapNoteScore == 'TapNoteScore_HitMine' then
      BCState:AddMineHit()
      Wife3State:AddMineHit()
      EXState:AddMineHit()
      SimpleState:AddMineHit()
      return
    end
    
    -- AvoidMine = successfully avoided, no score impact
    if param.TapNoteScore == 'TapNoteScore_AvoidMine' then
      return
    end
    
    if param.Player ~= PLAYER_1 then return end

    local rowMap = {
      TapNoteScore_W1 = 0,
      TapNoteScore_W2 = 1,
      TapNoteScore_W3 = 2,
      TapNoteScore_W4 = 3,
      TapNoteScore_W5 = 4,
      TapNoteScore_Miss = 5,
    }
    local row = rowMap[param.TapNoteScore] or 5
    
    -- Left Column (0) = Early, Right Column (1) = Late
    -- For Marvelous (W1), always show center style or use offset if available
    local col = 1  -- default to late/right
    if param.TapNoteOffset ~= nil then
      if param.TapNoteOffset < 0 then
        col = 0  -- early/left
      else
        col = 1  -- late/right
      end
    end

    self:setstate(row * 2 + col)
        :finishtweening()
        :zoom(0.65)
        :diffusealpha(1)
        :decelerate(0.1)
        :zoom(0.5)
        :decelerate(0.5)
        :addy(-15)
        :diffusealpha(0)
        :addy(15)  -- reset position

    -- Accumulate BlossomCandy Score
    local isMiss = (param.TapNoteScore == 'TapNoteScore_Miss')
    BCState:AddJudgment(param.TapNoteOffset, isMiss)
    Wife3State:AddJudgment(param.TapNoteOffset, isMiss)
    EXState:AddJudgment(param.TapNoteScore)
    SimpleState:AddJudgment(param.TapNoteScore)

    -- Collect offset data for evaluation screen scatter plot
    if not isMiss and param.TapNoteOffset ~= nil then
      local noteTime = param.NoteStartTime or GAMESTATE:GetCurMusicSeconds()
      table.insert(BCHitOffsets, {
        time = noteTime,
        offset = param.TapNoteOffset * 1000,  -- convert to ms
        judgment = param.TapNoteScore
      })
    end
  end
}

-- ============================================================================
-- Combo Counter (below judgment)
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  Name = "ComboDisplay",
  InitCommand = function(self)
    self:Center()
        :y(SCREEN_CENTER_Y + 120)
        :diffusealpha(0)
  end,

  -- Combo number
  LoadFont("hatsukoi Bold 48px") .. {
    Name = "ComboNumber",
    InitCommand = function(self)
      self:align(0.5, 0.5)
          :settext("0")
          :diffuse(1, 1, 1, 1)
          :zoom(0.5)
    end,
    JudgmentMessageCommand = function(self, param)
      -- Handle Hold/Roll drops - update combo display
      if param.HoldNoteScore then
        local hns = param.HoldNoteScore
        if hns == 'HoldNoteScore_LetGo' then
          local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
          if pss then
            local combo = pss:GetCurrentCombo()
            self:settext(tostring(combo))
                :diffuse(1, 1, 1, 1)
          end
        end
        return
      end
      
      -- Skip mines for combo display
      if param.TapNoteScore == 'TapNoteScore_HitMine' or 
         param.TapNoteScore == 'TapNoteScore_AvoidMine' then
        return
      end
      
      if param.Player ~= PLAYER_1 then return end

      local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
      if pss then
        local combo = pss:GetCurrentCombo()
        self:settext(tostring(combo))

        -- Color: white → lavender at 100+ → soft pink at 500+
        if combo >= 500 then
          self:diffuse(1, 0.75, 0.85, 1)  -- soft pink
        elseif combo >= 100 then
          self:diffuse(BCColors.perfect)
        else
          self:diffuse(1, 1, 1, 1)  -- white
        end

        -- Scale bump on combo hit
        if combo > 0 and param.TapNoteScore ~= 'TapNoteScore_Miss' then
          self:finishtweening()
              :zoom(0.6)
              :decelerate(0.1)
              :zoom(0.5)
        end
      end
    end
  },

  -- Milestone indicator (✦ crown)
  LoadFont("hatsukoi 48px") .. {
    Name = "Milestone",
    InitCommand = function(self)
      self:y(-25)
          :settext("✦")
          :diffuse(1, 0.92, 0.6, 1)
          :zoom(0.3)
          :diffusealpha(0)
    end,
    JudgmentMessageCommand = function(self, param)
      -- Handle Hold/Roll drops - hide milestone on combo break
      if param.HoldNoteScore then
        local hns = param.HoldNoteScore
        if hns == 'HoldNoteScore_LetGo' then
          self:diffusealpha(0)
        end
        return
      end
      
      -- Skip mines for milestone display
      if param.TapNoteScore == 'TapNoteScore_HitMine' or 
         param.TapNoteScore == 'TapNoteScore_AvoidMine' then
        return
      end
      
      if param.Player ~= PLAYER_1 then return end

      if param.TapNoteScore == 'TapNoteScore_Miss' then
        self:diffusealpha(0)  -- Hide on miss
        return
      end

      local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
      if pss then
        local combo = pss:GetCurrentCombo()
        -- Show at milestones: 100, 200, 500, 1000
        if combo == 100 or combo == 200 or combo == 500 or combo == 1000 then
          self:finishtweening()
              :diffusealpha(1)
              :zoom(0.45)
              :decelerate(0.2)
              :zoom(0.3)
        end
      end
    end
  }
}

-- ============================================================================
-- Health Bar (bottom-left)
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(30, SCREEN_HEIGHT - 50)
  end,

  -- Health bar background
  Def.Quad {
    InitCommand = function(self)
      self:setsize(200, 20)
          :align(0, 0.5)
          :diffuse(0.3, 0.3, 0.35, 0.5)
    end
  },

  -- Health fill (gradient: mint → lavender → blush pink)
  Def.Quad {
    Name = "HealthFill",
    InitCommand = function(self)
      self:setsize(200, 20)
          :align(0, 0.5)
          :diffuse(BCColors.great)  -- start mint
    end,
    LifeChangedMessageCommand = function(self, param)
      if param.Player ~= PLAYER_1 then return end

      local life = param.LifeMeter:GetLife()
      currentLife = life

      -- Update width
      self:setsize(200 * life, 20)

      -- Color: mint (full) → lavender (mid) → blush pink (low)
      if life > 0.5 then
        local t = (1 - life) * 2  -- 0 to 1
        self:diffuse(
          0.72 + (0.80 - 0.72) * t,
          0.94 + (0.72 - 0.94) * t,
          0.82 + (0.96 - 0.82) * t,
          1
        )
      else
        local t = (0.5 - life) * 2  -- 0 to 1
        self:diffuse(
          0.80 + (1 - 0.80) * t,
          0.72 + (0.75 - 0.72) * t,
          0.96 + (0.85 - 0.96) * t,
          1
        )
      end
    end
  },

  -- Low health warning (pulse when < 25%)
  Def.Quad {
    InitCommand = function(self)
      self:setsize(200, 20)
          :align(0, 0.5)
          :diffuse(BCColors.miss)
          :diffusealpha(0)
          :blend("BlendMode_Add")
    end,
    OnCommand = function(self)
      self:playcommand("Pulse")
    end,
    PulseCommand = function(self)
      if currentLife < 0.25 then
        self:diffusealpha(0.3)
            :smooth(0.5)
            :diffusealpha(0.1)
            :smooth(0.5)
            :queuecommand("Pulse")
      else
        self:diffusealpha(0)
            :sleep(0.5)
            :queuecommand("Pulse")
      end
    end
  }
}

-- ============================================================================
-- Song Info (bottom-right, fades during play)
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    self:xy(SCREEN_WIDTH - 30, SCREEN_HEIGHT - 30)
  end,

  LoadFont("hatsukoi 24px") .. {
    Name = "SongInfo",
    InitCommand = function(self)
      self:align(1, 1)
          :maxwidth(300)
          :settext("")
          :diffuse(BCColors.textMuted)
          :diffusealpha(0.6)
          :zoom(0.34)
    end,
    OnCommand = function(self)
      local song = GAMESTATE:GetCurrentSong()
      if song then
        local title = song:GetDisplayMainTitle()
        local artist = song:GetDisplayArtist()
        self:settext(title .. " / " .. artist)
      end
      -- Fade down after song starts
      self:sleep(2)
          :decelerate(1)
          :diffusealpha(0.3)
    end
  }
}

-- ============================================================================
-- Miss tint effect (gentle warm tint on miss)
-- ============================================================================
t[#t+1] = Def.Quad {
  InitCommand = function(self)
    self:FullScreen()
        :diffuse(BCColors.miss)
        :diffusealpha(0)
        :blend("BlendMode_Add")
  end,
  JudgmentMessageCommand = function(self, param)
    if param.HoldNoteScore then return end
    if param.Player ~= PLAYER_1 then return end

    if param.TapNoteScore == 'TapNoteScore_Miss' then
      self:finishtweening()
          :diffusealpha(0.08)
          :decelerate(0.3)
          :diffusealpha(0)
    end
  end
}

-- ============================================================================
-- Song Started / Ended hooks
-- ============================================================================
t[#t+1] = Def.ActorFrame {
  InitCommand = function(self)
    -- Reset immediately on screen init (before SongStarted fires)
    BCResetAllAccumulators()
  end,
  
  SongStartedMessageCommand = function(self)
    -- Reset all accumulators
    BCResetAllAccumulators()
    currentLife = 1.0
  end,

  SongFinishedMessageCommand = function(self)
    -- Store max combo for ComboOnly mode
    local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
    if pss then
      ComboOnlyState:SetMaxCombo(pss:GetMaxCombo())
    end
  end
}

return t
