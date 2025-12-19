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

-- luacheck: globals CreateFrame UIParent Settings InterfaceOptionsFrame InterfaceOptionsFrame_OpenToCategory InterfaceOptions_AddCategory InterfaceOptionsFramePanelContainer ShowUIPanel

local mod = rggm
local me = {}

mod.addonConfiguration = me

me.tag = "AddonConfiguration"

--[[
  Holds the id reference to the main category of the addon. Can be used with Settings.OpenToCategory({number})
  {number}
]]--
local mainCategoryId
local mainCategoryName -- Store the display name of the main category for subcategories in 3.3.5
local mainCategoryFrameName -- Store the frame name of the main category for subcategories in 3.3.5
local gearBarConfigCategoryName -- Store the display name of "GearBar Configuration" category for sub-subcategories
--[[
  Holds the id reference to the gearBar configuration subcategory
  {number}
]]--
local gearBarSubCategoryId

--[[
  Retrieve a reference to the main category of the addon

  @return {table | nil}
    The main category of the addon or nil if not found
]]--
function me.GetMainCategory()
  -- Compatibility for WoW 3.3.5
  if Settings and Settings.GetCategory then
    if mainCategoryId ~= nil then
      return Settings.GetCategory(mainCategoryId)
    end
  else
    -- Legacy: Return frame reference
    if mainCategoryId ~= nil then
      return _G[mainCategoryId]
    end
  end

  return nil
end

--[[
  Searches for the specific gearBar configuration subcategory and returns it

  @return {table | nil}
    The gearBar configuration subcategory or nil if not found
]]--
function me.GetGearBarSubCategory()
  -- In 3.3.5, we need to return a category object that can be used as parent
  -- Since we stored gearBarSubCategoryId, we can create a mock category object
  if not gearBarSubCategoryId then
    return nil
  end
  
  -- For 3.3.5, return a category object with the name for parent reference
  -- The actual frame should exist with the name from gearBarConfigCategoryName
  if gearBarConfigCategoryName then
    return {
      name = gearBarConfigCategoryName,
      ID = gearBarSubCategoryId
    }
  end
  
  -- Fallback: try to get from main category
  local mainCategory = me.GetMainCategory()
  if not mainCategory then
    return nil
  end

  -- In 3.3.5, subcategories might not have the same structure
  if mainCategory.subcategories then
    for i = 1, #mainCategory.subcategories do
      if mainCategory.subcategories[i].ID == gearBarSubCategoryId then
        return mainCategory.subcategories[i]
      end
    end
  end

  return nil
end

