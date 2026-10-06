--[[
    Airflow UI Library
    Re-created 1:1 from original design
    Clean, standalone, devirtualized, and runnable
--]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

-- Executor / Environment Compatibility
local function getSafeGuiParent()
    local success, parent = pcall(function()
        if gethui then
            return gethui()
        elseif syn and syn.protect_gui then
            local folder = Instance.new("Folder")
            folder.Name = "Airflow_Container"
            syn.protect_gui(folder)
            folder.Parent = CoreGui
            return folder
        elseif CoreGui then
            return CoreGui
        end
    end)
    if success and parent then
        return parent
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Font Loading with Fallback
local Font_SemiBold
local Font_Regular
local Font_Bold

local fontOk = pcall(function()
    Font_SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold)
    Font_Regular  = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
    Font_Bold     = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold)
end)

if not fontOk or not Font_SemiBold then
    Font_SemiBold = Font.fromEnum(Enum.Font.GothamMedium)
    Font_Regular  = Font.fromEnum(Enum.Font.Gotham)
    Font_Bold     = Font.fromEnum(Enum.Font.GothamBold)
end

-- Lucide Icon Provider (with online direct load + offline icon fallback)
local LucideIcons = nil
pcall(function()
    LucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/lucide-roblox-direct/main/source.lua"))()
end)

