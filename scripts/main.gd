extends Node2D

const GRID := 24
const TILE_W := 90.0
const TILE_H := 46.0
const SAVE_PATH := "user://business_world_v01.json"
const BAKERY_COST := 200
const START_CASH := 500
const HOUSE_COST := 120
const BASE_POPULATION := 20
const BASE_HOUSES := [Vector2i(5, 7), Vector2i(7, 6), Vector2i(18, 8), Vector2i(20, 12), Vector2i(6, 17)]
const TREE_TILES := [Vector2i(4, 4), Vector2i(8, 19), Vector2i(20, 20), Vector2i(3, 15), Vector2i(14, 4)]
var bread_price := 5
var new_houses: Array[Vector2i] = []
var house_mode := false
var game_seconds := 0.0
var lost_sales := 0
var price_down_button: Button
var price_up_button: Button
var house_button: Button
var town_label: Label

const BREAD_PRICE := 5
var flour := 20
var bread := 5
var oven_level := 1
var storage_level := 1
var customers_served := 0
var sales_revenue := 0
var business_costs := 0
var production_clock := 0.0
var customer_clock := 0.0
var refresh_clock := 0.0
var bakery_panel: PanelContainer
var bakery_stats: Label
var restock_button: Button
var oven_button: Button
var storage_button: Button


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

func _process(delta: float) -> void:
    if bakery_tile.x < 0:
        return
    production_clock += delta
    customer_clock += delta
    refresh_clock += delta
    game_seconds += delta
    var changed := false
    var production_seconds := maxf(2.0, 8.0 - float(oven_level - 1) * 2.0)
    var capacity := 30 + (storage_level - 1) * 20
    while production_clock >= production_seconds:
        production_clock -= production_seconds
        if flour > 0 and bread < capacity:
            flour -= 1
            bread += 1
            changed = true
    var interval := _customer_interval()
    while customer_clock >= interval:
        customer_clock -= interval
        if bread > 0:
            bread -= 1
            cash += bread_price
            sales_revenue += bread_price
            customers_served += 1
        else:
            lost_sales += 1
        changed = true
    if changed:
        _save_game()
    if changed or refresh_clock >= 1.0:
        refresh_clock = 0.0
        _refresh_ui()
    queue_redraw()

func _population() -> int:
    return BASE_POPULATION + new_houses.size() * 4

func _customer_interval() -> float:
    # Higher prices reduce demand, additional homes increase it.
    var price_effect := pow(float(bread_price) / 5.0, 1.3)
    var population_effect := 20.0 / float(_population())
    return clampf(5.0 * price_effect * population_effect, 1.4, 15.0)

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
            if Vector2i(x, y) == selected_tile and (build_mode or house_mode):
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
    for home in BASE_HOUSES:
        _draw_building(home, Color("#f2c38e"), Color("#b75d4b"), false)
    for home in new_houses:
        _draw_building(home, Color("#f2c38e"), Color("#b75d4b"), false)
    for tree in TREE_TILES:
        var p := iso(Vector2(tree.x, tree.y))
        draw_circle(p + Vector2(0, -18), 13, Color("#448a51"))
        draw_circle(p + Vector2(-6, -24), 9, Color("#62a75c"))
    if bakery_tile.x >= 0:
        _draw_building(bakery_tile, Color("#f7dfaa"), Color("#db8050"), true)
        # A representative shopper walks toward the bakery on each demand cycle.
        var progress := clampf(customer_clock / _customer_interval(), 0.0, 1.0)
        var start_pos := iso(Vector2(7, 6)) + Vector2(0, -9)
        var shop_pos := iso(Vector2(bakery_tile.x, bakery_tile.y)) + Vector2(31, 9)
        var shopper := start_pos.lerp(shop_pos, progress)
        draw_circle(shopper, 8, Color("#465e98"))
        draw_circle(shopper + Vector2(0, -9), 5, Color("#f6c087"))
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
    town_label = Label.new()
    town_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    town_label.add_theme_font_size_override("font_size", 17)
    top_box.add_child(town_label)

    var bottom := PanelContainer.new()
    bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.offset_top = -255
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
    house_button = Button.new()
    house_button.custom_minimum_size = Vector2(0, 60)
    house_button.pressed.connect(_on_house_pressed)
    controls.add_child(house_button)
    reset_button = Button.new()
    reset_button.text = "Start New Town"
    reset_button.custom_minimum_size = Vector2(0, 45)
    reset_button.pressed.connect(_reset)
    controls.add_child(reset_button)
    _make_bakery_panel(root)
    _refresh_ui()

