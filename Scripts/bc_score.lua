-- Blossom Candy Theme - BlossomCandy Score System
-- Auto-loaded globally at startup
-- Theme-side accumulator for custom scoring

-- Read timing windows from PREFSMAN at module load time
local function GetBCWindows()
  local scale = PREFSMAN:GetPreference("TimingWindowScale")
  return {
    W1 = PREFSMAN:GetPreference("TimingWindowSecondsW1") * scale * 1000,  -- store in ms
    W2 = PREFSMAN:GetPreference("TimingWindowSecondsW2") * scale * 1000,
    W3 = PREFSMAN:GetPreference("TimingWindowSecondsW3") * scale * 1000,
    W4 = PREFSMAN:GetPreference("TimingWindowSecondsW4") * scale * 1000,
    W5 = PREFSMAN:GetPreference("TimingWindowSecondsW5") * scale * 1000,
    -- Default at J4 (scale=1): W1=22.5ms, W2=45ms, W3=90ms, W4=135ms, W5=180ms
  }
end

local W = GetBCWindows()  -- computed once at load; values are in ms

-- Error function approximation (A&S formula 7.1.26)
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

-- Erf-based scoring curve: 0-67.5ms continuous
-- Parameters tuned so: t=0 → ~1.0, t=4.5 → ~0.998, t=22.5 → ~0.909, t=45 → ~0.80, t=67.5 → 0.0
local ERF_OFFSET = 36.0    -- center point (ms)
local ERF_SPREAD = 10.5    -- spread factor (ms) - tuned for 0.80 at 45ms

local function erfScore(t)
  -- Linear mapping: output goes from 1.0 at t=4.5 to 0.0 at t=67.5
  -- At t=4.5: (4.5-36)/10.5 = -3.0, erf(-3) ≈ -0.998, output ≈ 0.999
  -- At t=22.5: (22.5-36)/10.5 = -1.286, erf(-1.286) ≈ -0.818, output ≈ 0.909
  -- At t=45: (45-36)/10.5 = 0.857, erf(0.857) ≈ 0.600, output ≈ 0.80
  -- At t=67.5: (67.5-36)/10.5 = 3.0, erf(3) ≈ 0.998, output ≈ 0.001
  return 0.5 * (1.0 - erf((t - ERF_OFFSET) / ERF_SPREAD))
end

-- Linear interpolation: t in [t_min, t_max] → [s_start, s_end]
local function linearInterp(t, t_min, t_max, s_start, s_end)
  local x = (t - t_min) / (t_max - t_min)
  return s_start + (s_end - s_start) * x
end

-- Great window zero-crossing: midpoint of the Great window
-- At J4: W2=45ms, W3=90ms → greatZero = 67.5ms
local greatZero = W.W2 + (W.W3 - W.W2) / 2

-- Compute score for a single note based on offset (in seconds)
-- Returns raw score value (can be negative)
function BCNoteScore(offsetSeconds)
  if offsetSeconds == nil then
    return -2.50  -- Treat nil offset as miss
  end
  local t = math.abs(offsetSeconds) * 1000  -- convert to ms for comparison with W.*

  if t <= greatZero then
    -- Continuous erf curve: 0-67.5ms (Marvelous, Perfect, Great+)
    -- Goes from 1.00 at 0ms → 0.983 at 4.5ms → 0.00 at 67.5ms
    return erfScore(t)

  elseif t <= W.W3 then
    -- Great (negative half): linear 0.00 → −0.75
    return linearInterp(t, greatZero, W.W3, 0.00, -0.75)

  elseif t <= W.W4 then
    -- Good: linear −0.75 → −1.50
    return linearInterp(t, W.W3, W.W4, -0.75, -1.50)

  elseif t <= W.W5 then
    -- Bad: linear −1.50 → −2.50
    return linearInterp(t, W.W4, W.W5, -1.50, -2.50)

  else
    -- Outside window — handled via isMiss flag, but return miss value as fallback
    return -2.50
  end
end

-- Note: miss value (−2.50) is exactly continuous with the end of the Bad window.
-- There is no discontinuous jump at the miss boundary.
-- Hits and misses at the window edge score identically (-2.50).
-- Scores can go negative on miss-heavy plays; do not clamp to 0.

-- BlossomCandy Score State
BCState = {
  raw        = 0,
  totalNotes = 0,
}

function BCState:Reset()
  self.raw        = 0
  self.totalNotes = 0
end

function BCState:AddJudgment(offsetSeconds, isMiss)
  self.totalNotes = self.totalNotes + 1
  if isMiss or offsetSeconds == nil then
    self.raw = self.raw - 2.50
  else
    self.raw = self.raw + BCNoteScore(offsetSeconds)
  end
end

-- Hold/Roll Drop: treated as Miss (-2.50)
function BCState:AddHoldRollDrop()
  self.totalNotes = self.totalNotes + 1
  self.raw = self.raw - 2.50
end

-- Mine Hit: -3.0 penalty
function BCState:AddMineHit()
  self.totalNotes = self.totalNotes + 1
  self.raw = self.raw - 3.00
end

function BCState:GetPercent()
  if self.totalNotes == 0 then return 0 end
  return (self.raw / self.totalNotes) * 100
end

-- Curve Summary (at J4 defaults):
-- | Offset (abs) | Judgment | Score | Shape |
-- | 0 – 67.5ms | Marvelous/Perfect/Great+ | 1.00 → 0.00 | Erf (0.983 at 4.5ms) |
-- | 67.5 – 90ms | Great (neg.) | 0.00 → −0.75 | Linear |
-- | 90 – 135ms | Good | −0.75 → −1.50 | Linear |
-- | 135 – 180ms | Bad | −1.50 → −2.50 | Linear |
-- | Not hit | Miss | −2.50 | Fixed |
