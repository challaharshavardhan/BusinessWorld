extends Node2D

const GRID := 24
const TILE_W := 90.0
const TILE_H := 46.0
const SAVE_PATH := "user://business_world_v01.json"
const BAKERY_COST := 200
const START_CASH := 500

var cash := START_CASH
var bakery_tile := Vector2i(-1, -1)
var camera_offset := Vector2(360, 300)
var camera_zoom := 0.65
var selected_tile := Vector2i(12, 12)
var build_mode := false
var drag_start := Vector2.ZERO
var last_touch := Vector2.ZERO
var dragging := false
var touch_points: Dictionary = {}
var last_pinch_distance := 0.0

var ui_layer: CanvasLayer
var money_label: Label
var status_label: Label
var build_button: Button
var reset_button: Button

func _ready() -> void:
    _load_game()
    _make_ui()
    queue_redraw()

func iso(tile: Vector2) -> Vector2:
    return Vector2((tile.x - tile.y) * TILE_W * 0.5, (tile.x + tile.y) * TILE_H * 0.5)

func to_tile(pos: Vector2) -> Vector2i:
    var world := (pos - camera_offset) / camera_zoom
    var tx := world.y / TILE_H + world.x / TILE_W
    var ty := world.y / TILE_H - world.x / TILE_W
    return Vector2i(floori(tx), floori(ty))

func _draw() -> void:
    draw_rect(Rect2(Vector2(-1000, -1000), Vector2(4000, 4000)), Color("#a6d6ef"))
    draw_set_transform(camera_offset, 0.0, Vector2.ONE * camera_zoom)
    for y in range(GRID):
        for x in range(GRID):
            var p := iso(Vector2(x, y))
            var road := x == 10 or y == 10 or x == 16
            var color := Color("#9bc777") if (x + y) % 2 == 0 else Color("#91bd70")
            if road:
                color = Color("#a6a8a8")
            if Vector2i(x, y) == selected_tile and build_mode:
                color = Color("#f6dc76")
            var poly := PackedVector2Array([
                p + Vector2(0, -TILE_H / 2),
                p + Vector2(TILE_W / 2, 0),
                p + Vector2(0, TILE_H / 2),
                p + Vector2(-TILE_W / 2, 0)
            ])
            draw_colored_polygon(poly, color)
            draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(0.23, 0.36, 0.20, 0.15), 1.0)
            if road and y % 3 == 0:
                draw_line(p + Vector2(-8, 0), p + Vector2(8, 0), Color("#e8e6c7"), 2)
    for home in [Vector2i(5, 7), Vector2i(7, 6), Vector2i(18, 8), Vector2i(20, 12), Vector2i(6, 17)]:
        _draw_building(home, Color("#f2c38e"), Color("#b75d4b"), false)
    for tree in [Vector2i(4, 4), Vector2i(8, 19), Vector2i(20, 20), Vector2i(3, 15), Vector2i(14, 4)]:
        var p := iso(Vector2(tree.x, tree.y))
        draw_circle(p + Vector2(0, -18), 13, Color("#448a51"))
        draw_circle(p + Vector2(-6, -24), 9, Color("#62a75c"))
    if bakery_tile.x >= 0:
        _draw_building(bakery_tile, Color("#f7dfaa"), Color("#db8050"), true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_building(tile: Vector2i, wall: Color, roof: Color, bakery: bool) -> void:
    var p := iso(Vector2(tile.x, tile.y))
    draw_rect(Rect2(p + Vector2(-24, -42), Vector2(48, 42)), wall)
    draw_colored_polygon(PackedVector2Array([
        p + Vector2(-31, -42), p + Vector2(0, -68),
        p + Vector2(31, -42), p + Vector2(0, -27)
    ]), roof)
    draw_rect(Rect2(p + Vector2(-7, -23), Vector2(14, 23)), Color("#7c553f"))
    draw_rect(Rect2(p + Vector2(-21, -32), Vector2(10, 11)), Color("#88d4e9"))
    draw_rect(Rect2(p + Vector2(11, -32), Vector2(10, 11)), Color("#88d4e9"))
    if bakery:
        draw_rect(Rect2(p + Vector2(-25, -48), Vector2(50, 10)), Color("#f7f0dc"))
        draw_rect(Rect2(p + Vector2(-20, -46), Vector2(9, 7)), Color("#db8050"))
        draw_rect(Rect2(p + Vector2(-2, -46), Vector2(9, 7)), Color("#db8050"))
        draw_rect(Rect2(p + Vector2(16, -46), Vector2(9, 7)), Color("#db8050"))

func _make_ui() -> void:
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_layer.add_child(root)

    var top := PanelContainer.new()
    top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top.offset_bottom = 125
    root.add_child(top)
    var top_box := VBoxContainer.new()
    top.add_child(top_box)
    var title := Label.new()
    title.text = "BUSINESS WORLD  •  GREEN VALLEY"
    title.add_theme_font_size_override("font_size", 24)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    top_box.add_child(title)
    money_label = Label.new()
    money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    money_label.add_theme_font_size_override("font_size", 32)
    top_box.add_child(money_label)
    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 17)
    top_box.add_child(status_label)

    var bottom := PanelContainer.new()
    bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.offset_top = -190
    root.add_child(bottom)
    var controls := VBoxContainer.new()
    bottom.add_child(controls)
    var hint := Label.new()
    hint.text = "Drag to move • Pinch to zoom • Tap a plot"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls.add_child(hint)
    build_button = Button.new()
    build_button.custom_minimum_size = Vector2(0, 70)
    build_button.pressed.connect(_on_build_pressed)
    controls.add_child(build_button)
    reset_button = Button.new()
    reset_button.text = "Start New Town"
    reset_button.custom_minimum_size = Vector2(0, 45)
    reset_button.pressed.connect(_reset)
    controls.add_child(reset_button)
    _refresh_ui()

