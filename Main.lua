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
        Advanced Logger Function simply for debugging purposes.
        Provides detailed logging with time stamps and log levels.
]]--
local function AdvancedLogger(Message, Level)
        Level = Level or "INFO"
        print("[" .. Level .. "][" .. os.date("%X") .. "]: " .. Message)
end

--[[
        This class represents a single band of the aurora. Each band is composed of multiple segments that wave in the sky.
]]--
local AuroraBand = {}
AuroraBand.__index = AuroraBand

--[[
    Creates a new AuroraBand instance.
    
    Parameters:
      Origin (Vector3): The starting point of the aurora band in the world.
      Length (number): The horizontal length over which segments are distributed.
      SegmentCount (number): Number of segments to divide the band into.
      Amplitude (number): Maximum vertical displacement for the sine wave motion.
      Frequency (number): Speed factor for the sine wave oscillation.
      BaseColor (Color3): The starting color for the aurora gradient.
      FadeColor (Color3): The ending color for the aurora gradient.
      ParentFolder (Folder): The manager folder to parent all sub folders into, for organization.
      
    Returns:
      AuroraBand instance with its own segments, dynamic lights, and particle emitters.
]]--
function AuroraBand.new(Origin, Length, SegmentCount, Amplitude, Frequency, BaseColor, FadeColor, ParentFolder)
        assert(typeof(Origin) == "Vector3", "Origin must be a Vector3")
        assert(type(Length) == "number" and Length > 0, "Length must be a positive number")
        assert(type(SegmentCount) == "number" and SegmentCount >= 2, "SegmentCount must be at least 2")
        assert(type(Amplitude) == "number" and Amplitude >= 0, "Amplitude must be non negative")
        assert(type(Frequency) == "number" and Frequency > 0, "Frequency must be positive")
        assert(typeof(BaseColor) == "Color3", "BaseColor must be a Color3")
        assert(typeof(FadeColor) == "Color3", "FadeColor must be a Color3")
        assert(typeof(ParentFolder) == "Instance" and ParentFolder:IsA("Folder"), "ParentFolder must be a Folder instance")
        
        local self = setmetatable({}, AuroraBand)

        self.Origin = Origin or Vector3.new(0, 100, 0)
        self.Length = Length or 200
        self.SegmentCount = SegmentCount or 20
        self.Amplitude = Amplitude or 20
        self.Frequency = Frequency or 1
        self.BaseColor = BaseColor or Color3.fromRGB(0, 255, 150)
        self.FadeColor = FadeColor or Color3.fromRGB(50, 100, 255)
        self.Segments = {}

        self.Folder = Instance.new("Folder")
        self.Folder.Name = "AuroraBand"
        self.Folder.Parent = ParentFolder

        for i = 0, self.SegmentCount - 1 do
                local t = i / (self.SegmentCount - 1)
                local Position = self.Origin + Vector3.new(self.Length * t, 0, 0)

                local Segment = Instance.new("Part")
                Segment.Name = "AuroraSegment"
                Segment.Size = Vector3.new(self.Length / self.SegmentCount, 2, 20)
                Segment.Anchored = true
                Segment.CanCollide = false
                Segment.CastShadow = false
                Segment.Material = Enum.Material.Neon
                Segment.Transparency = 0.3
                Segment.CFrame = CFrame.new(Position)
                Segment.Parent = self.Folder

                local SegmentColor = self.BaseColor:Lerp(self.FadeColor, t)
                Segment.Color = SegmentColor

                local _Light = Instance.new("PointLight")
                _Light.Color = SegmentColor
                _Light.Range = 30
                _Light.Brightness = 2
                _Light.Parent = Segment

                local Emitter = Instance.new("ParticleEmitter", Segment)
                Emitter.Texture = "rbxassetid://243098098"
                Emitter.Rate = 20
                Emitter.Lifetime = NumberRange.new(2, 3)
                Emitter.Speed = NumberRange.new(1, 3)
                Emitter.VelocitySpread = 180
                Emitter.LightInfluence = 1
                Emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})

                table.insert(self.Segments, {Part = Segment, Light = _Light})
        end

        return self
end

