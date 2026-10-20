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
			return LocalPlayer:Kick("Error while accessing Game Modules, try rejoining through the desktop app, if this issue persists, please make a ticket in the discord server immediately.\ndiscord.gg/DsGCKtxxEN" .. (ExecutorName and (" | " .. ExecutorName) or ""))
		end

		ns__require, Method = function(Name)
			return ModuleCache[Name]
		end, "fenv.getgc"
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

			return LocalPlayer:Kick("Failed to require Module '" .. Name .. " ', error[" .. tostring(Result) .. "]\nPlease make a ticket in the discord server immediately.\ndiscord.gg/DsGCKtxxEN")
		end

		local Source = __internal()
		if not Source then
			local StartTime = os.clock()
			while true do
				if os.clock() - StartTime >= 5 then
					LocalPlayer:Kick("Module Access Timeout, please make a ticket in the discord server immediately.\ndiscord.gg/DsGCKtxxEN\nDebug Info: " .. ExecutorName .. " | " .. Name .. ": " .. (ModuleCache and "fenv.getgc" or "shared.require"))
					pcall(setclipboard, "discord.gg/DsGCKtxxEN")
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
local MiscFolder = IgnoreFolder:WaitForChild("Misc", 9e9)
local Camera, Map = workspace:WaitForChild("Camera", 9e9), workspace:WaitForChild("Map", 9e9)

local function CreateRaycastParams(Properties)
	local _RaycastParams = RaycastParams.new()
	for Property, Value in Properties do
		_RaycastParams[Property] = Value
	end
	return _RaycastParams, _RaycastParams.FilterDescendantsInstances
end

local AimingRaycastParams, AimingRaycastParamsFilterDescendantsInstances = CreateRaycastParams({FilterType = Enum.RaycastFilterType.Exclude, FilterDescendantsInstances = {IgnoreFolder, workspace:WaitForChild("Players", 9e9), workspace:WaitForChild("Roots", 9e9), Camera, Terrain}})
local TransparentRaycastParams = CreateRaycastParams({FilterType = Enum.RaycastFilterType.Exclude})
local BulletRaycastParams = CreateRaycastParams({FilterType = Enum.RaycastFilterType.Exclude, FilterDescendantsInstances = {IgnoreFolder, Camera, Terrain}})
local GrenadeRaycastParams = CreateRaycastParams({FilterType = Enum.RaycastFilterType.Include, FilterDescendantsInstances = {Map}})
local GrenadeImpactParams = CreateRaycastParams({FilterType = Enum.RaycastFilterType.Include})

local DarkerColorCache = setmetatable({}, {__mode = "kv", __index = function(self, Color)
	local DarkerColor = Color3.new(Color.R * 0.8, Color.G * 0.8, Color.B * 0.8)
	rawset(self, Color, DarkerColor)
	return DarkerColor
end})

local AimbotState = {}
local Aiming = {
	Aimbot_Enabled = false,
	Aimbot_Type = "None",
	Aimbot_Part = "Head",
	Aimbot_Smoothness = 3,
	Aimbot_AutoFire = false,
	Aimbot_RedirectGrenade = false,
	Aimbot_FuseAssist = false,
	Aimbot_Collateral = false,
	Aimbot_CollateralRadius = 9.9,
	Aimbot_AutoWall = false,
	Aimbot_AutoDelay = 0,
	Aimbot_HitChance = 100,
	Aimbot_WallCheck = false,
	Aimbot_WallCheckAction = "Ignore Target",
	Aimbot_HitScanning = false,
	Aimbot_HitScanningMode = "Cardinal",
	Aimbot_HitScanningAxes = {X = true, Y = true, Z = true},
	Aimbot_HitScanningSteps = 1,
	Aimbot_HitScanningRadius = 1,
	Aimbot_DeathNotification = false,
	Aimbot_ShowFOVCircle = false,
	Aimbot_FOVCircleColor = Color3.fromRGB(255, 255, 255),
	Aimbot_FOVCircleOpacity = 1,
	Aimbot_FOVCircleFilled = false,
	Aimbot_FOVCircleDotted = false,
	Aimbot_FOVCircleThickness = 1,
	Aimbot_FOVCircleRadius = 150,
	Aimbot_FOVCircleFireExpansion = false,
	Aimbot_FOVCircleFireAmount = 15,
	Aimbot_FOVCircleFireDuration = 0.2,
	Aimbot_FOVCircleFollowRecoil = false,
	Aimbot_TargetTracer = false,
	Aimbot_TargetTracerColor = Color3.fromRGB(255, 255, 255),
	Aimbot_TargetTracerOpacity = 1,

	RageBot_Enabled = false,
	RageBot_BlockShooting = true,
	RageBot_Part = "Head",
	RageBot_WallPenetrationDetection = false,
	RageBot_Collateral = false,
	RageBot_CollateralRadius = 9.9,
	RageBot_HitScanning = false,
	RageBot_HitScanningMode = "Cardinal",
	RageBot_HitScanningRadius = 1,
	RageBot_FireScanning = false,
	RageBot_FireScanningMode = "Cardinal",
	RageBot_FireScanningRadius = 3,
	RageBot_FireScanningCount = 8,
	RageBot_ScanLimit = true,
	RageBot_ScanLimitAmount = 128,
	RageBot_Backtrack = false,
	RageBot_BacktrackScans = 2,
	RageBot_BacktrackTime = 200
}

local Visuals = {
	ESPVisuals_MasterSwitch = false,

	ESPVisuals_MaxDistance = 10000,

	ESPVisuals_PerformanceMode = false,

	ESPVisuals_HighlightChams = false,
	ESPVisuals_HighlightChamColor = Color3.fromRGB(255, 0, 0),
	ESPVisuals_HighlightChamRendering = {Fill = true, Outline = true},
	ESPVisuals_HighlightChamStyle = "Solid",
	ESPVisuals_HighlightChamVisibleColor = Color3.fromRGB(0, 255, 0),
	ESPVisuals_HighlightChamOccluded = false,
	ESPVisuals_HighlightChamTransparency = 0,

	ESPVisuals_Skeletons = false,
	ESPVisuals_SkeletonColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_SkeletonTransparency = 0,
	ESPVisuals_SkeletonThickness = 1.5,
	ESPVisuals_SkeletonHeadDot = false,

	ESPVisuals_HeadTags = false,
	ESPVisuals_HeadTagColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_HeadTagTransparency = 0,
	ESPVisuals_HeadTagPixelOffset = false,
	ESPVisuals_HeadTagPixelOffsetSize = 0,
	ESPVisuals_HeadTagStaticElements = {Name = true},
	ESPVisuals_HeadTagStatusElements = {Aiming = true},
	ESPVisuals_HeadTagPosition = "Top",
	ESPVisuals_HeadTagSize = 13,

	ESPVisuals_Boxes = false,
	ESPVisuals_BoxColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_BoxTransparency = 0,
	ESPVisuals_BoxStyle = "Full",
	ESPVisuals_BoxThickness = 1.5,

	ESPVisuals_Healthbars = false,
	ESPVisuals_HealthbarStyle = "Solid",
	ESPVisuals_HealthbarColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_HealthbarTransparency = 0,
	ESPVisuals_HealthbarPosition = "Left",
	ESPVisuals_HealthbarWidth = 2,

	ESPVisuals_Tracers = false,
	ESPVisuals_TracerColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_TracerTransparency = 0,
	ESPVisuals_TracerOrigin = "Bottom",
	ESPVisuals_TracerPart = "Neck",
	ESPVisuals_TracerThickness = 1.5,

	ESPVisuals_OffscreenArrows = false,
	ESPVisuals_OffscreenArrowColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_OffscreenArrowTransparency = 0,
	ESPVisuals_OffscreenArrowFilled = false,
	ESPVisuals_OffscreenArrowSize = 14,
	ESPVisuals_OffscreenArrowRadius = 300,

	ESPVisuals_SoundRings = false,
	ESPVisuals_SoundRingsColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_SoundRingsTransparency = 0,
	ESPVisuals_SoundRingsOccluded = false,
	ESPVisuals_SoundRingsDuration = 0.8,

	ESPVisuals_GrenadeTags = false,
	ESPVisuals_GrenadeTagColor = Color3.fromRGB(255, 255, 255),
	ESPVisuals_GrenadeTagTransparency = 0,
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
	Combat_CustomCrosshairFollowSpread = false,
	Combat_CustomCrosshairSpin = false,
	Combat_CustomCrosshairSpinSpeed = 3,

	Combat_CustomRagdolls = false,
	Combat_RagdollCustomEffect = false,
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
	Camera_ThirdPersonCameraCollision = true,
	Camera_ThirdPersonHideViewModel = false,
	Camera_ThirdPersonOffsetX = 0,
	Camera_ThirdPersonOffsetY = 0,
	Camera_ThirdPersonOffsetZ = 7,
	Camera_ThirdPersonShowCharacter = false,
	Camera_ThirdPersonGhostCharacter = false,
	Camera_ThirdPersonHideCharacterWhileAiming = false,

	ViewModel_WeaponChams = false,
	ViewModel_WeaponChamColor = Color3.fromRGB(100, 0, 255),
	ViewModel_WeaponChamIgnoreSightParts = true,
	ViewModel_WeaponChamType = "ForceField",
	ViewModel_WeaponChamTransparency = 0.5,

	ViewModel_ArmChams = false,
	ViewModel_ArmChamColor = Color3.fromRGB(100, 0, 255),
	ViewModel_ArmChamType = "ForceField",
	ViewModel_ArmChamTransparency = 0.5,

	ViewModel_SleeveChams = false,
	ViewModel_SleeveChamColor = Color3.fromRGB(100, 0, 255),
	ViewModel_SleeveChamType = "ForceField",
	ViewModel_SleeveChamTransparency = 0.5,

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
	WeaponMods_InstantBullet = false,
	WeaponMods_RapidFire = false,
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
	WeaponMods_MuzzleFlashSize = 1,

	HitLogs_Enabled = false,
	HitLogs_ShowDamage = false,
	HitLogs_ShowDistance = false,
	HitLogs_ShowPart = true,

	SoundOverride_ShootSound = "None",
	SoundOverride_HitSound = "None",
	SoundOverride_KillSound = "None",

	KnifeAura_Enabled = false,
	KnifeAura_Range = 10,
	KnifeAura_Delay = 0.35,
	KnifeAura_Wallbang = true,
	KnifeAura_Part = "Head",

	Movement_NoSlideCooldown = false,
	Movement_NoFallDamage = false,
	Movement_BunnyHop = false,
	Movement_Fly = false,
	Movement_FlySpeed = 16,
	Movement_Speed = false,
	Movement_SpeedAmount = 16,
	Movement_InfiniteStamina = false,

	AntiAim_Enabled = false,
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
	AntiAim_FakeLag = false,
	AntiAim_FakeLagRandomizePosition = false,
	AntiAim_FakeLagX = 0,
	AntiAim_FakeLagZ = 0,
	AntiAim_FakeLagRefreshDistance = 5,
	AntiAim_FakeLagRefreshRate = 1,

	Extras_BreakAllWindows = false,
	Extras_HopOnVotekick = false,

	ClientSessionUnlocks_AttachmentsUnlocked = false,
	ClientSessionUnlocks_CamosUnlocked = false,
	ClientSessionUnlocks_KnivesUnlocked = false
}

local Settings = {
	Advanced_MultiPointScale = 2
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

local ImDrawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/src/libs/ImDrawing.luau"))()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/src/libs/UI.luau"))()

local RoundSystemClientInterface = Module.__get("RoundSystemClientInterface")
local PlayerDataClientInterface = Module.__get("PlayerDataClientInterface")
local HudCrosshairsInterface = Module.__get("HudCrosshairsInterface")
local ReplicationInterface = Module.__get("ReplicationInterface")
local CharacterInterface = Module.__get("CharacterInterface")
local CameraInterface = Module.__get("CameraInterface")
local PlayerDataUtils = Module.__get("PlayerDataUtils")
local PublicSettings = Module.__get("PublicSettings")
local FirearmObject = Module.__get("FirearmObject")
local NetworkClient = Module.__get("NetworkClient")
local GrenadeObject = Module.__get("GrenadeObject")
local AudioSystem = Module.__get("AudioSystem")
local BulletCheck = Module.__get("BulletCheck")
local MeleeObject = Module.__get("MeleeObject")
local Effects = Module.__get("Effects")
local SolvePolynomial = Module.__get("solve")

local GetActiveWeaponController = Module.__get("WeaponControllerInterface").getActiveWeaponController
local NetworkClientSend = NetworkClient.send
local GetLocalCharacter = CharacterInterface.getCharacterObject
local GetActiveCamera = CameraInterface.getActiveCamera
local PlayGameSound = AudioSystem.play
local GetPlayerStatusEntry = Module.__get("PlayerStatusInterface").getEntry
local OperateOnAllEntries = ReplicationInterface.operateOnAllEntries
local MuzzleFlash = Effects.muzzleflash
local Crosshair = Module.__get("HudScreenGui").getScreenGui().Main.DisplayCrosshairs
local GetTime = Module.__get("GameClock").getTime

local BulletLifetime = PublicSettings.bulletLifeTime
local BulletAcceleration = PublicSettings.bulletAcceleration

local CachedPlayers, MovementCache, MovementCached = {}, table.create(Module.Players.MaxPlayers), {}
local function RefreshCache()
	local Players, Now = {}, os.clock()
	local BacktrackTime = Now - Aiming.RageBot_BacktrackTime * 0.001
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

			for Index = #Cache, 15, -1 do
				if Cache[Index].Time >= BacktrackTime then
					break
				end
				Cache[Index] = nil
			end

			local CharacterHash = Entry._thirdPersonObject._characterModelHash
			table.insert(Cache, 1, {
				Position = Entry._receivedPosition, Head = CharacterHash.Head.CFrame, Torso = CharacterHash.Torso.CFrame, Time = Now,
				["Left Arm"] = CharacterHash["Left Arm"].CFrame, ["Right Arm"] = CharacterHash["Right Arm"].CFrame,
				["Left Leg"] = CharacterHash["Left Leg"].CFrame, ["Right Leg"] = CharacterHash["Right Leg"].CFrame
			})
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
RefreshCache()

local function GetActiveWeapon()
	local ActiveWeaponController = GetActiveWeaponController()
	return ActiveWeaponController and ActiveWeaponController:getActiveWeapon()
end

local LocalHead
local function GetLocalPosition()
	if not LocalHead or not LocalHead.Parent then
		local Character = GetLocalCharacter()
		LocalHead = Character and Character._characterModel:FindFirstChild("Head")
	end
	return LocalHead and LocalHead.Position or Camera.CFrame.Position
end

local ViewportSize = Camera.ViewportSize
local ViewportSizeX, ViewportSizeY = ViewportSize.X, ViewportSize.Y
local ScreenXCenter, ScreenYCenter = ViewportSizeX * 0.5, ViewportSizeY * 0.5
local ScreenTop, ScreenCenter, ScreenBottom = Vector2.new(ScreenXCenter, 0), Vector2.new(ScreenXCenter, ScreenYCenter), Vector2.new(ScreenXCenter, ViewportSizeY)
local TwoPi, Quarter = math.pi * 2, math.pi * 0.5

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	ViewportSize = Camera.ViewportSize
	ViewportSizeX = ViewportSize.X
	ViewportSizeY = ViewportSize.Y
	ScreenXCenter = ViewportSizeX * 0.5
	ScreenYCenter = ViewportSizeY * 0.5
	ScreenTop = Vector2.new(ScreenXCenter, 0)
	ScreenCenter = Vector2.new(ScreenXCenter, ScreenYCenter)
	ScreenBottom = Vector2.new(ScreenXCenter, ViewportSizeY)
end)

