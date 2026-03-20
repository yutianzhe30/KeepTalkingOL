# Mobile Support Issues

## 1. Module Size / Readability
Each module is too small on a mobile device
maybe:
- Module only activated when we "clicked" on it , then zoom in
- zoom out when we click on border/module solved

## 2. Touch Target Size
Buttons, wires, and interactive elements are too small for reliable finger taps
- Wire module: selecting/connecting wires requires pixel-precision
- Button module: 2x2 grid buttons may be too close together (misfire risk)
- Press module: sequential button taps on small targets

## 3. Virtual Joystick
Hard to control (existing note)
- D-pad radius/knob size may need tuning per device screen size
- Dead zone threshold (currently 0.30) may need adjustment
- Joystick position should not overlap with module content when zoomed in

## 4. Module-Specific Mobile Issues
- **Radio module**: frequency slider hard to drag precisely on small screen
- **ECG module**: reading waveform detail is difficult at small scale
- **Maze module**: wall details are sub-pixel; navigation is imprecise
- **Balance module**: tilt sensitivity may be too high/low depending on device
- **Serial number**: small alphanumeric characters hard to read

## 5. Text / Font Size
Labels, numbers, and clues inside modules are too small to read without zoom
- Timer digits may be readable but surrounding text is not
- ModuleLED status indicator is tiny (top-right corner of each module)

## 6. Landscape vs Portrait
Game grid (3x3) is designed for landscape — portrait mode stacks modules awkwardly
- Consider locking to landscape on mobile
- Or reflowing grid to 2-column portrait layout

## 7. Safe Area / Notch
No handling for device notches, camera cutouts, or rounded corners
- D-pad in bottom-right may be clipped on some devices

## 8. Performance / Battery
- BalanceModule physics runs continuously — may drain battery on mobile
- WebInput sensor polling should pause when app is backgrounded
