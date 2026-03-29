-- Blossom Candy Theme - Profile Management (Simplified)
-- Uses lua config system for player options persistence

BCProfile = {}

-- Get number of local profiles
function BCProfile:GetNumProfiles()
  return PROFILEMAN:GetNumLocalProfiles()
end

-- Get profile info at index (0-based)
function BCProfile:GetProfileInfo(index)
  if not PROFILEMAN then return nil end
  
  local id = PROFILEMAN:GetLocalProfileIDFromIndex(index)
  if not id then return nil end
  
  local profile = PROFILEMAN:GetLocalProfile(id)
  if not profile then return nil end
  
  return {
    index = index,
    id = id,
    name = profile:GetDisplayName() or ("Player " .. (index + 1)),
    dir = profile:GetProfileDir(),
    highscore = profile:GetTotalHighScores() or 0
  }
end

-- Get all profiles as a table
function BCProfile:GetAllProfiles()
  local profiles = {}
  local count = self:GetNumProfiles()
  for i = 0, count - 1 do
    local info = self:GetProfileInfo(i)
    if info then
      table.insert(profiles, info)
    end
  end
  return profiles
end

-- Check if we should auto-select a profile (only 1 profile exists)
function BCProfile:ShouldAutoSelect()
  return self:GetNumProfiles() == 1
end

-- Auto-select the only profile for a player
function BCProfile:AutoSelectProfile(pn)
  if self:ShouldAutoSelect() then
    local profile = self:GetProfileInfo(0)
    if profile then
      PROFILEMAN:LoadLocalProfile(pn, profile.id)
      -- Load config after profile is loaded
      BCLuaConfig_LoadAll()
      return profile
    end
  end
  return nil
end

-- Load a specific profile by index for a player
function BCProfile:LoadProfileByIndex(pn, index)
  local profile = self:GetProfileInfo(index)
  if profile then
    PROFILEMAN:LoadLocalProfile(pn, profile.id)
    -- Load config after profile is loaded
    BCLuaConfig_LoadAll()
    return profile
  end
  return nil
end

-- Get the currently loaded profile for a player
function BCProfile:GetCurrentProfile(pn)
  if PROFILEMAN and PROFILEMAN:IsPersistentProfile(pn) then
    return PROFILEMAN:GetProfile(pn)
  end
  return nil
end

-- Check if a profile is loaded for a player
function BCProfile:HasProfileLoaded(pn)
  if PROFILEMAN then
    return PROFILEMAN:IsPersistentProfile(pn)
  end
  return false
end

-- Save profile to disk (config is auto-saved via hooks)
function BCProfile:SaveProfile(pn)
  if PROFILEMAN and PROFILEMAN:IsPersistentProfile(pn) then
    PROFILEMAN:SaveLocalProfile(pn)
  end
end

-- Get profile display name
function BCProfile:GetProfileDisplayName(pn)
  local profile = self:GetCurrentProfile(pn)
  if profile then
    local name = profile:GetDisplayName()
    if name and name ~= "" then
      return name
    end
  end
  return "Guest"
end

-- Check if any profiles exist
function BCProfile:HasProfiles()
  return self:GetNumProfiles() > 0
end

-- Apply player options from config to PlayerState
function BCProfile:ApplyPlayerOptionsFromConfig(pn)
  local config = BCPlayerConfig:get_data()
  local playerState = GAMESTATE:GetPlayerState(pn)
  if not playerState then return end
  
  local playerOptions = playerState:GetPlayerOptions("ModsLevel_Preferred")
  if not playerOptions then return end

  -- Apply speed mod
  local speedType = config.speedModType or "C"
  local speedValue = config.speedModValue or 400
  
  if speedType == "C" then
    playerOptions:CMod(speedValue)
  elseif speedType == "M" then
    playerOptions:MMod(speedValue)
  else
    playerOptions:XMod(speedValue / 100)
  end

  -- Apply note skin
  if config.noteSkin and config.noteSkin ~= "" then
    pcall(function() playerOptions:NoteSkin(config.noteSkin) end)
  end

  -- Apply scroll direction
  if config.reverseScroll then
    pcall(function() playerOptions:Reverse(1) end)
  else
    pcall(function() playerOptions:Reverse(0) end)
  end

  -- Apply various modifiers
  pcall(function() playerOptions:Mini(config.mini or 0) end)
  pcall(function() playerOptions:Hidden(config.hidden or 0) end)
  pcall(function() playerOptions:Sudden(config.sudden or 0) end)
  pcall(function() playerOptions:Stealth(config.stealth and 1 or 0) end)
  pcall(function() playerOptions:Mirror(config.mirror and 1 or 0) end)
  pcall(function() playerOptions:Left(config.left and 1 or 0) end)
  pcall(function() playerOptions:Right(config.right and 1 or 0) end)
  pcall(function() playerOptions:Shuffle(config.shuffle and 1 or 0) end)

  -- Apply to all levels
  playerState:SetPlayerOptions("ModsLevel_Preferred", playerOptions)
  playerState:SetPlayerOptions("ModsLevel_Stage", playerOptions)
  playerState:SetPlayerOptions("ModsLevel_Song", playerOptions)
  playerState:SetPlayerOptions("ModsLevel_Current", playerOptions)
end

-- Save player options to config from PlayerState
function BCProfile:SavePlayerOptionsToConfig(pn)
  local playerState = GAMESTATE:GetPlayerState(pn)
  if not playerState then return end
  
  local playerOptions = playerState:GetPlayerOptions("ModsLevel_Preferred")
  if not playerOptions then return end

  -- Get speed mod
  local cmod = playerOptions:CMod()
  local mmod = playerOptions:MMod()
  local xmod = playerOptions:XMod()
  
  if cmod and cmod > 0 then
    BCPlayerConfig:set("speedModType", "C")
    BCPlayerConfig:set("speedModValue", cmod)
  elseif mmod and mmod > 0 then
    BCPlayerConfig:set("speedModType", "M")
    BCPlayerConfig:set("speedModValue", mmod)
  elseif xmod and xmod > 0 then
    BCPlayerConfig:set("speedModType", "X")
    BCPlayerConfig:set("speedModValue", math.floor(xmod * 100))
  end

  -- Get note skin
  local noteSkin = playerOptions:NoteSkin()
  if noteSkin then
    BCPlayerConfig:set("noteSkin", noteSkin)
  end

  -- Get scroll direction
  BCPlayerConfig:set("reverseScroll", playerOptions:Reverse() > 0)

  -- Get various modifiers
  BCPlayerConfig:set("mini", playerOptions:Mini())
  BCPlayerConfig:set("hidden", playerOptions:Hidden())
  BCPlayerConfig:set("sudden", playerOptions:Sudden())
  BCPlayerConfig:set("stealth", playerOptions:Stealth() > 0)
  BCPlayerConfig:set("mirror", playerOptions:Mirror() > 0)
  BCPlayerConfig:set("left", playerOptions:Left() > 0)
  BCPlayerConfig:set("right", playerOptions:Right() > 0)
  BCPlayerConfig:set("shuffle", playerOptions:Shuffle() > 0)
  
  -- Save config
  BCPlayerConfig:save()
end

-- Get current player config data
function BCProfile:GetPlayerConfig()
  return BCPlayerConfig:get_data()
end
