--[[
    Advanced Aurora Borealis System

    This script creates a dynamic aurora effect using neon parts, sine wave motion,
    dynamic lighting, and particle emitters.

    Made by @CordeliusVox
    Date: 04/03/2025
]]--

--// services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

--[[
    a function for debugging logs.
    it prefixes each message with a log level and the current time (formatted as HH:MM:SS).

    parameters:
      Message (string): the log message.
      Level (string): the log level (e.g., "INFO", "DEBUG"). default is "INFO".

    this function is used throughout the script to track events and key state changes.
]]
local function AdvancedLogger(Message, Level)
    Level = Level or "INFO" -- set a default log level to "INFO" if none is provided.
    print("[" .. Level .. "][" .. os.date("%X") .. "]: " .. Message) -- print the log message, formatting it with the level, current time, and message.
end

--[[ 
    represents a single band of the aurora.
    each band is composed of several segments that are individually animated to create
    the overall waving aurora effect. (using sine waves)
]]--
local AuroraBand = {}
AuroraBand.__index = AuroraBand

--[[
    constructs an AuroraBand instance.

    parameters:
      Origin (Vector3): starting position for the band.
      Length (number): the complete horizontal distance where segments are positioned.
      SegmentCount (number): how many segments to create along the band.
      Amplitude (number): highest vertical offset for variation.
      Frequency (number): speed factor for sine wave oscillation.
      BaseColor (Color3): starting color for the color gradient.
      FadeColor (Color3): ending color for the gradient.
      ParentFolder (Folder): parent container for organizing the created parts.

    returns:
      an AuroraBand instance with its segments, lights, and particle emitters. (basically, the whole band)
    
    notes on implementation:
      - each segment is a neon part with a dynamic PointLight and ParticleEmitter.
      - the segments are colored along a gradient (using Color3:Lerp) to create visual depth.
]]
function AuroraBand.new(Origin, Length, SegmentCount, Amplitude, Frequency, BaseColor, FadeColor, ParentFolder)
    -- validate input parameters
    assert(typeof(Origin) == "Vector3", "Origin must be a Vector3")
    assert(type(Length) == "number" and Length > 0, "Length must be a positive number")
    assert(type(SegmentCount) == "number" and SegmentCount >= 2, "SegmentCount must be at least 2")
    assert(type(Amplitude) == "number" and Amplitude >= 0, "Amplitude must be positive")
    assert(type(Frequency) == "number" and Frequency > 0, "Frequency must be positive")
    assert(typeof(BaseColor) == "Color3", "BaseColor must be a Color3")
    assert(typeof(FadeColor) == "Color3", "FadeColor must be a Color3")
    assert(typeof(ParentFolder) == "Instance" and ParentFolder:IsA("Folder"), "ParentFolder must be a Folder instance")

    local self = setmetatable({}, AuroraBand) -- create a new AuroraBand instance with an empty table and set its metatable to AuroraBand class.
    
    -- store parameters, using provided values (or defaults). this ensures "robustness".
    self.Origin = Origin or Vector3.new(0, 100, 0)
    self.Length = Length or 200
    self.SegmentCount = SegmentCount or 20
    self.Amplitude = Amplitude or 20
    self.Frequency = Frequency or 1
    self.BaseColor = BaseColor or Color3.fromRGB(0, 255, 150)
    self.FadeColor = FadeColor or Color3.fromRGB(50, 100, 255)
    self.Segments = {}  -- will hold each segment's Part and associated Light.

    -- create a folder to hold all parts for this aurora band (for organization in the hierarchy).
    self.Folder = Instance.new("Folder")
    self.Folder.Name = "AuroraBand"
    self.Folder.Parent = ParentFolder

    -- Create segments along the horizontal axis based on SegmentCount.
    for i = 0, self.SegmentCount - 1 do -- loop through each segment index from 0 to SegmentCount - 1.  
        local t = i / (self.SegmentCount - 1) -- normalized position (0 to 1) along the band.
        local Position = self.Origin + Vector3.new(self.Length * t, 0, 0)

        -- create a neon Part to represent a segment.
        local Segment = Instance.new("Part")
        Segment.Name = "AuroraSegment"
        Segment.Size = Vector3.new(self.Length / self.SegmentCount, 2, 20)
        Segment.Anchored = true -- prevent physics from moving the segment.
        Segment.CanCollide = false -- disable collision for performance.
        Segment.CastShadow = false -- disable shadows to boost performance.
        Segment.Material = Enum.Material.Neon
        Segment.Transparency = 0.3 -- initial transparency for blending effect.
        Segment.CFrame = CFrame.new(Position)
        Segment.Parent = self.Folder

        -- calculate a color along the gradient from BaseColor to FadeColor using lerp.
        local SegmentColor = self.BaseColor:Lerp(self.FadeColor, t) -- smoothly transition between BaseColor and FadeColor based on position, creating a gradient effect.  
        Segment.Color = SegmentColor

        -- attach a PointLight to each segment for cool lighting.
        local _Light = Instance.new("PointLight")
        _Light.Color = SegmentColor
        _Light.Range = 30
        _Light.Brightness = 2
        _Light.Parent = Segment

        -- create a ParticleEmitter to add additional visual effects.
        local Emitter = Instance.new("ParticleEmitter")
        Emitter.Parent = Segment
        Emitter.Texture = "rbxassetid://243098098"
        Emitter.Rate = 20
        Emitter.Lifetime = NumberRange.new(2, 3)
        Emitter.Speed = NumberRange.new(1, 3)
        Emitter.VelocitySpread = 180
        Emitter.LightInfluence = 1
        Emitter.Size = NumberSequence.new({ -- sets the particle size to start at 2 and shrink to 0 over its lifetime.  
            NumberSequenceKeypoint.new(0, 2),
            NumberSequenceKeypoint.new(1, 0)
        })

        -- store the segment part and its light for later updates.
        table.insert(self.Segments, {Part = Segment, Light = _Light})
    end

    return self
