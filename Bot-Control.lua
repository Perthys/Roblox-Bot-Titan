-- Created by Sang#2180

function Align(Part0,Part1,Position,Angle)
    local RunService = game:GetService("RunService")
	local AlignPos = Instance.new("AlignPosition", Part1)
	AlignPos.ApplyAtCenterOfMass = false
	AlignPos.MaxForce = 9e9*9e9
	AlignPos.MaxVelocity = 9e99*9e9
	AlignPos.ReactionForceEnabled = false
	AlignPos.Responsiveness = 9e99*9e9
	AlignPos.RigidityEnabled = false
	local AlignOri = Instance.new("AlignOrientation", Part1)
	AlignOri.MaxAngularVelocity = 9e99*9e9
	AlignOri.MaxTorque = 9e99*9e9
	AlignOri.PrimaryAxisOnly = false
	AlignOri.ReactionTorqueEnabled = false
	AlignOri.Responsiveness = 300
	AlignOri.RigidityEnabled = false
	local AttachmentA = Instance.new("Attachment", Part1)
	local AttachmentB = Instance.new("Attachment", Part0)
	AttachmentA.Orientation = Angle or Vector3.new(0,0,0)
	AttachmentA.Position = Position or Vector3.new(0,0,0)
	AlignPos.Attachment1 = AttachmentA
	AlignPos.Attachment0 = AttachmentB
	AlignOri.Attachment1 = AttachmentA
	AlignOri.Attachment0 = AttachmentB
end

local Connections = {}

local WebSocket = (syn and syn.websocket or WebSocket).connect("ws://localhost:42069")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ProxyPart = Instance.new("Part")
ProxyPart.Parent = workspace
ProxyPart.Anchored = true
ProxyPart.CanCollide = false

local Character = LocalPlayer.Character
Character.Archivable = true

local AnimateClone = Character.Animate:Clone()
Character.Animate:Destroy()
Character.Humanoid.Animator:Destroy()

local ReanimateRig = game:GetObjects("rbxassetid://9260652106")[1]

local ReanimHumanoidRootPart = ReanimateRig.HumanoidRootPart
ReanimHumanoidRootPart.Position = Character.HumanoidRootPart.Position

ReanimHumanoidRootPart.Transparency = 0
ReanimateRig.Humanoid.WalkSpeed = 16

ReanimateRig.Parent = Character

local function JsonDecode(Serialized)
    return HttpService:JSONDecode(Serialized)
end

local function JsonEncode(Serialized)
    return HttpService:JSONEncode(Serialized)
end

local function SendToMaster(Payload)
    Payload = JsonEncode(Payload)
    WebSocket:Send(Payload)
end

local function ClearConnections()
    for _, Connection in pairs(Connections) do
        Connection:Disconnect()
    end
end

for _, Instance in pairs(ReanimateRig:GetDescendants()) do 
	if Instance:IsA("BasePart") then
		Instance.Transparency = 1
	end
end


local function NoCollision(Target)
	for _, Instance in pairs(Target:GetDescendants()) do 
		if Instance:IsA("BasePart") or pcall(function() return Instance.CanCollide end) then
			table.insert(Connections, RunService.Stepped:Connect(function()
				Instance.CanCollide = false
			end))
			table.insert(Connections, RunService.Stepped:Connect(function()
				Instance.CanCollide = false
			end))
			table.insert(Connections, RunService.Stepped:Connect(function()
				Instance.CanCollide = false
			end))
		end
	end
end


