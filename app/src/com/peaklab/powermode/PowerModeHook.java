package com.peaklab.powermode;

import android.content.Context;
import android.view.View;
import android.widget.BaseAdapter;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;
import de.robv.android.xposed.XC_MethodHook;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.List;
import java.util.Locale;

/** Power Mode endpoint for the pico_power_coord_v2 last-writer-wins protocol. */
public class PowerModeHook implements IXposedHookLoadPackage {
    public static final String TAG = "PicoLabPower";
    private static final String PREFIX = "pico_power_coord_v2_";
    private static final String REQUEST = PREFIX + "request";
    private static final String ACK = PREFIX + "ack";
    private static final String EFFECTIVE_OWNER = PREFIX + "effective_owner";
    private static final String PHASE = PREFIX + "phase";
    private static final String ERROR = PREFIX + "error";
    private static volatile boolean sPowerMenuOpen;
    private static volatile Object sFragment;
    private static volatile ClassLoader sLoader;
    private static volatile Thread sWorker;
    private static volatile Thread sPoller;

    static final class Request {
        final String raw, token, owner, payload;
        final int mode;
        Request(String raw, String token, String owner, int mode) {
            this.raw = raw; this.token = token; this.owner = owner;
            this.payload = String.valueOf(mode); this.mode = mode;
        }
    }

    // Pure protocol logic, deliberately package-private for the host-side main test.
    static Request parseRequest(String raw) {
        if (raw == null) return null;
        String[] p = raw.split("\\|", -1);
        if (p.length != 4 || !"2".equals(p[0]) || p[1].length() == 0 || !"power".equals(p[2])) return null;
        try { int mode = Integer.parseInt(p[3]);
            if (mode < 0 || mode > 2) return null;
            return new Request(raw, p[1], p[2], mode);
        } catch (NumberFormatException e) { return null; }
    }
    static boolean isExactAck(Request r, String ack) { return r != null && r.raw.equals(ack); }
    static boolean shouldCommitUi(boolean applied, Request r, String current) { return applied && r != null && r.raw.equals(current); }
    static boolean vsleepMustWait(String owner, int active, int snapshot, String phase) {
        return active == 1 || snapshot == 1 || "restoring".equals(phase) || "vsleep".equals(owner);
    }
    static boolean mayApply(Request r, String current, String ack, String owner, int active, int snapshot, String phase, boolean handoff) {
        if (r == null || !r.raw.equals(current)) return false;
        // A handoff is acknowledged by V-Sleep only after its snapshot is gone.
        if (vsleepMustWait(owner, active, snapshot, phase)) return false;
        return !handoff || isExactAck(r, ack);
    }

    @Override public void handleLoadPackage(final XC_LoadPackage.LoadPackageParam lp) {
        if (!"com.picovr.settings".equals(lp.packageName)) return;
        final Class<?> frag;
        try { frag = XposedHelpers.findClass("com.picovr.fragments.PicolabFragment", lp.classLoader); }
        catch (Throwable t) { XposedBridge.log(TAG + ": no PicolabFragment " + t); return; }
        sLoader = lp.classLoader;
        try {
            XposedHelpers.findAndHookMethod(frag, "T0", View.class, new XC_MethodHook() {
                @Override protected void beforeHookedMethod(MethodHookParam p) { sPowerMenuOpen = true; }
                @Override protected void afterHookedMethod(MethodHookParam p) { sPowerMenuOpen = false; }
            });
        } catch (Throwable t) { XposedBridge.log(TAG + ": T0 hook err " + t); }
        try {
            Class<?> helper = XposedHelpers.findClass("com.picovr.customviews.PopupMenuHelper", lp.classLoader);
            Class<?> listener = XposedHelpers.findClass("com.picovr.listener.SimpleOnItemClickListener", lp.classLoader);
            XposedHelpers.findAndHookMethod(helper, "c", android.app.Activity.class, View.class, BaseAdapter.class, listener, int.class, new XC_MethodHook() {
                @Override protected void beforeHookedMethod(MethodHookParam p) {
                    if (!sPowerMenuOpen) return;
                    try {
                        BaseAdapter adapter = (BaseAdapter) p.args[2]; if (adapter == null) return;
                        Field f = null; for (Field fd : adapter.getClass().getDeclaredFields()) if (fd.getType() == List.class) { f = fd; break; }
                        if (f == null) return; f.setAccessible(true); List data = (List) f.get(adapter); if (data.size() >= 3) return;
                        Class<?> type = XposedHelpers.findClass("com.bytedance.osui.popupmenu.MenuItemType", lp.classLoader);
                        Object item = XposedHelpers.findClass("com.bytedance.osui.popupmenu.MenuItemData", lp.classLoader)
                                .getConstructor(type).newInstance(Enum.valueOf((Class<? extends Enum>) type, "TYPE_TITLE_CHECK"));
                        item.getClass().getMethod("l", CharSequence.class).invoke(item, getLocalizedString((Context) p.args[0]));
                        data.add(item); adapter.notifyDataSetChanged();
                    } catch (Throwable t) { XposedBridge.log(TAG + ": inject menu err " + t); }
                    finally { sPowerMenuOpen = false; }
                }
            });
        } catch (Throwable t) { XposedBridge.log(TAG + ": menu hook err " + t); }
        try {
            XposedHelpers.findAndHookMethod(frag, "U0", int.class, new XC_MethodHook() {
                @Override protected void beforeHookedMethod(MethodHookParam p) {
                    int mode = (Integer) p.args[0]; if (mode < 0 || mode > 2) return;
                    try {
                        Object a = XposedHelpers.callMethod(p.thisObject, "getActivity");
                        if (!(a instanceof Context)) throw new IllegalStateException("no Settings context");
                        sFragment = p.thisObject; submit((Context) a, mode, p.thisObject, lp.classLoader);
                    } catch (Throwable t) { XposedBridge.log(TAG + ": U0 submit failed " + t); }
                    p.setResult(null);
                }
            });
        } catch (Throwable t) { XposedBridge.log(TAG + ": U0 hook err " + t); }
        try {
            XposedHelpers.findAndHookMethod(frag, "Q", int.class, new XC_MethodHook() {
                @Override protected void beforeHookedMethod(MethodHookParam p) {
                    int mode = (Integer) p.args[0]; Object a = XposedHelpers.callMethod(p.thisObject, "getActivity");
                    if (a instanceof Context) {
                        startPoller((Context) a, p.thisObject);
                        if (isVsleepVisible((Context) a)) p.setResult("V-Sleep 生效中（基础档位: " + getInt((Context) a, "powerlevel", mode) + "）");
                        else if (mode == 2) p.setResult(getLocalizedString((Context) a));
                    }
                }
            });
        } catch (Throwable t) { XposedBridge.log(TAG + ": Q hook err " + t); }
        XposedBridge.log(TAG + ": v2 hooks installed");
    }

