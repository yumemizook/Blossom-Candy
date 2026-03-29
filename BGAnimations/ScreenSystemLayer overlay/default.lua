-- Hide system layer elements like "PRESS START" and "INSERT CARD"
-- This overlay hides the default system messages

return Def.ActorFrame {
  InitCommand = function(self)
    -- Hide system layer messages by covering them or finding them
    local screen = SCREENMAN:GetTopScreen()
    if screen then
      local syslayer = screen:GetChild("ScreenSystemLayer")
      if syslayer then
        syslayer:visible(false)
      end
    end
  end,
  
  OnCommand = function(self)
    self:queuecommand("HideSystemElements")
  end,
  
  HideSystemElementsCommand = function(self)
    local screen = SCREENMAN:GetTopScreen()
    if screen then
      -- Try to find and hide system messages
      local syslayer = screen:GetChild("ScreenSystemLayer")
      if syslayer then
        syslayer:visible(false)
      end
      
      -- Also try to find specific message actors
      local messages = {
        "Press Start",
        "PressStart",
        "Insert Card",
        "InsertCard",
        "Credit",
        "Credits"
      }
      
      for _, name in ipairs(messages) do
        local actor = screen:GetChild(name)
        if actor then
          actor:visible(false)
        end
      end
    end
  end
}
