# APACTION

## NAME

`apregister`, `apunregister` - assign an anticipation point handler to an instruction address

## SYNOPSIS

    #include <ap.h>

    int apregister(uintptr_t aptrig, struct apaction *ap);
    int apunregister(uintptr_t aptrig, aphandler_t aptar);

## DESCRIPTION

The **apregister**() and **apunregister**() functions allow the caller to register and unregister anticipation point handlers to specific instruction addresses. The argument `aptrig` specifies the instruction address that will be preempted by the anticipation point handler.

The structure `apaction`, used to describe an action to be taken, is defined in the `<ap.h>` header to include the following members:

| Member Type          | Member Name | Description                                                         |
|----------------------|-------------|---------------------------------------------------------------------|
| `void(*) (int)`      | `ap_handler`| Pointer to an anticipation point handler function.                  |
| `int`                | `active`    | A read/write bit that enables or disables the selected anticipation point. |
| `int`                | `APS`       | Anticipation Point Semaphore – bypasses anticipation point *n* times. |

Registering the same AP handler to the same instruction address multiple times is equivalent to replacing the already assigned AP handler with the new one.

Multiple anticipation point handlers can be registered to the same instruction address, and the order in which they are executed when triggered is non-deterministic.

**Note:**  
It is the programmer's responsibility to keep track of which APs are assigned to which instruction address.

## RETURN VALUE

On success, **apregister**() and **apunregister**() return 0. On error, -1 is returned.