    private static void submit(final Context c, final int mode, final Object fragment, final ClassLoader cl) throws Exception {
        final String raw = "2|" + Long.toHexString(System.nanoTime()) + "|power|" + mode;
        put(c, REQUEST, raw); put(c, PHASE, "requested"); put(c, ERROR, "");
        Thread old = sWorker; if (old != null) old.interrupt();
        sWorker = new Thread(new Runnable() { @Override public void run() { coordinate(c, raw, mode, fragment, cl); } }, "PicoPowerCoord");
        sWorker.start();
    }
    private static void coordinate(Context c, String raw, int mode, Object fragment, ClassLoader cl) {
        Request r = parseRequest(raw); long end = System.currentTimeMillis() + 30000;
        try {
            while (System.currentTimeMillis() < end && !Thread.currentThread().isInterrupted()) {
                String current = get(c, REQUEST); String owner = get(c, EFFECTIVE_OWNER);
                int active = "active".equals(get(c, PHASE)) && "vsleep".equals(owner) ? 1 : 0;
                int snapshot = "restoring".equals(get(c, PHASE)) ? 1 : 0;
                String phase = get(c, PHASE); String ack = get(c, ACK);
                boolean handoff = "vsleep".equals(owner) || "restoring".equals(phase) || active != 0 || snapshot != 0;
                if (!raw.equals(current)) return;
                if (mayApply(r, current, ack, owner, active, snapshot, phase, handoff)) break;
                Thread.sleep(100);
            }
            if (Thread.currentThread().isInterrupted() || !raw.equals(get(c, REQUEST))) return;
            put(c, PHASE, "applying"); applyPowerMode(c, mode, cl);
            if (!raw.equals(get(c, REQUEST))) return;
            put(c, EFFECTIVE_OWNER, "power:" + mode); put(c, PHASE, "active"); put(c, ACK, raw); put(c, ERROR, "");
            updateUi(c, fragment, mode);
        } catch (Throwable t) {
            if (raw.equals(get(c, REQUEST))) { put(c, PHASE, "error"); put(c, ERROR, String.valueOf(t.getMessage())); restoreUi(c, fragment); }
            XposedBridge.log(TAG + ": request failed " + t);
        }
    }
    private static void applyPowerMode(Context c, int mode, ClassLoader cl) throws Exception {
        Class<?> dsu = XposedHelpers.findClass("com.picovr.settings.custom.DeviceSwitchUtilsKt", cl);
        dsu.getMethod("e", Context.class, int.class).invoke(null, c, mode);
        String expected = mode == 2 ? "2448" : "1504"; setProp("persist.pvr.config.eyebuffer_width", expected); setProp("persist.pvr.config.eyebuffer_height", expected);
        if (getProp("persist.pvr.config.eyebuffer_width").equals(expected) == false || !getProp("persist.pvr.config.eyebuffer_height").equals(expected)) throw new IllegalStateException("eyebuffer verification failed");
        if (getInt(c, "powerlevel", -1) != mode) throw new IllegalStateException("powerlevel verification failed");
    }
    private static void updateUi(final Context c, final Object f, final int mode) { post(f, new Runnable() { public void run() { try { Field m = f.getClass().getDeclaredField("m"); m.setAccessible(true); m.setInt(f, mode); Method v = f.getClass().getDeclaredMethod("V", int.class); v.setAccessible(true); v.invoke(f, mode); } catch (Throwable t) { XposedBridge.log(TAG + ": UI update failed " + t); } } }); }
    private static void restoreUi(final Context c, final Object f) { final int actual = getInt(c, "powerlevel", 0); post(f, new Runnable() { public void run() { try { Field m = f.getClass().getDeclaredField("m"); m.setAccessible(true); m.setInt(f, actual); Method v = f.getClass().getDeclaredMethod("V", int.class); v.setAccessible(true); v.invoke(f, actual); } catch (Throwable ignored) {} } }); }
    private static void post(Object f, Runnable r) { try { f.getClass().getMethod("getActivity").invoke(f).getClass().getMethod("runOnUiThread", Runnable.class).invoke(f.getClass().getMethod("getActivity").invoke(f), r); } catch (Throwable ignored) {} }
    private static boolean isVsleepVisible(Context c) { String owner = get(c, EFFECTIVE_OWNER), phase = get(c, PHASE); return "vsleep".equals(owner) || "restoring".equals(phase); }
    private static synchronized void startPoller(final Context c, final Object f) {
        if (sPoller != null && sPoller.isAlive()) return;
        sPoller = new Thread(new Runnable() { public void run() {
            while (!Thread.currentThread().isInterrupted()) {
                try { Thread.sleep(750); if (isVsleepVisible(c)) updateUi(c, f, getInt(c, "powerlevel", 0)); }
                catch (InterruptedException e) { return; } catch (Throwable ignored) { }
            }
        }}, "PicoPowerCoordPoll");
        sPoller.setDaemon(true); sPoller.start();
    }
    private static void put(Context c, String k, String v) { try { Class g = Class.forName("android.provider.Settings$Global"); g.getMethod("putString", Class.forName("android.content.ContentResolver"), String.class, String.class).invoke(null, c.getContentResolver(), k, v); } catch (Throwable t) { throw new RuntimeException(t); } }
    private static String get(Context c, String k) { try { Class g = Class.forName("android.provider.Settings$Global"); return (String) g.getMethod("getString", Class.forName("android.content.ContentResolver"), String.class).invoke(null, c.getContentResolver(), k); } catch (Throwable t) { return null; } }
    private static int getInt(Context c, String k, int d) { try { Class g = Class.forName("android.provider.Settings$Global"); return (Integer) g.getMethod("getInt", Class.forName("android.content.ContentResolver"), String.class, int.class).invoke(null, c.getContentResolver(), k, d); } catch (Throwable t) { return d; } }
    private static void setProp(String k, String v) throws Exception { Class p = Class.forName("android.os.SystemProperties"); p.getMethod("set", String.class, String.class).invoke(null, k, v); }
    private static String getProp(String k) { try { return (String) Class.forName("android.os.SystemProperties").getMethod("get", String.class).invoke(null, k); } catch (Throwable t) { return ""; } }

