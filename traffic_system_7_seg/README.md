# Traffic Light System with 7-Segment Display

## Overview
This is a comprehensive SystemVerilog-based traffic light system with 7-segment countdown timer display. The system includes features for pedestrian crossing management, emergency vehicle override, and adaptive timing.

## File Structure

### Core Files

1. **traffic_light_controller.sv**
   - Main FSM-based traffic light controller
   - Implements RED, GREEN, YELLOW state machine
   - Includes 7-segment display countdown decoder
   - Features: Parametrizable state durations, pedestrian request input

2. **seven_segment_decoder.sv**
   - 7-segment digit decoder (0-F)
   - Supports common cathode and common anode modes
   - Seven segment driver with multiplexing support

3. **counter.sv**
   - Precision counter modules for timing
   - Frequency divider for clock generation
   - PWM controller for LED brightness control

4. **traffic_counter.sv** (NEW)
   - Traffic vehicle counter with 4-digit 7-segment display
   - Modules:
     - `traffic_counter`: Single-direction counter with debouncing
     - `traffic_counter_display`: 4-digit multiplexed display driver
     - `dual_direction_counter`: Simultaneous NS/EW counting
     - `smart_traffic_counter`: Counter with averaging and statistics
   - Features: Vehicle sensor debouncing, overflow detection, traffic density calculation

5. **traffic_counter_display.sv** (NEW)
   - Advanced display drivers and formatters for traffic counters
   - Modules:
     - `traffic_counter_display_driver`: Basic 4-digit multiplexed display
     - `four_digit_display_formatter`: Format and encode 4-digit counts
     - `traffic_density_display`: Display percentage-based density (0-100%)
     - `directional_counter_display`: NS/EW selector with auto-switching
     - `statistics_display_formatter`: Display current/average/peak/min counts
     - `traffic_counter_lcd_display`: Character display support (LCD/OLED)
     - `led_bar_graph_display`: 8-LED traffic density bar graph indicator
   - Features: Multiple display formats, automatic direction switching, statistical displays

6. **traffic_system_interface.sv**
   - Top-level interface module
   - Integrates controller and 7-segment driver
   - Includes synchronization and display management

7. **top_traffic_system.sv**
   - Complete system wrapper
   - Input synchronization and debouncing
   - Support for manual mode and emergency override
   - Pedestrian crossing logic

### Extended Modules

8. **utility_modules.sv**
   - Button debouncer (20ms default)
   - Rising/falling edge detectors
   - Asynchronous signal synchronizer
   - Pulse generator

9. **pedestrian_crossing.sv**
   - Pedestrian crossing controller (4-way)
   - State machine for walk/don't walk signals
   - Countdown timer for pedestrian crossing duration
   - Adaptive traffic controller for traffic volume adjustment

10. **multi_lane_intersection.sv**
   - 4-way intersection controller (North-South and East-West)
   - Multi-lane traffic light management
   - Emergency vehicle override system
   - Configurable emergency response

### Test Files

11. **tb_traffic_system.sv**
   - Comprehensive testbench for the system
   - Tests state transitions (RED → GREEN → YELLOW → RED)
   - Pedestrian request testing
   - Segment display verification

## System Parameters

```systemverilog
// Default parameter values
RED_DURATION     = 30 seconds
GREEN_DURATION   = 25 seconds
YELLOW_DURATION  = 5 seconds
CLK_FREQ         = 50 MHz
DEBOUNCE_TIME    = 20 ms
```

## Traffic Counter Features

### Vehicle Counting System
- **4-Digit Display**: Counts up to 9,999 vehicles per direction
- **Dual-Direction Counting**: Simultaneous NS and EW vehicle tracking
- **Sensor Debouncing**: 20ms debounce for infrared/inductive vehicle sensors
- **Real-Time Display**: Multiplexed 7-segment display for count visualization
- **Overflow Detection**: Flags when count exceeds maximum
- **Mode Control**: Normal count, reset, pause, and display-hold modes

