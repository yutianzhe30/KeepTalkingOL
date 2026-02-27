# Timer Module Optimization Rationale

## Baseline Analysis

The current implementation of `TimerModule.gd` updates the display every frame within the `_process(delta)` loop.

```gdscript
func _process(delta):
    if is_running and time_remaining > 0:
        # ... calculation of time_remaining ...
        update_display()
        # ...
```

Inside `update_display()`:

```gdscript
func update_display():
    var minutes = floor(time_remaining / 60)
    var seconds = floor(fmod(time_remaining, 60))
    label.text = "%02d:%02d" % [minutes, seconds]
```

### Performance Cost

1.  **String Allocation**: The expression `"%02d:%02d" % [minutes, seconds]` allocates a new String object on every frame (typically 60 FPS).
2.  **Property Assignment**: `label.text = ...` assigns this string to the Label node. While Godot's C++ side might check for equality, the GDScript-to-C++ call overhead and the GDScript string allocation still occur.

## Proposed Optimization

We can track the last displayed minute and second values. Since the timer only displays MM:SS, the visual output only changes once per second (or when the timer is initialized/reset).

### Optimization Strategy

1.  Store `last_display_minutes` and `last_display_seconds` as instance variables.
2.  In `update_display()`, calculate the current minutes and seconds.
3.  Compare current values with stored values.
4.  Only perform the string formatting and `label.text` assignment if the values have changed.

### Expected Impact

-   **Reduced Garbage Collection**: Prevents the creation of ~59 unnecessary String objects per second.
-   **Reduced CPU Usage**: Skips string formatting logic and method calls for the vast majority of frames.

## Verification

Since we cannot run a Godot runtime benchmark in this environment (no Godot binary), this optimization relies on standard game development patterns for UI updates: "Dirty Flag" or "Cache & Compare".
