extends Control

enum TileKind { WATER, LAND, ROAD }
enum BuildKind { NONE, POOL, CUTTER, MARKET }
enum GoalStep { CATCH, STORE, PROCESS, SELL, UPGRADE, BUILD, COMPLETE }

const GRID_W := 8
const GRID_H := 10
const WATER_ROWS := 3
const MAX_CUSTOMERS := 8

const TOOL_CATCH := "catch"
const TOOL_POOL := "pool"
const TOOL_CUTTER := "cutter"
const TOOL_MARKET := "market"
const TOOL_MOVE := "move"
const TOOL_REMOVE := "remove"

const COST_POOL := 10
const COST_CUTTER := 15
const COST_MARKET := 20

var tiles: Array = []
var selected_tool := TOOL_CATCH
var money := 30
var carried_fish := 0
var live_fish := 0
var meat := 0
var net_level := 1
var pool_level := 1
var cutter_level := 1
var customers_waiting := 0
var customer_timer := 4.0
var cutter_progress := 0.0
var status_text := "Tap water to catch fish. The starter fishery can already process and sell."
var goal_step := GoalStep.CATCH
var fish_caught_total := 0
var fish_stored_total := 0
var meat_processed_total := 0
var meat_sold_total := 0
var upgrades_bought_total := 0
var buildings_built_total := 0

var grid_rect := Rect2()
var tile_px := 48.0
var selected_cell := Vector2i(-1, -1)
var moving_building := BuildKind.NONE
var move_source_cell := Vector2i(-1, -1)
var feedback_popups: Array = []
var hud_label: Label
var goal_label: Label
var inspector_label: Label
var status_label: Label
var tool_buttons: Dictionary = {}


