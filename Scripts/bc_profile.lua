-- Blossom Candy Theme - Profile Management
-- Handles profile selection, auto-selection, and player options persistence

BCProfile = {}

-- Get number of local profiles
function BCProfile:GetNumProfiles()
  return PROFILEMAN:GetNumLocalProfiles()
end

-- Get profile info at index (0-based)
function BCProfile:GetProfileInfo(index)
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
      self:LoadPlayerOptionsFromProfile(pn)
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
    self:LoadPlayerOptionsFromProfile(pn)
    return profile
  end
  return nil
end

-- Get the currently loaded profile for a player
function BCProfile:GetCurrentProfile(pn)
  if PROFILEMAN:IsPersistentProfile(pn) then
    return PROFILEMAN:GetProfile(pn)
  end
  return nil
end

-- Check if a profile is loaded for a player
function BCProfile:HasProfileLoaded(pn)
  return PROFILEMAN:IsPersistentProfile(pn)
end

-- Save player options to profile
function BCProfile:SavePlayerOptionsToProfile(pn)
  local profile = self:GetCurrentProfile(pn)
  if not profile then return end

  local playerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")

  -- Save speed mod
  local speed = playerOptions:CMod() or playerOptions:MMod() or playerOptions:XMod()
  if speed and speed > 0 then
    profile:SavePreference("SpeedMod", tostring(speed))
    if playerOptions:CMod() > 0 then
      profile:SavePreference("SpeedModType", "C")
    elseif playerOptions:MMod() > 0 then
      profile:SavePreference("SpeedModType", "M")
    else
      profile:SavePreference("SpeedModType", "X")
    end
  end

  -- Save note skin
  local noteSkin = playerOptions:NoteSkin()
  if noteSkin then
    profile:SavePreference("NoteSkin", noteSkin)
  end

  -- Save scroll direction
  if playerOptions:Reverse() > 0 then
    profile:SavePreference("ScrollDirection", "Reverse")
  else
    profile:SavePreference("ScrollDirection", "Standard")
  end

  -- Save various options
  profile:SavePreference("Mini", tostring(playerOptions:Mini()))
  profile:SavePreference("Perspective", tostring(playerOptions:Perspective()))
  profile:SavePreference("Cover", tostring(playerOptions:Cover()))
  profile:SavePreference("Dark", tostring(playerOptions:Dark()))
  profile:SavePreference("Blind", tostring(playerOptions:Blind()))
  profile:SavePreference("RandAttack", tostring(playerOptions:RandAttack()))
  profile:SavePreference("NoAttack", tostring(playerOptions:NoAttack()))
  profile:SavePreference("PlayerAutoPlay", tostring(playerOptions:PlayerAutoPlay()))
  profile:SavePreference("JudgeType", tostring(playerOptions:JudgeType()))
  profile:SavePreference("Hidden", tostring(playerOptions:Hidden()))
  profile:SavePreference("HiddenOffset", tostring(playerOptions:HiddenOffset()))
  profile:SavePreference("Sudden", tostring(playerOptions:Sudden()))
  profile:SavePreference("SuddenOffset", tostring(playerOptions:SuddenOffset()))
  profile:SavePreference("Stealth", tostring(playerOptions:Stealth()))
  profile:SavePreference("Dizzy", tostring(playerOptions:Dizzy()))
  profile:SavePreference("Confusion", tostring(playerOptions:Confusion()))
  profile:SavePreference("Appearances", tostring(playerOptions:Appearances()))
  profile:SavePreference("TurnNone", tostring(playerOptions:TurnNone()))
  profile:SavePreference("Mirror", tostring(playerOptions:Mirror()))
  profile:SavePreference("Backwards", tostring(playerOptions:Backwards()))
  profile:SavePreference("Left", tostring(playerOptions:Left()))
  profile:SavePreference("Right", tostring(playerOptions:Right()))
  profile:SavePreference("Shuffle", tostring(playerOptions:Shuffle()))
  profile:SavePreference("SoftShuffle", tostring(playerOptions:SoftShuffle()))
  profile:SavePreference("SuperShuffle", tostring(playerOptions:SuperShuffle()))
  profile:SavePreference("NoHolds", tostring(playerOptions:NoHolds()))
  profile:SavePreference("NoRolls", tostring(playerOptions:NoRolls()))
  profile:SavePreference("NoMines", tostring(playerOptions:NoMines()))
  profile:SavePreference("Little", tostring(playerOptions:Little()))
  profile:SavePreference("Wide", tostring(playerOptions:Wide()))
  profile:SavePreference("Big", tostring(playerOptions:Big()))
  profile:SavePreference("Quick", tostring(playerOptions:Quick()))
  profile:SavePreference("BMRize", tostring(playerOptions:BMRize()))
  profile:SavePreference("Skippy", tostring(playerOptions:Skippy()))
  profile:SavePreference("Mines", tostring(playerOptions:Mines()))
  profile:SavePreference("Echo", tostring(playerOptions:Echo()))
  profile:SavePreference("Stomp", tostring(playerOptions:Stomp()))
  profile:SavePreference("Planted", tostring(playerOptions:Planted()))
  profile:SavePreference("Floored", tostring(playerOptions:Floored()))
  profile:SavePreference("Twister", tostring(playerOptions:Twister()))
  profile:SavePreference("HoldRolls", tostring(playerOptions:HoldRolls()))
  profile:SavePreference("MuteOnError", tostring(playerOptions:MuteOnError()))
  profile:SavePreference("StretchNoScroll", tostring(playerOptions:StretchNoScroll()))
  profile:SavePreference("Pitch", tostring(playerOptions:Pitch()))
