--[[
        Advanced Aurora Borealis System.
        This script creates a dynamic aurora effect using neon parts, sine wave motion, dynamic lighting, and particle emitters.
        
        Made by @CordeliusVox
        Date: 14/02/2025
]]--

--// Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

--[[
        advanced Logger Function simply for debugging purposes.
        provides detailed logging with time stamps and log levels.
]]
local function AdvancedLogger(Message, Level)
        Level = Level or "INFO" -- Use a default log level if none is provided.
        print("[" .. Level .. "][" .. os.date("%X") .. "]: " .. Message) -- Concatenates the log level and the current time (formatted using os.date) with the message.
end

--[[
        this class represents a single band of the aurora.
]]--
local AuroraBand = {}
AuroraBand.__index = AuroraBand

--[[
    the function creates an instance (a table) and sets up its properties.

    parameters:
      Origin (Vector3): The starting point of the aurora band in the world.
      Length (number): The horizontal length over which segments are distributed.
      SegmentCount (number): Number of segments to divide the band into.
      Amplitude (number): Maximum vertical displacement for the sine wave motion.
      Frequency (number): Speed factor for the sine wave oscillation.
      BaseColor (Color3): The starting color for the aurora gradient.
      FadeColor (Color3): The ending color for the aurora gradient.
      ParentFolder (Folder): The manager folder to parent all sub folders into, for organization.

    returns:
      AuroraBand instance with its own segments, dynamic lights, and particle emitters.
]]
function AuroraBand.new(Origin, Length, SegmentCount, Amplitude, Frequency, BaseColor, FadeColor, ParentFolder)
	-- type and value assertions guarantee that the function receives valid parameters.
        assert(typeof(Origin) == "Vector3", "Origin must be a Vector3")
        assert(type(Length) == "number" and Length > 0, "Length must be a positive number")
        assert(type(SegmentCount) == "number" and SegmentCount >= 2, "SegmentCount must be at least 2")
        assert(type(Amplitude) == "number" and Amplitude >= 0, "Amplitude must be non negative")
        assert(type(Frequency) == "number" and Frequency > 0, "Frequency must be positive")
        assert(typeof(BaseColor) == "Color3", "BaseColor must be a Color3")
        assert(typeof(FadeColor) == "Color3", "FadeColor must be a Color3")
        assert(typeof(ParentFolder) == "Instance" and ParentFolder:IsA("Folder"), "ParentFolder must be a Folder instance")

        local self = setmetatable({}, AuroraBand)

        -- use provided values or defaults (via 'or') for instance properties.
        self.Origin = Origin or Vector3.new(0, 100, 0)
        self.Length = Length or 200
        self.SegmentCount = SegmentCount or 20
        self.Amplitude = Amplitude or 20
        self.Frequency = Frequency or 1
        self.BaseColor = BaseColor or Color3.fromRGB(0, 255, 150)
        self.FadeColor = FadeColor or Color3.fromRGB(50, 100, 255)
        self.Segments = {}  -- table to hold each segment and its associated properties.

        -- create a Folder to organize all parts of this aurora band in the hierarchy.
        self.Folder = Instance.new("Folder")
        self.Folder.Name = "AuroraBand"
        self.Folder.Parent = ParentFolder

        -- loop to create each segment in the band.
        for i = 0, self.SegmentCount - 1 do
                local t = i / (self.SegmentCount - 1) -- 't' is a normalized value (0 - 1) representing the segment's position along the band.
                local Position = self.Origin + Vector3.new(self.Length * t, 0, 0) -- Calculate a base position along the horizontal axis.

                -- create a new Part instance for this segment.
                local Segment = Instance.new("Part")
                Segment.Name = "AuroraSegment"
                Segment.Size = Vector3.new(self.Length / self.SegmentCount, 2, 20) -- calculate width based on total length divided by the number of segments.
                Segment.Anchored = true -- ensures the part does not move due to physics.
                Segment.CanCollide = false -- disables collision to prevent interference with other objects.
                Segment.CastShadow = false -- optimize performance by disabling shadow casting.
                Segment.Material = Enum.Material.Neon -- using a neon material to emphasize brightness.
                Segment.Transparency = 0.3 -- set initial transparency for a blended effect.
                Segment.CFrame = CFrame.new(Position) -- position the segment using a CFrame from the calculated Position.
                Segment.Parent = self.Folder -- parent the segment to the band folder for organization.

                -- calculate a color using the normalized position 't'.
                local SegmentColor = self.BaseColor:Lerp(self.FadeColor, t)
                Segment.Color = SegmentColor -- Apply the color to the segment.

                -- create a PointLight to provide lighting.
                local _Light = Instance.new("PointLight")
                _Light.Color = SegmentColor
                _Light.Range = 30
                _Light.Brightness = 2
                _Light.Parent = Segment -- parent the light to the segment so it moves with the part.

                -- create a ParticleEmitter inside the segment.
                local Emitter = Instance.new("ParticleEmitter", Segment)
                Emitter.Texture = "rbxassetid://243098098"
                Emitter.Rate = 20
                Emitter.Lifetime = NumberRange.new(2, 3)
                Emitter.Speed = NumberRange.new(1, 3)
                Emitter.VelocitySpread = 180
                Emitter.LightInfluence = 1
                Emitter.Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 2),
                        NumberSequenceKeypoint.new(1, 0)
                })

                -- store a reference to both the Part and its Light in the Segments table.
                table.insert(self.Segments, {Part = Segment, Light = _Light})
        end

        -- return the newly constructed AuroraBand instance.
        return self