local function WorldToViewportPoint(Position)
	local Screen, OnScreen = Camera:WorldToViewportPoint(Position)
	return Vector2.new(Screen.X, Screen.Y), OnScreen
end

local function GetRecoilPosition()
	local Weapon = GetActiveWeapon()
	if not Weapon or not Weapon._barrelPart or not GetLocalCharacter() then
		return ScreenCenter
	end

	local Direction = Camera.CFrame:VectorToObjectSpace(Weapon:getBarrelCFrame().LookVector)
	local Scale = ScreenYCenter / (math.tan(math.rad(Camera.FieldOfView) * 0.5) * math.max(-Direction.Z, 0.001))
	return Vector2.new(math.clamp(ScreenXCenter + Direction.X * Scale, 0, ViewportSizeX), math.clamp(ScreenYCenter - Direction.Y * Scale, 0, ViewportSizeY))
end

local PartNames, PartSizes, LastFire = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, {
	Head = Vector3.new(1, 0.5, 0.5), Torso = Vector3.new(1, 1, 0.5),
	["Left Arm"] = Vector3.new(0.5, 1, 0.5),
	["Right Arm"] = Vector3.new(0.5, 1, 0.5),
	["Left Leg"] = Vector3.new(0.5, 1, 0.5),
	["Right Leg"] = Vector3.new(0.5, 1, 0.5),
}, -math.huge
local CrosshairDirections = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}

local TransparentRaycastExcluded = {}
local function TransparentRaycast(Origin, Direction)
	for Index = 1, 5 do
		TransparentRaycastExcluded[Index] = AimingRaycastParamsFilterDescendantsInstances[Index]
	end

	local Excluded, OriginalDirection = 5, Direction
	for Step = 1, 8 do
		for Index = Excluded + 1, #TransparentRaycastExcluded do
			TransparentRaycastExcluded[Index] = nil
		end

		TransparentRaycastParams.FilterDescendantsInstances = TransparentRaycastExcluded
		local Result = workspace:Raycast(Origin, Direction, TransparentRaycastParams)
		if not Result then
			return
		end

		local Hit = Result.Instance
		if Step < 8 and (Hit.Transparency > 0.9 or Hit.Name == "Window") then
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

local GoldenAngle, MultiPointCache = 2.399963229728653, nil
local CanSeeFrameCounter, CanSeeCache, CanSeeSizes = 0, {}, {PartSizes.Head, PartSizes.Torso, PartSizes["Left Arm"]}

local function CacheMultiPoint()
	local Directions, Offsets = {}, {}
	for Index = 1, Settings.Advanced_MultiPointScale do
		local Y = (2 * Index - 1) / Settings.Advanced_MultiPointScale - 1
		Directions[Index] = Vector3.new(math.cos((Index - 1) * GoldenAngle) * math.sqrt(1 - Y * Y), Y, -math.sin((Index - 1) * GoldenAngle) * math.sqrt(1 - Y * Y))
	end

	for _,Size in ipairs(CanSeeSizes) do
		Offsets[Size] = {{}, {}}
		for Index = 1, Settings.Advanced_MultiPointScale do
			Offsets[Size][1][Index], Offsets[Size][2][Index] = Directions[Index] * Size * 0.5, Directions[Index] * Size
		end
	end
	MultiPointCache = {Directions = Directions, Offsets = Offsets}
end
CacheMultiPoint()

local function CanSee(Part, Name, CenterOnly)
	local Center = CanSeeCache[Part]
	if Center == nil then
		local Origin = Camera.CFrame.Position
		Center = not TransparentRaycast(Origin, Part.Position - Origin)
		CanSeeCache[Part] = Center
	end

	if CenterOnly or Center then
		return Center
	end

	local PartCFrame = Part.CFrame
	local Origin = Camera.CFrame.Position
	local Delta = PartCFrame:VectorToObjectSpace(Origin - Part.Position)
	local Magnitude = Delta.Magnitude

	if Magnitude <= 1e-6 then
		return
	end

	local Directions, Offsets, Scale = MultiPointCache.Directions, MultiPointCache.Offsets[PartSizes[Name]], Settings.Advanced_MultiPointScale
	for Index = 2, Magnitude <= 2.327906827477306 and 1 or 2, -1 do
		local Positions = Offsets[Index]
		for _Index = 1, Scale do
			if Directions[_Index]:Dot(Delta) > 0 and not TransparentRaycast(Origin, PartCFrame * Positions[_Index] - Origin) then
				return true
			end
		end
	end
end

local function ns__hooktablefunction(Table, Index, Replacement, Helper)
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

for _,ObjectModule in ipairs({FirearmObject, GrenadeObject, MeleeObject}) do
	local IsFirearmObject = ObjectModule == FirearmObject
	local IsGrenadeObject = ObjectModule == GrenadeObject

	ns__hooktablefunction(ObjectModule, "step", function(Original, self, ...)
		Original(self, ...)

		local CustomOffset = Visuals.ViewModel_CustomOffset
		local CustomRotation = Visuals.ViewModel_CustomRotation
		local CustomRoll = Visuals.ViewModel_CustomRoll

		if not (CustomOffset or CustomRotation or CustomRoll) then
			return
		end

		local AimBlend = 0
		if IsFirearmObject then
			for _,Sight in self._activeAimStats do
				AimBlend += Sight.sightaimspring.p
			end
		end
		AimBlend = math.clamp(1 - AimBlend, 0, 1)

		if AimBlend <= 0 then
			return
		end

		local Offset = CFrame.identity

		if CustomOffset then
			Offset *= CFrame.new(Visuals.ViewModel_OffsetX, Visuals.ViewModel_OffsetY, Visuals.ViewModel_OffsetZ)
		end

		if CustomRotation then
			Offset *= CFrame.Angles(math.rad(Visuals.ViewModel_RotationX), math.rad(Visuals.ViewModel_RotationY), math.rad(Visuals.ViewModel_RotationZ))
		end

		Offset = CFrame.identity:Lerp(Offset, AimBlend)

		local CharacterObject = self._characterObject
		if CustomRoll then
			local CameraOffset = CharacterObject._rootPartClone.CFrame:ToObjectSpace(Camera.CFrame)
			Offset *= CameraOffset * CFrame.Angles(0, 0, math.rad(Visuals.ViewModel_Roll) * AimBlend) * CameraOffset:Inverse()
		end

		self._mainWeld.C0 *= Offset
		CharacterObject._leftWeld.C0 *= Offset
		CharacterObject._rightWeld.C0 *= Offset
	end)

	ns__hooktablefunction(ObjectModule, "getAnimLength", function(Original, self, Name, ...)
		if Miscellaneous.WeaponMods_InstantEquipUnequip and string.find(string.lower(Name), "equip") then
			return 0
		end
		return Original(self, Name, ...)
	end)

	ns__hooktablefunction(ObjectModule, "getWeaponStat", function(Original, self, Stat, ...)
		if (Stat == "unequiptime" or Stat == "equiptime") and Miscellaneous.WeaponMods_InstantEquipUnequip then
			return 0
		elseif IsGrenadeObject and Stat == "uncookable" and Miscellaneous.WeaponMods_UncookableGrenade then
			return true
		elseif IsFirearmObject then
			if (Stat == "unaimspeed" or Stat == "unmagnifyspeed") and Miscellaneous.WeaponMods_InstantAim then
				return 100
			elseif Stat == "variablechoke" or Stat == "spread" or Stat == "choke" or Stat == "aimchoke" or Stat == "hipchoke" then
				local Value = Miscellaneous.WeaponMods_SpreadAdjustment * 0.01
				if Value == 0 then
					return 0
				elseif Value < 1 then
					return (Original(self, Stat, ...) or 0) * Value
				end
			end
		end
		return Original(self, Stat, ...)
	end)

	if IsFirearmObject then
		ns__hooktablefunction(ObjectModule, "getFirerate", function(Original, self, ...)
			return Original(self, ...) * (Miscellaneous.WeaponMods_RapidFire and 1.5 or 1)
		end)

		for _,Name in ipairs({"shoot", "fireRound"}) do
			ns__hooktablefunction(ObjectModule, Name, function(Original, self, ...)
				if Aiming.RageBot_Enabled and Aiming.RageBot_BlockShooting then
					self._auto, self._burst = false, 0
					return
				end
				return Original(self, ...)
			end)
		end

		ns__hooktablefunction(ObjectModule, "computeWalkSway", function(Original, self, ...)
			return Miscellaneous.WeaponMods_NoWalkSway and Original(self, 0, 0) or Original(self, ...)
		end)

		ns__hooktablefunction(ObjectModule, "computeGunSway", function(Original, self, ...)
			return Miscellaneous.WeaponMods_NoWeaponSway and CFrame.identity or Original(self, ...)
		end)

		ns__hooktablefunction(ObjectModule, "getFiremode", function(Original, self, ...)
			return Miscellaneous.WeaponMods_AutomaticGun or Original(self, ...)
		end)

		ns__hooktablefunction(ObjectModule, "getActiveAimStat", function(Original, self, Stat, ...)
			if (Stat == "aimspeed" or Stat == "unaimspeed" or Stat == "magnifyspeed") and Miscellaneous.WeaponMods_InstantAim then
				return 100
			elseif Stat == "swayamp" and Miscellaneous.WeaponMods_NoScopeSway then
				return 0
			end
			return Original(self, Stat, ...)
		end)

		ns__hooktablefunction(ObjectModule, "reload", function(Original, self)
			if self:isEquipping() or self:isUnequipping() or self:isChambering() then
				return
			end

			if Miscellaneous.WeaponMods_InstantReload then
				self:applyReloadCount(self._weaponData.magsize)
				return self:fireInput("reloadFinish", GetTime())
			end

			return Original(self)
		end)
	elseif IsGrenadeObject then
		ns__hooktablefunction(ObjectModule, "modelSway", function(Original, self, ...)
			if Miscellaneous.WeaponMods_NoWeaponSway then
				return CFrame.identity
			end
			return Original(self, ...)
		end)
	else
		ns__hooktablefunction(ObjectModule, "meleeSway", function(Original, self, ...)
			if Miscellaneous.WeaponMods_NoWeaponSway then
				return CFrame.identity
			end
			return Original(self, ...)
		end)
	end

	if not IsFirearmObject then
		ns__hooktablefunction(ObjectModule, "walkSway", function(Original, self, ...)
			if Miscellaneous.WeaponMods_NoWalkSway then
				return CFrame.identity
			end
			return Original(self, ...)
		end)
	end
end

ns__hooktablefunction(Module.__get("RecoilSprings"), "applyImpulse", function(Original, self, Offset, Scale)
	local Value = Miscellaneous.WeaponMods_RecoilAdjustment * 0.01
	if Value == 0 then
		return
	elseif Value < 1 then
		return Original(self, Offset, (Scale or 1) * Value)
	end
	return Original(self, Offset, Scale)
end)

ns__hooktablefunction(Module.__get("CharacterObject"), "preSimulationStep", function(Original, self, DeltaTime)
	Original(self, DeltaTime)

	if Miscellaneous.Movement_Speed then
		local RootPart = self._rootPart
		local Horizontal = Vector3.new(RootPart.Velocity.X, 0, RootPart.Velocity.Z)
		local Speed = Horizontal.Magnitude
		if Speed > 0.5 then
			RootPart.CFrame += Horizontal.Unit * (Miscellaneous.Movement_SpeedAmount - Speed) * DeltaTime
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

		local RootPart = self._rootPart
		RootPart.Velocity = Direction
		RootPart.CFrame += RootPart.Velocity * DeltaTime
	end
end)

ns__hooktablefunction(Module.__get("CharacterObject"), "takeStamina", function(Original, self, ...)
	if Miscellaneous.Movement_InfiniteStamina then
		self:setStamina(1)
		return 1
	end
	return Original(self, ...)
end)

local RaycastStep = 1/60
local TicketCache = {}
local BulletTicket = 0

local FakeLag = {}
local CycleFrames, SpinTime = 0, 0
local function GetAntiAimAngles(Angles)
	local Pitch, Yaw = Angles.X, Angles.Y
	local ClockTime = os.clock()
	CycleFrames += 1

	if Miscellaneous.AntiAim_Pitch then
		local Mode = Miscellaneous.AntiAim_PitchMode
		if Mode == "Custom - Relative" then
			Pitch = math.clamp(Pitch + math.rad(Miscellaneous.AntiAim_PitchAmount), -Quarter, Quarter)
		elseif Mode == "Custom - Absolute" then
			Pitch = math.clamp(math.rad(Miscellaneous.AntiAim_PitchAmount), -Quarter, Quarter)
		elseif Mode == "Rotate" then
			Pitch = math.sin(ClockTime * (Miscellaneous.AntiAim_PitchSpeed * 0.5)) * Quarter
		elseif Mode == "Random" then
			Pitch = math.random() * math.pi - Quarter
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
			Yaw = CycleFrames % Speed >= (Speed * 0.5) and 2 or -2
		end
	end

	if Miscellaneous.AntiAim_Jitter then
		Yaw += (math.random() * 2 - 1) * math.rad(Miscellaneous.AntiAim_JitterAmount) * 0.25
	end

	if Miscellaneous.AntiAim_Spin then
		if SpinTime == 0 then
			SpinTime = ClockTime
		end
		Yaw += (ClockTime - SpinTime) * math.rad(Miscellaneous.AntiAim_SpinSpeed) * (Miscellaneous.AntiAim_SpinDirection == "Left" and 1 or -1)
	else
		SpinTime = 0
	end

	return Vector3.new(Pitch, Yaw, Angles.Z) * 0.99
end

local SphereHandleAdornment = ns__cloneref(Instance.new("SphereHandleAdornment"))
SphereHandleAdornment.Radius = 0.25
SphereHandleAdornment.Color3 = Color3.fromRGB(255, 50, 50)
SphereHandleAdornment.ZIndex = 5
SphereHandleAdornment.AlwaysOnTop = true
SphereHandleAdornment.Adornee = Terrain
SphereHandleAdornment.Parent = CoreGui

