extends Node3D

# Market Days — original playable recreation of the farm-market loop
# shown in the supplied gameplay recording. No proprietary game assets.
const SAVE_FILE := "user://market_days_v1.json"
const PRODUCT_NAMES := ["Tomato", "Cabbage", "Carrot", "Egg"]
const PRODUCT_COLORS := [
    Color("#e94b32"), Color("#55bb57"), Color("#edaa3a"), Color("#f7f1d8")
]

var cash := 0
var sales := 0
var served := 0
var machine_unlocked := false
var workers_hired := 0
var workers: Array[Node3D] = []
var worker_clock := 0.0
var game_clock := 0.0
var camera_zoom_size := 12.5
var camera_follow := true
var touch_positions: Dictionary = {}
var pinch_distance := 0.0
var hire_button: Button
var egg_button: Button
var zoom_in_button: Button
var zoom_out_button: Button
var center_button: Button
var right_controls: VBoxContainer
var carry_type := -1
var carry_count := 0
var capacity := 5
var shelf_stock: Array[int] = [9, 9, 9, 0]
var shelf_pos := [
    Vector3(6, 0, -4), Vector3(6, 0, 0), Vector3(6, 0, 4),
    Vector3(-7.3, 0, 4.5)
]
var customer_queue: Array[Dictionary] = []
var customer_timer := 0.0
var action_timer := 0.0
var stock_timer := 0.0
var toast_timer := 0.0
var floating_message := ""
var play_mode := "town"
var joystick_index := -1
var joystick_direction := Vector2.ZERO
var joystick_origin := Vector2(130, 575)
var mouse_joystick := false
var mats: Dictionary = {}
var market_root: Node3D
var town_root: Node3D
var player: Node3D
var camera: Camera3D
var ui_layer: CanvasLayer
var headline: Label
var detail: Label
var tip: Label
var mode_button: Button
var reset_button: Button
var joystick_panel: Panel
var joystick_thumb: Panel
var product_labels: Array[Label3D] = []
var carried_meshes: Array[MeshInstance3D] = []
var saved_player_position := Vector3(-2, 0, 5.3)
var unlock_pad: Node3D

func _ready() -> void:
    randomize()
    _load_game()
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 17.0
    camera.position = Vector3(16, 20, 19)
    add_child(camera)
    camera.make_current()
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-58, -40, 0)
    sun.light_energy = 1.7
    add_child(sun)
    town_root = Node3D.new()
    market_root = Node3D.new()
    add_child(town_root)
    add_child(market_root)
    _make_town()
    _make_market()
    _make_ui()
    _set_mode("town")

func _material(tint: Color) -> StandardMaterial3D:
    var key := tint.to_html()
    if mats.has(key):
        return mats[key] as StandardMaterial3D
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.82
    material.metallic = 0.0
    mats[key] = material
    return material

