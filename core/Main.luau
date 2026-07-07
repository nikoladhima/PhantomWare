if getgenv().ns__PhantomWare__Executed then
	return
end
getgenv().ns__PhantomWare__Executed = true
pcall(clearteleportqueue or clear_teleport_queue)

local Players = game:GetService("Players")
local LocalPlayer = (function()
	local LocalPlayer = Players.LocalPlayer
	return (LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")):WaitForChild("MenuScreenGui", 9e9) and LocalPlayer
end)()

local ExecutorName, ns__Modules, ns__Count = identifyexecutor and identifyexecutor() or (getexecutorname and getexecutorname()), nil, 0
while true do
	if ns__Count >= 10 then
		break
	end

	local ReplicationInterface = ns__Modules and ns__Modules.ReplicationInterface
	if ReplicationInterface and ReplicationInterface.operateOnAllEntries then
		break
	end

	for _,Value in next, getgc(true) do
		if type(Value) == "table" and rawget(Value, "ScreenCull") and rawget(Value, "NetworkClient") then
			ns__Modules = {}
			for Name, Data in next, Value do
				ns__Modules[Name] = type(Data) == "table" and Data.module or Data
			end
		end
	end

	ns__Count += 1
	task.wait(0.5)
end

if not ns__Modules then
	getgenv().ns__PhantomWare__Executed = false
	pcall(setfflag, "DebugRunParallelLuaOnMainThread", "True")
	LocalPlayer:Kick("Exploit not supported.\nReason: Error while accessing Game Modules, please make a ticket in the discord server immediately." .. (function()
		return ((setclipboard and pcall(setclipboard, "discord.gg/DwRT2nH93D")) and "" or "") .. "\ndiscord.gg/DwRT2nH93D"
	end)())
    return
elseif not ns__Modules.ReplicationInterface then
	writefile("NikoletoScripts/PhantomWare/Logs/Log_" .. os.date("%Y-%m-%d_%H-%M-%S") .. ".nslog", "[" .. (ExecutorName or "Unknown") .. " | " .. os.date(
		"%Y-%m-%d | %H:%M:%S"
	) .. "] Module Dump (" .. (function()
		local Count = 0
		for _ in next, ns__Modules do
			Count += 1
		end
		return tostring(Count)
	end)() .. "): {\n" .. (function()
		local Text = {}
		for Name, Data in next, ns__Modules do
			table.insert(Text, "    " .. tostring(Name) .. " = " .. (type(Data) == "table" and "{module = " .. (Data.module or "<nil>") .. "}" or tostring(Data)))
		end
		return table.concat(Text, ",\n")
	end)() .. "\n}")

	getgenv().ns__PhantomWare__Executed = false
	pcall(setfflag, "DebugRunParallelLuaOnMainThread", "True")

    LocalPlayer:Kick("Exploit not supported.\nReason: Error while accessing ReplicationInterface, please make a ticket in the discord server immediately." .. (function()
		return (pcall(setclipboard, "discord.gg/DwRT2nH93D") and "" or "") .. "\ndiscord.gg/DwRT2nH93D"
	end)())
    return
end

local ns__cloneref = cloneref or clone_ref or clonereference or clone_reference or function(Function)
    return Function
end

local VirtualInputManager = ns__cloneref(Instance.new("VirtualInputManager"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = ns__cloneref(game:GetService("CoreGui"))
local Terrain = ns__cloneref(workspace.Terrain)

local PlayersFolder = workspace:WaitForChild("Players", 9e9)
local IgnoreFolder = workspace:WaitForChild("Ignore", 9e9) 
local DeadBodyFolder = IgnoreFolder:WaitForChild("DeadBody", 9e9)
local RootsFolder = workspace:WaitForChild("Roots", 9e9)
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")

local AimingRaycastParams = RaycastParams.new()
AimingRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
AimingRaycastParams.FilterDescendantsInstances = {IgnoreFolder, PlayersFolder, RootsFolder, Camera, Terrain}

local TransparentRaycastParams = RaycastParams.new()
TransparentRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local BulletRaycastParams = RaycastParams.new()
BulletRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
BulletRaycastParams.FilterDescendantsInstances = {IgnoreFolder, Camera, Terrain}

local GrenadeRaycastParams = RaycastParams.new()
GrenadeRaycastParams.FilterType = Enum.RaycastFilterType.Include
GrenadeRaycastParams.FilterDescendantsInstances = {workspace:WaitForChild("Map", 9e9)}

local function SetProperty(Object, Property, Value)
	if Object[Property] ~= Value then
		Object[Property] = Value
	end
end

local DarkerColorCache = setmetatable({}, {__mode = "kv", __index = function(self, Color)
	local DarkerColor = Color3.new(Color.R * 0.85, Color.G * 0.85, Color.B * 0.85)
	rawset(self, Color, DarkerColor)
	return DarkerColor
end})

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

	if (...) then
		for _,Child in next, {...} do
			Child.Parent = Object
		end
	end

	return Object
end

local function CreateDrawing(Type, Properties)
	local DrawingObject = Drawing.new(Type)
	if Properties then
		for Property, Value in next, Properties do
			if Property == "NumSides" or Property == "Filled" then
				pcall(function()
					DrawingObject[Property] = Value
				end)
				continue
			end
			DrawingObject[Property] = Value
		end
	end
	return DrawingObject
end

local AimbotTarget = nil
local AimbotTargetPart = nil
local IsAimbotInputActive = false
local IsAimbotLocking = false
local IsAimbotTargetVisible = false

local RageBotNextShot = 0
local IsRageBotInputActive = false

local Aiming = {
	Aimbot_Enabled = false,
	Aimbot_Keybind = "None",

	Aimbot_Type = "Camera",
	Aimbot_Part = "Head",
	Aimbot_PartPriorityOrder = {"Head", "Torso", "Arms", "Legs"},

	Aimbot_AutoFire = false,
	Aimbot_WallCheck = false,
	Aimbot_Smoothness = 3,

	Aimbot_DeathNotification = true,

	Aimbot_ShowFOV = true,
	Aimbot_FOVColor = Color3.fromRGB(255, 255, 255),
	Aimbot_FOVOpacity = 0.5,
	Aimbot_FOVRadius = 150,

	Aimbot_TargetTracer = true,
	Aimbot_TargetTracerColor = Color3.fromRGB(255, 255, 255),

	RageBot_Enabled = false,
	RageBot_Keybind = "None",

	RageBot_Part = "Head",
	RageBot_HitboxPriorityOrder = {"Head", "Torso", "Arms", "Legs"},

	RageBot_WallPenetrationDetection = true,
	RageBot_IgnoreBulletTracers = false
}

local IsThirdPersonActive = false
local Visuals = {
	EnemyESP_MasterEnabled = true,
	EnemyESP_MasterOpacity = 100,

	EnemyESP_Chams = false,
	EnemyESP_ChamsStyle = "Solid",
	EnemyESP_ChamsColor = Color3.fromRGB(255, 0, 0),
	EnemyESP_ChamsRendering = {Fill = true, Outline = true},
	EnemyESP_ChamsVisibleColor = Color3.fromRGB(0, 255, 0),
	EnemyESP_ChamsOccluded = false,

	EnemyESP_Boxes = false,
	EnemyESP_BoxColor = Color3.fromRGB(255, 255, 255),
	EnemyESP_BoxThickness = 1.5,

	EnemyESP_Healthbars = false,
	EnemyESP_HealthbarColor = Color3.fromRGB(0, 255, 0),
	EnemyESP_HealthbarWidth = 5,

	EnemyESP_HeadTags = false,
	EnemyESP_HeadTagElements = {Name = true, Health = true, Distance = true, Visibility = true},
	EnemyESP_TagColor = Color3.fromRGB(255, 255, 255),
	EnemyESP_TagSize = 13,

	EnemyESP_Tracers = false,
	EnemyESP_TracerColor = Color3.fromRGB(255, 255, 255),
	EnemyESP_TracerTarget = "Torso",
	EnemyESP_TracerOrigin = "Bottom",
	EnemyESP_TracerThickness = 1.5,

	EnemyESP_Dots = false,
	EnemyESP_DotColor = Color3.fromRGB(255, 255, 255),
	EnemyESP_DotSize = 3,

	Combat_BulletTracers = false,
	Combat_BulletTracerColor = Color3.fromRGB(255, 255, 255),
	Combat_BulletTracerAlpha = 0.85,
	Combat_BulletTracerFadeMode = "Width",
	Combat_BulletTracerType = "Beam",
	Combat_BulletTracerThickness = 3.5,
	Combat_BulletTracerDuration = 0.55,

	Combat_LightningKillEffectEnabled = false,
	Combat_LightningKillEffectColor = Color3.fromRGB(255, 255, 255),

	Combat_HitMarkerEnabled = false,
	Combat_HitMarkerColor = Color3.fromRGB(255, 255, 255),
	Combat_HitMarkerStyle = "X",
	Combat_HitMarkerSize = 8,
	Combat_HitMarkerGap = 3,
	Combat_HitMarkerDuration = 0.5,
	Combat_HitMarkerSpin = false,
	Combat_HitMarkerSpinSpeed = 5,

	Combat_GrenadeTrajectory = false,
	Combat_GrenadeTrajectoryColor = Color3.fromRGB(255, 165, 0),
	Combat_GrenadeTrajectoryImpactColor = Color3.fromRGB(255, 50, 50),
	Combat_GrenadeTrajectoryMode = "2D",
	Combat_GrenadeTrajectoryBounces = 1,
	Combat_GrenadeTrajectoryThickness = 2,

	Combat_RadarHack = false,

	Camera_ThirdPersonView = false,
	Camera_ThirdPersonView_Keybind = "None",
	Camera_ThirdPersonShowCharacter = false,
	Camera_ThirdPersonShowCharacterWhileAiming = false,
	Camera_ThirdPersonApplyAntiAimToCharacter = true,
	Camera_ThirdPersonOffsetX = 0,
	Camera_ThirdPersonOffsetY = 0,
	Camera_ThirdPersonOffsetZ = 7,
	Camera_ThirdPersonCameraCollision = true,

	Camera_FOVModificationEnabled = false,
	Camera_FOVValue = 120,

	Lighting_ModifyLighting = false,
	Lighting_Ambient = Color3.fromRGB(255, 255, 255),
	Lighting_OutdoorAmbient = Color3.fromRGB(255, 255, 255),
	Lighting_ExposureCompensation = 0,
	Lighting_EnvironmentDiffuseScale = 0,
	Lighting_EnvironmentSpecularScale = 0,
	Lighting_ShadowSoftness = 1,

	Lighting_Flashlight = false,
	Lighting_FlashlightColor = Color3.fromRGB(255, 255, 255),
	Lighting_FlashlightBrightness = 4,
	Lighting_FlashlightRange = 60,
	Lighting_FlashlightAngle = 70,

	Viewmodel_Chams = false,
	Viewmodel_ChamsTargets = {Arms = true, Weapon = true},
	Viewmodel_ChamsType = "ForceField",
	Viewmodel_ChamsColor = Color3.fromRGB(100, 0, 255),
	Viewmodel_ChamsTranslucent = false,
	Viewmodel_ChamsArmsOccluded = false,
	Viewmodel_ChamsWeaponOccluded = false,
	Viewmodel_NoSleeves = false
}

local Miscellaneous = {
	GunMods_NoWalkSway = false,
	GunMods_NoGunSway = false,
	GunMods_NoRecoil = false,
	GunMods_InstantReload = false,

	Movement_NoFallDamage = false,
	Movement_BunnyHop = false,

	Movement_AntiAimEnabled = false,

	Movement_AntiAimYaw = false,
	Movement_AntiAimYawAmount = 180,
	Movement_AntiAimYawMode = "Relative",

	Movement_AntiAimPitch = false,
	Movement_AntiAimPitchAmount = 180,
	Movement_AntiAimPitchMode = "Relative",

	Movement_AntiAimSpinBot = false,
	Movement_AntiAimSpinSpeed = 360,
	Movement_AntiAimSpinDirection = "Right",

	Movement_AntiAimJitter = false,
	Movement_AntiAimJitterSpeed = 6,

	HitLogs_Enabled = false,
	HitLogs_ShowDamage = false,
	HitLogs_ShowDistance = false,

	SoundOverride_ShootSound = "None",
	SoundOverride_HitSound = "None",
	SoundOverride_KillSound = "None",
	SoundOverride_GotHitSound = "None",

	RagdollEffects_Mode = "None",
	RagdollEffects_LaunchForce = 150,
	RagdollEffects_FlingForce = 150,
	RagdollEffects_FloatSpeed = 10,

	ClientSessionUnlocks_AttachmentsUnlocked = false,
	ClientSessionUnlocks_KnivesUnlocked = false,
	ClientSessionUnlocks_CamosUnlocked = false
}

local Settings = {
	Advanced_ESPFramerateCap = false,
	Advanced_ESPFPSCapValue = 360,

	Advanced_MultiPointEnabled = true,
	Advanced_MultiPointScale = 2,
	Advanced_MultiPointLayers = 2
}

local LightingCache = {
	OriginalValues = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ExposureCompensation = Lighting.ExposureCompensation,
		EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		ShadowSoftness = Lighting.ShadowSoftness
	},
	Connections = {}
}
local MovementCache = table.create(Players.MaxPlayers)

local function RefreshLighting(Revert)
	if Revert then
		for Property, OriginalValue in next, LightingCache.OriginalValues do
			Lighting[Property] = OriginalValue
		end
	else
		Lighting.Ambient = Visuals.Lighting_Ambient
		Lighting.OutdoorAmbient = Visuals.Lighting_OutdoorAmbient
		Lighting.ExposureCompensation = Visuals.Lighting_ExposureCompensation
		Lighting.EnvironmentDiffuseScale = Visuals.Lighting_EnvironmentDiffuseScale
		Lighting.EnvironmentSpecularScale = Visuals.Lighting_EnvironmentSpecularScale
		Lighting.ShadowSoftness = Visuals.Lighting_ShadowSoftness
	end
end

local function ns__require(Module)
	local Source = ns__Modules[Module]
	if not Source then
		repeat task.wait(0.15) until ns__Modules[Module]
		return ns__Modules[Module]
	end
	return Source
end

local WeaponControllerInterface = ns__require("WeaponControllerInterface")
local PlayerDataClientInterface = ns__require("PlayerDataClientInterface")
local PlayerStatusInterface = ns__require("PlayerStatusInterface")
local ReplicationInterface = ns__require("ReplicationInterface")
local CharacterInterface = ns__require("CharacterInterface")
local _,CameraInterface = coroutine.resume(coroutine.create(function(CameraInterface)
	pcall(function()
		local FunctionEnvironment = getfenv(CameraInterface.setCameraType)
		FunctionEnvironment.warn = function() end
		FunctionEnvironment.print = function() end
	end)
	return CameraInterface
end), ns__require("CameraInterface"))

local ReplicationObject = ns__require("ReplicationObject")
local PlayerDataUtils = ns__require("PlayerDataUtils")
local PublicSettings = ns__require("PublicSettings")
local RecoilSprings = ns__require("RecoilSprings")
local FirearmObject = ns__require("FirearmObject")
local NetworkClient = ns__require("NetworkClient")
local BulletObject = ns__require("BulletObject")
local AudioSystem = ns__require("AudioSystem")
local BulletCheck = ns__require("BulletCheck")
local ScreenCull = ns__require("ScreenCull")
local MuzzleFlash = ns__require("Effects").muzzleflash
local FireImpulse = ns__require("HudCrosshairsInterface").fireImpulse

local NetworkClientSend = NetworkClient.send
local GetLocalCharacter = CharacterInterface.getCharacterObject
local GetActiveCamera = CameraInterface.getActiveCamera
local PlayGameSound = AudioSystem.play
local GetPlayerStatusEntry = PlayerStatusInterface.getEntry
local GetPlayerEntry = ReplicationInterface.getEntry
local OperateOnAllEntries = ReplicationInterface.operateOnAllEntries

local function GetActiveWeapon()
	local ActiveWeaponController = WeaponControllerInterface.getActiveWeaponController()
	if ActiveWeaponController then
		return ActiveWeaponController:getActiveWeapon()
	end
end

local function GetCharacterModelHash(ThirdPersonObject)
	return ThirdPersonObject and ThirdPersonObject._characterModelHash
end

local LocalHead = nil
local function GetLocalCFrame()
	if not LocalHead or not LocalHead.Parent then
		for _,Child in next, IgnoreFolder:GetChildren() do
			local Head = Child:IsA("Model") and Child:FindFirstChild("Head")
			if Head then
				LocalHead = Head
				return Head.CFrame
			end
		end
		return Camera.CFrame
	end
	return LocalHead.CFrame
end
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

local function GetTrajectory(Origin, Acceleration, Target, Speed, Velocity)
	local TimeToHit = (Target - Origin).Magnitude / Speed
	local Direction

	for _ = 1, 5 do
		local Offset = ((Target + (Velocity * TimeToHit)) - (0.5 * Acceleration * TimeToHit * TimeToHit)) - Origin
		local Magnitude = Offset.Magnitude
		TimeToHit = Magnitude / Speed
		if Magnitude > 0 then
			Direction = Offset.Unit
		end
	end

	if Direction then
		return Direction * Speed
	end
end

local function GetBulletVelocity(Origin, Target, Speed, Acceleration, BulletAccelerationTerm)
	local Delta = Target - Origin
	local QuadraticB, QuadraticC, TimeSquared1, TimeSquared2 = 4 * (
		Acceleration:Dot(Delta) - Speed * Speed
	), 4 * Delta:Dot(Delta), nil, nil

	if BulletAccelerationTerm > -1e-10 and BulletAccelerationTerm < 1e-10 and QuadraticB ~= 0 then
		TimeSquared1 = -QuadraticC / QuadraticB
	else
		local Discriminant = QuadraticB * QuadraticB - 4 * BulletAccelerationTerm * QuadraticC
		if Discriminant >= 0 then
			local Root, TwoA = math.sqrt(Discriminant), 2 * BulletAccelerationTerm
			TimeSquared1 = (-QuadraticB - Root) / TwoA
			TimeSquared2 = (-QuadraticB + Root) / TwoA
		end
	end

	local TimeToHit, Time1, Time2 = nil, (TimeSquared1 and TimeSquared1 > 0) and math.sqrt(TimeSquared1) or nil, (
		TimeSquared2 and TimeSquared2 > 0
	) and math.sqrt(TimeSquared2) or nil

	if Time1 and Time2 then
		TimeToHit = math.min(Time1, Time2)
	else
		TimeToHit = Time1 or Time2
	end

	if not TimeToHit then
		return
	end

	return (Delta - (TimeToHit * TimeToHit * 0.5) * Acceleration) / TimeToHit
end

local ViewportSize = Camera.ViewportSize
local ViewportSizeX, ViewportSizeY = ViewportSize.X, ViewportSize.Y
local ScreenXCenter, ScreenYCenter = ViewportSizeX * 0.5, ViewportSizeY * 0.5
local ScreenBottom, ScreenTop = Vector2.new(ScreenXCenter, ViewportSizeY), Vector2.new(ScreenXCenter, 0)
local ScreenCenter = Vector2.new(ScreenXCenter, ScreenYCenter)
local ScreenCenterX, ScreenCenterY = ScreenCenter.X, ScreenCenter.Y
local TwoPi, Quarter, NegativeQuarter = math.pi * 2, math.pi * 0.5, -(math.pi * 0.5)

local function WorldToViewportPoint(Position, KeepZ)
	local Screen, OnScreen = Camera:WorldToViewportPoint(Position)
	return Vector2.new(Screen.X, Screen.Y), OnScreen
end

local function TransparentRaycast(Origin, Direction, BaseFilter)
	local Excluded, RemainingDirection, RemainingOrigin = table.clone(BaseFilter.FilterDescendantsInstances), Direction, Origin
	for _ = 1, 8 do
		TransparentRaycastParams.FilterDescendantsInstances = Excluded
		local Result = workspace:Raycast(RemainingOrigin, RemainingDirection, TransparentRaycastParams)
		if not Result then
			return nil
		end

		local Hit = Result.Instance
		if Hit.Transparency > 0.9 then
			table.insert(Excluded, Hit)
			local FixedDirection = Direction.Unit * 0.01
			RemainingDirection = RemainingDirection - (Result.Position - RemainingOrigin) - FixedDirection
			RemainingOrigin = Result.Position + FixedDirection
			continue
		end

		return Result
	end
	return nil
end

local MultiPointCache = {}
local function GetOffsets(Points)
	local BasePoints = MultiPointCache[Points]
	if BasePoints then
		return BasePoints
	end

	local Step = 2 / Points
	local GoldenAngle = math.pi * (3 - math.sqrt(5))
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

function CanSee(Part, Layers)
	local Entry = CanSeeCache[Part]
	if Entry and Entry[2] == CanSeeFrameCounter and Entry[3] == Layers then
		return Entry[1]
	end

	local Origin = GetLocalPosition()
	local Position = Part.Position
	local Delta = Position - Origin

	if not TransparentRaycast(Origin, Delta, AimingRaycastParams) then
		CanSeeCache[Part] = GetCanSeeCache(true, Layers)
		return true
	end

	if not Settings.Advanced_MultiPointEnabled then
		CanSeeCache[Part] = GetCanSeeCache(false, Layers)
		return false
	end

	local PartCFrame = Part.CFrame
	local ObjectDelta = PartCFrame:VectorToObjectSpace(Origin - Position)
	local ObjectMagnitude = ObjectDelta.Magnitude

	if ObjectMagnitude <= 1e-6 then
		CanSeeCache[Part] = GetCanSeeCache(false, Layers)
		return false
	end

	local ViewDirection = ObjectDelta * (1 / ObjectMagnitude)
	local ViewDirectionX, ViewDirectionY, ViewDirectionZ = ViewDirection.X, ViewDirection.Y, ViewDirection.Z

	local HalfSize = Part.Size * 0.5
	local HalfSizeX, HalfSizeY, HalfSizeZ = HalfSize.X, HalfSize.Y, HalfSize.Z
	local Right, Up, Look = PartCFrame.RightVector, PartCFrame.UpVector, PartCFrame.LookVector

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

			if not TransparentRaycast(Origin, (Position + Right * (PointX * LayerScaleX) + Up * (
				PointY * LayerScaleY
			) + Look * (PointZ * LayerScaleZ)) - Origin, AimingRaycastParams) then
				CanSeeCache[Part] = GetCanSeeCache(true, Layers)
				return true
			end
		end
	end

	CanSeeCache[Part] = GetCanSeeCache(false, Layers)
	return false
end

local RageBotCache = {}
function RageBot_CanHit(Part, Layers)
	local Entry = RageBotCache[Part]
	if Entry and Entry[2] == CanSeeFrameCounter and Entry[3] == Layers then
		return Entry[1]
	end

	local Origin = GetLocalPosition()
	local Position = Part.Position
	local Delta = Position - Origin

	if not TransparentRaycast(Origin, Delta, AimingRaycastParams) then
		RageBotCache[Part] = GetCanSeeCache(true, Layers)
		return true
	end

	if not Settings.Advanced_MultiPointEnabled then
		RageBotCache[Part] = GetCanSeeCache(false, Layers)
		return false
	end

	local PartCFrame = Part.CFrame
	local ObjectDelta = PartCFrame:VectorToObjectSpace(Origin - Position)
	local ObjectMagnitude = ObjectDelta.Magnitude

	if ObjectMagnitude <= 1e-6 then
		RageBotCache[Part] = GetCanSeeCache(false, Layers)
		return false
	end

	local ViewDirection = ObjectDelta * (1 / ObjectMagnitude)
	local ViewDirectionX, ViewDirectionY, ViewDirectionZ = ViewDirection.X, ViewDirection.Y, ViewDirection.Z

	local HalfSize = Part.Size * 0.5
	local HalfSizeX, HalfSizeY, HalfSizeZ = HalfSize.X, HalfSize.Y, HalfSize.Z
	local Right, Up, Look = PartCFrame.RightVector, PartCFrame.UpVector, PartCFrame.LookVector

	local Offsets = GetOffsets(Settings.Advanced_MultiPointScale)
	local Count = #Offsets

	local ActiveLayers = math.clamp(math.floor(1 + math.log(1 + 4 / math.max(Delta.Magnitude, 0.1))), 1, Layers)
	for Layer = ActiveLayers, 1, -1 do
		local LayerScale = Layer / ActiveLayers
		local LayerScaleX, LayerScaleY, LayerScaleZ = LayerScale * HalfSizeX, LayerScale * HalfSizeY, LayerScale * HalfSizeZ
		for Index = 1, Count do
			local Point = Offsets[Index]
			local PointX, PointY, PointZ = Point.X, Point.Y, Point.Z

			if PointX * ViewDirectionX + PointY * ViewDirectionY + PointZ * ViewDirectionZ <= 0 then
				continue
			end

			if not TransparentRaycast(Origin, (Position + Right * (PointX * LayerScaleX) + Up * (PointY * LayerScaleY) + Look * (PointZ * LayerScaleZ)) - Origin, AimingRaycastParams) then
				RageBotCache[Part] = GetCanSeeCache(true, Layers)
				return true
			end
		end
	end

	RageBotCache[Part] = GetCanSeeCache(false, Layers)
	return false
end

function GetTargetPart(Character, AimbotPart, IsWallCheckOff)
	local Layers, Head, Torso, LeftArm, RightArm, LeftLeg, RightLeg = Settings.Advanced_MultiPointLayers, Character.Head, Character.Torso, Character["Left Arm"], Character["Right Arm"], Character["Left Leg"], Character["Right Leg"]
	if AimbotPart == "Head" then
		if not Head then
			return nil, nil, false
		end

		local Screen, OnScreen = WorldToViewportPoint(Head.Position)
		if not OnScreen then
			return nil, nil, false
		end

		local Status = CanSee(Head, Layers)
		if IsWallCheckOff or Status then
			return Head, Screen, Status
		end

		return nil, nil, false
	elseif AimbotPart == "Torso" then
		if not Torso then
			return nil, nil, false
		end

		local Screen, OnScreen = WorldToViewportPoint(Torso.Position)
		if not OnScreen then
			return nil, nil, false
		end

		local Status = CanSee(Torso, Layers)
		if IsWallCheckOff or Status then
			return Torso, Screen, Status 
		end
	
		return nil, nil, false
	elseif AimbotPart == "Priority" then
		for _,Name in ipairs(Aiming.Aimbot_PartPriorityOrder) do
			if Name == "Head" then
				if Head then
					local Screen, OnScreen = WorldToViewportPoint(Head.Position)
					if OnScreen then
						local Status = CanSee(Head, Layers)
						if IsWallCheckOff or Status then
							return Head, Screen, Status
						end
					end
				end
			elseif Name == "Torso" then
				if Torso then
					local Screen, OnScreen = WorldToViewportPoint(Torso.Position)
					if OnScreen then
						local Status = CanSee(Torso, Layers)
						if IsWallCheckOff or Status then
							return Torso, Screen, Status
						end
					end
				end
			else
				for _,Part in ipairs(Name == "Arms" and {LeftArm, RightArm} or {LeftLeg, RightLeg}) do
					if Part then
						local Screen, OnScreen = WorldToViewportPoint(Part.Position)
						if OnScreen then
							local Status = CanSee(Part, Layers)
							if IsWallCheckOff or Status then
								return Part, Screen, Status
							end
						end
					end
				end
			end
		end
		return nil, nil, false
	elseif AimbotPart == "Closest" then
		local BestPart, BestScreen, BestVisible, BestScore, Parts = nil, nil, false, math.huge, {Head, Torso, LeftArm, RightArm, LeftLeg, RightLeg}
		for Index = 1, 6 do
			local Part = Parts[Index]
			if not Part then
				continue
			end

			local Screen, OnScreen = WorldToViewportPoint(Part.Position)
			if not OnScreen then
				continue
			end

			local DeltaX, DeltaY = Screen.X - ScreenCenterX, Screen.Y - ScreenCenterY
			local Distance = DeltaX * DeltaX + DeltaY * DeltaY
			if Distance < BestScore then
				local Status = CanSee(Part, Layers)
				if IsWallCheckOff or Status then
					BestScore = Distance
					BestPart = Part
					BestScreen = Screen
					BestVisible = Status
				end
			end
		end
		return BestPart, BestScreen, BestVisible
	end
	return nil, nil, false
end

function Silent_GetClosest()
	local IsWallCheckOff = not Aiming.Aimbot_WallCheck
	local FOVRadius = Aiming.Aimbot_FOVRadius
	local MaxScore, AimbotPart = Aiming.Aimbot_ShowFOV and FOVRadius or math.huge, Aiming.Aimbot_Part
	local CenterX, CenterY, LocalHeadPosition = ScreenCenter.X, ScreenCenter.Y, GetLocalPosition()
	local BestPosition, BestEntry, BestPart

	OperateOnAllEntries(function(_,Entry)
		if not Entry._isEnemy or not Entry._alive then
			return
		end

		local Part, Screen, IsVisible = GetTargetPart(Entry._thirdPersonObject._characterModelHash, AimbotPart, IsWallCheckOff)
		if not Part or not Screen then
			return
		end

		local DeltaX, DeltaY = Screen.X - CenterX, Screen.Y - CenterY
		local Distance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
		if Distance > FOVRadius then
			return
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
	end)

	return BestPosition, BestEntry, BestPart
end

local HookRegistry = {}
local function ns__hookfunction(Register, Table, Index, Replacement, Info)
    local Helper, Original = Info and Info.Helper, Table[Index]
    Table[Index] = Helper and ((Info and Info.ReturnOriginal) and function(...)
		return Replacement(Helper, Original, ...)
	end or function(...)
		return Replacement(Helper, ...)
	end) or ((Info and Info.ReturnOriginal) and function(...)
		return Replacement(Original, ...)
	end or Replacement)
	HookRegistry[Index] = Register and {Table, Index, Original} or nil
    return Original
end
local function ns__restorefunction(Identifier)
	local Hook = HookRegistry[Identifier]
	if not Hook then
		return
	end
	Hook[1][Hook[2]] = Hook[3]
	HookRegistry[Identifier] = nil
end

ns__hookfunction(false, RecoilSprings, "applyImpulse", function(Original, ...)
	if Miscellaneous.GunMods_NoRecoil or (IsAimbotLocking and Aiming.Aimbot_Type ~= "Silent") then
		return
	end
	return Original(...)
end, {ReturnOriginal = true})

ns__hookfunction(false, FirearmObject, "reload", function(Original, self, ...)
	if IsRageBotInputActive or Miscellaneous.GunMods_InstantReload then
		local SpareCount = self._spareCount
		if SpareCount < 0 then
			return Original(self)
		end

		local MagSizeData = self._weaponData.magsize
		if SpareCount >= MagSizeData then
			self._spareCount -= (MagSizeData - self._magCount)
			self._magCount = MagSizeData
		else
			self._magCount = SpareCount
			self._spareCount = 0
		end
		return NetworkClientSend(NetworkClient, "reload")
	end
	return Original(self)
end, {ReturnOriginal = true})

local TicketCache = {}
local GlobalTicketCounter = 0
local TicketAddition = 0

local LastSilent = {
	Target = nil,
	Velocity = nil,
	Frame = 0
}

local IsSpawned = false
local IsFakeSpawned = false
local FakeReplicationObject = nil
local FakeThirdPersonObject = nil
local IsAutoFiring = false

ns__hookfunction(false, NetworkClient, "send", function(self, Packet, ...)
	if Packet == "flaguser" or Packet == "debug" or Packet == "logmessage" then
		return
	elseif Packet == "spawn" then
		GlobalTicketCounter = 0
		TicketAddition = 0
		IsFakeSpawned = true
		IsSpawned = true
	elseif Packet == "equip" then
		if FakeThirdPersonObject then
			local Slot = ...
			FakeReplicationObject:setActiveIndex(Slot)
			if Slot ~= 3 then
				FakeThirdPersonObject:equip(Slot)
			else
				FakeThirdPersonObject:equipMelee()
			end
		end
	elseif Packet == "stab" and FakeThirdPersonObject then
		FakeThirdPersonObject:stab()
	elseif Packet == "aim" and FakeThirdPersonObject then
		FakeThirdPersonObject:setAim(...)
	elseif Packet == "sprint" and FakeThirdPersonObject then
		FakeThirdPersonObject:setSprint(...)
	elseif Packet == "stance" and FakeThirdPersonObject then
		FakeThirdPersonObject:setStance(...)
	elseif Packet == "newbullets" then
		local UniqueId, BulletData, Time = ...
		local Bullets = BulletData.bullets
		GlobalTicketCounter = GlobalTicketCounter + #Bullets

		for _,Bullet in BulletData.bullets do
			Bullet[2] += TicketAddition
		end

		if IsAimbotInputActive and Aiming.Aimbot_Type == "Silent" then
			if LastSilent.Target and (os.clock() - LastSilent.Frame < 0.1) then
				local Direction = LastSilent.Velocity.Unit
				for _,Bullet in next, Bullets do
					Bullet[1] = Direction
				end
				LastSilent.Target = nil
				LastSilent.Velocity = nil
			else
				local Target, Entry = Silent_GetClosest()
				if Target and Entry then
					local Player = Entry._player
					if Target and MovementCache[Player] then
						local Cache = MovementCache[Player]
						local Current, Old, Velocity
						if Cache then
							Current = Cache[1]
							Old = Cache[15]
							
							if Current and Old then
								local CurrentTime, OldTime = Old.Time, Current.Time
								if (CurrentTime - OldTime) > 0.01 then
									Velocity = (Current.Position - Old.Position) / (CurrentTime - OldTime)
								end
							end
						end

						local Weapon = GetActiveWeapon()
						local ProjectileSpeed = BulletData.velocity and (
							Weapon and Weapon._weaponData.bulletspeed or BulletData.velocity.Magnitude
						) or 0
						local Trajectory = (GetTrajectory(BulletData.firepos, PublicSettings.bulletAcceleration, Target, ProjectileSpeed, Velocity or Vector3.zero)).Unit
						if Trajectory then
							for _,Bullet in next, Bullets do
								Bullet[1] = Trajectory
							end
						end
					end
				end
			end
		end

		if FakeThirdPersonObject then
			FakeThirdPersonObject:kickWeapon(nil, nil, 0, 0)
		end

		return NetworkClientSend(self, Packet, UniqueId, BulletData, Time)
	elseif Packet == "bullethit" then
		local UniqueId, Player, Position, PartName, Ticket, Time = ...
		Ticket += TicketAddition

		if TicketCache[Ticket] then
			return
		end

		TicketCache[Ticket] = true
		return NetworkClientSend(self, Packet, UniqueId, Player, Position, PartName, Ticket, Time)
	elseif Packet == "repupdate" then
		local Position, Angles,_,Time = ...
		if Angles and Miscellaneous.Movement_AntiAimEnabled then
			local X, Y, Z = Angles.X, Angles.Y, Angles.Z
			if Miscellaneous.Movement_AntiAimPitch then
				local Addition = math.rad(Miscellaneous.Movement_AntiAimPitchAmount) - Quarter
				X = Miscellaneous.Movement_AntiAimPitchMode == "Absolute" and Addition or math.clamp(X + Addition, NegativeQuarter, Quarter)
			end

			if Miscellaneous.Movement_AntiAimYaw then
				local Addition = math.rad(Miscellaneous.Movement_AntiAimYawAmount)
				Y = Miscellaneous.Movement_AntiAimYawMode == "Relative" and (Y + Addition) or Addition
			end

			if Miscellaneous.Movement_AntiAimSpinBot then
				Y += ((os.clock() * math.rad(Miscellaneous.Movement_AntiAimSpinSpeed)) % TwoPi) * (Miscellaneous.Movement_AntiAimSpinDirection == "Left" and 1 or -1)
			end

			if Miscellaneous.Movement_AntiAimJitter then
				Y += (math.floor(os.clock() * Miscellaneous.Movement_AntiAimJitterSpeed) % 2 == 0) and math.pi or 0
			end

			Angles = Vector3.new(X, Y, Z)
			return NetworkClientSend(self, Packet, Position, Angles, Angles * 0.99, Time)
		end
	elseif (Packet == "falldamage" and Miscellaneous.Movement_NoFallDamage) or (Packet == "changeCamo" and Miscellaneous.ClientSessionUnlocks_CamosUnlocked) or (Packet == "changeWeapon" and (...) == "Knife" and Miscellaneous.ClientSessionUnlocks_KnivesUnlocked) or (Packet == "changeAttachment" and Miscellaneous.ClientSessionUnlocks_AttachmentsUnlocked) then
		return
	end
	return NetworkClientSend(self, Packet, ...)
end)

ns__hookfunction(false, PlayerDataUtils, "getUnlocksData", function(Helper, Original, PlayerData)
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
end, {Helper = PlayerDataClientInterface.getPlayerData, ReturnOriginal = true})

ns__hookfunction(false, PlayerDataUtils, "ownsWeapon", function(Helper, Original, Player, WeaponName)
	return (Miscellaneous.ClientSessionUnlocks_KnivesUnlocked and Helper(WeaponName).baseWeaponData.type == "KNIFE") and true or Original(Player, WeaponName)
end, {Helper = ns__require("ContentInterface").getWeaponSource, ReturnOriginal = true})

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	ViewportSize = Camera.ViewportSize
	ViewportSizeX = ViewportSize.X
	ViewportSizeY = ViewportSize.Y
	ScreenXCenter = ViewportSizeX * 0.5
	ScreenYCenter = ViewportSizeY * 0.5
	ScreenBottom = Vector2.new(ScreenXCenter, ViewportSizeY)
	ScreenTop = Vector2.new(ScreenXCenter, 0)
	ScreenCenter = Vector2.new(ScreenXCenter, ScreenYCenter)
	ScreenCenterX, ScreenCenterY = ScreenCenter.X, ScreenCenterY.Y
end)

local ActiveBulletTracers = {}
local ActiveHitMarkers = {}

local SoundOptions = {"None", "Osu", "Pop", "MLG", "Ouch", "Fire", "Metal", "Neverlose", "Undertale", "Jet Set Radio", "TF2 Critical", "TF2 Alternative", "TF2 Frying Pan"}
local CustomSounds = {
	["None"] = "",
	["Osu"] = "rbxassetid://7172607676",
	["Pop"] = "rbxassetid://102822111971881",
	["MLG"] = "rbxassetid://109817519733426",
	["Ouch"] = "rbxassetid://136844926219636",
	["Fire"] = "rbxassetid://130412184952886",
	["Metal"] = "rbxassetid://8917041751",
	["Neverlose"] = "rbxassetid://18391691942",
	["Undertale"] = "rbxassetid://1471213022",
	["Jet Set Radio"] = "rbxassetid://97113622160405",
	["TF2 Critical"] = "rbxassetid://8255306220",
	["TF2 Alternative"] = "rbxassetid://2868331684",
	["TF2 Frying Pan"] = "rbxassetid://18922477538"
}

local PlaySoundId
PlaySoundId = ns__hookfunction(false, AudioSystem, "playSoundId", function(AssetId, Priority, Volume, ...)
	local ShootSound = Miscellaneous.SoundOverride_ShootSound
	if ShootSound == "None" then
		return PlaySoundId(AssetId, Priority, Volume, ...)
	end

	local ActiveWeapon = GetActiveWeapon()
	if ActiveWeapon and AssetId == ActiveWeapon._weaponData.firesoundid then
		return PlaySoundId(CustomSounds[ShootSound], Priority, Volume)
	end
end)

ns__hookfunction(false, AudioSystem, "playSound", function(Original, SoundName, ...)
	local Arguments = table.pack(...)
	if Miscellaneous.SoundOverride_HitSound ~= "None" and SoundName == "hitmarker" then
		return PlaySoundId(CustomSounds[Miscellaneous.SoundOverride_HitSound], 1, Arguments[3])
	elseif Miscellaneous.SoundOverride_KillSound ~= "None" and (SoundName == "killshot" or SoundName == "headshotkill") then
		return PlaySoundId(CustomSounds[Miscellaneous.SoundOverride_KillSound], 1, Arguments[3])
	elseif Miscellaneous.SoundOverride_GotHitSound ~= "None" and (SoundName == "crackSmall" or SoundName == "crackBig") then
		return PlaySoundId(CustomSounds[Miscellaneous.SoundOverride_GotHitSound], 1, Arguments[3])
	end
	return Original(SoundName, ...)
end, {ReturnOriginal = true})

local BeamCache = {}
local function ReleaseBeam(Beam)
	Beam.Parent = nil
	table.insert(BeamCache, Beam)
end

local AttachmentCache = {}
local GetAttachment, ReleaseAttachment = function()
	local Attachment = table.remove(AttachmentCache)
	if not Attachment then
		Attachment = ns__cloneref(Instance.new("Attachment"))
		Attachment.Name = "SoundAttachment"
	end
	Attachment.Parent = Terrain
	return Attachment
end, function(Attachment)
	Attachment.Parent = nil
	table.insert(AttachmentCache, Attachment)
end

local function GetRaycastPosition(Raycast)
	return Raycast and Raycast.Position
end

local function CreateBulletTracer(StartPosition, Direction)
	local Attachment0, Attachment1 = GetAttachment(), GetAttachment()
	Attachment0.Position = StartPosition
	Attachment1.Position = GetRaycastPosition(workspace:Raycast(StartPosition, Direction, BulletRaycastParams)) or (StartPosition + Direction)

	local Beam = table.remove(BeamCache)
	if not Beam then
		Beam = ns__cloneref(Instance.new("Beam"))
		Beam.Name = "SoundAttachment"
		Beam.FaceCamera = true
		Beam.TextureMode = Enum.TextureMode.Wrap
		Beam.TextureLength = 30
		Beam.LightEmission = 1
	end
	Beam.Parent = Terrain

	local Thickness = Visuals.Combat_BulletTracerThickness
	if Visuals.Combat_BulletTracerType == "Wavy" then
		Beam.Texture = "rbxassetid://446111271"
	else
		Thickness *= 0.05
		Beam.Texture = ""
	end

	Beam.Width0 = Thickness
	Beam.Width1 = Thickness
	Beam.Color = ColorSequence.new(Visuals.Combat_BulletTracerColor)
	Beam.Transparency = NumberSequence.new(1 - Visuals.Combat_BulletTracerAlpha)
	Beam.Attachment0 = Attachment0
	Beam.Attachment1 = Attachment1

	table.insert(ActiveBulletTracers, {
		StartTime = os.clock(),
		Duration = Visuals.Combat_BulletTracerDuration,
		Beam = Beam,
		Attachment0 = Attachment0,
		Attachment1 = Attachment1,
		Thickness = Thickness,
		Alpha = Visuals.Combat_BulletTracerAlpha
	})
end

ns__hookfunction(false, BulletObject, "new", function(Original, BulletData, ...)
	if not BulletData.onplayerhit then
		return Original(BulletData)
	end

	if IsAimbotInputActive and Aiming.Aimbot_Type == "Silent" then
		local Target, Entry, Part = Silent_GetClosest()
		if Target and Entry then
			local Player = Entry._player
			if Target and MovementCache[Player] then
				local Cache = MovementCache[Player]
				local Current, Old, Velocity
				if Cache then
					Current = Cache[1]
					Old = Cache[15]
					if Current and Old and (Current.Time - Old.Time) > 0.01 then
						Velocity = (Current.Position - Old.Position) / (Current.Time - Old.Time)
					end
				end

				local Trajectory = GetTrajectory(BulletData.position, BulletData.acceleration, Target, BulletData.velocity.Magnitude, Velocity or Vector3.zero)
				if Trajectory then
					BulletData.velocity = Trajectory
					LastSilent.Target = Target
					LastSilent.Velocity = Trajectory
					LastSilent.Frame = os.clock()
				end
			end
		end
	end

	local Bullet = Original(BulletData)
	if Visuals.Combat_BulletTracers then
		CreateBulletTracer(BulletData.position, BulletData.velocity.Unit * 1500)
		for _,Beam in next, Bullet._beamObject.beams do
			Beam.Enabled = false
		end
	end
	return Bullet
end, {ReturnOriginal = true})

local FlashlightPart = ns__cloneref(Instance.new("Part"))
FlashlightPart.Anchored = true
FlashlightPart.CanCollide = false
FlashlightPart.CanQuery = false
FlashlightPart.CanTouch = false
FlashlightPart.Transparency = 1
FlashlightPart.Size = Vector3.new(0.1, 0.1, 0.1)
FlashlightPart.Parent = workspace

local FlashlightSpotLight = ns__cloneref(Instance.new("SpotLight"))
FlashlightSpotLight.Brightness = 4
FlashlightSpotLight.Range = 60
FlashlightSpotLight.Angle = 70
FlashlightSpotLight.Color = Color3.fromRGB(255, 255, 255)
FlashlightSpotLight.Shadows = true
FlashlightSpotLight.Parent = FlashlightPart

local ModelHighlights = setmetatable({}, {__mode = "k"})
local ViewmodelCache = setmetatable({}, {__mode = "k"})
local ModelBaseParts = setmetatable({}, {__mode = "k"})
local SleevesCache = setmetatable({}, {__mode = "k"})

local function OnCameraModelAdded(Model)
	ModelBaseParts[Model] = {}

	for _,Part in ipairs(Model:GetDescendants()) do
		if Part.Name == "Sleeves" and Part:IsA("MeshPart") then
			SleevesCache[Part] = Part.Parent
		end

		if Part:IsA("BasePart") then
			table.insert(ModelBaseParts[Model], Part)
		end
	end

	Model.DescendantAdded:Connect(function(Part)
		if Part.Name == "Sleeves" and Part:IsA("MeshPart") then
			SleevesCache[Part] = Part.Parent
		end

		if Part:IsA("BasePart") then
			table.insert(ModelBaseParts[Model], Part)
		end
	end)

	local Highlight = ns__cloneref(Instance.new("Highlight"))
	Highlight.Name = HttpService:GenerateGUID(false)
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.Enabled = false
	Highlight.Adornee = Model
	Highlight.Parent = CoreGui
	ModelHighlights[Model] = Highlight

	Model.Destroying:Once(function()
		local Highlight = ModelHighlights[Model]
		if Highlight then
			Highlight:Destroy()
			ModelHighlights[Model] = nil
		end
		ModelBaseParts[Model] = nil
	end)
end

for _,Child in ipairs(Camera:GetChildren()) do
	if Child:IsA("Model") then
		OnCameraModelAdded(Child)
	end
end

Camera.ChildAdded:Connect(function(Child)
	if Child:IsA("Model") then
		OnCameraModelAdded(Child)
	end
end)

local LocalHumanoid = nil
for _,Child in next, IgnoreFolder:GetChildren() do
	if Child:IsA("Model") and Child:FindFirstChildOfClass("Humanoid") then
		IsSpawned = true
		LocalHumanoid = Child:FindFirstChildOfClass("Humanoid")
	end
end

ns__hookfunction(false, ScreenCull, "step", function(Original, ...)
	Original(...)

	if IsThirdPersonActive then
		local CameraOffset = Vector3.new(Visuals.Camera_ThirdPersonOffsetX, Visuals.Camera_ThirdPersonOffsetY, Visuals.Camera_ThirdPersonOffsetZ)
		local DidCollide = false

		if Visuals.Camera_ThirdPersonCameraCollision and CameraOffset.Magnitude > 0 then
			local OriginalPosition = Camera.CFrame.Position
			local Raycast = workspace:Raycast(OriginalPosition, (Camera.CFrame * CFrame.new(CameraOffset)).Position - OriginalPosition, AimingRaycastParams)
			if Raycast then
				Camera.CFrame *= CFrame.new(CameraOffset * ((Raycast.Position - OriginalPosition).Magnitude / CameraOffset.Magnitude) * 0.99)
				DidCollide = true
			end
		end

		if not DidCollide then
			Camera.CFrame *= CFrame.new(CameraOffset)
		end
	end

	if Visuals.Camera_FOVModificationEnabled then
		Camera.FieldOfView = Visuals.Camera_FOVValue
	end
end, {ReturnOriginal = true})

IgnoreFolder.ChildAdded:Connect(function(Child)
	local Humanoid = Child:IsA("Model") and (Child:FindFirstChildOfClass("Humanoid") or Child:WaitForChild("Humanoid", 2))
	if not Humanoid then
		return
	end

	IsSpawned = true
	LocalHumanoid = Humanoid
	Child.Destroying:Once(function()
		IsSpawned = false
		if LocalHumanoid == Humanoid then
			LocalHumanoid = nil
		end
	end)
end)

DeadBodyFolder.ChildAdded:Connect(function(Child)
	local RagdollMode = Miscellaneous.RagdollEffects_Mode
	if RagdollMode ~= "None" then
		local Torso = Child:FindFirstChild("Torso") or Child:FindFirstChildWhichIsA("BasePart")
		if not Torso then
			return
		end

		if RagdollMode == "Launch" then
			Torso.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), Miscellaneous.RagdollEffects_LaunchForce, math.random(-15, 15))
		elseif RagdollMode == "Fling" then
			local Force = Miscellaneous.RagdollEffects_FlingForce
			Torso.AssemblyLinearVelocity = Vector3.new(math.random(-Force, Force), math.random(0, Force), math.random(-Force, Force))
			Torso.AssemblyAngularVelocity = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))
			return
		end

		Torso.AssemblyLinearVelocity = Vector3.new(0, Miscellaneous.RagdollEffects_FloatSpeed, 0)
		for _,Child in next, Child:GetChildren() do
			if Child:IsA("BasePart") then
				local AntiGravity = ns__cloneref(Instance.new("BodyForce"))
				AntiGravity.Name = HttpService:GenerateGUID(false)
				AntiGravity.Force = Vector3.new(0, Child:GetMass() * workspace.Gravity, 0)
				AntiGravity.Parent = Child
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	CanSeeFrameCounter += 1
	local PrevousFrame = CanSeeFrameCounter - 1

	for Part, Entry in next, CanSeeCache do
		if Entry[2] ~= PrevousFrame then
			table.insert(CanSeeCachePool, Entry)
			CanSeeCache[Part] = nil
		end
	end

	for Part, Entry in next, RageBotCache do
		if Entry[2] ~= PrevousFrame then
			table.insert(CanSeeCachePool, Entry)
			RageBotCache[Part] = nil
		end
	end

	for Sleeve, OriginalParent in next, SleevesCache do
		if not OriginalParent or not OriginalParent.Parent then
			SleevesCache[Sleeve] = nil
			continue
		end

		if Visuals.Viewmodel_NoSleeves then
			if Sleeve.Parent ~= nil then
				Sleeve.Parent = nil
			end
		else
			if Sleeve.Parent ~= OriginalParent then
				Sleeve.Parent = OriginalParent
			end
		end
	end

	for Model, Parts in next, ModelBaseParts do
		if Model.Parent ~= Camera then
			ModelBaseParts[Model] = nil
			continue
		end

		local Arm, Targets, ValidTarget = Model:FindFirstChild("Arm"), Visuals.Viewmodel_ChamsTargets, false
		if Arm then
			if Targets.Arms then
				ValidTarget = true
			end
		elseif Targets.Weapon then
			ValidTarget = true
		end

		local Highlight = ModelHighlights[Model]
		if ValidTarget and Visuals.Viewmodel_Chams then
			Highlight.Enabled = false
			for _,Part in ipairs(Parts) do
				if not ViewmodelCache[Part] then
					ViewmodelCache[Part] = {Material = Part.Material.Name, Transparency = Part.Transparency, Color = Part.Color}
				end
				local Material = Visuals.Viewmodel_ChamsType
				Part.Material = Enum.Material[Material]
				Part.Color = Visuals.Viewmodel_ChamsColor
				Part.Transparency = (Material ~= "ForceField" and Visuals.Viewmodel_ChamsTranslucent) and 0.5 or 0
			end
		else
			Highlight.Enabled = false
			for _,Part in ipairs(Parts) do
				local Cache = ViewmodelCache[Part]
				if Cache then
					Part.Material = Enum.Material[Cache.Material]
					Part.Transparency = Cache.Transparency
					Part.Color = Cache.Color
					ViewmodelCache[Part] = nil
				end
			end
		end
	end

	if Visuals.Lighting_Flashlight and IsSpawned then
		FlashlightPart.CFrame = Camera.CFrame
		FlashlightSpotLight.Enabled = true
		FlashlightSpotLight.Color = Visuals.Lighting_FlashlightColor
		FlashlightSpotLight.Brightness = Visuals.Lighting_FlashlightBrightness
		FlashlightSpotLight.Range = Visuals.Lighting_FlashlightRange
		FlashlightSpotLight.Angle = Visuals.Lighting_FlashlightAngle
	else
		FlashlightSpotLight.Enabled = false
	end