ns__hooktablefunction(PlayerDataUtils, "getUnlocksData", function(Helper, Original, PlayerData)
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

ns__hooktablefunction(PlayerDataUtils, "ownsWeapon", function(Helper, Original, Player, WeaponName)
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
end

for _,Value in next, (getgc or get_gc)(true) do
	if type(Value) == "table" and rawget(Value, "correctposition") then
		local _correctposition = Value.correctposition
		Value.correctposition = function(Position, ...)
			local Humanoid = GetLocalHumanoid()
			if Humanoid and (
				Miscellaneous.Movement_Speed or Miscellaneous.Movement_Fly or Miscellaneous.Movement_BunnyHop
			) and Humanoid.FloorMaterial == Enum.Material.Air then
				local Hit = workspace:Raycast(GetLocalPosition(), Vector3.new(0, -1000, 0), GrenadeRaycastParams)
				if Hit then
					Position = Hit.Position + Vector3.new(0, 2, 0)
				end
			end
			FakeLag.LastSentPosition = Position
			return _correctposition(Position, ...)
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
	task.spawn(function()
		local FunctionEnvironment = getfenv(CameraInterface.setCameraType)
		FunctionEnvironment.warn = function() end
		FunctionEnvironment.print = function() end
	end)

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
		return PlaySoundId(CustomSounds[ShootSound], Priority, Volume, ...)
	end

	return PlaySoundId(AssetId, Priority, Volume, ...)
end

ns__hooktablefunction(Module.__get("MainCameraObject"), "step", function(Original, self, DeltaTime, ...)
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

ns__hooktablefunction(Module.__get("ScreenCull"), "step", function(Original)
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
	end

	if Visuals.Camera_CustomFOV then
		local ApplyToAim = Visuals.Camera_ApplyToAim
		if not ApplyToAim then
			local ActiveWeapon = GetActiveWeapon()
			ApplyToAim = not (ActiveWeapon and ActiveWeapon._aiming)
		end

		if ApplyToAim then
			Camera.FieldOfView = Visuals.Camera_FOVValue
		end
	end

	return Original(Camera.CFrame, Camera.ViewportSize, Camera.FieldOfView)
end)

local function OnDeadBody(Body, Update)
	if not Visuals.Combat_CustomRagdolls then
		return
	end

	if Visuals.Combat_RagdollCustomEffect and not Update then
		local Torso, Effect = Body.Torso, Visuals.Combat_RagdollEffect

		if Effect == "Launch" then
			Torso.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), Visuals.Combat_RagdollEffectLaunchForce, math.random(-15, 15))
		elseif Effect == "Fling" then
			local Force = Visuals.Combat_RagdollEffectFlingForce
			Torso.AssemblyLinearVelocity, Torso.AssemblyAngularVelocity = Vector3.new(math.random(-Force, Force), math.random(0, Force), math.random(
				-Force, Force
			)), Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))
		else
			local Mass = 0
			for _,Part in Body:QueryDescendants("BasePart") do
				Mass += Part:GetMass()
			end
			local Attachment = ns__cloneref(Instance.new("Attachment", Torso))
			Attachment.Name = "ns__RagdollFloat"
			Attachment.WorldPosition = Torso.AssemblyCenterOfMass
			local Velocity = ns__cloneref(Instance.new("LinearVelocity"))
			Velocity.Attachment0 = Attachment
			Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
			Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
			Velocity.LineDirection = Vector3.yAxis
			Velocity.LineVelocity = Visuals.Combat_RagdollEffectFloatSpeed
			Velocity.ForceLimitsEnabled = true
			Velocity.MaxForce = Mass * workspace.Gravity * 2
			Velocity.Parent = Attachment
		end
	end

	if Visuals.Combat_RagdollGhost then
		local Color = Visuals.Combat_RagdollGhostColor
		local VertexColor = Vector3.new(Color.R, Color.G, Color.B)
		for _,Object in ipairs(Body:QueryDescendants("BasePart, SpecialMesh, Texture, Decal")) do
			if Object:IsA("BasePart") then
				Object.Color = Color
				Object.Material = Enum.Material.ForceField
				Object.Transparency = 0
				if Object:IsA("MeshPart") then
					Object.TextureID = ""
				end
			elseif Object:IsA("SpecialMesh") then
				local MeshId = Object.MeshId
				if MeshId == "rbxassetid://4049240078" then
					Object.Parent.Transparency = 1
				else
					if MeshId == "rbxassetid://6179256256" then
						Object.TextureId = "rbxassetid://12325350352"
					end
					Object.VertexColor = VertexColor
				end
			else
				Object.Transparency = 1
			end
		end
	end
end

DeadBodyFolder.ChildAdded:Connect(OnDeadBody)

ns__hooktablefunction(HudCrosshairsInterface, "enable", function(Original)
	Original()
	if Visuals.Combat_CustomCrosshair and IsSpawned then
		Crosshair.Visible = false
	end
end)

local CrosshairModule = {SpinAngle = 0, IsGameCrosshairHidden = false}
function CrosshairModule:Update(DeltaTime)
	local Hide = Visuals.Combat_CustomCrosshair and IsSpawned
	if Hide ~= self.IsGameCrosshairHidden then
		self.IsGameCrosshairHidden = Hide
		if Hide then
			Crosshair.Visible = false
		elseif IsSpawned then
			HudCrosshairsInterface.enable()
		end
	end

	if not Hide then
		return
	end

	local ActiveWeapon = GetActiveWeapon()
	if ActiveWeapon and ActiveWeapon._aiming then
		return
	end

	local Gap = Visuals.Combat_CustomCrosshairGap
	if Visuals.Combat_CustomCrosshairFollowSpread then
		Gap += HudCrosshairsInterface.getCrossSize()
	end

	if Visuals.Combat_CustomCrosshairSpin then
		self.SpinAngle = (self.SpinAngle + DeltaTime * Visuals.Combat_CustomCrosshairSpinSpeed) % TwoPi
	end

	local Size, Thickness, Color = Visuals.Combat_CustomCrosshairSize, Visuals.Combat_CustomCrosshairThickness, Visuals.Combat_CustomCrosshairColor
	local Angle = Visuals.Combat_CustomCrosshairSpin and self.SpinAngle or 0
	local Cosine, Sine = math.cos(Angle), math.sin(Angle)
	local Center = Visuals.Combat_CustomCrosshairFollowRecoil and GetRecoilPosition() or ScreenCenter
	for Index = 1, 4 do
		local Direction, Offset = CrosshairDirections[Index], Gap + Size
		local Direction1, Direction2 = Direction[1], Direction[2]
		local Direction3 = Vector2.new(Direction1 * Cosine - Direction2 * Sine, Direction1 * Sine + Direction2 * Cosine)
		ImDrawing.Line(Center + Direction3 * Gap, Center + Direction3 * Offset, Color, Thickness, 1)
	end
end

local ViewModelModule = {Cache = setmetatable({}, {__mode = "k"}), Parts = setmetatable({}, {__mode = "k"}), Sleeves = setmetatable({}, {__mode = "k"})}
function ViewModelModule:Apply(Model, Part)
	if Part.Name == "Sleeves" then
		self.Sleeves[Part] = true
	end

	if Part:IsA("BasePart") or Part:IsA("Decal") then
		table.insert(self.Parts[Model], Part)
		self:RefreshPart(Model, Part)
	end
end

function ViewModelModule:RefreshPart(Model, Part)
	local IsSleeve = self.Sleeves[Part]
	local Character, Weapon = GetLocalCharacter(), GetActiveWeapon()
	local IsArmModel = Character and (Model == Character._leftArmModel or Model == Character._rightArmModel)
	Part.LocalTransparencyModifier = ((IsArmModel or (
		Weapon and Model == Weapon._weaponModel
	)) and Visuals.Camera_ThirdPerson and Visuals.Camera_ThirdPersonHideViewModel) and 1 or 0
	if not Part:IsA("BasePart") then
		return
	end

	local Name, Enabled, Color, Material, Transparency = Part.Name, nil, nil, nil, nil
	if IsArmModel and IsSleeve then
		Enabled = Visuals.ViewModel_SleeveChams
		Color = Visuals.ViewModel_SleeveChamColor
		Material = Visuals.ViewModel_SleeveChamType
		Transparency = Visuals.ViewModel_SleeveChamTransparency
	elseif IsArmModel then
		Enabled = Visuals.ViewModel_ArmChams
		Color = Visuals.ViewModel_ArmChamColor
		Material = Visuals.ViewModel_ArmChamType
		Transparency = Visuals.ViewModel_ArmChamTransparency
	else
		Enabled = Visuals.ViewModel_WeaponChams
		Color = Visuals.ViewModel_WeaponChamColor
		Material = Visuals.ViewModel_WeaponChamType
		Transparency = Visuals.ViewModel_WeaponChamTransparency
		if Weapon and Model == Weapon._weaponModel then
			local ReversePartMappings = Weapon._reversePartMappings
			Name = ReversePartMappings and ReversePartMappings[Name] or Name
			if Enabled and Visuals.ViewModel_WeaponChamIgnoreSightParts then
				Enabled = Weapon._transparencyData[Part] ~= 1
				if Enabled then
					if Weapon._sightObjects then
						for _,Sight in Weapon._sightObjects do
							if table.find(Sight.Hard, Part) or table.find(Sight.Default, Part) then
								Enabled = false
								break
							end
						end
					end

					if Weapon._activeAimStats then
						for _,Stats in Weapon._activeAimStats do
							local Sight = Stats.sightObject
							if Part == Stats.sightpart or Part == Stats.aperturesightpart or Sight and (Part == Sight._lenspart or Sight._aperturelens and Part == Sight._aperturelens.model) then
								Enabled = false
								break
							end
						end
					end
				end
			end
		end
	end

	if IsSleeve then
		for _,Child in ipairs(Part:GetChildren()) do
			if Child:IsA("Texture") or Child:IsA("Decal") then
				local Cached = self.Cache[Child]
				if Enabled then
					if not Cached then
						self.Cache[Child] = {Transparency = Child.Transparency}
					end
					Child.Transparency = 1
				elseif Cached then
					Child.Transparency = Cached.Transparency
					self.Cache[Child] = nil
				end
			end
		end
	end

	if not IsArmModel and (Name == "Handle" or Name == "Flame") then
		Part.Transparency = 1
	elseif Enabled and Name ~= "Trigger" and (IsSleeve or Part.ClassName ~= "Part") then
		local Cache, IsUnionOperation = self.Cache, Part:IsA("UnionOperation")
		if not Cache[Part] then
			Cache[Part] = {Material = Part.Material, Transparency = Part.Transparency, Color = Part.Color, UsePartColor = IsUnionOperation and Part.UsePartColor}
		end

		if IsUnionOperation then
			Part.UsePartColor = true
		end

		Part.Material = Enum.Material[Material]
		Part.Color = Color
		Part.Transparency = Material == "ForceField" and 0 or Transparency
	else
		local Cache = self.Cache
		local Cached = Cache[Part]
		if Cached then
			Part.Material = Cached.Material
			Part.Transparency = Cached.Transparency
			Part.Color = Cached.Color
			if Part:IsA("UnionOperation") then
				Part.UsePartColor = Cached.UsePartColor
			end
			Cache[Part] = nil
		end
	end
end

function ViewModelModule:Refresh()
	task.defer(function()
		for Model, ModelParts in next, self.Parts do
			if Model.Parent then
				for _,Part in next, ModelParts do
					self:RefreshPart(Model, Part)
				end
			end
		end

		local Weapon = Visuals.ViewModel_WeaponChamIgnoreSightParts and GetActiveWeapon()
		if Weapon and Weapon._sightObjects then
			Weapon:updateScope()
		end
	end)
end

function ViewModelModule:OnCameraChildAdded(Model)
	if not Model:IsA("Model") then
		return
	end

	local IsNew = not self.Parts[Model]
	self.Parts[Model] = {}

	for _,Part in ipairs(Model:QueryDescendants("BasePart, Decal, #Sleeves")) do
		self:Apply(Model, Part)
	end

	if not IsNew then
		return
	end

	Model.DescendantAdded:Connect(function(Part)
		self:Apply(Model, Part)
	end)

	Model.Destroying:Once(function()
		self.Parts[Model] = nil
	end)
end

local FakeReplicationObject
local LastHit = {}
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
	local Now = os.clock()
	if Now < self.NextHit then
		return
	end

	local Weapon = GetActiveWeapon()
	if not Weapon or Weapon:getWeaponType() ~= "Melee" then
		return
	end

	local Origin, Name = GetLocalPosition(), Miscellaneous.KnifeAura_Part
	Name = Name == "Random" and (math.random(2) == 1 and "Head" or "Torso") or Name
	local Range, Wallbang, Time = Miscellaneous.KnifeAura_Range, Miscellaneous.KnifeAura_Wallbang, nil
	for Player, Entry in next, CachedPlayers do
		if not Entry._isEnemy then
			continue
		end

		local Position = Entry._thirdPersonObject._characterModelHash[Name].Position
		local Offset = Position - Origin
		if Offset.Magnitude >= Range or (not Wallbang and TransparentRaycast(Origin, Offset)) then
			continue
		end

		if not Time then
			self.NextHit = Now + Miscellaneous.KnifeAura_Delay
			NetworkClientSend(NetworkClient, "stab")
			Time, LastFire = GetTime(), os.clock()
		end

		LastHit[Player] = true
		NetworkClientSend(NetworkClient, "knifehit", Player, Name, Position, Time)
	end
end

local ESPModule = {
	Highlights = {},
	Visible = {},
	SoundRings = {},
	Grenades = {},
	HelmetCache = {}
}

function ESPModule:ClearHighlight(Player)
	local Highlight = self.Highlights[Player]
	if Highlight then
		Highlight:Destroy()
	end
	self.Highlights[Player], self.Visible[Player] = nil, nil
end

function ESPModule:ClearSoundRings(Player)
	local SoundRings = self.SoundRings[Player]
	if SoundRings then
		for _,Ring in ipairs(SoundRings) do
			Ring.Adornment:Destroy()
		end
		self.SoundRings[Player] = nil
	end
end

function ESPModule:Clear(Player)
	self:ClearHighlight(Player)
	self:ClearSoundRings(Player)
end

local ESPSkeletonBones, ESPBoxSegments, ESPEdges = {{1, 2}, {1, 3}, {1, 4}, {4, 10}, {1, 5}, {5, 11}, {3, 6}, {6, 8}, {3, 7}, {7, 9}}, {
	{0, 0, 1, 0}, {0, 0, 0, 1}, {1, 0, -1, 0}, {1, 0, 0, 1}, {0, 1, 0, -1}, {0, 1, 1, 0}, {1, 1, -1, 0}, {1, 1, 0, -1}
}, {{1, 2}, {1, 3}, {2, 4}, {3, 4}, {5, 6}, {5, 7}, {6, 8}, {7, 8}, {1, 5}, {2, 6}, {3, 7}, {4, 8}}
local ESPCornerCache, ESPDepthCache, ESPBoundsCache = table.create(8), table.create(8), table.create(5)
local ESPJointCache, ESPScreenCache, HeadTagCache = table.create(11), table.create(11), {}

local function GetWeldPosition(Weld)
	return (Weld.part0.CFrame * Weld.C0).Position
end

local function CacheBounds(Position)
	local Screen = Camera:WorldToViewportPoint(Position)
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

local function CachePartBounds(PartCFrame, LookVector, CameraPosition, SizeX, SizeY, SizeZ)
	local Direction = PartCFrame:VectorToObjectSpace(LookVector)
	local Center = (PartCFrame.Position - CameraPosition):Dot(LookVector)
	local Radius = math.abs(Direction.X) * SizeX + math.abs(Direction.Y) * SizeY + math.abs(Direction.Z) * SizeZ
	if Center + Radius < 0.5 then
		return
	end

	local NeedsClipping = Center - Radius < 0.5
	local Count = 0
	for X = -SizeX, SizeX, SizeX * 2 do
		for Y = -SizeY, SizeY, SizeY * 2 do
			for Z = -SizeZ, SizeZ, SizeZ * 2 do
				local Offset = Vector3.new(X, Y, Z)
				local Position = PartCFrame * Offset
				if NeedsClipping then
					Count += 1
					local Depth = Center + Offset:Dot(Direction)
					ESPCornerCache[Count] = Position
					ESPDepthCache[Count] = Depth
					if Depth >= 0.5 then
						CacheBounds(Position)
					end
				else
					CacheBounds(Position)
				end
			end
		end
	end

	if NeedsClipping then
		for _,Edge in ipairs(ESPEdges) do
			local A, B = Edge[1], Edge[2]
			local DepthA, DepthB = ESPDepthCache[A], ESPDepthCache[B]
			if (DepthA < 0.5) ~= (DepthB < 0.5) then
				CacheBounds(ESPCornerCache[A]:Lerp(ESPCornerCache[B], (0.5 - DepthA) / (DepthB - DepthA)))
			end
		end
	end
end

