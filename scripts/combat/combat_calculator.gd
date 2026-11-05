class_name CombatCalculator
extends RefCounted

# Oyuncunun vuracağı hasarı hesaplar (Güç bonusu ve Kritik şansı eklenir)
static func calculate_player_attack(base_damage: int, player_stats: PlayerStats) -> int:
	if player_stats == null:
		return base_damage
		
	var strength = player_stats.get_stat(PlayerStats.StatType.STRENGTH)
	var crit_rate = player_stats.get_stat(PlayerStats.StatType.CRIT_RATE)
	var crit_mult = player_stats.get_stat(PlayerStats.StatType.CRIT_DAMAGE) / 100.0
	
	var final_damage = base_damage + strength
	
	# Kritik Vuruş Zarı (0-100 arası rastgele sayı)
	if (randf() * 100.0) <= crit_rate:
		final_damage = int(final_damage * crit_mult)
		print("Kritik Vuruş! Toplam Hasar: ", final_damage)
		
	return final_damage

# Düşmanın saldırısını hesaplar (Kaçınma kontrolü yapar)
# -1 dönerse oyuncu saldırıdan başarıyla kaçınmış (Dodge) demektir.
static func calculate_enemy_attack(enemy_damage: int, player_stats: PlayerStats) -> int:
	if player_stats == null:
		return enemy_damage
		
	# Her Çeviklik (Agility) puanı %2 Kaçınma şansı versin
	var dodge_chance = player_stats.get_stat(PlayerStats.StatType.AGILITY) * 2.0
	
	# Kaçınma Zarı
	if (randf() * 100.0) <= dodge_chance:
		print("Düşman saldırısından kaçınıldı! (Dodge)")
		return -1 
		
	return enemy_damage
