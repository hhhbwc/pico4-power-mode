import os, sys, zipfile, hashlib
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

BASE = os.path.dirname(os.path.abspath(__file__))
MAG = os.path.join(BASE, "magisk")
BUILD = os.path.join(BASE, "build")
os.makedirs(BUILD, exist_ok=True)

ZIPNAME = "pico4-power-mode_tuner_magisk_v1.2.zip"

files = ["module.prop", "service.sh", "daemon.sh", "kill_daemon.sh", "tune.sh", "action.sh", "uninstall.sh", "README.md"]

def load(p):
    t = open(p, encoding="utf-8").read()
    return t.replace("\r\n", "\n").replace("\r", "\n")

zpath = os.path.join(BUILD, ZIPNAME)
with zipfile.ZipFile(zpath, "w") as z:
    for name in files:
        data = load(os.path.join(MAG, name)).encode("utf-8")
        zi = zipfile.ZipInfo(name)
        zi.date_time = (2026, 9, 16, 13, 30, 0)
        zi.compress_type = zipfile.ZIP_DEFLATED
        mode = 0o100755 if name.endswith(".sh") else 0o100644
        zi.external_attr = (mode << 16) | 0o20
        z.writestr(zi, data)

print("zip:", zpath, os.path.getsize(zpath))
print("md5   :", hashlib.md5(open(zpath, "rb").read()).hexdigest())
print("sha256:", hashlib.sha256(open(zpath, "rb").read()).hexdigest())
with zipfile.ZipFile(zpath) as z:
    for i in z.infolist():
        print(f"  {i.file_size:>8} {i.filename}")
    for i in z.infolist():
        if i.filename.endswith(".sh"):
            assert b"\r\n" not in z.read(i.filename), f"CRLF in {i.filename}"
    print("LF check OK")
print("COMPANION BUILD DONE")