func _make_bakery_panel(root: Control) -> void:
    bakery_panel = PanelContainer.new()
    bakery_panel.set_anchors_preset(Control.PRESET_CENTER)
    bakery_panel.offset_left = -290
    bakery_panel.offset_right = 290
    bakery_panel.offset_top = -350
    bakery_panel.offset_bottom = 350
    bakery_panel.visible = false
    root.add_child(bakery_panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    bakery_panel.add_child(content)
    var heading := Label.new()
    heading.text = "BAKERY DASHBOARD"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 26)
    content.add_child(heading)
    bakery_stats = Label.new()
    bakery_stats.add_theme_font_size_override("font_size", 18)
    content.add_child(bakery_stats)
    var price_row := HBoxContainer.new()
    content.add_child(price_row)
    price_down_button = Button.new()
    price_down_button.text = "Price -$1"
    price_down_button.custom_minimum_size = Vector2(200, 56)
    price_down_button.pressed.connect(_price_down)
    price_row.add_child(price_down_button)
    price_up_button = Button.new()
    price_up_button.text = "Price +$1"
    price_up_button.custom_minimum_size = Vector2(200, 56)
    price_up_button.pressed.connect(_price_up)
    price_row.add_child(price_up_button)
    restock_button = Button.new()
    restock_button.text = "Buy 10 flour ($20)"
    restock_button.custom_minimum_size = Vector2(0, 65)
    restock_button.pressed.connect(_buy_flour)
    content.add_child(restock_button)
    oven_button = Button.new()
    oven_button.custom_minimum_size = Vector2(0, 65)
    oven_button.pressed.connect(_upgrade_oven)
    content.add_child(oven_button)
    storage_button = Button.new()
    storage_button.custom_minimum_size = Vector2(0, 65)
    storage_button.pressed.connect(_upgrade_storage)
    content.add_child(storage_button)
    var close_button := Button.new()
    close_button.text = "Close"
    close_button.custom_minimum_size = Vector2(0, 60)
    close_button.pressed.connect(_close_dashboard)
    content.add_child(close_button)

func _close_dashboard() -> void:
    bakery_panel.visible = false

func _refresh_ui() -> void:
    money_label.text = "Cash: $%d" % cash
    build_button.disabled = false
    town_label.text = "Population: %d  •  Bread price: $%d" % [_population(), bread_price]
    house_button.disabled = bakery_tile.x < 0 or (cash < HOUSE_COST and not house_mode)
    if house_mode:
        house_button.text = "Confirm House ($120)"
    else:
        house_button.text = "Build House ($120)"
    if bakery_tile.x >= 0:
        status_label.text = "Flour: %d  •  Bread: %d  •  Sales: %d" % [flour, bread, customers_served]
        build_button.text = "Open Bakery Dashboard"
    elif build_mode:
        status_label.text = "Select a green tile, then confirm"
        build_button.text = "Confirm Bakery ($200)"
    else:
        status_label.text = "Your first business awaits"
        build_button.text = "Build Bakery ($200)"
    if house_mode:
        status_label.text = "Tap an empty green tile, then confirm house"
    if bakery_panel != null and bakery_panel.visible:
        var capacity := 30 + (storage_level - 1) * 20
        var speed := maxi(2, 8 - (oven_level - 1) * 2)
        bakery_stats.text = "Flour %d  |  Bread %d/%d  |  Oven %ds\nBread price $%d  |  1 buyer / %.1fs\nCustomers served %d  |  Missed %d\nSales revenue $%d  |  Costs $%d\nNet after all costs $%d\nAvg sales $%.1f per minute" % [flour, bread, capacity, speed, bread_price, _customer_interval(), customers_served, lost_sales, sales_revenue, business_costs, sales_revenue - business_costs, float(customers_served) * 60.0 / maxf(1.0, game_seconds)]
        price_down_button.disabled = bread_price <= 2
        price_up_button.disabled = bread_price >= 12
        restock_button.disabled = cash < 20
        oven_button.text = "Upgrade oven (Lv %d) • $80" % oven_level
        oven_button.disabled = cash < 80 or oven_level >= 4
        if oven_level >= 4:
            oven_button.text = "Oven MAX"
        storage_button.text = "Upgrade storage (Lv %d) • $100" % storage_level
        storage_button.disabled = cash < 100 or storage_level >= 5
        if storage_level >= 5:
            storage_button.text = "Storage MAX"

func _price_down() -> void:
    bread_price = maxi(2, bread_price - 1)
    _save_game()
    _refresh_ui()

func _price_up() -> void:
    bread_price = mini(12, bread_price + 1)
    _save_game()
    _refresh_ui()

