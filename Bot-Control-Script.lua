-- Created by Sang#2180

if not game:IsLoaded() then game.Loaded:Wait() end




local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local NetworkClient = game:GetService("NetworkClient")
local GuiService = game:GetService("GuiService")
NetworkClient:SetOutgoingKBPSLimit(math.huge)

local connections = {}
local LimbType
local CurrentLimbCFrame

local LocalPlayer = Players.LocalPlayer
local Bosses= {"sangfoolery", "familyguyloverfan123", "SangWriter"} -- main account username

local Boss;

for i,v in pairs(Bosses) do 
    if LocalPlayer.Name == v then
        warn("on main")
        return 
    end
    if Players:FindFirstChild(v) then
        Boss = Players:FindFirstChild(v) 
        break
    end
end




local Character = LocalPlayer.Character


local ProxyPart = Instance.new("Part")
ProxyPart.CanCollide = false
ProxyPart.Parent = workspace
ProxyPart.Anchored = true

local WebSocket = (syn and syn.websocket or WebSocket).connect("ws://localhost:42069")

local BotLimbSelection = {
    SELECTED = false,
    ["Left Leg"] = false,
    ["Left Arm"] = false,
    ["Right Arm"] = false,
    ["Right Leg"] = false,
    ["Torso"] = false,
}

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

local function Align(Part0,Part1,Position,Angle, Connections)
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

local function DisableAllRendering()
    --settings()["Task Scheduler"].ThreadPoolConfig = Enum.ThreadPoolConfig.Threads1
    game.StarterGui:ClearAllChildren()
    game.Lighting:ClearAllChildren()

    RunService:Set3dRenderingEnabled(false)
    --RunService:setThrottleFramerateEnabled(true)

    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9

    settings().Rendering.QualityLevel = 1
    for i,v in pairs(game:GetDescendants()) do
        if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
            v.Material = "Plastic"
            v.Reflectance = 0
        elseif v:IsA("Decal") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        end
    end
end

pcall(function() -- fuck this bruh
    if Character:WaitForChild("Animate") then
        Character.Animate:Destroy()
    end
    if Character.Humanoid:WaitForChild("Animator") then
        Character.Humanoid.Animator:Destroy()
    end
end)



for i,v in next, game.Players.LocalPlayer.Character:GetDescendants() do
    if v:IsA("Part") then
        table.insert(connections, RunService.Stepped:Connect(function()
            v.CanCollide = false
        end))
    end
end

LocalPlayer.Character.Humanoid.Died:Connect(function()
    local HRP = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    Align(HRP, ProxyPart)
end)

LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
    LocalPlayer.Character.Humanoid.Sit = false
end)

Align(LocalPlayer.Character:WaitForChild("HumanoidRootPart"), ProxyPart)
table.insert(connections, RunService.Stepped:Connect(function()
    ProxyPart.CFrame = CurrentLimbCFrame or CFrame.new()
end))



local function SerializeCFrame(str)
    return CFrame.new(table.unpack(str:gsub(" ",""):split(",")))
end

Boss.Chatted:Connect(function(Message)
    game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(Message, "All")
end)

local function PingWebSocket()
    while true do
        SendToMaster({
            ["Operation"] = "Ping",
            ["Arguments"] = {
                ["UserId"] = LocalPlayer.UserId, -- we keep a map of userids to cookies on the (websocket) serverside
            }
        })
        wait(1)
    end
end



local LimbsNames = {
    [1] = "Left Arm",
    [2] = "Right Arm",
    [3] = "Left Leg",
    [4] = "Right Leg",
    [5] = "Torso",
    [6] = "Head"
}

SendToMaster({
    ["Operation"] = "GetSlots",
    ["Arguments"] = {
        ["UserId"] = LocalPlayer.UserId
    }
})


local Possibilites = {
    ["Slots"] = function(TargettedLimb)

        warn("Selected limb: ".. LimbsNames[TargettedLimb])
        LimbType = TargettedLimb
        BotLimbSelection.SELECTED = true

    end,
    ["MovementData"] = function(Response)
        if (not Response) or (not LimbType) then 
            print("no limb or response is nil")
            return
        end
        warn(LimbType)

        local Data = Response[LimbType][1]


        warn(LimbType, type(Data))

        if BotLimbSelection.SELECTED then
            CurrentLimbCFrame = SerializeCFrame(Data)
        end
    end,
}

WebSocket.OnMessage:Connect(function(Response)
    local Response = HttpService:JSONDecode(Response)
    local TypeOfMessage = table.remove(Response, 1)
    Possibilites[TypeOfMessage](unpack(Response))
end)

GuiService.ErrorMessageChanged:Connect(function()
    SendToMaster({
        ["Operation"] = "BotBanned",
        ["Arguments"] = {
            ["UserId"] = LocalPlayer.UserId
        }
    })
    task.wait();
end)


coroutine.wrap(PingWebSocket)()
DisableAllRendering()

-- Created by Sang#2180