end

--[[
    loop over each segment and computes new positions and colors.
]]
function AuroraBand:Update(DeltaTime, Time)
        -- loop through each stored segment.
        for i, SegmentData in ipairs(self.Segments) do
                local Part = SegmentData.Part
                local Light = SegmentData.Light

                local t = (i - 1) / (self.SegmentCount - 1) -- calculate a position for the current segment.
                local Wave = math.sin(Time * self.Frequency + t * math.pi * 2) * self.Amplitude  -- calculate a sine wave value, with its shift based on time (t).
                local Sway = math.cos(Time * self.Frequency * 0.5 + t * math.pi) * 5 -- calculate an additional cos based sway for lateral movement.
                local BasePosition = self.Origin + Vector3.new(self.Length * t, 0, 0) -- base position along the horizontal axis.
                local NewPosition = BasePosition + Vector3.new(0, Wave, Sway) -- combine the base position with vertical and lateral offsets.

                -- smoothy lerp from the current CFrame to the target position and fixed rotation.
                Part.CFrame = Part.CFrame:Lerp(CFrame.new(NewPosition) * CFrame.Angles(0, math.rad(90), 0), DeltaTime * 5)

                local ColorShift = 0.5 + 0.5 * math.sin(Time + t * math.pi * 2) -- calculate a shift value based on a sine wave to create smooth color transitions.
                local NewColor = self.BaseColor:Lerp(self.FadeColor, ColorShift) -- lerp between BaseColor and FadeColor using the ColorShift factor.
                -- Update both the part and the light with the new color.
                Part.Color = NewColor
                Light.Color = NewColor
        end
end

--[[
        AuroraManager class serves as a container for multiple AuroraBand instances.
        It organizes these bands and provides centralized update, reset, and configuration functions.
]]--
local AuroraManager = {}
AuroraManager.__index = AuroraManager

function AuroraManager.new()
        local self = setmetatable({}, AuroraManager)

        self.Bands = {}  -- container for all AuroraBand instances.

        -- create a Folder to group all aurora bands in the workspace hierarchy.
        self.Folder = Instance.new("Folder")
        self.Folder.Name = "AuroraManager"
        self.Folder.Parent = workspace

        -- each call to AuroraBand.new constructs a band with its own unique parameters.
        -- The parameters determine how segments are distributed, their wave properties, and color.
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

        -- return the manager instance which now contains multiple bands.
        return self
end

--[[
    simply delegates the update call to each individual AuroraBand.
    this design abstracts the multiple bands behind a single update loop.
]]
function AuroraManager:Update(DeltaTime, Time)
        for _, Band in ipairs(self.Bands) do
                Band:Update(DeltaTime, Time) -- each band manages its own update calculations.
        end
end

