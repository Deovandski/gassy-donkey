class_name TestSuite
extends RefCounted
## Base for test suites (see run_tests.gd): check() records a failure instead of stopping.

var failures: Array[String] = []
var tree: SceneTree


func check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func check_eq(got, want, what: String) -> void:
	if got != want:
		failures.append("%s: got %s, want %s" % [what, str(got), str(want)])