    private static String getLocalizedString(Context context) {
        if (context == null) return "性能模式";
        try {
            Object res = XposedHelpers.callMethod(context, "getResources");
            Object config = XposedHelpers.callMethod(res, "getConfiguration");
            Locale l = (Locale) XposedHelpers.getObjectField(config, "locale");
            String lang = l.getLanguage(), country = l.getCountry();
            switch (lang) {
                case "cs": return "Výkonný režim"; case "da": return "Ydelsestilstand";
                case "nl": return "Prestatiemodus"; case "fi": return "Suorituskykytila";
                case "fr": return "Mode performance"; case "de": return "Leistungsmodus";
                case "el": return "Λειτουργία απόδοσης"; case "it": return "Modalità prestazioni";
                case "ja": return "パフォーマンスモード"; case "ko": return "성능 모드";
                case "ms": return "Mod Prestasi"; case "nb": case "no": return "Ytelsesmodus";
                case "pl": return "Tryb wydajności"; case "pt": return "Modo de desempenho";
                case "ro": return "Mod de performanță"; case "ru": return "Режим производительности";
                case "es": return "Modo de rendimiento"; case "sv": return "Prestandaläge";
                case "th": return "Performance Mode"; case "tr": return "Performans Modu";
                case "zh": return ("TW".equals(country) || "HK".equals(country) || "MO".equals(country)) ? "效能模式" : "性能模式";
                default: return "Performance Mode";
            }
        } catch (Throwable t) { return "性能模式"; }
    }
}
