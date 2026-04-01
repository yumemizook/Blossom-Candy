-- Blossom Candy Theme - Blossom Points (BP) System
-- Auto-loaded globally at startup
-- Profile-level performance metric derived from best scores

local BP_SCALE     = 7.8    -- tuned so 10★ at 99% ≈ 1000 raw BP
local BP_BASELINE  = 0.94   -- A− threshold: accuracyFactor = 1.0 here
local BP_CURVE_K   = 5.0    -- exponential steepness

-- ============================================================================
-- Accuracy Factor Calculation
-- ============================================================================

local function AccuracyFactor(bcPct)
  -- e^(k × (bc/100 − baseline))
  -- At A− (94%): factor = 1.0
  -- Above 94%:   factor > 1.0 (bonus)
  -- Below 94%:   factor < 1.0 (penalty)
  return math.exp(BP_CURVE_K * (bcPct / 100 - BP_BASELINE))
end

-- ============================================================================
-- Minimum BC% Threshold Gating
-- ============================================================================

function MinimumBC(bloomRating)
  -- Linear: 60 + 2.5 × rating, capped at 90 for extreme charts
  return math.min(90.0, 60.0 + 2.5 * bloomRating)
end

-- ============================================================================
-- Raw BP Calculation
-- ============================================================================

function ComputeRawBP(bloomRating, bcPct)
  local minBC = MinimumBC(bloomRating)
  if bcPct < minBC then
    return 0  -- below threshold: no BP awarded
  end
  return (bloomRating ^ 2) * AccuracyFactor(bcPct) * BP_SCALE
end

-- ============================================================================
-- Profile Total BP with Decay Weighting
-- ============================================================================

function ComputeTotalBP(rawBPList)
  -- rawBPList: table of raw BP values, sorted descending
  -- Only best score per chart-rate combo should be included (deduplication upstream)
  table.sort(rawBPList, function(a, b) return a > b end)

  local total   = 0
  local decay   = 0.95

  for i, bp in ipairs(rawBPList) do
    total = total + bp * (decay ^ (i - 1))
  end

  return total
end

-- ============================================================================
-- Bloom Tiers (13 tiers - graduated floral progression)
-- ============================================================================

BCTiers = {
  { 40000, "Eternal Bloom", "gradeBlossom" },
  {  30000, "Ethereal",      "gradeSPlus"   },
  {  20000, "Luminous",      "gradeS"       },
  {  15000, "Radiant",       "gradeA"       },
  {  10000, "Blossom",       "gradeB"       },
  {   7500, "Flourish",      "gradeC"       },
  {   5000, "Full Bloom",    "gradeD"       },
  {   3000, "Bloom",         "gradeDminus"  },
  {   2000, "Bud",           "gradeC"       },
  {   1200, "Sapling",       "gradeB"       },
  {   1000, "Seedling",      "gradeA"       },
  {    400, "Sprout",        "gradeS"       },
  {      0, "Seed",          "gradeSPlus"   },
}

function BCTierFromTotal(totalBP)
  for _, tier in ipairs(BCTiers) do
    if totalBP >= tier[1] then
      return tier[2], BCColors[tier[3]]  -- label, color
    end
  end
  return "Seed", BCColors.gradeSPlus
end

-- ============================================================================
-- Data Persistence
-- ============================================================================

-- ============================================================================
-- Rate Detection
-- ============================================================================

-- Get the current playback rate from song options
function getCurRateValue()
  local rateStr = "1.0"
  local songOpts = GAMESTATE:GetSongOptionsString()
  if songOpts then
    -- Parse rate from options string (e.g., "1.5x Music" -> "1.50")
    local rateMatch = string.match(songOpts, "(%d+%.?%d*)x")
    if rateMatch then
      rateStr = string.format("%.2f", tonumber(rateMatch) or 1.0)
    end
  end
  local rate = tonumber(rateStr) or 1.0
  return rate
end

-- ============================================================================
-- Profile Data Path (Profile-Specific)
-- ============================================================================

local function GetBCProfileDataPath()
  if PROFILEMAN then
    for _, pn in ipairs({PLAYER_1, PLAYER_2}) do
      if PROFILEMAN:IsPersistentProfile(pn) then
        local profile = PROFILEMAN:GetProfile(pn)
        if profile then
          if profile.GetProfileDir then
            local profileDir = profile:GetProfileDir()
            if profileDir and profileDir ~= "" then
              return profileDir .. "/BCProfileData.lua"
            end
          end
          if profile.GetLocalProfileID then
            local id = profile:GetLocalProfileID()
            if id then
              return "Save/LocalProfiles/" .. id .. "/BCProfileData.lua"
            end
          end
        end
      end
    end
  end
  return nil
end

-- Legacy path for migration
local LEGACY_PROFILE_PATH = "Save/BCProfileData.lua"

