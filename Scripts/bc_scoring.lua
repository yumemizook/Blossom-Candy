-- Blossom Candy Theme - Alternate Scoring Systems
-- Auto-loaded globally at startup
-- Includes: Wife3, EX Score, Simple Percent, Combo Only

-- ============================================================================
-- Wife3 Scoring (Etterna-compatible, theme-side implementation)
-- ============================================================================

-- Approximation of erf via A&S formula 7.1.26 (same as Etterna _fallback source)
local function erf(x)
  local sign = x < 0 and -1 or 1
  x = math.abs(x)
  local p  =  0.3275911
  local a1 =  0.254829592
  local a2 = -0.284496736
  local a3 =  1.421413741
  local a4 = -1.453152027
  local a5 =  1.061405429
  local t = 1.0 / (1.0 + p * x)
  local y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t * math.exp(-x*x)
  return sign * y
end

-- Wife3 note score: returns raw score in range (-2.5, 2.0], miss = -5.5 raw
-- All parameters are at J4 (ts=1.0); for other judges, scale by (4/judge)^0.75
local function Wife3NoteScore(maxms)
  -- J4 constants (hardcoded for strict Etterna compatibility)
  local max_points     = 2.0
  local ridic          = 5.0     -- below this: full points
  local zero           = 65.0    -- erf zero crossing
  local max_boo_weight = 180.0   -- miss threshold
  local dev            = 22.7    -- erf deviation (spread)
  local power          = 2.5     -- linear region endpoint magnitude

  if maxms <= ridic then
    -- Full points below ridic threshold
    return max_points

  elseif maxms <= zero then
    -- erf region: smooth decay from max_points (2.0) → 0 at zero (65ms)
    return max_points * erf((zero - maxms) / dev)

  elseif maxms <= max_boo_weight then
    -- Linear (cb/boo) region: 0 at zero → -power at max_boo_weight
    return -power * (maxms - zero) / (max_boo_weight - zero)

  else
    -- Should not be reached; misses are handled via isMiss flag
    return -5.5
  end
end

-- Wife3 State Accumulator
Wife3State = {
  raw        = 0,
  totalNotes = 0,
}

function Wife3State:Reset()
  self.raw        = 0
  self.totalNotes = 0
end

function Wife3State:AddJudgment(offsetSeconds, isMiss)
  self.totalNotes = self.totalNotes + 1
  if isMiss then
    self.raw = self.raw + (-5.5)  -- miss_weight raw
  else
    local maxms = math.abs(offsetSeconds) * 1000
    self.raw = self.raw + Wife3NoteScore(maxms)
  end
end

-- Hold/Roll Drop: -4.5 penalty
function Wife3State:AddHoldRollDrop()
  self.totalNotes = self.totalNotes + 1
  self.raw = self.raw - 4.5
end

-- Mine Hit: -7.0 penalty
function Wife3State:AddMineHit()
  self.totalNotes = self.totalNotes + 1
  self.raw = self.raw - 7.0
end

function Wife3State:GetPercent()
  if self.totalNotes == 0 then return 0 end
  -- Normalize by max possible (2.0 per note)
  return (self.raw / (self.totalNotes * 2.0)) * 100
end

-- Wife3 Grade Thresholds (from Etterna _fallback/Scripts/10 Scores.lua)
Wife3Grades = {
  { 99.9935, "AAAAA", "gradeBlossom" },
  { 99.9550, "AAAA", "gradeSPlus" },
  { 99.7000, "AAA",  "gradeS"   },
  { 93.0000, "AA",   "gradeA"       },
  { 80.0000, "A",    "gradeB"       },
  { 70.0000, "B",    "gradeC"       },
  { 60.0000, "C",    "gradeD"       },
  { 0.0000, "D",    "gradeDminus"       },
}

function Wife3GradeFromPercent(pct)
  for _, tier in ipairs(Wife3Grades) do
    if pct >= tier[1] then
      return tier[2], BCColors[tier[3]]
    end
  end
  return "F", BCColors.gradeDMinus
end

-- ============================================================================
-- EX Score (theme-side)
-- W1 = 3, W2 = 2, W3 = 1, others = 0
-- ============================================================================

EXState = {
  score      = 0,
  totalNotes = 0,
}

function EXState:Reset()
  self.score      = 0
  self.totalNotes = 0
end

function EXState:AddJudgment(tns)
  self.totalNotes = self.totalNotes + 1
  local points = 0
  if     tns == 'TapNoteScore_W1' then points = 3
  elseif tns == 'TapNoteScore_W2' then points = 2
  elseif tns == 'TapNoteScore_W3' then points = 1
  end
  self.score = self.score + points
end

-- Hold/Roll Drop and Mine Hit: 0 points, just count the note
function EXState:AddHoldRollDrop()
  self.totalNotes = self.totalNotes + 1
end

function EXState:AddMineHit()
  self.totalNotes = self.totalNotes + 1
end

function EXState:GetScore()
  return self.score
end

function EXState:GetMaxPossible()
  return self.totalNotes * 3
end

function EXState:GetPercent()
  if self.totalNotes == 0 then return 0 end
  return (self.score / (self.totalNotes * 3)) * 100
end

-- ============================================================================
-- Simple Percent (theme-side)
-- Any non-miss = hit. hits / totalNotes * 100
-- ============================================================================

SimpleState = {
  hits       = 0,
  totalNotes = 0,
}

function SimpleState:Reset()
  self.hits       = 0
  self.totalNotes = 0
end

function SimpleState:AddJudgment(tns)
  self.totalNotes = self.totalNotes + 1
  if tns ~= 'TapNoteScore_Miss' then
    self.hits = self.hits + 1
  end
end

-- Hold/Roll Drop and Mine Hit: count as miss (no hit)
function SimpleState:AddHoldRollDrop()
  self.totalNotes = self.totalNotes + 1
  -- counts as miss, no hit increment
end

function SimpleState:AddMineHit()
  self.totalNotes = self.totalNotes + 1
  -- counts as miss, no hit increment
end

function SimpleState:GetPercent()
  if self.totalNotes == 0 then return 0 end
  return (self.hits / self.totalNotes) * 100
end

-- ============================================================================
-- Combo Only (no score, just tracks max combo)
-- ============================================================================

ComboOnlyState = {
  maxCombo = 0,
}

function ComboOnlyState:Reset()
  self.maxCombo = 0
end

function ComboOnlyState:SetMaxCombo(combo)
  self.maxCombo = combo
end

function ComboOnlyState:GetMaxCombo()
  return self.maxCombo
end