end

-- Load player options from profile
function BCProfile:LoadPlayerOptionsFromProfile(pn)
  local profile = self:GetCurrentProfile(pn)
  if not profile then return end

  local playerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")

  -- Load speed mod
  local speedType = profile:GetPreference("SpeedModType") or "C"
  local speedStr = profile:GetPreference("SpeedMod") or "400"
  local speed = tonumber(speedStr) or 400

  if speedType == "C" then
    playerOptions:CMod(speed)
  elseif speedType == "M" then
    playerOptions:MMod(speed)
  else
    playerOptions:XMod(speed / 100)
  end

  -- Load note skin
  local noteSkin = profile:GetPreference("NoteSkin")
  if noteSkin and noteSkin ~= "" then
    playerOptions:NoteSkin(noteSkin)
  end

  -- Load scroll direction
  local scrollDir = profile:GetPreference("ScrollDirection")
  if scrollDir == "Reverse" then
    playerOptions:Reverse(1)
  else
    playerOptions:Reverse(0)
  end

  -- Helper to load boolean preference
  local function loadBoolOpt(prefName, optFunc)
    local val = profile:GetPreference(prefName)
    if val then
      local num = tonumber(val) or 0
      optFunc(playerOptions, num)
    end
  end

  -- Load various options
  loadBoolOpt("Mini", function(po, v) po:Mini(v) end)
  loadBoolOpt("Perspective", function(po, v) po:Perspective(v) end)
  loadBoolOpt("Cover", function(po, v) po:Cover(v) end)
  loadBoolOpt("Dark", function(po, v) po:Dark(v) end)
  loadBoolOpt("Blind", function(po, v) po:Blind(v) end)
  loadBoolOpt("RandAttack", function(po, v) po:RandAttack(v) end)
  loadBoolOpt("NoAttack", function(po, v) po:NoAttack(v) end)
  loadBoolOpt("PlayerAutoPlay", function(po, v) po:PlayerAutoPlay(v) end)
  loadBoolOpt("JudgeType", function(po, v) po:JudgeType(v) end)
  loadBoolOpt("Hidden", function(po, v) po:Hidden(v) end)
  loadBoolOpt("HiddenOffset", function(po, v) po:HiddenOffset(v) end)
  loadBoolOpt("Sudden", function(po, v) po:Sudden(v) end)
  loadBoolOpt("SuddenOffset", function(po, v) po:SuddenOffset(v) end)
  loadBoolOpt("Stealth", function(po, v) po:Stealth(v) end)
  loadBoolOpt("Dizzy", function(po, v) po:Dizzy(v) end)
  loadBoolOpt("Confusion", function(po, v) po:Confusion(v) end)
  loadBoolOpt("Appearances", function(po, v) po:Appearances(v) end)
  loadBoolOpt("TurnNone", function(po, v) po:TurnNone(v) end)
  loadBoolOpt("Mirror", function(po, v) po:Mirror(v) end)
  loadBoolOpt("Backwards", function(po, v) po:Backwards(v) end)
  loadBoolOpt("Left", function(po, v) po:Left(v) end)
  loadBoolOpt("Right", function(po, v) po:Right(v) end)
  loadBoolOpt("Shuffle", function(po, v) po:Shuffle(v) end)
  loadBoolOpt("SoftShuffle", function(po, v) po:SoftShuffle(v) end)
  loadBoolOpt("SuperShuffle", function(po, v) po:SuperShuffle(v) end)
  loadBoolOpt("NoHolds", function(po, v) po:NoHolds(v) end)
  loadBoolOpt("NoRolls", function(po, v) po:NoRolls(v) end)
  loadBoolOpt("NoMines", function(po, v) po:NoMines(v) end)
  loadBoolOpt("Little", function(po, v) po:Little(v) end)
  loadBoolOpt("Wide", function(po, v) po:Wide(v) end)
  loadBoolOpt("Big", function(po, v) po:Big(v) end)
  loadBoolOpt("Quick", function(po, v) po:Quick(v) end)
  loadBoolOpt("BMRize", function(po, v) po:BMRize(v) end)
  loadBoolOpt("Skippy", function(po, v) po:Skippy(v) end)
  loadBoolOpt("Mines", function(po, v) po:Mines(v) end)
  loadBoolOpt("Echo", function(po, v) po:Echo(v) end)
  loadBoolOpt("Stomp", function(po, v) po:Stomp(v) end)
  loadBoolOpt("Planted", function(po, v) po:Planted(v) end)
  loadBoolOpt("Floored", function(po, v) po:Floored(v) end)
  loadBoolOpt("Twister", function(po, v) po:Twister(v) end)
  loadBoolOpt("HoldRolls", function(po, v) po:HoldRolls(v) end)
  loadBoolOpt("MuteOnError", function(po, v) po:MuteOnError(v) end)
  loadBoolOpt("StretchNoScroll", function(po, v) po:StretchNoScroll(v) end)
  loadBoolOpt("Pitch", function(po, v) po:Pitch(v) end)

  -- Apply the options
  GAMESTATE:GetPlayerState(pn):SetPlayerOptions("ModsLevel_Preferred", playerOptions)
  GAMESTATE:GetPlayerState(pn):SetPlayerOptions("ModsLevel_Stage", playerOptions)
  GAMESTATE:GetPlayerState(pn):SetPlayerOptions("ModsLevel_Song", playerOptions)
  GAMESTATE:GetPlayerState(pn):SetPlayerOptions("ModsLevel_Current", playerOptions)
end

-- Save profile to disk
function BCProfile:SaveProfile(pn)
  if PROFILEMAN:IsPersistentProfile(pn) then
    self:SavePlayerOptionsToProfile(pn)
    PROFILEMAN:SaveLocalProfile(pn)
  end
end

-- Get profile display name
function BCProfile:GetProfileDisplayName(pn)
  local profile = self:GetCurrentProfile(pn)
  if profile then
    return profile:GetDisplayName()
  end
  return "Guest"
end
