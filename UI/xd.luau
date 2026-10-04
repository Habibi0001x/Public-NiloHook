local Services = setmetatable({}, {
	__index = function(_, ServiceName)
		return game:GetService(ServiceName)
	end
})

local CoreGui = Services.CoreGui
local Players = Services.Players
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local RunService = Services.RunService
local GuiService = Services.GuiService
local ReplicatedStorage = Services.ReplicatedStorage

local CosmeticLibrary = { Cosmetics = {} }
pcall(function()
	CosmeticLibrary = require(ReplicatedStorage.Modules.CosmeticLibrary)
end)

local LocalPlayer = Players.LocalPlayer

local WrapController = nil
pcall(function()
	WrapController = require(LocalPlayer.PlayerScripts.Controllers.WrapController)
end)

local WrapTemplate = nil
pcall(function()
	WrapTemplate = LocalPlayer.PlayerScripts.Assets.Misc.Wrap
end)

local PreviewModels = {}

local function BuildWrapModel(WrapName, Target)
	if not WrapController or not WrapTemplate then
		return nil
	end

	local Ok, Model = pcall(function()
		setthreadidentity(2)
		local Clone = WrapTemplate:Clone()
		WrapController:ApplyWrap(WrapController:RecordOriginalWrapProperties(Clone), { Name = WrapName })
		local Snapshot = Clone:Clone()
		Clone:Destroy()
		return Snapshot
	end)

	if Ok and Model then
		setthreadidentity(8)
		Model.Parent = Target
		table.insert(PreviewModels, Model)
		return Model
	end
	return nil
end

local CharmModels = nil
pcall(function()
	CharmModels = LocalPlayer.PlayerScripts.Assets.Charms
end)

local function BuildCharmModel(CharmName, Target)
	if not CharmModels then
		return nil
	end

	local Ok, Model = pcall(function()
		setthreadidentity(2)
		local Source = CharmModels:FindFirstChild(CharmName)
		if not Source then
			return nil
		end
		return Source:Clone()
	end)

	if Ok and Model then
		setthreadidentity(8)
		Model.Parent = Target
		table.insert(PreviewModels, Model)
		return Model
	end
	return nil
end

if getgenv().Library then
	pcall(function()
		getgenv().Library:Unload()
	end)
	getgenv().Library = nil
end

local Icons = {}
pcall(function()
	Icons = loadstring(game:HttpGet("https://github.com/Footagesus/Icons/raw/refs/heads/main/lucide/dist/Icons.lua"))()
end)

local Library = {
	Name = "Vesper",
	Flags = {},
	Callbacks = {},
	Connections = {},
	Objects = {},
	TextObjects = {},
	Popups = {},
	Anchors = {},
	PopupOwners = {},
	PopupScales = {},
	Elements = {},
	AccentHooks = {},
	SearchIndex = {},
	Toggled = true,
	ToggleKey = Enum.KeyCode.RightControl,
	Folders = {
		Base = "vesper",
		Fonts = "vesper/fonts",
		Configs = "vesper/configs",
	},
	Theme = {
		Accent = Color3.fromRGB(232, 126, 26),
		AccentDark = Color3.fromRGB(186, 98, 18),
		Window = Color3.fromRGB(30, 33, 38),
		Topbar = Color3.fromRGB(23, 25, 29),
		Sidebar = Color3.fromRGB(26, 28, 33),
		Section = Color3.fromRGB(34, 37, 43),
		SectionHeader = Color3.fromRGB(41, 45, 52),
		Control = Color3.fromRGB(53, 58, 66),
		ControlDark = Color3.fromRGB(45, 49, 57),
		Border = Color3.fromRGB(46, 50, 58),
		Text = Color3.fromRGB(226, 229, 234),
		SubText = Color3.fromRGB(138, 145, 156),
		Dim = Color3.fromRGB(96, 102, 112),
	},
}

for _, Folder in ipairs({ Library.Folders.Base, Library.Folders.Fonts, Library.Folders.Configs }) do
	if isfolder and makefolder and not isfolder(Folder) then
		pcall(makefolder, Folder)
	end
end

local function Icon(Name)
	local Asset = Icons[Name]
	if typeof(Asset) == "table" then
		Asset = Asset.Url or Asset.url or Asset[1]
	end
	return Asset or "rbxassetid://0"
end

local function Connect(Signal, Fn)
	local Conn = Signal:Connect(Fn)
	table.insert(Library.Connections, Conn)
	return Conn
end

local function New(Class, Props, Children)
	setthreadidentity(8)
	local Object = Instance.new(Class)
	local Parent = nil
	local Weight = nil

	for Prop, Value in pairs(Props or {}) do
		if Prop == "Parent" then
			Parent = Value
		elseif Prop == "Weight" then
			Weight = Value
		else
			Object[Prop] = Value
		end
	end

	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		Object:SetAttribute("Weight", Weight)
		table.insert(Library.TextObjects, Object)
		if Library.Font then
			Object.FontFace = Library.FontFor(Weight)
		end
	end

	for _, Child in pairs(Children or {}) do
		Child.Parent = Object
	end

	if Parent then
		Object.Parent = Parent
	end

	table.insert(Library.Objects, Object)
	return Object
end

local function Corner(Radius)
	return New("UICorner", { CornerRadius = UDim.new(0, Radius or 5) })
end

local function Stroke(Color, Thickness, Transparency)
	return New("UIStroke", {
		Color = Color or Library.Theme.Border,
		Thickness = Thickness or 1,
		Transparency = Transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Padding(Top, Bottom, Left, Right)
	return New("UIPadding", {
		PaddingTop = UDim.new(0, Top or 0),
		PaddingBottom = UDim.new(0, Bottom or 0),
		PaddingLeft = UDim.new(0, Left or 0),
		PaddingRight = UDim.new(0, Right or 0),
	})
end

local function List(Pad, Dir, Align)
	return New("UIListLayout", {
		Padding = UDim.new(0, Pad or 0),
		FillDirection = Dir or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Align or Enum.VerticalAlignment.Top,
	})
end

local function Tween(Object, Time, Props)
	local Animation = TweenService:Create(Object, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props)
	Animation:Play()
	return Animation
end

local function MousePoint()
	local Location = UserInputService:GetMouseLocation()
	local Inset = GuiService:GetGuiInset()
	return Vector2.new(Location.X - Inset.X, Location.Y - Inset.Y)
end

local CustomFont = {}
do
	local Weights = {
		Thin = 100,
		ExtraLight = 200,
		Light = 300,
		Regular = 400,
		Medium = 500,
		SemiBold = 600,
		Bold = 700,
		ExtraBold = 800,
		Black = 900,
	}

	local WeightEnums = {
		Thin = Enum.FontWeight.Thin,
		ExtraLight = Enum.FontWeight.ExtraLight,
		Light = Enum.FontWeight.Light,
		Regular = Enum.FontWeight.Regular,
		Medium = Enum.FontWeight.Medium,
		SemiBold = Enum.FontWeight.SemiBold,
		Bold = Enum.FontWeight.Bold,
		ExtraBold = Enum.FontWeight.ExtraBold,
		Black = Enum.FontWeight.Heavy,
	}

	CustomFont.Weights = Weights
	CustomFont.WeightEnums = WeightEnums

	local Order = { "Thin", "ExtraLight", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Black" }
	CustomFont.Order = Order

	function CustomFont:BuildUrl(Name, Weight)
		local Family = Name:match("^%s*(.-)%s*$")
		Family = (Family:gsub("%s+", "+"))
		local Number = Weights[Weight] or tonumber(Weight)
		if Number and Number ~= 400 then
			return `https://fonts.googleapis.com/css2?family={Family}:wght@{Number}&display=swap`
		end
		return `https://fonts.googleapis.com/css2?family={Family}&display=swap`
	end

	function CustomFont:MultiUrl(Name)
		local Family = Name:match("^%s*(.-)%s*$")
		Family = (Family:gsub("%s+", "+"))
		return `https://fonts.googleapis.com/css2?family={Family}:wght@100;200;300;400;500;600;700;800;900&display=swap`
	end

	local function SafeName(Name)
		return (Name:gsub("[^%w]", ""))
	end

	function CustomFont:Fetch(Url)
		local Ok, Sheet = pcall(game.HttpGet, game, Url)
		if not Ok or not Sheet then
			return nil
		end

		local Found = {}
		for Block in Sheet:gmatch("@font%-face%s*{(.-)}") do
			local Number = Block:match("font%-weight:%s*(%d+)")
			local Direct = Block:match("src:%s*url%((.-)%)") or Block:match("url%((.-)%)")
			if Number and Direct then
				Found[tonumber(Number)] = Direct
			end
		end

		if not next(Found) then
			local Direct = Sheet:match("url%((.-)%)")
			if Direct then
				Found[400] = Direct
			end
		end

		return next(Found) and Found or nil
	end

	function CustomFont:Build(Name, Sources, Fallback)
		local Id = SafeName(Name)
		local Assets = {}

		for Number, Url in pairs(Sources) do
			local File = `{Library.Folders.Fonts}/{Id}_{Number}.ttf`
			local Ok = true
			if not isfile(File) then
				Ok = pcall(function()
					writefile(File, game:HttpGet(Url))
				end)
			end
			if Ok and isfile(File) then
				local Got, Asset = pcall(getcustomasset, File)
				if Got then
					Assets[Number] = Asset
				end
			end
		end

		if not next(Assets) then
			return nil
		end

		local Faces = {}
		for _, WeightName in ipairs(Order) do
			local Target = Weights[WeightName]
			local Asset = Assets[Target]

			if not Asset then
				local Best, Distance = nil, math.huge
				for Number, Candidate in pairs(Assets) do
					local Gap = math.abs(Number - Target)
					if Gap < Distance then
						Best, Distance = Candidate, Gap
					end
				end
				Asset = Best
			end

			table.insert(Faces, {
				name = Id,
				weight = Target,
				style = "normal",
				assetId = Asset,
			})
		end

		local Definition = `{Library.Folders.Fonts}/{Id}.font`
		local Ok = pcall(function()
			writefile(Definition, HttpService:JSONEncode({ name = Id, faces = Faces }))
		end)

		if not Ok then
			return nil
		end

		local Made, Result = pcall(function()
			return Font.new(getcustomasset(Definition), WeightEnums[Fallback or "Regular"], Enum.FontStyle.Normal)
		end)

		if not Made or not Result then
			return nil
		end

		local Distinct = 0
		for _ in pairs(Assets) do
			Distinct += 1
		end

		return Result, Distinct
	end

	function CustomFont:Google(Url, Name, Weight)
		local Sources = CustomFont:Fetch(Url)
		if not Sources then
			return nil
		end
		return CustomFont:Build(Name or "GoogleFont", Sources, Weight)
	end

	function CustomFont:New(Name, Weight, Style, Data)
		local Success, Result = pcall(function()
			if not isfile(Data.Id) then
				writefile(Data.Id, game:HttpGet(Data.Url))
			end

			local Asset = getcustomasset(Data.Id)
			local Faces = {}

			for _, WeightName in ipairs(Order) do
				table.insert(Faces, {
					name = Name,
					weight = Weights[WeightName],
					style = "normal",
					assetId = Asset,
				})
			end

			local Definition = `{Library.Folders.Fonts}/{Name}.font`
			writefile(Definition, HttpService:JSONEncode({ name = Name, faces = Faces }))
			return Font.new(getcustomasset(Definition), WeightEnums[Weight] or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		end)

		if Success and Result then
			return Result
		end
		return Font.fromEnum(Enum.Font.GothamMedium)
	end

	function CustomFont:Family(Name, Weight)
		local Sources = CustomFont:Fetch(CustomFont:MultiUrl(Name))
		if not Sources then
			Sources = CustomFont:Fetch(CustomFont:BuildUrl(Name, Weight))
		end
		if not Sources then
			return nil
		end
		return CustomFont:Build(Name, Sources, Weight)
	end
end

Library.Font = CustomFont:New("InterSemiBold", "Regular", "Normal", {
	Id = `{Library.Folders.Fonts}/InterSemiBold.ttf`,
	Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/InterSemibold.ttf",
})

Library.DefaultFont = Library.Font
Library.MultiWeight = false

function Library.FontFor(Weight)
	local Base = Library.Font
	if not Base or not Weight or not Library.MultiWeight then
		return Base
	end

	local Target = CustomFont.WeightEnums[Weight]
	if not Target then
		return Base
	end

	local Ok, Result = pcall(function()
		return Font.new(Base.Family, Target, Enum.FontStyle.Normal)
	end)

	return Ok and Result or Base
end

function Library:SetFont(FontObject)
	Library.Font = FontObject
	for _, Object in pairs(Library.TextObjects) do
		if Object and Object.Parent then
			Object.FontFace = Library.FontFor(Object:GetAttribute("Weight"))
		end
	end
end

function Library:LoadFont(Name, Url, Weight, Style)
	local Loaded = CustomFont:New(Name, Weight or "Regular", Style or "Normal", {
		Id = `{Library.Folders.Fonts}/{Name}.ttf`,
		Url = Url,
	})
	Library.MultiWeight = false
	Library:SetFont(Loaded)
	return Loaded
end

function Library:LoadGoogleFont(Url, Name, Weight)
	local Loaded, Count = CustomFont:Google(Url, Name, Weight)
	if Loaded then
		Library.MultiWeight = (Count or 1) > 1
		Library:SetFont(Loaded)
	end
	return Loaded
end

function Library:LoadGoogleFontByName(Name, Weight)
	if not Name or Name == "" then
		return nil
	end

	local Loaded, Count = CustomFont:Family(Name, Weight)
	if Loaded then
		Library.MultiWeight = (Count or 1) > 1
		Library:SetFont(Loaded)
	end
	return Loaded
end

local ScreenGui = New("ScreenGui", {
	Name = HttpService:GenerateGUID(false),
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 9999,
})

pcall(function()
	if gethui then
		ScreenGui.Parent = gethui()
	elseif syn and syn.protect_gui then
		syn.protect_gui(ScreenGui)
		ScreenGui.Parent = CoreGui
	else
		ScreenGui.Parent = CoreGui
	end
end)

if not ScreenGui.Parent then
	ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

Library.ScreenGui = ScreenGui

local Overlay = New("Frame", {
	Name = "Overlay",
	Parent = ScreenGui,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 200,
})

local NotifyHolder = New("Frame", {
	Name = "Notifications",
	Parent = ScreenGui,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.fromOffset(260, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 400,
}, {
	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}),
})
local function MarkAccent(Object)
	Object:SetAttribute("Accent", true)
	return Object
end

local CreateContainer

local KeybindList = New("Frame", {
	Name = "Keybinds",
	Parent = ScreenGui,
	BackgroundColor3 = Library.Theme.Window,
	Position = UDim2.fromOffset(24, 120),
	Size = UDim2.fromOffset(170, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 0.15,
	Visible = false,
	Active = true,
	ZIndex = 300,
}, {
	Corner(5),
	List(0),
})

local KeybindHeader = New("Frame", {
	Parent = KeybindList,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 26),
	LayoutOrder = 1,
	ZIndex = 301,
}, {
	New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "Keybinds",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		ZIndex = 302,
	}),
})

MarkAccent(New("Frame", {
	Parent = KeybindHeader,
	BackgroundColor3 = Library.Theme.Accent,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, -20, 0, 1),
	BorderSizePixel = 0,
	ZIndex = 302,
}))

