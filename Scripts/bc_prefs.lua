-- Blossom Candy Theme - Preferences Persistence
-- Auto-loaded globally at startup
-- SM5 has no SetThemeVar/GetThemeVar; use RageFile to Save/ directory

-- Default preferences
local DefaultBCPrefs = {
  scoringSystem   = "BC",        -- "BC", "Wife3", "EX", "Simple", "ComboOnly"
  showLifeGraph   = true,        -- show life graph on evaluation
  showOffsetGraph = false,       -- SM5 cannot show offset histogram (no replay data)
  showDPPercent   = true,        -- show DP% as secondary display
  autoPreview     = true,        -- auto-preview songs in song select
  previewDelay    = 1.2,         -- seconds before preview starts
  themeVersion    = "1.0.0",
  lastProfileId   = nil,         -- last selected profile ID (nil for guest)
}

-- Active preferences (loaded from file or defaults)
BCPrefs = {}

-- Deep copy helper
local function CopyTable(src)
  local dest = {}
  for k, v in pairs(src) do
    if type(v) == "table" then
      dest[k] = CopyTable(v)
    else
      dest[k] = v
    end
  end
  return dest
end

-- Save preferences to Save/BlossomCandyPrefs.lua
function SaveBCPrefs(prefs)
  prefs = prefs or BCPrefs
  local f = RageFileUtil.CreateRageFile()
  if f:Open("Save/BlossomCandyPrefs.lua", RageFile.WRITE) then
    local out = "return {\n"
    for k, v in pairs(prefs) do
      local valStr
      if type(v) == "string" then
        valStr = string.format("%q", v)
      elseif type(v) == "boolean" then
        valStr = v and "true" or "false"
      elseif type(v) == "number" then
        valStr = tostring(v)
      else
        valStr = string.format("%q", tostring(v))
      end
      out = out .. string.format("  %s = %s,\n", k, valStr)
    end
    out = out .. "}\n"
    f:Write(out)
    f:Close()
  end
  f:destroy()
end

-- Load preferences from Save/BlossomCandyPrefs.lua
function LoadBCPrefs()
  local chunk = loadfile("Save/BlossomCandyPrefs.lua")
  if chunk then
    local loaded = chunk()
    if loaded and type(loaded) == "table" then
      -- Merge with defaults (loaded values take precedence)
      local merged = CopyTable(DefaultBCPrefs)
      for k, v in pairs(loaded) do
        merged[k] = v
      end
      return merged
    end
  end
  -- Return fresh copy of defaults if no file or error
  return CopyTable(DefaultBCPrefs)
end

-- Initialize BCPrefs on load
BCPrefs = LoadBCPrefs()

-- Get a preference value
function BCGetPref(key)
  return BCPrefs[key]
end

-- Set a preference value (does not auto-save)
function BCSetPref(key, value)
  BCPrefs[key] = value
end

-- Get current scoring system accumulator based on preference
function BCGetActiveAccumulator()
  local system = BCPrefs.scoringSystem
  if     system == "BC"        then return BCState
  elseif system == "Wife3"     then return Wife3State
  elseif system == "EX"        then return EXState
  elseif system == "Simple"    then return SimpleState
  elseif system == "ComboOnly" then return ComboOnlyState
  else                               return BCState end
end

-- Reset all accumulators (call at song start)
function BCResetAllAccumulators()
  BCState:Reset()
  Wife3State:Reset()
  EXState:Reset()
  SimpleState:Reset()
  ComboOnlyState:Reset()
  BCHitOffsets = {}  -- Reset hit offset data for evaluation screen
end
