# Business World — Green Valley

An Android-first, offline-friendly isometric business tycoon built with Godot.

## v0.1 playable scope
- 24x24 isometric town with roads, houses, and trees
- Touch drag to pan; pinch to zoom
- Build a bakery for $200 from $500 starting cash
- Choose a valid plot and confirm construction
- Local save and load; reset town

**Not yet implemented:** customers, bakery production, profits, employees, and economic simulation. Those are future milestones.

## Build APK from Android phone
1. Open the GitHub repository's **Actions** tab.
2. Select **Build Android APK**.
3. Tap **Run workflow** and select **main**.
4. When the job succeeds, open the run and download the **BusinessWorld-Android-v0.1** artifact.
5. Extract the ZIP, then install the APK on your Android phone. Android may ask you to allow installation from your browser or file manager.

The workflow uses the Godot CI Docker image and debug signing. This is a test build, not a Play Store release.

## Game controls
- Tap **Build Bakery ($200)** to enter construction mode.
- Tap a green tile to choose a plot.
- Tap **Confirm Bakery** to build.
- Drag to pan, pinch to zoom.
- **Start New Town** erases local prototype progress.

## Architecture
Godot 4.x / GDScript. This is an initial playable visual vertical slice. Economy, customer, and business systems will be separated into reusable modules in later iterations.