local KeybindBody = New("Frame", {
	Parent = KeybindList,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	LayoutOrder = 2,
	ZIndex = 301,
}, {
	List(4),
	Padding(8, 10, 12, 12),
})

local KeybindEntries = {}

local function RefreshKeybindList()
	local Count = 0

	for _, Entry in ipairs(KeybindEntries) do
		local Visible = Entry.Key ~= nil and Entry.Mode ~= "Always" and Entry.Enabled
		Entry.Holder.Visible = Visible
		if Visible then
			Count += 1
			Entry.Name.Text = Entry.Title
			Entry.Value.Text = `[{Entry.Key.Name}] {Entry.Mode}`
			Entry.Value.TextColor3 = Entry.Active and Library.Theme.Accent or Library.Theme.Dim
		end
	end

	KeybindList.Visible = Count > 0 and Library.ShowKeybinds
end

local function AddKeybindEntry(Title)
	local Holder = New("Frame", {
		Parent = KeybindBody,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 15),
		Visible = false,
		ZIndex = 302,
	})

	local Name = New("TextLabel", {
		Parent = Holder,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = Title,
		TextColor3 = Library.Theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 303,
	})

	local Value = New("TextLabel", {
		Parent = Holder,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = "",
		TextColor3 = Library.Theme.Dim,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 303,
	})

	local Entry = {
		Title = Title,
		Holder = Holder,
		Name = Name,
		Value = Value,
		Key = nil,
		Mode = "Toggle",
		Enabled = false,
		Active = false,
	}

	table.insert(KeybindEntries, Entry)
	return Entry
end

Library.ShowKeybinds = true

function Library:ToggleKeybindList(State)
	Library.ShowKeybinds = State == nil and not Library.ShowKeybinds or State
	RefreshKeybindList()
end

local function Shade(Strength)
	return New("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.78, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(0, 0, 0), Strength or 0.12)),
		}),
	})
end

function Library:Notify(Options)
	Options = typeof(Options) == "table" and Options or { Text = Options }

	local Card = New("Frame", {
		Parent = NotifyHolder,
		BackgroundColor3 = Library.Theme.Section,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 401,
	}, {
		Corner(6),
		Stroke(Library.Theme.Border),
	})

	local Accent = MarkAccent(New("Frame", {
		Parent = Card,
		BackgroundColor3 = Library.Theme.Accent,
		Size = UDim2.new(0, 3, 1, -12),
		Position = UDim2.new(0, 0, 0, 6),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ZIndex = 402,
	}, {
		Corner(2),
		Shade(),
	}))

	local Content = New("Frame", {
		Parent = Card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 402,
	}, {
		List(3),
		Padding(9, 9, 14, 12),
	})

	local Title = New("TextLabel", {
		Parent = Content,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 15),
		Text = Options.Title or Library.Name,
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		ZIndex = 403,
	})

	local Body = New("TextLabel", {
		Parent = Content,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = Options.Text or "",
		TextColor3 = Library.Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextTransparency = 1,
		ZIndex = 403,
	})

	Tween(Card, 0.2, { BackgroundTransparency = 0 })
	Tween(Accent, 0.2, { BackgroundTransparency = 0 })
	Tween(Title, 0.2, { TextTransparency = 0 })
	Tween(Body, 0.2, { TextTransparency = 0 })

	task.delay(Options.Duration or 3, function()
		Tween(Card, 0.25, { BackgroundTransparency = 1 })
		Tween(Accent, 0.25, { BackgroundTransparency = 1 })
		Tween(Title, 0.25, { TextTransparency = 1 })
		Tween(Body, 0.25, { TextTransparency = 1 })
		for _, Object in pairs(Card:GetChildren()) do
			if Object:IsA("UIStroke") then
				Tween(Object, 0.25, { Transparency = 1 })
			end
		end
		task.wait(0.3)
		Card:Destroy()
	end)

	return Card
end

function Library:Modal(Options)
	Options = Options or {}

	local Backdrop = New("TextButton", {
		Parent = ScreenGui,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 500,
	})

	local Scale = New("UIScale", { Scale = 0.92 })

	local Card = New("CanvasGroup", {
		Parent = Backdrop,
		BackgroundColor3 = Library.Theme.Window,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Options.Width or 380, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
		ZIndex = 501,
	}, {
		Corner(10),
		Stroke(Library.Theme.Border),
		Scale,
		List(0),
	})

	local Header = New("Frame", {
		Parent = Card,
		BackgroundColor3 = Library.Theme.Topbar,
		Size = UDim2.new(1, 0, 0, 46),
		LayoutOrder = 1,
		ZIndex = 502,
	}, {
		Corner(10),
	})

	New("Frame", {
		Parent = Header,
		BackgroundColor3 = Library.Theme.Topbar,
		Position = UDim2.new(0, 0, 1, -10),
		Size = UDim2.new(1, 0, 0, 10),
		BorderSizePixel = 0,
		ZIndex = 502,
	})

	local Accent = MarkAccent(New("Frame", {
		Parent = Header,
		BackgroundColor3 = Library.Theme.Accent,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		ZIndex = 503,
	}))

	New("TextLabel", {
		Parent = Header,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Text = Options.Title or "About",
		TextColor3 = Library.Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 503,
	})

	local Close = New("ImageButton", {
		Parent = Header,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Image = Icon("x"),
		ImageColor3 = Library.Theme.SubText,
		ZIndex = 503,
	})

	local Body = New("Frame", {
		Parent = Card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		ZIndex = 502,
	}, {
		List(8),
		Padding(16, 18, 18, 18),
	})

	local Modal = {}

	function Modal:Close()
		Tween(Card, 0.14, { GroupTransparency = 1 })
		Tween(Scale, 0.14, { Scale = 0.94 })
		Tween(Backdrop, 0.16, { BackgroundTransparency = 1 })
		local Border = Card:FindFirstChildOfClass("UIStroke")
		if Border then
			Tween(Border, 0.12, { Transparency = 1 })
		end
		task.delay(0.2, function()
			Backdrop:Destroy()
		end)
	end

	Close.MouseEnter:Connect(function()
		Tween(Close, 0.12, { ImageColor3 = Library.Theme.Text })
	end)
	Close.MouseLeave:Connect(function()
		Tween(Close, 0.12, { ImageColor3 = Library.Theme.SubText })
	end)
	Close.MouseButton1Click:Connect(function()
		Modal:Close()
	end)
	Backdrop.MouseButton1Click:Connect(function()
		Modal:Close()
	end)

	Tween(Backdrop, 0.18, { BackgroundTransparency = 0.45 })
	Tween(Card, 0.18, { GroupTransparency = 0 })
	Tween(Scale, 0.22, { Scale = 1 })

	Modal.Card = Card
	Modal.Body = CreateContainer(Body, Options.Width and Options.Width - 36 or 344)
	return Modal
end

local function SetPopupVisible(Popup, Show)
	Show = Show and true or false
	if Popup:GetAttribute("Open") == Show then
		return
	end

	Popup:SetAttribute("Open", Show)
	local Scale = Library.PopupScales[Popup]
	local Border = Popup:FindFirstChildOfClass("UIStroke")

	if Show then
		Popup.GroupTransparency = 1
		if Border then
			Border.Transparency = 1
		end
		if Scale then
			Scale.Scale = 0.94
		end
		Popup.Visible = true
		Tween(Popup, 0.16, { GroupTransparency = 0 })
		if Border then
			Tween(Border, 0.16, { Transparency = 0 })
		end
		if Scale then
			Tween(Scale, 0.18, { Scale = 1 })
		end
	else
		Tween(Popup, 0.12, { GroupTransparency = 1 })
		if Border then
			Tween(Border, 0.1, { Transparency = 1 })
		end
		if Scale then
			Tween(Scale, 0.12, { Scale = 0.96 })
		end
		task.delay(0.13, function()
			if not Popup:GetAttribute("Open") then
				Popup.Visible = false
			end
		end)
	end
end

local function IsPopupAncestor(Popup, Child)
	local Node = Child
	while Node do
		if Node == Popup then
			return true
		end
		Node = Library.PopupOwners[Node]
	end
	return false
end

local function ClosePopups(Except)
	for _, Popup in pairs(Library.Popups) do
		if Popup:GetAttribute("Open") and not IsPopupAncestor(Popup, Except) then
			SetPopupVisible(Popup, false)
		end
	end
end

local function CloseChildren(Parent)
	for _, Popup in pairs(Library.Popups) do
		if Popup:GetAttribute("Open") and Popup ~= Parent and IsPopupAncestor(Parent, Popup) then
			SetPopupVisible(Popup, false)
		end
	end
end

local function Within(Object, Point)
	if not Object or not Object.Parent then
		return false
	end
	local Pos, Size = Object.AbsolutePosition, Object.AbsoluteSize
	return Point.X >= Pos.X and Point.X <= Pos.X + Size.X and Point.Y >= Pos.Y and Point.Y <= Pos.Y + Size.Y
end

local function PopupUnderCursor()
	local Point = MousePoint()
	local Contained = nil

	for _, Popup in pairs(Library.Popups) do
		if Popup:GetAttribute("Open") then
			if Within(Library.Anchors[Popup], Point) then
				return Popup
			end
			if Within(Popup, Point) and (not Contained or Popup.ZIndex >= Contained.ZIndex) then
				Contained = Popup
			end
		end
	end

	return Contained
