class_name TurnManager
extends Node

signal turn_started(turn_number: int)
signal hand_updated(hand_data: Dictionary) # Slot -> CardData eşleşmesi
signal action_points_changed(remaining: int, max_points: int)
signal enemy_turn_started
signal combat_ended(player_won: bool)

enum CombatState {
	START_BATTLE,
	PLAYER_TURN,
	ENEMY_TURN,
	RESOLVE_EFFECTS,
	BATTLE_OVER
}

@export var equipment_manager: EquipmentManager
@export var player_stats: PlayerStats

var current_state: CombatState = CombatState.START_BATTLE
var current_turn: int = 0
var max_actions_per_turn: int = 2
var remaining_actions: int = 2

# Eldeki 5 kartı yuvalarıyla eşleştirir: { Slot: CardData }
var current_hand: Dictionary = {}

# Savaşı Başlat
func start_combat() -> void:
	current_turn = 0
	current_state = CombatState.START_BATTLE
	if player_stats:
		max_actions_per_turn = player_stats.get_stat(PlayerStats.StatType.ACTION_POINTS)
	start_player_turn()

# Oyuncu Turunu Başlat
func start_player_turn() -> void:
	current_turn += 1
	current_state = CombatState.PLAYER_TURN
	remaining_actions = max_actions_per_turn
	
	if player_stats:
		player_stats.reset_block()
		
	draw_full_hand()
	turn_started.emit(current_turn)
	action_points_changed.emit(remaining_actions, max_actions_per_turn)

# 5 Ekipmanın Her Birinden İlk Kartı Çek
func draw_full_hand() -> void:
	current_hand.clear()
	if equipment_manager == null:
		return
		
	var pools = equipment_manager.get_equipped_card_pools()
	
	for slot in pools.keys():
		var card_list: Array[CardData] = pools[slot]
		if not card_list.is_empty():
			var picked_card = card_list.pick_random()
			if picked_card != null:
				current_hand[slot] = picked_card
				
	hand_updated.emit(current_hand)

# Kart Oynandığında Çalışan Fonksiyon
func play_card(slot: ItemData.EquipmentSlot) -> bool:
	if current_state != CombatState.PLAYER_TURN:
		return false
		
	if remaining_actions <= 0:
		print("Bu tur daha fazla kart oynayamazsın! (Limit: 2)")
		return false
		
	if not current_hand.has(slot) or current_hand[slot] == null:
		return false
		
	var played_card: CardData = current_hand[slot]
	
	# Aksiyon hakkını düş
	remaining_actions -= 1
	action_points_changed.emit(remaining_actions, max_actions_per_turn)
	
	# Oynanan kartın yerine aynı ekipmandan yeni kart çek
	_refill_slot_card(slot, played_card)
	
	hand_updated.emit(current_hand)
	return true

# Oynanan kartın yerine aynı eşyanın kalan kartlarından birini getirme
func _refill_slot_card(slot: ItemData.EquipmentSlot, last_played_card: CardData) -> void:
	var pools = equipment_manager.get_equipped_card_pools()
	var card_list: Array[CardData] = pools.get(slot, [])
	
	if card_list.is_empty():
		current_hand.erase(slot)
		return
		
	# Eğer eşyada birden fazla kart varsa, az önce oynanan dışındakilerden seç
	var available_cards: Array[CardData] = []
	for card in card_list:
		if card != last_played_card:
			available_cards.append(card)
			
	if available_cards.is_empty():
		available_cards = card_list
		
	current_hand[slot] = available_cards.pick_random()

# Oyuncu Turu Bitir Düğmesine Bastığında
func end_player_turn() -> void:
	if current_state != CombatState.PLAYER_TURN:
		return
		
	current_state = CombatState.ENEMY_TURN
	current_hand.clear()
	hand_updated.emit(current_hand)
	enemy_turn_started.emit()

func end_combat(player_won: bool) -> void:
	current_state = CombatState.BATTLE_OVER
	combat_ended.emit(player_won)
