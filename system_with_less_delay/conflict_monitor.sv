// =============================================================================
// conflict_monitor.sv — Safety Interlock / Conflict Detector
//
// Monitors all green outputs. Flags system_fault if any conflicting
// green pair is simultaneously active (N/S green AND E/W green).
//
// This is a purely combinational, independent watchdog layer.
// It does NOT trust the FSM — it watches the actual output wires.
// =============================================================================
module conflict_monitor (
    // Straight greens
    input  logic ns_str_green,   // N or S straight green active
    input  logic ew_str_green,   // E or W straight green active

    // Left-turn greens
    input  logic ns_left_green,
    input  logic ew_left_green,

    // Pedestrian walks
    input  logic ns_ped,
    input  logic ew_ped,

    output logic system_fault    // HIGH = conflict detected
);

    // ── Conflict Rules ────────────────────────────────────────────────────────
    // Rule 1: N/S straight green conflicts with E/W straight green
    logic conflict_str;
    assign conflict_str = ns_str_green & ew_str_green;

    // Rule 2: N/S left green conflicts with E/W straight green (and vice versa)
    logic conflict_left_a;
    assign conflict_left_a = ns_left_green & ew_str_green;

    logic conflict_left_b;
    assign conflict_left_b = ew_left_green & ns_str_green;

    // Rule 3: Both left turns green simultaneously
    logic conflict_left_both;
    assign conflict_left_both = ns_left_green & ew_left_green;

    // Rule 4: Pedestrian walk during conflicting green
    logic conflict_ped;
    assign conflict_ped = (ns_ped & ew_str_green) |
                          (ew_ped & ns_str_green);

    // ── Fault Output ──────────────────────────────────────────────────────────
    assign system_fault = conflict_str     |
                          conflict_left_a  |
                          conflict_left_b  |
                          conflict_left_both |
                          conflict_ped;

endmodule