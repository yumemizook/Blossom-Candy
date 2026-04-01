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
    
    -- Load config from Stats.xml
    load = function(self)
      self.data = CopyTable(self.default)
      
      local data = StatsXML_GetBlossomData()
      if data and data.playerConfig then
        MergeTables(self.data, data.playerConfig)
      end
      
      self.loaded = true
      return self.data
    end,
    
    -- Save config to Stats.xml
    save = function(self)
      local data = StatsXML_GetBlossomData() or {}
      data.playerConfig = CopyTable(self.data)
      return StatsXML_SetBlossomData(data)
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
  default = defaultPlayerConfig
})

-- Add hooks for auto save/load
add_standard_lua_config_save_load_hooks(BCPlayerConfig)
