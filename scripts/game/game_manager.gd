class_name GameManager
extends Node2D


@onready var inventory: ResourceInventory = $ResourceInventory
@onready var backpack: PlayerBackpack = $PlayerBackpack


@onready var player_interaction: PlayerInteraction = (
	$Entities/Player/PlayerInteraction
)
@onready var hud: HUD = $Interface/HUD

@onready var player: Player = $Entities/Player
@onready var camp_menu: CampMenu = $Interface/CampMenu
@onready var day_cycle: DayCycle = $DayCycle

@onready var camp: Camp = $Entities/Camp
@onready var result_screen: ResultScreen = $Interface/ResultScreen

@onready var world_tint: CanvasModulate = $WorldTint

@onready var ui_sound: AudioStreamPlayer = (
	$Interface/UISound
)
@onready var ui_denied_sound: AudioStreamPlayer = (
	$Interface/UIDeniedSound
)
@onready var victory_sound: AudioStreamPlayer = (
	$Interface/VictorySound
)
@onready var defeat_sound: AudioStreamPlayer = (
	$Interface/DefeatSound
)
@onready var forest_ambience: AudioStreamPlayer = (
	$ForestAmbience
)
@onready var night_ambience: AudioStreamPlayer = (
	$NightAmbience
)

@onready var deposit_timer: Timer = $DepositTimer



var ambience_crossfade_tween: Tween

var world_tint_tween: Tween


var game_finished: bool = false
var active_camp: Camp
var deposit_camp: Camp

var next_camp_stage_was_affordable := false

func _ready() -> void:
	player_interaction.interaction_completed.connect(
		_on_interaction_completed
	)

	inventory.resource_changed.connect(
		_on_inventory_resource_changed
	)
	
	player_interaction.interaction_prompt_changed.connect(
		_on_interaction_prompt_changed
	)
	
	camp_menu.build_requested.connect(
		_on_camp_build_requested
	)

	camp_menu.close_requested.connect(
		_close_camp_menu
	)
	
	day_cycle.display_changed.connect(
		_on_time_display_changed
	)

	day_cycle.day_ended.connect(
		_on_day_ended
	)

	day_cycle.survival_period_completed.connect(
		_on_survival_period_completed
	)

	_on_time_display_changed(
		day_cycle.current_day,
		day_cycle.get_phase_name()
	)
	
	result_screen.restart_requested.connect(
		_on_restart_requested
	)

	backpack.weight_changed.connect(
		_on_backpack_weight_changed
	)

	player_interaction.interaction_target_entered.connect(
		_on_interaction_target_entered
	)

	player_interaction.interaction_target_exited.connect(
		_on_interaction_target_exited
	)

	deposit_timer.timeout.connect(
		_on_deposit_timer_timeout
	)


	_update_entire_hud()


func _on_interaction_completed(
	result: Dictionary
) -> void:
	var action: String = result.get(
		"action",
		""
	)

	match action:
		"resource_requested":
			var resource := (
				result.get("resource") as ResourceNode
			)

			if resource == null:
				return

			var resource_type := int(
				result.get("resource_type", -1)
			)

			var requested_amount := int(
				result.get("amount", 1)
			)

			if not backpack.can_add(
				resource_type,
				requested_amount
			):
				_show_backpack_full()
				return

			var gathered_amount := resource.complete_gathering(
				requested_amount
			)

			if gathered_amount <= 0:
				return

			var resource_added := backpack.add_resource(
				resource_type,
				gathered_amount
			)

			if not resource_added:
				push_warning(
					"Backpack capacity changed during collection."
				)
				return

			var resource_name := (
				ResourceTypes.get_display_name(
					resource_type
				)
			)

			var player_screen_position := (
				get_viewport().get_canvas_transform()
				* player.global_position
			)

			hud.show_resource_gain(
				"+%d %s" % [
					gathered_amount,
					resource_name
				],
				player_screen_position
			)

			if resource.is_depleted:
				player_interaction.remove_target(
					resource
				)
			else:
				player_interaction.refresh_prompt()
		
		"camp_opened":
			var camp := result.get("camp") as Camp

			if camp != null:
				_open_camp_menu(camp)
		_:
			push_warning(
				"Unknown interaction action: %s"
				% action
			)