local BuiltinIcons = {
    ["house"]           = { Url = "rbxassetid://10723407389", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["home"]            = { Url = "rbxassetid://10723407389", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["crosshair"]       = { Url = "rbxassetid://10734923769", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["eye"]             = { Url = "rbxassetid://10723346959", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["shield"]          = { Url = "rbxassetid://10734975486", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["settings"]        = { Url = "rbxassetid://10734950309", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["palette"]         = { Url = "rbxassetid://10734922324", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["code"]            = { Url = "rbxassetid://10709769841", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["user"]            = { Url = "rbxassetid://10747373176", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["search"]          = { Url = "rbxassetid://10734943674", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["chevron-down"]    = { Url = "rbxassetid://10709790948", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["chevron-up"]      = { Url = "rbxassetid://10709791437", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["minus"]           = { Url = "rbxassetid://10734924724", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["plus"]            = { Url = "rbxassetid://10734941499", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["x"]               = { Url = "rbxassetid://10747384394", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["check"]           = { Url = "rbxassetid://10709790644", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["lock"]            = { Url = "rbxassetid://10723346297", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["lock-open"]       = { Url = "rbxassetid://10723346158", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["sparkles"]        = { Url = "rbxassetid://10734975692", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["bell"]            = { Url = "rbxassetid://10709761530", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["copy"]            = { Url = "rbxassetid://10709791097", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["external-link"]   = { Url = "rbxassetid://10709791174", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["locate-fixed"]     = { Url = "rbxassetid://10734923769", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
    ["globe"]           = { Url = "rbxassetid://10723345518", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero },
}

local function getIconAsset(name)
    if LucideIcons and type(LucideIcons.GetAsset) == "function" then
        local ok, asset = pcall(LucideIcons.GetAsset, name)
        if ok and asset then
            return asset
        end
    end
    if BuiltinIcons[name] then
        return BuiltinIcons[name]
    end
    return {
        Url = "rbxassetid://10723407389", -- fallback house
        ImageRectOffset = Vector2.zero,
        ImageRectSize = Vector2.zero,
    }
end

-- Themes (1:1 from line 6638 of x.lua)
local Themes = {
    Airflow = {
        accent     = Color3.fromRGB(235, 199, 246), -- #EBC7F6
        bg         = Color3.fromRGB(20, 16, 20),     -- #141014
        side       = Color3.fromRGB(31, 25, 31),     -- #1F191F
        sect       = Color3.fromRGB(28, 22, 28),     -- #1C161C
        head       = Color3.fromRGB(24, 19, 24),     -- #181318
        line       = Color3.fromRGB(40, 32, 41),     -- #282029
        elem       = Color3.fromRGB(42, 36, 43),     -- #2A242B
        elem_hover = Color3.fromRGB(52, 44, 53),     -- #342C35
        text       = Color3.fromRGB(233, 229, 234),  -- #E9E5EA
        dim        = Color3.fromRGB(125, 115, 126),  -- #7D737E
        smoke      = Color3.fromRGB(210, 218, 230),  -- #D2DAE6
    },
    Midnight = {
        accent     = Color3.fromRGB(132, 172, 255),
        bg         = Color3.fromRGB(13, 15, 21),
        side       = Color3.fromRGB(20, 23, 32),
        sect       = Color3.fromRGB(18, 21, 29),
        head       = Color3.fromRGB(15, 18, 25),
        line       = Color3.fromRGB(31, 37, 51),
        elem       = Color3.fromRGB(34, 40, 55),
        elem_hover = Color3.fromRGB(45, 53, 72),
        text       = Color3.fromRGB(226, 232, 242),
        dim        = Color3.fromRGB(110, 120, 140),
        smoke      = Color3.fromRGB(198, 214, 242),
    }
}

-- Helpers
local function create(className, properties, parent)
    local instance = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        instance[prop] = val
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function tween(object, duration, properties, easingStyle, easingDir)
    local info = TweenInfo.new(
        duration or 0.2,
        easingStyle or Enum.EasingStyle.Quint,
        easingDir or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(object, info, properties)
    tw:Play()
    return tw
end

-- Multi-layer Glow Icon Renderer (1:1 from fn38 in x.lua)
local function createIcon(parent, iconName, size, position, color)
    local asset = getIconAsset(iconName)
    local container = create("Frame", {
        Name = "IconContainer",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Position = position,
    }, parent)

    -- Ambient radial glow background
    local glow = create("ImageLabel", {
        Name = "AmbientGlow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://8992230677",
        ImageColor3 = color,
        ImageTransparency = 0.9,
        Size = UDim2.fromScale(2, 2),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 0,
    }, container)

    -- Multi-layer anti-aliased icon rendering
    local layers = {}
    local offsets = { { 0, 0 }, { 0.7, 0 }, { -0.7, 0 }, { 0, 0.7 }, { 0, -0.7 } }
    for _, offset in ipairs(offsets) do
        local layer = create("ImageLabel", {
            Name = "IconLayer",
            BackgroundTransparency = 1,
            Image = asset.Url or "",
            ImageRectOffset = asset.ImageRectOffset or Vector2.zero,
            ImageRectSize = asset.ImageRectSize or Vector2.zero,
            ImageColor3 = color,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromOffset(offset[1], offset[2]),
        }, container)

        create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(202, 188, 202)
            ),
        }, layer)

        table.insert(layers, layer)
    end

    local iconObj = {
        Container = container,
        Layers = layers,
        Glow = glow,
    }

    function iconObj:SetColor(newColor, duration)
        if duration and duration > 0 then
            tween(glow, duration, { ImageColor3 = newColor })
            for _, layer in ipairs(layers) do
                tween(layer, duration, { ImageColor3 = newColor })
            end
        else
            glow.ImageColor3 = newColor
            for _, layer in ipairs(layers) do
                layer.ImageColor3 = newColor
            end
        end
    end

    function iconObj:SetIcon(newIconName)
        local newAsset = getIconAsset(newIconName)
        for _, layer in ipairs(layers) do
            layer.Image = newAsset.Url or ""
            layer.ImageRectOffset = newAsset.ImageRectOffset or Vector2.zero
            layer.ImageRectSize = newAsset.ImageRectSize or Vector2.zero
        end
    end

    return iconObj
end

-- Input helper for Mobile vs Desktop
local function getPointerPosition(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        local inset = GuiService:GetGuiInset()
        return Vector2.new(input.Position.X - inset.X, input.Position.Y - inset.Y)
    end
    local mouse = LocalPlayer:GetMouse()
    return Vector2.new(mouse.X, mouse.Y)
end

-- ====================================================================
-- LIBRARY MAIN OBJECT
-- ====================================================================
local Library = {
    Flags = {},
    CurrentTheme = Themes.Airflow,
    Windows = {},
    ActivePopups = {},
    OnThemeChanged = {},
}

function Library:SetTheme(themeData)
    if type(themeData) == "string" then
        themeData = Themes[themeData] or Themes.Airflow
    end
    self.CurrentTheme = themeData
    for _, callback in ipairs(self.OnThemeChanged) do
        pcall(callback, themeData)
    end
end

-- ====================================================================
-- WINDOW CONSTRUCTOR
-- ====================================================================
function Library:Window(options)
    options = options or {}
    local Title = options.Title or "Airflow"
    local Subtitle = options.Subtitle or "Counter-Strike"
    local Description = options.Description or "Universal"
    local ToggleKey = options.Keybind or Enum.KeyCode.RightShift
    local UserNote = options.UserNote or "Premium"
    local ConfigsList = options.Configs or { "default" }

    local theme = self.CurrentTheme

    -- ScreenGui
    local ScreenGui = create("ScreenGui", {
        Name = "Airflow_UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        IgnoreGuiInset = true,
        Parent = getSafeGuiParent(),
    })

    -- Dismiss Overlay for Popups (Dropdowns, ColorPickers)
    local DismissOverlay = create("TextButton", {
        Name = "DismissOverlay",
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 40,
        Visible = false,
        Parent = ScreenGui,
    })

    local activePopup = nil
    local function closeActivePopup()
        if not activePopup then return end
        local pop = activePopup
        activePopup = nil
        DismissOverlay.Visible = false

        local scale = pop:FindFirstChildOfClass("UIScale")
        if scale then
            tween(scale, 0.12, { Scale = 0.94 }, Enum.EasingStyle.Quad)
        end
        if pop:IsA("CanvasGroup") then
            tween(pop, 0.14, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
        end
        task.delay(0.14, function()
            if activePopup ~= pop then
                pop.Visible = false
            end
        end)
    end

    DismissOverlay.MouseButton1Click:Connect(closeActivePopup)

    local function openPopup(popupInstance, absX, absY)
        closeActivePopup()
        local screenSize = ScreenGui.AbsoluteSize
        local popupW = popupInstance.Size.X.Offset
        local popupH = popupInstance.Size.Y.Offset

        local posX = math.clamp(absX, 8, math.max(8, screenSize.X - popupW - 8))
        local posY = math.clamp(absY, 8, math.max(8, screenSize.Y - popupH - 8))

        popupInstance.Position = UDim2.fromOffset(posX, posY)
        popupInstance.Visible = true

        local scale = popupInstance:FindFirstChildOfClass("UIScale")
        if scale then
            scale.Scale = 0.94
            tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
        end
        if popupInstance:IsA("CanvasGroup") then
            popupInstance.GroupTransparency = 1
            tween(popupInstance, 0.16, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
        end

        activePopup = popupInstance
        DismissOverlay.Visible = true
    end

    -- Main Window Outer Frame (705 x 602 px)
    local WindowFrame = create("Frame", {
        Name = "MainWindow",
        Size = UDim2.fromOffset(705, 602),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = ScreenGui,
    })

    local WindowUIScale = create("UIScale", {
        Scale = 0.9,
        Parent = WindowFrame,
    })

    -- Responsive Scaling
    local function updateResponsiveScale()
        local cam = workspace.CurrentCamera
        local viewport = cam and cam.ViewportSize or Vector2.new(1280, 720)
        if viewport.X < 8 or viewport.Y < 8 then
            viewport = Vector2.new(1280, 720)
        end
        local margin = viewport.X < 900 and 24 or 48
        local scaleFactor = math.min(1, math.min((viewport.X - margin) / 705, (viewport.Y - margin) / 602))
        WindowUIScale.Scale = math.max(0.65, scaleFactor * 0.9)
    end
    updateResponsiveScale()

    -- Drop Shadow (50px expansion, soft blur)
    local DropShadow = create("ImageLabel", {
        Name = "DropShadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 50, 1, 50),
        Position = UDim2.fromOffset(-25, -25),
        ZIndex = 0,
        Parent = WindowFrame,
    })

    -- Container CanvasGroup (Rounds all children flawlessly)
    local Container = create("CanvasGroup", {
        Name = "Container",
        BackgroundColor3 = theme.bg,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = WindowFrame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Container })
    create("UIStroke", { Thickness = 1, Color = theme.line, Parent = Container })

    -- ================================================================
    -- SIDEBAR (108 px width)
    -- ================================================================
    local Sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.side,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 108, 1, 0),
        Parent = Container,
    })

    -- Vertical Divider Line
    create("Frame", {
        Name = "SidebarDivider",
        BackgroundColor3 = theme.line,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.fromOffset(107, 0),
        Parent = Sidebar,
    })

    -- Top Brand Logo / Glow
    local BrandGlow = create("ImageLabel", {
        Name = "BrandGlow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://8992230677",
        ImageColor3 = theme.accent,
        ImageTransparency = 0.88,
        Size = UDim2.fromOffset(56, 50),
        Position = UDim2.fromOffset(26, 16),
        Parent = Sidebar,
    })
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 182, 202)),
        Parent = BrandGlow,
    })

    local LogoIcon = create("ImageLabel", {
        Name = "LogoIcon",
        BackgroundTransparency = 1,
        Image = "rbxassetid://10734975692", -- Sparkles / Brand mark
        ImageColor3 = theme.accent,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(40, 26),
        Parent = Sidebar,
    })

    -- Tab Button Scroll / Container
    local TabButtonContainer = create("Frame", {
        Name = "TabButtons",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -(78 + 96)),
        Position = UDim2.fromOffset(0, 78),
        Parent = Sidebar,
    })
    local TabListLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = TabButtonContainer,
    })

    -- User Profile Footer (96px height)
    local ProfileFooter = create("Frame", {
        Name = "ProfileFooter",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 96),
        Position = UDim2.new(0, 0, 1, -96),
        Parent = Sidebar,
    })
    create("Frame", {
        Name = "ProfileDivider",
        BackgroundColor3 = theme.line,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.fromOffset(14, 0),
        Parent = ProfileFooter,
    })

    -- Avatar Circle (38 x 38 px)
    local AvatarImage = create("ImageLabel", {
        Name = "Avatar",
        BackgroundColor3 = theme.head,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.new(0.5, -19, 0, 16),
        Parent = ProfileFooter,
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = AvatarImage })
    local AvatarStroke = create("UIStroke", {
        Thickness = 1,
        Color = theme.accent,
        Transparency = 0.35,
        Parent = AvatarImage,
    })

    task.spawn(function()
        pcall(function()
            local thumb = Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
            AvatarImage.Image = thumb
        end)
    end)

    local UsernameLabel = create("TextLabel", {
        Name = "Username",
        BackgroundTransparency = 1,
        FontFace = Font_SemiBold,
        Text = LocalPlayer.DisplayName or "User",
        TextColor3 = theme.text,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(1, -10, 0, 14),
        Position = UDim2.fromOffset(5, 59),
        Parent = ProfileFooter,
    })

    local StatusBadgeLabel = create("TextLabel", {
        Name = "StatusBadge",
        BackgroundTransparency = 1,
        FontFace = Font_SemiBold,
        Text = UserNote,
        TextColor3 = theme.dim,
        TextSize = 11,
        Size = UDim2.new(1, -10, 0, 13),
        Position = UDim2.fromOffset(5, 74),
        Parent = ProfileFooter,
    })

    -- ================================================================
    -- MAIN CONTENT AREA (Offset 108px from left)
    -- ================================================================
    local ContentArea = create("Frame", {
        Name = "ContentArea",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -108, 1, 0),
        Position = UDim2.fromOffset(108, 0),
        Parent = Container,
    })

    -- Top Header Bar (Height 56px)
    local TopHeader = create("Frame", {
        Name = "TopHeader",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 56),
        Position = UDim2.fromOffset(0, 0),
        Parent = ContentArea,
    })

    local HeaderIcon = createIcon(TopHeader, "sparkles", 24, UDim2.fromOffset(16, 16), theme.accent)

    local HeaderTitle = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Font_SemiBold,
        Text = Title,
        TextColor3 = theme.text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 320, 0, 16),
        Position = UDim2.fromOffset(48, 14),
        Parent = TopHeader,
    })

    local HeaderSubtitle = create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        FontFace = Font_SemiBold,
        Text = Subtitle,
        TextColor3 = theme.dim,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 320, 0, 14),
        Position = UDim2.fromOffset(48, 32),
        Parent = TopHeader,
    })

    -- Header Controls (Close & Minimize)
    local CloseButton = create("TextButton", {
        Name = "CloseButton",
        BackgroundColor3 = theme.elem,
        BackgroundTransparency = 0.5,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, -38, 0, 15),
        Parent = TopHeader,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseButton })
    create("UIStroke", { Thickness = 1, Color = theme.line, Parent = CloseButton })
    createIcon(CloseButton, "x", 14, UDim2.fromOffset(6, 6), theme.dim)

    CloseButton.MouseEnter:Connect(function()
        tween(CloseButton, 0.15, { BackgroundColor3 = Color3.fromRGB(180, 50, 50), BackgroundTransparency = 0 })
    end)
    CloseButton.MouseLeave:Connect(function()
        tween(CloseButton, 0.15, { BackgroundColor3 = theme.elem, BackgroundTransparency = 0.5 })
    end)
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Header Animated Transition (1:1 from fn51 in x.lua)
    local headerTransitionIndex = 0
    local function updateHeader(newTitle, newSub, newIconName)
        headerTransitionIndex += 1
        local currentIndex = headerTransitionIndex
        local titleY = (newSub == nil or newSub == "") and 21 or 14

        -- Slide left & fade out
        tween(HeaderTitle, 0.12, { TextTransparency = 1, Position = UDim2.fromOffset(40, titleY) }, Enum.EasingStyle.Quad)
        tween(HeaderSubtitle, 0.12, { TextTransparency = 1, Position = UDim2.fromOffset(40, 32) }, Enum.EasingStyle.Quad)
        tween(HeaderIcon.Container, 0.12, { Position = UDim2.fromOffset(10, 16) }, Enum.EasingStyle.Quad)

        task.delay(0.14, function()
            if headerTransitionIndex ~= currentIndex then return end
            HeaderTitle.Text = newTitle
            HeaderSubtitle.Text = newSub or ""
            HeaderIcon:SetIcon(newIconName or "sparkles")
            HeaderIcon:SetColor(theme.accent)

            HeaderTitle.Position = UDim2.fromOffset(54, titleY)
            HeaderSubtitle.Position = UDim2.fromOffset(54, 32)
            HeaderIcon.Container.Position = UDim2.fromOffset(20, 16)

            -- Slide back from right & fade in
            tween(HeaderTitle, 0.18, { TextTransparency = 0, Position = UDim2.fromOffset(48, titleY) })
            tween(HeaderSubtitle, 0.18, { TextTransparency = 0, Position = UDim2.fromOffset(48, 32) })
            tween(HeaderIcon.Container, 0.18, { Position = UDim2.fromOffset(16, 16) })
        end)
    end

    -- Tab Pages Container (Offset 56px from top)
    local PagesHolder = create("Frame", {
        Name = "PagesHolder",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -56),
        Position = UDim2.fromOffset(0, 56),
        ClipsDescendants = true,
        Parent = ContentArea,
    })

    -- ================================================================
    -- DRAGGING MECHANISM (Exponential Lerp physics 1:1)
    -- ================================================================
    local isDragging = false
    local dragStartPos = nil
    local dragStartFramePos = nil
    local targetPosition = WindowFrame.Position

    local DragHandleTop = create("TextButton", {
        Name = "DragHandleTop",
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(1, -108, 0, 56),
        Position = UDim2.fromOffset(108, 0),
        ZIndex = 5,
        Parent = Container,
    })

    local DragHandleSide = create("TextButton", {
        Name = "DragHandleSide",
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(107, 78),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 5,
        Parent = Container,
    })

    local function setupDragHandle(handle)
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                closeActivePopup()
                isDragging = true
                dragStartPos = getPointerPosition(input)
                dragStartFramePos = WindowFrame.Position
                targetPosition = dragStartFramePos

                while isDragging and (input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change) do
                    local cur = getPointerPosition(input)
                    local delta = cur - dragStartPos
                    targetPosition = UDim2.new(
                        dragStartFramePos.X.Scale,
                        dragStartFramePos.X.Offset + delta.X,
                        dragStartFramePos.Y.Scale,
                        dragStartFramePos.Y.Offset + delta.Y
                    )
                    RunService.RenderStepped:Wait()
                end
                isDragging = false
            end
        end)
    end

    setupDragHandle(DragHandleTop)
    setupDragHandle(DragHandleSide)

    -- Buttery smooth lerp update loop
    RunService.RenderStepped:Connect(function(dt)
        if targetPosition then
            WindowFrame.Position = WindowFrame.Position:Lerp(targetPosition, 1 - math.exp(-34 * dt))
        end
    end)

    -- ================================================================
    -- VISIBILITY TOGGLE (Keybind & Mobile button)
    -- ================================================================
    local isGuiOpen = true
    local function setGuiVisible(visible)
        isGuiOpen = visible
        closeActivePopup()
        if visible then
            ScreenGui.Enabled = true
            WindowUIScale.Scale = 0.85
            tween(WindowUIScale, 0.32, { Scale = 0.9 }, Enum.EasingStyle.Back)
            tween(Container, 0.22, { GroupTransparency = 0 })
            tween(DropShadow, 0.25, { ImageTransparency = 0.6 })
        else
            tween(WindowUIScale, 0.18, { Scale = 0.85 }, Enum.EasingStyle.Quad)
            tween(Container, 0.18, { GroupTransparency = 1 })
            tween(DropShadow, 0.18, { ImageTransparency = 1 })
            task.delay(0.19, function()
                if not isGuiOpen then
                    ScreenGui.Enabled = false
                end
            end)
        end
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == ToggleKey then
            setGuiVisible(not isGuiOpen)
        end
    end)

    -- Mobile floating button if TouchEnabled
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        local MobileGui = create("ScreenGui", {
            Name = "Airflow_MobileToggle",
            ResetOnSpawn = false,
            DisplayOrder = 1000,
            Parent = getSafeGuiParent(),
        })

        local MobileBtn = create("TextButton", {
            Name = "FloatingToggle",
            BackgroundColor3 = theme.sect,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.fromOffset(44, 44),
            Position = UDim2.fromOffset(14, 72),
            ZIndex = 50,
            Parent = MobileGui,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MobileBtn })
        create("UIStroke", { Thickness = 1, Color = theme.line, Parent = MobileBtn })
        createIcon(MobileBtn, "sparkles", 22, UDim2.fromOffset(11, 11), theme.accent)

        MobileBtn.MouseButton1Click:Connect(function()
            setGuiVisible(not isGuiOpen)
        end)
    end

    -- ================================================================
    -- TAB SYSTEM
    -- ================================================================
    local WindowObj = {
        Tabs = {},
        ActiveTab = nil,
        Instance = ScreenGui,
    }

    function WindowObj:Tab(tabOptions)
        tabOptions = tabOptions or {}
        local TabName = tabOptions.Name or "Tab"
        local TabIconName = tabOptions.Icon or "house"
        local TabHeaderTitle = tabOptions.Title or TabName
        local TabHeaderDesc = tabOptions.Description or tabOptions.Subtitle or ""

        -- Tab Button in Sidebar (76 x 76 px, centered)
        local TabButton = create("TextButton", {
            Name = "Tab_" .. TabName,
            BackgroundColor3 = theme.elem,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.fromOffset(76, 76),
            Parent = TabButtonContainer,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = TabButton })
        local TabStroke = create("UIStroke", {
            Thickness = 1,
            Color = theme.line,
            Transparency = 1,
            Parent = TabButton,
        })

        local TabIcon = createIcon(TabButton, TabIconName, 26, UDim2.new(0.5, -13, 0, 14), theme.dim)

        local TabLabel = create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            FontFace = Font_SemiBold,
            Text = TabName,
            TextColor3 = theme.dim,
            TextSize = 13,
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.fromOffset(0, 50),
            Parent = TabButton,
        })

        -- Tab Page Container (CanvasGroup with 2 columns)
        local TabPage = create("CanvasGroup", {
            Name = "Page_" .. TabName,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            Parent = PagesHolder,
        })

        local PageScroll = create("ScrollingFrame", {
            Name = "ScrollContent",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.line,
            ClipsDescendants = false,
            Parent = TabPage,
        })

        -- 2 Column Layout (Left: 275px, Right: 275px, 14px gap)
        local LeftColumn = create("Frame", {
            Name = "LeftColumn",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 275, 1, 0),
            Position = UDim2.fromOffset(16, 12),
            Parent = PageScroll,
        })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 12),
            Parent = LeftColumn,
        })

        local RightColumn = create("Frame", {
            Name = "RightColumn",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 275, 1, 0),
            Position = UDim2.fromOffset(305, 12),
            Parent = PageScroll,
        })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 12),
            Parent = RightColumn,
        })

        -- Dynamic scroll height recalculation
        local function updateCanvasSize()
            local leftH = 0
            for _, child in ipairs(LeftColumn:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then
                    leftH = leftH + child.Size.Y.Offset + 12
                end
            end
            local rightH = 0
            for _, child in ipairs(RightColumn:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then
                    rightH = rightH + child.Size.Y.Offset + 12
                end
            end
            local maxH = math.max(leftH, rightH) + 32
            PageScroll.CanvasSize = UDim2.fromOffset(0, maxH)
        end

        LeftColumn.ChildAdded:Connect(function() task.defer(updateCanvasSize) end)
        LeftColumn.ChildRemoved:Connect(function() task.defer(updateCanvasSize) end)
        RightColumn.ChildAdded:Connect(function() task.defer(updateCanvasSize) end)
        RightColumn.ChildRemoved:Connect(function() task.defer(updateCanvasSize) end)

        local TabObj = {
            Name = TabName,
            Page = TabPage,
            LeftColumn = LeftColumn,
            RightColumn = RightColumn,
            UpdateCanvas = updateCanvasSize,
        }

        local function activateTab()
            if WindowObj.ActiveTab == TabObj then return end
            closeActivePopup()

            local prev = WindowObj.ActiveTab
            WindowObj.ActiveTab = TabObj

            -- Fade out previous tab
            if prev then
                tween(prev.Button, 0.2, { BackgroundTransparency = 1 })
                tween(prev.Stroke, 0.2, { Transparency = 1 })
                prev.Icon:SetColor(theme.dim, 0.2)
                tween(prev.Label, 0.2, { TextColor3 = theme.dim })
                prev.Page.Visible = false
            end

            -- Activate this tab
            tween(TabButton, 0.2, { BackgroundTransparency = 0 })
            tween(TabStroke, 0.2, { Transparency = 0 })
            TabIcon:SetColor(theme.accent, 0.2)
            tween(TabLabel, 0.2, { TextColor3 = theme.text })

            TabPage.Visible = true
            TabPage.GroupTransparency = 1
            TabPage.Position = UDim2.fromOffset(0, 10)
            tween(TabPage, 0.28, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })

            updateHeader(TabHeaderTitle, TabHeaderDesc, TabIconName)
            updateCanvasSize()
        end

        TabObj.Button = TabButton
        TabObj.Stroke = TabStroke
        TabObj.Icon = TabIcon
        TabObj.Label = TabLabel
        TabObj.Activate = activateTab

        TabButton.MouseEnter:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                tween(TabButton, 0.15, { BackgroundTransparency = 0.75 })
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                tween(TabButton, 0.15, { BackgroundTransparency = 1 })
            end
        end)
        TabButton.MouseButton1Click:Connect(activateTab)

        -- ============================================================
        -- SECTION SYSTEM (Cards in 2-column layout)
        -- ============================================================
        function TabObj:Section(secOptions)
            secOptions = secOptions or {}
            local SecName = secOptions.Name or "Section"
            local SecSide = (secOptions.Side or "Left"):lower()
            local SecIconName = secOptions.Icon

            local colParent = (SecSide == "right") and RightColumn or LeftColumn

            -- Section Card Box (Width 275px)
            local CardBox = create("Frame", {
                Name = "Card_" .. SecName,
                BackgroundColor3 = theme.sect,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(275, 51),
                Parent = colParent,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = CardBox })
            local CardStroke = create("UIStroke", { Thickness = 1, Color = theme.line, Parent = CardBox })

            -- Header (Height 34px)
            local CardHeader = create("Frame", {
                Name = "Header",
                BackgroundColor3 = theme.head,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 34),
                Parent = CardBox,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = CardHeader })

            -- Squared bottom corners for header
            create("Frame", {
                Name = "HeaderBottomFiller",
                BackgroundColor3 = theme.head,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 1, -6),
                Parent = CardHeader,
            })

            -- Header Divider line
            create("Frame", {
                Name = "HeaderDivider",
                BackgroundColor3 = theme.line,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.fromOffset(0, 34),
                Parent = CardBox,
            })

            -- Title Label
            local CardTitleLabel = create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                FontFace = Font_SemiBold,
                Text = SecName,
                TextColor3 = theme.text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -60, 0, 34),
                Position = UDim2.fromOffset(12, 0),
                Parent = CardHeader,
            })

            -- Optional Section Icon
            if SecIconName then
                createIcon(CardHeader, SecIconName, 16, UDim2.new(1, -26, 0, 9), theme.accent)
            end

            -- Collapse / Expand Button
            local isCollapsed = false
            local CollapseBtn = create("TextButton", {
                Name = "CollapseBtn",
                BackgroundColor3 = theme.accent,
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.new(1, -30, 0, 7),
                Parent = CardHeader,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = CollapseBtn })
            local CollapseIcon = createIcon(CollapseBtn, "minus", 14, UDim2.fromOffset(3, 3), theme.accent)

            -- Elements Container
            local ElementsContainer = create("Frame", {
                Name = "Elements",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, -35),
                Position = UDim2.fromOffset(0, 35),
                ClipsDescendants = true,
                Parent = CardBox,
            })
            create("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                Parent = ElementsContainer,
            })
            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 6),
                Parent = ElementsContainer,
            })

            -- Dynamic Height Fitting (1:1 from fit() in x.lua)
            local function fitCard()
                local totalH = 34 + 16 -- Header + vertical padding
                local visibleCount = 0
                for _, el in ipairs(ElementsContainer:GetChildren()) do
                    if el:IsA("GuiObject") and el.Visible then
                        totalH = totalH + el.Size.Y.Offset
                        visibleCount = visibleCount + 1
                    end
                end
                if visibleCount > 1 then
                    totalH = totalH + (visibleCount - 1) * 6
                end

                if isCollapsed then
                    CardBox.Size = UDim2.fromOffset(275, 34)
                else
                    CardBox.Size = UDim2.fromOffset(275, totalH)
                end
                updateCanvasSize()
            end

            CollapseBtn.MouseButton1Click:Connect(function()
                isCollapsed = not isCollapsed
                CollapseIcon:SetIcon(isCollapsed and "plus" or "minus")
                ElementsContainer.Visible = not isCollapsed
                if isCollapsed then
                    tween(CardBox, 0.2, { Size = UDim2.fromOffset(275, 34) })
                else
                    fitCard()
                end
                task.delay(0.22, updateCanvasSize)
            end)

            ElementsContainer.ChildAdded:Connect(function() task.defer(fitCard) end)
            ElementsContainer.ChildRemoved:Connect(function() task.defer(fitCard) end)

            local SecObj = {
                Card = CardBox,
                Container = ElementsContainer,
                Fit = fitCard,
            }

            -- ========================================================
            -- UI ELEMENT: TOGGLE (34x18 pill switch with back-easing)
            -- ========================================================
            function SecObj:Toggle(toggleOpts)
                toggleOpts = toggleOpts or {}
                local Name = toggleOpts.Name or "Toggle"
                local Flag = toggleOpts.Flag
                local State = toggleOpts.Default or false
                local Callback = toggleOpts.Callback or function() end

                local Row = create("Frame", {
                    Name = "Row_Toggle_" .. Name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    Parent = ElementsContainer,
                })

                local Label = create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    FontFace = Font_SemiBold,
                    Text = Name,
                    TextColor3 = theme.text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Size = UDim2.new(1, -44, 1, 0),
                    Position = UDim2.fromOffset(0, 0),
                    Parent = Row,
                })

                -- Pill Switch (34 x 18 px)
                local Switch = create("TextButton", {
                    Name = "Switch",
                    BackgroundColor3 = State and theme.accent or theme.line,
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.fromOffset(34, 18),
                    Position = UDim2.new(1, -34, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = Row,
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Switch })

                -- Switch Knob (14 x 14 px)
                local Knob = create("Frame", {
                    Name = "Knob",
                    BackgroundColor3 = Color3.fromRGB(242, 238, 243),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.fromOffset(State and 18 or 2, 2),
                    Parent = Switch,
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })

                local function setToggleState(val, skipCallback)
                    State = val
                    if Flag then
                        Library.Flags[Flag] = State
                    end
                    tween(Switch, 0.2, { BackgroundColor3 = State and theme.accent or theme.line })
                    tween(Knob, 0.22, { Position = UDim2.fromOffset(State and 18 or 2, 2) }, Enum.EasingStyle.Back)
                    if not skipCallback then
                        pcall(Callback, State)
                    end
                end

                Switch.MouseButton1Click:Connect(function()
                    setToggleState(not State)
                end)

                if Flag then
                    Library.Flags[Flag] = State
                end

                return {
                    Set = setToggleState,
                    Get = function() return State end,
                }
            end

            -- ========================================================
            -- UI ELEMENT: SLIDER (Track + fill + value box + dragging)
            -- ========================================================
            function SecObj:Slider(sliderOpts)
                sliderOpts = sliderOpts or {}
                local Name = sliderOpts.Name or "Slider"
                local Flag = sliderOpts.Flag
                local Min = sliderOpts.Min or 0
                local Max = sliderOpts.Max or 100
                local Suffix = sliderOpts.Suffix or ""
                local Decimals = sliderOpts.Decimals or 0
                local Value = math.clamp(sliderOpts.Default or Min, Min, Max)
                local Callback = sliderOpts.Callback or function() end

                local Row = create("Frame", {
                    Name = "Row_Slider_" .. Name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ElementsContainer,
                })

                local TitleLabel = create("TextLabel", {
                    Name = "Title",
                    BackgroundTransparency = 1,
                    FontFace = Font_SemiBold,
                    Text = Name,
                    TextColor3 = theme.text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -60, 0, 16),
                    Position = UDim2.fromOffset(0, 0),
                    Parent = Row,
                })

                -- Value Display Box (52 x 18 px)
                local ValueBox = create("Frame", {
                    Name = "ValueBox",
                    BackgroundColor3 = theme.head,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(52, 18),
                    Position = UDim2.new(1, -52, 0, 0),
                    Parent = Row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ValueBox })
                create("UIStroke", { Thickness = 1, Color = theme.line, Parent = ValueBox })

                local ValueLabel = create("TextLabel", {
                    Name = "Value",
                    BackgroundTransparency = 1,
                    FontFace = Font_SemiBold,
                    Text = string.format("%." .. Decimals .. "f", Value) .. Suffix,
                    TextColor3 = theme.text,
                    TextSize = 11,
                    Size = UDim2.fromScale(1, 1),
                    Parent = ValueBox,
                })

                -- Slider Track (Height 6px)
                local Track = create("TextButton", {
                    Name = "Track",
                    BackgroundColor3 = theme.head,
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.fromOffset(0, 24),
                    Parent = Row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Track })
                create("UIStroke", { Thickness = 1, Color = theme.line, Parent = Track })

                local fillPct = (Max > Min) and math.clamp((Value - Min) / (Max - Min), 0, 1) or 0
                local Fill = create("Frame", {
                    Name = "Fill",
                    BackgroundColor3 = theme.accent,
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(fillPct, 1),
                    Parent = Track,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Fill })

                local function setSliderValue(val, skipCallback)
                    Value = math.clamp(val, Min, Max)
                    if Decimals == 0 then
                        Value = math.round(Value)
                    else
                        local p = 10 ^ Decimals
                        Value = math.round(Value * p) / p
                    end
                    if Flag then
                        Library.Flags[Flag] = Value
                    end
                    local pct = (Max > Min) and math.clamp((Value - Min) / (Max - Min), 0, 1) or 0
                    tween(Fill, 0.08, { Size = UDim2.fromScale(pct, 1) }, Enum.EasingStyle.Quad)
                    ValueLabel.Text = string.format("%." .. Decimals .. "f", Value) .. Suffix
                    if not skipCallback then
                        pcall(Callback, Value)
                    end
                end

                local isDraggingSlider = false
                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingSlider = true
                        while isDraggingSlider and (input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change) do
                            local pointer = getPointerPosition(input)
                            local trackX = Track.AbsolutePosition.X
                            local trackW = Track.AbsoluteSize.X
                            local rel = math.clamp((pointer.X - trackX) / trackW, 0, 1)
                            setSliderValue(Min + rel * (Max - Min))
                            RunService.RenderStepped:Wait()
                        end
                        isDraggingSlider = false
                    end
                end)

                if Flag then
                    Library.Flags[Flag] = Value
                end

                return {
                    Set = setSliderValue,
                    Get = function() return Value end,
                }
            end

            -- ========================================================
            -- UI ELEMENT: DROPDOWN (Single / Multi-select with Search)
            -- ========================================================
            function SecObj:Dropdown(dropOpts)
                dropOpts = dropOpts or {}
                local Name = dropOpts.Name or "Dropdown"
                local Flag = dropOpts.Flag
                local Options = dropOpts.Options or {}
                local Multi = dropOpts.Multi or false
                local Callback = dropOpts.Callback or function() end

                local Selected = Multi and {} or (dropOpts.Default or Options[1] or "")
                if Multi and type(dropOpts.Default) == "table" then
                    for _, v in ipairs(dropOpts.Default) do
                        Selected[v] = true
                    end
                end

                local Row = create("Frame", {
                    Name = "Row_Dropdown_" .. Name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 48),
                    Parent = ElementsContainer,
                })

                local Label = create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    FontFace = Font_SemiBold,
                    Text = Name,
                    TextColor3 = theme.text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 16),
                    Position = UDim2.fromOffset(0, 0),
                    Parent = Row,
                })

                local DropBtn = create("TextButton", {
                    Name = "DropButton",
                    BackgroundColor3 = theme.head,
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.fromOffset(0, 20),
                    Parent = Row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = DropBtn })
                local DropStroke = create("UIStroke", { Thickness = 1, Color = theme.line, Parent = DropBtn })

                local SelectionLabel = create("TextLabel", {
                    Name = "SelectionText",
                    BackgroundTransparency = 1,
                    FontFace = Font_SemiBold,
                    Text = "",
                    TextColor3 = theme.text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.fromOffset(8, 0),
                    Parent = DropBtn,
                })

                local Chevron = createIcon(DropBtn, "chevron-down", 14, UDim2.new(1, -18, 0.5, -7), theme.dim)

                local function getDisplayText()
                    if Multi then
                        local list = {}
                        for opt, val in pairs(Selected) do
                            if val then table.insert(list, opt) end
                        end
                        if #list == 0 then return "None" end
                        return table.concat(list, ", ")
                    else
                        return tostring(Selected)
                    end
                end

                local function updateDisplay()
                    SelectionLabel.Text = getDisplayText()
                end
                updateDisplay()

                -- Dropdown Popup Menu (Floating CanvasGroup)
                local PopupFrame = create("CanvasGroup", {
                    Name = "DropdownPopup_" .. Name,
                    BackgroundColor3 = theme.sect,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(250, 160),
                    Visible = false,
                    ZIndex = 50,
                    Parent = ScreenGui,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = PopupFrame })
                create("UIStroke", { Thickness = 1, Color = theme.line, Parent = PopupFrame })
                create("UIScale", { Scale = 1, Parent = PopupFrame })

                -- Search Bar in Dropdown
                local SearchBox = create("TextBox", {
                    Name = "SearchBox",
                    BackgroundColor3 = theme.head,
                    FontFace = Font_Regular,
                    PlaceholderText = "Search...",
                    PlaceholderColor3 = theme.dim,
                    Text = "",
                    TextColor3 = theme.text,
                    TextSize = 11,
                    Size = UDim2.new(1, -16, 0, 22),
                    Position = UDim2.fromOffset(8, 8),
                    Parent = PopupFrame,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
                create("UIStroke", { Thickness = 1, Color = theme.line, Parent = SearchBox })

                local OptionScroll = create("ScrollingFrame", {
                    Name = "OptionList",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -8, 1, -40),
                    Position = UDim2.fromOffset(4, 36),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = theme.line,
                    Parent = PopupFrame,
                })
                local OptionLayout = create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDim.new(0, 2),
                    Parent = OptionScroll,
                })

                local function refreshOptionsList(filter)
                    filter = (filter or ""):lower()
                    for _, child in ipairs(OptionScroll:GetChildren()) do
                        if child:IsA("GuiObject") then child:Destroy() end
                    end

                    local count = 0
                    for _, opt in ipairs(Options) do
                        if filter == "" or tostring(opt):lower():find(filter, 1, true) then
                            count = count + 1
                            local isSelected = Multi and Selected[opt] or (Selected == opt)

                            local ItemBtn = create("TextButton", {
                                Name = "Item_" .. tostring(opt),
                                BackgroundColor3 = isSelected and theme.elem or theme.sect,
                                BackgroundTransparency = isSelected and 0 or 1,
                                AutoButtonColor = false,
                                Text = "",
                                Size = UDim2.new(1, -6, 0, 22),
                                Parent = OptionScroll,
                            })
                            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ItemBtn })

                            local ItemText = create("TextLabel", {
                                Name = "Text",
                                BackgroundTransparency = 1,
                                FontFace = Font_SemiBold,
                                Text = tostring(opt),
                                TextColor3 = isSelected and theme.accent or theme.text,
                                TextSize = 11,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Size = UDim2.new(1, -24, 1, 0),
                                Position = UDim2.fromOffset(8, 0),
                                Parent = ItemBtn,
                            })

                            if isSelected then
                                createIcon(ItemBtn, "check", 12, UDim2.new(1, -16, 0.5, -6), theme.accent)
                            end

                            ItemBtn.MouseEnter:Connect(function()
                                tween(ItemBtn, 0.12, { BackgroundColor3 = theme.elem_hover, BackgroundTransparency = 0 })
                            end)
                            ItemBtn.MouseLeave:Connect(function()
                                local sel = Multi and Selected[opt] or (Selected == opt)
                                tween(ItemBtn, 0.12, {
                                    BackgroundColor3 = sel and theme.elem or theme.sect,
                                    BackgroundTransparency = sel and 0 or 1,
                                })
                            end)

                            ItemBtn.MouseButton1Click:Connect(function()
                                if Multi then
                                    Selected[opt] = not Selected[opt]
                                    if Flag then Library.Flags[Flag] = Selected end
                                    updateDisplay()
                                    refreshOptionsList(SearchBox.Text)
                                    pcall(Callback, Selected)
                                else
                                    Selected = opt
                                    if Flag then Library.Flags[Flag] = Selected end
                                    updateDisplay()
                                    closeActivePopup()
                                    pcall(Callback, Selected)
                                end
                            end)
                        end
                    end
                    OptionScroll.CanvasSize = UDim2.fromOffset(0, count * 24)
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    refreshOptionsList(SearchBox.Text)
                end)

                DropBtn.MouseButton1Click:Connect(function()
                    if activePopup == PopupFrame then
                        closeActivePopup()
                    else
                        refreshOptionsList("")
                        SearchBox.Text = ""
                        local absPos = DropBtn.AbsolutePosition
                        openPopup(PopupFrame, absPos.X, absPos.Y + DropBtn.AbsoluteSize.Y + 4)
                    end
                end)

                if Flag then
                    Library.Flags[Flag] = Selected
                end

                return {
                    Set = function(newVal)
                        if Multi and type(newVal) == "table" then
                            Selected = newVal
                        else
                            Selected = newVal
                        end
                        if Flag then Library.Flags[Flag] = Selected end
                        updateDisplay()
                        pcall(Callback, Selected)
                    end,
                    Get = function() return Selected end,
                    Refresh = function(newOptions)
                        Options = newOptions or {}
                        refreshOptionsList("")
                    end,
                }
            end

            -- ========================================================
            -- UI ELEMENT: COLORPICKER (2D HSV Palette + Hue bar + Hex)
            -- ========================================================
            function SecObj:ColorPicker(colorOpts)
                colorOpts = colorOpts or {}
                local Name = colorOpts.Name or "Color"
                local Flag = colorOpts.Flag
                local Color = colorOpts.Default or theme.accent
                local Callback = colorOpts.Callback or function() end

                local Row = create("Frame", {
                    Name = "Row_Color_" .. Name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    Parent = ElementsContainer,
                })

                local Label = create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    FontFace = Font_SemiBold,
                    Text = Name,
                    TextColor3 = theme.text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.fromOffset(0, 0),
                    Parent = Row,
                })

                -- Swatch Button (30 x 16 px)
                local Swatch = create("TextButton", {
                    Name = "Swatch",
                    BackgroundColor3 = Color,
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.fromOffset(30, 16),
                    Position = UDim2.new(1, -30, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = Row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Swatch })
                create("UIStroke", { Thickness = 1, Color = theme.line, Parent = Swatch })

                -- ColorPicker Popup Window (220 x 180 px)
                local ColorPopup = create("CanvasGroup", {
                    Name = "ColorPopup_" .. Name,
                    BackgroundColor3 = theme.sect,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(220, 180),
                    Visible = false,
                    ZIndex = 50,
                    Parent = ScreenGui,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ColorPopup })
                create("UIStroke", { Thickness = 1, Color = theme.line, Parent = ColorPopup })
                create("UIScale", { Scale = 1, Parent = ColorPopup })

                local curH, curS, curV = Color:ToHSV()

                -- Saturation / Value 2D Box (200 x 100 px)
                local SVBox = create("TextButton", {
                    Name = "SVBox",
                    BackgroundColor3 = Color3.fromHSV(curH, 1, 1),
                    AutoButtonColor = false,
                    Text = "",
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(200, 100),
                    Position = UDim2.fromOffset(10, 10),
                    Parent = ColorPopup,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = SVBox })

                -- Horizontal white-to-transparent gradient
                local WhiteGrad = create("Frame", {
                    Name = "WhiteGrad",
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = SVBox,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = WhiteGrad })
                create("UIGradient", {
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    Parent = WhiteGrad,
                })

                -- Vertical black-to-transparent gradient
                local BlackGrad = create("Frame", {
                    Name = "BlackGrad",
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    Parent = SVBox,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = BlackGrad })
                create("UIGradient", {
                    Rotation = 90,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                    Parent = BlackGrad,
                })

                -- Picker Ring Cursor
                local SVCursor = create("Frame", {
                    Name = "Cursor",
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(10, 10),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(curS, 0, 1 - curV, 0),
                    Parent = SVBox,
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SVCursor })
                create("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1), Parent = SVCursor })

                -- Hue Slider Bar (200 x 14 px)
                local HueBar = create("TextButton", {
                    Name = "HueBar",
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    AutoButtonColor = false,
                    Text = "",
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(200, 14),
                    Position = UDim2.fromOffset(10, 118),
                    Parent = ColorPopup,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = HueBar })
                create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                    }),
                    Parent = HueBar,
                })

                local HueCursor = create("Frame", {
                    Name = "HueCursor",
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Size = UDim2.fromOffset(6, 16),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(curH, 0, 0.5, 0),
                    Parent = HueBar,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = HueCursor })
                create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Parent = HueCursor })

                -- Hex Input Box
                local HexInput = create("TextBox", {
                    Name = "HexInput",
                    BackgroundColor3 = theme.head,
                    FontFace = Font_SemiBold,
                    Text = "#" .. Color:ToHex():upper(),
                    TextColor3 = theme.text,
                    TextSize = 11,
                    Size = UDim2.fromOffset(95, 20),
                    Position = UDim2.fromOffset(10, 142),
                    Parent = ColorPopup,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = HexInput })
                create("UIStroke", { Thickness = 1, Color = theme.line, Parent = HexInput })

                -- Preview Box
                local PreviewBox = create("Frame", {
                    Name = "Preview",
                    BackgroundColor3 = Color,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(95, 20),
                    Position = UDim2.fromOffset(115, 142),
                    Parent = ColorPopup,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = PreviewBox })
                create("UIStroke", { Thickness = 1, Color = theme.line, Parent = PreviewBox })

                local function applyColor(newCol, skipCallback)
                    Color = newCol
                    curH, curS, curV = Color:ToHSV()
                    Swatch.BackgroundColor3 = Color
                    PreviewBox.BackgroundColor3 = Color
                    SVBox.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
                    SVCursor.Position = UDim2.new(curS, 0, 1 - curV, 0)
                    HueCursor.Position = UDim2.new(curH, 0, 0.5, 0)
                    if not HexInput:IsFocused() then
                        HexInput.Text = "#" .. Color:ToHex():upper()
                    end
                    if Flag then
                        Library.Flags[Flag] = Color
                    end
                    if not skipCallback then
                        pcall(Callback, Color)
                    end
                end

                -- SV Dragging
                local isDraggingSV = false
                SVBox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingSV = true
                        while isDraggingSV and (input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change) do
                            local pointer = getPointerPosition(input)
                            local svX = SVBox.AbsolutePosition.X
                            local svY = SVBox.AbsolutePosition.Y
                            local s = math.clamp((pointer.X - svX) / SVBox.AbsoluteSize.X, 0, 1)
                            local v = 1 - math.clamp((pointer.Y - svY) / SVBox.AbsoluteSize.Y, 0, 1)
                            curS = s
                            curV = v
                            applyColor(Color3.fromHSV(curH, curS, curV))
                            RunService.RenderStepped:Wait()
                        end
                        isDraggingSV = false
                    end
                end)

                -- Hue Dragging
                local isDraggingHue = false
                HueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingHue = true
                        while isDraggingHue and (input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change) do
                            local pointer = getPointerPosition(input)
                            local hX = HueBar.AbsolutePosition.X
                            curH = math.clamp((pointer.X - hX) / HueBar.AbsoluteSize.X, 0, 1)
                            applyColor(Color3.fromHSV(curH, curS, curV))
                            RunService.RenderStepped:Wait()
                        end
                        isDraggingHue = false
                    end
                end)

                HexInput.FocusLost:Connect(function()
                    local clean = HexInput.Text:gsub("#", "")
                    local ok, parsed = pcall(Color3.fromHex, clean)
                    if ok and parsed then
                        applyColor(parsed)
                    else
                        HexInput.Text = "#" .. Color:ToHex():upper()
                    end
                end)

                Swatch.MouseButton1Click:Connect(function()
                    if activePopup == ColorPopup then
                        closeActivePopup()
                    else
                        local absPos = Swatch.AbsolutePosition
                        openPopup(ColorPopup, absPos.X - 190, absPos.Y + Swatch.AbsoluteSize.Y + 6)
                    end
                end)

                if Flag then
                    Library.Flags[Flag] = Color
                end

                return {
                    Set = applyColor,
                    Get = function() return Color end,
                }
            end

            -- ========================================================
            -- UI ELEMENT: KEYBIND
            -- ========================================================
            function SecObj:Keybind(keyOpts)
                keyOpts = keyOpts or {}
                local Name = keyOpts.Name or "Keybind"
                local Flag = keyOpts.Flag
                local Key = keyOpts.Default or Enum.KeyCode.RightShift
                local Mode = keyOpts.Mode or "Toggle" -- Toggle, Hold, Always
                local Callback = keyOpts.Callback or function() end

                local Row = create("Frame", {
                    Name = "Row_Keybind_" .. Name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    Parent = ElementsContainer,
                })

                local Label = create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    FontFace = Font_SemiBold,
                    Text = Name,
                    TextColor3 = theme.text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -70, 1, 0),
                    Parent = Row,
                })

                local KeyBtn = create("TextButton", {
                    Name = "KeyButton",
                    BackgroundColor3 = theme.head,
                    AutoButtonColor = false,
                    FontFace = Font_SemiBold,
                    Text = typeof(Key) == "EnumItem" and Key.Name or tostring(Key),
                    TextColor3 = theme.dim,
                    TextSize = 11,
                    Size = UDim2.fromOffset(62, 20),
                    Position = UDim2.new(1, -62, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = Row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = KeyBtn })
                local KeyStroke = create("UIStroke", { Thickness = 1, Color = theme.line, Parent = KeyBtn })

                local isListening = false
                KeyBtn.MouseButton1Click:Connect(function()
                    isListening = true
                    KeyBtn.Text = "..."
                    tween(KeyStroke, 0.15, { Color = theme.accent })
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if isListening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            Key = input.KeyCode
                            KeyBtn.Text = Key.Name
                            isListening = false
                            tween(KeyStroke, 0.15, { Color = theme.line })
                            if Flag then Library.Flags[Flag] = Key end
                        end
                    elseif not processed and input.KeyCode == Key then
                        pcall(Callback, true, Key)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if not isListening and Mode == "Hold" and input.KeyCode == Key then
                        pcall(Callback, false, Key)
                    end
                end)

                if Flag then
                    Library.Flags[Flag] = Key
                end

                return {
                    Set = function(newKey)
                        Key = newKey
                        KeyBtn.Text = typeof(Key) == "EnumItem" and Key.Name or tostring(Key)
                        if Flag then Library.Flags[Flag] = Key end
                    end,
                    Get = function() return Key end,
                }
            end

            -- ========================================================
            -- UI ELEMENT: BUTTON (Hover color + click stroke pulse)
            -- ========================================================
            function SecObj:Button(btnOpts)
                btnOpts = btnOpts or {}
                local Name = btnOpts.Name or "Button"
                local Callback = btnOpts.Callback or function() end

                local Btn = create("TextButton", {
                    Name = "Button_" .. Name,
                    BackgroundColor3 = theme.elem,
                    AutoButtonColor = false,
                    FontFace = Font_SemiBold,
                    Text = Name,
                    TextColor3 = theme.text,
                    TextSize = 12,
                    Size = UDim2.new(1, 0, 0, 26),
                    Parent = ElementsContainer,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Btn })
                local BtnStroke = create("UIStroke", { Thickness = 1, Color = theme.line, Parent = Btn })

                Btn.MouseEnter:Connect(function()
                    tween(Btn, 0.15, { BackgroundColor3 = theme.elem_hover })
                end)
                Btn.MouseLeave:Connect(function()
                    tween(Btn, 0.15, { BackgroundColor3 = theme.elem })
                end)
                Btn.MouseButton1Click:Connect(function()
                    BtnStroke.Color = theme.accent
                    tween(BtnStroke, 0.35, { Color = theme.line })
                    pcall(Callback)
                end)

                return Btn
            end

            -- ========================================================
            -- UI ELEMENT: TEXTBOX / INPUT
            -- ========================================================
            function SecObj:TextBox(tbOpts)
                tbOpts = tbOpts or {}
                local Name = tbOpts.Name or "Input"
                local Flag = tbOpts.Flag
                local Placeholder = tbOpts.Placeholder or "Enter value..."
                local Value = tbOpts.Default or ""
                local Callback = tbOpts.Callback or function() end

                local Row = create("Frame", {
                    Name = "Row_TextBox_" .. Name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 48),
                    Parent = ElementsContainer,
                })

                create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    FontFace = Font_SemiBold,
                    Text = Name,
                    TextColor3 = theme.text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 16),
                    Position = UDim2.fromOffset(0, 0),
                    Parent = Row,
                })

                local Box = create("TextBox", {
                    Name = "Input",
                    BackgroundColor3 = theme.head,
                    FontFace = Font_Regular,
                    Text = Value,
                    PlaceholderText = Placeholder,
                    PlaceholderColor3 = theme.dim,
                    TextColor3 = theme.text,
                    TextSize = 11,
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.fromOffset(0, 20),
                    Parent = Row,
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Box })
                local Stroke = create("UIStroke", { Thickness = 1, Color = theme.line, Parent = Box })
                create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = Box })

                Box.Focused:Connect(function()
                    tween(Stroke, 0.15, { Color = theme.accent })
                end)
                Box.FocusLost:Connect(function(enterPressed)
                    tween(Stroke, 0.15, { Color = theme.line })
                    Value = Box.Text
                    if Flag then Library.Flags[Flag] = Value end
                    pcall(Callback, Value, enterPressed)
                end)

                if Flag then
                    Library.Flags[Flag] = Value
                end

                return {
                    Set = function(t)
                        Box.Text = t
                        Value = t
                        if Flag then Library.Flags[Flag] = Value end
                    end,
                    Get = function() return Value end,
                }
            end

            -- ========================================================
            -- UI ELEMENT: LABEL
            -- ========================================================
            function SecObj:Label(labelText)
                local Row = create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    FontFace = Font_Regular,
                    Text = labelText or "",
                    TextColor3 = theme.dim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Size = UDim2.new(1, 0, 0, 18),
                    Parent = ElementsContainer,
                })
                return Row
            end

            -- ========================================================
            -- UI ELEMENT: DIVIDER
            -- ========================================================
            function SecObj:Divider()
                local Div = create("Frame", {
                    Name = "Divider",
                    BackgroundColor3 = theme.line,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = ElementsContainer,
                })
                return Div
            end

            return SecObj
        end

        table.insert(WindowObj.Tabs, TabObj)
        if #WindowObj.Tabs == 1 then
            task.defer(activateTab)
        end

        return TabObj
    end

    -- Initial Window Intro Bounce Animation
    WindowUIScale.Scale = 0.8
    Container.GroupTransparency = 1
    DropShadow.ImageTransparency = 1
    tween(WindowUIScale, 0.45, { Scale = 0.9 }, Enum.EasingStyle.Back)
    tween(Container, 0.35, { GroupTransparency = 0 })
    tween(DropShadow, 0.4, { ImageTransparency = 0.6 })

    table.insert(Library.Windows, WindowObj)
    return WindowObj
end

-- Aliases for flexibility
Library.CreateWindow = Library.Window
Library.new = Library.Window

return Library