local function HandlePlayerCollisions(Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	wait(3)
	NoCollision(Character)
	table.insert(Connections, Player.CharacterAdded:Connect(NoCollision))
end

for _, Player in pairs(Players:GetPlayers()) do
	spawn(function()
		HandlePlayerCollisions(Player)
	end)
end

table.insert(Connections, Players.PlayerAdded:Connect(HandlePlayerCollisions))

LocalPlayer.Character = ReanimateRig
workspace.Camera.CameraSubject = ReanimateRig.Humanoid

SendToMaster({
    ["Operation"] = "Initialize",
    ["Arguments"] = {
        ["MasterPlaceId"] = game.PlaceId,
        ["MasterJobId"] = game.JobId,
    }
})

table.insert(Connections, RunService.Stepped:Connect(function()
    local LimbData = {
        {tostring(ReanimateRig["Left Arm"].CFrame)},
        {tostring(ReanimateRig["Right Arm"].CFrame)},
        {tostring(ReanimateRig["Left Leg"].CFrame)},
        {tostring(ReanimateRig["Right Leg"].CFrame)},
        {tostring(ReanimateRig["Torso"].CFrame)},
		    {tostring(ReanimateRig["Head"].CFrame)}
    }
    SendToMaster({
        ["Operation"] = "BroadcastCFrames",
        ["Arguments"] = {["LimbData"] = LimbData}
    })
	--ProxyPart.CFrame = ReanimateRig["Head"].CFrame
end))

--wait(5)
--Align(Character.HumanoidRootPart, ProxyPart)

ReanimateRig.Humanoid.Died:Once(function()
    LocalPlayer.Character = Character
    Character:BreakJoints()
    ClearConnections()
end)

-- Created by Sang#2180

function R6Animate(FOLDER)

local Figure = FOLDER.Parent
local Torso = Figure:WaitForChild("Torso")
local RightShoulder = Torso:WaitForChild("Right Shoulder")
local LeftShoulder = Torso:WaitForChild("Left Shoulder")
local RightHip = Torso:WaitForChild("Right Hip")
local LeftHip = Torso:WaitForChild("Left Hip")
local Neck = Torso:WaitForChild("Neck")
local Humanoid = Figure:WaitForChild("Humanoid")
local pose = "Standing"

local currentAnim = ""
local currentAnimInstance = nil
local currentAnimTrack = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0
local animTable = {}
local animNames = { 
	idle = 	{	
				{ id = "http://www.roblox.com/asset/?id=180435571", weight = 9 },
				{ id = "http://www.roblox.com/asset/?id=180435792", weight = 1 }
			},
	walk = 	{ 	
				{ id = "http://www.roblox.com/asset/?id=180426354", weight = 10 } 
			}, 
	run = 	{
				{ id = "run.xml", weight = 10 } 
			}, 
	jump = 	{
				{ id = "http://www.roblox.com/asset/?id=125750702", weight = 10 } 
			}, 
	fall = 	{
				{ id = "http://www.roblox.com/asset/?id=180436148", weight = 10 } 
			}, 
	climb = {
				{ id = "http://www.roblox.com/asset/?id=180436334", weight = 10 } 
			}, 
	sit = 	{
				{ id = "http://www.roblox.com/asset/?id=178130996", weight = 10 } 
			},	
	toolnone = {
				{ id = "http://www.roblox.com/asset/?id=182393478", weight = 10 } 
			},
	toolslash = {
				{ id = "http://www.roblox.com/asset/?id=129967390", weight = 10 } 
--				{ id = "slash.xml", weight = 10 } 
			},
	toollunge = {
				{ id = "http://www.roblox.com/asset/?id=129967478", weight = 10 } 
			},
	wave = {
				{ id = "http://www.roblox.com/asset/?id=128777973", weight = 10 } 
			},
	point = {
				{ id = "http://www.roblox.com/asset/?id=128853357", weight = 10 } 
			},
	dance1 = {
				{ id = "http://www.roblox.com/asset/?id=182435998", weight = 10 }, 
				{ id = "http://www.roblox.com/asset/?id=182491037", weight = 10 }, 
				{ id = "http://www.roblox.com/asset/?id=182491065", weight = 10 } 
			},
	dance2 = {
				{ id = "http://www.roblox.com/asset/?id=182436842", weight = 10 }, 
				{ id = "http://www.roblox.com/asset/?id=182491248", weight = 10 }, 
				{ id = "http://www.roblox.com/asset/?id=182491277", weight = 10 } 
			},
	dance3 = {
				{ id = "http://www.roblox.com/asset/?id=182436935", weight = 10 }, 
				{ id = "http://www.roblox.com/asset/?id=182491368", weight = 10 }, 
				{ id = "http://www.roblox.com/asset/?id=182491423", weight = 10 } 
			},
	laugh = {
				{ id = "http://www.roblox.com/asset/?id=129423131", weight = 10 } 
			},
	cheer = {
				{ id = "http://www.roblox.com/asset/?id=129423030", weight = 10 } 
			},
}
local dances = {"dance1", "dance2", "dance3"}

-- Existance in this list signifies that it is an emote, the value indicates if it is a looping emote
local emoteNames = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

function configureAnimationSet(name, fileList)
	if (animTable[name] ~= nil) then
		for _, connection in pairs(animTable[name].connections) do
			connection:disconnect()
		end
	end
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0	
	animTable[name].connections = {}

	-- check for config values
	local config = FOLDER:FindFirstChild(name)
	if (config ~= nil) then
--		print("Loading anims " .. name)
		table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
		local idx = 1
		for _, childPart in pairs(config:GetChildren()) do
			if (childPart:IsA("Animation")) then
				table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
				animTable[name][idx] = {}
				animTable[name][idx].anim = childPart
				local weightObject = childPart:FindFirstChild("Weight")
				if (weightObject == nil) then
					animTable[name][idx].weight = 1
				else
					animTable[name][idx].weight = weightObject.Value
				end
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
	--			print(name .. " [" .. idx .. "] " .. animTable[name][idx].anim.AnimationId .. " (" .. animTable[name][idx].weight .. ")")
				idx = idx + 1
			end
		end
	end

	-- fallback to defaults
	if (animTable[name].count <= 0) then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {}
			animTable[name][idx].anim = Instance.new("Animation")
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name][idx].weight = anim.weight
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
--			print(name .. " [" .. idx .. "] " .. anim.id .. " (" .. anim.weight .. ")")
		end
	end
