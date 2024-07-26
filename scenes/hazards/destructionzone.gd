extends Area2D

# Strefa niszcząca obiekty

func _on_body_entered(body):
	if "increment" in body:
		body.increment()
	if "destroyable" in body:
		body.destroyable()
