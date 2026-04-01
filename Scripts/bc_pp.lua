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
-- Data Persistence (via Stats.xml)
-- ============================================================================

local function GetBCProfileData()
  local data = StatsXML_GetBlossomData()
  if not data then
    return { totalBP = 0, scores = {} }
  end
  return {
    totalBP = data.totalBP or 0,
    scores = data.scores or {}
  }
end

function LoadBCProfile()
  return GetBCProfileData()
end

function SaveBCProfile(profile)
  local data = StatsXML_GetBlossomData() or {}
  data.totalBP = profile.totalBP
  data.scores = profile.scores
  StatsXML_SetBlossomData(data)
end

-- ============================================================================
-- Rate Detection
-- ============================================================================

-- Get the current playback rate from song options
function getCurRateValue()
  local rateStr = "1.0"
  local songOpts = GAMESTATE:GetSongOptionsString()
  if songOpts then
    local rateMatch = string.match(songOpts, "(%d+%.?%d*)x")
    if rateMatch then
      rateStr = string.format("%.2f", tonumber(rateMatch) or 1.0)
    end
  end
  local rate = tonumber(rateStr) or 1.0
  return rate
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
  local minLife = 1.0
  if pss then
    w1 = pss:GetTapNoteScores("TapNoteScore_W1") or 0
    w2 = pss:GetTapNoteScores("TapNoteScore_W2") or 0
    w3 = pss:GetTapNoteScores("TapNoteScore_W3") or 0
    w4 = pss:GetTapNoteScores("TapNoteScore_W4") or 0
    w5 = pss:GetTapNoteScores("TapNoteScore_W5") or 0
    miss = pss:GetTapNoteScores("TapNoteScore_Miss") or 0
    minLife = pss:GetMinHealth() or 1.0
  end

  -- Get Judge and Life difficulty from player options
  local judgeDiff = 0
  local lifeDiff = 0
  local playerState = GAMESTATE:GetPlayerState(PLAYER_1)
  if playerState then
    local playerOptions = playerState:GetPlayerOptions("ModsLevel_Stage")
    if playerOptions then
      judgeDiff = playerOptions:TimingDifficulty() or 0
      lifeDiff = playerOptions:LifeDifficulty() or 0
    end
  end
  local dateAchieved = os.date("%Y-%m-%d")

  -- Only update if this is a new best for this chart-rate combo (based on rawBP)
  local existing   = profile.scores[key]
  if not existing or rawBP > existing.rawBP then
    profile.scores[key] = {
      rawBP       = rawBP,
      bcPct       = bcPct,
      bloomRating = bloomRating,
      grade       = grade,
      rateString  = rateStr,
      dpPct       = dpPct,
      wife3Pct    = wife3Pct,
      exPct       = exPct,
      simplePct   = simplePct,
      comboMax    = comboMax,
      w1          = w1,
      w2          = w2,
      w3          = w3,
      w4          = w4,
      w5          = w5,
      miss        = miss,
      date        = dateAchieved,
      judgeDiff   = judgeDiff,
      lifeDiff    = lifeDiff,
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
