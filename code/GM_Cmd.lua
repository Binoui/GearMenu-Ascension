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
      return
    end
    
    local args = {}

    if mod.logger then
    end

    -- parse arguments by whitespace
    for arg in string.gmatch(msg, "%S+") do
      table.insert(args, arg)
    end

    if args[1] == "" or args[1] == "help" or #args == 0 then
      ShowInfoMessage()
    elseif args[1] == "rl" or args[1] == "reload" then
      ReloadUI()
    elseif args[1] == "memory" or args[1] == "mem" then
      -- Memory diagnostics
      local tickerCount = 0
      
      -- Check tickers
      if mod.ticker then
        if mod.ticker.combatQueueTicker and not mod.ticker.combatQueueTicker:IsCancelled() then
          tickerCount = tickerCount + 1
        end
        if mod.ticker.changeMenuTicker and not mod.ticker.changeMenuTicker:IsCancelled() then
          tickerCount = tickerCount + 1
        end
        if mod.ticker.rangeCheckTicker and not mod.ticker.rangeCheckTicker:IsCancelled() then
          tickerCount = tickerCount + 1
        end
      end
      
      print("|cFF00FFB0GearMenu Memory Info:|r")
      print("Active Tickers: " .. tickerCount)
      print("|cFFFF0000Note:|r If you see 'out of memory' errors:")
      print("1. /rggm rl - Reload UI to clear memory")
      print("2. Disable other addons to test")
      print("3. Check if errors persist without GearMenu")
    elseif args[1] == "opt" then
      if mod.addonConfiguration and mod.addonConfiguration.OpenMainCategory then
        mod.addonConfiguration.OpenMainCategory()
      else
      end
    else
      if mod.logger then
        mod.logger.PrintUserError(rggm.L["invalid_argument"])
      else
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
      ShowInfoMessage()
    elseif args[1] == "rl" or args[1] == "reload" then
      ReloadUI()
    elseif args[1] == "opt" then
      if rggm.addonConfiguration and rggm.addonConfiguration.OpenMainCategory then
        rggm.addonConfiguration.OpenMainCategory()
      else
        if mod.logger then
          mod.logger.PrintUserError("Configuration module not loaded. Try /reload")
        end
      end
    else
      if mod.logger then
        mod.logger.PrintUserError(rggm.L["invalid_argument"])
      end
    end
  end
  
end
