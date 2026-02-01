class_name BaseModule
extends Control

signal module_solved
signal module_struck

func solve():
	print("Module Solved!")
	emit_signal("module_solved")

func strike():
	print("Module Strike!")
	emit_signal("module_struck")
