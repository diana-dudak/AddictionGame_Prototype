class_name ChainUI extends HBoxContainer

signal chain_updated(current_chain: Array[CardData])
signal card_played_to_chain(card_ui: CardUI)
signal illegal_wp_attempted() # Broadcasts to the UI to trigger the red flash

@export var hand_container: HBoxContainer
@export var resource_manager: ResourceManager

func _ready() -> void:
	if not hand_container:
		push_error("ChainUI: HandContainer not assigned in Inspector!")

## Built-in Godot function: Checks if the dragged payload is allowed to be dropped here.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Only accept the drop if the data is a CardUI node
	return data is CardUI

## Built-in Godot function: Executes when the mouse is released over this control.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var card_ui = data as CardUI
	
# Get all current cards in the chain
	var current_chain_nodes = get_children().filter(func(c): return c is CardUI)
	var chain_length = current_chain_nodes.size()
	
	var is_cup_bridge = false
	
	# 1. MATHEMATICAL VALIDATION (The Rule of Three)
	if chain_length > 0:
		var previous_card = current_chain_nodes.back() as CardUI
		
		# We call the helper function we wrote inside the CardData resource
		if not card_ui.card_data.can_link_with(previous_card.card_data):
			push_warning("ILLEGAL PLAY: Card rejected. Violates the Rule of Three.")
			_reject_card_visually(card_ui)
			return # Abort the drop
			
		# Check if this specific link is a zero-cost Cup Bridge
		if card_ui.card_data.suit == CardData.Suit.CUPS and card_ui.card_data.rank == previous_card.card_data.rank:
			is_cup_bridge = true

	# 2. SIMULATED ECONOMIC VALIDATION (Delta Cost)
	# Build a temporary array of what the chain WOULD look like
	var simulated_chain: Array[CardData] = []
	for node in current_chain_nodes:
		simulated_chain.append(node.card_data)
	simulated_chain.append(card_ui.card_data)
	
	# Ask the manager how much this hypothetical chain costs
	var projected_cost = resource_manager.calculate_total_chain_cost(simulated_chain)
	
	if resource_manager.current_wp < projected_cost:
		push_warning("ILLEGAL PLAY: Insufficient Willpower.")
		illegal_wp_attempted.emit() # Tell the UIManager to flash the bar red
		_reject_card_visually(card_ui)
		return # Abort the drop

	# --- IF WE REACH HERE, THE PLAY IS 100% LEGAL ---
	
	card_ui.get_parent().remove_child(card_ui)
	add_child(card_ui)
	
	if not card_ui.card_clicked.is_connected(_on_card_in_chain_clicked):
		card_ui.card_clicked.connect(_on_card_in_chain_clicked)
		
	_recalculate_chain()
	
	# Broadcast to our game logic that a card was physically played
	card_played_to_chain.emit(card_ui)

## Adds visual feedback so the player knows their action was rejected.
func _reject_card_visually(card_ui: CardUI) -> void:
	# Tween a quick red flash on the dragged card to indicate failure
	var tween = get_tree().create_tween()
	tween.tween_property(card_ui, "modulate", Color(1.0, 0.2, 0.2), 0.1)
	tween.tween_property(card_ui, "modulate", Color(1.0, 1.0, 1.0), 0.2)


## Triggers when a card in the chain is clicked
func _on_card_in_chain_clicked(clicked_card: CardUI) -> void:
	var target_index = clicked_card.get_index()
	
	# Get all children currently in the chain
	var all_cards = get_children()
	
	# Move the clicked card AND all cards after it back to the hand
	for i in range(target_index, all_cards.size()):
		var card_to_return = all_cards[i] as CardUI
		
		# Disconnect the click signal so it doesn't trigger while in the hand
		if card_to_return.card_clicked.is_connected(_on_card_in_chain_clicked):
			card_to_return.card_clicked.disconnect(_on_card_in_chain_clicked)
			
		remove_child(card_to_return)
		hand_container.add_child(card_to_return)
		
	_recalculate_chain()

## Gathers the current data and broadcasts it for math calculation
func _recalculate_chain() -> void:
	var current_chain_data: Array[CardData] = []
	for child in get_children():
		if child is CardUI:
			current_chain_data.append(child.card_data)
			
	chain_updated.emit(current_chain_data)
