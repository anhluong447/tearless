# TEARLESS

A fast-paced, tactical 3D FPS survival experience built on **Godot 4** with advanced physics navigation, multiple zombie types, weapon reload states, an upgrades terminal, and a multi-phase quest system.

---

## 🎮 Game Overview

In **Tearless**, you are deployed in an abandoned city plaza under a sunny sky. You must defend yourself, purchase upgrades, locate missing components to repair a communications transmitter, and survive long enough to escape.

### Key Features
*   **Tactical Gunplay & ADS**: Aim Down Sights (ADS), realistic weapon models, dynamic crosshairs reflecting shot spread/recoil, and particle sparks/blood splatters on hit impact.
*   **SPAS-12 Shotgun Mechanics**: Features realistic shell-by-shell reloading. Reloading can be canceled mid-shell by pressing the fire button, letting you fire immediately.
*   **Zombie Variety (FSM)**:
    *   `NORMAL` (Green): Standard speed and health.
    *   `RUNNER` (Orange): Highly aggressive, jumps/lunges at you.
    *   `TANK` (Dark Red): Giant, slow, double damage, and heavy health pool.
    *   `BOMBER` (Yellow): Pulsates red and detonates a massive Area-of-Effect explosion when in range.
*   **Campaign Quest Progression**:
    *   **Phase 1 (Survival)**: Survive Waves 1 through 3.
    *   **Phase 2 (Battery Hunt)**: Spawning pauses. Search the city sidewalks for **2 Glowing Batteries** and return them to the plaza's Radio Transmitter. Constant light zombie spawns pressure you during this search.
    *   **Phase 3 (Extraction Holdout)**: A 30-second countdown triggers endless wave spawning as the helicopter approaches.
    *   **Phase 4 (Escape)**: Step onto the glowing green **Extraction Pad** at the Landing Zone to win.
*   **Upgrade Shop Terminal**: Spend points earned from kills to buy upgrades:
    *   *Max HP* (+25 Max HP & heals player)
    *   *Ammo Reserves* (Refills all clips)
    *   *Move Speed* (+15%)
    *   *Bullet Damage* (+20%)
*   **Global Options & Main Menu**: Configurable mouse look sensitivity, master volume controls, and fullscreen toggle.

---

## ⌨️ Controls

| Key / Input | Action |
|---|---|
| **W, A, S, D** | Move |
| **Space** | Jump |
| **Shift** | Sprint |
| **Left-Click** | Shoot |
| **Right-Click (Hold)** | Aim Down Sights (ADS) |
| **R** | Reload (Tap again to cancel SPAS-12 reload) |
| **1 / 2 / 3** / **Scroll Wheel** | Switch Weapons (Pistol, Shotgun, SPAS-12) |
| **E** | Interact (Buy Upgrades, Place Batteries) |
| **Esc / Tab** | Release mouse cursor |

---

## 🛠️ Technical Details

*   **Autobaked Navigation**: The game bakes the 3D Navigation mesh (`NavigationRegion3D`) dynamically at runtime after CSG geometry finishes loading to ensure navigation lines align.
*   **Physics Raycasting**: Bullet collisions use direct physics state raycasts (`intersect_ray`) instead of standard nodes for frame-accurate hit results and surface normals.
*   **Step-Up Mechanics**: Zombie character controllers run a test-motion sweep to automatically step over low curbs and sidewalk blocks (up to `0.35m`), preventing navigation stalls.
*   **Class Persistence**: Persistent configurations (mouse sensitivity, volume settings) are managed via static class data in `settings.gd` for seamless scene-to-scene state transition.

---

## 🚀 Running the Game

1.  Open the project directory in **Godot Engine 4.4+**.
2.  Press **F5** or click the **Play** button in the top right.
3.  The game starts on the main menu. Adjust sensitivity/volume under Settings and click **Start Game** to play!
