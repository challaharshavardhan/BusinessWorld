# Supply Yard — Mobile Delivery Game (Prototype)

This is a completely original single-screen casual delivery game inspired by the layout and gameplay genre of a screenshot provided by the user. It does **not** use Township artwork, logos, names, meshes, textures, sprites, or game code.

## Gameplay
- Hold and drag a finger to move the character.
- Approach the **egg stack** at the blue collection zone to automatically pick up eggs.
- Approach the **truck** at the yellow delivery zone to load the order.
- Deliver the full requested quantity to earn $7 per egg.
- Walk onto the green **cash upgrade pad** when you have enough money to increase egg production.
- Eggs are produced automatically. Carry at most six; the stack holds at most 36.
- Restart begins a fresh prototype game.
- Save data is stored locally in a new file; the prior Business World save is not altered.

## Build Android APK
Open **Actions** → **Build Android APK** → latest successful workflow run.
Download **SupplyYard-Pivot-v1**, extract the zip, and install the debug APK on Android.

## Prior project
The original bakery tycoon v0.3 is preserved on the branch `archive/business-world-v0.3`.

## Scope and limitations
Visuals are original geometry rendered from Godot drawing commands as a placeholder for future authored 3D/2.5D art assets. There are no ripped game assets. The truck animation and character are intentionally lightweight. App upgrades may require reinstalling if CI debug signing changes; uninstalling deletes app data.
