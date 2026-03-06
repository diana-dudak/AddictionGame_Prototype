class_name DeckManager extends Node

signal hand_updated(current_hand: Array[CardData])
signal card_drawn(card: CardData)
signal deck_empty()

const MAX_HAND_SIZE: int = 7 # Hard cap to prevent hoarding
const BASE_DRAW_AMOUNT: int = 5 # Standard turn replenishment

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []

func _ready() -> void:
	_generate_initial_deck()
	draw_cards(BASE_DRAW_AMOUNT)

## Generates the starting 28-card deck from 2 random suits.
func _generate_initial_deck() -> void:
	var available_suits = [CardData.Suit.SWORDS, CardData.Suit.CUPS, CardData.Suit.WANDS, CardData.Suit.PENTACLES]
	available_suits.shuffle()
	
	# Pick the first two suits after shuffling
	var selected_suits = [available_suits[0], available_suits[1]]
	
	for suit in selected_suits:
		for rank in range(1, 15): # Ranks 1 through 14
			var new_card = CardData.new()
			new_card.suit = suit
			new_card.rank = rank
			draw_pile.append(new_card)
			
	draw_pile.shuffle()
	push_warning("Deck generated with 28 cards. Selected suits: ", selected_suits)

## Handles drawing cards, respecting the hard cap.
func draw_cards(amount: int) -> void:
	for i in range(amount):
		if hand.size() >= MAX_HAND_SIZE:
			push_warning("Hand is full. Cannot draw more cards.")
			break
			
		if draw_pile.is_empty():
			_shuffle_discard_into_deck()
			if draw_pile.is_empty():
				deck_empty.emit()
				return # No cards left at all
				
		var drawn_card: CardData = draw_pile.pop_back()
		hand.append(drawn_card)
		card_drawn.emit(drawn_card)
		
	hand_updated.emit(hand)

## Recycles the discard pile when the draw pile is depleted.
func _shuffle_discard_into_deck() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	draw_pile.shuffle()
	push_warning("Discard pile shuffled into draw pile.")