function LoadBCProfile()
  local path = GetBCProfileDataPath()
  Trace("Loading BCProfile from: " .. tostring(path))
  
  if path then
    local chunk = loadfile(path)
    if chunk then
      local success, result = pcall(chunk)
      if success and result then
        Trace("BCProfile loaded successfully, totalBP: " .. tostring(result.totalBP or 0))
        return result
      end
    end
    Trace("No BCProfile found at: " .. tostring(path))
  end
  
  Trace("Creating new empty BCProfile")
  return { totalBP = 0, scores = {} }
end

function SaveBCProfile(profile)
  local path = GetBCProfileDataPath()
  if not path then
    Trace("Cannot save BCProfile: no valid profile path")
    return
  end
  local f = RageFileUtil.CreateRageFile()
  if not f then return end
  if f:Open(path, 2) then  -- 2 = WRITE
    local out = "return {\n"
    out = out .. string.format("  totalBP = %.4f,\n", profile.totalBP)
    out = out .. "  scores = {\n"
    for key, entry in pairs(profile.scores) do
      out = out .. string.format(
        "    [%q] = { rawBP=%.4f, bcPct=%.4f, bloomRating=%.2f, grade=%q, rateString=%q, dpPct=%.4f, wife3Pct=%.4f, exPct=%.4f, simplePct=%.4f, comboMax=%d, w1=%d, w2=%d, w3=%d, w4=%d, w5=%d, miss=%d },\n",
        key, entry.rawBP, entry.bcPct, entry.bloomRating, entry.grade, entry.rateString,
        entry.dpPct or 0, entry.wife3Pct or 0, entry.exPct or 0, entry.simplePct or 0, entry.comboMax or 0,
        entry.w1 or 0, entry.w2 or 0, entry.w3 or 0, entry.w4 or 0, entry.w5 or 0, entry.miss or 0
      )
    end
    out = out .. "  }\n}\n"
    f:Write(out)
    f:Close()
  end
  f:destroy()
end

-- Compute the deduplication key for a score
function BCScoreKey(song, steps, rateString)
  return song:GetSongDir()
    .. "|" .. tostring(steps:GetStepsType())
    .. "|" .. tostring(steps:GetDifficulty())
    .. "|" .. (steps:GetDescription() or "")
    .. "|" .. rateString
end

-- ============================================================================
-- Profile Update After Play
-- ============================================================================

function UpdateBCProfile()
  local profile    = LoadBCProfile()
  local song       = GAMESTATE:GetCurrentSong()
  local steps      = GAMESTATE:GetCurrentSteps(PLAYER_1)
  if not song or not steps then return end

  local rateStr    = string.format("%.2fx", getCurRateValue and getCurRateValue() or 1.0)
  local key        = BCScoreKey(song, steps, rateStr)

  -- Get Bloom Rating from BCGetRating (uses cache)
  local bloomRating = steps:GetMeter()
  if BCGetRating then
    local ratingTable = BCGetRating(steps, song)
    bloomRating = type(ratingTable) == "table" and ratingTable.Overall or ratingTable or bloomRating
  end

  local bcPct      = BCState:GetPercent()
  local rawBP      = ComputeRawBP(bloomRating, bcPct)
  local grade      = BCGradeFromPercent(bcPct)

  -- Get percentages from all scoring systems
  local dpPct      = 0
  local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(PLAYER_1)
  if pss then
    dpPct = pss:GetPercentDancePoints() * 100
  end
  local wife3Pct   = Wife3State:GetPercent()
  local exPct      = EXState:GetPercent()
  local simplePct  = SimpleState:GetPercent()
  local comboMax   = ComboOnlyState:GetMaxCombo()

  -- Get judgment tallies from stage stats
  local w1, w2, w3, w4, w5, miss = 0, 0, 0, 0, 0, 0
  if pss then
    w1 = pss:GetTapNoteScores("TapNoteScore_W1") or 0
    w2 = pss:GetTapNoteScores("TapNoteScore_W2") or 0
    w3 = pss:GetTapNoteScores("TapNoteScore_W3") or 0
    w4 = pss:GetTapNoteScores("TapNoteScore_W4") or 0
    w5 = pss:GetTapNoteScores("TapNoteScore_W5") or 0
    miss = pss:GetTapNoteScores("TapNoteScore_Miss") or 0
  end

  -- Only update if this is a new best for this chart-rate combo (based on rawBP)
  local existing   = profile.scores[key]
  if not existing or rawBP > existing.rawBP then
    profile.scores[key] = {
      rawBP       = rawBP,
      bcPct       = bcPct,
      bloomRating = bloomRating,
      grade       = grade,
      rateString  = rateStr,
      -- Store scores from all systems
      dpPct       = dpPct,
      wife3Pct    = wife3Pct,
      exPct       = exPct,
      simplePct   = simplePct,
      comboMax    = comboMax,
      -- Store judgment tallies for PB display
      w1          = w1,
      w2          = w2,
      w3          = w3,
      w4          = w4,
      w5          = w5,
      miss        = miss,
    }

    -- Recompute total BP from all stored scores
    local allBP = {}
    for _, entry in pairs(profile.scores) do
      table.insert(allBP, entry.rawBP)
    end
    profile.totalBP = ComputeTotalBP(allBP)

    SaveBCProfile(profile)
  end
end
