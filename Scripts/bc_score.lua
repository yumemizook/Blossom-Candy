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

-- Smoothstep cubic ease: t in [t_min, t_max] → [s_max, s_min]
local function cubicEase(t, t_min, t_max, s_max, s_min)
  local x = (t - t_min) / (t_max - t_min)
  local curved = x * x * (3 - 2 * x)  -- smoothstep cubic
  return s_max + (s_min - s_max) * curved
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

  if t <= W.W1 then
    -- Marvelous: cubic 1.00 → 0.99
    return cubicEase(t, 0, W.W1, 1.00, 0.99)

  elseif t <= W.W2 then
    -- Perfect: cubic 0.99 → 0.80
    return cubicEase(t, W.W1, W.W2, 0.99, 0.80)

  elseif t <= greatZero then
    -- Great (positive half): cubic 0.80 → 0.00
    return cubicEase(t, W.W2, greatZero, 0.80, 0.00)

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
-- | 0 – 22.5ms | Marvelous | 1.00 → 0.99 | Cubic |
-- | 22.5 – 45ms | Perfect | 0.99 → 0.80 | Cubic |
-- | 45 – 67.5ms | Great (pos.) | 0.80 → 0.00 | Cubic |
-- | 67.5 – 90ms | Great (neg.) | 0.00 → −0.75 | Linear |
-- | 90 – 135ms | Good | −0.75 → −1.50 | Linear |
-- | 135 – 180ms | Bad | −1.50 → −2.50 | Linear |
-- | Not hit | Miss | −2.50 | Fixed |
