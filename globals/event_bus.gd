extends Node

@warning_ignore("unused_signal")
signal changed_interaction_state(in_area: bool)
signal casted()
signal block_thrown()
signal obstructed(state: bool)
signal changed_cursor_type(type: String)
signal player_died()
signal game_restarted()
signal game_paused()
signal game_resumed()
signal cursor_changed_state(colliding_body: Node, cast_allowed: bool, modification_allowed: bool)
signal gameplay_settings_entered()