func _box(root: Node3D, p: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.material_override = _material(tint)
    part.position = p
    root.add_child(part)
    return part

func _ball(root: Node3D, p: Vector3, radius: float, tint: Color) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 12
    mesh.rings = 6
    part.mesh = mesh
    part.material_override = _material(tint)
    part.position = p
    root.add_child(part)
    return part

func _cylinder(root: Node3D, p: Vector3, radius: float, height: float, tint: Color) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 12
    part.mesh = mesh
    part.material_override = _material(tint)
    part.position = p
    root.add_child(part)
    return part

func _text3d(root: Node3D, p: Vector3, value: String, size: int = 42) -> Label3D:
    var text := Label3D.new()
    text.text = value
    text.font_size = size
    text.pixel_size = 0.008
    text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    text.modulate = Color("#fff9e3")
    text.outline_modulate = Color("#475448")
    text.outline_size = 9
    text.position = p
    root.add_child(text)
    return text

func _person(root: Node3D, p: Vector3, shirt: Color, with_hat: bool = false) -> Node3D:
    var figure := Node3D.new()
    root.add_child(figure)
    figure.position = p
    _cylinder(figure, Vector3(-0.16, 0.35, 0), 0.12, 0.65, Color("#456786"))
    _cylinder(figure, Vector3(0.16, 0.35, 0), 0.12, 0.65, Color("#456786"))
    _cylinder(figure, Vector3(0, 1.08, 0), 0.38, 0.9, shirt)
    _cylinder(figure, Vector3(-0.49, 1.02, 0), 0.11, 0.7, Color("#ecc39b"))
    _cylinder(figure, Vector3(0.49, 1.02, 0), 0.11, 0.7, Color("#ecc39b"))
    _ball(figure, Vector3(0, 1.86, 0), 0.33, Color("#efc49c"))
    _ball(figure, Vector3(0, 2.07, -0.08), 0.28, Color("#704c35"))
    if with_hat:
        _cylinder(figure, Vector3(0, 2.25, 0), 0.5, 0.10, Color("#e9c776"))
        _cylinder(figure, Vector3(0, 2.44, 0), 0.29, 0.35, Color("#e1b75b"))
    return figure

func _tree(root: Node3D, p: Vector3) -> void:
    _cylinder(root, p + Vector3(0, 0.7, 0), 0.24, 1.4, Color("#9b6c43"))
    _ball(root, p + Vector3(0, 2.2, 0), 1.1, Color("#3e9c48"))
    _ball(root, p + Vector3(0.5, 2.5, 0.2), 0.72, Color("#5fc45f"))

func _house(root: Node3D, p: Vector3, tint: Color) -> void:
    _box(root, p + Vector3(0, 0.85, 0), Vector3(2.6, 1.7, 2.1), tint)
    _box(root, p + Vector3(0, 1.85, 0), Vector3(3.1, 0.36, 2.5), Color("#bc5d42"))
    _box(root, p + Vector3(0, 0.62, 1.07), Vector3(0.56, 1.25, 0.08), Color("#815534"))
    _box(root, p + Vector3(-0.81, 1.0, 1.07), Vector3(0.5, 0.48, 0.09), Color("#92d9e4"))

func _fence(root: Node3D, a: Vector3, b: Vector3, parts: int) -> void:
    var middle := (a + b) * 0.5
    var direction := b - a
    for height in [0.47, 1.12]:
        var beam := _box(root, middle + Vector3(0, height, 0), Vector3(direction.length(), 0.13, 0.14), Color("#cb9250"))
        beam.rotation.y = -atan2(direction.z, direction.x)
    for i in range(parts + 1):
        var pos := a.lerp(b, float(i) / float(parts))
        _box(root, pos + Vector3(0, 0.82, 0), Vector3(0.22, 1.64, 0.22), Color("#dba761"))

func _make_town() -> void:
    _box(town_root, Vector3(0, -0.26, 0), Vector3(26, 0.5, 21), Color("#77bb55"))
    _box(town_root, Vector3(0, 0.01, 2.4), Vector3(26, 0.11, 2.3), Color("#8797a2"))
    _box(town_root, Vector3(1.3, 0.02, -2), Vector3(2.3, 0.10, 18), Color("#8b9ba6"))
    for i in range(8):
        _box(town_root, Vector3(-11 + i * 3.1, 0.08, 2.4), Vector3(1.3, 0.06, 0.08), Color("#f5dfb1"))
    for position in [Vector3(-9, 0, -5), Vector3(-5, 0, -5), Vector3(6, 0, -6), Vector3(9, 0, 6)]:
        _house(town_root, position, Color("#f1c68e"))
    for position in [Vector3(-11, 0, 7), Vector3(-7, 0, 8), Vector3(11, 0, -6), Vector3(8, 0, -9)]:
        _tree(town_root, position)
    _box(town_root, Vector3(4.9, 0.1, -1), Vector3(6.0, 0.3, 5.4), Color("#e2bd78"))
    _box(town_root, Vector3(4.9, 1.9, -1), Vector3(6.0, 3.3, 5.4), Color("#d8bd7d"))
    _box(town_root, Vector3(4.9, 3.8, -1), Vector3(6.7, 0.5, 6.2), Color("#c15c47"))
    _text3d(town_root, Vector3(4.9, 5.0, -1), "FRESH MARKET", 70)
    _box(town_root, Vector3(-7, 0.1, 1.2), Vector3(5.4, 0.18, 4.0), Color("#977447"))
    for i in range(5):
        for j in range(3):
            _ball(town_root, Vector3(-9.0 + i * 0.9, 0.4, -0.1 + j * 1.2), 0.29, Color("#e9bc42"))
    _text3d(town_root, Vector3(-1, 4.0, -4), "GROW • DELIVER • EXPAND", 54)

func _shelf(root: Node3D, p: Vector3, kind: int) -> Node3D:
    var shelf := Node3D.new()
    root.add_child(shelf)
    shelf.position = p
    _box(shelf, Vector3(0, 0.8, 0), Vector3(1.4, 1.55, 2.7), Color("#95623e"))
    for level in range(3):
        _box(shelf, Vector3(0.13, 0.4 + level * 0.46, 0), Vector3(1.55, 0.14, 2.83), Color("#e4ae5f"))
        for i in range(3):
            _box(shelf, Vector3(0.28, 0.58 + level * 0.46, -0.8 + i * 0.8), Vector3(0.72, 0.25, 0.64), Color("#c39352"))
            for item in range(3):
                var offset := Vector3(0.06, 0, -0.22 + item * 0.22)
                _ball(shelf, Vector3(0.4, 0.82 + level * 0.46, -0.8 + i * 0.8) + offset, 0.19, PRODUCT_COLORS[kind])
    return shelf

func _make_market() -> void:
    _box(market_root, Vector3(0, -0.19, 0), Vector3(23, 0.34, 16.5), Color("#f5cf8d"))
    _box(market_root, Vector3(0, 0.03, -7.8), Vector3(23, 0.24, 0.8), Color("#bb7150"))
    _box(market_root, Vector3(10.9, 0.03, 0), Vector3(0.8, 0.24, 16), Color("#b97550"))
    _fence(market_root, Vector3(-10.8, 0, -7), Vector3(-10.8, 0, 7.1), 9)
    _fence(market_root, Vector3(-10.8, 0, 7.1), Vector3(10.8, 0, 7.1), 12)
    _box(market_root, Vector3(5, 2.0, -7.5), Vector3(9.5, 4.0, 0.4), Color("#a95a46"))
    for i in range(7):
        _box(market_root, Vector3(1.0 + i * 1.25, 2.0, -7.20), Vector3(0.17, 3.5, 0.18), Color("#e3bd81"))
    _text3d(market_root, Vector3(5, 4.7, -6.6), "FRESH MARKET", 66)
    _shelf(market_root, Vector3(-8.0, 0, -2), 0)
    _shelf(market_root, Vector3(-8.0, 0, 1.2), 1)
    _shelf(market_root, shelf_pos[0], 0)
    _shelf(market_root, shelf_pos[1], 1)
    _shelf(market_root, shelf_pos[2], 2)
    _box(market_root, Vector3(-2.3, 0.9, -0.9), Vector3(3.3, 1.8, 1.55), Color("#7f4534"))
    _box(market_root, Vector3(-2.3, 1.84, -0.9), Vector3(3.45, 0.18, 1.77), Color("#b26a4c"))
    _box(market_root, Vector3(-2.3, 2.25, -1.1), Vector3(0.75, 0.7, 0.6), Color("#278fb8"))
    _box(market_root, Vector3(-2.3, 2.61, -1.1), Vector3(0.8, 0.08, 0.65), Color("#51badd"))
    _box(market_root, Vector3(-5.0, 0.05, 0.1), Vector3(1.8, 0.07, 1.2), Color("#49917f"))
    _text3d(market_root, Vector3(-5.0, 0.45, 0.1), "$ CASH", 28)
    _box(market_root, Vector3(2.5, 0.035, 3.5), Vector3(2.2, 0.06, 2.2), Color("#389fb4"))
    _box(market_root, Vector3(2.5, 0.08, 3.5), Vector3(1.85, 0.1, 1.85), Color("#77c858"))
    _text3d(market_root, Vector3(2.5, 0.45, 3.5), "UNLOCK $80", 30)
    unlock_pad = Node3D.new()
    market_root.add_child(unlock_pad)
    # The eggs are sold from a dedicated table on the opposite side of the shop.
    unlock_pad.position = shelf_pos[3]
    _build_egg_machine(unlock_pad)
    unlock_pad.visible = machine_unlocked
    _text3d(market_root, Vector3(-1.3, 3, -1.5), "CHECKOUT", 42)
    player = _person(market_root, saved_player_position, Color("#f4d7d2"))
    _box(player, Vector3(0, 1.15, 0.4), Vector3(0.55, 0.83, 0.12), Color("#ec7190"))
    for i in range(capacity):
        var cargo := _ball(player, Vector3(-0.38 + float(i % 3) * 0.38, 2.55 + float(i / 3) * 0.38, 0), 0.19, Color("#fff4db"))
        carried_meshes.append(cargo)
    _render_carry()
    _text3d(market_root, shelf_pos[3] + Vector3(0, 2.6, 0), "EGG CORNER", 37)
    _text3d(player, Vector3(0, 3.1, 0), "YOU", 35)
    for i in range(workers_hired):
        _spawn_worker(i)
    _update_shelf_labels()

func _spawn_worker(index: int) -> void:
    var start := Vector3(-0.5 + float(index) * 0.8, 0, 3.4)
    var npc := _person(market_root, start, Color("#368eb5"), true)
    _text3d(npc, Vector3(0, 2.9, 0), "STAFF %d" % (index + 1), 30)
    workers.append(npc)

func _worker_service() -> void:
    if workers_hired == 0 or customer_queue.is_empty():
        return
    var kind: int = int(customer_queue[0]["kind"])
    if kind == 3 and not machine_unlocked:
        return
    if shelf_stock[kind] < 1:
        return
    shelf_stock[kind] -= 1
    var guest: Node3D = customer_queue[0]["node"]
    guest.queue_free()
    customer_queue.pop_front()
    var payment := 12 + kind * 3
    cash += payment
    sales += payment
    served += 1
    _say("Staff delivered %s: +$%d" % [PRODUCT_NAMES[kind], payment])
    _update_shelf_labels()
    _save_game()

func _hire_worker() -> void:
    var price := 70 + 60 * workers_hired
    if play_mode != "market" or workers_hired >= 3 or cash < price:
        return
    cash -= price
    workers_hired += 1
    _spawn_worker(workers_hired - 1)
    _say("Worker hired! Staff can now serve orders.")
    _save_game()
    _refresh_ui()

func _unlock_eggs() -> void:
    if play_mode != "market" or machine_unlocked or cash < 80:
        return
    cash -= 80
    machine_unlocked = true
    shelf_stock[3] = 9
    unlock_pad.visible = true
    _update_shelf_labels()
    _say("Egg stall unlocked on the LEFT of the market.")
    _save_game()
    _refresh_ui()

func _build_egg_machine(root: Node3D) -> void:
    _box(root, Vector3(0, 0.6, 0), Vector3(2.0, 1.1, 1.5), Color("#7e5945"))
    _box(root, Vector3(0, 0.09, 0), Vector3(2.6, 0.14, 2.2), Color("#448aa4"))
    _box(root, Vector3(0, 1.18, 0), Vector3(2.0, 0.18, 1.5), Color("#4c8797"))
    for i in range(4):
        _ball(root, Vector3(-0.55 + i * 0.37, 1.42, 0), 0.22, PRODUCT_COLORS[3])
    _text3d(root, Vector3(0, 2.35, 0), "EGG PACKER", 36)

func _render_carry() -> void:
    for i in range(carried_meshes.size()):
        carried_meshes[i].visible = i < carry_count
        if carry_type >= 0 and carry_type < PRODUCT_COLORS.size():
            carried_meshes[i].material_override = _material(PRODUCT_COLORS[carry_type])

func _update_shelf_labels() -> void:
    for label in product_labels:
        if is_instance_valid(label):
            label.queue_free()
    product_labels.clear()
    for i in range(3):
        product_labels.append(_text3d(market_root, shelf_pos[i] + Vector3(0, 3.0, 0), "%s  %d" % [PRODUCT_NAMES[i], shelf_stock[i]], 33))
    if machine_unlocked:
        product_labels.append(_text3d(market_root, shelf_pos[3] + Vector3(0, 2.7, 0), "Egg  %d" % shelf_stock[3], 33))

func _make_ui() -> void:
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_layer.add_child(root)
    var hud := PanelContainer.new()
    hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
    hud.offset_bottom = 80
    root.add_child(hud)
    var row := HBoxContainer.new()
    hud.add_child(row)
    headline = Label.new()
    headline.add_theme_font_size_override("font_size", 25)
    headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(headline)
    detail = Label.new()
    detail.add_theme_font_size_override("font_size", 21)
    detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(detail)
    mode_button = Button.new()
    mode_button.custom_minimum_size = Vector2(175, 70)
    mode_button.pressed.connect(_toggle_mode)
    row.add_child(mode_button)
    reset_button = Button.new()
    reset_button.text = "New game"
    reset_button.custom_minimum_size = Vector2(125, 70)
    reset_button.pressed.connect(_reset)
    row.add_child(reset_button)
    var bottom := PanelContainer.new()
    bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.offset_top = -65
    root.add_child(bottom)
    tip = Label.new()
    tip.add_theme_font_size_override("font_size", 21)
    tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bottom.add_child(tip)
    joystick_panel = Panel.new()
    joystick_panel.position = Vector2(49, 475)
    joystick_panel.size = Vector2(188, 188)
    joystick_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(joystick_panel)
    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.2, 0.34, 0.43, 0.28)
    base_style.set_corner_radius_all(100)
    joystick_panel.add_theme_stylebox_override("panel", base_style)
    joystick_thumb = Panel.new()
    joystick_thumb.size = Vector2(82, 82)
    joystick_thumb.position = Vector2(53, 53)
    joystick_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_panel.add_child(joystick_thumb)
    var thumb_style := StyleBoxFlat.new()
    thumb_style.bg_color = Color(0.77, 0.95, 0.93, 0.73)
    thumb_style.set_corner_radius_all(50)
    joystick_thumb.add_theme_stylebox_override("panel", thumb_style)

