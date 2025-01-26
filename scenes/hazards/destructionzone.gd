extends Area2D

# Strefa niszcząca obiekty

func _on_body_entered(body: Node2D) -> void:
	if body is Block:
		body.destroy()
		Globals.block_amount += 1