func _on_house_pressed() -> void:
    if bakery_tile.x < 0:
        return
    if not house_mode:
        house_mode = true
        build_mode = false
        selected_tile = Vector2i(12, 11)
    else:
        if cash < HOUSE_COST:
            status_label.text = "Not enough cash for a house"
            return
        if not _can_build(selected_tile):
            status_label.text = "Choose an empty green plot"
            return
        new_houses.append(selected_tile)
        cash -= HOUSE_COST
        business_costs += HOUSE_COST
        house_mode = false
        _save_game()
    _refresh_ui()
    queue_redraw()

func _buy_flour() -> void:
    if bakery_tile.x < 0 or cash < 20:
        return
    cash -= 20
    business_costs += 20
    flour += 10
    _save_game()
    _refresh_ui()

func _upgrade_oven() -> void:
    if bakery_tile.x < 0 or cash < 80 or oven_level >= 4:
        return
    cash -= 80
    business_costs += 80
    oven_level += 1
    _save_game()
    _refresh_ui()

func _upgrade_storage() -> void:
    if bakery_tile.x < 0 or cash < 100 or storage_level >= 5:
        return
    cash -= 100
    business_costs += 100
    storage_level += 1
    _save_game()
    _refresh_ui()

func _on_build_pressed() -> void:
    if bakery_tile.x >= 0:
        house_mode = false
        bakery_panel.visible = not bakery_panel.visible
        _refresh_ui()
        return
    if not build_mode:
        house_mode = false
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
        business_costs += BAKERY_COST
        build_mode = false
        _save_game()
    _refresh_ui()
    queue_redraw()

func _can_build(t: Vector2i) -> bool:
    if t.x < 0 or t.y < 0 or t.x >= GRID or t.y >= GRID:
        return false
    if t.x == 10 or t.y == 10 or t.x == 16:
        return false
    if t == bakery_tile or t in BASE_HOUSES or t in new_houses or t in TREE_TILES:
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
    var t := to_tile(pos)
    if not build_mode and not house_mode:
        if bakery_tile.x >= 0 and t == bakery_tile:
            bakery_panel.visible = true
            _refresh_ui()
        return
    if _can_build(t):
        selected_tile = t
        status_label.text = "Plot selected (%d, %d)" % [t.x, t.y]
    else:
        status_label.text = "Choose an empty green tile"
    queue_redraw()

func _house_save_data() -> Array:
    var result: Array = []
    for home in new_houses:
        result.append([home.x, home.y])
    return result

func _save_game() -> void:
    var data := {
        "version": 3,
        "bread_price": bread_price,
        "new_houses": _house_save_data(),
        "lost_sales": lost_sales,
        "cash": cash,
        "bakery_x": bakery_tile.x,
        "bakery_y": bakery_tile.y,
        "flour": flour,
        "bread": bread,
        "oven_level": oven_level,
        "storage_level": storage_level,
        "customers_served": customers_served,
        "sales_revenue": sales_revenue,
        "business_costs": business_costs
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
    if data is Dictionary and int(data.get("version", 0)) >= 1:
        cash = int(data.get("cash", START_CASH))
        bakery_tile = Vector2i(int(data.get("bakery_x", -1)), int(data.get("bakery_y", -1)))
        flour = int(data.get("flour", 20))
        bread = int(data.get("bread", 5))
        oven_level = int(data.get("oven_level", 1))
        storage_level = int(data.get("storage_level", 1))
        customers_served = int(data.get("customers_served", 0))
        sales_revenue = int(data.get("sales_revenue", 0))
        business_costs = int(data.get("business_costs", BAKERY_COST if bakery_tile.x >= 0 else 0))
        bread_price = clampi(int(data.get("bread_price", 5)), 2, 12)
        lost_sales = int(data.get("lost_sales", 0))
        new_houses.clear()
        var saved_houses = data.get("new_houses", [])
        if saved_houses is Array:
            for entry in saved_houses:
                if entry is Array and entry.size() == 2:
                    var t := Vector2i(int(entry[0]), int(entry[1]))
                    if _can_build(t):
                        new_houses.append(t)

func _reset() -> void:
    cash = START_CASH
    bakery_tile = Vector2i(-1, -1)
    build_mode = false
    house_mode = false
    new_houses.clear()
    bread_price = 5
    lost_sales = 0
    game_seconds = 0.0
    flour = 20
    bread = 5
    oven_level = 1
    storage_level = 1
    customers_served = 0
    sales_revenue = 0
    business_costs = 0
    production_clock = 0.0
    customer_clock = 0.0
    if bakery_panel != null:
        bakery_panel.visible = false
    _save_game()
    _refresh_ui()
    queue_redraw()
