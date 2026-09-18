extends Control

enum TileKind { WATER, LAND, ROAD, EXPANSION }
enum BuildKind { NONE, POOL, CUTTER, MARKET, STORAGE, SMOKER }
enum GoalStep { CATCH, STORE, PROCESS, SELL, UPGRADE, BUILD, NET_TWO, SILVERFISH, STORAGE, EXPAND, STABLE_SALES, SMOKER, SMOKED_SALE, COOK_SALE, MERCHANT_ORDER, DOCK_ORDER, COMPLETE }
enum FishKind { MINNOW, CARP, SILVERFISH }
enum BuyerKind { VILLAGER, COOK, MERCHANT }

const GRID_W := 8
const GRID_H := 10
const WATER_ROWS := 3
const MAX_CUSTOMERS := 12

const TOOL_CATCH := "catch"
const TOOL_PEOPLE := "people"
const TOOL_POOL := "pool"
const TOOL_CUTTER := "cutter"
const TOOL_MARKET := "market"
const TOOL_STORAGE := "storage"
const TOOL_SMOKER := "smoker"
const TOOL_EXPAND := "expand"
const TOOL_MOVE := "move"
const TOOL_REMOVE := "remove"

const COST_POOL := 10
const COST_CUTTER := 15
const COST_MARKET := 20
const COST_STORAGE := 25
const COST_SMOKER := 45
const COST_EXPAND := 35
const COST_WORKER := 35
const MAX_WORKERS := 6

const CUSTOMER_PATIENCE_SECONDS := 10.0
const MARKET_SELL_SECONDS := 1.25
const CUSTOMER_WALK_SPEED := 2.35
const WORKER_WALK_SPEED := 2.85
const WORKER_FISH_SECONDS := 4.5
const WORKER_POOL_CAPACITY_BONUS := 2
const WORKER_CUTTER_RATE_BONUS := 0.35
const WORKER_SMOKER_RATE_BONUS := 0.35
const SMOKER_SECONDS := 6.0
const MEAT_PRICE := 6
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
var selected_tool := TOOL_CATCH
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
var status_text := "Tap water to catch fish. The starter fishery can already process and sell."
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
	_init_people()
	_build_ui()
	_update_hud()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_tick_fish_spawns(delta)
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_handle_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_try_handle_tap(event.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	_calculate_grid_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color("#17212b"))
	_draw_grid()
	_draw_people()
	_draw_dock_order_board()
	_draw_footer_hint()
	_draw_feedback_popups()


func _init_tiles() -> void:
	tiles.clear()
	for y in GRID_H:
		var row: Array = []
		for x in GRID_W:
			var kind := TileKind.LAND
			if y < WATER_ROWS:
				kind = TileKind.WATER
			elif y == GRID_H - 1:
				kind = TileKind.ROAD
			elif x == 0 or x == GRID_W - 1:
				kind = TileKind.EXPANSION
			var fish_kind := _random_fish_kind()
			var fish_count := randi_range(1, 2) if kind == TileKind.WATER and randf() < 0.45 else 0
			row.append({
				"kind": kind,
				"building": BuildKind.NONE,
				"fish": fish_count,
				"fish_kind": fish_kind,
				"spawn_timer": randf_range(2.0, 6.0)
			})
		tiles.append(row)

	_set_starter_building(Vector2i(1, 3), BuildKind.POOL)
	_set_starter_building(Vector2i(2, 3), BuildKind.CUTTER)
	_set_starter_building(Vector2i(6, 8), BuildKind.MARKET)


func _set_starter_building(cell: Vector2i, building: int) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	tile["building"] = building
	tiles[cell.y][cell.x] = tile