end)

local function VisibilityCheck(Head, Torso, Arms, Legs)
	local Layers = Settings.Advanced_MultiPointLayers

	if CanSee(Head, Layers) or CanSee(Torso, Layers) then
		return true
	end

	for Index = 1, #Arms do
		if CanSee(Arms[Index], Layers) then
			return true
		end
	end

	for Index = 1, #Legs do
		if CanSee(Legs[Index], Layers) then
			return true
		end
	end

	return false
end

local function RotatePoint(Angle, Point, Center)
	local CosineAngle, SineAngle = math.cos(Angle), math.sin(Angle)
	local Offset = Point - Center
	local OffsetX, OffsetY = Offset.X, Offset.Y
	return Vector2.new(
		Center.X + (OffsetX * CosineAngle - OffsetY * SineAngle),
		Center.Y + (OffsetX * SineAngle + OffsetY * CosineAngle)
	)
end

local function HandleLine(Line, FromPoint, ToPoint, Center, Angle, Color, Spin)
	if Spin then
		FromPoint = RotatePoint(Angle, FromPoint, Center)
		ToPoint = RotatePoint(Angle, ToPoint, Center)
	end
	SetProperty(Line, "From", FromPoint)
	SetProperty(Line, "To", ToPoint)
	SetProperty(Line, "Color", Color)
	SetProperty(Line, "Visible", true)
