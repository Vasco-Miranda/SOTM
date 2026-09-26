extends Camera2D

var tilemap: TileMapLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	
	var tilemaps := get_tree().get_nodes_in_group("tilemaps")
	for map in tilemaps:
		if map.name == "TileMapLayer_Room":
			tilemap = map
	
	setup_camera_limits()
	
func setup_camera_limits() -> void:
	if not tilemap:
		return
	
	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_map_size := tilemap.tile_set.get_tile_size()
	
	limit_right = (used_rect.position.x + used_rect.size.x) * tile_map_size.x * 4
	limit_bottom = (used_rect.position.y + used_rect.size.y) * tile_map_size.y * 4
