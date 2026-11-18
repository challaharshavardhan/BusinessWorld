extends Node2D

# Original, code-drawn prototype inspired by casual isometric delivery games.
# No assets, logos, or code from another game are included.
const SAVE_PATH := "user://supply_yard_v1.json"
const WORLD_SIZE := Vector2(720, 1280)
const EGG_INTERVAL := 1.3

var cash := 0
var eggs := 7
var carry := 0
var order_needed := 5
var order_loaded := 0
var orders_done := 0
var station_level := 1
var upgrade_cost := 60
var production_clock := 0.0
var transfer_clock := 0.0
var truck_depart_timer := 0.0
var time_elapsed := 0.0
var player_position := Vector2(385, 790)
var joystick_origin := Vector2(130, 1100)
var joystick_vector := Vector2.ZERO
var joystick_active := false
var joystick_touch_index := -1
var mouse_active := false
var ui_layer: CanvasLayer
var money_label: Label
var order_label: Label
var hint_label: Label
var restart_button: Button

func _ready() -> void:
    _load()
    _make_ui()
    queue_redraw()

func _make_ui() -> void:
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_layer.add_child(root)

    var header := PanelContainer.new()
    header.set_anchors_preset(Control.PRESET_TOP_WIDE)
    header.offset_bottom = 118
    root.add_child(header)
    var head := VBoxContainer.new()
    header.add_child(head)
    var title := Label.new()
    title.text = "SUPPLY YARD"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 26)
    head.add_child(title)
    money_label = Label.new()
    money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    money_label.add_theme_font_size_override("font_size", 34)
    head.add_child(money_label)
    order_label = Label.new()
    order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    order_label.add_theme_font_size_override("font_size", 19)
    head.add_child(order_label)

    var footer := PanelContainer.new()
    footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    footer.offset_top = -125
    root.add_child(footer)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    footer.add_child(row)
    hint_label = Label.new()
    hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint_label.text = "Drag anywhere to move. Walk to the egg stack, then the truck."
    hint_label.add_theme_font_size_override("font_size", 17)
    row.add_child(hint_label)
    restart_button = Button.new()
    restart_button.text = "Restart"
    restart_button.custom_minimum_size = Vector2(124, 72)
    restart_button.pressed.connect(_reset)
    row.add_child(restart_button)
    _refresh()

func _refresh() -> void:
    money_label.text = "$%d   •   Eggs %d   •   Carry %d/6" % [cash, eggs, carry]
    order_label.text = "TRUCK ORDER  %d / %d     •     DELIVERIES  %d" % [order_loaded, order_needed, orders_done]

