# Keywords
- Signal Handler - An invocation of such a
     function because of a signal, or (recursively) of any further functions called  by  that  invocation
     (other than functions in the standard library),

# Motivation
- Investigate signal handling in GNU C to determine how return handlers are implimented in interrupts versus returning via the SP
- Use GNU C's signal handling library as a basis for the AP API implementation
- Pick out pieces of the documentation that are relevant to the AP API implementation

# Sources
[Basic Concept of Signals](https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.5/html_node/Concepts-of-Signals.html#Concepts%20of%20Signals)
[Specifying Signal Actions](https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.5/html_node/Signal-Actions.html#Signal%20Actions)
[Signal Handling](https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.5/html_node/Signal-Handling.html#Signal%20Handling)
[Blocking Signals](https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.5/html_node/Blocking-Signals.html#Blocking%20Signals)

# API implementation 
GNU C primarily uses the `sigaction` function to specify how a signal should handled by a process (note that `signal` is another method but is only used for legacy code).

```C
int sigaction (int signum, const struct sigaction *restrict action, struct sigaction *restrict old-action)
```
the *sigaction* struct contains all information about how to handle a particular signal
```C
struct sigaction {
    sighandler_t sa_handler //the actual handler, which is usually a user-defined function pointer
    sigset_t sa_mask
    int sa_flags
}
```

## A note on blocking signals
The *sa_mask* member specifies the set of signals to be blocked while the handler runs. 
### Why is signal blocking useful?
- preventing race conditions between two signals that share data (note that this can probably be ignored since we are focusing on a single core for AP)

## Configuring a signal
the *sa_flags* member allows a list of flags to be set for a given signal. Below is a list of the ones that could be relevant to APs
- SARESTART - controls what happens when a signal is delivered during certain primitives (such as open, read or write), and the signal handler returns normally. There are two alternatives: the library function can resume, or it can return failure with error code EINTR. 
- SA_SIGINFO — causes the handler to receive two extra arguments: a siginfo_t pointer with detailed info about the signal (its cause, the sending PID, etc.), and a ucontext_t pointer. Requires the handler to be declared as void handler(int sig, siginfo_t *info, void *ucontext)




# Under the hood
## The signal Stack
Signals utilize a special area of memory as their execution stack
## Using sigreturn
sigreturn is the APRET of GNU C signal handling. It is used inside the signal trampoline to restore state.