end

--[[
    updates each segment’s position and color based on passed time.

    parameters:
      DeltaTime (number): time passeed since the last update (for smooth interpolation).
      Time (number): total time passed since the system started (used for oscillation).

    logic:
      - moves vertically with a sine wave and sways sideways with cosine.
      - smoothly transition colors using a sine based factor.
      - uses CFrame:Lerp for gradual position changes.
]]
function AuroraBand:Update(DeltaTime, Time)
    for i, SegmentData in ipairs(self.Segments) do -- loop through each segment in the list with its index and get its data
        local Part = SegmentData.Part
        local Light = SegmentData.Light

        local t = (i - 1) / (self.SegmentCount - 1)
        -- calculate vertical movement and side sway with sine and cosine  
        local Wave = math.sin(Time * self.Frequency + t * math.pi * 2) * self.Amplitude -- calculate vertical motion using a sine wave
        local Sway = math.cos(Time * self.Frequency * 0.5 + t * math.pi) * 5 -- calculate sideways sway with a cosine wave  
        local BasePosition = self.Origin + Vector3.new(self.Length * t, 0, 0)
        local NewPosition = BasePosition + Vector3.new(0, Wave, Sway)

        -- smoothly transition (Lerp) from the current position to the new calculated position.
        Part.CFrame = Part.CFrame:Lerp(CFrame.new(NewPosition) * CFrame.Angles(0, math.rad(90), 0), DeltaTime * 5)

        -- calculate a color shift factor and blend between BaseColor and FadeColor.
        local ColorShift = 0.5 + 0.5 * math.sin(Time + t * math.pi * 2) -- shifts sine wave from (-1,1) to (0,1) by scaling and offsetting  
        local NewColor = self.BaseColor:Lerp(self.FadeColor, ColorShift)
        Part.Color = NewColor
        Light.Color = NewColor
    end
end

--[[
    resets each segment’s position to its initial calculated base position.
    this is useful for restoring the system to a known state after modifications or disruptions.
]]
function AuroraBand:Reset()
    for i, SegmentData in ipairs(self.Segments) do -- loop through all segments in the AuroraBand 
        local t = (i - 1) / (self.SegmentCount - 1) -- calculate the normalized position along the band (0 to 1)  
        local BasePosition = self.Origin + Vector3.new(self.Length * t, 0, 0) -- determine the base position for the segment along the band  
        SegmentData.Part.CFrame = CFrame.new(BasePosition) * CFrame.Angles(0, math.rad(90), 0) -- reset the segment's position and orientation  
    end
	
    AdvancedLogger("AuroraBand reset to initial positions", "DEBUG") -- log a debug message indicating the reset was performed  
end

--[[
    manages multiple AuroraBand instances.
    provides centralized update, reset, and configuration functions so that all bands
    can be controlled as a group.
]]
local AuroraManager = {}
AuroraManager.__index = AuroraManager

