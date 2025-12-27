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

-- Initialize rggm namespace if it doesn't exist
rggm = rggm or {}

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
      -- Check if user wants all addons or just GearMenu
      local showAll = (args[2] == "all" or args[2] == "addons")
      
      if showAll then
        -- Show memory for all addons
        UpdateAddOnMemoryUsage()
        
        local addonList = {}
        local totalMemory = 0
        
        -- Collect all addon memory data
        for i = 1, GetNumAddOns() do
          local name, title, notes, enabled = GetAddOnInfo(i)
          if enabled then
            local memory = GetAddOnMemoryUsage(i)
            if memory > 0 then
              totalMemory = totalMemory + memory
              table.insert(addonList, {
                name = name,
                title = title or name,
                memory = memory
              })
            end
          end
        end
        
        -- Sort by memory (descending)
        table.sort(addonList, function(a, b) return a.memory > b.memory end)
        
        -- Get total Lua memory
        local luaMemoryKB = collectgarbage("count")
        local luaMemoryMB = math.floor((luaMemoryKB / 1024) * 100) / 100
        local addonMemoryMB = math.floor((totalMemory / 1024) * 100) / 100
        
        print("|cFF00FFB0=== All Addons Memory Usage ===|r")
        print("|cFFFFFF00Total Lua Memory:|r " .. luaMemoryMB .. " MB")
        print("|cFFFFFF00Total Addon Memory:|r " .. addonMemoryMB .. " MB (" .. math.floor(totalMemory) .. " KB)")
        print("|cFFFFFF00Other Lua Memory:|r " .. math.floor((luaMemoryKB - totalMemory) / 1024 * 100) / 100 .. " MB")
        print("")
        print("|cFF00FF00Top Addons by Memory:|r")
        
        -- Show top 20 addons
        local maxShow = math.min(20, #addonList)
        for i = 1, maxShow do
          local addon = addonList[i]
          local memMB = math.floor((addon.memory / 1024) * 100) / 100
          local color = "FFFFFF"
          if addon.memory > 50000 then -- > 50 MB
            color = "FF0000"
          elseif addon.memory > 20000 then -- > 20 MB
            color = "FFFF00"
          elseif addon.memory > 10000 then -- > 10 MB
            color = "FFAA00"
          end
          print(string.format("|c%s%6.2f MB|r |cFFAAAAAA(%6i KB)|r - %s", 
            color, memMB, math.floor(addon.memory), addon.title))
        end
        
        if #addonList > maxShow then
          print("|cFFAAAAAA... and " .. (#addonList - maxShow) .. " more addons|r")
        end
        
        print("")
        print("|cFF00FF00Tip:|r Use /rggm mem to see GearMenu details")
        print("|cFF00FF00Tip:|r Use /rggm gc to force garbage collection")
      else
        -- Show GearMenu memory only
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
        
        -- Get Lua memory usage (in KB)
        local luaMemoryKB = collectgarbage("count")
        local luaMemoryMB = math.floor((luaMemoryKB / 1024) * 100) / 100
        
        -- Get GearMenu addon memory
        UpdateAddOnMemoryUsage()
        local gearMenuMemory = GetAddOnMemoryUsage("GearMenu") or 0
        local gearMenuMemoryMB = math.floor((gearMenuMemory / 1024) * 100) / 100
        
        -- Get timer frame pool info
        local poolSize = 0
        if C_Timer and C_Timer._GetPoolSize then
          poolSize = C_Timer._GetPoolSize()
        end
        
        print("|cFF00FFB0=== GearMenu Memory Info ===|r")
        print("|cFFFFFF00GearMenu Memory:|r " .. gearMenuMemoryMB .. " MB (" .. math.floor(gearMenuMemory) .. " KB)")
        print("|cFFFFFF00Total Lua Memory:|r " .. luaMemoryMB .. " MB (" .. math.floor(luaMemoryKB) .. " KB)")
        print("|cFFFFFF00Active Tickers:|r " .. tickerCount)
        if poolSize > 0 then
          print("|cFFFFFF00Timer Pool Size:|r " .. poolSize)
        end
        print("")
        print("|cFFFF0000If you see 'out of memory' errors:|r")
        print("1. /rggm gc - Force garbage collection")
        print("2. /rggm rl - Reload UI to clear memory")
        print("3. /rggm mem all - Check all addons memory")
        print("4. Disable other addons to test")
        print("")
        print("|cFF00FF00Tip:|r Use /rggm mem all to see all addons")
    elseif args[1] == "gc" then
      -- Force garbage collection
      local beforeKB = collectgarbage("count")
      collectgarbage("collect")
      local afterKB = collectgarbage("count")
      local freedKB = math.floor((beforeKB - afterKB) * 100) / 100
      local freedMB = math.floor((freedKB / 1024) * 100) / 100
      
      print("|cFF00FFB0GearMenu:|r Garbage collection performed")
      print("|cFFFFFF00Freed:|r " .. freedMB .. " MB (" .. freedKB .. " KB)")
      print("|cFFFFFF00Current Memory:|r " .. math.floor((afterKB / 1024) * 100) / 100 .. " MB")
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