function ESPModule:Update(LocalHeadPosition, Now)
	local MasterSwitch = Visuals.ESPVisuals_MasterSwitch and not MenuScreenGui.Enabled
	local HighlightChams = MasterSwitch and Visuals.ESPVisuals_HighlightChams
	local SoundRings = MasterSwitch and Visuals.ESPVisuals_SoundRings

	for Player, Highlight in next, self.Highlights do
		if not CachedPlayers[Player] then
			self:ClearHighlight(Player)
		elseif not HighlightChams then
			Highlight.Enabled = false
		end
	end

	for Player in next, self.SoundRings do
		if not SoundRings or not CachedPlayers[Player] then
			self:ClearSoundRings(Player)
		end
	end

	if not MasterSwitch or not Visuals.ESPVisuals_GrenadeTags then
		table.clear(self.Grenades)
		if not MasterSwitch then
			return
		end
	end

	local Transparency, ChamRendering = Visuals.ESPVisuals_HighlightChamTransparency, Visuals.ESPVisuals_HighlightChamRendering
	local ChamFillTransparency = ChamRendering.Fill and Transparency or 1
	local ChamOutlineTransparency = ChamRendering.Outline and Transparency or 1
	local MaxDistance = Visuals.ESPVisuals_MaxDistance
	if Visuals.ESPVisuals_GrenadeTags then
		local UseName, Color, Size, Opacity = Visuals.ESPVisuals_GrenadeTagUseName, Visuals.ESPVisuals_GrenadeTagColor, Visuals.ESPVisuals_GrenadeTagSize, 1 - Visuals.ESPVisuals_GrenadeTagTransparency
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
				continue
			end

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
				local Time = Second.t - First.t

				if Time <= 0 then
					Estimated = Second.p
				else
					local ForwardWeight = (Age - First.t) / Time
					local BackwardWeight = 1 - ForwardWeight
					Estimated = BackwardWeight * BackwardWeight * (
						BackwardWeight + 3 * ForwardWeight
					) * First.p + Time * BackwardWeight * BackwardWeight * ForwardWeight * First.v - Time * BackwardWeight * ForwardWeight * ForwardWeight * Second.v + ForwardWeight * ForwardWeight * (
						ForwardWeight + 3 * BackwardWeight
					) * Second.p
				end
			end

			if (Estimated - LocalHeadPosition).Magnitude > MaxDistance then
				continue
			end

			local Screen, OnScreen = WorldToViewportPoint(Estimated)
			if OnScreen then
				ImDrawing.Text(Screen, UseName and string.format("%s [%.1f]", Entry.Name, Fuse - Age) or string.format("GRENADE [%.1f]", Fuse - Age), Color, Size, Opacity)
			end
		end
	end

	if Visuals.ESPVisuals_PerformanceMode and CanSeeFrameCounter % 4 == 3 then
		return
	end

	local Boxes = Visuals.ESPVisuals_Boxes
	local HeadTags = Visuals.ESPVisuals_HeadTags
	local Healthbars = Visuals.ESPVisuals_Healthbars
	local Skeletons = Visuals.ESPVisuals_Skeletons
	local Tracers = Visuals.ESPVisuals_Tracers
	local OffscreenArrows = Visuals.ESPVisuals_OffscreenArrows
	local StaticElements = Visuals.ESPVisuals_HeadTagStaticElements
	local StatusElements = Visuals.ESPVisuals_HeadTagStatusElements
	local NeedsScreenBounds = Boxes or HeadTags or Healthbars
	if not (NeedsScreenBounds or Skeletons or Tracers or OffscreenArrows or HighlightChams or SoundRings) then
		return
	end

	local CameraCFrame = Camera.CFrame
	local CameraPosition, LookVector = CameraCFrame.Position, CameraCFrame.LookVector
	local ArrowRight, ArrowForward, ArrowSize, ArrowRadius
	if OffscreenArrows then
		local RightVector = CameraCFrame.RightVector
		ArrowRight = Vector3.new(RightVector.X, 0, RightVector.Z)

		if ArrowRight.Magnitude < 0.001 then
			ArrowRight = Vector3.new(-LookVector.Z, 0, LookVector.X)
		end

		ArrowRight = ArrowRight.Unit
		ArrowForward = Vector3.new(ArrowRight.Z, 0, -ArrowRight.X)

		local Half = math.min(ScreenXCenter, ScreenYCenter)
		ArrowSize = math.min(Visuals.ESPVisuals_OffscreenArrowSize, Half / 1.5)
		ArrowRadius = math.clamp(Visuals.ESPVisuals_OffscreenArrowRadius, 0, Half - ArrowSize * 1.2)
	end

	local Origin = Visuals.ESPVisuals_TracerOrigin
	local TracerFrom = Origin == "Top" and ScreenTop or Origin == "Center" and ScreenCenter or ScreenBottom
	for Player, Entry in next, CachedPlayers do
		if not Entry._isEnemy then
			self:Clear(Player)
			continue
		end

		local ThirdPersonObject = Entry._thirdPersonObject
		local CharacterHash = ThirdPersonObject._characterModelHash
		local Head = CharacterHash.Head
		local HeadPosition = Head.Position
		local Position = Entry:getPosition()
		local Distance = (Position - LocalHeadPosition).Magnitude
		if Distance > MaxDistance then
			local Highlight = self.Highlights[Player]
			if Highlight then
				Highlight.Enabled = false
			end

			self:ClearSoundRings(Player)
			continue
		end

		local CharacterModel, Torso = ThirdPersonObject._characterModel, CharacterHash.Torso
		local LeftArm, RightArm = CharacterHash["Left Arm"], CharacterHash["Right Arm"]
		local LeftLeg, RightLeg = CharacterHash["Left Leg"], CharacterHash["Right Leg"]

		local Rings = SoundRings and self.SoundRings[Player]
		if Rings then
			local Opacity = 1 - Visuals.ESPVisuals_SoundRingsTransparency
			for Index = #Rings, 1, -1 do
				local Ring = Rings[Index]
				if Now >= Ring.FadeStart + Ring.FadeDuration then
					Ring.Adornment:Destroy()
					table.remove(Rings, Index)
					continue
				end
				Ring.Adornment.Transparency = 1 - Opacity * Ring.Opacity * math.clamp(1 - (Now - Ring.FadeStart) / Ring.FadeDuration, 0, 1)
				Ring.Adornment.Color3 = Visuals.ESPVisuals_SoundRingsColor
				Ring.Adornment.AlwaysOnTop = not Visuals.ESPVisuals_SoundRingsOccluded
			end
		end

		if HighlightChams then
			local Visible = false
			if Visuals.ESPVisuals_HighlightChamStyle == "Visible" then
				local Start = self.Visible[Player] or 1
				for Pass = 1, 2 do
					for Offset = 0, 5 do
						local Index = (Start + Offset - 1) % 6 + 1
						local Name = PartNames[Index]
						if CanSee(CharacterHash[Name], Name, Pass == 1) then
							self.Visible[Player] = Index
							Visible = true
							break
						end
					end

					if Visible then
						break
					end
				end
			end

			local Highlight = self.Highlights[Player]
			if not Highlight then
				Highlight = ns__cloneref(Instance.new("Highlight"))
				Highlight.Parent = CoreGui
				self.Highlights[Player] = Highlight
			end

			local Color = Visible and Visuals.ESPVisuals_HighlightChamVisibleColor or Visuals.ESPVisuals_HighlightChamColor
			Highlight.Adornee = CharacterModel
			Highlight.DepthMode = Visuals.ESPVisuals_HighlightChamOccluded and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
			Highlight.Enabled = true
			Highlight.FillColor = Color
			Highlight.OutlineColor = DarkerColorCache[Color]
			Highlight.FillTransparency = ChamFillTransparency
			Highlight.OutlineTransparency = ChamOutlineTransparency
		end

		if OffscreenArrows then
			local _,HeadOnScreen = Camera:WorldToViewportPoint(Position)
			if not HeadOnScreen then
				local Offset = Position - CameraPosition
				local Direction = Vector2.new(Offset:Dot(ArrowRight), -Offset:Dot(ArrowForward))
				local Magnitude = Direction.Magnitude
				if Magnitude < 0.001 then
					Direction = Vector2.new(0, -1)
				else
					Direction /= Magnitude
				end

				local Center = ScreenCenter + Direction * ArrowRadius
				local Back = Center - Direction * (ArrowSize * 0.5)
				local Side = Vector2.new(-Direction.Y, Direction.X) * (ArrowSize * 0.6)
				ImDrawing.Triangle(Visuals.ESPVisuals_OffscreenArrowFilled, Center + Direction * ArrowSize, Back + Side, Back - Side, Visuals.ESPVisuals_OffscreenArrowColor, 1, 1 - Visuals.ESPVisuals_OffscreenArrowTransparency)

				if not NeedsScreenBounds and not Skeletons and not Tracers then
					continue
				end
			end
		end

		if NeedsScreenBounds then
			local BoxLeft, BoxTop, BoxRight, BoxBottom
			ESPBoundsCache.MinX, ESPBoundsCache.MinY = math.huge, math.huge
			ESPBoundsCache.MaxX, ESPBoundsCache.MaxY = -math.huge, -math.huge
			ESPBoundsCache.HasBounds = false

			CachePartBounds(Head.CFrame, LookVector, CameraPosition, 1, 0.5, 0.5)
			CachePartBounds(Torso.CFrame, LookVector, CameraPosition, 1, 1, 0.5)
			CachePartBounds(LeftArm.CFrame, LookVector, CameraPosition, 0.5, 1, 0.5)
			CachePartBounds(RightArm.CFrame, LookVector, CameraPosition, 0.5, 1, 0.5)
			CachePartBounds(LeftLeg.CFrame, LookVector, CameraPosition, 0.5, 1, 0.5)
			CachePartBounds(RightLeg.CFrame, LookVector, CameraPosition, 0.5, 1, 0.5)

			local Helmet = self.HelmetCache[ThirdPersonObject]
			if not Helmet then
				for _,Part in ipairs(CharacterModel[ThirdPersonObject._bodyLUT.Cosmetics]:GetChildren()) do
					if Part.MeshId == "rbxassetid://128240072851827" then
						Helmet = Part
						break
					end
				end

				self.HelmetCache[ThirdPersonObject] = Helmet
				ThirdPersonObject._destructor:add(function()
					self.HelmetCache[ThirdPersonObject] = nil
				end)
			end

			if Helmet then
				CachePartBounds(Helmet.CFrame, LookVector, CameraPosition, 0.803, 0.966, 0.803)
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
				local Health, MaxHealth
				if Healthbars or HeadTags and StaticElements.Health then
					Health, MaxHealth = Entry:getHealth()
				end

				local BoxHeight = BoxBottom - BoxTop
				if Boxes then
					local Width, Color, Thickness, Opacity = BoxRight - BoxLeft, Visuals.ESPVisuals_BoxColor, Visuals.ESPVisuals_BoxThickness, 1 - Visuals.ESPVisuals_BoxTransparency
					if Visuals.ESPVisuals_BoxStyle == "Corners" then
						local Arm = math.min(Width, BoxHeight) * 0.25
						for Index = 1, 8 do
							local Segment = ESPBoxSegments[Index]
							local Corner = Vector2.new(Segment[1] == 0 and BoxLeft or BoxRight, Segment[2] == 0 and BoxTop or BoxBottom)
							ImDrawing.Line(Corner, Corner + Vector2.new(Segment[3] * Arm, Segment[4] * Arm), Color, Thickness, Opacity)
						end
					else
						ImDrawing.Box(false, Vector2.new(BoxLeft, BoxTop), Vector2.new(Width, BoxHeight), Color, Thickness, Opacity)
					end
				end

				if HeadTags then
					local Position = Visuals.ESPVisuals_HeadTagPosition
					local Side = Position == "Left" or Position == "Right"
					table.clear(HeadTagCache)

					if StaticElements.Name then
						table.insert(HeadTagCache, Player.Name)
					end

					if StaticElements.Health then
						table.insert(HeadTagCache, ("[%d Health]"):format(math.floor(Health)))
					end

					if StaticElements.Distance then
						table.insert(HeadTagCache, ("[%d Studs]"):format(math.floor(Distance)))
					end

					local Weapon = StaticElements.Weapon and Entry:getWeaponObject()
					if Weapon then
						table.insert(HeadTagCache, "[" .. Weapon.weaponName .. "]")
					end

					if StatusElements.Aiming and ThirdPersonObject._aimSpring.t == 0 then
						table.insert(HeadTagCache, "[Aiming]")
					end

					if StatusElements.Sprinting and ThirdPersonObject._sprintSpring.t == 0 then
						table.insert(HeadTagCache, "[Sprinting]")
					end

					local Stance = ThirdPersonObject._stanceSpring.t
					if StatusElements.Crouching and Stance == 0.5 then
						table.insert(HeadTagCache, "[Crouching]")
					elseif StatusElements.Prone and Stance == 1 then
						table.insert(HeadTagCache, "[Prone]")
					end

					if #HeadTagCache > 0 then
						local Text = table.concat(HeadTagCache, Side and "\n" or " ")
						local Size = math.floor(Visuals.ESPVisuals_HeadTagSize * (0.75 + math.min(1, BoxHeight / 100) * 0.25) + 0.5)

						if Visuals.ESPVisuals_HeadTagPixelOffset then
							Size = math.max(1, Size + Visuals.ESPVisuals_HeadTagPixelOffsetSize)
						end

						local Width, Height = Library:GetTextBounds(Text, Enum.Font.Arimo, Size)
						local Padding = Healthbars and Visuals.ESPVisuals_HealthbarPosition == Position and Visuals.ESPVisuals_HealthbarWidth + 6 or 3

						local X = (BoxLeft + BoxRight) * 0.5
						local Y = Position == "Bottom" and BoxBottom + Padding or BoxTop - Height - Padding

						if Side then
							X = Position == "Left" and BoxLeft - Padding - Width * 0.5 or BoxRight + Padding + Width * 0.5
							Y = (BoxTop + BoxBottom - Height) * 0.5
						end

						ImDrawing.Text(Vector2.new(X, Y), Text, Visuals.ESPVisuals_HeadTagColor, Size, 1 - Visuals.ESPVisuals_HeadTagTransparency)
					end
				end

				if Healthbars then
					local Position, Thickness = Visuals.ESPVisuals_HealthbarPosition, Visuals.ESPVisuals_HealthbarWidth
					local Horizontal = Position == "Top" or Position == "Bottom"
					local Length = math.max(6, Horizontal and BoxRight - BoxLeft or BoxHeight)
					local Width, Height, Opacity = Horizontal and Length or Thickness, Horizontal and Thickness or Length, 1 - Visuals.ESPVisuals_HealthbarTransparency
					local BarPosition = Vector2.new(
						Horizontal and BoxLeft or Position == "Left" and BoxLeft - Thickness - 3 or BoxRight + 3,
						Horizontal and (Position == "Top" and BoxTop - Thickness - 3 or BoxBottom + 3) or BoxTop
					)

					local Fraction = MaxHealth > 0 and math.clamp(Health / MaxHealth, 0, 1) or 0

					ImDrawing.Box(true, BarPosition, Vector2.new(Width, Height), Color3.new(0, 0, 0), 1, Opacity)
					if Fraction > 0 then
						local FillWidth = math.max(1, Horizontal and math.floor((Width - 2) * Fraction) or Width - 2)
						local FillHeight = math.max(1, Horizontal and Height - 2 or math.floor((Height - 2) * Fraction))
						ImDrawing.Box(true, BarPosition + Vector2.new(1, Horizontal and 1 or Height - FillHeight - 1), Vector2.new(FillWidth, FillHeight), Visuals.ESPVisuals_HealthbarStyle == "Solid" and Visuals.ESPVisuals_HealthbarColor or Color3.fromHSV(
							Fraction * 0.33, 0.85, 1
						), 1, Opacity)
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
			ESPJointCache[6] = GetWeldPosition(ThirdPersonObject._leftFoot.weld)
			ESPJointCache[7] = GetWeldPosition(ThirdPersonObject._rightFoot.weld)
			ESPJointCache[8] = ThirdPersonObject._leftFoot.pos
			ESPJointCache[9] = ThirdPersonObject._rightFoot.pos
			local Opacity, Offset = 1 - Visuals.ESPVisuals_SkeletonTransparency, -Vector3.yAxis
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
					ImDrawing.Line(From, To, Visuals.ESPVisuals_SkeletonColor, Visuals.ESPVisuals_SkeletonThickness, Opacity)
				end
			end

			if Visuals.ESPVisuals_SkeletonHeadDot then
				local Screen = ESPScreenCache[2]
				if Screen then
					ImDrawing.Circle(true, Screen, 2.5, Visuals.ESPVisuals_SkeletonColor, 1, Opacity)
				end
			end
		end

		if Tracers and not (AimbotState.Target == Player and Aiming.Aimbot_TargetTracer) then
			local Part = Visuals.ESPVisuals_TracerPart
			local Screen, OnScreen = WorldToViewportPoint(Part == "Head" and HeadPosition or Part == "Neck" and GetWeldPosition(ThirdPersonObject._neckWeld) or Torso.Position)
			if OnScreen then
				ImDrawing.Line(TracerFrom, Screen, Visuals.ESPVisuals_TracerColor, Visuals.ESPVisuals_TracerThickness, 1 - Visuals.ESPVisuals_TracerTransparency)
			end
		end
	end
