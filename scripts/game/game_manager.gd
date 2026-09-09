class_name GameManager
extends Node2D

enum TutorialStep {
	WAITING,
	MOVEMENT,
	GATHERING,
	BACKPACK,
	RETURN_TO_CAMP,
	CONSTRUCTION,
	COMPLETE
}

const TUTORIAL_CONFIG_PATH := (
	"user://tutorial_settings.cfg"
)

const TUTORIAL_CONFIG_SECTION := "tutorial"

const CONTEXTUAL_TUTORIAL_COMPLETED_KEY := (
	"contextual_tutorial_completed"
)


@export_category("Tutorial")
@export var tutorial_enabled := true
@export_range(8.0, 128.0, 1.0) var tutorial_movement_distance := 48.0
@export_range(1, 12, 1) var tutorial_return_weight := 6 #The tutorial starts at 6 kg

var tutorial_step := TutorialStep.WAITING
var tutorial_start_position := Vector2.ZERO

@export_category("Hunger")

@export_range(1.0, 200.0, 1.0)
var maximum_hunger := 100.0

@export_range(1.0, 200.0, 1.0)
var starting_hunger := 100.0

@export_range(0.1, 5.0, 0.1)
var hunger_decrease_per_second := 1.0

@export_range(1.0, 100.0, 1.0)
var food_hunger_restoration := 80.0

@export_range(0.0, 100.0, 1.0)
var maximum_hunger_for_eating := 85.0


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

@onready var world_generator: WorldGenerator = $World

@onready var player_camera: Camera2D = (
	$Entities/Player/PlayerCamera
)

@onready var main_menu: MainMenu = (
	$Interface/MainMenu
)
@onready var forest_life: ForestLife = (
	$World/ForestLife
)

@onready var player_animation: PlayerAnimation = (
	$Entities/Player/PlayerVisual
)

@onready var backpack_view: BackpackView = (
	$Interface/BackpackView
)

var ambience_crossfade_tween: Tween

var world_tint_tween: Tween

var game_finished: bool = false
var active_camp: Camp
var deposit_camp: Camp

var next_camp_stage_was_affordable := false

var current_hunger := 100.0
var low_hunger_warning_shown := false
var critical_hunger_warning_shown := false

