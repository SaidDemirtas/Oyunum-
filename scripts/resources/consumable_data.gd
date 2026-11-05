class_name ConsumableData
extends ItemData

enum ConsumableType {
	HEALTH_POTION,      # Savaşta veya haritada can basar
	UPGRADE_STONE,      # Eşyalara + basmaya yarayan taş
	ENCHANT_ORB,        # Eşyanın efsununu değiştiren küre
	RARITY_CHANGER,     # Eşyanın nadirliğini değiştiren/yükselten taş
	BUFF_POTION         # Geçici güçlendirme veren iksir
}

@export_group("Tüketim Özellikleri")
@export var item_type: ConsumableType = ConsumableType.HEALTH_POTION
@export var effect_value: int = 15       # İyileştirme miktarı, buff süresi vb.
@export var success_rate: float = 1.0    # Başarı şansı (Örn: %70 artı basma için 0.7)
@export var is_usable_in_combat: bool = true
@export var max_stack_size: int = 10     # Çantada tek slotta kaç adet üst üste binebilir?
