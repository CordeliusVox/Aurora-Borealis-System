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
      ParentFolder (Folder): The manager folder to parent all sub folders into, for orginzation.	
      
    Returns:
      AuroraBand instance with its own segments, dynamic lights, and particle emitters.
]]
function AuroraBand.new(Origin, Length, SegmentCount, Amplitude, Frequency, BaseColor, FadeColor, ParentFolder)
	local self = setmetatable({}, AuroraBand)

	-- Store the configuration values for later use during updates.
	self.Origin = Origin or Vector3.new(0, 100, 0)
	self.Length = Length or 200
	self.SegmentCount = SegmentCount or 20
	self.Amplitude = Amplitude or 20
	self.Frequency = Frequency or 1
	self.BaseColor = BaseColor or Color3.fromRGB(0, 255, 150)
	self.FadeColor = FadeColor or Color3.fromRGB(50, 100, 255)
	self.Segments = {}  -- Will hold each segment's data (part and light reference)

	-- Create a folder in the workspace to keep all segments of this band organized.
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "AuroraBand"
	self.Folder.Parent = ParentFolder

	-- Create the segments that form the visual band.
	for i = 0, self.SegmentCount - 1 do
		-- Determine normalized position (t) along the band (0 at start, 1 at end)
		local t = i / (self.SegmentCount - 1)
		-- Compute the base position for this segment along the horizontal length.
		local Position = self.Origin + Vector3.new(self.Length * t, 0, 0)

		-- Create a neon part for the visual segment.
		local Segment = Instance.new("Part")
		Segment.Name = "AuroraSegment"
		Segment.Size = Vector3.new(self.Length / self.SegmentCount, 2, 20) -- Thin, wide segment
		Segment.Anchored = true -- We control it's position manually, it should not be affected by physics.
		Segment.CanCollide = false -- There is no need for collision for visual parts.
		Segment.CastShadow = false -- There is no need for shadows.
		Segment.Material = Enum.Material.Neon
		Segment.Transparency = 0.3 -- Partially transparent to blend with the sky.
		Segment.CFrame = CFrame.new(Position) -- Set initial position.
		Segment.Parent = self.Folder -- Parent it to our band folder for organization.

		-- Set the segment's color based on a gradient between BaseColor and FadeColor.
		local SegmentColor = self.BaseColor:Lerp(self.FadeColor, t)
		Segment.Color = SegmentColor

		-- Attach a PointLight to the segment for dynamic lighting.
		local _Light = Instance.new("PointLight")
		_Light.Color = SegmentColor
		_Light.Range = 30
		_Light.Brightness = 2
		_Light.Parent = Segment

		-- Attach a ParticleEmitter to create subtle particle effects. (Change these if you know what you're doing.)
		local Emitter = Instance.new("ParticleEmitter", Segment)
		Emitter.Texture = "rbxassetid://243098098"  -- Change this to your preferred texture asset.
		Emitter.Rate = 20
		Emitter.Lifetime = NumberRange.new(2, 3)
		Emitter.Speed = NumberRange.new(1, 3)
		Emitter.VelocitySpread = 180
		Emitter.LightInfluence = 1
		Emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})

		-- Save the segment's part and its light in our segments table.
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

		-- Find the position of the segment along the band.
		local t = (i - 1) / (self.SegmentCount - 1)
		-- Calculate vertical offset using a sine wave for smooth motion.
		local Wave = math.sin(Time * self.Frequency + t * math.pi * 2) * self.Amplitude
		-- Calculate a "slight" horizontal sway using cos, this adds complexity to the motion.
		local Sway = math.cos(Time * self.Frequency * 0.5 + t * math.pi) * 5
		-- The base position is calculated from the origin and the horizontal distribution.
		local BasePosition = self.Origin + Vector3.new(self.Length * t, 0, 0)
		-- Add the wave and sway to the base position to obtain the new target position.
		local NewPosition = BasePosition + Vector3.new(0, Wave, Sway)

		-- Smoothly transition the segment's position for visual stuff.
		-- Lerp between the current CFrame and the new target position.
		Part.CFrame = Part.CFrame:Lerp(CFrame.new(NewPosition) * CFrame.Angles(0, math.rad(90), 0), DeltaTime * 5)

		-- Compute a shifting factor for the color change based on time and segment position.
		local ColorShift = 0.5 + 0.5 * math.sin(Time + t * math.pi * 2)
		-- Interpolate the segment color between BaseColor and FadeColor.
		local NewColor = self.BaseColor:Lerp(self.FadeColor, ColorShift)
		Part.Color = NewColor
		Light.Color = NewColor -- Update the point light to match the segment's color.
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

	self.Bands = {}  -- Table to hold all created AuroraBand objects.

	-- Create a folder in workspace for the overall aurora system.
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "AuroraManager"
	self.Folder.Parent = workspace

	-- Create multiple AuroraBands with different configurations. (Can add ad many as u want)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(-80, 110, -60), 320, 26, 14, 1.3, Color3.fromRGB(0, 255, 200), Color3.fromRGB(100, 50, 255)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(-40, 135, 30), 280, 22, 12, 1.1, Color3.fromRGB(50, 255, 180), Color3.fromRGB(90, 40, 240)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(60, 120, -90), 350, 30, 10, 1.5, Color3.fromRGB(0, 255, 180), Color3.fromRGB(80, 20, 255)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(-100, 145, 70), 270, 24, 18, 1.0, Color3.fromRGB(20, 255, 220), Color3.fromRGB(110, 30, 230)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(50, 150, -50), 310, 27, 17, 1.25, Color3.fromRGB(10, 245, 200), Color3.fromRGB(140, 50, 255)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(-70, 140, 20), 360, 32, 13, 1.6, Color3.fromRGB(0, 255, 190), Color3.fromRGB(70, 20, 250)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(20, 160, -10), 290, 23, 19, 1.05, Color3.fromRGB(5, 255, 210), Color3.fromRGB(100, 35, 240)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(-30, 125, 90), 280, 21, 13, 1.1, Color3.fromRGB(0, 220, 210), Color3.fromRGB(90, 30, 240)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(90, 135, -70), 260, 19, 15, 0.9, Color3.fromRGB(10, 240, 190), Color3.fromRGB(110, 25, 230)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(-50, 130, -30), 300, 25, 12, 1.3, Color3.fromRGB(0, 235, 205), Color3.fromRGB(80, 20, 255)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(30, 145, 40), 330, 28, 14, 1.4, Color3.fromRGB(0, 250, 180), Color3.fromRGB(130, 40, 255)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(-90, 120, 10), 290, 22, 11, 1.2, Color3.fromRGB(5, 255, 190), Color3.fromRGB(95, 35, 250)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(10, 150, -80), 340, 28, 16, 1.4, Color3.fromRGB(0, 230, 255), Color3.fromRGB(130, 60, 255)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(-60, 155, 50), 250, 20, 20, 0.8, Color3.fromRGB(0, 200, 255), Color3.fromRGB(150, 0, 255)), self.Folder)
	table.insert(self.Bands, AuroraBand.new(Vector3.new(70, 125, -40), 320, 26, 14, 1.3, Color3.fromRGB(0, 180, 255), Color3.fromRGB(120, 10, 250)), self.Folder)

	return self