func _refresh_ui() -> void:
    money_label.text = "Cash: $%d" % cash
    if bakery_tile.x >= 0:
        status_label.text = "Bakery built! Next: customers and sales"
        build_button.text = "Bakery constructed ✓"
        build_button.disabled = true
    elif build_mode:
        status_label.text = "Select a green tile, then confirm"
        build_button.text = "Confirm Bakery ($200)"
    else:
        status_label.text = "Your first business awaits"
        build_button.text = "Build Bakery ($200)"

func _on_build_pressed() -> void:
    if bakery_tile.x >= 0:
        return
    if not build_mode:
        build_mode = true
        selected_tile = Vector2i(12, 12)
    else:
        if cash < BAKERY_COST:
            status_label.text = "Not enough cash"
            return
        if not _can_build(selected_tile):
            status_label.text = "Choose an empty green tile"
            return
        bakery_tile = selected_tile
        cash -= BAKERY_COST
        build_mode = false
        _save_game()
    _refresh_ui()
    queue_redraw()

func _can_build(t: Vector2i) -> bool:
    if t.x < 0 or t.y < 0 or t.x >= GRID or t.y >= GRID:
        return false
    if t.x == 10 or t.y == 10 or t.x == 16:
        return false
    for home in [Vector2i(5, 7), Vector2i(7, 6), Vector2i(18, 8), Vector2i(20, 12), Vector2i(6, 17)]:
        if t == home:
            return false
    return true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_points[event.index] = event.position
            last_touch = event.position
            drag_start = event.position
            dragging = false
        else:
            touch_points.erase(event.index)
            last_pinch_distance = 0.0
            if not dragging and touch_points.is_empty():
                _select_at(event.position)
    elif event is InputEventScreenDrag:
        touch_points[event.index] = event.position
        dragging = true
        if touch_points.size() >= 2:
            var pts := touch_points.values()
            var dist: float = pts[0].distance_to(pts[1])
            if last_pinch_distance > 0:
                camera_zoom = clampf(camera_zoom * dist / last_pinch_distance, 0.35, 1.7)
            last_pinch_distance = dist
        else:
            camera_offset += event.relative
        queue_redraw()
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            camera_zoom = minf(1.7, camera_zoom * 1.1)
            queue_redraw()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            camera_zoom = maxf(0.35, camera_zoom / 1.1)
            queue_redraw()
        elif event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                drag_start = event.position
                last_touch = event.position
                dragging = false
            elif not dragging:
                _select_at(event.position)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        if event.position.distance_to(drag_start) > 10:
            dragging = true
        if dragging:
            camera_offset += event.position - last_touch
            queue_redraw()
        last_touch = event.position

func _select_at(pos: Vector2) -> void:
    if not build_mode:
        return
    var t := to_tile(pos)
    if _can_build(t):
        selected_tile = t
        status_label.text = "Plot selected (%d, %d)" % [t.x, t.y]
    else:
        status_label.text = "Choose an empty green tile"
    queue_redraw()

func _save_game() -> void:
    var data := {
        "version": 1,
        "cash": cash,
        "bakery_x": bakery_tile.x,
        "bakery_y": bakery_tile.y
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var data = JSON.parse_string(file.get_as_text())
    if data is Dictionary and data.get("version", 0) == 1:
        cash = int(data.get("cash", START_CASH))
        bakery_tile = Vector2i(int(data.get("bakery_x", -1)), int(data.get("bakery_y", -1)))

func _reset() -> void:
    cash = START_CASH
    bakery_tile = Vector2i(-1, -1)
    build_mode = false
    _save_game()
    _refresh_ui()
    queue_redraw()