end

local Rendering_DrawingObjects, Rendering_Highlights = {}, {} 
local function UpdateESP(LocalHeadPosition, Player, Entry, Head, Torso, Arms, Legs, GlobalOpacity)
	local HighlightGroup = Rendering_Highlights[Player]
	if not HighlightGroup then
		HighlightGroup = {}
		Rendering_Highlights[Player] = HighlightGroup
	end

	if Visuals.EnemyESP_Chams then
		local ChamsColor
		if Visuals.EnemyESP_ChamsStyle == "Visible" and VisibilityCheck(Head, Torso, Arms, Legs) then
			ChamsColor = Visuals.EnemyESP_ChamsVisibleColor
		else
			ChamsColor = Visuals.EnemyESP_ChamsColor
		end

		local ChamsRendering = Visuals.EnemyESP_ChamsRendering
		local RenderFill, RenderOutline = ChamsRendering.Fill, ChamsRendering.Outline
		if RenderFill or RenderOutline then
			local Highlight = HighlightGroup.Full
			if not Highlight then
				Highlight = ns__cloneref(Instance.new("Highlight"))
				Highlight.Parent = CoreGui
				HighlightGroup.Full = Highlight
			end

			Highlight.DepthMode = Visuals.EnemyESP_ChamsOccluded and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
			Highlight.Adornee = Head.Parent
			local Opacity = 1 - GlobalOpacity
			Highlight.Enabled = true
			Highlight.FillColor = ChamsColor
			Highlight.OutlineColor = DarkerColorCache[ChamsColor]
			Highlight.FillTransparency = RenderFill and Opacity or 1
			Highlight.OutlineTransparency = RenderOutline and Opacity or 1
		else
			local Full = HighlightGroup.Full
			if Full then
				HighlightGroup.Full = nil
				Full:Destroy()
			end
		end
	else
		local Full = HighlightGroup.Full
		if Full then
			HighlightGroup.Full = nil
			Full:Destroy()
		end
	end

	local DrawingGroup = Rendering_DrawingObjects[Player]
	if not DrawingGroup then
		DrawingGroup = {
			Box = CreateDrawing("Square", {Filled = false, Color = Visuals.EnemyESP_BoxColor, Thickness = Visuals.EnemyESP_BoxThickness}),
			HealthbarOutline = CreateDrawing("Square", {Filled = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 1}),
			HealthbarBackground = CreateDrawing("Square", {Filled = true, Color = Color3.fromRGB(8, 8, 8)}),
			Healthbar = CreateDrawing("Square", {Filled = true, Color = Visuals.EnemyESP_HealthbarColor}),
			Tag = CreateDrawing("Text", {Size = Visuals.EnemyESP_TagSize, Outline = true, Center = true, Color = Visuals.EnemyESP_TagColor}),
			Dot = CreateDrawing("Circle", {Filled = true, Radius = Visuals.EnemyESP_DotSize, Color = Visuals.EnemyESP_DotColor}),
			Tracer = CreateDrawing("Line", {Color = Visuals.EnemyESP_TracerColor, Thickness = Visuals.EnemyESP_TracerThickness}),
		}
		Rendering_DrawingObjects[Player] = DrawingGroup
	end

	local Box, Tag, Dot, Tracer = DrawingGroup.Box, DrawingGroup.Tag, DrawingGroup.Dot, DrawingGroup.Tracer
	local HealthbarOutline, HealthbarBackground, Healthbar = DrawingGroup.HealthbarOutline, DrawingGroup.HealthbarBackground, DrawingGroup.Healthbar

	local HeadPosition = Head.Position
	local HeadScreen, HeadOnScreen = WorldToViewportPoint(HeadPosition)
	if not HeadOnScreen then
		SetProperty(Box, "Visible", false)
		SetProperty(Tag, "Visible", false)
		SetProperty(Dot, "Visible", false)
		SetProperty(Tracer, "Visible", false)
		SetProperty(HealthbarOutline, "Visible", false)
		SetProperty(HealthbarBackground, "Visible", false)
		SetProperty(Healthbar, "Visible", false)
		return
	end

	local HeadScreenX = HeadScreen.X
	local TorsoPosition = Torso.Position
	local TopScreen, TopOnScreen = Camera:WorldToViewportPoint(HeadPosition + Vector3.new(0, Head.Size.Y * 0.5 + 1.2, 0))
	local BottomScreen, BottomOnScreen = Camera:WorldToViewportPoint(TorsoPosition - Vector3.new(0, Torso.Size.Y * 0.5 + 3.0, 0))
	local BottomScreenY = BottomScreen.Y

	if TopOnScreen and BottomOnScreen then
		local TopScreenY = TopScreen.Y
		local BoxHeight = BottomScreenY - TopScreenY
		local BoxWidth = BoxHeight * 0.65

		if Visuals.EnemyESP_Boxes then
			SetProperty(Box, "Visible", true)
			SetProperty(Box, "Size", Vector2.new(BoxWidth, BoxHeight))
			SetProperty(Box, "Position", Vector2.new(HeadScreenX - BoxWidth * 0.5, TopScreenY))
			SetProperty(Box, "Transparency", GlobalOpacity)
		else
			SetProperty(Box, "Visible", false)
		end

		if Visuals.EnemyESP_HeadTags then
			SetProperty(Tag, "Visible", true)
			SetProperty(Tag, "Transparency", GlobalOpacity)
			SetProperty(Tag, "Color", Visuals.EnemyESP_TagColor)
			SetProperty(Tag, "Size", Visuals.EnemyESP_TagSize)

			local Elements = Visuals.EnemyESP_HeadTagElements
			local Text = ""
			if Elements.Name then
				Text = Player.Name
			end

			if Elements.Health then
				Text ..= (Text ~= "" and (" [") or "[") .. tostring(math.floor(Entry:getHealth())) .. "]"
			end

			if Elements.Distance then
				local Distance = math.floor((LocalHeadPosition - TorsoPosition).Magnitude)
				Text ..= (Text ~= "" and (" [%dm]"):format(Distance) or ("[%dm]"):format(Distance))
			end

			if Elements.Visibility then
				local Visibility = VisibilityCheck(Head, Torso, Arms, Legs) and "[Visible]" or "[Hidden]"
				Text ..= (Text ~= "" and (" " .. Visibility) or Visibility)
			end

			SetProperty(Tag, "Text", Text)
			SetProperty(Tag, "Position", Vector2.new(HeadScreenX, TopScreenY - Tag.Size - 3))
		else
			SetProperty(Tag, "Visible", false)
		end

		if Visuals.EnemyESP_Healthbars then
			local BarWidth = math.clamp(Visuals.EnemyESP_HealthbarWidth, 3, 8)
			local BarHeight = math.max(24, BoxHeight * 0.9)
			local BarX = HeadScreenX + BoxWidth * 0.5 + 5
			local BarY = TopScreenY + (BoxHeight - BarHeight) * 0.5
			local FillHeight = math.max(1, math.floor((BarHeight - 2) * math.clamp(Entry:getHealth() * 0.01, 0, 1)))

			SetProperty(HealthbarOutline, "Visible", true)
			SetProperty(HealthbarOutline, "Size", Vector2.new(BarWidth, BarHeight))
			SetProperty(HealthbarOutline, "Position", Vector2.new(BarX, BarY))
			SetProperty(HealthbarOutline, "Transparency", GlobalOpacity)

			SetProperty(HealthbarBackground, "Visible", true)
			SetProperty(HealthbarBackground, "Size", Vector2.new(BarWidth - 2, BarHeight - 2))
			SetProperty(HealthbarBackground, "Position", Vector2.new(BarX + 1, BarY + 1))
			SetProperty(HealthbarBackground, "Transparency", GlobalOpacity)

			SetProperty(Healthbar, "Visible", true)
			SetProperty(Healthbar, "Size", Vector2.new(BarWidth - 2, FillHeight))
			SetProperty(Healthbar, "Position", Vector2.new(BarX + 1, BarY + 1 + ((BarHeight - 2) - FillHeight)))
			SetProperty(Healthbar, "Color", Visuals.EnemyESP_HealthbarColor)
			SetProperty(Healthbar, "Transparency", GlobalOpacity)
		else
			SetProperty(HealthbarOutline, "Visible", false)
			SetProperty(HealthbarBackground, "Visible", false)
			SetProperty(Healthbar, "Visible", false)
		end
	else
		SetProperty(Box, "Visible", false)
		SetProperty(Tag, "Visible", false)
		SetProperty(HealthbarOutline, "Visible", false)
		SetProperty(HealthbarBackground, "Visible", false)
		SetProperty(Healthbar, "Visible", false)
	end

	if Visuals.EnemyESP_Dots then
		SetProperty(Dot, "Visible", true)
		SetProperty(Dot, "Position", HeadScreen)
		SetProperty(Dot, "Color", Visuals.EnemyESP_DotColor)
		SetProperty(Dot, "Radius", Visuals.EnemyESP_DotSize)
		SetProperty(Dot, "Transparency", GlobalOpacity)
	else
		SetProperty(Dot, "Visible", false)
	end

	if Visuals.EnemyESP_Tracers then
		local Origin = Visuals.EnemyESP_TracerOrigin
		if Origin == "Top" then
			SetProperty(Tracer, "From", ScreenTop)
		elseif Origin == "Center" then
			SetProperty(Tracer, "From", ScreenCenter)
		else
			SetProperty(Tracer, "From", ScreenBottom)
		end
		SetProperty(Tracer, "To", Visuals.EnemyESP_TracerTarget == "Torso" and Vector2.new(HeadScreenX, (HeadScreen.Y + BottomScreenY) * 0.5) or HeadScreen)
		SetProperty(Tracer, "Visible", true)
		SetProperty(Tracer, "Transparency", GlobalOpacity)
	else
		SetProperty(Tracer, "Visible", false)
	end
