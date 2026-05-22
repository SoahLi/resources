# Keywords

- **Machine Return (MRET)** - instruction used to return from a trap taken in Machine Mode, the highest privilege level
- **Supervisor Return (SRET)** - instruction used to return from a trap taken in Supervisor Mode, the privilege level used by operating system kernels .
- **User Return (URET)** - an instruction that is part of the N (User-Level Interrupts) extension, which is now largely deprecated. Its purpose was to return from a trap taken in User Mode.
- **Supervisor-level Debug Triggers (sdtrig)** - Provides a set of programmable trigger modules. These hardware modules can be configured to halt the processor or raise an exception when a specific condition is met . This is analogous to setting hardware breakpoints or watchpoints in a debugger. It sets hardware breakpoints when a specific action is met. This causes the core to stop fetching and executing
- Hardware Description Language (HDL) - describes digital circuits using langauges like Verilog
- Field-Programmable Gate Array (FPGA) - A chip that can be reconfigured to act like any digital circuit you describe in HDL.
- very-large-scale Integration (VLSI) - The process of fabricating a custom silicon chip
- **Semaphore (General, non lock-based term)** - a signal that controls whether something is permitted to proceed
- **General Purpose Registers (GPRs)** - the literal, general purpose registers of the CPU core
- **Conflict Free Region (CFR)** - section of code that can be run concurrently on the same core (by different software threads) without cache eviction penalties. 
- **Single Event Upsets (SEUs)** - a random, non-destructive bit flip in memory, usually caused by a highly energetic particle randomly flying in from nowhere and striking the chip
- **Asymmetric Multiprocessing** - A computing architecture where cores are assigned dedicated, specific roles rather than being treated equally.


# Background
## Machine Return (MRET) and Supervisor Return (SRET) 
instructions used to return from traps (interrupts or exceptions) and transition between privilege levels. 
    - When a trap occurs, the hardware saves the current state of the program (Program counter for example) into specific CSRs. These instructions are then used by the trap handler to restore this state and resume normal program execution
    

# Motivation
- The focus of this project is to implement the hardware support BUNDLE relies on: the anticipation mechanism. This solution would borrow from standard extensions to add new control/status registers (CSRs) and a new instruction for atomically returning execution to the thread such that the general purpose registers are in the same state as they were at the time of preemption
- This project is intended to first establish a valid description of the modification to the RISC-V instruction set architecture (ISA), with initial testing through modification of Gem5, eventual hardware description language (HDL) implementation for verification on an FPGA, and to have manufactured a prototype very-large-scale integrated (VLSI) chip for verification of the BUNDLE scheduling algorithm.
## Use Cases for APs
- Temporal Redundancy (temporal because jobs are running serially on one core) and fault tolerance- E.g aerospace flight controllers require redundancy to protect against things like single-event upsets
- Multi-axis motor control - In industrial robotics or avionics, a single core often manages multiple identical actuators, e.g., a 6-axis robotic arm or a quadcopter's independent rotors. The OS schedules a separate thread for each motor to run identical PID control loops or inverse kinematics simultaneously. BUNDLE allows these threads to share the instruction cache perfectly as they compute their next required torque
- Swarm and Muli-Agent Coordination - A central real-time controller managing a fleet of agents, e.g., automated guided vehicles on a factory floor. The controller evaluates identical trajectory, physics, and collision-avoidance algorithms for each agent. Since the physical constraints are the same, the code is identical for each thread. 

### What are the use cases for APs considering this is a per-core solution? I.e in what scenarios are multiple of the same job being scheduled on the same core (as opposed to different cores which would allow them to run in parallel)?
- Load balancing across multiple cores destroys predictability. This is why hard real-time systems use Asymmetric multiprocessing, which would most certainly lead to identical jobs being scheduled on the same core
- In special cases, a system might only posses a single core

# Approach One - N-Mode Trap Return
- Uses the N-Mode extension's user-level trap-return instructions. The following N-mode defined CSRs and instruction are used:
    - **User Interrupt Pending (UIP)** - CSR flag that indicates that a user interrupt is pending
    - **User Interrupt Enable (UIE)** - CSR flag that is set to 0 on entry into the interrupt handler. This prevents further interrupts (i.e from recursion, e.g if the handler had an anticipation point for some reason) entry into the handler until the current execution stream has returned from the handler via uret.
    - **User Exception Program Counter (UEPC)** - CSR to save the current Program Counter (i.e the instruction that was about to be executed) for later reuse after returning from the interrupt handler
    - **User Return (URET)** - Instruction that restores the state of the core to continue execution from the interrupt. Restores the Program Counter (Using the value in UEPC) and the UIE to 1 (most generally). Note that GPRs must be saved and restored by the user
    - **User Scratch (uscratch)** - CSR to store state-related values. Can be whatever you want (e.g the loop counter in the example)

