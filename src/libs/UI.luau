--[[
    This is a modified version of Linoria Library, credits to them.
]]

local clonerefFunction = cloneref or clone_ref or clonereference or clone_reference
local ns__cloneref = clonerefFunction and function(Object)
	local Success, Result = pcall(clonerefFunction, Object)
	return Success and Result or Object
end or function(Object)
    return Object
end

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = ns__cloneref(game:GetService("CoreGui"))
local Players = game:GetService("Players")

local PreRender = RunService.PreRender
local Heartbeat = RunService.Heartbeat

local LocalPlayer = Players.LocalPlayer
local Mouse = ns__cloneref(LocalPlayer:GetMouse())
local Camera = workspace.CurrentCamera

local ScreenGui = ns__cloneref(Instance.new("ScreenGui"))
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Enabled = false
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}

local Library = {
    Toggled = true,
    OptimizedDragging = false,

    Toggles = Toggles,
    Options = Options,

    FontColor = Color3.fromRGB(255, 255, 255),
    MainColor = Color3.fromRGB(28, 28, 28),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    AccentColor = Color3.fromRGB(127, 0, 255),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0),
    Font = Enum.Font.Code,

    OpenedFrames = {},
    DependencyBoxes = {},

    ScreenGui = ScreenGui
}

local UITweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ToggleTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local UIPropertyTweens = setmetatable({}, {__mode = 'k'})

local function TweenGuiProperty(Instance, Property, Target, TweenInfoOverride)
    local PropertyTweens = UIPropertyTweens[Instance]
    if not PropertyTweens then
        PropertyTweens = {}
        UIPropertyTweens[Instance] = PropertyTweens
    end

    local CurrentTween = PropertyTweens[Property]
    if CurrentTween and CurrentTween.Target == Target then
        return
    end

    if CurrentTween then
        CurrentTween.Tween:Cancel()
    end

    if Instance[Property] == Target then
        PropertyTweens[Property] = nil
        return
    end

    local Tween = TweenService:Create(Instance, TweenInfoOverride or UITweenInfo, {[Property] = Target})
    local TweenState = {Tween = Tween, Target = Target}
    PropertyTweens[Property] = TweenState
    Tween.Completed:Connect(function()
        if PropertyTweens[Property] == TweenState then
            PropertyTweens[Property] = nil
        end
    end)
    Tween:Play()
end

function Library:SafeCallback(Function, ...)
    if Function then
        return Function(...)
    end
end

function Library:Create(Class, Properties)
    local _Instance = Class
    if type(Class) == "string" then
        _Instance = ns__cloneref(Instance.new(Class))
    end
    for Property, Value in next, Properties do
        _Instance[Property] = Value
    end
    return _Instance
end

function Library:CreateLocalTextPopup(Title, Placeholder, Action, MultiLine, Callback)
    local Popup = {}
    local Frame = self:Create("Frame", {
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.BackgroundColor,
        BorderColor3 = self.OutlineColor,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = MultiLine and UDim2.fromOffset(560, 360) or UDim2.fromOffset(320, 112),
        Visible = false,
        ZIndex = 12000,
        Parent = ScreenGui
    })
    self:Create("Frame", {
        BackgroundColor3 = self.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 12001,
        Parent = Frame
    })
    Popup.Title = self:CreateLabel({
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -20, 0, MultiLine and 40 or 20),
        TextWrapped = MultiLine,
        Text = Title,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12002,
        Parent = Frame
    })
    local InputParent = Frame
    if MultiLine then
        InputParent = self:Create("ScrollingFrame", {
            BackgroundColor3 = self.MainColor,
            BorderColor3 = self.OutlineColor,
            Position = UDim2.fromOffset(10, 55),
            Size = UDim2.new(1, -20, 1, -97),
            CanvasSize = UDim2.fromOffset(0, 0),
            ClipsDescendants = true,
            ScrollBarThickness = 4,
            ZIndex = 12002,
            Parent = Frame
        })
    end
    Popup.Input = self:Create("TextBox", {
        BackgroundColor3 = self.MainColor,
        BackgroundTransparency = MultiLine and 1 or 0,
        BorderColor3 = self.OutlineColor,
        BorderSizePixel = MultiLine and 0 or 1,
        Position = MultiLine and UDim2.fromOffset(4, 4) or UDim2.fromOffset(10, 35),
        Size = MultiLine and UDim2.new(1, -14, 1, -8) or UDim2.new(1, -20, 0, 26),
        ClearTextOnFocus = false,
        MultiLine = MultiLine,
        TextWrapped = MultiLine,
        PlaceholderText = Placeholder,
        Text = "",
        TextColor3 = self.FontColor,
        TextSize = 13,
        Font = self.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        ZIndex = 12003,
        Parent = InputParent
    })
    if MultiLine then
        local function ResizeInput()
            local Height = TextService:GetTextSize(Popup.Input.Text, 13, Popup.Input.Font, Vector2.new(math.max(1, InputParent.AbsoluteSize.X - 14), math.huge)).Y + 8
            Popup.Input.Size = UDim2.new(1, -14, 0, math.max(26, InputParent.AbsoluteSize.Y - 8, Height))
            InputParent.CanvasSize = UDim2.fromOffset(0, Height + 8)
        end
        Popup.Input:GetPropertyChangedSignal("Text"):Connect(ResizeInput)
        InputParent:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeInput)
    end
    function Popup:Hide()
        self.Input:ReleaseFocus()
        Frame.Visible = false
        Library.OpenedFrames[Frame] = nil
    end
    function Popup:Show(Text)
        local Focused = UserInputService:GetFocusedTextBox()
        if Focused then
            Focused:ReleaseFocus()
        end
        self.Input.Text = Text or ""
        Frame.Visible = true
        Library.OpenedFrames[Frame] = Frame
        self.Input:CaptureFocus()
    end
    local function Submit()
        if Callback(Popup.Input.Text) then
            Popup:Hide()
        end
    end
    local Buttons = {Action}
    if MultiLine and setclipboard then
        Buttons[#Buttons + 1] = "Copy"
    end
    Buttons[#Buttons + 1] = "Cancel"
    for Index, Text in ipairs(Buttons) do
        local Button = self:Create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = self.MainColor,
            BorderColor3 = self.OutlineColor,
            Position = Index == #Buttons and UDim2.new(1, -88, 1, -32) or UDim2.new(0, 10 + (Index - 1) * 84, 1, -32),
            Size = UDim2.fromOffset(78, 22),
            Text = Text,
            TextColor3 = self.FontColor,
            TextSize = 13,
            Font = self.Font,
            ZIndex = 12003,
            Parent = Frame
        })
        self:OnHighlight(Button, Button, {BorderColor3 = "AccentColor"}, {BorderColor3 = "OutlineColor"})
        Button.Activated:Connect(function()
            if not Library:MouseIsOverOpenedFrame(Button, Frame) then
                if Index == 1 then
                    Submit()
                elseif Text == "Copy" then
                    setclipboard(Popup.Input.Text)
                else
                    Popup:Hide()
                end
            end
        end)
    end
    if not MultiLine then
        Popup.Input.FocusLost:Connect(function(EnterPressed)
            if EnterPressed then
                Submit()
            end
        end)
    end
    return Popup
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1
    Library:Create("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = Inst,
    })
end

function Library:CreateLabel(Properties)
    local _Instance = Library:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 16,
        TextStrokeTransparency = 0,
    })

    Library:ApplyTextStroke(_Instance)

    return Library:Create(_Instance, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame(Instance) then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            )

            if ObjPos.Y > (Cutoff or 40) then
                return
            end

            local Outline
            if Library.OptimizedDragging then
                Outline = Library:Create("Frame", {
                    BackgroundTransparency = 1, BorderSizePixel = 0,
                    Position = UDim2.fromOffset(Instance.AbsolutePosition.X, Instance.AbsolutePosition.Y),
                    Size = UDim2.fromOffset(Instance.AbsoluteSize.X, Instance.AbsoluteSize.Y),
                    ZIndex = 20000, Parent = ScreenGui
                })
                Library:Create("UIStroke", {Color = Library.FontColor, Thickness = 1, Parent = Outline})
            end

            local Position = Instance.Position
            while Library:IsInputActive(Instance) and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Position = UDim2.fromOffset(
                    Mouse.X - ObjPos.X + Instance.AbsoluteSize.X * Instance.AnchorPoint.X,
                    Mouse.Y - ObjPos.Y + Instance.AbsoluteSize.Y * Instance.AnchorPoint.Y
                )
                if Outline then
                    Outline.Position = UDim2.fromOffset(Mouse.X - ObjPos.X, Mouse.Y - ObjPos.Y)
                elseif Instance.Position ~= Position then
                    Instance.Position = Position
                end
                PreRender:Wait()
            end

            if Outline then
                Outline:Destroy()
                Instance.Position = Position
            end
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14)
    local Tooltip = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,
        Visible = false
    })

    Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y),
        TextSize = 14,
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip
    })

    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame(HoverInstance) then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Blockers = Library.HoverBlockers and Library.HoverBlockers[HighlightInstance]
        if Blockers then
            for _,Blocker in next, Blockers do
                if Blocker.Visible and Library:IsMouseOverFrame(Blocker) then
                    return
                end
            end
        end

        for Property, ColorIdx in next, Properties do
            local Value = Library[ColorIdx] or ColorIdx
            if typeof(Value) == "Color3" then
                TweenGuiProperty(Instance, Property, Value)
            else
                Instance[Property] = Value
            end
        end
    end)

    HighlightInstance.MouseLeave:Connect(function()
        for Property, ColorIdx in next, PropertiesDefault do
            local Value = Library[ColorIdx] or ColorIdx
            if typeof(Value) == "Color3" then
                TweenGuiProperty(Instance, Property, Value)
            else
                Instance[Property] = Value
            end
        end
    end)
end

local function GetTopmostGuiAtPosition(Position)
    if not Position then
        Position = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
    end

    local Success, GuiObjects = pcall(function()
        return CoreGui:GetGuiObjectsAtPosition(Position.X, Position.Y)
    end)

    if not Success then
        return
    end

    local Topmost
    for _,Object in ipairs(GuiObjects) do
        if Object:IsDescendantOf(ScreenGui) and Library:IsInputActive(Object) and (not Topmost or Object.ZIndex > Topmost.ZIndex) then
            Topmost = Object
        end
    end

    return Topmost
end

function Library:IsInputActive(Target)
    local Current = Target
    while Current and Current ~= ScreenGui do
        if Current:IsA("GuiObject") and not Current.Visible then
            return
        end
        Current = Current.Parent
    end
    return true
end

function Library:ClosePopups(Parent)
    for Frame, Anchor in next, self.OpenedFrames do
        if Anchor == Parent or Anchor:IsDescendantOf(Parent) then
            self.OpenedFrames[Frame] = nil
            Frame.Visible = false
            self:ClosePopups(Frame)
        end
    end

    if self.ConfigOverlay then
        local HasMenu = false
        for Frame in next, self.OpenedFrames do
            if Frame.Name == 'ConfigMenu' then
                HasMenu = true
                break
            end
        end
        self.ConfigOverlay.Visible = HasMenu
    end
end

function Library:IsMouseOverFrame(Frame)
    local AbsolutePosition, AbsoluteSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    if Mouse.X >= AbsolutePosition.X and Mouse.X <= AbsolutePosition.X + AbsoluteSize.X and Mouse.Y >= AbsolutePosition.Y and Mouse.Y <= AbsolutePosition.Y + AbsoluteSize.Y then
        return true
    end
end

function Library:MouseIsOverOpenedFrame(Target, InputRoot, InputPosition)
    if Target and not Library:IsInputActive(Target) then
        return true
    end

    local Topmost
    if Target then
        Topmost = GetTopmostGuiAtPosition(InputPosition)
        local Root = InputRoot or Target
        if Topmost and Topmost ~= Root and not Topmost:IsDescendantOf(Root) and not Root:IsDescendantOf(Topmost) then
            return true
        end
    end

    for Frame in next, Library.OpenedFrames do
        if Library:IsMouseOverFrame(Frame) and not (Target and (Target == Frame or Target:IsDescendantOf(Frame))) then
            local TargetHasTopmost = Target and Topmost and (Topmost == Target or Topmost:IsDescendantOf(Target) or Target:IsDescendantOf(Topmost))
            if not TargetHasTopmost then
                return true
            end
        end
    end
end

function Library:AddHoverBlocker(Toggle, Blocker)
    Library.HoverBlockers = Library.HoverBlockers or setmetatable({}, {__mode = 'k'})
    local Region = Toggle.HoverRegion
    if not Region then
        return
    end

    local List = Library.HoverBlockers[Region]
    if not List then
        List = {}
        Library.HoverBlockers[Region] = List
        Region.MouseMoved:Connect(function()
            Library:RefreshToggleHover(Toggle)
        end)
    end
    List[#List + 1] = Blocker
end

function Library:RefreshToggleHover(Toggle)
    local Outer = Toggle.HoverOuter
    if not Outer then
        return
    end

    local Blocked, Blockers = false, Library.HoverBlockers and Library.HoverBlockers[Toggle.HoverRegion]
    if Blockers then
        for _,Blocker in next, Blockers do
            if Blocker.Visible and Library:IsMouseOverFrame(Blocker) then
                Blocked = true
                break
            end
        end
    end

    TweenGuiProperty(Outer, "BorderColor3", Blocked and Color3.new(0, 0, 0) or Library.AccentColor)
end

function Library:UpdateDependencyBoxes()
    for _,Dependencybox in next, Library.DependencyBoxes do
        Dependencybox:Update()
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

local function MakeScroll(Parent, Position, Size)
    local Scroll = Library:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = Position,
        Size = Size,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BottomImage = "",
        TopImage = "",
        ScrollBarThickness = 5,
        ZIndex = 2,
        Parent = Parent,
    })

    local Layout = Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = Scroll
    })
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y)
    end)

    return Scroll
end

local BaseAddons = {}

