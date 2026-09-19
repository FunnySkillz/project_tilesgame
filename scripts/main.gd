extends Control

enum TileKind { WATER, LAND, DOCK, PLAZA, ROAD, EXPANSION }
enum WaterZone { SHALLOW, OPEN, COLD, DEEP, MONSTER }
enum BuildKind { NONE, POOL, CUTTER, MARKET, STORAGE, SMOKER }
enum GoalStep { CATCH, STORE, PROCESS, SELL, UPGRADE, BUILD, NET_TWO, SILVERFISH, STORAGE, EXPAND, STABLE_SALES, SMOKER, SMOKED_SALE, COOK_SALE, MERCHANT_ORDER, DOCK_ORDER, COMPLETE }
enum FishKind { MINNOW, CARP, SILVERFISH }
enum BuyerKind { VILLAGER, COOK, MERCHANT }

const BoatAgentScript := preload("res://scripts/fishing/BoatAgent.gd")
const FishAgentScript := preload("res://scripts/fishing/FishAgent.gd")
const PlayerAgentScript := preload("res://scripts/people/PlayerAgent.gd")
const FISHERMAN_TEXTURE := preload("res://assets/runtime_art/fisherman.png")
const VILLAGER_TEXTURE := preload("res://assets/runtime_art/villager.png")
const LIVE_POOL_TEXTURE := preload("res://assets/runtime_art/live_pool.png")
const CUTTER_TEXTURE := preload("res://assets/runtime_art/cutter.png")
const MARKET_TEXTURE := preload("res://assets/runtime_art/market.png")
const BOAT_TEXTURE := preload("res://assets/runtime_art/boat.png")
const MINNOW_TEXTURE := preload("res://assets/runtime_art/minnow.png")
const CARP_TEXTURE := preload("res://assets/runtime_art/carp.png")
const SILVERFISH_TEXTURE := preload("res://assets/runtime_art/silverfish.png")
const WATER_TILE_TEXTURE := preload("res://assets/runtime_art/tiles/water.png")
const DOCK_TILE_TEXTURE := preload("res://assets/runtime_art/tiles/dock.png")
const PLAZA_TILE_TEXTURE := preload("res://assets/runtime_art/tiles/plaza.png")
const ROAD_TILE_TEXTURE := preload("res://assets/runtime_art/tiles/road.png")
const LAND_TILE_TEXTURE := preload("res://assets/runtime_art/tiles/land.png")
const FRONTIER_TILE_TEXTURE := preload("res://assets/runtime_art/tiles/frontier.png")
const DOCK_LAMP_TEXTURE := preload("res://assets/runtime_art/dock_lamp.png")
const DOCK_ORDER_BOARD_TEXTURE := preload("res://assets/runtime_art/dock_order_board.png")

const GRID_W := 16
const GRID_H := 18
const WATER_ROWS := 4
const ROAD_ROW := 12
const MAX_CUSTOMERS := 12

const TOOL_CATCH := "catch"
const TOOL_WALK := "walk"
const TOOL_PEOPLE := "people"
const TOOL_POOL := "pool"
const TOOL_CUTTER := "cutter"
const TOOL_MARKET := "market"
const TOOL_STORAGE := "storage"
const TOOL_SMOKER := "smoker"
const TOOL_EXPAND := "expand"
const TOOL_MAP := "map"
const TOOL_MOVE := "move"
const TOOL_REMOVE := "remove"

const COST_POOL := 10
const COST_CUTTER := 15
const COST_MARKET := 20
const COST_STORAGE := 25
const COST_SMOKER := 45
const COST_EXPAND := 35
const COST_WORKER := 150
const COST_WORKER_TRAIN := 60
const MAX_WORKERS := 6
const WORKER_MAX_SKILL := 3
const WORKER_SKILL_XP_BASE := 4

const CUSTOMER_PATIENCE_SECONDS := 10.0
const MARKET_SELL_SECONDS := 1.25
const CUSTOMER_WALK_SPEED := 2.35
const WORKER_WALK_SPEED := 2.85
const WORKER_FISH_SECONDS := 4.5
const WORKER_POOL_CAPACITY_BONUS := 2
const WORKER_CUTTER_RATE_BONUS := 0.35
const WORKER_SMOKER_RATE_BONUS := 0.35
const WORKER_STORAGE_CAPACITY_BONUS := 4
const ACTIVE_FISH_MAX := 18
const BOAT_DOCK_X := 5.5
const NET_CATCH_RADIUS := 0.34
const PLAYER_FISH_CAPACITY := 3
const PLAYER_MEAT_CAPACITY := 3
const PLAYER_CUT_SECONDS := 2.25
const PLAYER_SALE_SECONDS := 0.55
const MONSTER_WARNING_SECONDS := 6.0
const MONSTER_WARNING_DECAY := 1.15
const SMOKER_SECONDS := 6.0
const MEAT_PRICE := 12
const SMOKED_MEAT_PRICE := 14
const COOK_SMOKED_MEAT_PRICE := 18
const MERCHANT_BULK_SIZE := 3
const MERCHANT_BULK_BONUS := 5
const DOCK_ORDER_SECONDS := 50.0
const DOCK_ORDER_COOLDOWN_SECONDS := 8.0
const DOCK_ORDER_BONUS := 24
const SMOKER_INPUT_MEAT := 2
const SMOKER_OUTPUT_SMOKED := 1

var tiles: Array = []
var selected_tool := TOOL_WALK
var money := 30
var carried_fish_stock: Array = [0, 0, 0]
var live_fish_stock: Array = [0, 0, 0]
var meat := 0
var smoked_meat := 0
var net_level := 1
var pool_level := 1
var cutter_level := 1
var customers_waiting := 0
var customers_lost := 0
var customer_timer := 4.0
var customer_patience_timer := CUSTOMER_PATIENCE_SECONDS
var market_sell_timer := MARKET_SELL_SECONDS
var cutter_progress := 0.0
var smoker_progress := 0.0
var status_text := "Walk to the dock, select Fish, and tap a nearby fish to fill your basket."
var goal_step := GoalStep.CATCH
var fish_caught_total := 0
var fish_caught_by_kind: Array = [0, 0, 0]
var fish_stored_total := 0
var meat_processed_total := 0
var meat_sold_total := 0
var smoked_meat_sold_total := 0
var buyers_served_by_kind: Array = [0, 0, 0]
var merchant_orders_completed_total := 0
var dock_orders_completed_total := 0
var dock_order_active := false
var dock_order_name := ""
var dock_order_need_meat := 0
var dock_order_need_smoked := 0
var dock_order_delivered_meat := 0
var dock_order_delivered_smoked := 0
var dock_order_timer := 0.0
var dock_order_cooldown := 2.0
var upgrades_bought_total := 0
var buildings_built_total := 0
var storage_unlocked := false
var land_expanded_total := 0
var customer_agents: Array = []
var workers: Array = []
var selected_worker_index := -1
var active_fish_agents: Array = []
var boat_agent = BoatAgentScript.new()
var player_agent = PlayerAgentScript.new()
var player_fish_stock: Array = [0, 0, 0]
var player_meat := 0
var player_cut_progress := 0.0
var player_sale_cooldown := 0.0
var dragging_boat := false
var dragging_map := false
var map_drag_origin := Vector2.ZERO
var map_camera_drag_origin := Vector2.ZERO
var map_camera := Vector2(2.0, 2.0)
var water_zone_catches: Array = [0, 0, 0, 0, 0]
var water_zone_discovered: Array = [false, false, false, false, false]
var monster_warning := 0.0
var monster_warning_notice_timer := 0.0

var grid_rect := Rect2()
var tile_px := 48.0
var selected_cell := Vector2i(-1, -1)
var moving_building := BuildKind.NONE
var move_source_cell := Vector2i(-1, -1)
var feedback_popups: Array = []
var hud_label: Label
var goal_label: Label
var unlock_label: Label
var inspector_label: Label
var status_label: Label
var tool_buttons: Dictionary = {}
var command_buttons: Dictionary = {}


func _ready() -> void:
	randomize()
	_init_tiles()
	_init_active_fishing()
	_init_player()
	_init_people()
	_build_ui()
	_calculate_grid_rect()
	_center_map(false)
	_update_hud()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_tick_fish_spawns(delta)
	_tick_active_fishing(delta)
	_tick_player(delta)
	_tick_workers(delta)
	_tick_cutters(delta)
	_tick_smokers(delta)
	_tick_dock_order(delta)
	_tick_customers(delta)
	_tick_feedback_popups(delta)
	_check_goal_progress()
	_update_hud()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not _try_start_map_drag(event.position) and not _try_start_boat_drag(event.position):
				_try_handle_tap(event.position)
		else:
			dragging_boat = false
			dragging_map = false
	elif event is InputEventMouseMotion:
		if dragging_map:
			_update_map_drag(event.position)
		elif dragging_boat:
			_update_boat_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if not _try_start_map_drag(event.position) and not _try_start_boat_drag(event.position):
				_try_handle_tap(event.position)
		else:
			dragging_boat = false
			dragging_map = false
	elif event is InputEventScreenDrag:
		if dragging_map:
			_update_map_drag(event.position)
		elif dragging_boat:
			_update_boat_drag(event.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	_calculate_grid_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color("#17212b"))
	_draw_grid()
	_draw_active_fishing()
	_draw_people()
	_draw_dock_order_board()
	_draw_footer_hint()
	_draw_feedback_popups()


func _init_tiles() -> void:
	tiles.clear()
	for y in GRID_H:
		var row: Array = []
		for x in GRID_W:
			var cell := Vector2i(x, y)
			var kind := TileKind.EXPANSION
			if y < WATER_ROWS:
				kind = TileKind.WATER
			elif y == ROAD_ROW:
				kind = TileKind.ROAD
			elif y == WATER_ROWS and x >= 3 and x <= 10:
				kind = TileKind.DOCK
			elif _is_starter_plaza_cell(cell):
				kind = TileKind.PLAZA
			elif _is_starter_land_cell(cell):
				kind = TileKind.LAND
			var water_zone := _water_zone_for_cell(cell) if kind == TileKind.WATER else WaterZone.SHALLOW
			var fish_kind := _random_fish_kind_for_zone(water_zone)
			var fish_count := randi_range(1, 2) if kind == TileKind.WATER and randf() < 0.45 else 0
			row.append({
				"kind": kind,
				"water_zone": water_zone,
				"building": BuildKind.NONE,
				"fish": fish_count,
				"fish_kind": fish_kind,
				"spawn_timer": randf_range(2.0, 6.0)
			})
		tiles.append(row)

	_set_starter_building(Vector2i(4, WATER_ROWS), BuildKind.POOL)
	_set_starter_building(Vector2i(5, WATER_ROWS), BuildKind.CUTTER)
	_set_starter_building(Vector2i(10, ROAD_ROW - 1), BuildKind.MARKET)


func _is_starter_plaza_cell(cell: Vector2i) -> bool:
	if cell.x == 8 and cell.y >= WATER_ROWS + 1 and cell.y <= ROAD_ROW - 1:
		return true
	if cell.y == ROAD_ROW - 1 and cell.x >= 8 and cell.x <= 10:
		return true
	if cell.y == ROAD_ROW - 2 and cell.x >= 9 and cell.x <= 10:
		return true
	return false


func _is_starter_land_cell(cell: Vector2i) -> bool:
	return cell.x >= 4 and cell.x <= 11 and cell.y >= WATER_ROWS + 1 and cell.y < ROAD_ROW


func _is_buildable_tile_kind(kind: int) -> bool:
	return kind == TileKind.LAND or kind == TileKind.DOCK or kind == TileKind.PLAZA


func _buildable_tile_text() -> String:
	return "land, dock, or plaza tiles"


func _tile_surface_name(kind: int) -> String:
	match kind:
		TileKind.DOCK:
			return "dock"
		TileKind.PLAZA:
			return "plaza"
		TileKind.ROAD:
			return "road"
		TileKind.EXPANSION:
			return "expansion ground"
		TileKind.WATER:
			return "water"
		_:
			return "land"


func _set_starter_building(cell: Vector2i, building: int) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	tile["building"] = building
	tiles[cell.y][cell.x] = tile


func _water_zone_for_cell(cell: Vector2i) -> int:
	if cell.y >= WATER_ROWS:
		return WaterZone.SHALLOW
	if cell.y == WATER_ROWS - 1:
		return WaterZone.SHALLOW
	if cell.y == 0 and cell.x >= GRID_W - 4:
		return WaterZone.MONSTER
	if cell.x <= 2:
		return WaterZone.COLD
	if cell.y == 0:
		return WaterZone.DEEP
	return WaterZone.OPEN


func _water_zone_at_world_position(position: Vector2) -> int:
	var cell := Vector2i(
		int(clamp(floor(position.x), 0.0, float(GRID_W - 1))),
		int(clamp(floor(position.y), 0.0, float(WATER_ROWS - 1)))
	)
	var tile: Dictionary = tiles[cell.y][cell.x]
	return int(tile["water_zone"])


func _water_zone_name(water_zone: int) -> String:
	match water_zone:
		WaterZone.SHALLOW:
			return "shallow water"
		WaterZone.OPEN:
			return "open water"
		WaterZone.COLD:
			return "cold water"
		WaterZone.DEEP:
			return "deep water"
		WaterZone.MONSTER:
			return "monster water"
		_:
			return "water"


func _water_zone_short_name(water_zone: int) -> String:
	match water_zone:
		WaterZone.SHALLOW:
			return "SHALLOW"
		WaterZone.OPEN:
			return "OPEN"
		WaterZone.COLD:
			return "COLD"
		WaterZone.DEEP:
			return "DEEP"
		WaterZone.MONSTER:
			return "MONSTER"
		_:
			return "WATER"


func _water_zone_hint(water_zone: int) -> String:
	match water_zone:
		WaterZone.SHALLOW:
			return "Minnows gather here."
		WaterZone.OPEN:
			return "Balanced early catches."
		WaterZone.COLD:
			return "Fish move slower; first cold catch pays a route bonus."
		WaterZone.DEEP:
			return "Better fish move faster; first deep catch pays a route bonus."
		WaterZone.MONSTER:
			return "Rich early mix; warning builds here before real danger arrives."
		_:
			return ""


func _water_zone_color(water_zone: int) -> Color:
	match water_zone:
		WaterZone.SHALLOW:
			return Color("#2e8fa2")
		WaterZone.OPEN:
			return Color("#2476a0")
		WaterZone.COLD:
			return Color("#5fa7c7")
		WaterZone.DEEP:
			return Color("#15476d")
		WaterZone.MONSTER:
			return Color("#18324f")
		_:
			return Color("#326b82")


func _water_zone_speed_modifier(water_zone: int) -> float:
	match water_zone:
		WaterZone.SHALLOW:
			return 0.92
		WaterZone.COLD:
			return 0.72
		WaterZone.DEEP:
			return 1.1
		WaterZone.MONSTER:
			return 1.28
		_:
			return 1.0


func _water_zone_discovery_reward(water_zone: int) -> int:
	match water_zone:
		WaterZone.COLD:
			return 4
		WaterZone.DEEP:
			return 6
		WaterZone.MONSTER:
			return 10
		_:
			return 0


func _water_zone_warning_label() -> String:
	if monster_warning <= 0.01:
		return ""
	var ratio: float = clamp(monster_warning / MONSTER_WARNING_SECONDS, 0.0, 1.0)
	if ratio >= 0.85:
		return " Monster water warning high."
	if ratio >= 0.45:
		return " Monster water warning rising."
	return " Monster water feels uneasy."


func _init_active_fishing() -> void:
	active_fish_agents.clear()
	boat_agent.setup(_boat_home_position())
	for i in ACTIVE_FISH_MAX:
		_spawn_active_fish()


func _spawn_active_fish() -> void:
	var water_zone := _random_active_fish_zone()
	var start_position := _random_position_in_water_zone(water_zone)
	var angle := randf_range(0.0, TAU)
	var velocity := Vector2(cos(angle), sin(angle)) * randf_range(0.25, 0.55)
	active_fish_agents.append(FishAgentScript.new().setup(start_position, velocity, _random_fish_kind_for_zone(water_zone)))


func _random_active_fish_zone() -> int:
	var roll := randf()
	if net_level < 2:
		if roll < 0.52:
			return WaterZone.SHALLOW
		if roll < 0.82:
			return WaterZone.OPEN
		if roll < 0.94:
			return WaterZone.COLD
		return WaterZone.DEEP
	if boat_agent.level >= 2:
		if roll < 0.24:
			return WaterZone.SHALLOW
		if roll < 0.50:
			return WaterZone.OPEN
		if roll < 0.68:
			return WaterZone.COLD
		if roll < 0.88:
			return WaterZone.DEEP
		return WaterZone.MONSTER
	if roll < 0.34:
		return WaterZone.SHALLOW
	if roll < 0.64:
		return WaterZone.OPEN
	if roll < 0.80:
		return WaterZone.COLD
	if roll < 0.95:
		return WaterZone.DEEP
	return WaterZone.MONSTER


func _random_position_in_water_zone(water_zone: int) -> Vector2:
	var cells: Array = []
	for y in WATER_ROWS:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if int(tile["water_zone"]) == water_zone:
				cells.append(Vector2i(x, y))
	if cells.is_empty():
		return Vector2(randf_range(0.35, float(GRID_W) - 0.35), randf_range(0.25, float(WATER_ROWS) - 0.35))

	var cell: Vector2i = cells[randi_range(0, cells.size() - 1)]
	return Vector2(
		float(cell.x) + randf_range(0.18, 0.82),
		float(cell.y) + randf_range(0.18, 0.82)
	)


func _boat_home_position() -> Vector2:
	return Vector2(BOAT_DOCK_X, float(WATER_ROWS) - 0.25)


func _boat_dock_cell() -> Vector2i:
	return Vector2i(int(floor(BOAT_DOCK_X)), WATER_ROWS)


func _init_player() -> void:
	player_agent.setup(Vector2(6, WATER_ROWS))
	player_fish_stock = [0, 0, 0]
	player_meat = 0
	player_cut_progress = 0.0
	player_sale_cooldown = 0.0


func _init_people() -> void:
	customer_agents.clear()
	workers.clear()
	selected_worker_index = -1