end
local function ClearESP(Player)
	local DrawingGroup = Rendering_DrawingObjects[Player]
	if DrawingGroup then
		for _,DrawingObject in next, DrawingGroup do
			DrawingObject:Remove()
		end
		Rendering_DrawingObjects[Player] = nil
	end

	local HighlightGroup = Rendering_Highlights[Player]
	if HighlightGroup then
		local Full = HighlightGroup.Full
		if Full then
			Full:Destroy()
		end
		Rendering_Highlights[Player] = nil
	end
end
Players.PlayerRemoving:Connect(ClearESP)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/PhantomWare/refs/heads/main/core/Library.luau"))()
local Window = Library:CreateWindow({Title = "PhantomWare | discord.gg/DwRT2nH93D" .. (ExecutorName and (" | " .. ExecutorName) or ""), TabPadding = 8, MenuFadeTime = 0.2}, 1)
local Toggles = Library.Toggles
local Options = Library.Options

local Tabs = {
	Aiming = Window:AddTab("Aiming"),
	Visuals = Window:AddTab("Visuals"),
	Miscellaneous = Window:AddTab("Miscellaneous"),
	Settings = Window:AddTab("Settings")
}

local function UpdateTable(Table, Setting, Value, Callback)
	Table[Setting] = Value
	if Callback then
		Callback(Value)
	end
end

local Aiming_RageBot = Tabs.Aiming:AddRightGroupbox("RageBot")
local Aiming_Aimbot = Tabs.Aiming:AddLeftGroupbox("Aimbot")

local Visuals_EnemyESPGroupbox = Tabs.Visuals:AddLeftGroupbox("Enemy ESP")
local Visuals_CombatGroupbox = Tabs.Visuals:AddRightGroupbox("Combat")

local World_Tabbox = Tabs.Visuals:AddRightTabbox("World")
local World_Camera = World_Tabbox:AddTab("Camera")
local World_Lighting = World_Tabbox:AddTab("Lighting")
local World_ViewModel = World_Tabbox:AddTab("ViewModel")

Aiming_Aimbot:AddToggle("Aimbot_Enabled", {Text = "Aimbot", Default = Aiming.Aimbot_Enabled, Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_Enabled", Value, function(Value)
		IsAimbotInputActive = Value
	end)
end}):AddKeyPicker("Aimbot_Keybind", {Default = Aiming.Aimbot_Keybind, Mode = "Toggle", Text = "Aiming Keybind", ChangedCallback = function(Keybind)
	UpdateTable(Aiming, "Aimbot_Keybind", Keybind)
end, Callback = function(Value)
	IsAimbotInputActive = Value
end})

local AimbotDependencyBox = Aiming_Aimbot:AddDependencyBox():SetupDependencies({{Toggles.Aimbot_Enabled, true}})

AimbotDependencyBox:AddDropdown("Aimbot_Type", {Text = "Type", Default = Aiming.Aimbot_Type, Values = {"Camera", "Mouse", "Silent"}, Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_Type", Value)
end})

AimbotDependencyBox:AddDropdown("Aimbot_Part", {Text = "Part", Default = Aiming.Aimbot_Part, Values = {"Head", "Torso", "Closest", "Priority"}, Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_Part", Value)
end})

AimbotDependencyBox:AddDependencyBox():SetupDependencies({{Options.Aimbot_Part, "Priority"}}):AddPrioritySelector("Aimbot_PartPriorityOrder", {
	Text = "Part Priorities", Default = Aiming.Aimbot_PartPriorityOrder, Callback = function(Value)
		Aiming.Aimbot_PartPriorityOrder = Value
	end
})

AimbotDependencyBox:AddDependencyBox():SetupDependencies({{Options.Aimbot_Type, {"Camera", "Mouse"}}}):AddSlider("Aimbot_Smoothness", {
	Text = "Smoothness", Default = Aiming.Aimbot_Smoothness, Min = 1, Max = 10, Rounding = 0, Callback = function(Value)
		UpdateTable(Aiming, "Aimbot_Smoothness", Value)
	end
})

if VirtualInputManager then
	AimbotDependencyBox:AddDependencyBox():SetupDependencies({{Options.Aimbot_Type, "Silent"}}):AddToggle("Aimbot_AutoFire", {
		Text = "AutoFire", Default = Aiming.Aimbot_AutoFire, Callback = function(Value)
			UpdateTable(Aiming, "Aimbot_AutoFire", Value)
		end
	})
end

AimbotDependencyBox:AddToggle("Aimbot_WallCheck", {Text = "Wall Check", Default = Aiming.Aimbot_WallCheck, Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_WallCheck", Value)
end})

AimbotDependencyBox:AddToggle("Aimbot_DeathNotification", {Text = "Death Notification", Default = Aiming.Aimbot_DeathNotification, Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_DeathNotification", Value)
end})

AimbotDependencyBox:AddToggle("Aimbot_ShowFOV", {Text = "FOV Circle", Default = Aiming.Aimbot_ShowFOV, Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_ShowFOV", Value)
end}):AddColorPicker("Aimbot_FOVColor", {Default = Aiming.Aimbot_FOVColor, Title = "FOV Color", Transparency = Aiming.Aimbot_FOVOpacity}).Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_FOVColor", Value)
	UpdateTable(Aiming, "Aimbot_FOVOpacity", 1 - Options.Aimbot_FOVColor.Transparency)
end

AimbotDependencyBox:AddDependencyBox():SetupDependencies({{Toggles.Aimbot_ShowFOV, true}}):AddSlider("Aimbot_FOVRadius", {
	Text = "FOV Radius", Default = Aiming.Aimbot_FOVRadius, Min = 10, Max = 800, Rounding = 0, Callback = function(Value)
		UpdateTable(Aiming, "Aimbot_FOVRadius", Value)
	end
})

AimbotDependencyBox:AddToggle("Aimbot_TargetTracer", {Text = "Target Tracer", Default = Aiming.Aimbot_TargetTracer, Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_TargetTracer", Value)
end}):AddColorPicker("Aimbot_TargetTracerColor", {Default = Aiming.Aimbot_TargetTracerColor, Title = "Tracer Color", Callback = function(Value)
	UpdateTable(Aiming, "Aimbot_TargetTracerColor", Value)
end})

Aiming_RageBot:AddToggle("RageBot_Enabled", {Text = "RageBot", Default = Aiming.RageBot_Enabled, Callback = function(Value)
	UpdateTable(Aiming, "RageBot_Enabled", Value, function(Value)
		IsRageBotInputActive = Value
	end)
end}):AddKeyPicker("RageBot_Keybind", {Default = Aiming.RageBot_Keybind, Mode = "Toggle", Text = "RageBot Keybind", ChangedCallback = function(Keybind)
	UpdateTable(Aiming, "RageBot_Keybind", Keybind)
end, Callback = function(Value)
	IsRageBotInputActive = Value
end})

local RageBotDependencyBox = Aiming_RageBot:AddDependencyBox():SetupDependencies({{Toggles.RageBot_Enabled, true}})
RageBotDependencyBox:AddDropdown("RageBot_Part", {Text = "Part", Default = Aiming.RageBot_Part, Values = {"Head", "Torso", "Closest", "Priority"}, Callback = function(Value)
	UpdateTable(Aiming, "RageBot_Part", Value)
end})

RageBotDependencyBox:AddDependencyBox():SetupDependencies({{Options.RageBot_Part, "Priority"}}):AddPrioritySelector("RageBot_HitboxPriorityOrder", {
	Text = "Part Priorities", Default = Aiming.RageBot_HitboxPriorityOrder, Callback = function(Value)
		Aiming.RageBot_HitboxPriorityOrder = Value
	end
})

RageBotDependencyBox:AddToggle("RageBot_WallPenetrationDetection", {Text = "Wall Penetration Detection", Default = Aiming.RageBot_WallPenetrationDetection, Callback = function(Value)
	UpdateTable(Aiming, "RageBot_WallPenetrationDetection", Value)
end})

RageBotDependencyBox:AddToggle("RageBot_IgnoreBulletTracers", {Text = "Ignore Bullet Tracers", Default = Aiming.RageBot_IgnoreBulletTracers, Callback = function(Value)
	UpdateTable(Aiming, "RageBot_IgnoreBulletTracers", Value)
end})

local Miscellaneous_GunMods = Tabs.Miscellaneous:AddLeftGroupbox("Gun Mods")

Miscellaneous_GunMods:AddToggle("GunMods_NoWalkSway", {Text = "No Walk Sway", Default = Miscellaneous.GunMods_NoWalkSway, Callback = function(Value)
	if not Value then
		return ns__restorefunction("computeWalkSway")
	end

	ns__hookfunction(true, FirearmObject, "computeWalkSway", function(Original, self, ...)
		return Original(self, 0, 0)
	end, {ReturnOriginal = true})

	UpdateTable(Miscellaneous, "GunMods_NoWalkSway", Value)
end})

Miscellaneous_GunMods:AddToggle("GunMods_NoGunSway", {Text = "No Gun Sway", Default = Miscellaneous.GunMods_NoGunSway, Callback = function(Value)
	if not Value then
		return ns__restorefunction("computeGunSway")
	end

	ns__hookfunction(true, FirearmObject, "computeGunSway", function(Original, self, ...)
		return CFrame.identity
	end, {ReturnOriginal = true})

	UpdateTable(Miscellaneous, "GunMods_NoGunSway", Value)
end})

Miscellaneous_GunMods:AddToggle("GunMods_NoRecoil", {Text = "No Recoil", Default = Miscellaneous.GunMods_NoRecoil, Callback = function(Value)
	UpdateTable(Miscellaneous, "GunMods_NoRecoil", Value)
end})

Miscellaneous_GunMods:AddToggle("GunMods_InstantReload", {Text = "Instant Reload", Default = Miscellaneous.GunMods_InstantReload, Callback = function(Value)
	UpdateTable(Miscellaneous, "GunMods_InstantReload", Value)
end})

local HitLogs_GroupBox = Tabs.Miscellaneous:AddLeftGroupbox("Hit Logs")
HitLogs_GroupBox:AddToggle("HitLogs_Enabled", {Text = "Hit Logs", Default = Miscellaneous.HitLogs_Enabled, Callback = function(Value)
	UpdateTable(Miscellaneous, "HitLogs_Enabled", Value)
end})

local HitLogs_DependencyBox = HitLogs_GroupBox:AddDependencyBox():SetupDependencies({{Toggles.HitLogs_Enabled, true}})
HitLogs_DependencyBox:AddToggle("HitLogs_ShowDamage", {Text = "Show Damage", Default = Miscellaneous.HitLogs_ShowDamage, Callback = function(Value)
	UpdateTable(Miscellaneous, "HitLogs_ShowDamage", Value)
end})
HitLogs_DependencyBox:AddToggle("HitLogs_ShowDistance", {Text = "Show Distance", Default = Miscellaneous.HitLogs_ShowDistance, Callback = function(Value)
	UpdateTable(Miscellaneous, "HitLogs_ShowDistance", Value)
end})

