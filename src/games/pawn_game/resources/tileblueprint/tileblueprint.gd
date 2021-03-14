extends Resource

class_name TileBlueprint

export var create_tile: Resource
export(Array, String) var buildable_on = ["Grass"]
export var work: int = 10
# resource name: amount needed
export var resource_cost: Dictionary = {
	"Gold": 0
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