func _set_mode(target: String) -> void:
    play_mode = target
    market_root.visible = target == "market"
    town_root.visible = target == "town"
    joystick_panel.visible = target == "market"
    if target == "market":
        camera.position = Vector3(15, 19, 18)
        camera.size = 17.0
        camera.look_at(Vector3(0, 0, 0))
        mode_button.text = "Town"
    else:
        camera.position = Vector3(19, 24, 25)
        camera.size = 22.0
        camera.look_at(Vector3(0, 0, 0))
        mode_button.text = "Enter Market"
    _refresh_ui()

func _toggle_mode() -> void:
    if play_mode == "town":
        _set_mode("market")
    else:
        _set_mode("town")

func _refresh_ui() -> void:
    if play_mode == "town":
        headline.text = "MARKET DAYS    •    GREEN VALLEY"
        detail.text = "Town overview • Visit your market"
        tip.text = "Tap ENTER MARKET to play the market management game."
        return
    headline.text = "CASH  $%d    •    SERVED  %d" % [cash, served]
    if customer_queue.size() > 0:
        var wanted: int = int(customer_queue[0]["kind"])
        detail.text = "NEXT: %s   |   Carry: %s %d/%d" % [PRODUCT_NAMES[wanted], PRODUCT_NAMES[carry_type] if carry_type >= 0 else "None", carry_count, capacity]
    else:
        detail.text = "Customers arriving  |  Carry %d/%d" % [carry_count, capacity]
    if toast_timer > 0.0:
        tip.text = floating_message
    elif not machine_unlocked:
        tip.text = "Collect produce on the right • Serve at checkout • Unlock egg packer for $80"
    else:
        tip.text = "Collect stock • Serve waiting customers • Keep growing your shop"

