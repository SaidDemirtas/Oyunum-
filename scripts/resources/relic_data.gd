class_name RelicData
extends Resource

enum TriggerEvent {
	BATTLE_START,     # Savaş başında tetiklenir (Örn: +5 Kalkanla başla)
	TURN_START,       # Her tur başında tetiklenir (Örn: +1 Enerji/Kart hakkı)
	ON_ATTACK,        # Saldırı kartı oynanınca tetiklenir
	ON_TAKE_DAMAGE,   # Hasar alındığında tetiklenir (Örn: Düşmana diken hasarı)
	BATTLE_END        # Savaş bitince tetiklenir (Örn: Fazladan altın/can yenileme)
}

@export_group("Kalıntı Bilgileri")
@export var relic_name: String = "New Relic"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Tetiklenme ve Etki")
@export var trigger_event: TriggerEvent = TriggerEvent.BATTLE_START
@export var effect_value: int = 5