--[[
    Updates the position and color of each segment in the band to create a dynamic,
    wavy aurora effect. The update is based on sine and cosine functions to simulate natural motion.
    
    Parameters:
      DeltaTime (number): Delta time since the last update.
      Time (number): The elapsed time, used to drive the wave motion.
]]
function AuroraBand:Update(DeltaTime, Time)
        for i, SegmentData in ipairs(self.Segments) do
                local Part = SegmentData.Part
                local Light = SegmentData.Light

                local t = (i - 1) / (self.SegmentCount - 1)
                local Wave = math.sin(Time * self.Frequency + t * math.pi * 2) * self.Amplitude
                local Sway = math.cos(Time * self.Frequency * 0.5 + t * math.pi) * 5
                local BasePosition = self.Origin + Vector3.new(self.Length * t, 0, 0)
                local NewPosition = BasePosition + Vector3.new(0, Wave, Sway)

                Part.CFrame = Part.CFrame:Lerp(CFrame.new(NewPosition) * CFrame.Angles(0, math.rad(90), 0), DeltaTime * 5)

                local ColorShift = 0.5 + 0.5 * math.sin(Time + t * math.pi * 2)
                local NewColor = self.BaseColor:Lerp(self.FadeColor, ColorShift)
                Part.Color = NewColor
                Light.Color = NewColor
        end
end

--[[
        This class manages multiple AuroraBand instances to create a richer aurora display.
]]--
local AuroraManager = {}
AuroraManager.__index = AuroraManager

--[[
    Initializes the AuroraManager which creates several AuroraBand instances,
    each with different parameters to produce a layered and varied aurora effect.
    
    Returns:
      AuroraManager instance containing a list of bands.
]]
function AuroraManager.new()
        local self = setmetatable({}, AuroraManager)

        self.Bands = {}

        self.Folder = Instance.new("Folder")
        self.Folder.Name = "AuroraManager"
        self.Folder.Parent = workspace

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
    Calls the update function for each AuroraBand managed by the AuroraManager.
    This maintains the update logic for all aurora bands.
    
    Parameters:
      DeltaTime (number): Delta time since the last update.
      Time (number): Passed time used to drive the dynamic motion.
]]
function AuroraManager:Update(DeltaTime, Time)
        for _, Band in ipairs(self.Bands) do
                Band:Update(DeltaTime, Time)
        end
end

--[[
        Sky and Lighting Enhancement Function
        This function dynamically adjusts the sky's ambient colors based on the aurora's mood.
]]--
local function UpdateSkyColor(Time)
        local DayColor = Color3.fromRGB(20, 20, 60)
        local NightColor = Color3.fromRGB(5, 5, 20)
        local Factor = 0.5 + 0.5 * math.sin(Time * 0.1)
        Lighting.Ambient = DayColor:Lerp(NightColor, Factor)
        Lighting.OutdoorAmbient = Lighting.Ambient
end

--// Main script setup and loop.

local _AuroraManager = AuroraManager.new()
local StartTime = tick()

RunService.Heartbeat:Connect(function(DeltaTime)
        local CurrentTime = tick() - StartTime
        _AuroraManager:Update(DeltaTime, CurrentTime)
        UpdateSkyColor(CurrentTime)
end)

AdvancedLogger("Advanced Aurora Borealis System Initialized", "DEBUG")

--[[
        Interactive Feature: Toggle Aurora Visibility
        Pressing the 'T' key toggles the transparency and light enabled state for all segments.
]]--
local AuroraVisible = true
local AuroraTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if GameProcessed then
                return 
        end

        if Input.KeyCode == Enum.KeyCode.T then
                AuroraVisible = not AuroraVisible

                for _, Band in ipairs(_AuroraManager.Bands) do
                        for _, SegmentData in ipairs(Band.Segments) do
                                local TransparencyTween = TweenService:Create(SegmentData.Part, AuroraTweenInfo, {Transparency = AuroraVisible and 0.3 or 1})
                                TransparencyTween:Play()
                                SegmentData.Light.Enabled = AuroraVisible
                                SegmentData.Part.ParticleEmitter.Transparency = NumberSequence.new({
                                        NumberSequenceKeypoint.new(0, AuroraVisible and 0 or 1),
                                        NumberSequenceKeypoint.new(1, AuroraVisible and 0 or 1)
                                })
                        end
                end

                AdvancedLogger("Aurora visibility toggled: " .. tostring(AuroraVisible), "INFO")
        end