func _spawn_customer() -> void:
    if customer_queue.size() >= 5:
        return
    var type_max := 3 if machine_unlocked else 2
    var kind := randi_range(0, type_max)
    var shirt: Color = [Color("#6ba6d8"), Color("#b76d83"), Color("#7fbe64"), Color("#e7bd55")][kind]
    var character := _person(market_root, Vector3(1.0, 0, 7.8), shirt, kind == 0)
    var request := _text3d(character, Vector3(0, 2.85, 0), PRODUCT_NAMES[kind], 32)
    request.modulate = PRODUCT_COLORS[kind]
    customer_queue.append({"node": character, "kind": kind})

func _process(delta: float) -> void:
    if play_mode != "market":
        return
    customer_timer += delta
    action_timer += delta
    stock_timer += delta
    toast_timer = maxf(0.0, toast_timer - delta)
    if customer_timer >= 2.9:
        customer_timer = 0.0
        _spawn_customer()
    for i in range(customer_queue.size()):
        var customer: Node3D = customer_queue[i]["node"]
        var destination := Vector3(-0.6, 0, 1.8 + float(i) * 1.18)
        customer.position = customer.position.lerp(destination, minf(delta * 2.6, 1.0))
    if joystick_direction.length() > 0.03:
        var screen_right := Vector3(camera.global_transform.basis.x.x, 0, camera.global_transform.basis.x.z).normalized()
        var screen_up := Vector3(camera.global_transform.basis.y.x, 0, camera.global_transform.basis.y.z).normalized()
        var movement := (screen_right * joystick_direction.x - screen_up * joystick_direction.y).normalized()
        player.position += movement * 5.8 * delta * minf(1.0, joystick_direction.length())
        player.position.x = clampf(player.position.x, -9.7, 9.7)
        player.position.z = clampf(player.position.z, -6.2, 6.2)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(movement.x, movement.z), minf(delta * 11.0, 1.0))
    if stock_timer >= 2.5:
        stock_timer = 0.0
        for i in range(4):
            if i < 3 or machine_unlocked:
                shelf_stock[i] = mini(16, shelf_stock[i] + 1)
        _update_shelf_labels()
    if action_timer >= 0.31:
        action_timer = 0.0
        _try_interact()
    _refresh_ui()

