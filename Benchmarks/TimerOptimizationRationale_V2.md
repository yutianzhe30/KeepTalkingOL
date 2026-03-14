# Timer Module Optimization Rationale V2

## Baseline Analysis

The current implementation of `TimerModule.gd` has several performance bottlenecks in its `_process(delta)` loop, which runs every frame (typically 60 times per second).

### Identified Inefficiencies

1.  **Redundant Calculations in `update_display()`**:
    ```gdscript
    func update_display():
        var minutes = floor(time_remaining / 60)
        var seconds = floor(fmod(time_remaining, 60))

        if minutes == last_display_minutes and seconds == last_display_seconds:
            return
        # ...
    ```
    Even when the timer hasn't reached a new second, the script performs float division, `floor()`, and `fmod()` every frame before checking the cache.

2.  **Redundant Calculations in `check_sound_tick()`**:
    ```gdscript
    func check_sound_tick():
        var current_second = ceil(time_remaining)
        if current_second != last_tick_second:
            # ...
    ```
    Similar to `update_display()`, `ceil()` is called every frame even when it's unlikely to have changed.

3.  **Unnecessary `_process` Calls**:
    The `_process(delta)` function runs every frame as long as the node is in the scene tree, even if the timer is stopped or has already exploded. While it has an `if is_running` check, the overhead of the engine calling the GDScript `_process` function still exists.

4.  **Multiple Cache Variables**:
    Using `last_display_minutes` and `last_display_seconds` requires two comparisons and two assignments, whereas a single `last_display_total_seconds` would suffice.

## Proposed Optimizations

### 1. Early Cache Exit
Move the cache check to the very top of `update_display()` and `check_sound_tick()`. By casting `time_remaining` to an integer once, we can skip all further logic for ~59 out of 60 frames per second.

### 2. Integer Math
Replace `floor`, `fmod`, and float division with integer division (`/`) and modulo (`%`) which are generally faster.

### 3. Process Management
Use `set_process(false)` by default and only enable it via `set_process(true)` when `start_timer()` is called. Disable it again in `stop_timer()` and `explode()`. This completely removes the overhead of the `_process` callback when the timer is inactive.

### 4. Consolidated Caching
Use a single integer variable `last_display_total_seconds` to track the state of the display.

## Expected Impact

- **CPU Efficiency**: Significant reduction in GDScript execution time per frame.
- **Power Consumption**: Lower CPU usage leads to better battery life on mobile devices (the target platform).
- **Reduced String Allocations**: By ensuring `update_display()` only proceeds when necessary, we strictly limit string formatting to once per second.
- **Engine Overhead**: Eliminating idle `_process` calls reduces the workload on the Godot main loop.