func _init_people() -> void:
	customer_agents.clear()
	workers.clear()
	selected_worker_index = -1
	_spawn_worker(Vector2i(3, 8), false)


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

	_add_tool_button(actions, TOOL_CATCH, "Catch", "Tap water to collect fish, or tap a pool to deposit carried fish.")
	_add_tool_button(actions, TOOL_PEOPLE, "People", "Select a worker, then tap water, a building, or land to assign them.")
	_add_tool_button(actions, TOOL_POOL, "Pool $10", "Build live fish capacity on land.")
	_add_tool_button(actions, TOOL_CUTTER, "Cutter $15", "Build processing on land.")
	_add_tool_button(actions, TOOL_MARKET, "Market $20", "Build selling on land.")
	_add_tool_button(actions, TOOL_STORAGE, "Storage", "Unlock by catching silverfish. Adds meat storage capacity.")
	_add_tool_button(actions, TOOL_SMOKER, "Smoker", "Unlock after steady sales. Turns meat into higher-value smoked meat.")
	_add_tool_button(actions, TOOL_EXPAND, "Expand", "Unlock after building Storage. Converts edge ground into buildable land.")
	_add_tool_button(actions, TOOL_MOVE, "Move", "Move one building to another land tile.")
	_add_tool_button(actions, TOOL_REMOVE, "Remove", "Remove a building and recover half its cost.")
	command_buttons["net"] = _add_command_button(actions, "Net +", "Upgrade net", _upgrade_net)
	command_buttons["pool"] = _add_command_button(actions, "Pool +", "Upgrade pools", _upgrade_pool)
	command_buttons["cutter"] = _add_command_button(actions, "Cutter +", "Upgrade cutters", _upgrade_cutter)
	command_buttons["hire"] = _add_command_button(actions, "Hire +", "Hire another worker", _hire_worker)
	_add_command_button(actions, "Clear", "Clear current tool", _select_catch)


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


func _select_catch() -> void:
	_cancel_move_if_needed()
	selected_worker_index = -1
	selected_tool = TOOL_CATCH
	status_text = "Catch selected."
	_update_tool_buttons()


func _try_handle_tap(position: Vector2) -> void:
	if not grid_rect.has_point(position):
		return

	var cell := Vector2i(
		int(floor((position.x - grid_rect.position.x) / tile_px)),
		int(floor((position.y - grid_rect.position.y) / tile_px))
	)

	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_W or cell.y >= GRID_H:
		return

	selected_cell = cell

	match selected_tool:
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


func _use_catch_tool(cell: Vector2i) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] == TileKind.WATER:
		if tile["fish"] <= 0:
			status_text = "No fish on this water tile yet."
			return

		var caught: int = min(tile["fish"], net_level)
		var fish_kind := int(tile["fish_kind"])
		tile["fish"] -= caught
		tiles[cell.y][cell.x] = tile
		_add_fish_to_stock(carried_fish_stock, fish_kind, caught)
		fish_caught_total += caught
		_add_fish_to_stock(fish_caught_by_kind, fish_kind, caught)
		status_text = "Caught " + str(caught) + " " + _fish_plural(fish_kind, caught) + ". Tap a pool to store them." + _maybe_unlock_storage(fish_kind)
		_add_popup_for_cell(cell, "+" + str(caught) + " " + _fish_name(fish_kind), _fish_color(fish_kind))
		return

	if tile["building"] == BuildKind.POOL:
		if _carried_fish_total() <= 0:
			status_text = "You are not carrying fish. Tap water first."
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

	status_text = "Catch works on water, or on pools when carrying fish."


func _use_people_tool(cell: Vector2i) -> void:
	var worker_index := _worker_index_at_cell(cell)
	if worker_index >= 0:
		selected_worker_index = worker_index
		status_text = _worker_name(worker_index) + " selected. Tap water, a building, or land to assign work."
		return

	if selected_worker_index < 0 or selected_worker_index >= workers.size():
		status_text = "Tap a worker first, then tap water, a building, or land to assign them."
		return
	if not _is_valid_worker_assignment(cell):
		status_text = "Workers cannot be assigned to locked expansion ground."
		return

	var worker: Dictionary = workers[selected_worker_index]
	worker["assigned"] = cell
	worker["target"] = Vector2(cell.x, cell.y)
	worker["work_timer"] = 0.5
	workers[selected_worker_index] = worker
	status_text = _worker_name(selected_worker_index) + " assigned. " + _worker_assignment_hint(cell)
	_add_popup_for_cell(cell, "Assigned", Color("#f2d16b"))