--[[
  Create addon configuration menu(s)
]]--
function me.SetupAddonConfiguration()
  print("|cFF00FFB0GearMenu:|r Setting up addon configuration panel...")
  
  -- Safety check: ensure all required modules exist
  if not mod.aboutContent then
    print("|cffff0000GearMenu Error:|r aboutContent module not loaded")
    return
  end
  
  -- initialize the main addon category
  local category, menu = me.BuildCategory(RGGM_CONSTANTS.ELEMENT_ADDON_PANEL, nil, rggm.L["addon_name"])
  
  if not category or not menu then
    print("|cffff0000GearMenu Error:|r Failed to create main category")
    return
  end
  
  print("|cFF00FF00GearMenu:|r Main category created, mainCategoryId = " .. tostring(mainCategoryId))
  
  -- Ensure the menu frame is properly sized for Interface Options
  if menu then
    menu:SetAllPoints(InterfaceOptionsFramePanelContainer)
    print("|cFF00FF00GearMenu:|r Menu frame configured")
  end
  
  -- add about content into main category
  if menu and mod.aboutContent and mod.aboutContent.BuildAboutContent then
    print("|cFF00FF00GearMenu:|r Building about content...")
    mod.aboutContent.BuildAboutContent(menu)
    print("|cFF00FF00GearMenu:|r About content built")
  else
    print("|cffff0000GearMenu Error:|r Cannot build about content - menu or aboutContent missing")
  end

  -- Build subcategories (these will be separate panels in 3.3.5)
  local generalCategory, generalMenu = me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GENERAL_OPTIONS_FRAME,
    category,
    rggm.L["general_category_name"],
    mod.generalMenu.BuildUi
  )
  if generalMenu then
    generalMenu:SetAllPoints(InterfaceOptionsFramePanelContainer)
    print("|cFF00FF00GearMenu:|r General options category created")
  end
  
  local trinketCategory, trinketMenu = me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_TRINKET_MENU_FRAME,
    category,
    rggm.L["trinket_menu_category_name"],
    mod.trinketConfigurationMenu.BuildUi
  )
  if trinketMenu then
    trinketMenu:SetAllPoints(InterfaceOptionsFramePanelContainer)
    print("|cFF00FF00GearMenu:|r Trinket menu category created")
  end
  
  local quickChangeCategory, quickChangeMenu = me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_QUICK_CHANGE_FRAME,
    category,
    rggm.L["quick_change_category_name"],
    mod.quickChangeMenu.BuildUi
  )
  if quickChangeMenu then
    quickChangeMenu:SetAllPoints(InterfaceOptionsFramePanelContainer)
    print("|cFF00FF00GearMenu:|r Quick change category created")
  end
  
  local gearBarConfigurationSubCategory, gearBarConfigMenu = me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_CONFIG_FRAME,
    category,
    rggm.L["gear_bar_configuration_panel_text"],
    mod.gearBarConfigurationMenu.BuildUi
  )
  if gearBarConfigMenu then
    gearBarConfigMenu:SetAllPoints(InterfaceOptionsFramePanelContainer)
    print("|cFF00FF00GearMenu:|r Gear bar configuration category created")
    -- Store the display name for sub-subcategories (individual gearBars)
    -- Use the actual menu.name which is what WoW 3.3.5 uses for parent matching
    gearBarConfigCategoryName = gearBarConfigMenu.name or rggm.L["gear_bar_configuration_panel_text"]
    print("|cFF00FF00GearMenu:|r Stored gearBarConfigCategoryName: " .. tostring(gearBarConfigCategoryName))
  end
  -- Store subcategory ID (may be nil in 3.3.5, that's OK)
  if gearBarConfigurationSubCategory and gearBarConfigurationSubCategory.ID then
    gearBarSubCategoryId = gearBarConfigurationSubCategory.ID
  else
    -- In 3.3.5, subcategories don't have IDs, use frame name
    gearBarSubCategoryId = RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_CONFIG_FRAME
  end
  print("|cFF00FF00GearMenu:|r Gear bar subcategory ID: " .. tostring(gearBarSubCategoryId))
  --[[
   load configured gearBars after the menu RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_CONFIG_FRAME was
   created to attach to
 ]]--
  -- Safety check: ensure gearBarConfigurationMenu exists before calling
  if mod.gearBarConfigurationMenu and mod.gearBarConfigurationMenu.LoadConfiguredGearBars then
    mod.gearBarConfigurationMenu.LoadConfiguredGearBars()
  else
    print("|cffff0000GearMenu Error:|r gearBarConfigurationMenu not available")
  end
  
  print("|cFF00FF00GearMenu:|r Addon configuration panel setup completed")
end

--[[
  Builds main and subcategories

  @param {string} frameName
  @param {table} parent
  @param {string} panelText
  @param {function} onShowCallback

  @return {table}, {table}
    category, menu
]]--
function me.BuildCategory(frameName, parent, panelText, onShowCallback)
  local category
  local menu

  -- Compatibility for WoW 3.3.5 - Settings API doesn't exist
  if Settings and Settings.RegisterCanvasLayoutCategory then
    -- Modern API (WoW 8.0+)
    if parent == nil then
      menu = CreateFrame("Frame", frameName)
      category = Settings.RegisterCanvasLayoutCategory(menu, panelText)
      mainCategoryId = category.ID
      Settings.RegisterAddOnCategory(category)
    else
      menu = CreateFrame("Frame", frameName, nil)
      menu.parent = parent.name
      local subcategory = Settings.RegisterCanvasLayoutSubcategory(parent, menu, frameName)
      subcategory.name = panelText
      category = subcategory
      Settings.RegisterAddOnCategory(subcategory)
    end
  else
    -- Legacy API (WoW 3.3.5) - Use InterfaceOptions_AddCategory
    if parent == nil then
      -- Check if InterfaceOptionsFramePanelContainer exists
      if not InterfaceOptionsFramePanelContainer then
        print("|cffff0000GearMenu Error:|r InterfaceOptionsFramePanelContainer not available")
        return nil, nil
      end
      
      menu = CreateFrame("Frame", frameName, InterfaceOptionsFramePanelContainer)
      if not menu then
        print("|cffff0000GearMenu Error:|r Failed to create frame " .. frameName)
        return nil, nil
      end
      
      menu.name = panelText
      InterfaceOptions_AddCategory(menu)
      -- Store reference for opening
      mainCategoryId = frameName
      mainCategoryName = panelText -- Store display name for subcategories
      mainCategoryFrameName = frameName -- Store frame name for subcategories
      category = { ID = frameName, name = panelText }
      print("|cFF00FF00GearMenu:|r Created main category: " .. frameName .. " (ID: " .. tostring(mainCategoryId) .. ", Name: " .. panelText .. ")")
    else
      -- For subcategories in 3.3.5, create them as separate panels with parent name
      if not InterfaceOptionsFramePanelContainer then
        print("|cffff0000GearMenu Error:|r InterfaceOptionsFramePanelContainer not available for subcategory")
        return nil, nil
      end
      
      menu = CreateFrame("Frame", frameName, InterfaceOptionsFramePanelContainer)
      if not menu then
        print("|cffff0000GearMenu Error:|r Failed to create subcategory frame " .. frameName)
        return nil, nil
      end
      
      menu.name = panelText
      -- In WoW 3.3.5, set the parent property BEFORE calling InterfaceOptions_AddCategory
      -- This is how LootCollector creates subcategories with the "+" expandable behavior
      -- For sub-subcategories (gearBars under "GearBar Configuration"), use gearBarConfigCategoryName
      -- For regular subcategories (General, TrinketMenu, etc.), use mainCategoryName
      local parentName = nil
      if parent and parent.name then
        -- Use the parent's name if provided (for sub-subcategories)
        parentName = parent.name
        print("|cFF00FF00GearMenu:|r Using parent.name for subcategory: " .. tostring(parentName))
      elseif mainCategoryName then
        -- Fallback to main category name (for regular subcategories)
        parentName = mainCategoryName
        print("|cFF00FF00GearMenu:|r Using mainCategoryName for subcategory: " .. tostring(parentName))
      end
      
      if parentName then
        menu.parent = parentName
        InterfaceOptions_AddCategory(menu)
        print("|cFF00FF00GearMenu:|r Created subcategory: " .. panelText .. " with parent: " .. parentName)
      else
        InterfaceOptions_AddCategory(menu)
        print("|cffff0000GearMenu Warning:|r No parent name available, subcategory created without parent")
      end
      
      category = { name = panelText, ID = frameName }
    end
  end

  if onShowCallback ~= nil then
    -- Wrap callback to ensure it's called
    menu:SetScript("OnShow", function(self)
      print("|cFF00FFB0GearMenu:|r OnShow triggered for " .. (panelText or "unknown"))
      onShowCallback(self)
    end)
  end

  --[[
   Important to hide panel initially. Interface addon options will take care of showing the menu.
   If this is not done OnShow callbacks will not be invoked correctly.
  ]]--
  menu:Hide()

  return category, menu
end

--[[
  Open the Blizzard addon configurations panel for the addon
]]--
function me.OpenMainCategory()
  print("|cFF00FFB0GearMenu:|r Opening configuration panel...")
  
  -- Check if panel was initialized
  if not mainCategoryId then
    print("|cffff0000GearMenu Error:|r mainCategoryId is nil - panel not initialized")
    print("|cffff0000GearMenu:|r Attempting to initialize panel now...")
    
    -- Try to initialize if not done
    if mod.addonConfiguration and mod.addonConfiguration.SetupAddonConfiguration then
      mod.addonConfiguration.SetupAddonConfiguration()
      if mainCategoryId then
        print("|cFF00FF00GearMenu:|r Panel initialized successfully")
      else
        print("|cffff0000GearMenu Error:|r Failed to initialize panel")
        return
      end
    else
      print("|cffff0000GearMenu Error:|r SetupAddonConfiguration function not available")
      return
    end
  end
  
  -- Compatibility for WoW 3.3.5 - Settings API doesn't exist
  if Settings and Settings.OpenToCategory then
    -- Modern API (WoW 8.0+)
    if mainCategoryId ~= nil then
      Settings.OpenToCategory(mainCategoryId)
      print("|cFF00FFB0GearMenu:|r Using modern Settings API")
    else
      print("|cffff0000GearMenu Error:|r mainCategoryId is nil")
    end
  else
    -- Legacy API (WoW 3.3.5)
    print("|cFF00FFB0GearMenu:|r Using legacy InterfaceOptions API")
    
    -- Open Interface Options frame
    if not InterfaceOptionsFrame:IsShown() then
      ShowUIPanel(InterfaceOptionsFrame)
    end
    
    -- Try to open to our category
    local success = pcall(function()
      InterfaceOptionsFrame_OpenToCategory(mainCategoryId)
    end)
    
    if not success then
      print("|cffff0000GearMenu Error:|r Failed to open category. Trying alternative method...")
      -- Alternative: Open Interface Options and manually select
      if InterfaceOptionsFrame then
        ShowUIPanel(InterfaceOptionsFrame)
        -- The panel should be accessible via the addon list
      end
    else
      print("|cFF00FF00GearMenu:|r Configuration panel opened successfully")
    end
  end
end

--[[
  Loops through the interface categories and searches for a matching gearBar. If one
  can be found it is getting deleted.

  @param {number} gearBarId
]]--
function me.InterfaceOptionsRemoveCategory(gearBarId)
  local categories = me.GetGearBarSubCategory().subcategories

  for i = 1, #categories do
    local interfaceCategory = categories[i]

    if interfaceCategory.gearBarId == gearBarId then
      categories[i] = nil -- delete category
      break
    end
  end

  local currentIndex = 0

  for i = 1, #categories do
    if categories[i] ~= nil then
      currentIndex = currentIndex + 1
      categories[currentIndex] = categories[i]
    end
  end

  for i = currentIndex + 1, #categories do
    categories[i] = nil
  end

  me.UpdateAddonPanel()
end

--[[
    This is a workaround to force a refresh of the interface addon panel after a gearBar was deleted.
    Moving to another category in the Blizzard settings and back to the addon panel will refresh the
    panel and show the updated gearBar list.
  ]]--
function me.UpdateAddonPanel()
  -- In 3.3.5, we need to refresh the Interface Options frame to show new categories
  if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
    -- Force a refresh by closing and reopening
    InterfaceOptionsFrame_OpenToCategory(mainCategoryId)
  end
end