func _process(delta: float) -> void:
    time_elapsed += delta
    if joystick_active:
        player_position += joystick_vector * 235.0 * delta
        player_position.x = clampf(player_position.x, 58.0, 666.0)
        player_position.y = clampf(player_position.y, 180.0, 1070.0)

    production_clock += delta
    transfer_clock += delta
    truck_depart_timer = maxf(0.0, truck_depart_timer - delta)

    while production_clock >= EGG_INTERVAL:
        production_clock -= EGG_INTERVAL
        eggs = mini(36, eggs + station_level)

    if transfer_clock >= 0.32:
        transfer_clock = 0.0
        if player_position.distance_to(Vector2(265, 716)) < 105.0 and eggs > 0 and carry < 6:
            eggs -= 1
            carry += 1
        elif player_position.distance_to(Vector2(200, 954)) < 125.0 and carry > 0 and truck_depart_timer <= 0.0:
            carry -= 1
            order_loaded += 1
            if order_loaded >= order_needed:
                cash += order_needed * 7
                orders_done += 1
                order_loaded = 0
                order_needed = 4 + (orders_done % 4) * 2
                truck_depart_timer = 1.6
            _save()
        elif player_position.distance_to(Vector2(540, 830)) < 92.0 and cash >= upgrade_cost and station_level < 5:
            cash -= upgrade_cost
            station_level += 1
            upgrade_cost += 50
            _save()

    _refresh()
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and joystick_touch_index == -1 and event.position.y > 135 and event.position.y < 1150:
            joystick_touch_index = event.index
            joystick_origin = event.position
            joystick_active = true
            joystick_vector = Vector2.ZERO
        elif not event.pressed and event.index == joystick_touch_index:
            joystick_touch_index = -1
            joystick_active = false
            joystick_vector = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == joystick_touch_index:
        joystick_vector = (event.position - joystick_origin).limit_length(80.0) / 80.0
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and event.position.y > 135 and event.position.y < 1150:
            mouse_active = true
            joystick_active = true
            joystick_origin = event.position
        elif not event.pressed and mouse_active:
            mouse_active = false
            joystick_active = false
            joystick_vector = Vector2.ZERO
    elif event is InputEventMouseMotion and mouse_active:
        joystick_vector = (event.position - joystick_origin).limit_length(80.0) / 80.0

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#8bc85d"))
    # Warm painterly patches and road form a tightly composed portrait diorama.
    _polygon([Vector2(0, 200), Vector2(720, 150), Vector2(720, 1050), Vector2(0, 1170)], Color("#80bc55"))
    _polygon([Vector2(0, 910), Vector2(720, 1030), Vector2(720, 1190), Vector2(0, 1090)], Color("#637a7d"))
    _polygon([Vector2(0, 924), Vector2(720, 1047), Vector2(720, 1071), Vector2(0, 946)], Color("#c5d1c1"))
    _polygon([Vector2(0, 1095), Vector2(720, 1216), Vector2(720, 1240), Vector2(0, 1117)], Color("#c2cdb5"))
    for i in range(9):
        var x: float = float(i * 95 - 30)
        draw_line(Vector2(x, 1020 + x * 0.16), Vector2(x + 43, 1027 + x * 0.16), Color("#e1e4ce"), 5.0)

    # Raised fenced orchard and production plot.
    _polygon([Vector2(265, 281), Vector2(700, 195), Vector2(719, 566), Vector2(340, 660)], Color("#ae8749"))
    _polygon([Vector2(278, 276), Vector2(700, 208), Vector2(708, 536), Vector2(342, 624)], Color("#a9cf63"))
    _polygon([Vector2(387, 330), Vector2(682, 274), Vector2(687, 502), Vector2(411, 572)], Color("#417890"))
    _polygon([Vector2(400, 324), Vector2(672, 273), Vector2(682, 482), Vector2(416, 551)], Color("#4f4136"))
    for i in range(17):
        var column: int = i % 4
        var row: int = i / 4
        var ex: float = 438 + column * 55 + (row % 2) * 18
        var ey: float = 340 + row * 44 - column * 7
        _egg(Vector2(ex, ey), 19.0)

    _fence(Vector2(0, 505), Vector2(325, 342), 7)
    _fence(Vector2(354, 338), Vector2(710, 246), 6)
    _fence(Vector2(0, 891), Vector2(110, 928), 3)
    _fence(Vector2(350, 974), Vector2(715, 1126), 7)

    # Collection table, piled products, truck, cashier and game-character.
    _table(Vector2(260, 758))
    _stack(Vector2(263, 712), mini(eggs, 32))
    _zone(Vector2(275, 755), 98, Color("#35e5e7"))
    _truck(Vector2(167 - truck_depart_timer * 180.0, 1015))
    _zone(Vector2(193, 940), 85, Color("#ffe16b"))
    _upgrade_pad(Vector2(540, 830))
    _person(player_position)

    # Carrying goods are visible above the player.
    for i in range(carry):
        var col: int = i % 3
        var row: int = i / 3
        _egg(player_position + Vector2(-23 + col * 22, -82 - row * 24), 11)

    # HUD markers located in the world.
    _world_text(Vector2(118, 872), "ORDER  %d/%d" % [order_loaded, order_needed], 24, Color("#fef9d3"))
    _world_text(Vector2(462, 782), "$%d TO UPGRADE" % upgrade_cost if station_level < 5 else "MAX LEVEL", 19, Color("#ffffff"))
    _world_text(Vector2(150, 600), "EGG STATION • LV %d" % station_level, 20, Color("#ffffff"))

    if joystick_active:
        draw_circle(joystick_origin, 60, Color(0.12, 0.25, 0.26, 0.28))
        draw_arc(joystick_origin, 60, 0, TAU, 48, Color(0.7, 1.0, 1.0, 0.8), 4)
        draw_circle(joystick_origin + joystick_vector * 48, 29, Color(0.6, 0.93, 0.92, 0.65))