func _build_ui() -> void:
	var overlay := VBoxContainer.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_theme_constant_override("separation", 8)
	add_child(overlay)

	var top_panel := PanelContainer.new()
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(top_panel)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 3)
	top_panel.add_child(header_box)

	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 18)
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.text = ""
	header_box.add_child(hud_label)

	goal_label = Label.new()
	goal_label.add_theme_font_size_override("font_size", 15)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_box.add_child(goal_label)

	unlock_label = Label.new()
	unlock_label.add_theme_font_size_override("font_size", 14)
	unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_box.add_child(unlock_label)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.add_child(spacer)

	var bottom_panel := PanelContainer.new()
	bottom_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bottom_panel)

	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(bottom_box)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_box.add_child(status_label)

	inspector_label = Label.new()
	inspector_label.add_theme_font_size_override("font_size", 14)
	inspector_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_box.add_child(inspector_label)

	var actions := GridContainer.new()
	actions.columns = 5
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	bottom_box.add_child(actions)

	_add_tool_button(actions, TOOL_WALK, "Walk", "Tap land, dock, plaza, or road to move the fisherman. Nearby stations work automatically.")
	_add_tool_button(actions, TOOL_CATCH, "Fish", "Before the boat unlocks, stand at the dock and tap a nearby fish to catch it. Later, drag to steer the boat.")
	_add_tool_button(actions, TOOL_MAP, "Map", "Select Map, then drag the board to pan across the larger fishery.")
	_add_tool_button(actions, TOOL_PEOPLE, "People", "Select a worker, then tap water, a pool, cutter, market, storage, or smoker to assign their job.")
	_add_tool_button(actions, TOOL_POOL, "Pool $10", "Build live fish capacity on a buildable tile.")
	_add_tool_button(actions, TOOL_CUTTER, "Cutter $15", "Build processing on a buildable tile.")
	_add_tool_button(actions, TOOL_MARKET, "Market $20", "Build selling on a buildable tile.")
	_add_tool_button(actions, TOOL_STORAGE, "Storage", "Unlock by catching silverfish. Adds meat storage capacity.")
	_add_tool_button(actions, TOOL_SMOKER, "Smoker", "Unlock after steady sales. Turns meat into higher-value smoked meat.")
	_add_tool_button(actions, TOOL_EXPAND, "Expand", "Unlock after building Storage. Converts edge ground into buildable land.")
	_add_tool_button(actions, TOOL_MOVE, "Move", "Move one building to another buildable tile.")
	_add_tool_button(actions, TOOL_REMOVE, "Remove", "Remove a building and recover half its cost.")
	command_buttons["net"] = _add_command_button(actions, "Net +", "Upgrade net", _upgrade_net)
	command_buttons["boat"] = _add_command_button(actions, "Boat +", "Upgrade boat speed and hold size", _upgrade_boat)
	command_buttons["pool"] = _add_command_button(actions, "Pool +", "Upgrade pools", _upgrade_pool)
	command_buttons["cutter"] = _add_command_button(actions, "Cutter +", "Upgrade cutters", _upgrade_cutter)
	command_buttons["hire"] = _add_command_button(actions, "Hire +", "Hire another worker", _hire_worker)
	command_buttons["train"] = _add_command_button(actions, "Train", "Train the selected worker's assigned job skill", _train_selected_worker)
	_add_command_button(actions, "Center", "Return the map view to the starter fishery", _center_map)
	_add_command_button(actions, "Walk", "Return to walking the fisherman", _select_walk)


func _add_tool_button(parent: Control, tool: String, text: String, tooltip: String) -> void:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(96, 42)
	button.pressed.connect(func() -> void:
		if tool != TOOL_MOVE:
			_cancel_move_if_needed()
		if not _is_tool_unlocked(tool):
			status_text = _tool_locked_reason(tool)
			_update_tool_buttons()
			return
		selected_tool = tool
		var cost := _tool_cost(tool)
		if cost > 0 and money < cost:
			status_text = "Selected " + text + ". Need $" + str(cost) + "; you have $" + str(money) + "."
		else:
			status_text = "Selected " + text + "."
		_update_tool_buttons()
	)
	parent.add_child(button)
	tool_buttons[tool] = button


func _add_command_button(parent: Control, text: String, tooltip: String, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(96, 42)
	button.pressed.connect(callable)
	parent.add_child(button)
	return button


func _select_walk() -> void:
	_cancel_move_if_needed()
	selected_worker_index = -1
	selected_tool = TOOL_WALK
	status_text = "Walk selected. Tap a nearby surface to move the fisherman."
	_update_tool_buttons()


func _try_start_map_drag(position: Vector2) -> bool:
	if selected_tool != TOOL_MAP or not grid_rect.has_point(position):
		return false
	dragging_map = true
	map_drag_origin = position
	map_camera_drag_origin = map_camera
	status_text = "Map view: drag to pan around the fishery. Use Center to return to the starter district."
	return true


func _update_map_drag(position: Vector2) -> void:
	if tile_px <= 0.0:
		return
	var dragged_cells := (position - map_drag_origin) / tile_px
	map_camera = map_camera_drag_origin - Vector2(round(dragged_cells.x), round(dragged_cells.y))
	_clamp_map_camera()
	queue_redraw()


func _center_map(show_status := true) -> void:
	if grid_rect.size == Vector2.ZERO:
		_calculate_grid_rect()
	var visible_cells := grid_rect.size / tile_px
	map_camera = Vector2(7.5, 7.0) - visible_cells * 0.5
	map_camera = Vector2(floor(map_camera.x), floor(map_camera.y))
	_clamp_map_camera()
	if show_status:
		status_text = "Map centered on the starter fishery. Select Map and drag to explore the frontier."
	_update_hud()
	queue_redraw()


func _try_handle_tap(position: Vector2) -> void:
	var cell := _cell_from_screen_position(position)
	if cell.x < 0:
		return

	selected_cell = cell

	match selected_tool:
		TOOL_WALK:
			_move_player_to(cell)
		TOOL_CATCH:
			_use_catch_tool(cell)
		TOOL_PEOPLE:
			_use_people_tool(cell)
		TOOL_POOL:
			_try_build(cell, BuildKind.POOL, COST_POOL, "pool")
		TOOL_CUTTER:
			_try_build(cell, BuildKind.CUTTER, COST_CUTTER, "cutter")
		TOOL_MARKET:
			_try_build(cell, BuildKind.MARKET, COST_MARKET, "market")
		TOOL_STORAGE:
			_try_build(cell, BuildKind.STORAGE, COST_STORAGE, "storage")
		TOOL_SMOKER:
			_try_build(cell, BuildKind.SMOKER, COST_SMOKER, "smoker")
		TOOL_EXPAND:
			_try_expand_land(cell)
		TOOL_MOVE:
			_use_move_tool(cell)
		TOOL_REMOVE:
			_use_remove_tool(cell)

	_update_hud()
	queue_redraw()


func _cell_from_screen_position(position: Vector2) -> Vector2i:
	if not grid_rect.has_point(position):
		return Vector2i(-1, -1)

	var world_position := (position - grid_rect.position) / tile_px + map_camera
	var cell := Vector2i(int(floor(world_position.x)), int(floor(world_position.y)))

	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_W or cell.y >= GRID_H:
		return Vector2i(-1, -1)
	return cell


func _try_start_boat_drag(position: Vector2) -> bool:
	if selected_tool != TOOL_CATCH or not _is_boat_unlocked():
		return false

	var cell := _cell_from_screen_position(position)
	if cell.x < 0:
		return false

	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] != TileKind.WATER:
		return false

	dragging_boat = true
	_set_boat_target_from_screen(position)
	status_text = "Boat following your drag. Sweep fish into the net, then tap the dock to unload."
	_add_popup("Boat target", _world_to_screen(boat_agent.target), Color("#9fe4dd"))
	_update_hud()
	queue_redraw()
	return true


func _update_boat_drag(position: Vector2) -> void:
	_set_boat_target_from_screen(position)
	queue_redraw()


func _set_boat_target_from_screen(position: Vector2) -> void:
	var world_position := (position - grid_rect.position) / tile_px + map_camera
	boat_agent.set_target(Vector2(
		clamp(world_position.x, 0.25, float(GRID_W) - 0.25),
		clamp(world_position.y, 0.25, float(WATER_ROWS) - 0.25)
	))
	selected_cell = Vector2i(
		int(clamp(floor(boat_agent.target.x), 0.0, float(GRID_W - 1))),
		int(clamp(floor(boat_agent.target.y), 0.0, float(WATER_ROWS - 1)))
	)


func _use_catch_tool(cell: Vector2i) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if not _is_boat_unlocked():
		_try_manual_shore_catch(cell)
		return

	if tile["kind"] == TileKind.WATER:
		boat_agent.set_target(_water_cell_target(cell))
		status_text = "Boat heading to " + _water_zone_name(int(tile["water_zone"])) + ". Drag to guide it, then tap the dock to unload."
		_add_popup_for_cell(cell, "Boat target", Color("#9fe4dd"))
		return

	if tile["kind"] == TileKind.DOCK:
		boat_agent.set_target(_boat_home_position())
		if _boat_is_at_dock() and _boat_net_count() > 0:
			_try_unload_boat()
		else:
			status_text = "Boat returning to the dock. It will unload when it arrives."
		return

	if tile["building"] == BuildKind.POOL:
		if _carried_fish_total() <= 0:
			status_text = "No carried fish. Catch with the boat, unload at the dock, or assign workers to fish."
			return

		var room := _pool_capacity() - _live_fish_total()
		if room <= 0:
			status_text = "Pools are full. Build or upgrade more capacity."
			return

		var moved: int = _move_fish_between_stocks(carried_fish_stock, live_fish_stock, room)
		fish_stored_total += moved
		status_text = "Stored " + str(moved) + " live fish in pools."
		_add_popup_for_cell(cell, "+" + str(moved) + " live", Color("#9fe4dd"))
		return

	status_text = "Fish works on water and the dock. Walk is for carrying catches between stations."


func _move_player_to(cell: Vector2i) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] == TileKind.WATER or tile["kind"] == TileKind.EXPANSION:
		status_text = "The fisherman can walk on owned land, docks, plazas, and roads."
		return
	player_agent.set_target(Vector2(cell.x, cell.y))
	status_text = "Fisherman walking to " + _tile_surface_name(int(tile["kind"])) + "."
	_add_popup_for_cell(cell, "On my way", Color("#f2d16b"))


func _try_manual_shore_catch(cell: Vector2i) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] != TileKind.WATER:
		status_text = "Walk to the dock, then tap a visible fish in nearby water."
		return
	if _player_fish_total() >= PLAYER_FISH_CAPACITY:
		status_text = "Basket full. Walk to the pool or cutter before catching more fish."
		return
	if player_agent.position.distance_to(Vector2(cell.x + 0.5, cell.y + 0.5)) > 1.45:
		status_text = "Walk closer to the dock beside that fish before casting."
		return

	var fish_index := _active_fish_index_in_cell(cell)
	if fish_index < 0:
		status_text = "No fish in that patch right now. Try another ripple."
		return

	var fish = active_fish_agents[fish_index]
	active_fish_agents.remove_at(fish_index)
	var fish_kind := int(fish.fish_kind)
	_add_fish_to_stock(player_fish_stock, fish_kind, 1)
	var water_zone := int(tile["water_zone"])
	water_zone_catches[water_zone] = int(water_zone_catches[water_zone]) + 1
	fish_caught_total += 1
	_add_fish_to_stock(fish_caught_by_kind, fish_kind, 1)
	status_text = "Caught a " + _fish_name(fish_kind) + ". Basket " + str(_player_fish_total()) + "/" + str(PLAYER_FISH_CAPACITY) + "." + _maybe_award_zone_discovery(water_zone) + _maybe_unlock_storage(fish_kind)
	_add_popup(_fish_name(fish_kind), _world_to_screen(fish.position), _fish_color(fish_kind))


func _active_fish_index_in_cell(cell: Vector2i) -> int:
	var closest_index := -1
	var closest_distance := INF
	var cell_center := Vector2(cell.x + 0.5, cell.y + 0.5)
	for i in active_fish_agents.size():
		var fish = active_fish_agents[i]
		if Vector2i(int(floor(fish.position.x)), int(floor(fish.position.y))) != cell:
			continue
		var distance: float = fish.position.distance_to(cell_center)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = i
	return closest_index


func _tick_player(delta: float) -> void:
	player_agent.tick(delta)
	player_sale_cooldown = max(0.0, player_sale_cooldown - delta)
	if not player_agent.is_at_target():
		return

	var cell := _player_cell()
	if cell.x < 0:
		return
	var tile: Dictionary = tiles[cell.y][cell.x]
	match int(tile["building"]):
		BuildKind.POOL:
			_player_unload_fish_to_pool(cell)
		BuildKind.CUTTER:
			_tick_player_cutter(cell, delta)
		BuildKind.MARKET:
			_try_player_sale(cell)
		_:
			player_cut_progress = 0.0


func _player_cell() -> Vector2i:
	var cell := Vector2i(int(round(player_agent.position.x)), int(round(player_agent.position.y)))
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_W or cell.y >= GRID_H:
		return Vector2i(-1, -1)
	return cell


func _player_fish_total() -> int:
	return _stock_total(player_fish_stock)


func _player_unload_fish_to_pool(cell: Vector2i) -> void:
	if _player_fish_total() <= 0:
		return
	var room := _pool_capacity() - _live_fish_total()
	if room <= 0:
		status_text = "Pool is full. Process fish at the cutter or upgrade the pool."
		return
	var moved := _move_fish_between_stocks(player_fish_stock, live_fish_stock, room)
	if moved <= 0:
		return
	fish_stored_total += moved
	status_text = "Fisherman dropped " + str(moved) + " fish in the pool."
	_add_popup_for_cell(cell, "Pool +" + str(moved), Color("#9fe4dd"))


func _tick_player_cutter(cell: Vector2i, delta: float) -> void:
	if player_meat >= PLAYER_MEAT_CAPACITY:
		player_cut_progress = 0.0
		status_text = "Hands full of meat. Walk it to the market."
		return
	if _player_fish_total() <= 0 and _live_fish_total() > 0:
		var fish_kind := _take_next_live_fish_kind()
		_add_fish_to_stock(player_fish_stock, fish_kind, 1)
		status_text = "Fisherman lifted a " + _fish_name(fish_kind) + " from the pool for cutting."
		_add_popup_for_cell(cell, "Fish in hand", _fish_color(fish_kind))
		return
	if _player_fish_total() <= 0:
		player_cut_progress = 0.0
		return

	player_cut_progress += delta
	if player_cut_progress < PLAYER_CUT_SECONDS:
		return
	player_cut_progress = 0.0
	var fish_kind := _take_next_fish_kind(player_fish_stock)
	var produced := _fish_meat_yield(fish_kind)
	produced = min(produced, PLAYER_MEAT_CAPACITY - player_meat)
	if produced <= 0:
		return
	player_meat += produced
	meat_processed_total += produced
	status_text = "Fisherman cut a " + _fish_name(fish_kind) + " into " + str(produced) + " meat."
	_add_popup_for_cell(cell, "+" + str(produced) + " meat", Color("#ffd7bb"))


func _try_player_sale(cell: Vector2i) -> void:
	if player_meat <= 0 or player_sale_cooldown > 0.0:
		return
	var waiting_indices := _waiting_customer_indices()
	for customer_index in waiting_indices:
		var customer: Dictionary = customer_agents[int(customer_index)]
		if int(customer["kind"]) == BuyerKind.COOK:
			continue
		player_meat -= 1
		meat_sold_total += 1
		money += MEAT_PRICE
		customer["remaining"] = int(customer["remaining"]) - 1
		customer["patience"] = _buyer_patience(int(customer["kind"]))
		if int(customer["remaining"]) <= 0:
			if int(customer["kind"]) == BuyerKind.MERCHANT:
				money += MERCHANT_BULK_BONUS
				merchant_orders_completed_total += 1
			customer["state"] = "leaving_happy"
			customer["target"] = customer["exit"]
			_record_buyer_served(int(customer["kind"]))
		customer_agents[int(customer_index)] = customer
		player_sale_cooldown = PLAYER_SALE_SECONDS
		status_text = "Fisherman handed over meat for $" + str(MEAT_PRICE) + "."
		_add_popup_for_cell(cell, "+$" + str(MEAT_PRICE), Color("#b7ef8a"))
		_update_customer_counts()
		return


func _take_next_fish_kind(stock: Array) -> int:
	for fish_kind: int in [FishKind.SILVERFISH, FishKind.CARP, FishKind.MINNOW]:
		if int(stock[fish_kind]) > 0:
			stock[fish_kind] = int(stock[fish_kind]) - 1
			return fish_kind
	return FishKind.MINNOW


func _use_people_tool(cell: Vector2i) -> void:
	var worker_index := _worker_index_at_cell(cell)
	if worker_index >= 0:
		selected_worker_index = worker_index
		var selected_worker: Dictionary = workers[worker_index]
		status_text = _worker_name(worker_index) + " selected. " + _worker_assignment_instruction(selected_worker)
		return

	if selected_worker_index < 0 or selected_worker_index >= workers.size():
		status_text = "Tap a worker first, then tap water, a building, or land to assign them."
		return
	if not _is_valid_worker_assignment(cell):
		status_text = "Workers cannot be assigned to locked expansion ground."
		return

	var worker: Dictionary = workers[selected_worker_index]
	worker = _begin_worker_assignment(worker, cell)
	workers[selected_worker_index] = worker
	if _worker_job_key(worker) == "idle":
		status_text = _worker_name(selected_worker_index) + " is on standby. Tap water, a pool, cutter, market, storage, or smoker for a real job."
	else:
		status_text = _worker_name(selected_worker_index) + " assigned to " + _worker_job_label(_worker_job_key(worker)) + ". " + _worker_assignment_hint(cell)
	_add_popup_for_cell(cell, "Assigned", Color("#f2d16b"))


func _try_build(cell: Vector2i, building: int, cost: int, label: String) -> void:
	if not _is_building_unlocked(building):
		status_text = _building_locked_reason(building)
		return

	var tile: Dictionary = tiles[cell.y][cell.x]
	if not _is_buildable_tile_kind(int(tile["kind"])):
		status_text = "Build " + label + " on " + _buildable_tile_text() + "."
		return
	if tile["building"] != BuildKind.NONE:
		status_text = "This tile already has a building."
		return
	if money < cost:
		status_text = "Need $" + str(cost) + " to build a " + label + "."
		return

	money -= cost
	tile["building"] = building
	tiles[cell.y][cell.x] = tile
	buildings_built_total += 1
	status_text = "Built a " + label + ". " + _layout_hint_for_building(cell, building)
	_add_popup_for_cell(cell, "-" + str(cost) + "$", Color("#ffd7bb"))


func _try_expand_land(cell: Vector2i) -> void:
	if not _is_tool_unlocked(TOOL_EXPAND):
		status_text = _tool_locked_reason(TOOL_EXPAND)
		return

	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] != TileKind.EXPANSION:
		status_text = "Tap a frontier expansion tile to buy more land."
		return
	if not _is_claimable_frontier(cell):
		status_text = "Claim frontier tiles beside land, dock, plaza, or road you already control."
		return
	if money < COST_EXPAND:
		status_text = "Need $" + str(COST_EXPAND) + " to expand land."
		return

	money -= COST_EXPAND
	tile["kind"] = TileKind.LAND
	tiles[cell.y][cell.x] = tile
	land_expanded_total += 1
	status_text = "Claimed new land. Build here or keep opening the frontier outward."
	_add_popup_for_cell(cell, "Land +1", Color("#b7ef8a"))


func _is_claimable_frontier(cell: Vector2i) -> bool:
	for next in _adjacent_cells(cell):
		var neighbor: Dictionary = tiles[next.y][next.x]
		var kind := int(neighbor["kind"])
		if kind == TileKind.LAND or kind == TileKind.DOCK or kind == TileKind.PLAZA or kind == TileKind.ROAD:
			return true
	return false