end

ns__hooktablefunction(AudioSystem, "playSound", function(Original, Name, ...)
	if Miscellaneous.SoundOverride_HitSound ~= "None" and Name == "hitmarker" then
		PlaySoundId(CustomSounds[Miscellaneous.SoundOverride_HitSound], 1, select(3, ...))
	elseif Miscellaneous.SoundOverride_KillSound ~= "None" and (Name == "killshot" or Name == "headshotkill") then
		PlaySoundId(CustomSounds[Miscellaneous.SoundOverride_KillSound], 1, select(3, ...))
	else
		Original(Name, ...)
	end

	local RootPart = Visuals.ESPVisuals_MasterSwitch and not MenuScreenGui.Enabled and Visuals.ESPVisuals_SoundRings and select(7, ...)
	if not RootPart then
		return
	end

	for Player, Entry in next, CachedPlayers do
		local ThirdPersonObject = Entry._isEnemy and Entry._thirdPersonObject
		if ThirdPersonObject and ThirdPersonObject._rootPart == RootPart then
			if (ThirdPersonObject._characterModelHash.Head.Position - GetLocalPosition()).Magnitude > Visuals.ESPVisuals_MaxDistance then
				return
			end

			local SoundRings = ESPModule.SoundRings[Player]
			if not SoundRings then
				SoundRings = {}
				ESPModule.SoundRings[Player] = SoundRings
			end

			if #SoundRings == 2 then
				local OldRing = table.remove(SoundRings, 1)
				OldRing.Adornment:Destroy()
			end

			local CylinderHandleAdornment, Duration = ns__cloneref(Instance.new("CylinderHandleAdornment")), Visuals.ESPVisuals_SoundRingsDuration
			CylinderHandleAdornment.Adornee = Terrain
			CylinderHandleAdornment.Parent = Terrain
			CylinderHandleAdornment.AlwaysOnTop = not Visuals.ESPVisuals_SoundRingsOccluded
			CylinderHandleAdornment.ZIndex = 1
			CylinderHandleAdornment.Height = 0.03
			CylinderHandleAdornment.AdornCullingMode = Enum.AdornCullingMode.Never
			CylinderHandleAdornment.CFrame = CFrame.new(RootPart.Position - Vector3.new(0, 2, 0)) * CFrame.Angles(Quarter, 0, 0)
			CylinderHandleAdornment.Radius = 2
			CylinderHandleAdornment.InnerRadius = 1.93
			CylinderHandleAdornment.Color3 = Visuals.ESPVisuals_SoundRingsColor
			CylinderHandleAdornment.Transparency = Visuals.ESPVisuals_SoundRingsTransparency
			CylinderHandleAdornment.Visible = true

			local Ring = {Adornment = CylinderHandleAdornment, Opacity = 1, FadeStart = os.clock() + Duration - 0.2, FadeDuration = 0.2}
			SoundRings[#SoundRings + 1] = Ring
			if #SoundRings == 2 then
				local OldRing, Now = SoundRings[1], os.clock()
				OldRing.Opacity *= math.clamp(1 - (Now - OldRing.FadeStart) / OldRing.FadeDuration, 0, 1)
				OldRing.FadeStart, OldRing.FadeDuration = Now, 0.12
			end

			TweenService:Create(CylinderHandleAdornment, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {InnerRadius = 5.93, Radius = 6}):Play()
			break
		end
	end
end)

local ParticleEffects = {
	Snow = {
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(6, 12),
		Drag = 3,
		Acceleration = Vector3.new(0, -6, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}),
		Color = ColorSequence.new(Color3.fromRGB(235, 242, 255))
	},
	Sparks = {
		Lifetime = NumberRange.new(0.3, 0.5),
		Speed = NumberRange.new(12, 20),
		Drag = 1,
		Acceleration = Vector3.new(0, -10, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.2)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		Color = ColorSequence.new(Color3.fromRGB(255, 180, 60))
	},
	Embers = {
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(8, 16),
		Drag = 2,
		Acceleration = Vector3.new(0, 4, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		Color = ColorSequence.new(Color3.fromRGB(255, 120, 30))
	}
}

local HitGhosts = {}
local function RenderHitGhost(Model)
	local Color, Duration, Parts = Visuals.Combat_HitGhostsColor, Visuals.Combat_HitGhostsLifetime, {}
	for _,Descendant in Model:QueryDescendants("BasePart, SpecialMesh, Weld, BillboardGui, Texture, Decal") do
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
				Descendant.VertexColor = Vector3.new(Color.R, Color.G, Color.B)
			end
		elseif Descendant:IsA("Weld") or Descendant:IsA("BillboardGui") or Descendant:IsA("Texture") or Descendant:IsA("Decal") then
			Descendant:Destroy()
		end
	end
	Model.Parent = workspace
	table.insert(HitGhosts, {Model = Model, Parts = Parts, Time = os.clock() + Duration, Duration = Duration})
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
			local Spin = Visuals.Combat_HitMarkerSpin
			local Cosine, Sine = 1, 0
			if Spin then
				local Angle = Elapsed * Visuals.Combat_HitMarkerSpinSpeed
				Cosine, Sine = math.cos(Angle), math.sin(Angle)
			end

			local Offsets = self.Offsets[Style]
			local Gap = Visuals.Combat_HitMarkerGap
			local Size = Visuals.Combat_HitMarkerSize
			for _Index = 1, 4 do
				local OffsetX, OffsetY = Offsets[_Index][1], Offsets[_Index][2]
				if Spin then
					OffsetX, OffsetY = OffsetX * Cosine - OffsetY * Sine, OffsetX * Sine + OffsetY * Cosine
				end
				local Direction = Vector2.new(OffsetX, OffsetY)
				ImDrawing.Line(Screen + Direction * Size, Screen + Direction * Gap, Color, Thickness, Transparency)
			end
		end
	end
end

local GrenadeModule = {
	Segments = {}, Marker = SphereHandleAdornment, Gravity = Vector3.new(0, -80, 0),
	TrajectoryColor = ColorSequence.new(Color3.fromRGB(255, 165, 0)),
	ImpactColor = ColorSequence.new(SphereHandleAdornment.Color3)
}

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

function GrenadeModule:GetFuse(Position, Velocity, Fuse)
	if Miscellaneous.WeaponMods_CustomGrenadeFuse then
		Fuse = Miscellaneous.WeaponMods_CustomGrenadeFuseAmount
	elseif Miscellaneous.WeaponMods_UncookableGrenade and Fuse <= 0 then
		Fuse = GetActiveWeapon()._weaponData.fusetime
	end

	if Miscellaneous.WeaponMods_CustomGrenadeFuse and Miscellaneous.WeaponMods_CustomGrenadeFuseOnImpact and Velocity.Magnitude > 0.01 then
		local Filter = {Map}
		for _,Entry in next, CachedPlayers do
			table.insert(Filter, Entry._thirdPersonObject._characterModel)
		end
		GrenadeImpactParams.FilterDescendantsInstances = Filter

		local LastPosition, Traveled = Position, 0
		for Step = 1, 300 do
			local Elapsed = Step * RaycastStep
			local Next = Position + Velocity * Elapsed + 0.5 * self.Gravity * Elapsed * Elapsed
			local Hit = workspace:Raycast(LastPosition, Next - LastPosition, GrenadeImpactParams)
			Traveled += (Next - LastPosition).Magnitude
			if Hit and Hit.Instance.Name ~= "Window" and Hit.Instance.Name ~= "Col" and Traveled >= 3 then
				local SegmentLength = (Next - LastPosition).Magnitude
				return Elapsed - (SegmentLength > 0 and RaycastStep * (Next - Hit.Position).Magnitude / SegmentLength or 0)
			end
			LastPosition = Next
		end
	end

	return Fuse
end

function GrenadeModule:ClearTrajectory()
	for _,Segment in self.Segments do
		Segment.Beam.Enabled = false
	end
	self.Marker.Visible = false
end

function GrenadeModule:UpdateTrajectory()
	local ActiveWeapon = IsSpawned and GetActiveWeapon()
	if not ActiveWeapon or ActiveWeapon:getWeaponType() ~= "Grenade" then
		return self:ClearTrajectory()
	end

	local CameraPosition, Position = GetActiveCamera()._baseCFrame.Position, ActiveWeapon._mainPart.Position
	local StartHit = workspace:Raycast(CameraPosition, Position - CameraPosition, GrenadeRaycastParams)
	Position = StartHit and (StartHit.Position + StartHit.Normal * 0.01) or Position

	local Gravity = ActiveWeapon._acceleration
	local TargetPart = Aiming.Aimbot_RedirectGrenade and not Visuals.Combat_GrenadeTrajectoryIgnoreAimbot and (not Aiming.Aimbot_WallCheck or AimbotState.IsTargetVisible) and AimbotState.TargetPart
	local WeaponData = ActiveWeapon._weaponData
	local Velocity, FuseRemaining
	if TargetPart then
		Velocity, FuseRemaining = self:GetVelocity(TargetPart.Position, Position)
	end

	Velocity = Velocity or ((Camera.CFrame * CFrame.Angles(math.rad(WeaponData.throwangle or 0), 0, 0)).LookVector * WeaponData.throwspeed + GetLocalCharacter()._rootPart.AssemblyLinearVelocity)
	local FuseTime = ActiveWeapon._fuseTime
	FuseRemaining = self:GetFuse(Position, Velocity, FuseRemaining or (FuseTime > 0 and math.max(0, FuseTime - GetTime()) or WeaponData.fusetime))
	if FuseRemaining <= 0 then
		return self:ClearTrajectory()
	end

	local Points, Bounces = {Position}, 0
	local Time, Elapsed, Ticks = 0, 0, 0
	local LastPosition, RaycastOffset = Position, Vector3.zero
	local MaxBounces = Visuals.Combat_GrenadeTrajectoryBounces
	local Step = math.max(1, math.floor(math.sqrt(8 * 0.025 / Gravity.Magnitude) / RaycastStep))
	for _ = 1, math.min(math.ceil(FuseRemaining / RaycastStep), 600) do
		local StepTime = math.min(RaycastStep, FuseRemaining - Elapsed)
		if StepTime <= 0 then
			break
		end

		Elapsed += StepTime
		Time += StepTime
		Ticks += 1

		local NextPosition = Position + Velocity * Time + 0.5 * Gravity * Time * Time
		local Hit = workspace:Raycast(LastPosition, NextPosition - LastPosition - 0.05 * RaycastOffset, GrenadeRaycastParams)
		if Hit and Hit.Instance.Name ~= "Window" and Hit.Instance.Name ~= "Col" then
			if Bounces >= MaxBounces then
				LastPosition = Hit.Position
				break
			end

			local Normal, Delta = Hit.Normal, Hit.Position - LastPosition
			local Magnitude = Delta.Magnitude
			local Contact = LastPosition + (Magnitude > 0 and math.max(0, 1 - 0.001 / Magnitude) or 0) * Delta + 0.05 * Normal
			table.insert(Points, Contact)
			local ImpactVelocity = Velocity + Gravity * Time
			local NormalSpeed = ImpactVelocity:Dot(Normal)
			local NormalVelocity = Normal * NormalSpeed
			local _Velocity = ImpactVelocity - NormalVelocity
			Velocity = math.max(0, 1 - (0.08 * (10 * math.max(0, -Normal:Dot(Gravity)) * StepTime + math.max(
				0, -1.2 * NormalSpeed
			)) / math.max(_Velocity.Magnitude, 1e-6))) * _Velocity - 0.2 * NormalVelocity
			Position, Time, LastPosition = Contact, 0, Contact
			if Velocity.Magnitude < 1 then
				break
			end

			RaycastOffset = 0.2 * Normal
			Bounces += 1
			Ticks = 0
		else
			if Ticks >= Step then
				table.insert(Points, NextPosition)
				Ticks = 0
			end
			LastPosition = NextPosition
		end
	end

	if Points[#Points] ~= LastPosition then
		table.insert(Points, LastPosition)
	end

	local Segments, SegmentsNeeded = self.Segments, #Points - 1
	for Index = #Segments + 1, SegmentsNeeded do
		local Attachment0 = ns__cloneref(Instance.new("Attachment"))
		local Attachment1 = ns__cloneref(Instance.new("Attachment"))
		local Beam = ns__cloneref(Instance.new("Beam"))
		Beam.FaceCamera = true
		Beam.LightEmission = 1
		Beam.Texture = ""
		Beam.Segments = 1
		Attachment0.Parent = Terrain
		Attachment1.Parent = Terrain
		Beam.Attachment0 = Attachment0
		Beam.Attachment1 = Attachment1
		Beam.Parent = Terrain
		Segments[Index] = {Beam = Beam, Attachment0 = Attachment0, Attachment1 = Attachment1}
	end

	local Thickness = Visuals.Combat_GrenadeTrajectoryThickness * 0.025
	for Index, Segment in Segments do
		local Beam = Segment.Beam
		if Index <= SegmentsNeeded then
			Segment.Attachment0.Position = Points[Index]
			Segment.Attachment1.Position = Points[Index + 1]
			Beam.Color = Index == SegmentsNeeded and self.ImpactColor or self.TrajectoryColor
			Beam.Width0 = Thickness
			Beam.Width1 = Thickness
		end
		Beam.Enabled = Index <= SegmentsNeeded
	end

	self.Marker.CFrame = CFrame.new(LastPosition)
	self.Marker.Visible = true
end

local ThirdPersonModule = {IsSpawned = false, Object = nil, LastPosition = nil}

function ThirdPersonModule:Destroy()
	self.GhostCache = nil
	if self.Object then
		FakeReplicationObject:despawn()
		self.Object:Destroy()
		self.Object = nil
		self.LastPosition = nil
	end
end

function ThirdPersonModule:Update(DeltaTime)
	local Character, Weapon = GetLocalCharacter(), GetActiveWeapon()
	if Character then
		local HideViewModel = Visuals.Camera_ThirdPerson and Visuals.Camera_ThirdPersonHideViewModel
		for _,Model in {Character._leftArmModel, Character._rightArmModel, Weapon and Weapon._weaponModel} do
			local Parts = ViewModelModule.Parts[Model]
			if not Parts then
				ViewModelModule:OnCameraChildAdded(Model)
				Parts = ViewModelModule.Parts[Model]
			end
			for _,Part in ipairs(Parts) do
				Part.LocalTransparencyModifier = HideViewModel and 1 or 0
			end
		end
	end

	local RootPart = Character and Visuals.Camera_ThirdPerson and Visuals.Camera_ThirdPersonShowCharacter and Character._rootPart
	if not RootPart then
		return self:Destroy()
	end

	local Position = RootPart.Position
	if Miscellaneous.AntiAim_Enabled and Miscellaneous.AntiAim_FakeLag then
		Position = FakeLag.LastSentPosition or Position
	end
	local Velocity = (Position - (self.LastPosition or Position)) / DeltaTime

	if self.IsSpawned or not self.Object then
		local Controller = GetActiveWeaponController()
		if Controller then
			self:Destroy()
			local Weapons, Loadout = Controller:getWeapons(), {activeWeaponIndex = Weapon and Weapon.weaponIndex ~= 4 and Weapon.weaponIndex or 1}
			for Index, Name in ipairs({"Primary", "Secondary", "Knife", "Grenade"}) do
				local Object = Weapons[Index]
				if Object then
					Loadout[Name] = {Name = Object.weaponName, Attachments = Object.weaponAttachments, Camo = Object.weaponCamo}
				end
			end

			FakeReplicationObject._player = LocalPlayer
			FakeReplicationObject:spawn(nil, Loadout)

			self.Object = FakeReplicationObject._thirdPersonObject
			self.Object:setStance(Character._movementMode)
			self.Object:setSprint(Character._sprinting)
			self.Object:setAim(Weapon and Weapon._aiming)

			for _,Part in self.Object._characterModelHash do
				Part.LocalTransparencyModifier = 0
				Part.Transparency = 0
			end

			self.IsSpawned = false
			Velocity = Vector3.zero
		end
	end
	self.LastPosition = Position

	if not self.Object then
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
		angles = Angles, barrelAngles = Miscellaneous.AntiAim_Enabled and Angles * 0.99 or Vector3.zero, breakcount = 0
	}, true)

	local Visible = not (Visuals.Camera_ThirdPersonHideCharacterWhileAiming and Weapon and Weapon._aiming)
	self.Object.canRenderWeapon = Visible
	FakeReplicationObject:step(Visible)
	if not Visible then
		self.Object:renderWeapon(false)
	end

	local Model = self.Object._characterModel
	local GhostCharacter, GhostColor = Visuals.Camera_ThirdPersonGhostCharacter, Visuals.Combat_HitGhostsColor
	local Cache = self.GhostCache
	if Cache and Cache.Model ~= Model then
		Cache, self.GhostCache = nil, nil
	end

	if not GhostCharacter and (not Cache or not next(Cache.Objects)) then
		return
	end

	if not Cache then
		Cache = {Model = Model, Objects = {}}
		self.GhostCache = Cache
	end

	if GhostCharacter then
		local VertexColor = Vector3.new(GhostColor.R, GhostColor.G, GhostColor.B)
		local function SetProperty(Object, Property, Value)
			local Saved = Cache.Objects[Object]
			if not Saved then
				Saved = {}
				Cache.Objects[Object] = Saved
			end

			if Saved[Property] == nil then
				Saved[Property] = Object[Property]
			end
			Object[Property] = Value
		end

		for _,Object in Model:QueryDescendants("BasePart, SpecialMesh, Texture, Decal") do
			if Object:IsA("BasePart") then
				SetProperty(Object, "Material", Enum.Material.ForceField)
				SetProperty(Object, "Color", GhostColor)
				SetProperty(Object, "Transparency", 0)
				if Object:IsA("MeshPart") then
					SetProperty(Object, "TextureID", "")
				end
			elseif Object:IsA("SpecialMesh") then
				if Object.MeshId == "rbxassetid://4049240078" then
					SetProperty(Object.Parent, "Transparency", 1)
				else
					if Object.MeshId == "rbxassetid://6179256256" then
						SetProperty(Object, "TextureId", "rbxassetid://12325350352")
					end
					SetProperty(Object, "VertexColor", VertexColor)
				end
			else
				SetProperty(Object, "Transparency", 1)
			end
		end
	else
		for Object, Properties in next, Cache.Objects do
			if Object.Parent then
				for Property, Value in next, Properties do
					Object[Property] = Value
				end
			end
		end
		table.clear(Cache.Objects)
	end
