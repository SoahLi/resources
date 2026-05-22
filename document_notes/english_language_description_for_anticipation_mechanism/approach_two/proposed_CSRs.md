- **IAPSTATUS (Anticipation Status)** - This CSR holds relevant information for the anticipation mechanism as a whole. 
    - **IAPIE (Anticipation interrupt enable)**: Enables anticipation points to preempt execution.
- **IAPLASTEX (Last Executed AP Index)** - This CSR holds the index of the anticipation point that most recently caused a preemption. This is the same index as is used for IAPSELECT.
- **IAPEPC (Anticipation Exception PC)** - This CSR holds the trigger address of the anticipation point which executed most recently.
- **IAPSCRATCH (Independent AP Scratch)** - A scratch register for use by the anticipation handler to save/restore state without using a general-purpose register.
- **IAPSELECT (Anticipation Point Select)** - This CSR holds the index of the anticipation point which is currently selected. Subsequent reads and writes to IAPCTRL, IAPTRIG, and IAPTAR are directed to the hardware registers for the currently selected anticipation point.
- **IAPCTRL (Anticipation Point Control)** - This CSR controls the behavior of the selected anticipation point. 
    - Privilege Mask (M/S/U) - Determines the privilege levels (Machine, Supervisor, User) in which this anticipation point is active.
    - Pending - A read-only bit indicating that this AP has been triggered but the handler has not yet been entered.
    - Active - A read/write bit that enables or disables the selected anticipation point.
    - Anticipation point semaphore (APS) - bypasses anticipation point n times (this implementation uses one bit). 
- **IAPTRIG (Anticipation Point Trigger)** -
This CSR holds the trigger address. When the program counter (PC) matches
this address, and the AP is active, the anticipation mechanism is initiated.
- **IAPTAR (Anticipation Point Target)** -
This CSR holds the target address. When an anticipation event is triggered, the
PC is set to this address, transferring execution to the handler.
