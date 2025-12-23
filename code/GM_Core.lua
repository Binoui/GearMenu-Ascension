--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- luacheck: globals GetAddOnMetadata ChannelInfo C_Timer

-- Initialize rggm namespace if it doesn't exist
rggm = rggm or {}
local me = rggm

me.tag = "Core"

-- Ensure the main frame exists (created by XML)
-- This will be set when the XML frame loads
me.mainFrame = nil

-- Debug: Print when core module loads (helps diagnose loading issues)
if not me._loaded then
  me._loaded = true
end

local initializationDone = false
local hasInitialized = false -- Track if we've already initialized

--[[
  Hook GetLocale to return a fixed value. This is used for testing only.
]]--

--[[
local _G = getfenv(0)

function _G.GetLocale()
  return "[language code]"
end
]]--

--[[
  Addon load

  @param {table} self
]]--
function me.OnLoad(self)
  -- Store reference to main frame
  me.mainFrame = self
  
  -- Register events
  me.RegisterEvents(self)
end

--[[
  Register addon events

  @param {table} self
]]--
function me.RegisterEvents(self)
  -- Fired when the player logs in, /reloads the UI, or zones between map instances
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  -- Fires when a bags inventory changes
  self:RegisterEvent("BAG_UPDATE")
  -- Fires when the player equips or unequips an item
  self:RegisterEvent("UNIT_INVENTORY_CHANGED")
  -- Fires when the player leaves combat status
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
  -- Fires when the player enters combat status
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  -- Fires when a player resurrects after being in spirit form
  self:RegisterEvent("PLAYER_UNGHOST")
  -- Fires when the player's spirit is released after death or when the player accepts a resurrection without releasing
  self:RegisterEvent("PLAYER_ALIVE")
  -- Fires when a cooldown update call is sent to a bag
  self:RegisterEvent("BAG_UPDATE_COOLDOWN")
  -- Fires when the keybindings are changed.
  self:RegisterEvent("UPDATE_BINDINGS")
  -- Fires when a spell is cast successfully. Event is received even if spell is resisted.
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  -- Fires when a unit's spellcast is interrupted
  self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
  -- Fires when the player is affected by some sort of control loss
  -- Note: These events may not exist in 3.3.5, but registering them is safe
  self:RegisterEvent("LOSS_OF_CONTROL_ADDED")
  self:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
  -- Register to the event that fires when the players target changes
  self:RegisterEvent("PLAYER_TARGET_CHANGED")
  -- Fired when a unit stops channeling
  self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
end