func _try_interact() -> void:
    if not machine_unlocked and player.position.distance_to(Vector3(2.5, 0, 3.5)) < 1.5 and cash >= 80:
        cash -= 80
        machine_unlocked = true
        shelf_stock[3] = 9
        unlock_pad.visible = true
        _say("Egg packer unlocked! New orders are arriving.")
        _update_shelf_labels()
        _save_game()
        return
    if carry_count > 0:
        for i in range(4):
            if i == 3 and not machine_unlocked:
                continue
            if player.position.distance_to(shelf_pos[i]) < 2.0:
                if carry_type != i and shelf_stock[i] > 0:
                    shelf_stock[carry_type] = mini(16, shelf_stock[carry_type] + carry_count)
                    carry_type = i
                    carry_count = mini(capacity, shelf_stock[i])
                    shelf_stock[i] -= carry_count
                    _render_carry()
                    _say("Switched to %s" % PRODUCT_NAMES[i])
                    _update_shelf_labels()
                    _save_game()
                    return
                elif carry_type == i and carry_count < capacity and shelf_stock[i] > 0:
                    var amount := mini(capacity - carry_count, shelf_stock[i])
                    carry_count += amount
                    shelf_stock[i] -= amount
                    _render_carry()
                    _update_shelf_labels()
                    _save_game()
                    return
    if carry_count == 0:
        for i in range(4):
            if i == 3 and not machine_unlocked:
                continue
            if player.position.distance_to(shelf_pos[i]) < 2.25 and shelf_stock[i] > 0:
                carry_type = i
                carry_count = mini(capacity, shelf_stock[i])
                shelf_stock[i] -= carry_count
                _render_carry()
                _say("Picked up %d %s" % [carry_count, PRODUCT_NAMES[i]])
                _update_shelf_labels()
                _save_game()
                return
    if carry_count > 0 and player.position.distance_to(Vector3(-2.3, 0, 0.55)) < 2.0 and customer_queue.size() > 0:
        var kind: int = int(customer_queue[0]["kind"])
        if kind == carry_type:
            var customer: Node3D = customer_queue[0]["node"]
            customer.queue_free()
            customer_queue.pop_front()
            carry_count -= 1
            cash += 12 + kind * 3
            sales += 12 + kind * 3
            served += 1
            if carry_count == 0:
                carry_type = -1
            _render_carry()
            _say("+$%d  Sale complete!" % (12 + kind * 3))
            _save_game()
        else:
            _say("Customer wants %s — collect it from the shelves." % PRODUCT_NAMES[kind])