func _use_move_tool(cell: Vector2i) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if moving_building == BuildKind.NONE:
		if tile["building"] == BuildKind.NONE:
			status_text = "Tap a building first, then tap an empty buildable tile."
			return
		if tile["building"] == BuildKind.POOL and not _can_remove_pool_at(cell):
			status_text = "Cannot move this pool while it is needed for live fish capacity."
			return
		if tile["building"] == BuildKind.STORAGE and not _can_remove_storage_at(cell):
			status_text = "Cannot move this storage while it is needed for meat or smoked meat capacity."
			return
		if tile["building"] == BuildKind.SMOKER and not _can_remove_smoker_at(cell):
			status_text = "Cannot move this smoker while it is needed for smoked meat capacity."
			return

		moving_building = int(tile["building"])
		move_source_cell = cell
		tile["building"] = BuildKind.NONE
		tiles[cell.y][cell.x] = tile
		status_text = "Moving " + _building_name(moving_building) + ". Tap an empty buildable tile to place it."
		_add_popup_for_cell(cell, "Move", Color("#f2d16b"))
		return

	if not _is_buildable_tile_kind(int(tile["kind"])):
		status_text = "Moved buildings must be placed on " + _buildable_tile_text() + "."
		return
	if tile["building"] != BuildKind.NONE:
		status_text = "That tile is occupied. Pick an empty buildable tile."
		return

	tile["building"] = moving_building
	tiles[cell.y][cell.x] = tile
	status_text = "Moved " + _building_name(moving_building) + ". " + _layout_hint_for_building(cell, moving_building)
	_add_popup_for_cell(cell, "Placed", Color("#b7ef8a"))
	moving_building = BuildKind.NONE
	move_source_cell = Vector2i(-1, -1)


func _use_remove_tool(cell: Vector2i) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	var building := int(tile["building"])
	if building == BuildKind.NONE:
		status_text = "Tap a building to remove it."
		return
	if building == BuildKind.POOL and not _can_remove_pool_at(cell):
		status_text = "Cannot remove this pool while it is needed for live fish capacity."
		return
	if building == BuildKind.STORAGE and not _can_remove_storage_at(cell):
		status_text = "Cannot remove this storage while it is needed for meat or smoked meat capacity."
		return
	if building == BuildKind.SMOKER and not _can_remove_smoker_at(cell):
		status_text = "Cannot remove this smoker while it is needed for smoked meat capacity."
		return

	var refund := int(floor(float(_building_cost(building)) * 0.5))
	money += refund
	tile["building"] = BuildKind.NONE
	tiles[cell.y][cell.x] = tile
	status_text = "Removed " + _building_name(building) + " and recovered $" + str(refund) + "."
	_add_popup_for_cell(cell, "+$" + str(refund), Color("#b7ef8a"))


func _upgrade_net() -> void:
	var cost := _net_upgrade_cost()
	if money < cost:
		status_text = "Need $" + str(cost) + " to upgrade the net."
		return
	money -= cost
	net_level += 1
	upgrades_bought_total += 1
	status_text = "Net upgraded to level " + str(net_level) + "." + _net_unlock_text()
	_add_popup("Net level " + str(net_level), grid_rect.position + Vector2(grid_rect.size.x * 0.5, 28.0), Color("#f2d16b"))
	_update_hud()


func _upgrade_boat() -> void:
	if not _is_boat_unlocked():
		status_text = "The boat arrives after Net 2. Catch and sell fish by hand first."
		return
	var cost := _boat_upgrade_cost()
	if money < cost:
		status_text = "Need $" + str(cost) + " to upgrade the boat."
		return
	money -= cost
	boat_agent.upgrade()
	upgrades_bought_total += 1
	status_text = "Boat upgraded to level " + str(boat_agent.level) + ". Speed and net hold improved."
	_add_popup("Boat level " + str(boat_agent.level), grid_rect.position + Vector2(grid_rect.size.x * 0.5, 34.0), Color("#9fe4dd"))
	_update_hud()


func _upgrade_pool() -> void:
	var cost := _pool_upgrade_cost()
	if money < cost:
		status_text = "Need $" + str(cost) + " to upgrade pools."
		return
	money -= cost
	pool_level += 1
	upgrades_bought_total += 1
	status_text = "Pools upgraded to level " + str(pool_level) + "."
	_add_popup("Pool level " + str(pool_level), grid_rect.position + Vector2(grid_rect.size.x * 0.5, 28.0), Color("#9fe4dd"))
	_update_hud()


func _upgrade_cutter() -> void:
	var cost := _cutter_upgrade_cost()
	if money < cost:
		status_text = "Need $" + str(cost) + " to upgrade cutters."
		return
	money -= cost
	cutter_level += 1
	upgrades_bought_total += 1
	status_text = "Cutters upgraded to level " + str(cutter_level) + "."
	_add_popup("Cutter level " + str(cutter_level), grid_rect.position + Vector2(grid_rect.size.x * 0.5, 28.0), Color("#ffd7bb"))
	_update_hud()


func _hire_worker() -> void:
	if not _is_worker_hiring_unlocked():
		status_text = "A fisherman will join after Net 2 and a few successful hand sales."
		return
	if workers.size() >= MAX_WORKERS:
		status_text = "Worker cap reached. Later housing will raise the people limit."
		return
	if money < COST_WORKER:
		status_text = "Need $" + str(COST_WORKER) + " to hire a worker."
		return

	money -= COST_WORKER
	var spawn_cell := Vector2i(clamp(6 + workers.size(), 0, GRID_W - 1), ROAD_ROW - 2)
	_spawn_worker(spawn_cell, true)
	selected_tool = TOOL_PEOPLE
	selected_worker_index = workers.size() - 1
	status_text = _worker_name(selected_worker_index) + " hired. Select water, a pool, cutter, market, storage, or smoker to give them a job."
	_add_popup_for_cell(spawn_cell, "Worker +1", Color("#f2d16b"))
	_update_hud()


func _train_selected_worker() -> void:
	if selected_worker_index < 0 or selected_worker_index >= workers.size():
		status_text = "Select a worker with People before training them."
		return

	var worker: Dictionary = workers[selected_worker_index]
	var job_key := _worker_job_key(worker)
	var skill_key := _worker_skill_key_for_job(job_key)
	if skill_key.is_empty():
		status_text = _worker_name(selected_worker_index) + " is on standby. Assign a real job before training."
		return

	var current_level := _worker_skill(worker, skill_key)
	if current_level >= WORKER_MAX_SKILL:
		status_text = _worker_name(selected_worker_index) + " has mastered " + _worker_skill_label(skill_key) + "."
		return

	var cost := _worker_training_cost(worker, skill_key)
	if money < cost:
		status_text = "Need $" + str(cost) + " to train " + _worker_name(selected_worker_index) + " in " + _worker_skill_label(skill_key) + "."
		return

	money -= cost
	var skills: Dictionary = worker["skills"]
	skills[skill_key] = current_level + 1
	worker["skills"] = skills
	var skill_xp: Dictionary = worker["skill_xp"]
	skill_xp[skill_key] = 0
	worker["skill_xp"] = skill_xp
	workers[selected_worker_index] = worker
	status_text = _worker_name(selected_worker_index) + " trained " + _worker_skill_label(skill_key) + " to level " + str(current_level + 1) + "."
	_add_popup_for_cell(Vector2i(worker["assigned"]), _worker_skill_short_label(skill_key) + " L" + str(current_level + 1), Color("#f2d16b"))
	_update_hud()


func _spawn_worker(cell: Vector2i, paid: bool) -> void:
	var worker_name := _worker_name(workers.size())
	workers.append({
		"name": worker_name,
		"pos": Vector2(cell.x, cell.y),
		"target": Vector2(cell.x, cell.y),
		"assigned": cell,
		"fishing_cell": Vector2i(-1, -1),
		"job_state": "idle",
		"carry_stock": [0, 0, 0],
		"work_timer": 0.0,
		"skills": _worker_starting_skills(workers.size()),
		"skill_xp": {
			"fishing": 0,
			"handling": 0,
			"processing": 0,
			"trading": 0
		},
		"paid": paid
	})


func _worker_starting_skills(worker_index: int) -> Dictionary:
	var skills := {
		"fishing": 1,
		"handling": 1,
		"processing": 1,
		"trading": 1
	}
	match worker_index % 6:
		0:
			skills["fishing"] = 2
		1:
			skills["processing"] = 2
		2:
			skills["trading"] = 2
		3:
			skills["handling"] = 2
		4:
			skills["processing"] = 2
			skills["trading"] = 2
		_:
			skills["fishing"] = 2
			skills["handling"] = 2
	return skills


func _worker_job_key(worker: Dictionary) -> String:
	var assigned: Vector2i = worker.get("assigned", Vector2i(-1, -1))
	if assigned.x < 0 or assigned.y < 0 or assigned.x >= GRID_W or assigned.y >= GRID_H:
		return "idle"
	var tile: Dictionary = tiles[assigned.y][assigned.x]
	if tile["kind"] == TileKind.WATER:
		return "fish"
	match int(tile["building"]):
		BuildKind.POOL:
			return "pool"
		BuildKind.CUTTER:
			return "cutter"
		BuildKind.MARKET:
			return "market"
		BuildKind.STORAGE:
			return "storage"
		BuildKind.SMOKER:
			return "smoker"
		_:
			return "idle"


func _worker_job_label(job_key: String) -> String:
	match job_key:
		"fish":
			return "fishing"
		"pool":
			return "pool handling"
		"cutter":
			return "cutter work"
		"market":
			return "market trade"
		"storage":
			return "storage handling"
		"smoker":
			return "smoker work"
		_:
			return "standby"


func _worker_job_short_label(worker: Dictionary) -> String:
	match _worker_job_key(worker):
		"fish":
			return "FISH"
		"pool":
			return "POOL"
		"cutter":
			return "CUT"
		"market":
			return "SELL"
		"storage":
			return "STORE"
		"smoker":
			return "SMOKE"
		_:
			return "IDLE"


func _worker_skill_key_for_job(job_key: String) -> String:
	match job_key:
		"fish":
			return "fishing"
		"pool", "storage":
			return "handling"
		"cutter", "smoker":
			return "processing"
		"market":
			return "trading"
		_:
			return ""


func _worker_skill_label(skill_key: String) -> String:
	match skill_key:
		"fishing":
			return "Fishing"
		"handling":
			return "Handling"
		"processing":
			return "Processing"
		"trading":
			return "Trade"
		_:
			return "Work"


func _worker_skill_short_label(skill_key: String) -> String:
	match skill_key:
		"fishing":
			return "F"
		"handling":
			return "H"
		"processing":
			return "P"
		"trading":
			return "T"
		_:
			return "?"


func _worker_skill(worker: Dictionary, skill_key: String) -> int:
	var skills: Dictionary = worker.get("skills", {})
	return int(skills.get(skill_key, 1))


func _worker_skill_xp(worker: Dictionary, skill_key: String) -> int:
	var skill_xp: Dictionary = worker.get("skill_xp", {})
	return int(skill_xp.get(skill_key, 0))


func _worker_skill_xp_required(worker: Dictionary, skill_key: String) -> int:
	return WORKER_SKILL_XP_BASE * _worker_skill(worker, skill_key)


func _worker_training_cost(worker: Dictionary, skill_key: String) -> int:
	return COST_WORKER_TRAIN * _worker_skill(worker, skill_key)


func _worker_fish_seconds(worker: Dictionary) -> float:
	var level := _worker_skill(worker, "fishing")
	return WORKER_FISH_SECONDS / (1.0 + float(level - 1) * 0.22)


func _award_worker_skill_xp(worker: Dictionary, skill_key: String, amount: int, popup_cell: Vector2i) -> Dictionary:
	if skill_key.is_empty() or amount <= 0 or _worker_skill(worker, skill_key) >= WORKER_MAX_SKILL:
		return worker

	var skills: Dictionary = worker["skills"]
	var skill_xp: Dictionary = worker["skill_xp"]
	var current_level := int(skills.get(skill_key, 1))
	var current_xp := int(skill_xp.get(skill_key, 0)) + amount
	var required := WORKER_SKILL_XP_BASE * current_level
	if current_xp < required:
		skill_xp[skill_key] = current_xp
		worker["skill_xp"] = skill_xp
		return worker

	current_xp -= required
	current_level += 1
	skills[skill_key] = current_level
	skill_xp[skill_key] = current_xp if current_level < WORKER_MAX_SKILL else 0
	worker["skills"] = skills
	worker["skill_xp"] = skill_xp
	_add_popup_for_cell(popup_cell, str(worker["name"]) + " " + _worker_skill_short_label(skill_key) + " L" + str(current_level), Color("#f2d16b"))
	return worker


func _award_station_worker_xp(building: int, skill_key: String, amount: int) -> void:
	for worker_index in workers.size():
		var worker: Dictionary = workers[worker_index]
		var assigned: Vector2i = worker["assigned"]
		if assigned.x < 0 or assigned.y < 0 or assigned.x >= GRID_W or assigned.y >= GRID_H:
			continue
		var tile: Dictionary = tiles[assigned.y][assigned.x]
		if int(tile["building"]) != building or not _agent_reached(worker["pos"], Vector2(assigned.x, assigned.y)):
			continue
		workers[worker_index] = _award_worker_skill_xp(worker, skill_key, amount, assigned)


func _worker_assignment_instruction(worker: Dictionary) -> String:
	var job_key := _worker_job_key(worker)
	if job_key == "idle":
		return "On standby. Tap water for fishing, or a station for its job."
	var skill_key := _worker_skill_key_for_job(job_key)
	return _worker_job_label(job_key).capitalize() + " uses " + _worker_skill_label(skill_key) + " L" + str(_worker_skill(worker, skill_key)) + "."


func _tick_workers(delta: float) -> void:
	for i in workers.size():
		var worker: Dictionary = workers[i]
		var pos: Vector2 = worker["pos"]
		var target: Vector2 = worker["target"]
		worker["pos"] = _move_grid_position(pos, target, WORKER_WALK_SPEED * delta)
		var next_pos: Vector2 = worker["pos"]
		if _agent_reached(next_pos, target):
			worker = _tick_worker_job(i, worker, delta)
		workers[i] = worker


func _tick_worker_job(worker_index: int, worker: Dictionary, delta: float) -> Dictionary:
	var assigned: Vector2i = worker["assigned"]
	if assigned.x < 0 or assigned.y < 0 or assigned.x >= GRID_W or assigned.y >= GRID_H:
		return worker

	var tile: Dictionary = tiles[assigned.y][assigned.x]
	if tile["kind"] != TileKind.WATER:
		worker["job_state"] = "working" if _worker_job_key(worker) != "idle" else "idle"
		return worker

	return _tick_fishing_worker(worker_index, worker, delta)


func _begin_worker_assignment(worker: Dictionary, cell: Vector2i) -> Dictionary:
	worker["assigned"] = cell
	if _worker_carry_total(worker) > 0:
		worker["job_state"] = "carry_to_pool"
		worker["target"] = _worker_pool_target(worker)
		return worker

	if tiles[cell.y][cell.x]["kind"] != TileKind.WATER:
		worker["fishing_cell"] = Vector2i(-1, -1)
		worker["job_state"] = "walk_to_assignment"
		worker["target"] = Vector2(cell.x, cell.y)
		return worker

	worker["fishing_cell"] = cell
	worker["job_state"] = "walk_to_water"
	worker["work_timer"] = 0.0
	worker["target"] = _worker_shore_target(cell)
	return worker


func _tick_fishing_worker(worker_index: int, worker: Dictionary, delta: float) -> Dictionary:
	var state := str(worker["job_state"])
	if state == "walk_to_water":
		worker["job_state"] = "fishing"
		worker["work_timer"] = _worker_fish_seconds(worker)
		status_text = _worker_name(worker_index) + " is casting from the dock."
		return worker

	if state == "fishing":
		worker["work_timer"] = float(worker["work_timer"]) - delta
		if float(worker["work_timer"]) > 0.0:
			return worker
		return _worker_catch_fish(worker_index, worker)

	if state == "waiting_for_pool" and _worker_carry_total(worker) <= 0:
		if _pool_capacity() - _live_fish_total() <= 0:
			return worker
		return _begin_worker_assignment(worker, worker["assigned"])

	if state == "carry_to_pool" or state == "waiting_for_pool":
		return _worker_unload_fish(worker_index, worker)

	return _begin_worker_assignment(worker, worker["assigned"])


func _worker_catch_fish(worker_index: int, worker: Dictionary) -> Dictionary:
	var fishing_cell: Vector2i = worker["fishing_cell"]
	if fishing_cell.x < 0:
		return _begin_worker_assignment(worker, worker["assigned"])
	var tile: Dictionary = tiles[fishing_cell.y][fishing_cell.x]
	if int(tile["fish"]) <= 0:
		worker["work_timer"] = 1.0
		return worker
	if _pool_capacity() - _live_fish_total() <= 0:
		worker["job_state"] = "waiting_for_pool"
		worker["target"] = _worker_pool_target(worker)
		return worker

	var fish_kind := int(tile["fish_kind"])
	tile["fish"] = int(tile["fish"]) - 1
	tiles[fishing_cell.y][fishing_cell.x] = tile
	_add_fish_to_stock(worker["carry_stock"], fish_kind, 1)
	fish_caught_total += 1
	_add_fish_to_stock(fish_caught_by_kind, fish_kind, 1)
	var active_fish_index := _active_fish_index_in_cell(fishing_cell)
	if active_fish_index >= 0:
		active_fish_agents.remove_at(active_fish_index)
	worker = _award_worker_skill_xp(worker, "fishing", 1, fishing_cell)
	worker["job_state"] = "carry_to_pool"
	worker["target"] = _worker_pool_target(worker)
	status_text = _worker_name(worker_index) + " caught a " + _fish_name(fish_kind) + " and is carrying it to the pool." + _maybe_unlock_storage(fish_kind)
	_add_popup_for_cell(fishing_cell, _worker_name(worker_index) + " caught", _fish_color(fish_kind))
	return worker


func _worker_unload_fish(worker_index: int, worker: Dictionary) -> Dictionary:
	if _worker_carry_total(worker) <= 0:
		return _begin_worker_assignment(worker, worker["assigned"])
	var room := _pool_capacity() - _live_fish_total()
	if room <= 0:
		worker["job_state"] = "waiting_for_pool"
		return worker
	var moved := _move_fish_between_stocks(worker["carry_stock"], live_fish_stock, room)
	if moved <= 0:
		return worker
	fish_stored_total += moved
	var pool_cell := _nearest_pool_cell(worker["pos"])
	status_text = _worker_name(worker_index) + " unloaded " + str(moved) + " fish at the pool and is heading back out."
	if pool_cell.x >= 0:
		_add_popup_for_cell(pool_cell, "Pool +" + str(moved), Color("#9fe4dd"))
	return _begin_worker_assignment(worker, worker["assigned"])


func _worker_carry_total(worker: Dictionary) -> int:
	return _stock_total(worker["carry_stock"])


func _worker_shore_target(water_cell: Vector2i) -> Vector2:
	var dock_cell := Vector2i(clamp(water_cell.x, 3, 10), WATER_ROWS)
	return Vector2(dock_cell.x, dock_cell.y)


func _worker_pool_target(worker: Dictionary) -> Vector2:
	var pool_cell := _nearest_pool_cell(worker["pos"])
	if pool_cell.x < 0:
		return Vector2(worker["pos"])
	return Vector2(pool_cell.x, pool_cell.y)


