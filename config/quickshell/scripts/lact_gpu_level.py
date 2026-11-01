# Sets the AMD GPU level via LACT. Arg: auto|low|high|manual
import json, socket, sys
lvl = sys.argv[1]
def call(req):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect("/run/lactd.sock")
    s.sendall((json.dumps(req) + "\n").encode())
    buf = b""
    while not buf.endswith(b"\n"):
        c = s.recv(65536)
        if not c:
            break
        buf += c
    s.close()
    return json.loads(buf.decode() or "{}")
try:
    devs = call({"command": "list_devices"})
    ids = [d["id"] for d in (devs.get("data") or [])]
    if not ids:
        print("GPU:nodev"); sys.exit(0)
    amd = [i for i in ids if i.upper().startswith("1002:")]
    if not amd:
        print("GPU:nodev"); sys.exit(0)
    if lvl == "get":
        # Current level of the first AMD GPU, as low|medium|high
        g = call({"command": "get_gpu_config", "args": {"id": amd[0]}})
        cur = ((g.get("data") or {}).get("performance_level") or "auto") if g.get("status") == "ok" else ""
        print("GPU:" + {"low": "low", "high": "high", "auto": "medium"}.get(cur, "medium" if cur else "err"))
        sys.exit(0)
    ok = True
    changed = False
    for i in amd:
        g = call({"command": "get_gpu_config", "args": {"id": i}})
        if g.get("status") != "ok":
            ok = False; print("get_gpu_config:", json.dumps(g), file=sys.stderr); continue
        cfg = g.get("data") or {}
        cfg["performance_level"] = lvl
        if lvl != "manual":
            cfg.pop("power_profile_mode_index", None)
        r = call({"command": "set_gpu_config", "args": {"id": i, "config": cfg}})
        if r.get("status") != "ok":
            ok = False; print("set_gpu_config:", json.dumps(r), file=sys.stderr); continue
        changed = True
    if changed:
        r = call({"command": "confirm_pending_config", "args": {"command": "confirm"}})
        if r.get("status") != "ok":
            ok = False; print("confirm_pending_config:", json.dumps(r), file=sys.stderr)
    print("GPU:" + (lvl if ok else "err"))
except Exception as e:
    print("GPU:err")
    print("lact:", e, file=sys.stderr)