func _say(message: String) -> void:
    floating_message = message
    toast_timer = 2.5

func _input(event: InputEvent) -> void:
    if play_mode != "market":
        return
    if event is InputEventScreenTouch:
        if event.pressed and joystick_index < 0 and event.position.x < 420 and event.position.y > 230:
            joystick_index = event.index
            joystick_origin = event.position
            joystick_direction = Vector2.ZERO
        elif not event.pressed and joystick_index == event.index:
            joystick_index = -1
            joystick_direction = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == joystick_index:
        joystick_direction = (event.position - joystick_origin).limit_length(80.0) / 80.0
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and event.position.x < 420 and event.position.y > 230:
            mouse_joystick = true
            joystick_origin = event.position
        elif not event.pressed:
            mouse_joystick = false
            joystick_direction = Vector2.ZERO
    elif event is InputEventMouseMotion and mouse_joystick:
        joystick_direction = (event.position - joystick_origin).limit_length(80.0) / 80.0
    if joystick_thumb != null:
        joystick_thumb.position = Vector2(53, 53) + joystick_direction * 42.0

func _save_game() -> void:
    var stored := {
        "cash": cash, "sales": sales, "served": served,
        "machine_unlocked": machine_unlocked,
        "carry_type": carry_type, "carry_count": carry_count,
        "stock": shelf_stock,
        "player_x": player.position.x if player != null else -2.0,
        "player_z": player.position.z if player != null else 4.0
    }
    var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(stored))

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_FILE):
        return
    var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    if data is Dictionary:
        cash = maxi(0, int(data.get("cash", 0)))
        sales = maxi(0, int(data.get("sales", 0)))
        served = maxi(0, int(data.get("served", 0)))
        machine_unlocked = bool(data.get("machine_unlocked", false))
        carry_type = clampi(int(data.get("carry_type", -1)), -1, 3)
        carry_count = clampi(int(data.get("carry_count", 0)), 0, capacity)
        saved_player_position = Vector3(float(data.get("player_x", -2.0)), 0, float(data.get("player_z", 4.0)))
        var old_stock = data.get("stock", [9, 9, 9, 0])
        if old_stock is Array and old_stock.size() == 4:
            for i in range(4):
                shelf_stock[i] = clampi(int(old_stock[i]), 0, 16)

func _reset() -> void:
    cash = 0
    served = 0
    sales = 0
    machine_unlocked = false
    carry_type = -1
    carry_count = 0
    shelf_stock = [9, 9, 9, 0]
    customer_timer = 0.0
    action_timer = 0.0
    stock_timer = 0.0
    for entry in customer_queue:
        var npc: Node3D = entry["node"]
        if is_instance_valid(npc):
            npc.queue_free()
    customer_queue.clear()
    if is_instance_valid(player):
        player.position = Vector3(-2, 0, 4.0)
    unlock_pad.visible = false
    _render_carry()
    _update_shelf_labels()
    _save_game()
    _set_mode("town")