local SoundOverride_Groupbox = Tabs.Miscellaneous:AddLeftGroupbox("Sound Override")
SoundOverride_Groupbox:AddDropdown("SoundOverride_ShootSound", {Text = "Shoot", Default = Miscellaneous.SoundOverride_ShootSound, Values = SoundOptions, Callback = function(Value)
	UpdateTable(Miscellaneous, "SoundOverride_ShootSound", Value)
end})
SoundOverride_Groupbox:AddDropdown("SoundOverride_HitSound", {Text = "Hit", Default = Miscellaneous.SoundOverride_HitSound, Values = SoundOptions, Callback = function(Value)
	UpdateTable(Miscellaneous, "SoundOverride_HitSound", Value)
end})
SoundOverride_Groupbox:AddDropdown("SoundOverride_KillSound", {Text = "Kill", Default = Miscellaneous.SoundOverride_KillSound, Values = SoundOptions, Callback = function(Value)
	UpdateTable(Miscellaneous, "SoundOverride_KillSound", Value)
end})
SoundOverride_Groupbox:AddDropdown("SoundOverride_GotHitSound", {Text = "Hurt", Default = Miscellaneous.SoundOverride_GotHitSound, Values = SoundOptions, Callback = function(Value)
	UpdateTable(Miscellaneous, "SoundOverride_GotHitSound", Value)
end})

local RagdollsEffects_Groupbox = Tabs.Miscellaneous:AddLeftGroupbox("Ragdoll Effects")
RagdollsEffects_Groupbox:AddDropdown("RagdollEffects_Mode", {Text = "Ragdoll Mode", Default = Miscellaneous.RagdollEffects_Mode, Values = {"None", "Launch", "Fling", "Float"}, Callback = function(Value)
	UpdateTable(Miscellaneous, "RagdollEffects_Mode", Value)
end})
RagdollsEffects_Groupbox:AddDependencyBox():SetupDependencies({{Options.RagdollEffects_Mode, "Launch"}}):AddSlider("RagdollEffects_LaunchForce", {Text = "Launch Force", Default = Miscellaneous.RagdollEffects_LaunchForce, Min = 50, Max = 500, Rounding = 0, Callback = function(Value)
	UpdateTable(Miscellaneous, "RagdollEffects_LaunchForce", Value)
end})
RagdollsEffects_Groupbox:AddDependencyBox():SetupDependencies({{Options.RagdollEffects_Mode, "Fling"}}):AddSlider("RagdollEffects_FlingForce", {Text = "Fling Force", Default = Miscellaneous.RagdollEffects_FlingForce, Min = 100, Max = 500, Rounding = 0, Callback = function(Value)
	UpdateTable(Miscellaneous, "RagdollEffects_FlingForce", Value)
end})
RagdollsEffects_Groupbox:AddDependencyBox():SetupDependencies({{Options.RagdollEffects_Mode, "Float"}}):AddSlider("RagdollEffects_FloatSpeed", {Text = "Float Speed", Default = Miscellaneous.RagdollEffects_FloatSpeed, Min = 1, Max = 100, Rounding = 0, Callback = function(Value)
	UpdateTable(Miscellaneous, "RagdollEffects_FloatSpeed", Value)
end})

local Miscellaneous_Movement = Tabs.Miscellaneous:AddRightGroupbox("Movement")
Miscellaneous_Movement:AddToggle("Movement_NoFallDamage", {Text = "No Fall Damage", Default = Miscellaneous.Movement_NoFallDamage, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_NoFallDamage", Value)
end})
Miscellaneous_Movement:AddToggle("Movement_BunnyHop", {Text = "Bunny Hop [May Despawn]", Default = Miscellaneous.Movement_BunnyHop, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_BunnyHop", Value)
end})
Miscellaneous_Movement:AddToggle("Movement_AntiAimEnabled", {Text = "Anti Aim", Default = Miscellaneous.Movement_AntiAimEnabled, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimEnabled", Value)
end})

local AntiAimDependencyBox = Miscellaneous_Movement:AddDependencyBox():SetupDependencies({{Toggles.Movement_AntiAimEnabled, true}})
AntiAimDependencyBox:AddToggle("Movement_AntiAimYaw", {Text = "Yaw", Default = Miscellaneous.Movement_AntiAimYaw, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimYaw", Value)
end})

local YawDependencyBox = AntiAimDependencyBox:AddDependencyBox():SetupDependencies({{Toggles.Movement_AntiAimYaw, true}})
YawDependencyBox:AddSlider("Movement_AntiAimYawAmount", {Text = "Yaw Amount", Default = Miscellaneous.Movement_AntiAimYawAmount, Min = 0, Max = 360, Rounding = 0, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimYawAmount", Value)
end})
YawDependencyBox:AddDropdown("Movement_AntiAimYawMode", {Text = "Yaw Mode", Default = Miscellaneous.Movement_AntiAimYawMode, Values = {"Relative", "Absolute"}, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimYawMode", Value)
end})
AntiAimDependencyBox:AddToggle("Movement_AntiAimPitch", {Text = "Pitch", Default = Miscellaneous.Movement_AntiAimPitch, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimPitch", Value)
end})

local PitchDependencyBox = AntiAimDependencyBox:AddDependencyBox():SetupDependencies({{Toggles.Movement_AntiAimPitch, true}})
PitchDependencyBox:AddSlider("Movement_AntiAimPitchAmount", {Text = "Pitch Amount", Default = Miscellaneous.Movement_AntiAimPitchAmount, Min = 0, Max = 180, Rounding = 0, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimPitchAmount", Value)
end})
PitchDependencyBox:AddDropdown("Movement_AntiAimPitchMode", {Text = "Pitch Mode", Default = Miscellaneous.Movement_AntiAimPitchMode, Values = {"Relative", "Absolute"}, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimPitchMode", Value)
end})
AntiAimDependencyBox:AddToggle("Movement_AntiAimJitter", {Text = "Jitter", Default = Miscellaneous.Movement_AntiAimJitter, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimJitter", Value)
end})
AntiAimDependencyBox:AddDependencyBox():SetupDependencies({{Toggles.Movement_AntiAimJitter, true}}):AddSlider("Movement_AntiAimJitterSpeed", {
	Text = "Jitter Speed", Default = Miscellaneous.Movement_AntiAimJitterSpeed, Min = 1, Max = 1000, Rounding = 0, Callback = function(Value)
		UpdateTable(Miscellaneous, "Movement_AntiAimJitterSpeed", Value)
	end
})
AntiAimDependencyBox:AddToggle("Movement_AntiAimSpinBot", {Text = "Spin Bot", Default = Miscellaneous.Movement_AntiAimSpinBot, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimSpinBot", Value)
end})

local SpinBotDependencyBox = AntiAimDependencyBox:AddDependencyBox():SetupDependencies({{Toggles.Movement_AntiAimSpinBot, true}})
SpinBotDependencyBox:AddDropdown("Movement_AntiAimSpinDirection", {Text = "Spin Direction", Default = Miscellaneous.Movement_AntiAimSpinDirection, Values = {"Left", "Right"}, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimSpinDirection", Value)
end})
SpinBotDependencyBox:AddSlider("Movement_AntiAimSpinSpeed", {Text = "Spin Speed", Default = Miscellaneous.Movement_AntiAimSpinSpeed, Min = 1, Max = 1000, Rounding = 0, Callback = function(Value)
	UpdateTable(Miscellaneous, "Movement_AntiAimSpinSpeed", Value)
end})

Visuals_CombatGroupbox:AddToggle("Combat_LightningKillEffectEnabled", {Text = "Lightning Kill Effect", Default = Visuals.Combat_LightningKillEffectEnabled, Callback = function(Value)
	UpdateTable(Visuals, "Combat_LightningKillEffectEnabled", Value)
end}):AddColorPicker("Combat_LightningKillEffectColor", {Default = Visuals.Combat_LightningKillEffectColor, Title = "Lightning Color", Callback = function(Value)
	UpdateTable(Visuals, "Combat_LightningKillEffectColor", Value)
end})

Visuals_CombatGroupbox:AddToggle("Combat_BulletTracers", {Text = "Bullet Tracers", Default = Visuals.Combat_BulletTracers, Callback = function(Value)
	UpdateTable(Visuals, "Combat_BulletTracers", Value)
end}):AddColorPicker("Combat_BulletTracerColor", {Default = Visuals.Combat_BulletTracerColor, Title = "Tracer Color", Callback = function(Value)
	UpdateTable(Visuals, "Combat_BulletTracerColor", Value)
end})

local Miscellaneous_ClientSessionUnlocks = Tabs.Miscellaneous:AddRightGroupbox("Client Session Unlocks")
Miscellaneous_ClientSessionUnlocks:AddButton({Text = "Unlock Attachments", Func = function()
	Miscellaneous.ClientSessionUnlocks_AttachmentsUnlocked = true
end})
Miscellaneous_ClientSessionUnlocks:AddButton({Text = "Unlock Knives", Func = function()
	Miscellaneous.ClientSessionUnlocks_KnivesUnlocked = true
end})
Miscellaneous_ClientSessionUnlocks:AddButton({Text = "Unlock Camos", Func = function()
    if Miscellaneous.ClientSessionUnlocks_CamosUnlocked then
        return Library:Notify("All camos have already been unlocked.", 3)
    end

    for _,Table in next, getgc(true) do
        if type(Table) ~= "table"  or not rawget(Table, "Mentha Spicata") or not rawget(Table, "Dove blue") then
            continue
        end

        local GetCasePacketData = PlayerDataUtils.getCasePacketData
        for Name, Data in next, Table do
            local Case = Data.Case
            if Case then
                GetCasePacketData(PlayerDataClientInterface.getPlayerData(), Case, true).Skins[Name] = {ALL = true}
            end
        end

        Miscellaneous.ClientSessionUnlocks_CamosUnlocked = true
		Library:Notify("Successfully unlocked all camos.", 5)
        break
    end
end})
Miscellaneous_ClientSessionUnlocks:AddLabel("Information [MUST READ]", false, "1. These Unlocks only last for the current session.\n2. Unlocks are not visible to others.\n3. Dropping Unlocked weapons lose any Unlocked Add-Ons.\n4. Dropping an Unlocked Knife will make it dissapear.")

local BulletTracersDependencyBox = Visuals_CombatGroupbox:AddDependencyBox():SetupDependencies({{Toggles.Combat_BulletTracers, true}})
BulletTracersDependencyBox:AddDropdown("Combat_BulletTracerType", {Text = "Tracer Type", Default = Visuals.Combat_BulletTracerType, Values = {"Beam", "Wavy"}, Callback = function(Value)
	UpdateTable(Visuals, "Combat_BulletTracerType", Value)
end})
BulletTracersDependencyBox:AddDropdown("Combat_BulletTracerFadeMode", {Text = "Fade Mode", Default = Visuals.Combat_BulletTracerFadeMode, Values = {"Width", "Transparency"}, Callback = function(Value)
	UpdateTable(Visuals, "Combat_BulletTracerFadeMode", Value)
end})
BulletTracersDependencyBox:AddSlider("Combat_BulletTracerThickness", {Text = "Thickness", Default = Visuals.Combat_BulletTracerThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Combat_BulletTracerThickness", Value)
end})
BulletTracersDependencyBox:AddSlider("Combat_BulletTracerDuration", {Text = "Duration", Default = Visuals.Combat_BulletTracerDuration, Min = 0.1, Max = 10, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Combat_BulletTracerDuration", Value)
end})

Visuals_CombatGroupbox:AddToggle("Combat_HitMarkerEnabled", {Text = "Hit Markers", Default = Visuals.Combat_HitMarkerEnabled, Callback = function(Value)
	UpdateTable(Visuals, "Combat_HitMarkerEnabled", Value)
end}):AddColorPicker("Combat_HitMarkerColor", {Default = Visuals.Combat_HitMarkerColor, Title = "Hit Markers Color", Callback = function(Value)
	UpdateTable(Visuals, "Combat_HitMarkerColor", Value)
end})

local HitMarkerDependencyBox = Visuals_CombatGroupbox:AddDependencyBox():SetupDependencies({{Toggles.Combat_HitMarkerEnabled, true}})

HitMarkerDependencyBox:AddDropdown("Combat_HitMarkerStyle", {Text = "Marker Style", Default = Visuals.Combat_HitMarkerStyle, Values = {"X", "Plus"}, Callback = function(Value)
	UpdateTable(Visuals, "Combat_HitMarkerStyle", Value)
end})

HitMarkerDependencyBox:AddSlider("Combat_HitMarkerSize", {Text = "Marker Size", Default = Visuals.Combat_HitMarkerSize, Min = 4, Max = 30, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "Combat_HitMarkerSize", Value)
end})

HitMarkerDependencyBox:AddSlider("Combat_HitMarkerGap", {Text = "Marker Gap", Default = Visuals.Combat_HitMarkerGap, Min = 0, Max = 15, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "Combat_HitMarkerGap", Value)
end})

HitMarkerDependencyBox:AddSlider("Combat_HitMarkerDuration", {Text = "Marker Duration", Default = Visuals.Combat_HitMarkerDuration, Min = 0.1, Max = 5, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Combat_HitMarkerDuration", Value)
end})

HitMarkerDependencyBox:AddToggle("Combat_HitMarkerSpin", {Text = "Spinning Marker", Default = Visuals.Combat_HitMarkerSpin, Callback = function(Value)
	UpdateTable(Visuals, "Combat_HitMarkerSpin", Value)
end})

HitMarkerDependencyBox:AddDependencyBox():SetupDependencies({{Toggles.Combat_HitMarkerSpin, true}}):AddSlider("Combat_HitMarkerSpinSpeed", {
	Text = "Spin Speed", Default = Visuals.Combat_HitMarkerSpinSpeed, Min = 1, Max = 10, Rounding = 0, Callback = function(Value)
		UpdateTable(Visuals, "Combat_HitMarkerSpinSpeed", Value)
	end
})

Visuals_CombatGroupbox:AddToggle("Combat_GrenadeTrajectory", {Text = "Grenade Trajectory [BETA]", Default = Visuals.Combat_GrenadeTrajectory, Callback = function(Value)
	UpdateTable(Visuals, "Combat_GrenadeTrajectory", Value)
end}):AddColorPicker("Combat_GrenadeTrajectoryColor", {Default = Visuals.Combat_GrenadeTrajectoryColor, Title = "Trajectory Color", Callback = function(Value)
	UpdateTable(Visuals, "Combat_GrenadeTrajectoryColor", Value)
end})

local GrenadeTrajectory_DepedencyBox = Visuals_CombatGroupbox:AddDependencyBox():SetupDependencies({{Toggles.Combat_GrenadeTrajectory, true}})

GrenadeTrajectory_DepedencyBox:AddLabel("Impact Color"):AddColorPicker("Combat_GrenadeTrajectoryImpactColor", {Default = Visuals.Combat_GrenadeTrajectoryImpactColor, Title = "Impact Color", Callback = function(Value)
	UpdateTable(Visuals, "Combat_GrenadeTrajectoryImpactColor", Value)
end})

GrenadeTrajectory_DepedencyBox:AddDropdown("Combat_GrenadeTrajectoryMode", {Text = "Mode", Default = Visuals.Combat_GrenadeTrajectoryMode, Values = {"2D", "3D"}, Callback = function(Value)
	UpdateTable(Visuals, "Combat_GrenadeTrajectoryMode", Value)
end})

GrenadeTrajectory_DepedencyBox:AddSlider("Combat_GrenadeTrajectoryBounces", {Text = "Bounces", Default = Visuals.Combat_GrenadeTrajectoryBounces, Min = 0, Max = 3, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "Combat_GrenadeTrajectoryBounces", Value)
end})

GrenadeTrajectory_DepedencyBox:AddSlider("Combat_GrenadeTrajectoryThickness", {Text = "Thickness", Default = Visuals.Combat_GrenadeTrajectoryThickness, Min = 1, Max = 6, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Combat_GrenadeTrajectoryThickness", Value)
end})

Visuals_CombatGroupbox:AddToggle("Combat_RadarHack", {Text = "Radar Hack", Default = Visuals.Combat_RadarHack, Callback = function(Value)
	UpdateTable(Visuals, "Combat_RadarHack", Value)
end})

Visuals_EnemyESPGroupbox:AddToggle("EnemyESP_MasterEnabled", {Text = "Master Switch", Default = Visuals.EnemyESP_MasterEnabled, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_MasterEnabled", Value)
end})

Visuals_EnemyESPGroupbox:AddSlider("EnemyESP_MasterOpacity", {Text = "Master Opacity", Default = Visuals.EnemyESP_MasterOpacity, Min = 0, Max = 100, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_MasterOpacity", Value)
end})

Visuals_EnemyESPGroupbox:AddToggle("EnemyESP_Chams", {Text = "Toggle Highlight Chams", Default = Visuals.EnemyESP_Chams, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_Chams", Value)
end}):AddColorPicker("EnemyESP_ChamsColor", {Default = Visuals.EnemyESP_ChamsColor, Title = "Chams Color", Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_ChamsColor", Value)
end})

local ChamsDependencyBox = Visuals_EnemyESPGroupbox:AddDependencyBox():SetupDependencies({{Toggles.EnemyESP_Chams, true}})

ChamsDependencyBox:AddDropdown("EnemyESP_ChamsRendering", {Text = "Rendering", Default = Visuals.EnemyESP_ChamsRendering, Values = {"Fill", "Outline"}, Multi = true, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_ChamsRendering", Value)
end})

ChamsDependencyBox:AddDropdown("EnemyESP_ChamsStyle", {Text = "Style", Default = Visuals.EnemyESP_ChamsStyle, Values = {"Solid", "Visible"}, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_ChamsStyle", Value)
end})

ChamsDependencyBox:AddDependencyBox():SetupDependencies({{Options.EnemyESP_ChamsStyle, "Visible"}}):AddLabel("Visible Color"):AddColorPicker("EnemyESP_ChamsVisibleColor", {
	Default = Visuals.EnemyESP_ChamsVisibleColor, Title = "Visible Color", Callback = function(Value)
		UpdateTable(Visuals, "EnemyESP_ChamsVisibleColor", Value)
	end
})

ChamsDependencyBox:AddToggle("EnemyESP_ChamsOccluded", {Text = "Occluded", Default = Visuals.EnemyESP_ChamsOccluded, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_ChamsOccluded", Value)
end})