func _on_inventory_resource_changed(
	resource_type: int,
	new_amount: int
) -> void:
	hud.set_resource_amount(
		resource_type,
		new_amount
	)


func _update_entire_hud() -> void:
	hud.set_resource_amount(
		ResourceTypes.Type.WOOD,
		inventory.get_amount(ResourceTypes.Type.WOOD)
	)

	hud.set_resource_amount(
		ResourceTypes.Type.STONE,
		inventory.get_amount(ResourceTypes.Type.STONE)
	)

	hud.set_resource_amount(
		ResourceTypes.Type.FOOD,
		inventory.get_amount(ResourceTypes.Type.FOOD)
	)
	hud.set_backpack_weight(
		backpack.get_current_weight(),
		backpack.maximum_weight
	)

func _on_interaction_prompt_changed(text: String) -> void:
	if text.is_empty():
		hud.hide_interaction_prompt()
		return

	hud.show_interaction_prompt(text)


func _open_camp_menu(camp: Camp) -> void:
	active_camp = camp
	_play_ui_click()
	
	hud.hide_interaction_prompt()
	
	player.set_movement_enabled(false)
	player_interaction.set_process_unhandled_input(false)
	
	day_cycle.set_running(false)
	_refresh_camp_menu()


func _refresh_camp_menu() -> void:
	if active_camp == null:
		return

	var costs := active_camp.get_next_stage_cost()
	var is_complete := costs.is_empty()

	camp_menu.open_menu(
		active_camp.get_next_stage_name(),
		_format_cost(costs),
		_can_afford(costs),
		is_complete
	)


func _on_camp_build_requested() -> void:
	if active_camp == null:
		return
	
	_play_ui_click()
	
	var costs := active_camp.get_next_stage_cost()

	if not _can_afford(costs):
		camp_menu.show_message("Not enough resources")
		_play_ui_denied()
		return

	_pay_cost(costs)
	active_camp.advance_construction()
	
	next_camp_stage_was_affordable = false
	_check_next_camp_stage_affordability()

	if active_camp.current_stage == Camp.CampStage.CABIN:
		_finish_game(
			"Victory",
			"The cabin is complete. You are ready for winter."
		)
		return

	_refresh_camp_menu()


func _can_afford(costs: Dictionary) -> bool:
	for resource_type in costs:
		var required_amount := int(costs[resource_type])

		if not inventory.has_resources(
			int(resource_type),
			required_amount
		):
			return false

	return true

func _check_next_camp_stage_affordability() -> void:
	if camp.current_stage == Camp.CampStage.CABIN:
		next_camp_stage_was_affordable = false
		return

	var costs := camp.get_next_stage_cost()
	var is_now_affordable := _can_afford(costs)

	if (
		is_now_affordable
		and not next_camp_stage_was_affordable
	):
		var next_stage_name := (
			camp.get_next_stage_name()
		)

		hud.show_milestone(
			#"NEXT BUILD AVAILABLE\n%s — RETURN TO CAMP"
			"NEXT BUILD AVAILABLE\n%s !"
			% next_stage_name.to_upper()
		)

	next_camp_stage_was_affordable = is_now_affordable




func _pay_cost(costs: Dictionary) -> void:
	for resource_type in costs:
		inventory.remove_resource(
			int(resource_type),
			int(costs[resource_type])
		)