do
    local Funcs = {}

    local function IsOutsidePopup(Position, Size)
        return Mouse.X < Position.X or Mouse.X > Position.X + Size.X or Mouse.Y < Position.Y - 21 or Mouse.Y > Position.Y + Size.Y
    end


    function Funcs:AddColorPicker(Index, Info)
        local ToggleLabel = self.TextLabel

        assert(Info.Default, 'AddColorPicker: Missing default value.')

        local function ClampTransparency(Value)
            return type(Value) == "number" and math.clamp(Value, 0, 1) or 0
        end

        local ColorPicker = {
            Value = Info.Default,
            Transparency = ClampTransparency(Info.Transparency),
            Type = 'ColorPicker',
            Callback = Info.Callback or function(Color) end,
        }

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color:ToHSV()

            ColorPicker.Hue = H
            ColorPicker.Saturation = S
            ColorPicker.Vib = V
        end

        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        local DisplayFrame = Library:Create("TextButton", {
            Active = true,
            AutoButtonColor = false,
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 28, 0, 14),
            Text = "",
            Selectable = false,
            ZIndex = 6,
            Parent = ToggleLabel,
        })

        Library:Create("ImageLabel", {
            BorderSizePixel = 0,
            Size = UDim2.new(0, 27, 0, 13),
            ZIndex = 5,
            Image = 'http://www.roblox.com/asset/?id=12977615774',
            Visible = not not Info.Transparency,
            Parent = DisplayFrame,
        })

        local PickerHeight = Info.Transparency and 252 or 234
        local PickerFrameOuter = Library:Create("Frame", {
            Active = true,
            Name = "Color",
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, PickerHeight),
            Visible = false,
            ZIndex = 35,
            Parent = ScreenGui
        })

        local function UpdatePickerPosition(Force)
            if not PickerFrameOuter.Visible and not Force then
                return
            end
            local Viewport = ScreenGui.AbsoluteSize
            if Viewport.X <= 0 or Viewport.Y <= 0 then
                Viewport = Camera.ViewportSize
            end

            local AnchorPosition = DisplayFrame.AbsolutePosition
            local AnchorSize = DisplayFrame.AbsoluteSize
            local BelowY = AnchorPosition.Y + AnchorSize.Y + 4
            local AboveY = AnchorPosition.Y - PickerHeight - 4
            local Y

            if BelowY + PickerHeight <= Viewport.Y - 4 then
                Y = BelowY
            elseif AboveY >= 4 then
                Y = AboveY
            else
                Y = BelowY
            end

            local X = math.clamp(AnchorPosition.X, 4, math.max(4, Viewport.X - 234))
            Y = math.clamp(Y, 4, math.max(4, Viewport.Y - PickerHeight - 4))
            PickerFrameOuter.Position = UDim2.fromOffset(X, Y)
        end
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdatePickerPosition)
        DisplayFrame:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdatePickerPosition)
        ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdatePickerPosition)
        UpdatePickerPosition()

        local PickerFrameInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 36,
            Parent = PickerFrameOuter
        })

        Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 37,
            Parent = PickerFrameInner
        })

        local SatVibMapOuter = Library:Create("Frame", {
            Active = true,
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 4, 0, 6),
            Size = UDim2.new(0, 200, 0, 200),
            ZIndex = 37,
            Parent = PickerFrameInner
        })

        local SatVibMapInner = Library:Create("Frame", {
            Active = true,
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 38,
            Parent = SatVibMapOuter
        })

        local SatVibMap = Library:Create("ImageLabel", {
            Active = true,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 38,
            Image = 'rbxassetid://4155801252',
            Parent = SatVibMapInner
        })

        local CursorOuter = Library:Create("ImageLabel", {
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1,
            Image = 'http://www.roblox.com/asset/?id=9619665977',
            ImageColor3 = Color3.new(0, 0, 0),
            ZIndex = 39,
            Parent = SatVibMap
        })

        Library:Create("ImageLabel", {
            Active = false,
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'http://www.roblox.com/asset/?id=9619665977',
            ZIndex = 40,
            Parent = CursorOuter
        })

        local HueSelectorOuter = Library:Create("Frame", {
            Active = true,
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 208, 0, 6),
            Size = UDim2.new(0, 15, 0, 200),
            ZIndex = 37,
            Parent = PickerFrameInner
        })

        local HueSelectorInner = Library:Create("Frame", {
            Active = true,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 38,
            Parent = HueSelectorOuter
        })

        local HueCursor = Library:Create("Frame", {
            Active = false,
            BackgroundColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0, 0.5),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 38,
            Parent = HueSelectorInner
        })

        local CursorTween, HueTween, TransparencyTween
        local DragMode

        local HueBoxOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(4, 209),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 38,
            Parent = PickerFrameInner
        })

        local HueBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 38,
            Parent = HueBoxOuter
        })

        Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            }),
            Rotation = 90,
            Parent = HueBoxInner
        })

        local HueBox = Library:Create("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            Font = Library.Font,
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
            PlaceholderText = 'Hex color',
            ClearTextOnFocus = false,
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor,
            TextSize = 14,
            TextStrokeTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 40,
            Parent = HueBoxInner,
        })

        Library:ApplyTextStroke(HueBox)

        local RGBBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 209),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        })

        local RGBBox = Library:Create(RGBBoxBase.Frame:FindFirstChild("TextBox"), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        })

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor

        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create("Frame", {
                Active = true,
                BorderColor3 = Color3.new(0, 0, 0),
                Position = UDim2.fromOffset(4, 232),
                Size = UDim2.new(1, -8, 0, 15),
                ZIndex = 39,
                Parent = PickerFrameInner,
            })

            TransparencyBoxInner = Library:Create("Frame", {
                Active = true,
                BackgroundColor3 = ColorPicker.Value,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 39,
                Parent = TransparencyBoxOuter,
            })

            Library:Create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Image = 'http://www.roblox.com/asset/?id=12978095818',
                ZIndex = 40,
                Parent = TransparencyBoxInner,
            })

            Library:Create("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                }),
                Parent = TransparencyBoxInner
            })

        TransparencyCursor = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0.5, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            ZIndex = 41,
            Parent = TransparencyBoxInner,
        })
        end

        local SequenceTable = {}

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
        end

        Library:Create("UIGradient", {
            Color = ColorSequence.new(SequenceTable),
            Rotation = 90,
            Parent = HueSelectorInner
        })

        HueBox.FocusLost:Connect(function(Enter)
            if Enter then
                local Success, Result = pcall(Color3.fromHex, HueBox.Text)
                if Success and typeof(Result) == "Color3" then
                    ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib = Result:ToHSV()
                end
            end
            ColorPicker:Display()
        end)

        RGBBox.FocusLost:Connect(function(Enter)
            if Enter then
                local R, G, B = string.match(RGBBox.Text, '^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$')
                if R then
                    R, G, B = tonumber(R), tonumber(G), tonumber(B)
                    if R <= 255 and G <= 255 and B <= 255 then
                        ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib = Color3.fromRGB(R, G, B):ToHSV()
                    end
                end
            end
            ColorPicker:Display()
        end)

        local LastValue, LastTransparency

        function ColorPicker:Display(Silent)
            local OldValue, OldTransparency = LastValue, LastTransparency
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)

            DisplayFrame:SetAttribute("FadeTransparency", ColorPicker.Transparency)
            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value,
                BackgroundTransparency = ColorPicker.Transparency,
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
            })
            TweenGuiProperty(DisplayFrame, "BackgroundTransparency", ColorPicker.Transparency)

            local function TweenCursor(Object, Current, Target, Duration)
                if Current then
                    Current:Cancel()
                end
        
                if ColorPicker.Dragging then
                    Object.Position = Target
                    return
                end

                local Tween = TweenService:Create(Object, TweenInfo.new(Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = Target})
                Tween:Play()
                return Tween
            end

            CursorTween = TweenCursor(CursorOuter, CursorTween, UDim2.new(ColorPicker.Saturation, 0, 1 - ColorPicker.Vib, 0), 0.08)
            HueTween = TweenCursor(HueCursor, HueTween, UDim2.new(0, 0, ColorPicker.Hue, 0), 0.08)
            if TransparencyBoxInner then
                TransparencyTween = TweenCursor(TransparencyCursor, TransparencyTween, UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0), 0.08)
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
            end

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RGBBox.Text = table.concat({math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            local Changed = OldValue and (ColorPicker.Value ~= OldValue or ColorPicker.Transparency ~= OldTransparency)
            LastValue, LastTransparency = ColorPicker.Value, ColorPicker.Transparency
            if not Silent and Changed then
                Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value, ColorPicker.Transparency)
            end
        end

        PickerFrameOuter.ZIndex += 5000
        for _,Descendant in ipairs(PickerFrameOuter:QueryDescendants("GuiObject")) do
            Descendant.ZIndex += 5000
        end

        function ColorPicker:Show()
            for Frame, Value in next, Library.OpenedFrames do
                if Frame.Name == "Color" then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
            end

            UpdatePickerPosition(true)
            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = DisplayFrame
        end

        function ColorPicker:Hide()
            ColorPicker.Dragging = false
            DragMode = nil
            PickerFrameOuter.Visible = false
            Library.OpenedFrames[PickerFrameOuter] = nil
        end

        function ColorPicker:SetValueRGB(Color, Transparency, Silent)
            ColorPicker.Transparency = ClampTransparency(Transparency)
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display(Silent)
        end

        local function UpdateDragValue()
            if not DragMode or not PickerFrameOuter.Visible then
                return
            end

            if DragMode == 'SaturationValue' then
                local Position, Size = SatVibMap.AbsolutePosition, SatVibMap.AbsoluteSize
                ColorPicker.Saturation = (math.clamp(Mouse.X, Position.X, Position.X + Size.X) - Position.X) / math.max(Size.X, 1)
                ColorPicker.Vib = 1 - ((math.clamp(Mouse.Y, Position.Y, Position.Y + Size.Y) - Position.Y) / math.max(Size.Y, 1))
            elseif DragMode == 'Hue' then
                local Position, Size = HueSelectorInner.AbsolutePosition, HueSelectorInner.AbsoluteSize
                ColorPicker.Hue = (math.clamp(Mouse.Y, Position.Y, Position.Y + Size.Y) - Position.Y) / math.max(Size.Y, 1)
            elseif DragMode == 'Transparency' and TransparencyBoxInner then
                local Position, Size = TransparencyBoxInner.AbsolutePosition, TransparencyBoxInner.AbsoluteSize
                ColorPicker.Transparency = 1 - ((math.clamp(Mouse.X, Position.X, Position.X + Size.X) - Position.X) / math.max(Size.X, 1))
            end

            ColorPicker:Display()
        end

        local function BeginColorDrag(Input, Mode)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or not PickerFrameOuter.Visible or not Library:IsInputActive(PickerFrameOuter) then
                return
            end

            DragMode = Mode
            ColorPicker.Dragging = true
            UpdateDragValue()
        end

        UserInputService.InputChanged:Connect(function(Input)
            if DragMode and Input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateDragValue()
            end
        end)

        UserInputService.InputEnded:Connect(function(Input)
            if DragMode and Input.UserInputType == Enum.UserInputType.MouseButton1 then
                DragMode = nil
                ColorPicker.Dragging = false
                ColorPicker:Display()
            end
        end)

        SatVibMap.InputBegan:Connect(function(Input)
            BeginColorDrag(Input, 'SaturationValue')
        end)

        HueSelectorInner.InputBegan:Connect(function(Input)
            BeginColorDrag(Input, 'Hue')
        end)

        DisplayFrame.Activated:Connect(function()
            if PickerFrameOuter.Visible then
                ColorPicker:Hide()
            else
                ColorPicker:Show()
            end
        end)

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                BeginColorDrag(Input, 'Transparency')
            end)
        end

        UserInputService.InputBegan:Connect(function(Input)
            if not Library:IsInputActive(DisplayFrame) then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsolutePosition, AbsoluteSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize
                if IsOutsidePopup(AbsolutePosition, AbsoluteSize) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ColorPicker:Hide()
                end
            end
        end)

        ColorPicker.DisplayFrame = DisplayFrame
        Options[Index] = ColorPicker

        ColorPicker:Display()
        return ColorPicker
    end

    function Funcs:AddKeyPicker(Index, Info)
        local ParentToggle = self.ParentToggle or (self.Type == "Toggle" and self)
        local ToggleLabel = self.TextLabel

        assert(Info.Default, 'AddKeyPicker: Missing default value.')

        local function GetKeyDisplayName(Key)
            if Key == 'LeftControl' then
                return 'LeftCtrl'
            elseif Key == 'RightControl' then
                return 'RightCtrl'
            elseif Key == 'LeftBracket' then
                return 'LeftBrkt'
            elseif Key == 'RightBracket' then
                return 'RightBrkt'
            end
            return Key
        end

        local KeyPicker = {
            Value = Info.Default,
            Toggled = false,
            Mode = Info.Mode or "Toggle",
            Type = 'KeyPicker',
            Callback = Info.Callback or function() end,
            SyncToggleState = Info.SyncToggleState or false
        }

        local PickOuter = Library:Create("Frame", {
            Active = true,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 28, 0, 15),
            ZIndex = 6,
            Parent = ToggleLabel
        })

        local PickInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7,
            Parent = PickOuter
        })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 13,
            Text = GetKeyDisplayName(Info.Default),
            TextWrapped = true,
            ZIndex = 8,
            Parent = PickInner
        })

        local Modes = Info.Modes or {"Always", "Toggle", "Hold"}
        KeyPicker.Modes = Modes
        KeyPicker.Mode = table.find(Modes, KeyPicker.Mode) and KeyPicker.Mode or Modes[1]

        local ModeSelectOuter = Library:Create("Frame", {
            Active = true,
            Name = 'ModeSelect',
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1),
            Size = UDim2.fromOffset(60, #Modes * 15 + 2),
            Visible = false,
            ZIndex = 12010,
            Parent = ScreenGui
        })

        local function UpdateModePosition(Force)
            if not ModeSelectOuter.Visible and not Force then
                return
            end
            local Viewport = ScreenGui.AbsoluteSize
            if Viewport.X <= 0 or Viewport.Y <= 0 then
                Viewport = Camera.ViewportSize
            end

            local AnchorPosition = PickOuter.AbsolutePosition
            local AnchorSize = PickOuter.AbsoluteSize
            local PopupSize = ModeSelectOuter.AbsoluteSize
            local X, Y

            if ToggleLabel:FindFirstAncestor("ConfigMenu") then
                X = AnchorPosition.X + AnchorSize.X - PopupSize.X
                Y = AnchorPosition.Y + AnchorSize.Y + 2
                if Y + PopupSize.Y > Viewport.Y then
                    Y = AnchorPosition.Y - PopupSize.Y - 2
                end
            else
                X = AnchorPosition.X + AnchorSize.X + 4
                Y = AnchorPosition.Y
                if X + PopupSize.X > Viewport.X then
                    X = AnchorPosition.X - PopupSize.X - 4
                end
            end

            X = math.clamp(X, 0, math.max(0, Viewport.X - PopupSize.X))
            Y = math.clamp(Y, 0, math.max(0, Viewport.Y - PopupSize.Y))
            ModeSelectOuter.Position = UDim2.fromOffset(X, Y)
        end

        PickOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateModePosition)
        PickOuter:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateModePosition)
        ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateModePosition)

        local ModeSelectInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 12011,
            Parent = ModeSelectOuter
        })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ModeSelectInner
        })

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 18),
            TextSize = 13,
            Visible = false,
            ZIndex = 110,
            Parent = Library.ActiveKeybindContainer
        })

        local ModeButtons = {}

        for Index, Mode in next, Modes do
            local ModeButton = {}

            local Label = Library:CreateLabel({
                Active = true,
                Size = UDim2.new(1, 0, 0, 15),
                TextSize = 13,
                Text = Mode,
                LayoutOrder = Index,
                ZIndex = 12012,
                Parent = ModeSelectInner
            })

            function ModeButton:Select(Silent)
                local Changed = KeyPicker.Mode ~= Mode
                for _,Button in next, ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Label.TextColor3 = Library.AccentColor

                ModeSelectOuter.Visible = false
                Library.OpenedFrames[ModeSelectOuter] = nil
                if Changed and not Silent then
                    KeyPicker:DoClick()
                    KeyPicker:Update()
                end
            end

            function ModeButton:Deselect()
                Label.TextColor3 = Library.FontColor
            end

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame(Label) then
                    ModeButton:Select()
                end
            end)

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Update()
            local KeyWidth = select(1, Library:GetTextBounds(DisplayLabel.Text, Library.Font, DisplayLabel.TextSize)) + 12
            TweenGuiProperty(PickOuter, 'Size', UDim2.new(0, math.max(28, math.ceil(KeyWidth)), 0, 15))

            if Info.NoUI then
                return
            end

            do
                local State = KeyPicker:GetState()
                local ParentOn = KeyPicker.ParentToggle and KeyPicker.ParentToggle.Value

                ContainerLabel.Text = string.format('[%s] %s (%s)', GetKeyDisplayName(KeyPicker.Value), Info.Text, KeyPicker.Mode)

                ContainerLabel.Visible = ParentOn or State
                ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor

                local YSize = 0
                local XSize = 0

                for _,Label in next, Library.ActiveKeybindContainer:GetChildren() do
                    if Label:IsA("TextLabel") and Label.Visible then
                        YSize += 18
                        if (Label.TextBounds.X > XSize) then
                            XSize = Label.TextBounds.X
                        end
                    end
                end

                TweenGuiProperty(Library.ActiveKeybindFrame, 'Size', UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23))
            end
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                if KeyPicker.Value == 'None' or UserInputService:GetFocusedTextBox() then
                    return false
                end

                local Key = KeyPicker.Value

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or Key == 'MB2' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:SetValue(Data, Silent)
            if type(Data) ~= "table" then
                Data = {Data, KeyPicker.Mode or "Toggle"}
            end

            local Key = Data[1]
            if typeof(Key) ~= "string" or Key == "" then
                Key = Info.Default or "None"
            end

            local Mode = Data[2]
            if typeof(Mode) ~= "string" or not ModeButtons[Mode] then
                Mode = KeyPicker.Mode or "Toggle"
            end

            local PreviousMode = KeyPicker.Mode
            local Changed = Key ~= KeyPicker.Value or Mode ~= PreviousMode
            DisplayLabel.Text = GetKeyDisplayName(Key)
            KeyPicker.Value = Key
            ModeButtons[Mode]:Select(true)
            if not Silent and Changed then
                if Mode ~= PreviousMode or Mode == "Hold" then
                    KeyPicker:DoClick()
                end
                Library:SafeCallback(KeyPicker.Callback, Key)
            end
            KeyPicker:Update()
        end

        if ParentToggle then
            table.insert(ParentToggle.Addons, KeyPicker)
            KeyPicker.ParentToggle = ParentToggle
            if KeyPicker.SyncToggleState then
                KeyPicker.Toggled = ParentToggle.Value
            end
        end

        function KeyPicker:DoClick(State)
            if State == nil then
                State = KeyPicker:GetState()
            end
            if ParentToggle and KeyPicker.SyncToggleState then
                ParentToggle:SetValue(State)
            end
            Library:SafeCallback(KeyPicker.Callback, State)
        end

        local Picking = false
        local function MatchesKey(Input)
            return (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KeyPicker.Value)
                or (Input.UserInputType == Enum.UserInputType.MouseButton1 and KeyPicker.Value == "MB1")
                or (Input.UserInputType == Enum.UserInputType.MouseButton2 and KeyPicker.Value == "MB2")
        end

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library.PickingKeyPicker and not Library:MouseIsOverOpenedFrame(PickOuter) then
                Picking = true
                Library.PickingKeyPicker = KeyPicker
                if KeyPicker.Mode == "Hold" then
                    KeyPicker:DoClick(false)
                end

                DisplayLabel.Text = ''

                local Break, Event
                local function StopPicking()
                    Break = true
                    Picking = false
                    task.defer(function()
                        if Library.PickingKeyPicker == KeyPicker then
                            Library.PickingKeyPicker = nil
                        end
                    end)
                    if Event then
                        Event:Disconnect()
                    end
                    DisplayLabel.Text = GetKeyDisplayName(KeyPicker.Value)
                end

                task.spawn(function()
                    local Text, NextUpdate = '', 0
                    while not Break do
                        if not Library.Toggled or not Library:IsInputActive(PickOuter) then
                            StopPicking()
                            return
                        end
                        local Now = os.clock()
                        if Now >= NextUpdate then
                            Text = Text == '...' and '.' or Text .. '.'
                            DisplayLabel.Text = Text
                            NextUpdate = Now + 0.4
                        end
                        PreRender:Wait()
                    end
                end)

                task.wait(0.2)
                if Break then
                    return
                end
                if not Library.Toggled or not Library:IsInputActive(PickOuter) then
                    StopPicking()
                    return
                end

                Event = UserInputService.InputBegan:Connect(function(Input)
                    if not Library.Toggled or not Library:IsInputActive(PickOuter) then
                        StopPicking()
                        return
                    end

                    local Key

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = "None"
                    else
                        return
                    end

                    if Key == "Escape" then
                        Key = "None"
                    end

                    KeyPicker.Value = Key
                    StopPicking()
                    if KeyPicker.Mode == "Hold" then
                        KeyPicker:DoClick()
                    end
                    Library:SafeCallback(KeyPicker.Callback, Key)
                    KeyPicker:Update()

                end)
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame(PickOuter) then
                UpdateModePosition(true)
                ModeSelectOuter.Visible = true
                Library.OpenedFrames[ModeSelectOuter] = PickOuter
            end
        end)

        UserInputService.InputBegan:Connect(function(Input)
            if not Library.PickingKeyPicker and not UserInputService:GetFocusedTextBox() and MatchesKey(Input) then
                if KeyPicker.Mode == "Toggle" then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                elseif KeyPicker.Mode == "Hold" then
                    KeyPicker:DoClick(true)
                end
                KeyPicker:Update()
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if not Library:IsInputActive(PickOuter) then
                    return
                end

                if IsOutsidePopup(ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize) then
                    ModeSelectOuter.Visible = false
                    Library.OpenedFrames[ModeSelectOuter] = nil
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(Input)
            if not Picking and KeyPicker.Mode == "Hold" and MatchesKey(Input) then
                KeyPicker:DoClick(false)
                KeyPicker:Update()
            end
        end)

        ModeButtons[KeyPicker.Mode]:Select(true)
        KeyPicker:Update()
        Options[Index] = KeyPicker
        KeyPicker.Outer = PickOuter
        return KeyPicker
    end

        function Funcs:AddSettingsMenu(Title)
        local ToggleLabel = self.TextLabel
            assert(ToggleLabel, 'AddSettingsMenu: Must be called on a Toggle.')

        local ConfigOuter = Library:Create('Frame', {
            Active = true,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, select(1, Library:GetTextBounds('•••', Library.Font, 13)) + 10, 0, 15),
            ZIndex = 9,
            Parent = ToggleLabel,
        })

        local ConfigInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 10,
            Parent = ConfigOuter,
        })

        local ConfigLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 13,
            Text = '•••',
            ZIndex = 11,
            Parent = ConfigInner,
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ConfigLabel,
        })

        Library:OnHighlight(ConfigOuter, ConfigInner,
            {BorderColor3 = 'AccentColor'},
            {BorderColor3 = 'OutlineColor'}
        )

        Library:AddHoverBlocker(self, ConfigOuter)
        ConfigOuter.MouseEnter:Connect(function()
            Library:RefreshToggleHover(self)
        end)

        local RegionResized = false
        ConfigOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            if RegionResized then
                return
            end
            local Region = self.HoverRegion
            if Region and ConfigOuter.AbsolutePosition.X > 0 and Region.AbsolutePosition.X > 0 then
                RegionResized = true
                Region.Size = UDim2.new(0, math.min(Region.Size.X.Offset, math.max(50, ConfigOuter.AbsolutePosition.X - Region.AbsolutePosition.X - 2)), 1, 0)
            end
        end)

        local ParentMenu = ConfigOuter:FindFirstAncestor('ConfigMenu')
        local MenuZIndex = ParentMenu and ParentMenu.ZIndex + 100 or 1001
        local MenuOuter = Library:Create('Frame', {
            Active = true,
            Name = 'ConfigMenu',
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.fromOffset(250, 50),
            Visible = false,
            ZIndex = MenuZIndex,
            Parent = ParentMenu or ScreenGui,
        })

        local MenuInner = Library:Create('Frame', {
            Active = true,
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = MenuZIndex + 1,
            Parent = MenuOuter,
        })

        Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = MenuZIndex + 2,
            Parent = MenuInner,
        })

        local MenuContainer = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 4, 0, 6),
            Size = UDim2.new(1, -8, 1, -10),
            ZIndex = MenuZIndex + 1,
            Parent = MenuInner,
        })

        local MenuLayout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = MenuContainer,
        })

        local Menu = {Container = MenuContainer}

        function Menu:Resize()
            MenuOuter.Size = UDim2.fromOffset(250, MenuLayout.AbsoluteContentSize.Y + 10)
            for _,Descendant in next, MenuContainer:QueryDescendants("GuiObject") do
                if not Descendant:GetAttribute("ZBoosted") then
                    Descendant:SetAttribute("ZBoosted", true)
                    Descendant.ZIndex = Descendant.ZIndex + MenuZIndex - 1
                end
            end
        end

        MenuLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Menu:Resize()
        end)

        local function UpdateMenuPosition(Force)
            if not MenuOuter.Visible and not Force then
                return
            end
            local X = ConfigOuter.AbsolutePosition.X + ConfigOuter.AbsoluteSize.X + 4
            local Viewport = Camera.ViewportSize
            if X + 250 > Viewport.X then
                X = ConfigOuter.AbsolutePosition.X - 250 - 4
            end
            local Y = math.clamp(ConfigOuter.AbsolutePosition.Y - 4, 10, math.max(10, Viewport.Y - MenuOuter.AbsoluteSize.Y - 10))
            local Origin = ParentMenu and ParentMenu.AbsolutePosition or Vector2.zero
            MenuOuter.Position = UDim2.fromOffset(X - Origin.X, Y - Origin.Y)
        end

        ConfigOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateMenuPosition)
        MenuOuter:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateMenuPosition)
        Camera:GetPropertyChangedSignal('ViewportSize'):Connect(UpdateMenuPosition)

        function Menu:Show()
            local Open = {}
            for Frame in next, Library.OpenedFrames do
                if (Frame.Name == 'ConfigMenu' and not ConfigOuter:IsDescendantOf(Frame)) or Frame.Name == 'Color' or Frame.Name == 'Dropdown' or Frame.Name == 'ModeSelect' then
                    Open[#Open + 1] = Frame
                end
            end
            for _,Frame in ipairs(Open) do
                Frame.Visible = false
                Library.OpenedFrames[Frame] = nil
            end
            if not Library.ConfigOverlay then
                Library.ConfigOverlay = Library:Create('Frame', {
                    Active = true,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 1000,
                    Visible = false,
                    Parent = ScreenGui,
                })
                pcall(function()
                    Library.ConfigOverlay.InputSink = Enum.InputSink.All
                end)
            end
            Menu:Resize()
            UpdateMenuPosition(true)
            MenuOuter.Visible = true
            Library.OpenedFrames[MenuOuter] = ConfigOuter
            Library.ConfigOverlay.Visible = true
        end

        function Menu:Hide()
            local Open = {}
            for Frame in next, Library.OpenedFrames do
                if Frame == MenuOuter or Frame:IsDescendantOf(MenuOuter) or Frame.Name == 'Color' or Frame.Name == 'Dropdown' or Frame.Name == 'ModeSelect' then
                    Open[#Open + 1] = Frame
                end
            end
            for _,Frame in ipairs(Open) do
                Frame.Visible = false
                Library.OpenedFrames[Frame] = nil
            end
            local HasMenu = false
            for Frame in next, Library.OpenedFrames do
                if Frame.Name == 'ConfigMenu' then
                    HasMenu = true
                    break
                end
            end
            if Library.ConfigOverlay then
                Library.ConfigOverlay.Visible = HasMenu
            end
        end

        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or not Library:IsInputActive(ConfigOuter) then
                return
            end

            local Position = Input.Position
            local ButtonPosition, ButtonSize = ConfigOuter.AbsolutePosition, ConfigOuter.AbsoluteSize
            local ClickedButton = Position.X >= ButtonPosition.X and Position.X <= ButtonPosition.X + ButtonSize.X
                and Position.Y >= ButtonPosition.Y and Position.Y <= ButtonPosition.Y + ButtonSize.Y

            if ClickedButton then
                for Frame in next, Library.OpenedFrames do
                    if Frame.Visible and Library:IsMouseOverFrame(Frame) and not ConfigOuter:IsDescendantOf(Frame) then
                        return
                    end
                end
                if MenuOuter.Visible then
                    Menu:Hide()
                else
                    Menu:Show()
                end
                return
            end

            if MenuOuter.Visible then
                local MenuPosition, MenuSize = MenuOuter.AbsolutePosition, MenuOuter.AbsoluteSize
                local ClickedMenu = Position.X >= MenuPosition.X and Position.X <= MenuPosition.X + MenuSize.X
                    and Position.Y >= MenuPosition.Y and Position.Y <= MenuPosition.Y + MenuSize.Y

                if not ClickedMenu and not Library:MouseIsOverOpenedFrame() then
                    Menu:Hide()
                end
            end
        end)
        setmetatable(Menu, Library.BaseGroupbox)
        local TitleRow = Menu:AddLabel(Title or 'Settings')
        TitleRow.TextLabel.TextYAlignment = Enum.TextYAlignment.Center
        local TitleLayout = TitleRow.TextLabel:FindFirstChildOfClass('UIListLayout')
        if TitleLayout then
            TitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        end

        local TitleProxy = {TextLabel = TitleRow.TextLabel, Container = MenuContainer, ParentToggle = self}
        setmetatable(TitleProxy, BaseAddons)

        function Menu:AddColorPicker(Index, Info)
            local Picker = TitleProxy:AddColorPicker(Index, Info)
            local DisplayFrame = Picker.DisplayFrame
            local ZOffset = DisplayFrame.Parent.ZIndex + 20 - DisplayFrame.ZIndex
            DisplayFrame.ZIndex += ZOffset
            DisplayFrame:SetAttribute("ZBoosted", true)
            for _,Descendant in next, DisplayFrame:QueryDescendants("GuiObject") do
                Descendant.ZIndex += ZOffset
                Descendant:SetAttribute("ZBoosted", true)
            end
            return Picker
        end

        function Menu:AddKeyPicker(Index, Info)
            local Picker = TitleProxy:AddKeyPicker(Index, Info)
            local ZOffset = MenuInner.ZIndex + 20 - Picker.Outer.ZIndex
            Picker.Outer.ZIndex += ZOffset
            Picker.Outer:SetAttribute("ZBoosted", true)
            for _,Descendant in next, Picker.Outer:QueryDescendants("GuiObject") do
                Descendant.ZIndex += ZOffset
                Descendant:SetAttribute("ZBoosted", true)
            end
            return Picker
        end

        return Menu
    end

    function Funcs:AddDropdown(Index, Info)
        local ToggleLabel = self.TextLabel
        assert(ToggleLabel, 'AddDropdown: Must be called on a Toggle.')

        Info.Compact = true
        Info.Parent = ToggleLabel
        Info.ArrowShift = Info.ArrowShift or 2
        if not Info.Width then
            local Widest = 0
            for _,Value in next, Info.Values do
                Widest = math.max(Widest, select(1, Library:GetTextBounds(Value, Library.Font, 14)))
            end
            Info.Width = math.max(60, math.ceil(Widest) + 44)
        end
        Info.Height = Info.Height or 13

        local Proxy = {Container = ToggleLabel}
        function Proxy:AddBlank() end
        function Proxy:Resize() end
        setmetatable(Proxy, Library.BaseGroupbox)

        local Dropdown = Proxy:AddDropdown(Index, Info)
        local ZIndex = ToggleLabel.ZIndex
        local Parent = ToggleLabel.Parent
        while Parent and Parent ~= ScreenGui do
            if Parent:IsA("GuiObject") then
                ZIndex = math.max(ZIndex, Parent.ZIndex)
            end
            Parent = Parent.Parent
        end
        local ZOffset = ZIndex + 20 - Dropdown.Outer.ZIndex
        local function BoostZ(Instance)
            Instance.ZIndex += ZOffset
            Instance:SetAttribute("ZBoosted", true)
        end

        BoostZ(Dropdown.Outer)
        for _,Descendant in next, Dropdown.Outer:QueryDescendants("GuiObject") do
            BoostZ(Descendant)
        end

        local ToggleObject = self
        local DropdownResized = false
        Dropdown.Outer:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            if DropdownResized then
                return
            end
            local Region = ToggleObject.HoverRegion
            if Region and Dropdown.Outer.AbsolutePosition.X > 0 and Region.AbsolutePosition.X > 0 then
                DropdownResized = true
                Region.Size = UDim2.new(0, math.min(Region.Size.X.Offset, math.max(50, Dropdown.Outer.AbsolutePosition.X - Region.AbsolutePosition.X - 2)), 1, 0)
            end
        end)

        Library:AddHoverBlocker(self, Dropdown.Outer)
        Dropdown.Outer.MouseEnter:Connect(function()
            Library:RefreshToggleHover(self)
        end)

        return Dropdown
    end

    BaseAddons.__index = Funcs
end

local BaseGroupbox = {}