end

local HitScanSphereOffsets, CardinalAxes, CornerSigns = {
    Vector3.yAxis, Vector3.new(-0.423957, 0.818182, 0.388380), Vector3.new(0.067439, 0.636364, -0.768436), Vector3.new(0.541951, 0.454545, 0.706879), Vector3.new(
		-0.947384, 0.272727, -0.167579
	), Vector3.new(0.840261, 0.090909, -0.534506), Vector3.new(-0.258529, -0.090909, 0.961716), Vector3.new(-0.443435, -0.272727, -0.853806), Vector3.new(
		0.836676, -0.454545, 0.305553
	), Vector3.new(-0.713030, -0.636364, 0.294329), Vector3.new(0.243694, -0.818182, -0.520761), -Vector3.yAxis,
}, {Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis}, {
	{-1, -1, -1, -Vector3.one.Unit}, {-1, -1, 1, Vector3.new(-1, -1, 1).Unit},
	{-1, 1, -1, Vector3.new(-1, 1, -1).Unit}, {-1, 1, 1, Vector3.new(-1, 1, 1).Unit},
	{1, -1, -1, Vector3.new(1, -1, -1).Unit}, {1, -1, 1, Vector3.new(1, -1, 1).Unit},
	{1, 1, -1, Vector3.new(1, 1, -1).Unit}, {1, 1, 1, Vector3.one.Unit},
}

local HitScanCorners = {}
for _,Size in next, PartSizes do
	if HitScanCorners[Size] then
		continue
	end

	local Corners = table.create(8)
	for Index, Sign in ipairs(CornerSigns) do
		local Corner = Vector3.new(Sign[1] * Size.X, Sign[2] * Size.Y, Sign[3] * Size.Z)
		Corners[Index] = {Corner, Corner.Unit}
	end

	HitScanCorners[Size] = Corners
end

local function GetMagnitude(_Vector3)
	return _Vector3:Dot(_Vector3)
end

local function GetBulletVelocity(Origin, Target, Speed)
	local Gravity = -BulletAcceleration
	local Displacement = Target - Origin

	local AccelerationSquared = GetMagnitude(Gravity)
	if AccelerationSquared <= 1e-12 then
		local Distance = Displacement.Magnitude
		if Distance <= 1e-6 then
			return
		end
		return Displacement / Distance * Speed, Distance / Speed
	end

	local MidTimeSquared = (2 * (Speed * Speed - Gravity:Dot(Displacement))) / AccelerationSquared
	local Discriminant = MidTimeSquared * MidTimeSquared - (4 * GetMagnitude(Displacement)) / AccelerationSquared
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

local ns__mousemoverel = mousemoverel or mouse_moverel or (function()
	Library:Notify("Required function for Mouse Aimbot is not supported, Mouse Aimbot won't function.", 6.75)
	return function() end
end)()

local FOVCircleDots = table.create(64)
for Index = 1, 64 do
	local Angle = (Index - 1) * TwoPi / 64
	FOVCircleDots[Index] = Vector2.new(math.cos(Angle), math.sin(Angle))
end

local AimingModule = {NextShot = 0, Start = 0}
function AimingModule:GetTarget(CharacterHash, AimbotPart, WallCheck, FOVOrigin, FOVRadius)
	local IsClosest = AimbotPart == "Closest"
	local ScanParts = IsClosest or AimbotPart == "Best"
	local BestPart, BestScreen, BestVisible, BestPosition, BestScore = nil, nil, false, nil, math.huge
	local IsSilent = Aiming.Aimbot_Type == "Silent"
	local IgnoreBlocked = WallCheck and Aiming.Aimbot_WallCheckAction == "Ignore Target"
	for Index = 1, ScanParts and 6 or 1 do
		local Name = ScanParts and PartNames[Index] or AimbotPart
		local Part = CharacterHash[Name]
		local Position, Screen, Visible = nil, nil, false
		if Aiming.Aimbot_HitScanning then
			local Center, Origin = Part.Position, Camera.CFrame.Position
			local ScanMode = IsSilent and "Cardinal" or Aiming.Aimbot_HitScanningMode
			local ScanOffsets = ScanMode == "Cardinal" and CardinalAxes or ScanMode == "Sphere" and HitScanSphereOffsets
			local Offsets = ScanOffsets or HitScanCorners[PartSizes[Name]]
			local Radius = Aiming.Aimbot_HitScanningRadius * (ScanOffsets and 1 or 0.5)
			local Steps = IsSilent and Aiming.Aimbot_HitScanningSteps or 1
			for _Index = 0, #Offsets * Steps do
				local _Position = Center
				if _Index > 0 then
					local Offset = Offsets[math.floor((_Index - 1) / Steps) + 1]
					if IsSilent and not Aiming.Aimbot_HitScanningAxes[Offset.X ~= 0 and "X" or Offset.Y ~= 0 and "Y" or "Z"] then
						continue
					end
					local _Radius = Radius * ((_Index - 1) % Steps + 1) / Steps
					_Position += ScanOffsets and Offset * _Radius or Offset[1] + Offset[2] * _Radius
				end
				local _Screen, OnScreen = WorldToViewportPoint(_Position)
				if not (OnScreen and (_Screen - FOVOrigin).Magnitude <= FOVRadius) then
					continue
				end

				if not TransparentRaycast(Origin, _Position - Origin) then
					Position, Screen, Visible = _Position, _Screen, true
					break
				end

				if not Position then
					Position, Screen = _Position, _Screen
				end
			end

			if not Position or IgnoreBlocked and not Visible then
				continue
			end
		else
			Position = Part.Position
			local OnScreen
			Screen, OnScreen = WorldToViewportPoint(Position)
			if not OnScreen or (Screen - FOVOrigin).Magnitude > FOVRadius then
				continue
			end
		end

		local Distance = 0
		if IsClosest then
			Distance = GetMagnitude(Screen - FOVOrigin)
			if Distance >= BestScore then
				continue
			end
		end

		if not Aiming.Aimbot_HitScanning then
			Visible = not WallCheck or not TransparentRaycast(Camera.CFrame.Position, Position - Camera.CFrame.Position)
			if IgnoreBlocked and not Visible then
				continue
			end
		end

		if not IsClosest then
			if Visible or not ScanParts or not WallCheck then
				return Part, Screen, Visible, Position
			elseif BestPart then
				continue
			end
		end

		BestScore, BestPart, BestScreen, BestVisible, BestPosition = Distance, Part, Screen, Visible, Position
	end
	return BestPart, BestScreen, BestVisible, BestPosition
end

function AimingModule:UpdateAimbot(LocalHeadPosition, Now)
	local AimbotEnabled = Aiming.Aimbot_Enabled
	local ShowFOV = AimbotEnabled and Aiming.Aimbot_ShowFOVCircle
	local FOVOrigin = ShowFOV and Aiming.Aimbot_FOVCircleFollowRecoil and GetRecoilPosition() or ScreenCenter
	local FOVRadius = ShowFOV and Aiming.Aimbot_FOVCircleRadius or math.huge
	if ShowFOV then
		local Radius = FOVRadius
		if Aiming.Aimbot_FOVCircleFireExpansion then
			local Progress = math.clamp(1 - (Now - LastFire) / Aiming.Aimbot_FOVCircleFireDuration, 0, 1)
			Radius += Aiming.Aimbot_FOVCircleFireAmount * Progress * Progress
		end
		Radius = math.max(15, Radius)

		local Color, Thickness, Opacity, Filled = Aiming.Aimbot_FOVCircleColor, Aiming.Aimbot_FOVCircleThickness, Aiming.Aimbot_FOVCircleOpacity, Aiming.Aimbot_FOVCircleFilled
		if Aiming.Aimbot_FOVCircleDotted and not Filled then
			for _,Offset in ipairs(FOVCircleDots) do
				ImDrawing.Circle(true, FOVOrigin + Offset * Radius, Thickness, Color, 1, Opacity)
			end
		else
			ImDrawing.Circle(Filled, FOVOrigin, Radius, Color, Thickness, Opacity)
		end
	end

	if not (AimbotEnabled and IsSpawned) then
		AimbotState.Target, AimbotState.TargetPart, AimbotState.IsTargetVisible, AimbotState.TargetPosition = nil, nil, false, nil
		return
	end

	local AimbotType, Smoothness = Aiming.Aimbot_Type, Aiming.Aimbot_Smoothness
	local CameraCFrame = Camera.CFrame
	local Target, TargetPart, TargetPosition, IsTargetVisible, TargetScreen, ClosestScore = nil, nil, nil, false, nil, math.huge
	local WallCheck, AimbotPart = Aiming.Aimbot_WallCheck, Aiming.Aimbot_Part
	local CameraPosition, LookVector = CameraCFrame.Position, CameraCFrame.LookVector

	for Player, Entry in next, CachedPlayers do
		if not Entry._isEnemy then
			continue
		end

		local CharacterHash = Entry._thirdPersonObject._characterModelHash
		local Delta = CharacterHash.Torso.Position - CameraPosition
		if not Aiming.Aimbot_HitScanning and (GetMagnitude(Delta) < 1e-6 or LookVector:Dot(Delta) < 0) then
			continue
		end

		local Part, Screen, IsVisible, Position = self:GetTarget(CharacterHash, AimbotPart, WallCheck, FOVOrigin, FOVRadius)
		if not Part then
			continue
		end

		local Distance = (Screen - FOVOrigin).Magnitude
		if Distance >= ClosestScore then
			continue
		end

		local Score = Distance + (Position - LocalHeadPosition).Magnitude * 0.15
		if Score < ClosestScore then
			ClosestScore, Target, TargetPart, TargetPosition, IsTargetVisible, TargetScreen = Score, Player, Part, Position, IsVisible, Screen
		end
	end

	AimbotState.Target, AimbotState.TargetPart, AimbotState.IsTargetVisible, AimbotState.TargetPosition = Target, TargetPart, IsTargetVisible, TargetPosition
	if not TargetPart then
		return
	end

	if Aiming.Aimbot_TargetTracer then
		local From, ActiveWeapon = ScreenCenter, GetActiveWeapon()
		local BarrelPart = ActiveWeapon and ActiveWeapon._barrelPart
		if BarrelPart then
			local Screen, OnScreen = WorldToViewportPoint(BarrelPart.Position)
			if OnScreen then
				From = Screen
			end
		end
		ImDrawing.Line(From, TargetScreen, Aiming.Aimbot_TargetTracerColor, 1.5, Aiming.Aimbot_TargetTracerOpacity)
	end

	if WallCheck and not IsTargetVisible then
		return
	end

	if AimbotType == "Mouse" and not Library.Toggled then
		ns__mousemoverel((TargetScreen.X - ScreenXCenter) / Smoothness, (TargetScreen.Y - ScreenYCenter) / Smoothness)
	elseif AimbotType == "Camera" then
		local Direction = (TargetPosition - CameraCFrame.Position).Unit
		if Smoothness > 1 then
			Direction = CameraCFrame.LookVector:Lerp(Direction, 1 / Smoothness).Unit
		end

		local ActiveCamera = GetActiveCamera()
		if ActiveCamera.setLookVector then
			ActiveCamera:setLookVector(Direction)
		end
	end
end

function AimingModule:SetFiring(Weapon, State)
	local _Weapon = self.Weapon
	if _Weapon and _Weapon ~= Weapon then
		_Weapon:shoot(false)
	end

	self.Weapon = State and Weapon

	if Weapon then
		Weapon:shoot(State)
	end

	if not State then
		self.Start = 0
	end
end