func _nearest_pool_cell(origin: Vector2) -> Vector2i:
	var closest := Vector2i(-1, -1)
	var closest_distance := INF
	for pool_cell in _building_cells(BuildKind.POOL):
		var distance: float = origin.distance_to(Vector2(pool_cell.x, pool_cell.y))
		if distance < closest_distance:
			closest_distance = distance
			closest = pool_cell
	return closest


func _tick_fish_spawns(delta: float) -> void:
	for y in WATER_ROWS:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if tile["fish"] > 0:
				continue

			tile["spawn_timer"] -= delta
			if tile["spawn_timer"] <= 0.0:
				tile["fish_kind"] = _random_fish_kind_for_zone(int(tile["water_zone"]))
				tile["fish"] = randi_range(1, min(3, 1 + net_level))
				tile["spawn_timer"] = randf_range(3.0, 7.0)
			tiles[y][x] = tile


func _tick_active_fishing(delta: float) -> void:
	if _is_boat_unlocked():
		_move_boat(delta)
		_tick_zone_warnings(delta)

	var water_min := Vector2(0.15, 0.15)
	var water_max := Vector2(float(GRID_W) - 0.15, float(WATER_ROWS) - 0.2)
	var fish_threat: Vector2 = boat_agent.position if _is_boat_unlocked() else Vector2(-100.0, -100.0)
	for fish in active_fish_agents:
		var water_zone := _water_zone_at_world_position(fish.position)
		fish.tick(delta, water_min, water_max, fish_threat, _water_zone_speed_modifier(water_zone))

	if _is_boat_unlocked():
		_collect_fish_in_net()
	while active_fish_agents.size() < ACTIVE_FISH_MAX:
		_spawn_active_fish()

	if _is_boat_unlocked() and _boat_is_at_dock() and _boat_net_count() > 0:
		_try_unload_boat()


func _move_boat(delta: float) -> void:
	boat_agent.tick(delta)


func _tick_zone_warnings(delta: float) -> void:
	monster_warning_notice_timer = max(0.0, monster_warning_notice_timer - delta)
	var boat_zone := _water_zone_at_world_position(boat_agent.position)
	if boat_zone == WaterZone.MONSTER:
		monster_warning = min(MONSTER_WARNING_SECONDS, monster_warning + delta)
		if monster_warning >= MONSTER_WARNING_SECONDS and monster_warning_notice_timer <= 0.0:
			status_text = "Monster water warning is high. No attack yet, but return before pushing deeper."
			_add_popup("Warning", _world_to_screen(boat_agent.position), Color("#ff8f7a"))
			monster_warning_notice_timer = 7.0
		return

	monster_warning = max(0.0, monster_warning - delta * MONSTER_WARNING_DECAY)


func _collect_fish_in_net() -> void:
	if _boat_net_count() >= _boat_net_capacity():
		return

	var net_center := _boat_net_center()
	var catch_radius := _boat_net_radius()
	for i in range(active_fish_agents.size() - 1, -1, -1):
		if _boat_net_count() >= _boat_net_capacity():
			return

		var fish = active_fish_agents[i]
		if fish.position.distance_to(net_center) > catch_radius + NET_CATCH_RADIUS:
			continue

		var catch_zone := _water_zone_at_world_position(fish.position)
		active_fish_agents.remove_at(i)
		_add_fish_to_stock(boat_agent.fish_stock, fish.fish_kind, 1)
		water_zone_catches[catch_zone] = int(water_zone_catches[catch_zone]) + 1
		fish_caught_total += 1
		_add_fish_to_stock(fish_caught_by_kind, fish.fish_kind, 1)
		status_text = "Net caught a " + _fish_name(fish.fish_kind) + " from " + _water_zone_name(catch_zone) + ". Net " + str(_boat_net_count()) + "/" + str(_boat_net_capacity()) + "." + _maybe_award_zone_discovery(catch_zone) + _maybe_unlock_storage(fish.fish_kind)
		_add_popup(_fish_name(fish.fish_kind), _world_to_screen(net_center), _fish_color(fish.fish_kind))


func _maybe_award_zone_discovery(water_zone: int) -> String:
	if bool(water_zone_discovered[water_zone]):
		return ""

	water_zone_discovered[water_zone] = true
	var reward := _water_zone_discovery_reward(water_zone)
	if reward <= 0:
		return ""

	money += reward
	_add_popup(_water_zone_short_name(water_zone) + " +$" + str(reward), _world_to_screen(boat_agent.position), Color("#b7ef8a"))
	return " " + _water_zone_short_name(water_zone) + " route bonus +$" + str(reward) + "."


func _try_unload_boat() -> void:
	var room := _pool_capacity() - _live_fish_total()
	if room <= 0:
		status_text = "Boat is docked, but pools are full. Build, staff, or upgrade pools."
		return

	var moved := _move_fish_between_stocks(boat_agent.fish_stock, live_fish_stock, room)
	if moved <= 0:
		return
	fish_stored_total += moved
	status_text = "Boat unloaded " + str(moved) + " live fish into pools."
	_add_popup("Unload +" + str(moved), _world_to_screen(_boat_home_position()), Color("#b7ef8a"))


func _water_cell_target(cell: Vector2i) -> Vector2:
	return Vector2(
		clamp(float(cell.x) + 0.5, 0.25, float(GRID_W) - 0.25),
		clamp(float(cell.y) + 0.5, 0.25, float(WATER_ROWS) - 0.25)
	)


func _boat_is_at_dock() -> bool:
	return boat_agent.is_at(_boat_home_position())


func _is_boat_unlocked() -> bool:
	return net_level >= 2


func _is_worker_hiring_unlocked() -> bool:
	return net_level >= 2 and meat_sold_total >= 4


func _has_cutter_automation() -> bool:
	return _worker_count_assigned_to_building(BuildKind.CUTTER) > 0


func _has_smoker_automation() -> bool:
	return _worker_count_assigned_to_building(BuildKind.SMOKER) > 0


func _has_market_automation() -> bool:
	return _worker_count_assigned_to_building(BuildKind.MARKET) > 0


func _boat_direction() -> Vector2:
	return boat_agent.direction()


func _boat_net_center() -> Vector2:
	return boat_agent.net_center(net_level)


func _boat_net_length() -> float:
	return boat_agent.net_length(net_level)


func _boat_net_radius() -> float:
	return boat_agent.net_radius(net_level)


func _boat_net_capacity() -> int:
	return boat_agent.net_capacity(net_level)


func _boat_net_count() -> int:
	return boat_agent.net_count()


func _tick_cutters(delta: float) -> void:
	var cutter_count := _building_count(BuildKind.CUTTER)
	if cutter_count <= 0 or _live_fish_total() <= 0 or not _has_cutter_automation():
		cutter_progress = 0.0
		return
	if meat >= _meat_capacity():
		status_text = "Meat storage is full. Build storage or move markets near roads to sell faster."
		return

	var required: float = _cutter_required_time()
	cutter_progress += delta * _cutter_rate()

	while cutter_progress >= required and _live_fish_total() > 0:
		var fish_kind := _take_next_live_fish_kind()
		var produced := _fish_meat_yield(fish_kind) + int(cutter_level >= 3)
		if meat + produced > _meat_capacity():
			_add_fish_to_stock(live_fish_stock, fish_kind, 1)
			status_text = "Meat storage is full. Storage buildings create more room."
			break
		cutter_progress -= required
		meat += produced
		meat_processed_total += produced
		_award_station_worker_xp(BuildKind.CUTTER, "processing", 1)
		status_text = "Cutters processed " + _fish_name(fish_kind) + " into " + str(produced) + " meat."
		_add_popup("+" + str(produced) + " meat", _building_center(BuildKind.CUTTER), Color("#ffd7bb"))


func _tick_smokers(delta: float) -> void:
	var smoker_count := _building_count(BuildKind.SMOKER)
	if smoker_count <= 0 or not _has_smoker_automation():
		smoker_progress = 0.0
		return
	if meat < SMOKER_INPUT_MEAT:
		return
	if smoked_meat >= _smoked_meat_capacity():
		status_text = "Smoked meat storage is full. Storage or smokers create more smoked goods room."
		return

	var required: float = _smoker_required_time()
	smoker_progress += delta * _smoker_rate()

	while smoker_progress >= required and meat >= SMOKER_INPUT_MEAT:
		if smoked_meat + SMOKER_OUTPUT_SMOKED > _smoked_meat_capacity():
			status_text = "Smoked meat storage is full. Storage or smokers create more smoked goods room."
			break
		smoker_progress -= required
		meat -= SMOKER_INPUT_MEAT
		smoked_meat += SMOKER_OUTPUT_SMOKED
		_award_station_worker_xp(BuildKind.SMOKER, "processing", 1)
		status_text = "Smoker turned " + str(SMOKER_INPUT_MEAT) + " meat into smoked meat."
		_add_popup("+" + str(SMOKER_OUTPUT_SMOKED) + " smoked", _building_center(BuildKind.SMOKER), Color("#e8a35c"))


func _tick_dock_order(delta: float) -> void:
	if not _is_dock_order_unlocked():
		return

	if dock_order_active:
		dock_order_timer -= delta
		if dock_order_timer <= 0.0:
			status_text = "The dock order expired. A new buyer will post another request soon."
			_add_popup("Order expired", _order_board_center(), Color("#ff8f7a"))
			_clear_dock_order()
			dock_order_cooldown = DOCK_ORDER_COOLDOWN_SECONDS
		return

	dock_order_cooldown -= delta
	if dock_order_cooldown <= 0.0:
		_post_new_dock_order()


func _tick_customers(delta: float) -> void:
	customer_timer -= delta
	if customer_timer <= 0.0:
		if customer_agents.size() < MAX_CUSTOMERS:
			_spawn_customer()
		customer_timer = _next_customer_seconds()

	_tick_customer_agents(delta)
	if not _has_market_automation():
		_update_customer_counts()
		return

	market_sell_timer -= delta
	if market_sell_timer > 0.0:
		_update_customer_counts()
		return
	market_sell_timer = MARKET_SELL_SECONDS

	var sales_capacity := _market_sales_capacity()
	var waiting_indices := _waiting_customer_indices()
	var can_fill_order := _can_fill_dock_order()
	if sales_capacity <= 0 or (waiting_indices.is_empty() and not can_fill_order) or (meat <= 0 and smoked_meat <= 0):
		_update_customer_counts()
		return

	var sold_smoked := 0
	var sold_meat := 0
	var earned := 0
	var buyers_helped := 0
	var buyers_completed := 0
	var sale_units := 0
	var order_units_sold := 0
	var dock_order_completed := false
	for customer_index in waiting_indices:
		if sale_units >= sales_capacity:
			break

		var customer: Dictionary = customer_agents[int(customer_index)]
		var sale := _sell_to_buyer(customer, sales_capacity - sale_units)
		var units: int = int(sale["units"])
		if units <= 0:
			continue

		sold_meat += int(sale["meat"])
		sold_smoked += int(sale["smoked"])
		earned += int(sale["earned"])
		sale_units += units
		buyers_helped += 1

		customer["remaining"] = int(customer["remaining"]) - units
		customer["patience"] = _buyer_patience(int(customer["kind"]))
		if int(customer["remaining"]) <= 0:
			if int(customer["kind"]) == BuyerKind.MERCHANT:
				earned += MERCHANT_BULK_BONUS
				merchant_orders_completed_total += 1
			customer["state"] = "leaving_happy"
			customer["target"] = customer["exit"]
			_record_buyer_served(int(customer["kind"]))
			buyers_completed += 1
		customer_agents[int(customer_index)] = customer

	if sale_units < sales_capacity and _can_fill_dock_order():
		var order_sale := _sell_to_dock_order(sales_capacity - sale_units)
		var order_units: int = int(order_sale["units"])
		if order_units > 0:
			sold_meat += int(order_sale["meat"])
			sold_smoked += int(order_sale["smoked"])
			earned += int(order_sale["earned"])
			sale_units += order_units
			order_units_sold += order_units
			dock_order_completed = bool(order_sale["completed"])

	if earned <= 0:
		_update_customer_counts()
		return

	money += earned
	_award_station_worker_xp(BuildKind.MARKET, "trading", max(1, sale_units))
	var sold_parts: Array = []
	if sold_smoked > 0:
		sold_parts.append(str(sold_smoked) + " smoked meat")
	if sold_meat > 0:
		sold_parts.append(str(sold_meat) + " meat")
	var sale_targets: Array = []
	if buyers_helped > 0:
		sale_targets.append(str(buyers_helped) + " buyers")
	if order_units_sold > 0:
		sale_targets.append("the dock order")
	status_text = "Sold " + " and ".join(sold_parts) + " to " + " and ".join(sale_targets) + " for $" + str(earned) + "."
	if buyers_completed > 0:
		status_text += " Completed " + str(buyers_completed) + " order" + ("s." if buyers_completed > 1 else ".")
	if dock_order_completed:
		status_text += " Dock order complete."
	if dock_order_active:
		status_text += " Dock order: " + _dock_order_progress_text() + "."
	_add_popup("+$" + str(earned), _building_center(BuildKind.MARKET), Color("#b7ef8a"))
	_update_customer_counts()


func _spawn_customer() -> void:
	var spawn_cell := Vector2i(randi_range(2, GRID_W - 3), ROAD_ROW)
	var target_cell := _customer_target_cell()
	var buyer_kind := _random_buyer_kind()
	customer_agents.append({
		"pos": Vector2(spawn_cell.x, spawn_cell.y),
		"target": Vector2(target_cell.x, target_cell.y),
		"exit": Vector2(spawn_cell.x, spawn_cell.y),
		"state": "arriving",
		"patience": _buyer_patience(buyer_kind),
		"kind": buyer_kind,
		"remaining": _buyer_order_size(buyer_kind)
	})


func _tick_customer_agents(delta: float) -> void:
	for i in range(customer_agents.size() - 1, -1, -1):
		var customer: Dictionary = customer_agents[i]
		var pos: Vector2 = customer["pos"]
		var target: Vector2 = customer["target"]
		customer["pos"] = _move_grid_position(pos, target, CUSTOMER_WALK_SPEED * delta)
		var next_pos: Vector2 = customer["pos"]

		if str(customer["state"]) == "arriving" and _agent_reached(next_pos, target):
			customer["state"] = "waiting"
			customer["patience"] = _buyer_patience(int(customer["kind"]))
		elif str(customer["state"]) == "waiting":
			customer["patience"] = float(customer["patience"]) - delta
			if float(customer["patience"]) <= 0.0:
				customer["state"] = "leaving_angry"
				customer["target"] = customer["exit"]
				customers_lost += 1
				status_text = "A " + _buyer_name(int(customer["kind"])) + " left hungry. Match buyer wants or add market staff."
				_add_popup("-buyer", _building_center(BuildKind.MARKET), Color("#ff8f7a"))
		elif str(customer["state"]).begins_with("leaving") and _agent_reached(next_pos, target):
			customer_agents.remove_at(i)
			continue

		customer_agents[i] = customer


func _next_customer_seconds() -> float:
	var pull := float(_building_count(BuildKind.MARKET)) * 0.25
	pull += _worker_market_pull()
	if _is_smoker_unlocked():
		pull += 0.2
	return max(1.15, randf_range(2.4, 4.1) - pull)


func _is_dock_order_unlocked() -> bool:
	return goal_step >= GoalStep.DOCK_ORDER


func _post_new_dock_order() -> void:
	var roll := randf()
	dock_order_active = true
	dock_order_delivered_meat = 0
	dock_order_delivered_smoked = 0
	dock_order_timer = DOCK_ORDER_SECONDS
	dock_order_cooldown = DOCK_ORDER_COOLDOWN_SECONDS

	if _building_count(BuildKind.SMOKER) <= 0:
		dock_order_name = "Camp Stew"
		dock_order_need_meat = 6
		dock_order_need_smoked = 0
	elif roll < 0.40:
		dock_order_name = "Dock Lunch"
		dock_order_need_meat = 6
		dock_order_need_smoked = 0
	elif roll < 0.72:
		dock_order_name = "Smokehouse Crate"
		dock_order_need_meat = 0
		dock_order_need_smoked = 3
	else:
		dock_order_name = "Harbor Feast"
		dock_order_need_meat = 4
		dock_order_need_smoked = 2

	status_text = "New dock order posted: " + _dock_order_progress_text() + "."
	_add_popup("New order", _order_board_center(), Color("#f2d16b"))


func _clear_dock_order() -> void:
	dock_order_active = false
	dock_order_name = ""
	dock_order_need_meat = 0
	dock_order_need_smoked = 0
	dock_order_delivered_meat = 0
	dock_order_delivered_smoked = 0
	dock_order_timer = 0.0


func _can_fill_dock_order() -> bool:
	if not dock_order_active:
		return false
	if _dock_order_remaining_meat() > 0 and meat > 0:
		return true
	if _dock_order_remaining_smoked() > 0 and smoked_meat > 0:
		return true
	return false


func _sell_to_dock_order(capacity: int) -> Dictionary:
	var result := {
		"meat": 0,
		"smoked": 0,
		"earned": 0,
		"units": 0,
		"completed": false
	}

	while capacity > 0 and _can_fill_dock_order():
		if _dock_order_remaining_smoked() > 0 and smoked_meat > 0:
			smoked_meat -= 1
			dock_order_delivered_smoked += 1
			smoked_meat_sold_total += 1
			result["smoked"] = int(result["smoked"]) + 1
			result["earned"] = int(result["earned"]) + SMOKED_MEAT_PRICE
			result["units"] = int(result["units"]) + 1
		elif _dock_order_remaining_meat() > 0 and meat > 0:
			meat -= 1
			dock_order_delivered_meat += 1
			meat_sold_total += 1
			result["meat"] = int(result["meat"]) + 1
			result["earned"] = int(result["earned"]) + MEAT_PRICE
			result["units"] = int(result["units"]) + 1
		else:
			break
		capacity -= 1

	if dock_order_active and _dock_order_is_complete():
		result["earned"] = int(result["earned"]) + DOCK_ORDER_BONUS
		result["completed"] = true
		dock_orders_completed_total += 1
		var completed_name := dock_order_name
		_clear_dock_order()
		dock_order_cooldown = DOCK_ORDER_COOLDOWN_SECONDS
		status_text = completed_name + " completed. Dock order bonus: $" + str(DOCK_ORDER_BONUS) + "."
		_add_popup("Order +$" + str(DOCK_ORDER_BONUS), _order_board_center(), Color("#b7ef8a"))

	return result


func _dock_order_remaining_meat() -> int:
	return max(0, dock_order_need_meat - dock_order_delivered_meat)


func _dock_order_remaining_smoked() -> int:
	return max(0, dock_order_need_smoked - dock_order_delivered_smoked)


func _dock_order_is_complete() -> bool:
	return _dock_order_remaining_meat() <= 0 and _dock_order_remaining_smoked() <= 0


func _dock_order_progress_text() -> String:
	if not dock_order_active:
		return "waiting for a new dock order"

	var parts: Array = []
	if dock_order_need_meat > 0:
		parts.append("M " + str(dock_order_delivered_meat) + "/" + str(dock_order_need_meat))
	if dock_order_need_smoked > 0:
		parts.append("S " + str(dock_order_delivered_smoked) + "/" + str(dock_order_need_smoked))
	return dock_order_name + " " + " ".join(parts) + " " + str(max(0, int(ceil(dock_order_timer)))) + "s"


