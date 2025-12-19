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

-- luacheck: globals CreateFrame UIParent GetInventoryItemID GetCursorInfo STANDARD_TEXT_FONT
-- luacheck: globals GetInventoryItemLink GetItemInfo C_Container IsItemInRange InCombatLockdown
-- luacheck: globals CursorCanGoInSlot EquipCursorItem ClearCursor IsInventoryItemLocked PickupInventoryItem

--[[
  The gearBar (GM_Gearbar) module is responsible for building and showing gearBars to the user.
  A gearBar can have n amount of slots where the user can define different gearSlot types and keybinds to activate them.

  A gearBar is always bound to a gearBarConfiguration that was created in the ui configuration of the addon.
  This configuration tells the gearBar exactly how many slots it should have and how those are configured.
  The module responsible for holding and changing this information is the gearBarManager (GM_GearBarManager).
  The gearBar module however should never change values in the gearBarManager. Its sole purpose is to read
  all of the present configurations and display them exactly as described to the user.
]]--

local mod = rggm
local me = {}

mod.gearBar = me

me.tag = "GearBar"

--[[
  ELEMENTS
]]--

--[[
  Initial setup of all configured gearBars. Used during addon startup
]]--
function me.BuildGearBars()
  local gearBars = mod.gearBarManager.GetGearBars()
  
  if not gearBars or #gearBars == 0 then
    return
  end
  

  for _, gearBar in pairs(gearBars) do
    if gearBar then
      me.BuildGearBar(gearBar)
    end
  end
  
end

--[[
  Build a gearBar based on the passed metadata

  @param {table} gearBar

  @return {table}
    The created gearBarFrame
]]--
function me.BuildGearBar(gearBar)
  if not gearBar or not gearBar.id then
    return nil
  end
  
  local frameName = RGGM_CONSTANTS.ELEMENT_GEAR_BAR_BASE_FRAME_NAME .. gearBar.id
  local gearBarFrame = CreateFrame(
    "Frame",
    frameName,
    UIParent,
    "BackdropTemplate"
  )
  
  if not gearBarFrame then
    return nil
  end
  
  -- Set initial size (will be updated later based on slots)
  local initialWidth = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE + RGGM_CONSTANTS.GEAR_BAR_WIDTH_MARGIN
  local initialHeight = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE
  gearBarFrame:SetWidth(initialWidth)
  gearBarFrame:SetHeight(initialHeight)
  gearBarFrame:SetPoint("CENTER", 0, 0)
  gearBarFrame:SetMovable(true)
  gearBarFrame:EnableMouse(true) -- Enable mouse events for dragging
  -- prevent dragging the frame outside the actual 3d-window
  gearBarFrame:SetClampedToScreen(true)

  gearBarFrame.id = gearBar.id
  
  -- Set a visible backdrop initially so the frame can be seen
  gearBarFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  gearBarFrame:SetBackdropColor(0, 0, 0, 0.8)
  gearBarFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
  
  -- store ui element reference
  mod.gearBarStorage.AddGearBar(gearBar.id, gearBarFrame)
  

  -- Create slots if any exist
  if gearBar.slots and #gearBar.slots > 0 then
    me.CreateGearSlots(gearBarFrame, gearBar)
  else
  end
  
  me.SetupDragFrame(gearBarFrame)
  me.UpdateGearBarSize(gearBar)
  me.UpdateGearBarPosition(gearBar)
  me.UpdateGearBarLockedState(gearBar) -- This will update backdrop based on locked state
  me.UpdateGearBarGearSlotTexturesAttributes(gearBar)
  
  -- Ensure the frame is visible and has a visible size
  local finalWidth, finalHeight = gearBarFrame:GetSize()
  
  if finalWidth > 0 and finalHeight > 0 then
    gearBarFrame:Show()
  else
  end

  return gearBarFrame
end

