"""Appends a scenario to QuaX's links.json as text, so the rest of the file keeps its layout.

    python3 append_scenario.py <links.json> <scenario.json>
"""

import json
import re
import sys

links_path, scenario_path = sys.argv[1:]
with open(links_path, encoding="utf-8") as f:
    text = f.read()
with open(scenario_path, encoding="utf-8") as f:
    scenario = json.load(f)

# raw_decode reads the scenarios array only and says where it ends, closing bracket included.
start = re.search(r'"scenarios"\s*:\s*(?=\[)', text).end()
end = json.JSONDecoder().raw_decode(text, start)[1] - 1
entry = json.dumps(scenario, indent=2, ensure_ascii=False).replace("\n", "\n    ")
updated = f"{text[:end].rstrip()},\n    {entry}\n  {text[end:]}"

expected = json.loads(text)
expected["scenarios"].append(scenario)
if json.loads(updated) != expected:
    sys.exit(f"Could not append the scenario to {links_path}: its layout is unexpected")
with open(links_path, "w", encoding="utf-8") as f:
    f.write(updated)
