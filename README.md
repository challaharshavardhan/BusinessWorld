# Market Days — 3D Market v1.2

A playable, independently created Android market simulation inspired by the user's reference recording. The game does not contain the original game's branding, meshes, artwork, or code.

## New in v1.2

### Visible money
- After each customer sale, a small **floating green banknote** shows the payment.
- Payments accumulate into a **stack of green bills** at the **$ CASH** collection mat beside the main checkout on the left side.
- The HUD separately shows **WALLET** (spendable cash) and **PICKUP** (money waiting on the mat).
- **Walk to the cash mat to pick up your earnings**. Money is not spendable for workers or land purchases until collected.
- Workers and the wholesale market also deposit earnings into that pile.
- Pending money is saved across app sessions.

### Expand the world
- Tap the **EXPAND $150** button (or walk onto the land pad when you have enough spendable cash) to unlock **East Yard**.
- The new walkable land connects to the right/east edge of the original market.
- In East Yard, approach the tomato table to automatically harvest tomatoes, or deliver any carried produce at the **WHOLESALE $9/ITEM** counter. Wholesale earnings are deposited into the cash pile for collection.
- After East Yard, **EXPAND $260** unlocks the **Orchard**, with a new carrot harvesting table, trees, fences, and cottages. Wholesale payout increases to $11/item.
- Both extensions persist in the local save and remain accessible whenever you enter the market.
- Player movement and follow camera support both new areas.

## Existing game features
- Isometric 3D town overview and landscape market interior.
- Touch joystick player movement; **ZOOM +**, **ZOOM -**, two-finger pinch and follow-camera.
- Shop shelves for tomato, cabbage and carrot, customer line and matching customer orders.
- Main checkout and front express checkout.
- Hire up to 3 workers (first $70, second $130, third $190) to serve customers automatically.
- Unlock the egg counter ($80), located separately on the left side of the market.
- Locally saved cash, goods, staff, camera zoom, and progress.

## Gameplay
1. Press **Enter Market**.
2. Move to a shelf using the touch joystick; collecting produce is automatic.
3. Read **NEXT:** in the HUD and take the correct produce to the main or front checkout.
4. Follow the **green money bundles** to the **$ CASH** mat near the main checkout. Pick up cash by walking to the mat.
5. Spend money on **HIRE**, **EGG STALL**, or **EXPAND**.
6. Explore East Yard and the Orchard with the joystick; use the zoom controls to see more or less of the map.

## Android install
Go to [GitHub Actions](https://github.com/challaharshavardhan/BusinessWorld/actions), open the latest successful Android run, download **MarketDays-3D-v1.2** from Artifacts, extract the ZIP and install the APK.

**Installation caution:** Each GitHub CI run currently creates a new Android debug signing key; Android may refuse an in-place update. Uninstalling the older APK erases that version's local game progress.

## Scope
This is an original low-poly 3D prototype with functional cash piles and two new regions; it is not a copy of any proprietary source game's assets or full content.
