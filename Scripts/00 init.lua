-- Blossom Candy Theme - Initialization
-- This file loads all theme scripts in the correct order

Trace("Blossom-Candy: Starting theme initialization...")

-- Load scripts in dependency order
dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_colors.lua")
Trace("Blossom-Candy: Loaded bc_colors.lua")

dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_scoring.lua")
Trace("Blossom-Candy: Loaded bc_scoring.lua")

dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_prefs.lua")
Trace("Blossom-Candy: Loaded bc_prefs.lua")

dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_statsxml.lua")
Trace("Blossom-Candy: Loaded bc_statsxml.lua")

dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_pp.lua")
Trace("Blossom-Candy: Loaded bc_pp.lua")

dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_score.lua")
Trace("Blossom-Candy: Loaded bc_score.lua")

dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_lua_config.lua")
Trace("Blossom-Candy: Loaded bc_lua_config.lua")

dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_rating.lua")
Trace("Blossom-Candy: Loaded bc_rating.lua")

dofile(THEME:GetCurrentThemeDirectory() .. "Scripts/bc_profile.lua")
Trace("Blossom-Candy: Loaded bc_profile.lua")

Trace("Blossom-Candy: Theme initialization complete!")
Trace("Blossom-Candy: getCurRateValue = " .. tostring(getCurRateValue))
Trace("Blossom-Candy: LoadBCProfile = " .. tostring(LoadBCProfile))
Trace("Blossom-Candy: BCScoreKey = " .. tostring(BCScoreKey))
