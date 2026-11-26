extends Node
## Runs every tests/test_*.gd suite with the game's autoloads loaded, prints the results and quits with
## exit code 1 if anything failed. Run:  godot --headless --path game -- --scene=tests
## A suite is a script that extends TestSuite; every method whose name starts with test_ is a test.

const SUITES := [
	"res://tests/test_progression.gd",
	"res://tests/test_stage_generator.gd",
	"res://tests/test_save_manager.gd",
	"res://tests/test_original_2016.gd",
]


func _ready() -> void:
	SaveManager.autosave = false
	var failed := 0
	var passed := 0
	for path in SUITES:
		var suite: TestSuite = load(path).new()
		suite.tree = get_tree()
		for m in suite.get_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			suite.failures.clear()
			suite.call(name)
			if suite.failures.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s %s" % [path.get_file(), name])
				for f in suite.failures:
					print("    ", f)
	print("%d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
