-- UI Library for Roblox
local Library = {}
Library.__index = Library

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Local player
local Player = Players.LocalPlayer

-- Configuration
local CONFIG = {
    TOGGLE_KEY = Enum.KeyCode.P,
    TOGGLE_COOLDOWN = 0.25,
    
    GUI = {
        X = 200, Y = 120,
        WIDTH = 770, HEIGHT = 520,
        LEFT_WIDTH = 195
    },
    
    COLORS = {
        LEFT_PANEL = Color3.fromRGB(5, 5, 5),
        RIGHT_PANEL = Color3.fromRGB(0, 0, 0),
        NICK_BLOCK = Color3.fromRGB(30, 30, 30),
        NICK_CIRCLE = Color3.fromRGB(70, 70, 70),
        BLOCK_BG = Color3.fromRGB(25, 25, 25),
        TOGGLE_OFF = Color3.fromRGB(60, 60, 60),
        TOGGLE_ON = Color3.fromRGB(100, 150, 255),
        SLIDER_BG = Color3.fromRGB(40, 40, 40),
        SLIDER_FILL = Color3.fromRGB(100, 150, 255),
        ACTIVE_TAB = Color3.fromRGB(100, 150, 255),
        TEXT_DEFAULT = Color3.new(1, 1, 1),
        TEXT_INACTIVE = Color3.fromRGB(150, 150, 150),
        HEADER = Color3.fromRGB(180, 180, 180),
        SCROLLBAR_BG = Color3.fromRGB(30, 30, 30),
        SCROLLBAR_THUMB = Color3.fromRGB(100, 150, 255),
        BUTTON_BG = Color3.fromRGB(50, 50, 50),
        DROPDOWN_BG = Color3.fromRGB(20, 20, 20),
        CHECKBOX_OFF = Color3.fromRGB(60, 60, 60),
        CHECKBOX_ON = Color3.fromRGB(100, 150, 255)
    },
    
    OPACITY = {
        LEFT = 0.6,
        RIGHT = 0.92,
        NICK_BLOCK = 0.92,
        BLOCK = 0.85,
        SCROLLBAR = 0.95,
        DROPDOWN = 0.98
    },
    
    LAYOUT = {
        LINE_SPACING = 40,
        TEXT_OFFSET_X = 50,
        NICK_HEIGHT = 50,
        AVATAR_SIZE = 30,
        BLOCK_PADDING = 15,
        BLOCK_SPACING = 15,
        OPTION_HEIGHT = 30,
        OPTION_SPACING = 8,
        TOGGLE_WIDTH = 40,
        TOGGLE_HEIGHT = 20,
        TOGGLE_CIRCLE_RADIUS = 8,
        SLIDER_HEIGHT = 6,
        SLIDER_CIRCLE_RADIUS = 10,
        SCROLLBAR_WIDTH = 10,
        BUTTON_HEIGHT = 25,
        DROPDOWN_ITEM_HEIGHT = 25
    },
    
    TEXT_SIZE = {
        TITLE = 27,
        HEADER = 13,
        BUTTON = 16,
        BLOCK_TITLE = 16,
        OPTION = 12,
        NICK = 18
    }
}

-- Global variables
local Panel = {x = CONFIG.GUI.X, y = CONFIG.GUI.Y}
local GUI_Visible = false
local GUI_Initialized = false
local ActiveDropdown = nil
local ScreenGui = nil

-- Utility functions
local function PointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and py >= ry and px <= rx + rw and py <= ry + rh
end

local function PointInCircle(px, py, cx, cy, radius)
    local dx, dy = px - cx, py - cy
    return (dx * dx + dy * dy) <= (radius * radius)
end

local function Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function CreateFrame(parent, properties)
    local frame = Instance.new("Frame")
    for property, value in pairs(properties) do
        frame[property] = value
    end
    frame.Parent = parent
    return frame
end

local function CreateTextLabel(parent, properties)
    local label = Instance.new("TextLabel")
    for property, value in pairs(properties) do
        label[property] = value
    end
    label.Parent = parent
    return label
end

local function CreateImageLabel(parent, properties)
    local image = Instance.new("ImageLabel")
    for property, value in pairs(properties) do
        image[property] = value
    end
    image.Parent = parent
    return image
end