func _try_build(cell: Vector2i, building: int, cost: int, label: String) -> void:
	if not _is_building_unlocked(building):
		status_text = _building_locked_reason(building)
		return

	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] != TileKind.LAND:
		status_text = "Build " + label + " on land tiles."
		return
	if tile["building"] != BuildKind.NONE:
		status_text = "This land tile already has a building."
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
		status_text = "Tap an edge expansion tile to buy more land."
		return
	if money < COST_EXPAND:
		status_text = "Need $" + str(COST_EXPAND) + " to expand land."
		return

	money -= COST_EXPAND
	tile["kind"] = TileKind.LAND
	tiles[cell.y][cell.x] = tile
	land_expanded_total += 1
	status_text = "Expanded the base with a new land tile."
	_add_popup_for_cell(cell, "Land +1", Color("#b7ef8a"))


func _use_move_tool(cell: Vector2i) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if moving_building == BuildKind.NONE:
		if tile["building"] == BuildKind.NONE:
			status_text = "Tap a building first, then tap an empty land tile."
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
		status_text = "Moving " + _building_name(moving_building) + ". Tap an empty land tile to place it."
		_add_popup_for_cell(cell, "Move", Color("#f2d16b"))
		return

	if tile["kind"] != TileKind.LAND:
		status_text = "Moved buildings must be placed on land."
		return
	if tile["building"] != BuildKind.NONE:
		status_text = "That tile is occupied. Pick an empty land tile."
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
	if workers.size() >= MAX_WORKERS:
		status_text = "Worker cap reached. Later housing will raise the people limit."
		return
	if money < COST_WORKER:
		status_text = "Need $" + str(COST_WORKER) + " to hire a worker."
		return

	money -= COST_WORKER
	var spawn_cell := Vector2i(clamp(3 + workers.size(), 0, GRID_W - 1), GRID_H - 2)
	_spawn_worker(spawn_cell, true)
	selected_tool = TOOL_PEOPLE
	selected_worker_index = workers.size() - 1
	status_text = _worker_name(selected_worker_index) + " hired. Tap a work tile to assign them."
	_add_popup_for_cell(spawn_cell, "Worker +1", Color("#f2d16b"))
	_update_hud()


func _spawn_worker(cell: Vector2i, paid: bool) -> void:
	var worker_name := _worker_name(workers.size())
	workers.append({
		"name": worker_name,
		"pos": Vector2(cell.x, cell.y),
		"target": Vector2(cell.x, cell.y),
		"assigned": cell,
		"work_timer": randf_range(0.5, WORKER_FISH_SECONDS),
		"paid": paid
	})


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
		return worker

	worker["work_timer"] = float(worker["work_timer"]) - delta
	if float(worker["work_timer"]) > 0.0:
		return worker
	worker["work_timer"] = WORKER_FISH_SECONDS

	if tile["fish"] <= 0:
		return worker
	var room := _pool_capacity() - _live_fish_total()
	if room <= 0:
		return worker

	var caught: int = min(1, int(tile["fish"]), room)
	var fish_kind := int(tile["fish_kind"])
	tile["fish"] = int(tile["fish"]) - caught
	tiles[assigned.y][assigned.x] = tile
	_add_fish_to_stock(live_fish_stock, fish_kind, caught)
	fish_caught_total += caught
	fish_stored_total += caught
	_add_fish_to_stock(fish_caught_by_kind, fish_kind, caught)
	status_text = _worker_name(worker_index) + " carried " + _fish_name(fish_kind) + " straight to the pools." + _maybe_unlock_storage(fish_kind)
	_add_popup_for_cell(assigned, _worker_name(worker_index) + " +" + str(caught), _fish_color(fish_kind))
	return worker


