class_name IceBlockStrategy
extends BaseBlockStrategy

const ICE_BLOCK_PHYSICS: Resource = preload('res://custom_scripts/ice_block_physics.tres')

func apply_modification(block: Block) -> void:
	if !block.applied_effect:
		block.friction = ICE_BLOCK_PHYSICS.friction
		block.gravity = ICE_BLOCK_PHYSICS.gravity
		block.applied_effect = true
	else:
		block.friction -= ICE_BLOCK_PHYSICS.friction
