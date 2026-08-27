package com.peaklab.powermode;

/** Lightweight Java 8 main test; run with the compiled hook and no Android runtime. */
public final class PowerModeHookProtocolTest {
    private static void check(boolean value, String name) { if (!value) throw new AssertionError(name); }
    public static void main(String[] args) {
        PowerModeHook.Request first = PowerModeHook.parseRequest("2|a|power|1");
        PowerModeHook.Request later = PowerModeHook.parseRequest("2|b|power|2");
        check(first != null && later != null, "parse");
        check(!PowerModeHook.mayApply(first, later.raw, first.raw, "", 0, 0, "idle", false), "later request wins");
        check(PowerModeHook.isExactAck(later, later.raw), "exact ack");
        check(!PowerModeHook.isExactAck(later, "2|b|power|1"), "ack payload exact");
        check(!PowerModeHook.mayApply(later, later.raw, later.raw, "vsleep", 1, 0, "active", true), "active sleep waits");
        check(!PowerModeHook.mayApply(later, later.raw, later.raw, "vsleep", 0, 1, "restoring", true), "snapshot restore waits");
        check(!PowerModeHook.mayApply(later, later.raw, "2|old|power|2", "", 0, 0, "idle", true), "mismatched ack waits");
        check(!PowerModeHook.shouldCommitUi(false, later, later.raw), "failure does not update UI");
        check(PowerModeHook.shouldCommitUi(true, later, later.raw), "success updates UI");
        System.out.println("PowerModeHookProtocolTest OK");
    }
}