end

-- Setup animation objects
function scriptChildModified(child)
	local fileList = animNames[child.Name]
	if (fileList ~= nil) then
		configureAnimationSet(child.Name, fileList)
	end	
end

FOLDER.ChildAdded:connect(scriptChildModified)
FOLDER.ChildRemoved:connect(scriptChildModified)


for name, fileList in pairs(animNames) do 
	configureAnimationSet(name, fileList)
end	

-- ANIMATION

-- declarations
local toolAnim = "None"
local toolAnimTime = 0

local jumpAnimTime = 0
local jumpAnimDuration = 0.3

local toolTransitionTime = 0.1
local fallTransitionTime = 0.3
local jumpMaxLimbVelocity = 0.75

-- functions

function stopAllAnimations()
	local oldAnim = currentAnim

	-- return to idle if finishing an emote
	if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
		oldAnim = "idle"
	end

	currentAnim = ""
	currentAnimInstance = nil
	if (currentAnimKeyframeHandler ~= nil) then
		currentAnimKeyframeHandler:disconnect()
	end

	if (currentAnimTrack ~= nil) then
		currentAnimTrack:Stop()
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end
	return oldAnim
end

function setAnimationSpeed(speed)
	if speed ~= currentAnimSpeed then
		currentAnimSpeed = speed
		currentAnimTrack:AdjustSpeed(currentAnimSpeed)
	end
end

function keyFrameReachedFunc(frameName)
	if (frameName == "End") then

		local repeatAnim = currentAnim
		-- return to idle if finishing an emote
		if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
			repeatAnim = "idle"
		end
		
		local animSpeed = currentAnimSpeed
		playAnimation(repeatAnim, 0.0, Humanoid)
		setAnimationSpeed(animSpeed)
	end
end

-- Preload animations
function playAnimation(animName, transitionTime, humanoid) 
		
	local roll = math.random(1, animTable[animName].totalWeight) 
	local origRoll = roll
	local idx = 1
	while (roll > animTable[animName][idx].weight) do
		roll = roll - animTable[animName][idx].weight
		idx = idx + 1
	end
