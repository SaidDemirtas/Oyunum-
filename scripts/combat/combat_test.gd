extends Control
## ADIM 1 - Savaş Prototipi
## Mevcut TurnManager, EquipmentManager, EnemyAI, CombatCalculator sınıflarını
## birbirine bağlar. Arayüz kodla kurulur, sahnede ekstra düğüm gerekmez.
## Test eşyaları ve kartları kodda üretilir (ileride LootGenerator ile değişecek).

const SLOT_NAMES := {
	ItemData.EquipmentSlot.HELMET: "Kask",
	ItemData.EquipmentSlot.ARMOR: "Zırh",
	ItemData.EquipmentSlot.WEAPON: "Silah",
	ItemData.EquipmentSlot.NECKLACE: "Kolye",
	ItemData.EquipmentSlot.BOOTS: "Ayakkabı"
}

var stats: PlayerStats
var equipment: EquipmentManager
var turn_manager: TurnManager
var enemy_ai: EnemyAI
var enemy_data: EnemyData

var enemy_hp: int = 0
var enemy_block: int = 0
var battle_over: bool = false

var player_label: Label
var enemy_label: Label
var intent_label: Label
var ap_label: Label
var log_label: Label
var hand_box: HBoxContainer
var end_turn_button: Button
var restart_button: Button
var log_lines: PackedStringArray = []


func _ready() -> void:
	_build_ui()
	_start_battle()


# ---------------------------------------------------------------
# ARAYÜZ (kodla kurulur)
# ---------------------------------------------------------------
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	enemy_label = _make_label(26)
	root.add_child(enemy_label)

	intent_label = _make_label(22)
	root.add_child(intent_label)

	log_label = _make_label(18)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(log_label)

	player_label = _make_label(26)
	root.add_child(player_label)

	ap_label = _make_label(22)
	root.add_child(ap_label)

	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 10)
	root.add_child(hand_box)

	end_turn_button = Button.new()
	end_turn_button.text = "Turu Bitir"
	end_turn_button.custom_minimum_size = Vector2(0, 50)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	root.add_child(end_turn_button)

	restart_button = Button.new()
	restart_button.text = "Yeniden Başla"
	restart_button.custom_minimum_size = Vector2(0, 50)
	restart_button.visible = false
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())
	root.add_child(restart_button)


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	return label


# ---------------------------------------------------------------
# SAVAŞ KURULUMU
# ---------------------------------------------------------------
func _start_battle() -> void:
	# 1) Oyuncu statları
	stats = PlayerStats.new()
	stats.health_depleted.connect(_on_player_died)

	# 2) Ekipman yöneticisi ve test eşyaları
	equipment = EquipmentManager.new()
	equipment.player_stats = stats
	add_child(equipment)
	_equip_test_items()
	stats.current_hp = stats.get_stat(PlayerStats.StatType.MAX_HP)

	# 3) Tur yöneticisi
	turn_manager = TurnManager.new()
	turn_manager.equipment_manager = equipment
	turn_manager.player_stats = stats
	add_child(turn_manager)
	turn_manager.hand_updated.connect(_on_hand_updated)
	turn_manager.action_points_changed.connect(_on_ap_changed)
	turn_manager.enemy_turn_started.connect(_on_enemy_turn)
	turn_manager.turn_started.connect(_on_turn_started)

	# 4) Düşman
	enemy_data = EnemyData.new()
	enemy_data.enemy_name = "Goblin Gözcü"
	enemy_data.max_hp = 40
	enemy_hp = enemy_data.max_hp
	enemy_ai = EnemyAI.new()
	add_child(enemy_ai)
	enemy_ai.intent_determined.connect(_on_intent)
	enemy_ai.action_executed.connect(_on_enemy_action)
	enemy_ai.setup(enemy_data)

	# 5) Arayüz güncellemesi ve savaşı başlat
	stats.stats_changed.connect(_refresh_ui)
	_refresh_ui()
	turn_manager.start_combat()


