extends Area2D

# Strefa niszcząca obiekty

func _on_body_entered(body: Node2D) -> void:
	if "destroyable" in body:
		body.destroy()
