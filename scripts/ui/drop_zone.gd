class_name DropZone
extends Control

signal card_played_on_target(card: CardData, target: ZoneType)

enum ZoneType {
	PLAYER,
	ENEMY
}

@export var zone_type: ZoneType = ZoneType.ENEMY

# Sürüklenen öğe bu alanın üzerine geldiğinde bırakılabilir mi?
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("source") and data["source"] == "combat_card":
		var card: CardData = data["card_data"]
		
		# Orijinal TargetType (SINGLE_ENEMY, ALL_ENEMIES, SELF) sistemine göre kontrol
		if (card.target_type == CardData.TargetType.SINGLE_ENEMY or card.target_type == CardData.TargetType.ALL_ENEMIES) and zone_type == ZoneType.ENEMY:
			return true
		elif card.target_type == CardData.TargetType.SELF and zone_type == ZoneType.PLAYER:
			return true
			
	return false 

# Eğer _can_drop_data "true" döndürdüyse ve fare bırakıldıysa burası çalışır
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var card: CardData = data["card_data"]
	print(card.card_name, " kartı ", ZoneType.keys()[zone_type], " hedefine oynandı!")
	
	card_played_on_target.emit(card, zone_type)
	
	
	