func _tick_fish_spawns(delta: float) -> void:
	for y in WATER_ROWS:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if tile["fish"] > 0:
				continue

			tile["spawn_timer"] -= delta
			if tile["spawn_timer"] <= 0.0:
				tile["fish_kind"] = _random_fish_kind()
				tile["fish"] = randi_range(1, min(3, 1 + net_level))
				tile["spawn_timer"] = randf_range(3.0, 7.0)
			tiles[y][x] = tile


func _tick_cutters(delta: float) -> void:
	var cutter_count := _building_count(BuildKind.CUTTER)
	if cutter_count <= 0 or _live_fish_total() <= 0:
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
		status_text = "Cutters processed " + _fish_name(fish_kind) + " into " + str(produced) + " meat."
		_add_popup("+" + str(produced) + " meat", _building_center(BuildKind.CUTTER), Color("#ffd7bb"))


func _tick_smokers(delta: float) -> void:
	var smoker_count := _building_count(BuildKind.SMOKER)
	if smoker_count <= 0:
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
	var spawn_cell := Vector2i(randi_range(0, GRID_W - 1), GRID_H - 1)
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
	pull += float(_worker_count_assigned_to_building(BuildKind.MARKET)) * 0.2
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
	return Vector2i(GRID_W - 2, GRID_H - 1)


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
		return Vector2i(GRID_W - 1, GRID_H - 1)
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
	capacity += _worker_count_assigned_to(cell) * WORKER_POOL_CAPACITY_BONUS
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
	rate += float(_worker_count_assigned_to(cell)) * WORKER_CUTTER_RATE_BONUS
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
	rate += float(_worker_count_assigned_to(cell)) * WORKER_SMOKER_RATE_BONUS
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
	capacity += _worker_count_assigned_to(cell)
	return capacity


func _random_fish_kind() -> int:
	var roll := randf()
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
	for fish_kind: int in [FishKind.SILVERFISH, FishKind.CARP, FishKind.MINNOW]:
		if int(live_fish_stock[fish_kind]) > 0:
			live_fish_stock[fish_kind] = int(live_fish_stock[fish_kind]) - 1
			return fish_kind
	return FishKind.MINNOW


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
	return tile["kind"] != TileKind.EXPANSION


func _worker_assignment_hint(cell: Vector2i) -> String:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if tile["kind"] == TileKind.WATER:
		return "They will catch fish and carry them directly to pools."
	if tile["kind"] == TileKind.ROAD:
		return "They will stand by on the road until you assign a job."

	match int(tile["building"]):
		BuildKind.POOL:
			return "Assigned pool workers add +" + str(WORKER_POOL_CAPACITY_BONUS) + " live capacity."
		BuildKind.CUTTER:
			return "Assigned cutter workers speed up processing."
		BuildKind.MARKET:
			return "Assigned market workers serve more buyers and attract buyers faster."
		BuildKind.STORAGE:
			return "Storage workers are standing by for future hauling jobs."
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
		TOOL_CATCH:
			return "Catch"
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
	return 20 + (net_level - 1) * 15


func _pool_upgrade_cost() -> int:
	return 25 + (pool_level - 1) * 20


func _cutter_upgrade_cost() -> int:
	return 30 + (cutter_level - 1) * 25