func _ready() -> void:
	_configure_world_layout()
	current_hunger = clampf(
		starting_hunger,
		0.0,
		maximum_hunger
	)
	main_menu.visibility_changed.connect(
		_on_main_menu_visibility_changed
	)
	
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
	backpack.resource_changed.connect(
		_on_backpack_resource_changed
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

	backpack_view.view_closed.connect(
		_on_backpack_view_closed
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
			
			if (
				resource_type == ResourceTypes.Type.FOOD
				and current_hunger < maximum_hunger_for_eating
			):
				hud.show_tutorial_hint(
					"Press F to eat carried Food and restore Hunger."
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
			
			if tutorial_step == TutorialStep.GATHERING:
				_set_tutorial_step(
				TutorialStep.BACKPACK
			)

			var resource_name := (
				ResourceTypes.get_display_name(
					resource_type
				)
			)

			var player_screen_position := (
				get_viewport().get_canvas_transform()
				* player.global_position
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
	hud.set_hunger(
		current_hunger,
		maximum_hunger
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
	if current_hunger < maximum_hunger_for_eating:
		camp_menu.show_message(
			"Press F to eat Food from storage"
		)


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
	
	if tutorial_step == TutorialStep.CONSTRUCTION:
		_set_tutorial_step(TutorialStep.COMPLETE)
	
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
	forest_life.set_phase(phase)
	_update_world_tint(phase)


func _on_day_ended(day: int) -> void:
	if game_finished:
		return



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
	if (tutorial_step == TutorialStep.BACKPACK
		and current_weight >= tutorial_return_weight
	):
		_set_tutorial_step(	TutorialStep.RETURN_TO_CAMP	)


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
	
	if (tutorial_step == TutorialStep.BACKPACK
		or tutorial_step == TutorialStep.RETURN_TO_CAMP
	):
		_set_tutorial_step(
			TutorialStep.CONSTRUCTION
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


func _configure_world_layout() -> void:
	var world_size := Vector2(
		world_generator.map_width
			* world_generator.tile_size,
		world_generator.map_height
			* world_generator.tile_size
	)

	var world_center := world_size / 2.0

	camp.global_position = world_center

	player.global_position = (
		world_center + Vector2(0.0, 88.0)
	)

	player.minimum_position = Vector2(
		10.0,
		64.0
	)

	player.maximum_position = Vector2(
		world_size.x - 10.0,
		world_size.y - 10.0
	)

	player_camera.limit_left = 0
	player_camera.limit_top = 0
	player_camera.limit_right = roundi(world_size.x)
	player_camera.limit_bottom = roundi(world_size.y)

func _on_main_menu_visibility_changed() -> void:
	if main_menu.visible:
		return

	if not tutorial_enabled:
		tutorial_step = TutorialStep.COMPLETE
		hud.hide_tutorial_hint()
		return

	if tutorial_step != TutorialStep.WAITING:
		return

	if _was_contextual_tutorial_completed():
		tutorial_step = TutorialStep.COMPLETE
		hud.hide_tutorial_hint()
		return

	tutorial_start_position = player.global_position

	_set_tutorial_step(
		TutorialStep.MOVEMENT
	)


func _set_tutorial_step(
	new_step: TutorialStep
) -> void:
	tutorial_step = new_step

	match tutorial_step:
		TutorialStep.MOVEMENT:
			hud.show_tutorial_hint(
				"Use WASD or the arrow keys to explore."
			)

		TutorialStep.GATHERING:
			hud.show_tutorial_hint(
				"Approach a resource and hold E to gather."
			)

		TutorialStep.BACKPACK:
			hud.show_tutorial_hint(
				"Resources have weight. Your backpack can carry 12 kg."
			)

		TutorialStep.RETURN_TO_CAMP:
			hud.show_tutorial_hint(
				"Your backpack is getting heavy. Return to camp."
			)

		TutorialStep.CONSTRUCTION:
			hud.show_tutorial_hint(
				"Use deposited resources to build the cabin before winter."
			)

		TutorialStep.COMPLETE:
			hud.hide_tutorial_hint()
			_save_contextual_tutorial_completed()


func _process(delta: float) -> void:
	_update_hunger(delta)
	_update_movement_tutorial()

func _was_contextual_tutorial_completed() -> bool:
	var config := ConfigFile.new()

	if config.load(TUTORIAL_CONFIG_PATH) != OK:
		return false

	return bool(
		config.get_value(
			TUTORIAL_CONFIG_SECTION,
			CONTEXTUAL_TUTORIAL_COMPLETED_KEY,
			false
		)
	)

func _save_contextual_tutorial_completed() -> void:
	var config := ConfigFile.new()

	config.load(TUTORIAL_CONFIG_PATH)

	config.set_value(
		TUTORIAL_CONFIG_SECTION,
		CONTEXTUAL_TUTORIAL_COMPLETED_KEY,
		true
	)

	var save_result := config.save(
		TUTORIAL_CONFIG_PATH
	)

	if save_result != OK:
		push_warning(
			"Could not save tutorial completion."

		)

func _update_hunger(delta: float) -> void:
	if game_finished:
		return

	if not day_cycle.running:
		return

	current_hunger = maxf(
		current_hunger
			- hunger_decrease_per_second * delta,
		0.0
	)

	hud.set_hunger(
		current_hunger,
		maximum_hunger
	)

	_check_hunger_warnings()

	if current_hunger <= 0.0:
		_finish_game(
			"Defeat",
			"You collapsed from hunger before the cabin was complete."
		)

func _update_movement_tutorial() -> void:
	if tutorial_step != TutorialStep.MOVEMENT:
		return

	var distance_moved := (
		player.global_position.distance_to(
			tutorial_start_position
		)
	)

	if distance_moved < tutorial_movement_distance:
		return

	_set_tutorial_step(
		TutorialStep.GATHERING
	)

func _check_hunger_warnings() -> void:
	var hunger_ratio := (
		current_hunger / maximum_hunger
	)

	if (
		hunger_ratio <= 0.30
		and not critical_hunger_warning_shown
	):
		critical_hunger_warning_shown = true

		hud.show_milestone(
			"STARVING!\nEAT FOOD SOON"
		)

		return

	if (
		hunger_ratio <= 0.60
		and not low_hunger_warning_shown
	):
		low_hunger_warning_shown = true

		hud.show_milestone(
			"YOU ARE GETTING HUNGRY\nPRESS F TO EAT"
		)

func _unhandled_input(
	event: InputEvent
) -> void:
	if event.is_echo():
		return

	if backpack_view.visible:
		if backpack_view.is_closing:
			get_viewport().set_input_as_handled()
			return
			
		if (
			event.is_action_pressed(
				"toggle_backpack"
			)
			or event.is_action_pressed("ui_cancel")
		):
			_close_backpack_view()
			get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("eat_food"):
			_try_eat_food()
			_refresh_backpack_view()

			get_viewport().set_input_as_handled()
			return

		return

	if event.is_action_pressed(
		"toggle_backpack"
	):
		_open_backpack_view()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("eat_food"):
		_try_eat_food()
		get_viewport().set_input_as_handled()

func _try_eat_food() -> void:
	if game_finished:
		return

	var camp_menu_is_open := (
		is_instance_valid(active_camp)
		and camp_menu.visible
	)

	var backpack_view_is_open := (
		backpack_view.visible
	)

	if (
		not day_cycle.running
		and not camp_menu_is_open
		and not backpack_view_is_open
	):
		return

	if current_hunger >= maximum_hunger_for_eating:
		_play_ui_denied()

		hud.show_resource_gain(
			"You are not hungry enough",
			_get_player_screen_position()
		)

		return

	var food_type := ResourceTypes.Type.FOOD
	var food_source := ""

	# Carried food can be eaten anywhere.
	if backpack.remove_resource(
		food_type,
		1
	):
		food_source = "backpack"

	# Camp storage can only be used while standing near camp.
	elif (
		(
			player_interaction.has_target(camp)
			or camp_menu_is_open
		)
		and inventory.remove_resource(food_type, 1)
	):
		food_source = "camp"

	if food_source.is_empty():
		_play_ui_denied()

		if player_interaction.has_target(camp):
			hud.show_resource_gain(
				"No Food available",
				_get_player_screen_position()
			)
		else:
			hud.show_resource_gain(
				"No Food in backpack",
				_get_player_screen_position()
			)

		return

	var previous_hunger := current_hunger

	current_hunger = minf(
		current_hunger + food_hunger_restoration,
		maximum_hunger
	)

	var restored_hunger := (
		current_hunger - previous_hunger
	)

	hud.set_hunger(
		current_hunger,
		maximum_hunger
	)

	_reset_hunger_warnings()
	
	player_animation.play_eating_feedback()
	hud.play_hunger_gain_feedback()
	
	if tutorial_step == TutorialStep.COMPLETE:
		hud.hide_tutorial_hint()

	var source_text := (
		"Backpack"
		if food_source == "backpack"
		else "Camp storage"
	)

	hud.show_resource_gain(
		"+%d Hunger · %s" % [
			roundi(restored_hunger),
			source_text
		],
		_get_player_screen_position()
	)

	_play_ui_click()

func _reset_hunger_warnings() -> void:
	var hunger_ratio := (
		current_hunger / maximum_hunger
	)

	if hunger_ratio > 0.60:
		low_hunger_warning_shown = false

	if hunger_ratio > 0.30:
		critical_hunger_warning_shown = false

func _refresh_backpack_view() -> void:
	if not backpack_view.visible:
		return

	backpack_view.refresh(
		backpack.get_all_resources(),
		backpack.get_current_weight(),
		backpack.maximum_weight
	)


func _on_backpack_resource_changed(
	_resource_type: int,
	_new_amount: int
) -> void:
	_refresh_backpack_view()


func _open_backpack_view() -> void:
	if game_finished:
		return

	if camp_menu.visible:
		return

	if main_menu.visible:
		return

	player.set_movement_enabled(false)

	player_interaction.set_process_unhandled_input(
		false
	)

	day_cycle.set_running(false)
	hud.hide_interaction_prompt()
	hud.hide()

	backpack_view.open_view(
		backpack.get_all_resources(),
		backpack.get_current_weight(),
		backpack.maximum_weight
	)


func _close_backpack_view() -> void:
	if not backpack_view.visible:
		return

	backpack_view.close_view()

func _on_backpack_view_closed() -> void:
	if game_finished:
		return

	hud.show()

	player.set_movement_enabled(true)

	player_interaction.set_process_unhandled_input(
		true
	)

	player_interaction.refresh_prompt()
	day_cycle.set_running(true)
