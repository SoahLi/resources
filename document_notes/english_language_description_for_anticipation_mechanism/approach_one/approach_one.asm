.data
    # exit_address
    # target_address
    # trigger_address
    .equ user_inactive, 0x20000000   # privilege mask, with 0 in the 'active' flag
    .equ user_active,   0x20000001   # privilege mask, with 1 in the 'active' flag
    .equ naps_mask,     0x00000002   # bitmask for the semaphore of the anticipation point

size_of_array: .word 12              # The size of an array of integers
array:                               # The start of an array of integers
    .word 123, 456, 789
    .word 123, 456, 789
boundary:                            # Represents a boundary between different blocks of memory
    .word 123, 456, 789
    .word 123, 456, 789

    .text
    .global _start
_start:
    # --- Setup Anticipation Point (AP0) ---
    csrw    napselect, zero          # Select anticipation point at index zero

    li      t0, user_inactive
    csrw    napctrl, t0              # Set AP0 privilege level to user, and active to false

    la      t0, target_address
    csrrw   zero, naptar, t0         # Set AP0 target to target_address

    la      t0, trigger_address
    csrrw   zero, naptrig, t0        # Set AP0 trigger to trigger_address

    li      t0, user_active
    csrrsi  zero, napctrl, 1         # Set AP0 active to true

    # --- Preempted Code (Loop) ---
    li      a0, 12
    la      t0, array                # Pointer to the current element of the array
    add     t2, zero, zero           # The current running total

for:
    #pseudocode but I hope you undersand the point
    beq     t0, (arrays_address + size_of_array * 4), end            # exit if counter == zero

trigger_address:                     # Address of the instruction being anticipated
    lw      t3, 0(t0)                # Load the currently pointed-to word from the array

### Anticipation mechanism triggers ###

    add     t2, t2, t3               # Add to running total
    addi    t0, t0, 4                # Move pointer to next word
    j       for                      # continue the endless cycle

end:
    j       end                      # Infinite loop to avoid executing miscellaneous data as code

    # --- Anticipation Handler ---
target_address:
    
    la      t1, boundary             # Load the address of the boundary into t1
    bne     t0, t1, continue_execution # If interrupted code isn't at boundary, return execution
    
    # If the interrupted code *was* trying to load boundary, jump to exit_address
    la      t1, exit_address         # Load the exit_address into t1
    csrw    uepc, t1                 # Set the value of UEPC to the exit_address
    
    uret                             # Returns to address stored in UEPC

continue_execution:
    csrsi   napstatus, naps_mask     # Set semaphore bit to 'admit one' execution of the instruction
    uret                             # Return execution to interrupted instruction

exit_address:
    # Scheduler redirect logic would go here
    j       exit_address