--[[
  Create all configured slots for the gearBar and use all data available to create the slots
  with the proper size and position

  @param {table} gearBarFrame
  @param {table} gearBar
]]--
function me.CreateGearSlots(gearBarFrame, gearBar)
  if not gearBar.slots or #gearBar.slots == 0 then
    return
  end
  
  
  for i = 1, #gearBar.slots do
    local gearSlot = me.CreateGearSlot(gearBarFrame, gearBar, i)
    if gearSlot then
      -- store ui element reference
      mod.gearBarStorage.AddGearSlot(gearBar.id, gearSlot)
    else
    end
  end
end

--[[
  Create a single gearSlot. Note that a gearSlot inherits from the SecureActionButtonTemplate to enable the usage
  of clicking items. Because of SetAttribute this function CANNOT be executed while in combat

  @param {table} gearBarFrame
    The gearBarFrame where the gearSlot gets attached to
  @param {table} gearBar
  @param {number} position
    Position on the gearBar

  @return {table}
    The created gearSlot
]]--
function me.CreateGearSlot(gearBarFrame, gearBar, position)
  if InCombatLockdown() then
    mod.logger.LogError(me.tag, "Unable to update slots in combat. Please /reload after your are out of combat")

    return
  end

  return mod.themeCoordinator.CreateGearSlot(gearBarFrame, gearBar, position)
end