func _net_unlock_text() -> String:
	if net_level == 2:
		return " Silverfish can now appear in the water."
	if net_level == 3:
		return " Better fish now appear more often."
	return ""


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
			if _has_adjacent_tile_kind(cell, TileKind.WATER):
				return "Water access gives this pool +2 capacity."
			return "Pools get +2 capacity when touching water."
		BuildKind.CUTTER:
			if _has_adjacent_building(cell, BuildKind.POOL):
				return "Adjacent pool gives this cutter +50% work rate."
			return "Cutters work faster beside pools."
		BuildKind.MARKET:
			if _has_adjacent_tile_kind(cell, TileKind.ROAD):
				return "Road access lets this market sell twice as fast."
			return "Markets sell faster beside the road."
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
	if _is_smoker_unlocked() or smoked_meat > 0:
		smoked_text = "   Smoke:%d/%d" % [smoked_meat, _smoked_meat_capacity()]
	hud_label.text = "Coldwater Catch\n$%d   Carry:%d %s   Live:%d/%d %s   Meat:%d/%d%s\nBuyers:%d/%d   Queue:%d   Lost:%d   Patience:%ds   Crew:%d/%d\nNet %d   Pool %d   Cutter %d   Land:%d" % [
		money,
		_carried_fish_total(),
		_stock_summary(carried_fish_stock),
		_live_fish_total(),
		capacity,
		_stock_summary(live_fish_stock),
		meat,
		_meat_capacity(),
		smoked_text,
		customer_agents.size(),
		MAX_CUSTOMERS,
		customers_waiting,
		customers_lost,
		int(ceil(customer_patience_timer)) if customers_waiting > 0 else int(CUSTOMER_PATIENCE_SECONDS),
		workers.size(),
		MAX_WORKERS,
		net_level,
		pool_level,
		cutter_level,
		land_expanded_total
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
		hire_button.text = "Hire $" + str(COST_WORKER) if workers.size() < MAX_WORKERS else "Crew full"
		hire_button.modulate = _affordability_color(COST_WORKER) if workers.size() < MAX_WORKERS else Color("#6f7782")


func _calculate_grid_rect() -> void:
	var top_margin := 222.0
	var bottom_margin := 272.0
	var inner_width: float = max(1.0, size.x - 24.0)
	var inner_height: float = max(1.0, size.y - top_margin - bottom_margin)
	tile_px = floor(min(inner_width / float(GRID_W), inner_height / float(GRID_H)))
	tile_px = clamp(tile_px, 34.0, 78.0)

	var grid_size := Vector2(float(GRID_W) * tile_px, float(GRID_H) * tile_px)
	var origin := Vector2(
		floor((size.x - grid_size.x) * 0.5),
		top_margin + floor(max(0.0, inner_height - grid_size.y) * 0.5)
	)
	grid_rect = Rect2(origin, grid_size)


func _draw_grid() -> void:
	var font := get_theme_default_font()
	for y in GRID_H:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			var rect := Rect2(
				grid_rect.position + Vector2(float(x) * tile_px, float(y) * tile_px),
				Vector2(tile_px, tile_px)
			).grow(-2.0)

			var fill := Color("#5e6747")
			if tile["kind"] == TileKind.WATER:
				fill = Color("#326b82")
			elif tile["kind"] == TileKind.ROAD:
				fill = Color("#504a45")
			elif tile["kind"] == TileKind.EXPANSION:
				fill = Color("#4d5660")
			draw_rect(rect, fill)
			draw_rect(rect, Color("#0e151b"), false, 2.0)

			if tile["kind"] == TileKind.WATER:
				_draw_water_tile(rect, int(tile["fish"]), int(tile["fish_kind"]))
			elif tile["kind"] == TileKind.ROAD:
				_draw_road_tile(rect)
			elif tile["kind"] == TileKind.EXPANSION:
				_draw_expansion_tile(rect)
			else:
				_draw_land_tile(rect, int(tile["building"]))

			if tile["building"] != BuildKind.NONE:
				var label := _building_label(int(tile["building"]))
				draw_string(font, rect.position + Vector2(8.0, rect.size.y - 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, 14, Color("#f5efe1"))

			if selected_cell == Vector2i(x, y):
				draw_rect(rect.grow(2.0), Color("#f2d16b"), false, 3.0)


func _draw_water_tile(rect: Rect2, fish_count: int, fish_kind: int) -> void:
	draw_arc(rect.get_center(), tile_px * 0.26, 0.2, PI - 0.2, 16, Color("#9fe4dd"), 2.0)
	draw_arc(rect.get_center() + Vector2(0, 6), tile_px * 0.22, 0.2, PI - 0.2, 16, Color("#72c5c3"), 2.0)

	for i in fish_count:
		var offset := Vector2(-tile_px * 0.18 + float(i) * tile_px * 0.18, -tile_px * 0.04 + float(i % 2) * 8.0)
		_draw_fish(rect.get_center() + offset, tile_px * 0.18, fish_kind)


func _draw_road_tile(rect: Rect2) -> void:
	draw_rect(rect, Color("#504a45"))
	draw_line(rect.position + Vector2(0, rect.size.y * 0.5), rect.end - Vector2(0, rect.size.y * 0.5), Color("#e8d28d"), 3.0)
	draw_line(rect.position + Vector2(8, rect.size.y * 0.5), rect.position + Vector2(rect.size.x - 8, rect.size.y * 0.5), Color("#2c2927"), 1.0)


func _draw_expansion_tile(rect: Rect2) -> void:
	draw_rect(rect, Color("#4d5660"))
	draw_line(rect.position + Vector2(8, 8), rect.end - Vector2(8, 8), Color("#9aa6b2"), 2.0)
	draw_line(rect.position + Vector2(rect.size.x - 8, 8), rect.position + Vector2(8, rect.size.y - 8), Color("#9aa6b2"), 2.0)
	draw_circle(rect.get_center(), 3.0, Color("#c9d2d8"))


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
		_draw_person(screen_pos, color, false, _buyer_short_label(buyer_kind))
		if state == "arriving" or state == "waiting":
			_draw_want_bubble(screen_pos, _buyer_want_label(customer), _buyer_color(buyer_kind))

	for i in workers.size():
		var worker: Dictionary = workers[i]
		var worker_pos: Vector2 = worker["pos"]
		_draw_person(_agent_screen_pos(worker_pos), Color("#f2d16b"), i == selected_worker_index, "W")


func _draw_dock_order_board() -> void:
	if not _is_dock_order_unlocked():
		return

	var rect := _cell_rect(_order_board_cell()).grow(-tile_px * 0.12)
	var font := get_theme_default_font()
	draw_rect(rect, Color("#2c2722"))
	draw_rect(rect, Color("#f0d597"), false, 2.0)
	draw_line(rect.position + Vector2(rect.size.x * 0.5, rect.size.y), rect.position + Vector2(rect.size.x * 0.5, rect.size.y + tile_px * 0.14), Color("#2c2722"), 3.0)
	draw_string(font, rect.position + Vector2(0, 13), "ORD", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, Color("#f0d597"))
	var label := "wait"
	if dock_order_active:
		var parts: Array = []
		if dock_order_need_meat > 0:
			parts.append("M" + str(dock_order_delivered_meat) + "/" + str(dock_order_need_meat))
		if dock_order_need_smoked > 0:
			parts.append("S" + str(dock_order_delivered_smoked) + "/" + str(dock_order_need_smoked))
		label = " ".join(parts)
	draw_string(font, rect.position + Vector2(0, rect.size.y - 5), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 10, Color("#f5efe1"))


func _agent_screen_pos(pos: Vector2) -> Vector2:
	return grid_rect.position + Vector2((pos.x + 0.5) * tile_px, (pos.y + 0.5) * tile_px)


func _draw_person(center: Vector2, body_color: Color, selected: bool, label: String) -> void:
	var head_radius: float = max(3.0, tile_px * 0.075)
	var body_size := Vector2(tile_px * 0.16, tile_px * 0.18)
	if selected:
		draw_circle(center, tile_px * 0.22, Color("#f2d16b"))
		draw_circle(center, tile_px * 0.18, Color("#17212b"))
	draw_circle(center + Vector2(0, -tile_px * 0.12), head_radius, Color("#f5efe1"))
	draw_rect(Rect2(center - body_size * 0.5 + Vector2(0, tile_px * 0.03), body_size), body_color)
	draw_line(center + Vector2(-body_size.x * 0.55, tile_px * 0.02), center + Vector2(-body_size.x, tile_px * 0.12), body_color, 2.0)
	draw_line(center + Vector2(body_size.x * 0.55, tile_px * 0.02), center + Vector2(body_size.x, tile_px * 0.12), body_color, 2.0)
	if label != "":
		draw_string(get_theme_default_font(), center + Vector2(-tile_px * 0.12, tile_px * 0.28), label, HORIZONTAL_ALIGNMENT_CENTER, tile_px * 0.24, 11, Color("#17212b"))


func _draw_want_bubble(center: Vector2, label: String, color: Color) -> void:
	var font := get_theme_default_font()
	var bubble_width: float = max(tile_px * 0.32, float(label.length()) * 8.0 + 8.0)
	var bubble := Rect2(center + Vector2(-bubble_width * 0.5, -tile_px * 0.54), Vector2(bubble_width, 15.0))
	draw_rect(bubble, Color("#f5efe1"))
	draw_rect(bubble, color, false, 1.5)
	draw_string(font, bubble.position + Vector2(0, 11.0), label, HORIZONTAL_ALIGNMENT_CENTER, bubble.size.x, 11, Color("#17212b"))


func _draw_land_tile(rect: Rect2, building: int) -> void:
	match building:
		BuildKind.NONE:
			draw_circle(rect.get_center() + Vector2(-8, -4), 3.0, Color("#76805a"))
			draw_circle(rect.get_center() + Vector2(10, 8), 2.5, Color("#788252"))
		BuildKind.POOL:
			var pool_rect := rect.grow(-tile_px * 0.18)
			draw_rect(pool_rect, Color("#1c90a3"))
			draw_rect(pool_rect, Color("#b6fff2"), false, 2.0)
			draw_circle(pool_rect.get_center() + Vector2(-8, -4), 4.0, Color("#b6fff2"))
			draw_circle(pool_rect.get_center() + Vector2(8, 5), 3.0, Color("#d2fff7"))
		BuildKind.CUTTER:
			var body := rect.grow(-tile_px * 0.17)
			draw_rect(body, Color("#773d44"))
			draw_rect(body, Color("#ffd7bb"), false, 2.0)
			draw_line(body.position + Vector2(8, body.size.y - 8), body.end - Vector2(8, body.size.y - 8), Color("#f4f0e5"), 5.0)
			if _building_count(BuildKind.CUTTER) > 0:
				var bar_width: float = body.size.x * clamp(cutter_progress / _cutter_required_time(), 0.0, 1.0)
				draw_rect(Rect2(body.position + Vector2(0, body.size.y - 5), Vector2(bar_width, 5)), Color("#f2d16b"))
		BuildKind.MARKET:
			var stall := rect.grow(-tile_px * 0.16)
			draw_rect(stall, Color("#6c4a9b"))
			draw_rect(Rect2(stall.position, Vector2(stall.size.x, stall.size.y * 0.32)), Color("#f2d16b"))
			draw_line(stall.position + Vector2(0, stall.size.y * 0.32), stall.position + Vector2(stall.size.x, stall.size.y * 0.32), Color("#1b1720"), 2.0)
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


func _draw_fish(center: Vector2, scale: float, fish_kind: int) -> void:
	var color := _fish_color(fish_kind)
	draw_circle(center, scale * 0.48, color)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(scale * 0.38, 0),
			center + Vector2(scale * 0.82, -scale * 0.36),
			center + Vector2(scale * 0.82, scale * 0.36)
		]),
		PackedColorArray([color, color, color])
	)
	draw_circle(center + Vector2(-scale * 0.18, -scale * 0.1), scale * 0.08, Color("#17212b"))


