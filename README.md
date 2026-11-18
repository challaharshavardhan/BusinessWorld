# Business World — Green Valley (v0.2)

An offline-first isometric Android business tycoon built using Godot 4.4.

## Playable features

- A 24x24 isometric town with roads, trees and houses
- Drag to pan and pinch to zoom
- Start with $500; build a bakery for $200
- After building, tap **Open Bakery Dashboard** or tap the bakery tile
- Automatic baking: one bread every 8 seconds using one flour; initial flour = 20 and bread = 5
- One customer purchases a bread every 5 seconds when bread is in stock; bread sells for $5
- Buy 10 flour for $20 in the dashboard
- Oven upgrade costs $80, up to level 4; each upgrade reduces bake time by two seconds (minimum two seconds)
- Storage upgrade costs $100, up to level 5; each upgrade adds 20 bread capacity above the starting 30
- Revenue, spending, inventory and customer count recorded in local save
- **Start New Town** resets the bakery and its economy

## Android APK

1. Open **Actions** in the GitHub repository and open **Build Android APK**.
2. Open a successful run; download the `BusinessWorld-Android-v0.2` artifact.
3. Extract the ZIP file and install the APK. This is a debug build.

**Existing saves:** The game loads the v0.1 save path and adds v0.2 fields with defaults. Reinstalling over the existing app generally retains the save if the debug signing key is compatible. If Android requires uninstalling, uninstalling erases app data and saved town.

## Gameplay notes

Sales and production advance only while the game is running (no offline earnings yet). Customers currently act as an aggregate demand simulation, not walking characters. Revenue and spending figures are cumulative since the town started; the latter includes construction, restocking and upgrades. Revenue minus these costs is a cumulative accounting metric, not current cash.

## Planned

Walking shoppers, dynamic prices and demand, business staffing, other businesses, and district expansion.
