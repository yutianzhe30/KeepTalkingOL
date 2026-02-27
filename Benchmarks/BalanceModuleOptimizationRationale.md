# Balance Module Optimization Rationale

## Baseline Analysis

The current implementation of `BalanceModule.gd` performs a node lookup and redundant property assignments every frame within the `_process(delta)` loop.

```gdscript
	var target_area = get_node_or_null("ReferenceRect/TargetArea")
	if target_area:
		target_area.custom_minimum_size = Vector2(TARGET_RADIUS * 2, TARGET_RADIUS * 2)
		target_area.size = Vector2(TARGET_RADIUS * 2, TARGET_RADIUS * 2)
		target_area.position = center - (target_area.size / 2.0)
```

### Performance Cost

1.  **Node Traversal**: `get_node_or_null("ReferenceRect/TargetArea")` queries the scene tree structure on every frame (typically 60+ FPS). This involves string hashing and tree traversal operations.
2.  **Redundant Assignment**: `TARGET_RADIUS` is a constant value (`20.0`), meaning `custom_minimum_size` and `size` do not change during gameplay. Assigning these properties every frame results in unnecessary GDScript-to-C++ calls and potential internal UI updates in Godot.

## Proposed Optimization

We can cache the node reference and move constant assignments to initialization, updating only what is strictly necessary during `_process`.

### Optimization Strategy

1.  Add an `@onready` variable to cache the reference to `TargetArea`.
2.  In `_ready()`, initialize the `custom_minimum_size` and `size` properties since they depend on the constant `TARGET_RADIUS`.
3.  In `_process(delta)`, only update the `target_area.position` using the pre-calculated `center` and cached `size`.

### Expected Impact

-   **Reduced CPU Usage**: Eliminates the overhead of scene tree queries (`get_node`) for every frame.
-   **Reduced Redundant Operations**: Eliminates the overhead of calculating and assigning constant size vectors every frame.

## Verification

Since we cannot run a Godot runtime benchmark in this environment (no Godot binary), this optimization relies on standard game development patterns for object caching and avoiding redundant property updates in hot loops.
