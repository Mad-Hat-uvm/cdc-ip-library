#!/usr/bin/env python3
"""
AI Documentation Generator for CDC IP Library
---------------------------------------------
- Scans only RTL files changed in the latest commit (avoids redundancy).
- Generates Markdown summaries for those files.
- Uses the OpenAI API (v1 client).
"""

import os
import subprocess
import datetime
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

rtl_dir = "rtl"
output_file = "docs/auto_notes.md"

# Find RTL files changed in the latest commit
changed_files = subprocess.getoutput(
    "git diff --name-only HEAD~1 HEAD -- " + rtl_dir
).splitlines()

rtl_files = [f for f in changed_files if f.endswith(".sv")]

# Exit early if no RTL changes
if not rtl_files:
    print("[AI Doc Gen] No RTL changes detected. Skipping.")
    exit(0)

os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as f:
    f.write("# 🤖 AI-Generated Notes\n\n")
    f.write(f"_Generated on {datetime.datetime.utcnow().isoformat()} UTC_\n\n")

    for filepath in rtl_files:
        try:
            with open(filepath) as src:
                code = src.read()
        except Exception as e:
            f.write(f"## {filepath}\n\n⚠️ Could not read file: {e}\n\n")
            continue

        prompt = f"""You are an ASIC/FPGA verification engineer.
Summarize this SystemVerilog RTL module for documentation:

- Identify its function and purpose.
- Describe how inputs/outputs behave.
- Note parameters or reset/clocking details.
- State typical usage in a design.

Here is the code:
{code}
"""

        try:
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=1000,
                temperature=0.3
            )
            summary = response.choices[0].message.content.strip()
        except Exception as e:
            summary = f"(⚠️ AI doc generation failed: {e})"

        f.write(f"## {os.path.basename(filepath)}\n\n{summary}\n\n")

print(f"[AI Doc Gen] Wrote notes for {len(rtl_files)} changed file(s) to {output_file}")
