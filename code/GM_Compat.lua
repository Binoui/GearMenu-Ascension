--[[
  Compatibility layer for WoW 3.3.5
  Provides C_Timer compatibility for older clients
]]--

-- Create C_Timer if it doesn't exist (for WoW 3.3.5)
if not C_Timer then
  C_Timer = {}
  
  -- Timer object for NewTicker
  local Ticker = {}
  Ticker.__index = Ticker
  
  function Ticker:Cancel()
    if self.frame then
      self.frame:Hide()
      self.frame:SetScript("OnUpdate", nil)
      self.cancelled = true
    end
  end
  
  function Ticker:IsCancelled()
    return self.cancelled == true
  end
  
  -- Create a frame-based timer for After
  function C_Timer.After(delay, callback)
    local frame = CreateFrame("Frame")
    local cancelled = false
    local target = GetTime() + (tonumber(delay) or 0)
    frame:SetScript("OnUpdate", function(self)
      if cancelled then
        self:SetScript("OnUpdate", nil)
        self:Hide()
        return
      end
      if GetTime() >= target then
        self:SetScript("OnUpdate", nil)
        self:Hide()
        callback()
      end
    end)
    frame:Show()
    return {
      Cancel = function() cancelled = true end,
      IsCancelled = function() return cancelled end,
    }
  end
  
  -- Create a repeating ticker
  function C_Timer.NewTicker(interval, callback)
    local ticker = setmetatable({}, Ticker)
    local frame = CreateFrame("Frame")
    ticker.frame = frame
    ticker.cancelled = false
    ticker.interval = interval
    ticker.callback = callback
    ticker.elapsed = 0
    
    frame:SetScript("OnUpdate", function(self, dt)
      if ticker.cancelled then
        self:Hide()
        self:SetScript("OnUpdate", nil)
        return
      end
      ticker.elapsed = ticker.elapsed + dt
      if ticker.elapsed >= interval then
        ticker.elapsed = 0
        callback()
      end
    end)
    frame:Show()
    
    return ticker
  end
end

-- Compatibility for ChannelInfo -> UnitChannelInfo
if not ChannelInfo then
  function ChannelInfo(unit)
    return UnitChannelInfo(unit)
  end
end

-- Compatibility for C_Container (doesn't exist in WoW 3.3.5)
if not C_Container then
  C_Container = {}
  
  function C_Container.GetContainerNumSlots(bag)
    return GetContainerNumSlots(bag)
  end
  
  function C_Container.GetContainerItemID(bag, slot)
    local itemLink = GetContainerItemLink(bag, slot)
    if itemLink then
      local _, _, itemId = string.find(itemLink, "item:(%d+):")
      if itemId then
        return tonumber(itemId)
      end
    end
    return nil
  end
  
  function C_Container.GetContainerItemLink(bag, slot)
    return GetContainerItemLink(bag, slot)
  end
  
  function C_Container.GetContainerItemInfo(bag, slot)
    -- In WoW 3.3.5, GetContainerItemInfo returns: texture, itemCount, locked, quality, readable, lootable, itemLink
    local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(bag, slot)
    if not texture then
      return nil
    end
    -- Modern API returns a table with iconFileID, but 3.3.5 returns multiple values
    -- Create a compatibility table for modern usage
    local result = {
      texture = texture,
      itemCount = itemCount,
      locked = locked,
      quality = quality,
      readable = readable,
      lootable = lootable,
      itemLink = itemLink,
      iconFileID = texture, -- In 3.3.5, texture is a string path, SetTexture accepts it
    }
    return result
  end
  
  function C_Container.PickupContainerItem(bag, slot)
    PickupContainerItem(bag, slot)
  end
  
  function C_Container.GetItemCooldown(itemId)
    -- In 3.3.5, GetItemCooldown takes itemId directly
    return GetItemCooldown(itemId)
  end
end

-- Note: In WoW 3.3.5, SetBackdrop works natively on all frames
-- The "BackdropTemplate" template doesn't exist but isn't needed
-- Frames can use SetBackdrop directly without the template
-- We'll handle "BackdropTemplate" by removing it from template strings when creating frames

-- Compatibility wrapper for CreateFrame to handle BackdropTemplate
local originalCreateFrame = CreateFrame
CreateFrame = function(frameType, name, parent, template, ...)
  if template and type(template) == "string" and template:find("BackdropTemplate") then
    -- Remove BackdropTemplate from template string (not needed in 3.3.5)
    template = template:gsub("%s*BackdropTemplate%s*,?", ""):gsub(",?%s*BackdropTemplate%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if template == "" then
      template = nil
    end
  end
  return originalCreateFrame(frameType, name, parent, template, ...)
end

-- Compatibility for SetAtlas (doesn't exist in WoW 3.3.5)
-- Add SetAtlas method to textures if it doesn't exist
-- Note: CreateFrame doesn't support "Texture" as a frame type, so we test differently
local testFrame = CreateFrame("Frame", nil, UIParent)
local testTexture = testFrame:CreateTexture()
if not testTexture.SetAtlas then
  -- Create a mixin for SetAtlas
  local SetAtlasMixin = {
    SetAtlas = function(self, atlas, ...)
      -- In 3.3.5, treat atlas as a texture path
      if type(atlas) == "string" then
        self:SetTexture(atlas)
      else
        self:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      end
    end
  }
  
  -- Apply to all texture creation via hook
  local frameMeta = getmetatable(CreateFrame("Frame"))
  if frameMeta and frameMeta.__index then
    local originalCreateTexture = frameMeta.__index.CreateTexture
    frameMeta.__index.CreateTexture = function(self, name, layer, subLayer, textureType)
      local texture = originalCreateTexture(self, name, layer, subLayer, textureType)
      if texture and not texture.SetAtlas then
        -- Mix in SetAtlas method
        for k, v in pairs(SetAtlasMixin) do
          texture[k] = v
        end
      end
      return texture
    end
  end
end
-- Clean up test frame
testFrame:Hide()

-- Compatibility for C_LossOfControl (doesn't exist in WoW 3.3.5)
-- In 3.3.5, loss of control effects are not tracked via this API
-- We'll create a stub that returns empty data
if not C_LossOfControl then
  C_LossOfControl = {}
  
  function C_LossOfControl.GetActiveLossOfControlDataCount()
    -- In 3.3.5, we can't detect loss of control effects via API
    -- Return 0 to indicate no active effects
    return 0
  end
  
  function C_LossOfControl.GetActiveLossOfControlData(index)
    -- Return nil since we can't get this data in 3.3.5
    return nil
  end
end