Visuals_EnemyESPGroupbox:AddToggle("EnemyESP_Dots", {Text = "Toggle Head Dots", Default = Visuals.EnemyESP_Dots, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_Dots", Value)
end}):AddColorPicker("EnemyESP_DotColor", {Default = Visuals.EnemyESP_DotColor, Title = "Dot Color", Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_DotColor", Value)
end})

Visuals_EnemyESPGroupbox:AddDependencyBox():SetupDependencies({{Toggles.EnemyESP_Dots, true}}):AddSlider("EnemyESP_DotSize", {
	Text = "Size", Default = Visuals.EnemyESP_DotSize, Min = 1, Max = 10, Rounding = 0, Callback = function(Value)
		UpdateTable(Visuals, "EnemyESP_DotSize", Value)
	end
})

Visuals_EnemyESPGroupbox:AddToggle("EnemyESP_HeadTags", {Text = "Toggle Head Tags", Default = Visuals.EnemyESP_HeadTags, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_HeadTags", Value)
end}):AddColorPicker("EnemyESP_TagColor", {Default = Visuals.EnemyESP_TagColor, Title = "Tag Color", Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_TagColor", Value)
end})

local HeadTags_Depedencybox = Visuals_EnemyESPGroupbox:AddDependencyBox():SetupDependencies({{Toggles.EnemyESP_HeadTags, true}})

HeadTags_Depedencybox:AddDropdown("EnemyESP_HeadTagElements", {Text = "Elements", Default = Visuals.EnemyESP_HeadTagElements, Values = {"Name", "Health", "Distance", "Visibility"}, Multi = true, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_HeadTagElements", Value)
end})

HeadTags_Depedencybox:AddSlider("EnemyESP_TagSize", {Text = "Size", Default = Visuals.EnemyESP_TagSize, Min = 8, Max = 32, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_TagSize", Value)
end})

Visuals_EnemyESPGroupbox:AddToggle("EnemyESP_Boxes", {Text = "Toggle Boxes", Default = Visuals.EnemyESP_Boxes, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_Boxes", Value)
end}):AddColorPicker("EnemyESP_BoxColor", {Default = Visuals.EnemyESP_BoxColor, Title = "Box Color", Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_BoxColor", Value)
end})

Visuals_EnemyESPGroupbox:AddToggle("EnemyESP_Healthbars", {Text = "Toggle Healthbars", Default = Visuals.EnemyESP_Healthbars, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_Healthbars", Value)
end}):AddColorPicker("EnemyESP_HealthbarColor", {Default = Visuals.EnemyESP_HealthbarColor, Title = "Healthbar Color", Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_HealthbarColor", Value)
end})

Visuals_EnemyESPGroupbox:AddDependencyBox():SetupDependencies({{Toggles.EnemyESP_Healthbars, true}}):AddSlider("EnemyESP_HealthbarWidth", {
	Text = "Width", Default = Visuals.EnemyESP_HealthbarWidth, Min = 1, Max = 12, Rounding = 0, Callback = function(Value)
		UpdateTable(Visuals, "EnemyESP_HealthbarWidth", Value)
	end
})

Visuals_EnemyESPGroupbox:AddDependencyBox():SetupDependencies({{Toggles.EnemyESP_Boxes, true}}):AddSlider("EnemyESP_BoxThickness", {
	Text = "Thickness", Default = Visuals.EnemyESP_BoxThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
		Visuals.EnemyESP_BoxThickness = Value
		for _,DrawingGroup in next, Rendering_DrawingObjects do
			if DrawingGroup.Box then
				DrawingGroup.Box.Thickness = Value
			end
		end
	end
})

Visuals_EnemyESPGroupbox:AddToggle("EnemyESP_Tracers", {Text = "Toggle Tracers", Default = Visuals.EnemyESP_Tracers, Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_Tracers", Value)
end}):AddColorPicker("EnemyESP_TracerColor", {Default = Visuals.EnemyESP_TracerColor, Title = "Tracer Color", Callback = function(Value)
	UpdateTable(Visuals, "EnemyESP_TracerColor", Value)
end})

local TracersDependencyBox = Visuals_EnemyESPGroupbox:AddDependencyBox():SetupDependencies({{Toggles.EnemyESP_Tracers, true}})

TracersDependencyBox:AddDropdown("EnemyESP_TracerTarget", {Text = "Target", Default = Visuals.EnemyESP_TracerTarget, Values = {"Head", "Torso"}, Callback = function(Value)
	Visuals.EnemyESP_TracerTarget = Value
end})

TracersDependencyBox:AddDropdown("EnemyESP_TracerOrigin", {Text = "Origin", Default = Visuals.EnemyESP_TracerOrigin, Values = {"Bottom", "Center", "Top"}, Callback = function(Value)
	Visuals.EnemyESP_TracerOrigin = Value
end})

TracersDependencyBox:AddSlider("EnemyESP_TracerThickness", {Text = "Thickness", Default = Visuals.EnemyESP_TracerThickness, Min = 1, Max = 5, Rounding = 1, Callback = function(Value)
	Visuals.EnemyESP_TracerThickness = Value
	for _,DrawingGroup in next, Rendering_DrawingObjects do
		if DrawingGroup.Tracer then
			DrawingGroup.Tracer.Thickness = Visuals.EnemyESP_TracerThickness
		end
	end
end})

World_Camera:AddToggle("Camera_ThirdPersonView", {Text = "Third Person View", Default = Visuals.Camera_ThirdPersonView, Callback = function(Value)
	UpdateTable(Visuals, "Camera_ThirdPersonView", Value)
end}):AddKeyPicker("Camera_ThirdPersonView_Keybind", {
	Default = Visuals.Camera_ThirdPersonView_Keybind, Mode = "Toggle", Text = "Third Person View Keybind", ChangedCallback = function(Keybind)
		UpdateTable(Visuals, "Camera_ThirdPersonView_Keybind", Keybind)
	end, Callback = function(Value)
		IsThirdPersonActive = Value
	end
})

local ThirdPersonDependencyBox = World_Camera:AddDependencyBox():SetupDependencies({{Toggles.Camera_ThirdPersonView, true}})

ThirdPersonDependencyBox:AddToggle("Camera_ThirdPersonShowCharacter", {Text = "Show Character", Default = Visuals.Camera_ThirdPersonShowCharacter, Callback = function(Value)
	UpdateTable(Visuals, "Camera_ThirdPersonShowCharacter", Value)
end})

local ShowCharacterDependencyBox = World_Camera:AddDependencyBox():SetupDependencies({{Toggles.Camera_ThirdPersonShowCharacter, true}})
ShowCharacterDependencyBox:AddToggle("Camera_ThirdPersonShowCharacterWhileAiming", {Text = "Show Character While Aiming", Default = Visuals.Camera_ThirdPersonShowCharacterWhileAiming, Callback = function(Value)
	UpdateTable(Visuals, "Camera_ThirdPersonShowCharacterWhileAiming", Value)
end})

ShowCharacterDependencyBox:AddToggle("Camera_ThirdPersonApplyAntiAimToCharacter", {Text = "Apply Anti Aim To Character", Default = Visuals.Camera_ThirdPersonApplyAntiAimToCharacter, Callback = function(Value)
	UpdateTable(Visuals, "Camera_ThirdPersonApplyAntiAimToCharacter", Value)
end})

ThirdPersonDependencyBox:AddToggle("Camera_ThirdPersonCameraCollision", {Text = "Camera Collision", Default = Visuals.Camera_ThirdPersonCameraCollision, Callback = function(Value)
	UpdateTable(Visuals, "Camera_ThirdPersonCameraCollision", Value)
end})

ThirdPersonDependencyBox:AddSlider("Camera_ThirdPersonOffsetX", {Text = "Offset X", Default = Visuals.Camera_ThirdPersonOffsetX, Min = -20, Max = 20, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "Camera_ThirdPersonOffsetX", Value)
end})

ThirdPersonDependencyBox:AddSlider("Camera_ThirdPersonOffsetY", {Text = "Offset Y", Default = Visuals.Camera_ThirdPersonOffsetY, Min = -20, Max = 20, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "Camera_ThirdPersonOffsetY", Value)
end})

ThirdPersonDependencyBox:AddSlider("Camera_ThirdPersonOffsetZ", {Text = "Offset Z", Default = Visuals.Camera_ThirdPersonOffsetZ, Min = -20, Max = 20, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "Camera_ThirdPersonOffsetZ", Value)
end})

World_Camera:AddToggle("Camera_FOVModificationEnabled", {Text = "FOV Modification", Default = Visuals.Camera_FOVModificationEnabled, Callback = function(Value)
	UpdateTable(Visuals, "Camera_FOVModificationEnabled", Value)
end})

World_Camera:AddDependencyBox():SetupDependencies({{Toggles.Camera_FOVModificationEnabled, true}}):AddSlider("Camera_FOVValue", {
	Text = "FOV Value", Default = Visuals.Camera_FOVValue, Min = 30, Max = 120, Rounding = 0, Callback = function(Value)
		UpdateTable(Visuals, "Camera_FOVValue", Value)
	end
})

World_ViewModel:AddToggle("Viewmodel_Chams", {Text = "Viewmodel Chams", Default = Visuals.Viewmodel_Chams, Callback = function(Value)
	UpdateTable(Visuals, "Viewmodel_Chams", Value)
end}):AddColorPicker("Viewmodel_ChamsColor", {Default = Visuals.Viewmodel_ChamsColor, Title = "Chams Color", Callback = function(Value)
	UpdateTable(Visuals, "Viewmodel_ChamsColor", Value)
end})

local ViewmodelChamsDependencyBox = World_ViewModel:AddDependencyBox():SetupDependencies({{Toggles.Viewmodel_Chams, true}})

ViewmodelChamsDependencyBox:AddDropdown("Viewmodel_ChamsTargets", {Text = "Targets", Default = {"Arms", "Weapon"}, Multi = true, Values = {"Arms", "Weapon"}, Callback = function(Value)
	UpdateTable(Visuals, "Viewmodel_ChamsTargets", Value)
end})

ViewmodelChamsDependencyBox:AddDropdown("Viewmodel_ChamsType", {Text = "Type", Default = Visuals.Viewmodel_ChamsType, Values = {"ForceField", "Neon", "Glass", "Plastic"}, Callback = function(Value)
	UpdateTable(Visuals, "Viewmodel_ChamsType", Value)
end})

local ViewmodelTranslucentDependencyBox = ViewmodelChamsDependencyBox:AddDependencyBox():SetupDependencies({{Options.Viewmodel_ChamsType, {"Neon", "Glass", "Plastic"}}})

ViewmodelTranslucentDependencyBox:AddToggle("Viewmodel_ChamsTranslucent", {Text = "Translucent", Default = Visuals.Viewmodel_ChamsTranslucent, Callback = function(Value)
	UpdateTable(Visuals, "Viewmodel_ChamsTranslucent", Value)
end})

World_ViewModel:AddToggle("Viewmodel_NoSleeves", {Text = "No Sleeves", Default = Visuals.Viewmodel_NoSleeves, Callback = function(Value)
	UpdateTable(Visuals, "Viewmodel_NoSleeves", Value)
end})

World_Lighting:AddToggle("Lighting_ModifyLighting", {Text = "Lighting Modification", Default = Visuals.Lighting_ModifyLighting, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_ModifyLighting", Value, function()
		for Connection in next, LightingCache.Connections do
			Connection:Disconnect()
		end
		table.clear(LightingCache.Connections)

		if not Visuals.Lighting_ModifyLighting then
			RefreshLighting(true)
			return
		end

		local Properties = {"Ambient", "OutdoorAmbient", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness"}
		for _,Property in ipairs(Properties) do
			LightingCache.Connections[Lighting:GetPropertyChangedSignal(Property):Connect(function()
				local Current = Lighting[Property]
				RefreshLighting(false)
				if Lighting[Property] ~= Current then
					LightingCache.OriginalValues[Property] = Current
					RefreshLighting(false)
				end
			end)] = true
		end

		RefreshLighting(false)
	end)
end})

local LightingDependencyBox = World_Lighting:AddDependencyBox():SetupDependencies({{Toggles.Lighting_ModifyLighting, true}})

LightingDependencyBox:AddSlider("Lighting_ExposureCompensation", {Text = "Exposure Compensation", Default = Visuals.Lighting_ExposureCompensation, Min = -5, Max = 5, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_ExposureCompensation", Value, function(Value)
		Lighting.ExposureCompensation = Value
	end) 
end})

LightingDependencyBox:AddLabel("Ambient"):AddColorPicker("Lighting_Ambient", {Default = Visuals.Lighting_Ambient, Title = "Ambient Color", Callback = function(Value)
	UpdateTable(Visuals, "Lighting_Ambient", Value, function(Value)
		Lighting.Ambient = Value
	end)
end})

LightingDependencyBox:AddLabel("Outdoor Ambient"):AddColorPicker("Lighting_OutdoorAmbient", {Default = Visuals.Lighting_OutdoorAmbient, Title = "Outdoor Ambient", Callback = function(Value)
	UpdateTable(Visuals, "Lighting_OutdoorAmbient", Value, function(Value)
		Lighting.OutdoorAmbient = Value
	end)
end})

LightingDependencyBox:AddSlider("Lighting_EnvironmentDiffuseScale", {Text = "Diffuse Scale", Default = Visuals.Lighting_EnvironmentDiffuseScale, Min = 0, Max = 1, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_EnvironmentDiffuseScale", Value, function(Value) 
		Lighting.EnvironmentDiffuseScale = Value
	end)
end})

LightingDependencyBox:AddSlider("Lighting_EnvironmentSpecularScale", {Text = "Specular Scale", Default = Visuals.Lighting_EnvironmentSpecularScale, Min = 0, Max = 1, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_EnvironmentSpecularScale", Value, function(Value)
		Lighting.EnvironmentSpecularScale = Value
	end)
end})

LightingDependencyBox:AddSlider("Lighting_ShadowSoftness", {Text = "Shadow Softness", Default = Visuals.Lighting_ShadowSoftness, Min = 0, Max = 1, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_ShadowSoftness", Value, function(Value)
		Lighting.ShadowSoftness = Value
	end)
end})

World_Lighting:AddToggle("Lighting_Flashlight", {Text = "Flashlight", Default = Visuals.Lighting_Flashlight, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_Flashlight", Value)
end})

local FlashlightDependencyBox = World_Lighting:AddDependencyBox():SetupDependencies({{Toggles.Lighting_Flashlight, true}})

FlashlightDependencyBox:AddLabel("Flashlight Color"):AddColorPicker("Lighting_FlashlightColor", {Default = Visuals.Lighting_FlashlightColor, Title = "Flashlight Color", Callback = function(Value)
	UpdateTable(Visuals, "Lighting_FlashlightColor", Value)
end})

FlashlightDependencyBox:AddSlider("Lighting_FlashlightBrightness", {Text = "Brightness", Default = Visuals.Lighting_FlashlightBrightness, Min = 0, Max = 10, Rounding = 1, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_FlashlightBrightness", Value)
end})

FlashlightDependencyBox:AddSlider("Lighting_FlashlightRange", {Text = "Range", Default = Visuals.Lighting_FlashlightRange, Min = 0, Max = 60, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_FlashlightRange", Value)
end})

FlashlightDependencyBox:AddSlider("Lighting_FlashlightAngle", {Text = "Angle", Default = Visuals.Lighting_FlashlightAngle, Min = 0, Max = 180, Rounding = 0, Callback = function(Value)
	UpdateTable(Visuals, "Lighting_FlashlightAngle", Value)
end})

local Settings_UserInterface = Tabs.Settings:AddLeftGroupbox("User Interface")
Settings_UserInterface:CreateConfigurationManager("NikoletoScripts/PhantomWare", ".ns", {Aiming, Visuals, Miscellaneous, Settings})
Settings_UserInterface:AddLabel("Menu Toggle Keybind"):AddKeyPicker("Inactive4", {Default = "RightShift", Mode = "Toggle", Text = "Menu Toggle Keybind", Callback = function(Value)
	Library:Toggle()
end})

local Settings_Advanced = Tabs.Settings:AddRightGroupbox("Advanced")

Settings_Advanced:AddToggle("Advanced_ESPFramerateCap", {Text = "ESP Framerate Cap", Default = Settings.Advanced_ESPFramerateCap, Callback = function(Value)
	UpdateTable(Settings, "Advanced_ESPFramerateCap", Value)
end})
Settings_Advanced:AddDependencyBox():SetupDependencies({{Toggles.Advanced_ESPFramerateCap, true}}):AddSlider("Advanced_ESPFPSCapValue", {
	Text = "FPS Cap", Default = Settings.Advanced_ESPFPSCapValue, Min = 1, Max = 360, Rounding = 0, Callback = function(Value)
		UpdateTable(Settings, "Advanced_ESPFPSCapValue", Value)
	end
})

