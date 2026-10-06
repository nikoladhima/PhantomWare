if getgenv().ns__PhantomWare__Executed then
	return
end

getgenv().ns__PhantomWare__Executed = true
pcall(clearteleportqueue or clear_teleport_queue or clearqueueonteleport)

local LocalPlayer, MenuScreenGui, Module
do
	local Players = game:GetService("Players")
	repeat task.wait() until Players.LocalPlayer
	LocalPlayer = Players.LocalPlayer
	MenuScreenGui = LocalPlayer:WaitForChild("PlayerGui", 9e9):WaitForChild("MenuScreenGui", 9e9)

	local Method, ns__require = "Unknown", nil
	if typeof(getrenv or get_renv) == "function" then
		local Success, Environment = pcall(getrenv or get_renv)
		ns__require = Success and Environment and Environment.shared and Environment.shared.require
		Method = "shared.require"
	end

	local ModuleCache, ExecutorName = nil, identifyexecutor and identifyexecutor() or tostring((getexecutorname and getexecutorname()))
	if typeof(ns__require) ~= "function" then
		local ns__Count = 0
		while ns__Count < 10 do
			local ReplicationInterface = ModuleCache and ModuleCache.ReplicationInterface
			if ReplicationInterface and ReplicationInterface.operateOnAllEntries then
				break
			end

			for _,Value in next, (getgc or get_gc)(true) do
				if type(Value) == "table" and rawget(Value, "ScreenCull") and rawget(Value, "NetworkClient") then
					ModuleCache = {}
					for Name, Data in next, Value do
						ModuleCache[Name] = type(Data) == "table" and Data.module or Data
					end
				end
			end

			ns__Count += 1
			task.wait(0.5)
		end

		if not ModuleCache then
			getgenv().ns__PhantomWare__Executed = false
			pcall(setfflag or set_fflag, "DebugRunParallelLuaOnMainThread", "True")
			return LocalPlayer:Kick("Error while accessing Game Modules, try rejoining through the desktop app, if this issue persists, please make a ticket in the discord server immediately.\ndiscord.gg/DwRT2nH93D" .. (ExecutorName and (" | " .. ExecutorName) or ""))
		end

		ns__require, Method = function(Name)
			return ModuleCache[Name]
		end, "fenv.getgc"
	elseif not ns__require then
		getgenv().ns__PhantomWare__Executed = false
		pcall(setfflag or set_fflag, "DebugRunParallelLuaOnMainThread", "True")
		return LocalPlayer:Kick("Error while accessing Game Modules, try rejoining through the desktop app, if this issue persists, please make a ticket in the discord server immediately.\ndiscord.gg/DwRT2nH93D" .. (ExecutorName and (" | " .. ExecutorName) or ""))
	end

	Module = {Method = Method, ExecutorName = ExecutorName, LocalPlayer = LocalPlayer, Players = Players, __get = function(Name)
		local function __internal()
			local Success, Result = pcall(ns__require, Name)
			if Success then
				return Result
			end

			if string.find(tostring(Result), "Reciprocal") then
				return
			end

			return LocalPlayer:Kick("Failed to require Module '" .. Name .. " ', error[" .. tostring(Result) .. "]\nPlease make a ticket in the discord server immediately.\ndiscord.gg/DwRT2nH93D")
		end

		local Source = __internal()
		if not Source then
			local StartTime = os.clock()
			while true do
				if os.clock() - StartTime >= 5 then
					LocalPlayer:Kick("Module Access Timeout, please make a ticket in the discord server immediately.\ndiscord.gg/DwRT2nH93D\nDebug Info: " .. ExecutorName .. " | " .. Name .. ": " .. (ModuleCache and "fenv.getgc" or "shared.require"))
					pcall(setclipboard, "discord.gg/DwRT2nH93D")
					break
				end

				Source = __internal()
				if Source then
					break
				end

				task.wait(0.5)
			end
		end
		return Source
	end}
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/src/libs/UI.luau"))()
local clonerefFunction = cloneref or clone_ref or clonereference or clone_reference
local ns__cloneref = clonerefFunction and function(Object)
	local Success, Result = pcall(clonerefFunction, Object)
	return Success and Result or Object
end or function(Object)
    return Object
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = ns__cloneref(game:GetService("CoreGui"))
local Debris = game:GetService("Debris")
local Terrain = ns__cloneref(workspace:WaitForChild("Terrain", 9e9))

local IgnoreFolder = workspace:WaitForChild("Ignore", 9e9)
local DeadBodyFolder = IgnoreFolder:WaitForChild("DeadBody", 9e9)
local Camera, Map = workspace:WaitForChild("Camera", 9e9), workspace:WaitForChild("Map", 9e9)

local AimingRaycastParams = RaycastParams.new()
AimingRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
AimingRaycastParams.FilterDescendantsInstances = {IgnoreFolder, workspace:WaitForChild("Players", 9e9), workspace:WaitForChild("Roots", 9e9), Camera, Terrain}

local TransparentRaycastParams = RaycastParams.new()
TransparentRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local BulletRaycastParams = RaycastParams.new()
BulletRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
BulletRaycastParams.FilterDescendantsInstances = {IgnoreFolder, Camera, Terrain}

local GrenadeRaycastParams = RaycastParams.new()
GrenadeRaycastParams.FilterType = Enum.RaycastFilterType.Include
GrenadeRaycastParams.FilterDescendantsInstances = {Map}
GrenadeRaycastParams.IgnoreWater = true

local GrenadeImpactParams = RaycastParams.new()
GrenadeImpactParams.FilterType = Enum.RaycastFilterType.Include
GrenadeImpactParams.IgnoreWater = true

local BodyParts = {"Head", "Torso", "Arms", "Legs"}
local ColorCache = setmetatable({}, {__mode = "kv", __index = function(self, Color)
	local DarkerColor = Color3.new(Color.R * 0.85, Color.G * 0.85, Color.B * 0.85)
	rawset(self, Color, DarkerColor)
	return DarkerColor
end})

local AimbotState = {}
local Aiming = {
	Aimbot_Enabled = false,
	Aimbot_Keybind = "None",
	Aimbot_Type = "None",
	Aimbot_Part = "Head",
	Aimbot_Smoothness = 3,
	Aimbot_AutoFire = false,
	Aimbot_AutoWall = false,
	Aimbot_AutoDelay = 0,
	Aimbot_HitChance = 100,
	Aimbot_BulletCache = true,
	Aimbot_WallCheck = false,
	Aimbot_DeathNotification = true,
	Aimbot_ShowFOVCircle = true,
	Aimbot_FOVCircleColor = Color3.fromRGB(255, 255, 255),
	Aimbot_FOVCircleOpacity = 1,
	Aimbot_FOVCircleFollowRecoil = false,
	Aimbot_FOVCircleRadius = 150,
	Aimbot_TargetTracer = true,
	Aimbot_TargetTracerColor = Color3.fromRGB(255, 255, 255),
	Aimbot_TargetTracerOpacity = 1,
	Aimbot_RedirectGrenade = false,
	Aimbot_FuseAssist = false,

	RageBot_Enabled = false,
	RageBot_Keybind = "None",
	RageBot_Part = "Head",
	RageBot_WallPenetrationDetection = true,
	RageBot_Collateral = false,
	RageBot_HitScanning = true,
	RageBot_HitScanningMode = "Cardinal",
	RageBot_HitScanningRadius = 1,
	RageBot_FireScanning = true,
	RageBot_FireScanningMode = "Cardinal",
	RageBot_FireScanningRadius = 3,
	RageBot_FireScanningCount = 8,
	RageBot_Backtrack = true,
	RageBot_BacktrackScans = 2,
	RageBot_BacktrackTime = 200
}

local Visuals = {
	ESPVisuals_MasterSwitch = true,

	ESPVisuals_MasterOpacity = 100,
	ESPVisuals_MaxDistance = 10000,

	ESPVisuals_PerformanceMode = false,
	ESPVisuals_PerformanceQuality = "Balanced",

	ESPVisuals_Chams = false,
	ESPVisuals_ChamColor = Color3.fromRGB(255, 0, 0),
	ESPVisuals_ChamRendering = {Fill = true, Outline = true},
	ESPVisuals_ChamStyle = "Solid",
	ESPVisuals_ChamVisibleColor = Color3.fromRGB(0, 255, 0),
	ESPVisuals_ChamOccluded = false,

	ESPVisuals_Skeletons = false,
	ESPVisuals_SkeletonColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_SkeletonThickness = 1.5,
	ESPVisuals_SkeletonHeadDot = false,

	ESPVisuals_HeadTags = false,
	ESPVisuals_HeadTagColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_HeadTagElements = {Name = true, Health = true, Distance = true},
	ESPVisuals_HeadTagSize = 13,

	ESPVisuals_Boxes = false,
	ESPVisuals_BoxColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_BoxStyle = "Full",
	ESPVisuals_BoxThickness = 1.5,

	ESPVisuals_Healthbars = false,
	ESPVisuals_HealthbarStyle = "Solid",
	ESPVisuals_HealthbarColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_HealthbarSide = "Left",
	ESPVisuals_HealthbarWidth = 2,

	ESPVisuals_Tracers = false,
	ESPVisuals_TracerColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_TracerOrigin = "Bottom",
	ESPVisuals_TracerThickness = 1.5,

	ESPVisuals_OffscreenArrows = false,
	ESPVisuals_OffscreenArrowColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_OffscreenArrowFilled = false,
	ESPVisuals_OffscreenArrowSize = 14,
	ESPVisuals_OffscreenArrowRadius = 300,

	ESPVisuals_SoundRings = false,
	ESPVisuals_SoundRingsColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_SoundRingsThroughWalls = true,
	ESPVisuals_SoundRingsDuration = 0.8,

	ESPVisuals_GrenadeTags = false,
	ESPVisuals_GrenadeTagColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_GrenadeTagSize = 13,
	ESPVisuals_GrenadeTagUseName = false,

	Combat_LocalBulletTracers = false,
	Combat_LocalBulletTracerColor = Color3.fromRGB(255, 255, 255),
	Combat_LocalBulletTracerAlpha = 0.85,
	Combat_LocalBulletTracerType = "Beam",
	Combat_LocalBulletTracerFadeMode = "Width",
	Combat_LocalBulletTracerThickness = 3.5,
	Combat_LocalBulletTracerDuration = 0.55,

	Combat_EnemyBulletTracers = false,
	Combat_EnemyBulletTracerColor = Color3.fromRGB(255, 50, 50),
	Combat_EnemyBulletTracerAlpha = 0.85,
	Combat_EnemyBulletTracerType = "Beam",
	Combat_EnemyBulletTracerFadeMode = "Width",
	Combat_EnemyBulletTracerThickness = 3.5,
	Combat_EnemyBulletTracerDuration = 0.55,

	Combat_TeamBulletTracers = false,
	Combat_TeamBulletTracerColor = Color3.fromRGB(50, 255, 50),
	Combat_TeamBulletTracerAlpha = 0.85,
	Combat_TeamBulletTracerType = "Beam",
	Combat_TeamBulletTracerFadeMode = "Width",
	Combat_TeamBulletTracerThickness = 3.5,
	Combat_TeamBulletTracerDuration = 0.55,

	Combat_GrenadeTrajectory = false,
	Combat_GrenadeTrajectoryIgnoreAimbot = false,
	Combat_GrenadeTrajectoryBounces = 1,
	Combat_GrenadeTrajectoryThickness = 2,

	Combat_CustomCrosshair = false,
	Combat_CustomCrosshairSize = 12,
	Combat_CustomCrosshairGap = 6,
	Combat_CustomCrosshairThickness = 1.5,
	Combat_CustomCrosshairColor = Color3.fromRGB(255, 255, 255),
	Combat_CustomCrosshairFollowRecoil = false,
	Combat_CustomCrosshairFollowSpread = true,
	Combat_CustomCrosshairSpin = false,
	Combat_CustomCrosshairSpinSpeed = 3,

	Combat_CustomRagdolls = false,
	Combat_RagdollEffect = "Launch",
	Combat_RagdollEffectLaunchForce = 150,
	Combat_RagdollEffectFlingForce = 150,
	Combat_RagdollEffectFloatSpeed = 10,
	Combat_RagdollGhost = false,
	Combat_RagdollGhostColor = Color3.fromRGB(255, 255, 255),

	Combat_HitParticles = false,
	Combat_HitParticleEffect = "Snow",
	Combat_HitParticleAmount = 25,
	Combat_HitParticleSize = 1,
	Combat_HitParticleLifetime = 1,

	Combat_HitMarkers = false,
	Combat_HitMarkerColor = Color3.fromRGB(255, 255, 255),
	Combat_HitMarkerStyle = "X",
	Combat_HitMarkerSize = 8,
	Combat_HitMarkerGap = 3,
	Combat_HitMarkerRadius = 10,
	Combat_HitMarkerThickness = 1.5,
	Combat_HitMarkerDuration = 0.5,
	Combat_HitMarkerFadeInOutAnimation = true,
	Combat_HitMarkerSpin = false,
	Combat_HitMarkerSpinSpeed = 5,

	Combat_HitGhosts = false,
	Combat_HitGhostsLifetime = 2,
	Combat_HitGhostsColor = Color3.fromRGB(255, 255, 255),
	Combat_HitGhostsOnKillOnly = false,

	Combat_RadarHack = false,
	Combat_AutoSpot = false,

	Camera_NoSuppression = false,
	Camera_NoBob = false,

	Camera_CustomFOV = false,
	Camera_ApplyToAim = false,
	Camera_FOVValue = 120,

	Camera_ThirdPerson = false,
	Camera_ThirdPersonKeybind = "None",
	Camera_ThirdPersonCameraCollision = true,
	Camera_ThirdPersonOffsetX = 0,
	Camera_ThirdPersonOffsetY = 0,
	Camera_ThirdPersonOffsetZ = 7,
	Camera_ThirdPersonShowCharacter = false,
	Camera_ThirdPersonHideCharacterWhileAiming = false,

	ViewModel_WeaponChams = false,
	ViewModel_WeaponChamColor = Color3.fromRGB(100, 0, 255),
	ViewModel_WeaponChamType = "ForceField",
	ViewModel_WeaponChamTranslucent = false,

	ViewModel_ArmChams = false,
	ViewModel_ArmChamColor = Color3.fromRGB(100, 0, 255),
	ViewModel_ArmChamType = "ForceField",
	ViewModel_ArmChamTranslucent = false,

	ViewModel_NoSleeves = false,

	ViewModel_CustomOffset = false,
	ViewModel_OffsetX = 0,
	ViewModel_OffsetY = 0,
	ViewModel_OffsetZ = 0,

	ViewModel_CustomRotation = false,
	ViewModel_RotationX = 0,
	ViewModel_RotationY = 0,
	ViewModel_RotationZ = 0,

	ViewModel_CustomRoll = false,
	ViewModel_Roll = 0,

	Lighting_Custom = false,
	Lighting_ExposureCompensation = 0.5,
	Lighting_Ambient = Color3.fromRGB(150, 150, 150),
	Lighting_OutdoorAmbient = Color3.fromRGB(150, 150, 150),
	Lighting_EnvironmentDiffuseScale = 0.5,
	Lighting_EnvironmentSpecularScale = 0.5,
	Lighting_ShadowSoftness = 0.5,

	Lighting_Bloom = false,
	Lighting_BloomIntensity = 1,
	Lighting_BloomSize = 24,
	Lighting_BloomThreshold = 2,

	Lighting_Flashlight = false,
	Lighting_FlashlightColor = Color3.fromRGB(177, 165, 165),
	Lighting_FlashlightBrightness = 4,
	Lighting_FlashlightRange = 60,
	Lighting_FlashlightAngle = 70
}

local Miscellaneous = {
	WeaponMods_AutomaticGun = false,
	WeaponMods_RecoilAdjustment = 100,
	WeaponMods_SpreadAdjustment = 100,

	WeaponMods_NoWeaponSway = false,
	WeaponMods_NoScopeSway = false,
	WeaponMods_NoWalkSway = false,

	WeaponMods_InstantEquipUnequip = false,
	WeaponMods_InstantReload = false,
	WeaponMods_InstantAim = false,

	WeaponMods_UncookableGrenade = false,
	WeaponMods_CustomGrenadeFuse = false,
	WeaponMods_CustomGrenadeFuseOnImpact = false,
	WeaponMods_CustomGrenadeFuseAmount = 5,

	WeaponMods_CustomMuzzleFlash = false,
	WeaponMods_MuzzleFlashColor = Color3.fromRGB(255, 150, 50),
	WeaponMods_MuzzleFlashMaterial = "Neon",
	WeaponMods_MuzzleFlashSize = 1,
	WeaponMods_MuzzleFlashLocalOnly = true,

	HitLogs_Enabled = false,
	HitLogs_ShowDamage = false,
	HitLogs_ShowDistance = false,
	HitLogs_ShowPart = true,

	SoundOverride_ShootSound = "None",
	SoundOverride_HitSound = "None",
	SoundOverride_KillSound = "None",

	KnifeAura_Enabled = false,
	KnifeAura_Keybind = "None",
	KnifeAura_Range = 10,
	KnifeAura_Delay = 0.35,
	KnifeAura_Wallbang = true,
	KnifeAura_Part = "Head",

	Movement_NoFallDamage = false,
	Movement_BunnyHop = false,
	Movement_BunnyHopKeybind = "None",
	Movement_NoSlideCooldown = false,
	Movement_Speed = false,
	Movement_SpeedKeybind = "None",
	Movement_SpeedAmount = 16,
	Movement_Fly = false,
	Movement_FlyKeybind = "None",
	Movement_FlySpeed = 16,

	AntiAim_Enabled = false,
	AntiAim_Keybind = "None",
	AntiAim_Yaw = false,
	AntiAim_YawMode = "Custom - Relative",
	AntiAim_YawAmount = 180,
	AntiAim_YawSpeed = 5,
	AntiAim_Pitch = false,
	AntiAim_PitchMode = "Custom - Relative",
	AntiAim_PitchAmount = 90,
	AntiAim_PitchSpeed = 5,
	AntiAim_Jitter = false,
	AntiAim_JitterAmount = 30,
	AntiAim_Spin = false,
	AntiAim_SpinDirection = "Right",
	AntiAim_SpinSpeed = 360,

	Extras_LoopBreakAllWindows = false,
	Extras_HopOnVotekick = false,

	ClientSessionUnlocks_AttachmentsUnlocked = false,
	ClientSessionUnlocks_CamosUnlocked = false,
	ClientSessionUnlocks_KnivesUnlocked = false
}

local Settings = {
	Advanced_MultiPointEnabled = true,
	Advanced_MultiPointLayers = 2,
	Advanced_MultiPointScale = 2,
}

local LightingCache = {
	OriginalValues = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ExposureCompensation = Lighting.ExposureCompensation,
		EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		ShadowSoftness = Lighting.ShadowSoftness,
		LightingStyle = Lighting.LightingStyle
	}, Connections = {}
}

local BloomEffect = Instance.new("BloomEffect")
BloomEffect.Enabled = false
BloomEffect.Parent = Lighting