### Counter Modules
1. **traffic_counter**: Single-direction counter with debouncing and 4-digit display
   - Max count: 9999 (parametrizable)
   - Debounce filter for sensor noise
   - 7-segment encoding for all digits
   - Overflow flag output
   
2. **dual_direction_counter**: Simultaneous NS/EW counting
   - Separate counters for North-South and East-West traffic
   - Display multiplexing to show either direction
   - Combined status output (overflow + active flags)
   
3. **smart_traffic_counter**: Advanced statistics and averaging
   - Current count display
   - Moving average calculation (4-sample history)
   - Peak and minimum count tracking
   - Traffic density calculation (0-255 scale)
   - Automatic hourly sampling

### Counter Signal Definitions
```systemverilog
// Input Signals
vehicle_sensor      - Single pulse per detected vehicle
counter_mode[1:0]   - 00: Normal, 01: Reset, 10: Pause, 11: Hold display
ns_vehicle_sensor   - North-South direction sensor
ew_vehicle_sensor   - East-West direction sensor
display_select      - 0: Display NS count, 1: Display EW count

// Output Signals
vehicle_count[15:0] - Current vehicle count (0-9999)
seg_thousands[6:0]  - Thousands digit 7-segment
seg_hundreds[6:0]   - Hundreds digit 7-segment
seg_tens[6:0]       - Tens digit 7-segment
seg_ones[6:0]       - Ones digit 7-segment
digit_select[3:0]   - Multiplex digit selection (4-digit display)
overflow            - Flag when count > MAX_COUNT
active              - Counter actively counting flag
traffic_density[7:0]- Calculated density (0-255)
```

### Vehicle Sensor Integration
- **Sensor Type**: Inductive loop detector or IR sensor
- **Signal**: High pulse for each vehicle detected
- **Pulse Width**: Minimum 100ms (longer pulses debounced)
- **Frequency**: Up to 10 vehicles/second per direction
- **Load**: Standard CMOS input, 20mA max

### Traffic Density Calculation
```
Light Traffic:    0-50 vehicles/hour (density 0-50)
Normal Traffic:  50-200 vehicles/hour (density 50-200)
Heavy Traffic:   >200 vehicles/hour (density 200-255)
```

### Counter Display Modules

1. **traffic_counter_display_driver**: Basic 4-digit multiplexed display
   - Route signals to appropriate 7-segment display outputs
   - Implements digit selection multiplexing
   - Single-input control for display routing

2. **four_digit_display_formatter**: Complete 4-digit display system
   - Converts 16-bit count (0-9999) to 4 separate digit codes
   - Automatic 7-segment encoding
   - Built-in multiplexing (4kHz refresh, 1kHz per digit)
   - Overflow flag generation
   - Suitable for standard 7-segment display modules

3. **traffic_density_display**: Specialized density visualization
   - Converts traffic density (0-255) to percentage (0-100%)
   - Displays as 2-digit percentage on 7-segment
   - Real-time classification: Light/Normal/Heavy
   - Automatic refresh multiplexing

4. **directional_counter_display**: Smart direction selector
   - Simultaneous NS and EW counting tracking
   - Multiple display modes:
     - Fixed NS direction
     - Fixed EW direction  
     - Automatic alternation (every 1 second)
     - Manual direction switching
   - Status indicators for active direction and overflow
   - Comprehensive display status byte

5. **statistics_display_formatter**: Statistical data visualization
   - Displays multiple statistics in sequence:
     - Current count
     - Average count (moving average)
     - Peak count (historical max)
     - Minimum count (historical min)
     - Range (peak - min)
   - Selection via stat_select input
   - Automatic 4-digit formatting

6. **traffic_counter_lcd_display**: Character-based display support
   - Interface for 16×2 or 16×4 character LCD/OLED displays
   - Formatted output lines (16 characters each)
   - Multiple display modes:
     - Standard: NS and EW counts with density
     - Detailed: Individual density percentages
     - Statistics: Peak, average, and other metrics
   - Display update flag (updates every 1 second)

