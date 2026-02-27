extends Node

# Benchmark runner
func _ready():
	print("--- Starting PressModule Search Benchmark ---")
	benchmark_search()
	print("--- Benchmark Complete ---")

func benchmark_search():
	var parent = Node.new()
	# We don't add parent to the tree to avoid polluting the main scene,
	# but get_parent() relies on the node being in the tree or just having a parent.
	# Nodes can have parents without being in the SceneTree.
	# However, to be safe and closer to reality, let's add parent to self.
	add_child(parent)

	# 1. Setup Environment: Many siblings
	var sibling_count = 10000
	print("Creating %d siblings..." % sibling_count)
	for i in range(sibling_count):
		var node = Node.new()
		node.name = "RandomModule_%d" % i
		parent.add_child(node)

	# Add Timer at the very end to trigger worst-case performance
	var timer = Node.new()
	timer.name = "TimerModule"
	parent.add_child(timer)

	# Add our subject PressModule
	# We use a script that extends PressModule but overrides _ready to avoid errors
	var subject_script = GDScript.new()
	subject_script.source_code = "extends 'res://Scripts/Modules/PressModule.gd'\nfunc _ready(): pass"
	subject_script.reload()

	var subject = Node.new()
	subject.set_script(subject_script)
	parent.add_child(subject)

	# 2. Measure
	var start_time = Time.get_ticks_usec()

	# Force the search
	# We have to simulate the condition where timer_module is null
	subject.timer_module = null
	subject._find_timer_module()

	var end_time = Time.get_ticks_usec()
	var duration = end_time - start_time

	print("Search duration: %d microseconds" % duration)

	if subject.timer_module == timer:
		print("SUCCESS: Timer module found.")
	else:
		print("FAILURE: Timer module NOT found.")

	parent.queue_free()