func _format_cost(costs: Dictionary) -> String:
	if costs.is_empty():
		return ""

	var parts := PackedStringArray()

	for resource_type in costs:
		var resource_name := ResourceTypes.get_display_name(
			int(resource_type)
		)

		parts.append(
			"%s %s" % [
				costs[resource_type],
				resource_name
			]
		)

	return ", ".join(parts)



func _close_camp_menu() -> void:
	_play_ui_click()
	camp_menu.close_menu()
	active_camp = null

	player.set_movement_enabled(true)
	player_interaction.set_process_unhandled_input(true)
	player_interaction.refresh_prompt()
	day_cycle.set_running(true)
	
func _on_time_display_changed(
	day: int,
	phase: String
) -> void:
	hud.set_day(day, phase)
	_update_world_tint(phase)

func _on_day_ended(day: int) -> void:
	if game_finished:
		return

	var food_type := ResourceTypes.Type.FOOD

	if inventory.remove_resource(food_type, 1):
		print("Consumed 1 Food from camp storage.")
		return

	if backpack.remove_resource(food_type, 1):
		hud.show_resource_gain(
			"-1 Food from backpack",
			_get_player_screen_position()
		)

		print("Consumed 1 Food from backpack.")
		return

	_finish_game(
		"Defeat",
		"Your supplies ran out before the cabin was complete."
	)


func _on_survival_period_completed() -> void:
	if game_finished:
		return

	if camp.current_stage == Camp.CampStage.CABIN:
		_finish_game(
			"Victory",
			"The cabin is ready for winter."
		)
	else:
		_finish_game(
			"Defeat",
			"Winter arrived before the cabin was completed."
		)

func _finish_game(
	title: String,
	message: String
) -> void:
	if game_finished:
		return

	game_finished = true
	active_camp = null

	match title:
		"Victory":
			_play_victory_sound()
			_fade_out_ambience()

		"Defeat":
			_play_defeat_sound()

	day_cycle.set_running(false)
	player.set_movement_enabled(false)
	player_interaction.set_process_unhandled_input(false)

	hud.hide_interaction_prompt()
	camp_menu.close_menu()
	
	var camp_stage_name := String(
		Camp.CampStage.keys()[
			int(camp.current_stage)
		]
	).capitalize()

	var final_stats := {
		"day": day_cycle.current_day,
		"wood": inventory.get_amount(
			ResourceTypes.Type.WOOD
		),
		"stone": inventory.get_amount(
			ResourceTypes.Type.STONE
		),
		"food": inventory.get_amount(
			ResourceTypes.Type.FOOD
		),
		"camp_stage": camp_stage_name
	}

	result_screen.show_result(
		title,
		message,
		final_stats
	)


func _on_restart_requested() -> void:
	get_tree().reload_current_scene()

func _update_world_tint(phase: String) -> void:
	var target_color := Color.WHITE

	match phase.to_lower():
		"morning":
			target_color = Color("#fff1d6")

		"afternoon":
			target_color = Color("#ffffff")

		"evening":
			target_color = Color("#ddb29f")

		"night":
			target_color = Color("#8497bd")

	if world_tint_tween != null:
		world_tint_tween.kill()

	world_tint_tween = create_tween()

	world_tint_tween.tween_property(
		world_tint,
		"color",
		target_color,
		1.5
	)
	var normalized_phase := phase.to_lower()
	_update_ambience(normalized_phase)
	camp.set_night_lighting(
		normalized_phase == "evening"
		or normalized_phase == "night"
	)


func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()

func _play_ui_denied() -> void:
	if ui_denied_sound.stream == null:
		return

	ui_denied_sound.play()

func _play_victory_sound() -> void:
	if victory_sound.stream == null:
		return

	victory_sound.pitch_scale = 1.0
	victory_sound.play()


func _play_defeat_sound() -> void:
	if defeat_sound.stream == null:
		return

	defeat_sound.pitch_scale = 1.0
	defeat_sound.play()