func _equip_test_items() -> void:
	var weapon_cards: Array[CardData] = []
	weapon_cards.append(_make_card("Vuruş", CardData.CardType.ATTACK, 6, 0, 0, 0.0))
	weapon_cards.append(_make_card("Ağır Vuruş", CardData.CardType.ATTACK, 14, 0, 0, 0.1))
	equipment.equip_item(_make_item("Test Kılıcı", ItemData.EquipmentSlot.WEAPON, weapon_cards, 0))

	var armor_cards: Array[CardData] = []
	armor_cards.append(_make_card("Siper", CardData.CardType.DEFENSE, 0, 8, 0, 0.0))
	armor_cards.append(_make_card("Demir Kapı", CardData.CardType.DEFENSE, 0, 12, 2, 0.0))
	equipment.equip_item(_make_item("Test Zırhı", ItemData.EquipmentSlot.ARMOR, armor_cards, 10))

	var helmet_cards: Array[CardData] = []
	helmet_cards.append(_make_card("Kafa Atma", CardData.CardType.ATTACK, 4, 0, 0, 0.0))
	helmet_cards.append(_make_card("Küçük Kalkan", CardData.CardType.DEFENSE, 0, 5, 0, 0.0))
	equipment.equip_item(_make_item("Test Kaskı", ItemData.EquipmentSlot.HELMET, helmet_cards, 0))

	var necklace_cards: Array[CardData] = []
	necklace_cards.append(_make_card("Şifa", CardData.CardType.SKILL, 0, 0, 6, 0.0))
	equipment.equip_item(_make_item("Test Kolyesi", ItemData.EquipmentSlot.NECKLACE, necklace_cards, 0))

	var boots_cards: Array[CardData] = []
	boots_cards.append(_make_card("Seri Adım", CardData.CardType.DEFENSE, 0, 4, 0, 0.0))
	equipment.equip_item(_make_item("Test Çizmesi", ItemData.EquipmentSlot.BOOTS, boots_cards, 0))


func _make_item(item_name: String, slot: ItemData.EquipmentSlot, cards: Array[CardData], bonus_hp: int) -> ItemData:
	var item := ItemData.new()
	item.item_name = item_name
	item.slot_type = slot
	item.bonus_max_hp = bonus_hp
	item.card_pool = cards
	return item


func _make_card(card_name: String, type: CardData.CardType, damage: int, shield: int, heal: int, lifesteal: float) -> CardData:
	var card := CardData.new()
	card.card_name = card_name
	card.type = type
	card.base_damage = damage
	card.base_shield = shield
	card.base_heal = heal
	card.apply_lifesteal = lifesteal
	return card


# ---------------------------------------------------------------
# OYUNCU TURU
# ---------------------------------------------------------------
func _on_turn_started(turn_number: int) -> void:
	_log("--- Tur %d ---" % turn_number)


func _on_hand_updated(hand: Dictionary) -> void:
	for child in hand_box.get_children():
		child.queue_free()

	for slot in hand.keys():
		var card: CardData = hand[slot]
		if card == null:
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 150)
		button.text = "%s\n[%s]\n%s" % [card.card_name, SLOT_NAMES[slot], _card_summary(card)]
		button.disabled = battle_over
		button.pressed.connect(_on_card_pressed.bind(slot))
		hand_box.add_child(button)


func _card_summary(card: CardData) -> String:
	var parts: PackedStringArray = []
	if card.base_damage > 0:
		parts.append("Hasar %d" % card.base_damage)
	if card.base_shield > 0:
		parts.append("Kalkan %d" % card.base_shield)
	if card.base_heal > 0:
		parts.append("Can +%d" % card.base_heal)
	return "\n".join(parts)


func _on_ap_changed(remaining: int, max_points: int) -> void:
	ap_label.text = "Aksiyon hakkı: %d / %d" % [remaining, max_points]


func _on_card_pressed(slot: int) -> void:
	if battle_over:
		return
	var card: CardData = turn_manager.current_hand.get(slot)
	if card == null:
		return
	if not turn_manager.play_card(slot):
		_log("Bu tur daha fazla kart oynayamazsın.")
		return
	_apply_card(card)
	_refresh_ui()