do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        local Groupbox = self
        local Container = Groupbox.Container

        Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Size),
            ZIndex = 1,
            Parent = Container
        })
    end

    function Funcs:AddLabel(Text, DoesWrap, ToolTip)
        local Label = {}

        local Groupbox = self
        local Container = Groupbox.Container

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15),
            TextSize = 14,
            Text = Text,
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container
        })

        if DoesWrap then
            TextLabel.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))))
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TextLabel
            })
        end

        Label.TextLabel = TextLabel
        Label.Container = Container

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                TextLabel.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))))
            end

            Groupbox:Resize()
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()
        if type(ToolTip) == "string" then
            Library:AddToolTip(ToolTip, TextLabel)
        end
        return Label
    end

    function Funcs:AddButton(...)
        local Button = {}
        local function ProcessButtonParams(Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.')
        end

        ProcessButtonParams(Button, ...)

        local Groupbox = self
        local Container = Groupbox.Container

        local function CreateBaseButton(Button)
            local Outer = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -4, 0, 20),
                ZIndex = 5
            })

            local Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = Outer
            })

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = 14,
                Text = Button.Text,
                ZIndex = 6,
                Parent = Inner
            })

            Library:Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                }),
                Rotation = 90,
                Parent = Inner
            })

            Library:OnHighlight(Outer, Outer, {BorderColor3 = "AccentColor"}, {BorderColor3 = "Black"})
            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            Button.Outer.InputBegan:Connect(function(Input)
                if Library:MouseIsOverOpenedFrame(Button.Outer) or Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == "string" then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}
            ProcessButtonParams(SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)
            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)
            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == "string" then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == "string" then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == "string" then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()

        return Button
    end

    function Funcs:AddDivider()
        local Groupbox = self
        local Container = self.Container

        Groupbox:AddBlank(2)
        local DividerOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 5),
            ZIndex = 5,
            Parent = Container
        })

        Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DividerOuter
        })

        Groupbox:AddBlank(9)
        Groupbox:Resize()
    end

    function Funcs:AddToggle(Index, Info)
        assert(Info.Text, 'AddToggle: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false,
            Type = "Toggle",

            Callback = Info.Callback or function(Value) end,
            Addons = {},
            Risky = Info.Risky
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local ToggleOuter = Library:Create("Frame", {
            Active = true,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 13, 0, 13),
            ZIndex = 5,
            Parent = Container
        })

        local ToggleInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = ToggleOuter
        })

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0),
            Position = UDim2.new(1, 6, 0, 0),
            TextSize = 14,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
            Parent = ToggleInner
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ToggleLabel
        })

        local ToggleRegion = Library:Create("Frame", {
            Active = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 170, 1, 0),
            ZIndex = 8,
            Parent = ToggleOuter
        })

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            {BorderColor3 = "AccentColor"},
            {BorderColor3 = "Black"}
        )

        if type(Info.Tooltip) == "string" then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            TweenGuiProperty(ToggleInner, "BackgroundColor3", Toggle.Value and Library.AccentColor or Library.MainColor, ToggleTweenInfo)
            TweenGuiProperty(ToggleInner, "BorderColor3", Toggle.Value and Library.AccentColorDark or Library.OutlineColor, ToggleTweenInfo)

            for _,Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.Update then
                    Addon:Update()
                end
            end
        end

        function Toggle:SetValue(Bool, Silent)
            Bool = (not not Bool)

            local Changed = Toggle.Value ~= Bool
            Toggle.Value = Bool
            Toggle:Display()

            for _,Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            if not Silent and Changed then
                Library:SafeCallback(Toggle.Callback, Toggle.Value)
            end
            Library:UpdateDependencyBoxes()
        end

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame(ToggleRegion, ToggleOuter) then
                Toggle:SetValue(not Toggle.Value)
            end
        end)

        if Toggle.Risky then
            ToggleLabel.TextColor3 = Library.RiskColor
        end

        Toggle:Display()
        Groupbox:AddBlank(Info.BlankSize or 5 + 2)
        Groupbox:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = Container
        Toggle.HoverRegion = ToggleRegion
        Toggle.HoverOuter = ToggleOuter
        setmetatable(Toggle, BaseAddons)

        Toggles[Index] = Toggle
        Library:UpdateDependencyBoxes()
        return Toggle
    end

    function Funcs:AddSlider(Index, Info)
        assert(Info.Default, 'AddSlider: Missing default value.')
        assert(Info.Text, 'AddSlider: Missing slider Text.')
        assert(Info.Min, 'AddSlider: Missing minimum value.')
        assert(Info.Max, 'AddSlider: Missing maximum value.')
        assert(Info.Rounding, 'AddSlider: Missing rounding value.')

        local Slider = {
            Value = Info.Default,
            Min = Info.Min,
            Max = Info.Max,
            Rounding = Info.Rounding,
            MaxSize = 232,
            Type = 'Slider',
            Callback = Info.Callback or function(Value) end
        }

        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = 14,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container
            })
            Groupbox:AddBlank(3)
        end

        local SliderOuter = Library:Create("Frame", {
            Active = true,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 13),
            ZIndex = 5,
            Parent = Container
        })

        local SliderInner = Library:Create("Frame", {
            Active = true,
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = SliderOuter
        })

        local Fill = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor,
            BorderColor3 = Library.AccentColorDark,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 7,
            Parent = SliderInner
        })

        local HideBorderRight = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            ZIndex = 8,
            Parent = Fill
        })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 14,
            Text = 'Infinite',
            ZIndex = 9,
            Parent = SliderInner
        })

        Library:OnHighlight(SliderOuter, SliderOuter, {BorderColor3 = "AccentColor"}, {BorderColor3 = "Black"})

        if type(Info.Tooltip) == "string" then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:Display()
            local BarWidth = SliderInner.AbsoluteSize.X
            if BarWidth > 0 then
                Slider.MaxSize = BarWidth
            end

            local Suffix = Info.Suffix or ''

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = Slider.Value .. Suffix
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix)
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize))
            if Slider.FillTween then
                Slider.FillTween:Cancel()
            end
            Slider.FillTween = TweenService:Create(Fill, TweenInfo.new(0.02, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, X, 1, 0)})
            Slider.FillTween:Play()

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0)
        end

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value)
            end


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max))
        end

        function Slider:SetValue(String, Silent)
            local Number = tonumber(String)
            if not Number then
                return
            end

            Number = math.clamp(Number, Slider.Min, Slider.Max)

            local Changed = Slider.Value ~= Number
            Slider.Value = Number
            Slider:Display()

            if not Silent and Changed then
                Library:SafeCallback(Slider.Callback, Slider.Value)
            end
        end

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame(SliderInner) then
                Slider.MaxSize = SliderInner.AbsoluteSize.X
                local StartX = Fill.AbsolutePosition.X

                while Library.Toggled and Library:IsInputActive(SliderInner) and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local Value = Slider:GetValueFromXOffset(math.clamp(Mouse.X - StartX, 0, Slider.MaxSize))
                    if Value ~= Slider.Value then
                        Slider.Value = Value
                        Slider:Display()
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                    end

                    PreRender:Wait()
                end
            end
        end)

        Slider:Display()
        Groupbox:AddBlank(Info.BlankSize or 6)
        Groupbox:Resize()

        Options[Index] = Slider
        return Slider
    end

    function Funcs:AddDropdown(Index, Info)
        assert(Info.Values, 'AddDropdown: Missing dropdown value list.')
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true
        end

        local Dropdown = {
            Values = Info.Values,
            Value = Info.Multi and {},
            Multi = Info.Multi,
            Type = 'Dropdown',
            Callback = Info.Callback or function(Value) end
        }

        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = 14,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container
            })

            Groupbox:AddBlank(3)
        end

        local DropdownOuter = Library:Create("Frame", {
            Active = true,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = Info.Width and UDim2.new(0, Info.Width, 0, Info.Height or 20) or UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Info.Parent or Container
        })

        local DropdownInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DropdownOuter
        })

        Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            }),
            Rotation = 90,
            Parent = DropdownInner
        })

        local DropdownArrow = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -16, 0.5, Info.ArrowShift or 0),
            Size = UDim2.new(0, 12, 0, 12),
            Image = 'http://www.roblox.com/asset/?id=6282522798',
            ZIndex = 8,
            Parent = DropdownInner
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            TextSize = 14,
            Text = '--',
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 7,
            Parent = DropdownInner
        })

        Library:OnHighlight(DropdownOuter, DropdownOuter, {BorderColor3 = "AccentColor"}, {BorderColor3 = "Black"})

        if type(Info.Tooltip) == "string" then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8

        local ListOuter = Library:Create("Frame", {
            Active = true,
            ClipsDescendants = true,
            Name = 'Dropdown',
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            ZIndex = 5000,
            Visible = false,
            Parent = ScreenGui
        })

        local ListItemCount = 0
        local DropdownTween
        local DropdownAnimationVersion = 0
        local IsDropdownOpen = false

        local function GetListViewportSize()
            local ViewportSize = ScreenGui.AbsoluteSize
            if ViewportSize.X <= 0 or ViewportSize.Y <= 0 then
                ViewportSize = Camera.ViewportSize
            end
            return ViewportSize
        end

        local function RecalculateListSize()
            local ViewportSize = GetListViewportSize()
            local Width = math.min(DropdownOuter.AbsoluteSize.X, ViewportSize.X)
            local Height = math.min(math.min(ListItemCount * 20 + 1, MAX_DROPDOWN_ITEMS * 20 + 1), ViewportSize.Y)
            ListOuter.Size = UDim2.fromOffset(Width, Height)
        end

        local function RecalculateListPosition(Force)
            if not ListOuter.Visible and not Force then
                return
            end
            local ViewportSize = GetListViewportSize()
            local AnchorPosition = DropdownOuter.AbsolutePosition
            local AnchorSize = DropdownOuter.AbsoluteSize
            local ListSize = ListOuter.AbsoluteSize
            local X = math.clamp(AnchorPosition.X, 0, math.max(0, ViewportSize.X - ListSize.X))
            local BelowY = AnchorPosition.Y + AnchorSize.Y + 1
            local AboveY = AnchorPosition.Y - ListSize.Y - 1
            local Y

            if BelowY + ListSize.Y <= ViewportSize.Y then
                Y = BelowY
            elseif AboveY >= 0 then
                Y = AboveY
            else
                Y = math.clamp(BelowY, 0, math.max(0, ViewportSize.Y - ListSize.Y))
            end

            ListOuter.Position = UDim2.fromOffset(X, Y)
        end

        RecalculateListSize()
        RecalculateListPosition()

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition)
        DropdownOuter:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            RecalculateListSize()
            RecalculateListPosition()
        end)
        ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            RecalculateListSize()
            RecalculateListPosition()
        end)

        local ListInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 5001,
            Parent = ListOuter
        })

        local Scrolling = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 5002,
            Parent = ListInner,
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
            ScrollBarImageTransparency = 1
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Scrolling
        })

        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ''

            if Info.Multi then
                for Index, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', '
                    end
                end

                Str = string.sub(Str, 1, #Str - 2)
            else
                Str = Dropdown.Value or ''
            end

            ItemList.Text = (Str == '' and '--' or Str)
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local Buttons = {}

            for _,Element in next, Scrolling:GetChildren() do
                if Element:IsA('GuiObject') then
                    Element:Destroy()
                end
            end

            local Count = 0

            for Index, Value in next, Values do
                local Table = {}

                Count += 1

                local Button = Library:Create("Frame", {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderMode = Enum.BorderMode.Middle,
                    Size = UDim2.new(1, -1, 0, 20),
                    ZIndex = 5003,
                    Active = true,
                    Parent = Scrolling
                })

                local ButtonLabel = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, -6, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    TextSize = 14,
                    Text = Value,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5004,
                    Parent = Button
                })

                Library:OnHighlight(Button, Button, {BorderColor3 = "AccentColor", ZIndex = 5004}, {BorderColor3 = "OutlineColor", ZIndex = 5003})

                local Selected

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor
                end

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected

                        if Info.Multi or Try or Info.AllowNull then
                            if Info.Multi then
                                Selected = Try
                                if Selected then
                                    Dropdown.Value[Value] = true
                                else
                                    Dropdown.Value[Value] = nil
                                end
                            else
                                Selected = Try
                                if Selected then
                                    Dropdown.Value = Value
                                else
                                    Dropdown.Value = nil
                                end

                                for _,OtherButton in next, Buttons do
                                    OtherButton:UpdateButton()
                                end
                            end

                            Table:UpdateButton()
                            Dropdown:Display()

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:UpdateDependencyBoxes()
                        elseif Info.CallbackOnSameValue then
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        end
                    end
                end)

                Table:UpdateButton()
                Buttons[Button] = Table
            end

            Dropdown:Display()
            ListItemCount = Count
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1)
            RecalculateListSize()
            RecalculateListPosition()
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end
            Dropdown:BuildDropdownList()
        end

        function Dropdown:OpenDropdown()
            if IsDropdownOpen then
                return
            end

            RecalculateListSize()
            RecalculateListPosition(true)
            local TargetSize = ListOuter.Size
            local TargetPosition = ListOuter.Position
            local TargetX, TargetY = TargetPosition.X.Offset, TargetPosition.Y.Offset
            local TargetWidth, TargetHeight = TargetSize.X.Offset, TargetSize.Y.Offset
            local IsAboveAnchor = TargetY < DropdownOuter.AbsolutePosition.Y

            DropdownAnimationVersion += 1
            if DropdownTween then
                DropdownTween:Cancel()
            end

            Scrolling.ScrollBarImageTransparency = 1
            ListOuter.Size = UDim2.fromOffset(TargetWidth, 0)
            ListOuter.Position = UDim2.fromOffset(TargetX, IsAboveAnchor and TargetY + TargetHeight or TargetY)
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = DropdownOuter
            IsDropdownOpen = true
            DropdownTween = TweenService:Create(ListOuter, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = TargetSize,
                Position = TargetPosition
            })
            local Version = DropdownAnimationVersion
            DropdownTween.Completed:Connect(function(PlaybackState)
                if Version == DropdownAnimationVersion and PlaybackState == Enum.PlaybackState.Completed then
                    Scrolling.ScrollBarImageTransparency = ListItemCount * 20 + 1 > TargetHeight and 0 or 1
                end
            end)
            DropdownTween:Play()
            TweenGuiProperty(DropdownArrow, 'Rotation', 180)
        end

        function Dropdown:CloseDropdown()
            if not IsDropdownOpen then
                return
            end

            IsDropdownOpen = false
            DropdownAnimationVersion += 1
            local Version = DropdownAnimationVersion
            if DropdownTween then
                DropdownTween:Cancel()
            end
            Scrolling.ScrollBarImageTransparency = 1

            local CurrentPosition = ListOuter.Position
            local CurrentSize = ListOuter.Size
            local CurrentY = CurrentPosition.Y.Offset
            local IsAboveAnchor = CurrentY < DropdownOuter.AbsolutePosition.Y
            DropdownTween = TweenService:Create(ListOuter, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(CurrentSize.X.Offset, 0),
                Position = UDim2.fromOffset(CurrentPosition.X.Offset, IsAboveAnchor and CurrentY + CurrentSize.Y.Offset or CurrentY)
            })
            DropdownTween.Completed:Connect(function(PlaybackState)
                if Version == DropdownAnimationVersion and PlaybackState == Enum.PlaybackState.Completed then
                    ListOuter.Visible = false
                    Library.OpenedFrames[ListOuter] = nil
                    ListOuter.Size = UDim2.fromOffset(CurrentSize.X.Offset, 0)
                end
            end)
            DropdownTween:Play()
            TweenGuiProperty(DropdownArrow, 'Rotation', 0)
        end

        ListOuter:GetPropertyChangedSignal('Visible'):Connect(function()
            if not ListOuter.Visible and IsDropdownOpen then
                IsDropdownOpen = false
                DropdownAnimationVersion += 1
                if DropdownTween then
                    DropdownTween:Cancel()
                end
                Library.OpenedFrames[ListOuter] = nil
                Scrolling.ScrollBarImageTransparency = 1
                TweenGuiProperty(DropdownArrow, 'Rotation', 0)
            end
        end)

        function Dropdown:SetValue(Value, Silent)
            local Changed = false
            if Dropdown.Multi then
                local nTable = {}

                for Index, Selected in next, Value do
                    if Selected and table.find(Dropdown.Values, Index) then
                        nTable[Index] = true
                    end
                end

                local Old = Dropdown.Value or {}
                for _Index in next, nTable do
                    if not Old[_Index] then
                        Changed = true
                        break
                    end
                end
                if not Changed then
                    for _Index in next, Old do
                        if not nTable[_Index] then
                            Changed = true
                            break
                        end
                    end
                end
                Dropdown.Value = nTable
            else
                local NewValue
                if Value and table.find(Dropdown.Values, Value) then
                    NewValue = Value
                elseif Value then
                    NewValue = Dropdown.Value
                end
                Changed = NewValue ~= Dropdown.Value
                Dropdown.Value = NewValue
            end

            Dropdown:BuildDropdownList()
            if not Silent and (Changed or Info.CallbackOnSameValue) then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            end
            Library:UpdateDependencyBoxes()
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame(DropdownOuter) then
                if IsDropdownOpen then
                    Dropdown:CloseDropdown()
                else
                    Dropdown:OpenDropdown()
                end
            end
        end)

        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or not ListOuter.Visible or not Library:IsInputActive(DropdownOuter) then
                return
            end

            local Position = Input.Position
            local function IsInside(Frame)
                local FramePosition, FrameSize = Frame.AbsolutePosition, Frame.AbsoluteSize
                return Position.X >= FramePosition.X and Position.X <= FramePosition.X + FrameSize.X  and Position.Y >= FramePosition.Y and Position.Y <= FramePosition.Y + FrameSize.Y
            end

            if not IsInside(DropdownOuter) and not IsInside(ListOuter) then
                Dropdown:CloseDropdown()
            end
        end)

        local Default = Info.Default
        if type(Default) == "number" then
            Default = Dropdown.Values[Default]
        end

        if Info.Multi and type(Default) ~= "table" then
            Default = Default and {[Default] = true} or {}
        end

        Dropdown:SetValue(Default, true)
        Groupbox:AddBlank(Info.BlankSize or 5)
        Groupbox:Resize()

        Library:UpdateDependencyBoxes()
        Options[Index] = Dropdown
        Dropdown.Outer = DropdownOuter
        return Dropdown
    end

    function Funcs:AddDependencyBox()
        local Depbox = {Dependencies = {}}

        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Container
        })

        local Frame = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = true,
            Parent = Holder
        })

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Frame
        })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize()
        end)

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            if not Holder.Visible then
                Library:ClosePopups(Holder)
            end
            Depbox:Resize()
        end)

        function Depbox:Update()
            for _,Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]
                local Match = false

                if type(Value) == "table" then
                    Match = table.find(Value, Elem.Value)
                else
                    Match = (Elem.Value == Value)
                end

                if not Match then
                    Holder.Visible = false
                    Depbox:Resize()
                    return
                end
            end

            Holder.Visible = true
            Depbox:Resize()
        end

        function Depbox:SetupDependencies(Dependencies)
            for _,Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.')
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.')
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.')
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
            return self
        end

        Depbox.Container = Frame
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox
    end

    BaseGroupbox.__index = Funcs

    Library.BaseGroupbox = BaseGroupbox
end

do
    Library.NotificationArea = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 300, 0, 200),
        ZIndex = 100,
        Parent = ScreenGui
    })

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Library.NotificationArea
    })

    local WatermarkOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(1, -18, 0, 18),
        Size = UDim2.new(0, 213, 0, 20),
        ZIndex = 400,
        Visible = false,
        Parent = ScreenGui
    })

    local WatermarkInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 401,
        Parent = WatermarkOuter
    })

    local InnerFrame = Library:Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 402,
        Parent = WatermarkInner
    })

    Library:Create("UIGradient", {
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor)}),
        Rotation = -90,
        Parent = InnerFrame
    })

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        TextSize = 14,
        Text = "PhantomWare",
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 403,
        Parent = InnerFrame,
    })

    Library.Watermark = WatermarkOuter
    Library.WatermarkText = WatermarkLabel
    Library:MakeDraggable(Library.Watermark)

    local KeybindOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 210, 0, 20),
        Visible = true,
        ZIndex = 100,
        Parent = ScreenGui,
    })

    local KeybindInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = KeybindOuter,
    })

    Library:Create("Frame", {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 102,
        Parent = KeybindInner
    })

    Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Active Keybind List",
        ZIndex = 104,
        Parent = KeybindInner
    })

    local ActiveKeybindContainer = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        ZIndex = 1,
        Parent = KeybindInner
    })

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ActiveKeybindContainer
    })

    Library:Create('UIPadding', {PaddingLeft = UDim.new(0, 5),  Parent = ActiveKeybindContainer})
    Library.ActiveKeybindFrame = KeybindOuter
    Library.ActiveKeybindContainer = ActiveKeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14)
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
    Library.Watermark.Visible = true
    Library.WatermarkText.Text = Text
end

Library.WatermarkOptions = {Enabled = false, Color = Color3.fromRGB(255, 255, 255)}
Library.WatermarkState = {Frames = 0, LastUpdate = 0}

function Library:GetPing()
    local Success, Value = pcall(function()
        return game:GetService("Stats").PerformanceStats.Ping:GetValue()
    end)
    return Success and math.floor(Value) or 0
end

function Library:UpdateWatermark()
    local Options = Library.WatermarkOptions
    if not Options.Enabled then
        return
    end
    Library.WatermarkState.Frames += 1

    local Now = os.clock()
    if Now - Library.WatermarkState.LastUpdate >= 0.3 then
        local FPS = math.floor(Library.WatermarkState.Frames / (Now - Library.WatermarkState.LastUpdate))
        Library.WatermarkState.Frames, Library.WatermarkState.LastUpdate = 0, Now
        Library.WatermarkText.TextColor3 = Library.WatermarkOptions.Color
        Library:SetWatermark("PhantomWare | " .. FPS .. " fps | " .. Library:GetPing() .. " ms")
    end
end

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14)
    YSize += 7

    local NotifyOuter = Library:Create("Frame", {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 100, 0, 10),
        Size = UDim2.new(0, 0, 0, YSize),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = Library.NotificationArea
    })

    local NotifyInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = NotifyOuter
    })

    local InnerFrame = Library:Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 102,
        Parent = NotifyInner
    })

    Library:Create("UIGradient", {
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor)}),
        Rotation = -90,
        Parent = InnerFrame
    })

    Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        Text = Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 14,
        ZIndex = 103,
        Parent = InnerFrame
    })

    Library:Create("Frame", {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, -1, 0, -1),
        Size = UDim2.new(0, 3, 1, 2),
        ZIndex = 104,
        Parent = NotifyOuter
    })

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true)
    task.spawn(function()
        task.wait(Time or 5)
        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true)
        task.wait(0.4)
        NotifyOuter:Destroy()
    end)
end

local ConfigKeys = {None = true, MB1 = true, MB2 = true}
for _,Key in ipairs(Enum.KeyCode:GetEnumItems()) do
    ConfigKeys[Key.Name] = true
end

local function ValidateConfig(Data)
    if type(Data) ~= "table" then
        return false, "Invalid configuration data."
    end

    for Flag, Saved in next, Data do
        if type(Flag) ~= "string" or type(Saved) ~= "table" or type(Saved.Type) ~= "string" or Saved.Value == nil then
            return false, "Invalid config entry: " .. tostring(Flag)
        end

        local Option = Toggles[Flag] or Options[Flag]
        if not Option then
            continue
        end

        local Type, Value = Saved.Type, Saved.Value
        local Valid = Type == Option.Type
        if Valid then
            if Type == "Toggle" then
                Valid = type(Value) == "boolean"
            elseif Type == "Slider" then
                Valid = type(Value) == "number" and math.abs(Value) < math.huge
            elseif Type == "Dropdown" then
                if Option.Multi then
                    Valid = type(Value) == "table"
                    if Valid then
                        if Flag == "ESPVisuals_HeadTagStaticElements" then
                            Value.Stance = nil
                            Value.Ammo = nil
                        elseif Flag == "ESPVisuals_HeadTagStatusElements" then
                            Value.Grenade = nil
                            Value.Reloading = nil
                        end
                        for Name, Selected in next, Value do
                            if type(Selected) ~= "boolean" or not table.find(Option.Values, Name) then
                                Valid = false
                                break
                            end
                        end
                    end
                else
                    Valid = table.find(Option.Values, Value)
                end
            elseif Type == "KeyPicker" then
                Valid = type(Value) == "string" and ConfigKeys[Value]
                    and (Saved.Mode == nil or table.find(Option.Modes, Saved.Mode))
            elseif Type == "ColorPicker" then
                Valid = type(Value) == "string" and string.match(Value, "^%x%x%x%x%x%x$")
                    and (Saved.Transparency == nil or (type(Saved.Transparency) == "number" and Saved.Transparency >= 0 and Saved.Transparency <= 1))
            else
                Valid = false
            end
        end

        if not Valid then
            return false, "Invalid config value: " .. Flag
        end
    end

    return true
end

function Library:ApplyConfiguration(Data)
    local Valid, Error = ValidateConfig(Data)
    if not Valid then
        Library:Notify(Error, 3)
        return
    end

    for Flag, Saved in next, Data do
        local Option = Toggles[Flag] or Options[Flag]
        if not Option then
            continue
        end
        if Saved.Type == "ColorPicker" then
            Option:SetValueRGB(Color3.fromHex(Saved.Value), Saved.Transparency)
        elseif Saved.Type == "KeyPicker" then
            Option:SetValue({Saved.Value, Saved.Mode or Option.Mode})
        else
            Option:SetValue(Saved.Value)
        end
    end

    for _,Option in next, Options do
        if Option.Type == "KeyPicker" and Option.SyncToggleState and Option.Mode ~= "Toggle" then
            Option:DoClick()
        end
    end

    return true
end

local function WriteLocalConfig(Name, Data)
    local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, Data)
    if not Success then
        Library:Notify("Failed to serialize configuration.", 3)
        return
    end

    writefile("NikoletoScripts/PhantomWare/Configs/" .. Name .. ".ns", Encoded)
    return true
end

local function GetAutoload()
    if isfile("NikoletoScripts/PhantomWare/Autoload.ns") then
        local Name = readfile("NikoletoScripts/PhantomWare/Autoload.ns")
        if #Name > 0 then
            return Name
        end
    end
end

local function LoadLocalConfig(Name)
    local Path = "NikoletoScripts/PhantomWare/Configs/" .. Name .. ".ns"
    local Content = isfile(Path) and readfile(Path)
    if not Content then
        Library:Notify("Config no longer exists.", 3)
        return
    end

    local Success, Data = pcall(HttpService.JSONDecode, HttpService, Content)
    if not Success or type(Data) ~= "table" then
        Library:Notify("Invalid Configuration Profile: " .. Name, 3)
        return
    end

    if not Library:ApplyConfiguration(Data) then
        return
    end
    Library:Notify("Loaded Configuration Profile: " .. Name, 3)
    return true
end