func _draw_footer_hint() -> void:
	if selected_tool == TOOL_CATCH:
		return
	var font := get_theme_default_font()
	var hint := ""
	match selected_tool:
		TOOL_PEOPLE:
			if selected_worker_index >= 0 and selected_worker_index < workers.size():
				hint = "People: " + _worker_name(selected_worker_index) + " selected. Tap water, a building, or land."
			else:
				hint = "People: tap a worker, then tap water, a building, or land."
		TOOL_EXPAND:
			hint = "Expand: tap edge ground to buy one land tile."
		TOOL_MOVE:
			hint = "Move: tap a building, then an empty land tile."
		TOOL_REMOVE:
			hint = "Remove: tap a building to recover half its cost."
		_:
			hint = "Tap a land tile to place: " + selected_tool
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
		grid_rect.position + Vector2(float(cell.x) * tile_px, float(cell.y) * tile_px),
		Vector2(tile_px, tile_px)
	).grow(-2.0)


func _selected_tile_text() -> String:
	if selected_cell.x < 0:
		return "Tile: tap water, people, pools, cutters, or markets to inspect them."

	if _is_dock_order_unlocked() and selected_cell == _order_board_cell():
		if dock_order_active:
			return "Order board: " + _dock_order_progress_text() + ". Markets deliver spare sales capacity into this order."
		return "Order board: waiting for the next dock request."

	var worker_index := _worker_index_at_cell(selected_cell)
	if worker_index >= 0:
		var worker: Dictionary = workers[worker_index]
		var assigned: Vector2i = worker["assigned"]
		var assignment := "standing by"
		if assigned != selected_cell:
			assignment = "walking to " + str(assigned)
		else:
			assignment = _worker_assignment_hint(assigned)
		return "Person: " + _worker_name(worker_index) + ". " + assignment

	var buyer_index := _buyer_index_at_cell(selected_cell)
	if buyer_index >= 0:
		var buyer: Dictionary = customer_agents[buyer_index]
		return "Buyer: " + _buyer_name(int(buyer["kind"])) + " " + _buyer_want_text(buyer) + ". State: " + str(buyer["state"]) + "."

	var tile: Dictionary = tiles[selected_cell.y][selected_cell.x]
	if tile["kind"] == TileKind.WATER:
		if tile["fish"] <= 0:
			return "Tile: water. Fish will return soon."
		var fish_kind := int(tile["fish_kind"])
		return "Tile: water with " + str(tile["fish"]) + " " + _fish_plural(fish_kind, int(tile["fish"])) + ". Workers assigned here auto-carry fish to pools."
	if tile["kind"] == TileKind.ROAD:
		return "Tile: road. Markets beside roads sell twice as fast."
	if tile["kind"] == TileKind.EXPANSION:
		if _is_land_expansion_unlocked():
			return "Tile: expansion ground. Use Expand to buy this land for $" + str(COST_EXPAND) + "."
		return "Tile: expansion ground. Build Storage to unlock land expansion."

	match int(tile["building"]):
		BuildKind.POOL:
			return "Tile: pool. Holds " + str(_pool_capacity_at(selected_cell)) + "; staff " + str(_worker_count_assigned_to(selected_cell)) + "; total live capacity " + str(_pool_capacity()) + "."
		BuildKind.CUTTER:
			return "Tile: cutter. Rate x" + _format_ratio(_cutter_rate_at(selected_cell)) + "; staff " + str(_worker_count_assigned_to(selected_cell)) + "; faster beside pools."
		BuildKind.MARKET:
			return "Tile: market. Sales " + str(_market_capacity_at(selected_cell)) + "/tick; staff " + str(_worker_count_assigned_to(selected_cell)) + "; road access doubles it."
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
			return "Tile: open land. Build " + options + " here."


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
