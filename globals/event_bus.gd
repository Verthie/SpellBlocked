extends Node

@warning_ignore("unused_signal")
signal changed_interaction_state(in_area: bool)
signal casted()
signal applied_modification(block: Block, block_type: String)
signal removed_modification(block: Block)
signal block_thrown()
signal obstructed(state: bool)
signal changed_block_type()
signal block_removed(block: Block)
signal block_action_rejected()
signal changed_cursor_type(type: String)
signal entered_checkpoint(checkpoint_id: int, save_parameters: int)
signal player_died()
signal quick_restarted()
signal game_restarted()
signal game_paused()
signal game_resumed()
signal cursor_changed_state(colliding_body: Node, cast_allowed: bool, modification_allowed: bool)
signal gameplay_settings_entered()
signal object_splashed(body: Node2D, position: Vector2i, collider: Node2D)
signal level_finished()
signal level_exited()
