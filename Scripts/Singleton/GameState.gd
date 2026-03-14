extends Node

var simple_mode: bool = false

# Fixed serial number used in tutorial mode (last digit 4 = even, compatible with 4-wire rules)
const TUTORIAL_SERIAL: String = "A1B2C4"

# Emitted by BombManager to drive the hint panel forward
signal hint_updated(hint_text: String)
