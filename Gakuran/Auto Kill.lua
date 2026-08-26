-- only kills people who are talking in VC

local RunService = game:GetService("RunService");
local Players = game:GetService("Players");
local Environment = getgenv();

local function RequireLoaded(Name, IsExpected)
    for _, Module in getloadedmodules() do
        if Module.Name ~= Name then
            continue;
        end;

        local Success, Value = pcall(require, Module);

        if Success and type(Value) == "table" and IsExpected(Value) then
            return Value;
        end;
    end;

    error("Missing loaded module: " .. Name);
end;

local AuthServiceClient = RequireLoaded("AuthServiceClient", function(Value)
    return type(Value.NextForKey) == "function";
end);

local NetworkClient = RequireLoaded("Client", function(Value)
    return type(Value.KnockedGripRequest) == "table" and type(Value.KnockedGripRequest.Fire) == "function";
end);

local KnockedServiceUtils = RequireLoaded("KnockedServiceUtils", function(Value)
    return type(Value.IsVictimAvailableForCarryGrip) == "function";
end);

local CombatM1 = RequireLoaded("M1", function(Value)
    return type(Value.Hold) == "function";
end);

local CombatM2 = RequireLoaded("M2", function(Value)
    return type(Value.OnM2Activated) == "function";
end);

local CombatEquip = RequireLoaded("Equip", function(Value)
    return type(Value.Equip) == "function";
end);

local Talked = Environment.CombatFinisherTalked or { };
Environment.CombatFinisherTalked = Talked;
local Analyzers = { };
local Hitting = false;
local TargetRoot = nil;
local GripTarget = nil;
local GripApproachAt = 0;
local GripRequestAt = 0;
local GripNeedsReplication = false;
local TargetInvalidAt = 0;
local NextM2AttemptAt = 0;
local LastEquip = 0;
local States = { "Running", "PlatformStanding", "Seated", "FallingDown", "Climbing", "Freefall", "Jumping", "Landed" };

if Environment.CombatFinisherConnection then
    Environment.CombatFinisherConnection:Disconnect();
end;

local function IsValidRoot(Root)
    if not Root or not Root.Parent then
        return false;
    end;

    local Character = Root.Parent;
    local Target = Players:GetPlayerFromCharacter(Character);
    local Humanoid = Character:FindFirstChildOfClass("Humanoid");

    if not Target or Target == Players.LocalPlayer then
        return false;
    end;

    if Character:GetAttribute("Greenzone") or Character:GetAttribute("Ragdoll") then
        return false;
    end;

    if not (Humanoid and Humanoid.Health > 0 and Humanoid.RootPart == Root) then
        return false;
    end;

    if not table.find(Talked, Target) then
        return false;
    end;

    if not table.find(States, Humanoid:GetState().Name) then
        return false;
    end;

    return true;
end;

local function IsValidGripTarget(Character)
    if not Character or not Character.Parent or not Character:FindFirstChild("Head") or Character:GetAttribute("Dead") == true then
        return false;
    end;

    local Target = Players:GetPlayerFromCharacter(Character);

    if not Target or Target == Players.LocalPlayer or not table.find(Talked, Target) then
        return false;
    end;

    local Downed = workspace:FindFirstChild("Downed");

    if not Downed then
        return false;
    end;

    for _, Entry in Downed:GetChildren() do
        if Entry:IsA("ObjectValue") and Entry.Value == Character then
            return true;
        end;
    end;

    return false;
end;

local function IsTrackedGripTarget(Character)
    if not Character or not Character.Parent or Character:GetAttribute("Dead") == true then
        return false;
    end;

    local Target = Players:GetPlayerFromCharacter(Character);
    if not Target or Target == Players.LocalPlayer or not table.find(Talked, Target) then
        return false;
    end;

    return Character:GetAttribute("Downed") == true or Character:GetAttribute("Ragdoll") == true;
end;

local function IsPotentialTransitionTarget(Character)
    if not Character or not Character.Parent or Character:GetAttribute("Dead") == true or Character:GetAttribute("Greenzone") then
        return false;
    end;

    local Target = Players:GetPlayerFromCharacter(Character);

    return Target and Target ~= Players.LocalPlayer and table.find(Talked, Target) ~= nil;
end;

local function GetActiveGrip(Character)
    local CharacterStates = Character:FindFirstChild("States");
    local Gripping = CharacterStates and CharacterStates:FindFirstChild("Gripping");

    if Gripping and Gripping:IsA("ObjectValue") then
        return Gripping.Value;
    end;

    return nil;