func _order_board_cell() -> Vector2i:
	return Vector2i(GRID_W - 3, ROAD_ROW)


func _order_board_center() -> Vector2:
	return _cell_rect(_order_board_cell()).get_center()


func _random_buyer_kind() -> int:
	var roll := randf()
	var cooks_unlocked := _building_count(BuildKind.SMOKER) > 0 or smoked_meat > 0 or goal_step >= GoalStep.SMOKED_SALE
	var merchants_unlocked := goal_step >= GoalStep.COOK_SALE or meat_sold_total >= 12 or _building_count(BuildKind.MARKET) >= 2

	if cooks_unlocked and merchants_unlocked:
		if roll < 0.50:
			return BuyerKind.VILLAGER
		if roll < 0.78:
			return BuyerKind.COOK
		return BuyerKind.MERCHANT
	if cooks_unlocked:
		if roll < 0.68:
			return BuyerKind.VILLAGER
		return BuyerKind.COOK
	if merchants_unlocked:
		if roll < 0.75:
			return BuyerKind.VILLAGER
		return BuyerKind.MERCHANT
	return BuyerKind.VILLAGER


func _sell_to_buyer(customer: Dictionary, capacity: int) -> Dictionary:
	var buyer_kind := int(customer["kind"])
	var remaining: int = min(int(customer["remaining"]), capacity)
	var result := {
		"meat": 0,
		"smoked": 0,
		"earned": 0,
		"units": 0
	}

	match buyer_kind:
		BuyerKind.VILLAGER:
			if meat > 0:
				meat -= 1
				result["meat"] = 1
				result["earned"] = MEAT_PRICE
				result["units"] = 1
			elif smoked_meat > 0:
				smoked_meat -= 1
				result["smoked"] = 1
				result["earned"] = SMOKED_MEAT_PRICE
				result["units"] = 1
		BuyerKind.COOK:
			if smoked_meat > 0:
				smoked_meat -= 1
				result["smoked"] = 1
				result["earned"] = COOK_SMOKED_MEAT_PRICE
				result["units"] = 1
		BuyerKind.MERCHANT:
			while remaining > 0 and (meat > 0 or smoked_meat > 0):
				if meat > 0:
					meat -= 1
					result["meat"] = int(result["meat"]) + 1
					result["earned"] = int(result["earned"]) + MEAT_PRICE
				else:
					smoked_meat -= 1
					result["smoked"] = int(result["smoked"]) + 1
					result["earned"] = int(result["earned"]) + SMOKED_MEAT_PRICE
				result["units"] = int(result["units"]) + 1
				remaining -= 1

	meat_sold_total += int(result["meat"])
	smoked_meat_sold_total += int(result["smoked"])
	return result


func _record_buyer_served(buyer_kind: int) -> void:
	buyers_served_by_kind[buyer_kind] = int(buyers_served_by_kind[buyer_kind]) + 1


func _buyer_order_size(buyer_kind: int) -> int:
	if buyer_kind == BuyerKind.MERCHANT:
		return MERCHANT_BULK_SIZE
	return 1


func _buyer_patience(buyer_kind: int) -> float:
	match buyer_kind:
		BuyerKind.COOK:
			return CUSTOMER_PATIENCE_SECONDS + 2.0
		BuyerKind.MERCHANT:
			return CUSTOMER_PATIENCE_SECONDS + 4.0
		_:
			return CUSTOMER_PATIENCE_SECONDS


func _buyer_name(buyer_kind: int) -> String:
	match buyer_kind:
		BuyerKind.COOK:
			return "cook"
		BuyerKind.MERCHANT:
			return "merchant"
		_:
			return "villager"


func _buyer_color(buyer_kind: int) -> Color:
	match buyer_kind:
		BuyerKind.COOK:
			return Color("#d58cff")
		BuyerKind.MERCHANT:
			return Color("#f0d597")
		_:
			return Color("#9fe4dd")


func _buyer_short_label(buyer_kind: int) -> String:
	match buyer_kind:
		BuyerKind.COOK:
			return "C"
		BuyerKind.MERCHANT:
			return "M"
		_:
			return "V"


func _buyer_want_label(customer: Dictionary) -> String:
	match int(customer["kind"]):
		BuyerKind.COOK:
			return "S"
		BuyerKind.MERCHANT:
			return "x" + str(customer["remaining"])
		_:
			return "M"


func _buyer_want_text(customer: Dictionary) -> String:
	match int(customer["kind"]):
		BuyerKind.COOK:
			return "wants smoked meat"
		BuyerKind.MERCHANT:
			return "wants " + str(customer["remaining"]) + " goods for a bulk order"
		_:
			return "wants meat"


func _customer_target_cell() -> Vector2i:
	var markets := _building_cells(BuildKind.MARKET)
	if markets.is_empty():
		return Vector2i(GRID_W - 3, ROAD_ROW)
	return markets[randi_range(0, markets.size() - 1)]


func _waiting_customer_indices() -> Array:
	var result: Array = []
	for i in customer_agents.size():
		var customer: Dictionary = customer_agents[i]
		if str(customer["state"]) == "waiting":
			result.append(i)
	return result


func _update_customer_counts() -> void:
	customers_waiting = _waiting_customer_indices().size()
	customer_patience_timer = _lowest_waiting_patience()


func _lowest_waiting_patience() -> float:
	var lowest := CUSTOMER_PATIENCE_SECONDS
	var found := false
	for customer in customer_agents:
		if str(customer["state"]) != "waiting":
			continue
		found = true
		lowest = min(lowest, float(customer["patience"]))
	return lowest if found else CUSTOMER_PATIENCE_SECONDS


func _building_count(building: int) -> int:
	var count := 0
	for row in tiles:
		for tile in row:
			if tile["building"] == building:
				count += 1
	return count


func _building_cells(building: int) -> Array:
	var result: Array = []
	for y in GRID_H:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if tile["building"] == building:
				result.append(Vector2i(x, y))
	return result


func _move_grid_position(pos: Vector2, target: Vector2, distance: float) -> Vector2:
	var delta := target - pos
	if delta.length() <= distance or delta.length() <= 0.001:
		return target
	return pos + delta.normalized() * distance


func _agent_reached(pos: Vector2, target: Vector2) -> bool:
	return pos.distance_to(target) <= 0.03


func _worker_count_assigned_to(cell: Vector2i) -> int:
	var count := 0
	for worker in workers:
		var assigned: Vector2i = worker["assigned"]
		var pos: Vector2 = worker["pos"]
		if assigned == cell and _agent_reached(pos, Vector2(cell.x, cell.y)):
			count += 1
	return count


func _worker_count_assigned_to_building(building: int) -> int:
	var count := 0
	for worker in workers:
		var assigned: Vector2i = worker["assigned"]
		if assigned.x < 0 or assigned.y < 0 or assigned.x >= GRID_W or assigned.y >= GRID_H:
			continue
		var tile: Dictionary = tiles[assigned.y][assigned.x]
		var pos: Vector2 = worker["pos"]
		if tile["building"] == building and _agent_reached(pos, Vector2(assigned.x, assigned.y)):
			count += 1
	return count


func _worker_pool_capacity_bonus(cell: Vector2i) -> int:
	var bonus := 0
	for worker in workers:
		if not _worker_is_staffing_cell(worker, cell):
			continue
		bonus += WORKER_POOL_CAPACITY_BONUS + _worker_skill(worker, "handling") - 1
	return bonus


func _worker_storage_capacity_bonus(cell: Vector2i) -> int:
	var bonus := 0
	for worker in workers:
		if not _worker_is_staffing_cell(worker, cell):
			continue
		bonus += WORKER_STORAGE_CAPACITY_BONUS + (_worker_skill(worker, "handling") - 1) * 2
	return bonus


func _worker_processing_rate_bonus(cell: Vector2i, base_bonus: float) -> float:
	var bonus := 0.0
	for worker in workers:
		if not _worker_is_staffing_cell(worker, cell):
			continue
		bonus += base_bonus * (1.0 + float(_worker_skill(worker, "processing") - 1) * 0.5)
	return bonus


func _worker_market_capacity_bonus(cell: Vector2i) -> int:
	var bonus := 0
	for worker in workers:
		if not _worker_is_staffing_cell(worker, cell):
			continue
		bonus += _worker_skill(worker, "trading")
	return bonus


func _worker_market_pull() -> float:
	var pull := 0.0
	for worker in workers:
		var job_key := _worker_job_key(worker)
		if job_key != "market":
			continue
		var assigned: Vector2i = worker["assigned"]
		if _agent_reached(worker["pos"], Vector2(assigned.x, assigned.y)):
			pull += 0.2 * float(_worker_skill(worker, "trading"))
	return pull


func _worker_is_staffing_cell(worker: Dictionary, cell: Vector2i) -> bool:
	var assigned: Vector2i = worker["assigned"]
	return assigned == cell and _agent_reached(worker["pos"], Vector2(cell.x, cell.y)) and _worker_job_key(worker) != "idle"


func _pool_capacity() -> int:
	var capacity := 0
	for y in GRID_H:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if tile["building"] == BuildKind.POOL:
				capacity += _pool_capacity_at(Vector2i(x, y))
	return capacity


func _pool_capacity_at(cell: Vector2i) -> int:
	var capacity := 4 + pool_level * 2
	if _has_adjacent_tile_kind(cell, TileKind.WATER):
		capacity += 2
	capacity += _worker_pool_capacity_bonus(cell)
	return capacity


func _pool_capacity_without(cell_to_exclude: Vector2i) -> int:
	var capacity := 0
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			if cell == cell_to_exclude:
				continue
			var tile: Dictionary = tiles[y][x]
			if tile["building"] == BuildKind.POOL:
				capacity += _pool_capacity_at(cell)
	return capacity


func _can_remove_pool_at(cell: Vector2i) -> bool:
	return _live_fish_total() <= _pool_capacity_without(cell)


func _meat_capacity() -> int:
	var capacity := 18 + _building_count(BuildKind.MARKET) * 6 + cutter_level * 2
	for y in GRID_H:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if tile["building"] == BuildKind.STORAGE:
				capacity += _storage_capacity_at(Vector2i(x, y))
	return capacity


func _meat_capacity_without(cell_to_exclude: Vector2i) -> int:
	var capacity := 18 + _building_count(BuildKind.MARKET) * 6 + cutter_level * 2
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			if cell == cell_to_exclude:
				continue
			var tile: Dictionary = tiles[y][x]
			if tile["building"] == BuildKind.STORAGE:
				capacity += _storage_capacity_at(cell)
	return capacity


func _can_remove_storage_at(cell: Vector2i) -> bool:
	return meat <= _meat_capacity_without(cell) and smoked_meat <= _smoked_meat_capacity_without(cell)


func _storage_capacity_at(cell: Vector2i) -> int:
	var capacity := 14
	if _has_adjacent_building(cell, BuildKind.MARKET):
		capacity += 6
	capacity += _worker_storage_capacity_bonus(cell)
	return capacity


func _smoked_meat_capacity() -> int:
	var capacity := 8
	capacity += _building_count(BuildKind.STORAGE) * 4
	for y in GRID_H:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if tile["building"] == BuildKind.SMOKER:
				capacity += _smoker_capacity_at(Vector2i(x, y))
	return capacity


func _smoked_meat_capacity_without(cell_to_exclude: Vector2i) -> int:
	var capacity := 8
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			if cell == cell_to_exclude:
				continue
			var tile: Dictionary = tiles[y][x]
			if tile["building"] == BuildKind.STORAGE:
				capacity += 4
			elif tile["building"] == BuildKind.SMOKER:
				capacity += _smoker_capacity_at_with_exclusion(cell, cell_to_exclude)
	return capacity


func _can_remove_smoker_at(cell: Vector2i) -> bool:
	return smoked_meat <= _smoked_meat_capacity_without(cell)


func _smoker_capacity_at(cell: Vector2i) -> int:
	return _smoker_capacity_at_with_exclusion(cell, Vector2i(-1, -1))


func _smoker_capacity_at_with_exclusion(cell: Vector2i, excluded_cell: Vector2i) -> int:
	var capacity := 4
	if _has_adjacent_building_except(cell, BuildKind.STORAGE, excluded_cell):
		capacity += 2
	return capacity


func _cutter_required_time() -> float:
	return max(1.2, 4.0 - float(cutter_level - 1) * 0.45)


func _cutter_rate() -> float:
	var rate := 0.0
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			var tile: Dictionary = tiles[y][x]
			if tile["building"] != BuildKind.CUTTER:
				continue
			rate += _cutter_rate_at(cell)
	return rate


func _cutter_rate_at(cell: Vector2i) -> float:
	var rate := 1.0
	if _has_adjacent_building(cell, BuildKind.POOL):
		rate += 0.5
	rate += _worker_processing_rate_bonus(cell, WORKER_CUTTER_RATE_BONUS)
	return rate


func _smoker_required_time() -> float:
	return SMOKER_SECONDS


func _smoker_rate() -> float:
	var rate := 0.0
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			var tile: Dictionary = tiles[y][x]
			if tile["building"] != BuildKind.SMOKER:
				continue
			rate += _smoker_rate_at(cell)
	return rate


func _smoker_rate_at(cell: Vector2i) -> float:
	var rate := 1.0
	if _has_adjacent_building(cell, BuildKind.CUTTER):
		rate += 0.45
	if _has_adjacent_building(cell, BuildKind.STORAGE):
		rate += 0.25
	rate += _worker_processing_rate_bonus(cell, WORKER_SMOKER_RATE_BONUS)
	return rate


func _market_sales_capacity() -> int:
	var capacity := 0
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			var tile: Dictionary = tiles[y][x]
			if tile["building"] != BuildKind.MARKET:
				continue
			capacity += _market_capacity_at(cell)
	return capacity


func _market_capacity_at(cell: Vector2i) -> int:
	var capacity := 1
	if _has_adjacent_tile_kind(cell, TileKind.ROAD):
		capacity += 1
	if _is_plaza_connected(cell):
		capacity += 1
	capacity += _worker_market_capacity_bonus(cell)
	return capacity


func _is_plaza_connected(cell: Vector2i) -> bool:
	var tile: Dictionary = tiles[cell.y][cell.x]
	return tile["kind"] == TileKind.PLAZA or _has_adjacent_tile_kind(cell, TileKind.PLAZA)


func _random_fish_kind() -> int:
	return _random_fish_kind_for_zone(WaterZone.OPEN)


func _random_fish_kind_for_zone(water_zone: int) -> int:
	var roll := randf()
	match water_zone:
		WaterZone.SHALLOW:
			if net_level >= 2 and roll > 0.92:
				return FishKind.SILVERFISH
			if roll < 0.82:
				return FishKind.MINNOW
			return FishKind.CARP
		WaterZone.COLD:
			if net_level >= 2:
				if roll < 0.36:
					return FishKind.MINNOW
				if roll < 0.62:
					return FishKind.CARP
				return FishKind.SILVERFISH
			if roll < 0.62:
				return FishKind.MINNOW
			return FishKind.CARP
		WaterZone.DEEP:
			if net_level >= 2:
				if roll < 0.22:
					return FishKind.MINNOW
				if roll < 0.64:
					return FishKind.CARP
				return FishKind.SILVERFISH
			if roll < 0.42:
				return FishKind.MINNOW
			return FishKind.CARP
		WaterZone.MONSTER:
			if net_level >= 2:
				if roll < 0.18:
					return FishKind.MINNOW
				if roll < 0.46:
					return FishKind.CARP
				return FishKind.SILVERFISH
			if roll < 0.25:
				return FishKind.MINNOW
			return FishKind.CARP

	if net_level >= 3:
		if roll < 0.30:
			return FishKind.MINNOW
		if roll < 0.75:
			return FishKind.CARP
		return FishKind.SILVERFISH
	if net_level >= 2:
		if roll < 0.45:
			return FishKind.MINNOW
		if roll < 0.85:
			return FishKind.CARP
		return FishKind.SILVERFISH
	if roll < 0.72:
		return FishKind.MINNOW
	return FishKind.CARP


func _fish_name(fish_kind: int) -> String:
	match fish_kind:
		FishKind.MINNOW:
			return "minnow"
		FishKind.CARP:
			return "carp"
		FishKind.SILVERFISH:
			return "silverfish"
		_:
			return "fish"


func _fish_plural(fish_kind: int, count: int) -> String:
	var name := _fish_name(fish_kind)
	if count == 1:
		return name
	if fish_kind == FishKind.SILVERFISH:
		return "silverfish"
	return name + "s"


func _fish_color(fish_kind: int) -> Color:
	match fish_kind:
		FishKind.MINNOW:
			return Color("#f2d16b")
		FishKind.CARP:
			return Color("#f08b57")
		FishKind.SILVERFISH:
			return Color("#c7e8ff")
		_:
			return Color("#f2d16b")


func _fish_meat_yield(fish_kind: int) -> int:
	match fish_kind:
		FishKind.MINNOW:
			return 1
		FishKind.CARP:
			return 2
		FishKind.SILVERFISH:
			return 3
		_:
			return 1


func _stock_total(stock: Array) -> int:
	var total := 0
	for amount in stock:
		total += int(amount)
	return total


func _carried_fish_total() -> int:
	return _stock_total(carried_fish_stock)


func _live_fish_total() -> int:
	return _stock_total(live_fish_stock)


func _add_fish_to_stock(stock: Array, fish_kind: int, count: int) -> void:
	stock[fish_kind] = int(stock[fish_kind]) + count


func _move_fish_between_stocks(from_stock: Array, to_stock: Array, max_count: int) -> int:
	var moved := 0
	for fish_kind: int in [FishKind.SILVERFISH, FishKind.CARP, FishKind.MINNOW]:
		if moved >= max_count:
			break
		var available := int(from_stock[fish_kind])
		if available <= 0:
			continue
		var take: int = min(available, max_count - moved)
		from_stock[fish_kind] = available - take
		to_stock[fish_kind] = int(to_stock[fish_kind]) + take
		moved += take
	return moved


func _take_next_live_fish_kind() -> int:
	return _take_next_fish_kind(live_fish_stock)


func _stock_summary(stock: Array) -> String:
	if _stock_total(stock) <= 0:
		return ""

	var parts: Array = []
	if int(stock[FishKind.MINNOW]) > 0:
		parts.append("M" + str(stock[FishKind.MINNOW]))
	if int(stock[FishKind.CARP]) > 0:
		parts.append("C" + str(stock[FishKind.CARP]))
	if int(stock[FishKind.SILVERFISH]) > 0:
		parts.append("S" + str(stock[FishKind.SILVERFISH]))
	return "[" + " ".join(parts) + "]"


func _worker_name(worker_index: int) -> String:
	var names: Array = ["Mara", "Ivo", "Nia", "Toren", "Sella", "Bran"]
	if worker_index >= 0 and worker_index < names.size():
		return names[worker_index]
	return "Worker " + str(worker_index + 1)


