-- Blossom Candy Theme - Difficulty Rating Calculator
-- Auto-loaded globally at startup
-- Computes chart difficulty using density + pattern analysis

-- ============================================================================
-- Chart Identification (SM5 has no GetChartKey)
-- ============================================================================

function BCChartKey(song, steps)
  if not song or not steps then return nil end
  return song:GetSongDir()
    .. "|" .. tostring(steps:GetStepsType())
    .. "|" .. tostring(steps:GetDifficulty())
    .. "|" .. (steps:GetDescription() or "")
end

-- ============================================================================
-- Rating Cache Persistence
-- ============================================================================

local RatingCache = {}

function BCLoadRatingCache()
  local chunk = loadfile("Save/BCRatingCache.lua")
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
  local out = "return {\n"
  for k, v in pairs(RatingCache) do
    local key = string.format("%q", k)
    if type(v) == "table" and v.Overall then
      out = out .. string.format("  [%s] = {\n", key)
      out = out .. string.format("    Overall = %.4f,\n", v.Overall)
      out = out .. string.format("    Stream = %.4f,\n", v.Stream or 1.0)
      out = out .. string.format("    Jack = %.4f,\n", v.Jack or 1.0)
      out = out .. string.format("    Tech = %.4f,\n", v.Tech or 1.0)
      out = out .. string.format("    Stamina = %.4f\n", v.Stamina or 1.0)
      out = out .. "  },\n"
    end
  end
  out = out .. "}\n"
  
  local f = RageFileUtil.CreateRageFile()
  if f:Open("Save/BCRatingCache.lua", 2) then -- 2 = WRITE
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
      
      if fields[2] and fields[4] and fields[2]:lower() == targetType and fields[4]:lower() == targetDiff:lower() then
        if fields[7] then
          return ParseNotesString(fields[7], td)
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
-- Etterna MSD-Lite Algorithm Refactor
-- ============================================================================

