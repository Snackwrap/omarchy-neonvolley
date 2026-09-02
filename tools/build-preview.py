#!/usr/bin/env python3
"""Generate tools/promo.html — the marketplace card — with scene captures inlined."""
import base64
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
TABS = ROOT / "assets" / "tabs"

# Popup width is fixed; height varies slightly — crop a common band from the top.
BAND = 620

PANELS = [
    ("menu.png",     "MENU",      "synthwave attract screen and mode picker"),
    ("play.png",     "IN PLAY",   "mid-rally scoreboard, serve arrow, ball trail"),
    ("gameover.png", "MATCH END", "winner overlay and persistent match tally"),
]


def uri(name):
    src = TABS / name
    out = subprocess.run(
        ["magick", str(src), "-crop", f"880x{BAND}+0+0", "+repage", "png:-"],
        check=True, capture_output=True).stdout
    return "data:image/png;base64," + base64.b64encode(out).decode()


cards = "\n".join(
    f'''      <figure class="card">
        <div class="shot"><img src="{uri(f)}" alt="{label}"></div>
        <figcaption><b>{label}</b> {note}</figcaption>
      </figure>''' for f, label, note in PANELS)

HTML = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  * {{ margin:0; padding:0; box-sizing:border-box; }}
  body {{ width:1600px; height:1000px; background:#05050c; overflow:hidden;
         font-family:'JetBrainsMono Nerd Font','JetBrainsMono NF',monospace; position:relative; }}
  body::before {{ content:""; position:absolute; inset:0;
    background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(255,0,110,.03) 2px,rgba(255,0,110,.03) 4px);
    pointer-events:none; }}
  .glow {{ position:absolute; width:900px; height:900px; border-radius:50%;
           background:radial-gradient(circle,rgba(255,0,110,.14) 0%,transparent 70%);
           right:-180px; top:-260px; }}
  .wrap {{ position:relative; display:flex; height:100%; padding:66px 60px; gap:52px; align-items:center; }}
  .left {{ width:566px; flex:none; }}
  .brand {{ display:flex; align-items:center; gap:13px; margin-bottom:30px; }}
  .brand .mark {{ color:#FF006E; font-size:24px; font-weight:800; letter-spacing:2px; }}
  .brand .word {{ color:#5A1030; font-size:15px; font-weight:700; letter-spacing:6px; }}
  h1 {{ color:#FF4D9A; font-size:44px; line-height:1.14; font-weight:800; letter-spacing:-0.5px; }}
  h1 .acc {{ color:#00F5FF; text-shadow:0 0 24px rgba(0,245,255,.35); }}
  .sub {{ color:#9D174D; font-size:17px; line-height:1.55; margin-top:19px; }}
  .modes {{ display:flex; gap:10px; margin-top:28px; }}
  .mode {{ flex:1; border-radius:7px; padding:10px 8px; text-align:center;
           border:1px solid rgba(255,0,110,.28); background:rgba(255,0,110,.06); }}
  .mode b {{ display:block; font-size:14px; font-weight:800; letter-spacing:1px; color:#FF4D9A; }}
  .mode span {{ display:block; color:#5A1030; font-size:10.5px; margin-top:4px; letter-spacing:.4px; }}
  .feat {{ list-style:none; margin-top:28px; }}
  .feat li {{ color:#c4708f; font-size:15.5px; line-height:1.5; margin-bottom:12px;
              padding-left:22px; position:relative; }}
  .feat li::before {{ content:"\\25B8"; color:#00F5FF; font-weight:700; position:absolute; left:0; }}
  .feat b {{ color:#FF4D9A; }}
  .install {{ margin-top:30px; display:inline-block; background:#0a0a12; border:1px solid #2a1020;
             border-radius:9px; padding:13px 19px; color:#c4708f; font-size:14px; white-space:nowrap; }}
  .install .p {{ color:#5A1030; }} .install .c {{ color:#00F5FF; }}
  .grid {{ flex:1; display:grid; grid-template-columns:1fr 1fr; gap:26px 24px; }}
  .grid .card:last-child {{ grid-column:1 / -1; max-width:calc(50% - 12px); justify-self:center; }}
  .card .shot {{ border-radius:9px; border:1px solid rgba(255,0,110,.35); overflow:hidden;
                box-shadow:0 18px 44px rgba(0,0,0,.65), 0 0 40px rgba(255,0,110,.08);
                -webkit-mask-image:linear-gradient(to bottom,#000 82%,transparent 100%);
                mask-image:linear-gradient(to bottom,#000 82%,transparent 100%); }}
  .card .shot img {{ display:block; width:100%; }}
  .card figcaption {{ margin-top:11px; color:#5A1030; font-size:13px; letter-spacing:.3px; }}
  .card figcaption b {{ color:#FF006E; letter-spacing:2.2px; margin-right:9px; }}
</style></head><body>
  <div class="glow"></div>
  <div class="wrap">
    <div class="left">
      <div class="brand"><span class="mark">NV</span><span class="word">NEON VOLLEY &middot; FOR OMARCHY</span></div>
      <h1>Mini tennis in the bar.<br><span class="acc">Neon grid, real rallies.</span></h1>
      <div class="sub">A cyberpunk court in your Omarchy bar — 1P vs CPU or local 2P, chiptune SFX, and a match-win scoreboard that sticks around.</div>
      <div class="modes">
        <div class="mode"><b>1P VS CPU</b><span>Easy &middot; Normal &middot; Hard</span></div>
        <div class="mode"><b>2P LOCAL</b><span>keyboard split controls</span></div>
      </div>
      <ul class="feat">
        <li><b>Power shots</b> &mdash; swing early for extra pace</li>
        <li><b>Match tracker</b> &mdash; wins persist across sessions</li>
        <li><b>Sound, difficulty, popup position</b> &mdash; all configurable from the CLI</li>
      </ul>
      <div class="install"><span class="p">$</span> omarchy plugin add <span class="c">github.com/Snackwrap/omarchy-neonvolley</span></div>
    </div>
    <div class="grid">
{cards}
    </div>
  </div>
</body></html>"""

(ROOT / "tools" / "promo.html").write_text(HTML, encoding="utf-8")
print("tools/promo.html written")