func _polygon(points: Array, color: Color) -> void:
    draw_colored_polygon(PackedVector2Array(points), color)

func _egg(p: Vector2, r: float) -> void:
    draw_circle(p + Vector2(3, 5), r * 0.95, Color("#7e7653"))
    draw_circle(p, r, Color("#fff3c7"))
    draw_circle(p + Vector2(-4, -5), r * 0.58, Color("#fffbe1"))

func _stack(base: Vector2, amount: int) -> void:
    var count := mini(amount, 32)
    for i in range(count):
        var row: int = i / 4
        var col: int = i % 4
        _egg(base + Vector2(col * 19 - 29, -row * 19), 11.0)

func _zone(p: Vector2, radius: float, color: Color) -> void:
    draw_arc(p, radius, 0.1, TAU - 0.1, 48, color, 7, true)

func _table(p: Vector2) -> void:
    _polygon([p + Vector2(-92, -10), p + Vector2(45, -40), p + Vector2(118, 4), p + Vector2(-19, 38)], Color("#4283a0"))
    _polygon([p + Vector2(-92, -10), p + Vector2(-19, 38), p + Vector2(-19, 83), p + Vector2(-92, 32)], Color("#8d4a30"))
    _polygon([p + Vector2(-19, 38), p + Vector2(118, 4), p + Vector2(118, 50), p + Vector2(-19, 83)], Color("#b96d45"))
    _polygon([p + Vector2(-90, -20), p + Vector2(45, -48), p + Vector2(114, -10), p + Vector2(-20, 22)], Color("#67b5d0"))
    draw_rect(Rect2(p + Vector2(48, -19), Vector2(30, 26)), Color("#515e71"))
    draw_rect(Rect2(p + Vector2(52, -17), Vector2(22, 5)), Color("#d1e3e4"))

func _truck(p: Vector2) -> void:
    _polygon([p + Vector2(-145, -92), p + Vector2(-8, -124), p + Vector2(68, -86), p + Vector2(-72, -53)], Color("#ffe046"))
    _polygon([p + Vector2(-145, -92), p + Vector2(-72, -53), p + Vector2(-72, 3), p + Vector2(-145, -32)], Color("#dd9f21"))
    _polygon([p + Vector2(-72, -53), p + Vector2(68, -86), p + Vector2(68, -26), p + Vector2(-72, 3)], Color("#f5c72f"))
    _polygon([p + Vector2(4, -74), p + Vector2(58, -84), p + Vector2(92, -45), p + Vector2(31, -30)], Color("#5ab0c9"))
    draw_circle(p + Vector2(-89, 0), 21, Color("#323f51"))
    draw_circle(p + Vector2(32, -19), 21, Color("#323f51"))
    draw_circle(p + Vector2(-89, 0), 10, Color("#c3d7d8"))
    draw_circle(p + Vector2(32, -19), 10, Color("#c3d7d8"))
    for i in range(6):
        _egg(p + Vector2(-90 + (i % 3) * 26, -102 - (i / 3) * 22), 12)