local function BCAnalyzeIntervals(notes)
  if #notes == 0 then return 0 end
  
  local intervals = {}
  local currentIntervalEnd = math.ceil(notes[1].seconds)
  if currentIntervalEnd < notes[1].seconds + 0.5 then
     currentIntervalEnd = currentIntervalEnd + 1
  end
  
  local currentIntervalNotes = {}
  
  for _, note in ipairs(notes) do
    if note.seconds > currentIntervalEnd then
      if #currentIntervalNotes > 0 then
        table.insert(intervals, currentIntervalNotes)
      end
      -- Advance to the next integer boundary containing this note
      currentIntervalEnd = math.ceil(note.seconds)
      currentIntervalNotes = {note}
    else
      table.insert(currentIntervalNotes, note)
    end
  end
  if #currentIntervalNotes > 0 then
    table.insert(intervals, currentIntervalNotes)
  end

  local intervalScores = {}
  local streamIntervals = {}
  local jackIntervals = {}
  local techIntervals = {}
  
  for _, intervalNotes in ipairs(intervals) do
    local nps = #intervalNotes
    
    local jackMod = 0
    local chordMod = 0
    local crossoverMod = 0
    
    local lastCols = {}
    local concurrentNotes = 0
    local lastTime = intervalNotes[1].seconds
    
    for i, note in ipairs(intervalNotes) do
      local col = note.column
      local t = note.seconds
      
      -- Chord calculation
      if math.abs(t - lastTime) < 0.001 then
        concurrentNotes = concurrentNotes + 1
      else
        if concurrentNotes > 1 then
          -- Hands (3) and Quads (4) are exponentially harder than Jumps (2)
          chordMod = chordMod + (math.pow(concurrentNotes - 1, 1.5) * 0.35)
        end
        concurrentNotes = 1
        lastTime = t
      end
      
      -- Jack calculation
      if lastCols[col] then
        local gap = t - lastCols[col]
        -- Prevents 180bpm trills/jumptrills from triggering jack penalties
        -- Genuine 16th jacks must be < 0.150 gap 
        if gap < 0.090 then
          jackMod = jackMod + 1.5 -- 16th minijack at 170+ bpm
        elseif gap < 0.120 then
          jackMod = jackMod + 0.8 -- 16th minijack at 125+ bpm
        elseif gap < 0.150 then
          jackMod = jackMod + 0.3 -- 16th minijack at 100+ bpm
        end
      end
      lastCols[col] = t
      
      -- Crossover estimation
      if i > 2 then
        local p1 = intervalNotes[i-1].column
        local p2 = intervalNotes[i-2].column
        if (p2 == 1 and p1 == 4 and col == 2) or (p2 == 4 and p1 == 1 and col == 3) or
           (p2 == 2 and p1 == 1 and col == 4) or (p2 == 3 and p1 == 4 and col == 1) then
          crossoverMod = crossoverMod + 0.2
        end
      end
    end
    if concurrentNotes > 1 then
      chordMod = chordMod + (math.pow(concurrentNotes - 1, 1.5) * 0.35)
    end
    
    local effectiveNPS = nps + jackMod + chordMod + crossoverMod
    table.insert(intervalScores, effectiveNPS)
    table.insert(streamIntervals, nps + chordMod)
    table.insert(jackIntervals, nps + jackMod + chordMod)
    table.insert(techIntervals, nps + crossoverMod)
  end
  
  if #intervalScores == 0 then 
    return {Overall=1.0, Stream=1.0, Jack=1.0, Tech=1.0, Stamina=1.0}
  end
  
  local function AggregateIntervals(scores)
    if #scores == 0 then return 0, 0 end
    -- We need a fresh copy to sort since we're tracking multiple arrays!
    local s = {}
    for i=1, #scores do s[i] = scores[i] end
    table.sort(s, function(a, b) return a > b end)
    
    local peakCount = math.max(1, math.ceil(#s * 0.10))
    local peakSum = 0
    for i = 1, peakCount do
      peakSum = peakSum + s[i]
    end
    local peakAvg = peakSum / peakCount
    
    if #s < 5 then
      return peakAvg, peakAvg
    end
    
    local sustainStart = math.max(1, math.floor(#s * 0.25))
    local sustainEnd = math.max(1, math.floor(#s * 0.75))
    if sustainEnd < sustainStart then sustainEnd = sustainStart end
    local sustainSum = 0
    for i = sustainStart, sustainEnd do
      sustainSum = sustainSum + s[i]
    end
    local sustainAvg = sustainSum / ((sustainEnd - sustainStart) + 1)
    
    local finalRaw = (peakAvg * 0.75) + (sustainAvg * 0.25)
    return finalRaw, sustainAvg
  end

  local overRaw, stamRaw = AggregateIntervals(intervalScores)
  local streamRaw = AggregateIntervals(streamIntervals)
  local jackRaw = AggregateIntervals(jackIntervals)
  local techRaw = AggregateIntervals(techIntervals)
  
  local function RawToStars(raw)
    -- Linear scaling compressed with the requested 15% calc-wide reduction
    local stars = (raw / 3.5) * 0.85
    
    -- Powerful logarithmic compression starting at 9.0 Stars
    if stars > 9.0 then
      stars = 9.0 + 4.0 * math.log((stars - 9.0) / 4.0 + 1.0)
    end
    if stars < 1.0 then stars = 1.0 end
    return stars
  end

  return {
    Overall = RawToStars(overRaw),
    Stream = RawToStars(streamRaw),
    Jack = RawToStars(jackRaw),
    Tech = RawToStars(techRaw),
    Stamina = RawToStars(stamRaw)
  }
end

-- ============================================================================
-- Final Rating Calculation
-- ============================================================================

-- Main rating function
function BCComputeRating(steps, song)
  if not steps or not song then return {Overall=1.0, Stream=1.0, Jack=1.0, Tech=1.0, Stamina=1.0} end

  local notes = BCGetNoteTimeline(steps, song)
  
  if #notes > 0 then
    -- MSD-Lite Interval Evaluation returns fully formatted Skillset Table
    return BCAnalyzeIntervals(notes)
  end

  -- Absolute bottom-of-barrel fallback (Radar Values)
  local pn = GAMESTATE:GetMasterPlayerNumber()
  local rv = steps:GetRadarValues(pn)
  if not rv then return {Overall=1.0, Stream=1.0, Jack=1.0, Tech=1.0, Stamina=1.0} end
  
  local totalNotes = rv:GetValue('RadarCategory_TapsAndHolds')
  local songLength = song:GetLastSecond()
  if not totalNotes or totalNotes <= 0 or songLength <= 0 then return {Overall=1.0, Stream=1.0, Jack=1.0, Tech=1.0, Stamina=1.0} end
  
  local avgNPS = totalNotes / songLength
  local stars = (avgNPS / 1.2) * 0.85
  if stars < 1.0 then stars = 1.0 end
  return {
    Overall = stars,
    Stream = stars,
    Jack = stars,
    Tech = stars,
    Stamina = stars
  }
end

-- Get rating with caching
function BCGetRating(steps, song)
  if not steps or not song then return {Overall=1.0, Stream=1.0, Jack=1.0, Tech=1.0, Stamina=1.0} end
  
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
  
  return {Overall = steps:GetMeter(), Stream=1.0, Jack=1.0, Tech=1.0, Stamina=1.0}
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
