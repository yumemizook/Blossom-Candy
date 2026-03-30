-- Blossom Candy Theme - Enhanced MSD Calculator
-- Auto-loaded globally at startup
-- Based on Etterna MinaCalc algorithm with 0-10+ scaling

-- ============================================================================
-- Math Helpers (Etterna-compatible)
-- ============================================================================

-- Complementary error function approximation (A&S 7.1.26)
local function erfc(x)
  if x < 0 then return 2 - erfc(-x) end
  local p  =  0.3275911
  local a1 =  0.254829592
  local a2 = -0.284496736
  local a3 =  1.421413741
  local a4 = -1.453152027
  local a5 =  1.061405429
  local t = 1.0 / (1.0 + p * x)
  local y = (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t * math.exp(-x*x)
  return y
end

-- Fast power function (for non-integer exponents)
local function fastpow(base, exp)
  if exp == 2 then return base * base end
  if exp == 1 then return base end
  if exp == 0 then return 1 end
  return math.pow(base, exp)
end

-- Weighted average helper
local function weighted_average(a, b, w1, w2)
  return (a * w1 + b * w2) / (w1 + w2)
end

-- ============================================================================
-- Etterna-Style Skill Aggregation (Binary Search with erfc)
-- ============================================================================

-- Aggregate skill values using erfc-based binary search (Etterna algorithm)
-- v: vector of difficulty values
-- delta_multiplier: controls spread of erfc curve
-- result_multiplier: final scaling factor
-- resolution: starting search step size
local function aggregate_skill(v, delta_multiplier, result_multiplier, starting_rating, resolution)
  if #v == 0 then return 0 end
  
  local rating = starting_rating or 0.0
  resolution = resolution or 10.24
  
  -- Binary search: 11 iterations for precision
  for i = 1, 11 do
    local sum = 0.0
    
    -- Accumulate sum using erfc function
    repeat
      rating = rating + resolution
      sum = 0.0
      for _, vv in ipairs(v) do
        -- erfc-based contribution: max(0, 2/erfc(delta*(vv-rating)) - 2)
        local contrib = 2.0 / math.max(erfc(delta_multiplier * (vv - rating)), 0.001) - 2.0
        sum = sum + math.max(0, contrib)
      end
    until fastpow(2, rating * 0.1) >= sum
    
    -- Binary search step back
    rating = rating - resolution
    resolution = resolution / 2.0
  end
  
  rating = rating + resolution * 2.0
  return rating * result_multiplier
end

-- Default skill aggregation parameters (tuned for 0-10 scale)
local skill_params = {
  -- Skillset: {delta_mult, result_mult, starting_rating}
  Stream     = {0.1, 0.5, 0.0},
  Jumpstream = {0.1, 0.5, 0.0},
  Handstream = {0.1, 0.5, 0.0},
  Jackseed   = {0.1, 0.5, 0.0},
  Chordjack  = {0.1, 0.5, 0.0},
  Technical  = {0.1, 0.5, 0.0},
  Stamina    = {0.08, 0.4, 0.0},
}

function BCChartKey(song, steps)
  if not song or not steps then return nil end
  return song:GetSongDir()
    .. "|" .. tostring(steps:GetStepsType())
    .. "|" .. tostring(steps:GetDifficulty())
    .. "|" .. (steps:GetDescription() or "")
end

-- ============================================================================
-- Rating Cache Persistence (Profile-Specific)
-- ============================================================================

local RatingCache = {}

-- Get the profile-specific path for BCRatingCache.lua
local function GetBCRatingCachePath()
  if PROFILEMAN then
    -- Try to get the profile directory from the current player
    for _, pn in ipairs({PLAYER_1, PLAYER_2}) do
      if PROFILEMAN:IsPersistentProfile(pn) then
        -- Construct path using player number (API doesn't expose profile ID directly)
        local playerStr = (pn == PLAYER_1) and "P1" or "P2"
        return "Save/LocalProfiles/Player_" .. playerStr .. "/BCRatingCache.lua"
      end
    end
  end
  -- Fallback to global Save folder if no profile loaded
  return "Save/BCRatingCache.lua"
end

function BCLoadRatingCache()
  local cachePath = GetBCRatingCachePath()
  local chunk = loadfile(cachePath)
  if chunk then
    local loaded = chunk()
    if loaded and type(loaded) == "table" then
      RatingCache = loaded
      return
    end
  end
  RatingCache = {}
end

function BCSaveRatingCache()
  local cachePath = GetBCRatingCachePath()

  local out = "return {\n"
  for k, v in pairs(RatingCache) do
    local key = string.format("%q", k)
    if type(v) == "table" and v.Overall then
      out = out .. string.format("  [%s] = {\n", key)
      out = out .. string.format("    Overall = %.4f,\n", v.Overall)
      out = out .. string.format("    Stream = %.4f,\n", v.Stream or 1.0)
      out = out .. string.format("    Jumpstream = %.4f,\n", v.Jumpstream or 1.0)
      out = out .. string.format("    Handstream = %.4f,\n", v.Handstream or 1.0)
      out = out .. string.format("    Jackseed = %.4f,\n", v.Jackseed or 1.0)
      out = out .. string.format("    Chordjack = %.4f,\n", v.Chordjack or 1.0)
      out = out .. string.format("    Technical = %.4f,\n", v.Technical or 1.0)
      out = out .. string.format("    Stamina = %.4f\n", v.Stamina or 1.0)
      out = out .. "  },\n"
    end
  end
  out = out .. "}\n"

  local f = RageFileUtil.CreateRageFile()
  if f:Open(cachePath, 2) then -- 2 = WRITE
    f:Write(out)
    f:Close()
  end
  f:destroy()
end

function BCGetCachedRating(chartKey)
  if RatingCache[chartKey] and type(RatingCache[chartKey]) == "table" and RatingCache[chartKey].Overall then
    return RatingCache[chartKey]
  end
  return nil
end

function BCSetCachedRating(chartKey, ratingTable)
  if type(ratingTable) == "table" and ratingTable.Overall then
    RatingCache[chartKey] = ratingTable
  end
end

-- Load cache on startup
BCLoadRatingCache()

-- ============================================================================
-- Note Data Parsing
-- ============================================================================

-- Parse note data from steps into a timeline
-- Returns: table of { seconds, column, type } entries
-- ============================================================================
-- Custom File Parser for SM 5.1 (Fallback when GetNoteData is missing)
-- ============================================================================

local function FormatStepsType(st)
  local s = tostring(st) or ""
  if s:find("StepsType_") then
    s = s:gsub("StepsType_", "")
  end
  return s:lower():gsub("_", "-")
end

local function ParseNotesString(notesStr, td)
  local notes = {}
  local measures = {}
  
  -- Split measures by comma
  for measureStr in notesStr:gmatch("([^,]+)") do
    local currentMeasure = {}
    -- Split lines by looking for numeric/letter keys (ignoring whitespace)
    for line in measureStr:gmatch("([0-9MKNOLFH]+)") do
       table.insert(currentMeasure, line)
    end
    table.insert(measures, currentMeasure)
  end
  
  -- Calculate beats and seconds
  for mIndex, measure in ipairs(measures) do
    local linesTotal = #measure
    if linesTotal > 0 then
      for lIndex, rowData in ipairs(measure) do
        for c = 1, #rowData do
          local char = rowData:sub(c, c)
          if char == "1" or char == "2" or char == "4" or char == "L" then
             local beat = ((mIndex - 1) * 4) + ((lIndex - 1) * 4 / linesTotal)
             local seconds = td:GetElapsedTimeFromBeat(beat)
             
             table.insert(notes, {
               seconds = seconds,
               column = c,
               type = char == "1" and "Tap" or (char == "2" and "Hold" or (char == "4" and "Roll" or "Lift"))
             })
          end
        end
      end
    end
  end
  
  table.sort(notes, function(a, b) return a.seconds < b.seconds end)
  return notes
end

local function BCGetNoteTimelineFromFile(steps, song)
  local path = song:GetSongFilePath()
  if not path or path == "" then return nil end

  local f = RageFileUtil.CreateRageFile()
  if not f:Open(path, 1) then -- 1 is READ
    f:destroy()
    return nil
  end

  local isSSC = path:lower():match("%.ssc$")
  local targetType = FormatStepsType(steps:GetStepsType())
  local targetDiff = tostring(steps:GetDifficulty()):gsub("Difficulty_", "")
  
  local td = steps:GetTimingData()
  if not td and song then td = song:GetSongTimingData() end
  if not td then f:Close() f:destroy() return nil end

  -- Fast read into memory and strip comments
  local lines = {}
  while not f:AtEOF() do
    local l = f:GetLine()
    local commentPos = l:find("//")
    if commentPos then l = l:sub(1, commentPos - 1) end
    table.insert(lines, l)
  end
  f:Close()
  f:destroy()
  
  local fullText = table.concat(lines, "\n")

  if isSSC then
    local startPos = 1
    local blocks = {}
    while true do
      local nextPos = fullText:find("#NOTEDATA:", startPos)
      if not nextPos then
        table.insert(blocks, fullText:sub(startPos))
        break
      end
      if startPos ~= nextPos then
        table.insert(blocks, fullText:sub(startPos, nextPos - 1))
      end
      startPos = nextPos + 10
    end
    
    for _, block in ipairs(blocks) do
      local sType = block:match("#STEPSTYPE:([^;]+);")
      local sDiff = block:match("#DIFFICULTY:([^;]+);")
      -- Trim whitespace from captured values
      if sType then sType = sType:match("^%s*(.-)%s*$") end
      if sDiff then sDiff = sDiff:match("^%s*(.-)%s*$") end
      if sType and sDiff and sType:lower() == targetType and sDiff:lower() == targetDiff:lower() then
        local notesStr = block:match("#NOTES:\n?([^;]+)")
        if notesStr then
          return ParseNotesString(notesStr, td)
        end
      end
    end

  else -- SM format
    local startPos = 1
    while true do
      local nextPos = fullText:find("#NOTES:", startPos)
      if not nextPos then break end
      
      local endPos = fullText:find(";", nextPos)
      if not endPos then endPos = #fullText end
      
      local block = fullText:sub(nextPos, endPos)
      local fields = {}
      for field in block:gmatch("([^:]+)") do
        table.insert(fields, field:match("^%s*(.-)%s*$"))
      end
      
      if fields[2] and fields[4] then
        -- Trim whitespace from captured values
        local fileStepType = fields[2]:match("^%s*(.-)%s*$"):lower()
        local fileDiff = fields[4]:match("^%s*(.-)%s*$"):lower()
        if fileStepType == targetType and fileDiff == targetDiff:lower() then
          if fields[7] then
            return ParseNotesString(fields[7], td)
          end
        end
      end
      
      startPos = endPos + 1
    end
  end

  return nil
end

-- ============================================================================
-- Note Data Parsing
-- ============================================================================

-- Parse note data from steps into a timeline
-- Returns: table of { seconds, column, type } entries
function BCGetNoteTimeline(steps, song)
  if not steps then return {} end

  -- Get timing data (with fallback)
  local td = steps:GetTimingData()
  if not td and song then
    td = song:GetSongTimingData()
  end
  if not td then return {} end

  local notes = {}
  -- Check if GetNoteData is available (SM5.1-newer or OutFox)
  if not steps.GetNoteData then 
    -- SM5.1 Fallback: Parse the data directly from the chart file!
    local fileNotes = BCGetNoteTimelineFromFile(steps, song)
    if fileNotes then return fileNotes end
    return {} 
  end
  
  local noteData = steps:GetNoteData()
  if not noteData then return {} end

  -- Parse note data
  -- Format: each row is "beat|column|type|..."
  for row in string.gmatch(noteData, "([^\n]+)") do
    local beat, col, ntype = string.match(row, "([^|]+)|([^|]+)|([^|]+)")
    if beat and col then
      beat = tonumber(beat)
      col = tonumber(col)
      if beat and col then
        local seconds = td:GetElapsedTimeFromBeat(beat)
        table.insert(notes, {
          seconds = seconds,
          column = col,
          type = ntype or "Tap"
        })
      end
    end
  end

  -- Sort by time
  table.sort(notes, function(a, b) return a.seconds < b.seconds end)
  return notes
end

-- ============================================================================
-- Enhanced MSD Algorithm (Etterna MinaCalc-style)
-- ============================================================================

-- Hand-split note analysis (left=cols 1-2, right=cols 3-4 for 4k)
local function split_hands(notes, keycount)
  keycount = keycount or 4
  local left = {}
  local right = {}
  local mid = keycount / 2
  
  for _, note in ipairs(notes) do
    if note.column <= mid then
      table.insert(left, note)
    else
      table.insert(right, note)
    end
  end
  return left, right
end

-- Build 0.5-second intervals (Etterna standard)
local function build_intervals(notes)
  if #notes == 0 then return {} end
  
  local intervals = {}
  local interval_duration = 0.5
  local start_time = notes[1].seconds
  local current_end = start_time + interval_duration
  local current_notes = {}
  
  for _, note in ipairs(notes) do
    if note.seconds >= current_end then
      if #current_notes > 0 then
        table.insert(intervals, {
          notes = current_notes,
          start = current_end - interval_duration,
          duration = interval_duration,
          nps = #current_notes / interval_duration
        })
      end
      -- Advance interval
      while note.seconds >= current_end do
        current_end = current_end + interval_duration
      end
      current_notes = {note}
    else
      table.insert(current_notes, note)
    end
  end
  
  if #current_notes > 0 then
    table.insert(intervals, {
      notes = current_notes,
      start = current_end - interval_duration,
      duration = interval_duration,
      nps = #current_notes / interval_duration
    })
  end
  
  return intervals
end

-- Pattern analysis for a single interval
local function analyze_interval_patterns(interval_notes, prev_notes, keycount)
  keycount = keycount or 4
  local patterns = {
    nps = #interval_notes / 0.5,
    jumps = 0,
    hands = 0,
    quads = 0,
    jack_severity = 0,
    chordjack_severity = 0,
    tech_severity = 0,
    last_col_times = {}
  }
  
  if #interval_notes == 0 then return patterns end
  
  -- Track concurrent notes (jumps/hands)
  local concurrent = 0
  local last_time = interval_notes[1].seconds
  local chord_count = 0
  local jack_count = 0
  local jack_gaps = {}
  
  for i, note in ipairs(interval_notes) do
    local col = note.column
    local t = note.seconds
    
    -- Concurrent note detection (jumps/hands)
    if math.abs(t - last_time) < 0.005 then
      concurrent = concurrent + 1
    else
      -- Process previous group
      if concurrent == 2 then
        patterns.jumps = patterns.jumps + 1
      elseif concurrent == 3 then
        patterns.hands = patterns.hands + 1
        chord_count = chord_count + 1
      elseif concurrent >= 4 then
        patterns.quads = patterns.quads + 1
        chord_count = chord_count + 2
      end
      concurrent = 1
      last_time = t
    end
    
    -- Jack detection (same column within interval)
    if patterns.last_col_times[col] then
      local gap = t - patterns.last_col_times[col]
      table.insert(jack_gaps, gap)
      
      -- Severity based on gap (shorter = harder)
      if gap < 0.060 then        -- 16th at 250+bpm
        patterns.jack_severity = patterns.jack_severity + 2.5
        jack_count = jack_count + 1.5
      elseif gap < 0.090 then    -- 16th at 170+bpm
        patterns.jack_severity = patterns.jack_severity + 1.5
        jack_count = jack_count + 1.0
      elseif gap < 0.125 then    -- 16th at 120+bpm
        patterns.jack_severity = patterns.jack_severity + 0.8
        jack_count = jack_count + 0.5
      elseif gap < 0.170 then    -- 8th at 180+bpm
        patterns.jack_severity = patterns.jack_severity + 0.3
      end
    end
    
    -- Cross-column jack detection (for chordjacks)
    for other_col = 1, keycount do
      if other_col ~= col and patterns.last_col_times[other_col] then
        local cross_gap = math.abs(t - patterns.last_col_times[other_col])
        if cross_gap < 0.090 then
          patterns.chordjack_severity = patterns.chordjack_severity + 0.4
        end
      end
    end
    
    patterns.last_col_times[col] = t
    
    -- Technical pattern detection (based on previous 2 notes)
    if i > 2 then
      local p1 = interval_notes[i-1].column
      local p2 = interval_notes[i-2].column
      
      -- Classic crossovers (1-4-2, 4-1-3, etc.)
      if (p2 == 1 and p1 == keycount and col == 2) or 
         (p2 == keycount and p1 == 1 and col == keycount-1) or
         (p2 == 2 and p1 == 1 and col == keycount) or
         (p2 == keycount-1 and p1 == keycount and col == 1) then
        patterns.tech_severity = patterns.tech_severity + 0.6
      end
      
      -- Trills (1-2-1, 2-3-2, 3-4-3, 4-3-4)
      if p2 == col and math.abs(p1 - col) == 1 then
        patterns.tech_severity = patterns.tech_severity + 0.3
      end
      
      -- Gallops (1-3-2, 4-2-3)
      if math.abs(p2 - p1) >= 2 and math.abs(p1 - col) >= 2 then
        patterns.tech_severity = patterns.tech_severity + 0.25
      end
    end
  end
  
  -- Process final concurrent group
  if concurrent == 2 then
    patterns.jumps = patterns.jumps + 1
  elseif concurrent == 3 then
    patterns.hands = patterns.hands + 1
    chord_count = chord_count + 1
  elseif concurrent >= 4 then
    patterns.quads = patterns.quads + 1
    chord_count = chord_count + 2
  end
  
  -- Chordjack bonus
  if jack_count > 0 and chord_count > 0 then
    patterns.chordjack_severity = patterns.chordjack_severity + 
      (patterns.jack_severity * 0.5) + (math.min(chord_count, 3) * 0.8)
  end
  
  return patterns
end

-- Calculate base difficulty for a skillset
local function calc_skillset_diff(base_nps, pattern_mods, skillset)
  local mod = 0
  
  if skillset == "Stream" then
    mod = 0
  elseif skillset == "Jumpstream" then
    mod = pattern_mods.jumps * 1.2
  elseif skillset == "Handstream" then
    mod = (pattern_mods.hands * 2.5) + (pattern_mods.quads * 4.0)
  elseif skillset == "Jackseed" then
    mod = pattern_mods.jack_severity
  elseif skillset == "Chordjack" then
    mod = pattern_mods.chordjack_severity
  elseif skillset == "Technical" then
    mod = pattern_mods.tech_severity
  end
  
  -- NPS-based scaling with pattern mods
  return math.max(0, base_nps + mod)
end

-- Grind/scaling factor for stamina (Etterna-style)
local function calc_grind_scaler(intervals)
  if #intervals == 0 then return 1.0 end
  
  local total_notes = 0
  local populated = 0
  
  for _, intv in ipairs(intervals) do
    if intv.nps > 0 then
      total_notes = total_notes + #intv.notes
      populated = populated + 1
    end
  end
  
  if populated == 0 then return 0.1 end
  
  local avg_nps = total_notes / (populated * 0.5)
  local file_length_seconds = populated * 0.5
  
  -- Longer files get stamina bonus
  local timescaler = 0.3 + (0.7 * math.log(file_length_seconds / 30 + 1) / math.log(10))
  return math.min(1.0, math.max(0.1, timescaler))
end

-- Main analysis function using Etterna-style aggregation
local function BCAnalyzeIntervals(notes, keycount)
  keycount = keycount or 4
  
  if #notes == 0 then
    return {
      Overall = 1.0, Stream = 1.0, Jumpstream = 1.0, Handstream = 1.0,
      Jackseed = 1.0, Chordjack = 1.0, Technical = 1.0, Stamina = 1.0
    }
  end
  
  -- Split by hands for hand-dependent analysis
  local left_notes, right_notes = split_hands(notes, keycount)
  
  -- Build intervals for each hand
  local left_intervals = build_intervals(left_notes)
  local right_intervals = build_intervals(right_notes)
  local all_intervals = build_intervals(notes)
  
  -- Collect difficulty vectors for each skillset
  local skill_vectors = {
    Stream = {},
    Jumpstream = {},
    Handstream = {},
    Jackseed = {},
    Chordjack = {},
    Technical = {},
    Stamina = {}
  }
  
  -- Analyze each interval and build difficulty vectors
  local prev_patterns = nil
  for i, interval in ipairs(all_intervals) do
    local patterns = analyze_interval_patterns(interval.notes, prev_patterns, keycount)
    
    -- Store NPS-based difficulty for each skillset
    table.insert(skill_vectors.Stream, calc_skillset_diff(interval.nps, patterns, "Stream"))
    table.insert(skill_vectors.Jumpstream, calc_skillset_diff(interval.nps, patterns, "Jumpstream"))
    table.insert(skill_vectors.Handstream, calc_skillset_diff(interval.nps, patterns, "Handstream"))
    table.insert(skill_vectors.Jackseed, calc_skillset_diff(interval.nps, patterns, "Jackseed"))
    table.insert(skill_vectors.Chordjack, calc_skillset_diff(interval.nps, patterns, "Chordjack"))
    table.insert(skill_vectors.Technical, calc_skillset_diff(interval.nps, patterns, "Technical"))
    
    prev_patterns = patterns
  end
  
  -- Calculate stamina vector (based on base stream difficulty, no grind scaler yet)
  for i, interval in ipairs(all_intervals) do
    -- Stamina starts from stream base without grind factor
    local base_stam = skill_vectors.Stream[i] or 0
    table.insert(skill_vectors.Stamina, base_stam)
  end
  
  -- Aggregate each skillset using Etterna-style erfc-based binary search
  local raw_ratings = {}
  for skillset, params in pairs(skill_params) do
    if skill_vectors[skillset] and #skill_vectors[skillset] > 0 then
      local delta_mult = params[1]
      local result_mult = params[2]
      local start_rating = params[3]
      
      raw_ratings[skillset] = aggregate_skill(
        skill_vectors[skillset],
        delta_mult,
        result_mult,
        start_rating,
        10.24
      )
    else
      raw_ratings[skillset] = 0
    end
  end
  
  -- Calculate Overall as the max difficulty per interval across all skillsets
  -- This is how Etterna actually calculates it - take the hardest pattern
  -- at each interval regardless of which skillset it belongs to
  local overall_vector = {}
  for i = 1, #all_intervals do
    local max_diff = 0
    for skillset, _ in pairs(skill_params) do
      if skill_vectors[skillset] and skill_vectors[skillset][i] then
        max_diff = math.max(max_diff, skill_vectors[skillset][i])
      end
    end
    table.insert(overall_vector, max_diff)
  end
  
  -- Calculate grind scaler for stamina adjustment
  local grindscaler = calc_grind_scaler(all_intervals)
  
  -- Aggregate the overall vector using standard parameters
  raw_ratings.Overall = aggregate_skill(
    overall_vector,
    skill_params.Stream[1],  -- Use Stream params for Overall
    skill_params.Stream[2],
    0.0,
    10.24
  )
  
  -- Convert raw ratings to 0-10+ star scale
  local function RawToStars(raw, isStamina)
    -- Base scaling: ~3.5 raw NPS = 1.0 stars
    local stars = raw / 3.5
    
    -- Apply gentle grind scaler ONLY to stamina, and only once
    if isStamina then
      -- Stamina bonus: longer files get modest boost (max 25% at very long files)
      local stamBonus = 1.0 + (0.25 * grindscaler)
      stars = stars * stamBonus
      -- Cap stamina at 1.5x the highest base skillset to prevent inflation
      local maxBaseSkill = math.max(
        raw_ratings.Stream or 0,
        raw_ratings.Jumpstream or 0,
        raw_ratings.Handstream or 0,
        raw_ratings.Jackseed or 0,
        raw_ratings.Chordjack or 0,
        raw_ratings.Technical or 0
      )
      local stamCap = (maxBaseSkill / 3.5) * 1.5
      stars = math.min(stars, stamCap)
    end
    
    -- Logarithmic compression for high difficulties (starting at 9.0)
    if stars > 9.0 then
      -- Smooth exponential growth beyond 9.0
      local excess = stars - 9.0
      stars = 9.0 + (3.0 * math.log(excess / 3.0 + 1.0))
    end
    
    -- Hard floor and ceiling
    return math.max(0.0, math.min(20.0, stars))
  end
  
  return {
    Overall = RawToStars(raw_ratings.Overall, false),
    Stream = RawToStars(raw_ratings.Stream, false),
    Jumpstream = RawToStars(raw_ratings.Jumpstream, false),
    Handstream = RawToStars(raw_ratings.Handstream, false),
    Jackseed = RawToStars(raw_ratings.Jackseed, false),
    Chordjack = RawToStars(raw_ratings.Chordjack, false),
    Technical = RawToStars(raw_ratings.Technical, false),
    Stamina = RawToStars(raw_ratings.Stamina, true)
  }
end

-- ============================================================================
-- Final Rating Calculation
-- ============================================================================

-- Main rating function
function BCComputeRating(steps, song)
  if not steps or not song then
    return {
      Overall=1.0, Stream=1.0, Jumpstream=1.0, Handstream=1.0,
      Jackseed=1.0, Chordjack=1.0, Technical=1.0, Stamina=1.0
    }
  end

  local notes = BCGetNoteTimeline(steps, song)
  
  -- Detect keycount from steps type (default to 4)
  local keycount = 4
  local stepsType = tostring(steps:GetStepsType()):lower()
  if stepsType:find("_5") or stepsType:find("5k") then keycount = 5
  elseif stepsType:find("_6") or stepsType:find("6k") then keycount = 6
  elseif stepsType:find("_7") or stepsType:find("7k") then keycount = 7
  elseif stepsType:find("_8") or stepsType:find("8k") then keycount = 8
  elseif stepsType:find("_9") or stepsType:find("9k") then keycount = 9
  end
  
  if #notes > 0 then
    -- Enhanced MSD calculation with Etterna-style aggregation
    return BCAnalyzeIntervals(notes, keycount)
  end

  -- Absolute bottom-of-barrel fallback (Radar Values)
  local pn = GAMESTATE:GetMasterPlayerNumber()
  local rv = steps:GetRadarValues(pn)
  if not rv then
    return {
      Overall=1.0, Stream=1.0, Jumpstream=1.0, Handstream=1.0,
      Jackseed=1.0, Chordjack=1.0, Technical=1.0, Stamina=1.0
    }
  end
  
  local totalNotes = rv:GetValue('RadarCategory_TapsAndHolds')
  local songLength = song:GetLastSecond()
  if not totalNotes or totalNotes <= 0 or songLength <= 0 then
    return {
      Overall=1.0, Stream=1.0, Jumpstream=1.0, Handstream=1.0,
      Jackseed=1.0, Chordjack=1.0, Technical=1.0, Stamina=1.0
    }
  end
  
  local avgNPS = totalNotes / songLength
  local stars = (avgNPS / 1.2) * 0.82
  if stars < 0 then stars = 0 end
  return {
    Overall = stars,
    Stream = stars,
    Jumpstream = stars,
    Handstream = stars,
    Jackseed = stars,
    Chordjack = stars,
    Technical = stars,
    Stamina = stars
  }
end

-- Get rating with caching
function BCGetRating(steps, song)
  if not steps or not song then
    return {
      Overall=1.0, Stream=1.0, Jumpstream=1.0, Handstream=1.0,
      Jackseed=1.0, Chordjack=1.0, Technical=1.0, Stamina=1.0
    }
  end
  
  local key = BCChartKey(song, steps)
  
  -- Use the helper to check the cache safely
  local cached = BCGetCachedRating(key)
  if cached then return cached end
  
  local ratingTable = BCComputeRating(steps, song)
  if ratingTable and ratingTable.Overall then
    BCSetCachedRating(key, ratingTable)
    BCSaveRatingCache()
    return ratingTable
  end
  
  return {
    Overall = steps:GetMeter(),
    Stream=1.0, Jumpstream=1.0, Handstream=1.0,
    Jackseed=1.0, Chordjack=1.0, Technical=1.0, Stamina=1.0
  }
end

-- Difficulty pill color gradient
-- mint (low) → lavender (mid) → dusty rose (high) → muted coral (>10)
function BCGetRatingColor(stars)
  if stars <= 3 then
    -- Mint to lavender
    local t = stars / 3
    return {
      0.72 + (0.80 - 0.72) * t,
      0.94 + (0.72 - 0.94) * t,
      0.82 + (0.96 - 0.82) * t,
      1
    }
  elseif stars <= 7 then
    -- Lavender to dusty rose
    local t = (stars - 3) / 4
    return {
      0.80 + (0.92 - 0.80) * t,
      0.72 + (0.74 - 0.72) * t,
      0.96 + (0.78 - 0.96) * t,
      1
    }
  elseif stars <= 10 then
    -- Dusty rose to muted coral
    local t = (stars - 7) / 3
    return {
      0.92 + (0.90 - 0.92) * t,
      0.74 + (0.60 - 0.74) * t,
      0.78 + (0.62 - 0.78) * t,
      1
    }
  else
    -- Muted coral
    return BCColors.miss
  end
end