function AimingModule:UpdateAutoFire(Now)
	local ActiveWeapon = GetActiveWeapon()
	if self.Weapon and self.Weapon ~= ActiveWeapon then
		self:SetFiring()
	end

	local TargetPosition = AimbotState.TargetPosition
	if not ActiveWeapon or ActiveWeapon:getWeaponType() ~= "Firearm" or Aiming.Aimbot_Type ~= "Silent" or not TargetPosition or Aiming.Aimbot_WallCheck and not AimbotState.IsTargetVisible then
		return self:SetFiring()
	end

	local CanShoot = AimbotState.IsTargetVisible
	if Aiming.Aimbot_AutoWall then
		local WeaponData, Origin = ActiveWeapon._weaponData, GetLocalPosition()
		local Velocity = GetBulletVelocity(Origin, TargetPosition, WeaponData.bulletspeed)
		CanShoot = Velocity and BulletCheck(Origin, TargetPosition, Velocity, BulletAcceleration, WeaponData.penetrationdepth, RaycastStep)
	end

	if not CanShoot then
		return self:SetFiring()
	end

	if self.Start == 0 then
		self.Start = Now
	end

	if (Now - self.Start) * 1000 < Aiming.Aimbot_AutoDelay then
		return
	end

	local Automatic = ActiveWeapon:getFiremode() == true
	if not self.Weapon or Automatic and not ActiveWeapon._auto and ActiveWeapon._magCount > 0 and (not ActiveWeapon:isReloading() or ActiveWeapon._canShoot) then
		self:SetFiring(ActiveWeapon, true)
	elseif ActiveWeapon._burst == 0 and not Automatic then
		self:SetFiring(ActiveWeapon)
	end
end

local FireScanOffsets
local function CacheFireScan()
	local Offsets = {}
	for Index = 0, Aiming.RageBot_FireScanningCount - 1 do
		local Height = Aiming.RageBot_FireScanningCount == 1 and 0 or 1 - (Index / (Aiming.RageBot_FireScanningCount - 1)) * 2
		local Ring = math.sqrt(math.max(0, 1 - Height * Height))
		Offsets[Index + 1] = Vector3.new(math.cos(GoldenAngle * Index) * Ring, Height, math.sin(GoldenAngle * Index) * Ring)
	end
	FireScanOffsets = Offsets
end
CacheFireScan()