--[[
        calculates an interpolation factor based on time using a sine function.
        then uses this factor to interpolate between two ambient colors.
        the resulting color is assigned to the Lighting properties.
]]
local function UpdateSkyColor(Time)
        local DayColor = Color3.fromRGB(20, 20, 60)
        local NightColor = Color3.fromRGB(5, 5, 20)
	
        local Factor = 0.5 + 0.5 * math.sin(Time * 0.1) -- factor smoothly between 0 and 1 using sine.
	
        Lighting.Ambient = DayColor:Lerp(NightColor, Factor) -- use lerp to compute the intermediate color.
        Lighting.OutdoorAmbient = Lighting.Ambient -- keep both lighting properties in sync.
end

--// main script setup and loop.
local _AuroraManager = AuroraManager.new() -- instantiate the manager which creates all bands.
local StartTime = tick() -- record the start time to calculate passed time for animations.

-- connect a function to the RunService.Heartbeat event for frame updates.
RunService.Heartbeat:Connect(function(DeltaTime)
        local CurrentTime = tick() - StartTime -- calculate the passed time since the start.
		
        _AuroraManager:Update(DeltaTime, CurrentTime) -- delegate the per frame update to the AuroraManager, which in turn updates all bands.
        UpdateSkyColor(CurrentTime) -- Update lighting parameters based on passed time.
end)

-- log system initialization with debug details.
AdvancedLogger("Advanced Aurora Borealis System Initialized", "DEBUG")

--[[
        listens for input events to dynamically change the visibility state.
]]
local AuroraVisible = true -- state flag to keep track of visibility.
local AuroraTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) -- tween settings for smooth transitions.

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if GameProcessed then
                return  -- exit if the input is already processed by the game.
        end

        if Input.KeyCode == Enum.KeyCode.T then
                AuroraVisible = not AuroraVisible -- toggle the visibility state.

                -- loop through every band and then through each segment in the band.
                for _, Band in ipairs(_AuroraManager.Bands) do
                        for _, SegmentData in ipairs(Band.Segments) do
                                local TransparencyTween = TweenService:Create(SegmentData.Part, AuroraTweenInfo, {Transparency = AuroraVisible and 0.3 or 1}) -- create a tween for the part's Transparency property.
                                TransparencyTween:Play()  -- start the tween animation.
                                SegmentData.Light.Enabled = AuroraVisible -- directly enable or disable the light based on the toggled state.
                                SegmentData.Part.ParticleEmitter.Transparency = NumberSequence.new({ -- adjust the ParticleEmitter's Transparency using a NumberSequence.
                                        NumberSequenceKeypoint.new(0, AuroraVisible and 0 or 1),
                                        NumberSequenceKeypoint.new(1, AuroraVisible and 0 or 1)
                                })
                        end
                end

                -- log the change with the new state.
                AdvancedLogger("Aurora visibility toggled: " .. tostring(AuroraVisible), "INFO")
        end
end)

--[[
        resets each segment's position to its initial calculated base position.
]]
function AuroraBand:Reset()
        for i, SegmentData in ipairs(self.Segments) do
                local t = (i - 1) / (self.SegmentCount - 1)
                local BasePosition = self.Origin + Vector3.new(self.Length * t, 0, 0)
		
                SegmentData.Part.CFrame = CFrame.new(BasePosition) * CFrame.Angles(0, math.rad(90), 0) -- reset the CFrame to the base position with a fixed rotation.
        end
        AdvancedLogger("AuroraBand reset to initial positions", "DEBUG")
end

--[[
        resets all aurora bands by looping through each one and calling its Reset method.
]]
function AuroraManager:ResetAllBands()
        for _, Band in ipairs(self.Bands) do
                Band:Reset()
        end
        AdvancedLogger("All AuroraBands have been reset", "DEBUG")
end

--[[
        sets a new global frequency by looping through all bands.
]]
function AuroraManager:SetGlobalFrequency(NewFrequency)
        assert(type(NewFrequency) == "number" and NewFrequency > 0, "Frequency must be a positive number") -- ensure new frequency is a positive number.
	
        for _, band in ipairs(self.Bands) do
                band.Frequency = NewFrequency -- directly assign the new frequency value to each band.
        end
        AdvancedLogger("Global frequency set to " .. NewFrequency, "INFO")
end

