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

-- luacheck: globals GetItemInfo C_LossOfControl InCombatLockdown INVSLOT_MAINHAND INVSLOT_OFFHAND

local mod = rggm
local me = {}
mod.combatQueue = me

me.tag = "CombatQueue"

local combatQueueStore = {}
--[[
  Tracks whether an equipment change is blocked or not based on loss of control effects.
  Does not include other possible states suchs as in combat that can prevent an equipment change
]]--
local isEquipChangeBlocked = false

--[[
  Getter for combatQueueStore

  @return {table}
]]--
function me.GetCombatQueueStore()
  return combatQueueStore
end

--[[
  Add item to combatQueue. There can only be one item per slot

  @param {number} itemId
  @param {number} slotId
]]--
function me.AddToQueue(itemId, slotId)
  if not itemId or not slotId then return end

  combatQueueStore[slotId] = itemId
  mod.gearBar.UpdateCombatQueue(slotId, itemId)
  mod.ticker.StartTickerCombatQueue()
end

--[[
  Remove item from combatQueue

  @param {number} slotId
]]--
function me.RemoveFromQueue(slotId)
  if not slotId then return end

  -- get item from queue that is about to be removed
  local itemId = combatQueueStore[slotId]

  -- if no item is registered in queue for that specific slotId
  if itemId == nil then
    return
  end

  combatQueueStore[slotId] = nil
  mod.gearBar.UpdateCombatQueue(slotId)
end

--[[
  Process through combat queue and equip item if there is one waiting in the queue
]]--
function me.ProcessQueue()
  if me.IsCombatQueueEmpty() then
    -- stop combat queue ticker when combat queue is empty
    mod.ticker.StopTickerCombatQueue()
    return
  end

  -- Weapons (main hand and offhand) can be switched during combat
  -- Other items cannot be changed while player is in combat or is casting
  local inCombatLockdown = InCombatLockdown()
  local isCasting = mod.common.IsPlayerCasting()
  local isDead = mod.common.IsPlayerReallyDead()
  
  if isDead then return end
  
  -- update queue for all slotpositions
  for _, gearSlot in pairs(mod.gearManager.GetGearSlots()) do
    if combatQueueStore[gearSlot.slotId] ~= nil then
      local isWeaponSlot = (gearSlot.slotId == INVSLOT_MAINHAND or gearSlot.slotId == INVSLOT_OFFHAND)
      
      -- For weapons, allow switching even if InCombatLockdown() is true
      -- Weapons can be switched in combat in WoW 3.3.5
      if isWeaponSlot and not isCasting then
        -- Weapons can be switched in combat, bypass InCombatLockdown check
        mod.itemManager.EquipItemById(combatQueueStore[gearSlot.slotId], gearSlot.slotId)
        mod.gearBar.UpdateCombatQueue(gearSlot.slotId, combatQueueStore[gearSlot.slotId])
      elseif not inCombatLockdown and not isCasting then
        -- Non-weapon items: only proceed if not in combat lockdown and not casting
        mod.itemManager.EquipItemById(combatQueueStore[gearSlot.slotId], gearSlot.slotId)
        mod.gearBar.UpdateCombatQueue(gearSlot.slotId, combatQueueStore[gearSlot.slotId])
      end
      -- If in combat lockdown with non-weapon or casting, skip this item (it will be processed later)
    end
  end
end

--[[
  @return {boolean}
    true - If the combatQueue is completely empty
    false - If the combatQueue is not empty
]]--
function me.IsCombatQueueEmpty()
  if next(combatQueueStore) == nil then
    return true
  end

  return false
end

--[[
  Checks whether the player has a loss of control effect on him that prevents him from changing equipment.

  Possible values for locType:

  | SCHOOL_INTERRUPT | IRRELEVANT |
  | DISARM           | IRRELEVANT |
  | PACIFYSILENCE    | IRRELEVANT |
  | SILENCE          | IRRELEVANT |
  | PACIFY           | IRRELEVANT |
  | ROOT             | IRRELEVANT |
  | STUN_MECHANIC    | RELEVANT   |
  | STUN             | RELEVANT   |
  | FEAR_MECHANIC    | RELEVANT   |
  | FEAR             | RELEVANT   |
  | CHARM            | RELEVANT   |
  | CONFUSE          | RELEVANT   |
  | POSSESS          | RELEVANT   |
]]--
function me.UpdateEquipChangeBlockStatus()
  local relevantLocTypes = {
    ["SCHOOL_INTERRUPT"] = false,
    ["DISARM"] = false,
    ["PACIFYSILENCE"] = false,
    ["SILENCE"] = false,
    ["PACIFY"] = false,
    ["ROOT"] = false,
    ["STUN_MECHANIC"] = true,
    ["STUN"] = true,
    ["FEAR_MECHANIC"] = true,
    ["FEAR"] = true,
    ["CHARM"] = true,
    ["CONFUSE"] = true,
    ["POSSESS"] = true
  }
  -- In WoW 3.3.5, C_LossOfControl doesn't exist, so we can't detect loss of control effects
  -- The compatibility layer returns 0 count, so this loop won't execute
  -- This means isEquipChangeBlocked will remain false, which is acceptable for 3.3.5
  local eventIndex = C_LossOfControl.GetActiveLossOfControlDataCount()

  while eventIndex > 0 do
    local event = C_LossOfControl.GetActiveLossOfControlData(eventIndex)
    
    if event and event.locType then

      if relevantLocTypes[event.locType] then
        isEquipChangeBlocked = true
        return
      end
    end

    eventIndex = eventIndex - 1
  end

  isEquipChangeBlocked = false
  mod.ticker.StartTickerCombatQueue()
end

--[[
  @return {boolean}
    true - If equipment change is blocked
    false - If equipment change is not blocked
]]--
function me.IsEquipChangeBlocked()
  return isEquipChangeBlocked
end