function AuroraManager.new()
    local self = setmetatable({}, AuroraManager)
    self.Bands = {}  -- container for all AuroraBand instances.

    -- create a folder in the Workspace to organize all aurora bands.
    self.Folder = Instance.new("Folder")
    self.Folder.Name = "AuroraManager"
    self.Folder.Parent = workspace

    -- create several AuroraBand instances with varying parameters to produce a layered effect.
    table.insert(self.Bands, AuroraBand.new(Vector3.new(-80, 110, -60), 320, 26, 14, 1.3, Color3.fromRGB(0, 255, 200), Color3.fromRGB(100, 50, 255), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(-40, 135, 30), 280, 22, 12, 1.1, Color3.fromRGB(50, 255, 180), Color3.fromRGB(90, 40, 240), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(60, 120, -90), 350, 30, 10, 1.5, Color3.fromRGB(0, 255, 180), Color3.fromRGB(80, 20, 255), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(-100, 145, 70), 270, 24, 18, 1.0, Color3.fromRGB(20, 255, 220), Color3.fromRGB(110, 30, 230), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(50, 150, -50), 310, 27, 17, 1.25, Color3.fromRGB(10, 245, 200), Color3.fromRGB(140, 50, 255), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(-70, 140, 20), 360, 32, 13, 1.6, Color3.fromRGB(0, 255, 190), Color3.fromRGB(70, 20, 250), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(20, 160, -10), 290, 23, 19, 1.05, Color3.fromRGB(5, 255, 210), Color3.fromRGB(100, 35, 240), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(-30, 125, 90), 280, 21, 13, 1.1, Color3.fromRGB(0, 220, 210), Color3.fromRGB(90, 30, 240), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(90, 135, -70), 260, 19, 15, 0.9, Color3.fromRGB(10, 240, 190), Color3.fromRGB(110, 25, 230), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(-50, 130, -30), 300, 25, 12, 1.3, Color3.fromRGB(0, 235, 205), Color3.fromRGB(80, 20, 255), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(30, 145, 40), 330, 28, 14, 1.4, Color3.fromRGB(0, 250, 180), Color3.fromRGB(130, 40, 255), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(-90, 120, 10), 290, 22, 11, 1.2, Color3.fromRGB(5, 255, 190), Color3.fromRGB(95, 35, 250), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(10, 150, -80), 340, 28, 16, 1.4, Color3.fromRGB(0, 230, 255), Color3.fromRGB(130, 60, 255), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(-60, 155, 50), 250, 20, 20, 0.8, Color3.fromRGB(0, 200, 255), Color3.fromRGB(150, 0, 255), self.Folder))
    table.insert(self.Bands, AuroraBand.new(Vector3.new(70, 125, -40), 320, 26, 14, 1.3, Color3.fromRGB(0, 180, 255), Color3.fromRGB(120, 10, 250), self.Folder))

    return self
end

--[[
    loop through all bands to update each one's state.

    parameters:
      DeltaTime (number): Time elapsed since the last frame.
      Time (number): Total elapsed time since the system started.

    this centralized update ensures all aurora bands animate synchronously.
]]
function AuroraManager:Update(DeltaTime, Time)
    for _, Band in ipairs(self.Bands) do -- loops through all AuroraBands stored in self.Bands  
        Band:Update(DeltaTime, Time) -- calls each band's Update method, propagating time values  
    end
end

--[[
    dynamically adjusts the ambient lighting color to simulate
    a smooth day to night transition using sine based interpolation.
    
    pParameters:
      Time (number): the passed time used to calculate the interpolation factor.
]]
local function UpdateSkyColor(Time)
    local DayColor = Color3.fromRGB(20, 20, 60)
    local NightColor = Color3.fromRGB(5, 5, 20)
    
    -- factor moving repeatedly between 0 and 1 to blend between DayColor and NightColor.
    local Factor = 0.5 + 0.5 * math.sin(Time * 0.1)
    Lighting.Ambient = DayColor:Lerp(NightColor, Factor)
    Lighting.OutdoorAmbient = Lighting.Ambient
end

--[[
    adjusts the brightness of the global lighting based on time.
    uses a sine function to introduce smooth, periodic variation in brightness. (nerd)
    
    parameters:
      Time (number): the passed time used to calculate the brightness variation.
]]
local function UpdateSkyIntensity(Time)
    local BaseIntensity = 0.2
    local Variation = 0.1 * math.sin(Time * 0.5)
    Lighting.Brightness = BaseIntensity + Variation
end