func _worker_index_at_cell(cell: Vector2i) -> int:
	for i in workers.size():
		var worker: Dictionary = workers[i]
		var pos: Vector2 = worker["pos"]
		var assigned: Vector2i = worker["assigned"]
		if assigned == cell:
			return i
		if pos.distance_to(Vector2(cell.x, cell.y)) <= 0.55:
			return i
	return -1


func _buyer_index_at_cell(cell: Vector2i) -> int:
	for i in customer_agents.size():
		var customer: Dictionary = customer_agents[i]
		var pos: Vector2 = customer["pos"]
		var target: Vector2 = customer["target"]
		if Vector2(cell.x, cell.y).distance_to(pos) <= 0.55:
			return i
		if Vector2(cell.x, cell.y).distance_to(target) <= 0.35:
			return i
	return -1


func _is_valid_worker_assignment(cell: Vector2i) -> bool:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] == TileKind.EXPANSION:
		return false
	if tile["kind"] == TileKind.WATER:
		return cell.y == WATER_ROWS - 1
	return true


func _worker_assignment_hint(cell: Vector2i) -> String:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] == TileKind.WATER:
		return "They will cast from the nearest dock, carry each catch to a pool, then repeat."
	if tile["kind"] == TileKind.ROAD:
		return "They will stand by on the road until you assign a job."
	if tile["building"] == BuildKind.NONE and tile["kind"] == TileKind.DOCK:
		return "They will stand by on the dock, close to fishing work."
	if tile["building"] == BuildKind.NONE and tile["kind"] == TileKind.PLAZA:
		return "They will stand by in the plaza where buyers gather."

	match int(tile["building"]):
		BuildKind.POOL:
			return "Assigned pool workers add +" + str(WORKER_POOL_CAPACITY_BONUS) + " live capacity."
		BuildKind.CUTTER:
			return "Assigned cutter workers speed up processing."
		BuildKind.MARKET:
			return "Assigned market workers serve more buyers and attract buyers faster."
		BuildKind.STORAGE:
			return "Storage workers add meat capacity and improve their Handling skill."
		BuildKind.SMOKER:
			return "Assigned smoker workers speed up smoked meat production."
		_:
			return "They will stand by on this tile."


func _format_ratio(value: float) -> String:
	return "%.1f" % value


func _building_cost(building: int) -> int:
	match building:
		BuildKind.POOL:
			return COST_POOL
		BuildKind.CUTTER:
			return COST_CUTTER
		BuildKind.MARKET:
			return COST_MARKET
		BuildKind.STORAGE:
			return COST_STORAGE
		BuildKind.SMOKER:
			return COST_SMOKER
		_:
			return 0


func _tool_cost(tool: String) -> int:
	match tool:
		TOOL_POOL:
			return COST_POOL
		TOOL_CUTTER:
			return COST_CUTTER
		TOOL_MARKET:
			return COST_MARKET
		TOOL_STORAGE:
			return COST_STORAGE
		TOOL_SMOKER:
			return COST_SMOKER
		TOOL_EXPAND:
			return COST_EXPAND
		_:
			return 0


func _tool_label(tool: String) -> String:
	match tool:
		TOOL_WALK:
			return "Walk"
		TOOL_CATCH:
			return "Fish"
		TOOL_MAP:
			return "Map"
		TOOL_PEOPLE:
			return "People"
		TOOL_POOL:
			return "Pool $" + str(COST_POOL)
		TOOL_CUTTER:
			return "Cutter $" + str(COST_CUTTER)
		TOOL_MARKET:
			return "Market $" + str(COST_MARKET)
		TOOL_STORAGE:
			return "Storage $" + str(COST_STORAGE) if _is_tool_unlocked(tool) else "Storage L"
		TOOL_SMOKER:
			return "Smoker $" + str(COST_SMOKER) if _is_tool_unlocked(tool) else "Smoker L"
		TOOL_EXPAND:
			return "Expand $" + str(COST_EXPAND) if _is_tool_unlocked(tool) else "Expand L"
		TOOL_MOVE:
			return "Move"
		TOOL_REMOVE:
			return "Remove"
		_:
			return tool


func _is_tool_unlocked(tool: String) -> bool:
	if tool == TOOL_STORAGE:
		return _is_storage_unlocked()
	if tool == TOOL_SMOKER:
		return _is_smoker_unlocked()
	if tool == TOOL_EXPAND:
		return _is_land_expansion_unlocked()
	return true


func _tool_locked_reason(tool: String) -> String:
	if tool == TOOL_STORAGE:
		return "Storage is locked. Catch a silverfish after upgrading the net to level 2."
	if tool == TOOL_SMOKER:
		return "Smoker is locked. Expand land and prove steady sales first."
	if tool == TOOL_EXPAND:
		return "Expansion is locked. Build Storage first."
	return "This tool is locked."


func _is_building_unlocked(building: int) -> bool:
	if building == BuildKind.STORAGE:
		return _is_storage_unlocked()
	if building == BuildKind.SMOKER:
		return _is_smoker_unlocked()
	return true


func _building_locked_reason(building: int) -> String:
	if building == BuildKind.STORAGE:
		return "Storage is locked. Catch a silverfish first."
	if building == BuildKind.SMOKER:
		return "Smoker is locked. Complete the steady sales goal first."
	return "This building is locked."


func _is_storage_unlocked() -> bool:
	return storage_unlocked or int(fish_caught_by_kind[FishKind.SILVERFISH]) > 0


func _is_land_expansion_unlocked() -> bool:
	return _building_count(BuildKind.STORAGE) > 0


func _is_smoker_unlocked() -> bool:
	return goal_step >= GoalStep.SMOKER


func _maybe_unlock_storage(fish_kind: int) -> String:
	if fish_kind != FishKind.SILVERFISH or storage_unlocked:
		return ""

	storage_unlocked = true
	_add_popup("Storage unlocked", grid_rect.position + Vector2(grid_rect.size.x * 0.5, 46.0), Color("#b7ef8a"))
	return " Storage unlocked."


func _net_upgrade_cost() -> int:
	return 50 + (net_level - 1) * 25


func _boat_upgrade_cost() -> int:
	return 28 + (boat_agent.level - 1) * 22


func _pool_upgrade_cost() -> int:
	return 25 + (pool_level - 1) * 20


func _cutter_upgrade_cost() -> int:
	return 30 + (cutter_level - 1) * 25


func _net_unlock_text() -> String:
	if net_level == 2:
		return " The boat is ready at the dock, and silverfish can now appear offshore."
	if net_level == 3:
		return " Net radius grew again. Better fish now appear more often."
	return " Net capacity is now " + str(_boat_net_capacity()) + "."


func _affordability_color(cost: int) -> Color:
	if cost <= 0 or money >= cost:
		return Color.WHITE
	return Color("#a98282")


func _building_name(building: int) -> String:
	match building:
		BuildKind.POOL:
			return "pool"
		BuildKind.CUTTER:
			return "cutter"
		BuildKind.MARKET:
			return "market"
		BuildKind.STORAGE:
			return "storage"
		BuildKind.SMOKER:
			return "smoker"
		_:
			return "building"


func _layout_hint_for_building(cell: Vector2i, building: int) -> String:
	match building:
		BuildKind.POOL:
			if tiles[cell.y][cell.x]["kind"] == TileKind.DOCK:
				return "Dock pools sit right on the working shoreline."
			if _has_adjacent_tile_kind(cell, TileKind.WATER):
				return "Water access gives this pool +2 capacity."
			return "Pools get +2 capacity when touching water."
		BuildKind.CUTTER:
			if _has_adjacent_building(cell, BuildKind.POOL):
				return "Adjacent pool gives this cutter +50% work rate."
			return "Cutters work faster beside pools."
		BuildKind.MARKET:
			if _has_adjacent_tile_kind(cell, TileKind.ROAD) and _is_plaza_connected(cell):
				return "Road and plaza access give this market strong buyer flow."
			if _is_plaza_connected(cell):
				return "Plaza access gives this market +1 sale capacity."
			if _has_adjacent_tile_kind(cell, TileKind.ROAD):
				return "Road access gives this market +1 sale capacity."
			return "Markets sell faster beside the road or plaza."
		BuildKind.STORAGE:
			if _has_adjacent_building(cell, BuildKind.MARKET):
				return "Adjacent market gives this storage +6 meat capacity."
			return "Storage gets +6 capacity beside markets."
		BuildKind.SMOKER:
			if _has_adjacent_building(cell, BuildKind.CUTTER) and _has_adjacent_building(cell, BuildKind.STORAGE):
				return "Cutter and storage adjacency make this smoker faster and roomier."
			if _has_adjacent_building(cell, BuildKind.CUTTER):
				return "Adjacent cutter gives this smoker +45% work rate."
			if _has_adjacent_building(cell, BuildKind.STORAGE):
				return "Adjacent storage gives this smoker +25% work rate and +2 smoked capacity."
			return "Smokers work faster beside cutters and storage."
		_:
			return ""


func _adjacent_cells(cell: Vector2i) -> Array:
	var result: Array = []
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var next: Vector2i = cell + offset
		if next.x >= 0 and next.y >= 0 and next.x < GRID_W and next.y < GRID_H:
			result.append(next)
	return result


func _has_adjacent_tile_kind(cell: Vector2i, kind: int) -> bool:
	for next in _adjacent_cells(cell):
		var tile: Dictionary = tiles[next.y][next.x]
		if tile["kind"] == kind:
			return true
	return false


func _has_adjacent_building(cell: Vector2i, building: int) -> bool:
	for next in _adjacent_cells(cell):
		var tile: Dictionary = tiles[next.y][next.x]
		if tile["building"] == building:
			return true
	return false


func _has_adjacent_building_except(cell: Vector2i, building: int, excluded_cell: Vector2i) -> bool:
	for next in _adjacent_cells(cell):
		if next == excluded_cell:
			continue
		var tile: Dictionary = tiles[next.y][next.x]
		if tile["building"] == building:
			return true
	return false


func _cancel_move_if_needed() -> void:
	if moving_building == BuildKind.NONE:
		return
	var tile: Dictionary = tiles[move_source_cell.y][move_source_cell.x]
	tile["building"] = moving_building
	tiles[move_source_cell.y][move_source_cell.x] = tile
	moving_building = BuildKind.NONE
	move_source_cell = Vector2i(-1, -1)
	status_text = "Move cancelled."


func _check_goal_progress() -> void:
	match goal_step:
		GoalStep.CATCH:
			if fish_caught_total >= 2:
				_complete_goal("First catch secured.", 4)
		GoalStep.STORE:
			if fish_stored_total >= 2:
				_complete_goal("Pools are feeding the production line.", 4)
		GoalStep.PROCESS:
			if meat_processed_total >= 2:
				_complete_goal("The cutter is turning fish into sellable meat.", 5)
		GoalStep.SELL:
			if meat_sold_total >= 2:
				_complete_goal("Buyers are buying. The loop works.", 6)
		GoalStep.UPGRADE:
			if upgrades_bought_total >= 1:
				_complete_goal("First upgrade bought. The fishery is getting faster.", 8)
		GoalStep.BUILD:
			if buildings_built_total >= 1:
				_complete_goal("First expansion built. Phase 1 loop is online.", 10)
		GoalStep.NET_TWO:
			if net_level >= 2:
				_complete_goal("Net 2 is ready. Better fish can enter the loop.", 10)
		GoalStep.SILVERFISH:
			if int(fish_caught_by_kind[FishKind.SILVERFISH]) >= 1:
				_complete_goal("Silverfish discovered. Storage plans are unlocked.", 12)
		GoalStep.STORAGE:
			if _building_count(BuildKind.STORAGE) >= 1:
				_complete_goal("Storage built. The fishery can hold more meat.", 12)
		GoalStep.EXPAND:
			if land_expanded_total >= 1:
				_complete_goal("New land claimed. The base has room to grow.", 15)
		GoalStep.STABLE_SALES:
			if meat_sold_total >= 14:
				_complete_goal("Steady sales proven. The early fishery is established.", 20)
		GoalStep.SMOKER:
			if _building_count(BuildKind.SMOKER) >= 1:
				_complete_goal("Smoker built. The fishery can make premium goods.", 16)
		GoalStep.SMOKED_SALE:
			if smoked_meat_sold_total >= 2:
				_complete_goal("Smoked meat sells well. Cooks and merchants are noticing.", 20)
		GoalStep.COOK_SALE:
			if int(buyers_served_by_kind[BuyerKind.COOK]) >= 1:
				_complete_goal("A cook bought smoked meat. Buyer preferences now matter.", 18)
		GoalStep.MERCHANT_ORDER:
			if merchant_orders_completed_total >= 1:
				_complete_goal("Merchant bulk order complete. The dock trade is alive.", 22)
		GoalStep.DOCK_ORDER:
			if dock_orders_completed_total >= 1:
				_complete_goal("Dock order fulfilled. The trade board is working.", 24)


func _complete_goal(message: String, reward: int) -> void:
	money += reward
	goal_step += 1
	status_text = message + " Goal reward: $" + str(reward) + "."
	_add_popup("Goal +$" + str(reward), grid_rect.position + Vector2(grid_rect.size.x * 0.5, 18.0), Color("#b7ef8a"))


func _goal_text() -> String:
	match goal_step:
		GoalStep.CATCH:
			return "Goal: Catch 2 fish from water. " + _progress_text(fish_caught_total, 2)
		GoalStep.STORE:
			return "Goal: Store 2 live fish in the pool. " + _progress_text(fish_stored_total, 2)
		GoalStep.PROCESS:
			return "Goal: Let the cutter produce 2 meat. " + _progress_text(meat_processed_total, 2)
		GoalStep.SELL:
			return "Goal: Sell 2 meat to buyers. " + _progress_text(meat_sold_total, 2)
		GoalStep.UPGRADE:
			return "Goal: Buy any upgrade. " + _progress_text(upgrades_bought_total, 1)
		GoalStep.BUILD:
			return "Goal: Build one extra pool, cutter, or market. " + _progress_text(buildings_built_total, 1)
		GoalStep.NET_TWO:
			return "Goal: Upgrade Net to level 2. " + _progress_text(net_level, 2)
		GoalStep.SILVERFISH:
			return "Goal: Catch 1 silverfish. " + _progress_text(int(fish_caught_by_kind[FishKind.SILVERFISH]), 1)
		GoalStep.STORAGE:
			return "Goal: Build 1 Storage. " + _progress_text(_building_count(BuildKind.STORAGE), 1)
		GoalStep.EXPAND:
			return "Goal: Expand 1 edge tile into land. " + _progress_text(land_expanded_total, 1)
		GoalStep.STABLE_SALES:
			return "Goal: Sell 14 total meat to prove steady demand. " + _progress_text(meat_sold_total, 14)
		GoalStep.SMOKER:
			return "Goal: Build 1 Smoker for premium goods. " + _progress_text(_building_count(BuildKind.SMOKER), 1)
		GoalStep.SMOKED_SALE:
			return "Goal: Sell 2 smoked meat. " + _progress_text(smoked_meat_sold_total, 2)
		GoalStep.COOK_SALE:
			return "Goal: Serve 1 cook. Cooks want smoked meat. " + _progress_text(int(buyers_served_by_kind[BuyerKind.COOK]), 1)
		GoalStep.MERCHANT_ORDER:
			return "Goal: Complete 1 merchant bulk order. " + _progress_text(merchant_orders_completed_total, 1)
		GoalStep.DOCK_ORDER:
			return "Goal: Complete 1 dock order from the road board. " + _progress_text(dock_orders_completed_total, 1)
		_:
			return "Living trade branch complete. Next milestone: plaza paths, richer stalls, or cold."


func _unlock_text() -> String:
	if not _is_storage_unlocked():
		if net_level < 2:
			return "Unlocks: Net 2 reveals silverfish. Catch silverfish to unlock Storage."
		return "Unlocks: catch silverfish to unlock Storage."
	if not _is_land_expansion_unlocked():
		return "Unlocks: Storage available. Build Storage to unlock land expansion."
	if not _is_smoker_unlocked():
		return "Unlocks: Expand land and prove steady sales to unlock Smoker."
	if _building_count(BuildKind.SMOKER) <= 0:
		return "Unlocks: Smoker available. Turns 2 meat into smoked meat worth $" + str(SMOKED_MEAT_PRICE) + "."
	if goal_step < GoalStep.COOK_SALE:
		return "Unlocks: buyer wants appear above people. M=meat, S=smoked, x3=bulk."
	if goal_step < GoalStep.MERCHANT_ORDER:
		return "Unlocks: cooks pay $" + str(COOK_SMOKED_MEAT_PRICE) + " for smoked meat."
	if goal_step < GoalStep.DOCK_ORDER:
		return "Unlocks: merchants buy bulk orders and pay $" + str(MERCHANT_BULK_BONUS) + " completion bonuses."
	if dock_order_active:
		return "Dock order: " + _dock_order_progress_text() + ". Markets fill it after serving buyers."
	return "Dock order board: waiting " + str(max(0, int(ceil(dock_order_cooldown)))) + "s for the next posted order."


func _progress_text(current: int, target: int) -> String:
	return "(" + str(min(current, target)) + "/" + str(target) + ")"


func _tick_feedback_popups(delta: float) -> void:
	for i in range(feedback_popups.size() - 1, -1, -1):
		var popup: Dictionary = feedback_popups[i]
		popup["age"] = float(popup["age"]) + delta
		if popup["age"] >= popup["life"]:
			feedback_popups.remove_at(i)
		else:
			feedback_popups[i] = popup


func _add_popup_for_cell(cell: Vector2i, text: String, color: Color) -> void:
	_add_popup(text, _cell_rect(cell).get_center(), color)


func _add_popup(text: String, position: Vector2, color: Color) -> void:
	feedback_popups.append({
		"text": text,
		"pos": position,
		"age": 0.0,
		"life": 1.05,
		"color": color
	})


func _building_center(building: int) -> Vector2:
	for y in GRID_H:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if tile["building"] == building:
				return _cell_rect(Vector2i(x, y)).get_center()
	return grid_rect.get_center()


func _update_hud() -> void:
	if hud_label == null:
		return

	var capacity := _pool_capacity()
	var smoked_text := ""
	var boat_text := "Boat:locked"
	if _is_boat_unlocked():
		boat_text = "Boat:%d/%d" % [_boat_net_count(), _boat_net_capacity()]
	if _is_smoker_unlocked() or smoked_meat > 0:
		smoked_text = "   Smoke:%d/%d" % [smoked_meat, _smoked_meat_capacity()]
	hud_label.text = "Coldwater Catch\n$%d   You:F%d/%d M%d/%d   %s   Pool:%d/%d %s%s\nBuyers:%d/%d   Queue:%d   Lost:%d   Patience:%ds   Crew:%d/%d\nNet %d   Boat %d   Pool %d   Cutter %d   Claimed:%d   Map:%dx%d" % [
		money,
		_player_fish_total(),
		PLAYER_FISH_CAPACITY,
		player_meat,
		PLAYER_MEAT_CAPACITY,
		boat_text,
		_live_fish_total(),
		capacity,
		_stock_summary(live_fish_stock),
		smoked_text,
		customer_agents.size(),
		MAX_CUSTOMERS,
		customers_waiting,
		customers_lost,
		int(ceil(customer_patience_timer)) if customers_waiting > 0 else int(CUSTOMER_PATIENCE_SECONDS),
		workers.size(),
		MAX_WORKERS,
		net_level,
		boat_agent.level,
		pool_level,
		cutter_level,
		land_expanded_total,
		GRID_W,
		GRID_H
	]
	goal_label.text = _goal_text()
	unlock_label.text = _unlock_text()
	status_label.text = status_text
	inspector_label.text = _selected_tile_text()
	_update_tool_buttons()


