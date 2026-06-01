# Motivation
To create a library in C that allows the execution of Anticipation points (APs), dynamically, utilizing the new APRET instruction

# Considerations
## Using Signal handling as a basis for an AP API
The useful aspects of GNU C signal handling can be seen [here](../../document_notes/GNU_C_AP_API_proposal/signal.md). It would probably be useful to consider the design of signals as a basis for our new API, since they share many of the same high-level principles

## Addresses vs. Indexes
In the first design for this new API used enums/indexes to identify APs, which is in line with the GNU C signaling library. However, this approach is not feasible when considering a key component of APs: the fact that they are scheduled at runtime. This means that at compile time, the instruction our scheduler wishes to anticipate is variable. Therefore, it would be impossible to use indexes since they require modification of the code being anticipated (e.g with labels or inline asm), and we must resort to binding instruction addresses to their intended handlers.

## Other Benefits of this API
One benefit of APs is the ability for them to be used as semaphores. (Prof. Tessler, does this change the API at all?)

## How to mark the trigger address
WIP

## Assigning multiple handlers to the same address
This new API must allow the assignment of multiple APs to the same instruction address. This is feasible since each AP has it's own `APTRIG` and `APTAR` CSRs. Details are described in [the differences between AP API interface and `sigaction`](#differences-between-ap-api-interface-and-sigaction)

## Specifying the order of handlers to run when an AP is triggered
I think for now, and until we address this problem in person, it should be assumed that assigning a new handler to an AP appends it to a list that determines the order execution for handlers.

Maybe we can implement some utility functions around this:

```C
//returns a list that represents the order of execution for APs of an instruction
std::vector<UUID> addrOrder(uintptr_t APaddr);

//returns 0 on success (e.g, checks that all UUIDs are binded to this APaddr) and -1 on failure
//this seems a little clunky. It would probably be better to just define a standard, like the one above
int assignAPOrder(uintptr_t APaddr, vector<UUID> order);
```


## Assigning handlers to multiple instruction addresses
Seems like sort of a niche topic, but I could see this being useful if we wanted to default default behavior for an AP. In terms of AP referencing in the scheduler (what prompted this consideration), I don't think should be problematic if we bar the binding of indentical APs to a single instruction address.

# Proposed API
The proposed API mirrors GNU C's [`sigaction`](https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.5/html_node/Advanced-Signal-Handling.html#Advanced%20Signal%20Handling) function handler as closely as possible. Changes were required to address the considerations above. Details are explained below

## Interface
```C
//registers a handler to a specific RISCV instruction address. I also like APadd as a function name
//the return value from sigaction is zero if it succeeds, and -1 on failure. 
int APregister(uintptr_t APaddr, const struct APaction *action);

//removes, erases, deletes, unbinds, and/or unlinks (os term) (All options I like more instead of unregister) an AP from it's associated address
int APunregister(uintptr_t APaddr, const struct APaction *action); 
```

### Differences between AP API interface and `sigaction`
#### Function signature for `sigaction`
```C
int sigaction (int signum, const struct sigaction *restrict action, struct sigaction *restrict old-action)
```

