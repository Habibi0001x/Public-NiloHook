--[[
    NiloHook - Key System UI Library
    Matches lib.luau 1:1 in design, structure, components and themes.
    Full Mobile and PC Support with Auto-Paste and Paste Button on Mobile.
]]

local KeySystem = {}
KeySystem.Key = "NiloHook-Test1"
KeySystem.FileName = "NKey.txt"
KeySystem.DiscordLink = "https://discord.gg/38rUYfz4T"
KeySystem.GetKeyLink = "https://discord.gg/38rUYfz4T"

-- Services & Executor compatibility
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local IsMobile = UserInputService.TouchEnabled or false

local function getGuiParent()
    if gethui then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    local ok, coreGui = pcall(function() 
        return cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui") 
    end)
    if ok and coreGui then return coreGui end
    local plr = Players.LocalPlayer
    if plr then
        local pg = plr:FindFirstChildOfClass("PlayerGui")
        if pg then return pg end
    end
    return game:GetService("StarterGui")
end

-- Function to safely set clipboard content across various executors
local function setClipboardContent(text)
    if setclipboard then
        setclipboard(text)
        return true
    elseif toclipboard then
        toclipboard(text)
        return true
    elseif syn and syn.write_clipboard then
        syn.write_clipboard(text)
        return true
    elseif Clipboard and Clipboard.set then
        Clipboard.set(text)
        return true
    end
    return false
end

-- Function to safely read clipboard content across various executors
local function getClipboardContent()
    if getclipboard then
        local ok, res = pcall(getclipboard)
        if ok and type(res) == "string" then return res end
    elseif fromclipboard then
        local ok, res = pcall(fromclipboard)
        if ok and type(res) == "string" then return res end
    elseif syn and syn.read_clipboard then
        local ok, res = pcall(syn.read_clipboard)
        if ok and type(res) == "string" then return res end
    elseif Clipboard and Clipboard.get then
        local ok, res = pcall(Clipboard.get)
        if ok and type(res) == "string" then return res end
    end
    return nil
end

-- Themes exact 1:1 from lib.luau with Success & Error colors
local Themes = {
    ["Preset"] = {
        Background = Color3.fromRGB(16, 18, 21),
        Inline = Color3.fromRGB(22, 25, 29),
        Shadow = Color3.fromRGB(0, 0, 0),
        Text = Color3.fromRGB(255, 255, 255),
        Image = Color3.fromRGB(255, 255, 255),
        DarkGradient = Color3.fromRGB(211, 211, 211),
        InactiveText = Color3.fromRGB(185, 185, 185),
        Element = Color3.fromRGB(34, 39, 45),
        Accent = Color3.fromRGB(196, 231, 255),
        Border = Color3.fromRGB(32, 36, 42),
        Success = Color3.fromRGB(100, 255, 160),
        Error = Color3.fromRGB(255, 90, 90)
    },
    ["Halloween"] = {
        Background = Color3.fromRGB(11, 10, 9),
        Inline = Color3.fromRGB(23, 18, 16),
        Shadow = Color3.fromRGB(253, 133, 21),
        Text = Color3.fromRGB(198, 198, 198),
        Image = Color3.fromRGB(201, 201, 201),
        DarkGradient = Color3.fromRGB(211, 202, 195),
        InactiveText = Color3.fromRGB(179, 179, 179),
        Element = Color3.fromRGB(42, 32, 26),
        Accent = Color3.fromRGB(253, 133, 21),
        Border = Color3.fromRGB(42, 35, 32),
        Success = Color3.fromRGB(100, 255, 160),
        Error = Color3.fromRGB(255, 90, 90)
    },
    ["Aqua"] = {
        Background = Color3.fromRGB(19, 21, 23),
        Inline = Color3.fromRGB(31, 35, 39),
        Shadow = Color3.fromRGB(0, 0, 0),
        Text = Color3.fromRGB(245, 245, 245),
        Image = Color3.fromRGB(255, 255, 255),
        DarkGradient = Color3.fromRGB(211, 211, 211),
        InactiveText = Color3.fromRGB(185, 185, 185),
        Element = Color3.fromRGB(58, 66, 77),
        Accent = Color3.fromRGB(31, 106, 181),
        Border = Color3.fromRGB(48, 56, 63),
        Success = Color3.fromRGB(100, 255, 160),
        Error = Color3.fromRGB(255, 90, 90)
    },
    ["One Tap"] = {
        Background = Color3.fromRGB(51, 51, 51),
        Inline = Color3.fromRGB(30, 30, 30),
        Shadow = Color3.fromRGB(0, 0, 0),
        Text = Color3.fromRGB(245, 245, 245),
        Image = Color3.fromRGB(255, 255, 255),
        DarkGradient = Color3.fromRGB(211, 211, 211),
        InactiveText = Color3.fromRGB(185, 185, 185),
        Element = Color3.fromRGB(45, 45, 45),
        Accent = Color3.fromRGB(237, 170, 0),
        Border = Color3.fromRGB(0, 0, 0),
        Success = Color3.fromRGB(100, 255, 160),
        Error = Color3.fromRGB(255, 90, 90)
    }
}