local function RefreshLighting(Revert)
	if not Revert then
		for _,Setting in {"Ambient", "OutdoorAmbient", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness"} do
			Lighting[Setting] = Visuals["Lighting_" .. Setting]
		end
		return
	end

	for Property, OriginalValue in next, LightingCache.OriginalValues do
		Lighting[Property] = OriginalValue
	end
end

local function UpdateBloom()
	BloomEffect.Intensity = Visuals.Lighting_BloomIntensity
	BloomEffect.Size = Visuals.Lighting_BloomSize
	BloomEffect.Threshold = Visuals.Lighting_BloomThreshold
	BloomEffect.Enabled = Visuals.Lighting_Bloom
end

local RoundSystemClientInterface = Module.__get("RoundSystemClientInterface")
local PlayerDataClientInterface = Module.__get("PlayerDataClientInterface")
local HudCrosshairsInterface = Module.__get("HudCrosshairsInterface")
local CharacterInterface = Module.__get("CharacterInterface")
local _,CameraInterface = coroutine.resume(coroutine.create(function(CameraInterface)
	pcall(function()
		local FunctionEnvironment = getfenv(CameraInterface.setCameraType)
		FunctionEnvironment.warn = function() end
		FunctionEnvironment.print = function() end
	end)
	return CameraInterface
end), Module.__get("CameraInterface"))

local PlayerDataUtils = Module.__get("PlayerDataUtils")
local PublicSettings = Module.__get("PublicSettings")
local FirearmObject = Module.__get("FirearmObject")
local NetworkClient = Module.__get("NetworkClient")
local CharacterObject = Module.__get("CharacterObject")
local AudioSystem = Module.__get("AudioSystem")
local BulletCheck = Module.__get("BulletCheck")
local GrenadeObject = Module.__get("GrenadeObject")
local MeleeObject = Module.__get("MeleeObject")
local Effects = Module.__get("Effects")

local GetGameClockTime = Module.__get("GameClock").getTime
local NetworkClientSend = NetworkClient.send
local GetLocalCharacter = CharacterInterface.getCharacterObject
local GetActiveCamera = CameraInterface.getActiveCamera
local PlayGameSound = AudioSystem.play
local GetPlayerStatusEntry = Module.__get("PlayerStatusInterface").getEntry
local OperateOnAllEntries = Module.__get("ReplicationInterface").operateOnAllEntries
local MuzzleFlash = Effects.muzzleflash

local BulletLifetime = PublicSettings.bulletLifeTime
local BulletAcceleration = PublicSettings.bulletAcceleration

local CachedPlayers, MovementCache, MovementCached = table.create(Module.Players.MaxPlayers), table.create(Module.Players.MaxPlayers), {}
local function RefreshCache()
	local Players, Now = {}, os.clock()
	local CacheMovement = Aiming.Aimbot_Enabled and Aiming.Aimbot_Type == "Silent" or (Aiming.RageBot_Enabled and (Aiming.RageBot_Collateral or Aiming.RageBot_Backtrack))
	OperateOnAllEntries(function(Player, Entry)
		if not (Entry._alive and Entry._receivedPosition) then
			return
		end

		Players[Player] = Entry
		if not Entry._isEnemy then
			if MovementCache[Player] then
				MovementCache[Player] = nil
			end
			return
		end

		if CacheMovement then
			MovementCached[Player] = true

			local Cache = MovementCache[Player]
			if not Cache then
				Cache = {}
				MovementCache[Player] = Cache
			end

			for Index = math.min(#Cache, 14), 1, -1 do
				Cache[Index + 1] = Cache[Index]
			end

			local CharacterHash = Entry._thirdPersonObject._characterModelHash
			Cache[1] = {Head = CharacterHash.Head.Position, Torso = CharacterHash.Torso.Position, Time = Now}
		end
	end)
	CachedPlayers = Players

	for Player in next, MovementCache do
		if not MovementCached[Player] then
			MovementCache[Player] = nil
		end
	end
	table.clear(MovementCached)
end

local function GetActiveWeapon()
	local Character = GetLocalCharacter()
	if Character then
		local WeaponController = Character._weaponController
		if WeaponController then
			return WeaponController._activeWeaponRegistry[WeaponController._activeWeaponIndex]
		end
	end
end

local LocalHead = nil
local function GetLocalPosition()
	if not LocalHead or not LocalHead.Parent then
		for _,Child in next, IgnoreFolder:GetChildren() do
			local Head = Child:IsA("Model") and Child:FindFirstChild("Head")
			if Head then
				LocalHead = Head
				return Head.Position
			end
		end
		return Camera.CFrame.Position
	end
	return LocalHead.Position
end

local function SolvePolynomial(Coeff1, Coeff2, Coeff3, Coeff4, Coeff5)
	if not Coeff1 then
		return
	end

	if Coeff1 > -1e-10 and Coeff1 < 1e-10 then
		return SolvePolynomial(Coeff2, Coeff3, Coeff4, Coeff5)
	end

	if Coeff5 then
		local QuarticShift = -Coeff2 / (4 * Coeff1)
		local DepressedB = (Coeff3 + QuarticShift * (3 * Coeff2 + 6 * Coeff1 * QuarticShift)) / Coeff1
		local DepressedC = (Coeff4 + QuarticShift * (2 * Coeff3 + QuarticShift * (3 * Coeff2 + 4 * Coeff1 * QuarticShift))) / Coeff1
		local DepressedD = (Coeff5 + QuarticShift * (Coeff4 + QuarticShift * (Coeff3 + QuarticShift * (Coeff2 + Coeff1 * QuarticShift)))) / Coeff1
		if DepressedC > -1e-10 and DepressedC < 1e-10 then
			local BiquadRoot1, BiquadRoot2 = SolvePolynomial(1, DepressedB, DepressedD)
			if BiquadRoot2 and not (BiquadRoot2 < 0) then
				local RootSqrt1 = math.sqrt(BiquadRoot1)
				local RootSqrt2 = math.sqrt(BiquadRoot2)
				return QuarticShift - RootSqrt2, QuarticShift - RootSqrt1, QuarticShift + RootSqrt1, QuarticShift + RootSqrt2
			end
			return
		end

		local Resolvent,_,CubicRoot = SolvePolynomial(1, 2 * DepressedB, DepressedB * DepressedB - 4 * DepressedD, -DepressedC * DepressedC)
		local Base = CubicRoot or Resolvent
		local ResolventRoot = math.sqrt(Base)
		local QuadraticA1, QuadraticA2 = SolvePolynomial(1, ResolventRoot, (Base + DepressedB - DepressedC / ResolventRoot) * 0.5)
		local QuadraticB1, QuadraticB2 = SolvePolynomial(1, -ResolventRoot, (Base + DepressedB + DepressedC / ResolventRoot) * 0.5)
		if QuadraticA1 and QuadraticB1 then
			return QuarticShift + QuadraticA1, QuarticShift + QuadraticA2, QuarticShift + QuadraticB1, QuarticShift + QuadraticB2
		end

		if QuadraticA1 then
			return QuarticShift + QuadraticA1, QuarticShift + QuadraticA2
		end

		if QuadraticB1 then
			return QuarticShift + QuadraticB1, QuarticShift + QuadraticB2
		end
	elseif Coeff4 then
		local CubicShift = -Coeff2 / (3 * Coeff1)
		local CubicP = -(Coeff3 + CubicShift * (2 * Coeff2 + 3 * Coeff1 * CubicShift)) / (3 * Coeff1)
		local CubicQ = -(Coeff4 + CubicShift * (Coeff3 + CubicShift * (Coeff2 + Coeff1 * CubicShift))) / (2 * Coeff1)
		local Discriminant = CubicQ * CubicQ - CubicP * CubicP * CubicP
		local AbsDisc = math.sqrt(math.abs(Discriminant))
		if not (Discriminant > 0) then
			local Angle = math.atan2(AbsDisc, CubicQ) / 3
			local Spread = math.sqrt(CubicP) * 2
			return CubicShift - Spread * math.sin(Angle + 0.5235987755982988), CubicShift + Spread * math.sin(Angle - 0.5235987755982988), CubicShift + Spread * math.cos(Angle)
		end

		local CubeTermA = CubicQ + AbsDisc
		local CubeTermB = CubicQ - AbsDisc
		local CubeRootA = CubeTermA < 0 and -(-CubeTermA) ^ 0.3333333333333333 or CubeTermA ^ 0.3333333333333333
		local CubeRootB
		if CubeTermB < 0 then
			CubeRootB = -(-CubeTermB) ^ 0.3333333333333333
			if CubeRootB then
				return CubicShift + CubeRootA + CubeRootB
			else
				CubeRootB = CubeTermB ^ 0.3333333333333333
				return CubicShift + CubeRootA + CubeRootB
			end
		else
			CubeRootB = CubeTermB ^ 0.3333333333333333
			return CubicShift + CubeRootA + CubeRootB
		end
	elseif Coeff3 then
		local Vertex = -Coeff2 / (2 * Coeff1)
		local Discriminant = Vertex * Vertex - Coeff3 / Coeff1
		if Discriminant < 0 then
			return
		end

		local Spread = math.sqrt(Discriminant)
		return Vertex - Spread, Vertex + Spread
	elseif Coeff2 then
		return -Coeff2 / Coeff1
	end
end

local function MinimumPositive(...)
	local Best = nil
	for Index = 1, select("#", ...) do
		local Value = select(Index, ...)
		if not (Value < 0 or Best and Best < Value) then
			Best = Value
		end
	end
	return Best
end

local BallisticsModule = {}

function BallisticsModule:Solve(Origin, Target, Speed, TargetVelocity, Gravity, BulletAccel)
	local Delta, RelativeVelocity, RelativeAcceleration = Target - Origin, TargetVelocity, Vector3.zero - Gravity
	local Time = MinimumPositive(SolvePolynomial(
		RelativeAcceleration:Dot(RelativeAcceleration) - BulletAccel * BulletAccel, 4 * (RelativeAcceleration:Dot(
			RelativeVelocity
		) - BulletAccel * Speed),4 * (RelativeAcceleration:Dot(Delta) + RelativeVelocity:Dot(
			RelativeVelocity) - Speed * Speed
		), 8 * Delta:Dot(RelativeVelocity), 4 * Delta:Dot(Delta)
	))

	if Time then
		return (Delta + Time * RelativeVelocity + Time * Time / 2 * RelativeAcceleration) / (Time * Speed + Time * Time / 2 * BulletAccel), Time
	end
end

local function GetTrajectory(Origin, Acceleration, Target, Speed, Velocity)
	local Weapon = GetActiveWeapon()
	local Direction = BallisticsModule:Solve(Origin, Target, Speed, Velocity or Vector3.zero, Acceleration, Weapon and Weapon:getWeaponStat("bulletaccel") or 0)
	if Direction then
		return Direction * Speed
	end
end

local function GetBulletVelocity(Origin, Target, Speed)
	local Gravity = -BulletAcceleration
	local Displacement = Target - Origin

	local AccelerationSquared = Gravity:Dot(Gravity)
	if AccelerationSquared <= 1e-12 then
		local Distance = Displacement.Magnitude
		if Distance <= 1e-6 then
			return
		end
		return Displacement / Distance * Speed, Distance / Speed
	end

	local MidTimeSquared = (2 * (Gravity:Dot(Displacement) + Speed * Speed)) / AccelerationSquared
	local Discriminant = MidTimeSquared * MidTimeSquared - (4 * Displacement:Dot(Displacement)) / AccelerationSquared
	if Discriminant < 0 then
		return
	end

	local Root = Discriminant ^ 0.5
	local TimeLow, TimeHigh = MidTimeSquared - Root, MidTimeSquared + Root
	local TimeSquared = TimeLow < 0 and TimeHigh or TimeLow
	if TimeSquared <= 0 then
		return
	end

	local Time = TimeSquared ^ 0.5
	return Gravity * Time * 0.5 + Displacement / Time, Time
end

local ViewportSize = Camera.ViewportSize
local ViewportSizeX, ViewportSizeY = ViewportSize.X, ViewportSize.Y
local ScreenXCenter, ScreenYCenter = ViewportSizeX * 0.5, ViewportSizeY * 0.5
local ScreenBottom, ScreenTop = Vector2.new(ScreenXCenter, ViewportSizeY), Vector2.new(ScreenXCenter, 0)
local ScreenCenter = Vector2.new(ScreenXCenter, ScreenYCenter)
local ScreenCenterX, ScreenCenterY = ScreenCenter.X, ScreenCenter.Y
local TwoPi, Quarter = math.pi * 2, math.pi * 0.5

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	ViewportSize = Camera.ViewportSize
	ViewportSizeX = ViewportSize.X
	ViewportSizeY = ViewportSize.Y
	ScreenXCenter = ViewportSizeX * 0.5
	ScreenYCenter = ViewportSizeY * 0.5
	ScreenBottom = Vector2.new(ScreenXCenter, ViewportSizeY)
	ScreenTop = Vector2.new(ScreenXCenter, 0)
	ScreenCenter = Vector2.new(ScreenXCenter, ScreenYCenter)
	ScreenCenterX, ScreenCenterY = ScreenCenter.X, ScreenCenter.Y
end)

local function WorldToViewportPoint(Position, KeepZ)
	local Screen, OnScreen = Camera:WorldToViewportPoint(Position)
	return Vector2.new(Screen.X, Screen.Y), OnScreen
end

local function GetFOVOrigin()
	if Aiming.Aimbot_FOVCircleFollowRecoil then
		local Weapon = GetActiveWeapon()
		local Barrel = Weapon and Weapon._barrelPart
		if Barrel then
			local Screen, OnScreen = WorldToViewportPoint(Barrel.CFrame * Vector3.new(0, 0, -100))
			if OnScreen then
				return Screen
			end
		end
	end
	return ScreenCenter
end

local TransparentRaycastExcluded = {}
local function TransparentRaycast(Origin, Direction)
	local Instances = AimingRaycastParams.FilterDescendantsInstances
	local Count = #Instances
	for Index = 1, Count do
		TransparentRaycastExcluded[Index] = Instances[Index]
	end

	local Excluded, OriginalDirection = Count, Direction
	for _ = 1, 8 do
		for Index = Excluded + 1, #TransparentRaycastExcluded do
			TransparentRaycastExcluded[Index] = nil
		end

		TransparentRaycastParams.FilterDescendantsInstances = TransparentRaycastExcluded
		local Result = workspace:Raycast(Origin, Direction, TransparentRaycastParams)
		if not Result then
			return
		end

		local Hit = Result.Instance
		if Hit.Transparency > 0.9 or Hit.Name == "Window" then
			Excluded += 1
			TransparentRaycastExcluded[Excluded] = Hit
			local Offset, Position = OriginalDirection.Unit * 0.01, Result.Position
			Direction = Direction - (Position - Origin) - Offset
			Origin = Position + Offset
			continue
		end

		return Result
	end
end

local GoldenAngle = math.pi * (3 - math.sqrt(5))
local MultiPointCache = {}
local function GetOffsets(Points)
	local CachedPoints = MultiPointCache[Points]
	if CachedPoints then
		return CachedPoints
	end

	local Step = 2 / Points
	local NewPoints = table.create(Points)
	for Index = 1, Points do
		local IndexOffset = Index - 1
		local Y = IndexOffset * Step - 1 + Step * 0.5
		local Radius, Angle = math.sqrt(math.max(0, 1 - Y * Y)), IndexOffset * GoldenAngle
		NewPoints[Index] = Vector3.new(math.cos(Angle) * Radius, Y, math.sin(Angle) * Radius)
	end

	MultiPointCache[Points] = NewPoints
	return NewPoints
end

local CanSeeFrameCounter = 0
local CanSeeCachePool = {}
local CanSeeCache = {}

local function GetCanSeeCache(Result, Layers)
	local Entry = table.remove(CanSeeCachePool)
	if Entry then
		Entry[1] = Result
		Entry[2] = CanSeeFrameCounter
		Entry[3] = Layers
		return Entry
	end
	return {Result, CanSeeFrameCounter, Layers}
end

local function CanSee(Part, UseCamera)
	local Layers, Entry = Settings.Advanced_MultiPointLayers, CanSeeCache[Part]
	if Entry and Entry[2] == CanSeeFrameCounter and Entry[3] == Layers then
		return Entry[1]
	end

	local Origin = UseCamera and Camera.CFrame.Position or GetLocalPosition()
	local Position = Part.Position
	local Delta = Position - Origin

	if not TransparentRaycast(Origin, Delta) then
		CanSeeCache[Part] = GetCanSeeCache(true, Layers)
		return true
	end

	if not Settings.Advanced_MultiPointEnabled then
		CanSeeCache[Part] = GetCanSeeCache(false, Layers)
		return
	end

	local PartCFrame = Part.CFrame
	local ObjectDelta = PartCFrame:VectorToObjectSpace(Origin - Position)
	local ObjectMagnitude = ObjectDelta.Magnitude

	if ObjectMagnitude <= 1e-6 then
		CanSeeCache[Part] = GetCanSeeCache(false, Layers)
		return
	end

	local ViewDirection = ObjectDelta * (1 / ObjectMagnitude)
	local ViewDirectionX, ViewDirectionY, ViewDirectionZ = ViewDirection.X, ViewDirection.Y, ViewDirection.Z

	local HalfSize = Part.Size * 0.5
	local HalfSizeX, HalfSizeY, HalfSizeZ = HalfSize.X, HalfSize.Y, HalfSize.Z
	local RightVector, UpVector, LookVector = PartCFrame.RightVector, PartCFrame.UpVector, PartCFrame.LookVector

	local Offsets = GetOffsets(Settings.Advanced_MultiPointScale)
	local Count = #Offsets

	local ActiveLayers = math.clamp(math.floor(1 + math.log(1 + 4 / math.max(Delta.Magnitude, 0.1))), 1, Layers)
	for Layer = ActiveLayers, 1, -1 do
		local LayerScale = Layer / ActiveLayers
		local LayerScaleX, LayerScaleY, LayerScaleZ = LayerScale * HalfSizeX, LayerScale * HalfSizeY, LayerScale * HalfSizeZ
		for Index = 1, Count do
			local Point  = Offsets[Index]
			local PointX, PointY, PointZ = Point.X, Point.Y, Point.Z

			if PointX * ViewDirectionX + PointY * ViewDirectionY + PointZ * ViewDirectionZ <= 0 then
				continue
			end

			if not TransparentRaycast(Origin, (Position + RightVector * (PointX * LayerScaleX) + UpVector * (
				PointY * LayerScaleY
			) + LookVector * (PointZ * LayerScaleZ)) - Origin) then
				CanSeeCache[Part] = GetCanSeeCache(true, Layers)
				return true
			end
		end
	end

	CanSeeCache[Part] = GetCanSeeCache(false, Layers)
end

local RaycastStep = 1/60
local RageBotModule = {NextShot = 0}

local HitScanSphereOffsets = {}
for Index = 0, 11 do
	local Height = 1 - (Index / 11) * 2
	local Ring = math.sqrt(math.max(0, 1 - Height * Height))
	local Theta = GoldenAngle * Index
	HitScanSphereOffsets[Index + 1] = Vector3.new(math.cos(Theta) * Ring, Height, math.sin(Theta) * Ring)
end

local CardinalAxes = {Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis}
local CornerSigns = {
	{-1, -1, -1, -Vector3.one.Unit}, {-1, -1, 1, Vector3.new(-1, -1, 1).Unit},
	{-1, 1, -1, Vector3.new(-1, 1, -1).Unit}, {-1, 1, 1, Vector3.new(-1, 1, 1).Unit},
	{1, -1, -1, Vector3.new(1, -1, -1).Unit}, {1, -1, 1, Vector3.new(1, -1, 1).Unit},
	{1, 1, -1, Vector3.new(1, 1, -1).Unit}, {1, 1, 1, Vector3.one.Unit},
}

function RageBotModule:GetHitPoints(Origin, Part)
	local Center = Part.Position
	local Points, Facing = {Center}, Origin - Center
	local Distance = Facing.Magnitude
	if Distance <= 1e-6 then
		return Points
	end

	local Mode = Aiming.RageBot_HitScanningMode
	Facing *= 1 / Distance

	if Mode == "Cardinal" then
		local Radius = Aiming.RageBot_HitScanningRadius
		for _,Axis in next, CardinalAxes do
			if Axis.X * Facing.X + Axis.Y * Facing.Y + Axis.Z * Facing.Z > -0.2 then
				Points[#Points + 1] = Center + Axis * Radius
			end
		end
	elseif Mode == "Sphere" then
		local Radius = Aiming.RageBot_HitScanningRadius
		for _,Offset in next, HitScanSphereOffsets do
			if Offset.X * Facing.X + Offset.Y * Facing.Y + Offset.Z * Facing.Z > -0.2 then
				Points[#Points + 1] = Center + Offset * Radius
			end
		end
	else
		local Radius, HalfSize = Aiming.RageBot_HitScanningRadius, Part.Size * 0.5
		for _,Sign in next, CornerSigns do
			local Corner = Vector3.new(Sign[1] * HalfSize.X, Sign[2] * HalfSize.Y, Sign[3] * HalfSize.Z)
			local Direction = Corner.Magnitude > 1e-6 and Corner.Unit or Facing
			if Direction.X * Facing.X + Direction.Y * Facing.Y + Direction.Z * Facing.Z > -0.2 then
				Points[#Points + 1] = Center + Corner + Direction * Radius * 0.5
			end
		end
	end
	return Points
end

local FireScanCount, FireScanOffsets = -1, nil
function RageBotModule:GetFireOrigins(Origin)
	local Origins = {Origin}
	if Aiming.RageBot_FireScanning then
		local Radius, Mode = Aiming.RageBot_FireScanningRadius, Aiming.RageBot_FireScanningMode
		if Mode == "Sphere" then
			local Count = Aiming.RageBot_FireScanningCount
			if FireScanCount ~= Count then
				local Offsets = {}
				for Index = 0, Count - 1 do
					local Height = Count == 1 and 0 or 1 - (Index / (Count - 1)) * 2
					local Ring = math.sqrt(math.max(0, 1 - Height * Height))
					local Theta = GoldenAngle * Index
					Offsets[Index + 1] = Vector3.new(math.cos(Theta) * Ring, Height, math.sin(Theta) * Ring)
				end
				FireScanCount, FireScanOffsets = Count, Offsets
			end

			for _,Offset in next, FireScanOffsets do
				Origins[#Origins + 1] = Origin + Offset * Radius
			end
		elseif Mode == "Corners" then
			for _,Sign in next, CornerSigns do
				Origins[#Origins + 1] = Origin + Sign[4] * Radius
			end
		else
			for _,Axis in next, CardinalAxes do
				Origins[#Origins + 1] = Origin + Axis * Radius
			end
		end
	end
	return Origins
end

function RageBotModule:SolveShot(Targets, Count, LocalPosition, BulletSpeed, Penetration, PenetrationDepth, Cache, Entry, CharacterHash)
	local Lifetime, Scans = BulletSpeed * BulletLifetime, 0
	local function Check(Origin, AimAt, Name, IsInstance, CountScans)
		if CountScans then
			if Scans >= 128 then
				return
			end
			Scans += 1
		end

		local Delta = AimAt - Origin
		if Delta.Magnitude > Lifetime then
			return
		end

		if Penetration then
			local BulletVelocity = GetBulletVelocity(Origin, AimAt, BulletSpeed)
			if not BulletVelocity then
				return
			end

			if not TransparentRaycast(Origin, Delta) or BulletCheck(Origin, AimAt, BulletVelocity, BulletAcceleration, PenetrationDepth, RaycastStep) then
				return Origin, AimAt, BulletVelocity, IsInstance and Name
			end
			return
		end

		if TransparentRaycast(Origin, Delta) then
			return
		end

		local BulletVelocity = GetBulletVelocity(Origin, AimAt, BulletSpeed)
		if not BulletVelocity then
			return
		end

		return Origin, AimAt, BulletVelocity, IsInstance and Name
	end

	local function Solve(Origins)
		for _,Origin in next, Origins do
			for Index = 1, Count do
				local Target = Targets[Index]
				local _Origin, _Target, Velocity, Name = Check(Origin, Target.IsInstance and Target.Part.Position or Target.Position, Target.Name, Target.IsInstance, false)
				if _Origin then
					return _Origin, _Target, Velocity, Name
				end
			end
		end

		if Aiming.RageBot_HitScanning then
			for _,Origin in next, Origins do
				for Index = 1, Count do
					local Target = Targets[Index]
					if Target.IsInstance then
						local Part = Target.Part
						local Cached = Cache and Cache[Part]
						local HitPoints = Cached and Cached.Origin == Origin and Cached.Points
						if not HitPoints then
							HitPoints = self:GetHitPoints(Origin, Part)
							if Cache then
								Cache[Part] = {Origin = Origin, Points = HitPoints}
							end
						end

						for _Index = 2, #HitPoints do
							local _Origin, _Target, Velocity, Name = Check(Origin, HitPoints[_Index], Target.Name, true, true)
							if _Origin then
								return _Origin, _Target, Velocity, Name
							end
						end
					end
				end
			end
		end

		if Aiming.RageBot_Backtrack and Entry then
			local Head, Torso = CharacterHash.Head, CharacterHash.Torso
			if Head or Torso then
				for _,Origin in next, Origins do
					local _Origin, Target, Velocity, Name = Check(Origin, Entry._receivedPosition, Torso and "Torso" or "Head", true, true)
					if _Origin then
						return _Origin, Target, Velocity, Name
					end
				end
			end

			local _Cache = MovementCache[Entry._player]
			if _Cache then
				local _Scans, Now = 0, os.clock()
				for Index = 2, #_Cache do
					if _Scans >= Aiming.RageBot_BacktrackScans then
						break
					end

					local Cached = _Cache[Index]
					if (Now - Cached.Time) * 1000 > Aiming.RageBot_BacktrackTime then
						break
					end

					for _Index = 1, Count do
						local Target = Targets[_Index]
						if not Target.IsInstance then
							continue
						end

						local Position = (Head and Target.Part == Head) and Cached.Head or Cached.Torso
						if not Position then
							continue
						end

						for _,Origin in next, Origins do
							local _Origin, _Target, Velocity, Name = Check(Origin, Position, Target.Name, true, true)
							if _Origin then
								return _Origin, _Target, Velocity, Name
							end
						end
					end
					_Scans += 1
				end
			end
		end
	end

	local Origin, Target, Velocity, Name = Solve({LocalPosition})
	if Origin then
		return Origin, Target, Velocity, Name
	end

	if not Aiming.RageBot_FireScanning then
		return
	end

	return Solve({table.unpack(self:GetFireOrigins(LocalPosition), 2)})
end

local RageTargetSlots = {}
for Index = 1, 6 do
	RageTargetSlots[Index] = {Name = "", IsInstance = true}
end
local RageFallbackSlot = {Name = "Head", IsInstance = false}

function RageBotModule:GetTargets(Entry, Targets)
	local CharacterHash = Entry._thirdPersonObject._characterModelHash
	local Head, Torso = CharacterHash.Head, CharacterHash.Torso
	local Target = Aiming.RageBot_Part

	local Count = 0
	local function Add(Part, Name)
		if Part then
			Count += 1
			local Slot = RageTargetSlots[Count]
			Slot.Part = Part
			Slot.Name = Name
			Targets[Count] = Slot
		end
	end

	if Target ~= "Best" then
		Add(Target == "Head" and Head or Torso, Target)
	else
		local LeftArm, RightArm = CharacterHash["Left Arm"], CharacterHash["Right Arm"]
		local LeftLeg, RightLeg = CharacterHash["Left Leg"], CharacterHash["Right Leg"]
		for _,Name in ipairs(BodyParts) do
			if Name == "Head" then
				Add(Head, "Head")
			elseif Name == "Torso" then
				Add(Torso, "Torso")
			else
				local Part1, Part2, Name1, Name2
				if Name == "Arms" then
					Part1, Part2, Name1, Name2 = LeftArm, RightArm, "Left Arm", "Right Arm"
				else
					Part1, Part2, Name1, Name2 = LeftLeg, RightLeg, "Left Leg", "Right Leg"
				end
				Add(Part1, Name1)
				Add(Part2, Name2)
			end
		end
	end

	if Count == 0 then
		Count = 1
		RageFallbackSlot.Position = Entry._receivedPosition
		Targets[1] = RageFallbackSlot
	end

	return Count
end

local function GetTargetPart(CharacterHash, AimbotPart, IgnoreWalls)
	local Head, Torso, LeftArm, RightArm, LeftLeg, RightLeg = CharacterHash.Head, CharacterHash.Torso, CharacterHash["Left Arm"], CharacterHash["Right Arm"], CharacterHash["Left Leg"], CharacterHash["Right Leg"]
	if AimbotPart == "Head" or AimbotPart == "Torso" then
		local Part = AimbotPart == "Head" and Head or Torso
		local Screen, OnScreen = WorldToViewportPoint(Part.Position)
		if not OnScreen then
			return
		end

		local Status = CanSee(Part)
		if IgnoreWalls or Status then
			return Part, Screen, Status
		end
	elseif AimbotPart == "Best" then
		for _,Name in ipairs(BodyParts) do
			if Name == "Head" then
				local Screen, OnScreen = WorldToViewportPoint(Head.Position)
				if OnScreen then
					local _CanSee = CanSee(Head)
					if IgnoreWalls or _CanSee then
						return Head, Screen, _CanSee
					end
				end
			elseif Name == "Torso" then
				local Screen, OnScreen = WorldToViewportPoint(Torso.Position)
				if OnScreen then
					local _CanSee = CanSee(Torso)
					if IgnoreWalls or _CanSee then
						return Torso, Screen, _CanSee
					end
				end
			else
				local IsArms = Name == "Arms"

				local Part1 = IsArms and LeftArm or LeftLeg
				local Screen, OnScreen = WorldToViewportPoint(Part1.Position)
				if OnScreen then
					local _CanSee = CanSee(Part1)
					if IgnoreWalls or _CanSee then
						return Part1, Screen, _CanSee
					end
				end

				local Part2 = IsArms and RightArm or RightLeg
				local _Screen, _OnScreen = WorldToViewportPoint(Part2.Position)
				if _OnScreen then
					local _CanSee = CanSee(Part2)
					if IgnoreWalls or _CanSee then
						return Part2, _Screen, _CanSee
					end
				end
			end
		end
	elseif AimbotPart == "Closest" then
		local BestPart, BestScreen, BestVisible, BestScore, Parts = nil, nil, false, math.huge, {Head, Torso, LeftArm, RightArm, LeftLeg, RightLeg}
		for Index = 1, 6 do
			local Part = Parts[Index]
			local Screen, OnScreen = WorldToViewportPoint(Part.Position)
			if not OnScreen then
				continue
			end

			local DeltaX, DeltaY = Screen.X - ScreenCenterX, Screen.Y - ScreenCenterY
			local Distance = DeltaX * DeltaX + DeltaY * DeltaY
			if Distance < BestScore then
				local _CanSee = CanSee(Part)
				if IgnoreWalls or _CanSee then
					BestScore, BestPart, BestScreen, BestVisible = Distance, Part, Screen, _CanSee
				end
			end
		end
		return BestPart, BestScreen, BestVisible
	end
end

local function ns__hookfunction(Table, Index, Replacement, Helper)
    local Original = Table[Index]
    Table[Index] = Helper and function(...)
		return Replacement(Helper, Original, ...)
	end or function(...)
		return Replacement(Original, ...)
	end
    return Original
end

local IsSpawned = CharacterInterface.isAlive()
local function GetLocalHumanoid()
	local Character = GetLocalCharacter()
	return Character and Character._humanoid
end

ns__hookfunction(FirearmObject, "computeWalkSway", function(Original, self, ...)
	return Miscellaneous.WeaponMods_NoWalkSway and Original(self, 0, 0) or Original(self, ...)
end)

ns__hookfunction(FirearmObject, "computeGunSway", function(Original, self, ...)
	return Miscellaneous.WeaponMods_NoWeaponSway and CFrame.identity or Original(self, ...)
end)

ns__hookfunction(FirearmObject, "getFiremode", function(Original, self, ...)
	return Miscellaneous.WeaponMods_AutomaticGun and true or Original(self, ...)
end)

ns__hookfunction(FirearmObject, "getWeaponStat", function(Original, self, Stat, ...)
	if (Stat == "unequiptime" or Stat == "equiptime") and Miscellaneous.WeaponMods_InstantEquipUnequip then
		return 0
	elseif (Stat == "unaimspeed" or Stat == "unmagnifyspeed") and Miscellaneous.WeaponMods_InstantAim then
		return 100
	elseif Stat == "variablechoke" or Stat == "spread" or Stat == "choke" or Stat == "aimchoke" or Stat == "hipchoke" then
		local Value = Miscellaneous.WeaponMods_SpreadAdjustment * 0.01
		if Value == 0 then
			return 0
		elseif Value < 1 then
			return (Original(self, Stat, ...) or 0) * Value
		end
	end
	return Original(self, Stat, ...)
end)

ns__hookfunction(FirearmObject, "getActiveAimStat", function(Original, self, Stat, ...)
	if (Stat == "aimspeed" or Stat == "unaimspeed" or Stat == "magnifyspeed") and Miscellaneous.WeaponMods_InstantAim then
		return 100
	elseif Stat == "swayamp" and Miscellaneous.WeaponMods_NoScopeSway then
		return 0
	end
	return Original(self, Stat, ...)
end)

ns__hookfunction(Module.__get("RecoilSprings"), "applyImpulse", function(Original, self, Offset, Scale, ...)
	local Value = Miscellaneous.WeaponMods_RecoilAdjustment * 0.01
	if Value == 0 then
		return
	elseif Value < 1 then
		return Original(self, Offset, (Scale or 1) * Value, ...)
	end

	return Original(self, Offset, Scale, ...)
end)

ns__hookfunction(CharacterObject, "preSimulationStep", function(Original, self, DeltaTime)
	Original(self, DeltaTime)

	if Miscellaneous.Movement_Speed then
		local Root = self._rootPart
		local Horizontal = Vector3.new(Root.Velocity.X, 0, Root.Velocity.Z)
		local Speed = Horizontal.Magnitude
		if Speed > 0.5 then
			Root.CFrame += Horizontal.Unit * (Miscellaneous.Movement_SpeedAmount - Speed) * DeltaTime
		end
	end

	if Miscellaneous.Movement_Fly then
		local CameraCFrame = Camera.CFrame
		local Direction = CameraCFrame.LookVector * ((UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (
			UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0
		)) + CameraCFrame.RightVector * ((UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (
			UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0
		))

		if Direction.Magnitude > 0 then
			Direction = Direction.Unit * Miscellaneous.Movement_FlySpeed
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			Direction += Vector3.new(0, Miscellaneous.Movement_FlySpeed, 0)
		end

		local Root = self._rootPart
		Root.Velocity = Direction
		Root.CFrame += Root.Velocity * DeltaTime
	end
end)

ns__hookfunction(FirearmObject, "reload", function(Original, self)
	if self:isEquipping() or self:isUnequipping() or self:isChambering() then
		return
	end

	if Miscellaneous.WeaponMods_InstantReload then
		NetworkClientSend(NetworkClient, "reload")
		self:applyReloadCount(self._weaponData.magsize)
		return self:fireInput("reloadFinish", GetGameClockTime())
	end

	return Original(self)
end)

local TicketCache = {}
local TicketAddition = 0

local SilentCache = {Frame = 0, Time = 0}
local SilentAimbotModule = {}

function SilentAimbotModule:GetClosest()
	local IsWallCheckOff = not Aiming.Aimbot_WallCheck
	local FOVRadius = Aiming.Aimbot_ShowFOVCircle and Aiming.Aimbot_FOVCircleRadius or math.huge
	local MaxScore, AimbotPart = math.huge, Aiming.Aimbot_Part
	local FOVOrigin = Aiming.Aimbot_ShowFOVCircle and GetFOVOrigin() or ScreenCenter
	local CenterX, CenterY, LocalHeadPosition = FOVOrigin.X, FOVOrigin.Y, GetLocalPosition()
	local BestPosition, BestEntry, BestPart

	for _,Entry in next, CachedPlayers do
		local CharacterModelHash = Entry._isEnemy and Entry._thirdPersonObject._characterModelHash
		if not CharacterModelHash then
			continue
		end

		local Part, Screen = GetTargetPart(CharacterModelHash, AimbotPart, IsWallCheckOff)
		if not Part or not Screen then
			continue
		end

		local DeltaX, DeltaY = Screen.X - CenterX, Screen.Y - CenterY
		local Distance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
		if Distance > FOVRadius then
			continue
		end

		local Position = Part.Position
		DeltaX, DeltaY = Position.X - LocalHeadPosition.X, Position.Y - LocalHeadPosition.Y
		local DeltaZ = Position.Z - LocalHeadPosition.Z
		local Score = Distance + math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ) * 0.15

		if Score < MaxScore then
			MaxScore = Score
			BestPosition = Position
			BestEntry = Entry
			BestPart = Part
		end
	end

	return BestPosition, BestEntry, BestPart
end

function SilentAimbotModule:Solve(Origin, Acceleration, Speed)
	if Aiming.Aimbot_HitChance < math.random(1, 100) then
		return
	end

	local Now = os.clock()
	local Target, Entry = self:GetClosest()
	if not Target or not Entry then
		return
	end

	local Cache = MovementCache[Entry._player]
	if not Cache then
		return
	end

	local Current, Old, Velocity = Cache[1], Cache[15], nil
	if Current and Old and (Current.Time - Old.Time) > 0.01 then
		Velocity = (Current.Head - Old.Head) / (Current.Time - Old.Time)
	end

	local Trajectory = GetTrajectory(Origin, Acceleration, Target, Speed, Velocity or Vector3.zero)
	if Trajectory then
		return Trajectory.Unit, Target, Entry, Now
	end
end

local AntiAimCycleFrames = 0
local SpinTime = os.clock()
local SpinWasOn = false
local function GetAntiAimAngles(Angles)
	local Pitch, Yaw, Roll = Angles.X, Angles.Y, Angles.Z
	local ClockTime = os.clock()
	AntiAimCycleFrames += 1

	if Miscellaneous.AntiAim_Pitch then
		local Mode = Miscellaneous.AntiAim_PitchMode
		if Mode == "Custom - Relative" then
			Pitch = math.clamp(Pitch + math.rad(Miscellaneous.AntiAim_PitchAmount), -Quarter, Quarter)
		elseif Mode == "Custom - Absolute" then
			Pitch = math.clamp(math.rad(Miscellaneous.AntiAim_PitchAmount), -2, 2)
		elseif Mode == "Rotate" then
			Pitch = math.sin(ClockTime * (Miscellaneous.AntiAim_PitchSpeed * 0.5)) * 2
		elseif Mode == "Random" then
			Pitch = math.random() * 4 - 2
		end
	end

	if Miscellaneous.AntiAim_Yaw then
		local Mode = Miscellaneous.AntiAim_YawMode
		if Mode == "Custom - Relative" then
			Yaw += math.rad(Miscellaneous.AntiAim_YawAmount)
		elseif Mode == "Custom - Absolute" then
			Yaw = math.rad(Miscellaneous.AntiAim_YawAmount)
		elseif Mode == "Backwards" then
			Yaw += math.pi
		elseif Mode == "Random" then
			Yaw = math.rad(math.random(-180, 180))
		elseif Mode == "Cycle" then
			local Speed = 76.5 - (Miscellaneous.AntiAim_YawSpeed * 1.5)
			Yaw = AntiAimCycleFrames % Speed >= (Speed * 0.5) and 2 or -2
		end
	end

	if Miscellaneous.AntiAim_Jitter then
		Yaw += (math.random() * 2 - 1) * math.rad(Miscellaneous.AntiAim_JitterAmount) * 0.25
	end

	if Miscellaneous.AntiAim_Spin then
		if not SpinWasOn then
			SpinWasOn = true
			SpinTime = os.clock()
		end
		Yaw += (os.clock() - SpinTime) * math.rad(Miscellaneous.AntiAim_SpinSpeed) * (Miscellaneous.AntiAim_SpinDirection == "Left" and 1 or -1)
	else
		SpinWasOn = false
	end

	return Vector3.new(Pitch, Yaw, Roll) * 0.99
end

local SphereHandleAdornment = ns__cloneref(Instance.new("SphereHandleAdornment"))
SphereHandleAdornment.Radius = 0.25
SphereHandleAdornment.ZIndex = 5
SphereHandleAdornment.AlwaysOnTop = true
SphereHandleAdornment.Adornee = Terrain
SphereHandleAdornment.Parent = CoreGui

local GrenadeModule = {Segments = {}, Marker = SphereHandleAdornment}
function GrenadeModule:GetVelocity(Target, Position)
	local Delta = Target - Position
	local Distance = Delta.Magnitude
	if Distance <= 1 then
		Delta, Distance = Camera.CFrame.LookVector * 5, 0.05
	else
		Distance *= 0.01
	end

	local Velocity = (Delta - Vector3.new(0, -40, 0) * Distance * Distance) / Distance
	if Velocity.Magnitude > 150 then
		return
	end

	return Velocity, Aiming.Aimbot_FuseAssist and Distance
end

function GrenadeModule:ImpactFuse(Position, Velocity)
	local Filter = {Map}
	for _,Entry in next, CachedPlayers do
		table.insert(Filter, Entry._thirdPersonObject._characterModel)
	end
	GrenadeImpactParams.FilterDescendantsInstances = Filter

	local Gravity = Vector3.new(0, -80, 0)
	local LastPosition, Traveled = Position, 0
	for Step = 1, 300 do
		local Elapsed = Step * RaycastStep
		local Next = Position + Velocity * Elapsed + 0.5 * Gravity * Elapsed * Elapsed
		local Hit = workspace:Raycast(LastPosition, Next - LastPosition, GrenadeImpactParams)
		Traveled += (Next - LastPosition).Magnitude
		if Hit and Hit.Instance.Name ~= "Window" and Hit.Instance.Name ~= "Col" and Traveled >= 3 then
			local SegmentLength = (Next - LastPosition).Magnitude
			return Elapsed - (SegmentLength > 0 and RaycastStep * (Next - Hit.Position).Magnitude / SegmentLength or 0)
		end
		LastPosition = Next
	end
end

ns__hookfunction(PlayerDataUtils, "getUnlocksData", function(Helper, Original, PlayerData)
	local Unlocks = Original(PlayerData)
	if Miscellaneous.ClientSessionUnlocks_AttachmentsUnlocked and PlayerData == Helper() then
		local OldUnlocks = Unlocks
		Unlocks = setmetatable({}, {
			__index = function(_,Index)
				local Unlock = OldUnlocks[Index] or {}
				Unlock.kills = 1000000000
				OldUnlocks[Index] = Unlock
				return Unlock
			end, __newindex = function(_,Index, Value)
				OldUnlocks[Index] = Value
				return
			end
		})
	end
	return Unlocks
end, PlayerDataClientInterface.getPlayerData)

ns__hookfunction(PlayerDataUtils, "ownsWeapon", function(Helper, Original, Player, WeaponName)
	if Miscellaneous.ClientSessionUnlocks_KnivesUnlocked then
		local Source = Helper(WeaponName)
		local Data = Source and Source.baseWeaponData
		if Data and Data.type == "KNIFE" then
			return true
		end
	end
	return Original(Player, WeaponName)
end, Module.__get("ContentInterface").getWeaponSource)

local BulletTracerModule = {Active = {}}
function BulletTracerModule:Render(StartPosition, Direction, Index)
	local Color = Visuals[Index .. "Color"]
	local Thickness = Visuals[Index .. "Thickness"]
	local Duration = Visuals[Index .. "Duration"]
	local Alpha = Visuals[Index .. "Alpha"]
	local Type = Visuals[Index .. "Type"]
	local FadeMode = Visuals[Index .. "FadeMode"]

	local Attachment0 = ns__cloneref(Instance.new("Attachment"))
	Attachment0.Parent = Terrain
	Attachment0.Position = StartPosition
	local Attachment1 = ns__cloneref(Instance.new("Attachment"))
	Attachment1.Parent = Terrain
	local RaycastResult = workspace:Raycast(StartPosition, Direction, BulletRaycastParams)
	Attachment1.Position = RaycastResult and RaycastResult.Position or (StartPosition + Direction)

	local Beam = ns__cloneref(Instance.new("Beam"))
	Beam.FaceCamera = true
	Beam.TextureMode = Enum.TextureMode.Wrap
	Beam.TextureLength = 30
	Beam.LightEmission = 1
	Beam.Parent = Terrain

	if Type == "Wavy Beam" then
		Beam.Texture = "rbxassetid://446111271"
	else
		Thickness *= 0.05
		Beam.Texture = ""
	end

	Beam.Width0 = Thickness
	Beam.Width1 = Thickness
	Beam.Color = ColorSequence.new(Color)
	Beam.Transparency = NumberSequence.new(1 - Alpha)
	Beam.Attachment0 = Attachment0
	Beam.Attachment1 = Attachment1

	table.insert(BulletTracerModule.Active, {
		StartTime = os.clock(),
		Duration = Duration,
		Beam = Beam,
		Attachment0 = Attachment0,
		Attachment1 = Attachment1,
		Thickness = Thickness,
		Alpha = Alpha,
		FadeMode = FadeMode,
	})
	return Beam
end

local EnemyBulletTracer = "Combat_EnemyBulletTracers"
local TeamBulletTracer = "Combat_TeamBulletTracers"

for _,Value in next, (getgc or get_gc)(true) do
	if type(Value) == "table" and rawget(Value, "correctposition") and rawget(Value, "newbullets") then
		local _correctposition = Value.correctposition
		Value.correctposition = function(Position, ...)
			local Humanoid = GetLocalHumanoid()
			if Humanoid and (
				Miscellaneous.Movement_Speed or Miscellaneous.Movement_Fly or Miscellaneous.Movement_BunnyHop
			) and Humanoid.FloorMaterial == Enum.Material.Air then
				local Hit = workspace:Raycast(GetLocalPosition(), Vector3.new(0, -1000, 0), GrenadeRaycastParams)
				if Hit then
					return _correctposition(Hit.Position + Vector3.new(0, 2, 0), ...)
				end
			end
			return _correctposition(Position, ...)
		end

		local _newbullets = Value.newbullets
		Value.newbullets = function(Data, ...)
			_newbullets(Data, ...)

			local Player = Data.player
			if Player == LocalPlayer then
				return
			end

			local Entry = CachedPlayers[Player]
			if not Entry then
				return
			end

			local IndexName = Entry._isEnemy and EnemyBulletTracer or TeamBulletTracer
			if not Visuals[IndexName] then
				return
			end

			local Origin, Bullets = Data.firepos, Data.bullets
			for Index = 1, #Bullets do
				BulletTracerModule:Render(Origin, Bullets[Index].velocity * 1000, string.sub(IndexName, 1, -2))
			end
		end

		break
	end
end

local CustomSounds = {
	["None"] = "", ["Osu"] = "rbxassetid://7172607676", ["MLG"] = "rbxassetid://109817519733426",
	["Bonk"] = "rbxassetid://5682262154", ["Rust"] = "rbxassetid://5043539486",
	["Metal"] = "rbxassetid://8917041751", ["Skeet"] = "rbxassetid://83717596220569", ["Quack"] = "rbxassetid://6435400690",
	["Katana"] = "rbxassetid://7122613461", ["Neverlose"] = "rbxassetid://18391691942", ["Undertale"] = "rbxassetid://1471213022",
	["Jet Set Radio"] = "rbxassetid://97113622160405", ["TF2 Critical"] = "rbxassetid://8255306220",
	["TF2 Frying Pan"] = "rbxassetid://18922477538", ["TF2 Alternative"] = "rbxassetid://2868331684"
}

pcall(function()
	local Assets = {"rbxassetid://446111271"}
	for _,AssetId in next, CustomSounds do
		if AssetId ~= "" then
			Assets[#Assets + 1] = AssetId
		end
	end
	local ContentProvider = ns__cloneref(game:GetService("ContentProvider"))
	task.spawn(ContentProvider.PreloadAsync, ContentProvider, Assets)
end)

local PlaySoundId = AudioSystem.playSoundId
AudioSystem.playSoundId = function(AssetId, Priority, Volume, ...)
	local ShootSound = Miscellaneous.SoundOverride_ShootSound
	if ShootSound == "None" then
		return PlaySoundId(AssetId, Priority, Volume, ...)
	end

	local ActiveWeapon = GetActiveWeapon()
	if ActiveWeapon and AssetId == ActiveWeapon._weaponData.firesoundid then
		return PlaySoundId(CustomSounds[ShootSound], Priority, Volume)
	end

	return PlaySoundId(AssetId, Priority, Volume, ...)
end

local function PlayTween(Tween)
	Tween:Play()
	return Tween
end

local ESPModule = {Highlights = {}, Grenades = {}, SoundRings = {}}
ns__hookfunction(AudioSystem, "playSound", function(Original, Name, ...)
	if Miscellaneous.SoundOverride_HitSound ~= "None" and Name == "hitmarker" then
		PlaySoundId(CustomSounds[Miscellaneous.SoundOverride_HitSound], 1, select(3, ...))
	elseif Miscellaneous.SoundOverride_KillSound ~= "None" and (Name == "killshot" or Name == "headshotkill") then
		PlaySoundId(CustomSounds[Miscellaneous.SoundOverride_KillSound], 1, select(3, ...))
	else
		Original(Name, ...)
	end

	local RootPart = Visuals.ESPVisuals_SoundRings and select(7, ...)
	if not RootPart then
		return
	end

	for Player, Entry in next, CachedPlayers do
		if Entry._isEnemy and Entry._thirdPersonObject._rootPart == RootPart then
			local SoundRings = ESPModule.SoundRings[Player]
			if not SoundRings then
				SoundRings = {}
				ESPModule.SoundRings[Player] = SoundRings
			end

			local CylinderHandleAdornment = ns__cloneref(Instance.new("CylinderHandleAdornment"))
			CylinderHandleAdornment.Adornee = Terrain
			CylinderHandleAdornment.Parent = Terrain
			CylinderHandleAdornment.AlwaysOnTop = Visuals.ESPVisuals_SoundRingsThroughWalls
			CylinderHandleAdornment.ZIndex = 1
			CylinderHandleAdornment.Height = 0.03
			CylinderHandleAdornment.AdornCullingMode = Enum.AdornCullingMode.Never
			CylinderHandleAdornment.CFrame = CFrame.new(RootPart.Position - Vector3.new(0, 2, 0)) * CFrame.Angles(Quarter, 0, 0)
			CylinderHandleAdornment.InnerRadius = 2
			CylinderHandleAdornment.Radius = 1.93
			CylinderHandleAdornment.Color3 = Visuals.ESPVisuals_SoundRingsColor
			CylinderHandleAdornment.Transparency = 0
			CylinderHandleAdornment.Visible = true
			SoundRings[#SoundRings + 1] = CylinderHandleAdornment

			local Duration = Visuals.ESPVisuals_SoundRingsDuration
			TweenService:Create(CylinderHandleAdornment, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {InnerRadius = 6, Radius = 5.93}):Play()
			task.delay(Duration - 0.2, function()
				PlayTween(TweenService:Create(CylinderHandleAdornment, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Transparency = 1})).Completed:Wait()
				for Index, Item in next, SoundRings do
					if Item == CylinderHandleAdornment then
						table.remove(SoundRings, Index)
						break
					end
				end
				CylinderHandleAdornment:Destroy()
			end)

			break
		end
	end
end)

ns__hookfunction(Module.__get("BulletObject"), "new", function(Original, BulletData, ...)
	if not BulletData.onplayerhit then
		return Original(BulletData)
	end

	if Aiming.Aimbot_Enabled and Aiming.Aimbot_Type == "Silent" then
		local Speed = BulletData.velocity.Magnitude
		local Direction, Target, Entry, Time = SilentAimbotModule:Solve(BulletData.position, BulletData.acceleration, Speed)
		if Direction and Target and Entry then
			local Velocity = Direction * Speed
			BulletData.velocity = Velocity
			SilentCache.Target = Target
			SilentCache.Velocity = Velocity
			SilentCache.Frame = Time
			SilentCache.Player = Entry._player
			SilentCache.Entry = Entry
			SilentCache.Time = Time
		end
	end

	local Bullet = Original(BulletData)
	if BulletData.extra and Visuals.Combat_LocalBulletTracers then
		BulletTracerModule:Render(BulletData.position, BulletData.velocity.Unit * 1000, "Combat_LocalBulletTracer")
		for _,Object in next, Bullet._beamObject.beams do
			Object.Enabled = false
		end
	end
	return Bullet
end)

ns__hookfunction(GrenadeObject, "getWeaponStat", function(Original, self, Stat, ...)
	if (Stat == "unequiptime" or Stat == "equiptime") and Miscellaneous.WeaponMods_InstantEquipUnequip then
		return 0
	elseif Stat == "uncookable" and Miscellaneous.WeaponMods_UncookableGrenade then
		return true
	end
	return Original(self, Stat, ...)
end)

ns__hookfunction(MeleeObject, "getWeaponStat", function(Original, self, Stat, ...)
	if (Stat == "unequiptime" or Stat == "equiptime") and Miscellaneous.WeaponMods_InstantEquipUnequip then
		return 0
	end
	return Original(self, Stat, ...)
end)

ns__hookfunction(Module.__get("MainCameraObject"), "step", function(Original, self, DeltaTime, ...)
	local LocalCharacter, Speed
	if Visuals.Camera_NoBob then
		LocalCharacter = GetLocalCharacter()
		if LocalCharacter then
			Speed = LocalCharacter._speed
			LocalCharacter._speed = 0
		end
	end

	Original(self, DeltaTime, ...)

	if LocalCharacter and Speed then
		LocalCharacter._speed = Speed
	end

	if Visuals.Camera_NoSuppression then
		self._suppressionSpring.p = Vector3.zero
	end
end)

ns__hookfunction(MeleeObject, "meleeSway", function(Original, self, ...)
	if Miscellaneous.WeaponMods_NoWeaponSway then
		return CFrame.identity
	end
	return Original(self, ...)
end)

ns__hookfunction(GrenadeObject, "modelSway", function(Original, self, ...)
	if Miscellaneous.WeaponMods_NoWeaponSway then
		return CFrame.identity
	end
	return Original(self, ...)
end)

local FlashlightPart = ns__cloneref(Instance.new("Part"))
FlashlightPart.Anchored = true
FlashlightPart.CanCollide = false
FlashlightPart.CanQuery = false
FlashlightPart.CanTouch = false
FlashlightPart.Transparency = 1
FlashlightPart.Size = Vector3.new(0.1, 0.1, 0.1)
FlashlightPart.Parent = workspace

local SpotLight = ns__cloneref(Instance.new("SpotLight"))
SpotLight.Brightness = 4
SpotLight.Range = 60
SpotLight.Angle = 70
SpotLight.Color = Color3.fromRGB(255, 255, 255)
SpotLight.Shadows = true
SpotLight.Parent = FlashlightPart

ns__hookfunction(Module.__get("ScreenCull"), "step", function(Original, ...)
	Original(...)

	local UseOffset
	if Visuals.Camera_ThirdPerson then
		local CameraOffset = Vector3.new(Visuals.Camera_ThirdPersonOffsetX, Visuals.Camera_ThirdPersonOffsetY, Visuals.Camera_ThirdPersonOffsetZ)
		local Collided = false

		if Visuals.Camera_ThirdPersonCameraCollision and CameraOffset.Magnitude > 0 then
			local OriginalPosition = Camera.CFrame.Position
			local Raycast = workspace:Raycast(OriginalPosition, (Camera.CFrame * CFrame.new(CameraOffset)).Position - OriginalPosition, AimingRaycastParams)
			if Raycast then
				Camera.CFrame *= CFrame.new(CameraOffset * ((Raycast.Position - OriginalPosition).Magnitude / CameraOffset.Magnitude) * 0.99)
				Collided = true
			end
		end

		if not Collided then
			Camera.CFrame *= CFrame.new(CameraOffset)
		end

		UseOffset = true
	end

	local FOVValue
	if Visuals.Camera_CustomFOV then
		local ApplyToAim = Visuals.Camera_ApplyToAim
		if not ApplyToAim then
			local ActiveWeapon = GetActiveWeapon()
			ApplyToAim = not (ActiveWeapon and ActiveWeapon._aiming)
		end

		if ApplyToAim then
			Camera.FieldOfView = Visuals.Camera_FOVValue
			FOVValue = Visuals.Camera_FOVValue
		end
	end

	if UseOffset and not FOVValue then
		FOVValue = Camera.FieldOfView
	end

	if FOVValue then
		Original(Camera.CFrame, Camera.ViewportSize, FOVValue)
	end
end)

local function OnDeadBody(Child)
	if not Visuals.Combat_CustomRagdolls then
		return
	end

	local Torso = (not Child:GetAttribute("ns__CustomRagdoll")) and (Child:FindFirstChild("Torso") or Child:FindFirstChildWhichIsA("BasePart"))
	if not Torso then
		return
	end

	if Visuals.Combat_RagdollEffect == "Launch" then
		Torso.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), Visuals.Combat_RagdollEffectLaunchForce, math.random(-15, 15))
	elseif Visuals.Combat_RagdollEffect == "Fling" then
		local Force = Visuals.Combat_RagdollEffectFlingForce
		Torso.AssemblyLinearVelocity, Torso.AssemblyAngularVelocity = Vector3.new(math.random(-Force, Force), math.random(0, Force), math.random(
			-Force, Force
		)), Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))
	else
		Torso.AssemblyLinearVelocity = Vector3.new(0, Visuals.Combat_RagdollEffectFloatSpeed, 0)
		for _,Object in next, Child:GetChildren() do
			if Object:IsA("BasePart") and not Object:FindFirstChildOfClass("BodyForce") then
				local BodyForce = ns__cloneref(Instance.new("BodyForce"))
				BodyForce.Force, BodyForce.Parent = Vector3.new(0, Object:GetMass() * workspace.Gravity, 0), Object
			end
		end
	end

	if Visuals.Combat_RagdollGhost then
		local Color = Visuals.Combat_RagdollGhostColor
		local HiddenParts = {}
		for _,Object in ipairs(Child:GetDescendants()) do
			if Object:IsA("BasePart") then
				Object.Color = Color
				Object.Material = Enum.Material.ForceField
				Object.Transparency = 0
				if Object:IsA("MeshPart") then
					Object.TextureID = ""
				end
			elseif Object:IsA("SpecialMesh") then
				if Object.MeshId == "rbxassetid://4049240078" then
					HiddenParts[Object.Parent] = true
				else
					if Object.MeshId == "rbxassetid://6179256256" then
						Object.TextureId = "rbxassetid://12325350352"
					end
					Object.VertexColor = Vector3.new(Color.R, Color.G, Color.B)
				end
			elseif Object:IsA("Texture") or Object:IsA("Decal") then
				Object.Transparency = 1
			end
		end
		for Part in next, HiddenParts do
			if Part and Part.Parent then
				Part.Transparency = 1
			end
		end
	end

	Child:SetAttribute("ns__CustomRagdoll", true)
end

DeadBodyFolder.ChildAdded:Connect(OnDeadBody)

local function RotatePoint(Angle, Point, Center)
	local CosineAngle, SineAngle = math.cos(Angle), math.sin(Angle)
	local Offset = Point - Center
	local OffsetX, OffsetY = Offset.X, Offset.Y
	return Vector2.new(
		Center.X + (OffsetX * CosineAngle - OffsetY * SineAngle),
		Center.Y + (OffsetX * SineAngle + OffsetY * CosineAngle)
	)
end

local IsGameCrosshairHidden, WasSpawned = false, false
local SpinAngle = 0
local CrosshairDirections = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
local ImDrawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/src/libs/ImDrawing.luau"))()

local function UpdateCrosshair(DeltaTime)
	if IsSpawned and not WasSpawned then
		IsGameCrosshairHidden = false
	end

	WasSpawned = IsSpawned
	local Hide = Visuals.Combat_CustomCrosshair and IsSpawned
	if Hide ~= IsGameCrosshairHidden then
		IsGameCrosshairHidden = Hide
		if Hide then
			HudCrosshairsInterface.disable()
		else
			HudCrosshairsInterface.enable()
		end
	end

	local ActiveWeapon = GetActiveWeapon()
	if not (Visuals.Combat_CustomCrosshair and IsSpawned) or (ActiveWeapon and ActiveWeapon._aiming) then
		return
	end

	local Center = ScreenCenter
	if Visuals.Combat_CustomCrosshairFollowRecoil then
		if ActiveWeapon then
			local Barrel = ActiveWeapon._barrelPart
			if Barrel then
				local Screen, OnScreen = WorldToViewportPoint(Barrel.CFrame * Vector3.new(0, 0, -100))
				if OnScreen then
					Center = Screen
				end
			end
		end
	end

	local Gap = Visuals.Combat_CustomCrosshairGap
	if Visuals.Combat_CustomCrosshairFollowSpread then
		Gap += HudCrosshairsInterface.getCrossSize()
	end

	if Visuals.Combat_CustomCrosshairSpin then
		SpinAngle = (SpinAngle + DeltaTime * Visuals.Combat_CustomCrosshairSpinSpeed) % TwoPi
	end

	local Size, Thickness, Color = Visuals.Combat_CustomCrosshairSize, Visuals.Combat_CustomCrosshairThickness, Visuals.Combat_CustomCrosshairColor
	local Angle = Visuals.Combat_CustomCrosshairSpin and SpinAngle or 0
	local Cosine, Sine = math.cos(Angle), math.sin(Angle)
	for Index = 1, 4 do
		local Direction, Offset = CrosshairDirections[Index], Gap + Size
		local Direction1, Direction2 = Direction[1], Direction[2]
		local AimDirection = Vector2.new(Direction1 * Cosine - Direction2 * Sine, Direction1 * Sine + Direction2 * Cosine)
		ImDrawing.Line(Center + AimDirection * Gap, Center + AimDirection * Offset, Color, Thickness, 1)
	end
end

function ESPModule:Clear(Player)
	local Highlight = self.Highlights[Player]
	if Highlight then
		Highlight:Destroy()
		self.Highlights[Player] = nil
	end

	if self.SoundRings[Player] then
		self.SoundRings[Player] = nil
	end
end

local ViewModelModule = {Cache = setmetatable({}, {__mode = "k"}), Parts = setmetatable({}, {__mode = "k"}), Sleeves = setmetatable({}, {__mode = "k"})}

function ViewModelModule:Apply(Model, Part)
	if Part.Name == "Sleeves" then
		self.Sleeves[Part] = true
	end

	if Part:IsA("BasePart") then
		table.insert(self.Parts[Model], Part)
		self:RefreshPart(Model, Part)
	end

	if Part.Name == "Arm" then
		for _,Child in ipairs(self.Parts[Model]) do
			self:RefreshPart(Model, Child)
		end
	end
end

function ViewModelModule:RefreshPart(Model, Part)
	local NoSleeves = Visuals.ViewModel_NoSleeves
	local IsSleeve = self.Sleeves[Part]
	Part.LocalTransparencyModifier = (NoSleeves and IsSleeve) and 1 or 0
	if IsSleeve then
		for _,Child in ipairs(Part:GetChildren()) do
			Child.Transparency = NoSleeves and 1 or 0
		end
	end

	local Arm = Model:FindFirstChild("Arm")
	local IsArm = Arm ~= nil
	local Enabled, Color, Material, Translucent
	if IsArm then
		Enabled = Visuals.ViewModel_ArmChams
		Color = Visuals.ViewModel_ArmChamColor
		Material = Visuals.ViewModel_ArmChamType
		Translucent = Visuals.ViewModel_ArmChamTranslucent
	else
		Enabled = Visuals.ViewModel_WeaponChams
		Color = Visuals.ViewModel_WeaponChamColor
		Material = Visuals.ViewModel_WeaponChamType
		Translucent = Visuals.ViewModel_WeaponChamTranslucent
	end
	if not IsArm and (Part.Name == "Handle" or Part.Name == "Flame") and Material == "ForceField" then
		Part.Transparency = 1
	elseif Enabled and not self.Sleeves[Part] and Part.Name ~= "Trigger" and Part.ClassName ~= "Part" then
		local Cache, IsUnionOperation = self.Cache, Part:IsA("UnionOperation")
		if not Cache[Part] then
			Cache[Part] = {
				Material = Part.Material.Name, Transparency = Part.Transparency, Color = Part.Color, UsePartColor = IsUnionOperation and Part.UsePartColor
			}
		end
		if IsUnionOperation then
			Part.UsePartColor = true
		end
		Part.Material = Enum.Material[Material]
		Part.Color = Color
		Part.Transparency = (Material ~= "ForceField" and Translucent) and 0.65 or 0
	else
		local Cache = self.Cache
		local Cached = Cache[Part]
		if Cached then
			Part.Material = Enum.Material[Cached.Material]
			Part.Transparency = Cached.Transparency
			Part.Color = Cached.Color
			if Cached.UsePartColor and Part:IsA("UnionOperation") then
				Part.UsePartColor = Cached.UsePartColor
			end
			Cache[Part] = nil
		elseif not IsSleeve and (Part.Name == "Handle" or Part.Name == "Flame") then
			Part.Transparency = 0
		end
	end
end

function ViewModelModule:OnCameraChildAdded(Model)
	if not Model:IsA("Model") then
		return
	end

	self.Parts[Model] = {}

	for _,Part in ipairs(Model:QueryDescendants("BasePart, #Sleeves")) do
		self:Apply(Model, Part)
	end

	Model.DescendantAdded:Connect(function(Part)
		self:Apply(Model, Part)
	end)

	Model.Destroying:Once(function()
		self.Parts[Model] = nil
	end)
end


local FakeReplicationObject
task.spawn(function()
	FakeReplicationObject = Module.__get("ReplicationObject").new(setmetatable({}, {
		__index = function(_,Index)
			if Index == "GetPropertyChangedSignal" then
				return function(_,Property)
					return LocalPlayer:GetPropertyChangedSignal(Property)
				end
			end
			return LocalPlayer[Index]
		end, __newindex = function(_,Index, Value)
			LocalPlayer[Index] = Value
		end
	}))
end)

local KnifeAuraModule = {NextHit = 0}
function KnifeAuraModule:Update()
	local Weapon = GetActiveWeapon()
	if not (Weapon and Weapon:getWeaponType() == "Melee") then
		return
	end

	local Now = os.clock()
	if Now >= self.NextHit then
		local Origin, SelectedPart = GetLocalPosition(), Miscellaneous.KnifeAura_Part
		local Name = SelectedPart == "Random" and (math.random(2) == 1 and "Head" or "Torso") or SelectedPart
		local Range = Miscellaneous.KnifeAura_Range
		local Targets = {}

		for Player, Entry in next, CachedPlayers do
			if not Entry._isEnemy then
				continue
			end

			local Part = Entry._thirdPersonObject._characterModelHash[Name]
			local Position = Part.Position
			if (Position - Origin).Magnitude >= Range then
				continue
			end

			if Miscellaneous.KnifeAura_Wallbang or not TransparentRaycast(Origin, Position - Origin) then
				table.insert(Targets, {Player, Part})
			end
		end

		if #Targets > 0 then
			self.NextHit = Now + Miscellaneous.KnifeAura_Delay
			NetworkClientSend(NetworkClient, "stab")
			for _,Hit in next, Targets do
				NetworkClientSend(NetworkClient, "knifehit", Hit[1], Name, Hit[2].Position, NetworkClient.getTime())
			end
		end
	end
end

local ESPSkeletonBones, ESPBoxSegments, ESPEdges = {{1, 2}, {1, 3}, {1, 4}, {4, 10}, {1, 5}, {5, 11}, {3, 6}, {6, 8}, {3, 7}, {7, 9}}, {
	{0, 0, 1, 0}, {0, 0, 0, 1}, {1, 0, -1, 0}, {1, 0, 0, 1}, {0, 1, 0, -1}, {0, 1, 1, 0}, {1, 1, -1, 0}, {1, 1, 0, -1}
}, {{1, 2}, {1, 3}, {2, 4}, {3, 4}, {5, 6}, {5, 7}, {6, 8}, {7, 8}, {1, 5}, {2, 6}, {3, 7}, {4, 8}}
local ESPCornerCache, ESPDepthCache, ESPBoundsCache = table.create(8), table.create(8), table.create(5)
local ESPJointCache, ESPScreenCache = table.create(11), table.create(11)

local function GetWeldPosition(Weld)
	return (Weld.part0.CFrame * Weld.C0).Position
end

local function CacheBounds(Position)
	local Screen = WorldToViewportPoint(Position)
	local X, Y = Screen.X, Screen.Y

	if X < ESPBoundsCache.MinX then
		ESPBoundsCache.MinX = X
	end

	if Y < ESPBoundsCache.MinY then
		ESPBoundsCache.MinY = Y
	end

	if X > ESPBoundsCache.MaxX then
		ESPBoundsCache.MaxX = X
	end

	if Y > ESPBoundsCache.MaxY then
		ESPBoundsCache.MaxY = Y
	end

	ESPBoundsCache.HasBounds = true
end

local function CacheEdgeBounds()
	for _,Edge in ipairs(ESPEdges) do
		local A, B = Edge[1], Edge[2]
		local DepthA, DepthB = ESPDepthCache[A], ESPDepthCache[B]
		if (DepthA < 0.5) ~= (DepthB < 0.5) then
			CacheBounds(ESPCornerCache[A]:Lerp(ESPCornerCache[B], (0.5 - DepthA) / (DepthB - DepthA)))
		end
	end
end

local function CachePartBounds(Part, YSize, CameraCFrame)
	local PartCFrame, Count = Part.CFrame, 0
	for X = -1, 1, 2 do
		for Y = -YSize, YSize, YSize * 2 do
			for Z = -0.5, 0.5, 1 do
				Count += 1

				local Position = PartCFrame * Vector3.new(X, Y, Z)
				local Depth = -CameraCFrame:PointToObjectSpace(Position).Z

				ESPCornerCache[Count] = Position
				ESPDepthCache[Count] = Depth

				if Depth >= 0.5 then
					CacheBounds(Position)
				end
			end
		end
	end
	CacheEdgeBounds()
end

local function CachePartBounds2(Part, CameraCFrame)
	local PartCFrame, Count = Part.CFrame, 0
	for X = -0.5, 0.5, 1 do
		for Y = -1, 1, 2 do
			for Z = -0.5, 0.5, 1 do
				Count += 1

				local Position = PartCFrame * Vector3.new(X, Y, Z)
				local Depth = -CameraCFrame:PointToObjectSpace(Position).Z

				ESPCornerCache[Count] = Position
				ESPDepthCache[Count] = Depth

				if Depth >= 0.5 then
					CacheBounds(Position)
				end
			end
		end
	end
	CacheEdgeBounds()
end

function ESPModule:Update(LocalHeadPosition)
    local GlobalOpacity = Visuals.ESPVisuals_MasterOpacity * 0.01
    local MaxDistance = Visuals.ESPVisuals_MaxDistance
	MaxDistance *= MaxDistance

    local Boxes = Visuals.ESPVisuals_Boxes
    local HeadTags = Visuals.ESPVisuals_HeadTags
    local Healthbars = Visuals.ESPVisuals_Healthbars
    local Skeletons = Visuals.ESPVisuals_Skeletons
    local Tracers = Visuals.ESPVisuals_Tracers
    local OffscreenArrows = Visuals.ESPVisuals_OffscreenArrows
    local Chams = Visuals.ESPVisuals_Chams
    local NeedsScreenBounds = Boxes or HeadTags or Healthbars
    local NeedsHeadScreen = NeedsScreenBounds or Skeletons or Tracers or OffscreenArrows
    if not Chams then
		local Highlights = self.Highlights
        for Player in next, Highlights do
			local Highlight = Highlights[Player]
			if Highlight then
				Highlight:Destroy()
			end
			Highlights[Player] = nil
        end
    end

	if not NeedsHeadScreen and not Chams then
		return
	end

	local ChamRendering = Visuals.ESPVisuals_ChamRendering
    for Player, Entry in next, CachedPlayers do
        if not Entry._isEnemy then
            self:Clear(Player)
            continue
        end

        local ThirdPersonObject = Entry._thirdPersonObject
        local CharacterHash = ThirdPersonObject._characterModelHash
        local Head = CharacterHash.Head
        local HeadPosition = Head.Position
        local Distance = HeadPosition - LocalHeadPosition
		Distance = Distance:Dot(Distance)
        if Distance > MaxDistance then
            self:Clear(Player)
            continue
        end

		local CharacterModel, Torso, LeftArm, RightArm, LeftLeg, RightLeg, CameraCFrame  = ThirdPersonObject._characterModel, CharacterHash.Torso, CharacterHash[
			"Left Arm"
		], CharacterHash["Right Arm"], CharacterHash["Left Leg"], CharacterHash["Right Leg"], Camera.CFrame

        if Chams and (ChamRendering.Fill or ChamRendering.Outline) then
            local ChamsColor = (Visuals.ESPVisuals_ChamStyle == "Visible" and (CanSee(Head, true) or CanSee(Torso, true) or CanSee(LeftArm, true) or CanSee(
				RightArm, true
			) or CanSee(LeftLeg, true) or CanSee(RightLeg, true))) and Visuals.ESPVisuals_ChamVisibleColor or Visuals.ESPVisuals_ChamColor

            local Highlight = self.Highlights[Player]
            if not Highlight then
                Highlight = ns__cloneref(Instance.new("Highlight"))
                Highlight.Parent = CoreGui
                self.Highlights[Player] = Highlight
            end

            local Opacity = 1 - GlobalOpacity
            Highlight.Adornee = CharacterModel
            Highlight.DepthMode = Visuals.ESPVisuals_ChamOccluded and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
            Highlight.Enabled = true
            Highlight.FillColor = ChamsColor
            Highlight.OutlineColor = ColorCache[ChamsColor]
            Highlight.FillTransparency = ChamRendering.Fill and Opacity or 1
            Highlight.OutlineTransparency = ChamRendering.Outline and Opacity or 1
        else
			local Highlight = self.Highlights[Player]
			if Highlight then
				Highlight:Destroy()
			end
			self.Highlights[Player] = nil
        end

        if NeedsHeadScreen then
            local _,HeadOnScreen = WorldToViewportPoint(HeadPosition)
            if not HeadOnScreen then
                if OffscreenArrows then
					local Relative = CameraCFrame:PointToObjectSpace(HeadPosition)
					local RelativeZ, Direction = Relative.Z, Vector2.new(Relative.X, -Relative.Y)

					if RelativeZ > 0 then
						Direction = -Direction
					end

					local Magnitude = Direction.Magnitude
					if Magnitude < 0.001 then
						Direction = Vector2.new(0, RelativeZ > 0 and 1 or -1)
					else
						Direction /= Magnitude
					end

					local Half = math.min(ScreenXCenter, ScreenYCenter)
					local Size = math.min(Visuals.ESPVisuals_OffscreenArrowSize, Half / 1.5)
					local Center = ScreenCenter + Direction * math.clamp(Visuals.ESPVisuals_OffscreenArrowRadius, 0, Half - Size * 1.2)
					local Back = Center - Direction * (Size * 0.5)
					local Side = Vector2.new(-Direction.Y, Direction.X) * (Size * 0.6)
					ImDrawing.Triangle(Visuals.ESPVisuals_OffscreenArrowFilled, Center + Direction * Size, Back + Side, Back - Side, Visuals.ESPVisuals_OffscreenArrowColor, 1, GlobalOpacity)
                end

                if not NeedsScreenBounds then
                    continue
                end
            end
        end

        if NeedsScreenBounds then
            local BoxLeft, BoxTop, BoxRight, BoxBottom
            ESPBoundsCache.MinX, ESPBoundsCache.MinY = math.huge, math.huge
            ESPBoundsCache.MaxX, ESPBoundsCache.MaxY = -math.huge, -math.huge
            ESPBoundsCache.HasBounds = false

			CachePartBounds(Head, 0.5, CameraCFrame)
			CachePartBounds(Torso, 1, CameraCFrame)
			CachePartBounds2(LeftArm, CameraCFrame)
			CachePartBounds2(RightArm, CameraCFrame)
			CachePartBounds2(LeftLeg, CameraCFrame)
			CachePartBounds2(RightLeg, CameraCFrame)

			local Children, SizeX, SizeY, SizeZ = CharacterModel[ThirdPersonObject._bodyLUT.Cosmetics]:GetChildren(), 0.8034200668334961, 0.9660239815711975, 0.8034199476242065
			for Index = 1, #Children do
				local Part = Children[Index]
				if Part.MeshId ~= "rbxassetid://128240072851827" then
					continue
				end

				local PartCFrame, CameraPosition, CameraLookVector, Count = Part.CFrame, CameraCFrame.Position, CameraCFrame.LookVector, 0
				for X = -1, 1, 2 do
					for Y = -1, 1, 2 do
						for Z = -1, 1, 2 do
							local Position = PartCFrame * Vector3.new(SizeX * X, SizeY * Y, SizeZ * Z)
							local Depth = (Position - CameraPosition):Dot(CameraLookVector)

							Count += 1
							ESPCornerCache[Count] = Position
							ESPDepthCache[Count] = Depth

							if Depth >= 0.5 then
								CacheBounds(Position)
							end
						end
					end
				end

				for _,Edge in ipairs(ESPEdges) do
					local IndexA, IndexB = Edge[1], Edge[2]
					local DepthA, DepthB = ESPDepthCache[IndexA], ESPDepthCache[IndexB]
					if (DepthA < 0.5 and DepthB >= 0.5) or (DepthB < 0.5 and DepthA >= 0.5) then
						CacheBounds(ESPCornerCache[IndexA]:Lerp(ESPCornerCache[IndexB], (0.5 - DepthA) / (DepthB - DepthA)))
					end
				end

				break
			end

			if ESPBoundsCache.HasBounds then
				local MinX, MinY = ESPBoundsCache.MinX, ESPBoundsCache.MinY
				local MaxX, MaxY = ESPBoundsCache.MaxX, ESPBoundsCache.MaxY
				if MaxX >= 0 and MaxY >= 0 and MinX <= ViewportSizeX and MinY <= ViewportSizeY then
					local Left, Right = math.max(MinX - 2, 0), math.min(MaxX + 2, ViewportSizeX)
					local Top, Bottom = math.max(MinY - 2, 0), math.min(MaxY + 2, ViewportSizeY)
					if Right > Left and Bottom > Top then
						BoxLeft, BoxTop, BoxRight, BoxBottom = Left, Top, Right, Bottom
					end
				end
			end

            if BoxLeft then
                local BoxHeight = BoxBottom - BoxTop
                if Boxes then
					local Width, Color, Thickness = BoxRight - BoxLeft, Visuals.ESPVisuals_BoxColor, Visuals.ESPVisuals_BoxThickness
                    if Visuals.ESPVisuals_BoxStyle == "Corners" then
                        local Arm = math.min(Width, BoxHeight) * 0.25
                        for Index = 1, 8 do
                            local Segment = ESPBoxSegments[Index]
                            local Corner = Vector2.new(Segment[1] == 0 and BoxLeft or BoxRight, Segment[2] == 0 and BoxTop or BoxBottom)
                            ImDrawing.Line(Corner, Corner + Vector2.new(Segment[3] * Arm, Segment[4] * Arm), Color, Thickness, GlobalOpacity)
                        end
                    else
                        ImDrawing.Box(false, Vector2.new(BoxLeft, BoxTop), Vector2.new(Width, BoxHeight), Color, Thickness, GlobalOpacity)
                    end
                end

				if HeadTags then
					local Elements = Visuals.ESPVisuals_HeadTagElements
					local Text = ""
					local HasText = false

					if Elements.Name then
						Text = Player.Name
						HasText = true
					end

					if Elements.Health then
						local Health = math.floor(Entry:getHealth())
						Text ..= HasText and (" [" .. Health .. "]") or ("[" .. Health .. "]")
						HasText = true
					end

					if Elements.Distance then
						local _Distance = math.floor(math.sqrt(Distance))
						Text ..= HasText and (" [" .. _Distance .. "m]") or ("[" .. _Distance .. "m]")
						HasText = true
					end

					if HasText then
						local Size = Visuals.ESPVisuals_HeadTagSize
						ImDrawing.Text(Vector2.new((BoxLeft + BoxRight) * 0.5, BoxTop - Size - 3), Text, Visuals.ESPVisuals_HeadTagColor, Size, GlobalOpacity)
					end
				end

				if Healthbars then
					local Width, Height = Visuals.ESPVisuals_HealthbarWidth, math.max(6, BoxHeight)
					local BarX = Visuals.ESPVisuals_HealthbarSide == "Left" and (BoxLeft - Width - 3) or BoxRight + 3

					local Health, MaxHealth = Entry:getHealth()
					local Fraction = MaxHealth > 0 and math.clamp(Health / MaxHealth, 0, 1) or 0

					ImDrawing.Box(true, Vector2.new(BarX, BoxTop), Vector2.new(Width, Height), Color3.new(0, 0, 0), 1, GlobalOpacity)
					if Fraction > 0 then
						local FillHeight = math.max(1, math.floor((Height - 2) * Fraction))
						ImDrawing.Box(true, Vector2.new(BarX + 1, BoxTop + Height - FillHeight - 1), Vector2.new(math.max(
							1, Width - 2
						), FillHeight), Visuals.ESPVisuals_HealthbarStyle == "Solid" and Visuals.ESPVisuals_HealthbarColor or Color3.fromHSV(
							Fraction * 0.33, 0.85, 1
						), 1, GlobalOpacity)
					end
				end
            end
        end

        if Skeletons then
			ESPJointCache[1] = GetWeldPosition(ThirdPersonObject._neckWeld)
			ESPJointCache[2] = HeadPosition + Head.CFrame.UpVector
			ESPJointCache[3] = Torso.Position
			ESPJointCache[4] = GetWeldPosition(ThirdPersonObject._leftShoulderWeld)
			ESPJointCache[5] = GetWeldPosition(ThirdPersonObject._rightShoulderWeld)
			ESPJointCache[6] = GetWeldPosition(ThirdPersonObject._leftHipWeld)
			ESPJointCache[7] = GetWeldPosition(ThirdPersonObject._rightHipWeld)
            ESPJointCache[8] = ThirdPersonObject._leftFoot.pos
			ESPJointCache[9] = ThirdPersonObject._rightFoot.pos
			local Offset = -Vector3.yAxis
			ESPJointCache[10] = LeftArm.CFrame * Offset
			ESPJointCache[11] = RightArm.CFrame * Offset

            for Index = 1, 11 do
                local Position = ESPJointCache[Index]
                if Position then
                    local Screen, OnScreen = WorldToViewportPoint(Position)
                    ESPScreenCache[Index] = OnScreen and Screen
                else
                    ESPScreenCache[Index] = nil
                end
            end

            for _,Bone in next, ESPSkeletonBones do
                local From, To = ESPScreenCache[Bone[1]], ESPScreenCache[Bone[2]]
                if From and To then
                    ImDrawing.Line(From, To, Visuals.ESPVisuals_SkeletonColor, Visuals.ESPVisuals_SkeletonThickness, GlobalOpacity)
                end
            end

            if Visuals.ESPVisuals_SkeletonHeadDot then
                local Screen = ESPScreenCache[2]
                if Screen then
                    ImDrawing.Circle(true, Screen, 2.5, Visuals.ESPVisuals_SkeletonColor, 1, GlobalOpacity)
                end
            end
        end

        if Tracers and not (AimbotState.Target == Player and Aiming.Aimbot_TargetTracer) then
            local Origin = Visuals.ESPVisuals_TracerOrigin
            ImDrawing.Line((Origin == "Top" and ScreenTop) or (Origin == "Center" and ScreenCenter) or ScreenBottom, (WorldToViewportPoint(
				HeadPosition + -Vector3.yAxis
			)), Visuals.ESPVisuals_TracerColor, Visuals.ESPVisuals_TracerThickness, GlobalOpacity)
        end
    end
end

local ParticleEffects = {
	Snow = {
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(6, 12),
		Drag = 3,
		Acceleration = Vector3.new(0, -6, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}),
		Color = ColorSequence.new(Color3.fromRGB(235, 242, 255)),
	},
	Sparks = {
		Lifetime = NumberRange.new(0.3, 0.5),
		Speed = NumberRange.new(12, 20),
		Drag = 1,
		Acceleration = Vector3.new(0, -10, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.2)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		Color = ColorSequence.new(Color3.fromRGB(255, 180, 60)),
	},
	Embers = {
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(8, 16),
		Drag = 2,
		Acceleration = Vector3.new(0, 4, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		Color = ColorSequence.new(Color3.fromRGB(255, 120, 30)),
	}
}

local HitGhosts = {}
local function RenderHitCham(Model)
	local Color, Parts = Visuals.Combat_HitGhostsColor, {}
	for _,Descendant in Model:GetDescendants() do
		if Descendant:IsA("BasePart") then
			Descendant.Anchored = true
			Descendant.CanCollide = false
			Descendant.CanQuery = false
			Descendant.CanTouch = false
			Descendant.Color = Color
			Descendant.Material = Enum.Material.ForceField
			Descendant.Transparency = 0
			if Descendant.ClassName == "MeshPart" then
				Descendant.TextureID = ""
			end
			Parts[#Parts + 1] = Descendant
		elseif Descendant:IsA("SpecialMesh") then
			if Descendant.MeshId == "rbxassetid://4049240078" then
				Descendant.Parent:Destroy()
			else
				if Descendant.MeshId == "rbxassetid://6179256256" then
					Descendant.TextureId = "rbxassetid://12325350352"
				end
				Descendant.VertexColor = Vector3.new(Color.R / 255, Color.G / 255, Color.B / 255)
			end
		elseif Descendant:IsA("Weld") or Descendant:IsA("BillboardGui") or Descendant:IsA("Texture") or Descendant:IsA("Decal") then
			Descendant:Destroy()
		end
	end

	Model.Parent = workspace
	table.insert(HitGhosts, {Model = Model, Parts = Parts, Time = os.clock() + Visuals.Combat_HitGhostsLifetime})
end

local HitMarkerModule = {Active = {}, Offsets = {X = {{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}}}
function HitMarkerModule:Update(Now)
	local Active = self.Active
	for Index = #Active, 1, -1 do
		local Marker = Active[Index]
		local Elapsed = Now - Marker.Time
		if Elapsed >= (Visuals.Combat_HitMarkerFadeInOutAnimation and (Marker.Duration + 0.18) or Marker.Duration) then
			table.remove(Active, Index)
			continue
		end

		local Screen, OnScreen = WorldToViewportPoint(Marker.Position)
		if not OnScreen then
			continue
		end

		local Transparency = 1
		if Visuals.Combat_HitMarkerFadeInOutAnimation then
			local FadeIn, FadeOut = 0.08, 0.1
			if Elapsed < FadeIn then
				Transparency = Elapsed / FadeIn
			elseif Elapsed > Marker.Duration + FadeIn then
				Transparency = 1 - math.min(1, (Elapsed - Marker.Duration - FadeIn) / FadeOut)
			end
		end

		local Thickness = Visuals.Combat_HitMarkerThickness
		local Color = Marker.Color
		local Style = Marker.Style
		if Style == "Circle" then
			ImDrawing.Circle(false, Screen, Visuals.Combat_HitMarkerRadius, Color, Thickness, Transparency)
		else
			local Offsets = self.Offsets[Style]
			local X, Y = Screen.X, Screen.Y
			local Spin = Visuals.Combat_HitMarkerSpin
			local Angle = Spin and Elapsed * Visuals.Combat_HitMarkerSpinSpeed or 0
			local Gap = Visuals.Combat_HitMarkerGap
			local Size = Visuals.Combat_HitMarkerSize
			for _Index = 1, 4 do
				local OffsetX, OffsetY = Offsets[_Index][1], Offsets[_Index][2]
				local FromPoint = Vector2.new(X + OffsetX * Size, Y + OffsetY * Size)
				local ToPoint = Vector2.new(X + OffsetX * Gap, Y + OffsetY * Gap)
				if Spin then
					FromPoint, ToPoint = RotatePoint(Angle, FromPoint, Screen), RotatePoint(Angle, ToPoint, Screen)
				end
				ImDrawing.Line(FromPoint, ToPoint, Color, Thickness, Transparency)
			end
		end
	end
end

local ns__mousemoverel = mousemoverel or mouse_moverel or (function()
	Library:Notify("Required function for Mouse Aimbot is not supported, Mouse Aimbot won't function.", 6.75)
	return function() end
end)()

local function UpdateAimbot(LocalHeadPosition)
	local AimbotEnabled = Aiming.Aimbot_Enabled
	local ShowFOV = AimbotEnabled and Aiming.Aimbot_ShowFOVCircle
	if ShowFOV then
		ImDrawing.Circle(false, GetFOVOrigin(), Aiming.Aimbot_FOVCircleRadius, Aiming.Aimbot_FOVCircleColor, 1, Aiming.Aimbot_FOVCircleOpacity)
	end

	if AimbotEnabled then
		if IsSpawned then
			local TargetPart, Target, IsTargetVisible, TargetScreen, ClosestScore = nil, nil, false, nil, math.huge
			local FOVRadius, IsWallCheckOff = ShowFOV and Aiming.Aimbot_FOVCircleRadius or math.huge, not Aiming.Aimbot_WallCheck
			local AimbotPart, FOVOrigin = Aiming.Aimbot_Part, ShowFOV and GetFOVOrigin() or ScreenCenter
			local CenterX, CenterY = FOVOrigin.X, FOVOrigin.Y

			local function Check(Player, CharacterHash)
				local CameraCFrame, TorsoPosition = Camera.CFrame, CharacterHash.Torso.Position
				local CameraPosition, LookVector = CameraCFrame.Position, CameraCFrame.LookVector
				local DeltaX, DeltaY, DeltaZ = TorsoPosition.X - CameraPosition.X, TorsoPosition.Y - CameraPosition.Y, TorsoPosition.Z - CameraPosition.Z
				local DeltaMagnitude = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ)
				if DeltaMagnitude < 0.001 or (LookVector.X * DeltaX + LookVector.Y * DeltaY + LookVector.Z * DeltaZ) / DeltaMagnitude < 0 then
					return
				end

				local Part, Screen, IsVisible = GetTargetPart(CharacterHash, AimbotPart, IsWallCheckOff)
				if not Part or not Screen then
					return
				end

				DeltaX, DeltaY = Screen.X - CenterX, Screen.Y - CenterY
				local Distance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
				if Distance > FOVRadius then
					return
				end

				local PartPosition = Part.Position
				DeltaX, DeltaY, DeltaZ = PartPosition.X - LocalHeadPosition.X, PartPosition.Y - LocalHeadPosition.Y, PartPosition.Z - LocalHeadPosition.Z
				local Score = Distance + math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ) * 0.15
				if Score < ClosestScore then
					ClosestScore = Score
					Target = Player
					TargetPart = Part
					IsTargetVisible = IsVisible
					TargetScreen = Screen
				end
			end

			local AimbotTargetEntry = AimbotState.Target and CachedPlayers[AimbotState.Target]
			if AimbotTargetEntry and AimbotTargetEntry._alive and Aiming.Aimbot_Type ~= "Silent" then
				Check(AimbotState.Target, AimbotTargetEntry._thirdPersonObject._characterModelHash)
			end

			if not Target then
				for Player, Entry in next, CachedPlayers do
					if Entry._isEnemy then
						Check(Player, Entry._thirdPersonObject._characterModelHash)
					end
				end
			end

			AimbotState.Target, AimbotState.TargetPart, AimbotState.IsTargetVisible = Target, TargetPart, IsTargetVisible
			if TargetPart then
				if Aiming.Aimbot_Type == "Mouse" and not Library.Toggled then
					local Smoothness = Aiming.Aimbot_Smoothness
					ns__mousemoverel((TargetScreen.X - ScreenCenterX) / Smoothness, (TargetScreen.Y - ScreenCenterY) / Smoothness)
				elseif Aiming.Aimbot_Type == "Camera" then
					local LookVector, Smoothness = (AimbotState.TargetPart.Position - Camera.CFrame.Position).Unit, Aiming.Aimbot_Smoothness
					if Smoothness > 1 then
						LookVector = (Camera.CFrame.LookVector:Lerp(LookVector, 1/Smoothness)).Unit
					end

					local ActiveCamera = GetActiveCamera()
					local setLookVector = ActiveCamera.setLookVector
					if setLookVector then
						setLookVector(ActiveCamera, LookVector)
					end
				end
			end
		else
			AimbotState.Target, AimbotState.TargetPart, AimbotState.IsTargetVisible = nil, nil, false
		end
	else
		AimbotState.Target, AimbotState.TargetPart, AimbotState.IsTargetVisible = nil, nil, false
		return
	end

	if Aiming.Aimbot_TargetTracer and AimbotState.TargetPart then
		local From, ActiveWeapon = ScreenCenter, GetActiveWeapon()
		local BarrelPart = ActiveWeapon and ActiveWeapon._barrelPart
		if BarrelPart then
			local Screen, OnScreen = WorldToViewportPoint(BarrelPart.Position)
			if OnScreen then
				From = Screen
			end
		end
		ImDrawing.Line(From, (WorldToViewportPoint(AimbotState.TargetPart.Position)), Aiming.Aimbot_TargetTracerColor, 1.5, Aiming.Aimbot_TargetTracerOpacity)
	end
end

function ESPModule:UpdateGrenades(Now)
	local UseName = Visuals.ESPVisuals_GrenadeTagUseName
	local Color = Visuals.ESPVisuals_GrenadeTagColor
	local Size = Visuals.ESPVisuals_GrenadeTagSize
	local Opacity = Visuals.ESPVisuals_MasterOpacity * 0.01

	local Grenades = self.Grenades
	local Count = #Grenades
	for Index = Count, 1, -1 do
		local Entry = Grenades[Index]
		local Age = Now - Entry.Start
		local Fuse = Entry.Fuse

		if Age > Fuse then
			Grenades[Index] = Grenades[Count]
			Grenades[Count] = nil
			Count -= 1
		else
			local Nodes = Entry.Nodes
			local NodeCount = #Nodes
			local Estimated

			if Age <= Nodes[1].t then
				Estimated = Nodes[1].p
			elseif Age >= Nodes[NodeCount].t then
				Estimated = Nodes[NodeCount].p
			else
				local Segment = 1
				while Nodes[Segment + 1].t <= Age do
					Segment += 1
				end

				local First, Second = Nodes[Segment], Nodes[Segment + 1]
				local StartTime = First.t
				local Time = Second.t - StartTime

				if Time <= 0 then
					Estimated = Second.p
				else
					local ForwardWeight = (Age - StartTime) * (1 / Time)
					local BackwardWeight = 1 - ForwardWeight
					Estimated = BackwardWeight * BackwardWeight * (
						BackwardWeight + 3 * ForwardWeight
					) * First.p + Time * BackwardWeight * BackwardWeight * ForwardWeight * First.v - Time * BackwardWeight * ForwardWeight * ForwardWeight * Second.v + ForwardWeight * ForwardWeight * (
						ForwardWeight + 3 * BackwardWeight
					) * Second.p
				end
			end

			local Screen, OnScreen = WorldToViewportPoint(Estimated)
			if OnScreen then
				ImDrawing.Text(Screen, UseName and string.format("%s [%.1f]", Entry.Name, Fuse - Age) or string.format("GRENADE [%.1f]", Fuse - Age), Color, Size, Opacity)
			end
		end
	end
end

function GrenadeModule:UpdateTrajectory()
	local ActiveWeapon = IsSpawned and GetActiveWeapon()
	if not ActiveWeapon or ActiveWeapon:getWeaponType() ~= "Grenade" then
		for _,Segment in GrenadeModule.Segments do
			Segment.Beam.Transparency = NumberSequence.new(1)
		end
		GrenadeModule.Marker.Visible = false
		return
	end

	local CameraPosition = Camera.CFrame.Position
	local StartPosition = ActiveWeapon._mainPart.Position
	local StartHit = workspace:Raycast(CameraPosition, StartPosition - CameraPosition, GrenadeRaycastParams)
	local Position = StartHit and (StartHit.Position + StartHit.Normal * 0.01) or StartPosition

	local WeaponData = ActiveWeapon._weaponData
	local Points, Bounces, Impact, Gravity = {Position}, 0, nil, Vector3.new(0, -80, 0)
	local TargetPart = (not Visuals.Combat_GrenadeTrajectoryIgnoreAimbot) and AimbotState.TargetPart
	local SegmentStart, SegmentVelocity, SegmentTime, LastPosition, RaycastOffset, SegmentAcceleration, LastBounce = Position, (
		TargetPart and GrenadeModule:GetVelocity(TargetPart.Position, GetLocalPosition())
	) or (Camera.CFrame * CFrame.Angles(math.rad(WeaponData.throwangle or 0), 0, 0)).LookVector * (
		WeaponData.throwspeed or 100
	) + (GetLocalCharacter()._rootPart.AssemblyLinearVelocity or Vector3.zero), 0, Position, Vector3.zero, Gravity, false
	local MaxBounces, Elasticity, Friction = Visuals.Combat_GrenadeTrajectoryBounces, ActiveWeapon._bounceElasticity or 0.2, ActiveWeapon._frictionConstant or 0.08
	for _ = 1, 240 do
		SegmentTime += RaycastStep
		local NextPosition = SegmentStart + SegmentVelocity * SegmentTime + 0.5 * SegmentAcceleration * SegmentTime * SegmentTime
		local Hit = workspace:Raycast(LastPosition, NextPosition - LastPosition - 0.05 * RaycastOffset, GrenadeRaycastParams)
		if Hit and Hit.Instance.Name ~= "Window" and Hit.Instance.Name ~= "Col" then
			local HitPosition = Hit.Position
			if Bounces >= MaxBounces then
				Impact = HitPosition
				table.insert(Points, Impact)
				break
			end

			local Normal, Delta = Hit.Normal, HitPosition - LastPosition
			local Contact = LastPosition + math.max(0, 1 - 0.001 / Delta.Magnitude) * Delta + 0.05 * Normal
			table.insert(Points, Contact)
			local ImpactVelocity = SegmentVelocity + Gravity * SegmentTime
			local NormalVelocity = Normal * ImpactVelocity:Dot(Normal)
			local TangentialVelocity = ImpactVelocity - NormalVelocity
			SegmentVelocity = math.max(0, 1 - Friction * (10 * math.max(0, -Normal:Dot(SegmentAcceleration)) * RaycastStep + math.max(
				0, -(1 + Elasticity) * Normal:Dot(ImpactVelocity)
			)) / TangentialVelocity.Magnitude) * TangentialVelocity - Elasticity * NormalVelocity
			if SegmentVelocity.Magnitude < 1 then
				Impact = Contact
				break
			end

			SegmentStart, SegmentTime, LastPosition, SegmentAcceleration = Contact, 0, Contact, LastBounce and Vector3.zero or Gravity
			LastBounce, RaycastOffset = true, 0.2 * Normal
			Bounces += 1
		else
			table.insert(Points, NextPosition)
			LastPosition, LastBounce = NextPosition, false
		end
	end

	local PointCount = #Points
	local SegmentsNeeded = math.max(0, PointCount - 1)
	while #GrenadeModule.Segments < SegmentsNeeded do
		local Attachment0 = ns__cloneref(Instance.new("Attachment"))
		local Attachment1 = ns__cloneref(Instance.new("Attachment"))
		local Beam = ns__cloneref(Instance.new("Beam"))
		Beam.FaceCamera = true
		Beam.LightEmission = 1
		Beam.Texture = ""
		Beam.Segments = 10
		Attachment0.Parent = Terrain
		Attachment1.Parent = Terrain
		Beam.Attachment0 = Attachment0
		Beam.Attachment1 = Attachment1
		Beam.Parent = Terrain
		table.insert(GrenadeModule.Segments, {Beam = Beam, Attachment0 = Attachment0, Attachment1 = Attachment1})
	end

	local TrajectoryColor, ImpactColor, Thickness = Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 50, 50), Visuals.Combat_GrenadeTrajectoryThickness * 0.025
	for Index = 1, #GrenadeModule.Segments do
		local Segment = GrenadeModule.Segments[Index]
		local Beam = Segment.Beam
		if Index <= SegmentsNeeded then
			Segment.Attachment0.Position = Points[Index]
			Segment.Attachment1.Position = Points[Index + 1]
			Beam.Color = ColorSequence.new(Index == SegmentsNeeded and ImpactColor or TrajectoryColor)
			Beam.Width0 = Thickness
			Beam.Width1 = Thickness
			Beam.Transparency = NumberSequence.new(0)
		else
			Beam.Transparency = NumberSequence.new(1)
		end
	end

	GrenadeModule.Marker.Color3 = ImpactColor
	GrenadeModule.Marker.CFrame = CFrame.new(Impact or Points[PointCount])
	GrenadeModule.Marker.Visible = true
end

local AutoFireModule = {IsFiring = false, Start = 0}

function AutoFireModule:SetFiring(State, Weapon)
	self.IsFiring = State
	if Weapon then
		Weapon:shoot(State)
	end
end

function AutoFireModule:CanPenetrate(Weapon, TargetPart)
	local WeaponData = Weapon._weaponData
	local PenetrationDepth, BulletSpeed = WeaponData.penetrationdepth, WeaponData.bulletspeed
	if not (PenetrationDepth and BulletSpeed) then
		return
	end

	local Origin = GetLocalPosition()
	local Velocity = GetBulletVelocity(Origin, TargetPart.Position, BulletSpeed)
	return Velocity and BulletCheck(Origin, TargetPart.Position, Velocity, BulletAcceleration, PenetrationDepth)
end

function AutoFireModule:Update(Now)
	local ActiveWeapon = GetActiveWeapon()
	if not ActiveWeapon or ActiveWeapon:getWeaponType() ~= "Firearm" then
		if self.IsFiring then
			self:SetFiring(false, ActiveWeapon)
		end
		self.Start = 0
		return
	end

	if Aiming.Aimbot_Type ~= "Silent" or not AimbotState.TargetPart then
		if self.IsFiring then
			self:SetFiring(false, ActiveWeapon)
		end
		self.Start = 0
		return
	end

	local CanShoot = false
	if Aiming.Aimbot_AutoWall then
		CanShoot = self:CanPenetrate(ActiveWeapon, AimbotState.TargetPart)
	else
		CanShoot = AimbotState.IsTargetVisible
	end

	if not CanShoot then
		if self.IsFiring then
			self:SetFiring(false, ActiveWeapon)
		end
		self.Start = 0
		return
	end

	if self.Start == 0 then
		self.Start = Now
	end

	if (Now - self.Start) * 1000 >= Aiming.Aimbot_AutoDelay then
		if ActiveWeapon:getFiremode() then
			if not self.IsFiring then
				self:SetFiring(true, ActiveWeapon)
			end
		else
			self:SetFiring(not self.IsFiring, ActiveWeapon)
		end
	end
end

local ThirdPersonModule = {IsSpawned = false, Object = nil, LastPosition = nil, DeltaTimeAcceleration = 0}

function ThirdPersonModule:Destroy()
	if self.Object then
		FakeReplicationObject:despawn()
		self.Object:Destroy()
		self.Object = nil
		self.LastPosition = nil
	end
end

function ThirdPersonModule:Update(DeltaTime)
	if not (Visuals.Camera_ThirdPerson and Visuals.Camera_ThirdPersonShowCharacter) then
		return self:Destroy()
	end

	local LocalCharacter = GetLocalCharacter()
	local RootPart = LocalCharacter and LocalCharacter._rootPart
	if not RootPart then
		return self:Destroy()
	end

	self.DeltaTimeAcceleration += DeltaTime
	local Position = RootPart.Position
	self.LastPosition = self.LastPosition or Position
	local Velocity = (Position - self.LastPosition) / self.DeltaTimeAcceleration
	self.DeltaTimeAcceleration = 0

	if self.IsSpawned or not self.Object then
		local PlayerData = PlayerDataClientInterface.getPlayerData()
		local ClassData = PlayerData and PlayerData.settings and PlayerData.settings.classdata
		if ClassData then
			FakeReplicationObject._player = LocalPlayer
			FakeReplicationObject:spawn(nil, ClassData[ClassData.curclass])
			self.Object = FakeReplicationObject._thirdPersonObject
			FakeReplicationObject:setActiveIndex(1)
			local WeaponObjects = FakeReplicationObject:getWeaponObjects()
			for Index = 1, 3 do
				if WeaponObjects[Index] then
					self.Object:buildWeapon(Index)
				end
			end
			self.IsSpawned = false
		end
	end

	if not self.Object then
		self.LastPosition = Position
		return
	end

	local Angles = GetActiveCamera()._angles
	if Miscellaneous.AntiAim_Enabled then
		Angles = GetAntiAimAngles(Angles)
	else
		SpinTime = 0
	end

	FakeReplicationObject._posspring.t = Position
	FakeReplicationObject._posspring.p = Position
	FakeReplicationObject._lookangles.t = Angles
	FakeReplicationObject._lookangles.p = Angles

	local ClockTime, TickTime = os.clock(), tick()
	FakeReplicationObject._smoothReplication:receive(ClockTime, TickTime, {
		t = TickTime, position = Position, velocity = Velocity,
		angles = Angles, barrelAngles = Vector3.zero, breakcount = 0
	}, true)

	FakeReplicationObject._updaterecieved = true
	FakeReplicationObject._receivedPosition = Position
	FakeReplicationObject._receivedFrameTime = NetworkClient.getTime()
	FakeReplicationObject._lastPacketTime = ClockTime
	FakeReplicationObject._lastBarrelAngles = Vector3.zero
	FakeReplicationObject:step(3, true)

	local Weapon = GetActiveWeapon()
	local IsAiming = Weapon and Weapon._aiming or false
	if Visuals.Camera_ThirdPerson then
		if Visuals.Camera_ThirdPersonHideCharacterWhileAiming and IsAiming then
			self.Object:setCharacterRender(false)
		else
			self.Object:setCharacterRender(true)
			self.Object.canRenderWeapon = true
			if self.Object._characterModelHash then
				for _,Part in self.Object._characterModelHash do
					Part.LocalTransparencyModifier = 0
					Part.Transparency = 0
				end
			end
		end
	end

	self.LastPosition = Position
end

function RageBotModule:Reload(Weapon, WeaponData)
	if Weapon._magCount >= 1 then
		return true
	end

	local MagSize = WeaponData.magsize
	if MagSize <= 0 or Weapon._spareCount <= 0 then
		return
	end

	NetworkClientSend(NetworkClient, "reload")

	local ReloadCount = math.min(MagSize, Weapon._spareCount)
	Weapon._magCount += ReloadCount
	Weapon._spareCount -= ReloadCount

	return true
end

function RageBotModule:Update()
	local Weapon = GetActiveWeapon()
	if Weapon and Weapon:getWeaponType() == "Firearm" and Weapon._magCount and Weapon._spareCount and (Weapon._magCount > 0 or Weapon._spareCount > 0) and os.clock() > self.NextShot then
		local WeaponData = Weapon._weaponData
		local PenetrationDepth, BulletSpeed = WeaponData.penetrationdepth, WeaponData.bulletspeed
		if not (PenetrationDepth and BulletSpeed) then
			return
		end

		local FireRateTable = WeaponData.firerate
		local ShotInterval = 60 / (WeaponData.variablefirerate and FireRateTable[Weapon._firemodeIndex] or FireRateTable)
		local LocalPosition = GetLocalPosition()
		local PenetrationDetection = Aiming.RageBot_WallPenetrationDetection

		local Entries, Distances, Healths = {}, {}, {}
		for _,Entry in next, CachedPlayers do
			if not Entry._isEnemy then
				continue
			end

			local Index = #Entries + 1
			Entries[Index] = Entry

			local HeadPosition = Entry._thirdPersonObject._characterModelHash.Head.Position
			local DeltaX, DeltaY, DeltaZ = HeadPosition.X - LocalPosition.X, HeadPosition.Y - LocalPosition.Y, HeadPosition.Z - LocalPosition.Z
			Distances[Index] = DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ
			Healths[Index] = Entry:getHealth()
		end

		local EntryCount = #Entries
		if EntryCount == 0 then
			return
		end

		local IndexTable = table.create(EntryCount)
		for Index = 1, EntryCount do
			IndexTable[Index] = Index
		end

		table.sort(IndexTable, function(IndexA, IndexB)
			local HealthA, HealthB = Healths[IndexA], Healths[IndexB]
			if HealthA == HealthB then
				return Distances[IndexA] < Distances[IndexB]
			end
			return HealthA < HealthB
		end)

		local SortedEntries = table.create(EntryCount)
		for Index = 1, EntryCount do
			SortedEntries[Index] = Entries[IndexTable[Index]]
		end

		local NetworkTime, ScanCache, Targets = NetworkClient.getTime(), {}, table.create(6)
		for Index = 1, #SortedEntries do
			local Entry = SortedEntries[Index]
			local Origin, Target, Velocity, HitPartName = self:SolveShot(Targets, self:GetTargets(Entry, Targets), LocalPosition, BulletSpeed, PenetrationDetection, PenetrationDepth, ScanCache, Entry, Entry._thirdPersonObject._characterModelHash)
			if Origin then
				if os.clock() < self.NextShot then
					break
				end

				if not self:Reload(Weapon, WeaponData) then
					break
				end

				local PelletCount = WeaponData.pelletcount or 1
				local Direction, Bullets = Velocity.Unit, {}

				for _Index = 1, PelletCount do
					Bullets[_Index] = {Direction, TicketAddition}
					TicketAddition += 1
				end

				local UniqueId = Weapon.uniqueId
				NetworkClientSend(NetworkClient, "newbullets", UniqueId, {
					camerapos = LocalPosition,
					firepos = Origin,
					bullets = Bullets,
				}, NetworkTime)

				local Player = Entry._player
				for _Index = 1, PelletCount do
					NetworkClientSend(NetworkClient, "bullethit", UniqueId, Player, Target, HitPartName or "Head", Bullets[_Index][2], NetworkTime)
				end

				if Aiming.RageBot_Collateral then
					for _Index = Index + 1, #SortedEntries do
						local _Entry = SortedEntries[_Index]
						local _Player = _Entry._player
						if _Player ~= Player then
							if (_Entry._receivedPosition - Target).Magnitude <= 9.9 then
								for __Index = 1, PelletCount do
									NetworkClientSend(NetworkClient, "bullethit", UniqueId, _Player, Target, HitPartName or "Head", Bullets[__Index][2], NetworkTime)
								end
							end
						end
					end
				end

				if Visuals.Combat_LocalBulletTracers then
					BulletTracerModule:Render(Origin, Direction * 1000, "Combat_LocalBulletTracer")
				end

				local Barrel = Weapon._barrelPart
				Effects.muzzleflash(Barrel, WeaponData.hideflash, 0.9)

				local WeaponType = WeaponData.type
				if WeaponType == "SNIPER" then
					PlayGameSound("metalshell", 0.1)
				elseif WeaponType == "SHOTGUN" then
					PlayGameSound("shotWeaponshell", 0.2)
				elseif WeaponType == "REVOLVER" and not WeaponData.caselessammo then
					PlayGameSound("metalshell", 0.15, 0.8)
				end

				if not Weapon._aiming then
					HudCrosshairsInterface.fireImpulse(WeaponData.crossexpansion)
				end

				if WeaponData.sniperbass then
					PlayGameSound("1PsniperBass", 0.75)
					PlayGameSound("1PsniperEcho", 1)
				end

				local ShootSound = Miscellaneous.SoundOverride_ShootSound
				if ShootSound == "None" then
					PlaySoundId(WeaponData.firesoundid, 2, WeaponData.firevolume, WeaponData.firepitch, Barrel, nil, 0, 0.05)
				else
					PlaySoundId(CustomSounds[ShootSound], 2, WeaponData.firevolume, WeaponData.firepitch, Barrel, nil, 0, 0.05)
				end

				Weapon._magCount -= 1
				self.NextShot = os.clock() + ShotInterval

			end
		end
	end
end

Module.Players.PlayerRemoving:Connect(function(Player)
	ESPModule:Clear(Player)
	MovementCache[Player] = nil
end)

for _,Child in Camera:GetChildren() do
	ViewModelModule:OnCameraChildAdded(Child)
end

Camera.ChildAdded:Connect(function(Child)
	ViewModelModule:OnCameraChildAdded(Child)
end)

Effects.muzzleflash = function(Barrel, Hide, Scale)
	local Weapon = Barrel and GetActiveWeapon()
	local Custom = Miscellaneous.WeaponMods_CustomMuzzleFlash and (not Miscellaneous.WeaponMods_MuzzleFlashLocalOnly or (Weapon and Weapon._barrelPart == Barrel))

	local Result = MuzzleFlash(Barrel, Hide, (Scale or 1) * (Custom and Miscellaneous.WeaponMods_MuzzleFlashSize or 1))
	if Custom then
		local MiscFolder = IgnoreFolder:FindFirstChild("Misc")
		if MiscFolder then
			local Origin = Barrel.Position
			local Material = Enum.Material[Miscellaneous.WeaponMods_MuzzleFlashMaterial] or Enum.Material.Neon
			for _,Child in MiscFolder:GetChildren() do
				if Child:IsA("Model") and (Child:GetPivot().Position - Origin).Magnitude < 1.5 then
					for _,Item in Child:QueryDescendants("ParticleEmitter, BasePart, ParticleEmitter, Light") do
						if Item:IsA("BasePart") then
							Item.Color = Miscellaneous.WeaponMods_MuzzleFlashColor
							Item.Material = Material
						elseif Item:IsA("ParticleEmitter") then
							Item.Color = ColorSequence.new(Miscellaneous.WeaponMods_MuzzleFlashColor)
						elseif Item:IsA("Light") then
							Item.Color = Miscellaneous.WeaponMods_MuzzleFlashColor
						end
					end
				end
			end
		end
	end
	return Result
end

local LastHit
ns__hookfunction(Module.__get("ThirdPersonObject"), "popCharacterModel", function(Original, self)
	local Character, Position = Original(self)
	if Visuals.Combat_HitGhosts and LastHit == self._player then
		LastHit = nil
		RenderHitCham(Character:Clone())
	end
	return Character, Position
end)

ns__hookfunction(Module.__get("ThirdPersonObject"), "kickWeapon", function(Original, self, ...)
	return
end)

for Index, Table in ipairs({FirearmObject, GrenadeObject, MeleeObject}) do
	ns__hookfunction(Table, "step", function(Original, self, ...)
		Original(self, ...)
		if self._mainWeld and (Visuals.ViewModel_CustomOffset or Visuals.ViewModel_CustomRotation or Visuals.ViewModel_CustomRoll) then
			local AimBlend = 1
			if self.getActiveAimStats then
				AimBlend = 0
				for _,Sight in self:getActiveAimStats() do
					AimBlend += Sight.sightaimspring.p
				end
				AimBlend = math.clamp(1 - AimBlend, 0, 1)
			end

			if AimBlend <= 0 then
				return
			end

			local Custom = CFrame.identity
			if Visuals.ViewModel_CustomOffset then
				Custom *= CFrame.new(Visuals.ViewModel_OffsetX, Visuals.ViewModel_OffsetY, Visuals.ViewModel_OffsetZ)
			end

			if Visuals.ViewModel_CustomRotation then
				Custom *= CFrame.Angles(math.rad(Visuals.ViewModel_RotationX), math.rad(Visuals.ViewModel_RotationY), math.rad(Visuals.ViewModel_RotationZ))
			end

			local Applied = CFrame.identity:Lerp(Custom, AimBlend)
			self._mainWeld.C0 *= Applied

			local ArmLeft, ArmRight = self._characterObject:getArmWelds()
			if ArmLeft then
				ArmLeft.C0 *= Applied
			end

			if ArmRight then
				ArmRight.C0 *= Applied
			end

			if Visuals.ViewModel_CustomRoll then
				local CameraCFrame = Camera.CFrame
				local RootCFrame = self._characterObject:getRootPart().CFrame
				local InverseRootSpace = RootCFrame:Inverse() * CameraCFrame * CFrame.Angles(0, 0, math.rad(
					Visuals.ViewModel_Roll
				) * AimBlend) * CameraCFrame:Inverse() * RootCFrame

				self._mainWeld.C0 *= InverseRootSpace
				if ArmLeft then
					ArmLeft.C0 *= InverseRootSpace
				end

				if ArmRight then
					ArmRight.C0 *= InverseRootSpace
				end
			end
		end
	end)

	ns__hookfunction(Table, "getAnimLength", function(Original, self, Name, ...)
		if (string.find(string.lower(Name), "unequip") or string.find(string.lower(Name), "equip")) and Miscellaneous.WeaponMods_InstantEquipUnequip then
			return 0
		end
		return Original(self, Name, ...)
	end)

	if Index > 1 then
		ns__hookfunction(Table, "walkSway", function(Original, self, ...)
			if Miscellaneous.WeaponMods_NoWalkSway then
				return CFrame.identity
			end
			return Original(self, ...)
		end)
	end
end

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
if RemoteEvent then
	RemoteEvent.OnClientEvent:Connect(function(Packet, ...)
		if Packet == "startvotekick" then
			if (...) == LocalPlayer.Name and Miscellaneous.Extras_HopOnVotekick then
				game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
			end
		elseif Packet == "newgrenade" then
			if Visuals.ESPVisuals_GrenadeTags then
				local Nodes = select(3, ...)
				if Nodes[1] then
					local Grenades = ESPModule.Grenades
					Grenades[#Grenades + 1] = {
						Nodes = Nodes,
						Fuse = select(5, ...),
						Name = select(2, ...),
						Start = os.clock(),
					}
				end
			end
		elseif Packet == "died" then
			local Victim = (...).victim
			if Victim == LocalPlayer then
				IsSpawned, SpinTime, ThirdPersonModule.IsSpawned = false, 0, false
				return
			end

			local Attacker = Aiming.Aimbot_DeathNotification and Victim == AimbotState.Target and (...).attacker
			if Attacker then
				Library:Notify(Attacker == LocalPlayer and ("You eliminated " .. Victim.Name) or ("Target was eliminated by " .. Attacker.Name), 3)
			end

			ESPModule:Clear(Victim)
			MovementCache[Victim] = nil
		elseif Packet == "bulletHitConfirm" or Packet == "meleeHitConfirm" or Packet == "grenadeHitConfirm" then
			local Victim = (...)
			if Victim == LocalPlayer then
				return
			end

			local Position = select(3, ...)
			if Miscellaneous.HitLogs_Enabled then
				local HitPart = select(2, ...)
				local Text = {"Hit " .. Victim.Name}
				if Miscellaneous.HitLogs_ShowPart and HitPart then
					table.insert(Text, "in the " .. HitPart)
				end
				if Miscellaneous.HitLogs_ShowDamage then
					table.insert(Text, "for " .. math.floor(select(4, ...) or 0) .. " damage")
				end

				if Miscellaneous.HitLogs_ShowDistance then
					table.insert(Text, "from " .. math.floor((GetLocalPosition() - Position).Magnitude) .. "m away")
				end

				Library:Notify(table.concat(Text, " "), 3)
			end

			if Visuals.Combat_HitMarkers then
				table.insert(HitMarkerModule.Active, {
					Position = Position,
					Time = os.clock(),
					Duration = Visuals.Combat_HitMarkerDuration,
					Style = Visuals.Combat_HitMarkerStyle,
					Color = Visuals.Combat_HitMarkerColor,
				})
			end

			if Visuals.Combat_HitParticles then
				local Preset, Part = ParticleEffects[Visuals.Combat_HitParticleEffect], ns__cloneref(Instance.new("Part"))
				Part.Anchored = true
				Part.CanCollide = false
				Part.CanQuery = false
				Part.CanTouch = false
				Part.Transparency = 1
				Part.Size = Vector3.new(0.5, 0.5, 0.5)
				Part.CFrame = CFrame.new(Position)
				Part.Parent = workspace
				local Emitter = ns__cloneref(Instance.new("ParticleEmitter"))
				Emitter.Rate = 0
				Emitter.Lifetime = NumberRange.new(Preset.Lifetime.Min * Visuals.Combat_HitParticleLifetime, Preset.Lifetime.Max * Visuals.Combat_HitParticleLifetime)
				Emitter.Speed = Preset.Speed
				Emitter.EmissionDirection = Enum.NormalId.Top
				Emitter.SpreadAngle = Vector2.new(180, 180)
				Emitter.Drag = Preset.Drag
				Emitter.Acceleration = Preset.Acceleration
				local Keypoints = Preset.Size.Keypoints
				Emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, Keypoints[1].Value * Visuals.Combat_HitParticleSize), NumberSequenceKeypoint.new(1, Keypoints[2].Value * Visuals.Combat_HitParticleSize)})
				Emitter.Transparency = Preset.Transparency
				Emitter.Color = Preset.Color
				Emitter.Parent = Part
				Emitter:Emit(Visuals.Combat_HitParticleAmount)
				Debris:AddItem(Part, 3)
			end

			if Visuals.Combat_HitGhosts and not Visuals.Combat_HitGhostsOnKillOnly then
				local Entry = CachedPlayers[Victim]
				if Entry then
					RenderHitCham(Entry._thirdPersonObject._characterModel:Clone())
				end
			end
		end
	end)
end

RunService.PreRender:Connect(function(DeltaTime)
	ImDrawing.NewFrame()

	local PreviousFrame = CanSeeFrameCounter
	CanSeeFrameCounter += 1
	for Part, Entry in next, CanSeeCache do
		if Entry[2] ~= PreviousFrame then
			table.insert(CanSeeCachePool, Entry)
			CanSeeCache[Part] = nil
		end
	end

	if Visuals.Lighting_Flashlight and IsSpawned then
		FlashlightPart.CFrame = Camera.CFrame
		SpotLight.Enabled = true
		SpotLight.Color = Visuals.Lighting_FlashlightColor
		SpotLight.Brightness = Visuals.Lighting_FlashlightBrightness
		SpotLight.Range = Visuals.Lighting_FlashlightRange
		SpotLight.Angle = Visuals.Lighting_FlashlightAngle
	else
		SpotLight.Enabled = false
	end
	local Now, LocalHeadPosition = os.clock(), GetLocalPosition()
	HitMarkerModule:Update(Now)

	for Index = #HitGhosts, 1, -1 do
		local Cham = HitGhosts[Index]
		local Progress = (Cham.Time - Now) / Visuals.Combat_HitGhostsLifetime
		if Progress <= 0 then
			Cham.Model:Destroy()
			table.remove(HitGhosts, Index)
		else
			local Transparency = 1 - Progress
			for _,Part in Cham.Parts do
				Part.Transparency = Transparency
			end
		end
	end

	BulletAcceleration, BulletLifetime = PublicSettings.bulletAcceleration, PublicSettings.bulletLifeTime
	UpdateAimbot(LocalHeadPosition)

	if Visuals.ESPVisuals_MasterSwitch and not MenuScreenGui.Enabled then
		local Quality = Visuals.ESPVisuals_PerformanceQuality
		if (not Visuals.ESPVisuals_PerformanceMode or (
			Quality == "Balanced" and CanSeeFrameCounter % 2 == 0
		) or (Quality == "Performance" and CanSeeFrameCounter % 3 == 0) or (
			Quality == "Quality" and CanSeeFrameCounter % 3 ~= 2
		)) then
			ESPModule:Update(LocalHeadPosition)
		end
	else
		for Player in next, ESPModule.Highlights do
			ESPModule:Clear(Player)
		end
	end

	UpdateCrosshair(DeltaTime)

	if Visuals.ESPVisuals_GrenadeTags then
		ESPModule:UpdateGrenades(Now)
	end

	if Aiming.Aimbot_AutoFire and not RoundSystemClientInterface.roundLock then
		AutoFireModule:Update(Now)
	end

	Library:UpdateWatermark()
	ImDrawing.EndFrame()
end)

RunService.Heartbeat:Connect(function(DeltaTime)
	RefreshCache()

	local Now = os.clock()
	for Index = #BulletTracerModule.Active, 1, -1 do
		local Data = BulletTracerModule.Active[Index]
		local Elapsed, Duration = Now - Data.StartTime, Data.Duration
		if Elapsed >= Duration then
			Data.Beam:Destroy()
			Data.Attachment0:Destroy()
			Data.Attachment1:Destroy()
			table.remove(BulletTracerModule.Active, Index)
		else
			local Progress = Elapsed / Duration
			if Data.FadeMode == "Width" then
				local Beam, Thickness = Data.Beam, Data.Thickness * (1 - Progress)
				Beam.Width0 = Thickness
				Beam.Width1 = Thickness
			else
				local Alpha = Data.Alpha
				Data.Beam.Transparency = NumberSequence.new((1 - Alpha) + (Alpha * Progress))
			end
		end
	end

	if Visuals.Combat_GrenadeTrajectory then
		GrenadeModule:UpdateTrajectory()
	end

	local RadarHack = IsSpawned and Visuals.Combat_RadarHack
	for Player, Entry in next, CachedPlayers do
		if Entry._isEnemy then
			local Status = RadarHack and GetPlayerStatusEntry(Player)
			if Status then
				Status.isSpotted = true
			end
		end
	end

	if IsSpawned then
		if Visuals.Combat_AutoSpot then
			local Enemies = {}
			for Player, Entry in next, CachedPlayers do
				if Entry._isEnemy then
					table.insert(Enemies, Player)
				end
			end

			if #Enemies > 0 then
				NetworkClientSend(NetworkClient, "spotplayers", Enemies, NetworkClient.getTime())
			end
		end

		local Humanoid = GetLocalHumanoid()
		if Humanoid and Miscellaneous.Movement_BunnyHop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			Humanoid.Jump = true
		end

		if Miscellaneous.Movement_NoSlideCooldown then
			local LocalCharacter = GetLocalCharacter()
			if LocalCharacter then
				LocalCharacter.dived = false
			end
		end

		if not RoundSystemClientInterface.roundLock then
			if Aiming.RageBot_Enabled then
				RageBotModule:Update()
			end

			if Miscellaneous.KnifeAura_Enabled then
				KnifeAuraModule:Update()
			end
		end
	end
	ThirdPersonModule:Update(DeltaTime)
end)

local repupdate_LastTime, repupdate_ReverseTime
NetworkClient.send = function(self, Packet, ...)
	if Packet == "flaguser" or Packet == "debug" or Packet == "logmessage" then
		return
	elseif Packet == "repupdate" then
		local Position, Angles, BarrelAngles, Time = ...
		if Miscellaneous.Movement_Speed or Miscellaneous.Movement_Fly or Miscellaneous.Movement_BunnyHop then
			if not repupdate_ReverseTime then
				repupdate_LastTime = Time
			end

			if (Time - repupdate_LastTime) > RaycastStep then
				repupdate_ReverseTime = false
				repupdate_LastTime = Time
			end

			repupdate_ReverseTime = not repupdate_ReverseTime
			Time = repupdate_LastTime
		end

		if Angles and Miscellaneous.AntiAim_Enabled then
			Angles = GetAntiAimAngles(Angles)
		end

		return NetworkClientSend(self, Packet, Position, Angles, BarrelAngles, Time)
	elseif Packet == "spawn" then
		TicketAddition, IsSpawned, ThirdPersonModule.IsSpawned = 0, true, true
		return NetworkClientSend(self, Packet, ...)
	end

	if ThirdPersonModule.Object then
		if Packet == "equip" then
			local Slot = (...)
			if FakeReplicationObject then
				FakeReplicationObject:setActiveIndex(Slot)
			end

			if Slot ~= 3 then
				ThirdPersonModule.Object:equip(Slot)
			else
				ThirdPersonModule.Object:equipMelee()
			end

			return NetworkClientSend(self, Packet, ...)
		elseif Packet == "stab" then
			ThirdPersonModule.Object:stab()
			return NetworkClientSend(self, Packet, ...)
		elseif Packet == "aim" then
			ThirdPersonModule.Object:setAim(...)
			return NetworkClientSend(self, Packet, ...)
		elseif Packet == "sprint" then
			ThirdPersonModule.Object:setSprint(...)
			return NetworkClientSend(self, Packet, ...)
		elseif Packet == "stance" then
			ThirdPersonModule.Object:setStance(...)
			return NetworkClientSend(self, Packet, ...)
		end
	end

	if Packet == "newbullets" then
		local UniqueId, BulletData, Time = ...
		local Bullets = BulletData.bullets
		local Count = #Bullets

		for Index = 1, Count do
			Bullets[Index][2] += TicketAddition
		end

		if Aiming.Aimbot_Enabled and Aiming.Aimbot_Type == "Silent" then
			if Aiming.Aimbot_BulletCache and SilentCache.Target and (os.clock() - SilentCache.Frame < 0.1) then
				local Direction = SilentCache.Velocity.Unit
				for Index = 1, Count do
					Bullets[Index][1] = Direction
				end
			else
				local Direction, Target, Entry, _Time = SilentAimbotModule:Solve(BulletData.firepos, BulletAcceleration, GetActiveWeapon()._weaponData.bulletspeed)
				if Direction and Target and Entry then
					for Index = 1, Count do
						Bullets[Index][1] = Direction
					end
					SilentCache.Player = Entry._player
					SilentCache.Time = _Time
				end
			end
		end

		local Object = ThirdPersonModule.Object
		if Object then
			Object:kickWeapon(false, nil, 0, 0)
		end

		return NetworkClientSend(self, Packet, UniqueId, BulletData, Time)
	elseif Packet == "bullethit" then
		local UniqueId, Player, Position, PartName, Ticket, Time = ...
		Ticket += TicketAddition

		if TicketCache[Ticket] then
			return
		end

		TicketCache[Ticket], LastHit = true, Player
		return NetworkClientSend(self, Packet, UniqueId, Player, Position, PartName, Ticket, Time)
	elseif Packet == "newgrenade" then
		local Position, Velocity, Time, Fuse = ...

		if Miscellaneous.WeaponMods_CustomGrenadeFuse then
			Fuse = Miscellaneous.WeaponMods_CustomGrenadeFuseAmount
		end

		if Aiming.Aimbot_RedirectGrenade and IsSpawned and AimbotState.TargetPart then
			local _Velocity, _Fuse = GrenadeModule:GetVelocity(AimbotState.TargetPart.Position, Position)
			if _Velocity then
				Velocity = _Velocity
				if _Fuse then
					Fuse = _Fuse
				end
			end
		end

		if Miscellaneous.WeaponMods_UncookableGrenade and Fuse <= 0 then
			Fuse = GetActiveWeapon():getWeaponStat("fusetime") or 5
		end

		if Miscellaneous.WeaponMods_CustomGrenadeFuse and Miscellaneous.WeaponMods_CustomGrenadeFuseOnImpact and Velocity.Magnitude > 0.01 then
			Fuse = GrenadeModule:ImpactFuse(Position, Velocity) or Fuse
		end

		return NetworkClientSend(self, Packet, Position, Velocity, Time, Fuse)
	elseif (Packet == "falldamage" and Miscellaneous.Movement_NoFallDamage) or (Packet == "changeCamo" and Miscellaneous.ClientSessionUnlocks_CamosUnlocked) or (Packet == "changedweapon" and (...) == "Knife" and Miscellaneous.ClientSessionUnlocks_KnivesUnlocked) or (Packet == "changeAttachment" and Miscellaneous.ClientSessionUnlocks_AttachmentsUnlocked) then
		return
	end

	return NetworkClientSend(self, Packet, ...)
end

Library:BuildUI({Aiming, Visuals, Miscellaneous, Settings}, {
	ESPModule, LightingCache, OnDeadBody, RefreshLighting, UpdateBloom, CustomSounds, Effects.breakwindow, PlaySoundId, {
		"None", "Osu", "MLG", "Bonk", "Rust", "Metal", "Skeet", "Quack", "Katana", "Neverlose",
		"Undertale", "Jet Set Radio", "TF2 Critical", "TF2 Frying Pan", "TF2 Alternative"
	}
}, {Camera, Lighting, DeadBodyFolder, Module.Method}, {PlayerDataClientInterface.getPlayerData, PlayerDataUtils.getCasePacketData}, Module.ExecutorName)

Library:Toggle()

pcall(function()
	local Request = not isfile("NikoletoScripts/PhantomWare/Cache/Invite.nscache") and (httprequest or http_request or request)
	if Request then
		if pcall(Request, {
			Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST", Headers = {["Content-Type"] = "application/json", Origin = "https://discord.com"},
			Body = HttpService:JSONEncode({cmd = "INVITE_BROWSER", nonce = HttpService:GenerateGUID(false), args = {code = "DwRT2nH93D"}})
		}) then
			writefile("NikoletoScripts/PhantomWare/Cache/Invite.nscache", "DwRT2nH93D")
		end
	end
end)
