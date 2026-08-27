# Runtime Coordination

This module is the Power Mode endpoint for protocol `pico_power_coord_v2` through `Settings.Global`.

The endpoint publishes exactly one last-writer-wins request in the format `2|token|power|payload` where payload is one of `0`, `1`, or `2` under `pico_power_coord_v2_request`. It consumes `pico_power_coord_v2_ack`, `pico_power_coord_v2_effective_owner`, `pico_power_coord_v2_phase`, and `pico_power_coord_v2_error`. A newer request interrupts the previous worker. During V-Sleep ownership, an active transaction, snapshot cleanup, or `restoring` phase, no official switch, eye-buffer write, or UI field update occurs. A handoff requires an exact matching ack and completed cleanup. V-Sleep publishes the matching ack before changing the effective owner, so Power Mode cannot apply during the final cleanup race.

When no V-Sleep transaction exists, the request is applied asynchronously with `DeviceSwitchUtilsKt.e`, then eye-buffer is forced to 1504 for levels 0/1 or 2448 for level 2. `powerlevel` and eye-buffer are verified before `effective_owner=power:<mode>`, `phase=active`, and the matching ack are committed. Failures publish `phase=error` and restore the actual level in the visible UI.

This protocol targets PICO 4 A8110 firmware `5.13.7`. Version 1.2 uses version code 3.
