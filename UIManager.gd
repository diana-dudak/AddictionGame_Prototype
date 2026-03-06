class_name UIManager extends CanvasLayer

@export_category("Logic Dependencies")
@export var resource_manager: ResourceManager
@export var deck_manager: DeckManager
@export var chain_manager: ChainManager

@export_category("UI Elements")
@export var voltage_bar: ProgressBar
@export var projected_wp_bar: ProgressBar
@export var wp_bar: ProgressBar
@export var wp_label: Label
@export var damage_label: Label

@export_category("Card Containers")
@export var hand_container: HBoxContainer
@export var card_scene_template: PackedScene
@export var chain_container: ChainUI

var _blink_tween: Tween
var _last_projected_cost: int = 0

func _ready() -> void:
	# 1. Validate dependencies (Defensive Programming)
	if not resource_manager or not wp_bar or not voltage_bar or not wp_label or not hand_container or not card_scene_template:
		push_error("UIManager: Missing node references. Check the Inspector.")
		return
		
	# 2. Configure Progress Bar base settings
	voltage_bar.min_value = 0.0
	voltage_bar.max_value = 100.0 # Voltage is calculated as a percentage up to 100%
	
	# 3. Connect signals from the ResourceManager to our UI update functions
	resource_manager.wp_changed.connect(_on_wp_changed)
	resource_manager.voltage_changed.connect(_on_voltage_changed)
	resource_manager.max_wp_clipped.connect(_on_max_wp_clipped)
	
	# Note: The initial sync is handled by the deferred signal in ResourceManager._ready()
	if deck_manager: deck_manager.card_drawn.connect(_on_card_drawn)
	
	# Connect the physical chain to the UI display
	if chain_container and chain_manager:
		chain_container.chain_updated.connect(_on_chain_updated)
		chain_container.illegal_wp_attempted.connect(_on_illegal_wp_attempted)

func _on_chain_updated(current_chain: Array[CardData]) -> void:
	var projected_damage = chain_manager.calculate_projected_damage(current_chain)
	
	# Add some horror-themed visual feedback if damage is massive
	if projected_damage > 100:
		damage_label.modulate = Color(1.0, 0.2, 0.2) # Turn red
	else:
		damage_label.modulate = Color(1.0, 1.0, 1.0)
		
	damage_label.text = "Expected Damage: " + str(projected_damage)

## Instantiates a visual card when the logic layer draws one.
func _on_card_drawn(card_data: CardData) -> void:
	if not card_scene_template:
		push_error("UIManager: Card Scene Template is missing!")
		return
		
	var new_card_ui = card_scene_template.instantiate() as CardUI
	hand_container.add_child(new_card_ui)
	
	# Pass the raw data to the visual script so it can format its text
	new_card_ui.setup(card_data)	

## Animates the Willpower bar changing.
func _on_wp_changed(current_wp: int, max_wp: int) -> void:
	wp_bar.max_value = max_wp
	projected_wp_bar.max_value = max_wp
	projected_wp_bar.value = float(current_wp)
	
	# Re-apply any existing projection slice
	_apply_projected_visuals(_last_projected_cost)
	

## Animates the Voltage meter creeping up.
func _on_voltage_changed(current_voltage: float) -> void:
	var tween = get_tree().create_tween()
	
	# Voltage should feel like a slow, threatening build-up
	tween.tween_property(voltage_bar, "value", current_voltage, 0.5)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
		
	# Visual warning if we enter the "Danger Zone" (~50% failure rate)
	if current_voltage >= 50.0:
		voltage_bar.modulate = Color(1.0, 0.0, 0.0) # Turn the bar red
	else:
		voltage_bar.modulate = Color(1.0, 1.0, 1.0) # Keep it normal

## Handles the UI reaction when Aurelius permanently reduces max health.
func _on_max_wp_clipped(new_max: int) -> void:
	# In a horror game, losing max health should be physically obvious.
	# We shrink the maximum value and flash the bar.
	wp_bar.max_value = new_max
	
	# Force an immediate text update when max health drops
	wp_label.text = str(wp_bar.value) + " / " + str(new_max)
	
	var tween = get_tree().create_tween()
	tween.tween_property(wp_bar, "modulate", Color(0.2, 0.2, 0.2), 0.1) # Flash dark
	tween.tween_property(wp_bar, "modulate", Color(1.0, 1.0, 1.0), 0.5) # Fade back to normal

## Rapid red flash for an illegal move
func _on_illegal_wp_attempted() -> void:
	if _blink_tween:
		_blink_tween.kill()
		
	projected_wp_bar.modulate = Color(1.0, 0.0, 0.0, 1.0) # Snap to Red
	
	var flash = get_tree().create_tween()
	flash.tween_property(projected_wp_bar, "modulate:a", 0.2, 0.08)
	flash.tween_property(projected_wp_bar, "modulate:a", 1.0, 0.08)
	flash.set_loops(3) # Blink 3 times rapidly
	
	# When the error flash finishes, return to the normal yellow warning state
	flash.finished.connect(func(): _apply_projected_visuals(_last_projected_cost))

## The core logic for animating the Delta Bar
func _apply_projected_visuals(cost: int) -> void:
	var remaining_wp = resource_manager.current_wp - cost
	
	# Slide the foreground bar down to reveal the projected cost slice
	var tween = get_tree().create_tween()
	tween.tween_property(wp_bar, "value", float(remaining_wp), 0.2).set_trans(Tween.TRANS_SINE)
	
	wp_label.text = str(remaining_wp) + " / " + str(resource_manager.current_max_wp)
	
	# Handle the slow, threatening yellow blink
	if _blink_tween:
		_blink_tween.kill()
		
	if cost > 0:
		projected_wp_bar.modulate = Color(1.0, 0.8, 0.0, 1.0) # Yellow
		_blink_tween = get_tree().create_tween().set_loops()
		_blink_tween.tween_property(projected_wp_bar, "modulate:a", 0.3, 0.6)
		_blink_tween.tween_property(projected_wp_bar, "modulate:a", 1.0, 0.6)
	else:
		projected_wp_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)
