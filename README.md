# Market Days — 3D market game v1.1

An original Godot 4.4 Android game inspired by the gameplay in the user-provided recording. It does not use the source game's logo, art assets, characters, meshes, or code.

## New in v1.1
- **Close-up camera:** opens the market zoomed in on the playable character rather than the whole platform.
- **Zoom controls:** **ZOOM +**, **ZOOM −**, phone two-finger pinch gestures, and mouse-wheel zoom in desktop tests.
- **Focus player:** camera follows your avatar as you walk; press **FOCUS PLAYER** if needed.
- **Staff:** on the right side of the market, the **HIRE $70** button appears, with later workers costing $130 and $190, up to three. You need enough cash from checkout sales before hiring. Hired staff are visible blue-clothed NPCs, move between shelves and checkout, automatically fulfill queued orders when stock is available, and earn shop revenue.
- **Dedicated egg counter:** **EGG STALL $80** unlocks a separate egg station on the **left/front side** of the market, away from tomato, cabbage, and carrot shelves. Eggs restock and can appear in future customer orders.
- **Playable character:** labeled YOU, visible toward the front of the market in the close-up view.
- Worker hires and camera zoom are saved alongside your existing cash, product, and market data.

## How to play
1. Open Market Days. Select **Enter Market** from the town overview.
2. Move your avatar using the touch joystick in the lower-left portion of the display. Walk near a produce shelf to automatically pick up up to five items.
3. Read the **NEXT:** order at the top. Bring that type of produce to checkout near the middle; cash increases when the sale completes.
4. Once you have $70, tap **HIRE $70**. You'll see a worker appear and begin automatically helping serve customers. Hire up to three.
5. With $80, tap **EGG STALL $80** or step on the green unlock pad. The new egg station appears on the left side.
6. Use **ZOOM + / ZOOM −**, pinch with two fingers, or **FOCUS PLAYER** to adjust the view.

## APK
Go to GitHub **Actions** → most recent successful **Build Android APK** run → download artifact **MarketDays-3D-v1.1** → extract ZIP and install the APK.

**Note:** GitHub Actions currently creates a fresh debug signing key on each build. Android may not let you install the new APK over your previous one; if you uninstall the old package, its on-device save is erased. The older Market Days v1 project is archived at `archive/market-days-3d-v1`.

## Scope
This is an independent **playable recreation prototype**, not a duplication of the proprietary source game. Models are simple low-poly originals, with basic shopper/worker animation and simplified economics.
