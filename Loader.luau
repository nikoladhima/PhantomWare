--[[
    ███████████  █████                            █████                             █████   ███   █████
    ▒▒███▒▒▒▒▒███▒▒███                            ▒▒███                             ▒▒███   ▒███  ▒▒███
    ▒███    ▒███ ▒███████    ██████   ████████   ███████    ██████  █████████████   ▒███   ▒███   ▒███   ██████   ████████   ██████
    ▒██████████  ▒███▒▒███  ▒▒▒▒▒███ ▒▒███▒▒███ ▒▒▒███▒    ███▒▒███▒▒███▒▒███▒▒███  ▒███   ▒███   ▒███  ▒▒▒▒▒███ ▒▒███▒▒███ ███▒▒███
    ▒███▒▒▒▒▒▒   ▒███ ▒███   ███████  ▒███ ▒███   ▒███    ▒███ ▒███ ▒███ ▒███ ▒███  ▒▒███  █████  ███    ███████  ▒███ ▒▒▒ ▒███████
    ▒███         ▒███ ▒███  ███▒▒███  ▒███ ▒███   ▒███ ███▒███ ▒███ ▒███ ▒███ ▒███   ▒▒▒█████▒█████▒    ███▒▒███  ▒███     ▒███▒▒▒
    █████        ████ █████▒▒████████ ████ █████  ▒▒█████ ▒▒██████  █████▒███ █████    ▒▒███ ▒▒███     ▒▒████████ █████    ▒▒██████
    ▒▒▒▒▒        ▒▒▒▒ ▒▒▒▒▒  ▒▒▒▒▒▒▒▒ ▒▒▒▒ ▒▒▒▒▒    ▒▒▒▒▒   ▒▒▒▒▒▒  ▒▒▒▒▒ ▒▒▒ ▒▒▒▒▒      ▒▒▒   ▒▒▒       ▒▒▒▒▒▒▒▒ ▒▒▒▒▒      ▒▒▒▒▒▒

    -- Made by Nikoleto Scripts, if you encounter issues, open a ticket in the Discord server.
    GitHub: https://github.com/nikoladhima
    Discord: https://discord.gg/DwRT2nH93D / @nikoleto._
]]

repeat task.wait(0.25) until game:IsLoaded()
if workspace.DistributedGameTime < 3 then
    task.wait(3 - workspace.DistributedGameTime)
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

for Reason, Value in {["Missing function getgenv"] = getgenv, ["Missing file functions"] = listfiles and makefolder and writefile and readfile and delfile and isfile and isfolder} do
    if not Value then
        return LocalPlayer:Kick("Exploit not supported.\nReason: " .. Reason)
    end
end

local MainPath = "https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/src/Main.luau"
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
        return RunOnActor(Actor, "loadstring(game:HttpGet('" .. MainPath .. "'))()")
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
    return loadstring(game:HttpGet(MainPath))()
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
            return loadstring(game:HttpGet(']] .. MainPath .. [['))()
        end

        loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/Loader.luau"))()
    ]])
end

task.delay(0.465, function()
    local TeleportService = game:GetService("TeleportService")
    if pcall(TeleportService.Teleport, TeleportService, game.PlaceId) then
        return
    end

    for _ = 1, 4 do
        if pcall(TeleportService.Teleport, TeleportService, game.PlaceId) then
            break
        end
        task.wait(0.5)
    end

    LocalPlayer:Kick("Failed to teleport, follow these steps to manually fix the issue:\n1. Click the Leave button which will take you to the Desktop App.\n2. Join Phantom Forces again while you are still inside the Desktop App.\n3. Wait until you load and execute PhantomWare again.\nNote: If this issue persists, please open a ticket in the Discord server.\ndiscord.gg/DwRT2nH93D")
    pcall(setclipboard, "discord.gg/DwRT2nH93D")
end)
