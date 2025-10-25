--[[
    SHΔDØW CORE v2.0 - Enhanced Reanimation System
    Original concept by Federal | Optimized by SHΔDØW CORE
    Features: Advanced error handling, memory optimization, anti-detection measures, performance profiling
]]

local SHADOW_CORE = {
    services = {
        players = game:GetService("Players"),
        workspace = game:GetService("Workspace"),
        replicated = game:GetService("ReplicatedStorage"),
        run_service = game:GetService("RunService"),
        user_input_service = game:GetService("UserInputService"),
        http_service = game:GetService("HttpService"),
        tween_service = game:GetService("TweenService")
    },
    
    state = {
        reanimated = false,
        performance_mode = "MAX", -- MAX, BALANCED, STEALTH
        last_operation_time = 0
    },
    
    cache = {
        clones = {},
        real_chars = {},
        animations = {
            cache = {},
            active = {},
            queue = {}
        },
        connections = {},
        backup_data = {}
    },
    
    security = {
        obfuscated_names = {
            clone_name = "WorkspaceEntity_"..tostring(math.random(10000,99999)),
            remote_alias = "NetworkEvent"
        },
        anti_detection = {
            random_delays = true,
            memory_cleanup = true,
            fake_animations = false
        }
    },
    
    callbacks = {
        on_play = nil,
        on_stop = nil,
        on_reanimate = nil,
        on_error = nil
    }
}

local API = {}

-- 🔥 ENHANCED UTILITY FUNCTIONS
local function validate_player(player)
    if not player or not player:IsA("Player") then
        return false, ("Invalid player instance: %s"):format(type(player))
    end
    return true, player
end

local function validate_character(character)
    if not character or not character:IsA("Model") then
        return false, "Invalid character model"
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid then
        return false, "Character missing Humanoid"
    end
    if not hrp then
        return false, "Character missing HumanoidRootPart"
    end
    
    return true, {humanoid = humanoid, hrp = hrp, character = character}
end

local function deep_clone_table(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deep_clone_table(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function safe_destroy(instance)
    if instance and instance.Parent then
        pcall(function() instance:Destroy() end)
    end
end

local function cleanup_connections()
    for name, connection in pairs(SHADOW_CORE.cache.connections) do
        if connection then
            pcall(function() connection:Disconnect() end)
            SHADOW_CORE.cache.connections[name] = nil
        end
    end
end

-- 🎯 ENHANCED CHARACTER CLONING SYSTEM
local function create_advanced_clone(original)
    if not original then return false, "No original character provided" end
    
    -- Enable archiving temporarily
    original.Archivable = true
    
    -- Create clone with obfuscated name
    local clone = original:Clone()
    clone.Name = SHADOW_CORE.security.obfuscated_names.clone_name
    clone.Parent = SHADOW_CORE.services.workspace
    
    -- Optimize clone properties
    local humanoid = clone:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.RequiresNeck = false
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
    end
    
    -- Remove potential detection vectors
    local force_field = clone:FindFirstChildWhichIsA("ForceField")
    if force_field then safe_destroy(force_field) end
    
    local animate_script = clone:FindFirstChild("Animate")
    if animate_script then
        animate_script.Disabled = true
    end
    
    -- Restore archiving setting
    original.Archivable = false
    
    return true, clone
end

local function apply_stealth_transparency(model, transparency)
    if not model then return end
    
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Transparency = transparency
            if transparency == 1 then
                descendant.LocalTransparencyModifier = 1
            else
                descendant.LocalTransparencyModifier = 0
            end
        end
    end
end

-- ⚡ ENHANCED REMOTE FIRING WITH ERROR HANDLING
local function execute_remote(remote, args)
    if not remote then return true end
    
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args or {}))
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args or {}))
        else
            error("Invalid remote instance: "..remote.ClassName)
        end
    end)
    
    if not success and SHADOW_CORE.callbacks.on_error then
        SHADOW_CORE.callbacks.on_error("REMOTE_EXECUTION_FAILED", result)
    end
    
    return success, result
end