--[[
  @param {table} gearSlot
  @param {number} gearSlotSize

  @return {table}
    The created combatQueueSlot
]]--
function me.CreateCombatQueueSlot(gearSlot, gearSlotSize)
  local combatQueueSlot = CreateFrame("Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_COMBAT_QUEUE_SLOT, gearSlot)
  local combatQueueSlotSize = gearSlotSize * RGGM_CONSTANTS.GEAR_BAR_COMBAT_QUEUE_SLOT_SIZE_MODIFIER

  combatQueueSlot:SetSize(
    combatQueueSlotSize,
    combatQueueSlotSize
  )
  combatQueueSlot:SetPoint("TOPRIGHT", gearSlot)

  local iconHolderTexture = combatQueueSlot:CreateTexture(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_ICON_TEXTURE_NAME,
    "BACKGROUND",
    nil
  )
  iconHolderTexture:SetPoint("TOPLEFT", combatQueueSlot, "TOPLEFT")
  iconHolderTexture:SetPoint("BOTTOMRIGHT", combatQueueSlot, "BOTTOMRIGHT")
  iconHolderTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  combatQueueSlot.icon = iconHolderTexture

  return combatQueueSlot
end

--[[
  @param {table} gearSlot
  @param {number} gearSlotSize

  @return {table}
    The created keybindingFontString
]]--
function me.CreateKeyBindingText(gearSlot, gearSlotSize)
  local keybindingFontString = gearSlot:CreateFontString(nil, "OVERLAY")
  keybindingFontString:SetTextColor(1, 1, 1, 1)
  keybindingFontString:SetPoint("TOP", 0, 1)
  keybindingFontString:SetSize(gearSlot:GetWidth(), 20)
  keybindingFontString:SetFont(
    STANDARD_TEXT_FONT,
    gearSlotSize * RGGM_CONSTANTS.GEAR_BAR_CHANGE_KEYBIND_TEXT_MODIFIER,
    "THICKOUTLINE"
  )
  keybindingFontString:Hide()

  return keybindingFontString
end

--[[
  UPDATE

  GearBar update functions
]]--

--[[
  Update all GearBars with a certain operation (see param)

  @param {function} func
    A function to invoke for each gearBar
]]--
function me.UpdateGearBars(func)
  local gearBars = mod.gearBarManager.GetGearBars()

  for _, gearBar in pairs(gearBars) do
      func(gearBar)
  end
end

--[[
  Load the initial gearBar state once the addon is initialized

  @param {table} gearBar
]]--
function me.UpdateGearBarVisual(gearBar)
  me.UpdateGearBarGearSlotTextures(gearBar)
  me.UpdateGearBarGearSlotCooldowns(gearBar)
  me.UpdateKeyBindingState(gearBar)
end

--[[
  Update the position of a gearBar. This is called onInit when the bar is first loaded from the configuration

  @param {table} gearBar
]]--
function me.UpdateGearBarPosition(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)
  if not uiGearBar or not uiGearBar.gearBarReference then
    if mod.logger then
      mod.logger.LogError(me.tag, "Cannot update position - gearBar UI not found for id: " .. gearBar.id)
    end
    return
  end
  
  uiGearBar.gearBarReference:ClearAllPoints()
  
  -- Handle position - relativePoint may not exist for new gearBars
  if gearBar.position.relativePoint then
    uiGearBar.gearBarReference:SetPoint(
      gearBar.position.point,
      nil,
      gearBar.position.relativePoint,
      gearBar.position.posX or 0,
      gearBar.position.posY or 0
    )
  else
    -- Default: use point, posX, posY only (relativePoint defaults to same as point)
    uiGearBar.gearBarReference:SetPoint(
      gearBar.position.point or "CENTER",
      nil,
      gearBar.position.point or "CENTER",
      gearBar.position.posX or 0,
      gearBar.position.posY or 0
    )
  end
  
  -- Ensure the frame is visible
  uiGearBar.gearBarReference:Show()
end

--[[
  Update the visual representation of a gearBar whether the gearBar is locked or unlocked

  @param {table} gearBar
]]--
function me.UpdateGearBarLockedState(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)
  
  if not uiGearBar or not uiGearBar.gearBarReference then
    if mod.logger then
      mod.logger.LogError(me.tag, "Cannot update locked state - gearBar UI not found for id: " .. gearBar.id)
    end
    return
  end

  if gearBar.isLocked then
    uiGearBar.gearBarReference:SetBackdrop(nil)
  else
    -- Set a visible backdrop so the frame can be seen and moved
    uiGearBar.gearBarReference:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    uiGearBar.gearBarReference:SetBackdropColor(0, 0, 0, 0.8)
    uiGearBar.gearBarReference:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
  end
end

--[[
  Update gearBar size in cases such as a new gearSlot was added or one was removed or the
  size of the gearSlot was changed.

  @param {table} gearBar
    Data representation of a gearBar
]]--
function me.UpdateGearBarSize(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)
  
  if not uiGearBar or not uiGearBar.gearBarReference then
    if mod.logger then
      mod.logger.LogError(me.tag, "Cannot update size - gearBar UI not found for id: " .. gearBar.id)
    else
    end
    return
  end

  local slotCount = gearBar.slots and #gearBar.slots or 0
  local slotSize = gearBar.gearSlotSize or RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE
  
  -- Ensure minimum size even if no slots
  if slotCount == 0 then
    slotCount = 1
  end
  
  local width = slotCount * slotSize + RGGM_CONSTANTS.GEAR_BAR_WIDTH_MARGIN
  local height = slotSize
  
  uiGearBar.gearBarReference:SetWidth(width)
  uiGearBar.gearBarReference:SetHeight(height)
  
end

--[[
  UPDATE

  GearSlot update functions
]]--

--[[
  Update the visual representation of the combatQueue on all present gearBars by
  locking through all gearBars and whether they have a slot with a matching slotId or
  not. This catches cases where multiple gearBars have the same slot present

  @param {table} slotId
  @param {number} itemId
]]--
function me.UpdateCombatQueue(slotId, itemId)
  mod.logger.LogDebug(me.tag, "Updating combatqueues for slotId - " .. slotId)

  for _, gearBar in pairs(mod.gearBarStorage.GetGearBars()) do
    local gearSlots = gearBar.gearSlotReferences

    for i = 1, #gearSlots do
      if gearSlots[i]:GetAttribute("item") == slotId then
        local icon = gearSlots[i].combatQueueSlot.icon
        local bagNumber, bagPos = mod.itemManager.FindItemInBag(itemId)

        if itemId then
          if bagNumber ~= nil and bagPos ~= nil then
            local itemInfo = C_Container.GetContainerItemInfo(bagNumber, bagPos)
            if itemInfo and itemInfo.iconFileID then
              icon:SetTexture(itemInfo.iconFileID)
              icon:Show()
            else
              icon:Hide()
            end
          else
            icon:Hide()
          end
        else
          icon:Hide()
        end
      end
    end
  end
end

--[[
  Update visual display of itemrange for all gearslots
]]--
function me.UpdateSpellRange()
  local uiGearBars = mod.gearBarStorage.GetGearBars()

  for _, uiGearBar in pairs(uiGearBars) do
    local gearBarId = uiGearBar.gearBarReference.id

    for _, gearSlot in pairs(uiGearBar.gearSlotReferences) do
      local gearBar = mod.gearBarManager.GetGearBar(gearBarId)

      if mod.target.GetCurrentTargetGuid() == "" then
        gearSlot.keyBindingText:SetTextColor(1, 1, 1, 1)
      else
        local gearSlotMetaData = gearBar.slots[gearSlot.position]

        if gearSlotMetaData ~= nil then
          local itemLink = GetInventoryItemLink(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlotMetaData.slotId)
          --[[
            - Returns true if item is in range
            - Returns false if item is not in range
            - Returns nil if not applicable(e.g. item is passive only) or the slot might be empty
          ]]--
          local isInRange = IsItemInRange(itemLink, RGGM_CONSTANTS.UNIT_ID_TARGET)

          if isInRange == nil or isInRange == true then
            gearSlot.keyBindingText:SetTextColor(1, 1, 1, 1)
          else
            gearSlot.keyBindingText:SetTextColor(1, 0, 0, 1)
          end
        end
      end
    end
  end
end

--[[
  Update the cooldown of all gearSlots on all gearBars in response to BAG_UPDATE_COOLDOWN
  or a visual update of the gearBars

  @param {table} gearBar
]]--
function me.UpdateGearBarGearSlotCooldowns(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  for index, gearSlotMetaData in pairs(gearBar.slots) do
    local uiGearSlot = uiGearBar.gearSlotReferences[index]

    mod.cooldown.UpdateGearSlotCooldown(gearBar, uiGearSlot, gearSlotMetaData)
  end
end

--[[
  Update the keyBinding text and hide the keyBinding if no text is available on all slots of the
  passed gearBar

  * Handles the event where the player activates or deactivates showKeyBindings
  * Handles the event where we receive an UPDATE_BINDINGS event

  @param {table} gearBar
]]--
function me.UpdateKeyBindingState(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  for index, gearSlotMetaData in pairs(gearBar.slots) do
    local uiGearSlot = uiGearBar.gearSlotReferences[index]

    if gearSlotMetaData.keyBinding and mod.gearBarManager.IsShowKeyBindingsEnabled(gearBar.id) then
      uiGearSlot.keyBindingText:SetText(mod.keyBind.ConvertKeyBindingText(gearSlotMetaData.keyBinding))
      uiGearSlot.keyBindingText:Show()
    else
      uiGearSlot.keyBindingText:SetText("")
      uiGearSlot.keyBindingText:Hide()
    end
  end
end

--[[
  Update all gearSlot textures of the passed gearBar

  @param {table} gearBar
]]--
function me.UpdateGearBarGearSlotTextures(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  for index, gearSlot in pairs(gearBar.slots) do
    local uiGearSlot = uiGearBar.gearSlotReferences[index]

    me.UpdateGearSlotTexture(uiGearSlot, gearSlot)
    mod.themeCoordinator.UpdateSlotTextureAttributes(uiGearSlot, gearBar.gearSlotSize)
  end
end

--[[
  Update the button texture style and add icon for the currently worn item. If no item is worn
  the default icon is displayed

  @param {table} gearSlot
  @param {table} gearSlotMetaData
]]--
function me.UpdateGearSlotTexture(gearSlot, gearSlotMetaData)
  -- Get the real itemId from the inventory link (not transmog)
  local itemLink = GetInventoryItemLink(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlotMetaData.slotId)
  local itemId = nil
  
  if itemLink then
    -- Extract itemId from item link: "item:itemId:enchantId:gemId1:gemId2:gemId3:gemId4:suffixId:uniqueId:linkLevel:specializationId:modifiersMask:itemContext"
    local _, _, id = string.find(itemLink, "item:(%d+):")
    if id then
      itemId = tonumber(id)
    end
  end
  
  -- Fallback to GetInventoryItemID if link parsing fails
  if not itemId then
    itemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlotMetaData.slotId)
  end

  if itemId then
    -- Get the icon from GetItemInfo using the real itemId (not transmog)
    local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemId)
    if itemIcon then
      gearSlot.itemTexture:SetTexture(itemIcon)
    else
      -- If GetItemInfo fails, fallback to GetInventoryItemTexture
      local itemTexture = GetInventoryItemTexture(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlotMetaData.slotId)
      if itemTexture then
        gearSlot.itemTexture:SetTexture(itemTexture)
      else
        gearSlot.itemTexture:SetTexture(gearSlotMetaData.textureId)
      end
    end
  else
    -- If no item can be found in the inventoryslot use the default icon
    gearSlot.itemTexture:SetTexture(gearSlotMetaData.textureId)
  end
end

--[[
  Update the texture attributes of all gearSlots of the passed gearBar

  @param {table} gearBar
]]--
function me.UpdateGearBarGearSlotTexturesAttributes(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  for index, _ in pairs(gearBar.slots) do
    local uiGearSlot = uiGearBar.gearSlotReferences[index]

    mod.themeCoordinator.UpdateSlotTextureAttributes(uiGearSlot, gearBar.gearSlotSize)
  end
end

--[[
  GearSlot size adjustment in response to a configuration change
]]--

--[[
  Update the size of a gearSlot and all its underlying components that need to be adapted
  as well

  @param {table} gearBar
]]--
function me.UpdateGearSlotSizes(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  for position, _ in pairs(gearBar.slots) do
    local uiGearSlot = uiGearBar.gearSlotReferences[position]

    me.UpdateGearSlotSize(uiGearBar, uiGearSlot, gearBar.gearSlotSize, position)
    mod.cooldown.UpdateGearSlotCooldownOverlaySize(uiGearSlot, gearBar.gearSlotSize)
    me.UpdateGearSlotCombatQueueSize(uiGearSlot, gearBar.gearSlotSize)
    me.UpdateGearSlotKeyBindingTextSize(uiGearSlot, gearBar.gearSlotSize)
    mod.themeCoordinator.UpdateSlotTextureAttributes(uiGearSlot, gearBar.gearSlotSize)
  end
end

--[[
  @param {table} uiGearBar
  @param {table} uiGearSlot
  @param {number} gearSlotSize
  @param {number} position
]]--
function me.UpdateGearSlotSize(uiGearBar, uiGearSlot, gearSlotSize, position)
  uiGearSlot:SetSize(gearSlotSize, gearSlotSize)
  uiGearSlot:SetPoint(
    "LEFT",
    uiGearBar.gearBarReference,
    "LEFT",
    RGGM_CONSTANTS.GEAR_BAR_SLOT_X + (position - 1) * gearSlotSize,
    RGGM_CONSTANTS.GEAR_BAR_SLOT_Y
  )
end

--[[
  @param {table} uiGearSlot
  @param {number} slotSize
]]--
function me.UpdateGearSlotCombatQueueSize(uiGearSlot, slotSize)
  uiGearSlot.combatQueueSlot:SetSize(
    slotSize * RGGM_CONSTANTS.GEAR_BAR_COMBAT_QUEUE_SLOT_SIZE_MODIFIER,
    slotSize * RGGM_CONSTANTS.GEAR_BAR_COMBAT_QUEUE_SLOT_SIZE_MODIFIER
  )
end

--[[
  @param {table} uiGearSlot
  @param {number} slotSize
]]--
function me.UpdateGearSlotKeyBindingTextSize(uiGearSlot, slotSize)
  uiGearSlot.keyBindingText:SetFont(
    STANDARD_TEXT_FONT,
    slotSize * RGGM_CONSTANTS.GEAR_BAR_CHANGE_KEYBIND_TEXT_MODIFIER,
    "THICKOUTLINE"
  )
end

--[[
  Used in response to adding, removing or updating a gearSlot in the Interfaces Panel

  @param {table} gearBar
]]--
function me.UpdateGearBarGearSlots(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)
  
  -- If the gearBar UI hasn't been built yet, build it first
  if not uiGearBar then
    if mod.logger then
      mod.logger.LogDebug(me.tag, "GearBar UI not found for id " .. gearBar.id .. ", building it now")
    end
    me.BuildGearBar(gearBar)
    uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)
    
    -- If still nil after building, something went wrong
    if not uiGearBar then
      if mod.logger then
        mod.logger.LogError(me.tag, "Failed to build GearBar UI for id: " .. gearBar.id)
      else
      end
      return
    end
  end

  for position, gearSlotMetaData in pairs(gearBar.slots) do
    local uiGearSlot = uiGearBar.gearSlotReferences[position]

    if uiGearSlot == nil then
      me.CreateNewGearSlot(gearBar, uiGearBar, position)
    else
      me.UpdateExistingSlot(uiGearBar, gearSlotMetaData, position)
    end
  end

  -- update visual elements of the gearBar
  me.UpdateGearBarGearSlotTextures(gearBar)
  me.UpdateGearBarGearSlotCooldowns(gearBar)
  me.UpdateKeyBindingState(gearBar)
  me.UpdateGearBarSize(gearBar)
  me.CleanupOrphanedGearSlots(gearBar)
end

--[[
  @param {table} uiGearSlot
  @param {table} gearSlotMetaData
  @param {number} position
]]--
function me.UpdateExistingSlot(uiGearBar, gearSlotMetaData, position)
  local uiGearSlot = uiGearBar.gearSlotReferences[position]

  uiGearSlot:SetAttribute("type1", "item")
  uiGearSlot:SetAttribute("item", gearSlotMetaData.slotId)
  uiGearSlot:Show()
end

--[[
  @param {table} uiGearSlot
  @param {table} uiGearBar
  @param {number} position
]]--
function me.CreateNewGearSlot(gearBar, uiGearBar, position)
  -- create new gearSlot
  mod.logger.LogInfo(me.tag, "GearSlot does not yet exist. Creating a new one")

  local gearSlot = me.CreateGearSlot(uiGearBar.gearBarReference, gearBar, position)
  mod.gearBarStorage.AddGearSlot(gearBar.id, gearSlot)
end

--[[
  Search for orphan gearSlots that should be removed. Note it is not possible to delete
  a frame. It can only be hidden but will of course not be recreated once the user reloads the ui

  Note: It is very important to not lose a reference to a slot because just recreating the same slot
  with the same name won't work with keybinds. In that case a reload is required to recreate the ui

  @param {table} gearBar
    The configuration of a gearBar
  @param {table} gearBarUi
    The visual representation of a gearBar
]]--
function me.CleanupOrphanedGearSlots(gearBar)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  for i = 1, #uiGearBar.gearSlotReferences do
    if gearBar.slots[i] == nil then
      -- simply hide gearSlots that are not in use
      uiGearBar.gearSlotReferences[i]:Hide()
    end
  end
end

--[[
  EVENTS
]]--

--[[
  Setup events for gearBar frame

  @param {table} gearBar
    The gearBar to attach the drag handlers to
]]--
function me.SetupDragFrame(gearBar)
  gearBar:SetScript("OnMouseDown", me.StartDragFrame)
  gearBar:SetScript("OnMouseUp", me.StopDragFrame)
end

--[[
  Frame callback to start moving the gearBar frame

  @param {table} self
]]--
function me.StartDragFrame(self)
  if mod.gearBarManager.IsGearBarLocked(self.id) then return end

  self:StartMoving()
end

--[[
  Frame callback to stop moving the gearBar frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  if mod.gearBarManager.IsGearBarLocked(self.id) then return end

  self:StopMovingOrSizing()

  local point, relativeTo, relativePoint, posX, posY = self:GetPoint()
  mod.gearBarManager.UpdateGearBarPosition(self.id, point, relativeTo, relativePoint, posX, posY)
end

--[[
  Setup event for a changeSlot

  @param {table} gearSlot
]]--
function me.SetupEvents(gearSlot)
  --[[
    Note: SecureActionButtons ignore right clicks by default - reenable right clicks
  ]]--
  if mod.configuration.IsFastPressEnabled() then
    gearSlot:RegisterForClicks("LeftButtonDown", "RightButtonDown")
  else
    gearSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  end

  gearSlot:RegisterForDrag("LeftButton")
  --[[
    Replacement for OnCLick. Do not overwrite click event for protected button
  ]]--
  gearSlot:SetScript("PreClick", function(self, button, down)
    me.GearSlotOnClick(self, button, down)
  end)

  gearSlot:SetScript("OnEnter", me.GearSlotOnEnter)
  gearSlot:SetScript("OnLeave", me.GearSlotOnLeave)

  gearSlot:SetScript("OnReceiveDrag", function(self)
    me.GearSlotOnReceiveDrag(self)
  end)

  gearSlot:SetScript("OnDragStart", function(self)
    me.GearSlotOnDragStart(self)
  end)
end

--[[
  Update clickhandler to match fastpress configuration. Only register to events that are needed
]]--
function me.UpdateClickHandler()
  local uiGearBars = mod.gearBarStorage.GetGearBars()

  for _, uiGearBar in pairs(uiGearBars) do
    for _, gearSlot in pairs(uiGearBar.gearSlotReferences) do
      if mod.configuration.IsFastPressEnabled() then
        gearSlot:RegisterForClicks("LeftButtonDown", "RightButtonDown")
      else
        gearSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      end
    end
  end
end

--[[
  Callback for a gearBarSlot OnClick

  @param {table} self
  @param {string} button
]]--
function me.GearSlotOnClick(self, button)
  if button == "RightButton" then
    mod.combatQueue.RemoveFromQueue(self:GetAttribute("item"))
  else
    return -- ignore other buttons
  end

  mod.themeCoordinator.GearSlotOnClick(self, button)
end

--[[
  Callback for a gearSlot OnEnter

  @param {table} self
]]--
function me.GearSlotOnEnter(self)
  mod.gearBarChangeMenu.UpdateChangeMenu(self.position, self:GetParent().id)

  local itemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, self:GetAttribute("item"))
  mod.tooltip.UpdateTooltipById(itemId)
  mod.themeCoordinator.GearSlotOnEnter(self)
end

--[[
  Callback for a gearSlot OnLeave

  @param {table} self
]]--
function me.GearSlotOnLeave(self)
  mod.tooltip.TooltipClear()
  mod.themeCoordinator.GearSlotOnLeave(self)
end

--[[
  Callback for a gearSlot OnReceiveDrag

  @param {table} self
]]--
function me.GearSlotOnReceiveDrag(self)
  if not mod.configuration.IsDragAndDropEnabled() then return end

  local gearSlot = mod.gearBarManager.GetGearSlot(self:GetParent().id, self.position)

  if gearSlot == nil then return end

  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(gearSlot.slotId)
  -- abort if no item could be found
  if gearSlotMetaData == nil then return end

  if CursorCanGoInSlot(gearSlotMetaData.slotId) then
    if InCombatLockdown() or mod.common.IsPlayerCasting() then
      local _, itemId = GetCursorInfo()

      mod.combatQueue.AddToQueue(itemId, gearSlotMetaData.slotId)
      ClearCursor()
    else
      EquipCursorItem(gearSlotMetaData.slotId)
    end
  else
    mod.logger.LogInfo(me.tag, "Invalid item for slotId - " .. gearSlotMetaData.slotId)
    ClearCursor() -- clear cursor from item
  end
end

--[[
  Callback for a gearSlot OnDragStart

  @param {table} self
]]--
function me.GearSlotOnDragStart(self)
  if not mod.configuration.IsDragAndDropEnabled() then return end

  local gearSlot = mod.gearBarManager.GetGearSlot(self:GetParent().id, self.position)

  if gearSlot == nil then return end

  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(gearSlot.slotId)
  -- abort if no item could be found
  if gearSlotMetaData == nil then return end

  if not IsInventoryItemLocked(gearSlotMetaData.slotId) then
    PickupInventoryItem(gearSlotMetaData.slotId)
  end
end