end

Connect(UserInputService.InputBegan, function(Input, Processed)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		local Target = PopupUnderCursor()
		if Target then
			ClosePopups(Target)
		else
			ClosePopups()
		end
	elseif not Processed and Input.KeyCode == Library.ToggleKey then
		Library:Toggle()
	end
end)

function Library:Toggle(State)
	Library.Toggled = State == nil and not Library.Toggled or State
	if Library.Main then
		Library.Main.Visible = Library.Toggled
	end
	if not Library.Toggled then
		ClosePopups()
	end
end

function Library:Unload()
	for _, Conn in pairs(Library.Connections) do
		pcall(function()
			Conn:Disconnect()
		end)
	end
	table.clear(Library.Connections)
	table.clear(Library.Objects)
	table.clear(Library.TextObjects)
	table.clear(Library.Popups)
	table.clear(Library.Anchors)
	table.clear(Library.PopupOwners)
	table.clear(Library.PopupScales)
	table.clear(Library.Elements)
	table.clear(Library.AccentHooks)
	table.clear(Library.SearchIndex)
	table.clear(Library.Flags)
	for _, Model in pairs(PreviewModels) do
		pcall(function()
			Model:Destroy()
		end)
	end
	table.clear(PreviewModels)
	if Library.ScreenGui then
		pcall(function()
			Library.ScreenGui:Destroy()
		end)
	end
end

function Library:SetAccent(Color)
	Library.Theme.Accent = Color
	Library.Theme.AccentDark = Color:Lerp(Color3.fromRGB(0, 0, 0), 0.2)

	for _, Object in pairs(Library.Objects) do
		if Object and Object.Parent and Object:GetAttribute("Accent") then
			if Object:IsA("UIStroke") then
				Object.Color = Color
			elseif Object:IsA("TextLabel") or Object:IsA("TextButton") then
				Object.TextColor3 = Color
			elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
				Object.ImageColor3 = Color
			else
				Object.BackgroundColor3 = Color
			end
		end
	end

	for _, Refresh in pairs(Library.AccentHooks) do
		pcall(Refresh, Color)
	end
end

local function OnAccent(Fn)
	table.insert(Library.AccentHooks, Fn)
	return Fn
end

local function MakeDraggable(Handle, Target)
	local Dragging, Start, StartPos = false, nil, nil
	Connect(Handle.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			Start = Input.Position
			StartPos = Target.Position
		end
	end)
	Connect(UserInputService.InputEnded, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)
	Connect(UserInputService.InputChanged, function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local Delta = Input.Position - Start
			Target.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
		end
	end)
end

MakeDraggable(KeybindList, KeybindList)

local function CreatePopup(Width, Owner, Depth)
	local Scale = New("UIScale", { Scale = 1 })

	local Popup = New("CanvasGroup", {
		Parent = Overlay,
		BackgroundColor3 = Library.Theme.Section,
		Size = UDim2.fromOffset(Width or 200, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Active = true,
		GroupTransparency = 1,
		ZIndex = 210 + (Depth or 0) * 10,
	}, {
		Corner(6),
		Stroke(Library.Theme.Border),
		Scale,
	})

	Library.PopupScales[Popup] = Scale
	Library.PopupOwners[Popup] = Owner
	table.insert(Library.Popups, Popup)
	return Popup
end

local function AnchorPopup(Popup, Anchor, OffsetX, OffsetY)
	Library.Anchors[Popup] = Anchor
	local Pos = Anchor.AbsolutePosition
	local Size = Anchor.AbsoluteSize
	local Width = math.max(Popup.AbsoluteSize.X, Popup.Size.X.Offset)
	local Height = math.max(Popup.AbsoluteSize.Y, 40)
	local X = Pos.X + (OffsetX or 0)
	local Y = Pos.Y + Size.Y + (OffsetY or 6)
	local Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	if X + Width > Viewport.X - 8 then
		X = Viewport.X - Width - 8
	end
	if X < 8 then
		X = 8
	end
	if Y + Height > Viewport.Y - 8 then
		Y = math.max(8, Pos.Y - Height - 6)
	end
	Popup.Position = UDim2.fromOffset(X, Y)
end


local function SetFlag(Flag, Value, Callback)
	if Flag then
		Library.Flags[Flag] = Value
	end
	if Callback then
		task.spawn(Callback, Value)
	end
end

local function Register(Flag, Element, Kind)
	if Flag then
		Library.Elements[Flag] = { Element = Element, Kind = Kind }
	end
	return Element
end

local function Index(Container, Name, Kind, Row)
	if not Name or Name == "" or not Container.Tab then
		return
	end
	table.insert(Library.SearchIndex, {
		Name = Name,
		Kind = Kind,
		Tab = Container.Tab,
		Section = Container.Section,
		Row = Row,
	})
end

local function BaseRow(Parent, Height)
	return New("Frame", {
		Parent = Parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Height or 26),
	})
end

local function RowLabel(Parent, Text, Reserved)
	return New("TextLabel", {
		Parent = Parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(Reserved or 60), 1, 0),
		Text = Text,
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClipsDescendants = true,
	})
end