--// main script setup & loop
local StartTime = time() -- Use time() for a accurate time reference.

-- instantiate the AuroraManager which creates all aurora bands.
local _AuroraManager = AuroraManager.new()

-- connect to the Heartbeat event for per frame updates.
RunService.Heartbeat:Connect(function(DeltaTime)
    local CurrentTime = time() - StartTime -- calculate passed time.
    
    _AuroraManager:Update(DeltaTime, CurrentTime) -- update all aurora bands.
    UpdateSkyColor(CurrentTime) -- adjust ambient lighting color.
end)

-- log system initialization for debugging purposes.
AdvancedLogger("Advanced Aurora Borealis System Initialized", "DEBUG")

--[[
    toggles the visibility of the aurora when the user presses the T key.
    
    the toggle affects:
      - The transparency of each aurora segment (using tweenservice for smooth transitions).
      - The enabled state of each segment's light.
      - The transparency settings of each segment's ParticleEmitter.
    
]]
local AuroraVisible = true -- visible state
local AuroraTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) -- basic tween info for smooth transitions.

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if GameProcessed then
        return  -- exit if the input is already handled by roblox themselves.
    end

    if Input.KeyCode == Enum.KeyCode.T then -- check if the input is the 'T' keycode
        AuroraVisible = not AuroraVisible -- toggle the visibility state.
        
        -- loop over all bands and segments to update their visual properties.
        for _, Band in ipairs(_AuroraManager.Bands) do -- loop through each AuroraBand in the manager to get the band.
            for _, SegmentData in ipairs(Band.Segments) do -- loop through each segment of the current band and get their data.
                local TargetTransparency = AuroraVisible and 0.3 or 1 -- determine the target transparency based on whether Aurora is visible.  
                local TransparencyTween = TweenService:Create(SegmentData.Part, AuroraTweenInfo, {Transparency = TargetTransparency}) -- make a tween to smoothly transition the transparency.
                TransparencyTween:Play()
                
                -- directly enable/disable the light.
                SegmentData.Light.Enabled = AuroraVisible
                
                -- adjust the transparency of the particle effect dynamically.  
                local Emitter = SegmentData.Part:FindFirstChildOfClass("ParticleEmitter") -- locate the ParticleEmitter within the segment
                if Emitter then
                    Emitter.Transparency = NumberSequence.new({ -- assign a new transparency sequence, setting particles fully visible or hidden instantly.  
                        NumberSequenceKeypoint.new(0, AuroraVisible and 0 or 1),
                        NumberSequenceKeypoint.new(1, AuroraVisible and 0 or 1)
                    })
                end
            end
        end

        AdvancedLogger("Aurora visibility toggled: " .. tostring(AuroraVisible), "INFO") -- log message to inform update visibility state.
    end
end)

--[[
    resets all bands to their initial positions.
    useful for recalibration or restoring the system after significant changes.
]]
function AuroraManager:ResetAllBands()
    for _, Band in ipairs(self.Bands) do -- loop through each AuroraBand in the manager to get the band.
        Band:Reset() -- call the Reset method to reposition the band segments  
    end
	
    AdvancedLogger("All AuroraBands have been reset", "DEBUG") -- log the reset action for debugging purposes.  
end

--[[
    sets a new frequency for the moves of all bands.

    parameters:
      NewFrequency (number): the new frequency value, must be positive.
]]
function AuroraManager:SetGlobalFrequency(NewFrequency)
    assert(type(NewFrequency) == "number" and NewFrequency > 0, "Frequency must be a positive number") -- validate that the input is a positive number.
    
    for _, Band in ipairs(self.Bands) do -- loop through each AuroraBand and update its frequency property.
        Band.Frequency = NewFrequency
    end
	
    AdvancedLogger("Global frequency set to " .. NewFrequency, "INFO") -- log the frequency change for tracking and debugging purpose.
end

--[[
    sets a new amplitude for the moves of all bands.

    parameters:
      NewAmplitude (number): the new amplitude value; must be non-negative.
]]
function AuroraManager:SetGlobalAmplitude(NewAmplitude)
    assert(type(NewAmplitude) == "number" and NewAmplitude >= 0, "Amplitude must be non negative") -- validate that the input is a positive number.
    
    for _, Band in ipairs(self.Bands) do -- loop through each AuroraBand and update its amplitude property.
        Band.Amplitude = NewAmplitude
    end
	
    AdvancedLogger("Global amplitude set to " .. NewAmplitude, "INFO") -- log the amplitude change for tracking and debugging purpose.
