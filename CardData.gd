class_name CardData extends Resource

# Enums provide strict type safety and auto-completion in the editor
enum Suit { SWORDS, CUPS, WANDS, PENTACLES }

@export var suit: Suit
@export_range(1, 14) var rank: int # 1 = Ace, 11 = Page, 12 = Knight, 13 = Queen, 14 = King

## Helper function to check if this card can legally link to another
func can_link_with(previous_card: CardData) -> bool:
	# The Cup Bridge: Cups bypass the standard rule and can link to any same-rank card
	if self.suit == Suit.CUPS and self.rank == previous_card.rank:
		return true
		
	# Standard Rule of Three: Matches suit OR is adjacent in rank
	var is_same_suit: bool = (self.suit == previous_card.suit)
	var is_adjacent_rank: bool = abs(self.rank - previous_card.rank) == 1
	
	return is_same_suit or is_adjacent_rank