func _update_tool_buttons() -> void:
	for tool in tool_buttons.keys():
		var button: Button = tool_buttons[tool]
		var cost := _tool_cost(str(tool))
		button.text = _tool_label(str(tool))
		button.button_pressed = tool == selected_tool
		button.modulate = Color("#6f7782") if not _is_tool_unlocked(str(tool)) else _affordability_color(cost)

	if command_buttons.has("net"):
		var net_button: Button = command_buttons["net"]
		net_button.text = "Net $" + str(_net_upgrade_cost())
		net_button.modulate = _affordability_color(_net_upgrade_cost())
	if command_buttons.has("boat"):
		var boat_button: Button = command_buttons["boat"]
		boat_button.text = "Boat L" if not _is_boat_unlocked() else "Boat $" + str(_boat_upgrade_cost())
		boat_button.modulate = Color("#6f7782") if not _is_boat_unlocked() else _affordability_color(_boat_upgrade_cost())
	if command_buttons.has("pool"):
		var pool_button: Button = command_buttons["pool"]
		pool_button.text = "Pool $" + str(_pool_upgrade_cost())
		pool_button.modulate = _affordability_color(_pool_upgrade_cost())
	if command_buttons.has("cutter"):
		var cutter_button: Button = command_buttons["cutter"]
		cutter_button.text = "Cutter $" + str(_cutter_upgrade_cost())
		cutter_button.modulate = _affordability_color(_cutter_upgrade_cost())
	if command_buttons.has("hire"):
		var hire_button: Button = command_buttons["hire"]
		if not _is_worker_hiring_unlocked():
			hire_button.text = "Hire L"
			hire_button.modulate = Color("#6f7782")
		else:
			hire_button.text = "Hire $" + str(COST_WORKER) if workers.size() < MAX_WORKERS else "Crew full"
			hire_button.modulate = _affordability_color(COST_WORKER) if workers.size() < MAX_WORKERS else Color("#6f7782")
	if command_buttons.has("train"):
		var train_button: Button = command_buttons["train"]
		if selected_worker_index < 0 or selected_worker_index >= workers.size():
			train_button.text = "Train job"
			train_button.modulate = Color("#6f7782")
		else:
			var worker: Dictionary = workers[selected_worker_index]
			var skill_key := _worker_skill_key_for_job(_worker_job_key(worker))
			if skill_key.is_empty():
				train_button.text = "Train job"
				train_button.modulate = Color("#6f7782")
			elif _worker_skill(worker, skill_key) >= WORKER_MAX_SKILL:
				train_button.text = "Mastered"
				train_button.modulate = Color("#6f7782")
			else:
				var train_cost := _worker_training_cost(worker, skill_key)
				train_button.text = "Train $" + str(train_cost)
				train_button.modulate = _affordability_color(train_cost)


func _calculate_grid_rect() -> void:
	var top_margin := 222.0
	var bottom_margin := 272.0
	var inner_width: float = max(1.0, size.x - 24.0)
	var inner_height: float = max(1.0, size.y - top_margin - bottom_margin)
	tile_px = floor(min(inner_width / 11.5, inner_height / 9.5))
	tile_px = clamp(tile_px, 38.0, 64.0)

	var grid_size := Vector2(
		floor(inner_width / tile_px) * tile_px,
		floor(inner_height / tile_px) * tile_px
	)
	var origin := Vector2(
		floor((size.x - grid_size.x) * 0.5),
		top_margin + floor(max(0.0, inner_height - grid_size.y) * 0.5)
	)
	grid_rect = Rect2(origin, grid_size)
	_clamp_map_camera()


func _clamp_map_camera() -> void:
	if tile_px <= 0.0 or grid_rect.size == Vector2.ZERO:
		return
	var visible_cells := grid_rect.size / tile_px
	map_camera.x = clamp(floor(map_camera.x), 0.0, max(0.0, float(GRID_W) - visible_cells.x))
	map_camera.y = clamp(floor(map_camera.y), 0.0, max(0.0, float(GRID_H) - visible_cells.y))


func _draw_grid() -> void:
	var font := get_theme_default_font()
	for y in GRID_H:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			var cell := Vector2i(x, y)
			var rect := Rect2(
				grid_rect.position + Vector2(float(x) * tile_px, float(y) * tile_px) - map_camera * tile_px,
				Vector2(tile_px, tile_px)
			).grow(-2.0)
			if not grid_rect.intersects(rect):
				continue

			var fill := Color("#5e6747")
			var texture: Texture2D = LAND_TILE_TEXTURE
			var texture_tint := Color.WHITE
			if tile["kind"] == TileKind.WATER:
				fill = _water_zone_color(int(tile["water_zone"]))
				texture = WATER_TILE_TEXTURE
				texture_tint = _water_zone_texture_tint(int(tile["water_zone"]))
			elif tile["kind"] == TileKind.DOCK:
				fill = Color("#66503d")
				texture = DOCK_TILE_TEXTURE
			elif tile["kind"] == TileKind.PLAZA:
				fill = Color("#6a6258")
				texture = PLAZA_TILE_TEXTURE
			elif tile["kind"] == TileKind.ROAD:
				fill = Color("#504a45")
				texture = ROAD_TILE_TEXTURE
			elif tile["kind"] == TileKind.EXPANSION:
				fill = Color("#4d5660")
				texture = FRONTIER_TILE_TEXTURE
			draw_rect(rect, fill)
			if tile["kind"] == TileKind.ROAD:
				_draw_rotated_tile_texture(rect, texture, PI * 0.5, texture_tint)
			else:
				draw_texture_rect(texture, rect, false, texture_tint)
			draw_rect(rect, Color("#0e151b"), false, 2.0)

			if tile["kind"] == TileKind.WATER:
				_draw_water_tile(rect, int(tile["fish"]), int(tile["fish_kind"]), int(tile["water_zone"]))
			elif tile["kind"] == TileKind.DOCK:
				_draw_dock_tile(rect, int(tile["building"]))
			elif tile["kind"] == TileKind.PLAZA:
				_draw_plaza_tile(rect, int(tile["building"]))
			elif tile["kind"] == TileKind.ROAD:
				_draw_road_tile(rect)
			elif tile["kind"] == TileKind.EXPANSION:
				_draw_expansion_tile(rect)
			else:
				_draw_land_tile(rect, int(tile["building"]))
			if tile["kind"] == TileKind.DOCK and int(tile["building"]) == BuildKind.NONE and _is_dock_lamp_cell(cell):
				_draw_dock_lamp(rect)

			if tile["building"] != BuildKind.NONE:
				var label := _building_label(int(tile["building"]))
				draw_string(font, rect.position + Vector2(8.0, rect.size.y - 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, 14, Color("#f5efe1"))

			if selected_cell == Vector2i(x, y):
				draw_rect(rect.grow(2.0), Color("#f2d16b"), false, 3.0)


func _water_zone_texture_tint(water_zone: int) -> Color:
	match water_zone:
		WaterZone.SHALLOW:
			return Color("#c8ffff")
		WaterZone.COLD:
			return Color("#9fc7e2")
		WaterZone.DEEP:
			return Color("#55779c")
		WaterZone.MONSTER:
			return Color("#43576b")
		_:
			return Color("#8fd6dd")


func _draw_rotated_tile_texture(rect: Rect2, texture: Texture2D, angle: float, tint: Color) -> void:
	draw_set_transform(rect.get_center(), angle, Vector2.ONE)
	draw_texture_rect(texture, Rect2(-rect.size * 0.5, rect.size), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_water_tile(rect: Rect2, fish_count: int, fish_kind: int, water_zone: int) -> void:
	var ripple_color := Color("#9fe4dd")
	var secondary_color := Color("#72c5c3")
	if water_zone == WaterZone.DEEP or water_zone == WaterZone.MONSTER:
		ripple_color = Color("#5aa9c8")
		secondary_color = Color("#326f8f")
	elif water_zone == WaterZone.COLD:
		ripple_color = Color("#d6f5ff")
		secondary_color = Color("#a7d7e8")

	draw_arc(rect.get_center(), tile_px * 0.26, 0.2, PI - 0.2, 16, ripple_color, 2.0)
	draw_arc(rect.get_center() + Vector2(0, 6), tile_px * 0.22, 0.2, PI - 0.2, 16, secondary_color, 2.0)
	_draw_water_zone_detail(rect, water_zone)

	# Tile stock still powers worker autofishing; moving fish are the manual catch targets.
	for i in fish_count:
		var offset := Vector2(-tile_px * 0.18 + float(i) * tile_px * 0.18, -tile_px * 0.04 + float(i % 2) * 8.0)
		var marker_color: Color = _fish_color(fish_kind).lerp(Color("#f5efe1"), 0.35)
		marker_color.a = 0.55
		draw_circle(rect.get_center() + offset, tile_px * 0.035, marker_color)


func _draw_water_zone_detail(rect: Rect2, water_zone: int) -> void:
	match water_zone:
		WaterZone.SHALLOW:
			draw_line(rect.position + Vector2(5, rect.size.y - 8), rect.end - Vector2(5, 6), Color("#a8e6dc"), 1.2)
			draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.28), tile_px * 0.035, Color("#bdebd7"))
		WaterZone.COLD:
			var floe := PackedVector2Array([
				rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.28),
				rect.position + Vector2(rect.size.x * 0.38, rect.size.y * 0.20),
				rect.position + Vector2(rect.size.x * 0.52, rect.size.y * 0.34),
				rect.position + Vector2(rect.size.x * 0.34, rect.size.y * 0.48),
				rect.position + Vector2(rect.size.x * 0.16, rect.size.y * 0.42)
			])
			var floe_outline := PackedVector2Array([floe[0], floe[1], floe[2], floe[3], floe[4], floe[0]])
			draw_colored_polygon(floe, Color("#cde9f2"))
			draw_polyline(floe_outline, Color("#f5fbff"), 1.2)
		WaterZone.DEEP:
			draw_circle(rect.get_center(), tile_px * 0.18, Color("#0e2e4b"))
			draw_arc(rect.get_center(), tile_px * 0.31, PI * 0.08, PI * 0.85, 16, Color("#2d7598"), 1.4)
		WaterZone.MONSTER:
			draw_circle(rect.get_center(), tile_px * 0.22, Color("#10253d"))
			draw_arc(rect.get_center(), tile_px * 0.31, PI * 0.1, PI * 1.7, 20, Color("#5b8aa0"), 1.5)
			draw_circle(rect.get_center() + Vector2(tile_px * 0.12, -tile_px * 0.04), tile_px * 0.025, Color("#ff8f7a"))


func _draw_road_tile(rect: Rect2) -> void:
	draw_line(rect.position + Vector2(5, rect.size.y * 0.5), rect.end - Vector2(5, rect.size.y * 0.5), Color("#f5efe1", 0.22), 1.0)


func _draw_dock_tile(rect: Rect2, building: int) -> void:
	if building != BuildKind.NONE:
		_draw_land_tile(rect, building)


func _draw_plaza_tile(rect: Rect2, building: int) -> void:
	if building != BuildKind.NONE:
		_draw_land_tile(rect, building)


func _draw_expansion_tile(rect: Rect2) -> void:
	draw_line(rect.position + Vector2(8, 8), rect.end - Vector2(8, 8), Color("#d5e7ee", 0.72), 2.0)
	draw_line(rect.position + Vector2(rect.size.x - 8, 8), rect.position + Vector2(8, rect.size.y - 8), Color("#d5e7ee", 0.72), 2.0)
	draw_circle(rect.get_center(), 3.0, Color("#f2d16b"))


func _is_dock_lamp_cell(cell: Vector2i) -> bool:
	return cell.y == WATER_ROWS and (cell.x == 3 or cell.x == 9)


func _draw_dock_lamp(rect: Rect2) -> void:
	var lamp_size := Vector2(tile_px * 0.54, tile_px * 0.78)
	var lamp_rect := Rect2(rect.get_center() - Vector2(lamp_size.x * 0.5, lamp_size.y * 0.72), lamp_size)
	draw_circle(rect.get_center() + Vector2(0, -tile_px * 0.04), tile_px * 0.32, Color("#f2b860", 0.16))
	draw_texture_rect(DOCK_LAMP_TEXTURE, lamp_rect, false)


func _draw_people() -> void:
	for customer in customer_agents:
		var buyer_kind := int(customer["kind"])
		var color := _buyer_color(buyer_kind)
		var state := str(customer["state"])
		if state == "waiting":
			var patience_ratio: float = clamp(float(customer["patience"]) / CUSTOMER_PATIENCE_SECONDS, 0.0, 1.0)
			color = _buyer_color(buyer_kind) if patience_ratio > 0.5 else Color("#ffb36b")
			if patience_ratio < 0.25:
				color = Color("#ff8f7a")
		elif state == "leaving_happy":
			color = Color("#b7ef8a")
		elif state == "leaving_angry":
			color = Color("#ff8f7a")
		var customer_pos: Vector2 = customer["pos"]
		var screen_pos := _agent_screen_pos(customer_pos)
		if not grid_rect.grow(tile_px * 0.6).has_point(screen_pos):
			continue
		_draw_person(screen_pos, color, false, _buyer_short_label(buyer_kind))
		if state == "arriving" or state == "waiting":
			_draw_want_bubble(screen_pos, _buyer_want_label(customer), _buyer_color(buyer_kind))

	for i in workers.size():
		var worker: Dictionary = workers[i]
		var worker_pos: Vector2 = worker["pos"]
		var worker_screen := _agent_screen_pos(worker_pos)
		if grid_rect.grow(tile_px * 0.6).has_point(worker_screen):
			if _worker_is_visibly_working(worker):
				var work_phase := float(Time.get_ticks_msec()) * 0.008 + float(i)
				worker_screen += Vector2(sin(work_phase) * tile_px * 0.025, cos(work_phase * 1.4) * tile_px * 0.018)
				_draw_worker_activity(worker_screen, worker)
			_draw_person(worker_screen, Color("#f2d16b"), i == selected_worker_index, "W")
			_draw_worker_carry(worker_screen, worker)
			_draw_worker_job_badge(worker_screen, worker)

	var player_screen := _agent_screen_pos(player_agent.position)
	if grid_rect.grow(tile_px * 0.6).has_point(player_screen):
		_draw_person(player_screen, Color("#e87d52"), true, "YOU")
		_draw_player_carry(player_screen)


func _draw_active_fishing() -> void:
	for fish in active_fish_agents:
		var fish_agent = fish
		var fish_screen := _world_to_screen(fish_agent.position)
		if grid_rect.grow(tile_px * 0.3).has_point(fish_screen):
			_draw_fish(fish_screen, tile_px * 0.13, fish_agent.fish_kind, fish_agent.velocity)

	if not _is_boat_unlocked():
		return
	var boat_screen := _world_to_screen(boat_agent.position)
	if not grid_rect.grow(tile_px).has_point(boat_screen):
		return
	var net_center := _boat_net_center()
	var net_screen := _world_to_screen(net_center)
	var net_radius: float = _boat_net_radius() * tile_px
	var net_fill: float = float(_boat_net_count()) / float(max(1, _boat_net_capacity()))
	var rope_color := Color("#d9c6a1").lerp(Color("#ffb36b"), net_fill * 0.45)
	draw_line(boat_screen, net_screen, rope_color, 2.0)
	draw_circle(net_screen, net_radius * 0.88, Color("#173a53", 0.18 + net_fill * 0.13))
	draw_arc(net_screen, net_radius, 0.0, TAU, 32, rope_color, 2.0)
	draw_arc(net_screen, net_radius * 0.62, 0.0, TAU, 24, Color("#8fb8bd"), 1.0)
	var buoy_count: int = max(6, 6 + net_level * 2)
	for buoy_index in buoy_count:
		var buoy_angle := TAU * float(buoy_index) / float(buoy_count)
		var buoy_position := net_screen + Vector2(cos(buoy_angle), sin(buoy_angle)) * net_radius
		var buoy_color := Color("#e87d52") if buoy_index % 2 == 0 else Color("#f5efe1")
		draw_circle(buoy_position, max(2.0, tile_px * 0.038), buoy_color)

	var caught_index := 0
	for fish_kind: int in [FishKind.MINNOW, FishKind.CARP, FishKind.SILVERFISH]:
		for i in int(boat_agent.fish_stock[fish_kind]):
			var angle := float(caught_index) * 1.7
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * min(net_radius * 0.55, 5.0 + float(caught_index % 4) * 3.0)
			_draw_fish(net_screen + offset, tile_px * 0.045, fish_kind, offset)
			caught_index += 1

	_draw_boat(boat_screen)
	_draw_monster_warning_meter(boat_screen)
	var font := get_theme_default_font()
	draw_string(font, net_screen + Vector2(-36, -net_radius - 5), "NET " + str(_boat_net_count()) + "/" + str(_boat_net_capacity()), HORIZONTAL_ALIGNMENT_CENTER, 72.0, 12, Color("#f5efe1"))


