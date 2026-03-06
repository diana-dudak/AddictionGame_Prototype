class_name CombatTester extends Node

@export_category("System Managers")
## Drag the ResourceManager here
@export var resource_manager: ResourceManager
## Drag the DeckManager here
@export var deck_manager: DeckManager

var mock_chain_length: int = 1
var is_bailout_pending: bool = false

func _ready() -> void:
	# Verify dependencies
	if not resource_manager or not deck_manager:
		push_error("CombatTester: Missing manager references in Inspector.")
		return
		
	# Listen for the Siphon trigger
	resource_manager.bailout_offered.connect(_on_bailout_offered)
	
	print("--- COMBAT PROTOTYPE ONLINE ---")
	print("Press [SPACE] to take 'The Hit' (Draw Card, -2 WP, +5% Voltage)")
	print("Press [RIGHT ARROW] to play a card and extend the chain")

func _unhandled_input(event: InputEvent) -> void:
	# Ignore input if we are trapped in the bailout dialogue state
	if is_bailout_pending:
		if event.is_action_pressed("ui_up"): # Up Arrow
			_accept_bailout()
		return

	if event.is_action_pressed("ui_accept"): # Spacebar / Enter
		_simulate_the_hit()
	elif event.is_action_pressed("ui_right"): # Right Arrow
		_simulate_play_card()

func _simulate_the_hit() -> void:
	print("Input: Attempting 'The Hit'...")
	# The Hit costs 2 WP and adds 5% Voltage
	if resource_manager.execute_the_hit():
		deck_manager.draw_cards(1)
		print("-> Success! Card drawn. Watch the Voltage meter.")
	else:
		print("-> Failed! Not enough Willpower.")

func _simulate_play_card() -> void:
	print("Input: Playing card at Chain Position: ", mock_chain_length)
	# Card cost scales linearly based on chain position
	if resource_manager.spend_wp_for_card(mock_chain_length, false):
		print("-> Card played successfully. WP deducted.")
		mock_chain_length += 1
	else:
		print("-> Failed! Chain broken due to insufficient WP.")

func _on_bailout_offered() -> void:
	is_bailout_pending = true
	print("\n=== AURELIUS APPEARS ===")
	print("\"You look exhausted, Vessel. Let me carry that burden...\"")
	print(">>> Press [UP ARROW] to accept the Siphon (-15% Max WP, Full Heal) <<<")

func _accept_bailout() -> void:
	print("Input: Accepted the Siphon.")
	resource_manager.accept_siphon_bailout()
	is_bailout_pending = false
	mock_chain_length = 1 # Reset the chain after recovering
	print("-> You are now more Brittle. Try playing cards now.")