-- Select active theme (matches getgenv().theme or Preset)
local function getActiveTheme()
    local themeName = getgenv().theme or "Preset"
    return Themes[themeName] or Themes["Preset"]
end

local safeFont = Font.fromEnum(Enum.Font.BuilderSans)

local function getLighterColor(color, increment)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v * (increment or 1.45), 0, 1))
end

-- Helper functions matching lib.luau Instances
local function applyUIGradient(parent, darkGradientColor)
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 84
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, darkGradientColor or Color3.fromRGB(211, 211, 211))
    })
    gradient.Parent = parent
    return gradient
end

local function applyUIStroke(parent, borderColor, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = borderColor
    stroke.Thickness = 1
    stroke.Transparency = transparency or 0.4
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function applyUICorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 5)
    corner.Parent = parent
    return corner
end

-- Draggable implementation matching lib.luau MakeDraggable
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local inputChanged
            inputChanged = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    inputChanged:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

-- Check if saved key file exists and matches target key
function KeySystem.CheckSavedKey()
    if isfile and isfile(KeySystem.FileName) then
        local ok, content = pcall(readfile, KeySystem.FileName)
        if ok and content then
            content = string.gsub(content, "^%s*(.-)%s*$", "%1") -- trim whitespace
            if content == KeySystem.Key then
                return true
            end
        end
    end
    return false
end

-- Save key to file
function KeySystem.SaveKey(key)
    if writefile then
        pcall(writefile, KeySystem.FileName, key or KeySystem.Key)
    end
end

