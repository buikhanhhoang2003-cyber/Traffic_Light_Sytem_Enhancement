// =============================================================================
// conflict_monitor.v — Safety Interlock / Conflict Detector
// =============================================================================
module conflict_monitor (
    // Axis A (N/S)
    input  wire a_str_green,
    input  wire a_left_green,
    input  wire a_ped_walk,

    // Axis B (E/W)
    input  wire b_str_green,
    input  wire b_left_green,
    input  wire b_ped_walk,

    output wire system_fault
);

    // Rule 1: A straight vs B straight
    wire conflict_str         = a_str_green  & b_str_green;

    // Rule 2: A left vs B straight (oncoming conflict)
    wire conflict_a_left_b_str = a_left_green & b_str_green;

    // Rule 3: B left vs A straight (oncoming conflict)
    wire conflict_b_left_a_str = b_left_green & a_str_green;

    // Rule 4: Both left turns simultaneously
    wire conflict_both_left   = a_left_green & b_left_green;

    // Rule 5: A straight vs B left
    wire conflict_a_str_b_left = a_str_green  & b_left_green;

    // Rule 6: Pedestrian walk during conflicting opposing green
    wire conflict_ped = (a_ped_walk & b_str_green)  |
                        (a_ped_walk & b_left_green)  |
                        (b_ped_walk & a_str_green)   |
                        (b_ped_walk & a_left_green);

    assign system_fault = conflict_str          |
                          conflict_a_left_b_str |
                          conflict_b_left_a_str |
                          conflict_both_left    |
                          conflict_a_str_b_left |
                          conflict_ped;

endmodule