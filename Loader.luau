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
    Discord: https://discord.gg/DsGCKtxxEN / @nikoleto._
]]

repeat task.wait(0.25) until game:IsLoaded()
if workspace.DistributedGameTime < 3 then
    task.wait(3 - workspace.DistributedGameTime)
end

local Players = game:GetService("Players")
repeat task.wait(0.25) until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

if not (listfiles and makefolder and writefile and readfile and delfile and isfile and isfolder) then
    return LocalPlayer:Kick("Exploit not supported.\nReason: Missing file functions")
end

local MainPath = "https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/src/Main.luau"
local Base = "NikoletoScripts/PhantomWare/"
for _,Path in {"NikoletoScripts", string.sub(Base, 1, -2), Base .. "Sounds", Base .. "Configs", Base .. "Cache", Base .. "Logs"} do
    pcall(function()
        if not isfolder(Path) then
            makefolder(Path)
        end
    end)
end

for _,Table in ipairs({{getdeletedactors or get_deleted_actors, run_on_actor or runonactor}, {getactors or get_actors, run_on_actor or runonactor}, {getactorthreads or get_actor_threads, run_on_thread or runonthread or run_on_actor_thread or runonactorthread}}) do
    local Get, Run = Table[1], Table[2]
    if Get and Run then
        local Success, Items = pcall(Get)
        if Success and type(Items) == "table" and Items[1] and pcall(Run, Items[1], string.format("loadstring(game:HttpGet(%q))()", MainPath)) then
            return
        end
    end
end

local Getgc, Getfflag, Setfflag = getgc or get_gc, getfflag or get_fflag, setfflag or set_fflag
for Function, Missing in {["getgc"] = not Getgc, ["getfflag"] = not Getfflag, ["setfflag"] = not Setfflag} do
    if Missing then
        return LocalPlayer:Kick("Exploit not supported.\nReason: Missing function " .. Function)
    end
end

local Success, Error = pcall(Setfflag, "", "")
if not Success and Error and string.find(string.lower(tostring(Error)), "not allowed") then
    return LocalPlayer:Kick("Please check your executor's settings and allow 'setfflag'")
end

local _Success, DebugRunParallelLuaOnMainThread = pcall(Getfflag, "DebugRunParallelLuaOnMainThread")
if not _Success then
    return LocalPlayer:Kick("Exploit not supported.\nReason: Error while calling function 'getfflag'")
end

if string.lower(tostring(DebugRunParallelLuaOnMainThread)) == "true" then
    return loadstring(game:HttpGet(MainPath))()
end
Setfflag("DebugRunParallelLuaOnMainThread", "True")

local QueueOnTeleport = queueonteleport or queue_on_teleport
if QueueOnTeleport then
    pcall(QueueOnTeleport, [[
        repeat task.wait(0.25) until game:IsLoaded()
        if workspace.DistributedGameTime < 3 then
            task.wait(3 - workspace.DistributedGameTime)
        end

        local Players = game:GetService("Players")
        repeat task.wait(0.25) until Players.LocalPlayer
        local LocalPlayer = Players.LocalPlayer

        local Success, DebugRunParallelLuaOnMainThread = pcall(getfflag or get_fflag, "DebugRunParallelLuaOnMainThread")
        if not Success then
            return LocalPlayer:Kick("Exploit not supported.\nReason: Error while calling function 'getfflag'")
        end

        if string.lower(tostring(DebugRunParallelLuaOnMainThread)) == "true" then
            return loadstring(game:HttpGet(']] .. MainPath .. [['))()
        end

        loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/Loader.luau"))()
    ]])
end

task.delay(0.35, function()
    local TeleportService = game:GetService("TeleportService")
    for _ = 1, 5 do
        if pcall(TeleportService.Teleport, TeleportService, game.PlaceId) then
            return
        end
        task.wait(0.5)
    end
    LocalPlayer:Kick("Teleport failed. Please follow these steps to fix the issue:\n1. Click Leave to return to the Roblox Desktop App.\n2. Rejoin Phantom Forces directly from the Desktop App.\n3. Wait for the game to load, then execute PhantomWare again.\n\nIf the issue persists, open a support ticket in our Discord server:\ndiscord.gg/DsGCKtxxEN")
    pcall(setclipboard, "discord.gg/DsGCKtxxEN")
end)