--[[
  MainFrame OnEvent handler

  @param {string} event
  @param {table} vararg
]]--
function me.OnEvent(event, ...)
  if event == "PLAYER_ENTERING_WORLD" then
    -- In WoW 3.3.5, PLAYER_ENTERING_WORLD may not have the same parameters
    -- Initialize on first PLAYER_ENTERING_WORLD event if not already done
    if not hasInitialized then
      hasInitialized = true
      
      -- Delay initialization slightly to ensure all modules are loaded
      if C_Timer and C_Timer.After then
        C_Timer.After(0.5, function()
          me.Initialize()
        end)
      else
        -- Fallback if C_Timer not available - use a simple frame timer
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.5 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            me.Initialize()
          end
        end)
        frame:Show()
      end
    end
  elseif event == "BAG_UPDATE" then

    if initializationDone then
      -- trigger UpdateChangeMenu again to update items after an item was equipped
      if _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_FRAME]:IsVisible() then
        me.gearBarChangeMenu.UpdateChangeMenu()
      end

      if me.configuration.IsTrinketMenuEnabled() then
        me.trinketMenu.UpdateTrinketMenu()
      end
    end
  elseif event == "UNIT_INVENTORY_CHANGED" then
    local unit = ...

    if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER and initializationDone then
      me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarVisual)
      if me.configuration.IsTrinketMenuEnabled() then
        me.trinketMenu.UpdateTrinketMenu()
      end
    end
  elseif event == "BAG_UPDATE_COOLDOWN" then

    if initializationDone then
      me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarGearSlotCooldowns)
      if me.configuration.IsTrinketMenuEnabled() then
        me.trinketMenu.UpdateTrinketMenuSlotCooldowns()
      end
    end
  elseif event == "UPDATE_BINDINGS" then

    --[[
      On starting up the addon often times GetBindingAction will not return the correct keybinding set but rather an
      empty string. To prevent this a slight delay is required.

      In case GetBindingAction returns an empty string GearMenu will loose the connection of its keybind. This means
      that GearMenu is unable to show the shortcuts in the GearBar anymore but the keybinds will continue to work.
    ]]--
    -- Only process keybind updates if initialization is done
    if initializationDone and me.keyBind and me.keyBind.OnUpdateKeyBindings then
      if C_Timer and C_Timer.After then
        C_Timer.After(RGGM_CONSTANTS.KEYBIND_UPDATE_DELAY, me.keyBind.OnUpdateKeyBindings)
      else
        -- Fallback if C_Timer not available
        me.keyBind.OnUpdateKeyBindings()
      end
    end
  elseif event == "LOSS_OF_CONTROL_ADDED" then

    if initializationDone then
      me.combatQueue.UpdateEquipChangeBlockStatus()
    end
  elseif event == "LOSS_OF_CONTROL_UPDATE" then

    if initializationDone then
      me.combatQueue.UpdateEquipChangeBlockStatus()
    end
  -- Note: LOSS_OF_CONTROL events may not exist in 3.3.5, but we handle them gracefully if they do
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unit = ...

    if initializationDone then
      local channelledSpell = ChannelInfo(RGGM_CONSTANTS.UNIT_ID_PLAYER)

      if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER and not channelledSpell then
        me.quickChange.OnUnitSpellCastSucceeded(...)
        me.combatQueue.ProcessQueue()
      end
    end
  elseif event == "UNIT_SPELLCAST_INTERRUPTED" then

    local unit = ...

    if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER and initializationDone then
      me.combatQueue.ProcessQueue()
    end
  elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then

    local unit = ...

    if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER and initializationDone then
      me.combatQueue.ProcessQueue()
    end
  elseif (event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE")
    and not me.common.IsPlayerReallyDead() then
      if event == "PLAYER_REGEN_ENABLED" then
      elseif event == "PLAYER_UNGHOST" then
      elseif event == "PLAYER_ALIVE" then
      end

      if initializationDone then
        -- player is alive again or left combat - work through all combat queues
        me.ticker.StartTickerCombatQueue()
      end
  elseif event == "PLAYER_REGEN_DISABLED" then

    if initializationDone then
      me.ticker.StopTickerCombatQueue()
    end
  elseif event == "PLAYER_TARGET_CHANGED" then

    if initializationDone then
      me.target.UpdateCurrentTarget()
    end
  end
end

--[[
  Initialize addon
]]--
function me.Initialize()
  -- Safety check: ensure logger exists
  if not me.logger then
    return
  end
  
  -- Wrap initialization in error handler
  local success, err = pcall(function()
    -- Check all required modules exist and provide detailed error messages
    local missingModules = {}
    if not me.cmd then
      table.insert(missingModules, "cmd (GM_Cmd.lua)")
    end
    if not me.configuration then
      table.insert(missingModules, "configuration (GM_Configuration.lua)")
    end
    if not me.addonConfiguration then
      table.insert(missingModules, "addonConfiguration (GM_AddonConfiguration.lua)")
    end
    if not me.themeCoordinator then
      table.insert(missingModules, "themeCoordinator (GM_ThemeCoordinator.lua)")
    end
    if not me.gearBar then
      table.insert(missingModules, "gearBar (GM_GearBar.lua)")
    end
    if not me.gearBarChangeMenu then
      table.insert(missingModules, "gearBarChangeMenu (GM_GearBarChangeMenu.lua)")
    end
    
    if #missingModules > 0 then
      error("Missing required modules: " .. table.concat(missingModules, ", ") .. ". Please check that all files are loaded correctly.")
    end
    
    -- setup slash commands
    me.cmd.SetupSlashCmdList()
    -- load addon variables
    me.configuration.SetupConfiguration()
    -- setup addon configuration ui
    me.addonConfiguration.SetupAddonConfiguration()
    -- sync up theme (needs to be happening before accessing ui elements)
    me.themeCoordinator.UpdateTheme()
    -- initialize secure equip buttons for weapons in combat
    if me.itemManager and me.itemManager.InitializeSecureEquipButtons then
      me.itemManager.InitializeSecureEquipButtons()
    end
    -- build ui for all gearBars
    me.gearBar.BuildGearBars()
    -- build ui for changeMenu
    me.gearBarChangeMenu.BuildChangeMenu()
    -- update initial view of gearBars after addon initialization
    me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarVisual)

    if me.configuration.IsTrinketMenuEnabled() then
      -- build ui for trinketMenu
      if me.trinketMenu then
        me.trinketMenu.BuildTrinketMenu()
        -- update initial view of trinketMenu
        me.trinketMenu.UpdateTrinketMenu()
      end
    end

    -- initialization is done
    initializationDone = true

    me.ShowWelcomeMessage()
  end)
  
  if not success then
    local errorMsg = "|cffff0000GearMenu Initialization Error:|r " .. tostring(err)
    if me.logger then
      me.logger.LogError(me.tag, "Initialization failed: " .. tostring(err))
      -- Note: debug.traceback() is not available in WoW 3.3.5
      -- The error message already contains the stack trace information
    end
    -- Try to show error in chat
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage(errorMsg)
    end
  end
end

--[[
  Show welcome message to user
]]--
function me.ShowWelcomeMessage()
  local version = GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version") or "Unknown"
  print(
    string.format("|cFF00FFB0" .. RGGM_CONSTANTS.ADDON_NAME .. "|r " .. rggm.L["help"], version)
  )
end
