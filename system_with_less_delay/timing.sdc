# =============================================================================
# traffic_light_top.sdc — Timing Constraints (Altera/Intel Quartus)
# =============================================================================

# Primary clock — 50MHz
create_clock -name {clk} -period 20.000 [get_ports {clk}]

# Clock uncertainty
set_clock_uncertainty -rise_from {clk} -rise_to {clk} 0.020
set_clock_uncertainty -fall_from {clk} -fall_to {clk} 0.020

# Input delays — slow-changing control signals
set_input_delay -clock {clk} -max 3.000 [get_ports {rst_n}]
set_input_delay -clock {clk} -max 3.000 [get_ports {ns_sensor}]
set_input_delay -clock {clk} -max 3.000 [get_ports {ew_sensor}]
set_input_delay -clock {clk} -max 3.000 [get_ports {emergency_trigger}]

# Output delays — LED drivers (very relaxed, human-visible timing)
set_output_delay -clock {clk} -max 5.000 [get_ports {led_*}]
set_output_delay -clock {clk} -max 5.000 [get_ports {system_fault_led}]

# False path — async reset, no timing analysis needed
set_false_path -from [get_ports {rst_n}]

# False path — clock divider counter is not a timing-critical path
set_false_path -from [get_registers {u_clk_div|cnt_1hz*}]
set_false_path -from [get_registers {u_clk_div|cnt_2hz*}]

derive_pll_clocks
derive_clock_uncertainty
```

---

## Complete FSM State Diagram
```
                    rst_n=0
                       │
                       ▼
              ┌──── FAIL_SAFE ────┐  All Red
              └────────┬──────────┘
                  rst_n=1│
                         ▼
              ┌───── NS_GREEN ────┐  N/S Green + Left Green
              │     (9s / gap)   │  Pedestrian walk: first 4s
              └────────┬──────────┘  Gap-out if sensor=0 after 3s
                       │
                       ▼
              ┌──── NS_YELLOW ────┐  N/S Yellow + Left Yellow
              │      (5s)        │  E/W remains Red
              └────────┬──────────┘
                       │
                       ▼
              ┌──── ALL_RED_A ────┐  All Red clearance buffer (2s)
              └────────┬──────────┘
                       │
                       ▼
              ┌───── EW_GREEN ────┐  E/W Green + Left Green
              │     (9s / gap)   │  Pedestrian walk: first 4s
              └────────┬──────────┘  Gap-out if sensor=0 after 3s
                       │
                       ▼
              ┌──── EW_YELLOW ────┐  E/W Yellow + Left Yellow
              │      (5s)        │  N/S remains Red
              └────────┬──────────┘
                       │
                       ▼
              ┌──── ALL_RED_B ────┐  All Red clearance buffer (2s)
              └────────┬──────────┘
                       │
                       └──────────────► NS_GREEN (cycle repeats)


  emergency_trigger=1 (from any normal state)
              │
              ▼
     ┌─ EMERGENCY_YELLOW ─┐  Both directions → Yellow (5s)
     └────────┬────────────┘
              ▼
     ┌── EMERGENCY_RED ───┐  All Red clearance (2s)
     └────────┬────────────┘
              ▼
     ┌── EMERGENCY_GREEN ─┐  N/S priority Green (held while trigger=1)
     └────────┬────────────┘
         trigger=0│
                  └──────────────► ALL_RED_A → resume normal cycle


  system_fault=1 (conflict detected, from any state)
              │
              ▼
     ┌──── BLINK_RED ─────┐  All outputs blink RED at 2Hz
     │   (latched until   │  Only rst_n=0 can clear this
     │      reset)        │
     └────────────────────┘