--[[
        sets a new global amplitude for all bands.
]]
function AuroraManager:SetGlobalAmplitude(NewAmplitude)
        assert(type(NewAmplitude) == "number" and NewAmplitude >= 0, "Amplitude must be non negative") -- ensures NewAmplitude is non negetive.
	
        for _, Band in ipairs(self.Bands) do
                Band.Amplitude = NewAmplitude
        end
        AdvancedLogger("Global amplitude set to " .. NewAmplitude, "INFO")
end

--[[
        logs the current status of each aurora band.
]]
function AuroraManager:PrintStatus()
        for i, Band in ipairs(self.Bands) do -- loop through bands and pass their key parameters into a log message.
                AdvancedLogger("Band " .. i .. " - Origin: " .. tostring(Band.Origin) .. ", Length: " .. Band.Length .. ", Frequency: " .. Band.Frequency .. ", Amplitude: " .. Band.Amplitude, "INFO")
        end
end

--[[
        clean up function that iterates through each band and destroys its Folder.
        Also destroys the manager's Folder, ensuring all created objects are removed.
]]
function AuroraManager:Shutdown()
        for _, Band in ipairs(self.Bands) do
                if Band.Folder and Band.Folder.Parent then
                        Band.Folder:Destroy()
                end
        end
        if self.Folder and self.Folder.Parent then
                self.Folder:Destroy()
        end
        AdvancedLogger("AuroraManager shutdown completed", "INFO")
end

--[[
        temporarily boosts the brightness and amplitude of the aurora effect.
        for each band, the current amplitude is stored, then incremented.
        a delay function schedules a callback to reset the values after the specified duration.
]]
function AuroraManager:TriggerAuroraFlash(Duration, ExtraBrightness, ExtraAmplitude)
        assert(type(Duration) == "number" and Duration > 0, "Duration must be positive")
        assert(type(ExtraBrightness) == "number" and ExtraBrightness >= 0, "ExtraBrightness must be non negative")
        assert(type(ExtraAmplitude) == "number" and ExtraAmplitude >= 0, "ExtraAmplitude must be non negative")

        for _, Band in ipairs(self.Bands) do
                local OriginalAmplitude = Band.Amplitude
                Band.Amplitude = Band.Amplitude + ExtraAmplitude -- increase the amplitude for a flash effect.

                for _, Segment in ipairs(Band.Segments) do
                        Segment.Light.Brightness = Segment.Light.Brightness + ExtraBrightness -- increase the brightness of the light attached to the segment.
                end
                
                delay(Duration, function() -- schedule a delayed function to restore original values.
                        Band.Amplitude = OriginalAmplitude
                        for _, _Segment in ipairs(Band.Segments) do
                                _Segment.Light.Brightness = _Segment.Light.Brightness - ExtraBrightness
                        end
                        AdvancedLogger("Aurora flash effect ended for a band", "DEBUG")
                end)
        end
        AdvancedLogger("Aurora flash effect triggered", "INFO")
end

--[[
        loops over each segment and changes the texture of its ParticleEmitter.
]]
function AuroraManager:SetParticleTexture(NewTextureId)
        assert(type(NewTextureId) == "string" and NewTextureId ~= "", "NewTextureId must be a non empty string")

        for _, Band in ipairs(self.Bands) do
                for _, Segment in ipairs(Band.Segments) do
                        local Emitter = Segment.Part:FindFirstChildOfClass("ParticleEmitter")
                        if Emitter then
                                Emitter.Texture = NewTextureId  -- direct assignment changes the particle texture.
                        end
                end
        end
        AdvancedLogger("Particle texture updated to " .. NewTextureId, "INFO")
end

--[[
        adjusts the brightness of the global lighting.
        calculates a variation based on a sine function and adds it to a base intensity.
]]
local function UpdateSkyIntensity(Time)
        local BaseIntensity = 0.2
        local Variation = 0.1 * math.sin(Time * 0.5)
        Lighting.Brightness = BaseIntensity + Variation
end

-- additional RunService connection that updates the lighting intensity on every heartbeat.
RunService.Heartbeat:Connect(function(DeltaTime)
        local CurrentTime = tick() - StartTime
        UpdateSkyIntensity(CurrentTime)
end)
