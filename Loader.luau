--[[
    PhantomWare | Official Loader
    This project is open-source and intended for learning and personal use.

    Support:
    If you encounter issues, open a ticket in the Discord server.
    You may also contact me (@nikoleto._) via Discord for questions about the code.

    -- Made by Nikoleto Scripts
    GitHub: https://github.com/nikoladhima
    Discord: https://discord.gg/DwRT2nH93D
]]

repeat task.wait(0.25) until game:IsLoaded()
if workspace.DistributedGameTime < 3 then
    task.wait(3 - workspace.DistributedGameTime)
end

local function IsFunction(Function)
    return typeof(Function) == "function" and Function
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

for Reason, Value in {
    ["Missing function getgenv"] = IsFunction(getgenv), ["Missing Drawing Environment"] = (Drawing and IsFunction(Drawing.new)), ["Missing file functions"] = (IsFunction(
        isfolder
    ) and IsFunction(listfiles) and IsFunction(makefolder) and IsFunction(isfile) and IsFunction(writefile) and IsFunction(readfile) and IsFunction(delfile) and IsFunction(
        listfiles
    ))
} do
    if not Value then
        LocalPlayer:Kick("Exploit not supported.\nReason: " .. Reason)
        return
    end
end

local Base = "NikoletoScripts/PhantomWare/"
for _,Path in {"NikoletoScripts", "NikoletoScripts/PhantomWare", Base .. "Sounds", Base .. "Configs", Base .. "Cache", Base .. "Log"} do
	makefolder(Path)
end

local Request = not isfile("NikoletoScripts/PhantomWare/Cache/Invite.nscache") and (httprequest or http_request or request)
if Request then
    local HttpService = game:GetService("HttpService")
    if pcall(Request, {
        Url = 'http://127.0.0.1:6463/rpc?v=1',  Method = 'POST', Headers = {['Content-Type'] = 'application/json', Origin = 'https://discord.com'},
        Body = HttpService:JSONEncode({cmd = 'INVITE_BROWSER', nonce = HttpService:GenerateGUID(false), args = {code = "DwRT2nH93D"}})
    }) then
        writefile("NikoletoScripts/PhantomWare/Cache/Invite.nscache", "DwRT2nH93D")
    end
end

