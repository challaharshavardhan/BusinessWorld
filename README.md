# Business World — Green Valley (v0.3)

An Android-first offline isometric tycoon built with Godot 4.4.

## What's new in v0.3
- **Visible shopper:** a representative animated customer walks from a house toward the bakery each simulated purchase cycle
- **Dynamic bakery demand:** visit interval depends on bread price and town population
- **Bread pricing:** adjust prices between $2 and $12 in the bakery dashboard; higher prices slow customer arrivals
- **Houses and population:** build houses for $120. Each new house increases town population by four, bringing more customers
- **Business analytics:** cumulative revenue, costs, net after costs, customers served, missed sales, and average served customers per minute
- **Cleaner dashboard:** compact statistics with price and upgrade controls

## Existing v0.2 gameplay
- Begin with $500, construct a bakery for $200
- Bakery starts with 20 flour and 5 bread
- Production starts at one bread every 8 seconds, uses one flour per bread; default capacity 30
- Buy 10 flour for $20
- Upgrade oven for $80 (up to level 4) and storage for $100 (up to level 5)
- Pan and zoom the isometric town and use **Start New Town** to reset

## How to play
1. Build the bakery on an empty green tile.
2. Tap **Open Bakery Dashboard** to review inventory and adjust bread prices.
3. Observe the customer's walking marker approaching the bakery and watch sales accumulate.
4. Use **Build House ($120)**, select an empty green tile, and confirm construction. Each house grows population by four.
5. Watch the displayed buyer interval change when you raise/lower the price or build houses.
6. Restock flour and upgrade the bakery to keep up with demand.

## Build and install
Open GitHub **Actions** → **Build Android APK**, open the latest successful run and download the `BusinessWorld-Android-v0.3` artifact. Extract the APK and install it on your Android phone.

**Data:** Loads existing v0.1/v0.2 save files from the same path; new properties have defaults. If Android forces you to uninstall a differently signed debug APK, uninstalling deletes your local save.

**Scope:** This is a prototype. The shopper is a visual representative, not an individually pathfinding customer. The demand model uses fixed price elasticity; business costs include construction and upgrades and do not yet include staffing, rent, or daily wages. In-game time advances only while the app is running.