--		print(animName .. " " .. idx .. " [" .. origRoll .. "]")
	local anim = animTable[animName][idx].anim

	-- switch animation		
	if (anim ~= currentAnimInstance) then
		
		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop(transitionTime)
			currentAnimTrack:Destroy()
		end

		currentAnimSpeed = 1.0
	
		-- load it to the humanoid; get AnimationTrack
		currentAnimTrack = humanoid:LoadAnimation(anim)
		currentAnimTrack.Priority = Enum.AnimationPriority.Core
			
		-- play the animation
		currentAnimTrack:Play(transitionTime)
		currentAnim = animName
		currentAnimInstance = anim

		-- set up keyframe name triggers
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end
		currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
		
	end

end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local toolAnimName = ""
local toolAnimTrack = nil
local toolAnimInstance = nil
local currentToolAnimKeyframeHandler = nil

function toolKeyFrameReachedFunc(frameName)
	if (frameName == "End") then
--		print("Keyframe : ".. frameName)	
		playToolAnimation(toolAnimName, 0.0, Humanoid)
	end
end


function playToolAnimation(animName, transitionTime, humanoid, priority)	 
		
		local roll = math.random(1, animTable[animName].totalWeight) 
		local origRoll = roll
		local idx = 1
		while (roll > animTable[animName][idx].weight) do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
--		print(animName .. " * " .. idx .. " [" .. origRoll .. "]")
		local anim = animTable[animName][idx].anim

		if (toolAnimInstance ~= anim) then
			
			if (toolAnimTrack ~= nil) then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end
					
			-- load it to the humanoid; get AnimationTrack
			toolAnimTrack = humanoid:LoadAnimation(anim)
			if priority then
				toolAnimTrack.Priority = priority
			end
				
			-- play the animation
			toolAnimTrack:Play(transitionTime)
			toolAnimName = animName
			toolAnimInstance = anim

			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
		end
end
-- Created by Sang#2180

function stopToolAnimations()
	local oldAnim = toolAnimName

	if (currentToolAnimKeyframeHandler ~= nil) then
		currentToolAnimKeyframeHandler:disconnect()
	end

	toolAnimName = ""
	toolAnimInstance = nil
	if (toolAnimTrack ~= nil) then
		toolAnimTrack:Stop()
		toolAnimTrack:Destroy()
		toolAnimTrack = nil
	end


	return oldAnim
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------


function onRunning(speed)
	if speed > 0.01 then
		playAnimation("walk", 0.1, Humanoid)
		if currentAnimInstance and currentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
			setAnimationSpeed(speed / 14.5)
		end
		pose = "Running"
	else
		if emoteNames[currentAnim] == nil then
			playAnimation("idle", 0.1, Humanoid)
			pose = "Standing"
		end
	end
end

function onDied()
	pose = "Dead"
end

function onJumping()
	playAnimation("jump", 0.1, Humanoid)
	jumpAnimTime = jumpAnimDuration
	pose = "Jumping"
end

function onClimbing(speed)
	playAnimation("climb", 0.1, Humanoid)
	setAnimationSpeed(speed / 12.0)
	pose = "Climbing"
end

function onGettingUp()
	pose = "GettingUp"
end

function onFreeFall()
	if (jumpAnimTime <= 0) then
		playAnimation("fall", fallTransitionTime, Humanoid)
	end
	pose = "FreeFall"
end

function onFallingDown()
	pose = "FallingDown"
end

function onSeated()
	pose = "Seated"
end

function onPlatformStanding()
	pose = "PlatformStanding"
end

function onSwimming(speed)
	if speed > 0 then
		pose = "Running"
	else
		pose = "Standing"
	end
end

function getTool()	
	for _, kid in ipairs(Figure:GetChildren()) do
		if kid.className == "Tool" then return kid end
	end
	return nil
end

function getToolAnim(tool)
	for _, c in ipairs(tool:GetChildren()) do
		if c.Name == "toolanim" and c.className == "StringValue" then
			return c
		end
	end
	return nil
end