The major problem when trying to mirror `sigaction` arises when we consider the case of assigning multiple APs to a single address. [POSIX standards](https://pubs.opengroup.org/onlinepubs/9699919799/functions/sigaction.html) specify the following:

> "Once an action is installed for a specific signal, it shall remain installed until another action is explicitly requested (by another call to sigaction()), until the SA_RESETHAND flag causes resetting of the handler, or until one of the exec functions is called."

This is not acceptable for our implementation. Thus, the scheduler must keep references of the APs it assigns if it wishes to unregister them at a later point in the program. The easiest way to do this would be _. This would allow the scheduler to assign multiple APs to a single instruction, while still _

Another thing that changed as a result of the multiple vs. single handlers problem is the use of `old-action`. The purpose of `old-action` is to "allow you to inquire about how a signal is being handled without changing that handling", but this doesn't make any sense if we have multiple handlers - which one would we return? For now, I choose to leave this feature out of our implementation

Note the removal of [`restrict`](https://en.wikipedia.org/wiki/Restrict), since the program must hold the reference to `action` if it intends to `APunregister` it at some point; as well as the same `action` reference would be used in both `APregister` and `APunregister`. If, however, we still wished to include `restrict` in our implementation (for performance reasons, space reasons, or the like), the API could instead look something like this:

#### Unique ID Approach 1
```C

//something analogous to a result-type pattern.
typedef struct {
    int success;
    const unsigned long long uuid;
} APRegisterResult;

//returns a "tuple" with the first arg being whether or not the function was successful, and the second being a UUID for the AP (or maybe it's index/a CSR? Idk, just need a unique identifier to hold on to)
APRegisterResult APregister(uintptr_t APaddr, const struct APaction *restrict action);

//pass the UUID to unregister the AP
int APunregister(uintptr_t APaddr, const unsigned long long *UUID); 
```
this approach seems overly complex IMO but is more verbose

#### Unique ID Approach 2
```C
// Return the status code, write uuid via pointer
int APregister(uintptr_t APaddr, const struct APaction *restrict action, const unsighned long long *UUID);

//pass the UUID to unregister the AP
int APunregister(uintptr_t APaddr, const unsigned long long *UUID); 
```
this approach is more in line with traditional C APIs. The UUID arg can be thought of as the replacement for `old-action`


### `struct APaction` - Data Type
#### The `APaction` struct 
```C
struct APaction {
    APhandler_t handler; //Can either be set to AP_IGN or a user-defined handler
    APset_t mask
    int flags;
    int active; 
    int APS; 
}
```

Structures of type `struct APaction` are used in the `APaction` function to specify all the information about how to handle a particular signal. This structure contains at least the following members:

```C
APhandler_t handler
```
Establishes an action for the signal APaddr. The value can be SIG_DFL, SIG_IGN, or a function pointer. See Basic Signal Handling.

```C
APset_t sa_mask
```
This specifies a set of APs to be blocked while the handler runs. Note that the signal that was delivered is automatically blocked by default before its handler is started; this is true regardless of the value in `sa_mask`. If you want that signal not to be blocked within its handler, you must write code in the handler to unblock it.

```C
int flags
```
the `flags` member allows a list of flags (is a bit mask) to be set for a given signal. Below are a list of the ones that I thought could be relevant to APs:
- RESTART - controls what happens when a signal is delivered during certain primitives (such as open, read or write), and the signal handler returns normally. There are two alternatives: the library function can resume, or it can return failure with error code EINTR. 
- INFO — causes the handler to receive two extra arguments: a siginfo_t pointer with detailed info about the signal (its cause, the sending PID, etc.), and a ucontext_t pointer. Requires the handler to be declared as void handler(int sig, siginfo_t *info, void *ucontext)

```C
int active
```
represents the active flag in IAPCTRL

```C
int APS
```
represents the APS in IAPCTRL. It's the semaphore of the AP

# Example API

The following code is a pseudo example of how the scheduler might use this API for the asm in  [approach two in the AP proposal](../../document_notes/english_language_description_for_anticipation_mechanism/approach_two/approach_two.asm):

```C
//UTILITY FILE
//constants defined in utility file
//this one is useful to the scheduler
#define AP_ACTIVE    0x20000001
//these should probably be hidden
#define AP_INACTIVE  0x20000000
#define IAPS_MASK    0x00000002


//USER PROGRAM
// -------------
//GNU C specifies that the only parameter of a signal handler is the int signum. This (and the void return) are what classifies it as a signhandler_t. We need additional context in our implementation, how would this work? These handlers must have to be provided by the program and not the scheduler. With this thinking in mind, I will assume we have the context of the C program application. This is kind of out of the scope of the API anyway so I won't worry too much about it
void myAPHandler(int APidx) {
    if(i == boundary) {
        APRET(APidx);
    } 
}
// -------------



//SCHEDULER
// -------------
// maybe contains a structure to hold APs and their associated structs. Then again this is probably something that should be handled internally by the API. But then how would the scheduler be able to reference the correct addresses and actions? I'm too tired to think about this in depth so I'm just going to go with it.
unordered_map<unitptr_t, unordered_map<APhandler_t, Apaction> registry;


//While running
//... parses asm at runtime. Determines that lw t3, 0(t0) is a good place to put an AP ...
//the address of the lw t3, 0(t0) is located in the APChosenAddr variable


struct APaction *action = (struct APaction*) malloc(sizeof(struct APaction));

action->handler = myAPHandler;

//the docs use sigemptyset (&new_action.sa_mask);
action->mask = {}; //empty set, there are no other APs we need to block

action->flags = 0;
action->active = 1; //this AP should be active.
action->APS = 1; //semaphore with value 1.
//note that the above values will all be dynamic. I'm just showing what they might look like


APregister(APChosenAddr, action);


//Some time later when the scheduler wants to unregister this action 
Apunregister(APChosenAddr, registry[APChosenAddr][myAPHandler]);
// -------------


```

# Under the hood
## What is handled implicitly?
This section is not totally relevant to the API, but I thought I'd leave it in

### IAPSTATUS and IAPIE
I'm trying to remember what the purpose of IAPIE is. If it's to prevent recursion, then this will be handled implicitly.

### IAPLASTEX and APSELECT
Going off of the signal library, it is customary (e.g with `raise(int signum)`) to pass the signal identifier, or in our case the AP index, to generating function. In this way, using IAPLASTEX is kind of pointless since the AP handler is always aware of the index, and can be set in the handler prologue

### IAPECP
set up in the handler prologue

### IAPSCRATCH
set up in the handler prologue.
Kind of unsure about this one. Currently, an infinite number of GPRs could be needed in the handler function. I need to come up with a way to prevent this, but it seems challenging without just using inline asm

### IAPCTRL
- privilege mask: it doesn't make sense for the user to set this, so it must be done implicitly
- active: I'm too tired to think of a solid example for when we would have APs implimented but not have them active. Either way, should be set either by the user or dynamically by the scheduler
- APS: set by the user


### IAPTRIG
Set by the user but in the AP_EXEC macro

### IAPTAR
set by the user

## Structures to manage order of execution for multiple APs
This will be handled internally, such that each instruction address will contain it's own vector to specify the order of execution for it's registered APs. A challenge is presented around adding functionality around letting the scheduler reference this metadata (such as with the `registry` variable in the example - we don't want both)

## Checking the PC for trigger addresses 
WIP. I'm assuming this code will be implimented internally in the API
