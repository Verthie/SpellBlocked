extends ParentProjectile

# Pocisk ma usuwać obiekty po zderzeniu z nimi

func _on_body_entered(body):
	if "increment" in body:
		body.increment()
	if "destroyable" in body:
		body.destroyable()
	queue_free()