func _ready() -> void:
	randomize()
	_init_tiles()
	_build_ui()
	_update_hud()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_tick_fish_spawns(delta)
	_tick_cutters(delta)
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
			var fish_count := randi_range(1, 2) if kind == TileKind.WATER and randf() < 0.45 else 0
			row.append({
				"kind": kind,
				"building": BuildKind.NONE,
				"fish": fish_count,
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
	_add_tool_button(actions, TOOL_POOL, "Pool $10", "Build live fish capacity on land.")
	_add_tool_button(actions, TOOL_CUTTER, "Cutter $15", "Build processing on land.")
	_add_tool_button(actions, TOOL_MARKET, "Market $20", "Build selling on land.")
	_add_tool_button(actions, TOOL_MOVE, "Move", "Move one building to another land tile.")
	_add_tool_button(actions, TOOL_REMOVE, "Remove", "Remove a building and recover half its cost.")
	_add_command_button(actions, "Net +", "Upgrade net", _upgrade_net)
	_add_command_button(actions, "Pool +", "Upgrade pools", _upgrade_pool)
	_add_command_button(actions, "Cutter +", "Upgrade cutters", _upgrade_cutter)
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
		selected_tool = tool
		status_text = "Selected " + text + "."
		_update_tool_buttons()
	)
	parent.add_child(button)
	tool_buttons[tool] = button


func _add_command_button(parent: Control, text: String, tooltip: String, callable: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(96, 42)
	button.pressed.connect(callable)
	parent.add_child(button)


func _select_catch() -> void:
	_cancel_move_if_needed()
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
		TOOL_POOL:
			_try_build(cell, BuildKind.POOL, COST_POOL, "pool")
		TOOL_CUTTER:
			_try_build(cell, BuildKind.CUTTER, COST_CUTTER, "cutter")
		TOOL_MARKET:
			_try_build(cell, BuildKind.MARKET, COST_MARKET, "market")
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
		tile["fish"] -= caught
		tiles[cell.y][cell.x] = tile
		carried_fish += caught
		fish_caught_total += caught
		status_text = "Caught " + str(caught) + " fish. Tap a pool to store them."
		_add_popup_for_cell(cell, "+" + str(caught) + " fish", Color("#f2d16b"))
		return

	if tile["building"] == BuildKind.POOL:
		if carried_fish <= 0:
			status_text = "You are not carrying fish. Tap water first."
			return

		var room := _pool_capacity() - live_fish
		if room <= 0:
			status_text = "Pools are full. Build or upgrade more capacity."
			return

		var moved: int = min(room, carried_fish)
		carried_fish -= moved
		live_fish += moved
		fish_stored_total += moved
		status_text = "Stored " + str(moved) + " live fish in pools."
		_add_popup_for_cell(cell, "+" + str(moved) + " live", Color("#9fe4dd"))
		return

	status_text = "Catch works on water, or on pools when carrying fish."


func _try_build(cell: Vector2i, building: int, cost: int, label: String) -> void:
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


func _use_move_tool(cell: Vector2i) -> void:
	var tile: Dictionary = tiles[cell.y][cell.x]
	if moving_building == BuildKind.NONE:
		if tile["building"] == BuildKind.NONE:
			status_text = "Tap a building first, then tap an empty land tile."
			return
		if tile["building"] == BuildKind.POOL and not _can_remove_pool_at(cell):
			status_text = "Cannot move this pool while it is needed for live fish capacity."
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

	var refund := int(floor(float(_building_cost(building)) * 0.5))
	money += refund
	tile["building"] = BuildKind.NONE
	tiles[cell.y][cell.x] = tile
	status_text = "Removed " + _building_name(building) + " and recovered $" + str(refund) + "."
	_add_popup_for_cell(cell, "+$" + str(refund), Color("#b7ef8a"))


func _upgrade_net() -> void:
	var cost := 20 + (net_level - 1) * 15
	if money < cost:
		status_text = "Need $" + str(cost) + " to upgrade the net."
		return
	money -= cost
	net_level += 1
	upgrades_bought_total += 1
	status_text = "Net upgraded to level " + str(net_level) + "."
	_add_popup("Net level " + str(net_level), grid_rect.position + Vector2(grid_rect.size.x * 0.5, 28.0), Color("#f2d16b"))
	_update_hud()


func _upgrade_pool() -> void:
	var cost := 25 + (pool_level - 1) * 20
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
	var cost := 30 + (cutter_level - 1) * 25
	if money < cost:
		status_text = "Need $" + str(cost) + " to upgrade cutters."
		return
	money -= cost
	cutter_level += 1
	upgrades_bought_total += 1
	status_text = "Cutters upgraded to level " + str(cutter_level) + "."
	_add_popup("Cutter level " + str(cutter_level), grid_rect.position + Vector2(grid_rect.size.x * 0.5, 28.0), Color("#ffd7bb"))
	_update_hud()


func _tick_fish_spawns(delta: float) -> void:
	for y in WATER_ROWS:
		for x in GRID_W:
			var tile: Dictionary = tiles[y][x]
			if tile["fish"] > 0:
				continue

			tile["spawn_timer"] -= delta
			if tile["spawn_timer"] <= 0.0:
				tile["fish"] = randi_range(1, min(3, 1 + net_level))
				tile["spawn_timer"] = randf_range(3.0, 7.0)
			tiles[y][x] = tile


func _tick_cutters(delta: float) -> void:
	var cutter_count := _building_count(BuildKind.CUTTER)
	if cutter_count <= 0 or live_fish <= 0:
		cutter_progress = 0.0
		return
	if meat >= _meat_capacity():
		status_text = "Meat storage is full. Build or move markets near roads to sell faster."
		return

	var required: float = _cutter_required_time()
	cutter_progress += delta * _cutter_rate()

	while cutter_progress >= required and live_fish > 0:
		var produced := 2 + int(cutter_level >= 3)
		if meat + produced > _meat_capacity():
			status_text = "Meat storage is full. Markets create more storage and sell faster near roads."
			break
		cutter_progress -= required
		live_fish -= 1
		meat += produced
		meat_processed_total += produced
		status_text = "Cutters processed fish into meat."
		_add_popup("+" + str(produced) + " meat", _building_center(BuildKind.CUTTER), Color("#ffd7bb"))


func _tick_customers(delta: float) -> void:
	customer_timer -= delta
	if customer_timer <= 0.0:
		customers_waiting = min(MAX_CUSTOMERS, customers_waiting + 1)
		customer_timer = randf_range(3.0, 5.5)

	var sales_capacity := _market_sales_capacity()
	if sales_capacity <= 0 or customers_waiting <= 0 or meat <= 0:
		return

	var sold: int = min(meat, sales_capacity, customers_waiting)
	meat -= sold
	customers_waiting -= sold
	money += sold * 6
	meat_sold_total += sold
	status_text = "Sold " + str(sold) + " meat for $" + str(sold * 6) + "."
	_add_popup("+$" + str(sold * 6), _building_center(BuildKind.MARKET), Color("#b7ef8a"))


func _building_count(building: int) -> int:
	var count := 0
	for row in tiles:
		for tile in row:
			if tile["building"] == building:
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
	return live_fish <= _pool_capacity_without(cell)


func _meat_capacity() -> int:
	return 18 + _building_count(BuildKind.MARKET) * 6 + cutter_level * 2


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
	return capacity


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
		_:
			return 0


func _building_name(building: int) -> String:
	match building:
		BuildKind.POOL:
			return "pool"
		BuildKind.CUTTER:
			return "cutter"
		BuildKind.MARKET:
			return "market"
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
				_complete_goal("Customers are buying. The loop works.", 6)
		GoalStep.UPGRADE:
			if upgrades_bought_total >= 1:
				_complete_goal("First upgrade bought. The fishery is getting faster.", 8)
		GoalStep.BUILD:
			if buildings_built_total >= 1:
				_complete_goal("First expansion built. Phase 1 loop is online.", 10)


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
			return "Goal: Sell 2 meat to customers. " + _progress_text(meat_sold_total, 2)
		GoalStep.UPGRADE:
			return "Goal: Buy any upgrade. " + _progress_text(upgrades_bought_total, 1)
		GoalStep.BUILD:
			return "Goal: Build one extra pool, cutter, or market. " + _progress_text(buildings_built_total, 1)
		_:
			return "Phase 1 complete: keep improving the loop or start the next milestone."


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
	hud_label.text = "Coldwater Catch\n$%d   Carry:%d   Live:%d/%d   Meat:%d/%d   Customers:%d\nNet %d   Pool %d   Cutter %d" % [
		money,
		carried_fish,
		live_fish,
		capacity,
		meat,
		_meat_capacity(),
		customers_waiting,
		net_level,
		pool_level,
		cutter_level
	]
	goal_label.text = _goal_text()
	status_label.text = status_text
	inspector_label.text = _selected_tile_text()
	_update_tool_buttons()


func _update_tool_buttons() -> void:
	for tool in tool_buttons.keys():
		var button: Button = tool_buttons[tool]
		button.button_pressed = tool == selected_tool


func _calculate_grid_rect() -> void:
	var top_margin := 136.0
	var bottom_margin := 250.0
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
			draw_rect(rect, fill)
			draw_rect(rect, Color("#0e151b"), false, 2.0)

			if tile["kind"] == TileKind.WATER:
				_draw_water_tile(rect, int(tile["fish"]))
			elif tile["kind"] == TileKind.ROAD:
				_draw_road_tile(rect)
			else:
				_draw_land_tile(rect, int(tile["building"]))

			if tile["building"] != BuildKind.NONE:
				var label := _building_label(int(tile["building"]))
				draw_string(font, rect.position + Vector2(8.0, rect.size.y - 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, 14, Color("#f5efe1"))

			if selected_cell == Vector2i(x, y):
				draw_rect(rect.grow(2.0), Color("#f2d16b"), false, 3.0)


func _draw_water_tile(rect: Rect2, fish_count: int) -> void:
	draw_arc(rect.get_center(), tile_px * 0.26, 0.2, PI - 0.2, 16, Color("#9fe4dd"), 2.0)
	draw_arc(rect.get_center() + Vector2(0, 6), tile_px * 0.22, 0.2, PI - 0.2, 16, Color("#72c5c3"), 2.0)

	for i in fish_count:
		var offset := Vector2(-tile_px * 0.18 + float(i) * tile_px * 0.18, -tile_px * 0.04 + float(i % 2) * 8.0)
		_draw_fish(rect.get_center() + offset, tile_px * 0.18)


func _draw_road_tile(rect: Rect2) -> void:
	draw_rect(rect, Color("#504a45"))
	draw_line(rect.position + Vector2(0, rect.size.y * 0.5), rect.end - Vector2(0, rect.size.y * 0.5), Color("#e8d28d"), 3.0)
	draw_line(rect.position + Vector2(8, rect.size.y * 0.5), rect.position + Vector2(rect.size.x - 8, rect.size.y * 0.5), Color("#2c2927"), 1.0)


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


func _draw_fish(center: Vector2, scale: float) -> void:
	draw_circle(center, scale * 0.48, Color("#f2d16b"))
	draw_polygon(
		PackedVector2Array([
			center + Vector2(scale * 0.38, 0),
			center + Vector2(scale * 0.82, -scale * 0.36),
			center + Vector2(scale * 0.82, scale * 0.36)
		]),
		PackedColorArray([Color("#f2d16b"), Color("#f2d16b"), Color("#f2d16b")])
	)
	draw_circle(center + Vector2(-scale * 0.18, -scale * 0.1), scale * 0.08, Color("#17212b"))


func _draw_footer_hint() -> void:
	if selected_tool == TOOL_CATCH:
		return
	var font := get_theme_default_font()
	var hint := ""
	match selected_tool:
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
		return "Tile: tap any water, pool, cutter, or market to inspect it."

	var tile: Dictionary = tiles[selected_cell.y][selected_cell.x]
	if tile["kind"] == TileKind.WATER:
		return "Tile: water with " + str(tile["fish"]) + " fish."
	if tile["kind"] == TileKind.ROAD:
		return "Tile: road. Markets beside roads sell twice as fast."

	match int(tile["building"]):
		BuildKind.POOL:
			return "Tile: pool. This pool holds " + str(_pool_capacity_at(selected_cell)) + "; total live capacity " + str(_pool_capacity()) + "."
		BuildKind.CUTTER:
			return "Tile: cutter. Rate x" + _format_ratio(_cutter_rate_at(selected_cell)) + "; faster beside pools."
		BuildKind.MARKET:
			return "Tile: market. Sales " + str(_market_capacity_at(selected_cell)) + "/tick; road access doubles it."
		_:
			return "Tile: open land. Build a pool, cutter, or market here."


func _building_label(building: int) -> String:
	match building:
		BuildKind.POOL:
			return "POOL"
		BuildKind.CUTTER:
			return "CUT"
		BuildKind.MARKET:
			return "SELL"
		_:
			return ""
