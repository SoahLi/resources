# WIP


# Keywords
- **Task**   - a set of computations or a piece of work that a system must perform. Defined by period (how frequently this task needs to execute), worst case execution time, and a relative deadline (the amount of time a task has to execute based on a trigger [from another task])
- **Job** - an instance of a task. Has a set of dynamic properties like arrival/release time, execution time, and absolute deadline
- **preemption** - The operating system forcibly takes the CPU away from the process/thread
- **nonpreemption** - the process/thread voluntarily releases the CPU when done (via yield() for example)
- **Limited preemption model** - attempt to minimize preemption overhead (CRPD) by reducing the number of allowed preemptions and/or allowing preemption at program locations where the CRPD effect is minimized
- **Worst case execution time (WCET)** - The maximum length of time a task, program, or code segment could take to execute on a specific hardware platform, assuming no exceptions (such as hardware faults) occur.
- **Cache related preemption delay (CRPD)** - The maximum length of time a task, program, or code segment could take to execute on a specific hardware platform, assuming no exceptions (such as hardware faults) occur. 
- **Earliest deadline first (EDF)** - assigns execution priority based on the task with the closest task deadline
- **Useful Cache Block (UCB)** - a cache block that may be cached and may be reused later if not evicted
- **Evicting Cache Block** - The set of all memory blocks a task may access during it's execution. A memory block that may be accessed by the same task in the future is a UCB of that task. 
- **Accessed Useful Cache Block** - a UCB of a task that is access during the execution of a spcific basic block
- **Load cache block (LCB)** - A useful cache block that was evicted by a preemptor and will be accessed again in the upcoming non‑preemptive region (between the current and next preemption points), forcing a reload.
- **Deferred Preemption Model** - permit a currently executing job to execute non-preemptively for some period of time after the arrival of a high priority job.
    - **Fixed Preemption Point Model** - the beginning of non-preemptive regions occur with the arrival of a higher priority job. The currently executing job continues executing non-preemptively for Q_i time units or earlier if the job completes execution. The location of the non-preemptive regions is nondeterministic or essentially floating. Baruah's approach [15] computes the maximum amount of blocking time denoted Q_i for which a task Ti may execute non- preemptively while still preserving scheduling feasibility.
    - **Floating Point Preemption Model** - In the fixed preemption point model [14], a task can be preempted only at a limited set of pre-defined locations. Basically, tasks contain a series of non-preemptive regions. Preemptions are permitted at non-preemptive region boundaries or fixed preemption points.
- Basic block (In terms of BUNDLE) - one or more instructions that execute non- preemptively.


 

# Attributes of BUNDLE
- BUNDLE involves sectioning code belonging to a given process into conflict-free regions
(CFRs) that can be run concurrently on the same core (by different software threads) without
cache eviction penalties between executions after all relevant regions of memory for that CFR
- The purpose of hardware anticipation points (APs) is enabling a scheduler to
block (preempt/deschedule) each software thread at the end of a given CFR, allowing execution
of the same CFR by other (pending) threads, then proceeding to the next CFR. This allows
software threads to share cached regions of memory over consecutive executions of a given
CFR, theoretically reducing cache evictions and the associated cost of accessing main memory
have been cached. 
    - note that for the purpose of our tests, anticipation points will not be scheduled dynamically
- Jobs are forbidden from preempting one another, while threads within a job are allowed to preempt other threads
- All instructions in a task live inside a basic block. Preemption points occur at edges between basic blocks