func _draw_boat(center: Vector2) -> void:
	var direction := _boat_direction()
	var right := direction.orthogonal()
	var stern := center - direction * tile_px * 0.42
	var wake_color := Color("#b8edf3", 0.62)
	draw_line(stern - right * tile_px * 0.08, stern - direction * tile_px * 0.48 - right * tile_px * 0.30, wake_color, 1.6)
	draw_line(stern + right * tile_px * 0.08, stern - direction * tile_px * 0.48 + right * tile_px * 0.30, wake_color, 1.6)
	draw_arc(stern - direction * tile_px * 0.28, tile_px * 0.25, PI * 0.18, PI * 0.82, 12, Color("#7ec3d4", 0.52), 1.2)

	var boat_size := Vector2(tile_px * 1.34, tile_px * 0.90)
	draw_set_transform(center, direction.angle(), Vector2.ONE)
	draw_texture_rect(BOAT_TEXTURE, Rect2(-boat_size * 0.5, boat_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if boat_agent.level >= 2:
		draw_circle(center - direction * tile_px * 0.16 + right * tile_px * 0.20, tile_px * 0.035, Color("#9fe4dd"))
	if boat_agent.level >= 3:
		draw_circle(center - direction * tile_px * 0.20 - right * tile_px * 0.18, tile_px * 0.045, Color("#f2d16b"))


func _draw_monster_warning_meter(boat_screen: Vector2) -> void:
	if monster_warning <= 0.01:
		return

	var ratio: float = clamp(monster_warning / MONSTER_WARNING_SECONDS, 0.0, 1.0)
	var meter_size := Vector2(tile_px * 0.64, 5.0)
	var meter := Rect2(boat_screen + Vector2(-meter_size.x * 0.5, -tile_px * 0.56), meter_size)
	draw_rect(meter, Color("#2c1721"))
	draw_rect(Rect2(meter.position, Vector2(meter.size.x * ratio, meter.size.y)), Color("#ff8f7a"))
	draw_rect(meter, Color("#f5efe1"), false, 1.0)
	if ratio >= 0.75:
		draw_string(get_theme_default_font(), meter.position + Vector2(0, -3), "WARN", HORIZONTAL_ALIGNMENT_CENTER, meter.size.x, 10, Color("#ffb36b"))


func _draw_dock_order_board() -> void:
	if not _is_dock_order_unlocked():
		return

	var cell_rect := _cell_rect(_order_board_cell())
	if not grid_rect.intersects(cell_rect):
		return
	var font := get_theme_default_font()
	var board_size := Vector2(tile_px * 1.16, tile_px * 1.02)
	var board_rect := Rect2(cell_rect.get_center() - Vector2(board_size.x * 0.5, board_size.y * 0.56), board_size)
	draw_texture_rect(DOCK_ORDER_BOARD_TEXTURE, board_rect, false)
	var label := "wait"
	if dock_order_active:
		var parts: Array = []
		if dock_order_need_meat > 0:
			parts.append("M" + str(dock_order_delivered_meat) + "/" + str(dock_order_need_meat))
		if dock_order_need_smoked > 0:
			parts.append("S" + str(dock_order_delivered_smoked) + "/" + str(dock_order_need_smoked))
		label = " ".join(parts)
	var parchment_x := board_rect.position.x + board_rect.size.x * 0.27
	var parchment_width := board_rect.size.x * 0.53
	draw_string(font, Vector2(parchment_x, board_rect.position.y + board_rect.size.y * 0.43), "ORD", HORIZONTAL_ALIGNMENT_CENTER, parchment_width, 8, Color("#473722"))
	draw_string(font, Vector2(parchment_x, board_rect.position.y + board_rect.size.y * 0.58), label, HORIZONTAL_ALIGNMENT_CENTER, parchment_width, 8, Color("#473722"))


func _agent_screen_pos(pos: Vector2) -> Vector2:
	return grid_rect.position + (Vector2(pos.x + 0.5, pos.y + 0.5) - map_camera) * tile_px


func _world_to_screen(pos: Vector2) -> Vector2:
	return grid_rect.position + (pos - map_camera) * tile_px


func _draw_person(center: Vector2, body_color: Color, selected: bool, label: String) -> void:
	var sprite_size := Vector2(tile_px * 0.78, tile_px * 0.88)
	var sprite_rect := Rect2(center - Vector2(sprite_size.x * 0.5, sprite_size.y * 0.68), sprite_size)
	if selected:
		draw_circle(center, tile_px * 0.22, Color("#f2d16b"))
		draw_circle(center, tile_px * 0.18, Color("#17212b"))
	draw_circle(center + Vector2(0, tile_px * 0.19), tile_px * 0.16, body_color.darkened(0.35))
	var texture: Texture2D = FISHERMAN_TEXTURE if label == "YOU" or label == "W" else VILLAGER_TEXTURE
	draw_texture_rect(texture, sprite_rect, false)


func _draw_want_bubble(center: Vector2, label: String, color: Color) -> void:
	var font := get_theme_default_font()
	var bubble_width: float = max(tile_px * 0.32, float(label.length()) * 8.0 + 8.0)
	var bubble := Rect2(center + Vector2(-bubble_width * 0.5, -tile_px * 0.54), Vector2(bubble_width, 15.0))
	draw_rect(bubble, Color("#f5efe1"))
	draw_rect(bubble, color, false, 1.5)
	draw_string(font, bubble.position + Vector2(0, 11.0), label, HORIZONTAL_ALIGNMENT_CENTER, bubble.size.x, 11, Color("#17212b"))


func _draw_player_carry(center: Vector2) -> void:
	var parts: Array = []
	if _player_fish_total() > 0:
		parts.append("F" + str(_player_fish_total()))
	if player_meat > 0:
		parts.append("M" + str(player_meat))
	if parts.is_empty():
		return
	_draw_want_bubble(center, " ".join(parts), Color("#e87d52"))


func _draw_worker_carry(center: Vector2, worker: Dictionary) -> void:
	var carried := _worker_carry_total(worker)
	if carried <= 0:
		return
	_draw_want_bubble(center, "F" + str(carried), Color("#f2d16b"))


func _draw_worker_job_badge(center: Vector2, worker: Dictionary) -> void:
	var job_key := _worker_job_key(worker)
	var skill_key := _worker_skill_key_for_job(job_key)
	var label := _worker_job_short_label(worker)
	if not skill_key.is_empty():
		label += " " + _worker_skill_short_label(skill_key) + str(_worker_skill(worker, skill_key))
	var width: float = maxf(tile_px * 0.44, float(label.length()) * 5.8 + 6.0)
	var badge := Rect2(center + Vector2(-width * 0.5, tile_px * 0.26), Vector2(width, 12.0))
	var border_color := Color("#f2d16b") if job_key != "idle" else Color("#8d98a0")
	draw_rect(badge, Color("#17212b", 0.88))
	draw_rect(badge, border_color, false, 1.0)
	draw_string(get_theme_default_font(), badge.position + Vector2(0, 9.5), label, HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 9, Color("#f5efe1"))


func _draw_worker_activity(center: Vector2, worker: Dictionary) -> void:
	var job_key := _worker_job_key(worker)
	var activity_color := Color("#f2d16b")
	match job_key:
		"fish":
			draw_arc(center + Vector2(0, -tile_px * 0.18), tile_px * 0.21, PI * 1.08, PI * 1.90, 10, Color("#9fe4dd"), 1.2)
		"pool", "storage":
			draw_circle(center + Vector2(-tile_px * 0.15, -tile_px * 0.1), tile_px * 0.035, Color("#9fe4dd"))
			draw_circle(center + Vector2(tile_px * 0.14, -tile_px * 0.2), tile_px * 0.025, Color("#d9f2f5"))
		"cutter", "smoker":
			activity_color = Color("#ffb36b")
			draw_line(center + Vector2(-tile_px * 0.16, -tile_px * 0.22), center + Vector2(tile_px * 0.16, -tile_px * 0.08), activity_color, 1.6)
			draw_line(center + Vector2(-tile_px * 0.08, -tile_px * 0.26), center + Vector2(tile_px * 0.08, -tile_px * 0.04), activity_color, 1.2)
		"market":
			activity_color = Color("#b7ef8a")
			draw_circle(center + Vector2(0, -tile_px * 0.2), tile_px * 0.06, activity_color, false, 1.4)
			draw_line(center + Vector2(-tile_px * 0.08, -tile_px * 0.2), center + Vector2(tile_px * 0.08, -tile_px * 0.2), activity_color, 1.0)


func _draw_land_tile(rect: Rect2, building: int) -> void:
	match building:
		BuildKind.NONE:
			pass
		BuildKind.POOL:
			_draw_building_art(rect, LIVE_POOL_TEXTURE)
		BuildKind.CUTTER:
			_draw_building_art(rect, CUTTER_TEXTURE)
			if _building_count(BuildKind.CUTTER) > 0:
				var bar_rect := Rect2(rect.position + Vector2(tile_px * 0.12, rect.size.y - tile_px * 0.16), Vector2(tile_px * 0.76, 4.0))
				var bar_width: float = bar_rect.size.x * clamp(cutter_progress / _cutter_required_time(), 0.0, 1.0)
				draw_rect(bar_rect, Color("#17212b"))
				draw_rect(Rect2(bar_rect.position, Vector2(bar_width, bar_rect.size.y)), Color("#f2d16b"))
		BuildKind.MARKET:
			_draw_building_art(rect, MARKET_TEXTURE)
		BuildKind.STORAGE:
			var crate := rect.grow(-tile_px * 0.18)
			draw_rect(crate, Color("#8a6f43"))
			draw_rect(crate, Color("#f0d597"), false, 2.0)
			draw_line(crate.position + Vector2(0, crate.size.y * 0.35), crate.position + Vector2(crate.size.x, crate.size.y * 0.35), Color("#473722"), 2.0)
			draw_line(crate.position + Vector2(crate.size.x * 0.5, 0), crate.position + Vector2(crate.size.x * 0.5, crate.size.y), Color("#473722"), 2.0)
		BuildKind.SMOKER:
			var smoker := rect.grow(-tile_px * 0.16)
			draw_rect(smoker, Color("#4b433b"))
			draw_rect(smoker, Color("#e8a35c"), false, 2.0)
			draw_rect(Rect2(smoker.position + Vector2(smoker.size.x * 0.58, 4), Vector2(smoker.size.x * 0.2, smoker.size.y * 0.34)), Color("#2c2722"))
			draw_circle(smoker.position + Vector2(smoker.size.x * 0.68, -1), 3.0, Color("#c8d0d5"))
			draw_circle(smoker.position + Vector2(smoker.size.x * 0.78, -7), 2.0, Color("#dbe2e6"))
			var smoke_bar_width: float = smoker.size.x * clamp(smoker_progress / _smoker_required_time(), 0.0, 1.0)
			draw_rect(Rect2(smoker.position + Vector2(0, smoker.size.y - 5), Vector2(smoke_bar_width, 5)), Color("#e8a35c"))


func _draw_building_art(rect: Rect2, texture: Texture2D) -> void:
	var art_rect := rect.grow(-tile_px * 0.035)
	draw_texture_rect(texture, art_rect, false)


func _draw_fish(center: Vector2, scale: float, fish_kind: int, direction: Vector2 = Vector2.RIGHT) -> void:
	var texture: Texture2D = MINNOW_TEXTURE
	var sprite_size := Vector2(scale * 3.0, scale * 1.48)
	match fish_kind:
		FishKind.CARP:
			texture = CARP_TEXTURE
			sprite_size = Vector2(scale * 3.45, scale * 1.78)
		FishKind.SILVERFISH:
			texture = SILVERFISH_TEXTURE
			sprite_size = Vector2(scale * 3.50, scale * 1.50)
	if direction.length() <= 0.001:
		direction = Vector2.RIGHT
	draw_set_transform(center, direction.angle(), Vector2.ONE)
	draw_texture_rect(texture, Rect2(-sprite_size * 0.5, sprite_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_footer_hint() -> void:
	var font := get_theme_default_font()
	var hint := ""
	match selected_tool:
		TOOL_WALK:
			hint = "Walk: tap land, dock, plaza, or road. Pools, cutters, and markets work when you arrive."
		TOOL_CATCH:
			if _is_boat_unlocked():
				hint = "Fish: drag on water to steer the boat, tap dock to unload the net." + _water_zone_warning_label()
			else:
				hint = "Fish: stand at the dock and tap a visible fish in nearby water. Basket " + str(_player_fish_total()) + "/" + str(PLAYER_FISH_CAPACITY) + "."
		TOOL_PEOPLE:
			if selected_worker_index >= 0 and selected_worker_index < workers.size():
				var worker: Dictionary = workers[selected_worker_index]
				hint = "People: " + _worker_name(selected_worker_index) + ". " + _worker_assignment_instruction(worker) + " Tap a work target to reassign."
			else:
				hint = "People: tap a worker, then water, a pool, cutter, market, storage, or smoker."
		TOOL_EXPAND:
			hint = "Expand: tap a frontier tile touching territory you already own."
		TOOL_MAP:
			hint = "Map: drag to pan across the larger fishery. Center returns to the starter district."
		TOOL_MOVE:
			hint = "Move: tap a building, then an empty buildable tile."
		TOOL_REMOVE:
			hint = "Remove: tap a building to recover half its cost."
		_:
			hint = "Tap a buildable tile to place: " + selected_tool
	draw_string(font, grid_rect.position + Vector2(4, grid_rect.size.y + 24), hint, HORIZONTAL_ALIGNMENT_LEFT, grid_rect.size.x, 16, Color("#f5efe1"))


func _draw_feedback_popups() -> void:
	var font := get_theme_default_font()
	for popup in feedback_popups:
		var age := float(popup["age"])
		var life := float(popup["life"])
		var alpha: float = 1.0 - clamp(age / life, 0.0, 1.0)
		var color: Color = popup["color"]
		color.a = alpha
		var position: Vector2 = popup["pos"] + Vector2(0, -age * 28.0)
		draw_string(font, position, str(popup["text"]), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 17, color)


func _cell_rect(cell: Vector2i) -> Rect2:
	if grid_rect.size == Vector2.ZERO:
		_calculate_grid_rect()
	return Rect2(
		grid_rect.position + (Vector2(float(cell.x), float(cell.y)) - map_camera) * tile_px,
		Vector2(tile_px, tile_px)
	).grow(-2.0)


func _selected_tile_text() -> String:
	if selected_cell.x < 0:
		return "You: tap Walk to move the fisherman between fish, pool, cutter, and market."

	if _is_dock_order_unlocked() and selected_cell == _order_board_cell():
		if dock_order_active:
			return "Order board: " + _dock_order_progress_text() + ". Markets deliver spare sales capacity into this order."
		return "Order board: waiting for the next dock request."

	var worker_index := _worker_index_at_cell(selected_cell)
	if worker_index >= 0:
		var worker: Dictionary = workers[worker_index]
		var assigned: Vector2i = worker["assigned"]
		return "Person: " + _worker_name(worker_index) + ". " + _worker_state_text(worker, assigned)

	var buyer_index := _buyer_index_at_cell(selected_cell)
	if buyer_index >= 0:
		var buyer: Dictionary = customer_agents[buyer_index]
		return "Buyer: " + _buyer_name(int(buyer["kind"])) + " " + _buyer_want_text(buyer) + ". State: " + str(buyer["state"]) + "."

	var tile: Dictionary = tiles[selected_cell.y][selected_cell.x]
	if tile["kind"] == TileKind.WATER:
		var water_zone := int(tile["water_zone"])
		return "Tile: " + _water_zone_name(water_zone) + ". " + _water_zone_hint(water_zone) + " Drag with Catch to steer; unload at the dock."
	if tile["kind"] == TileKind.DOCK:
		return "Tile: dock. Tap with Catch to return and unload the boat. Dock tiles are buildable."
	if tile["kind"] == TileKind.PLAZA:
		return "Tile: plaza. Buildable trade surface; markets on or beside plazas sell +1 per tick."
	if tile["kind"] == TileKind.ROAD:
		return "Tile: road. Markets beside roads gain +1 sale capacity."
	if tile["kind"] == TileKind.EXPANSION:
		if _is_land_expansion_unlocked():
			if _is_claimable_frontier(selected_cell):
				return "Tile: claimable frontier. Use Expand to buy this land for $" + str(COST_EXPAND) + "."
			return "Tile: distant frontier. Claim a connected tile first, then grow outward to reach this land."
		return "Tile: expansion ground. Build Storage to unlock land expansion."

	match int(tile["building"]):
		BuildKind.POOL:
			return "Tile: pool. Holds " + str(_pool_capacity_at(selected_cell)) + "; staff " + str(_worker_count_assigned_to(selected_cell)) + "; total live capacity " + str(_pool_capacity()) + "."
		BuildKind.CUTTER:
			return "Tile: cutter. Rate x" + _format_ratio(_cutter_rate_at(selected_cell)) + "; staff " + str(_worker_count_assigned_to(selected_cell)) + "; faster beside pools."
		BuildKind.MARKET:
			return "Tile: market. Sales " + str(_market_capacity_at(selected_cell)) + "/tick; staff " + str(_worker_count_assigned_to(selected_cell)) + "; road and plaza access each help flow."
		BuildKind.STORAGE:
			return "Tile: storage. Adds " + str(_storage_capacity_at(selected_cell)) + " meat capacity and smoked goods room; better beside markets."
		BuildKind.SMOKER:
			return "Tile: smoker. Rate x" + _format_ratio(_smoker_rate_at(selected_cell)) + "; staff " + str(_worker_count_assigned_to(selected_cell)) + "; capacity +" + str(_smoker_capacity_at(selected_cell)) + "."
		_:
			var options := "pool, cutter, market"
			if _is_storage_unlocked():
				options += ", storage"
			if _is_smoker_unlocked():
				options += ", smoker"
			return "Tile: open " + _tile_surface_name(int(tile["kind"])) + ". Build " + options + " here."


func _worker_state_text(worker: Dictionary, assigned: Vector2i) -> String:
	var state := str(worker["job_state"])
	var job_key := _worker_job_key(worker)
	var skill_key := _worker_skill_key_for_job(job_key)
	var skill_text := ""
	if not skill_key.is_empty():
		skill_text = _worker_skill_label(skill_key) + " L" + str(_worker_skill(worker, skill_key)) + " " + _worker_skill_progress_text(worker, skill_key) + "."
	if state == "walk_to_water":
		return "Walking to the dock to fish at " + str(assigned) + ". " + skill_text
	if state == "fishing":
		return "Fishing from the dock at " + str(assigned) + ". " + skill_text
	if state == "carry_to_pool":
		return "Carrying " + str(_worker_carry_total(worker)) + " fish to the pool. " + skill_text
	if state == "waiting_for_pool":
		return "Holding fish until there is pool space. " + skill_text
	if state == "walk_to_assignment":
		return "Walking to their assigned station at " + str(assigned) + ". " + skill_text
	if state == "working":
		return "Working as " + _worker_job_label(job_key) + ". " + _worker_job_effect_text(worker) + " " + skill_text
	if assigned.x >= 0 and assigned.y >= 0:
		if job_key != "idle":
			return "Ready for " + _worker_job_label(job_key) + ". " + _worker_job_effect_text(worker) + " " + skill_text
	return "Standing by."


func _worker_skill_progress_text(worker: Dictionary, skill_key: String) -> String:
	if _worker_skill(worker, skill_key) >= WORKER_MAX_SKILL:
		return "mastered"
	return str(_worker_skill_xp(worker, skill_key)) + "/" + str(_worker_skill_xp_required(worker, skill_key)) + " XP"


func _worker_job_effect_text(worker: Dictionary) -> String:
	var job_key := _worker_job_key(worker)
	match job_key:
		"fish":
			return "One catch every " + _format_ratio(_worker_fish_seconds(worker)) + "s."
		"pool":
			return "Adds +" + str(WORKER_POOL_CAPACITY_BONUS + _worker_skill(worker, "handling") - 1) + " live capacity."
		"storage":
			return "Adds +" + str(WORKER_STORAGE_CAPACITY_BONUS + (_worker_skill(worker, "handling") - 1) * 2) + " meat capacity."
		"cutter":
			return "Adds +" + _format_ratio(WORKER_CUTTER_RATE_BONUS * (1.0 + float(_worker_skill(worker, "processing") - 1) * 0.5)) + " cutter rate."
		"smoker":
			return "Adds +" + _format_ratio(WORKER_SMOKER_RATE_BONUS * (1.0 + float(_worker_skill(worker, "processing") - 1) * 0.5)) + " smoker rate."
		"market":
			return "Adds +" + str(_worker_skill(worker, "trading")) + " sales per tick."
		_:
			return ""


func _worker_is_visibly_working(worker: Dictionary) -> bool:
	var state := str(worker["job_state"])
	return state == "fishing" or state == "working"


func _building_label(building: int) -> String:
	match building:
		BuildKind.POOL:
			return "POOL"
		BuildKind.CUTTER:
			return "CUT"
		BuildKind.MARKET:
			return "SELL"
		BuildKind.STORAGE:
			return "STO"
		BuildKind.SMOKER:
			return "SMK"
		_:
			return ""
