class_name Upgrades
extends RefCounted
## Upgrade card pool. Titles and descriptions are player-facing Turkish text.

const POOL := [
	{"id": "fire_rate", "title": "Seri Atış", "desc": "Ateş hızı %20 artar", "icon": "res://assets/icons/fire_rate.png", "max": 8},
	{"id": "damage", "title": "Keskin Uç", "desc": "Hasar %25 artar", "icon": "res://assets/icons/damage.png", "max": 10},
	{"id": "move_speed", "title": "Kanatlı Çizme", "desc": "Hareket hızı %12 artar", "icon": "res://assets/icons/move_speed.png", "max": 5},
	{"id": "max_hp", "title": "Demir Yürek", "desc": "Azami can +25, 40 can yeniler", "icon": "res://assets/icons/max_hp.png", "max": 8},
	{"id": "multishot", "title": "Yelpaze Atış", "desc": "+1 ok, yelpaze şeklinde", "icon": "res://assets/icons/multishot.png", "max": 4},
]


static func roll(count: int, taken: Dictionary) -> Array:
	var avail := []
	for u in POOL:
		if taken.get(u.id, 0) < u.max:
			avail.append(u)
	avail.shuffle()
	return avail.slice(0, count)
