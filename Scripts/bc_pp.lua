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

local PROFILE_PATH = "Save/BCProfileData.lua"

function LoadBCProfile()
  local chunk = loadfile(PROFILE_PATH)
  if chunk then
    return chunk()
  end
  return { totalBP = 0, scores = {} }
end

function SaveBCProfile(profile)
  local f = RageFileUtil.CreateRageFile()
  if f:Open(PROFILE_PATH, RageFile.WRITE) then
    local out = "return {\n"
    out = out .. string.format("  totalBP = %.4f,\n", profile.totalBP)
    out = out .. "  scores = {\n"
    for key, entry in pairs(profile.scores) do
      out = out .. string.format(
        "    [%q] = { rawBP=%.4f, bcPct=%.4f, bloomRating=%.2f, grade=%q, rateString=%q },\n",
        key, entry.rawBP, entry.bcPct, entry.bloomRating, entry.grade, entry.rateString
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

  -- Get Bloom Rating from cache (already computed on song select)
  local chartKey   = ChartKey(song, steps)
  local cache      = loadfile("Save/BCRatingCache.lua")
  local ratings    = cache and cache() or {}
  local bloomRating = (ratings[chartKey] and ratings[chartKey].stars) or 0

  local bcPct      = BCState:GetPercent()
  local rawBP      = ComputeRawBP(bloomRating, bcPct)
  local grade      = BCGradeFromPercent(bcPct)

  -- Only update if this is a new best for this chart-rate combo
  local existing   = profile.scores[key]
  if not existing or rawBP > existing.rawBP then
    profile.scores[key] = {
      rawBP       = rawBP,
      bcPct       = bcPct,
      bloomRating = bloomRating,
      grade       = grade,
      rateString  = rateStr,
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
