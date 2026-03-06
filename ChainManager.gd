class_name ChainManager extends Node

## Calculates expected damage based on the GDD formula
func calculate_projected_damage(chain: Array[CardData]) -> int:
	if chain.is_empty():
		return 0
		
	var sum_ranks: int = 0
	## Total multiplier from all sources, for now only from wands
	var final_multiplier: float = 1.0
	var wand_multiplier: float = 1.0
	
	var sword_bonus: int = 0
	
	for card in chain:
		sum_ranks += card.rank
		
		# Apply specific suit logic
		if card.suit == CardData.Suit.WANDS:
			wand_multiplier *= 1.5 # Wands act as an exponential multiplier
		elif card.suit == CardData.Suit.SWORDS:
			sword_bonus += 5 # Swords add flat raw damage
	
	final_multiplier = wand_multiplier
	var base_damage = (sum_ranks + sword_bonus) * chain.size()
	var final_damage = int(base_damage * final_multiplier)
	
	return final_damage
