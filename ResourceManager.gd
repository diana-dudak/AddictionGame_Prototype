class_name ResourceManager extends Node

# Signals for UI and State Machine synchronization
signal wp_changed(current_wp: int, max_wp: int)
signal max_wp_clipped(new_max: int)
signal voltage_changed(current_voltage: float)
signal bailout_offered() # Emitted when WP drops below 10

@export_category("Willpower Economy")
@export var base_max_wp: int = 100
var current_max_wp: int
var current_wp: int

@export_category("Short Circuit & Voltage")
var current_voltage: float = 0.0

func _ready() -> void:
	current_max_wp = base_max_wp
	current_wp = current_max_wp
	
	# Initial UI sync
	call_deferred("emit_initial_signals")

func emit_initial_signals() -> void:
	wp_changed.emit(current_wp, current_max_wp)
	voltage_changed.emit(current_voltage)

## Modifies WP and checks for the Siphon bailout threshold.
func modify_wp(amount: int) -> void:
	var old_wp: int = current_wp
	current_wp = clampi(current_wp + amount, 0, current_max_wp)
	
	if current_wp != old_wp:
		wp_changed.emit(current_wp, current_max_wp)
		
	# The Trigger: Aurelius offers a refill if WP drops below 10
	if current_wp < 10 and old_wp >= 10:
		trigger_bailout_offer()

## Calculates the cost of a card based on its position in the chain.
func get_card_cost(chain_position: int, is_cup_bridge: bool = false) -> int:
	# Zero-Cost Flow: Cups used as a same-rank bridge cost 0 WP
	if is_cup_bridge:
		return 0
		
	# Formula: Base (1 WP) + (Position in Chain - 1)
	return 1 + (chain_position - 1)

## Applies the cost of a card play.
func spend_wp_for_card(chain_position: int, is_cup_bridge: bool = false) -> bool:
	var cost: int = get_card_cost(chain_position, is_cup_bridge)
	if current_wp >= cost:
		modify_wp(-cost)
		return true
	return false

## Active Acquisition: "The Hit"
## Spends 2 WP and increases Voltage by 5% to manually draw a card.
func execute_the_hit() -> bool:
	var hit_cost: int = 2
	if current_wp >= hit_cost:
		modify_wp(-hit_cost)
		add_voltage(5.0) # Adds 5% flat Voltage
		return true
	return false

## Adds voltage to the hidden meter, used for Short Circuit calculations.
func add_voltage(amount_percent: float) -> void:
	current_voltage += amount_percent
	voltage_changed.emit(current_voltage)

## Signals the game state that Aurelius is offering a deal.
func trigger_bailout_offer() -> void:
	push_warning("Aurelius Siphon Triggered: Player WP critical (< 10).")
	bailout_offered.emit()

## Accepts Aurelius's bailout. Restores WP but permanently reduces Max WP.
func accept_siphon_bailout() -> void:
	# Permanent Decay: Clips 15% of the player's Max WP
	var penalty: int = int(base_max_wp * 0.15) 
	current_max_wp = max(1, current_max_wp - penalty)
	
	# Restores current WP to 100% of the NEW Max WP
	current_wp = current_max_wp 
	
	max_wp_clipped.emit(current_max_wp)
	wp_changed.emit(current_wp, current_max_wp)
	push_warning("Bailout accepted. Player is now more Brittle. Max WP: ", current_max_wp)
