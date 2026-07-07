--[[
    PhantomWare | Loader
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

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

for Reason, Value in {
    ["Missing function getgenv"] = getgenv, ["Missing Drawing Environment"] = Drawing and Drawing.new,
    ["Missing file functions"] = listfiles and makefolder and writefile and readfile and delfile and isfile and isfolder
} do
    if not Value then
        LocalPlayer:Kick("Exploit not supported.\nReason: " .. Reason)
        return
    end
end

local Base = "NikoletoScripts/PhantomWare/"
for _,Path in {"NikoletoScripts", "NikoletoScripts/PhantomWare", Base .. "Sounds", Base .. "Configs", Base .. "Cache", Base .. "Logs"} do
	pcall(function()
        if not isfolder(Path) then
            makefolder(Path)
        end
    end)
end

local RunOnActor = runonactor or run_on_actor
if RunOnActor then
    local Actors = nil
    local SetActors, GetActor, RunSource = function(Function)
        Actors = Function()
    end, function()
        return Actors and Actors[1]
    end, function (Actor)
        return RunOnActor(Actor, [[loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/Main.luau"))()]])
    end

    local GetDeletedActors = getdeletedactors or get_deleted_actors
    if GetDeletedActors then
        local Actor = pcall(SetActors, GetDeletedActors) and GetActor()
        if Actor and pcall(RunSource, Actor) then
            return
        end
    else
        local GetActors = getactors or get_actors
        if GetActors then
            local Actor = pcall(SetActors, GetActors) and GetActor()
            if Actor and pcall(RunSource, Actor) then
                return
            end
        end
    end
end

local Getgc, Getfflag, Setfflag = getgc or get_gc, getfflag or get_fflag, setfflag or set_fflag
for Function, Value in {["getgc"] = Getgc, ["getfflag"] = Getfflag, ["setfflag"] = Setfflag} do
    if not Value then
        return LocalPlayer:Kick("Exploit not supported.\nReason: Missing function " .. Function)
    end
end

local _,Error = pcall(Setfflag, "", "")
if Error and string.find(string.lower(tostring(Error)), "not allowed") then
    return LocalPlayer:Kick("Please check your executor's settings and allow 'setfflag'")
end

local Success, DebugRunParallelLuaOnMainThread = pcall(Getfflag, "DebugRunParallelLuaOnMainThread")
if not Success then
    return LocalPlayer:Kick("Exploit not supported.\nReason: Error while calling function 'getfflag'")
end

if tostring(DebugRunParallelLuaOnMainThread):lower() == "true" then
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/Main.luau"))()
end

local function Teleport()
    local clonerefFunction = cloneref or clone_ref or clonereference or clone_reference
    local function ns__cloneref(Object)
        if not clonerefFunction then
            return Object
        end
        local ObjectSuccess, Result = pcall(clonerefFunction, Object)
        return ObjectSuccess and Result or Object
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

    local WaitingStatus = Create("TextLabel", Create("ScreenGui", ns__cloneref(game:GetService("CoreGui")), {IgnoreGuiInset = true, ResetOnSpawn = false}), {
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

    game:GetService("TeleportService"):Teleport(game.PlaceId)
end

Setfflag("DebugRunParallelLuaOnMainThread", "True")
local QueueOnTeleport = queueonteleport or queue_on_teleport
if QueueOnTeleport then
    QueueOnTeleport([[
        repeat task.wait(0.25) until game:IsLoaded()
        if workspace.DistributedGameTime < 3 then
            task.wait(3 - workspace.DistributedGameTime)
        end

        local Success, DebugRunParallelLuaOnMainThread = pcall(getfflag or get_fflag, "DebugRunParallelLuaOnMainThread")
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
