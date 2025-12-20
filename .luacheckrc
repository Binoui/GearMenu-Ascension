-- Luacheck configuration for GearMenu WoW Addon
-- This file configures luacheck to recognize WoW API globals and addon-specific globals

-- Addon-specific globals
globals = {
  "rggm",
  "GearMenuConfiguration",
  "RGGM_CONSTANTS",
  "RGGM_ENVIRONMENT"
}

-- WoW API globals (WoW 3.3.5)
read_globals = {
  -- Core WoW API
  "CreateFrame",
  "UIParent",
  "GetTime",
  "ReloadUI",
  "GetAddOnMetadata",
  "DEFAULT_CHAT_FRAME",
  
  -- Item API
  "GetItemInfo",
  "GetItemSpell",
  "GetItemQualityColor",
  "GetInventoryItemID",
  "GetInventoryItemLink",
  "GetInventoryItemTexture",
  "PickupInventoryItem",
  "IsInventoryItemLocked",
  "IsEquippedItem",
  "EquipCursorItem",
  "ClearCursor",
  "CursorHasItem",
  "CursorCanGoInSlot",
  "PutItemInBackpack",
  "PutItemInBag",
  "GetContainerNumSlots",
  "GetContainerItemLink",
  "GetContainerItemInfo",
  "PickupContainerItem",
  "GetItemCooldown",
  
  -- Unit API
  "UnitIsDeadOrGhost",
  "UnitIsFeignDeath",
  "UnitIsEnemy",
  "UnitGUID",
  "UnitName",
  "UnitClass",
  "UnitBuff",
  "UnitCastingInfo",
  "UnitChannelInfo",
  
  -- Spell/Casting API
  "CastingInfo",
  "ChannelInfo",
  "SpellIsTargeting",
  "IsItemInRange",
  
  -- Combat API
  "InCombatLockdown",
  "UnitAffectingCombat",
  
  -- UI API
  "ShowUIPanel",
  "MouseIsOver",
  "GetCursorPosition",
  "GetScreenHeight",
  "GetScreenWidth",
  "GetCVar",
  "PlaySound",
  "SOUNDKIT",
  
  -- Interface Options API
  "InterfaceOptionsFrame",
  "InterfaceOptionsFrame_OpenToCategory",
  "InterfaceOptions_AddCategory",
  "InterfaceOptionsFramePanelContainer",
  "Settings",
  
  -- Tooltip API
  "GameTooltip",
  "GameTooltip_SetTitle",
  "GameTooltip_AddNormalLine",
  "GameTooltip_AddInstructionLine",
  "GameTooltip_AddColoredLine",
  "GameTooltip_SetDefaultAnchor",
  
  -- Dropdown Menu API
  "UIDropDownMenu_Initialize",
  "UIDropDownMenu_AddButton",
  "UIDropDownMenu_SetSelectedValue",
  "CloseMenus",
  
  -- Scroll Frame API
  "FauxScrollFrame_Update",
  "FauxScrollFrame_GetOffset",
  
  -- Cooldown API
  "CooldownFrame_Set",
  "CooldownFrame_Clear",
  "COOLDOWN_TYPE_NORMAL",
  
  -- Keybinding API
  "GetBindingKey",
  "GetBindingAction",
  "SetBinding",
  "SetBindingClick",
  "GetCurrentBindingSet",
  "SaveBindings",
  
  -- Popup API
  "StaticPopupDialogs",
  "StaticPopup_Show",
  "StaticPopup_Hide",
  
  -- Slash Command API
  "SLASH_GEARMENU1",
  "SLASH_GEARMENU2",
  "SlashCmdList",
  
  -- Font Constants
  "STANDARD_TEXT_FONT",
  "GameFontDisableSmallLeft",
  "GameFontHighlightSmallLeft",
  "GameFontNormalSmallLeft",
  "RED_FONT_COLOR",
  "GRAY_FONT_COLOR",
  "NORMAL_FONT_COLOR",
  "HIGHLIGHT_FONT_COLOR",
  "TOOLTIP_DEFAULT_COLOR",
  "TOOLTIP_DEFAULT_BACKGROUND_COLOR",
  
  -- Inventory Slot Constants
  "INVSLOT_HEAD",
  "INVSLOT_NECK",
  "INVSLOT_SHOULDER",
  "INVSLOT_CHEST",
  "INVSLOT_WAIST",
  "INVSLOT_LEGS",
  "INVSLOT_FEET",
  "INVSLOT_WRIST",
  "INVSLOT_HAND",
  "INVSLOT_FINGER1",
  "INVSLOT_FINGER2",
  "INVSLOT_TRINKET1",
  "INVSLOT_TRINKET2",
  "INVSLOT_BACK",
  "INVSLOT_MAINHAND",
  "INVSLOT_OFFHAND",
  "INVSLOT_RANGED",
  "INVSLOT_AMMO",
  
  -- Other Constants
  "VIDEO_QUALITY_LABEL6",
  
  -- Modern API (may not exist in 3.3.5, but handled by compat layer)
  "C_Timer",
  "C_Container",
  "C_LossOfControl",
  
  -- Secure API
  "securecall",
  "ExecuteFrameScript",
  "CreateFromMixins",
  
  -- Color Picker
  "ColorPickerFrame",
  
  -- Error Frame
  "UIErrorsFrame",
  
  -- Locale
  "GetLocale"
}

-- Standard Lua globals that are used
std = "lua51"

-- Ignore warnings about unused arguments (common in WoW addons)
unused_args = false

-- Ignore warnings about unused second return values
unused_secondaries = false

-- Allow unused loop variables
unused_loop = true

-- Ignore warnings about accessing undefined fields (WoW API is dynamic)
-- We'll rely on read_globals for known APIs
ignore = {
  "212", -- unused argument
  "213", -- unused loop variable
  "611", -- accessing undefined field (WoW API is dynamic)
  "631", -- field is accessed but never set
}

-- Allow redefining globals (needed for some WoW addon patterns)
redefined = true
