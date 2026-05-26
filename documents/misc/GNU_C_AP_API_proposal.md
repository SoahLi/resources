# Keywords

# Motivation
To create a library in C that allows the execution of APs, which utilize the new APRET instruction

# Considerations
## Using Signal handling as a basis for an AP API
The useful aspects of GNU C signal handling can be seen [here](../../document_notes/GNU_C_AP_API_proposal/signal.md). It would probably be useful to consider the design of signals as a basis for our new API, since they share many of the same high-level principles

## How to mark the trigger address
There is no practical way (that I know of) to get the address of a specific line of code without using inline asm. However, we can use labels using the [labels as values extension](https://gcc.gnu.org/onlinedocs/gcc/Labels-as-Values.html) for GNU C.

This approach presents a couple of problems:
- One line of code generates many instructions, so if you want to anticipate a single instruction, it would probably not be possible (unless you use inline asm). Not a super big deal, but something to consider
- The compiler can move instructions across the label, i.e code under the label can be hoisted and vica versa. This makes it pretty unreliable. The only way to solve this is by adding `asm volatile("" ::: "memory");` above and below the label to clobber the compiler optimization


The simpler and more robust approach would be to use inline assembly for the AP, something like:
```C
void* trigger_addr;
int loaded_val;

asm volatile(
    "trigger_point%=:\n"          // local label
    "lw %1, 0(%2)\n"              // example of an anticipated instruction
    "la %0, trigger_point%=\n"    // capture its address
    : "=r"(trigger_addr), "=r"(loaded_val)
    : "r"(array_ptr)
    : "memory"
);
```

I would argue that it's kind of weird to be trying to anticipate specific instructions in a C program. So, maybe it's more useful to just put a no op here? In this way it would act more like a barrier mechanism.

# Example API

The following would theoretically generate something analogous to the assembly located in [approach_two.asm](../english_language_description_for_anticipation_mechanism/approach_two/approach_two.asm). PLEASE NOTE THIS IS PSEUDO CODE I WROTE LATE AT NIGHT
```C
//implementation of the APaction struct and other utils in a separate file
struct APaction {
    int active; //represents the active flag in IAPCTRL
    int APS; //represents the APS in IAPCTRL
    APhandler_t handler; //Can either be set to AP_IGN or a user-defined handler
}

//this ones useful to the programmer
#define AP_ACTIVE    0x20000001

//these should probably be hidden
#define AP_INACTIVE  0x20000000
#define IAPS_MASK    0x00000002


```

```C
//process code (executed by multiple threads on the same core)

struct APaction newaction;
newaction.active = AP_ACTIVE;
newaction.APS = 1;

void my_AP_handler(int APidx); 
newaction.handler = my_AP_handler


APaction(0, newaction) //assigns newactionto to AP of index 0.  Returns 0 on success and -1 on fail
                       //Note :Signals also use an old-action arg to get information about the previous information saved in AP index 0 but I left that out.

const uint32_t size_of_array = 12;
uint32_t array[size_of_array] = {123, 456, 789, 123, 456, 789, 123, 456, 789, 123, 456, 789};
uint32_t *boundary = array + 5; //half way point
uint32_t *arrEnd = array+size_of_array;

uint32_t total = 0;
uint32_t *i = array;
while(i != end) {
    AP_EXEC(0) //interrupt with AP 0
    total += array[i];
}

//GNU C signal handlers only take one param. Maybe we include an optional param for APSCRATCH? But also this should not have to be handled by the programmer
void my_AP_handler(int APidx) {
    if(i == boundary) {
        APRET(APidx)
    } 
}
```


## What is handled implicitly?
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


