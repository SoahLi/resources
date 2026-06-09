#include "ap.h"

ap_entry_t ap_table[AP_MAX_ENTRIES];
uint64_t free_mask = ~0ULL; //1 means free, 0 means used


 int ap_reg(uintptr_t ap_addr, void(*ap_handler) (uint8_t), uint8_t ap_flags) {

 }
 //int ap_ureg(uintptr_t ap_addr, void(*ap_handler)(uint8_t));
 //int ap_sret(uintptr_t r_addr);
