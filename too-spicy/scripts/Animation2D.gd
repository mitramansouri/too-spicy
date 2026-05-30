class_name Animation2D extends TextureRect

var frames: Array[Texture2D] = []
var current_frame: int = 0
var fps: float = 12.0
var elapsed: float = 0.0

func load_frames(folder_path: String, frame_count: int):
	for i in range(frame_count):
		var path = "%s/frame_%d.png" % [folder_path, i]
		frames.append(load(path))
	if frames.size() > 0:
		texture = frames[0]

func _process(delta):
	if frames.is_empty():
		return
	elapsed += delta
	if elapsed >= 1.0 / fps:
		elapsed = 0.0
		current_frame = (current_frame + 1) % frames.size()
		texture = frames[current_frame]
