-- Blossom Candy Theme - Lua Config System
-- Simplified config management inspired by spawncamping-wallhack
-- Auto-loaded globally at startup

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

-- Merge tables (src into dest)
local function MergeTables(dest, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dest[k]) == "table" then
      MergeTables(dest[k], v)
    else
      dest[k] = v
    end
  end
  return dest
end

-- Create a lua config manager
-- @param cfg: table with name, file, default, match_depth
function create_lua_config(cfg)
  local config = {
    name = cfg.name or "config",
    file = cfg.file or "config.lua",
    default = cfg.default or {},
    data = {},
    loaded = false,
    
    -- Get current data (load if not loaded)
    get_data = function(self)
      if not self.loaded then
        self:load()
      end
      return self.data
    end,
    
    -- Set data value
    set = function(self, key, value)
      self.data[key] = value
    end,
    
    -- Get data value
    get = function(self, key, default_value)
      return self.data[key] or default_value
    end,
    
    -- Load config from profile directory
    load = function(self)
      self.data = CopyTable(self.default)
      
      -- Try to load from current profile
      local profileDir = nil
      if PROFILEMAN and GAMESTATE then
        for _, pn in ipairs({PLAYER_1, PLAYER_2}) do
          if PROFILEMAN:IsPersistentProfile(pn) then
            -- Construct path using player number (API doesn't expose profile ID directly)
            local playerStr = (pn == PLAYER_1) and "P1" or "P2"
            profileDir = "Save/LocalProfiles/Player_" .. playerStr
            break
          end
        end
      end
      
      if profileDir then
        local filepath = profileDir .. "/" .. self.file
        local chunk = loadfile(filepath)
        if chunk then
          local loaded = chunk()
          if loaded and type(loaded) == "table" then
            MergeTables(self.data, loaded)
          end
        end
      end
      
      self.loaded = true
      return self.data
    end,
    
    -- Save config to profile directory
    save = function(self)
      local profileDir = nil
      local pn_save = nil
      
      if PROFILEMAN and GAMESTATE then
        for _, pn in ipairs({PLAYER_1, PLAYER_2}) do
          if PROFILEMAN:IsPersistentProfile(pn) then
            -- Construct path using player number (API doesn't expose profile ID directly)
            local playerStr = (pn == PLAYER_1) and "P1" or "P2"
            profileDir = "Save/LocalProfiles/Player_" .. playerStr
            pn_save = pn
            break
          end
        end
      end
      
      if not profileDir then return false end
      
      local filepath = profileDir .. "/" .. self.file
      local f = RageFileUtil.CreateRageFile()
      
      if f:Open(filepath, RageFile.WRITE) then
        local function serialize(t, indent)
          indent = indent or 0
          local spaces = string.rep("  ", indent)
          local lines = {}
          
          for k, v in pairs(t) do
            local key = type(k) == "string" and string.format("%q", k) or "[" .. k .. "]"
            if type(v) == "table" then
              table.insert(lines, spaces .. key .. " = {")
              table.insert(lines, serialize(v, indent + 1))
              table.insert(lines, spaces .. "},")
            elseif type(v) == "string" then
              table.insert(lines, spaces .. key .. " = " .. string.format("%q", v) .. ",")
            elseif type(v) == "boolean" then
              table.insert(lines, spaces .. key .. " = " .. (v and "true" or "false") .. ",")
            elseif type(v) == "number" then
              table.insert(lines, spaces .. key .. " = " .. v .. ",")
            else
              table.insert(lines, spaces .. key .. " = " .. string.format("%q", tostring(v)) .. ",")
            end
          end
          
          return table.concat(lines, "\n")
        end
        
        local out = "return {\n" .. serialize(self.data, 1) .. "}\n"
        f:Write(out)
        f:Close()
        f:destroy()
        return true
      end
      
      f:destroy()
      return false
    end,
    
    -- Reset to defaults
    reset = function(self)
      self.data = CopyTable(self.default)
      self.loaded = true
    end
  }
  
  return config
end

-- Add standard save/load hooks that trigger on screen changes
function add_standard_lua_config_save_load_hooks(config)
  -- Hook into profile load/save via screen messages
  -- This will be called by BGAnimations that need to handle profile changes
  
  if not BCLuaConfigHooks then
    BCLuaConfigHooks = {}
  end
  
  table.insert(BCLuaConfigHooks, {
    config = config,
    load = function() config:load() end,
    save = function() config:save() end
  })
end

-- Call this when a profile is loaded (e.g., in ScreenSelectMusic init)
function BCLuaConfig_LoadAll()
  if BCLuaConfigHooks then
    for _, hook in ipairs(BCLuaConfigHooks) do
      pcall(hook.load)
    end
  end
end

-- Call this when saving (e.g., in ScreenGameplay OffCommand)
function BCLuaConfig_SaveAll()
  if BCLuaConfigHooks then
    for _, hook in ipairs(BCLuaConfigHooks) do
      pcall(hook.save)
    end
  end
end

-- Default player config (moved from separate file)
local defaultPlayerConfig = {
  -- Timing/Judgment settings
  judgmentScale = 1.0,
  judgmentOffset = 0,
  
  -- Speed settings
  speedModType = "C",  -- C, M, or X
  speedModValue = 400,
  
  -- Scroll direction
  reverseScroll = false,
  
  -- Note skin
  noteSkin = "default",
  
  -- Modifiers
  mini = 0,
  hidden = 0,
  sudden = 0,
  stealth = false,
  mirror = false,
  left = false,
  right = false,
  shuffle = false,
  
  -- Appearance
  screenFilter = 0,
  darkBackground = false,
  
  -- Scoring (from bc_prefs)
  scoringSystem = "BC",
  showLifeGraph = true,
  showDPPercent = true,
  
  -- Theme settings
  autoPreview = true,
  previewDelay = 1.2,
}

-- Create global player config
BCPlayerConfig = create_lua_config({
  name = "BCPlayerConfig",
  file = "BlossomCandyConfig.lua",
  default = defaultPlayerConfig
})

-- Add hooks for auto save/load
add_standard_lua_config_save_load_hooks(BCPlayerConfig)
