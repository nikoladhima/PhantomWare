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

if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

if workspace.DistributedGameTime < 3 then
	task.wait(3 - workspace.DistributedGameTime)
end

local function IsFunction(Function)
    return typeof(Function) == "function" and Function
end

for Reason, Value in {
    ["Missing getgenv"] = IsFunction(getgenv), ["Missing Drawing Environment"] = (Drawing and IsFunction(Drawing.new)),
    ["Missing file functions"] = (IsFunction(isfolder) and IsFunction(makefolder) and IsFunction(delfolder) and IsFunction(
        isfile
    ) and IsFunction(writefile) and IsFunction(readfile) and IsFunction(delfile) and IsFunction(listfiles))
} do
    if not Value then
        game:GetService("Players").LocalPlayer:Kick("Exploit not supported.\nReason: " .. Reason)
        return
    end
end

local Base = "NikoletoScripts/PhantomWare/"
for _,Path in {"NikoletoScripts", "NikoletoScripts/PhantomWare", Base .. "Configs", Base .. "Cache", Base .. "Log"} do
	makefolder(Path)
end

local Request = not isfile("NikoletoScripts/PhantomWare/Cache/Invite.nscache") and httprequest and request
if Request then
    local HttpService = game:GetService("HttpService")
    if pcall(Request, {
        Url = 'http://127.0.0.1:6463/rpc?v=1',  Method = 'POST', Headers = {['Content-Type'] = 'application/json', Origin = 'https://discord.com'},
        Body = HttpService:JSONEncode({cmd = 'INVITE_BROWSER', nonce = HttpService:GenerateGUID(false), args = {code = "DwRT2nH93D"}})
    }) then
        writefile("NikoletoScripts/PhantomWare/Cache/Invite.nscache", "DwRT2nH93D")
    end
end

local function Load(Name, ...)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/" .. Name))(...)
    getgenv().ns__PhantomWare__Executed = true
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

local GetGc, GetFflag, SetFflag = IsFunction(getgc or get_gc), IsFunction(getfflag or get_fflag), IsFunction(setfflag or set_fflag)
if not GetGc or not GetFflag or not SetFflag then
    Load("Lite.luau")
    return
end

local _,Error = pcall(SetFflag, "", "")
if Error and string.find(string.lower(tostring(Error)), "not allowed") then
    game:GetService("Players").LocalPlayer:Kick("Please check your executor's settings and allow 'setfflag'")
    return
end

local Success, DebugRunParallelLuaOnMainThread = pcall(function()
    return GetFflag("DebugRunParallelLuaOnMainThread")
end)

if not Success then
    Load("Lite.luau")
    return
end

if tostring(DebugRunParallelLuaOnMainThread):lower() == "true" then
    Load("Main.luau")
    return
end

SetFflag("DebugRunParallelLuaOnMainThread", "True")
local QueueOnTeleport = IsFunction(queueonteleport or queue_on_teleport)
if QueueOnTeleport then
    QueueOnTeleport([[
        if not game:IsLoaded() then
            repeat task.wait() until game:IsLoaded()
        end

        if workspace.DistributedGameTime < 3 then
            task.wait(3 - workspace.DistributedGameTime)
        end

        local Success, DebugRunParallelLuaOnMainThread = pcall(function()
            return (getfflag or get_fflag)("DebugRunParallelLuaOnMainThread")
        end)

        if not Success then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/Lite.luau"))()
            return
        end

        if tostring(DebugRunParallelLuaOnMainThread):lower() == "true" then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/Main.luau"))()
            return
        end

        loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/Loader.luau"))()
    ]])
    local TeleportService = game:GetService("TeleportService")
    pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId)
    return
end
Load("Lite.luau")