end

--[[
    Calls the update function for each AuroraBand managed by the AuroraManager.
    This maintains the update logic for all aurora bands.
    
    Parameters:
      DeltaTime (number): Delta time since the last update.
      time (number): Passed time used to drive the dynamic motion.
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
	-- Define two base ambient colors: one for a darker, night like mood and one slightly brighter.
	local DayColor = Color3.fromRGB(20, 20, 60)
	local NightColor = Color3.fromRGB(5, 5, 20)
	-- Use a sine wave to smoothly transition between these two colors over time.
	local Factor = 0.5 + 0.5 * math.sin(Time * 0.1)
	-- Lerp between dayColor and nightColor to get the current ambient color.
	Lighting.Ambient = DayColor:Lerp(NightColor, Factor)
	Lighting.OutdoorAmbient = Lighting.Ambient -- Apply the same color to outdoor ambient lighting.
end

--// Main script setup and loop.

-- Create the AuroraManager instance which spawns several aurora bands.
local _AuroraManager = AuroraManager.new()

-- Store the start time for the update calculations.
local StartTime = tick()

-- Main update loop using RunService.Heartbeat for per frame updates.
RunService.Heartbeat:Connect(function(DeltaTime)
	local CurrentTime = tick() - StartTime -- Calculate passed time.
	-- Update all aurora bands based on delta time and passed time.
	_AuroraManager:Update(DeltaTime, CurrentTime)
	-- Update the sky ambient colors to somewhat enhance the aurora mood.
	UpdateSkyColor(CurrentTime)
end)

AdvancedLogger("Advanced Aurora Borealis System Initialized", "DEBUG")

--[[
	Interactive Feature: Toggle Aurora Visibility
	Pressing the 'T' key toggles the transparency and light enabled state for all segments.
]]--
local AuroraVisible = true  -- Initial visibility state

-- Listen for key press events using UserInputService.
UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	if GameProcessed then -- Ignore if the game already processed the input.
		return 
	end

	if Input.KeyCode == Enum.KeyCode.T then
		AuroraVisible = not AuroraVisible  -- Toggle the visibility flag.
		-- Loop through all aurora bands and their segments to update transparency and lighting.
		for _, Band in ipairs(_AuroraManager.Bands) do
			for _, SegmentData in ipairs(Band.Segments) do
				-- When invisible, set transparency to full (1) and disable light.
				SegmentData.Part.Transparency = AuroraVisible and 0.3 or 1
				SegmentData.Light.Enabled = AuroraVisible
			end
    end
		AdvancedLogger("Aurora visibility toggled: " .. tostring(AuroraVisible), "INFO")
	end
end)
