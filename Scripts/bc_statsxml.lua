-- Blossom Candy Theme - Stats.xml Manager
-- Manages BlossomCandy data within the profile's Stats.xml file

local BlossomStats = {
  data = nil,
  loaded = false
}

local function GetProfileDirForPlayer(pn)
  if not PROFILEMAN then return nil end
  
  local profile = PROFILEMAN:GetProfile(pn)
  
  if profile then
    if profile.GetProfileDir then
      local dir = profile:GetProfileDir()
      if dir and dir ~= "" then return dir end
    end
    if profile.GetLocalProfileID then
      local id = profile:GetLocalProfileID()
      if id then return "Save/LocalProfiles/" .. id end
    end
  end
  
  if PROFILEMAN:GetNumLocalProfiles() > 0 then
    local id = PROFILEMAN:GetLocalProfileIDFromIndex(0)
    if id then return "Save/LocalProfiles/" .. id end
  end
  
  return nil
end

function StatsXML_GetProfileDir()
  local dir = GetProfileDirForPlayer(PLAYER_1)
  if dir then return dir end
  
  dir = GetProfileDirForPlayer(PLAYER_2)
  if dir then return dir end
  
  Trace("StatsXML_GetProfileDir: No profile directory found")
  return nil
end

function StatsXML_Load()
  local profileDir = StatsXML_GetProfileDir()
  if not profileDir then
    BlossomStats.data = nil
    BlossomStats.loaded = false
    return nil
  end
  
  local statsPath = profileDir .. "/Stats.xml"
  local f = RageFileUtil.CreateRageFile()
  
  if not f:Open(statsPath, 1) then
    f:destroy()
    BlossomStats.data = nil
    BlossomStats.loaded = true
    return nil
  end
  
  local xmlContent = {}
  while not f:AtEOF() do
    table.insert(xmlContent, f:GetLine())
  end
  f:Close()
  f:destroy()
  
  local xmlStr = table.concat(xmlContent, "\n")
  
  local bcDataStr = xmlStr:match("<BlossomCandy>%s*(.-)%s*</BlossomCandy>")
  if bcDataStr then
    local chunk = loadstring("return " .. bcDataStr)
    if chunk then
      local success, result = pcall(chunk)
      if success and result then
        BlossomStats.data = result
        BlossomStats.loaded = true
        return result
      end
    end
  end
  
  BlossomStats.data = nil
  BlossomStats.loaded = true
  return nil
end

function StatsXML_Save(data)
  local profileDir = StatsXML_GetProfileDir()
  if not profileDir then
    Trace("StatsXML_Save: No profile directory available")
    return false
  end
  
  local statsPath = profileDir .. "/Stats.xml"
  local f = RageFileUtil.CreateRageFile()
  local success = f:Open(statsPath, 1)
  
  if not success then
    f:destroy()
    local newFile = RageFileUtil.CreateRageFile()
    if newFile:Open(statsPath, 2) then
      local xmlContent = [[<?xml version="1.0" encoding="utf-8"?>
<Stats>
  <BlossomCandy>
]] .. StatsXML_Serialize(data, 4) .. [[
  </BlossomCandy>
</Stats>]]
      newFile:Write(xmlContent)
      newFile:Close()
    end
    newFile:destroy()
    BlossomStats.data = data
    return true
  end
  
  local xmlContent = {}
  while not f:AtEOF() do
    table.insert(xmlContent, f:GetLine())
  end
  f:Close()
  f:destroy()
  
  local xmlStr = table.concat(xmlContent, "\n")
  
  local bcDataMatch = xmlStr:match("<BlossomCandy>.*</BlossomCandy>")
  local serializedData = StatsXML_Serialize(data, 4)
  
  if bcDataMatch then
    xmlStr = xmlStr:gsub("<BlossomCandy>.*</BlossomCandy>", "<BlossomCandy>\n" .. serializedData .. "\n  </BlossomCandy>")
  else
    local insertPos = xmlStr:match("</Stats>")
    if insertPos then
      xmlStr = xmlStr:gsub("</Stats>", "  <BlossomCandy>\n" .. serializedData .. "\n  </BlossomCandy>\n</Stats>")
    else
      xmlStr = [[<?xml version="1.0" encoding="utf-8"?>
<Stats>
  <BlossomCandy>
]] .. serializedData .. [[
  </BlossomCandy>
</Stats>]]
    end
  end
  
  local outFile = RageFileUtil.CreateRageFile()
  if outFile:Open(statsPath, 2) then
    outFile:Write(xmlStr)
    outFile:Close()
    outFile:destroy()
    BlossomStats.data = data
    return true
  end
  
  outFile:destroy()
  return false
end

function StatsXML_Serialize(data, indent)
  indent = indent or 0
  local spaces = string.rep(" ", indent)
  local lines = {}
  
  for k, v in pairs(data) do
    local key = type(k) == "string" and string.format("[%q]", k) or "[" .. k .. "]"
    if type(v) == "table" then
      table.insert(lines, spaces .. key .. " = {\n" .. StatsXML_Serialize(v, indent + 2) .. spaces .. "},")
    elseif type(v) == "string" then
      table.insert(lines, spaces .. key .. " = \"" .. v .. "\",")
    elseif type(v) == "boolean" then
      table.insert(lines, spaces .. key .. " = " .. (v and "true" or "false") .. ",")
    elseif type(v) == "number" then
      table.insert(lines, spaces .. key .. " = " .. v .. ",")
    else
      table.insert(lines, spaces .. key .. " = nil,")
    end
  end
  
  return table.concat(lines, "\n")
end

function StatsXML_GetBlossomData()
  if not BlossomStats.loaded then
    StatsXML_Load()
  end
  return BlossomStats.data
end

function StatsXML_SetBlossomData(data)
  BlossomStats.data = data
  StatsXML_Save(data)
end

function StatsXML_ClearCache()
  BlossomStats.data = nil
  BlossomStats.loaded = false
end

function StatsXML_Reload()
  BlossomStats.data = nil
  BlossomStats.loaded = false
  return StatsXML_Load()
end

function StatsXML_OnProfileChanged()
  StatsXML_Reload()
  BCLoadRatingCache()
  if BCPlayerConfig then
    BCPlayerConfig:load()
  end
end