Settings_Advanced:AddToggle("Advanced_MultiPointEnabled", {Text = "Multi-Point Raycasting", Default = Settings.Advanced_MultiPointEnabled, Callback = function(Value)
	UpdateTable(Settings, "Advanced_MultiPointEnabled", Value)
end})
local MultiPointDependencyBox = Settings_Advanced:AddDependencyBox():SetupDependencies({{Toggles.Advanced_MultiPointEnabled, true}})
MultiPointDependencyBox:AddSlider("Advanced_MultiPointScale", {Text = "Scale", Default = Settings.Advanced_MultiPointScale, Min = 2, Max = 10, Rounding = 0, Callback = function(Value)
	UpdateTable(Settings, "Advanced_MultiPointScale", Value)
end})
MultiPointDependencyBox:AddSlider("Advanced_MultiPointLayers", {Text = "Layers", Default = Settings.Advanced_MultiPointLayers, Min = 1, Max = 5, Rounding = 0, Callback = function(Value)
	UpdateTable(Settings, "Advanced_MultiPointLayers", Value)
end})

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
if RemoteEvent then
	local HitMarkerThicknessProperty = {Thickness = 1.5}
	local function PlayTween(Tween)
		Tween:Play()
		return Tween
	end
	RemoteEvent.OnClientEvent:Connect(function(Type, ...)
		local Arguments = {...}
		if Type == "bulletHitConfirm" then
			local Position = Arguments[3]
			if Miscellaneous.HitLogs_Enabled then
				local Text, Damage = {"Hit " .. Arguments[1].Name}, math.floor(Arguments[4])
				table.insert(Text, "in the " .. Arguments[2])
				if Miscellaneous.HitLogs_ShowDamage then
					table.insert(Text, "for " .. tostring(math.floor(Damage)) .. " health")
				end

				if Miscellaneous.HitLogs_ShowDistance then
					table.insert(Text, "from " .. math.floor((GetLocalPosition() - Position).Magnitude) .. "m away")
				end

				if Damage > 99 then
					table.insert(Text, "[INSTANT KILL]")
				end

				Library:Notify(table.concat(Text, " "), 3)
			end

			if Visuals.Combat_HitMarkerEnabled then
				local Style, DrawingObjects = Visuals.Combat_HitMarkerStyle, {}

				table.insert(DrawingObjects, CreateDrawing("Line", HitMarkerThicknessProperty))
				table.insert(DrawingObjects, CreateDrawing("Line", HitMarkerThicknessProperty))
				table.insert(DrawingObjects, CreateDrawing("Line", HitMarkerThicknessProperty))
				table.insert(DrawingObjects, CreateDrawing("Line", HitMarkerThicknessProperty))

				table.insert(ActiveHitMarkers, {
					Position = Position,
					Time = os.clock(),
					Duration = Visuals.Combat_HitMarkerDuration,
					Style = Style,
					Color = Visuals.Combat_HitMarkerColor,
					DrawingObjects = DrawingObjects
				})
			end
			return
		end

		local Info = Arguments[1]
		if Type == "died" then
			local Victim = Info.victim
			if Victim == LocalPlayer then
				IsSpawned = false
				return
			end

			local Attacker = Info.attacker
			if not Attacker then
				return
			end

			local IsLocalPlayer = Attacker == LocalPlayer
			if Victim == AimbotTarget and Aiming.Aimbot_DeathNotification then
				Library:Notify(IsLocalPlayer and ("You eliminated " .. Victim.Name) or ("Target was eliminated by " .. Attacker.Name), 3)
			end

			if IsLocalPlayer then
				if Visuals.Combat_LightningKillEffectEnabled then
					local Origin = Info.origin
					if not Origin then
						return
					end

					local Direction = Info.direction
					if not Direction then
						return
					end

					local Color = Visuals.Combat_LightningKillEffectColor

					local Part = ns__cloneref(Instance.new("Part"))
					Part.Anchored = true
					Part.Material = Enum.Material.Neon
					Part.CanCollide = false
					Part.CanTouch = false
					Part.CanQuery = false
					Part.Color = Color
					Part.Size = Vector3.new(6, 1000, 6)
					Part.Position = Origin + Direction
					
					Part.Parent = Terrain
					local PointLight = ns__cloneref(Instance.new("PointLight"))
					PointLight.Brightness = 3
					PointLight.Color = Color
					PointLight.Range = 20
					PointLight.Parent = Part
					PlayTween(TweenService:Create(Part, TweenInfo.new(2), {
						Size = Vector3.new(0, 500, 0), Transparency = 1
					})).Completed:Once(function()
						Part:Destroy()
					end)
				end
			end
		end
	end)
end
local ThirdPersonLastPosition = nil
local ThirdPersonDeltaTime = 0