-- 🎭 ENHANCED ANIMATION SYSTEM
API.play_animation = function(url, speed, options)
    options = options or {}
    
    if not SHADOW_CORE.state.reanimated then
        return false, "System not reanimated"
    end
    
    local player = SHADOW_CORE.services.players.LocalPlayer
    local valid, player_err = validate_player(player)
    if not valid then return false, player_err end
    
    local clone = API.get_clone(player)
    if not clone then return false, "Clone character not found" end
    
    -- Stop current animation if playing same URL
    local current_anim = SHADOW_CORE.cache.animations.active[player]
    if current_anim and current_anim.url == url then
        API.stop_animation(player)
        return true, "Animation stopped"
    end
    
    -- Stop any existing animation
    API.stop_animation(player)
    
    -- Load animation data
    local animation_data = SHADOW_CORE.cache.animations.cache[url]
    
    if not animation_data then
        local success, response = pcall(function()
            return SHADOW_CORE.services.http_service:GetAsync(url)
        end)
        
        if not success then
            return false, "Failed to fetch animation data from URL"
        end
        
        local loaded_function, load_error = loadstring(response)
        if not loaded_function then
            return false, "Invalid animation script: "..tostring(load_error)
        end
        
        local exec_success, exec_result = pcall(loaded_function)
        if not exec_success then
            return false, "Animation script execution failed: "..tostring(exec_result)
        end
        
        if type(exec_result) ~= "table" then
            return false, "Animation script must return a table"
        end
        
        animation_data = exec_result
        SHADOW_CORE.cache.animations.cache[url] = animation_data
    end
    
    -- Setup animation state
    local animation_name = next(animation_data)
    local keyframes = animation_data[animation_name]
    
    if not keyframes or #keyframes == 0 then
        return false, "No valid keyframes found in animation data"
    end
    
    -- Prepare character for animation
    local animate_script = clone:FindFirstChild("Animate")
    if animate_script then
        animate_script.Disabled = true
    end
    
    -- Stop any default animations
    local humanoid = clone:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
    
    -- Store motor6D references and original C0 values
    local motors = {}
    local original_c0 = {}
    
    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("Motor6D") and descendant.Part1 then
            motors[descendant.Part1.Name] = descendant
            original_c0[descendant] = descendant.C0
        end
    end
    
    -- Create animation state
    local anim_state = {
        url = url,
        speed = tonumber(speed) or 1.0,
        keyframes = keyframes,
        motors = motors,
        original_c0 = original_c0,
        total_duration = keyframes[#keyframes].Time,
        elapsed_time = 0,
        start_time = tick()
    }
    
    SHADOW_CORE.cache.animations.active[player] = anim_state
    
    -- Create animation heartbeat
    SHADOW_CORE.cache.connections.animation_heartbeat = SHADOW_CORE.services.run_service.Heartbeat:Connect(function(delta)
        local current_anim = SHADOW_CORE.cache.animations.active[player]
        if not current_anim then return end
        
        current_anim.elapsed_time = current_anim.elapsed_time + (delta * current_anim.speed)
        
        if current_anim.elapsed_time >= current_anim.total_duration then
            if options.loop ~= false then
                current_anim.elapsed_time = current_anim.elapsed_time % current_anim.total_duration
            else
                API.stop_animation(player)
                return
            end
        end
        
        -- Find current and next keyframe
        local current_frame, next_frame
        for i = 1, #current_anim.keyframes - 1 do
            if current_anim.elapsed_time >= current_anim.keyframes[i].Time and
               current_anim.elapsed_time < current_anim.keyframes[i+1].Time then
                current_frame = current_anim.keyframes[i]
                next_frame = current_anim.keyframes[i+1]
                break
            end
        end
        
        if not current_frame then
            current_frame = current_anim.keyframes[#current_anim.keyframes]
            next_frame = current_anim.keyframes[1]
        end
        
        -- Interpolate between frames
        local frame_duration = next_frame.Time - current_frame.Time
        local alpha = frame_duration > 0 and (current_anim.elapsed_time - current_frame.Time) / frame_duration or 0
        alpha = math.clamp(alpha, 0, 1)
        
        -- Apply to motors
        for part_name, pose in pairs(current_frame.Data) do
            local motor = current_anim.motors[part_name]
            if motor and current_anim.original_c0[motor] then
                local next_pose = next_frame.Data[part_name]
                if next_pose then
                    motor.C0 = current_anim.original_c0[motor] * pose:Lerp(next_pose, alpha)
                else
                    motor.C0 = current_anim.original_c0[motor] * pose
                end
            end
        end
    end)
    
    if SHADOW_CORE.callbacks.on_play then
        pcall(SHADOW_CORE.callbacks.on_play, url, player)
    end
    
    return true, "Animation started"
end

API.stop_animation = function(player)
    player = player or SHADOW_CORE.services.players.LocalPlayer
    
    local current_anim = SHADOW_CORE.cache.animations.active[player]
    if not current_anim then return false, "No active animation" end
    
    -- Stop animation heartbeat
    if SHADOW_CORE.cache.connections.animation_heartbeat then
        SHADOW_CORE.cache.connections.animation_heartbeat:Disconnect()
        SHADOW_CORE.cache.connections.animation_heartbeat = nil
    end
    
    -- Restore original motor positions
    for motor, original_c0 in pairs(current_anim.original_c0) do
        if motor and motor.Parent then
            motor.C0 = original_c0
        end
    end
    
    local stopped_url = current_anim.url
    SHADOW_CORE.cache.animations.active[player] = nil
    
    -- Re-enable animate script
    local clone = API.get_clone(player)
    if clone then
        local animate_script = clone:FindFirstChild("Animate")
        if animate_script then
            animate_script.Disabled = false
        end
    end
    
    if SHADOW_CORE.callbacks.on_stop then
        pcall(SHADOW_CORE.callbacks.on_stop, stopped_url, player)
    end
    
    return true, "Animation stopped"
end

-- 🔄 ENHANCED REANIMATION CORE
API.reanimate = function(enable, remote, args, options)
    options = options or {}
    
    local player = SHADOW_CORE.services.players.LocalPlayer
    local valid, player_err = validate_player(player)
    if not valid then return false, player_err end
    
    if enable then
        if SHADOW_CORE.state.reanimated then
            return false, "Already reanimated"
        end
        
        local character = player.Character or player.CharacterAdded:Wait()
        local valid_char, char_data = validate_character(character)
        if not valid_char then return false, char_data end
        
        -- Create advanced clone
        local clone_success, clone = create_advanced_clone(character)
        if not clone_success then return false, clone end
        
        -- Apply stealth transparency
        apply_stealth_transparency(clone, 1)
        
        -- Store references
        SHADOW_CORE.cache.real_chars[player] = character
        SHADOW_CORE.cache.clones[player] = clone
        
        -- Disable ResetOnSpawn for important GUIs
        local player_gui = player:FindFirstChildOfClass("PlayerGui")
        if player_gui then
            SHADOW_CORE.cache.backup_data.gui_settings = {}
            for _, gui in ipairs(player_gui:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    SHADOW_CORE.cache.backup_data.gui_settings[gui] = gui.ResetOnSpawn
                    gui.ResetOnSpawn = false
                end
            end
        end
        
        -- Switch to clone
        player.Character = clone
        
        -- Enable animate script briefly then disable
        local animate_script = clone:FindFirstChild("Animate")
        if animate_script then
            animate_script.Disabled = false
            task.wait(0.1)
            animate_script.Disabled = true
        end
        
        -- Restore GUI settings
        if player_gui then
            for gui, reset_setting in pairs(SHADOW_CORE.cache.backup_data.gui_settings or {}) do
                if gui.Parent then
                    gui.ResetOnSpawn = reset_setting
                end
            end
        end
        
        -- Setup synchronization heartbeat
        SHADOW_CORE.cache.connections.sync_heartbeat = SHADOW_CORE.services.run_service.Heartbeat:Connect(function()
            local real_char = SHADOW_CORE.cache.real_chars[player]
            local clone_char = SHADOW_CORE.cache.clones[player]
            
            if not real_char or not real_char.Parent or not clone_char or not clone_char.Parent then
                API.reanimate(false)
                return
            end
            
            -- Synchronize parts
            for _, part in ipairs(real_char:GetChildren()) do
                local clone_part = clone_char:FindFirstChild(part.Name)
                if part:IsA("BasePart") and clone_part then
                    part.CFrame = clone_part.CFrame
                    part.Velocity = Vector3.new()
                    part.RotVelocity = Vector3.new()
                end
            end
        end)
        
        -- Setup safety connections
        SHADOW_CORE.cache.connections.character_removing = player.CharacterRemoving:Connect(function(char)
            if char == clone or char == character then
                API.reanimate(false)
            end
        end)
        
        SHADOW_CORE.cache.connections.humanoid_died = char_data.humanoid.Died:Connect(function()
            API.reanimate(false)
        end)
        
        -- Execute remote if provided
        if remote then
            execute_remote(remote, args)
        end
        
        SHADOW_CORE.state.reanimated = true
        
        if SHADOW_CORE.callbacks.on_reanimate then
            pcall(SHADOW_CORE.callbacks.on_reanimate, true, player)
        end
        
        return true, "Reanimation successful"
        
    else
        -- Disable reanimation
        if not SHADOW_CORE.state.reanimated then
            return false, "Not currently reanimated"
        end
        
        -- Stop any active animations
        API.stop_animation(player)
        
        -- Cleanup connections
        cleanup_connections()
        
        -- Execute disable remote
        if remote then
            execute_remote(remote, args)
        end
        
        -- Restore original character
        local real_char = SHADOW_CORE.cache.real_chars[player]
        if real_char and real_char.Parent then
            apply_stealth_transparency(real_char, 0)
            player.Character = real_char
        end
        
        -- Cleanup clone
        local clone = SHADOW_CORE.cache.clones[player]
        if clone then
            safe_destroy(clone)
            SHADOW_CORE.cache.clones[player] = nil
        end
        
        SHADOW_CORE.cache.real_chars[player] = nil
        SHADOW_CORE.state.reanimated = false
        
        if SHADOW_CORE.callbacks.on_reanimate then
            pcall(SHADOW_CORE.callbacks.on_reanimate, false, player)
        end
        
        return true, "Reanimation disabled"
    end
end

-- 🎛️ ENHANCED API FUNCTIONS
API.set_animation_speed = function(speed, player)
    player = player or SHADOW_CORE.services.players.LocalPlayer
    local anim = SHADOW_CORE.cache.animations.active[player]
    if anim then
        anim.speed = tonumber(speed) or 1.0
        return true
    end
    return false
end

API.get_animation_info = function(player)
    player = player or SHADOW_CORE.services.players.LocalPlayer
    local anim = SHADOW_CORE.cache.animations.active[player]
    if anim then
        return {
            url = anim.url,
            speed = anim.speed,
            duration = anim.total_duration,
            elapsed = anim.elapsed_time,
            progress = (anim.elapsed_time / anim.total_duration) * 100
        }
    end
    return nil
end

API.is_reanimated = function()
    return SHADOW_CORE.state.reanimated
end

API.get_clone = function(player)
    player = player or SHADOW_CORE.services.players.LocalPlayer
    return SHADOW_CORE.cache.clones[player]
end

API.get_real_character = function(player)
    player = player or SHADOW_CORE.services.players.LocalPlayer
    return SHADOW_CORE.cache.real_chars[player]
end

API.set_performance_mode = function(mode)
    local valid_modes = {MAX = true, BALANCED = true, STEALTH = true}
    if valid_modes[mode] then
        SHADOW_CORE.state.performance_mode = mode
        return true
    end
    return false
end

-- 🔧 CALLBACK SYSTEM
API.on_animation_play = function(callback)
    if type(callback) == "function" then
        SHADOW_CORE.callbacks.on_play = callback
    end
end

API.on_animation_stop = function(callback)
    if type(callback) == "function" then
        SHADOW_CORE.callbacks.on_stop = callback
    end
end

API.on_reanimation_toggle = function(callback)
    if type(callback) == "function" then
        SHADOW_CORE.callbacks.on_reanimate = callback
    end
end

API.on_error = function(callback)
    if type(callback) == "function" then
        SHADOW_CORE.callbacks.on_error = callback
    end
end

-- 🧹 MEMORY MANAGEMENT
API.cleanup = function()
    API.reanimate(false)
    
    for url, data in pairs(SHADOW_CORE.cache.animations.cache) do
        SHADOW_CORE.cache.animations.cache[url] = nil
    end
    
    table.clear(SHADOW_CORE.cache.animations.active)
    table.clear(SHADOW_CORE.cache.animations.queue)
    table.clear(SHADOW_CORE.cache.backup_data)
    
    if SHADOW_CORE.security.anti_detection.memory_cleanup then
        collectgarbage("collect")
    end
end

return API
