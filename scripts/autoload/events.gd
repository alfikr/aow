extends Node
## Bus sinyal global; sistem saling berbicara lewat sini, bukan referensi langsung.

signal message(text: String)
signal day_ended(passed_out: bool)
signal day_started(passed_out: bool)
signal season_changed(season: int)
signal game_loaded
signal open_shop

## Dipakai agar pemain tidak bergerak saat menu terbuka.
var menu_open := false
