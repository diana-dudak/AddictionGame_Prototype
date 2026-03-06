class_name ChainUI extends HBoxContainer

signal card_played_to_chain(card_ui: CardUI)

## Built-in Godot function: Checks if the dragged payload is allowed to be dropped here.
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Only accept the drop if the data is a CardUI node
	return data is CardUI

## Built-in Godot function: Executes when the mouse is released over this control.
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var card_ui = data as CardUI
	
	# Remove the card from the HandContainer
	card_ui.get_parent().remove_child(card_ui)
	
	# Add it to this ChainContainer
	add_child(card_ui)
	
	# Broadcast to our game logic that a card was physically played
	card_played_to_chain.emit(card_ui)