-- Create UI matching lib.luau 1:1
function KeySystem.CreateUI(onVerifiedCallback)
    local parent = getGuiParent()
    local Theme = getActiveTheme()

    -- Clean up existing Key UI if present
    pcall(function()
        for _, v in ipairs(parent:GetChildren()) do
            if v.Name == "NiloHook_KeySystem" then
                v:Destroy()
            end
        end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NiloHook_KeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = parent

    -- Main Container Frame (Size 480x280)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 480, 0, 280)
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -140)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    applyUICorner(MainFrame, 5)
    applyUIStroke(MainFrame, Theme.Border, 0.4)

    -- Mobile responsive UIScale matching lib.luau line 8044
    if IsMobile then
        local UiScale = Instance.new("UIScale")
        UiScale.Parent = MainFrame

        local function updateScale()
            local vp = Camera.ViewportSize
            local defSize = Vector2.new(480, 280)
            local scaleX = vp.X < (defSize.X + 20) and (vp.X - 30) / defSize.X or 1
            local scaleY = vp.Y < (defSize.Y + 40) and (vp.Y - 50) / defSize.Y or 1
            UiScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.55, 1)
        end

        updateScale()
        pcall(function()
            Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
        end)
    end

    -- Drop Shadow Image matching lib.luau line 8114
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.ImageColor3 = Theme.Shadow
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.ImageTransparency = 0.9
    Shadow.Size = UDim2.new(1, 25, 1, 25)
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Image = "http://www.roblox.com/asset/?id=18245826428"
    Shadow.BackgroundTransparency = 1
    Shadow.BorderSizePixel = 0
    Shadow.SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79))
    Shadow.ZIndex = 1
    Shadow.Parent = MainFrame

    -- Topbar Frame matching lib.luau line 8131
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 35)
    Topbar.BackgroundColor3 = Theme.Inline
    Topbar.BorderSizePixel = 0
    Topbar.ZIndex = 2
    Topbar.Parent = MainFrame

    applyUICorner(Topbar, 5)
    applyUIGradient(Topbar, Theme.DarkGradient)

    -- Topbar Bottom Covers matching lib.luau line 8147-8170
    local TopbarCover = Instance.new("Frame")
    TopbarCover.Size = UDim2.new(1, 0, 0, 3)
    TopbarCover.AnchorPoint = Vector2.new(0, 1)
    TopbarCover.Position = UDim2.new(0, 0, 1, 0)
    TopbarCover.BackgroundColor3 = Theme.Inline
    TopbarCover.BorderSizePixel = 0
    TopbarCover.ZIndex = 2
    TopbarCover.Parent = Topbar

    local TopbarLine = Instance.new("Frame")
    TopbarLine.Size = UDim2.new(1, 0, 0, 1)
    TopbarLine.AnchorPoint = Vector2.new(0, 1)
    TopbarLine.Position = UDim2.new(0, 0, 1, 0)
    TopbarLine.BackgroundColor3 = Theme.Border
    TopbarLine.BackgroundTransparency = 0.4
    TopbarLine.BorderSizePixel = 0
    TopbarLine.ZIndex = 2
    TopbarLine.Parent = Topbar

    -- Logo matching lib.luau line 8181
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0, 22, 0, 22)
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.Position = UDim2.new(0, 7, 0.5, 0)
    Logo.Image = "rbxassetid://135215559087473"
    Logo.ImageColor3 = Theme.Accent
    Logo.BackgroundTransparency = 1
    Logo.BorderSizePixel = 0
    Logo.ZIndex = 2
    Logo.Parent = Topbar

    -- Title matching lib.luau line 8197
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Text = "NiloHook"
    Title.FontFace = safeFont
    Title.TextSize = 14
    Title.TextColor3 = Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Position = UDim2.new(0, 37, 0.5, 0)
    Title.AnchorPoint = Vector2.new(0, 0.5)
    Title.BackgroundTransparency = 1
    Title.AutomaticSize = Enum.AutomaticSize.X
    Title.BorderSizePixel = 0
    Title.ZIndex = 2
    Title.Parent = Topbar

    -- Version Badge matching lib.luau line 8217
    local VersionFrame = Instance.new("Frame")
    VersionFrame.Name = "VersionBadge"
    VersionFrame.Size = UDim2.new(0, 0, 0, 15)
    VersionFrame.Position = UDim2.new(1, 5, 0, 1)
    VersionFrame.BackgroundColor3 = Theme.Background
    VersionFrame.AutomaticSize = Enum.AutomaticSize.X
    VersionFrame.BorderSizePixel = 0
    VersionFrame.ZIndex = 2
    VersionFrame.Parent = Title

    applyUICorner(VersionFrame, 5)
    applyUIStroke(VersionFrame, Theme.Border, 0.4)

    local VersionPadding = Instance.new("UIPadding")
    VersionPadding.PaddingLeft = UDim.new(0, 6)
    VersionPadding.PaddingRight = UDim.new(0, 5)
    VersionPadding.Parent = VersionFrame

    local VersionText = Instance.new("TextLabel")
    VersionText.Text = "Key System"
    VersionText.FontFace = safeFont
    VersionText.TextSize = 12
    VersionText.TextColor3 = Theme.Text
    VersionText.TextTransparency = 0.5
    VersionText.TextXAlignment = Enum.TextXAlignment.Left
    VersionText.BackgroundTransparency = 1
    VersionText.AutomaticSize = Enum.AutomaticSize.X
    VersionText.Size = UDim2.new(0, 0, 0, 15)
    VersionText.BorderSizePixel = 0
    VersionText.ZIndex = 2
    VersionText.Parent = VersionFrame

    -- Close Button matching lib.luau line 8275
    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Name = "CloseButton"
    CloseBtn.Size = UDim2.new(0, 17, 0, 17)
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.Position = UDim2.new(1, -7, 0.5, 0)
    CloseBtn.Image = "rbxassetid://76001605964586"
    CloseBtn.ImageColor3 = Theme.Image
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.AutoButtonColor = false
    CloseBtn.BorderSizePixel = 0
    CloseBtn.ZIndex = 2
    CloseBtn.Parent = Topbar

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Make MainFrame Draggable via Topbar
    makeDraggable(MainFrame, Topbar)

    -- Content Frame Container
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "Content"
    ContentFrame.Size = UDim2.new(1, -24, 1, -47)
    ContentFrame.Position = UDim2.new(0, 12, 0, 41)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    -- Inner Card Section matching lib.luau Section style
    local Section = Instance.new("Frame")
    Section.Name = "Section"
    Section.Size = UDim2.new(1, 0, 1, 0)
    Section.BackgroundColor3 = Theme.Inline
    Section.BorderSizePixel = 0
    Section.Parent = ContentFrame

    applyUICorner(Section, 5)
    applyUIStroke(Section, Theme.Border, 0.4)
    applyUIGradient(Section, Theme.DarkGradient)

    local SectionPadding = Instance.new("UIPadding")
    SectionPadding.PaddingTop = UDim.new(0, 16)
    SectionPadding.PaddingBottom = UDim.new(0, 16)
    SectionPadding.PaddingLeft = UDim.new(0, 16)
    SectionPadding.PaddingRight = UDim.new(0, 16)
    SectionPadding.Parent = Section

    -- Description / Info Label
    local Description = Instance.new("TextLabel")
    Description.Name = "Description"
    Description.Text = "Enter your key below to authenticate and run NiloHook v2."
    Description.FontFace = safeFont
    Description.TextSize = 13
    Description.TextColor3 = Theme.InactiveText
    Description.TextXAlignment = Enum.TextXAlignment.Left
    Description.BackgroundTransparency = 1
    Description.Size = UDim2.new(1, 0, 0, 20)
    Description.Position = UDim2.new(0, 0, 0, 0)
    Description.Parent = Section

    -- Key Input Box Component (Search style 1:1 matching lib.luau line 8363)
    local InputFrame = Instance.new("Frame")
    InputFrame.Name = "KeyInputFrame"
    InputFrame.Size = UDim2.new(1, 0, 0, 36)
    InputFrame.Position = UDim2.new(0, 0, 0, 32)
    InputFrame.BackgroundColor3 = Theme.Inline
    InputFrame.BorderSizePixel = 0
    InputFrame.Parent = Section

    applyUICorner(InputFrame, 5)
    local InputStroke = applyUIStroke(InputFrame, Theme.Border, 0.4)
    applyUIGradient(InputFrame, Theme.DarkGradient)

    -- Key Icon on Left of input box
    local KeyIcon = Instance.new("ImageLabel")
    KeyIcon.Size = UDim2.new(0, 18, 0, 18)
    KeyIcon.AnchorPoint = Vector2.new(0, 0.5)
    KeyIcon.Position = UDim2.new(0, 10, 0.5, 0)
    KeyIcon.Image = "rbxassetid://114252321536924"
    KeyIcon.ImageColor3 = Theme.Accent
    KeyIcon.BackgroundTransparency = 1
    KeyIcon.BorderSizePixel = 0
    KeyIcon.Parent = InputFrame

    -- Helper to bind Mouse & Touch buttons
    local function bindButtonClick(button, callback)
        button.MouseButton1Click:Connect(callback)
        if IsMobile then
            pcall(function() button.TouchTap:Connect(callback) end)
        end
    end

    -- Dedicated Paste Key Button inside InputFrame for Mobile & PC
    local PasteBtn = Instance.new("TextButton")
    PasteBtn.Name = "PasteBtn"
    PasteBtn.Size = UDim2.new(0, 60, 0, 24)
    PasteBtn.AnchorPoint = Vector2.new(1, 0.5)
    PasteBtn.Position = UDim2.new(1, -6, 0.5, 0)
    PasteBtn.BackgroundColor3 = Theme.Element
    PasteBtn.Text = "Paste"
    PasteBtn.FontFace = safeFont
    PasteBtn.TextSize = 12
    PasteBtn.TextColor3 = Theme.Accent
    PasteBtn.AutoButtonColor = false
    PasteBtn.BorderSizePixel = 0
    PasteBtn.ZIndex = 3
    PasteBtn.Parent = InputFrame

    applyUICorner(PasteBtn, 4)
    applyUIStroke(PasteBtn, Theme.Accent, 0.4)
    applyUIGradient(PasteBtn, Theme.DarkGradient)

    PasteBtn.MouseEnter:Connect(function()
        TweenService:Create(PasteBtn, TweenInfo.new(0.15), { BackgroundColor3 = getLighterColor(Theme.Element, 1.45) }):Play()
    end)
    PasteBtn.MouseLeave:Connect(function()
        TweenService:Create(PasteBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Element }):Play()
    end)

    local KeyTextBox = Instance.new("TextBox")
    KeyTextBox.Name = "KeyInput"
    KeyTextBox.Size = UDim2.new(1, -105, 1, 0)
    KeyTextBox.Position = UDim2.new(0, 34, 0, 0)
    KeyTextBox.BackgroundTransparency = 1
    KeyTextBox.PlaceholderText = "enter key here..."
    KeyTextBox.PlaceholderColor3 = Theme.InactiveText
    KeyTextBox.Text = ""
    KeyTextBox.TextColor3 = Theme.Text
    KeyTextBox.FontFace = safeFont
    KeyTextBox.TextSize = 14
    KeyTextBox.TextXAlignment = Enum.TextXAlignment.Left
    KeyTextBox.ClearTextOnFocus = false
    KeyTextBox.Parent = InputFrame

    KeyTextBox.Focused:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.2), { Color = Theme.Accent, Transparency = 0 }):Play()
    end)
    KeyTextBox.FocusLost:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.2), { Color = Theme.Border, Transparency = 0.4 }):Play()
    end)

    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "Status"
    StatusLabel.Text = "Status: waiting for key..."
    StatusLabel.FontFace = safeFont
    StatusLabel.TextSize = 12
    StatusLabel.TextColor3 = Theme.InactiveText
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Position = UDim2.new(0, 0, 0, 76)
    StatusLabel.Parent = Section

    -- Paste Button Action
    bindButtonClick(PasteBtn, function()
        local clip = getClipboardContent()
        if clip and #clip > 0 then
            clip = string.gsub(clip, "^%s*(.-)%s*$", "%1")
            KeyTextBox.Text = clip
            StatusLabel.Text = "Status: Pasted key from clipboard!"
            StatusLabel.TextColor3 = Theme.Accent
        else
            StatusLabel.Text = "Status: Clipboard is empty or unreadable!"
            StatusLabel.TextColor3 = Theme.Error
        end
    end)

    -- Mobile Auto-Paste on open if clipboard contains valid key format
    if IsMobile then
        task.defer(function()
            local clip = getClipboardContent()
            if clip and #clip > 0 then
                clip = string.gsub(clip, "^%s*(.-)%s*$", "%1")
                if clip == KeySystem.Key or string.find(clip, "NiloHook") then
                    KeyTextBox.Text = clip
                    StatusLabel.Text = "Status: Auto-pasted key from clipboard!"
                    StatusLabel.TextColor3 = Theme.Accent
                end
            end
        end)
    end

    -- Button Row Container
    local ButtonRow = Instance.new("Frame")
    ButtonRow.Name = "ButtonRow"
    ButtonRow.Size = UDim2.new(1, 0, 0, 36)
    ButtonRow.Position = UDim2.new(0, 0, 0, 108)
    ButtonRow.BackgroundTransparency = 1
    ButtonRow.Parent = Section

    -- Primary Button (Submit Key with Accent highlight)
    local SubmitBtn = Instance.new("TextButton")
    SubmitBtn.Name = "SubmitKey"
    SubmitBtn.Size = UDim2.new(0.48, -4, 1, 0)
    SubmitBtn.Position = UDim2.new(0, 0, 0, 0)
    SubmitBtn.BackgroundColor3 = Theme.Element
    SubmitBtn.Text = "Submit Key"
    SubmitBtn.FontFace = safeFont
    SubmitBtn.TextSize = 14
    SubmitBtn.TextColor3 = Theme.Accent
    SubmitBtn.AutoButtonColor = false
    SubmitBtn.BorderSizePixel = 0
    SubmitBtn.Parent = ButtonRow

    applyUICorner(SubmitBtn, 5)
    local SubmitStroke = applyUIStroke(SubmitBtn, Theme.Accent, 0.2)
    applyUIGradient(SubmitBtn, Theme.DarkGradient)

    SubmitBtn.MouseEnter:Connect(function()
        TweenService:Create(SubmitBtn, TweenInfo.new(0.15), { BackgroundColor3 = getLighterColor(Theme.Element, 1.45) }):Play()
    end)
    SubmitBtn.MouseLeave:Connect(function()
        TweenService:Create(SubmitBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Element }):Play()
    end)

    -- Get Key Button (1:1 Element Style from lib.luau)
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Name = "GetKey"
    GetKeyBtn.Size = UDim2.new(0.25, -4, 1, 0)
    GetKeyBtn.Position = UDim2.new(0.48, 4, 0, 0)
    GetKeyBtn.BackgroundColor3 = Theme.Element
    GetKeyBtn.Text = "Get Key"
    GetKeyBtn.FontFace = safeFont
    GetKeyBtn.TextSize = 13
    GetKeyBtn.TextColor3 = Theme.Text
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.BorderSizePixel = 0
    GetKeyBtn.Parent = ButtonRow

    applyUICorner(GetKeyBtn, 5)
    applyUIStroke(GetKeyBtn, Theme.Border, 0.4)
    applyUIGradient(GetKeyBtn, Theme.DarkGradient)

    GetKeyBtn.MouseEnter:Connect(function()
        TweenService:Create(GetKeyBtn, TweenInfo.new(0.15), { BackgroundColor3 = getLighterColor(Theme.Element, 1.45) }):Play()
    end)
    GetKeyBtn.MouseLeave:Connect(function()
        TweenService:Create(GetKeyBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Element }):Play()
    end)

    -- Discord Button (1:1 Element Style from lib.luau)
    local DiscordBtn = Instance.new("TextButton")
    DiscordBtn.Name = "Discord"
    DiscordBtn.Size = UDim2.new(0.27, 0, 1, 0)
    DiscordBtn.Position = UDim2.new(0.73, 4, 0, 0)
    DiscordBtn.BackgroundColor3 = Theme.Element
    DiscordBtn.Text = "Discord"
    DiscordBtn.FontFace = safeFont
    DiscordBtn.TextSize = 13
    DiscordBtn.TextColor3 = Theme.Text
    DiscordBtn.AutoButtonColor = false
    DiscordBtn.BorderSizePixel = 0
    DiscordBtn.Parent = ButtonRow

    applyUICorner(DiscordBtn, 5)
    applyUIStroke(DiscordBtn, Theme.Border, 0.4)
    applyUIGradient(DiscordBtn, Theme.DarkGradient)

    DiscordBtn.MouseEnter:Connect(function()
        TweenService:Create(DiscordBtn, TweenInfo.new(0.15), { BackgroundColor3 = getLighterColor(Theme.Element, 1.45) }):Play()
    end)
    DiscordBtn.MouseLeave:Connect(function()
        TweenService:Create(DiscordBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Element }):Play()
    end)

    -- Key Verification Handler
    local verifying = false

    local function handleVerification()
        if verifying then return end

        local entered = string.gsub(KeyTextBox.Text, "^%s*(.-)%s*$", "%1") -- trim whitespace

        if entered == KeySystem.Key then
            verifying = true
            StatusLabel.Text = "Status: Key Verified! Loading..."
            StatusLabel.TextColor3 = Theme.Success

            KeySystem.SaveKey(entered)

            TweenService:Create(SubmitStroke, TweenInfo.new(0.2), { Color = Theme.Success, Transparency = 0 }):Play()

            task.delay(0.5, function()
                local fadeTween = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 480, 0, 0),
                    Position = UDim2.new(0.5, -240, 0.5, 0)
                })
                fadeTween:Play()
                fadeTween.Completed:Wait()

                ScreenGui:Destroy()

                if onVerifiedCallback then
                    onVerifiedCallback()
                end
            end)
        else
            StatusLabel.Text = "Status: Invalid Key! Check key and try again."
            StatusLabel.TextColor3 = Theme.Error
            TweenService:Create(InputStroke, TweenInfo.new(0.2), { Color = Theme.Error, Transparency = 0 }):Play()

            task.delay(1.5, function()
                if not verifying then
                    TweenService:Create(InputStroke, TweenInfo.new(0.2), { Color = Theme.Border, Transparency = 0.4 }):Play()
                end
            end)
        end
    end

    bindButtonClick(SubmitBtn, handleVerification)

    KeyTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            handleVerification()
        end
    end)

    bindButtonClick(GetKeyBtn, function()
        setClipboardContent(KeySystem.GetKeyLink)
        StatusLabel.Text = "Status: Key link copied to clipboard!"
        StatusLabel.TextColor3 = Theme.Accent
    end)

    bindButtonClick(DiscordBtn, function()
        setClipboardContent(KeySystem.DiscordLink)
        StatusLabel.Text = "Status: Discord link copied to clipboard!"
        StatusLabel.TextColor3 = Theme.Accent
    end)
end

-- Main verification entrypoint
function KeySystem.Verify(onSuccess)
    -- Check if saved key is valid
    if not getgenv()._niloForceKeyUI and KeySystem.CheckSavedKey() then
        print("[NiloHook] Valid key found in " .. KeySystem.FileName .. ". Bypassing Key UI.")
        if onSuccess then
            onSuccess()
        end
        return true
    end

    -- If no valid saved key, build & present UI
    KeySystem.CreateUI(onSuccess)
    return false
end

-- If executed directly as a standalone script in executor
if not getgenv()._niloLoadingFromMain then
    task.spawn(function()
        KeySystem.Verify(function()
            print("[NiloHook] Key verification complete!")
        end)
    end)
end

return KeySystem