local RageSlots = {{}, {}, {}, {}, {}, {}}
function AimingModule:UpdateRageBot()
	local Weapon = GetActiveWeapon()
	if not Weapon or Weapon:getWeaponType() ~= "Firearm" or os.clock() <= self.NextShot or (Weapon._magCount <= 0 and Weapon._spareCount <= 0) then
		return
	end

	local LocalPosition, Entries, Distances, Healths, IndexTable = GetLocalPosition(), {}, {}, {}, {}
	for _,Entry in next, CachedPlayers do
		if not Entry._isEnemy then
			continue
		end

		local Index = #Entries + 1
		Entries[Index] = Entry
		IndexTable[Index] = Index
		Distances[Index] = GetMagnitude(Entry._thirdPersonObject._characterModelHash.Head.Position - LocalPosition)
		Healths[Index] = Entry:getHealth()
	end

	local EntryCount = #Entries
	if EntryCount == 0 then
		return
	end

	table.sort(IndexTable, function(IndexA, IndexB)
		local HealthA, HealthB = Healths[IndexA], Healths[IndexB]
		if HealthA == HealthB then
			return Distances[IndexA] < Distances[IndexB]
		end
		return HealthA < HealthB
	end)

	local Time, WeaponData = GetTime(), Weapon._weaponData
	local PenetrationDepth, BulletSpeed = WeaponData.penetrationdepth, WeaponData.bulletspeed
	local ShotInterval = 60 / (WeaponData.variablefirerate and WeaponData.firerate[Weapon._firemodeIndex] or WeaponData.firerate) / (Miscellaneous.WeaponMods_RapidFire and 1.5 or 1)
	local PenetrationDetection, TargetName = Aiming.RageBot_WallPenetrationDetection, Aiming.RageBot_Part
	local IsBest = TargetName == "Best"
	local Count, Lifetime = IsBest and 6 or 1, BulletSpeed * BulletLifetime
	local ScanLimit = Aiming.RageBot_ScanLimit and Aiming.RageBot_ScanLimitAmount or math.huge
	local FireOrigins = nil
	for Index = 1, EntryCount do
		if os.clock() < self.NextShot then
			break
		end

		local Entry = Entries[IndexTable[Index]]
		local CharacterHash = Entry._thirdPersonObject._characterModelHash
		for _Index = 1, Count do
			local Name = IsBest and PartNames[_Index] or TargetName
			local Slot = RageSlots[_Index]
			Slot.Part = CharacterHash[Name]
			Slot.Name = Name
		end

		local Scans = 0
		local function Check(Origin, AimAt, Name, CountScans)
			if CountScans then
				if Scans >= ScanLimit then
					return
				end
				Scans += 1
			end

			local Delta = AimAt - Origin
			if Delta.Magnitude > Lifetime then
				return
			end

			if not PenetrationDetection and TransparentRaycast(Origin, Delta) then
				return
			end

			local Velocity = GetBulletVelocity(Origin, AimAt, BulletSpeed)
			if not Velocity then
				return
			end

			if PenetrationDetection and not BulletCheck(Origin, AimAt, Velocity, BulletAcceleration, PenetrationDepth, RaycastStep) then
				return
			end

			return Origin, AimAt, Velocity, Name
		end

		local function Solve(Origins, FireScanning)
			for _,Origin in next, Origins do
				if FireScanning and Scans >= ScanLimit then
					break
				end

				for _Index = 1, Count do
					local Target = RageSlots[_Index]
					local _Origin, _Target, Velocity, Name = Check(Origin, Target.Part.Position, Target.Name, FireScanning)
					if _Origin then
						return _Origin, _Target, Velocity, Name
					end
				end
			end

			if Aiming.RageBot_HitScanning and Scans < ScanLimit then
				local Mode = Aiming.RageBot_HitScanningMode
				local Offsets = Mode == "Cardinal" and CardinalAxes or Mode == "Sphere" and HitScanSphereOffsets
				local Radius = Aiming.RageBot_HitScanningRadius * (Offsets and 1 or 0.5)
				for _,Origin in next, Origins do
					if Scans >= ScanLimit then
						break
					end

					for _Index = 1, Count do
						if Scans >= ScanLimit then
							break
						end

						local Target = RageSlots[_Index]
						local Center = Target.Part.Position
						local Facing = Origin - Center
						local Distance = Facing.Magnitude
						if Distance > 1e-6 then
							Facing *= 1 / Distance
							for _,Offset in next, Offsets or HitScanCorners[PartSizes[Target.Name]] do
								if Scans >= ScanLimit then
									break
								end

								local Direction = Offsets and Offset or Offset[2]
								if Direction:Dot(Facing) > -0.2 then
									local _Origin, _Target, Velocity, Name = Check(Origin, Offsets and Center + Direction * Radius or Center + Offset[1] + Direction * Radius, Target.Name, true)
									if _Origin then
										return _Origin, _Target, Velocity, Name
									end
								end
							end
						end
					end
				end
			end

			if Aiming.RageBot_Backtrack then
				for _,Origin in next, Origins do
					local _Origin, Target, Velocity, Name = Check(Origin, Entry._receivedPosition, "Torso")
					if _Origin then
						return _Origin, Target, Velocity, Name
					end
				end

				local _Cache = MovementCache[Entry._player]
				if _Cache then
					local Now, Window, _Scans = os.clock(), Aiming.RageBot_BacktrackTime * 0.001, Aiming.RageBot_BacktrackScans
					local Oldest, _Index, Last = Now - Window, 2, 1
					for Scan = 1, _Scans do
						local _Time = Now - Window * Scan / _Scans
						if not _Cache[_Index] or _Cache[_Index].Time < Oldest then
							break
						end

						while _Cache[_Index + 1] and _Cache[_Index + 1].Time >= Oldest and math.abs(_Cache[_Index + 1].Time - _Time) <= math.abs(_Cache[_Index].Time - _Time) do
							_Index += 1
						end

						if _Index == Last then
							continue
						end

						Last = _Index
						local Cached = _Cache[_Index]
						for __Index = 1, Count do
							local Name = IsBest and PartNames[__Index] or TargetName
							local Position = Cached[Name].Position
							for _,Origin in next, Origins do
								local _Origin, _Target, Velocity, _Name = Check(Origin, Position, Name)
								if _Origin then
									return _Origin, _Target, Velocity, _Name
								end
							end
						end
					end
				end
			end
		end

		local Origin, Target, Velocity, HitPartName = Solve({LocalPosition})
		if not Origin and Aiming.RageBot_FireScanning then
			if not FireOrigins then
				FireOrigins = {}
				local Radius, Mode = Aiming.RageBot_FireScanningRadius, Aiming.RageBot_FireScanningMode
				if Mode == "Sphere" then
					for _,Offset in next, FireScanOffsets do
						FireOrigins[#FireOrigins + 1] = LocalPosition + Offset * Radius
					end
				elseif Mode == "Corners" then
					for _,Sign in next, CornerSigns do
						FireOrigins[#FireOrigins + 1] = LocalPosition + Sign[4] * Radius
					end
				else
					for _,Axis in next, CardinalAxes do
						FireOrigins[#FireOrigins + 1] = LocalPosition + Axis * Radius
					end
				end
			end
			Origin, Target, Velocity, HitPartName = Solve(FireOrigins, true)
		end

		if Origin then
			if Weapon._magCount < 1 then
				local MagSize = WeaponData.magsize
				if MagSize <= 0 or Weapon._spareCount <= 0 then
					break
				end
				Weapon:applyReloadCount(MagSize)
			end

			local PelletCount = WeaponData.pelletcount or 1
			local Direction, Bullets = Velocity.Unit, {}

			for _Index = 1, PelletCount do
				BulletTicket += 1
				Bullets[_Index] = {Direction, BulletTicket}
			end

			local UniqueId = Weapon.uniqueId
			LastFire = os.clock()

			NetworkClientSend(NetworkClient, "newbullets", UniqueId, {
				camerapos = LocalPosition,
				firepos = Origin,
				bullets = Bullets,
			}, Time)

			local Player = Entry._player
			LastHit[Player] = true

			for _Index = 1, PelletCount do
				NetworkClientSend(NetworkClient, "bullethit", UniqueId, Player, Target, HitPartName, Bullets[_Index][2], Time)
			end

			if Aiming.RageBot_Collateral then
				local BacktrackTime = os.clock() - Aiming.RageBot_BacktrackTime * 0.001
				for _Index = 1, EntryCount do
					local _Entry = Entries[IndexTable[_Index]]
					local _Player = _Entry._player
					if _Player == Player then
						continue
					end

					local Offset = _Entry._receivedPosition - Target
					local CanHit = Offset.Magnitude <= Aiming.RageBot_CollateralRadius
					if not CanHit then
						local Cache = MovementCache[_Player]
						if Cache then
							for __Index = 1, #Cache do
								local Cached = Cache[__Index]
								if Cached.Time < BacktrackTime then
									break
								end

								Offset = Cached.Position - Target
								if Offset.Magnitude <= Aiming.RageBot_CollateralRadius then
									CanHit = true
									break
								end
							end
						end
					end

					if CanHit then
						LastHit[_Player] = true
						for __Index = 1, PelletCount do
							NetworkClientSend(NetworkClient, "bullethit", UniqueId, _Player, Target, HitPartName, Bullets[__Index][2], Time)
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

ns__hooktablefunction(Module.__get("BulletObject"), "new", function(Original, Data)
	if not Data.onplayerhit then
		return Original(Data)
	end

	local Extra = Data.extra
	local Ticket = Extra.bulletTicket

	if Aiming.Aimbot_Enabled and Aiming.Aimbot_Type == "Silent" then
		local Speed, BulletAccel = Data.velocity.Magnitude, Extra.firearmObject._weaponData.bulletaccel or 0
		local Cache = AimingModule.SilentCache
		if not Cache then
			Cache = {}
			AimingModule.SilentCache = Cache
			if Aiming.Aimbot_HitChance >= math.random(1, 100) then
				local AimbotPart, WallCheck, FOVOrigin = Aiming.Aimbot_Part, Aiming.Aimbot_WallCheck, Aiming.Aimbot_ShowFOVCircle and Aiming.Aimbot_FOVCircleFollowRecoil and GetRecoilPosition() or ScreenCenter
				local FOVRadius, MaxScore, LocalHeadPosition, Target, Entry, TargetVisible = Aiming.Aimbot_ShowFOVCircle and Aiming.Aimbot_FOVCircleRadius or math.huge, math.huge, GetLocalPosition(), nil, nil, false
				for _,_Entry in next, CachedPlayers do
					local ThirdPersonObject = _Entry._isEnemy and _Entry._thirdPersonObject
					if not ThirdPersonObject then
						continue
					end

					local Part, Screen, Visible, Position = AimingModule:GetTarget(ThirdPersonObject._characterModelHash, AimbotPart, WallCheck, FOVOrigin, FOVRadius)
					if not Part then
						continue
					end

					local Score = (Screen - FOVOrigin).Magnitude + (Position - LocalHeadPosition).Magnitude * 0.15
					if Score < MaxScore then
						MaxScore, Target, Entry, TargetVisible = Score, Position, _Entry, Visible
					end
				end

				local _Cache = Target and (not WallCheck or TargetVisible) and MovementCache[Entry._player]
				if _Cache then
					local Current, Old, Velocity = _Cache[1], _Cache[15], Vector3.zero
					local Elapsed = Current and Old and Current.Time - Old.Time
					if Elapsed and Elapsed > 0.01 then
						Velocity = (Current.Head.Position - Old.Head.Position) / Elapsed
					end

					local Acceleration, Delta, Time = -BulletAcceleration, Target - Data.position, nil
					for _,Root in ipairs({SolvePolynomial(GetMagnitude(Acceleration) - BulletAccel * BulletAccel, 4 * (
						Acceleration:Dot(Velocity) - BulletAccel * Speed
					), 4 * (Acceleration:Dot(Delta) + GetMagnitude(Velocity) - Speed * Speed), 8 * Delta:Dot(Velocity), 4 * GetMagnitude(Delta))}) do
						if Root > 0 and (not Time or Root < Time) then
							Time = Root
						end
					end

					if Time then
						Cache.Direction = ((Delta + Time * Velocity + Time * Time / 2 * Acceleration) / (Time * Speed + Time * Time / 2 * BulletAccel)).Unit
					end
				end
			end
		end

		local Direction = Cache.Direction
		if Direction then
			Data.velocity, Data.acceleration = Direction * Speed, BulletAcceleration + Direction * BulletAccel
		end
		Cache[#Cache + 1] = Direction or Data.velocity / Speed
	end

	BulletTicket += 1
	TicketCache[Ticket] = {Ticket = BulletTicket, Players = {}, FirstHits = Miscellaneous.WeaponMods_InstantBullet and Extra.firstHits}

	local LocalBulletTracers = Visuals.Combat_LocalBulletTracers
	if LocalBulletTracers then
		Data.usingGlassHack = false
	end

	local Bullet = Original(Data)
	Bullet._destructor:add(function()
		TicketCache[Ticket] = nil
	end)

	if LocalBulletTracers then
		BulletTracerModule:Render(Data.position, Data.velocity.Unit * 1000, "Combat_LocalBulletTracer")
		for _,Object in next, Bullet._beamObject.beams do
			Object.Enabled = false
		end
	end

	if Miscellaneous.WeaponMods_InstantBullet then
		local Steps = math.max(1, math.ceil(Data.life * 240))
		local Delta = Data.life / Steps
		for _ = 1, Steps do
			if Bullet.pendingDeletion then
				break
			end
			Bullet:step(Delta, true)
		end
		Bullet.pendingDeletion = true
	end

	return Bullet
end)

Module.Players.PlayerRemoving:Connect(function(Player)
	LastHit[Player] = nil
	ESPModule:Clear(Player)
	MovementCache[Player] = nil
end)

for _,Child in Camera:GetChildren() do
	ViewModelModule:OnCameraChildAdded(Child)
end

Camera.ChildAdded:Connect(function(Child)
	ViewModelModule:OnCameraChildAdded(Child)
end)

Module.__get("CharacterEvents").onSpawned:connect(function()
	ViewModelModule:Refresh()
end)

local MuzzleFlashColorCache = setmetatable({}, {__mode = "k"})
Effects.muzzleflash = function(Barrel, Hide, Scale)
	for Model, Cache in next, MuzzleFlashColorCache do
		if Model.PrimaryPart.Position.Y == 1e9 then
			for Item, Color in next, Cache do
				Item.Color = Color
			end
			MuzzleFlashColorCache[Model] = nil
		end
	end

	if not Miscellaneous.WeaponMods_CustomMuzzleFlash then
		return MuzzleFlash(Barrel, Hide, Scale or 1)
	end

	local Weapon = Barrel and GetActiveWeapon()
	if not Weapon or Weapon._barrelPart ~= Barrel then
		return MuzzleFlash(Barrel, Hide, Scale or 1)
	end
	MuzzleFlash(Barrel, Hide, (Scale or 1) * Miscellaneous.WeaponMods_MuzzleFlashSize)

	local Origin, Color = Barrel.Position, Miscellaneous.WeaponMods_MuzzleFlashColor
	for _,Child in MiscFolder:GetChildren() do
		if Child.Name == "MuzzleFlash" and (Child:GetPivot().Position - Origin).Magnitude < 1.5 then
			local Cache = MuzzleFlashColorCache[Child]
			if not Cache then
				Cache = {}
				MuzzleFlashColorCache[Child] = Cache
			end

			for _,Item in Child:QueryDescendants("BasePart, ParticleEmitter") do
				Cache[Item] = Cache[Item] or Item.Color
				if Item:IsA("ParticleEmitter") then
					Item.Color = ColorSequence.new(Color)
				else
					Item.Color = Color
				end
			end
		end
	end
end

ns__hooktablefunction(Module.__get("ThirdPersonObject"), "popCharacterModel", function(Original, self)
	local Character, Position = Original(self)
	LastHit[self._player] = (Visuals.Combat_HitGhosts and LastHit[self._player] and RenderHitGhost(Character:Clone())) or nil
	return Character, Position
end)

ReplicatedStorage:WaitForChild("RemoteEvent", 6e9).OnClientEvent:Connect(function(Packet, ...)
	if Packet == "startvotekick" then
		if Miscellaneous.Extras_HopOnVotekick and (...) == LocalPlayer.Name then
			local TeleportService = game:GetService("TeleportService")
			if not pcall(TeleportService.Teleport, TeleportService, game.PlaceId) then
				for _ = 1, 4 do
					if pcall(TeleportService.Teleport, TeleportService, game.PlaceId) then
						break
					end
					task.wait(0.5)
				end
			end
		end
	elseif Packet == "swapweapon" then
		if (...) ~= LocalPlayer or not ThirdPersonModule.Object or (select(2, ...)) == 4 then
			return
		end

		ThirdPersonModule.Object:_cleanActiveWeaponParts()
		local Model = FakeReplicationObject:popWeaponModel((select(2, ...)))
		if Model then
			Model:Destroy()
		end

		FakeReplicationObject:swapWeapon((select(2, ...)), select(3, ...))
		FakeReplicationObject:setActiveIndex((select(2, ...)))
		ThirdPersonModule.Object:equip((select(2, ...)))
	elseif Packet == "newbullets" then
		local Data = (...)
		local Player = Data.player
		if Player == LocalPlayer then
			return
		end

		local Entry = CachedPlayers[Player]
		if not Entry then
			return
		end

		local IndexName = Entry._isEnemy and "Combat_EnemyBulletTracers" or "Combat_TeamBulletTracers"
		if not Visuals[IndexName] then
			return
		end

		local Origin, Bullets = Data.firepos, Data.bullets
		IndexName = string.sub(IndexName, 1, -2)
		for Index = 1, #Bullets do
			BulletTracerModule:Render(Origin, Bullets[Index].velocity * 1000, IndexName)
		end
	elseif Packet == "newgrenade" then
		if Visuals.ESPVisuals_MasterSwitch and Visuals.ESPVisuals_GrenadeTags and select(3, ...)[1] then
			ESPModule.Grenades[#ESPModule.Grenades + 1] = {Nodes = select(3, ...), Fuse = select(5, ...) - NetworkClient.getPing() * 0.5, Name = select(2, ...), Start = os.clock()}
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
		if (...) == LocalPlayer then
			return
		end

		if Miscellaneous.HitLogs_Enabled then
			local Text = {"Hit " .. (...).Name}

			if Miscellaneous.HitLogs_ShowPart and select(2, ...) then
				table.insert(Text, "in the " .. select(2, ...))
			end

			if Miscellaneous.HitLogs_ShowDamage then
				table.insert(Text, "for " .. math.floor(select(4, ...) or 0) .. " damage")
			end

			if Miscellaneous.HitLogs_ShowDistance then
				table.insert(Text, "from " .. math.floor((GetLocalPosition() - select(3, ...)).Magnitude) .. " studs away")
			end

			Library:Notify(table.concat(Text, " "), 3)
		end

		if Visuals.Combat_HitMarkers then
			table.insert(HitMarkerModule.Active, {
				Position = select(3, ...),
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
			Part.CFrame = CFrame.new((select(3, ...)))
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
			local Entry = CachedPlayers[(...)]
			if Entry then
				local ThirdPersonObject = Entry._thirdPersonObject
				if ThirdPersonObject then
					RenderHitGhost(ThirdPersonObject._characterModel:Clone())
				end
			end
		end
	end
end)

RunService.PreRender:Connect(function(DeltaTime)
	ImDrawing.NewFrame()
	Library:UpdateWatermark()

	CanSeeFrameCounter += 1
	table.clear(CanSeeCache)

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
		local Ghost = HitGhosts[Index]
		local Progress = (Ghost.Time - Now) / Ghost.Duration
		if Progress <= 0 then
			Ghost.Model:Destroy()
			table.remove(HitGhosts, Index)
		else
			local Transparency = 1 - Progress
			for _,Part in Ghost.Parts do
				Part.Transparency = Transparency
			end
		end
	end

	AimingModule:UpdateAimbot(LocalHeadPosition, Now)
	ESPModule:Update(LocalHeadPosition, Now)
	CrosshairModule:Update(DeltaTime)

	if Aiming.Aimbot_AutoFire and not RoundSystemClientInterface.roundLock and not (Aiming.RageBot_Enabled and Aiming.RageBot_BlockShooting) then
		AimingModule:UpdateAutoFire(Now)
	elseif AimingModule.Weapon or AimingModule.Start ~= 0 then
		AimingModule:SetFiring()
	end

	ImDrawing.EndFrame()
end)

local LastSpot = 0
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
	ThirdPersonModule:Update(DeltaTime)

	if not IsSpawned or RoundSystemClientInterface.roundLock then
		return
	end

	if Visuals.Combat_RadarHack then
		for Player, Entry in next, CachedPlayers do
			if Entry._isEnemy then
				local Status = GetPlayerStatusEntry(Player)
				if Status then
					Status.isSpotted = true
				end
			end
		end
	end

	if Visuals.Combat_AutoSpot and Now - LastSpot >= 0.05 then
		LastSpot = Now
		local Enemies = {}
		for Player, Entry in next, CachedPlayers do
			if Entry._isEnemy then
				table.insert(Enemies, Player)
			end
		end
		if #Enemies > 0 then
			NetworkClientSend(NetworkClient, "spotplayers", Enemies, GetTime())
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

	if Aiming.RageBot_Enabled then
		AimingModule:UpdateRageBot()
	end

	if Miscellaneous.KnifeAura_Enabled then
		KnifeAuraModule:Update()
	end
end)

local repupdate_LastTime, repupdate_ReverseTime
NetworkClient.send = function(self, Packet, ...)
	if Packet == "flaguser" or Packet == "debug" or Packet == "logmessage" then
		return
	elseif Packet == "repupdate" then
		local Now, Position, Angles, BarrelAngles, Time = tick(), ...
		if Miscellaneous.AntiAim_Enabled and Miscellaneous.AntiAim_FakeLag then
			if not FakeLag.LastRefreshPosition then
				FakeLag.LastRefreshPosition, FakeLag.LastRefreshTime = Position, Now
			end

			if (Position - FakeLag.LastRefreshPosition).Magnitude > Miscellaneous.AntiAim_FakeLagRefreshDistance or Now - FakeLag.LastRefreshTime > Miscellaneous.AntiAim_FakeLagRefreshRate then
				FakeLag.LastRefreshPosition, FakeLag.LastRefreshTime = Position, Now
				if Miscellaneous.AntiAim_FakeLagRandomizePosition then
					Position += Vector3.new((math.random() * 2 - 1) * Miscellaneous.AntiAim_FakeLagX, 0, (math.random() * 2 - 1) * Miscellaneous.AntiAim_FakeLagZ)
				end
			else
				return
			end
		else
			FakeLag.LastRefreshPosition, FakeLag.LastRefreshTime = nil, nil
		end

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

		if Miscellaneous.AntiAim_Enabled then
			Angles = GetAntiAimAngles(Angles)
			BarrelAngles = Angles * 0.99
		end

		FakeLag.LastSentPosition = Position
		return NetworkClientSend(self, Packet, Position, Angles, BarrelAngles, Time)
	elseif Packet == "spawn" then
		IsSpawned, ThirdPersonModule.IsSpawned = true, true
		table.clear(FakeLag)
		return NetworkClientSend(self, Packet, ...)
	end

	if ThirdPersonModule.Object then
		if Packet == "equip" then
			if (...) ~= 4 then
				FakeReplicationObject:setActiveIndex((...))
				ThirdPersonModule.Object:equip((...))
			end
			return NetworkClientSend(self, Packet, ...)
		elseif Packet == "stab" then
			LastFire = os.clock()
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
		local Cache = AimingModule.SilentCache
		AimingModule.SilentCache, LastFire = nil, os.clock()

		local FirstHits
		for Index = 1, Count do
			local Bullet = Bullets[Index]
			if Cache then
				Bullet[1] = Cache[Index]
			end

			local Entry = TicketCache[Bullet[2]]

			if Entry then
				Bullet[2] = Entry.Ticket
				FirstHits = Entry.FirstHits or FirstHits
			end
		end

		if Count == 0 then
			return
		end

		if FirstHits then
			for _,Hit in ipairs(FirstHits) do
				Hit[5] = math.max(Hit[5], Time)
			end
		end

		if ThirdPersonModule.Object then
			ThirdPersonModule.Object:kickWeapon(false, nil, 0, 0)
		end

		return NetworkClientSend(self, Packet, UniqueId, BulletData, Time)
	elseif Packet == "bullethit" then
		local UniqueId, Player, Position, PartName, Ticket, Time = ...
		local Bullet = TicketCache[Ticket]
		if Bullet then
			Ticket = Bullet.Ticket
			if Bullet.Players[Player] then
				return
			end
			Bullet.Players[Player] = true
		end

		LastHit[Player] = true
		NetworkClientSend(self, Packet, UniqueId, Player, Position, PartName, Ticket, Time)

		if Aiming.Aimbot_Enabled and Aiming.Aimbot_Type == "Silent" and Aiming.Aimbot_Collateral then
			for _Player, Entry in next, CachedPlayers do
				if _Player == Player or not Entry._isEnemy then
					continue
				end

				local BulletPlayers = Bullet and Bullet.Players
				if BulletPlayers and BulletPlayers[_Player] then
					continue
				end

				if (Entry._receivedPosition - Position).Magnitude <= Aiming.Aimbot_CollateralRadius then
					if BulletPlayers then
						BulletPlayers[_Player] = true
					end
					LastHit[_Player] = true
					NetworkClientSend(self, Packet, UniqueId, _Player, Position, PartName, Ticket, Time)
				end
			end
		end
		return
	elseif Packet == "breakwindow" then
		local Window, Ticket = ...
		local Bullet = TicketCache[Ticket]
		return NetworkClientSend(self, Packet, Window, Bullet and Bullet.Ticket or Ticket, select(3, ...))
	elseif Packet == "gameModeEvent" and select(2, ...) == "bulletHitFlag" then
		local GameMode, Action, Ticket = ...
		local Bullet = TicketCache[Ticket]
		return NetworkClientSend(self, Packet, GameMode, Action, Bullet and Bullet.Ticket or Ticket, select(4, ...))
	elseif Packet == "knifehit" then
		LastHit[(...)] = true
	elseif Packet == "stab" then
		LastFire = os.clock()
	elseif Packet == "newgrenade" then
		local Position, Velocity, Time, Fuse = ...
		if Aiming.Aimbot_RedirectGrenade and IsSpawned and AimbotState.TargetPart and (not Aiming.Aimbot_WallCheck or AimbotState.IsTargetVisible) then
			local _Velocity, _Fuse = GrenadeModule:GetVelocity(AimbotState.TargetPart.Position, Position)
			if _Velocity then
				Velocity = _Velocity
				if _Fuse then
					Fuse = _Fuse
				end
			end
		end
		Fuse = GrenadeModule:GetFuse(Position, Velocity, Fuse)
		return NetworkClientSend(self, Packet, Position, Velocity, Time, Fuse)
	elseif (Packet == "falldamage" and Miscellaneous.Movement_NoFallDamage) or (Packet == "changeCamo" and Miscellaneous.ClientSessionUnlocks_CamosUnlocked) or (Packet == "changeweapon" and (...) == "Knife" and Miscellaneous.ClientSessionUnlocks_KnivesUnlocked) or (Packet == "changeAttachment" and Miscellaneous.ClientSessionUnlocks_AttachmentsUnlocked) then
		return
	end

	return NetworkClientSend(self, Packet, ...)
end

local BloomEffect = ns__cloneref(Instance.new("BloomEffect"))
BloomEffect.Enabled = false
BloomEffect.Parent = Lighting

Library:BuildUI({Aiming, Visuals, Miscellaneous, Settings}, {LightingCache, OnDeadBody,
	function(Value)
		if not Value then
			for _,Setting in {"Ambient", "OutdoorAmbient", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness"} do
				Lighting[Setting] = Visuals["Lighting_" .. Setting]
			end
			return
		end

		for Property, OriginalValue in next, LightingCache.OriginalValues do
			Lighting[Property] = OriginalValue
		end
	end, function()
		BloomEffect.Intensity = Visuals.Lighting_BloomIntensity
		BloomEffect.Size = Visuals.Lighting_BloomSize
		BloomEffect.Threshold = Visuals.Lighting_BloomThreshold
		BloomEffect.Enabled = Visuals.Lighting_Bloom
	end, ViewModelModule, CustomSounds, Effects.breakwindow, PlaySoundId, {
	"None", "Osu", "MLG", "Bonk", "Rust", "Metal", "Skeet", "Quack", "Katana", "Neverlose",
	"Undertale", "Jet Set Radio", "TF2 Critical", "TF2 Frying Pan", "TF2 Alternative"
}, AimingModule, GrenadeModule, CacheMultiPoint, CacheFireScan}, {Camera, Lighting, DeadBodyFolder, Module.Method}, {PlayerDataClientInterface.getPlayerData, PlayerDataUtils.getCasePacketData}, Module.ExecutorName)

pcall(function()
	local Request = not isfile("NikoletoScripts/PhantomWare/Cache/Discord.nscache") and (httprequest or http_request or request)
	if Request then
		if pcall(Request, {
			Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST", Headers = {["Content-Type"] = "application/json", Origin = "https://discord.com"},
			Body = HttpService:JSONEncode({cmd = "INVITE_BROWSER", nonce = HttpService:GenerateGUID(false), args = {code = "DsGCKtxxEN"}})
		}) then
			writefile("NikoletoScripts/PhantomWare/Cache/Discord.nscache", "DsGCKtxxEN")
		end
	end
end)
