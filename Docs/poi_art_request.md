# 🎨 Art Request: POI System Sprites

## Overview
The POI system currently uses **placeholder polygon shapes**. These need to be replaced with proper 16x16 or 32x32 pixel art sprites to match the game's visual style.

---

## Sprites Needed

### 1. Challenge Shrine
| Property | Value |
|----------|-------|
| **Size** | 32x32 or 48x48 pixels |
| **Style** | Mystical stone pillar with glowing crystal on top |
| **Colors** | Blue/cyan glow, stone gray base |
| **Animation** | Optional: 2-4 frame glow pulse |
| **Save To** | `res://Textures/poi/challenge_shrine.png` |

**Description:**
A small stone obelisk or pillar with a magical crystal floating above it. The crystal should emit a cyan/blue glow. Think of it like a waypoint marker or ancient shrine that challenges the player.

---

### 2. Challenge Shrine Glow (Optional)
| Property | Value |
|----------|-------|
| **Size** | 64x64 pixels |
| **Style** | Soft radial glow / aura |
| **Colors** | Cyan/blue, semi-transparent |
| **Save To** | `res://Textures/poi/shrine_glow.png` |

**Description:**
A soft glowing aura that surrounds the shrine. This pulses to draw player attention. Can be a simple radial gradient.

---

### 3. Zone Indicator (For Survival Challenge)
| Property | Value |
|----------|-------|
| **Size** | 64x64 or 128x128 pixels |
| **Style** | Circular zone marker |
| **Colors** | Green when safe, Red when player outside |
| **Save To** | `res://Textures/poi/zone_circle.png` |

**Description:**
A circular ground indicator showing the "stay in zone" area for survival challenges. Should look like a magical circle or rune pattern on the ground.

---

## Directory Structure

Create this folder if it doesn't exist:
```
res://Textures/poi/
├── challenge_shrine.png
├── shrine_glow.png (optional)
└── zone_circle.png
```

---

## After Creating Art

Once you've created the sprites, let me know and I'll update the `challenge_shrine.tscn` to use them instead of the polygon placeholders!

---

## Quick Reference - Current Placeholder Colors
- **Base Platform**: Dark blue-gray `Color(0.15, 0.25, 0.4)`
- **Pillar**: Medium blue `Color(0.2, 0.4, 0.7)` 
- **Crystal**: Bright cyan `Color(0.4, 0.8, 1.0)`
- **Glow**: Cyan transparent `Color(0.3, 0.7, 1.0, 0.3)`