function Library:BuildUI(UIState, UIFeatures, GameData, PlayerData, ExecutorName)
    local AimingTab, VisualsTab, MiscellaneousTab, SettingsTab, ConfigsTab = (function()
        local ActiveTab
        local Outer = Library:Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(550, 600),
            Visible = false,
            ZIndex = 1,
            Parent = ScreenGui
        })

        Library:Create("UICorner", {
            CornerRadius = UDim.new(0, 3),
            Parent = Outer,
        })

        Library:MakeDraggable(Outer, 25)

        local Inner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 1,
            Parent = Outer
        })

        Library:Create("UIStroke", {
            Color = Library.AccentColor,
            Thickness = 1,
            Parent = Inner,
        })

        Library:CreateLabel({
            Position = UDim2.new(0, 7, 0, 0),
            Size = UDim2.new(0, 0, 0, 25),
            Text = "PhantomWare | discord.gg/DsGCKtxxEN" .. (ExecutorName and (" | " .. ExecutorName) or ""),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1,
            Parent = Inner
        })

        local MainSectionOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            Position = UDim2.new(0, 8, 0, 25),
            Size = UDim2.new(1, -16, 1, -33),
            ZIndex = 1,
            Parent = Inner
        })

        local MainSectionInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Color3.new(0, 0, 0),
            BorderMode = Enum.BorderMode.Inset,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 1,
            Parent = MainSectionOuter
        })

        local TabArea = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -16, 0, 21),
            ZIndex = 1,
            Parent = MainSectionInner
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TabArea
        })

        local TabContainer = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            Position = UDim2.new(0, 8, 0, 30),
            Size = UDim2.new(1, -16, 1, -38),
            ZIndex = 2,
            Parent = MainSectionInner
        })

        local function AddTab(Name)
            local Tab = {}
            local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16)

            local TabButton = Library:Create("Frame", {
                Active = true,
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0),
                ZIndex = 1,
                Parent = TabArea
            })

            Library:CreateLabel({
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, -1),
                Text = Name,
                ZIndex = 1,
                Parent = TabButton
            })

            local Blocker = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 1),
                Visible = false,
                ZIndex = 3,
                Parent = TabButton
            })

            local TabFrame = Library:Create("Frame", {
                Name = 'TabFrame',
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                Visible = false,
                ZIndex = 2,
                Parent = TabContainer
            })

            local LeftSide = Library:Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 8 - 1, 0, 8 - 1),
                Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                BottomImage = '',
                TopImage = '',
                ScrollBarThickness = 0,
                ZIndex = 2,
                Parent = TabFrame
            })

            local RightSide = Library:Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1),
                Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                BottomImage = '',
                TopImage = '',
                ScrollBarThickness = 0,
                ZIndex = 2,
                Parent = TabFrame
            })

            for _,Side in next, {LeftSide, RightSide} do
                local Layout = Library:Create('UIListLayout', {
                    Padding = UDim.new(0, 8),
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    Parent = Side
                })
                Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    Side.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y)
                end)
            end

            function Tab:ShowTab()
                for Frame in next, Library.OpenedFrames do
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end

                if Library.ConfigOverlay then
                    Library.ConfigOverlay.Visible = false
                end

                if ActiveTab then
                    ActiveTab:HideTab()
                end
                ActiveTab = Tab

                Blocker.Visible = true
                TabButton.BackgroundColor3 = Library.MainColor
                TabFrame.Visible = true
            end

            function Tab:HideTab()
                Blocker.Visible = false
                TabButton.BackgroundColor3 = Library.BackgroundColor
                TabFrame.Visible = false
            end

            function Tab:AddGroupbox(Name, Parent)
                local Groupbox = {}

                local BoxOuter = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderMode = Enum.BorderMode.Inset,
                    Size = UDim2.new(1, 0, 0, 507 + 2),
                    ZIndex = 2,
                    Parent = Parent
                })

                local BoxInner = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1),
                    ZIndex = 4,
                    Parent = BoxOuter
                })

                Library:Create("Frame", {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 2),
                    ZIndex = 5,
                    Parent = BoxInner
                })

                Library:CreateLabel({
                    Size = UDim2.new(1, 0, 0, 18),
                    Position = UDim2.new(0, 4, 0, 2),
                    TextSize = 14,
                    Text = Name,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5,
                    Parent = BoxInner
                })

                local Container = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 4, 0, 20),
                    Size = UDim2.new(1, -4, 1, -20),
                    ZIndex = 1,
                    Parent = BoxInner
                })

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = Container
                })

                function Groupbox:Resize()
                    local Size = 0

                    for _,Element in next, Groupbox.Container:GetChildren() do
                        if Element:IsA('GuiObject') and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
                end

                Groupbox.Container = Container
                setmetatable(Groupbox, BaseGroupbox)

                Groupbox:AddBlank(3)
                Groupbox:Resize()

                return Groupbox
            end

            function Tab:AddLeftGroupbox(Name)
                return Tab:AddGroupbox(Name, LeftSide)
            end

            function Tab:AddRightGroupbox(Name)
                return Tab:AddGroupbox(Name, RightSide)
            end

            function Tab:AddTabbox(Parent)
                local Tabbox = {Tabs = {}}

                local BoxOuter = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderMode = Enum.BorderMode.Inset,
                    Size = UDim2.new(1, 0, 0, 0),
                    ZIndex = 2,
                    Parent = Parent
                })

                local BoxInner = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1),
                    ZIndex = 4,
                    Parent = BoxOuter
                })

                Library:Create("Frame", {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 2),
                    ZIndex = 10,
                    Parent = BoxInner
                })

                local TabboxButtons = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 1),
                    Size = UDim2.new(1, 0, 0, 18),
                    ZIndex = 5,
                    Parent = BoxInner
                })

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = TabboxButtons
                })

                function Tabbox:AddTab(Name)
                    local Tab = {}

                    local Button = Library:Create("Frame", {
                        Active = true,
                        BackgroundColor3 = Library.MainColor,
                        BorderColor3 = Color3.new(0, 0, 0),
                        Size = UDim2.new(0.5, 0, 1, 0),
                        ZIndex = 6,
                        Parent = TabboxButtons
                    })

                    Library:CreateLabel({
                        Size = UDim2.new(1, 0, 1, 0),
                        TextSize = 14,
                        Text = Name,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 7,
                        Parent = Button
                    })

                    local Block = Library:Create("Frame", {
                        BackgroundColor3 = Library.BackgroundColor,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 1, 0),
                        Size = UDim2.new(1, 0, 0, 1),
                        Visible = false,
                        ZIndex = 9,
                        Parent = Button
                    })

                    local Container = Library:Create("Frame", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 4, 0, 20),
                        Size = UDim2.new(1, -4, 1, -20),
                        ZIndex = 1,
                        Visible = false,
                        Parent = BoxInner
                    })

                    Library:Create('UIListLayout', {
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = Container
                    })

                    function Tab:Show()
                        for _,Tab in next, Tabbox.Tabs do
                            Tab:Hide()
                        end

                        Container.Visible = true
                        Block.Visible = true

                        Button.BackgroundColor3 = Library.BackgroundColor

                        Tab:Resize()
                    end

                    function Tab:Hide()
                        Container.Visible = false
                        Block.Visible = false

                        Button.BackgroundColor3 = Library.MainColor
                    end

                    function Tab:Resize()
                        local TabCount = #Tabbox.Tabs

                        for _,Button in next, TabboxButtons:GetChildren() do
                            if Button:IsA('GuiObject') then
                                Button.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                            end
                        end

                        if (not Container.Visible) then
                            return
                        end

                        local Size = 0

                        for _,Element in next, Tab.Container:GetChildren() do
                            if Element:IsA('GuiObject') and Element.Visible then
                                Size = Size + Element.Size.Y.Offset
                            end
                        end

                        BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
                    end

                    Button.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame(Button) then
                            Tab:Show()
                        end
                    end)

                    Tab.Container = Container
                    Tabbox.Tabs[#Tabbox.Tabs + 1] = Tab

                    setmetatable(Tab, BaseGroupbox)

                    Tab:AddBlank(3)
                    Tab:Resize()

                    if #Tabbox.Tabs == 1 then
                        Tab:Show()
                    end

                    return Tab
                end

                return Tabbox
            end

            function Tab:AddLeftTabbox()
                return Tab:AddTabbox(LeftSide)
            end

            function Tab:AddRightTabbox()
                return Tab:AddTabbox(RightSide)
            end

            TabButton.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Tab:ShowTab()
                end
            end)

            if not ActiveTab then
                Tab:ShowTab()
            end

            Tab.Frame = TabFrame
            return Tab
        end

        local ModalElement = Library:Create('TextButton', {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
            Visible = true,
            Text = '',
            Modal = false,
            Parent = ScreenGui
        })

        local TransparencyCache = {}
        Outer.DescendantRemoving:Connect(function(Descendant)
            TransparencyCache[Descendant] = nil
        end)
        local Toggled = false
        local Fading = false
        local FadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

        function Library:Toggle()
            if Fading then
                return
            end

            Fading = true
            Toggled = not Toggled
            ModalElement.Modal = Toggled
            Library.Toggled = Toggled
            TweenService:Create(Outer, FadeInfo, {BackgroundTransparency = Toggled and 0 or 1}):Play()

            if Toggled then
                ScreenGui.Enabled = true
                Outer.Visible = true
                task.spawn(function()
                    local State = UserInputService.MouseIconEnabled

                    local Cursor = Drawing.new('Triangle')
                    Cursor.Thickness = 1
                    Cursor.Filled = true
                    Cursor.Visible = true

                    local CursorOutline = Drawing.new('Triangle')
                    CursorOutline.Thickness = 1
                    CursorOutline.Filled = false
                    CursorOutline.Color = Color3.new(0, 0, 0)
                    CursorOutline.Visible = true

                    while Toggled and ScreenGui.Parent do
                        UserInputService.MouseIconEnabled = false

                        local MouseLocation = UserInputService:GetMouseLocation()

                        Cursor.Color = Library.AccentColor

                        Cursor.PointA = Vector2.new(MouseLocation.X, MouseLocation.Y)
                        Cursor.PointB = Vector2.new(MouseLocation.X + 16, MouseLocation.Y + 6)
                        Cursor.PointC = Vector2.new(MouseLocation.X + 6, MouseLocation.Y + 16)

                        CursorOutline.PointA = Cursor.PointA
                        CursorOutline.PointB = Cursor.PointB
                        CursorOutline.PointC = Cursor.PointC

                        PreRender:Wait()
                    end

                    UserInputService.MouseIconEnabled = State
                    Cursor:Remove()
                    CursorOutline:Remove()
                end)
            end

            for _,Descendant in Outer:QueryDescendants("ImageLabel, TextLabel, TextBox, TextButton, Frame, ScrollingFrame, UIStroke") do
                local Properties = {}

                if Descendant:IsA("ImageLabel") then
                    table.insert(Properties, "ImageTransparency")
                    table.insert(Properties, "BackgroundTransparency")
                elseif Descendant:IsA("TextLabel") or Descendant:IsA("TextBox") or Descendant:IsA("TextButton") then
                    table.insert(Properties, "TextTransparency")
                    table.insert(Properties, "BackgroundTransparency")
                elseif Descendant:IsA("Frame") or Descendant:IsA("ScrollingFrame") then
                    table.insert(Properties, "BackgroundTransparency")
                elseif Descendant:IsA("UIStroke") then
                    table.insert(Properties, "Transparency")
                end

                local Cache = TransparencyCache[Descendant]
                if not Cache then
                    Cache = {}
                    TransparencyCache[Descendant] = Cache
                end

                for _,Prop in next, Properties do
                    local Transparency = Prop == "BackgroundTransparency" and Descendant:GetAttribute("FadeTransparency")
                    if Transparency then
                        Cache[Prop] = Transparency
                    elseif not Cache[Prop] or not Toggled then
                        Cache[Prop] = Descendant[Prop]
                    end

                    if Cache[Prop] == 1 then
                        continue
                    end
                    if Toggled then
                        Descendant[Prop] = 1
                    end

                    TweenGuiProperty(Descendant, Prop, Toggled and Cache[Prop] or 1, FadeInfo)
                end
            end

            task.wait(0.2)
            Outer.Visible = Toggled
            if not Toggled then
                for Frame in next, Library.OpenedFrames do
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
                if Library.ConfigOverlay then
                    Library.ConfigOverlay.Visible = false
                end
            end
            Fading = false
        end

        return AddTab("Aiming"), AddTab("Visuals"), AddTab("Miscellaneous"), AddTab("Settings"), AddTab("Configs")
    end)()

    local function Build_AimingTab()
        local Aiming_RageBot = AimingTab:AddRightGroupbox("RageBot")
        local Aiming_Aimbot = AimingTab:AddLeftGroupbox("Aimbot")

        local AimbotEnabledToggle = Aiming_Aimbot:AddToggle("Aimbot_Enabled", {Text = "Enabled", Default = UIState[1].Aimbot_Enabled, Callback = function(Value)
            UIState[1].Aimbot_Enabled = Value
        end})
        AimbotEnabledToggle:AddDropdown("Aimbot_Type", {Default = UIState[1].Aimbot_Type, Values = {"None", "Camera", "Mouse", "Silent"}, Callback = function(Value)
            UIState[1].Aimbot_Type = Value
        end})
        AimbotEnabledToggle:AddKeyPicker("Aimbot_Keybind", {Default = "None", Mode = "Toggle", Text = "Aimbot", SyncToggleState = true})

        local AimbotDependencyBox = Aiming_Aimbot:AddDependencyBox():SetupDependencies({{Toggles.Aimbot_Enabled, true}})

        AimbotDependencyBox:AddDropdown("Aimbot_Part", {Text = "Part", Default = UIState[1].Aimbot_Part, Values = {"Head", "Torso", "Closest", "Best"}, Callback = function(Value)
            UIState[1].Aimbot_Part = Value
        end})

        AimbotDependencyBox:AddDependencyBox():SetupDependencies({{Options.Aimbot_Type, {"Camera", "Mouse", "Silent"}}}):AddDivider()

        AimbotDependencyBox:AddDependencyBox():SetupDependencies({{Options.Aimbot_Type, {"Camera", "Mouse"}}}):AddSlider("Aimbot_Smoothness", {
            Text = "Smoothness", Default = UIState[1].Aimbot_Smoothness, Min = 1, Max = 10, Rounding = 1, Callback = function(Value)
                UIState[1].Aimbot_Smoothness = Value
            end
        })

        local RedirectGrenadeMenu = AimbotDependencyBox:AddToggle("Aimbot_RedirectGrenade", {Text = "Redirect Grenade", Default = UIState[1].Aimbot_RedirectGrenade, Callback = function(Value)
            UIState[1].Aimbot_RedirectGrenade = Value
        end}):AddSettingsMenu("Redirect Grenade Settings")
        RedirectGrenadeMenu:AddToggle("Aimbot_FuseAssist", {Text = "Fuse Assist", Default = UIState[1].Aimbot_FuseAssist, Callback = function(Value)
            UIState[1].Aimbot_FuseAssist = Value
        end})

        local SilentDependencyBox = AimbotDependencyBox:AddDependencyBox():SetupDependencies({{Options.Aimbot_Type, "Silent"}})
        local AimbotCollateralMenu = SilentDependencyBox:AddToggle("Aimbot_Collateral", {
            Text = "Collateral", Default = UIState[1].Aimbot_Collateral, Callback = function(Value)
                UIState[1].Aimbot_Collateral = Value
            end
        }):AddSettingsMenu("Collateral Settings")
        AimbotCollateralMenu:AddSlider("Aimbot_CollateralRadius", {
            Text = "Radius", Default = UIState[1].Aimbot_CollateralRadius, Min = 1, Max = 9.9, Rounding = 1, Callback = function(Value)
                UIState[1].Aimbot_CollateralRadius = Value
            end
        })

        local AutoFireMenu = SilentDependencyBox:AddToggle("Aimbot_AutoFire", {
            Text = "Auto Fire", Default = UIState[1].Aimbot_AutoFire, Callback = function(Value)
                UIState[1].Aimbot_AutoFire = Value
                if not Value then
                    UIFeatures[10]:SetFiring()
                end
            end
        }):AddSettingsMenu("Auto Fire Settings")
        AutoFireMenu:AddToggle("Aimbot_AutoWall", {
            Text = "Auto Wall", Default = UIState[1].Aimbot_AutoWall, Callback = function(Value)
                UIState[1].Aimbot_AutoWall = Value
            end
        })
        AutoFireMenu:AddSlider("Aimbot_AutoDelay", {
            Text = "Delay (ms)", Default = UIState[1].Aimbot_AutoDelay, Min = 0, Max = 500, Rounding = 0, Callback = function(Value)
                UIState[1].Aimbot_AutoDelay = Value
            end
        })

        SilentDependencyBox:AddSlider("Aimbot_HitChance", {
            Text = "Hit Chance", Default = UIState[1].Aimbot_HitChance, Min = 0, Max = 100, Rounding = 0, Callback = function(Value)
                UIState[1].Aimbot_HitChance = Value
            end
        })

        AimbotDependencyBox:AddDivider()

        local WallCheckMenu = AimbotDependencyBox:AddToggle("Aimbot_WallCheck", {Text = "Wall Check", Default = UIState[1].Aimbot_WallCheck, Callback = function(Value)
            UIState[1].Aimbot_WallCheck = Value
        end}):AddSettingsMenu("Wall Check Settings")
        WallCheckMenu:AddDropdown("Aimbot_WallCheckAction", {Text = "Action", Default = UIState[1].Aimbot_WallCheckAction, Values = {"Ignore Target", "Pause Aimbot"}, Callback = function(Value)
            UIState[1].Aimbot_WallCheckAction = Value
        end})

        local AimbotHitScanMenu = AimbotDependencyBox:AddToggle("Aimbot_HitScanning", {Text = "Hit Scanning", Default = UIState[1].Aimbot_HitScanning, Callback = function(Value)
            UIState[1].Aimbot_HitScanning = Value
        end}):AddSettingsMenu("Hit Scanning Settings")
        AimbotHitScanMenu:AddDependencyBox():SetupDependencies({{Options.Aimbot_Type, {"None", "Camera", "Mouse"}}}):AddDropdown("Aimbot_HitScanningMode", {Text = "Scan Mode", Default = UIState[1].Aimbot_HitScanningMode, Values = {"Cardinal", "Sphere", "Corners"}, Callback = function(Value)
            UIState[1].Aimbot_HitScanningMode = Value
        end})

        local SilentScanBox = AimbotHitScanMenu:AddDependencyBox():SetupDependencies({{Options.Aimbot_Type, "Silent"}})
        SilentScanBox:AddDropdown("Aimbot_HitScanningAxes", {Text = "Axes", Default = UIState[1].Aimbot_HitScanningAxes, Values = {"X", "Y", "Z"}, Multi = true, Callback = function(Value)
            UIState[1].Aimbot_HitScanningAxes = Value
        end})
        SilentScanBox:AddSlider("Aimbot_HitScanningSteps", {Text = "Steps", Default = UIState[1].Aimbot_HitScanningSteps, Min = 1, Max = 5, Rounding = 0, Callback = function(Value)
            UIState[1].Aimbot_HitScanningSteps = Value
        end})
        AimbotHitScanMenu:AddSlider("Aimbot_HitScanningRadius", {
            Text = "Scan Radius", Default = UIState[1].Aimbot_HitScanningRadius, Min = 0.5, Max = 3, Rounding = 1, Callback = function(Value)
                UIState[1].Aimbot_HitScanningRadius = Value
            end
        })

        AimbotDependencyBox:AddToggle("Aimbot_DeathNotification", {Text = "Death Notification", Default = UIState[1].Aimbot_DeathNotification, Callback = function(Value)
            UIState[1].Aimbot_DeathNotification = Value
        end})

        AimbotDependencyBox:AddDivider()

        local FOVMenu = AimbotDependencyBox:AddToggle("Aimbot_ShowFOVCircle", {Text = "FOV Circle", Default = UIState[1].Aimbot_ShowFOVCircle, Callback = function(Value)
            UIState[1].Aimbot_ShowFOVCircle = Value
        end}):AddSettingsMenu("FOV Circle Settings")
        FOVMenu:AddColorPicker("Aimbot_FOVCircleColor", {Default = UIState[1].Aimbot_FOVCircleColor, Transparency = 1 - UIState[1].Aimbot_FOVCircleOpacity}).Callback = function(Value)
            UIState[1].Aimbot_FOVCircleColor = Value
            UIState[1].Aimbot_FOVCircleOpacity = 1 - Options.Aimbot_FOVCircleColor.Transparency
        end
        local FilledBox = FOVMenu:AddDependencyBox()
        FilledBox:AddToggle("Aimbot_FOVCircleFilled", {Text = "Filled", Default = UIState[1].Aimbot_FOVCircleFilled, Callback = function(Value)
            UIState[1].Aimbot_FOVCircleFilled = Value
            if Value and Toggles.Aimbot_FOVCircleDotted and Toggles.Aimbot_FOVCircleDotted.Value then
                Toggles.Aimbot_FOVCircleDotted:SetValue(false)
            end
        end})
        local OutlineBox = FOVMenu:AddDependencyBox():SetupDependencies({{Toggles.Aimbot_FOVCircleFilled, false}})
        OutlineBox:AddToggle("Aimbot_FOVCircleDotted", {Text = "Dotted", Default = UIState[1].Aimbot_FOVCircleDotted, Callback = function(Value)
            UIState[1].Aimbot_FOVCircleDotted = Value
            if Value and Toggles.Aimbot_FOVCircleFilled.Value then
                Toggles.Aimbot_FOVCircleFilled:SetValue(false)
            end
        end})
        FilledBox:SetupDependencies({{Toggles.Aimbot_FOVCircleDotted, false}})
        if Toggles.Aimbot_FOVCircleFilled.Value and Toggles.Aimbot_FOVCircleDotted.Value then
            Toggles.Aimbot_FOVCircleDotted:SetValue(false)
        end
        OutlineBox:AddSlider("Aimbot_FOVCircleThickness", {Text = "Thickness", Default = UIState[1].Aimbot_FOVCircleThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[1].Aimbot_FOVCircleThickness = Value
        end})
        FOVMenu:AddSlider("Aimbot_FOVCircleRadius", {Text = "Radius", Default = UIState[1].Aimbot_FOVCircleRadius, Min = 15, Max = 800, Rounding = 0, Callback = function(Value)
            UIState[1].Aimbot_FOVCircleRadius = Value
        end})
        local FireMenu = FOVMenu:AddToggle("Aimbot_FOVCircleFireExpansion", {Text = "Fire Expansion", Default = UIState[1].Aimbot_FOVCircleFireExpansion, Callback = function(Value)
            UIState[1].Aimbot_FOVCircleFireExpansion = Value
        end}):AddSettingsMenu("Fire Expansion Settings")
        FireMenu:AddSlider("Aimbot_FOVCircleFireAmount", {Text = "Amount", Default = UIState[1].Aimbot_FOVCircleFireAmount, Min = 15, Max = 100, Rounding = 0, Callback = function(Value)
            UIState[1].Aimbot_FOVCircleFireAmount = Value
        end})
        FireMenu:AddSlider("Aimbot_FOVCircleFireDuration", {Text = "Return Duration (s)", Default = UIState[1].Aimbot_FOVCircleFireDuration, Min = 0.05, Max = 1, Rounding = 2, Callback = function(Value)
            UIState[1].Aimbot_FOVCircleFireDuration = Value
        end})
        FOVMenu:AddToggle("Aimbot_FOVCircleFollowRecoil", {Text = "Follow Recoil", Default = UIState[1].Aimbot_FOVCircleFollowRecoil, Callback = function(Value)
            UIState[1].Aimbot_FOVCircleFollowRecoil = Value
        end})

        AimbotDependencyBox:AddToggle("Aimbot_TargetTracer", {Text = "Target Tracer", Default = UIState[1].Aimbot_TargetTracer, Callback = function(Value)
            UIState[1].Aimbot_TargetTracer = Value
        end}):AddColorPicker("Aimbot_TargetTracerColor", {Default = UIState[1].Aimbot_TargetTracerColor, Transparency = 1 - UIState[1].Aimbot_TargetTracerOpacity, Callback = function(Value)
            UIState[1].Aimbot_TargetTracerColor = Value
            UIState[1].Aimbot_TargetTracerOpacity = 1 - Options.Aimbot_TargetTracerColor.Transparency
        end})

        Aiming_RageBot:AddToggle("RageBot_Enabled", {Text = "Enabled", Default = UIState[1].RageBot_Enabled, Callback = function(Value)
            UIState[1].RageBot_Enabled = Value
        end}):AddKeyPicker("RageBot_Keybind", {Default = "None", Mode = "Toggle", Text = "RageBot", SyncToggleState = true})

        local RageBotDependencyBox = Aiming_RageBot:AddDependencyBox():SetupDependencies({{Toggles.RageBot_Enabled, true}})
        RageBotDependencyBox:AddToggle("RageBot_BlockShooting", {Text = "Block Shooting", Default = UIState[1].RageBot_BlockShooting, Callback = function(Value)
            UIState[1].RageBot_BlockShooting = Value
        end})
        RageBotDependencyBox:AddDropdown("RageBot_Part", {Text = "Part", Default = UIState[1].RageBot_Part, Values = {"Head", "Torso", "Best"}, Callback = function(Value)
            UIState[1].RageBot_Part = Value
        end})

        RageBotDependencyBox:AddDivider()

        RageBotDependencyBox:AddToggle("RageBot_WallPenetrationDetection", {Text = "Wall Penetration Detection", Default = UIState[1].RageBot_WallPenetrationDetection, Callback = function(Value)
            UIState[1].RageBot_WallPenetrationDetection = Value
        end})

        local RageBotCollateralMenu = RageBotDependencyBox:AddToggle("RageBot_Collateral", {Text = "Collateral", Default = UIState[1].RageBot_Collateral, Callback = function(Value)
            UIState[1].RageBot_Collateral = Value
        end}):AddSettingsMenu("Collateral Settings")
        RageBotCollateralMenu:AddSlider("RageBot_CollateralRadius", {
            Text = "Radius", Default = UIState[1].RageBot_CollateralRadius, Min = 1, Max = 9.9, Rounding = 1, Callback = function(Value)
                UIState[1].RageBot_CollateralRadius = Value
            end
        })

        RageBotDependencyBox:AddDivider()

        local HitScanMenu = RageBotDependencyBox:AddToggle("RageBot_HitScanning", {Text = "Hit Scanning", Default = UIState[1].RageBot_HitScanning, Callback = function(Value)
            UIState[1].RageBot_HitScanning = Value
        end}):AddSettingsMenu("Hit Scanning Settings")
        HitScanMenu:AddDropdown("RageBot_HitScanningMode", {Text = "Scan Mode", Default = UIState[1].RageBot_HitScanningMode, Values = {"Cardinal", "Sphere", "Corners"}, Callback = function(Value)
            UIState[1].RageBot_HitScanningMode = Value
        end})
        HitScanMenu:AddSlider("RageBot_HitScanningRadius", {
            Text = "Scan Radius", Default = UIState[1].RageBot_HitScanningRadius, Min = 0.5, Max = 9.9, Rounding = 1, Callback = function(Value)
                UIState[1].RageBot_HitScanningRadius = Value
            end
        })

        local FireScanMenu = RageBotDependencyBox:AddToggle("RageBot_FireScanning", {Text = "Fire Scanning", Default = UIState[1].RageBot_FireScanning, Callback = function(Value)
            UIState[1].RageBot_FireScanning = Value
        end}):AddSettingsMenu("Fire Scanning Settings")
        FireScanMenu:AddDropdown("RageBot_FireScanningMode", {Text = "Scan Mode", Default = UIState[1].RageBot_FireScanningMode, Values = {"Cardinal", "Sphere", "Corners"}, Callback = function(Value)
            UIState[1].RageBot_FireScanningMode = Value
        end})
        FireScanMenu:AddSlider("RageBot_FireScanningRadius", {
            Text = "Scan Radius", Default = UIState[1].RageBot_FireScanningRadius, Min = 0.1, Max = 15.9, Rounding = 1, Callback = function(Value)
                UIState[1].RageBot_FireScanningRadius = Value
            end
        })
        FireScanMenu:AddDependencyBox():SetupDependencies({{Options.RageBot_FireScanningMode, "Sphere"}}):AddSlider("RageBot_FireScanningCount", {
            Text = "Scan Count", Default = UIState[1].RageBot_FireScanningCount, Min = 1, Max = 16, Rounding = 0, Callback = function(Value)
                UIState[1].RageBot_FireScanningCount = Value
                UIFeatures[13]()
            end
        })

        local ScanLimitMenu = RageBotDependencyBox:AddToggle("RageBot_ScanLimit", {Text = "Scan Limit", Default = UIState[1].RageBot_ScanLimit, Callback = function(Value)
            UIState[1].RageBot_ScanLimit = Value
        end}):AddSettingsMenu("Scan Limit Settings")
        ScanLimitMenu:AddSlider("RageBot_ScanLimitAmount", {
            Text = "Amount", Default = UIState[1].RageBot_ScanLimitAmount, Min = 16, Max = 1024, Rounding = 0, Callback = function(Value)
                UIState[1].RageBot_ScanLimitAmount = Value
            end
        })

        RageBotDependencyBox:AddDivider()

        local BacktrackMenu = RageBotDependencyBox:AddToggle("RageBot_Backtrack", {Text = "Backtrack", Default = UIState[1].RageBot_Backtrack, Callback = function(Value)
            UIState[1].RageBot_Backtrack = Value
        end}):AddSettingsMenu("Backtrack Settings")
        BacktrackMenu:AddSlider("RageBot_BacktrackScans", {
            Text = "Scans", Default = UIState[1].RageBot_BacktrackScans, Min = 1, Max = 5, Rounding = 0, Callback = function(Value)
                UIState[1].RageBot_BacktrackScans = Value
            end
        })
        BacktrackMenu:AddSlider("RageBot_BacktrackTime", {
            Text = "Time", Default = UIState[1].RageBot_BacktrackTime, Min = 50, Max = 500, Rounding = 0, Suffix = "ms", Callback = function(Value)
                UIState[1].RageBot_BacktrackTime = Value
            end
        })
    end

    local function Build_VisualsTab()
        local Visuals_ESPVisualsGroupbox = VisualsTab:AddLeftGroupbox("ESP Visuals")
        local Visuals_CombatGroupbox = VisualsTab:AddRightGroupbox("Combat")

        local World_Tabbox = VisualsTab:AddRightTabbox()
        local World_Camera = World_Tabbox:AddTab("Camera")
        local World_Lighting = World_Tabbox:AddTab("Lighting")
        local World_ViewModel = World_Tabbox:AddTab("ViewModel")

        local LocalBulletTracers_Menu = Visuals_CombatGroupbox:AddToggle("Combat_LocalBulletTracers", {Text = "Local Bullet Tracers", Default = UIState[2].Combat_LocalBulletTracers, Callback = function(Value)
            UIState[2].Combat_LocalBulletTracers = Value
        end}):AddSettingsMenu("Local Bullet Tracer Settings")
        LocalBulletTracers_Menu:AddColorPicker("Combat_LocalBulletTracerColor", {Default = UIState[2].Combat_LocalBulletTracerColor, Callback = function(Value)
            UIState[2].Combat_LocalBulletTracerColor = Value
        end})
        LocalBulletTracers_Menu:AddDropdown("Combat_LocalBulletTracerType", {Text = "Tracer Type", Default = UIState[2].Combat_LocalBulletTracerType, Values = {"Beam", "Wavy Beam"}, Callback = function(Value)
            UIState[2].Combat_LocalBulletTracerType = Value
        end})
        LocalBulletTracers_Menu:AddDropdown("Combat_LocalBulletTracerFadeMode", {Text = "Fade Mode", Default = UIState[2].Combat_LocalBulletTracerFadeMode, Values = {"Width", "Transparency"}, Callback = function(Value)
            UIState[2].Combat_LocalBulletTracerFadeMode = Value
        end})
        LocalBulletTracers_Menu:AddSlider("Combat_LocalBulletTracerThickness", {Text = "Thickness", Default = UIState[2].Combat_LocalBulletTracerThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_LocalBulletTracerThickness = Value
        end})
        LocalBulletTracers_Menu:AddSlider("Combat_LocalBulletTracerDuration", {Text = "Duration", Default = UIState[2].Combat_LocalBulletTracerDuration, Min = 0.1, Max = 10, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_LocalBulletTracerDuration = Value
        end})

        local EnemyBulletTracers_Menu = Visuals_CombatGroupbox:AddToggle("Combat_EnemyBulletTracers", {Text = "Enemy Bullet Tracers", Default = UIState[2].Combat_EnemyBulletTracers, Callback = function(Value)
            UIState[2].Combat_EnemyBulletTracers = Value
        end}):AddSettingsMenu("Enemy Bullet Tracer Settings")
        EnemyBulletTracers_Menu:AddColorPicker("Combat_EnemyBulletTracerColor", {Default = UIState[2].Combat_EnemyBulletTracerColor, Callback = function(Value)
            UIState[2].Combat_EnemyBulletTracerColor = Value
        end})
        EnemyBulletTracers_Menu:AddDropdown("Combat_EnemyBulletTracerType", {Text = "Tracer Type", Default = UIState[2].Combat_EnemyBulletTracerType, Values = {"Beam", "Wavy Beam"}, Callback = function(Value)
            UIState[2].Combat_EnemyBulletTracerType = Value
        end})
        EnemyBulletTracers_Menu:AddDropdown("Combat_EnemyBulletTracerFadeMode", {Text = "Fade Mode", Default = UIState[2].Combat_EnemyBulletTracerFadeMode, Values = {"Width", "Transparency"}, Callback = function(Value)
            UIState[2].Combat_EnemyBulletTracerFadeMode = Value
        end})
        EnemyBulletTracers_Menu:AddSlider("Combat_EnemyBulletTracerThickness", {Text = "Thickness", Default = UIState[2].Combat_EnemyBulletTracerThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_EnemyBulletTracerThickness = Value
        end})
        EnemyBulletTracers_Menu:AddSlider("Combat_EnemyBulletTracerDuration", {Text = "Duration", Default = UIState[2].Combat_EnemyBulletTracerDuration, Min = 0.1, Max = 10, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_EnemyBulletTracerDuration = Value
        end})

        local TeamBulletTracers_Menu = Visuals_CombatGroupbox:AddToggle("Combat_TeamBulletTracers", {Text = "Team Bullet Tracers", Default = UIState[2].Combat_TeamBulletTracers, Callback = function(Value)
            UIState[2].Combat_TeamBulletTracers = Value
        end}):AddSettingsMenu("Team Bullet Tracer Settings")
        TeamBulletTracers_Menu:AddColorPicker("Combat_TeamBulletTracerColor", {Default = UIState[2].Combat_TeamBulletTracerColor, Callback = function(Value)
            UIState[2].Combat_TeamBulletTracerColor = Value
        end})
        TeamBulletTracers_Menu:AddDropdown("Combat_TeamBulletTracerType", {Text = "Tracer Type", Default = UIState[2].Combat_TeamBulletTracerType, Values = {"Beam", "Wavy Beam"}, Callback = function(Value)
            UIState[2].Combat_TeamBulletTracerType = Value
        end})
        TeamBulletTracers_Menu:AddDropdown("Combat_TeamBulletTracerFadeMode", {Text = "Fade Mode", Default = UIState[2].Combat_TeamBulletTracerFadeMode, Values = {"Width", "Transparency"}, Callback = function(Value)
            UIState[2].Combat_TeamBulletTracerFadeMode = Value
        end})
        TeamBulletTracers_Menu:AddSlider("Combat_TeamBulletTracerThickness", {Text = "Thickness", Default = UIState[2].Combat_TeamBulletTracerThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_TeamBulletTracerThickness = Value
        end})
        TeamBulletTracers_Menu:AddSlider("Combat_TeamBulletTracerDuration", {Text = "Duration", Default = UIState[2].Combat_TeamBulletTracerDuration, Min = 0.1, Max = 10, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_TeamBulletTracerDuration = Value
        end})

        Visuals_CombatGroupbox:AddDivider()

        local GrenadeTrajectoryMenu = Visuals_CombatGroupbox:AddToggle("Combat_GrenadeTrajectory", {Text = "Grenade Trajectory", Default = UIState[2].Combat_GrenadeTrajectory, Callback = function(Value)
            UIState[2].Combat_GrenadeTrajectory = Value
            if not Value then
                UIFeatures[11]:ClearTrajectory()
            end
        end}):AddSettingsMenu("Grenade Trajectory Settings")
        GrenadeTrajectoryMenu:AddToggle("Combat_GrenadeTrajectoryIgnoreAimbot", {Text = "Ignore Aimbot", Default = UIState[2].Combat_GrenadeTrajectoryIgnoreAimbot, Callback = function(Value)
            UIState[2].Combat_GrenadeTrajectoryIgnoreAimbot = Value
        end})
        GrenadeTrajectoryMenu:AddSlider("Combat_GrenadeTrajectoryBounces", {Text = "Bounces", Default = UIState[2].Combat_GrenadeTrajectoryBounces, Min = 0, Max = 3, Rounding = 0, Callback = function(Value)
            UIState[2].Combat_GrenadeTrajectoryBounces = Value
        end})
        GrenadeTrajectoryMenu:AddSlider("Combat_GrenadeTrajectoryThickness", {Text = "Thickness", Default = UIState[2].Combat_GrenadeTrajectoryThickness, Min = 1, Max = 6, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_GrenadeTrajectoryThickness = Value
        end})

        Visuals_CombatGroupbox:AddDivider()

        local CustomCrosshairMenu = Visuals_CombatGroupbox:AddToggle("Combat_CustomCrosshair", {Text = "Custom Crosshair", Default = UIState[2].Combat_CustomCrosshair, Callback = function(Value)
            UIState[2].Combat_CustomCrosshair = Value
        end}):AddSettingsMenu("Custom Crosshair Settings")
        CustomCrosshairMenu:AddColorPicker("Combat_CustomCrosshairColor", {Default = UIState[2].Combat_CustomCrosshairColor, Callback = function(Value)
            UIState[2].Combat_CustomCrosshairColor = Value
        end})
        CustomCrosshairMenu:AddSlider("Combat_CustomCrosshairSize", {
            Text = "Size", Default = UIState[2].Combat_CustomCrosshairSize, Min = 4, Max = 30, Rounding = 0, Callback = function(Value)
                UIState[2].Combat_CustomCrosshairSize = Value
            end
        })
        CustomCrosshairMenu:AddSlider("Combat_CustomCrosshairGap", {
            Text = "Gap", Default = UIState[2].Combat_CustomCrosshairGap, Min = 0, Max = 30, Rounding = 0, Callback = function(Value)
                UIState[2].Combat_CustomCrosshairGap = Value
            end
        })
        CustomCrosshairMenu:AddSlider("Combat_CustomCrosshairThickness", {
            Text = "Thickness", Default = UIState[2].Combat_CustomCrosshairThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
                UIState[2].Combat_CustomCrosshairThickness = Value
            end
        })
        CustomCrosshairMenu:AddToggle("Combat_CustomCrosshairFollowRecoil", {Text = "Follow Recoil", Default = UIState[2].Combat_CustomCrosshairFollowRecoil, Callback = function(Value)
            UIState[2].Combat_CustomCrosshairFollowRecoil = Value
        end})
        CustomCrosshairMenu:AddToggle("Combat_CustomCrosshairFollowSpread", {Text = "Follow Spread", Default = UIState[2].Combat_CustomCrosshairFollowSpread, Callback = function(Value)
            UIState[2].Combat_CustomCrosshairFollowSpread = Value
        end})
        CustomCrosshairMenu:AddToggle("Combat_CustomCrosshairSpin", {Text = "Spin", Default = UIState[2].Combat_CustomCrosshairSpin, Callback = function(Value)
            UIState[2].Combat_CustomCrosshairSpin = Value
        end})
        CustomCrosshairMenu:AddDependencyBox():SetupDependencies({{Toggles.Combat_CustomCrosshairSpin, true}}):AddSlider("Combat_CustomCrosshairSpinSpeed", {
            Text = "Spin Speed", Default = UIState[2].Combat_CustomCrosshairSpinSpeed, Min = 1, Max = 10, Rounding = 0, Callback = function(Value)
                UIState[2].Combat_CustomCrosshairSpinSpeed = Value
            end
        })

        local function UpdateRagdolls()
            if UIState[2].Combat_CustomRagdolls then
                for _,Child in ipairs(GameData[3]:GetChildren()) do
                    UIFeatures[2](Child, true)
                end
            end
        end

        local CustomRagdollsMenu = Visuals_CombatGroupbox:AddToggle("Combat_CustomRagdolls", {Text = "Custom Ragdolls", Default = UIState[2].Combat_CustomRagdolls, Callback = function(Value)
            UIState[2].Combat_CustomRagdolls = Value
            UpdateRagdolls()
        end}):AddSettingsMenu("Custom Ragdoll Settings")
        CustomRagdollsMenu:AddToggle("Combat_RagdollCustomEffect", {Text = "Custom Effect", Default = UIState[2].Combat_RagdollCustomEffect, Callback = function(Value)
            UIState[2].Combat_RagdollCustomEffect = Value
        end}):AddDropdown("Combat_RagdollEffect", {Text = "Effect", Default = UIState[2].Combat_RagdollEffect, Values = {"Launch", "Fling", "Float"}, Callback = function(Value)
            UIState[2].Combat_RagdollEffect = Value
        end})
        CustomRagdollsMenu:AddDependencyBox():SetupDependencies({{Toggles.Combat_RagdollCustomEffect, true}, {Options.Combat_RagdollEffect, "Launch"}}):AddSlider("Combat_RagdollEffectLaunchForce", {Text = "Launch Force", Default = UIState[2].Combat_RagdollEffectLaunchForce, Min = 50, Max = 500, Rounding = 0, Callback = function(Value)
            UIState[2].Combat_RagdollEffectLaunchForce = Value
        end})
        CustomRagdollsMenu:AddDependencyBox():SetupDependencies({{Toggles.Combat_RagdollCustomEffect, true}, {Options.Combat_RagdollEffect, "Fling"}}):AddSlider("Combat_RagdollEffectFlingForce", {Text = "Fling Force", Default = UIState[2].Combat_RagdollEffectFlingForce, Min = 100, Max = 500, Rounding = 0, Callback = function(Value)
            UIState[2].Combat_RagdollEffectFlingForce = Value
        end})
        CustomRagdollsMenu:AddDependencyBox():SetupDependencies({{Toggles.Combat_RagdollCustomEffect, true}, {Options.Combat_RagdollEffect, "Float"}}):AddSlider("Combat_RagdollEffectFloatSpeed", {Text = "Float Speed", Default = UIState[2].Combat_RagdollEffectFloatSpeed, Min = 1, Max = 100, Rounding = 0, Callback = function(Value)
            UIState[2].Combat_RagdollEffectFloatSpeed = Value
        end})
        CustomRagdollsMenu:AddToggle("Combat_RagdollGhost", {Text = "Ghost", Default = UIState[2].Combat_RagdollGhost, Callback = function(Value)
            UIState[2].Combat_RagdollGhost = Value
            UpdateRagdolls()
        end}):AddColorPicker("Combat_RagdollGhostColor", {Default = UIState[2].Combat_RagdollGhostColor, Callback = function(Value)
            UIState[2].Combat_RagdollGhostColor = Value
            UpdateRagdolls()
        end})

        Visuals_CombatGroupbox:AddDivider()

        local HitParticlesMenu = Visuals_CombatGroupbox:AddToggle("Combat_HitParticles", {Text = "Hit Particles", Default = UIState[2].Combat_HitParticles, Callback = function(Value)
            UIState[2].Combat_HitParticles = Value
        end}):AddSettingsMenu("Hit Particle Settings")
        HitParticlesMenu:AddDropdown("Combat_HitParticleEffect", {Text = "Effect", Default = UIState[2].Combat_HitParticleEffect, Values = {"Snow", "Sparks", "Embers"}, Callback = function(Value)
            UIState[2].Combat_HitParticleEffect = Value
        end})
        HitParticlesMenu:AddSlider("Combat_HitParticleAmount", {
            Text = "Amount", Default = UIState[2].Combat_HitParticleAmount, Min = 5, Max = 50, Rounding = 0, Callback = function(Value)
                UIState[2].Combat_HitParticleAmount = Value
            end
        })
        HitParticlesMenu:AddSlider("Combat_HitParticleLifetime", {
            Text = "Lifetime", Suffix = "x", Default = UIState[2].Combat_HitParticleLifetime, Min = 0.1, Max = 3, Rounding = 1, Callback = function(Value)
                UIState[2].Combat_HitParticleLifetime = Value
            end
        })
        HitParticlesMenu:AddSlider("Combat_HitParticleSize", {
            Text = "Size", Suffix = "x", Default = UIState[2].Combat_HitParticleSize, Min = 0.5, Max = 3, Rounding = 1, Callback = function(Value)
                UIState[2].Combat_HitParticleSize = Value
            end
        })

        local HitMarkersMenu = Visuals_CombatGroupbox:AddToggle("Combat_HitMarkers", {Text = "Hit Markers", Default = UIState[2].Combat_HitMarkers, Callback = function(Value)
            UIState[2].Combat_HitMarkers = Value
        end}):AddSettingsMenu("Hit Marker Settings")
        HitMarkersMenu:AddColorPicker("Combat_HitMarkerColor", {Default = UIState[2].Combat_HitMarkerColor, Callback = function(Value)
            UIState[2].Combat_HitMarkerColor = Value
        end})
        HitMarkersMenu:AddDropdown("Combat_HitMarkerStyle", {Text = "Style", Default = UIState[2].Combat_HitMarkerStyle, Values = {"X", "Circle"}, Callback = function(Value)
            UIState[2].Combat_HitMarkerStyle = Value
        end})
        HitMarkersMenu:AddDependencyBox():SetupDependencies({{Options.Combat_HitMarkerStyle, "X"}}):AddSlider("Combat_HitMarkerSize", {Text = "Size", Default = UIState[2].Combat_HitMarkerSize, Min = 4, Max = 30, Rounding = 0, Callback = function(Value)
            UIState[2].Combat_HitMarkerSize = Value
        end})
        HitMarkersMenu:AddDependencyBox():SetupDependencies({{Options.Combat_HitMarkerStyle, "X"}}):AddSlider("Combat_HitMarkerGap", {Text = "Gap", Default = UIState[2].Combat_HitMarkerGap, Min = 0, Max = 15, Rounding = 0, Callback = function(Value)
            UIState[2].Combat_HitMarkerGap = Value
        end})
        HitMarkersMenu:AddDependencyBox():SetupDependencies({{Options.Combat_HitMarkerStyle, "Circle"}}):AddSlider("Combat_HitMarkerRadius", {Text = "Radius", Default = UIState[2].Combat_HitMarkerRadius, Min = 4, Max = 30, Rounding = 0, Callback = function(Value)
            UIState[2].Combat_HitMarkerRadius = Value
        end})
        HitMarkersMenu:AddSlider("Combat_HitMarkerThickness", {Text = "Thickness", Default = UIState[2].Combat_HitMarkerThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_HitMarkerThickness = Value
        end})
        HitMarkersMenu:AddSlider("Combat_HitMarkerDuration", {Text = "Duration", Default = UIState[2].Combat_HitMarkerDuration, Min = 0.1, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].Combat_HitMarkerDuration = Value
        end})
        HitMarkersMenu:AddToggle("Combat_HitMarkerFadeInOutAnimation", {Text = "Fade In/Out Animation", Default = UIState[2].Combat_HitMarkerFadeInOutAnimation, Callback = function(Value)
            UIState[2].Combat_HitMarkerFadeInOutAnimation = Value
        end})
        HitMarkersMenu:AddToggle("Combat_HitMarkerSpin", {Text = "Spin", Default = UIState[2].Combat_HitMarkerSpin, Callback = function(Value)
            UIState[2].Combat_HitMarkerSpin = Value
        end})
        HitMarkersMenu:AddDependencyBox():SetupDependencies({{Toggles.Combat_HitMarkerSpin, true}}):AddSlider("Combat_HitMarkerSpinSpeed", {
            Text = "Speed", Default = UIState[2].Combat_HitMarkerSpinSpeed, Min = 1, Max = 5, Rounding = 0, Callback = function(Value)
                UIState[2].Combat_HitMarkerSpinSpeed = Value
            end
        })

        local HitGhostsMenu = Visuals_CombatGroupbox:AddToggle("Combat_HitGhosts", {Text = "Hit Ghosts", Default = UIState[2].Combat_HitGhosts, Callback = function(Value)
            UIState[2].Combat_HitGhosts = Value
        end}):AddSettingsMenu("Hit Ghost Settings")
        HitGhostsMenu:AddColorPicker("Combat_HitGhostsColor", {Default = UIState[2].Combat_HitGhostsColor, Callback = function(Value)
            UIState[2].Combat_HitGhostsColor = Value
        end})
        HitGhostsMenu:AddSlider("Combat_HitGhostsLifetime", {
            Text = "Lifetime", Default = UIState[2].Combat_HitGhostsLifetime, Min = 0.5, Max = 5, Rounding = 1, Suffix = "s", Callback = function(Value)
                UIState[2].Combat_HitGhostsLifetime = Value
            end
        })
        HitGhostsMenu:AddToggle("Combat_HitGhostsOnKillOnly", {Text = "On Kill Only", Default = UIState[2].Combat_HitGhostsOnKillOnly, Callback = function(Value)
            UIState[2].Combat_HitGhostsOnKillOnly = Value
        end})

        Visuals_CombatGroupbox:AddDivider()

        Visuals_CombatGroupbox:AddToggle("Combat_RadarHack", {Text = "Radar Hack", Default = UIState[2].Combat_RadarHack, Callback = function(Value)
            UIState[2].Combat_RadarHack = Value
        end})
        Visuals_CombatGroupbox:AddToggle("Combat_AutoSpot", {Text = "Auto Spot", Default = UIState[2].Combat_AutoSpot, Callback = function(Value)
            UIState[2].Combat_AutoSpot = Value
        end})

        Visuals_ESPVisualsGroupbox:AddToggle("ESPVisuals_MasterSwitch", {Text = "Master Switch", Default = UIState[2].ESPVisuals_MasterSwitch, Callback = function(Value)
            UIState[2].ESPVisuals_MasterSwitch = Value
        end})

        local ESPVisualsDependencies = Visuals_ESPVisualsGroupbox:AddDependencyBox():SetupDependencies({{Toggles.ESPVisuals_MasterSwitch, true}})

        local MasterSwitchMenu = Toggles.ESPVisuals_MasterSwitch:AddSettingsMenu("Master Switch Settings")
        MasterSwitchMenu:AddSlider("ESPVisuals_MaxDistance", {Text = "Max Distance", Default = UIState[2].ESPVisuals_MaxDistance, Min = 0, Max = 10000, Rounding = 0, Callback = function(Value)
            UIState[2].ESPVisuals_MaxDistance = Value
        end})
        MasterSwitchMenu:AddToggle("ESPVisuals_PerformanceMode", {Text = "Performance Mode", Default = UIState[2].ESPVisuals_PerformanceMode, Callback = function(Value)
            UIState[2].ESPVisuals_PerformanceMode = Value
        end})

        ESPVisualsDependencies:AddDivider()

        local HighlightChamsMenu = ESPVisualsDependencies:AddToggle("ESPVisuals_HighlightChams", {Text = "Highlight Chams", Default = UIState[2].ESPVisuals_HighlightChams, Callback = function(Value)
            UIState[2].ESPVisuals_HighlightChams = Value
        end}):AddSettingsMenu("Chams Settings")
        HighlightChamsMenu:AddColorPicker("ESPVisuals_HighlightChamColor", {Default = UIState[2].ESPVisuals_HighlightChamColor, Callback = function(Value)
            UIState[2].ESPVisuals_HighlightChamColor = Value
        end})
        HighlightChamsMenu:AddDropdown("ESPVisuals_HighlightChamRendering", {Text = "Rendering", Default = UIState[2].ESPVisuals_HighlightChamRendering, Values = {"Fill", "Outline"}, Multi = true, Callback = function(Value)
            UIState[2].ESPVisuals_HighlightChamRendering = Value
        end})
        HighlightChamsMenu:AddDropdown("ESPVisuals_HighlightChamStyle", {Text = "Style", Default = UIState[2].ESPVisuals_HighlightChamStyle, Values = {"Solid", "Visible"}, Callback = function(Value)
            UIState[2].ESPVisuals_HighlightChamStyle = Value
        end})
        HighlightChamsMenu:AddDependencyBox():SetupDependencies({{Options.ESPVisuals_HighlightChamStyle, "Visible"}}):AddLabel("Visible Color"):AddColorPicker("ESPVisuals_HighlightChamVisibleColor", {
            Default = UIState[2].ESPVisuals_HighlightChamVisibleColor, Callback = function(Value)
                UIState[2].ESPVisuals_HighlightChamVisibleColor = Value
            end
        })
        HighlightChamsMenu:AddToggle("ESPVisuals_HighlightChamOccluded", {Text = "Occluded", Default = UIState[2].ESPVisuals_HighlightChamOccluded, Callback = function(Value)
            UIState[2].ESPVisuals_HighlightChamOccluded = Value
        end})
        HighlightChamsMenu:AddSlider("ESPVisuals_HighlightChamTransparency", {Text = "Transparency", Default = UIState[2].ESPVisuals_HighlightChamTransparency, Min = 0, Max = 1, Rounding = 2, Callback = function(Value)
            UIState[2].ESPVisuals_HighlightChamTransparency = Value
        end})
        ESPVisualsDependencies:AddDivider()

        local Skeletons_Menu = ESPVisualsDependencies:AddToggle("ESPVisuals_Skeletons", {Text = "Skeletons", Default = UIState[2].ESPVisuals_Skeletons, Callback = function(Value)
            UIState[2].ESPVisuals_Skeletons = Value
        end}):AddSettingsMenu("Skeleton Settings")
        Skeletons_Menu:AddColorPicker("ESPVisuals_SkeletonColor", {Default = UIState[2].ESPVisuals_SkeletonColor, Transparency = UIState[2].ESPVisuals_SkeletonTransparency, Callback = function(Value, Transparency)
            UIState[2].ESPVisuals_SkeletonColor = Value
            UIState[2].ESPVisuals_SkeletonTransparency = Transparency
        end})
        Skeletons_Menu:AddSlider("ESPVisuals_SkeletonThickness", {
            Text = "Thickness", Default = UIState[2].ESPVisuals_SkeletonThickness, Min = 1, Max = 3.5, Rounding = 1, Callback = function(Value)
                UIState[2].ESPVisuals_SkeletonThickness = Value
            end
        })
        Skeletons_Menu:AddToggle("ESPVisuals_SkeletonHeadDot", {Text = "Head Dot", Default = UIState[2].ESPVisuals_SkeletonHeadDot, Callback = function(Value)
            UIState[2].ESPVisuals_SkeletonHeadDot = Value
        end})

        ESPVisualsDependencies:AddDivider()

        local HeadTags_Menu = ESPVisualsDependencies:AddToggle("ESPVisuals_HeadTags", {Text = "Head Tags", Default = UIState[2].ESPVisuals_HeadTags, Callback = function(Value)
            UIState[2].ESPVisuals_HeadTags = Value
        end}):AddSettingsMenu("Head Tag Settings")
        HeadTags_Menu:AddColorPicker("ESPVisuals_HeadTagColor", {Default = UIState[2].ESPVisuals_HeadTagColor, Transparency = UIState[2].ESPVisuals_HeadTagTransparency, Callback = function(Value, Transparency)
            UIState[2].ESPVisuals_HeadTagColor = Value
            UIState[2].ESPVisuals_HeadTagTransparency = Transparency
        end})
        HeadTags_Menu:AddToggle("ESPVisuals_HeadTagPixelOffset", {Text = "Pixel Offset", Default = UIState[2].ESPVisuals_HeadTagPixelOffset, Callback = function(Value)
            UIState[2].ESPVisuals_HeadTagPixelOffset = Value
        end})
        HeadTags_Menu:AddDependencyBox():SetupDependencies({{Toggles.ESPVisuals_HeadTagPixelOffset, true}}):AddSlider("ESPVisuals_HeadTagPixelOffsetSize", {Text = "Size", Default = UIState[2].ESPVisuals_HeadTagPixelOffsetSize, Min = -10, Max = 10, Rounding = 0, Suffix = "px", Callback = function(Value)
            UIState[2].ESPVisuals_HeadTagPixelOffsetSize = Value
        end})
        HeadTags_Menu:AddDropdown("ESPVisuals_HeadTagStaticElements", {Text = "Static Elements", Default = UIState[2].ESPVisuals_HeadTagStaticElements, Values = {"Name", "Health", "Distance", "Weapon"}, Multi = true, Callback = function(Value)
            UIState[2].ESPVisuals_HeadTagStaticElements = Value
        end})
        HeadTags_Menu:AddDropdown("ESPVisuals_HeadTagStatusElements", {Text = "Status Elements", Default = UIState[2].ESPVisuals_HeadTagStatusElements, Values = {"Aiming", "Sprinting", "Crouching", "Prone"}, Multi = true, Callback = function(Value)
            UIState[2].ESPVisuals_HeadTagStatusElements = Value
        end})
        HeadTags_Menu:AddDropdown("ESPVisuals_HeadTagPosition", {Text = "Position", Default = UIState[2].ESPVisuals_HeadTagPosition, Values = {"Top", "Bottom", "Left", "Right"}, Callback = function(Value)
            UIState[2].ESPVisuals_HeadTagPosition = Value
        end})
        HeadTags_Menu:AddSlider("ESPVisuals_HeadTagSize", {Text = "Size", Default = UIState[2].ESPVisuals_HeadTagSize, Min = 8, Max = 20, Rounding = 0, Callback = function(Value)
            UIState[2].ESPVisuals_HeadTagSize = Value
        end})

        ESPVisualsDependencies:AddDivider()

        local Boxes_Menu = ESPVisualsDependencies:AddToggle("ESPVisuals_Boxes", {Text = "Boxes", Default = UIState[2].ESPVisuals_Boxes, Callback = function(Value)
            UIState[2].ESPVisuals_Boxes = Value
        end}):AddSettingsMenu("Box Settings")
        Boxes_Menu:AddColorPicker("ESPVisuals_BoxColor", {Default = UIState[2].ESPVisuals_BoxColor, Transparency = UIState[2].ESPVisuals_BoxTransparency, Callback = function(Value, Transparency)
            UIState[2].ESPVisuals_BoxColor = Value
            UIState[2].ESPVisuals_BoxTransparency = Transparency
        end})
        Boxes_Menu:AddDropdown("ESPVisuals_BoxStyle", {Text = "Style", Default = UIState[2].ESPVisuals_BoxStyle, Values = {"Full", "Corners"}, Callback = function(Value)
            UIState[2].ESPVisuals_BoxStyle = Value
        end})
        Boxes_Menu:AddSlider("ESPVisuals_BoxThickness", {
            Text = "Thickness", Default = UIState[2].ESPVisuals_BoxThickness, Min = 1, Max = 2.5, Rounding = 1, Callback = function(Value)
                UIState[2].ESPVisuals_BoxThickness = Value
            end
        })

        ESPVisualsDependencies:AddDivider()

        local Healthbars_Menu = ESPVisualsDependencies:AddToggle("ESPVisuals_Healthbars", {Text = "Healthbars", Default = UIState[2].ESPVisuals_Healthbars, Callback = function(Value)
            UIState[2].ESPVisuals_Healthbars = Value
        end}):AddSettingsMenu("Healthbar Settings")
        Healthbars_Menu:AddDropdown("ESPVisuals_HealthbarStyle", {Text = "Style", Default = UIState[2].ESPVisuals_HealthbarStyle, Values = {"Solid", "Health"}, Callback = function(Value)
            UIState[2].ESPVisuals_HealthbarStyle = Value
        end})
        Healthbars_Menu:AddColorPicker("ESPVisuals_HealthbarColor", {
            Default = UIState[2].ESPVisuals_HealthbarColor, Transparency = UIState[2].ESPVisuals_HealthbarTransparency, Callback = function(Value, Transparency)
                UIState[2].ESPVisuals_HealthbarColor = Value
                UIState[2].ESPVisuals_HealthbarTransparency = Transparency
            end
        })
        Healthbars_Menu:AddDropdown("ESPVisuals_HealthbarPosition", {Text = "Position", Default = UIState[2].ESPVisuals_HealthbarPosition, Values = {"Top", "Bottom", "Left", "Right"}, Callback = function(Value)
            UIState[2].ESPVisuals_HealthbarPosition = Value
        end})
        Healthbars_Menu:AddSlider("ESPVisuals_HealthbarWidth", {
            Text = "Width", Default = UIState[2].ESPVisuals_HealthbarWidth, Min = 2, Max = 5, Rounding = 1, Callback = function(Value)
                UIState[2].ESPVisuals_HealthbarWidth = Value
            end
        })

        ESPVisualsDependencies:AddDivider()

        local Tracers_Menu = ESPVisualsDependencies:AddToggle("ESPVisuals_Tracers", {Text = "Tracers", Default = UIState[2].ESPVisuals_Tracers, Callback = function(Value)
            UIState[2].ESPVisuals_Tracers = Value
        end}):AddSettingsMenu("Tracer Settings")
        Tracers_Menu:AddColorPicker("ESPVisuals_TracerColor", {Default = UIState[2].ESPVisuals_TracerColor, Transparency = UIState[2].ESPVisuals_TracerTransparency, Callback = function(Value, Transparency)
            UIState[2].ESPVisuals_TracerColor = Value
            UIState[2].ESPVisuals_TracerTransparency = Transparency
        end})
        Tracers_Menu:AddDropdown("ESPVisuals_TracerOrigin", {Text = "Origin", Default = UIState[2].ESPVisuals_TracerOrigin, Values = {"Top", "Center", "Bottom"}, Callback = function(Value)
            UIState[2].ESPVisuals_TracerOrigin = Value
        end})
        Tracers_Menu:AddDropdown("ESPVisuals_TracerPart", {Text = "Part", Default = UIState[2].ESPVisuals_TracerPart, Values = {"Head", "Neck", "Torso"}, Callback = function(Value)
            UIState[2].ESPVisuals_TracerPart = Value
        end})
        Tracers_Menu:AddSlider("ESPVisuals_TracerThickness", {Text = "Thickness", Default = UIState[2].ESPVisuals_TracerThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].ESPVisuals_TracerThickness = Value
        end})

        ESPVisualsDependencies:AddDivider()

        local OffscreenArrows_Menu = ESPVisualsDependencies:AddToggle("ESPVisuals_OffscreenArrows", {Text = "Offscreen Arrows", Default = UIState[2].ESPVisuals_OffscreenArrows, Callback = function(Value)
            UIState[2].ESPVisuals_OffscreenArrows = Value
        end}):AddSettingsMenu("Offscreen Arrow Settings")
        OffscreenArrows_Menu:AddColorPicker("ESPVisuals_OffscreenArrowColor", {Default = UIState[2].ESPVisuals_OffscreenArrowColor, Transparency = UIState[2].ESPVisuals_OffscreenArrowTransparency, Callback = function(Value, Transparency)
            UIState[2].ESPVisuals_OffscreenArrowColor = Value
            UIState[2].ESPVisuals_OffscreenArrowTransparency = Transparency
        end})
        OffscreenArrows_Menu:AddToggle("ESPVisuals_OffscreenArrowFilled", {Text = "Filled", Default = UIState[2].ESPVisuals_OffscreenArrowFilled, Callback = function(Value)
            UIState[2].ESPVisuals_OffscreenArrowFilled = Value
        end})
        OffscreenArrows_Menu:AddSlider("ESPVisuals_OffscreenArrowSize", {Text = "Size", Default = UIState[2].ESPVisuals_OffscreenArrowSize, Min = 5, Max = 20, Rounding = 0, Callback = function(Value)
            UIState[2].ESPVisuals_OffscreenArrowSize = Value
        end})
        OffscreenArrows_Menu:AddSlider("ESPVisuals_OffscreenArrowRadius", {Text = "Radius", Default = UIState[2].ESPVisuals_OffscreenArrowRadius, Min = 100, Max = 450, Rounding = 0, Callback = function(Value)
            UIState[2].ESPVisuals_OffscreenArrowRadius = Value
        end})

        ESPVisualsDependencies:AddDivider()

        local SoundRingsMenu = ESPVisualsDependencies:AddToggle("ESPVisuals_SoundRings", {Text = "Sound Rings", Default = UIState[2].ESPVisuals_SoundRings, Callback = function(Value)
            UIState[2].ESPVisuals_SoundRings = Value
        end}):AddSettingsMenu("Sound Rings Settings")
        SoundRingsMenu:AddColorPicker("ESPVisuals_SoundRingsColor", {Default = UIState[2].ESPVisuals_SoundRingsColor, Transparency = UIState[2].ESPVisuals_SoundRingsTransparency, Callback = function(Value, Transparency)
            UIState[2].ESPVisuals_SoundRingsColor = Value
            UIState[2].ESPVisuals_SoundRingsTransparency = Transparency
        end})
        SoundRingsMenu:AddToggle("ESPVisuals_SoundRingsOccluded", {Text = "Occluded", Default = UIState[2].ESPVisuals_SoundRingsOccluded, Callback = function(Value)
            UIState[2].ESPVisuals_SoundRingsOccluded = Value
        end})
        SoundRingsMenu:AddSlider("ESPVisuals_SoundRingsDuration", {Text = "Duration", Default = UIState[2].ESPVisuals_SoundRingsDuration, Min = 0.3, Max = 3, Rounding = 1, Suffix = "s", Callback = function(Value)
            UIState[2].ESPVisuals_SoundRingsDuration = Value
        end})

        ESPVisualsDependencies:AddDivider()

        local GrenadeTags_Menu = ESPVisualsDependencies:AddToggle("ESPVisuals_GrenadeTags", {Text = "Grenade Tags", Default = UIState[2].ESPVisuals_GrenadeTags, Callback = function(Value)
            UIState[2].ESPVisuals_GrenadeTags = Value
        end}):AddSettingsMenu("Grenade Tag Settings")
        GrenadeTags_Menu:AddColorPicker("ESPVisuals_GrenadeTagColor", {Default = UIState[2].ESPVisuals_GrenadeTagColor, Transparency = UIState[2].ESPVisuals_GrenadeTagTransparency, Callback = function(Value, Transparency)
            UIState[2].ESPVisuals_GrenadeTagColor = Value
            UIState[2].ESPVisuals_GrenadeTagTransparency = Transparency
        end})
        GrenadeTags_Menu:AddSlider("ESPVisuals_GrenadeTagSize", {
            Text = "Size", Default = UIState[2].ESPVisuals_GrenadeTagSize, Min = 8, Max = 20, Rounding = 0, Callback = function(Value)
                UIState[2].ESPVisuals_GrenadeTagSize = Value
            end
        })
        GrenadeTags_Menu:AddToggle("ESPVisuals_GrenadeTagUseName", {Text = "Use Name", Default = UIState[2].ESPVisuals_GrenadeTagUseName, Callback = function(Value)
            UIState[2].ESPVisuals_GrenadeTagUseName = Value
        end})

        World_Camera:AddToggle("Camera_NoSuppression", {Text = "No Suppression", Default = UIState[2].Camera_NoSuppression, Callback = function(Value)
            UIState[2].Camera_NoSuppression = Value
        end})

        World_Camera:AddToggle("Camera_NoBob", {Text = "No Bob", Default = UIState[2].Camera_NoBob, Callback = function(Value)
            UIState[2].Camera_NoBob = Value
        end})

        World_Camera:AddDivider()

        local CustomFOVMenu = World_Camera:AddToggle("Camera_CustomFOV", {Text = "Custom Field Of View", Default = UIState[2].Camera_CustomFOV, Callback = function(Value)
            UIState[2].Camera_CustomFOV = Value
        end}):AddSettingsMenu("Field Of View Settings")
        CustomFOVMenu:AddToggle("Camera_ApplyToAim", {Text = "Apply to Aim", Default = UIState[2].Camera_ApplyToAim, Callback = function(Value)
            UIState[2].Camera_ApplyToAim = Value
        end})
        CustomFOVMenu:AddSlider("Camera_FOVValue", {
            Text = "FOV Value", Default = UIState[2].Camera_FOVValue, Min = 30, Max = 120, Rounding = 0, Callback = function(Value)
                UIState[2].Camera_FOVValue = Value
            end
        })

        local ThirdPersonMenu = World_Camera:AddToggle("Camera_ThirdPerson", {Text = "Third Person", Default = UIState[2].Camera_ThirdPerson, Callback = function(Value)
            UIState[2].Camera_ThirdPerson = Value
            UIFeatures[5]:Refresh()
        end}):AddSettingsMenu("Third Person Settings")
        ThirdPersonMenu:AddKeyPicker("Camera_ThirdPersonKeybind", {
            Default = "None", Mode = "Toggle", Text = "Third Person", SyncToggleState = true
        })
        ThirdPersonMenu:AddToggle("Camera_ThirdPersonCameraCollision", {Text = "Camera Collision", Default = UIState[2].Camera_ThirdPersonCameraCollision, Callback = function(Value)
            UIState[2].Camera_ThirdPersonCameraCollision = Value
        end})
        ThirdPersonMenu:AddToggle("Camera_ThirdPersonHideViewModel", {Text = "Hide ViewModel", Default = UIState[2].Camera_ThirdPersonHideViewModel, Callback = function(Value)
            UIState[2].Camera_ThirdPersonHideViewModel = Value
            UIFeatures[5]:Refresh()
        end})
        ThirdPersonMenu:AddSlider("Camera_ThirdPersonOffsetX", {Text = "Offset X", Default = UIState[2].Camera_ThirdPersonOffsetX, Min = -20, Max = 20, Rounding = 0, Callback = function(Value)
            UIState[2].Camera_ThirdPersonOffsetX = Value
        end})
        ThirdPersonMenu:AddSlider("Camera_ThirdPersonOffsetY", {Text = "Offset Y", Default = UIState[2].Camera_ThirdPersonOffsetY, Min = -20, Max = 20, Rounding = 0, Callback = function(Value)
            UIState[2].Camera_ThirdPersonOffsetY = Value
        end})
        ThirdPersonMenu:AddSlider("Camera_ThirdPersonOffsetZ", {Text = "Offset Z", Default = UIState[2].Camera_ThirdPersonOffsetZ, Min = -20, Max = 20, Rounding = 0, Callback = function(Value)
            UIState[2].Camera_ThirdPersonOffsetZ = Value
        end})
        ThirdPersonMenu:AddToggle("Camera_ThirdPersonShowCharacter", {Text = "Show Character", Default = UIState[2].Camera_ThirdPersonShowCharacter, Callback = function(Value)
            UIState[2].Camera_ThirdPersonShowCharacter = Value
        end})
        local ThirdPersonCharacterSettings = ThirdPersonMenu:AddDependencyBox():SetupDependencies({{Toggles.Camera_ThirdPersonShowCharacter, true}})
        ThirdPersonCharacterSettings:AddToggle("Camera_ThirdPersonGhostCharacter", {Text = "Ghost Character", Default = UIState[2].Camera_ThirdPersonGhostCharacter, Callback = function(Value)
            UIState[2].Camera_ThirdPersonGhostCharacter = Value
        end})
        ThirdPersonCharacterSettings:AddToggle("Camera_ThirdPersonHideCharacterWhileAiming", {Text = "Hide Character While Aiming", Default = UIState[2].Camera_ThirdPersonHideCharacterWhileAiming, Callback = function(Value)
            UIState[2].Camera_ThirdPersonHideCharacterWhileAiming = Value
        end})

        local CustomLightingMenu = World_Lighting:AddToggle("Lighting_Custom", {Text = "Custom Lighting", Default = UIState[2].Lighting_Custom, Callback = function(Value)
            UIState[2].Lighting_Custom = Value
            if not Value then
                for Connection in next, UIFeatures[1].Connections do
                    Connection:Disconnect()
                end
                table.clear(UIFeatures[1].Connections)
                return UIFeatures[3](true)
            end

            for Property in next, UIFeatures[1].OriginalValues do
                UIFeatures[1].OriginalValues[Property] = GameData[2][Property]
            end

            for Connection in next, UIFeatures[1].Connections do
                Connection:Disconnect()
            end
            table.clear(UIFeatures[1].Connections)

            local Properties = {"Ambient", "OutdoorAmbient", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness", "LightingStyle"}
            for _,Property in ipairs(Properties) do
                UIFeatures[1].Connections[GameData[2]:GetPropertyChangedSignal(Property):Connect(function()
                    local Current = GameData[2][Property]
                    UIFeatures[3](false)
                    if GameData[2][Property] ~= Current then
                        UIFeatures[1].OriginalValues[Property] = Current
                        UIFeatures[3](false)
                    end
                end)] = true
            end

            UIFeatures[3](false)
        end}):AddSettingsMenu("Custom Lighting Settings")
        CustomLightingMenu:AddSlider("Lighting_ExposureCompensation", {Text = "Exposure Compensation", Default = UIState[2].Lighting_ExposureCompensation, Min = -5, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].Lighting_ExposureCompensation = Value
            if UIState[2].Lighting_Custom then
                GameData[2].ExposureCompensation = Value
            end
        end})
        CustomLightingMenu:AddLabel("Ambient"):AddColorPicker("Lighting_Ambient", {Default = UIState[2].Lighting_Ambient, Callback = function(Value)
            UIState[2].Lighting_Ambient = Value
            if UIState[2].Lighting_Custom then
                GameData[2].Ambient = Value
            end
        end})
        CustomLightingMenu:AddLabel("Outdoor Ambient"):AddColorPicker("Lighting_OutdoorAmbient", {Default = UIState[2].Lighting_OutdoorAmbient, Callback = function(Value)
            UIState[2].Lighting_OutdoorAmbient = Value
            if UIState[2].Lighting_Custom then
                GameData[2].OutdoorAmbient = Value
            end
        end})
        CustomLightingMenu:AddSlider("Lighting_EnvironmentDiffuseScale", {Text = "Diffuse Scale", Default = UIState[2].Lighting_EnvironmentDiffuseScale, Min = 0, Max = 1, Rounding = 1, Callback = function(Value)
            UIState[2].Lighting_EnvironmentDiffuseScale = Value
            if UIState[2].Lighting_Custom then
                GameData[2].EnvironmentDiffuseScale = Value
            end
        end})
        CustomLightingMenu:AddSlider("Lighting_EnvironmentSpecularScale", {Text = "Specular Scale", Default = UIState[2].Lighting_EnvironmentSpecularScale, Min = 0, Max = 1, Rounding = 1, Callback = function(Value)
            UIState[2].Lighting_EnvironmentSpecularScale = Value
            if UIState[2].Lighting_Custom then
                GameData[2].EnvironmentSpecularScale = Value
            end
        end})
        CustomLightingMenu:AddSlider("Lighting_ShadowSoftness", {Text = "Shadow Softness", Default = UIState[2].Lighting_ShadowSoftness, Min = 0, Max = 1, Rounding = 1, Callback = function(Value)
            UIState[2].Lighting_ShadowSoftness = Value
            if UIState[2].Lighting_Custom then
                GameData[2].ShadowSoftness = Value
            end
        end})

        local BloomMenu = World_Lighting:AddToggle("Lighting_Bloom", {Text = "Bloom", Default = UIState[2].Lighting_Bloom, Callback = function(Value)
            UIState[2].Lighting_Bloom = Value
            UIFeatures[4]()
        end}):AddSettingsMenu("Bloom Settings")
        BloomMenu:AddSlider("Lighting_BloomIntensity", {
            Text = "Intensity", Default = UIState[2].Lighting_BloomIntensity, Min = 0, Max = 2, Rounding = 2, Callback = function(Value)
                UIState[2].Lighting_BloomIntensity = Value
                UIFeatures[4]()
            end
        })
        BloomMenu:AddSlider("Lighting_BloomSize", {
            Text = "Size", Default = UIState[2].Lighting_BloomSize, Min = 1, Max = 56, Rounding = 0, Callback = function(Value)
                UIState[2].Lighting_BloomSize = Value
                UIFeatures[4]()
            end
        })
        BloomMenu:AddSlider("Lighting_BloomThreshold", {
            Text = "Threshold", Default = UIState[2].Lighting_BloomThreshold, Min = 0, Max = 2, Rounding = 2, Callback = function(Value)
                UIState[2].Lighting_BloomThreshold = Value
                UIFeatures[4]()
            end
        })

        local FlashlightMenu = World_Lighting:AddToggle("Lighting_Flashlight", {Text = "Flashlight", Default = UIState[2].Lighting_Flashlight, Callback = function(Value)
            UIState[2].Lighting_Flashlight = Value
        end}):AddSettingsMenu("Flashlight Settings")
        FlashlightMenu:AddColorPicker("Lighting_FlashlightColor", {Default = UIState[2].Lighting_FlashlightColor, Callback = function(Value)
            UIState[2].Lighting_FlashlightColor = Value
        end})
        FlashlightMenu:AddSlider("Lighting_FlashlightBrightness", {Text = "Brightness", Default = UIState[2].Lighting_FlashlightBrightness, Min = 0, Max = 10, Rounding = 1, Callback = function(Value)
            UIState[2].Lighting_FlashlightBrightness = Value
        end})
        FlashlightMenu:AddSlider("Lighting_FlashlightRange", {Text = "Range", Default = UIState[2].Lighting_FlashlightRange, Min = 0, Max = 60, Rounding = 0, Callback = function(Value)
            UIState[2].Lighting_FlashlightRange = Value
        end})
        FlashlightMenu:AddSlider("Lighting_FlashlightAngle", {Text = "Angle", Default = UIState[2].Lighting_FlashlightAngle, Min = 0, Max = 180, Rounding = 0, Callback = function(Value)
            UIState[2].Lighting_FlashlightAngle = Value
        end})

        local WeaponChamsMenu = World_ViewModel:AddToggle("ViewModel_WeaponChams", {Text = "Weapon Chams", Default = UIState[2].ViewModel_WeaponChams, Callback = function(Value)
            UIState[2].ViewModel_WeaponChams = Value
            UIFeatures[5]:Refresh()
        end}):AddSettingsMenu("Weapon Cham Settings")
        WeaponChamsMenu:AddColorPicker("ViewModel_WeaponChamColor", {Default = UIState[2].ViewModel_WeaponChamColor, Callback = function(Value)
            UIState[2].ViewModel_WeaponChamColor = Value
            UIFeatures[5]:Refresh()
        end})
        WeaponChamsMenu:AddToggle("ViewModel_WeaponChamIgnoreSightParts", {Text = "Ignore Sight Parts", Default = UIState[2].ViewModel_WeaponChamIgnoreSightParts, Callback = function(Value)
            UIState[2].ViewModel_WeaponChamIgnoreSightParts = Value
            UIFeatures[5]:Refresh()
        end})
        WeaponChamsMenu:AddDropdown("ViewModel_WeaponChamType", {Text = "Type", Default = UIState[2].ViewModel_WeaponChamType, Values = {"ForceField", "Neon", "Glass", "SmoothPlastic"}, Callback = function(Value)
            UIState[2].ViewModel_WeaponChamType = Value
            UIFeatures[5]:Refresh()
        end})
        WeaponChamsMenu:AddDependencyBox():SetupDependencies({{Options.ViewModel_WeaponChamType, {"Neon", "Glass", "SmoothPlastic"}}}):AddSlider("ViewModel_WeaponChamTransparency", {Text = "Transparency", Default = UIState[2].ViewModel_WeaponChamTransparency, Min = 0, Max = 1, Rounding = 2, Callback = function(Value)
            UIState[2].ViewModel_WeaponChamTransparency = Value
            UIFeatures[5]:Refresh()
        end})

        local ArmChamsMenu = World_ViewModel:AddToggle("ViewModel_ArmChams", {Text = "Arm Chams", Default = UIState[2].ViewModel_ArmChams, Callback = function(Value)
            UIState[2].ViewModel_ArmChams = Value
            UIFeatures[5]:Refresh()
        end}):AddSettingsMenu("Arm Cham Settings")
        ArmChamsMenu:AddColorPicker("ViewModel_ArmChamColor", {Default = UIState[2].ViewModel_ArmChamColor, Callback = function(Value)
            UIState[2].ViewModel_ArmChamColor = Value
            UIFeatures[5]:Refresh()
        end})
        ArmChamsMenu:AddDropdown("ViewModel_ArmChamType", {Text = "Type", Default = UIState[2].ViewModel_ArmChamType, Values = {"ForceField", "Neon", "Glass", "SmoothPlastic"}, Callback = function(Value)
            UIState[2].ViewModel_ArmChamType = Value
            UIFeatures[5]:Refresh()
        end})
        ArmChamsMenu:AddDependencyBox():SetupDependencies({{Options.ViewModel_ArmChamType, {"Neon", "Glass", "SmoothPlastic"}}}):AddSlider("ViewModel_ArmChamTransparency", {Text = "Transparency", Default = UIState[2].ViewModel_ArmChamTransparency, Min = 0, Max = 1, Rounding = 2, Callback = function(Value)
            UIState[2].ViewModel_ArmChamTransparency = Value
            UIFeatures[5]:Refresh()
        end})

        local SleeveChamsMenu = World_ViewModel:AddToggle("ViewModel_SleeveChams", {Text = "Sleeve Chams", Default = UIState[2].ViewModel_SleeveChams, Callback = function(Value)
            UIState[2].ViewModel_SleeveChams = Value
            UIFeatures[5]:Refresh()
        end}):AddSettingsMenu("Sleeve Cham Settings")
        SleeveChamsMenu:AddColorPicker("ViewModel_SleeveChamColor", {Default = UIState[2].ViewModel_SleeveChamColor, Callback = function(Value)
            UIState[2].ViewModel_SleeveChamColor = Value
            UIFeatures[5]:Refresh()
        end})
        SleeveChamsMenu:AddDropdown("ViewModel_SleeveChamType", {Text = "Type", Default = UIState[2].ViewModel_SleeveChamType, Values = {"ForceField", "Neon", "Glass", "SmoothPlastic"}, Callback = function(Value)
            UIState[2].ViewModel_SleeveChamType = Value
            UIFeatures[5]:Refresh()
        end})
        SleeveChamsMenu:AddDependencyBox():SetupDependencies({{Options.ViewModel_SleeveChamType, {"Neon", "Glass", "SmoothPlastic"}}}):AddSlider("ViewModel_SleeveChamTransparency", {Text = "Transparency", Default = UIState[2].ViewModel_SleeveChamTransparency, Min = 0, Max = 1, Rounding = 2, Callback = function(Value)
            UIState[2].ViewModel_SleeveChamTransparency = Value
            UIFeatures[5]:Refresh()
        end})

        World_ViewModel:AddDivider()

        local CustomOffsetMenu = World_ViewModel:AddToggle("ViewModel_CustomOffset", {Text = "Custom Offset", Default = UIState[2].ViewModel_CustomOffset, Callback = function(Value)
            UIState[2].ViewModel_CustomOffset = Value
        end}):AddSettingsMenu("Custom Offset Settings")
        CustomOffsetMenu:AddSlider("ViewModel_OffsetX", {Text = "X", Default = UIState[2].ViewModel_OffsetX, Min = -5, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].ViewModel_OffsetX = Value
        end})
        CustomOffsetMenu:AddSlider("ViewModel_OffsetY", {Text = "Y", Default = UIState[2].ViewModel_OffsetY, Min = -5, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].ViewModel_OffsetY = Value
        end})
        CustomOffsetMenu:AddSlider("ViewModel_OffsetZ", {Text = "Z", Default = UIState[2].ViewModel_OffsetZ, Min = -5, Max = 5, Rounding = 1, Callback = function(Value)
            UIState[2].ViewModel_OffsetZ = Value
        end})

        local CustomRotationMenu = World_ViewModel:AddToggle("ViewModel_CustomRotation", {Text = "Custom Rotation", Default = UIState[2].ViewModel_CustomRotation, Callback = function(Value)
            UIState[2].ViewModel_CustomRotation = Value
        end}):AddSettingsMenu("Custom Rotation Settings")
        CustomRotationMenu:AddSlider("ViewModel_RotationX", {Text = "X", Default = UIState[2].ViewModel_RotationX, Min = -180, Max = 180, Rounding = 0, Callback = function(Value)
            UIState[2].ViewModel_RotationX = Value
        end})
        CustomRotationMenu:AddSlider("ViewModel_RotationY", {Text = "Y", Default = UIState[2].ViewModel_RotationY, Min = -180, Max = 180, Rounding = 0, Callback = function(Value)
            UIState[2].ViewModel_RotationY = Value
        end})
        CustomRotationMenu:AddSlider("ViewModel_RotationZ", {Text = "Z", Default = UIState[2].ViewModel_RotationZ, Min = -180, Max = 180, Rounding = 0, Callback = function(Value)
            UIState[2].ViewModel_RotationZ = Value
        end})

        World_ViewModel:AddToggle("ViewModel_CustomRoll", {Text = "Custom Roll", Default = UIState[2].ViewModel_CustomRoll, Callback = function(Value)
            UIState[2].ViewModel_CustomRoll = Value
        end}):AddSettingsMenu("Custom Roll Settings"):AddSlider("ViewModel_Roll", {
            Text = "Roll", Default = UIState[2].ViewModel_Roll, Min = -180, Max = 180, Rounding = 0, Callback = function(Value)
                UIState[2].ViewModel_Roll = Value
            end
        })
    end

    local function Build_MiscellaneousTab()
        local Miscellaneous_WeaponMods = MiscellaneousTab:AddLeftGroupbox("Weapon Mods")

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_AutomaticGun", {Text = "Automatic Gun", Default = UIState[3].WeaponMods_AutomaticGun, Callback = function(Value)
            UIState[3].WeaponMods_AutomaticGun = Value
        end})

        Miscellaneous_WeaponMods:AddSlider("WeaponMods_RecoilAdjustment", {
            Text = "Recoil Adjustment", Default = UIState[3].WeaponMods_RecoilAdjustment, Min = 0, Max = 100, Rounding = 0, Callback = function(Value)
                UIState[3].WeaponMods_RecoilAdjustment = Value
            end
        })

        Miscellaneous_WeaponMods:AddSlider("WeaponMods_SpreadAdjustment", {
            Text = "Spread Adjustment", Default = UIState[3].WeaponMods_SpreadAdjustment, Min = 0, Max = 100, Rounding = 0, Callback = function(Value)
                UIState[3].WeaponMods_SpreadAdjustment = Value
            end
        })

        Miscellaneous_WeaponMods:AddDivider()

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_InstantBullet", {Text = "Instant Bullet [EXPERIMENTAL]", Default = UIState[3].WeaponMods_InstantBullet, Callback = function(Value)
            UIState[3].WeaponMods_InstantBullet = Value
        end})

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_RapidFire", {Text = "Rapid Fire [EXPERIMENTAL]", Default = UIState[3].WeaponMods_RapidFire, Callback = function(Value)
            UIState[3].WeaponMods_RapidFire = Value
        end})

        Miscellaneous_WeaponMods:AddDivider()

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_NoWeaponSway", {Text = "No Weapon Sway", Default = UIState[3].WeaponMods_NoWeaponSway, Callback = function(Value)
            UIState[3].WeaponMods_NoWeaponSway = Value
        end})

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_NoScopeSway", {Text = "No Scope Sway", Default = UIState[3].WeaponMods_NoScopeSway, Callback = function(Value)
            UIState[3].WeaponMods_NoScopeSway = Value
        end})

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_NoWalkSway", {Text = "No Walk Sway", Default = UIState[3].WeaponMods_NoWalkSway, Callback = function(Value)
            UIState[3].WeaponMods_NoWalkSway = Value
        end})

        Miscellaneous_WeaponMods:AddDivider()

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_InstantEquipUnequip", {Text = "Instant Equip/Unequip", Default = UIState[3].WeaponMods_InstantEquipUnequip, Callback = function(Value)
            UIState[3].WeaponMods_InstantEquipUnequip = Value
        end})

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_InstantReload", {Text = "Instant Reload", Default = UIState[3].WeaponMods_InstantReload, Callback = function(Value)
            UIState[3].WeaponMods_InstantReload = Value
        end})

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_InstantAim", {Text = "Instant Aim", Default = UIState[3].WeaponMods_InstantAim, Callback = function(Value)
            UIState[3].WeaponMods_InstantAim = Value
        end})

        Miscellaneous_WeaponMods:AddDivider()

        Miscellaneous_WeaponMods:AddToggle("WeaponMods_UncookableGrenade", {Text = "Uncookable Grenade", Default = UIState[3].WeaponMods_UncookableGrenade, Callback = function(Value)
            UIState[3].WeaponMods_UncookableGrenade = Value
        end})

        local CustomGrenadeFuseMenu = Miscellaneous_WeaponMods:AddToggle("WeaponMods_CustomGrenadeFuse", {Text = "Custom Grenade Fuse", Default = UIState[3].WeaponMods_CustomGrenadeFuse, Callback = function(Value)
            UIState[3].WeaponMods_CustomGrenadeFuse = Value
        end}):AddSettingsMenu("Grenade Fuse Settings")
        CustomGrenadeFuseMenu:AddToggle("WeaponMods_CustomGrenadeFuseOnImpact", {Text = "On Impact [BETA]", Default = UIState[3].WeaponMods_CustomGrenadeFuseOnImpact, Callback = function(Value)
            UIState[3].WeaponMods_CustomGrenadeFuseOnImpact = Value
        end})
        CustomGrenadeFuseMenu:AddDependencyBox():SetupDependencies({{Toggles.WeaponMods_CustomGrenadeFuseOnImpact, false}}):AddSlider("WeaponMods_CustomGrenadeFuseAmount", {
            Text = "Fuse Amount", Default = UIState[3].WeaponMods_CustomGrenadeFuseAmount, Min = 0, Max = 5, Rounding = 2, Callback = function(Value)
                UIState[3].WeaponMods_CustomGrenadeFuseAmount = Value
            end
        })

        Miscellaneous_WeaponMods:AddDivider()

        local CustomMuzzleFlashMenu = Miscellaneous_WeaponMods:AddToggle("WeaponMods_CustomMuzzleFlash", {Text = "Custom Muzzle Flash", Default = UIState[3].WeaponMods_CustomMuzzleFlash, Callback = function(Value)
            UIState[3].WeaponMods_CustomMuzzleFlash = Value
        end}):AddSettingsMenu("Muzzle Flash Settings")
        CustomMuzzleFlashMenu:AddColorPicker("WeaponMods_MuzzleFlashColor", {Default = UIState[3].WeaponMods_MuzzleFlashColor, Callback = function(Value)
            UIState[3].WeaponMods_MuzzleFlashColor = Value
        end})
        CustomMuzzleFlashMenu:AddSlider("WeaponMods_MuzzleFlashSize", {
            Text = "Size", Default = UIState[3].WeaponMods_MuzzleFlashSize, Min = 0.1, Max = 3, Rounding = 1, Suffix = "x", Callback = function(Value)
                UIState[3].WeaponMods_MuzzleFlashSize = Value
            end
        })

        local HitLogsMenu = MiscellaneousTab:AddLeftGroupbox("Hit Logs"):AddToggle("HitLogs_Enabled", {Text = "Enabled", Default = UIState[3].HitLogs_Enabled, Callback = function(Value)
            UIState[3].HitLogs_Enabled = Value
        end}):AddSettingsMenu("Hit Log Settings")
        HitLogsMenu:AddToggle("HitLogs_ShowDamage", {Text = "Show Damage", Default = UIState[3].HitLogs_ShowDamage, Callback = function(Value)
            UIState[3].HitLogs_ShowDamage = Value
        end})
        HitLogsMenu:AddToggle("HitLogs_ShowDistance", {Text = "Show Distance", Default = UIState[3].HitLogs_ShowDistance, Callback = function(Value)
            UIState[3].HitLogs_ShowDistance = Value
        end})
        HitLogsMenu:AddToggle("HitLogs_ShowPart", {Text = "Show Part", Default = UIState[3].HitLogs_ShowPart, Callback = function(Value)
            UIState[3].HitLogs_ShowPart = Value
        end})

        local function PlaySound(Value)
            if Value ~= "None"  then
                task.spawn(UIFeatures[8], UIFeatures[6][Value], 1, 1)
            end
        end

        local SoundOverride_Groupbox = MiscellaneousTab:AddLeftGroupbox("Sound Override")
        SoundOverride_Groupbox:AddDropdown("SoundOverride_ShootSound", {CallbackOnSameValue = true, Text = "Shoot", Default = UIState[3].SoundOverride_ShootSound, Values = UIFeatures[9], Callback = function(Value)
            UIState[3].SoundOverride_ShootSound = Value
            PlaySound(Value)
        end})
        SoundOverride_Groupbox:AddDropdown("SoundOverride_HitSound", {CallbackOnSameValue = true, Text = "Hit", Default = UIState[3].SoundOverride_HitSound, Values = UIFeatures[9], Callback = function(Value)
            UIState[3].SoundOverride_HitSound = Value
            PlaySound(Value)
        end})
        SoundOverride_Groupbox:AddDropdown("SoundOverride_KillSound", {CallbackOnSameValue = true, Text = "Kill", Default = UIState[3].SoundOverride_KillSound, Values = UIFeatures[9], Callback = function(Value)
            UIState[3].SoundOverride_KillSound = Value
            PlaySound(Value)
        end})

        local Miscellaneous_KnifeAura = MiscellaneousTab:AddRightGroupbox("Knife Aura")
        Miscellaneous_KnifeAura:AddToggle("KnifeAura_Enabled", {Text = "Enabled", Default = UIState[3].KnifeAura_Enabled, Callback = function(Value)
            UIState[3].KnifeAura_Enabled = Value
        end}):AddKeyPicker("KnifeAura_Keybind", {Default = "None", Mode = "Toggle", Text = "Knife Aura", SyncToggleState = true})

        local KnifeAuraDependencyBox = Miscellaneous_KnifeAura:AddDependencyBox():SetupDependencies({{Toggles.KnifeAura_Enabled, true}})
        KnifeAuraDependencyBox:AddDropdown("KnifeAura_Part", {Text = "Part", Default = UIState[3].KnifeAura_Part, Values = {"Head", "Torso", "Random"}, Callback = function(Value)
            UIState[3].KnifeAura_Part = Value
        end})
        KnifeAuraDependencyBox:AddToggle("KnifeAura_Wallbang", {Text = "Wallbang", Default = UIState[3].KnifeAura_Wallbang, Callback = function(Value)
            UIState[3].KnifeAura_Wallbang = Value
        end})
        KnifeAuraDependencyBox:AddSlider("KnifeAura_Range", {
            Text = "Range", Default = UIState[3].KnifeAura_Range, Min = 5, Max = 25, Rounding = 0, Callback = function(Value)
                UIState[3].KnifeAura_Range = Value
            end
        })
        KnifeAuraDependencyBox:AddSlider("KnifeAura_Delay", {
            Text = "Hit Delay", Default = UIState[3].KnifeAura_Delay, Min = 0.1, Max = 0.5, Rounding = 2, Callback = function(Value)
                UIState[3].KnifeAura_Delay = Value
            end
        })

        local Miscellaneous_Movement = MiscellaneousTab:AddRightGroupbox("Movement")
        Miscellaneous_Movement:AddToggle("Movement_NoSlideCooldown", {Text = "No Slide Cooldown", Default = UIState[3].Movement_NoSlideCooldown, Callback = function(Value)
            UIState[3].Movement_NoSlideCooldown = Value
        end})
        Miscellaneous_Movement:AddToggle("Movement_NoFallDamage", {Text = "No Fall Damage", Default = UIState[3].Movement_NoFallDamage, Callback = function(Value)
            UIState[3].Movement_NoFallDamage = Value
        end})
        Miscellaneous_Movement:AddToggle("Movement_BunnyHop", {Text = "Bunny Hop [May Despawn]", Default = UIState[3].Movement_BunnyHop, Callback = function(Value)
            UIState[3].Movement_BunnyHop = Value
        end}):AddKeyPicker("Movement_BunnyHopKeybind", {Default = "None", Mode = "Toggle", Text = "Bunny Hop", SyncToggleState = true})
        Miscellaneous_Movement:AddToggle("Movement_Fly", {Text = "Fly [May Despawn]", Default = UIState[3].Movement_Fly, Callback = function(Value)
            UIState[3].Movement_Fly = Value
        end})

        local FlyMenu = Toggles.Movement_Fly:AddSettingsMenu("Fly Settings")
        FlyMenu:AddKeyPicker("Movement_FlyKeybind", {Default = "None", Mode = "Toggle", Text = "Fly", SyncToggleState = true})
        FlyMenu:AddSlider("Movement_FlySpeed", {Text = "Speed", Default = UIState[3].Movement_FlySpeed, Min = 0, Max = 50, Rounding = 0, Callback = function(Value)
            UIState[3].Movement_FlySpeed = Value
        end})

        Miscellaneous_Movement:AddToggle("Movement_Speed", {Text = "Speed", Default = UIState[3].Movement_Speed, Callback = function(Value)
            UIState[3].Movement_Speed = Value
        end})

        local SpeedMenu = Toggles.Movement_Speed:AddSettingsMenu("Speed Settings")
        SpeedMenu:AddKeyPicker("Movement_SpeedKeybind", {Default = "None", Mode = "Toggle", Text = "Speed", SyncToggleState = true})
        SpeedMenu:AddSlider("Movement_SpeedAmount", {Text = "Amount", Default = UIState[3].Movement_SpeedAmount, Min = 0, Max = 250, Rounding = 0, Callback = function(Value)
            UIState[3].Movement_SpeedAmount = Value
        end})

        Miscellaneous_Movement:AddToggle("Movement_InfiniteStamina", {Text = "Infinite Stamina", Default = UIState[3].Movement_InfiniteStamina, Callback = function(Value)
            UIState[3].Movement_InfiniteStamina = Value
        end})

        local Miscellaneous_AntiAim = MiscellaneousTab:AddRightGroupbox("Anti Aim")
        Miscellaneous_AntiAim:AddToggle("AntiAim_Enabled", {Text = "Enabled", Default = UIState[3].AntiAim_Enabled, Callback = function(Value)
            UIState[3].AntiAim_Enabled = Value
        end}):AddKeyPicker("AntiAim_Keybind", {Default = "None", Mode = "Toggle", Text = "Anti Aim", SyncToggleState = true})

        local AntiAimDependencyBox = Miscellaneous_AntiAim:AddDependencyBox():SetupDependencies({{Toggles.AntiAim_Enabled, true}})
        AntiAimDependencyBox:AddToggle("AntiAim_Yaw", {Text = "Yaw", Default = UIState[3].AntiAim_Yaw, Callback = function(Value)
            UIState[3].AntiAim_Yaw = Value
        end})

        local YawMenu = Toggles.AntiAim_Yaw:AddSettingsMenu("Yaw Settings")
        YawMenu:AddDropdown("AntiAim_YawMode", {Text = "Mode", Default = UIState[3].AntiAim_YawMode, Values = {"Custom - Relative", "Custom - Absolute", "Backwards", "Random", "Cycle"}, Callback = function(Value)
            UIState[3].AntiAim_YawMode = Value
        end})
        YawMenu:AddDependencyBox():SetupDependencies({{Options.AntiAim_YawMode, {"Custom - Relative", "Custom - Absolute"}}}):AddSlider("AntiAim_YawAmount", {
            Text = "Amount", Default = UIState[3].AntiAim_YawAmount, Min = -180, Max = 360, Rounding = 0, Callback = function(Value)
                UIState[3].AntiAim_YawAmount = Value
            end
        })
        YawMenu:AddDependencyBox():SetupDependencies({{Options.AntiAim_YawMode, {"Cycle"}}}):AddSlider("AntiAim_YawSpeed", {
            Text = "Speed", Default = UIState[3].AntiAim_YawSpeed, Min = 0, Max = 50, Rounding = 0, Callback = function(Value)
                UIState[3].AntiAim_YawSpeed = Value
            end
        })
        AntiAimDependencyBox:AddToggle("AntiAim_Pitch", {Text = "Pitch", Default = UIState[3].AntiAim_Pitch, Callback = function(Value)
            UIState[3].AntiAim_Pitch = Value
        end})

        local PitchMenu = Toggles.AntiAim_Pitch:AddSettingsMenu("Pitch Settings")
        PitchMenu:AddDropdown("AntiAim_PitchMode", {Text = "Mode", Default = UIState[3].AntiAim_PitchMode, Values = {"Custom - Relative", "Custom - Absolute", "Rotate", "Random"}, Callback = function(Value)
            UIState[3].AntiAim_PitchMode = Value
        end})
        PitchMenu:AddDependencyBox():SetupDependencies({{Options.AntiAim_PitchMode, {"Custom - Relative", "Custom - Absolute"}}}):AddSlider("AntiAim_PitchAmount", {
            Text = "Amount", Default = UIState[3].AntiAim_PitchAmount, Min = -180, Max = 180, Rounding = 0, Callback = function(Value)
                UIState[3].AntiAim_PitchAmount = Value
            end
        })
        PitchMenu:AddDependencyBox():SetupDependencies({{Options.AntiAim_PitchMode, "Rotate"}}):AddSlider("AntiAim_PitchSpeed", {
            Text = "Speed", Default = UIState[3].AntiAim_PitchSpeed, Min = 0, Max = 50, Rounding = 0, Callback = function(Value)
                UIState[3].AntiAim_PitchSpeed = Value
            end
        })
        AntiAimDependencyBox:AddToggle("AntiAim_Jitter", {Text = "Jitter", Default = UIState[3].AntiAim_Jitter, Callback = function(Value)
            UIState[3].AntiAim_Jitter = Value
        end})

        Toggles.AntiAim_Jitter:AddSettingsMenu("Jitter Settings"):AddSlider("AntiAim_JitterAmount", {
            Text = "Amount", Default = UIState[3].AntiAim_JitterAmount, Min = 0, Max = 360, Rounding = 0, Callback = function(Value)
                UIState[3].AntiAim_JitterAmount = Value
            end
        })
        AntiAimDependencyBox:AddToggle("AntiAim_Spin", {Text = "Spin", Default = UIState[3].AntiAim_Spin, Callback = function(Value)
            UIState[3].AntiAim_Spin = Value
        end})

        local SpinBotMenu = Toggles.AntiAim_Spin:AddSettingsMenu("Spin Settings")
        SpinBotMenu:AddDropdown("AntiAim_SpinDirection", {Text = "Direction", Default = UIState[3].AntiAim_SpinDirection, Values = {"Left", "Right"}, Callback = function(Value)
            UIState[3].AntiAim_SpinDirection = Value
        end})
        SpinBotMenu:AddSlider("AntiAim_SpinSpeed", {Text = "Speed", Default = UIState[3].AntiAim_SpinSpeed, Min = 1, Max = 1000, Rounding = 0, Callback = function(Value)
            UIState[3].AntiAim_SpinSpeed = Value
        end})

        local FakeLagMenu = AntiAimDependencyBox:AddToggle("AntiAim_FakeLag", {Text = "Fake Lag", Default = UIState[3].AntiAim_FakeLag, Callback = function(Value)
            UIState[3].AntiAim_FakeLag = Value
        end}):AddSettingsMenu("Fake Lag Settings")
        FakeLagMenu:AddSlider("AntiAim_FakeLagRefreshDistance", {Text = "Refresh Distance", Default = UIState[3].AntiAim_FakeLagRefreshDistance, Min = 0, Max = 8.9, Rounding = 1, Suffix = " studs", Callback = function(Value)
            UIState[3].AntiAim_FakeLagRefreshDistance = Value
        end})
        FakeLagMenu:AddSlider("AntiAim_FakeLagRefreshRate", {Text = "Refresh Rate", Default = UIState[3].AntiAim_FakeLagRefreshRate, Min = 0, Max = 10, Rounding = 0, Suffix = "s", Callback = function(Value)
            UIState[3].AntiAim_FakeLagRefreshRate = Value
        end})
        FakeLagMenu:AddToggle("AntiAim_FakeLagRandomizePosition", {Text = "Randomize Position", Default = UIState[3].AntiAim_FakeLagRandomizePosition, Callback = function(Value)
            UIState[3].AntiAim_FakeLagRandomizePosition = Value
        end})
        local RandomizePositionBox = FakeLagMenu:AddDependencyBox():SetupDependencies({{Toggles.AntiAim_FakeLagRandomizePosition, true}})
        RandomizePositionBox:AddSlider("AntiAim_FakeLagX", {Text = "X-Axis", Default = UIState[3].AntiAim_FakeLagX, Min = 0, Max = 8.9, Rounding = 1, Suffix = " studs", Callback = function(Value)
            UIState[3].AntiAim_FakeLagX = Value
        end})
        RandomizePositionBox:AddSlider("AntiAim_FakeLagZ", {Text = "Z-Axis", Default = UIState[3].AntiAim_FakeLagZ, Min = 0, Max = 8.9, Rounding = 1, Suffix = " studs", Callback = function(Value)
            UIState[3].AntiAim_FakeLagZ = Value
        end})
        local Miscellaneous_ClientSessionUnlocks = MiscellaneousTab:AddRightGroupbox("Client Session Unlocks")
        Miscellaneous_ClientSessionUnlocks:AddButton({Text = "Unlock Attachments", Func = function()
            UIState[3].ClientSessionUnlocks_AttachmentsUnlocked = true
        end})
        Miscellaneous_ClientSessionUnlocks:AddButton({Text = "Unlock Knives", Func = function()
            UIState[3].ClientSessionUnlocks_KnivesUnlocked = true
        end})
        Miscellaneous_ClientSessionUnlocks:AddButton({Text = "Unlock Camos", Func = function()
            if UIState[3].ClientSessionUnlocks_CamosUnlocked then
                return self:Notify("All camos have already been unlocked.", 3)
            end

            for _,Table in next, (getgc or get_gc)(true) do
                if type(Table) ~= "table" or not rawget(Table, "Mentha Spicata") or not rawget(Table, "Dove blue") then
                    continue
                end

                for Name, Data in next, Table do
                    local Case = Data.Case
                    if Case then
                        PlayerData[2](PlayerData[1](), Case, true).Skins[Name] = {ALL = true}
                    end
                end

                UIState[3].ClientSessionUnlocks_CamosUnlocked = true
                self:Notify("Successfully unlocked all camos.", 5)
                break
            end
        end})
        Miscellaneous_ClientSessionUnlocks:AddLabel("Information [MUST READ | HOVER]", false, "As of 9/19/2026, these Unlocks are undetected, use at your own risk.\n1. These Unlocks only last for the current session and are only visible to you, not others.\n2. Dropping Unlocked weapons makes it lose any Unlocked Add-Ons meaning you'll need to respawn to have the Add-Ons again.\n3. Dropping an Unlocked Knife in a match will make it dissapear.")

        local Miscellaneous_Extras = MiscellaneousTab:AddRightGroupbox("Extras")
        Miscellaneous_Extras:AddToggle("Extras_BreakAllWindows", {Text = "Break All Windows", Default = UIState[3].Extras_BreakAllWindows, Callback = function(Value)
            UIState[3].Extras_BreakAllWindows = Value
        end})
        Miscellaneous_Extras:AddToggle("Extras_HopOnVotekick", {Text = "Hop On Votekick", Default = UIState[3].Extras_HopOnVotekick, Callback = function(Value)
            UIState[3].Extras_HopOnVotekick = Value
        end})

        task.spawn(function()
            while true do
                if UIState[3].Extras_BreakAllWindows then
                    local CameraPosition = GameData[1].CFrame.Position
                    for _,Descendant in next, workspace:QueryDescendants("BasePart#Window") do
                        if Descendant.Position ~= CameraPosition then
                            UIFeatures[7](Descendant, Descendant.Position, (Descendant.Position - CameraPosition).Unit)
                        end
                    end
                    task.wait(4.975)
                end
                task.wait()
            end
        end)
    end

    local function Build_SettingsTab()
        local Settings_UserInterface = SettingsTab:AddLeftGroupbox("User Interface")
        Settings_UserInterface:AddToggle("Watermark_Enabled", {Text = "Watermark", Default = false, Callback = function(Value)
            self.WatermarkState.Frames, self.WatermarkState.LastUpdate = 0, os.clock()
            self.WatermarkOptions.Enabled, self.Watermark.Visible = Value, Value
        end}):AddColorPicker("Watermark_Color", {Default = Color3.fromRGB(255, 255, 255), Callback = function(Value)
            self.WatermarkOptions.Color = Value
        end})

        Settings_UserInterface:AddToggle("OptimizedDragging", {Text = "Optimized Dragging", Default = self.OptimizedDragging, Callback = function(Value)
            self.OptimizedDragging = Value
        end})

        Settings_UserInterface:AddToggle("ActiveKeybindList", {Text = "Active Keybind List", Default = true, Callback = function(Value)
            self.ActiveKeybindFrame.Visible = Value
        end})

        Settings_UserInterface:AddLabel("Menu Toggle Keybind"):AddKeyPicker("Inactive4", {Default = "RightShift", Mode = "Toggle", Modes = {"Toggle"}, Text = "Menu Toggle Keybind", NoUI = true, Callback = function(Value)
            if type(Value) == "boolean" then
                self:Toggle()
            end
        end})

        local Settings_Advanced = SettingsTab:AddRightGroupbox("Advanced")
        Settings_Advanced:AddSlider("Advanced_MultiPointScale", {Text = "Multi-Point Raycasting Scale", Default = UIState[4].Advanced_MultiPointScale, Min = 2, Max = 10, Rounding = 0, Callback = function(Value)
            UIState[4].Advanced_MultiPointScale = Value
            UIFeatures[12]()
        end})

        Settings_Advanced:AddButton({Text = "Server Hop", Func = function()
            local TeleportService = game:GetService("TeleportService")
            local Success, Error
            for _ = 1, 5 do
                Success, Error = pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
                if Success then
                    return
                end
                task.wait(0.5)
            end
            self:Notify("Server hop failed: " .. tostring(Error), 5)
        end}):AddButton({Text = "Rejoin", Func = function()
            local TeleportService = game:GetService("TeleportService")
            local Success, Error
            for _ = 1, 5 do
                Success, Error = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, LocalPlayer)
                if Success then
                    return
                end
                task.wait(0.5)
            end
            self:Notify("Rejoin failed: " .. tostring(Error), 5)
        end})

        Settings_Advanced:AddLabel("Module Method: " .. GameData[4])
    end

    local function Build_ConfigsTab()
        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -16, 1, -16),
            ClipsDescendants = true,
            ZIndex = 2,
            Parent = ConfigsTab.Frame
        })

        local RefreshLocalRows

        local function MakeButton(Parent, Text, Position, Size, Callback)
            local Outer = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Position = Position,
                Size = Size,
                ZIndex = 5,
                Parent = Parent
            })
            local Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = Outer
            })
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = 14,
                Text = Text,
                ZIndex = 6,
                Parent = Inner
            })
            Library:OnHighlight(Outer, Outer, {BorderColor3 = "AccentColor"}, {BorderColor3 = "Black"})
            Outer.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or Library:MouseIsOverOpenedFrame(Outer) then
                    return
                end
                Callback()
            end)
            return Outer, Label
        end

        local LocalPanel = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 2),
            Size = UDim2.new(1, -4, 1, -10),
            ZIndex = 2,
            Parent = Holder
        })

        local ImportPopup = Library:CreateLocalTextPopup("Import Config - Text may be visually cut off, don't worry it will still import the full config.", "Paste config JSON", "Import", true, function(Text)
            local Success, Data = pcall(HttpService.JSONDecode, HttpService, Text)
            if not Success or string.match(Text, "^%s*(.)") ~= "{" or type(Data) ~= "table" then
                return Library:Notify("Please paste a valid config JSON object.", 3)
            end

            local Valid, Error = ValidateConfig(Data)
            if not Valid then
                return Library:Notify(Error, 3)
            end

            local Number = 1
            while isfile("NikoletoScripts/PhantomWare/Configs/ImportedConfig_" .. Number .. ".ns") do
                Number += 1
            end

            local Name = "ImportedConfig_" .. Number
            if WriteLocalConfig(Name, Data) then
                RefreshLocalRows()
                Library:Notify("Imported Config: " .. Name, 3)
                return true
            end
        end)
        local ImportButton = MakeButton(LocalPanel, "Import", UDim2.new(1, -132, 0, 0), UDim2.new(0, 62, 0, 20), function()
            ImportPopup:Show()
        end)

        local LoadedProfile
        local SelectedLocalName
        local ConfigRows = {}
        local SaveCurrentConfig
        local IsSaveLayoutAnimating = false
        local IsSettingConfigName = false

        local NameBox = Library:Create("TextBox", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            Position = UDim2.new(0, 2, 0, 0),
            Size = UDim2.new(1, -252, 0, 20),
            Text = "",
            PlaceholderText = "Config Name",
            ClearTextOnFocus = false,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = LocalPanel
        })

        local AutoloadButton, AutoloadToggleLabel = MakeButton(LocalPanel, "Set as autoload", UDim2.new(1, -246, 0, 0), UDim2.new(0, 110, 0, 20), function()
            if not SelectedLocalName then
                return Library:Notify("Select a config first.", 3)
            end

            if GetAutoload() == SelectedLocalName then
                delfile("NikoletoScripts/PhantomWare/Autoload.ns")
                Library:Notify("Removed Configuration Profile from Autoload.", 3)
            else
                writefile("NikoletoScripts/PhantomWare/Autoload.ns", SelectedLocalName)
                Library:Notify("Set " .. SelectedLocalName .. " as Autoload.", 3)
            end

            RefreshLocalRows()
        end)

        local SaveButton, SaveButtonLabel = MakeButton(LocalPanel, "Save", UDim2.new(1, -66, 0, 0), UDim2.new(0, 62, 0, 20), function()
            if not IsSaveLayoutAnimating then
                SaveCurrentConfig()
            end
        end)

        local function PaintAutoloadToggle()
            AutoloadToggleLabel.Text = SelectedLocalName and GetAutoload() == SelectedLocalName and "Remove autoload" or "Set as autoload"
        end

        local function SelectConfig(Name)
            local Previous = ConfigRows[SelectedLocalName]
            if Previous then
                Previous.BorderColor3 = Library.OutlineColor
            end
            SelectedLocalName = Name

            local Row = ConfigRows[Name]
            if Row then
                Row.BorderColor3 = Library.AccentColor
            end

            PaintAutoloadToggle()
        end
        local SaveLayoutTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local SaveButtonTween, NameBoxTween, AutoloadButtonTween, ImportButtonTween
        local IsOverwriteMode = false
        local SaveModeVersion = 0

        local function ResolveOverwriteName()
            local Name = string.gsub(NameBox.Text, "^%s*(.-)%s*$", "%1")
            if #Name <= 0 then
                return
            end

            local ConfigPath = "NikoletoScripts/PhantomWare/Configs/" .. Name .. ".ns"
            if isfile(ConfigPath) then
                local LowerName = string.lower(Name)
                for ExistingName in next, ConfigRows do
                    if string.lower(ExistingName) == LowerName then
                        return ExistingName
                    end
                end
                return Name
            end
        end

        local function UpdateSaveButtonState()
            local ShouldOverwrite = not not ResolveOverwriteName()
            if ShouldOverwrite == IsOverwriteMode then
                return
            end

            IsOverwriteMode = ShouldOverwrite
            SaveModeVersion += 1
            local Version = SaveModeVersion
            IsSaveLayoutAnimating = true
            if SaveButtonTween then
                SaveButtonTween:Cancel()
            end

            if NameBoxTween then
                NameBoxTween:Cancel()
            end

            if AutoloadButtonTween then
                AutoloadButtonTween:Cancel()
            end

            if ImportButtonTween then
                ImportButtonTween:Cancel()
            end

            SaveButtonLabel.Text = ShouldOverwrite and "Overwrite" or "Save"

            SaveButtonTween = TweenService:Create(SaveButton, SaveLayoutTweenInfo, {
                Position = UDim2.new(1, ShouldOverwrite and -90 or -66, 0, 0),
                Size = UDim2.new(0, ShouldOverwrite and 86 or 62, 0, 20)
            })
            NameBoxTween = TweenService:Create(NameBox, SaveLayoutTweenInfo, {
                Size = UDim2.new(1, ShouldOverwrite and -276 or -252, 0, 20)
            })
            AutoloadButtonTween = TweenService:Create(AutoloadButton, SaveLayoutTweenInfo, {
                Position = UDim2.new(1, ShouldOverwrite and -270 or -246, 0, 0)
            })
            ImportButtonTween = TweenService:Create(ImportButton, SaveLayoutTweenInfo, {
                Position = UDim2.new(1, ShouldOverwrite and -156 or -132, 0, 0)
            })
            SaveButtonTween.Completed:Connect(function(PlaybackState)
                if PlaybackState == Enum.PlaybackState.Completed and Version == SaveModeVersion then
                    IsSaveLayoutAnimating = false
                end
            end)
            SaveButtonTween:Play()
            NameBoxTween:Play()
            AutoloadButtonTween:Play()
            ImportButtonTween:Play()
        end

        local function SetConfigName(Name)
            IsSettingConfigName = true
            NameBox.Text = Name
            IsSettingConfigName = false
            UpdateSaveButtonState()
        end

        NameBox:GetPropertyChangedSignal("Text"):Connect(function()
            if IsSettingConfigName then
                return
            end
            local Name = ResolveOverwriteName()
            if SelectedLocalName ~= Name then
                SelectConfig(Name)
            end
            UpdateSaveButtonState()
        end)

        SaveCurrentConfig = function()
            local ExistingName = ResolveOverwriteName()
            local Name = ExistingName or string.gsub(NameBox.Text, "^%s*(.-)%s*$", "%1")
            if #Name <= 0 then
                return Library:Notify("Please enter a config name.", 3)
            end

            if string.match(Name, "[/\\:*?\"<>|%c]") then
                return Library:Notify("Config name contains invalid characters.", 3)
            end

            local Data = {}

            for Flag, Toggle in next, Toggles do
                if type(Toggle) == "table" and Toggle.Value ~= nil and not string.find(string.lower(Flag), "inactive") then
                    Data[Flag] = {Type = "Toggle", Value = Toggle.Value}
                end
            end

            for Flag, Option in next, Options do
                if type(Option) ~= "table" or string.find(string.lower(Flag), "inactive") then
                    continue
                end

                local Type = Option.Type
                if type(Type) ~= "string" then
                    continue
                end

                if Type == "ColorPicker" then
                    if typeof(Option.Value) == "Color3" then
                        Data[Flag] = {Type = Type, Value = Option.Value:ToHex(), Transparency = Option.Transparency}
                    end
                elseif Type == "KeyPicker" then
                    if Option.Value then
                        Data[Flag] = {Type = Type, Value = Option.Value, Mode = Option.Mode}
                    end
                elseif (Type == "Dropdown" or Type == "Slider") and Option.Value ~= nil then
                    Data[Flag] = {Type = Type, Value = Option.Value}
                end
            end

            if WriteLocalConfig(Name, Data) then
                SetConfigName(Name)
                Library:Notify((ExistingName and "Overwrote" or "Saved") .. " Configuration Profile: " .. Name, 3)
                RefreshLocalRows()
            end
        end

        local LocalListBox = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Position = UDim2.new(0, 0, 0, 26),
            Size = UDim2.new(1, 0, 1, -34),
            ZIndex = 2,
            Parent = LocalPanel
        })
        local LocalRows = MakeScroll(LocalListBox, UDim2.new(0, 8, 0, 8), UDim2.new(1, -16, 1, -16))

        local RenameSourceName
        local RenamePopup = Library:CreateLocalTextPopup("Rename Config", "New config name", "Rename", false, function(Text)
            local NewName = string.gsub(Text, "^%s*(.-)%s*$", "%1")
            if #NewName <= 0 then
                return Library:Notify("Name must contain at least one character.", 3)
            end

            if NewName == RenameSourceName then
                return true
            end

            if string.match(NewName, "[/\\:*?\"<>|%c]") then
                return Library:Notify("Name contains invalid characters.", 3)
            end

            local OldPath = "NikoletoScripts/PhantomWare/Configs/" .. RenameSourceName .. ".ns"
            local NewPath = "NikoletoScripts/PhantomWare/Configs/" .. NewName .. ".ns"
            if isfile(NewPath) then
                return Library:Notify("A config with that name already exists.", 3)
            end

            if not isfile(OldPath) then
                Library:Notify("Config no longer exists.", 3)
                RefreshLocalRows()
                return true
            end

            writefile(NewPath, readfile(OldPath))
            delfile(OldPath)
            if GetAutoload() == RenameSourceName then
                writefile("NikoletoScripts/PhantomWare/Autoload.ns", NewName)
            end

            if LoadedProfile == RenameSourceName then
                LoadedProfile = NewName
            end

            if SelectedLocalName == RenameSourceName then
                SelectedLocalName = NewName
                SetConfigName(NewName)
            end

            Library:Notify("Renamed config to " .. NewName .. ".", 3)
            UpdateSaveButtonState()
            RefreshLocalRows()
            return true
        end)

        RefreshLocalRows = function()
            for _,Child in next, LocalRows:GetChildren() do
                if Child:IsA("GuiObject") then
                    Child:Destroy()
                end
            end
            table.clear(ConfigRows)

            local Names = {}
            if isfolder("NikoletoScripts/PhantomWare/Configs") then
                for _,FilePath in next, listfiles("NikoletoScripts/PhantomWare/Configs") do
                    local Name = string.match(FilePath, "([^/\\]*)%.ns$")
                    if Name then
                        Names[#Names + 1] = Name
                    end
                end
                table.sort(Names)
            end

            for _,Name in next, Names do
                local Row = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderMode = Enum.BorderMode.Inset,
                    Size = UDim2.new(1, -4, 0, 22),
                    ZIndex = 3,
                    Parent = LocalRows
                })
                ConfigRows[Name] = Row

                if SelectedLocalName == Name then
                    Row.BorderColor3 = Library.AccentColor
                end

                Row.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1
                        or Input.Position.X >= Row.AbsolutePosition.X + Row.AbsoluteSize.X - (setclipboard and 256 or 192)
                        or Library:MouseIsOverOpenedFrame(Row) then
                        return
                    end
                    SelectConfig(SelectedLocalName ~= Name and Name or nil)
                    SetConfigName(SelectedLocalName or "")
                end)

                local NameLabel = Library:CreateLabel({
                    Position = UDim2.new(0, 6, 0, 0),
                    Size = UDim2.new(1, setclipboard and -262 or -198, 1, 0),
                    TextSize = 13,
                    Text = Name,
                    TextWrapped = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4,
                    Parent = Row
                })
                if LoadedProfile == Name then
                    NameLabel.TextColor3 = Library.AccentColor
                end

                MakeButton(Row, "Rename", UDim2.new(1, setclipboard and -256 or -192, 0, 1), UDim2.new(0, 60, 0, 18), function()
                    RenameSourceName = Name
                    RenamePopup.Title.Text = "Rename " .. Name
                    RenamePopup:Show(Name)
                end)

                if setclipboard then
                    MakeButton(Row, "Copy", UDim2.new(1, -192, 0, 1), UDim2.new(0, 60, 0, 18), function()
                        local Path = "NikoletoScripts/PhantomWare/Configs/" .. Name .. ".ns"
                        if isfile(Path) then
                            setclipboard(readfile(Path))
                            Library:Notify("Copied Config: " .. Name, 3)
                        else
                            Library:Notify("Config no longer exists.", 3)
                            RefreshLocalRows()
                        end
                    end)
                end

                MakeButton(Row, "Load", UDim2.new(1, -128, 0, 1), UDim2.new(0, 60, 0, 18), function()
                    if LoadLocalConfig(Name) then
                        LoadedProfile = Name
                        RefreshLocalRows()
                    end
                end)

                MakeButton(Row, "Delete", UDim2.new(1, -64, 0, 1), UDim2.new(0, 60, 0, 18), function()
                    local Path = "NikoletoScripts/PhantomWare/Configs/" .. Name .. ".ns"
                    if isfile(Path) then
                        delfile(Path)
                    end

                    if GetAutoload() == Name then
                        delfile("NikoletoScripts/PhantomWare/Autoload.ns")
                    end

                    if LoadedProfile == Name then
                        LoadedProfile = nil
                    end

                    if SelectedLocalName == Name then
                        SelectedLocalName = nil
                    end

                    Library:Notify("Deleted Config: " .. Name, 3)
                    UpdateSaveButtonState()
                    RefreshLocalRows()
                end)
            end
            PaintAutoloadToggle()
        end

        RefreshLocalRows()

        task.defer(function()
            local Autoload = GetAutoload()
            if Autoload and LoadLocalConfig(Autoload) then
                LoadedProfile = Autoload
                RefreshLocalRows()
            end
        end)
    end

    return Build_AimingTab(), Build_VisualsTab(), Build_MiscellaneousTab(), Build_SettingsTab(), Build_ConfigsTab(), Library:Toggle()
end

return Library
