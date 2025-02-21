# Aurora Borealis System

A aurora effect script for Roblox that leverages neon parts, sine wave motion, lighting, and particle emitters to create a visually stunning and immersive aurora borealis effect.

**Made by:** @CordeliusVox  
**Date:** 14/02/2025

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)

---

## Overview

The **Aurora Borealis System** script creates a ever changing aurora effect in your Roblox game. It uses multiple AuroraBands, each composed of neon parts with particle emitters and point lights to simulate natural aurora movement and color transitions. The system is managed centrally by an AuroraManager that provides functionality for real time updates, resetting, toggling visibility, and even triggering flash effects.

---

## Features

- **Dynamic Aurora Bands:** Generates multiple aurora bands with adjustable properties such as length, segment count, amplitude, and frequency.
- **Smooth Sine Wave Motion:** Utilizes sine and cosine functions to animate vertical and lateral movement.
- **Color Gradients & Transitions:** Implements smooth color interpolation between two defined colors.
- **Dynamic Lighting:** Each segment features a point light that updates in tandem with color changes.
- **Particle Emitters:** Enhances visual effect with particle emitters attached to each segment.
- **Advanced Logging:** A built in logger function that prints detailed debug information with timestamps and log levels.
- **Input Handling:** Toggles visibility and animation states using keyboard input.
- **Utility Functions:** Includes functions to reset positions, update global frequency/amplitude, and trigger temporary flash effects.
- **Environmental Lighting Control:** Adjusts both ambient and outdoor lighting to simulate sky color changes and brightness variations.

---

## Installation

1. **Open Roblox Studio.**
2. **Insert a local script:** Create a new local script inside your desired location (StarterPlayerScripts, StarterCharacterScripts, e.g).
3. **Copy & Paste:** Copy the entire Aurora Borealis System script into your script.
4. **Organize Assets:** The script will automatically create Folders for organizing AuroraBands. No further setup is required.
5. **Test:** Run your game to see the dynamic aurora effect in action.

---

## Usage

- **Start Animation:** The script automatically initializes and updates the aurora effect on game start.
- **Toggle Visibility:** Press the `T` key to toggle the visibility of the aurora effect.
- **Dynamic Updates:** The AuroraManager continuously updates each aurora band with frame by frame calculations, adjusting positions, colors, and lighting.
- **Flash Effects:** Use the `TriggerAuroraFlash(Duration, ExtraBrightness, ExtraAmplitude)` function to temporarily boost brightness and amplitude.
- **Reset & Adjust:** Utilize functions like `ResetAllBands()`, `SetGlobalFrequency(NewFrequency)`, and `SetGlobalAmplitude(NewAmplitude)` to modify the effect during runtime.

---

## Customization

- **Adjusting Band Properties:** Modify the parameters passed to AuroraBand.new (such as amplitude, frequency, or colors) to tune the visual effect.
- **Lighting and Particle Effects:** Customize point light properties and particle emitter settings to achieve a unique aurora look.
- **Key Bindings:** Change the input key in the UserInputService connection if you want to use a different key for toggling visibility.