local function CreateUICorner(parent, cornerRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = parent
    return corner
end

local function CreateUIStroke(parent, properties)
    local stroke = Instance.new("UIStroke")
    for property, value in pairs(properties) do
        stroke[property] = value
    end
    stroke.Parent = parent
    return stroke
end

-- Scroll Manager
local ScrollManager = {
    offset = 0,
    maxOffset = 0,
    draggingThumb = false,
    dragStartY = 0,
    dragStartOffset = 0
}

function ScrollManager:Init(parent)
    self.scrollbarBg = CreateFrame(parent, {
        Size = UDim2.new(0, CONFIG.LAYOUT.SCROLLBAR_WIDTH, 1, -16),
        Position = UDim2.new(1, -CONFIG.LAYOUT.SCROLLBAR_WIDTH - 8, 0, 8),
        BackgroundColor3 = CONFIG.COLORS.SCROLLBAR_BG,
        BackgroundTransparency = 1 - CONFIG.OPACITY.SCROLLBAR,
        Visible = false
    })
    CreateUICorner(self.scrollbarBg, 5)
    
    self.scrollbarThumb = CreateFrame(parent, {
        Size = UDim2.new(0, CONFIG.LAYOUT.SCROLLBAR_WIDTH, 0, 40),
        Position = UDim2.new(1, -CONFIG.LAYOUT.SCROLLBAR_WIDTH - 8, 0, 8),
        BackgroundColor3 = CONFIG.COLORS.SCROLLBAR_THUMB,
        BackgroundTransparency = 1 - CONFIG.OPACITY.SCROLLBAR,
        Visible = false
    })
    CreateUICorner(self.scrollbarThumb, 5)
end

function ScrollManager:UpdateMaxOffset(contentHeight, viewHeight)
    self.maxOffset = math.max(0, contentHeight - viewHeight)
    self.offset = Clamp(self.offset, 0, self.maxOffset)
end

function ScrollManager:Update(rightX, rightY, rightWidth, rightHeight)
    if self.maxOffset > 10 then
        self.scrollbarBg.Visible = GUI_Visible and GUI_Initialized
        
        local thumbHeight = math.max(40, (rightHeight - 16) * (rightHeight / (rightHeight + self.maxOffset)))
        local scrollableHeight = rightHeight - 16 - thumbHeight
        local thumbY = rightY + 8 + (scrollableHeight * (self.offset / self.maxOffset))
        
        self.scrollbarThumb.Size = UDim2.new(0, CONFIG.LAYOUT.SCROLLBAR_WIDTH, 0, thumbHeight)
        self.scrollbarThumb.Position = UDim2.new(0, rightX + rightWidth - CONFIG.LAYOUT.SCROLLBAR_WIDTH - 8, 0, thumbY)
        self.scrollbarThumb.Visible = GUI_Visible and GUI_Initialized
    else
        self.scrollbarBg.Visible = false
        self.scrollbarThumb.Visible = false
    end
end

function ScrollManager:HandleThumbDrag(mx, my)
    if self.draggingThumb then
        local rightY = Panel.y
        local rightHeight = CONFIG.GUI.HEIGHT
        local thumbHeight = math.max(40, (rightHeight - 16) * (rightHeight / (rightHeight + self.maxOffset)))
        
        local deltaY = my - self.dragStartY
        local scrollRange = rightHeight - 16 - thumbHeight
        if scrollRange > 0 then
            local scrollDelta = (deltaY / scrollRange) * self.maxOffset
            self.offset = Clamp(self.dragStartOffset + scrollDelta, 0, self.maxOffset)
        end
        return true
    end
    return false
end

function ScrollManager:StartThumbDrag(mx, my)
    if self.maxOffset <= 10 then return false end
    
    local pos = self.scrollbarThumb.AbsolutePosition
    local size = self.scrollbarThumb.AbsoluteSize
    
    if PointInRect(mx, my, pos.X, pos.Y, size.X, size.Y) then
        self.draggingThumb = true
        self.dragStartY = my
        self.dragStartOffset = self.offset
        return true
    end
    return false
end

function ScrollManager:StopThumbDrag()
    self.draggingThumb = false
end

-- Toggle Component
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(option, accentColor, parent)
    local self = setmetatable({}, Toggle)
    self.option = option
    self.accentColor = accentColor or CONFIG.COLORS.TOGGLE_ON
    
    self.container = CreateFrame(parent, {
        Size = UDim2.new(1, 0, 0, CONFIG.LAYOUT.OPTION_HEIGHT),
        BackgroundTransparency = 1
    })
    
    self.label = CreateTextLabel(self.container, {
        Size = UDim2.new(0, 175, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = option.Name,
        TextSize = CONFIG.TEXT_SIZE.OPTION,
        TextColor3 = CONFIG.COLORS.TEXT_INACTIVE,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })
    
    self.toggleFrame = CreateFrame(self.container, {
        Size = UDim2.new(0, CONFIG.LAYOUT.TOGGLE_WIDTH, 0, CONFIG.LAYOUT.TOGGLE_HEIGHT),
        Position = UDim2.new(0, 175, 0.5, -CONFIG.LAYOUT.TOGGLE_HEIGHT/2),
        BackgroundColor3 = CONFIG.COLORS.TOGGLE_OFF,
        BackgroundTransparency = 0.2
    })
    CreateUICorner(self.toggleFrame, 10)
    
    self.toggleCircle = CreateFrame(self.toggleFrame, {
        Size = UDim2.new(0, CONFIG.LAYOUT.TOGGLE_CIRCLE_RADIUS * 2, 0, CONFIG.LAYOUT.TOGGLE_CIRCLE_RADIUS * 2),
        Position = UDim2.new(0, 2, 0.5, -CONFIG.LAYOUT.TOGGLE_CIRCLE_RADIUS),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0
    })
    CreateUICorner(self.toggleCircle, CONFIG.LAYOUT.TOGGLE_CIRCLE_RADIUS)
    
    self:UpdateVisuals()
    
    return self
end

function Toggle:UpdateVisuals()
    self.label.TextColor3 = self.option.Value and CONFIG.COLORS.TEXT_DEFAULT or CONFIG.COLORS.TEXT_INACTIVE
    self.toggleFrame.BackgroundColor3 = self.option.Value and self.accentColor or CONFIG.COLORS.TOGGLE_OFF
    
    local circlePos = self.option.Value and 
        (CONFIG.LAYOUT.TOGGLE_WIDTH - CONFIG.LAYOUT.TOGGLE_CIRCLE_RADIUS * 2 - 2) or 2
    
    self.toggleCircle.Position = UDim2.new(0, circlePos, 0.5, -CONFIG.LAYOUT.TOGGLE_CIRCLE_RADIUS)
end

function Toggle:HandleClick(mx, my)
    local absPos = self.toggleFrame.AbsolutePosition
    local absSize = self.toggleFrame.AbsoluteSize
    
    if PointInRect(mx, my, absPos.X, absPos.Y, absSize.X, absSize.Y) then
        self.option.Value = not self.option.Value
        self:UpdateVisuals()
        
        if self.option.Callback then
            self.option.Callback(self.option.Value)
        end
        return true
    end
    return false
end

function Toggle:SetVisible(visible)
    self.container.Visible = visible
end

-- Slider Component
local Slider = {}
Slider.__index = Slider

function Slider.new(option, accentColor, parent)
    local self = setmetatable({}, Slider)
    self.option = option
    self.dragging = false
    self.accentColor = accentColor or CONFIG.COLORS.SLIDER_FILL
    
    self.container = CreateFrame(parent, {
        Size = UDim2.new(1, 0, 0, CONFIG.LAYOUT.OPTION_HEIGHT),
        BackgroundTransparency = 1
    })
    
    self.label = CreateTextLabel(self.container, {
        Size = UDim2.new(0, 75, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = option.Name,
        TextSize = CONFIG.TEXT_SIZE.OPTION,
        TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })
    
    self.sliderBg = CreateFrame(self.container, {
        Size = UDim2.new(0, 100, 0, CONFIG.LAYOUT.SLIDER_HEIGHT),
        Position = UDim2.new(0, 75, 0, 5),
        BackgroundColor3 = CONFIG.COLORS.SLIDER_BG,
        BackgroundTransparency = 0.2
    })
    CreateUICorner(self.sliderBg, 3)
    
    self.sliderFill = CreateFrame(self.sliderBg, {
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.accentColor,
        BackgroundTransparency = 0.2
    })
    CreateUICorner(self.sliderFill, 3)
    
    self.sliderCircle = CreateFrame(self.container, {
        Size = UDim2.new(0, CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS * 2, 0, CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS * 2),
        Position = UDim2.new(0, 75, 0, 8 - CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0
    })
    CreateUICorner(self.sliderCircle, CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS)
    
    self.valueText = CreateTextLabel(self.container, {
        Size = UDim2.new(0, 50, 1, 0),
        Position = UDim2.new(0, 180, 0, 0),
        Text = tostring(math.floor(option.Value)),
        TextSize = CONFIG.TEXT_SIZE.OPTION,
        TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })
    
    self:UpdateVisuals()
    
    return self
end

function Slider:UpdateVisuals()
    local percent = (self.option.Value - self.option.Min) / (self.option.Max - self.option.Min)
    local fillWidth = 100 * percent
    
    self.sliderFill.Size = UDim2.new(0, fillWidth, 1, 0)
    self.sliderCircle.Position = UDim2.new(0, 75 + fillWidth - CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS, 0, 8 - CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS)
    self.valueText.Text = tostring(math.floor(self.option.Value))
end

function Slider:HandleDrag(mx, my)
    if self.dragging then
        local absPos = self.sliderBg.AbsolutePosition
        local absSize = self.sliderBg.AbsoluteSize
        
        local percent = Clamp((mx - absPos.X) / absSize.X, 0, 1)
        self.option.Value = Lerp(self.option.Min, self.option.Max, percent)
        self:UpdateVisuals()
        
        if self.option.Callback then
            self.option.Callback(self.option.Value)
        end
        return true
    end
    return false
end

function Slider:StartDrag(mx, my)
    local absPos = self.sliderBg.AbsolutePosition
    local absSize = self.sliderBg.AbsoluteSize
    local circlePos = self.sliderCircle.AbsolutePosition
    
    if PointInRect(mx, my, absPos.X, absPos.Y - 5, absSize.X, absSize.Y + 10) or
       PointInCircle(mx, my, circlePos.X + CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS, 
                    circlePos.Y + CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS, 
                    CONFIG.LAYOUT.SLIDER_CIRCLE_RADIUS) then
        self.dragging = true
        return true
    end
    return false
end

function Slider:StopDrag()
    self.dragging = false
end

function Slider:SetVisible(visible)
    self.container.Visible = visible
end

-- MultiSelect Component
local MultiSelect = {}
MultiSelect.__index = MultiSelect

function MultiSelect.new(option, accentColor, parent)
    local self = setmetatable({}, MultiSelect)
    self.option = option
    self.accentColor = accentColor or CONFIG.COLORS.CHECKBOX_ON
    self.isOpen = false
    self.dropdownElements = {}
    
    self.container = CreateFrame(parent, {
        Size = UDim2.new(1, 0, 0, CONFIG.LAYOUT.OPTION_HEIGHT),
        BackgroundTransparency = 1
    })
    
    self.label = CreateTextLabel(self.container, {
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = option.Name,
        TextSize = CONFIG.TEXT_SIZE.OPTION,
        TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })
    
    self.button = CreateFrame(self.container, {
        Size = UDim2.new(0, 115, 0, CONFIG.LAYOUT.BUTTON_HEIGHT),
        Position = UDim2.new(0, 100, 0, -2),
        BackgroundColor3 = CONFIG.COLORS.BUTTON_BG,
        BackgroundTransparency = 0.2
    })
    CreateUICorner(self.button, 3)
    
    self.buttonText = CreateTextLabel(self.button, {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Text = "Select...",
        TextSize = CONFIG.TEXT_SIZE.OPTION,
        TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })
    
    self.dropdownBg = CreateFrame(parent, {
        Size = UDim2.new(0, 115, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = CONFIG.COLORS.DROPDOWN_BG,
        BackgroundTransparency = 1 - CONFIG.OPACITY.DROPDOWN,
        Visible = false,
        ClipsDescendants = true
    })
    CreateUICorner(self.dropdownBg, 3)
    CreateUIStroke(self.dropdownBg, {Color = CONFIG.COLORS.TOGGLE_OFF, Thickness = 1})
    
    for _, itemName in ipairs(option.Options) do
        local itemFrame = CreateFrame(self.dropdownBg, {
            Size = UDim2.new(1, 0, 0, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT),
            Position = UDim2.new(0, 0, 0, 5 + (#self.dropdownElements * CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT)),
            BackgroundTransparency = 1
        })
        
        local checkbox = CreateFrame(itemFrame, {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 5, 0, 3),
            BackgroundColor3 = CONFIG.COLORS.CHECKBOX_OFF,
            BackgroundTransparency = 0.2
        })
        CreateUICorner(checkbox, 2)
        
        local checkmark = CreateTextLabel(checkbox, {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Text = "✓",
            TextSize = 14,
            TextColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Font = Enum.Font.GothamBold,
            Visible = false
        })
        
        local itemText = CreateTextLabel(itemFrame, {
            Size = UDim2.new(1, -28, 1, 0),
            Position = UDim2.new(0, 28, 0, 0),
            Text = itemName,
            TextSize = CONFIG.TEXT_SIZE.OPTION,
            TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham
        })
        
        table.insert(self.dropdownElements, {
            name = itemName,
            frame = itemFrame,
            checkbox = checkbox,
            checkmark = checkmark,
            text = itemText,
            selected = false
        })
    end
    
    self:UpdateVisuals()
    
    return self
end

function MultiSelect:UpdateVisuals()
    local selectedCount = 0
    for _, elem in ipairs(self.dropdownElements) do
        if elem.selected then selectedCount = selectedCount + 1 end
    end
    
    self.buttonText.Text = selectedCount > 0 and ("Selected: " .. selectedCount) or "Select..."
    
    if self.isOpen then
        local dropdownHeight = #self.dropdownElements * CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT + 10
        self.dropdownBg.Size = UDim2.new(0, 115, 0, dropdownHeight)
        self.dropdownBg.Visible = true
        
        for i, elem in ipairs(self.dropdownElements) do
            elem.frame.Position = UDim2.new(0, 0, 0, 5 + (i - 1) * CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT)
            elem.checkbox.BackgroundColor3 = elem.selected and self.accentColor or CONFIG.COLORS.CHECKBOX_OFF
            elem.checkmark.Visible = elem.selected
        end
    else
        self.dropdownBg.Visible = false
    end
end

function MultiSelect:HandleClick(mx, my)
    local buttonAbsPos = self.button.AbsolutePosition
    local buttonAbsSize = self.button.AbsoluteSize
    
    if PointInRect(mx, my, buttonAbsPos.X, buttonAbsPos.Y, buttonAbsSize.X, buttonAbsSize.Y) then
        self.isOpen = not self.isOpen
        if self.isOpen and ActiveDropdown and ActiveDropdown ~= self then
            ActiveDropdown.isOpen = false
            ActiveDropdown:UpdateVisuals()
        end
        ActiveDropdown = self.isOpen and self or nil
        self:UpdateVisuals()
        return true
    end
    
    if self.isOpen then
        local dropdownAbsPos = self.dropdownBg.AbsolutePosition
        local dropdownAbsSize = self.dropdownBg.AbsoluteSize
        
        if PointInRect(mx, my, dropdownAbsPos.X, dropdownAbsPos.Y, dropdownAbsSize.X, dropdownAbsSize.Y) then
            for i, elem in ipairs(self.dropdownElements) do
                local itemAbsPos = elem.frame.AbsolutePosition
                local itemAbsSize = elem.frame.AbsoluteSize
                
                if PointInRect(mx, my, itemAbsPos.X, itemAbsPos.Y, itemAbsSize.X, itemAbsSize.Y) then
                    elem.selected = not elem.selected
                    
                    if not self.option.Values then
                        self.option.Values = {}
                    end
                    
                    if elem.selected then
                        table.insert(self.option.Values, elem.name)
                    else
                        for j, v in ipairs(self.option.Values) do
                            if v == elem.name then
                                table.remove(self.option.Values, j)
                                break
                            end
                        end
                    end
                    
                    if self.option.Callback then
                        self.option.Callback(self.option.Values)
                    end
                    
                    self:UpdateVisuals()
                    return true
                end
            end
        else
            self.isOpen = false
            ActiveDropdown = nil
            self:UpdateVisuals()
        end
    end
    
    return false
end

function MultiSelect:SetVisible(visible)
    self.container.Visible = visible
    if not visible then
        self.dropdownBg.Visible = false
    end
end

-- Section Component
local Section = {}
Section.__index = Section

function Section.new(data, accentColor, parent)
    local self = setmetatable({}, Section)
    self.data = data
    self.accentColor = accentColor
    
    self.container = CreateFrame(parent, {
        BackgroundColor3 = CONFIG.COLORS.BLOCK_BG,
        BackgroundTransparency = 1 - CONFIG.OPACITY.BLOCK,
        ClipsDescendants = true
    })
    CreateUICorner(self.container, 5)
    
    self.title = CreateTextLabel(self.container, {
        Size = UDim2.new(1, -CONFIG.LAYOUT.BLOCK_PADDING * 2, 0, CONFIG.TEXT_SIZE.BLOCK_TITLE),
        Position = UDim2.new(0, CONFIG.LAYOUT.BLOCK_PADDING, 0, CONFIG.LAYOUT.BLOCK_PADDING),
        Text = data.Name,
        TextSize = CONFIG.TEXT_SIZE.BLOCK_TITLE,
        TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold
    })
    
    self.components = {}
    
    return self
end

function Section:Toggle(options)
    local option = {
        Name = options.Name or "Toggle",
        Value = options.Default or false,
        Callback = options.Callback
    }
    
    local toggle = Toggle.new(option, self.accentColor, self.container)
    table.insert(self.components, toggle)
    
    return {
        SetValue = function(value)
            option.Value = value
            toggle:UpdateVisuals()
            if option.Callback then
                option.Callback(value)
            end
        end,
        GetValue = function()
            return option.Value
        end
    }
end

function Section:Slider(options)
    local option = {
        Name = options.Name or "Slider",
        Min = options.Min or 0,
        Max = options.Max or 100,
        Value = options.Default or 50,
        Callback = options.Callback
    }
    
    local slider = Slider.new(option, self.accentColor, self.container)
    table.insert(self.components, slider)
    
    return {
        SetValue = function(value)
            option.Value = Clamp(value, option.Min, option.Max)
            slider:UpdateVisuals()
            if option.Callback then
                option.Callback(option.Value)
            end
        end,
        GetValue = function()
            return option.Value
        end
    }
end

function Section:MultiSelect(options)
    local option = {
        Name = options.Name or "Multi Select",
        Options = options.Options or {},
        Values = {},
        Callback = options.Callback
    }
    
    local multiselect = MultiSelect.new(option, self.accentColor, self.container)
    table.insert(self.components, multiselect)
    
    return {
        GetSelected = function()
            return option.Values
        end,
        SetSelected = function(values)
            option.Values = values or {}
            for _, elem in ipairs(multiselect.dropdownElements) do
                elem.selected = false
                for _, v in ipairs(option.Values) do
                    if elem.name == v then
                        elem.selected = true
                        break
                    end
                end
            end
            multiselect:UpdateVisuals()
            if option.Callback then
                option.Callback(option.Values)
            end
        end
    }
end

function Section:CalculateHeight()
    local height = CONFIG.LAYOUT.BLOCK_PADDING * 2 + CONFIG.TEXT_SIZE.BLOCK_TITLE + 10
    for _, component in ipairs(self.components) do
        height = height + CONFIG.LAYOUT.OPTION_HEIGHT + CONFIG.LAYOUT.OPTION_SPACING
    end
    return height
end

function Section:UpdateBlock(x, y, width)
    self.container.Position = UDim2.new(0, x, 0, y)
    local height = self:CalculateHeight()
    self.container.Size = UDim2.new(0, width, 0, height)
    
    local optionY = CONFIG.LAYOUT.BLOCK_PADDING + CONFIG.TEXT_SIZE.BLOCK_TITLE + 15
    for _, component in ipairs(self.components) do
        component.container.Position = UDim2.new(0, CONFIG.LAYOUT.BLOCK_PADDING, 0, optionY)
        optionY = optionY + CONFIG.LAYOUT.OPTION_HEIGHT + CONFIG.LAYOUT.OPTION_SPACING
    end
    
    return height
end

function Section:SetVisible(visible, clipY, clipHeight)
    if not visible or not GUI_Initialized then
        self.container.Visible = false
        for _, component in ipairs(self.components) do
            component:SetVisible(false)
        end
        return
    end
    
    local blockY = self.container.AbsolutePosition.Y
    local blockHeight = self.container.AbsoluteSize.Y
    local blockBottom = blockY + blockHeight
    local clipBottom = clipY + clipHeight
    
    if blockBottom < clipY or blockY > clipBottom then
        self.container.Visible = false
        for _, component in ipairs(self.components) do
            component:SetVisible(false)
        end
        return
    end
    
    self.container.Visible = GUI_Visible and GUI_Initialized
    
    for _, component in ipairs(self.components) do
        component:SetVisible(true)
    end
end

-- Tab Component
local Tab = {}
Tab.__index = Tab

function Tab.new(name, accentColor, parent)
    local self = setmetatable({}, Tab)
    self.name = name
    self.accentColor = accentColor
    self.sections = {}
    self.isActive = false
    
    return self
end

function Tab:Section(options)
    local section = Section.new(options, self.accentColor, ScreenGui)
    table.insert(self.sections, section)
    return section
end

-- Main Library
function Library:Create(options)
    local self = setmetatable({}, Library)
    
    self.Name = options.Name or "UI Library"
    self.AccentColor = options.AccentColor or CONFIG.COLORS.TOGGLE_ON
    self.ToggleKey = options.ToggleKey or CONFIG.TOGGLE_KEY
    
    -- Update config with custom colors
    CONFIG.COLORS.TOGGLE_ON = self.AccentColor
    CONFIG.COLORS.SLIDER_FILL = self.AccentColor
    CONFIG.COLORS.ACTIVE_TAB = self.AccentColor
    CONFIG.COLORS.SCROLLBAR_THUMB = self.AccentColor
    CONFIG.COLORS.CHECKBOX_ON = self.AccentColor
    CONFIG.TOGGLE_KEY = self.ToggleKey
    
    -- Create ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UILibrary"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    
    self.tabs = {}
    self.tabButtons = {}
    self.activeTab = nil
    
    -- Create main panels
    self.leftPanel = CreateFrame(ScreenGui, {
        Position = UDim2.new(0, Panel.x, 0, Panel.y),
        Size = UDim2.new(0, CONFIG.GUI.LEFT_WIDTH, 0, CONFIG.GUI.HEIGHT),
        BackgroundColor3 = CONFIG.COLORS.LEFT_PANEL,
        BackgroundTransparency = 1 - CONFIG.OPACITY.LEFT
    })
    
    self.rightPanel = CreateFrame(ScreenGui, {
        Position = UDim2.new(0, Panel.x + CONFIG.GUI.LEFT_WIDTH, 0, Panel.y),
        Size = UDim2.new(0, CONFIG.GUI.WIDTH - CONFIG.GUI.LEFT_WIDTH, 0, CONFIG.GUI.HEIGHT),
        BackgroundColor3 = CONFIG.COLORS.RIGHT_PANEL,
        BackgroundTransparency = 1 - CONFIG.OPACITY.RIGHT,
        ClipsDescendants = true
    })
    
    self.nickBlock = CreateFrame(self.leftPanel, {
        Position = UDim2.new(0, 0, 1, -CONFIG.LAYOUT.NICK_HEIGHT),
        Size = UDim2.new(1, 0, 0, CONFIG.LAYOUT.NICK_HEIGHT),
        BackgroundColor3 = CONFIG.COLORS.NICK_BLOCK,
        BackgroundTransparency = 1 - CONFIG.OPACITY.NICK_BLOCK
    })
    
    self.nickCircle = CreateFrame(self.nickBlock, {
        Size = UDim2.new(0, CONFIG.LAYOUT.AVATAR_SIZE, 0, CONFIG.LAYOUT.AVATAR_SIZE),
        Position = UDim2.new(0, 10, 0.5, -CONFIG.LAYOUT.AVATAR_SIZE/2),
        BackgroundColor3 = CONFIG.COLORS.NICK_CIRCLE,
        BackgroundTransparency = 0
    })
    CreateUICorner(self.nickCircle, CONFIG.LAYOUT.AVATAR_SIZE/2)
    
    -- Load avatar
    local userId = Player.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size100x100
    
    pcall(function()
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if content then
            self.avatarImage = CreateImageLabel(self.nickCircle, {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = content
            })
            CreateUICorner(self.avatarImage, CONFIG.LAYOUT.AVATAR_SIZE/2)
        end
    end)
    
    self.nickText = CreateTextLabel(self.nickBlock, {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        Text = Player.DisplayName,
        TextSize = CONFIG.TEXT_SIZE.NICK,
        TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold
    })
    
    self.title = CreateTextLabel(self.leftPanel, {
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 20),
        Text = self.Name,
        TextSize = CONFIG.TEXT_SIZE.TITLE,
        TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamBold
    })
    
    self.dragging = false
    self.dragOffset = {x = 0, y = 0}
    self.wasLeftPressed = false
    self.lastToggle = 0
    
    ScrollManager:Init(self.rightPanel)
    
    self:SetVisible(false)
    self:StartLoop()
    
    return self
end

function Library:Tab(options)
    local tab = Tab.new(options.Name or "Tab", self.AccentColor, ScreenGui)
    
    local tabButton = {
        name = tab.name,
        tab = tab,
        text = CreateTextLabel(self.leftPanel, {
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0, CONFIG.LAYOUT.TEXT_OFFSET_X - 20, 0, 60 + (#self.tabButtons * CONFIG.LAYOUT.LINE_SPACING)),
            Text = tab.name,
            TextSize = CONFIG.TEXT_SIZE.BUTTON,
            TextColor3 = CONFIG.COLORS.TEXT_DEFAULT,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham
        }),
        box = CreateFrame(self.leftPanel, {
            Size = UDim2.new(1, -20, 0, CONFIG.LAYOUT.LINE_SPACING - 10),
            Position = UDim2.new(0, 10, 0, 55 + (#self.tabButtons * CONFIG.LAYOUT.LINE_SPACING)),
            BackgroundTransparency = 1
        })
    }
    
    table.insert(self.tabButtons, tabButton)
    table.insert(self.tabs, tab)
    
    if not self.activeTab then
        self:SwitchTab(tab)
    end
    
    return tab
end

function Library:SwitchTab(targetTab)
    for _, tab in ipairs(self.tabs) do
        tab.isActive = false
    end
    targetTab.isActive = true
    self.activeTab = targetTab
    ScrollManager.offset = 0
    
    -- Update tab button colors
    for _, tabButton in ipairs(self.tabButtons) do
        tabButton.text.TextColor3 = tabButton.tab.isActive and self.AccentColor or CONFIG.COLORS.TEXT_DEFAULT
    end
end

function Library:SetVisible(visible)
    GUI_Visible = visible
    if ScreenGui then
        ScreenGui.Enabled = visible
    end
end

function Library:UpdateBlocks()
    if not GUI_Initialized then return end
    
    local rightX = Panel.x + CONFIG.GUI.LEFT_WIDTH
    local rightY = Panel.y
    local rightWidth = CONFIG.GUI.WIDTH - CONFIG.GUI.LEFT_WIDTH
    local rightHeight = CONFIG.GUI.HEIGHT
    local blockWidth = (rightWidth - CONFIG.LAYOUT.BLOCK_SPACING * 3 - CONFIG.LAYOUT.SCROLLBAR_WIDTH - 10) / 2
    
    for _, tab in ipairs(self.tabs) do
        if tab.isActive then
            local col1Y = rightY + CONFIG.LAYOUT.BLOCK_SPACING - ScrollManager.offset
            local col2Y = rightY + CONFIG.LAYOUT.BLOCK_SPACING - ScrollManager.offset
            local maxHeight = 0
            
            for i, section in ipairs(tab.sections) do
                local col = ((i - 1) % 2) + 1
                local x = col == 1 and (rightX + CONFIG.LAYOUT.BLOCK_SPACING) or (rightX + blockWidth + CONFIG.LAYOUT.BLOCK_SPACING * 2)
                local y = col == 1 and col1Y or col2Y
                
                local height = section:UpdateBlock(x, y, blockWidth)
                section:SetVisible(GUI_Visible, rightY, rightHeight)
                
                if col == 1 then
                    col1Y = col1Y + height + CONFIG.LAYOUT.BLOCK_SPACING
                    maxHeight = math.max(maxHeight, col1Y - rightY + ScrollManager.offset)
                else
                    col2Y = col2Y + height + CONFIG.LAYOUT.BLOCK_SPACING
                    maxHeight = math.max(maxHeight, col2Y - rightY + ScrollManager.offset)
                end
            end
            
            ScrollManager:UpdateMaxOffset(maxHeight, rightHeight)
        else
            for _, section in ipairs(tab.sections) do
                section:SetVisible(false, 0, 0)
            end
        end
    end
    
    ScrollManager:Update(rightX, rightY, rightWidth, rightHeight)
end

function Library:HandleClick(mx, my)
    if ScrollManager:StartThumbDrag(mx, my) then return end
    
    for _, tabButton in ipairs(self.tabButtons) do
        local absPos = tabButton.box.AbsolutePosition
        local absSize = tabButton.box.AbsoluteSize
        if PointInRect(mx, my, absPos.X, absPos.Y, absSize.X, absSize.Y) then
            self:SwitchTab(tabButton.tab)
            return
        end
    end
    
    if self.activeTab then
        for _, section in ipairs(self.activeTab.sections) do
            if not section.container.Visible then continue end
            
            for _, component in ipairs(section.components) do
                if component.HandleClick and component:HandleClick(mx, my) then
                    return
                end
                if component.StartDrag and component:StartDrag(mx, my) then
                    return
                end
            end
        end
    end
    
    if ActiveDropdown then
        ActiveDropdown:HandleClick(mx, my)
    end
    
    local leftAbsPos = self.leftPanel.AbsolutePosition
    local leftAbsSize = self.leftPanel.AbsoluteSize
    local rightAbsPos = self.rightPanel.AbsolutePosition
    local rightAbsSize = self.rightPanel.AbsoluteSize
    
    if PointInRect(mx, my, leftAbsPos.X, leftAbsPos.Y, leftAbsSize.X, leftAbsSize.Y) or
       PointInRect(mx, my, rightAbsPos.X, rightAbsPos.Y, rightAbsSize.X, rightAbsSize.Y) then
        self.dragging = true
        self.dragOffset.x = mx - Panel.x
        self.dragOffset.y = my - Panel.y
    end
end

function Library:HandleInput()
    if not GUI_Visible or not GUI_Initialized then
        self.dragging = false
        self.wasLeftPressed = false
        for _, tab in ipairs(self.tabs) do
            for _, section in ipairs(tab.sections) do
                for _, component in ipairs(section.components) do
                    if component.StopDrag then
                        component:StopDrag()
                    end
                end
            end
        end
        ScrollManager:StopThumbDrag()
        return
    end
    
    local mouse = UserInputService:GetMouseLocation()
    local mx, my = mouse.X, mouse.Y
    local leftPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    
    if leftPressed then
        if self.activeTab then
            for _, section in ipairs(self.activeTab.sections) do
                for _, component in ipairs(section.components) do
                    if component.HandleDrag then
                        component:HandleDrag(mx, my)
                    end
                end
            end
        end
        
        ScrollManager:HandleThumbDrag(mx, my)
        
        if not self.wasLeftPressed then
            self:HandleClick(mx, my)
        end
    else
        if self.wasLeftPressed then
            if self.activeTab then
                for _, section in ipairs(self.activeTab.sections) do
                    for _, component in ipairs(section.components) do
                        if component.StopDrag then
                            component:StopDrag()
                        end
                    end
                end
            end
            ScrollManager:StopThumbDrag()
        end
        self.dragging = false
    end
    
    if self.dragging then
        Panel.x = mx - self.dragOffset.x
        Panel.y = my - self.dragOffset.y
        
        self.leftPanel.Position = UDim2.new(0, Panel.x, 0, Panel.y)
        self.rightPanel.Position = UDim2.new(0, Panel.x + CONFIG.GUI.LEFT_WIDTH, 0, Panel.y)
    end
    
    self.wasLeftPressed = leftPressed
end

function Library:HandleToggle()
    if UserInputService:IsKeyDown(CONFIG.TOGGLE_KEY) then
        local now = tick()
        if now - self.lastToggle > CONFIG.TOGGLE_COOLDOWN then
            GUI_Visible = not GUI_Visible
            self:SetVisible(GUI_Visible)
            
            if not GUI_Initialized and GUI_Visible then
                GUI_Initialized = true
            end
            
            self.lastToggle = now
        end
    end
end

function Library:StartLoop()
    RunService.RenderStepped:Connect(function()
        self:HandleToggle()
        if not GUI_Visible then return end
        
        self:HandleInput()
        self:UpdateBlocks()
    end)
end

function Library:Unload()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    GUI_Visible = false
    GUI_Initialized = false
    print("[UI Library] Unloaded")
end

return Library