## Example Assembly
- On the first pass through the code which sums the elements of the array, preemption
takes place on `lw t3, 0(t0)`.
- In this implementation, when the PC reaches trigger_address and before executing the
instruction at that address (i.e the load word instruction), a user-level interrupt triggers, atomically and automatically setting the UIP flag,
resetting the UIE flag, storing the address of the instruction that was about to execute to UEPC, setting PC to target_address,
and setting naplastex to 0 (the index of the triggering anticipation point)
- Once the memory pointer t0 equals the first index/address in boundary, it exits. Therefore, since on the first pass, t1 does not equal boundary, execution continues and the thread is not interrupted.
    - Note that in this non-boundary case (the case where execution returns to the loop), we need a bit NAPS (N-mode AP semaphore) to prevent re-preemption and to let execution continue into the loop. Without this, execution would preempt infinetely. I.e when the trigger_address instruction is executed, if NAPS = 0, enter the handler and the handler sets NAPS to 1, and when execution resumes from the handler, atomically set NAPS = 0.
- Once t0 == boundary, i.e it has reached the halfway point in the array, the handler code jumps to the exit condition, allowing the OS to schedule another thread to start executing. When the interrupted thread returns to start summing over the second half of the array, it resumes at the `lw` instruction and subsequently increments t0, ensuring that t0 != boundary (because it was incremented before it was checked again). These two distinct execution can be thought of as separate CFRs (i.e all threads sum over the first half of the loop before any thread starts summing over the second half of the loop, but this is not shown in code because it's handled by the scheduler)
 


# Approach Two - Independent Return (APRET)
- a new instruction (APRET) This is independent of any RISC-V interrupt/trap pipeline, which is used by approach one (and hence has the I prefix of CSRs for independent). This could result in much lower overhead
## Explanation of Global versus Local CSRs for APs
For initial configuration, IAPSELECT is used to "window" (is that the correct term) between local CSRs. Then, when any AP is triggered, IAPLASTEX is set and the handler uses this to reference the correct local CSRs:
- Global CSRs
    - IAPSTATUS
    - IAPLASTEX
    - IAPEPC
    - IAPSCRATCH
    - IAPSELECT

- Local (AP instance based) CSRs
    - IAPCTRL
    - IAPTRIG
    - IAPTAR

## Example Assembly

- The example assembly here is functionally identical to the code in approach one, with the new IAPRET instruction atomically resetting the `pending` flag of APCTRL (UIP), sets the APIE (UIE) of APSTATUS, and sets PC to the value stored in APEPC (UEPC. 
- When the anticipation point is triggered, it uses internal features to atomically set the pending flag of IAPCTRL (UIP), and reset the IAPIE of IAPSTATUS (UIE to prevent recursion), store the current PC to IAPEPC (UEPC), set PC to IAPTAR, and set IAPLASTEX to 0 (the index of the triggering anticipation point to be able to reference the correct AP instance related CSRs).


# Commentary On Design Decision
## Why Not just use hardware breakpoints?
Hardware breakpoints are limited in number for arm and x86, they allow their anticipated
instruction to complete its pipeline before passing execution to the handler, and RISC-V doesn’t
offer a manner by which to manage hardware breakpoints from within (use of an external
debugger is necessary to set and handle hardware breakpoints).

## Why not just use ebreak?
This requires an operating system context switch (trapping from User mode to Kernel mode and back). Context switches take hundreds or thousands of clock cycles.

## What’s the proper way to store the context without incurring writeback penalty?
This is an essential future research task regarding BUNDLE, however cache locking appears to
be integral for BUNDLE to see a positive cache benefit.

## Why not mask apctrl to include apselect?
A question of whether to combine these into a single register using bitmasks (e.g., bits 0-3 select the index, bits 4-7 hold the configuration). Adding more CSRs takes up physical silicon space, but packing them together makes the logic gates required to decode them much more complicated

## Should we directly use URET from the N-Extension, Overhaul it, or copy only requisite features for Anticipation?
The N-mode extension was deprecated for a couple of reasons. The most significant reason is
that the implementation was deemed unviable, and the consensus leading to its deprecation
was that it should be refactored if it were brought back.
This being said, it’s not worth refactoring the user-level interrupt extension as a subtask of this
project, and as such it is most viable to copy the requisite features from interrupt handling
features