end;

local function GetNextRoot(MyRoot)
    local Roots = { };

    for _, Target in Players:GetPlayers() do
        if Target == Players.LocalPlayer or Target.Name == "HannahDonovan3" then
            continue;
        end;

        local Character = Target.Character;
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid");
        local Root = Humanoid and Humanoid.RootPart;

        if not IsValidRoot(Root) then
            continue;
        end;

        Roots[#Roots + 1] = Root;
    end;

    table.sort(Roots, function(A, B)
        return (A.Position - MyRoot.Position).Magnitude < (B.Position - MyRoot.Position).Magnitude;
    end);

    return Roots[1];
end;

local function GetNextGripTarget(MyRoot)
    local Downed = workspace:FindFirstChild("Downed");
    local Targets = { };

    if not Downed then
        return nil;
    end;

    for _, Entry in Downed:GetChildren() do
        local Character = Entry:IsA("ObjectValue") and Entry.Value;

        if IsValidGripTarget(Character) then
            Targets[#Targets + 1] = Character;
        end;
    end;

    table.sort(Targets, function(A, B)
        return (KnockedServiceUtils.GetInteractionPosition(A) - MyRoot.Position).Magnitude < (KnockedServiceUtils.GetInteractionPosition(B) - MyRoot.Position).Magnitude;
    end);

    return Targets[1];
end;

local function SetGripTarget(Character, MyRoot, Now)
    if GripTarget == Character then
        return;
    end;

    GripTarget = Character;
    GripApproachAt = Now;
    GripRequestAt = 0;

    local InteractionPosition = KnockedServiceUtils.GetInteractionPosition(Character);
    GripNeedsReplication = not InteractionPosition or (InteractionPosition - MyRoot.Position).Magnitude > KnockedServiceUtils.CONSTANTS.MAX_INTERACTION_DISTANCE;
end;

local function StopHitting()
    if Hitting then
        CombatM1.Hold("Stop");
    end;

    Hitting = false;
end;

Environment.CombatFinisherConnection = RunService.Heartbeat:Connect(function()
    for _, Player in Players:GetPlayers() do
        if Player == Players.LocalPlayer then
            continue;
        end;

        local Analyzer = Analyzers[Player];

        if not Analyzer then
            local Input = Player:FindFirstChildOfClass("AudioDeviceInput");

            if Input then
                Analyzer = Instance.new("AudioAnalyzer");
                Analyzer.Parent = Player;

                local Wire = Instance.new("Wire");
                Wire.SourceInstance = Input;
                Wire.TargetInstance = Analyzer;
                Wire.Parent = Analyzer;

                Analyzers[Player] = Analyzer;
            end;
        end;

        if Analyzer and Analyzer.RmsLevel > 0.01 and not table.find(Talked, Player) then
            Talked[#Talked + 1] = Player;
        end;
    end;

    local Camera = workspace.CurrentCamera;
    local Character = Players.LocalPlayer.Character;
    local MyHumanoid = Character and Character:FindFirstChildOfClass("Humanoid");
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart");
    local Now = os.clock();

    if not (Character and MyHumanoid and MyRoot and MyHumanoid.Health > 0) then
        TargetRoot = nil;
        GripTarget = nil;
        Hitting = false;

        return;
    end;

    local ActiveGrip = GetActiveGrip(Character);

    if ActiveGrip then
        SetGripTarget(ActiveGrip, MyRoot, Now);
        GripNeedsReplication = false;
        TargetInvalidAt = 0;
    elseif GripTarget and not IsTrackedGripTarget(GripTarget) then
        GripTarget = nil;
    end;

    if not GripTarget and TargetRoot then
        local CurrentTarget = TargetRoot.Parent;

        if IsTrackedGripTarget(CurrentTarget) then
            SetGripTarget(CurrentTarget, MyRoot, Now);
            TargetInvalidAt = 0;
        end;
    end;

    if not GripTarget and TargetRoot and not IsValidRoot(TargetRoot) then
        local CurrentTarget = TargetRoot.Parent;

        if IsPotentialTransitionTarget(CurrentTarget) then
            if TargetInvalidAt == 0 then
                TargetInvalidAt = Now;
            end;

            if Now - TargetInvalidAt < 0.75 then
                StopHitting();

                local TransitionHumanoid = CurrentTarget:FindFirstChildOfClass("Humanoid");

                if Camera and TransitionHumanoid and Camera.CameraSubject ~= TransitionHumanoid then
                    Camera.CameraSubject = TransitionHumanoid;
                end;

                sethiddenproperty(MyRoot, "PhysicsRepRootPart", TargetRoot);
                MyRoot.CFrame = TargetRoot.CFrame * CFrame.new(0, 0, 3);

                return;
            end;
        end;
    elseif TargetRoot then
        TargetInvalidAt = 0;
    end;

    if not GripTarget then
        local NextGripTarget = GetNextGripTarget(MyRoot);

        if NextGripTarget then
            SetGripTarget(NextGripTarget, MyRoot, Now);
        end;
    end;

    if GripTarget then
        StopHitting();

        local GripHumanoid = GripTarget:FindFirstChildOfClass("Humanoid");
        local GripRoot = GripTarget:FindFirstChild("HumanoidRootPart");

        if Camera and GripHumanoid and Camera.CameraSubject ~= GripHumanoid then
            Camera.CameraSubject = GripHumanoid;
        end;

        if ActiveGrip == GripTarget then
            return;
        end;

        if not GripRoot then
            GripTarget = nil;
            return;
        end;

        sethiddenproperty(MyRoot, "PhysicsRepRootPart", GripRoot);

        local GripPosition = GripRoot.Position;
        MyRoot.CFrame = CFrame.lookAt(GripPosition + Vector3.new(0, 0, 3), GripPosition);

        local InteractionPosition = KnockedServiceUtils.GetInteractionPosition(GripTarget);

        if not InteractionPosition or (InteractionPosition - MyRoot.Position).Magnitude > KnockedServiceUtils.CONSTANTS.MAX_INTERACTION_DISTANCE then
            return;
        end;

        if not IsValidGripTarget(GripTarget) then
            return;
        end;

        local GripRetryDelay = (KnockedServiceUtils.CONSTANTS.GRIP_VICTIM_HIT_DELAY or 2.05) + 0.75;

        if GripNeedsReplication and Now - GripApproachAt < 0.15 then
            return;
        end;

        GripNeedsReplication = false;

        if Now - GripRequestAt < GripRetryDelay then
            return;
        end;

        local Token, Check, Nonce = AuthServiceClient:NextForKey("Knocked.Grip");
        GripRequestAt = Now;

        if Nonce == 0 then
            return;
        end;

        NetworkClient.KnockedGripRequest.Fire({
            Victim = GripTarget,
            Token = Token,
            Check = Check,
            Nonce = Nonce
        });

        return;
    end;

    if TargetRoot and not IsValidRoot(TargetRoot) then
        TargetRoot = nil;
        TargetInvalidAt = 0;
    end;

    TargetRoot = TargetRoot or GetNextRoot(MyRoot);

    if not TargetRoot then
        if Camera and Camera.CameraSubject ~= MyHumanoid then
            Camera.CameraSubject = MyHumanoid;
        end;

        StopHitting();

        return;
    end;

    local TargetCharacter = TargetRoot.Parent;
    local TargetHumanoid = TargetCharacter and TargetCharacter:FindFirstChildOfClass("Humanoid");

    if not TargetHumanoid then
        TargetRoot = nil;
        return;
    end;

    if Camera and Camera.CameraSubject ~= TargetHumanoid then
        Camera.CameraSubject = TargetHumanoid;
    end;

    sethiddenproperty(MyRoot, "PhysicsRepRootPart", TargetRoot);

    MyRoot.CFrame = TargetRoot.CFrame * CFrame.new(0, 0, 3);

    if Character:GetAttribute("Equip") ~= true then
        StopHitting();

        if Now - LastEquip >= 1 then
            LastEquip = Now;
            CombatEquip.Equip();
        end;

        return;
    end;

    if Character:GetAttribute("M2") or Character:GetAttribute("PendingM2") then
        StopHitting();
        return;
    end;

    if Character:GetAttribute("CombatAttacking") then
        return;
    end;

    if not Hitting then
        Hitting = true;
        CombatM1.Hold("Start");

        return;
    end;

    if Character:GetAttribute("M2Cooldown") ~= true and Now >= NextM2AttemptAt then
        StopHitting();
        NextM2AttemptAt = Now + 1;
        CombatM2.OnM2Activated();

        return;
    end;
end);
