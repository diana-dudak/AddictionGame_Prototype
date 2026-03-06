class_name UIManager extends CanvasLayer

@export_category("Logic Dependencies")
## Drag the ResourceManager node from your scene tree into this slot in the inspector
@export var resource_manager: ResourceManager
## Drag your DeckManager here
@export var deck_manager: DeckManager

@export_category("UI Elements")
## Drag the WillpowerBar node here$WillpowerBar
@export var wp_bar: ProgressBar
## Drag the VoltageMeter node here
@export var voltage_bar: ProgressBar

@export_category("UI Labels")
## Drag the WPText (Label) node here in the Inspector
@export var wp_label: Label

@export_category("Card Containers")
## Drag the HandContainer here
@export var hand_container: HBoxContainer
## Drag your newly created CardUI.tscn from the FileSystem here
@export var card_scene_template: PackedScene

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
	if deck_manager:
		deck_manager.card_drawn.connect(_on_card_drawn)
		
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
	
	# Update the exact numbers on our custom label
	wp_label.text = str(current_wp) + " / " + str(max_wp)
	
	# Kill any existing animations on the bar to prevent stuttering
	var tween = get_tree().create_tween()
	
	# If we took damage, snap quickly. If we healed, fill smoothly.
	var duration = 0.15 if current_wp < wp_bar.value else 0.4
	
	tween.tween_property(wp_bar, "value", float(current_wp), duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

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