7. **led_bar_graph_display**: Visual density indicator
   - Converts traffic density to 8-level LED bar
   - 8-bit LED output (each bit represents one LED)
   - Real-time traffic classification:
     - Light: < 25% (1-2 LEDs)
     - Normal: 25-50% (3-4 LEDs)
     - Heavy: 50-75% (5-6 LEDs)
     - Critical: > 75% (7-8 LEDs)
   - Individual status outputs for each classification level

### Display Architecture Examples

**4-Digit 7-Segment Configuration**:
```
Display Layout: [Thousands][Hundreds][Tens][Ones]
Multiplexing:   1kHz per digit (4kHz total refresh)
Refresh Period: 250µs per digit
Minimum Flicker: Imperceptible at this refresh rate
```

**Dual-Display Configuration** (Traffic Lights + Counter):
```
Display 1 (Traffic Light Countdown): 2-digit time remaining
Display 2 (Vehicle Counter):         4-digit vehicle count
- OR -
Display 2 (Switch Mode):             Alternate NS/EW counts
```

**LCD Character Display** (16×2):
```
Line 1: "NS:0000 EW:0000"
Line 2: "Density:H/N/L   " (Heavy/Normal/Light)
```

### Display Mode Selection

From software, you can switch displays:
```systemverilog
// Switch between traffic countdown and vehicle counter
if (display_select == 1'b0) begin
    // Display traffic light countdown
    segment_output = seg_countdown;
    digit_mux = countdown_digit_select;
end else begin
    // Display vehicle counter
    segment_output = seg_counter;
    digit_mux = counter_digit_select;
end

// Switch between NS and EW counter displays
directional_display_mode = 2'b10;  // Auto-switch every second
// Or: 2'b00 = Always NS, 2'b01 = Always EW, 2'b11 = Manual switch
```

## State Machine

```
       +-------------------------------------------------+
       |                  RED STATE                      |
       |     Duration: 30 seconds (parametrizable)      |
       |     LED: Red light ON, others OFF              |
       +----------|-----------+----------^-------+-------+
                  |           ^                  |
                  v           |                  |
       +---------+-------+---+---+-------+--------+-------+
       |         GREEN STATE      |     YELLOW STATE    |
       | Duration: 25 seconds     |  Duration: 5 sec    |
       | LED: Green light ON      |  LED: Yellow ON     |
       +--------------|----------+-------+--------+------+
                      |                  ^        |
                      |                  |        |
                      +------------------+--------+
```

## Key Features

### 1. Traffic Light Control
- Standard 3-state traffic light (RED, GREEN, YELLOW)
- Finite state machine implementation
- Configurable timing for each state
- Pedestrian request integration

### 2. 7-Segment Display
- Real-time countdown timer display
- Shows remaining time for current state
- Multiplexed display for 2-digit numbers (0-99 seconds)
- Common cathode/anode support

### 3. Pedestrian Crossing
- North-South pedestrian control
- East-West pedestrian control
- Walk/Don't Walk signal generation
- Countdown display for pedestrian crossing time
- Integrated with traffic light phases

### 4. Advanced Features
- **Button Debouncing**: 20ms debounce for pedestrian buttons
- **Edge Detection**: Rising and falling edge detection for events
- **Synchronization**: Multi-stage synchronizers for async inputs
- **Emergency Override**: Allows emergency vehicles to control lights
- **Adaptive Timing**: Adjusts timing based on traffic volume
- **Traffic Counting**: Vehicle detection and counting system with 4-digit display

## Signal Definitions

### Input Signals
```systemverilog
clk                 - System clock (typically 50 MHz)
rst_n               - Active-low reset
pedestrian_request  - Pedestrian crossing request
pedestrian_push     - Physical pedestrian button
mode[1:0]           - Operating mode (00: Normal, 01: Manual, 10: Emergency)
manual_state_sel    - Manual state selection input
emergency_signal    - Emergency vehicle presence indicator
traffic_volume      - Traffic density measurement (0-255)
```