function animateTool()
	
	if (toolAnim == "None") then
		playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
		return
	end

	if (toolAnim == "Slash") then
		playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
		return
	end

	if (toolAnim == "Lunge") then
		playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
		return
	end
end

function moveSit()
	RightShoulder.MaxVelocity = 0.15
	LeftShoulder.MaxVelocity = 0.15
	RightShoulder:SetDesiredAngle(3.14 /2)
	LeftShoulder:SetDesiredAngle(-3.14 /2)
	RightHip:SetDesiredAngle(3.14 /2)
	LeftHip:SetDesiredAngle(-3.14 /2)
end

local lastTick = 0

function move(time)
	local amplitude = 1
	local frequency = 1
--	time = 0
		local deltaTime = time - lastTick
		lastTick = time

	local climbFudge = 0
	local setAngles = false

		if (jumpAnimTime > 0) then
			jumpAnimTime = jumpAnimTime - deltaTime
		end

	if (pose == "FreeFall" and jumpAnimTime <= 0) then
		playAnimation("fall", fallTransitionTime, Humanoid)
	elseif (pose == "Seated") then
		playAnimation("sit", 0.5, Humanoid)
		return
	elseif (pose == "Running") then
		playAnimation("walk", 0.1, Humanoid)
	elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
--		print("Wha " .. pose)
		stopAllAnimations()
		amplitude = 0.1
		frequency = 1
		setAngles = true
	end

	if (setAngles) then
		local desiredAngle = amplitude * math.sin(time * frequency)

		RightShoulder:SetDesiredAngle(desiredAngle + climbFudge)
		LeftShoulder:SetDesiredAngle(desiredAngle - climbFudge)
		RightHip:SetDesiredAngle(-desiredAngle)
		LeftHip:SetDesiredAngle(-desiredAngle)
	end

	-- Tool Animation handling
	local tool = getTool()
	if tool and tool:FindFirstChild("Handle") then
	
		local animStringValueObject = getToolAnim(tool)

		if animStringValueObject then
			toolAnim = animStringValueObject.Value
			-- message recieved, delete StringValue
			animStringValueObject.Parent = nil
			toolAnimTime = time + .3
		end

		if time > toolAnimTime then
			toolAnimTime = 0
			toolAnim = "None"
		end

		animateTool()		
	else
		stopToolAnimations()
		toolAnim = "None"
		toolAnimInstance = nil
		toolAnimTime = 0
	end
end


local events = {}
local eventHum = Humanoid

local function onUnhook()
	for i = 1, #events do
		events[i]:Disconnect()
	end
	events = {}
end

local function onHook()
	onUnhook()
	
	pose = eventHum.Sit and "Seated" or "Standing"
	
	events = {
		eventHum.Died:connect(onDied),
		eventHum.Running:connect(onRunning),
		eventHum.Jumping:connect(onJumping),
		eventHum.Climbing:connect(onClimbing),
		eventHum.GettingUp:connect(onGettingUp),
		eventHum.FreeFalling:connect(onFreeFall),
		eventHum.FallingDown:connect(onFallingDown),
		eventHum.Seated:connect(onSeated),
		eventHum.PlatformStanding:connect(onPlatformStanding),
		eventHum.Swimming:connect(onSwimming)
	}
end


onHook()
--FOLDER:WaitForChild("Loaded").Value = true


-- main program

-- initialize to idle
playAnimation("idle", 0.1, Humanoid)
pose = "Standing"

spawn(function()
	while Figure.Parent ~= nil do
		local _, time = wait(0.1)
		move(time)
	end
end)

return {
	onRunning = onRunning, 
	onDied = onDied, 
	onJumping = onJumping, 
	onClimbing = onClimbing, 
	onGettingUp = onGettingUp, 
	onFreeFall = onFreeFall, 
	onFallingDown = onFallingDown, 
	onSeated = onSeated, 
	onPlatformStanding = onPlatformStanding,
	onHook = onHook,
	onUnhook = onUnhook
}

end

-- Created by Sang#2180

R6Animate(ReanimateRig.Animate)