func _fade_out_ambience() -> void:
	if ambience_crossfade_tween != null:
		ambience_crossfade_tween.kill()

	ambience_crossfade_tween = create_tween()
	ambience_crossfade_tween.set_parallel(true)

	ambience_crossfade_tween.tween_property(
		forest_ambience,
		"volume_db",
		-80.0,
		0.6
	)

	ambience_crossfade_tween.tween_property(
		night_ambience,
		"volume_db",
		-80.0,
		0.6
	)

	ambience_crossfade_tween.set_parallel(false)

	ambience_crossfade_tween.tween_callback(
		func() -> void:
			forest_ambience.stop()
			night_ambience.stop()
	)


func _update_ambience(phase: String) -> void:
	var use_night_ambience := (
		phase == "evening"
		or phase == "night"
	)

	var day_volume := -80.0 if use_night_ambience else -22.0
	var night_volume := -21.0 if use_night_ambience else -80.0

	if ambience_crossfade_tween != null:
		ambience_crossfade_tween.kill()

	ambience_crossfade_tween = create_tween()
	ambience_crossfade_tween.set_parallel(true)

	ambience_crossfade_tween.tween_property(
		forest_ambience,
		"volume_db",
		day_volume,
		2.0
	)

	ambience_crossfade_tween.tween_property(
		night_ambience,
		"volume_db",
		night_volume,
		2.0
	)

func _on_backpack_weight_changed(
	current_weight: int,
	maximum_weight: int
) -> void:
	hud.set_backpack_weight(
		current_weight,
		maximum_weight
	)


func _show_backpack_full() -> void:
	_play_ui_denied()

	var player_screen_position := (
		get_viewport().get_canvas_transform()
		* player.global_position
	)

	hud.show_resource_gain(
		"Backpack full — return to camp",
		player_screen_position
	)


func _on_interaction_target_entered(
	target: InteractionTarget
) -> void:
	if game_finished:
		return

	if not target is Camp:
		return

	if backpack.is_empty():
		return

	deposit_camp = target as Camp
	deposit_timer.start()

	hud.show_interaction_prompt(
		"Depositing supplies..."
	)


func _on_interaction_target_exited(
	target: InteractionTarget
) -> void:
	if target != deposit_camp:
		return

	if not deposit_timer.is_stopped():
		deposit_timer.stop()

	deposit_camp = null

	hud.show_resource_gain(
		"Deposit cancelled",
		_get_player_screen_position()
	)

func _on_deposit_timer_timeout() -> void:
	if deposit_camp == null:
		return

	if not is_instance_valid(deposit_camp):
		deposit_camp = null
		return

	if not player_interaction.has_target(
		deposit_camp
	):
		deposit_camp = null
		return

	if backpack.is_empty():
		deposit_camp = null
		return

	var delivered_resources := backpack.take_all()

	for resource_type in delivered_resources:
		var delivered_amount := int(
			delivered_resources[resource_type]
		)

		if delivered_amount <= 0:
			continue

		inventory.add_resource(
			int(resource_type),
			delivered_amount
		)

	hud.show_delivery_summary(
		delivered_resources
	)

	_check_next_camp_stage_affordability()

	if active_camp != null:
		_refresh_camp_menu()

	deposit_camp = null
	player_interaction.refresh_prompt()


func _format_delivery_summary(
	delivered_resources: Dictionary
) -> String:
	var parts := PackedStringArray()

	for resource_type in delivered_resources:
		var amount := int(
			delivered_resources[resource_type]
		)

		if amount <= 0:
			continue

		var resource_name := (
			ResourceTypes.get_display_name(
				int(resource_type)
			)
		)

		parts.append(
			"+%d %s" % [
				amount,
				resource_name
			]
		)

	if parts.is_empty():
		return "No supplies delivered"

	return "Delivered: %s" % ", ".join(parts)


func _get_player_screen_position() -> Vector2:
	return (
		get_viewport().get_canvas_transform()
		* player.global_position
	)
