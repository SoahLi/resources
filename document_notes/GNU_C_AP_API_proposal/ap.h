
#include <stdint.h>

#define AP_MAX_ENTRIES 64

typedef struct {
    uintptr_t        addr;
    void           (*handler)(uint8_t);
    uint8_t          flags;
    uint8_t          hw_index;
} ap_entry_t;
extern ap_entry_t ap_table[];

extern uint64_t free_mask;
//extern unordered_map<pair<uintptr_t, void(*)(uint8_t)>, uint8_t> ap_index;
//either use a hash map, or just do linear search on the ap_table

 int ap_reg(uintptr_t ap_addr, void(*ap_handler) (uint8_t), uint8_t ap_flags);
 int ap_ureg(uintptr_t ap_addr, void(*ap_handler)(uint8_t));
 int ap_sret(uintptr_t r_addr);