end)

--[[
	Resets each segment's position to its initial base position.
]]--
function AuroraBand:Reset()
        for i, SegmentData in ipairs(self.Segments) do
                local t = (i - 1) / (self.SegmentCount - 1)
                local BasePosition = self.Origin + Vector3.new(self.Length * t, 0, 0)
                SegmentData.Part.CFrame = CFrame.new(BasePosition) * CFrame.Angles(0, math.rad(90), 0)
        end
        AdvancedLogger("AuroraBand reset to initial positions", "DEBUG")
end

--[[
	Resets all aurora bands to their initial states.
]]--
function AuroraManager:ResetAllBands()
        for _, Band in ipairs(self.Bands) do
                Band:Reset()
        end
        AdvancedLogger("All AuroraBands have been reset", "DEBUG")
end

--[[
	Sets a new frequency for all bands.
]]--
function AuroraManager:SetGlobalFrequency(NewFrequency)
        assert(type(NewFrequency) == "number" and newFrequency > 0, "Frequency must be a positive number")
        for _, band in ipairs(self.Bands) do
                band.Frequency = NewFrequency
        end
        AdvancedLogger("Global frequency set to " .. NewFrequency, "INFO")
end

--[[
	Sets a new amplitude for all bands.
]]--
function AuroraManager:SetGlobalAmplitude(NewAmplitude)
        assert(type(newAmplitude) == "number" and NewAmplitude >= 0, "Amplitude must be non negative")
        for _, band in ipairs(self.Bands) do
                band.Amplitude = NewAmplitude
        end
        AdvancedLogger("Global amplitude set to " .. NewAmplitude, "INFO")
end

--[[
	Logs the status of each aurora band.
]]--
function AuroraManager:PrintStatus()
        for i, Band in ipairs(self.Bands) do
                AdvancedLogger("Band " .. i .. " - Origin: " .. tostring(Band.Origin) .. ", Length: " .. Band.Length .. ", Frequency: " .. Band.Frequency .. ", Amplitude: " .. Band.Amplitude, "INFO")
        end
end

--[[
	Cleans up the aurora system by destroying all created folders and parts.
]]--
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
	Temporarily boosts the brightness and amplitude of the aurora effect.
]]--
function AuroraManager:TriggerAuroraFlash(Duration, ExtraBrightness, ExtraAmplitude)
        assert(type(duration) == "number" and Duration > 0, "Duration must be positive")
        assert(type(extraBrightness) == "number" and ExtraBrightness >= 0, "ExtraBrightness must be non negative")
        assert(type(extraAmplitude) == "number" and ExtraAmplitude >= 0, "ExtraAmplitude must be non negative")
	
        for _, Band in ipairs(self.Bands) do
                local OriginalAmplitude = Band.Amplitude
                Band.Amplitude = Band.Amplitude + ExtraAmplitude
		
                for _, Segment in ipairs(Band.Segments) do
                        Segment.Light.Brightness = Segment.Light.Brightness + ExtraBrightness
                end
                delay(Duration, function()
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
	Changes the particle emitter texture for all segments.
]]--
function AuroraManager:SetParticleTexture(NewTextureId)
        assert(type(NewTextureId) == "string" and newTextureId ~= "", "NewTextureId must be a non empty string")
	
        for _, Band in ipairs(self.Bands) do
                for _, Segment in ipairs(Band.Segments) do
                        local Emitter = Segment.Part:FindFirstChildOfClass("ParticleEmitter")
                        if Emitter then
                                Emitter.Texture = NewTextureId
                        end
                end
        end
        AdvancedLogger("Particle texture updated to " .. NewTextureId, "INFO")
end

--[[
	Dynamically adjusts the brightness of the lighting.
]]--
local function UpdateSkyIntensity(Time)
        local BaseIntensity = 0.2
        local Variation = 0.1 * math.sin(Time * 0.5)
        Lighting.Brightness = BaseIntensity + Variation
end

-- Additional RunService connection to update sky intensity.
RunService.Heartbeat:Connect(function(DeltaTime)
        local CurrentTime = tick() - StartTime
        UpdateSkyIntensity(CurrentTime)
end)
