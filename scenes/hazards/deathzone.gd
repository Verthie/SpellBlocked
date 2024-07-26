extends Area2D

# Strefa uśmiercająca gracza

@onready var timer: Timer = $Timer

func _on_body_entered(_body):
	timer.start()

func _on_timer_timeout():
	get_tree().reload_current_scene()

#TODO Animacje śmierci, odbierające również graczowi możliwość ruszania się po kontakcie ze strefą