end

--[[
    logs key parameters of each aurora band.
    this helps in debugging and verifying the current state of each band.
]]
function AuroraManager:PrintStatus()
    for i, Band in ipairs(self.Bands) do
        AdvancedLogger("Band " .. i .. " - Origin: " .. tostring(Band.Origin) .. ", Length: " .. Band.Length .. ", Frequency: " .. Band.Frequency .. ", Amplitude: " .. Band.Amplitude, "INFO")
    end
end

--[[
    safely cleans up the system by destroying all created objects.
    ensures that the folders and parts are removed from the game hierarchy.
]]
function AuroraManager:Shutdown()
    for _, Band in ipairs(self.Bands) do -- loop through all AuroraBands and check if their folder exists before destroying it.
        if Band.Folder and Band.Folder.Parent then
            Band.Folder:Destroy() -- remove the folder containing the band’s segments (if it exists).
        end
    end
	
    if self.Folder and self.Folder.Parent then -- check if the AuroraManager’s main folder exists before destroying it.
        self.Folder:Destroy() -- remove the container holding all bands (if it exists).
    end
	
    AdvancedLogger("AuroraManager shutdown completed", "INFO") -- log the shutdown process for debugging and tracking.
end

--[[
   temporarily boosts brightness and amplitude for a flash effect.
    
    parameters:
      Duration (number): how long the flash effect lasts (in seconds).
      ExtraBrightness (number): additional brightness to add to each segment’s light.
      ExtraAmplitude (number): additional amplitude to add for the moving effect.
    
    implementation details:
      - stores the original amplitude for each band.
      - increases the amplitude and brightness immediately.
      - uses task.delay to schedule the reset of values after the specified duration.
]]
function AuroraManager:TriggerAuroraFlash(Duration, ExtraBrightness, ExtraAmplitude)
    -- validate that inputs are valid positive numbers.
    assert(type(Duration) == "number" and Duration > 0, "Duration must be positive")
    assert(type(ExtraBrightness) == "number" and ExtraBrightness >= 0, "ExtraBrightness must be positive")
    assert(type(ExtraAmplitude) == "number" and ExtraAmplitude >= 0, "ExtraAmplitude must be positive")

    for _, Band in ipairs(self.Bands) do -- loop through all AuroraBands to apply the temporary effects.
        local OriginalAmplitude = Band.Amplitude -- store the original amplitude before modifying it for future use.
        Band.Amplitude = Band.Amplitude + ExtraAmplitude -- increase amplitude for a stronger wave effect.

        for _, Segment in ipairs(Band.Segments) do -- loop through all segment and increase the brightness of the light in the band.
            Segment.Light.Brightness = Segment.Light.Brightness + ExtraBrightness
        end
        
        task.delay(Duration, function() -- schedule a task to revert the changes after the specified duration.
            Band.Amplitude = OriginalAmplitude -- restore the original amplitude.
            for _, _Segment in ipairs(Band.Segments) do -- loop though each segment and reset their light's brightness.
                _Segment.Light.Brightness = _Segment.Light.Brightness - ExtraBrightness
            end
        end)
    end
	
    AdvancedLogger("Aurora flash effect triggered", "INFO") -- log that the flash effect was triggered successfully.
end

--[[
    updates the texture of all ParticleEmitters across all bands.

    parameters:
      NewTextureId (string): the asset ID string for the new texture.
]]
function AuroraManager:SetParticleTexture(NewTextureId)
    assert(type(NewTextureId) == "string" and NewTextureId ~= "", "NewTextureId must be a non empty string") -- validate the provided texture ID is a valid non empty string.

    for _, Band in ipairs(self.Bands) do -- loop through all AuroraBands.
        for _, Segment in ipairs(Band.Segments) do -- loop through all segments within each band.
            local Emitter = Segment.Part:FindFirstChildOfClass("ParticleEmitter") -- attempt to find a ParticleEmitter within the segment.
            if Emitter then
                Emitter.Texture = NewTextureId -- apply the new texture to the emitter.
            end
        end
    end
	
    AdvancedLogger("Particle texture updated to " .. NewTextureId, "INFO") -- log the texture update for debugging and tracking.
end

-- additional RunService connection to update lighting intensity each frame.
RunService.Heartbeat:Connect(function(DeltaTime)
    local CurrentTime = time() - StartTime -- calculate the passed time since the script started.
    UpdateSkyIntensity(CurrentTime) -- update the sky intensity based on the passed time.
end)