### Output Signals
```systemverilog
red, yellow, green  - Traffic light outputs (active high)
seg_ones[6:0]       - Ones digit 7-segment codes (a-g)
seg_tens[6:0]       - Tens digit 7-segment codes (a-g)
digit_select[1:0]   - Multiplexer selection for digits
pedestrian_go       - Pedestrian crossing allowed
traffic_state[1:0]  - Current state output (00=RED, 01=GREEN, 10=YELLOW)
remaining_time[7:0] - Time remaining in current state
```

## 7-Segment Display Encoding

Common Cathode Mode (7'b = {g,f,e,d,c,b,a}):
```
0: 1111110
1: 0110000
2: 1101101
3: 1111001
4: 0110011
5: 1011011
6: 1011111
7: 1110000
8: 1111111
9: 1111011
```

## How to Simulate

### With Modelsim/Questasim:
```bash
vlog -sv *.sv
vsim -c tb_traffic_system -do "run -all"
```

### With Vivado:
1. Create new simulation project
2. Add all *.sv files
3. Set tb_traffic_system as top-level testbench
4. Run simulation

### With Verilator:
```bash
verilator -cc --exe --build -j 4 tb_traffic_system.sv *.sv
./obj_dir/Vtb_traffic_system
```

## Hardware Implementation

### FPGA Requirements
- Minimum LUT/Logic gates: ~500-1000 (for basic controller)
- I/O pins required:
  - 3 outputs for traffic lights
  - 14 outputs for 7-segment displays (7×2 digits)
  - 1-4 inputs for pedestrian buttons
  - 1 clock input
  - 1 reset input

### Pin Assignment Example (for Xilinx/Altera):
```
clk         → Pin E3   (100 MHz input)
rst_n       → Pin C12  (Active-low reset)
red         → Pin H17  (Red LED)
yellow      → Pin J18  (Yellow LED)
green       → Pin J17  (Green LED)
seg_ones[0] → Pin T10  (Segment a)
seg_ones[1] → Pin R10  (Segment b)
...
```

## Testing Scenarios

1. **Test 1: State Transitions**
   - Verify RED → GREEN transition
   - Verify GREEN → YELLOW transition
   - Verify YELLOW → RED transition

2. **Test 2: Pedestrian Requests**
   - Button press during RED state
   - Button press during GREEN state
   - Multiple concurrent requests

3. **Test 3: Display Countdown**
   - Verify countdown decrements correctly
   - Verify display update on digit changes
   - Verify multiplexing between tens and ones digits

4. **Test 4: Emergency Override**
   - Activate emergency mode
   - Verify immediate light control
   - Verify return to normal after timeout

## Module Hierarchy

```
top_traffic_system
    ├── traffic_light_controller
    │   └── countdown timer logic
    ├── seven_segment_driver
    │   ├── seven_segment_decoder
    │   └── multiplexing logic
    └── synchronizers & debouncers

multi_lane_intersection
    ├── traffic_light_controller (NS)
    ├── traffic_light_controller (EW)
    ├── pedestrian_crossing_controller
    ├── adaptive_traffic_controller
    └── emergency_override
```

## Timing Specifications

- **Clock Frequency**: 50 MHz (20 ns period)
- **Yellow Duration**: 5 seconds (standard)
- **Minimum Green**: 25 seconds (configurable)
- **Debounce Time**: 20 ms
- **Pedestrian Walk Duration**: 20 seconds
- **7-Segment Refresh Rate**: 1 kHz (minimum 60 Hz for flicker-free display)

## Future Enhancements

1. Lane detection using camera/sensor input
2. Machine learning-based adaptive timing
3. Vehicle detection for dynamic duration adjustment
4. Wireless communication with other intersections
5. Real-time traffic monitoring and reporting
6. Weather-adaptive timing
7. Noise pollution monitoring
8. Smart parking integration

## Design Standards Compliance

- **Safety**: Pedestrian crossing always takes priority over vehicle movement
- **Reliability**: Built-in synchronization for external signals
- **Maintainability**: Clean module hierarchy and well-documented code
- **Scalability**: Easily adaptable for different intersection configurations

## License

This system is provided as-is for educational and commercial use.

---

**Author**: Traffic Light System Enhancement Team  
**Version**: 1.0  
**Last Updated**: March 2026
