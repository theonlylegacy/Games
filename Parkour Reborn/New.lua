-- Might be broken now, this is older

run_on_thread(getactorthreads()[1], [=[
local players = game:GetService("Players")
local user_input_service = game:GetService("UserInputService")
local run_service = game:GetService("RunService")
local replicated_storage = game:GetService("ReplicatedStorage")
local replicated_first = game:GetService("ReplicatedFirst")
local insert_service = game:GetService("InsertService")

local gui = loadstring(http.request({
    Url = "https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua",
    Method = "GET",
}).Body)()

local registry = {}
local core = {}
local utility = require(replicated_first.Modules.Utility)
local humanoid = require(replicated_first.Modules.Humanoid)
local shortcut = require(replicated_first.Modules.Core.Shortcut)

local modules = getrenv().shared.modules
local animation = modules.animation
local gamemode = modules.gamemode
local movement = modules.movement
local browser = modules.browser
local compass = modules.compass
local raycast = modules.raycast
local network = modules.network
local engine = modules.engine
local camera = modules.camera
local actor = modules.actor
local input = modules.input
local sound = modules.sound
local logic = modules.logic
local score = modules.score
local gear = modules.gear
local data = modules.data
local ui = modules.ui

local raycast_ignore = workspace.RaycastIgnore

core.run_function_on_identity = function(identity, callback)
    local old_identity = get_thread_identity()

    set_thread_identity(identity)
    callback()
    set_thread_identity(old_identity)
end

core.find_player = function(name)
    for _, player in players:GetPlayers() do
        local character = player.Character

        if not (character and string.lower(player.Name) == string.lower(name)) then
            continue
        end

        return character
    end
end

core.collect_item = function(character, item)
    local proximity = item:FindFirstChild("ProximityPrompt", true)
    local item_id = proximity and proximity:FindFirstChild("SpawnName").Value

    if not item_id then
        return
    end

	character:PivotTo(item:GetPivot())
    
    task.delay(0.5, function()
        network:get("collectItem", item_id)
    end)
end

core.find_item = function(name)
    for _, item in raycast_ignore:GetChildren() do
        local proximity = item:FindFirstChild("ProximityPrompt", true)

        if not (proximity and string.lower(proximity.ObjectText) == string.lower(name)) then
            continue
        end

        return item
    end
end

local old = browser.navigate
browser.navigate = function(...)
    if ({...})[1] == "exodus.com" then
        core.run_function_on_identity(8, function()
            local window = gui.Windows[1]
            browser.contentFrame:ClearAllChildren()

            window.WindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            window.WindowFrame.Position = UDim2.fromScale(0.5, 0.5)
            window.WindowFrame.Parent = browser.contentFrame
            window.WindowFrame.Visible = true
        end)

        return
    else
        core.run_function_on_identity(8, function()
            local window = gui.Windows[1]

            window.WindowFrame.Visible = false
            window.WindowFrame.Parent = nil
        end)
    end

    return old(...)
end

local old = data.hasAbility
data.hasAbility = function(...)
    if registry["unlock abilities"] then
        return true
    end

    return old(...)
end

local old = movement.wallJump
movement.wallJump = function(self, ...)
    if typeof(({...})[1]) == "table" then
        local jump_data = ({...})[1]

        if jump_data.jumpType == "boost" then
            movement:endWallrun()
            movement.events.wallJump:Fire()
            sound:PlayStep("jump")
            actor.lastLandedTick = 0
            actor.humanoid:SetState("Falling")
            movement.parkour.dash.lastAirUse = tick() - 0.75

            local range = utility.convertToRange(jump_data.overrideWalkSpeed or actor.speed, actor.baseSpeed, actor.maxSpeed, 0, 1)
            local multiplier = 0

            if gear:hasUpgrade("Core", "Glove", 1, 1) then
                multiplier = 18 + (registry["wallboost increment"]) + 6 * range
            else
                multiplier = 11 + (registry["wallboost increment"]) + 6 * range
            end

            local humanoid = actor.humanoid
            local gravity = math.sqrt(2 * actor.defaultGravity * multiplier)

            humanoid:SetVelocity(Vector3.yAxis * gravity)
            animation.wallboost:Play()
            movement("wallboost")
            data.stats:increment("WallBoosts", 1)
            task.spawn(logic.retryAutoParkour)

            return
        end
    end

    return old(self, ...)
end

local old = movement.jump
movement.jump = function(self, ...) -- yes, I used AI for the naming
    actor:SwapJumpPhase()

    local jump_phase = ({...})[1] or actor.jumpPhase
    if jump_phase == "doublejump" and (actor.ammo.doubleJump > 0 and (actor.velocity.Y < movement.doubleJumpStrength and not actor.frozen)) then
        local is_compound_advanced = gear.equipped.Compound.level >= 2
        local velocity = Vector3.zero

        if gear:hasUpgrade("Compound", "BoostBelt", 2) then
            local vertical_boost = 10 * (is_compound_advanced and 1.5 or 1)
            local dash_strength = movement.double_jump_dash_strength * (is_compound_advanced and 1.25 or 1)
            local dash_direction = shortcut.unit(shortcut.use_non_zero_v3(actor.input_vector, shortcut.v3flat(actor.velocity), shortcut.v3flat(actor.rootlook))) * dash_strength
            local current_speed = shortcut.v3flat(actor.velocity).magnitude
            local horizontal_velocity = dash_direction.unit * math.max(dash_direction.magnitude, current_speed)
            local vertical_velocity = actor.velocity.Y + vertical_boost * 3

            velocity = Vector3.new(horizontal_velocity.X, math.min(vertical_boost, vertical_velocity), horizontal_velocity.Z)
        else
            local jump_strength = movement.double_jump_strength * (is_compound_advanced and 1.5 or 1)
            local jump_velocity = actor.velocity.Y + jump_strength * 1

            velocity = Vector3.new(actor.velocity.X, math.min(jump_strength, jump_velocity), actor.velocity.Z)
        end

        actor.velocity = velocity
        actor.humanoid:SetVelocity(velocity)
        actor.ammo.doubleJump -= 1
    end

    if actor.character and (actor.humanoid and (actor.rootpart and (actor.alive and (gamemode.races.state ~= "countdown" and jump_phase ~= "doublejump")))) then
        actor.onground(true)
        actor.humanoid:SetState("Jumping")
        actor.physics.Grounded = false
        movement.events.jump:Fire()
        actor.air = true
        actor.ground = false
        actor.landed = false
        actor.jumping = tick()
        actor.ammo.jump = false

        local is_sliding = actor.sliding
        local horizontal_multiplier = 1
        local vertical_boost = 0
        local raycast_result = registry["longjump anywhere"] and {hit = false} or raycast(Ray.new(actor.rootpart.Position + actor.rootlook * 2, Vector3.new(0, -4, 0)))

        animation.roll:Stop()
        animation.slideRoll:Stop()

        if actor.sitting then
            actor.sitting = false
            animation.sit_in:SafeStop()
            animation.sit_out:SafeStop()
            animation.sit_loop:SafeStop()
        end

        local dash = movement.parkour.dash
        local boost_factor = dash.afterboosted and (registry["increase longjump strength"] and 5 or 1) or 0.65
        local dash_ready = dash.active or (dash.holdForLanding or tick() - dash.lastRelease < 0.2)
        local airborne_or_dropdown = not raycast_result.hit or (actor.velocity.Y > 8 and true or movement.parkour.dropdown.active)

        if is_sliding then
            actor.lastSlideJump = tick()
        end

        camera.jumpTilt.up = true

        if airborne_or_dropdown and (not is_sliding and dash_ready) then
            if airborne_or_dropdown and dash_ready then
                movement(dash.afterboosted and "longjump" or "edgejump")

                horizontal_multiplier = 1 + (movement.leapMultiplier - 1) * boost_factor
                vertical_boost = boost_factor * (registry["increase longjump strength"] and 10 or 2)

                if dash.totalChainJumps > 0 then
                    horizontal_multiplier += (0.5 - 0.5 / dash.totalChainJumps)
                end

                if dash.afterboosted then
                    dash.chainStrain = math.min(dash.chainStrain + 1, dash.strainLimit * 2)

                    if dash.chainStrain < dash.strainLimit then
                        dash.totalChainJumps = dash.totalChainJumps + 1
                    else
                        dash.totalChainJumps = 1
                    end

                    if data:hasAbility("Chain") then
                        dash.holdForLanding = dash.chainWindow
                        ui.hud.Momentum.Overcharge.Visible = true
                        
                        local total_chain_jumps = dash.totalChainJumps
                        if total_chain_jumps >= 3 then
                            ui.chain:updateCounter()

                            local flash_rate_base = 6 + total_chain_jumps / total_chain_jumps ^ 0.25
                            local flash_intensity = total_chain_jumps / total_chain_jumps ^ 0.4
                            local flash_count = math.min(200, total_chain_jumps / 3)

                            for _ = 1, math.floor(flash_count) + 2 do
                                ui.chain:spawnFlash(shortcut.random(flash_rate_base / 2, flash_rate_base), flash_intensity)
                            end
                        end

                        network:send("chainJump", dash.totalChainJumps)
                    end
                    
                    if actor.velocity.Y > 8 then
                        data.stats:increment("LongJumpBoosts", 1)
                    end

                    if jump_phase == "left" then
                        animation.edgeJumpL:Play(0.1, 1, 1)
                    else
                        animation.edgeJumpR:Play(0.1, 1, 1)
                    end

                    dash.lastLongJump = tick()
                    data.stats:increment("LongJumps", 1)
                    actor:speedboost()
                else
                    animation.flailjump:Play(0.2)
                end
            end
        else
            if jump_phase == "left" then
                animation.jumpL:Play()
            else
                animation.jumpR:Play()
            end

            movement:breakChain()
        end

        local has_boost_belt = gear:hasUpgrade("Compound", "BoostBelt")
        local has_boost_belt = gear:hasUpgrade("Compound", "BoostBelt")
        local jump_power = actor.jumpPower * movement.floatPower * (has_boost_belt and 1.2 or 1)
        local input_active = actor.inputVector.magnitude > input.inputVectorZeroThreshold
        local horizontal_speed = actor.horizontalVelocity.magnitude
        local is_moving_slow = false

        if input_active then
            is_moving_slow = horizontal_speed < actor.baseSpeed
        else
            is_moving_slow = input_active
        end

        local intended_velocity = actor.inputVector * actor.speed
        local adjusted_velocity = Vector3.zero
        local effective_speed = 0

        if is_moving_slow then
            adjusted_velocity = intended_velocity * horizontal_multiplier
        elseif horizontal_speed > 0 then
            adjusted_velocity = actor.horizontalVelocity * horizontal_multiplier
        else
            adjusted_velocity = camera.rawlook * Vector3.new(1, 0, 1) * horizontal_multiplier
        end

        if dash_ready then
            effective_speed = actor.speed
        else
            local min_speed = math.min(actor.maxSpeed, horizontal_speed)
            local max_speed_candidate = input_active and actor.maxSpeed or 0
            local capped_speed = math.min(max_speed_candidate, actor.speed, actor.maxSpeed)
            effective_speed = math.max(min_speed, capped_speed)
        end

        local final_speed = effective_speed * horizontal_multiplier
        local max_speed = math.max(final_speed, horizontal_speed)
        local move_direction = shortcut.unit(adjusted_velocity) * max_speed
        local powerslide = movement.parkour.powerslide

        if powerslide.active then
            local input_unit = shortcut.unit(actor.inputVector)
            local powerslide_velocity_unit = shortcut.unit(powerslide.velocity)
            local clamped_direction

            if input_active then
                local clamped_2d = utility.clampVectorWithinCone(Vector2.new(input_unit.X, input_unit.Z), Vector2.new(powerslide_velocity_unit.X, powerslide_velocity_unit.Z), 120).unit
                clamped_direction = Vector3.new(clamped_2d.X, 0, clamped_2d.Y).Unit
            else
                clamped_direction = powerslide_velocity_unit
            end

            if clamped_direction.Magnitude == clamped_direction.Magnitude then
                powerslide_velocity_unit = clamped_direction
            end

            move_direction = powerslide_velocity_unit * powerslide.entrySpeed
            movement:stopPowerslide()
        end

        if movement.parkour.dropdown.active then
            movement:setMovementActive("dropdown", false)
            animation.dropdown:SafeStop()
        end

        if movement.parkour.dropslide.active then
            movement:setMovementActive("dropslide", false)
            animation.dropdownSlide:SafeStop()
        end

        local vertical_velocity = actor.velocity.Y
        local jump_velocity = math.max(0, vertical_velocity) + actor.jumpPower + vertical_boost 
        local max_vertical_velocity = math.max(42, vertical_velocity)
        local clamped_vertical_velocity = math.clamp(jump_velocity, 0, max_vertical_velocity)
        local move_magnitude = move_direction.Magnitude

        if move_magnitude ~= move_magnitude then 
            move_direction = Vector3.new()
        end

        local final_velocity = Vector3.new(move_direction.X, clamped_vertical_velocity, move_direction.Z)
        actor.humanoid:SetVelocity(final_velocity)

        if score.combo.score.base > 0 then
            task.spawn(function()
                score.combo:attemptAdvanceCoverage()
            end)
        end

        sound:PlayStep("jump")
        movement.highJumping = tick()

        while not actor.ground and (actor.jumping and (movement.highJumping and (actor.jumping < movement.highJumping and not movement.parkour.is))) do
            engine.wait()

            if jump_power <= 0 then
                movement.highJumping = false
                break
            end

            actor.gravity = actor.defaultGravity - jump_power
            jump_power = math.max(0, jump_power - engine.delta * movement.floatDecay)

            if not input.bindsDown.upmove and (movement.highJumping and tick() - movement.highJumping > 0.05) then
                movement.highJumping = false
                break
            end
        end

        if not (actor.ground or (animation.coil.raw.IsPlaying or movement.parkour.is)) then
            actor.humanoid:SetState("Falling")
        end

        actor.gravity = actor.defaultGravity
        actor.jumping = false
        movement.highJumping = false
    end
end

local old = movement.land
movement.land = function(self, ...)
    if registry["auto land"] then
        local gravity = actor.defaultGravity
        local physics = actor.physics
        local velocity = actor.airVelocity
        local momentum = physics.GroundNormal and -physics.GroundNormal:Dot(velocity.unit) or 1
		local fall_distance = 0.5 * gravity * ((velocity.magnitude * momentum) / gravity) ^ 2

        if fall_distance > self.parkour.land.minLandingHeight and fall_distance >= self.parkour.land.minDamageHeight then
            input.bindsDown.downmove = tick()
            
            task.delay(0.1, function()
                input.bindsDown.downmove = nil
            end)
        end
    end

    return old(self, ...)
end

local old = gear.grappler.throw
gear.grappler.throw = function(self, ...)
    if registry["increase pull strength"] then
        local pull_force = self.pullForce
        self.pullForce = 120

        old(self, ...)

        self.pullForce = pull_force

        return
    end

    return old(self, ...)
end

local old = actor.inchealth
actor.inchealth = function(self, ...)
    if registry["god mode"] and math.abs(({...})[1]) ~= ({...})[1] then
       return
    end

    return old(self, ...)
end

-- run_service.RenderStepped:Connect(function()
--     gear.grappler.pullForce = 120
-- end)

local window = gui:TabsWindow({
	Title = "Exodus",
	NoClose = true,
	NoResize = true,
	NoCollapse = true,
	NoMove = true,
    Visible = false,
	Size = UDim2.fromOffset(580, 450),
})

window:Center()

local movement_tab = window:CreateTab({Name = "movement"})
local augment_tab = window:CreateTab({Name = "augment"}) 
local item_tab = window:CreateTab({Name = "items"})

movement_tab:Checkbox({
	Label = "Auto Land",
	Value = false,
	Callback = function(self, value)
		registry["auto land"] = value
	end
})

movement_tab:Checkbox({
	Label = "Longjump Anywhere",
	Value = false,
	Callback = function(self, value)
		registry["longjump anywhere"] = value
	end
})


movement_tab:Checkbox({
	Label = "Increase Longjump Strength",
	Value = false,
	Callback = function(self, value)
		registry["increase longjump strength"] = value
	end
})

movement_tab:Checkbox({
	Label = "Increase Pull Strength",
	Value = false,
	Callback = function(self, value)
		registry["increase pull strength"] = value
	end
})

movement_tab:SliderInt({
    Label = "Wallboost Increment",
    Value = 0,
    Minimum = 0,
    Maximum = 100,
    Callback = function(self, value)
        registry["wallboost increment"] = value
    end
})

movement_tab:InputText({
	Label = "player database",
	PlaceHolder = "search here",
	Value = "",
    Callback = function(self, value)
        local character = core.find_player(value)

        if actor.character and character then
            actor.character:PivotTo(character:GetPivot() * CFrame.new(0, 15, 0))
        end
    end
})

augment_tab:Checkbox({
	Label = "God Mode",
	Value = false,
	Callback = function(self, value)
		registry["god mode"] = value
	end
})

augment_tab:Checkbox({
	Label = "Unlock Abilities",
	Value = false,
	Callback = function(self, value)
		registry["unlock abilities"] = value
	end
})

item_tab:InputText({
	Label = "item database",
	PlaceHolder = "search here",
	Value = "",
    Callback = function(self, value)
        local item = core.find_item(value)

        if actor.character and item then
            actor.character:PivotTo(item:GetPivot())
        end
    end
})

]=])