local RunOnActor = IsFunction(runonactor or run_on_actor)
if RunOnActor then
    local Actors = nil
    local SetActors, GetActor, RunSource = function(Function)
        Actors = Function()
    end, function()
        return Actors and Actors[1]
    end, function (Actor)
        return RunOnActor(Actor, [[loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/Main.luau"))()]])
    end

    local GetDeletedActors = IsFunction(getdeletedactors or get_deleted_actors)
    if GetDeletedActors then
        local Actor = pcall(SetActors, GetDeletedActors) and GetActor()
        if Actor and pcall(RunSource, Actor) then
            return
        end
    else
        local GetActors = IsFunction(getactors or get_actors)
        if GetActors then
            local Actor = pcall(SetActors, GetActors) and GetActor()
            if Actor and pcall(RunSource, Actor) then
                return
            end
        end
    end
end

local Getgc, Getfflag, Setfflag = IsFunction(getgc or get_gc), IsFunction(getfflag or get_fflag), IsFunction(setfflag or set_fflag)
for Function, Value in {["getgc"] = Getgc, ["getfflag"] = Getfflag, ["setfflag"] = Setfflag} do
    if not Value then
        return LocalPlayer:Kick("Exploit not supported.\nReason: Missing function " .. Function)
    end
end

local _,Error = pcall(Setfflag, "", "")
if Error and string.find(string.lower(tostring(Error)), "not allowed") then
    return LocalPlayer:Kick("Please check your executor's settings and allow 'setfflag'")
end

local Success, DebugRunParallelLuaOnMainThread = pcall(function()
    return Getfflag("DebugRunParallelLuaOnMainThread")
end)

if not Success then
    return LocalPlayer:Kick("Exploit not supported.\nReason: Error while calling function 'getfflag'")
end

if tostring(DebugRunParallelLuaOnMainThread):lower() == "true" then
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/Main.luau"))()
end

local function Teleport()
    local TeleportService = game:GetService("TeleportService")
    local TweenService = game:GetService("TweenService")
    local ns__cloneref = cloneref or clone_ref or clonereference or clone_reference or function(Function)
        return Function
    end

    local function Create(Type, Parent, Properties, ...)
        local Object = ns__cloneref(Instance.new(Type))

        if Properties then
            for Property, Value in next, Properties do
                Object[Property] = Value
            end
        end

        if Parent then
            Object.Parent = Parent
        end

        for _,Child in next, {...} do
            Child.Parent = Object
        end

        return Object
    end

    local LoadingGui = Create("ScreenGui", ns__cloneref(game:GetService("CoreGui")), {IgnoreGuiInset = true, ResetOnSpawn = false})
	local function PlayTween(Tween)
		Tween:Play()
		return Tween
    end

    local WaitingStatus = Create("TextLabel", LoadingGui, {
        Size = UDim2.fromOffset(400, 100), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0.15, TextColor3 = Color3.new(1, 1, 1), TextScaled = true,  Font = Enum.Font.GothamBold, Text = ""
    }, Create("UICorner", nil, {CornerRadius = UDim.new(0, 12)}), Create("UIStroke", nil, {Color = Color3.fromRGB(
        90, 90, 100
    ), Thickness = 1, Transparency = 0.3}), Create("UIPadding", nil, {PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(
        0, 12
    ), PaddingBottom = UDim.new(0, 12)}))

    for Index = 10, 1, -1 do
        WaitingStatus.Text = "Teleporting in " .. Index .. " " .. (Index < 2 and "second" or "seconds") .. ".\nPlease execute the script again after you load."
        task.wait(1)
    end

    local LeftCurtain  = Create("Frame", LoadingGui, {Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(-0.5, 0), BackgroundColor3 = Color3.fromRGB(
		30, 30, 38
	), BorderSizePixel = 0, ZIndex = 20})

    local RightCurtain = Create("Frame", LoadingGui, {Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.fromRGB(
		30, 30, 38
	),  BorderSizePixel = 0,  ZIndex = 20})

	TweenService:Create(LeftCurtain, TweenInfo.new(1.1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, 0)}):Play()
    PlayTween(TweenService:Create(RightCurtain, TweenInfo.new(1.1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(0.5, 0)
	})).Completed:Wait()
    task.wait(0.15)
    WaitingStatus:Destroy()

    local MainFrame = Create("Frame", Create("Frame", LoadingGui, {Size = UDim2.fromOffset(520, 260), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(
		0.5, 0.5
	), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 25}), {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(
		20, 20, 28
	), BackgroundTransparency = 1}, Create("UICorner", nil, {CornerRadius = UDim.new(0, 18)}), Create("UIStroke", nil, {Color = Color3.fromRGB(
		120, 120, 140
	), Thickness = 1, Transparency = 1, BorderStrokePosition = Enum.BorderStrokePosition.Inner}), Create("TextLabel", nil, {Size = UDim2.new(
		1, 0, 0, 36
	), Position = UDim2.fromScale(0.5, 0.1), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = Color3.fromRGB(
		240, 240, 255
	), TextTransparency = 1, BackgroundTransparency = 1, Text = "PhantomWare | discord.gg/DwRT2nH93D", Font = Enum.Font.GothamBold, TextSize = 26}))

    local IconFrame = Create("Frame", MainFrame, {Size = UDim2.fromOffset(140, 140), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(
		0.5, 0.5
	), BackgroundTransparency = 1})

    local Icon = Create("ImageLabel", IconFrame, {BackgroundTransparency = 1, Image = "rbxassetid://77211109346710", ImageTransparency = 1, Size = UDim2.fromScale(
		1, 1
	), ScaleType = Enum.ScaleType.Fit, Rotation = 0}, Create("UICorner", nil, {CornerRadius = UDim.new(0, 16)}))

    local LoadingStatus = Create("TextLabel", MainFrame, {Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromScale(0.5, 0.85), AnchorPoint = Vector2.new(
		0.5, 0.5
	), BackgroundTransparency = 1, Text = "Teleporting",  TextColor3 = Color3.fromRGB(240, 240, 255), TextTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 28})

    Create("Frame", LoadingGui, {Size = UDim2.fromScale(1, 1),  BackgroundColor3 = Color3.fromRGB(12, 12, 16), BackgroundTransparency = 0, ZIndex = 0})

    TweenService:Create(LeftCurtain,  TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(-0.5, 0)}):Play()
	PlayTween(TweenService:Create(RightCurtain, TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(1, 0)
	})).Completed:Wait()

    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05}):Play()
	TweenService:Create(MainFrame.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.5}):Play()

    task.wait(0.1)

    local Title = MainFrame:FindFirstChildOfClass("TextLabel")
	Title.Position = UDim2.fromScale(0.5, -0.05)
	TweenService:Create(Title, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.1),
		TextTransparency = 0,
	}):Play()

    task.wait(0.12)

    IconFrame.Position = UDim2.fromScale(0.5, 0.55)
    TweenService:Create(IconFrame, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.45)}):Play()
    TweenService:Create(Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.05}):Play()

    task.wait(0.15)

    LoadingStatus.Position = UDim2.fromScale(0.5, 0.95)
    TweenService:Create(LoadingStatus, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(
		0.5, 0.85
	), TextTransparency = 0}):Play()

    task.spawn(function()
        for Index = 1, 7 do
			if Index == 4 then
				LoadingStatus.Text = "Teleporting"
				continue
			end
            LoadingStatus.Text ..= "."
            task.wait(0.4)
        end
    end)

    for Index = 1, 2 do
        local Tween = PlayTween(TweenService:Create(Icon, TweenInfo.new(1.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = 360 * Index}))
        task.spawn(function()
            TweenService:Create(IconFrame, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromOffset(152, 152)}):Play()
            task.wait(0.55)
            TweenService:Create(IconFrame, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromOffset(140, 140)}):Play()
        end)
        Tween.Completed:Wait()
    end

    TeleportService:SetTeleportGui(LoadingGui)
    local getconnections = getconnections or get_connections
    if getconnections then
        pcall(function()
            for _,Connection in getconnections(game:GetService("LogService").MessageOut) do
                Connection:Disable()
            end
        end)
    end
    TeleportService:Teleport(game.PlaceId)
end

Setfflag("DebugRunParallelLuaOnMainThread", "True")
local QueueOnTeleport = IsFunction(queueonteleport or queue_on_teleport)
if QueueOnTeleport then
    QueueOnTeleport([[
        repeat task.wait(0.25) until game:IsLoaded()
        if workspace.DistributedGameTime < 4 then
            task.wait(4 - workspace.DistributedGameTime)
        end

        local Success, DebugRunParallelLuaOnMainThread = pcall(function()
            return (getfflag or get_fflag)("DebugRunParallelLuaOnMainThread")
        end)

        if not Success then
           return LocalPlayer:Kick("Exploit not supported.\nReason: Error while calling function 'getfflag'")
        end

        if tostring(DebugRunParallelLuaOnMainThread):lower() == "true" then
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/Main.luau"))()
        end

        loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/Loader.luau"))()
    ]])
    return pcall(Teleport)
end
pcall(Teleport)
