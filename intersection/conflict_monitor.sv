// =============================================================================
// conflict_monitor.sv — Safety Interlock / Conflict Detector
//
// Updated for 8-state FSM where left turns now have active green phases.
// Monitors actual output wires — does NOT trust the FSM.
// Flags system_fault if any conflicting pair is simultaneously active.
// =============================================================================
module conflict_monitor (
    // Axis A (N/S)
    input  logic a_str_green,
    input  logic a_left_green,
    input  logic a_ped_walk,

    // Axis B (E/W)
    input  logic b_str_green,
    input  logic b_left_green,
    input  logic b_ped_walk,

    output logic system_fault
);

    // ── Conflict Rules ────────────────────────────────────────────────────────

    // Rule 1: A straight vs B straight
    logic conflict_str;
    assign conflict_str = a_str_green & b_str_green;

    // Rule 2: A left vs B straight (oncoming conflict)
    logic conflict_a_left_b_str;
    assign conflict_a_left_b_str = a_left_green & b_str_green;

    // Rule 3: B left vs A straight (oncoming conflict)
    logic conflict_b_left_a_str;
    assign conflict_b_left_a_str = b_left_green & a_str_green;

    // Rule 4: Both left turns simultaneously
    logic conflict_both_left;
    assign conflict_both_left = a_left_green & b_left_green;

    // Rule 5: A straight vs B left
    logic conflict_a_str_b_left;
    assign conflict_a_str_b_left = a_str_green & b_left_green;

    // Rule 6: Pedestrian walk during conflicting opposing green
    logic conflict_ped;
    assign conflict_ped = (a_ped_walk & b_str_green)  |
                          (a_ped_walk & b_left_green)  |
                          (b_ped_walk & a_str_green)   |
                          (b_ped_walk & a_left_green);

    // ── Fault Output ──────────────────────────────────────────────────────────
    assign system_fault = conflict_str         |
                          conflict_a_left_b_str|
                          conflict_b_left_a_str|
                          conflict_both_left   |
                          conflict_a_str_b_left|
                          conflict_ped;

endmodule