func _apply_card(card: CardData) -> void:
	_log("Oynadın: %s" % card.card_name)

	if card.base_damage > 0:
		var damage := CombatCalculator.calculate_player_attack(card.base_damage, stats)
		_damage_enemy(damage)
		_log("  Düşmana %d hasar verdin." % damage)
		if card.apply_lifesteal > 0.0:
			var stolen := roundi(damage * card.apply_lifesteal)
			if stolen > 0:
				stats.heal(stolen)
				_log("  Can çalma: +%d can." % stolen)

	if card.base_shield > 0:
		stats.add_block(card.base_shield)
		_log("  +%d kalkan." % card.base_shield)

	if card.base_heal > 0:
		stats.heal(card.base_heal)
		_log("  +%d can." % card.base_heal)


func _damage_enemy(amount: int) -> void:
	var remaining := amount
	if enemy_block > 0:
		var absorbed := mini(enemy_block, remaining)
		enemy_block -= absorbed
		remaining -= absorbed
	enemy_hp = maxi(0, enemy_hp - remaining)
	if enemy_hp <= 0:
		_end_battle(true)


func _on_end_turn_pressed() -> void:
	if battle_over:
		return
	turn_manager.end_player_turn()


# ---------------------------------------------------------------
# DÜŞMAN TURU
# ---------------------------------------------------------------
func _on_enemy_turn() -> void:
	if battle_over:
		return
	enemy_block = 0
	_refresh_ui()
	await get_tree().create_timer(0.6).timeout
	if battle_over:
		return
	enemy_ai.execute_turn()
	if battle_over:
		return
	turn_manager.start_player_turn()


func _on_intent(intent: EnemyData.ActionIntent, value: int) -> void:
	match intent:
		EnemyData.ActionIntent.ATTACK:
			intent_label.text = "Düşman niyeti: SALDIRI (%d hasar)" % value
		EnemyData.ActionIntent.DEFEND:
			intent_label.text = "Düşman niyeti: SAVUNMA (+%d kalkan)" % value
		_:
			intent_label.text = "Düşman niyeti: ???"


func _on_enemy_action(intent: EnemyData.ActionIntent, value: int) -> void:
	match intent:
		EnemyData.ActionIntent.ATTACK:
			var damage := CombatCalculator.calculate_enemy_attack(value, stats)
			if damage < 0:
				_log("%s saldırdı ama sen kaçındın!" % enemy_data.enemy_name)
			else:
				_log("%s sana %d hasar vurdu." % [enemy_data.enemy_name, damage])
				stats.take_damage(damage)
		EnemyData.ActionIntent.DEFEND:
			enemy_block += value
			_log("%s +%d kalkan kazandı." % [enemy_data.enemy_name, value])
		_:
			_log("%s bir şey yapmadı." % enemy_data.enemy_name)
	_refresh_ui()


# ---------------------------------------------------------------
# SAVAŞ SONU
# ---------------------------------------------------------------
func _on_player_died() -> void:
	_end_battle(false)


func _end_battle(player_won: bool) -> void:
	if battle_over:
		return
	battle_over = true
	turn_manager.end_combat(player_won)
	end_turn_button.disabled = true
	restart_button.visible = true
	for button in hand_box.get_children():
		if button is Button:
			button.disabled = true
	if player_won:
		_log("*** ZAFER! Düşmanı yendin. ***")
	else:
		_log("*** YENİLDİN. ***")
	_refresh_ui()


# ---------------------------------------------------------------
# ARAYÜZ GÜNCELLEME
# ---------------------------------------------------------------
func _refresh_ui() -> void:
	if enemy_data == null or stats == null:
		return
	enemy_label.text = "%s   Can: %d / %d   Kalkan: %d" % [enemy_data.enemy_name, enemy_hp, enemy_data.max_hp, enemy_block]
	player_label.text = "Sen   Can: %d / %d   Kalkan: %d" % [stats.current_hp, stats.get_stat(PlayerStats.StatType.MAX_HP), stats.current_block]


func _log(text: String) -> void:
	log_lines.append(text)
	while log_lines.size() > 10:
		log_lines.remove_at(0)
	log_label.text = "\n".join(log_lines)
