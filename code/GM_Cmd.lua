--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

-- luacheck: globals SLASH_GEARMENU1 SLASH_GEARMENU2 SlashCmdList ReloadUI

local mod = rggm
local me = {}
mod.cmd = me

me.tag = "Cmd"

--[[
  Print cmd options for addon
]]--
local function ShowInfoMessage()
  print(rggm.L["info_title"])
  print(rggm.L["reload"])
  print(rggm.L["opt"])
end

--[[
  Setup slash command handler
]]--
function me.SetupSlashCmdList()
  SLASH_GEARMENU1 = "/rggm"
  SLASH_GEARMENU2 = "/gearmenu"

  SlashCmdList["GEARMENU"] = function(msg)
    -- Safety check: ensure addon is initialized
    if not mod or not mod.Initialize then
      print("|cffff0000GearMenu Error:|r Addon not initialized. Please reload UI.")
      return
    end
    
    local args = {}

    if mod.logger then
      mod.logger.LogDebug(me.tag, "/rggm passed argument: " .. msg)
    end

    -- parse arguments by whitespace
    for arg in string.gmatch(msg, "%S+") do
      table.insert(args, arg)
    end

    if args[1] == "" or args[1] == "help" or #args == 0 then
      ShowInfoMessage()
    elseif args[1] == "rl" or args[1] == "reload" then
      ReloadUI()
    elseif args[1] == "opt" then
      if mod.addonConfiguration and mod.addonConfiguration.OpenMainCategory then
        mod.addonConfiguration.OpenMainCategory()
      else
        print("|cffff0000GearMenu Error:|r Configuration module not loaded.")
      end
    else
      if mod.logger then
        mod.logger.PrintUserError(rggm.L["invalid_argument"])
      else
        print("|cffff0000GearMenu:|r Invalid argument")
      end
    end
  end
end

-- Register slash commands immediately when file loads (not waiting for initialization)
-- This ensures commands work even if initialization fails
do
  SLASH_GEARMENU1 = "/rggm"
  SLASH_GEARMENU2 = "/gearmenu"
  
  SlashCmdList["GEARMENU"] = function(msg)
    -- If addon is not initialized, try to show basic help
    if not rggm or not rggm.cmd then
      print("|cFF00FFB0GearMenu:|r Addon is loading or not initialized.")
      print("|cFF00FFB0GearMenu:|r Use /reload to reload the UI.")
      return
    end
    
    -- Use the proper command handler if available
    if rggm.cmd.SetupSlashCmdList then
      -- Re-register to ensure it's set up
      rggm.cmd.SetupSlashCmdList()
    end
    
    -- Call the handler
    local args = {}
    for arg in string.gmatch(msg or "", "%S+") do
      table.insert(args, arg)
    end
    
    if args[1] == "" or args[1] == "help" or #args == 0 then
      print("|cFF00FFB0GearMenu:|r Use |cFFFFC300/rggm|r or |cFFFFC300/gearmenu|r for a list of options")
      print("|cFFFFC300opt|r - display Options menu")
      print("|cFFFFC300reload|r - reload UI")
    elseif args[1] == "rl" or args[1] == "reload" then
      ReloadUI()
    elseif args[1] == "opt" then
      print("|cFF00FFB0GearMenu:|r Attempting to open options...")
      if rggm.addonConfiguration and rggm.addonConfiguration.OpenMainCategory then
        print("|cFF00FFB0GearMenu:|r Calling OpenMainCategory...")
        rggm.addonConfiguration.OpenMainCategory()
      else
        print("|cffff0000GearMenu Error:|r Configuration module not loaded.")
        if not rggm.addonConfiguration then
          print("|cffff0000  - addonConfiguration is nil")
        elseif not rggm.addonConfiguration.OpenMainCategory then
          print("|cffff0000  - OpenMainCategory function not found")
        end
        print("|cffff0000GearMenu:|r Try /reload to reload the UI")
      end
    else
      print("|cffff0000GearMenu:|r Invalid argument")
    end
  end
  
  print("|cFF00FFB0GearMenu:|r Slash commands registered")
end