local function AttachSub(Row, Builder, RightOffset, Owner, Depth)
	if not Builder then
		return nil
	end

	local Gear = New("ImageButton", {
		Parent = Row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(RightOffset or 0), 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = Icon("settings"),
		ImageColor3 = Library.Theme.Dim,
	})

	local Popup = CreatePopup(230, Owner, (Depth or 0) + 1)
	New("UIListLayout", { Parent = Popup, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	Padding(10, 10, 12, 12).Parent = Popup

	Builder(CreateContainer(Popup, 206, Popup, (Depth or 0) + 1))

	local Hovering = false

	local function Refresh()
		local Color = Popup:GetAttribute("Open") and Library.Theme.Accent or (Hovering and Library.Theme.Text or Library.Theme.Dim)
		Tween(Gear, 0.12, { ImageColor3 = Color })
	end

	OnAccent(Refresh)

	Connect(Popup:GetAttributeChangedSignal("Open"), function()
		if not Popup:GetAttribute("Open") then
			CloseChildren(Popup)
		end
		Refresh()
	end)

	Gear.MouseEnter:Connect(function()
		Hovering = true
		Refresh()
	end)
	Gear.MouseLeave:Connect(function()
		Hovering = false
		Refresh()
	end)
	Gear.MouseButton1Click:Connect(function()
		local Show = not Popup:GetAttribute("Open")
		ClosePopups(Show and Popup or Owner)
		if Show then
			AnchorPopup(Popup, Gear, -200, 8)
		end
		SetPopupVisible(Popup, Show)
	end)

	return Gear
end

function CreateContainer(Parent, Width, Owner, Depth)
	local Container = {}
	Container.Width = Width or 300
	Container.Owner = Owner
	Container.Depth = Depth or 0

	function Container:Label(Options)
		Options = typeof(Options) == "table" and Options or { Text = Options }
		local Row = BaseRow(Parent, 22)
		local Label = New("TextLabel", {
			Parent = Row,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = Options.Text or "Label",
			TextColor3 = Options.Color or Library.Theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		})
		return {
			Set = function(_, Text)
				Label.Text = Text
			end,
		}
	end

	function Container:Divider()
		local Row = BaseRow(Parent, 9)
		New("Frame", {
			Parent = Row,
			BackgroundColor3 = Library.Theme.Border,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0, 1),
		})
	end

	function Container:Button(Options)
		Options = Options or {}
		local Row = BaseRow(Parent, 28)
		Index(Container, Options.Name, "Button", Row)
		local Button = New("TextButton", {
			Parent = Row,
			BackgroundColor3 = Library.Theme.Control,
			Size = UDim2.fromScale(1, 1),
			Text = Options.Name or "Button",
			TextColor3 = Library.Theme.Text,
			TextSize = 13,
			AutoButtonColor = false,
		}, {
			Corner(4),
			Stroke(Library.Theme.Border),
			Shade(0.13),
		})

		local Hovering = false

		Button.MouseEnter:Connect(function()
			Hovering = true
			Tween(Button, 0.12, { BackgroundColor3 = Library.Theme.Accent })
		end)
		Button.MouseLeave:Connect(function()
			Hovering = false
			Tween(Button, 0.12, { BackgroundColor3 = Library.Theme.Control })
		end)
		Button.MouseButton1Click:Connect(function()
			if Options.Callback then
				task.spawn(Options.Callback)
			end
		end)

		OnAccent(function(Color)
			if Hovering then
				Tween(Button, 0.12, { BackgroundColor3 = Color })
			end
		end)

		return Button
	end

	function Container:Toggle(Options)
		Options = Options or {}
		local Value = Options.Default or false
		local Row = BaseRow(Parent, 26)
		Index(Container, Options.Name, "Toggle", Row)
		RowLabel(Row, Options.Name or "Toggle", Options.Sub and 62 or 44)

		local Switch = New("TextButton", {
			Parent = Row,
			BackgroundColor3 = Library.Theme.Control,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(36, 18),
			Text = "",
			AutoButtonColor = false,
		}, {
			Corner(9),
			Shade(0.16),
		})

		local Knob = New("Frame", {
			Parent = Switch,
			BackgroundColor3 = Library.Theme.SubText,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			BorderSizePixel = 0,
		}, {
			Corner(6),
			Shade(0.1),
		})

		AttachSub(Row, Options.Sub, 46, Container.Owner, Container.Depth)

		local Element = {}
		local Bind = nil

		local function Paint()
			Tween(Switch, 0.15, { BackgroundColor3 = Value and Library.Theme.Accent or Library.Theme.Control })
			Tween(Knob, 0.15, {
				Position = UDim2.new(0, Value and 21 or 3, 0.5, 0),
				BackgroundColor3 = Value and Color3.fromRGB(255, 255, 255) or Library.Theme.SubText,
			})
		end

		function Element:Set(NewValue, Silent)
			Value = NewValue and true or false
			if Bind then
				Bind.Enabled = Value
				if Bind.Mode == "Toggle" then
					Bind.Active = Value
				elseif Bind.Mode ~= "Always" then
					Bind.Active = false
				end
				RefreshKeybindList()
			end
			Paint()
			SetFlag(Options.Flag, Value, not Silent and Options.Callback or nil)
		end

		function Element:Get()
			return Value
		end

		function Element:Active()
			if not Value then
				return false
			end
			if not Bind or Bind.Mode == "Always" then
				return true
			end
			return Bind.Active
		end

		if Options.Keybind then
			Bind = AddKeybindEntry(Options.Name or "Toggle")
			Bind.Mode = Options.Mode or "Toggle"
			Bind.Key = Options.Keybind ~= true and Options.Keybind or nil
			Bind.Enabled = Value
			Bind.Active = Bind.Mode == "Toggle" and Value or false

			Element.Bind = Bind

			function Element:SetKey(Key)
				Bind.Key = Key
				RefreshKeybindList()
			end

			function Element:SetMode(Mode)
				Bind.Mode = Mode
				Bind.Active = Mode == "Toggle" and Value or false
				RefreshKeybindList()
				Paint()
			end

			Connect(UserInputService.InputBegan, function(Input, Processed)
				if Processed or not Bind.Key or Input.KeyCode ~= Bind.Key then
					return
				end
				if not Value or Bind.Mode == "Always" then
					return
				end
				if Bind.Mode == "Hold" then
					Bind.Active = true
				else
					Bind.Active = not Bind.Active
				end
				RefreshKeybindList()
				Paint()
				if Options.OnActive then
					task.spawn(Options.OnActive, Bind.Active)
				end
			end)

			Connect(UserInputService.InputEnded, function(Input)
				if not Bind.Key or Input.KeyCode ~= Bind.Key then
					return
				end
				if Bind.Mode == "Hold" and Bind.Active then
					Bind.Active = false
					RefreshKeybindList()
					Paint()
					if Options.OnActive then
						task.spawn(Options.OnActive, false)
					end
				end
			end)
		end

		OnAccent(function()
			Paint()
			RefreshKeybindList()
		end)

		Switch.MouseButton1Click:Connect(function()
			Element:Set(not Value)
		end)

		Element:Set(Value, true)
		SetFlag(Options.Flag, Value)
		RefreshKeybindList()
		return Register(Options.Flag, Element, "Toggle")
	end

	function Container:Slider(Options)
		Options = Options or {}
		local Min = Options.Min or 0
		local Max = Options.Max or 100
		local Decimals = Options.Decimals or 0
		local Value = math.clamp(Options.Default or Min, Min, Max)
		local Row = BaseRow(Parent, 26)
		Index(Container, Options.Name, "Slider", Row)

		local Label = New("TextLabel", {
			Parent = Row,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 96, 1, 0),
			Text = Options.Name or "Slider",
			TextColor3 = Library.Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local ValueLabel = New("TextLabel", {
			Parent = Row,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(38, 16),
			Text = tostring(Value),
			TextColor3 = Library.Theme.SubText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		})

		local Bar = New("Frame", {
			Parent = Row,
			BackgroundColor3 = Library.Theme.ControlDark,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -46, 0.5, 0),
			Size = UDim2.new(1, -(Options.Sub and 168 or 148), 0, 4),
			BorderSizePixel = 0,
		}, {
			Corner(2),
		})

		local Fill = MarkAccent(New("Frame", {
			Parent = Bar,
			BackgroundColor3 = Library.Theme.Accent,
			Size = UDim2.fromScale(0, 1),
			BorderSizePixel = 0,
		}, {
			Corner(2),
			Shade(0.2),
		}))

		local KnobStroke = MarkAccent(Stroke(Library.Theme.Accent, 1, 0.4))

		local Knob = MarkAccent(New("Frame", {
			Parent = Bar,
			BackgroundColor3 = Library.Theme.Accent,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(10, 10),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, {
			Corner(5),
			KnobStroke,
			Shade(0.16),
		}))

		local Gear = AttachSub(Row, Options.Sub, 0, Container.Owner, Container.Depth)
		if Gear then
			Gear.AnchorPoint = Vector2.new(0, 0.5)
			Gear.Position = UDim2.new(0, 100, 0.5, 0)
		end

		local Element = {}

		local function Format(Number)
			if Decimals > 0 then
				return string.format("%." .. Decimals .. "f", Number)
			end
			return tostring(math.floor(Number + 0.5))
		end

		function Element:Set(NewValue, Silent)
			Value = math.clamp(NewValue, Min, Max)
			if Decimals > 0 then
				Value = tonumber(string.format("%." .. Decimals .. "f", Value))
			else
				Value = math.floor(Value + 0.5)
			end
			local Alpha = (Value - Min) / (Max - Min)
			Fill.Size = UDim2.fromScale(Alpha, 1)
			Knob.Position = UDim2.new(Alpha, 0, 0.5, 0)
			ValueLabel.Text = Format(Value) .. (Options.Suffix or "")
			SetFlag(Options.Flag, Value, not Silent and Options.Callback or nil)
		end

		function Element:Get()
			return Value
		end

		local Dragging = false
		local function Update()
			local Alpha = math.clamp((MousePoint().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
			Element:Set(Min + (Max - Min) * Alpha)
		end

		Connect(Bar.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
				Update()
			end
		end)
		Connect(Knob.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
			end
		end)
		Connect(UserInputService.InputEnded, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = false
			end
		end)
		Connect(UserInputService.InputChanged, function(Input)
			if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
				Update()
			end
		end)

		Element:Set(Value, true)
		return Register(Options.Flag, Element, "Slider")
	end

	function Container:Dropdown(Options)
		Options = Options or {}
		local Items = Options.Items or {}
		local Multi = Options.Multi or false
		local Value = Options.Default or (Multi and {} or Options.Placeholder or "Select")
		local Row = BaseRow(Parent, 26)
		Index(Container, Options.Name, "Dropdown", Row)
		RowLabel(Row, Options.Name or "Dropdown", (Options.Sub and 24 or 6) + math.min(140, Container.Width * 0.52))

		local Box = New("TextButton", {
			Parent = Row,
			BackgroundColor3 = Library.Theme.ControlDark,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, math.min(140, Container.Width * 0.52), 0, 22),
			Text = "",
			AutoButtonColor = false,
		}, {
			Corner(4),
			Stroke(Library.Theme.Border),
		})

		local Display = New("TextLabel", {
			Parent = Box,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -26, 1, 0),
			Text = "Select",
			TextColor3 = Library.Theme.SubText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		New("ImageLabel", {
			Parent = Box,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			Image = Icon("chevron-down"),
			ImageColor3 = Library.Theme.Dim,
		})

		local Popup = CreatePopup(160, Container.Owner, Container.Depth + 1)
		List(6).Parent = Popup
		Padding(8, 8, 8, 8).Parent = Popup

		local SearchRow = New("Frame", {
			Parent = Popup,
			BackgroundColor3 = Library.Theme.ControlDark,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = 1,
			Visible = false,
			ClipsDescendants = true,
			ZIndex = Popup.ZIndex + 1,
		}, {
			Corner(4),
			Stroke(Library.Theme.Border),
		})

		New("ImageLabel", {
			Parent = SearchRow,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 7, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			Image = Icon("search"),
			ImageColor3 = Library.Theme.Dim,
			ZIndex = Popup.ZIndex + 2,
		})

		local Search = New("TextBox", {
			Parent = SearchRow,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(25, 0),
			Size = UDim2.new(1, -32, 1, 0),
			Text = "",
			PlaceholderText = "Search...",
			PlaceholderColor3 = Library.Theme.Dim,
			TextColor3 = Library.Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ClearTextOnFocus = false,
			ZIndex = Popup.ZIndex + 2,
		})

		local Scroller = New("ScrollingFrame", {
			Parent = Popup,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			ClipsDescendants = true,
			ZIndex = Popup.ZIndex + 1,
		}, {
			List(2),
		})

		local Empty = New("TextLabel", {
			Parent = Popup,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			Text = "No matches",
			TextColor3 = Library.Theme.Dim,
			TextSize = 12,
			LayoutOrder = 3,
			Visible = false,
			ZIndex = Popup.ZIndex + 1,
		})

		AttachSub(Row, Options.Sub, Box.Size.X.Offset + 10, Container.Owner, Container.Depth)

		local Element = {}
		local Buttons = {}
		local MaxRows = Options.MaxRows or 7

		local function ApplyFilter()
			local Query = Search.Text:lower():match("^%s*(.-)%s*$")
			local Shown = 0

			for _, Item in ipairs(Items) do
				local Button = Buttons[Item]
				if Button then
					local Match = Query == "" or tostring(Item):lower():find(Query, 1, true) ~= nil
					Button.Visible = Match
					if Match then
						Shown += 1
					end
				end
			end

			Empty.Visible = Shown == 0
			Scroller.Size = UDim2.new(1, 0, 0, math.min(Shown, MaxRows) * 24)
		end

		local function IsSelected(Item)
			if Multi then
				for _, Selected in pairs(Value) do
					if Selected == Item then
						return true
					end
				end
				return false
			end
			return Value == Item
		end

		local function Refresh()
			for Item, Button in pairs(Buttons) do
				local Selected = IsSelected(Item)
				Button.BackgroundTransparency = Selected and 0 or 1
				Button.BackgroundColor3 = Library.Theme.Accent
				Button.TextColor3 = Selected and Color3.fromRGB(255, 255, 255) or Library.Theme.SubText
			end
			if Multi then
				Display.Text = #Value > 0 and table.concat(Value, ", ") or (Options.Placeholder or "Select")
				Display.TextColor3 = #Value > 0 and Library.Theme.Text or Library.Theme.SubText
			else
				Display.Text = tostring(Value)
				Display.TextColor3 = Library.Theme.Text
			end
		end

		OnAccent(Refresh)

		function Element:Set(NewValue, Silent)
			Value = NewValue
			Refresh()
			SetFlag(Options.Flag, Value, not Silent and Options.Callback or nil)
		end

		function Element:Get()
			return Value
		end

		function Element:SetItems(NewItems)
			Items = NewItems
			for _, Button in pairs(Buttons) do
				Button:Destroy()
			end
			table.clear(Buttons)
			for Index, Item in ipairs(Items) do
				local Option = New("TextButton", {
					Parent = Scroller,
					BackgroundColor3 = Library.Theme.Accent,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 22),
					LayoutOrder = Index,
					Text = tostring(Item),
					TextColor3 = Library.Theme.SubText,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					AutoButtonColor = false,
					ZIndex = Popup.ZIndex + 2,
				}, {
					Corner(4),
					Shade(0.13),
					Padding(0, 0, 8, 8),
				})
				Buttons[Item] = Option

				Option.MouseButton1Click:Connect(function()
					if Multi then
						local Found
						for Position, Selected in pairs(Value) do
							if Selected == Item then
								Found = Position
							end
						end
						if Found then
							table.remove(Value, Found)
						else
							table.insert(Value, Item)
						end
						Element:Set(Value)
					else
						Element:Set(Item)
						SetPopupVisible(Popup, false)
					end
				end)
			end
			Refresh()
			ApplyFilter()
		end

		Search:GetPropertyChangedSignal("Text"):Connect(ApplyFilter)

		Box.MouseButton1Click:Connect(function()
			local Show = not Popup:GetAttribute("Open")
			ClosePopups(Popup)
			Popup.Size = UDim2.fromOffset(math.max(160, Box.AbsoluteSize.X), 0)
			SearchRow.Visible = #Items > MaxRows
			if Show then
				Search.Text = ""
				ApplyFilter()
				AnchorPopup(Popup, Box, 0, 4)
			end
			SetPopupVisible(Popup, Show)
		end)

		Element:SetItems(Items)
		Element:Set(Value, true)
		return Register(Options.Flag, Element, "Dropdown")
	end

	function Container:TextBox(Options)
		Options = Options or {}
		local Row = BaseRow(Parent, 26)
		Index(Container, Options.Name, "TextBox", Row)
		RowLabel(Row, Options.Name or "Textbox", (Options.Sub and 24 or 6) + math.min(140, Container.Width * 0.52))

		local Holder = New("Frame", {
			Parent = Row,
			BackgroundColor3 = Library.Theme.ControlDark,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, math.min(140, Container.Width * 0.52), 0, 22),
			ClipsDescendants = true,
		}, {
			Corner(4),
			Stroke(Library.Theme.Border),
			Padding(0, 0, 8, 8),
		})

		local Input = New("TextBox", {
			Parent = Holder,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = Options.Default or "",
			PlaceholderText = Options.Placeholder or "",
			PlaceholderColor3 = Library.Theme.Dim,
			TextColor3 = Library.Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ClearTextOnFocus = false,
			ClipsDescendants = true,
		})

		AttachSub(Row, Options.Sub, Holder.Size.X.Offset + 10, Container.Owner, Container.Depth)

		Input.FocusLost:Connect(function()
			SetFlag(Options.Flag, Input.Text, Options.Callback)
		end)

		SetFlag(Options.Flag, Input.Text)

		return Register(Options.Flag, {
			Set = function(_, Text)
				Input.Text = Text
				SetFlag(Options.Flag, Text, Options.Callback)
			end,
			Get = function()
				return Input.Text
			end,
		}, "TextBox")
	end

	function Container:Keybind(Options)
		Options = Options or {}
		local Key = Options.Default
		local Binding = false
		local Row = BaseRow(Parent, 26)
		Index(Container, Options.Name, "Keybind", Row)
		RowLabel(Row, Options.Name or "Keybind", Options.Sub and 106 or 88)

		local Button = New("TextButton", {
			Parent = Row,
			BackgroundColor3 = Library.Theme.ControlDark,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(80, 22),
			Text = Key and Key.Name or "None",
			TextColor3 = Library.Theme.SubText,
			TextSize = 12,
			AutoButtonColor = false,
		}, {
			Corner(4),
			Stroke(Library.Theme.Border),
		})

		AttachSub(Row, Options.Sub, 90, Container.Owner, Container.Depth)

		Button.MouseButton1Click:Connect(function()
			Binding = true
			Button.Text = "..."
			Button.TextColor3 = Library.Theme.Accent
		end)

		Connect(UserInputService.InputBegan, function(Input, Processed)
			if Binding and Input.UserInputType == Enum.UserInputType.Keyboard then
				Binding = false
				Key = Input.KeyCode ~= Enum.KeyCode.Backspace and Input.KeyCode or nil
				Button.Text = Key and Key.Name or "None"
				Button.TextColor3 = Library.Theme.SubText
				SetFlag(Options.Flag, Key, Options.Callback)
			elseif not Processed and not Binding and Key and Input.KeyCode == Key then
				if Options.Pressed then
					task.spawn(Options.Pressed)
				end
			end
		end)

		SetFlag(Options.Flag, Key)

		return Register(Options.Flag, {
			Set = function(_, NewKey)
				Key = NewKey
				Button.Text = Key and Key.Name or "None"
				Button.TextColor3 = Library.Theme.SubText
				SetFlag(Options.Flag, Key, Options.Callback)
			end,
			Get = function()
				return Key
			end,
		}, "Keybind")
	end

	function Container:ColorPicker(Options)
		Options = Options or {}
		local Value = Options.Default or Library.Theme.Accent
		local Hue, Saturation, Brightness = Value:ToHSV()
		local Row = BaseRow(Parent, 26)
		Index(Container, Options.Name, "ColorPicker", Row)
		RowLabel(Row, Options.Name or "Color", Options.Sub and 60 or 42)

		local Preview = New("TextButton", {
			Parent = Row,
			BackgroundColor3 = Value,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(34, 18),
			Text = "",
			AutoButtonColor = false,
		}, {
			Corner(4),
			Stroke(Library.Theme.Border),
			Shade(0.16),
		})

		AttachSub(Row, Options.Sub, 44, Container.Owner, Container.Depth)

		local Popup = CreatePopup(190, Container.Owner, Container.Depth + 1)
		Padding(10, 10, 10, 10).Parent = Popup
		List(8).Parent = Popup

		local Field = New("ImageButton", {
			Parent = Popup,
			BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
			Size = UDim2.new(1, 0, 0, 120),
			AutoButtonColor = false,
			ZIndex = Popup.ZIndex + 1,
		}, {
			Corner(4),
		})

		New("Frame", {
			Parent = Field,
			BackgroundTransparency = 0,
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			ZIndex = Popup.ZIndex + 2,
		}, {
			Corner(4),
			New("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			}),
		})

		New("Frame", {
			Parent = Field,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			ZIndex = Popup.ZIndex + 3,
		}, {
			Corner(4),
			New("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
			}),
		})

		local Cursor = New("Frame", {
			Parent = Field,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(10, 10),
			ZIndex = Popup.ZIndex + 4,
		}, {
			Corner(5),
			Stroke(Color3.fromRGB(255, 255, 255), 2),
		})

		local HueBar = New("ImageButton", {
			Parent = Popup,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.new(1, 0, 0, 12),
			AutoButtonColor = false,
			ZIndex = Popup.ZIndex + 1,
		}, {
			Corner(6),
			New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
				}),
			}),
		})

		local HueCursor = New("Frame", {
			Parent = HueBar,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(4, 16),
			ZIndex = Popup.ZIndex + 2,
		}, {
			Corner(2),
		})

		local Element = {}

		local function Apply(Silent)
			Value = Color3.fromHSV(Hue, Saturation, Brightness)
			Preview.BackgroundColor3 = Value
			Field.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
			Cursor.Position = UDim2.fromScale(Saturation, 1 - Brightness)
			HueCursor.Position = UDim2.new(Hue, 0, 0.5, 0)
			SetFlag(Options.Flag, Value, not Silent and Options.Callback or nil)
		end

		function Element:Set(Color, Silent)
			Hue, Saturation, Brightness = Color:ToHSV()
			Apply(Silent)
		end

		function Element:Get()
			return Value
		end

		local DraggingField, DraggingHue = false, false

		Connect(Field.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				DraggingField = true
			end
		end)
		Connect(HueBar.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				DraggingHue = true
			end
		end)
		Connect(UserInputService.InputEnded, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				DraggingField, DraggingHue = false, false
			end
		end)
		Connect(RunService.RenderStepped, function()
			if not Popup:GetAttribute("Open") then
				return
			end
			local Location = MousePoint()
			if DraggingField then
				Saturation = math.clamp((Location.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
				Brightness = 1 - math.clamp((Location.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)
				Apply()
			elseif DraggingHue then
				Hue = math.clamp((Location.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
				Apply()
			end
		end)

		Preview.MouseButton1Click:Connect(function()
			local Show = not Popup:GetAttribute("Open")
			ClosePopups(Popup)
			if Show then
				AnchorPopup(Popup, Preview, -156, 6)
			end
			SetPopupVisible(Popup, Show)
		end)

		Apply(true)
		return Register(Options.Flag, Element, "ColorPicker")
	end

	return Container
end

function Library:Window(Options)
	Options = Options or {}

	local Main = New("Frame", {
		Parent = ScreenGui,
		BackgroundColor3 = Library.Theme.Window,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Options.Size and Options.Size.X or 820, Options.Size and Options.Size.Y or 560),
		ClipsDescendants = true,
	}, {
		Corner(8),
		Stroke(Color3.fromRGB(15, 16, 19)),
	})

	Library.Main = Main
	local Window = { Tabs = {}, Groups = {} }

	local Topbar = New("Frame", {
		Parent = Main,
		BackgroundColor3 = Library.Theme.Topbar,
		Size = UDim2.new(1, 0, 0, 62),
		BorderSizePixel = 0,
	}, {
		Corner(8),
	})

	New("Frame", {
		Parent = Topbar,
		BackgroundColor3 = Library.Theme.Topbar,
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		BorderSizePixel = 0,
	})

	New("Frame", {
		Parent = Topbar,
		BackgroundColor3 = Library.Theme.Border,
		Position = UDim2.fromOffset(193, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 4,
	})

	MakeDraggable(Topbar, Main)

	local Brand = New("Frame", {
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(0, 168, 1, 0),
	})

	local Title = New("TextLabel", {
		Parent = Brand,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 11),
		Size = UDim2.new(1, 0, 0, 23),
		Text = string.upper(Options.Title or "VESPER"),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Weight = "Bold",
	})

	local Shine = New("UIGradient", {
		Parent = Title,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 174, 186)),
			ColorSequenceKeypoint.new(0.42, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.58, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 174, 186)),
		}),
		Offset = Vector2.new(-1, 0),
	})

	New("TextLabel", {
		Parent = Brand,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 15),
		Text = Options.Description or "premium suite",
		TextColor3 = Library.Theme.Dim,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Weight = "SemiBold",
	})

	task.spawn(function()
		while Title.Parent and Library.ScreenGui.Parent do
			Shine.Offset = Vector2.new(-1, 0)
			Tween(Shine, 1.6, { Offset = Vector2.new(1, 0) })
			task.wait(3.4)
		end
	end)

	local TopControls = New("Frame", {
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(212, 0),
		Size = UDim2.new(1, -212 - 130, 1, 0),
	}, {
		List(10, Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center),
	})

	local SaveButton = New("TextButton", {
		Parent = TopControls,
		BackgroundColor3 = Library.Theme.Control,
		Size = UDim2.fromOffset(100, 30),
		Text = "",
		AutoButtonColor = false,
	}, {
		Corner(5),
		Stroke(Library.Theme.Border),
		Shade(0.13),
	})

	local SaveIcon = New("ImageLabel", {
		Parent = SaveButton,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = Icon("save"),
		ImageColor3 = Library.Theme.Text,
	})

	New("TextLabel", {
		Parent = SaveButton,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 34, 0.5, 0),
		Size = UDim2.new(1, -44, 1, 0),
		Text = "Save",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	local SaveHover = false

	local function RefreshSave()
		Tween(SaveButton, 0.14, {
			BackgroundColor3 = SaveHover and Library.Theme.Accent or Library.Theme.Control,
		})
		Tween(SaveIcon, 0.14, {
			ImageColor3 = SaveHover and Color3.fromRGB(255, 255, 255) or Library.Theme.Text,
		})
	end

	SaveButton.MouseEnter:Connect(function()
		SaveHover = true
		RefreshSave()
	end)
	SaveButton.MouseLeave:Connect(function()
		SaveHover = false
		RefreshSave()
	end)
	OnAccent(RefreshSave)

	SaveButton.MouseButton1Click:Connect(function()
		Tween(SaveIcon, 0.1, { Rotation = SaveIcon.Rotation - 20 })
		task.delay(0.1, function()
			Tween(SaveIcon, 0.18, { Rotation = 0 })
		end)
		if Options.OnSave then
			task.spawn(Options.OnSave, Library.Flags)
		else
			Library:SaveConfig(Library.Flags.Config)
		end
	end)

	local ConfigBox = New("TextButton", {
		Parent = TopControls,
		BackgroundColor3 = Library.Theme.Control,
		Size = UDim2.fromOffset(190, 30),
		Text = "",
		AutoButtonColor = false,
	}, {
		Corner(5),
		Stroke(Library.Theme.Border),
		Shade(0.13),
	})

	local ConfigLabel = New("TextLabel", {
		Parent = ConfigBox,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.new(1, -34, 1, 0),
		Text = (Options.Configs or { "Global" })[1],
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	New("ImageLabel", {
		Parent = ConfigBox,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		Image = Icon("chevron-down"),
		ImageColor3 = Library.Theme.Dim,
	})

	local ConfigPopup = CreatePopup(190)
	local ConfigList = New("Frame", {
		Parent = ConfigPopup,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = ConfigPopup.ZIndex + 1,
	}, {
		List(2),
		Padding(6, 6, 6, 6),
	})

	local ConfigButtons = {}

	local function BuildConfigList()
		for _, Button in pairs(ConfigButtons) do
			Button:Destroy()
		end
		table.clear(ConfigButtons)

		local Names = Library:ListConfigs()
		if #Names == 0 then
			Names = Options.Configs or { "Global" }
		end

		for Index, Name in ipairs(Names) do
			local Option = New("TextButton", {
				Parent = ConfigList,
				BackgroundColor3 = Library.Theme.Accent,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 24),
				LayoutOrder = Index,
				Text = Name,
				TextColor3 = Library.Theme.SubText,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				ZIndex = ConfigPopup.ZIndex + 2,
			}, {
				Corner(4),
				Padding(0, 0, 8, 8),
			})
			table.insert(ConfigButtons, Option)

			Option.MouseButton1Click:Connect(function()
				ConfigLabel.Text = Name
				Library.Flags.Config = Name
				SetPopupVisible(ConfigPopup, false)
				if Options.OnConfig then
					task.spawn(Options.OnConfig, Name)
				end
			end)
		end
	end

	BuildConfigList()
	Library.Flags.Config = ConfigLabel.Text

	ConfigBox.MouseButton1Click:Connect(function()
		local Show = not ConfigPopup:GetAttribute("Open")
		ClosePopups(ConfigPopup)
		if Show then
			BuildConfigList()
			AnchorPopup(ConfigPopup, ConfigBox, 0, 4)
		end
		SetPopupVisible(ConfigPopup, Show)
	end)

	local SearchPopup = CreatePopup(300)
	Padding(10, 10, 10, 10).Parent = SearchPopup
	List(6).Parent = SearchPopup

	local SearchBox = New("Frame", {
		Parent = SearchPopup,
		BackgroundColor3 = Library.Theme.ControlDark,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 1,
		ClipsDescendants = true,
		ZIndex = SearchPopup.ZIndex + 1,
	}, {
		Corner(5),
		Stroke(Library.Theme.Border),
		Padding(0, 0, 10, 10),
	})

	local SearchInput = New("TextBox", {
		Parent = SearchBox,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		PlaceholderText = "Search settings...",
		PlaceholderColor3 = Library.Theme.Dim,
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = SearchPopup.ZIndex + 2,
	})

	local Results = New("ScrollingFrame", {
		Parent = SearchPopup,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		ZIndex = SearchPopup.ZIndex + 1,
	}, {
		List(3),
	})

	local ResultRows = {}

	local function RunSearch(Query)
		for _, Item in pairs(ResultRows) do
			Item:Destroy()
		end
		table.clear(ResultRows)

		Query = Query:lower():match("^%s*(.-)%s*$")
		local Matches = 0

		if Query ~= "" then
			for _, Entry in ipairs(Library.SearchIndex) do
				if Matches >= 8 then
					break
				end
				if Entry.Name:lower():find(Query, 1, true) then
					Matches += 1

					local Item = New("TextButton", {
						Parent = Results,
						BackgroundColor3 = Library.Theme.Control,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 30),
						LayoutOrder = Matches,
						Text = "",
						AutoButtonColor = false,
						ZIndex = SearchPopup.ZIndex + 2,
					}, {
						Corner(4),
					})

					New("TextLabel", {
						Parent = Item,
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(9, 3),
						Size = UDim2.new(1, -18, 0, 14),
						Text = Entry.Name,
						TextColor3 = Library.Theme.Text,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = SearchPopup.ZIndex + 3,
					})

					New("TextLabel", {
						Parent = Item,
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(9, 15),
						Size = UDim2.new(1, -18, 0, 12),
						Text = `{Entry.Tab.Name} - {Entry.Section} - {Entry.Kind}`,
						TextColor3 = Library.Theme.Dim,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = SearchPopup.ZIndex + 3,
					})

					table.insert(ResultRows, Item)

					Item.MouseEnter:Connect(function()
						Tween(Item, 0.1, { BackgroundTransparency = 0.85 })
					end)
					Item.MouseLeave:Connect(function()
						Tween(Item, 0.1, { BackgroundTransparency = 1 })
					end)
					Item.MouseButton1Click:Connect(function()
						SetPopupVisible(SearchPopup, false)
						Entry.Tab:Select()
						local Row = Entry.Row
						if Row and Row.Parent then
							local Flash = New("Frame", {
								Parent = Row,
								BackgroundColor3 = Library.Theme.Accent,
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 12, 1, 4),
								Position = UDim2.fromOffset(-6, -2),
								BorderSizePixel = 0,
								ZIndex = 0,
							}, {
								Corner(4),
							})
							Tween(Flash, 0.08, { BackgroundTransparency = 0.45 })
							task.delay(0.45, function()
								Tween(Flash, 0.2, { BackgroundTransparency = 1 })
								task.delay(0.25, function()
									Flash:Destroy()
								end)
							end)
						end
					end)
				end
			end
		end

		Results.Size = UDim2.new(1, 0, 0, math.min(Matches * 33, 200))
	end

	SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
		RunSearch(SearchInput.Text)
	end)

	local Actions = New("Frame", {
		Parent = Topbar,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -22, 0, 0),
		Size = UDim2.fromOffset(120, 62),
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 18),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function ShowAbout()
		local Modal = Library:Modal({ Title = `About {Options.Title or Library.Name}`, Width = 400 })
		Modal.Body:Label({
			Text = Options.About or `{Options.Title or Library.Name} is a Roblox UI library built for script menus.`,
			Color = Library.Theme.Text,
		})
		Modal.Body:Divider()
		Modal.Body:Label({ Text = `Press {Library.ToggleKey.Name} to show or hide the menu.` })
		Modal.Body:Label({ Text = "Gear icons next to a control open its extra settings." })
		Modal.Body:Label({ Text = "Configs and fonts are managed from the Settings tab." })
		Modal.Body:Divider()
		Modal.Body:Button({ Name = "Close", Callback = function()
			Modal:Close()
		end })
	end

	local DefaultActions = {
		{ Icon = "info", Callback = ShowAbout },
		{ Icon = "settings", Callback = function()
			for _, Tab in ipairs(Window.Tabs) do
				if Tab.Name == "Settings" then
					Tab:Select()
					return
				end
			end
			Library:Notify({ Title = Library.Name, Text = "No settings tab registered." })
		end },
		{ Icon = "search" },
	}

	for Index, Data in ipairs(Options.Actions or DefaultActions) do
		local Action = New("ImageButton", {
			Parent = Actions,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(18, 18),
			LayoutOrder = Index,
			Image = Icon(Data.Icon),
			ImageColor3 = Library.Theme.SubText,
		})
		Action.MouseEnter:Connect(function()
			Tween(Action, 0.12, { ImageColor3 = Library.Theme.Text })
		end)
		Action.MouseLeave:Connect(function()
			Tween(Action, 0.12, { ImageColor3 = Library.Theme.SubText })
		end)
		Action.MouseButton1Click:Connect(function()
			if Data.Icon == "search" then
				local Show = not SearchPopup:GetAttribute("Open")
				ClosePopups(Show and SearchPopup or nil)
				if Show then
					AnchorPopup(SearchPopup, Action, -282, 10)
					SearchInput.Text = ""
					RunSearch("")
				end
				SetPopupVisible(SearchPopup, Show)
				if Show then
					SearchInput:CaptureFocus()
				end
			elseif Data.Callback then
				task.spawn(Data.Callback)
			end
		end)
	end

	local Sidebar = New("Frame", {
		Parent = Main,
		BackgroundColor3 = Library.Theme.Sidebar,
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(0, 194, 1, -62),
		BorderSizePixel = 0,
	}, {
		Corner(8),
	})

	New("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Library.Theme.Sidebar,
		Size = UDim2.new(1, 0, 0, 10),
		BorderSizePixel = 0,
	})

	New("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Library.Theme.Sidebar,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 10, 1, 0),
		BorderSizePixel = 0,
	})

	New("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Library.Theme.Border,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 4,
	})

	local UserCard = New("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Library.Theme.Topbar,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 56),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, {
		Corner(8),
	})

	New("Frame", {
		Parent = UserCard,
		BackgroundColor3 = Library.Theme.Topbar,
		Size = UDim2.new(1, 0, 0, 10),
		BorderSizePixel = 0,
		ZIndex = 2,
	})

	New("Frame", {
		Parent = UserCard,
		BackgroundColor3 = Library.Theme.Topbar,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.fromOffset(10, 10),
		BorderSizePixel = 0,
		ZIndex = 2,
	})

	local Avatar = New("ImageLabel", {
		Parent = UserCard,
		BackgroundColor3 = Library.Theme.Control,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		Image = "",
		ZIndex = 3,
	}, {
		Corner(16),
	})

	pcall(function()
		Avatar.Image = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)

	New("TextLabel", {
		Parent = UserCard,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(56, 10),
		Size = UDim2.new(1, -66, 0, 18),
		Text = Options.User or Players.LocalPlayer.Name,
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	})

	local SubtitleTemplate = Options.Subtitle or "Till: {accent}lifetime{/accent}"

	local Subtitle = New("TextLabel", {
		Parent = UserCard,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(56, 28),
		Size = UDim2.new(1, -66, 0, 16),
		Text = "",
		TextColor3 = Library.Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = true,
		ZIndex = 3,
	})

	local function RenderSubtitle()
		local Color = Library.Theme.Accent
		local Hex = string.format("%02X%02X%02X", Color.R * 255, Color.G * 255, Color.B * 255)
		Subtitle.Text = SubtitleTemplate:gsub("{accent}", `<font color="#{Hex}">`):gsub("{/accent}", "</font>")
	end

	RenderSubtitle()
	OnAccent(RenderSubtitle)

	local TabScroller = New("ScrollingFrame", {
		Parent = Sidebar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, 0, 1, -70),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = Library.Theme.Control,
		BorderSizePixel = 0,
	}, {
		List(2),
		Padding(4, 12, 10, 10),
	})

	local Content = New("Frame", {
		Parent = Main,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(194, 62),
		Size = UDim2.new(1, -194, 1, -62),
	})

	local Highlight = MarkAccent(New("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Library.Theme.Accent,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0, 0),
		Size = UDim2.fromOffset(3, 0),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 4,
	}, {
		Corner(2),
		Shade(0.2),
	}))

	local ActiveTab = nil

	function Window:MoveHighlight(Tab, Animate)
		local Button = Tab.Button
		local Center = Button.AbsolutePosition.Y + Button.AbsoluteSize.Y / 2 - Sidebar.AbsolutePosition.Y
		local Top = TabScroller.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y
		local Bottom = Top + TabScroller.AbsoluteSize.Y
		local Visible = Center >= Top and Center <= Bottom

		Highlight.Visible = Visible
		if not Visible then
			return
		end

		local Goal = UDim2.new(0, 3, 0, Center)
		if Animate then
			Tween(Highlight, 0.18, { Position = Goal, Size = UDim2.fromOffset(3, 20) })
		else
			Highlight.Position = Goal
			Highlight.Size = UDim2.fromOffset(3, 20)
		end
	end

	local function CreateGroupLabel(Name)
		local Label = New("TextLabel", {
			Parent = TabScroller,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			Text = Name,
			TextColor3 = Library.Theme.Dim,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = #TabScroller:GetChildren(),
		}, {
			Padding(8, 0, 8, 0),
		})
		Window.Groups[Name] = true
		return Label
	end

	function Window:Tab(TabOptions)
		TabOptions = TabOptions or {}

		if TabOptions.Group and not Window.Groups[TabOptions.Group] then
			CreateGroupLabel(TabOptions.Group)
		end

		local Button = New("TextButton", {
			Parent = TabScroller,
			BackgroundColor3 = Library.Theme.Section,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 32),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = #TabScroller:GetChildren(),
		}, {
			Corner(5),
			Shade(0.12),
		})

		local TabIcon = New("ImageLabel", {
			Parent = Button,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Image = Icon(TabOptions.Icon or "circle"),
			ImageColor3 = Library.Theme.SubText,
		})

		local TabLabel = New("TextLabel", {
			Parent = Button,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -42, 1, 0),
			Text = TabOptions.Name or "Tab",
			TextColor3 = Library.Theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local Page = New("Frame", {
			Parent = Content,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 0),
			Size = UDim2.new(1, -36, 1, 0),
			Visible = false,
		})

		local function BuildColumns(Holder, Top)
			local Made = {}
			for Side = 1, 2 do
				Made[Side] = New("ScrollingFrame", {
					Parent = Holder,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.5 * (Side - 1), Side == 1 and 0 or 7, 0, Top),
					Size = UDim2.new(0.5, -7, 1, -(Top + 10)),
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 0,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					BorderSizePixel = 0,
					ClipsDescendants = true,
				}, {
					List(14),
					Padding(2, 16, 2, 2),
				})
			end
			return Made
		end

		local Columns = BuildColumns(Page, 16)

		local Tab = { Button = Button, Page = Page, Name = TabOptions.Name or "Tab" }

		function Tab:Select()
			if ActiveTab == Tab then
				return
			end
			if ActiveTab then
				ActiveTab.Page.Visible = false
				Tween(ActiveTab.Button, 0.15, { BackgroundTransparency = 1 })
				Tween(ActiveTab.Icon, 0.15, { ImageColor3 = Library.Theme.SubText })
				Tween(ActiveTab.Label, 0.15, { TextColor3 = Library.Theme.SubText })
			end
			ActiveTab = Tab
			Page.Visible = true
			Tween(Button, 0.15, { BackgroundTransparency = 0 })
			Tween(TabIcon, 0.15, { ImageColor3 = Library.Theme.Accent })
			Tween(TabLabel, 0.15, { TextColor3 = Library.Theme.Text })
			Window:MoveHighlight(Tab, Highlight.Visible)
		end

		Tab.Icon = TabIcon
		Tab.Label = TabLabel

		OnAccent(function(Color)
			if ActiveTab == Tab then
				Tween(TabIcon, 0.12, { ImageColor3 = Color })
			end
		end)

		Button.MouseEnter:Connect(function()
			if ActiveTab ~= Tab then
				Tween(TabLabel, 0.12, { TextColor3 = Library.Theme.Text })
			end
		end)
		Button.MouseLeave:Connect(function()
			if ActiveTab ~= Tab then
				Tween(TabLabel, 0.12, { TextColor3 = Library.Theme.SubText })
			end
		end)
		Button.MouseButton1Click:Connect(function()
			Tab:Select()
		end)

		local function MakeSection(TargetColumns, Owner, SectionOptions)
			SectionOptions = typeof(SectionOptions) == "table" and SectionOptions or { Name = SectionOptions }
			local Column = TargetColumns[SectionOptions.Side == "Right" and 2 or 1]

			local Section = New("Frame", {
				Parent = Column,
				BackgroundColor3 = Library.Theme.Section,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, {
				Corner(6),
				Stroke(Library.Theme.Border),
				List(0),
			})

			local Header = New("Frame", {
				Parent = Section,
				BackgroundColor3 = Library.Theme.SectionHeader,
				Size = UDim2.new(1, 0, 0, 34),
				LayoutOrder = 1,
			}, {
				Corner(6),
			})

			New("Frame", {
				Parent = Header,
				BackgroundColor3 = Library.Theme.SectionHeader,
				Position = UDim2.new(0, 0, 1, -8),
				Size = UDim2.new(1, 0, 0, 8),
				BorderSizePixel = 0,
			})

			New("Frame", {
				Parent = Header,
				BackgroundColor3 = Library.Theme.Border,
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				ZIndex = 2,
			})

			New("TextLabel", {
				Parent = Header,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -24, 1, 0),
				Text = SectionOptions.Name or "Section",
				TextColor3 = Library.Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local Body = New("Frame", {
				Parent = Section,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
			}, {
				List(6),
				Padding(12, 14, 14, 14),
			})

			local Container = CreateContainer(Body, 340)
			Container.Tab = Owner
			Container.Section = SectionOptions.Name or "Section"
			return Container
		end

		function Tab:Section(SectionOptions)
			return MakeSection(Columns, Tab, SectionOptions)
		end

		local SubBar, SubPages, ActiveSub = nil, {}, nil

		function Tab:SubPage(SubOptions)
			SubOptions = typeof(SubOptions) == "table" and SubOptions or { Name = SubOptions }

			if not SubBar then
				Columns[1].Visible = false
				Columns[2].Visible = false

				SubBar = New("Frame", {
					Parent = Page,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 34),
					Position = UDim2.fromOffset(0, 8),
				}, {
					List(6, Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center),
				})

				New("Frame", {
					Parent = Page,
					BackgroundColor3 = Library.Theme.Border,
					Position = UDim2.fromOffset(0, 43),
					Size = UDim2.new(1, 0, 0, 1),
					BorderSizePixel = 0,
				})
			end

			local Holder = New("Frame", {
				Parent = Page,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 52),
				Size = UDim2.new(1, 0, 1, -52),
				Visible = false,
			})

			local Button = New("TextButton", {
				Parent = SubBar,
				BackgroundColor3 = Library.Theme.Section,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(0, 28),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = #SubPages + 1,
			}, {
				Corner(5),
				Shade(0.12),
				Padding(0, 0, 10, 12),
				List(6, Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center),
			})

			local SubIcon = New("ImageLabel", {
				Parent = Button,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(15, 15),
				Image = Icon(SubOptions.Icon or "circle"),
				ImageColor3 = Library.Theme.SubText,
				LayoutOrder = 1,
			})

			local SubLabel = New("TextLabel", {
				Parent = Button,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(0, 28),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = SubOptions.Name or "Page",
				TextColor3 = Library.Theme.SubText,
				TextSize = 13,
				LayoutOrder = 2,
			})

			local SubColumns = BuildColumns(Holder, 0)

			local Sub = {
				Name = SubOptions.Name or "Page",
				Button = Button,
				Holder = Holder,
			}

			function Sub:Select()
				if ActiveSub == Sub then
					return
				end
				if ActiveSub then
					ActiveSub.Holder.Visible = false
					Tween(ActiveSub.Button, 0.15, { BackgroundTransparency = 1 })
					Tween(ActiveSub.Icon, 0.15, { ImageColor3 = Library.Theme.SubText })
					Tween(ActiveSub.Label, 0.15, { TextColor3 = Library.Theme.SubText })
				end
				ActiveSub = Sub
				Holder.Visible = true
				Tween(Button, 0.15, { BackgroundTransparency = 0 })
				Tween(SubIcon, 0.15, { ImageColor3 = Library.Theme.Accent })
				Tween(SubLabel, 0.15, { TextColor3 = Library.Theme.Text })
			end

			function Sub:Section(SectionOptions)
				return MakeSection(SubColumns, Tab, SectionOptions)
			end

			function Sub:Grid(GridOptions)
				GridOptions = GridOptions or {}

				SubColumns[1].Visible = false
				SubColumns[2].Visible = false

				local PerRow = GridOptions.Columns or 3
				local Gap = GridOptions.Gap or 10
				local Inset = GridOptions.Inset or 3

				local GridLayout = New("UIGridLayout", {
					CellSize = UDim2.fromOffset(100, GridOptions.Height or 132),
					CellPadding = UDim2.fromOffset(Gap, Gap),
					SortOrder = Enum.SortOrder.LayoutOrder,
				})

				local Scroller = New("ScrollingFrame", {
					Parent = Holder,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 6),
					Size = UDim2.new(1, 0, 1, -16),
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 0,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					BorderSizePixel = 0,
					ClipsDescendants = true,
				}, {
					GridLayout,
					Padding(Inset, 16, Inset, Inset),
				})

				local function Resize()
					local Usable = Scroller.AbsoluteSize.X - (Inset * 2) - (Gap * (PerRow - 1))
					if Usable <= 0 then
						return
					end
					GridLayout.CellSize = UDim2.fromOffset(math.floor(Usable / PerRow), GridOptions.Height or 132)
				end

				Resize()
				task.defer(Resize)
				Connect(Scroller:GetPropertyChangedSignal("AbsoluteSize"), Resize)

				local Grid = { Frame = Scroller, Tiles = {} }
				local Selected = nil

				function Grid:Clear()
					for _, Tile in pairs(Grid.Tiles) do
						Tile.Frame:Destroy()
					end
					table.clear(Grid.Tiles)
					Selected = nil
				end

				function Grid:Add(Data)
					setthreadidentity(8)
					local Frame = New("TextButton", {
						Parent = Scroller,
						BackgroundColor3 = Library.Theme.Section,
						Text = "",
						AutoButtonColor = false,
						LayoutOrder = Data.Order or (#Grid.Tiles + 1),
						ClipsDescendants = true,
					}, {
						Corner(6),
						Stroke(Library.Theme.Border),
						Shade(0.13),
					})

					local Image = New("ImageLabel", {
						Parent = Frame,
						BackgroundColor3 = Library.Theme.ControlDark,
						Position = UDim2.fromOffset(6, 6),
						Size = UDim2.new(1, -12, 1, -34),
						Image = Data.Image or "",
						ScaleType = Enum.ScaleType.Fit,
					}, {
						Corner(4),
					})

					local Viewport = nil
					local Model = Data.Model

					if Model or Data.Build then
						Viewport = New("ViewportFrame", {
							Parent = Image,
							BackgroundTransparency = 1,
							Size = UDim2.fromScale(1, 1),
							Ambient = Color3.fromRGB(200, 200, 200),
							LightColor = Color3.fromRGB(255, 255, 255),
							LightDirection = Vector3.new(-0.4, -1, -0.6),
						}, {
							Corner(4),
						})

						local Camera = New("Camera", { Parent = Viewport })
						Viewport.CurrentCamera = Camera

						if Data.Build then
							Model = Data.Build(Viewport)
						elseif Model then
							Model.Parent = Viewport
						end

						if Model then
							local Framed = pcall(function()
								local Box, Extent = Model:GetBoundingBox()
								local Radius = math.max(Extent.Magnitude, 2)
								local Distance = Radius * (Data.Zoom or 0.2)
								Camera.CFrame = CFrame.new(
									Box.Position + Vector3.new(Distance, Distance * 0.4, Distance),
									Box.Position
								)
							end)

							if not Framed then
								local Origin = nil
								for _, Part in ipairs(Model:GetDescendants()) do
									if Part:IsA("BasePart") then
										Origin = Part.Position
										break
									end
								end
								Origin = Origin or Vector3.zero
								Camera.CFrame = CFrame.new(Origin + Vector3.new(4, 0, 4), Origin)
							end

							Model:PivotTo(Model:GetPivot() * CFrame.Angles(0, math.rad(110), 0))
						else
							Viewport:Destroy()
							Viewport = nil
						end
					end

					if not Viewport and not Data.Image then
						New("ImageLabel", {
							Parent = Image,
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(22, 22),
							Image = Icon(Data.Placeholder or "ban"),
							ImageColor3 = Library.Theme.Dim,
						})
					end

					New("TextLabel", {
						Parent = Frame,
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.new(0, 7, 1, -7),
						Size = UDim2.new(1, -14, 0, 15),
						Text = Data.Name or "Item",
						TextColor3 = Library.Theme.Text,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
					})

					local Border = Frame:FindFirstChildOfClass("UIStroke")

					local Tile = { Frame = Frame, Image = Image, Viewport = Viewport, Border = Border, Name = Data.Name, Value = Data.Value, Group = Data.Group }

					local Active = false

					function Tile:SetActive(State, Force)
						State = State and true or false
						if Active == State and not Force then
							return
						end
						Active = State
						Tween(Border, 0.12, { Color = State and Library.Theme.Accent or Library.Theme.Border })
						Tween(Frame, 0.12, { BackgroundColor3 = State and Library.Theme.SectionHeader or Library.Theme.Section })
					end

					Frame.MouseEnter:Connect(function()
						if Selected ~= Tile then
							Tween(Frame, 0.1, { BackgroundColor3 = Library.Theme.SectionHeader })
						end
					end)
					Frame.MouseLeave:Connect(function()
						if Selected ~= Tile then
							Tween(Frame, 0.1, { BackgroundColor3 = Library.Theme.Section })
						end
					end)
					Frame.MouseButton1Click:Connect(function()
						Grid:Select(Tile.Value)
						if GridOptions.Callback then
							task.spawn(GridOptions.Callback, Tile.Value, Tile.Name)
						end
					end)

					table.insert(Grid.Tiles, Tile)
					return Tile
				end

				function Grid:Select(Value)
					Selected = nil
					for _, Tile in pairs(Grid.Tiles) do
						local Match = Tile.Value == Value
						Tile:SetActive(Match)
						if Match then
							Selected = Tile
						end
					end
				end

				function Grid:Filter(Group)
					for _, Tile in pairs(Grid.Tiles) do
						local Visible = Group == nil or Tile.Group == nil or Tile.Group == Group
						if Tile.Frame.Visible ~= Visible then
							Tile.Frame.Visible = Visible
						end
					end
				end

				OnAccent(function()
					if Selected then
						Selected:SetActive(true, true)
					end
				end)

				return Grid
			end

			Sub.Icon = SubIcon
			Sub.Label = SubLabel

			OnAccent(function(Color)
				if ActiveSub == Sub then
					Tween(SubIcon, 0.12, { ImageColor3 = Color })
				end
			end)

			Button.MouseEnter:Connect(function()
				if ActiveSub ~= Sub then
					Tween(SubLabel, 0.12, { TextColor3 = Library.Theme.Text })
				end
			end)
			Button.MouseLeave:Connect(function()
				if ActiveSub ~= Sub then
					Tween(SubLabel, 0.12, { TextColor3 = Library.Theme.SubText })
				end
			end)
			Button.MouseButton1Click:Connect(function()
				ClosePopups()
				Sub:Select()
			end)

			table.insert(SubPages, Sub)
			if #SubPages == 1 then
				Sub:Select()
			end

			return Sub
		end

		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then
			task.defer(function()
				Tab:Select()
			end)
		end

		return Tab
	end

	function Window:SetSubtitle(Text)
		SubtitleTemplate = Text
		RenderSubtitle()
	end

	function Window:Select(Index)
		if Window.Tabs[Index] then
			Window.Tabs[Index]:Select()
		end
	end

	Connect(TabScroller:GetPropertyChangedSignal("CanvasPosition"), function()
		if ActiveTab then
			Window:MoveHighlight(ActiveTab, false)
		end
	end)

	Library.CurrentWindow = Window
	return Window
end

local function Encode(Value)
	local Kind = typeof(Value)
	if Kind == "Color3" then
		return { __type = "Color3", R = Value.R, G = Value.G, B = Value.B }
	elseif Kind == "EnumItem" then
		return { __type = "KeyCode", Name = Value.Name }
	elseif Kind == "table" then
		local Copy = {}
		for Index, Item in pairs(Value) do
			Copy[Index] = Encode(Item)
		end
		return Copy
	end
	return Value
end

local function Decode(Value)
	if typeof(Value) ~= "table" then
		return Value
	end
	if Value.__type == "Color3" then
		return Color3.new(Value.R, Value.G, Value.B)
	elseif Value.__type == "KeyCode" then
		return Enum.KeyCode[Value.Name]
	end
	local Copy = {}
	for Index, Item in pairs(Value) do
		Copy[Index] = Decode(Item)
	end
	return Copy
end

local function ConfigPath(Name)
	return `{Library.Folders.Configs}/{Name}.json`
end

function Library:ListConfigs()
	local Names = {}
	pcall(function()
		for _, File in ipairs(listfiles(Library.Folders.Configs)) do
			local Name = File:match("([^\\/]+)%.json$")
			if Name then
				table.insert(Names, Name)
			end
		end
	end)
	table.sort(Names)
	return Names
end

function Library:SaveConfig(Name)
	if not Name or Name == "" then
		Library:Notify({ Title = "Config", Text = "Enter a config name first." })
		return false
	end

	local Data = {}
	for Flag, Value in pairs(Library.Flags) do
		Data[Flag] = Encode(Value)
	end

	local Success = pcall(function()
		writefile(ConfigPath(Name), HttpService:JSONEncode(Data))
	end)

	Library:Notify({
		Title = "Config",
		Text = Success and `Saved "{Name}".` or `Failed to save "{Name}".`,
	})
	return Success
end

function Library:LoadConfig(Name)
	if not Name or Name == "" then
		Library:Notify({ Title = "Config", Text = "Select a config first." })
		return false
	end

	local Success, Data = pcall(function()
		return HttpService:JSONDecode(readfile(ConfigPath(Name)))
	end)

	if not Success or typeof(Data) ~= "table" then
		Library:Notify({ Title = "Config", Text = `Failed to load "{Name}".` })
		return false
	end

	local Decoded = {}
	for Flag, Raw in pairs(Data) do
		Decoded[Flag] = Decode(Raw)
	end

	for _, Flag in ipairs({ "LibraryAccent", "Accent" }) do
		local Color = Decoded[Flag]
		if typeof(Color) == "Color3" then
			Library:SetAccent(Color)
			break
		end
	end

	local Applied = 0
	for Flag, Value in pairs(Decoded) do
		local Entry = Library.Elements[Flag]
		if Entry and Entry.Element.Set then
			pcall(function()
				Entry.Element:Set(Value)
				Applied += 1
			end)
		else
			Library.Flags[Flag] = Value
		end
	end

	Library:Notify({ Title = "Config", Text = `Loaded "{Name}" ({Applied} settings).` })
	return true
end

function Library:DeleteConfig(Name)
	if not Name or Name == "" then
		Library:Notify({ Title = "Config", Text = "Select a config first." })
		return false
	end

	local Success = pcall(function()
		delfile(ConfigPath(Name))
	end)

	Library:Notify({
		Title = "Config",
		Text = Success and `Deleted "{Name}".` or `Failed to delete "{Name}".`,
	})
	return Success
end

function Library:CreateDefaultConfigs(Names)
	local Created = {}
	for _, Name in ipairs(Names or { "Default" }) do
		if not isfile(ConfigPath(Name)) then
			local Data = {}
			for Flag, Value in pairs(Library.Flags) do
				Data[Flag] = Encode(Value)
			end
			local Success = pcall(function()
				writefile(ConfigPath(Name), HttpService:JSONEncode(Data))
			end)
			if Success then
				table.insert(Created, Name)
			end
		end
	end

	if #Created > 0 then
		Library:Notify({ Title = "Config", Text = `Created defaults: {table.concat(Created, ", ")}.` })
	end
	return Created
end

function Library:Settings(Options)
	Options = Options or {}
	local Window = Options.Window or Library.CurrentWindow
	if not Window then
		return nil
	end

	local Tab = Window:Tab({
		Name = Options.Name or "Settings",
		Icon = Options.Icon or "sliders-horizontal",
		Group = Options.Group or "Library",
	})

	local Appearance = Tab:Section({ Name = "Appearance", Side = "Left" })

	Appearance:ColorPicker({
		Name = "Accent Color",
		Default = Library.Theme.Accent,
		Flag = "LibraryAccent",
		Callback = function(Color)
			Library:SetAccent(Color)
		end,
	})

	local SelectedWeight = "Regular"
	local CurrentFamily = "Inter"

	local function ApplyFont(Family, Weight)
		if not Family or Family == "" then
			return
		end
		task.spawn(function()
			local Loaded = Library:LoadGoogleFontByName(Family, Weight)
			if Loaded then
				CurrentFamily = Family
				Library:Notify({ Title = "Font", Text = `Loaded {Family} {Weight}.` })
			else
				Library:Notify({ Title = "Font", Text = `{Family} {Weight} unavailable.` })
			end
		end)
	end

	Appearance:Dropdown({
		Name = "Weight",
		Items = { "Thin", "ExtraLight", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Black" },
		Default = "Regular",
		Flag = "LibraryFontWeight",
		Callback = function(Weight)
			SelectedWeight = Weight
			if CurrentFamily then
				ApplyFont(CurrentFamily, Weight)
			end
		end,
	})

	Appearance:TextBox({
		Name = "Font Name",
		Placeholder = "Source Sans",
		Flag = "LibraryFontName",
		Callback = function(Text)
			ApplyFont(Text, SelectedWeight)
		end,
	})

	Appearance:TextBox({
		Name = "Font URL",
		Placeholder = "paste fonts.googleapis.com url",
		Flag = "LibraryFontUrl",
		Callback = function(Text)
			if not Text:find("https") then
				return
			end

			local Family = Text:match("family=([^:&]+)")
			if Family then
				Family = (Family:gsub("%+", " "))
			end

			task.spawn(function()
				local Loaded = Library:LoadGoogleFont(Text, Family, SelectedWeight)
				if Loaded then
					CurrentFamily = Family
					Library:Notify({
						Title = "Font",
						Text = Family and `Loaded {Family}.` or "Font loaded.",
					})
				else
					Library:Notify({ Title = "Font", Text = "Failed to load font." })
				end
			end)
		end,
	})

	Appearance:Button({
		Name = "Reset Font",
		Callback = function()
			Library:SetFont(Library.DefaultFont)
			CurrentFamily = nil
			Library:Notify({ Title = "Font", Text = "Reset to default font." })
		end,
	})

	Appearance:Dropdown({
		Name = "Font Preset",
		Items = { "Archivo Black", "Bebas Neue", "JetBrains Mono", "Poppins", "Roboto" },
		Flag = "LibraryFontPreset",
		Callback = function(Name)
			ApplyFont(Name, SelectedWeight)
		end,
	})

	local ConfigSection = Tab:Section({ Name = "Configs", Side = "Right" })

	local Selected = nil
	local ConfigList

	ConfigList = ConfigSection:Dropdown({
		Name = "Config",
		Items = Library:ListConfigs(),
		Placeholder = "none",
		Flag = "LibraryConfig",
		Callback = function(Name)
			Selected = Name
		end,
	})

	local NameBox = ConfigSection:TextBox({
		Name = "Name",
		Placeholder = "new config",
		Flag = "LibraryConfigName",
	})

	local function RefreshList()
		ConfigList:SetItems(Library:ListConfigs())
	end

	ConfigSection:Button({
		Name = "Create",
		Callback = function()
			local Name = NameBox:Get()
			if Library:SaveConfig(Name) then
				Selected = Name
				RefreshList()
				ConfigList:Set(Name, true)
			end
		end,
	})

	ConfigSection:Button({
		Name = "Save",
		Callback = function()
			if Library:SaveConfig(Selected) then
				RefreshList()
			end
		end,
	})

	ConfigSection:Button({
		Name = "Load",
		Callback = function()
			Library:LoadConfig(Selected)
		end,
	})

	ConfigSection:Button({
		Name = "Delete",
		Callback = function()
			if Library:DeleteConfig(Selected) then
				Selected = nil
				RefreshList()
			end
		end,
	})

	ConfigSection:Button({
		Name = "Refresh List",
		Callback = function()
			RefreshList()
			Library:Notify({ Title = "Config", Text = "Config list refreshed." })
		end,
	})

	local Menu = Tab:Section({ Name = "Menu", Side = "Right" })

	Menu:Keybind({
		Name = "Toggle Key",
		Default = Library.ToggleKey,
		Flag = "LibraryToggleKey",
		Callback = function(Key)
			if Key then
				Library.ToggleKey = Key
			end
		end,
	})

	Menu:Toggle({
		Name = "Keybind List",
		Default = true,
		Flag = "LibraryKeybindList",
		Callback = function(State)
			Library:ToggleKeybindList(State)
		end,
	})

	Menu:Button({
		Name = "Unload Library",
		Callback = function()
			Library:Unload()
		end,
	})

	return Tab
end

function Library:Cosmetics(Options)
	Options = Options or {}
	local Window = Options.Window or Library.CurrentWindow
	if not Window then
		return nil
	end

	local Tab = Window:Tab({
		Name = Options.Name or "Cosmetics",
		Icon = Options.Icon or "sparkles",
		Group = Options.Group or "Miscellaneous",
	})

	local Pages = {
		General = Tab:SubPage({ Name = "General", Icon = "layout-grid" }),
		Skin = Tab:SubPage({ Name = "Skins", Icon = "spray-can" }),
		Wrap = Tab:SubPage({ Name = "Wraps", Icon = "layers" }),
		Charm = Tab:SubPage({ Name = "Charms", Icon = "gem" }),
		Finisher = Tab:SubPage({ Name = "Finishers", Icon = "swords" }),
	}

	local Weapons = {}
	local Catalogue = { Skin = {}, Wrap = {}, Charm = {}, Finisher = {} }

	for Name, Data in next, CosmeticLibrary.Cosmetics do
		if Data.ItemName and not table.find(Weapons, Data.ItemName) then
			table.insert(Weapons, Data.ItemName)
		end
		if Catalogue[Data.Type] then
			table.insert(Catalogue[Data.Type], { Name = Name, Data = Data })
		end
	end

	table.sort(Weapons)

	for _, Entries in pairs(Catalogue) do
		table.sort(Entries, function(A, B)
			return A.Name < B.Name
		end)
	end

	if #Weapons == 0 then
		Weapons = { "None" }
	end

	local CurrentWeapon = Weapons[1]

	local Equipped = {}
	for _, Weapon in ipairs(Weapons) do
		Equipped[Weapon] = { Skin = nil, Wrap = nil, Charm = nil, Finisher = nil }
	end

	local Grids = {}

	local Builders = {
		Wrap = BuildWrapModel,
		Charm = BuildCharmModel,
	}

	local Zooms = { Charm = 0.1 }

	local function BuildGrid(Kind, PerWeapon)
		setthreadidentity(8)

		local Grid = Pages[Kind]:Grid({
			Callback = function(Value)
				Equipped[CurrentWeapon][Kind] = Value
				if Options.OnEquip then
					task.spawn(Options.OnEquip, CurrentWeapon, Kind, Value)
				end
				Library:Notify({
					Title = Kind,
					Text = Value and `{CurrentWeapon}: {Value}` or `{CurrentWeapon}: none`,
				})
			end,
		})

		Grid:Add({ Name = "None", Value = nil, Order = 0 })

		for Index, Item in ipairs(Catalogue[Kind]) do
			local Name = Item.Name
			local Make = Builders[Kind]
			Grid:Add({
				Name = Name,
				Value = Name,
				Image = not Make and (Item.Data.ImageHighResolution or Item.Data.Image) or nil,
				Build = Make and function(Viewport)
					return Make(Name, Viewport)
				end or nil,
				Group = PerWeapon and Item.Data.ItemName or nil,
				Zoom = Zooms[Kind],
				Order = Index,
			})
		end

		Grids[Kind] = { Grid = Grid, PerWeapon = PerWeapon }
		return Grid
	end

	BuildGrid("Skin", true)
	BuildGrid("Wrap", false)
	BuildGrid("Charm", false)
	BuildGrid("Finisher", false)

	local function SyncGrids()
		for Kind, Entry in pairs(Grids) do
			if Entry.PerWeapon then
				Entry.Grid:Filter(CurrentWeapon)
			end
			Entry.Grid:Select(Equipped[CurrentWeapon][Kind])
		end
	end

	local General = Pages.General:Section({ Name = "General", Side = "Left" })

	General:Toggle({
		Name = "Enabled",
		Default = true,
		Flag = "CosmeticsEnabled",
	})

	General:Dropdown({
		Name = "Weapon",
		Items = Weapons,
		Default = CurrentWeapon,
		Flag = "CosmeticsWeapon",
		Callback = function(Weapon)
			CurrentWeapon = Weapon
			SyncGrids()
		end,
	})

	SyncGrids()

	Tab.Weapons = Weapons
	Tab.Equipped = Equipped
	Tab.Pages = Pages

	function Tab:GetEquipped(Weapon)
		return Equipped[Weapon or CurrentWeapon]
	end

	return Tab
end

getgenv().Library = Library
return Library