func _person(p: Vector2) -> void:
    draw_circle(p + Vector2(0, 8), 19, Color(0.2, 0.4, 0.25, 0.3))
    draw_line(p + Vector2(-9, -4), p + Vector2(-12, 24), Color("#254d79"), 12)
    draw_line(p + Vector2(9, -4), p + Vector2(10, 24), Color("#254d79"), 12)
    draw_line(p + Vector2(-13, -33), p + Vector2(-22, -3), Color("#f3bc8e"), 9)
    draw_line(p + Vector2(13, -33), p + Vector2(23, -3), Color("#f3bc8e"), 9)
    draw_rect(Rect2(p + Vector2(-17, -51), Vector2(34, 47)), Color("#ecf4dd"))
    draw_rect(Rect2(p + Vector2(-7, -46), Vector2(14, 37)), Color("#ef7791"))
    draw_circle(p + Vector2(0, -65), 19, Color("#f0b883"))
    draw_arc(p + Vector2(0, -73), 18, PI, TAU, 12, Color("#834d35"), 12)
    draw_circle(p + Vector2(-8, -68), 2, Color("#373437"))
    draw_circle(p + Vector2(8, -68), 2, Color("#373437"))

func _fence(a: Vector2, b: Vector2, posts: int) -> void:
    draw_line(a + Vector2(0, -29), b + Vector2(0, -29), Color("#b47a40"), 16)
    draw_line(a + Vector2(0, -10), b + Vector2(0, -10), Color("#9b6338"), 13)
    for i in range(posts + 1):
        var point := a.lerp(b, float(i) / float(posts))
        draw_line(point + Vector2(0, 10), point + Vector2(0, -53), Color("#ba844a"), 20)
        draw_line(point + Vector2(-5, 10), point + Vector2(-5, -53), Color("#dcad6c"), 5)

func _upgrade_pad(p: Vector2) -> void:
    _polygon([p + Vector2(0, -65), p + Vector2(86, 0), p + Vector2(0, 65), p + Vector2(-86, 0)], Color("#37d7de"))
    _polygon([p + Vector2(0, -57), p + Vector2(78, 0), p + Vector2(0, 57), p + Vector2(-78, 0)], Color("#4a5d67"))
    draw_rect(Rect2(p + Vector2(-26, -20), Vector2(52, 40)), Color("#83d951"))
    _world_text(p + Vector2(-22, 10), "$", 33, Color("#23572f"))

func _world_text(p: Vector2, value: String, size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _save() -> void:
    var data := {
        "cash": cash, "eggs": eggs, "carry": carry, "order_needed": order_needed,
        "order_loaded": order_loaded, "orders_done": orders_done,
        "station_level": station_level, "upgrade_cost": upgrade_cost,
        "player_x": player_position.x, "player_y": player_position.y
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))

func _load() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    if data is Dictionary:
        cash = maxi(0, int(data.get("cash", 0)))
        eggs = clampi(int(data.get("eggs", 7)), 0, 36)
        carry = clampi(int(data.get("carry", 0)), 0, 6)
        order_needed = maxi(1, int(data.get("order_needed", 5)))
        order_loaded = clampi(int(data.get("order_loaded", 0)), 0, order_needed - 1)
        orders_done = maxi(0, int(data.get("orders_done", 0)))
        station_level = clampi(int(data.get("station_level", 1)), 1, 5)
        upgrade_cost = maxi(60, int(data.get("upgrade_cost", 60)))
        player_position = Vector2(float(data.get("player_x", 385)), float(data.get("player_y", 790)))

func _reset() -> void:
    cash = 0
    eggs = 7
    carry = 0
    order_needed = 5
    order_loaded = 0
    orders_done = 0
    station_level = 1
    upgrade_cost = 60
    production_clock = 0.0
    transfer_clock = 0.0
    truck_depart_timer = 0.0
    player_position = Vector2(385, 790)
    joystick_active = false
    joystick_vector = Vector2.ZERO
    _save()
    _refresh()
    queue_redraw()