task.spawn(function()
	FakeReplicationObject = ReplicationObject.new(setmetatable({}, {
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

local RaycastStep, GrenadeTrajectory2DLines, GrenadeTrajectory3DSegments = 1/60, {}, {}
local GrenadeTrajectory2DMarker = CreateDrawing("Circle", {Filled = true, NumSides = 12})
local GrenadeTrajectory3DMarker = Create("SphereHandleAdornment", Parent, {Radius = 0.25, ZIndex = 5, AlwaysOnTop = true, Adornee = Terrain})
RunService.Heartbeat:Connect(function(DeltaTime)
	local AutoSpot = Visuals.EnemyESP_MasterEnabled and Visuals.Combat_RadarHack
	OperateOnAllEntries(function(Player, Entry)
		if not Entry._isEnemy or not Entry._alive then
			if MovementCache[Player] then
				MovementCache[Player] = nil
			end
			return
		end

		local Status = AutoSpot and GetPlayerStatusEntry(Player)
		if Status then
			Status.isSpotted = true
		end

		local Cache = MovementCache[Player]
		if not Cache then
			Cache = {}
			MovementCache[Player] = Cache
		end

		local Count = #Cache
		if Count >= 15 then
			for Index = 15, 2, -1 do
				Cache[Index] = Cache[Index - 1]
			end
		else
			for Index = Count, 1, -1 do
				Cache[Index + 1] = Cache[Index]
			end
		end

		Cache[1] = {Position = Entry._thirdPersonObject._characterModelHash.Head.Position, Time = os.clock()}
	end)

	if Visuals.Camera_ThirdPersonShowCharacter and Visuals.Camera_ThirdPersonView and IsThirdPersonActive then
		local LocalCharacter = GetLocalCharacter()
		local RootPart = LocalCharacter and LocalCharacter:getRealRootPart()
		if RootPart then
			ThirdPersonDeltaTime += DeltaTime
			local Position = RootPart.Position
			ThirdPersonLastPosition = ThirdPersonLastPosition or Position
			ThirdPersonDeltaTime = 0

			if IsFakeSpawned or not FakeThirdPersonObject then
				local PlayerData = PlayerDataClientInterface.getPlayerData()
				local Settings = PlayerData and PlayerData.settings
				if Settings then
					local ClassData = Settings.classdata
					if ClassData then
						FakeReplicationObject._player = LocalPlayer
						FakeReplicationObject:spawn(nil, ClassData[ClassData.curclass])
						FakeThirdPersonObject = FakeReplicationObject._thirdPersonObject
						FakeReplicationObject:setActiveIndex(1)
						local WeaponObjects = FakeReplicationObject:getWeaponObjects()
						for Index = 1, 3 do
							if WeaponObjects[Index] then
								FakeThirdPersonObject:buildWeapon(Index)
							end
						end
						IsFakeSpawned = false
					end
				end
			end

			if FakeThirdPersonObject then
				local Angles = CameraInterface:getActiveCamera():getAngles()
				if Miscellaneous.Movement_AntiAimEnabled and Visuals.Camera_ThirdPersonApplyAntiAimToCharacter then
					local X, Y, Z = Angles.X, Angles.Y, Angles.Z

					if Miscellaneous.Movement_AntiAimYaw then
						local Addition = math.rad(Miscellaneous.Movement_AntiAimYawAmount)
						Y = Miscellaneous.Movement_AntiAimYawMode == "Relative" and (Y + Addition) or Addition
					end

					if Miscellaneous.Movement_AntiAimSpinBot then
						Y += ((os.clock() * math.rad(Miscellaneous.Movement_AntiAimSpinSpeed)) % TwoPi) * (Miscellaneous.Movement_AntiAimSpinDirection == "Left" and 1 or -1)
					end

					if Miscellaneous.Movement_AntiAimJitter then
						Y += (math.floor(os.clock() * Miscellaneous.Movement_AntiAimJitterSpeed) % 2 == 0) and math.pi or 0
					end

					if Miscellaneous.Movement_AntiAimPitch then
						local Addition = math.rad(Miscellaneous.Movement_AntiAimPitchAmount) - Quarter
						X = Miscellaneous.Movement_AntiAimPitchMode == "Absolute" and Addition or math.clamp(X + Addition, NegativeQuarter, Quarter)
					end

					Angles = Vector3.new(X, Y, Z)
				end

				FakeReplicationObject._posspring.t = Position
				FakeReplicationObject._posspring.p = Position
				FakeReplicationObject._lookangles.t = Angles
				FakeReplicationObject._lookangles.p = Angles

				local ClockTime, TickTime = os.clock(), tick()
				FakeReplicationObject._smoothReplication:receive(ClockTime, TickTime, {
					t = TickTime, position = Position, velocity = ThirdPersonDeltaTime > 0 and (Position - ThirdPersonLastPosition) / ThirdPersonDeltaTime or Vector3.zero,
					angles = Angles, barrelAngles = Vector3.zero, breakcount = 0
				}, true)

				FakeReplicationObject._updaterecieved = true
				FakeReplicationObject._receivedPosition = Position
				FakeReplicationObject._receivedFrameTime = NetworkClient.getTime()
				FakeReplicationObject._lastPacketTime = ClockTime
				FakeReplicationObject._lastBarrelAngles = Vector3.zero
				FakeReplicationObject:step(3, true)

				local IsAiming = false
				local Weapon = GetActiveWeapon()
				if Weapon and Weapon._aiming then
					IsAiming = true
				end

				if not Visuals.Camera_ThirdPersonShowCharacterWhileAiming and IsAiming then
					FakeThirdPersonObject:setCharacterRender(false)
				else
					FakeThirdPersonObject:setCharacterRender(true)
					FakeThirdPersonObject.canRenderWeapon = true
					if FakeThirdPersonObject._characterModelHash then
						for _,Part in next, FakeThirdPersonObject._characterModelHash do
							Part.LocalTransparencyModifier = 0
							Part.Transparency = 0
						end
					end
				end
			end

			ThirdPersonLastPosition = Position
		else
			if FakeThirdPersonObject then
				FakeReplicationObject:despawn()
				FakeThirdPersonObject:Destroy()
				FakeThirdPersonObject = nil
				ThirdPersonLastPosition = nil
			end
		end
	else
		if FakeThirdPersonObject then
			FakeReplicationObject:despawn()
			FakeThirdPersonObject:Destroy()
			FakeThirdPersonObject = nil
			ThirdPersonLastPosition = nil
		end
	end

	if LocalHumanoid and Miscellaneous.Movement_BunnyHop and UserInputService:IsKeyDown(Enum.KeyCode.Space) and LocalHumanoid.FloorMaterial ~= Enum.Material.Air then
		local LocalCharacter = GetLocalCharacter()
		if LocalCharacter then
			rawset(LocalCharacter, "_lastJumpTime", 0)
			LocalCharacter:jump(4)
		end
	end

	local Now = os.clock()
	for Index = #ActiveBulletTracers, 1, -1 do
		local Data = ActiveBulletTracers[Index]
		local Elapsed, Duration = Now - Data.StartTime, Data.Duration
		if Elapsed >= Duration then
			ReleaseBeam(Data.Beam)
			ReleaseAttachment(Data.Attachment0)
			ReleaseAttachment(Data.Attachment1)
			table.remove(ActiveBulletTracers, Index)
		else
			local Progress = Elapsed / Duration
			if Visuals.Combat_BulletTracerFadeMode == "Width" then
				local Beam, Thickness = Data.Beam, Data.Thickness * (1 - Progress)
				Beam.Width0 = Thickness
				Beam.Width1 = Thickness
			else
				local Alpha = Data.Alpha
				Data.Beam.Transparency = NumberSequence.new((1 - Alpha) + (Alpha * Progress))
			end
		end
	end

	local Weapon = IsRageBotInputActive and IsSpawned and GetActiveWeapon()
	if Weapon and Weapon:getWeaponType() == "Firearm" and Weapon._magCount and Weapon._spareCount and (Weapon._magCount > 0 or Weapon._spareCount > 0) then
		if Now < RageBotNextShot then
			return
		end

		local WeaponData = Weapon._weaponData
		local PenetrationDepth = WeaponData.penetrationdepth
		if not PenetrationDepth then
			return
		end

		local BulletSpeed = WeaponData.bulletspeed
		if not BulletSpeed then
			return
		end

		local Origin = GetLocalPosition()
		local SortedEntries = {}
		local SortedDistances = {}
		OperateOnAllEntries(function(Player, Entry)
			if not Entry._isEnemy or not Entry._alive then
				return
			end

			local Index = #SortedEntries + 1
			SortedEntries[Index] = Entry

			local HeadPosition = Entry._thirdPersonObject._characterModelHash.Head.Position
			local DeltaX, DeltaY, DeltaZ = HeadPosition.X - Origin.X, HeadPosition.Y - Origin.Y, HeadPosition.Z - Origin.Z
			SortedDistances[Index] = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ)
		end)

		local EntryCount = #SortedEntries
		if EntryCount == 0 then
			return
		end

		local IndexTable = table.create(EntryCount)
		for Index = 1, EntryCount do
			IndexTable[Index] = Index
		end

		table.sort(IndexTable, function(Distance1, Distance2)
			return SortedDistances[Distance1] < SortedDistances[Distance2]
		end)

		local SortedByDistance = table.create(EntryCount)
		for Index = 1, EntryCount do
			SortedByDistance[Index] = SortedEntries[IndexTable[Index]]
		end
		SortedEntries = SortedByDistance

		local RageBotPart = Aiming.RageBot_Part
		local HitboxPriorityOrder = Aiming.RageBot_HitboxPriorityOrder
		local ShouldCreateBulletTracer = Visuals.Combat_BulletTracerColor and not Aiming.RageBot_IgnoreBulletTracers
		local PenetrationDetection = Aiming.RageBot_WallPenetrationDetection
		local Layers = Settings.Advanced_MultiPointLayers
		local BulletAcceleration = PublicSettings.bulletAcceleration
		local BulletAccelerationTerm = BulletAcceleration:Dot(BulletAcceleration)
		for EntryIndex = 1, #SortedEntries do
			local Entry = SortedEntries[EntryIndex]
			local Character = GetCharacterModelHash(Entry._thirdPersonObject)

			local Head, Torso = Character.Head, Character.Torso
			local LeftArm, RightArm = Character["Left Arm"], Character["Right Arm"]
			local LeftLeg, RightLeg = Character["Left Leg"], Character["Right Leg"]

			local TargetCount = 0
			local Part1, Part2, Part3, Part4, Part5, Part6
			local IsPart1, IsPart2, IsPart3, IsPart4, IsPart5, IsPart6 = true, true, true, true, true, true

			if RageBotPart == "Head" then
				if Head then
					TargetCount = 1
					Part1 = Head
				end
			elseif RageBotPart == "Torso" then
				if Torso then
					TargetCount = 1
					Part1 = Torso
				end
			elseif RageBotPart == "Priority" then
				for _,Name in ipairs(HitboxPriorityOrder) do
					if Name == "Head" then
						if Head then
							TargetCount += 1
							if TargetCount == 1 then
								Part1 = Head
							elseif TargetCount == 2 then
								Part2 = Head
							elseif TargetCount == 3 then
								Part3 = Head
							elseif TargetCount == 4 then
								Part4 = Head
							elseif TargetCount == 5 then
								Part5 = Head
							else
								Part6 = Head 
							end
						end
					elseif Name == "Torso" then
						if Torso then
							TargetCount += 1
							if TargetCount == 1 then
								Part1 = Torso
							elseif TargetCount == 2 then
								Part2 = Torso
							elseif TargetCount == 3 then
								Part3 = Torso
							elseif TargetCount == 4 then
								Part4 = Torso
							elseif TargetCount == 5 then
								Part5 = Torso
							else
								Part6 = Torso
							end
						end
					else
						for _,Arm in ipairs(Name == "Arms" and {LeftArm, RightArm} or {LeftLeg, RightLeg}) do
							if not Arm then
								continue
							end
							TargetCount += 1
							if TargetCount == 1 then
								Part1 = Arm
							elseif TargetCount == 2 then
								Part2 = Arm
							elseif TargetCount == 3 then
								Part3 = Arm
							elseif TargetCount == 4 then
								Part4 = Arm
							elseif TargetCount == 5 then
								Part5 = Arm
							else
								Part6 = Arm
							end
						end
					end
				end
			elseif RageBotPart == "Closest" then
				local Parts, AllDists, PartIndices = {Head, Torso, LeftArm, RightArm, LeftLeg, RightLeg}, {}, {1, 2, 3, 4, 5, 6}
				for Index = 1, 6 do
					if Parts[Index] then
						local Position = Parts[Index].Position
						local DeltaX, DeltaY, DeltaZ = Position.X - Origin.X, Position.Y - Origin.Y, Position.Z - Origin.Z
						AllDists[Index] = DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ
					else
						AllDists[Index] = math.huge
					end
				end

				table.sort(PartIndices, function(Distance1, Distance2)
					return AllDists[Distance1] < AllDists[Distance2]
				end)

				Parts = {
					Parts[PartIndices[1]],
					Parts[PartIndices[2]],
					Parts[PartIndices[3]],
					Parts[PartIndices[4]],
					Parts[PartIndices[5]],
					Parts[PartIndices[6]]
				}

				for Index = 1, 6 do
					if Parts[Index] then
						TargetCount += 1
						if TargetCount == 1 then
							Part1 = Parts[Index]
						elseif TargetCount == 2 then
							Part2 = Parts[Index]
						elseif TargetCount == 3 then
							Part3 = Parts[Index]
						elseif TargetCount == 4 then
							Part4 = Parts[Index]
						elseif TargetCount == 5 then
							Part5 = Parts[Index]
						else
							Part6 = Parts[Index]
						end
					end
				end
			elseif RageBotPart == "Random" then
				Part1 = ({Head, Torso, LeftArm, RightArm, LeftLeg, RightLeg})[math.random(1, Count)]
				TargetCount = 1
			end

			if TargetCount == 0 then
				TargetCount = 1
				Part1 = Entry._receivedPosition
				IsPart1 = false
			end

			local TargetList, PartList = {Part1, Part2, Part3, Part4, Part5, Part6}, {IsPart1, IsPart2, IsPart3, IsPart4, IsPart5, IsPart6}
			local NewOrigin, NewTarget, Velocity

			for TargetIndex = 1, TargetCount do
				local TargetPart, IsPart = TargetList[TargetIndex], PartList[TargetIndex]
				local CurrentTarget = IsPart and TargetPart.Position or TargetPart

				local CurrentVelocity = GetBulletVelocity(Origin, CurrentTarget, BulletSpeed, BulletAcceleration, BulletAccelerationTerm)
				if not CurrentVelocity then
					continue
				end
				
				if PenetrationDetection and BulletCheck(Origin, CurrentTarget, CurrentVelocity, BulletAcceleration, PenetrationDepth, RaycastStep) then
					NewOrigin = Origin
					NewTarget = CurrentTarget
					Velocity = CurrentVelocity
					break
				elseif IsPart and RageBot_CanHit(TargetPart, Layers) then
					NewOrigin = Origin
					NewTarget = CurrentTarget
					Velocity = CurrentVelocity
					break
				end
			end

			if NewOrigin then
				local MagCount = Weapon._magCount
				if MagCount < 1 then
					local SpareCount, MagSize = Weapon._spareCount, WeaponData.magsize
					if SpareCount >= MagSize then
						Weapon._magCount = MagSize
						Weapon._spareCount -= MagCount
					else
						Weapon._magCount = SpareCount
						Weapon._spareCount = 0
					end
					NetworkClientSend(NetworkClient, "reload")
				end

				local IsSinglePellet = false
				local PelletCount =  WeaponData.pelletcount
				if not PelletCount then
					PelletCount = 1 
					IsSinglePellet = true
				end

				local Direction, Bullets = Velocity.Unit, table.create(PelletCount)

				if IsSinglePellet then
					Bullets[1] = {Direction, GlobalTicketCounter + TicketAddition}
					TicketAddition += 1
				else
					for Index = 1, PelletCount do
						Bullets[Index] = {Direction, GlobalTicketCounter + TicketAddition}
						TicketAddition += 1
					end
				end

				local UniqueId = Weapon.uniqueId
				NetworkClientSend(NetworkClient, "newbullets", UniqueId, {
					camerapos = Origin,
					firepos = NewOrigin,
					velocity = Velocity,
					bullets = Bullets,
				}, NetworkClient.getTime())

				local Player = Entry._player
				if IsSinglePellet then
					NetworkClientSend(NetworkClient, "bullethit", UniqueId, Player, NewTarget, "Head", Bullets[1][2], NetworkClient.getTime())
				else
					for Index = 1, PelletCount do
						NetworkClientSend(NetworkClient, "bullethit", UniqueId, Player, NewTarget, "Head", Bullets[Index][2], NetworkClient.getTime())
					end
				end

				local Barrel = Weapon._barrelPart
				MuzzleFlash(Barrel, WeaponData.hideflash, 0.9)

				local WeaponType = WeaponData.type
				if WeaponType == "SNIPER" then
					PlayGameSound("metalshell", 0.1)
				elseif WeaponType == "SHOTGUN" then
					PlayGameSound("shotWeaponshell", 0.2)
				elseif WeaponType == "REVOLVER" and not WeaponData.caselessammo then
					PlayGameSound("metalshell", 0.15, 0.8)
				end

				if not Weapon._aiming then
					FireImpulse(WeaponData.crossexpansion)
				end

				if WeaponData.sniperbass then
					PlayGameSound("1PsniperBass", 0.75)
					PlayGameSound("1PsniperEcho", 1)
				end

				local HitSound = Miscellaneous.SoundOverride_HitSound
				if HitSound == "None" then
					PlaySoundId(WeaponData.firesoundid, 2, WeaponData.firevolume, WeaponData.firepitch, Barrel, nil, 0, 0.05)
				else
					PlaySoundId(CustomSounds[HitSound], 2, WeaponData.firevolume, WeaponData.firepitch, Barrel, nil, 0, 0.05)
				end

				if ShouldCreateBulletTracer then
					CreateBulletTracer(NewOrigin, Direction * 1500)
				end

				local FireRate = WeaponData.firerate
				RageBotNextShot = Now + (60 / (WeaponData.variablefirerate and FireRate[Weapon._firemodeIndex] or FireRate))
				Weapon._magCount -= 1
				break
			end
		end
	end
end)

local FOVCircle = CreateDrawing("Circle", {Visible = false, Filled = false, Color = Aiming.Aimbot_FOVColor, Position = ScreenCenter, Thickness = 1})
local TargetTracer = CreateDrawing("Line", {Visible = false, Color = Aiming.Aimbot_TargetTracerColor, Thickness = 1.5})
local LastESPUpdateTime, ns__mousemoverel = 0, mousemoverel or function() end
RunService.RenderStepped:Connect(function()
	local Now, LocalHeadPosition = os.clock(), GetLocalPosition()
	table.clear(CanSeeCache)

	for Index = #ActiveHitMarkers, 1, -1 do
		local Marker = ActiveHitMarkers[Index]
		local DrawingObjects = Marker.DrawingObjects
		local Elapsed = Now - Marker.Time
		
		if Elapsed >= Marker.Duration then
			for _,DrawingObject in ipairs(DrawingObjects) do
				DrawingObject:Remove()
			end
			table.remove(ActiveHitMarkers, Index)
			continue
		end

		local Screen, OnScreen = WorldToViewportPoint(Marker.Position)
		if not OnScreen then
			for _,DrawingObject in ipairs(DrawingObjects) do
				SetProperty(DrawingObject, "Visible", false)
			end
			continue
		end

		local X, Y = Screen.X, Screen.Y
		local Spin = Visuals.Combat_HitMarkerSpin
		local Size = Visuals.Combat_HitMarkerSize
		local Gap = Visuals.Combat_HitMarkerGap
		local Angle = 0

		if Spin then
			Angle = Elapsed * Visuals.Combat_HitMarkerSpinSpeed
			Size = Size
			Gap = Gap
		end

		local MarkerColor = Marker.Color
		if Marker.Style == "X" then
			HandleLine(Marker.DrawingObjects[1], Vector2.new(X - Size, Y - Size), Vector2.new(X - Gap, Y - Gap), Screen, Angle, MarkerColor, Spin)
			HandleLine(Marker.DrawingObjects[2], Vector2.new(X + Size, Y - Size), Vector2.new(X + Gap, Y - Gap), Screen, Angle, MarkerColor, Spin)
			HandleLine(Marker.DrawingObjects[3], Vector2.new(X - Size, Y + Size), Vector2.new(X - Gap, Y + Gap), Screen, Angle, MarkerColor, Spin)
			HandleLine(Marker.DrawingObjects[4], Vector2.new(X + Size, Y + Size), Vector2.new(X + Gap, Y + Gap), Screen, Angle, MarkerColor, Spin)
		else
			HandleLine(Marker.DrawingObjects[1], Vector2.new(X - Size, Y), Vector2.new(X - Gap, Y), Screen, Angle, MarkerColor, Spin)
			HandleLine(Marker.DrawingObjects[2], Vector2.new(X + Size, Y), Vector2.new(X + Gap, Y), Screen, Angle, MarkerColor, Spin)
			HandleLine(Marker.DrawingObjects[3], Vector2.new(X, Y - Size), Vector2.new(X, Y - Gap), Screen, Angle, MarkerColor, Spin)
			HandleLine(Marker.DrawingObjects[4], Vector2.new(X, Y + Size), Vector2.new(X, Y + Gap), Screen, Angle, MarkerColor, Spin)
		end
	end

	if Aiming.Aimbot_Enabled then
		local ShowFOV = Aiming.Aimbot_ShowFOV
		if ShowFOV then
			SetProperty(FOVCircle, "Radius", Aiming.Aimbot_FOVRadius)
			SetProperty(FOVCircle, "Color", Aiming.Aimbot_FOVColor)
			SetProperty(FOVCircle, "Transparency", Aiming.Aimbot_FOVOpacity)
			SetProperty(FOVCircle, "Visible", true)
		else
			SetProperty(FOVCircle, "Visible", false)
		end

		local IsLocking = false
		if IsSpawned and IsAimbotInputActive then
			local TargetPart, Target, IsTargetVisible, TargetScreen, ClosestScore = nil, nil, false, nil, math.huge
			local FOVRadius, IsWallCheckOff = ShowFOV and Aiming.Aimbot_FOVRadius or math.huge, not Aiming.Aimbot_WallCheck
			local AimbotPart, CenterX, CenterY = Aiming.Aimbot_Part, ScreenCenter.X, ScreenCenter.Y

			local function EvaluatePlayer(Player, Character)
				local Torso = Character.Torso
				local CameraCFrame, TorsoPosition = Camera.CFrame, Torso.Position
				local CameraPosition, LookVector = CameraCFrame.Position, CameraCFrame.LookVector
				local DeltaX, DeltaY, DeltaZ = TorsoPosition.X - CameraPosition.X, TorsoPosition.Y - CameraPosition.Y, TorsoPosition.Z - CameraPosition.Z
				local DeltaMagnitude = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ)
				if DeltaMagnitude < 0.001 or (LookVector.X * DeltaX + LookVector.Y * DeltaY + LookVector.Z * DeltaZ) / DeltaMagnitude < 0 then
					return
				end

				local Part, Screen, IsVisible = GetTargetPart(Character, AimbotPart, IsWallCheckOff)
				if not Part or not Screen then
					return
				end

				DeltaX, DeltaY = Screen.X - CenterX, Screen.Y - CenterY
				local Distance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
				if Distance > FOVRadius then
					return
				end

				DeltaX, DeltaY, DeltaZ = TorsoPosition.X - LocalHeadPosition.X, TorsoPosition.Y - LocalHeadPosition.Y, TorsoPosition.Z - LocalHeadPosition.Z
				local Score = Distance + math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ) * 0.15
				if Score < ClosestScore then
					ClosestScore = Score
					Target = Player
					TargetPart = Part
					IsTargetVisible = IsVisible
					TargetScreen = Screen
				end
			end

			local AimbotTargetEntry = AimbotTarget and GetPlayerEntry(AimbotTarget)
			if AimbotTargetEntry and AimbotTargetEntry._alive then
				EvaluatePlayer(AimbotTarget, AimbotTargetEntry._thirdPersonObject._characterModelHash)
			end

			if not Target then
				OperateOnAllEntries(function(Player, Entry)
					if Entry._isEnemy and Entry._alive then
						EvaluatePlayer(Player, Entry._thirdPersonObject._characterModelHash)
					end
				end)
			end

			AimbotTarget = Target
			AimbotTargetPart = TargetPart
			IsAimbotTargetVisible = IsTargetVisible
			if TargetPart then
				if Aiming.Aimbot_Type == "Mouse" and not Library.Toggled then
					local Smoothness = Aiming.Aimbot_Smoothness
					ns__mousemoverel((TargetScreen.X - ScreenCenterX) / Smoothness, (TargetScreen.Y - ScreenCenterY) / Smoothness)
				elseif Aiming.Aimbot_Type == "Camera" then
					local LookVector, Smoothness = (AimbotTargetPart.Position - Camera.CFrame.Position).Unit, Aiming.Aimbot_Smoothness
					if Smoothness > 1 then
						LookVector = (Camera.CFrame.LookVector:Lerp(LookVector, 1/Smoothness)).Unit
					end

					local ActiveCamera = GetActiveCamera()
					if ActiveCamera then
						ActiveCamera:setLookVector(LookVector)
					end
				end
				IsLocking = true
			end
		else
			AimbotTarget = nil
			AimbotTargetPart = nil
			IsAimbotTargetVisible = false
		end

		IsAimbotLocking = IsLocking
	else
		AimbotTarget = nil
		AimbotTargetPart = nil
		IsAimbotLocking = false
		SetProperty(FOVCircle, "Visible", false)
	end

	if Visuals.EnemyESP_MasterEnabled then
		local SkipFrame = false
		if Settings.Advanced_ESPFramerateCap then
			if Now - LastESPUpdateTime < 1/Settings.Advanced_ESPFPSCapValue then
				SkipFrame = true
			end
		end

		if not SkipFrame then
			LastESPUpdateTime = Now
			local GlobalOpacity = Visuals.EnemyESP_MasterOpacity * 0.01
			OperateOnAllEntries(function(Player, Entry)
				if not Entry._isEnemy or not Entry._alive then
					return ClearESP(Player)
				end
				local Character = Entry._thirdPersonObject._characterModelHash
				UpdateESP(LocalHeadPosition, Player, Entry, Character.Head, Character.Torso, {Character["Left Arm"], Character["Right Arm"]}, {
					Character["Left Leg"], Character["Right Leg"]
				}, GlobalOpacity)
			end)
		end
	else
		for Player in next, Rendering_DrawingObjects do
			ClearESP(Player)
		end
	end

	if Aiming.Aimbot_TargetTracer and IsAimbotLocking and AimbotTargetPart then
		local Barrel = GetActiveWeapon()
		Barrel = Barrel and Barrel._barrelPart
		if Barrel then
			local Screen, OnScreen = WorldToViewportPoint(Barrel.Position)
			if OnScreen then
				SetProperty(TargetTracer, "From", Screen)
			else
				SetProperty(TargetTracer, "Visible", false)
			end
		else
			SetProperty(TargetTracer, "From", ScreenCenter)
		end
		local Screen, OnScreen = WorldToViewportPoint(AimbotTargetPart.Position)
		SetProperty(TargetTracer, "To", OnScreen and Screen or ScreenCenter)
		SetProperty(TargetTracer, "Color", Aiming.Aimbot_TargetTracerColor)
		SetProperty(TargetTracer, "Visible", true)
	else
		SetProperty(TargetTracer, "Visible", false)
	end

	if Aiming.Aimbot_AutoFire and IsAimbotLocking and AimbotTarget and (Aiming.Aimbot_WallCheck and IsAimbotTargetVisible) then
		IsAutoFiring = not IsAutoFiring
		task.spawn(VirtualInputManager.SendMouseButtonEvent, VirtualInputManager, 0, 0, 0, IsAutoFiring, game, 1)
	elseif IsAutoFiring then
		IsAutoFiring = false
		task.spawn(VirtualInputManager.SendMouseButtonEvent, VirtualInputManager, 0, 0, 0, false, game, 1)
	end

	if Visuals.Combat_GrenadeTrajectory and IsSpawned then
		local ActiveWeapon = GetActiveWeapon()
		if ActiveWeapon and ActiveWeapon:getWeaponType() == "Grenade" then
			local WeaponData = ActiveWeapon._weaponData
			if WeaponData then
				local LocalPosition = GetLocalPosition()
				local Velocity = (GetLocalCFrame() * CFrame.Angles(math.rad(WeaponData.throwangle or 0), 0, 0)).LookVector * (
					WeaponData.throwspeed or 100
				) + (GetLocalCharacter():getRealRootPart() and GetLocalCharacter():getRealRootPart().AssemblyLinearVelocity or Vector3.zero)

				local TargetPosition = ActiveWeapon._mainPart
				TargetPosition = TargetPosition and TargetPosition.Position or LocalPosition
				
				local StartHit = workspace:Raycast(LocalPosition, TargetPosition - LocalPosition, GrenadeRaycastParams)
				local Position = StartHit and (StartHit.Position + StartHit.Normal * 0.01) or TargetPosition

				local Points = {Position}
				local BouncesDone = 0
				local DeltaTime = 0.05
				local MaxSteps = 120
				local ImpactPoint = nil

				local Gravity = Vector3.new(0, -80, 0)
				local MaxBounces = Visuals.Combat_GrenadeTrajectoryBounces
				for _ = 1, MaxSteps do
					local NextPosition = Position + Velocity * DeltaTime + 0.5 * Gravity * DeltaTime * DeltaTime
					local Hit = workspace:Raycast(Position, NextPosition - Position, GrenadeRaycastParams)
					if Hit then
						local HitPosition = Hit.Position
						table.insert(Points, HitPosition)

						if BouncesDone >= MaxBounces then
							ImpactPoint = HitPosition
							break
						end

						local Normal = Hit.Normal
						Position = HitPosition + Normal * 0.05
						local CurrentVelocity = (Velocity - 2 * Velocity:Dot(Normal) * Normal) * 0.2
						Velocity = CurrentVelocity - (CurrentVelocity - CurrentVelocity:Dot(Normal) * Normal) * 0.08
						BouncesDone += 1
					else
						Position = NextPosition
						Velocity = Velocity + Gravity * DeltaTime
						table.insert(Points, Position)
					end
				end

				local TrajectoryColor = Visuals.Combat_GrenadeTrajectoryColor
				local ImpactColor = Visuals.Combat_GrenadeTrajectoryImpactColor
				local Thickness = Visuals.Combat_GrenadeTrajectoryThickness
				local PointCount = #Points
				local FinalPoint = ImpactPoint or Points[#Points]
				if Visuals.Combat_GrenadeTrajectoryMode == "3D" then
					local SegmentsNeeded = math.max(0, PointCount - 1)
					while #GrenadeTrajectory3DSegments < SegmentsNeeded do
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
						table.insert(GrenadeTrajectory3DSegments, {Beam = Beam, Attachment0 = Attachment0, Attachment1 = Attachment1})
					end

					for Index = 1, #GrenadeTrajectory3DSegments do
						local Segment = GrenadeTrajectory3DSegments[Index]
						local Beam = Segment.Beam
						if Index <= SegmentsNeeded then
							Segment.Attachment0.Position = Points[Index]
							Segment.Attachment1.Position = Points[Index + 1]
							Beam.Color = ColorSequence.new(Index == SegmentsNeeded and ImpactColor or TrajectoryColor)
							Beam.Width0 = Thickness * 0.025
							Beam.Width1 = Thickness * 0.025
							Beam.Transparency = NumberSequence.new(0)
						else
							Beam.Transparency = NumberSequence.new(1)
						end
					end

					GrenadeTrajectory3DMarker.Color3 = ImpactColor
					GrenadeTrajectory3DMarker.CFrame = CFrame.new(FinalPoint)
					GrenadeTrajectory3DMarker.Visible = true

					if GrenadeTrajectory2DLines then
						for _,Line in ipairs(GrenadeTrajectory2DLines) do
							Line.Visible = false
						end
					end

					if GrenadeTrajectory2DMarker then
						GrenadeTrajectory2DMarker.Visible = false
					end
				else
					local SegmentsNeeded = math.max(0, PointCount - 1)
					while #GrenadeTrajectory2DLines < SegmentsNeeded do
						local Line = Drawing.new("Line")
						Line.Visible = false
						table.insert(GrenadeTrajectory2DLines, Line)
					end

					for Index = 1, #GrenadeTrajectory2DLines do
						local Line = GrenadeTrajectory2DLines[Index]
						if Index <= SegmentsNeeded then
							local Screen1, OnScreen1 = WorldToViewportPoint(Points[Index])
							local Screen2, OnScreen2 = WorldToViewportPoint(Points[Index + 1])
							if OnScreen1 and OnScreen2 then
								Line.From = Screen1
								Line.To = Screen2
								Line.Color = Index == SegmentsNeeded and ImpactColor or TrajectoryColor
								Line.Thickness = Thickness
								Line.Visible = true
							else
								Line.Visible = false
							end
						else
							Line.Visible = false
						end
					end

					local Screen, OnScreen = WorldToViewportPoint(FinalPoint)
					if OnScreen then
						GrenadeTrajectory2DMarker.Position = Screen
						GrenadeTrajectory2DMarker.Radius = Thickness * 1.5
						GrenadeTrajectory2DMarker.Color = ImpactColor
						GrenadeTrajectory2DMarker.Visible = true
					else
						GrenadeTrajectory2DMarker.Visible = false
					end

					if GrenadeTrajectory3DSegments then
						for _,Segment in ipairs(GrenadeTrajectory3DSegments) do
							Segment.Beam.Transparency = NumberSequence.new(1)
						end
					end

					if GrenadeTrajectory3DMarker then
						GrenadeTrajectory3DMarker.Visible = false
					end
				end
				return
			end
		end
	end

	if GrenadeTrajectory2DLines then
		for _,Line in ipairs(GrenadeTrajectory2DLines) do
			Line.Visible = false
		end
	end

	if GrenadeTrajectory3DSegments then
		for _,Segment in ipairs(GrenadeTrajectory3DSegments) do
			Segment.Beam.Transparency = NumberSequence.new(1)
		end
	end

	if GrenadeTrajectory2DMarker then
		GrenadeTrajectory2DMarker.Visible = false
	end

	if GrenadeTrajectory3DMarker then
		GrenadeTrajectory3DMarker.Visible = false
	end
end)

Library:Toggle()
