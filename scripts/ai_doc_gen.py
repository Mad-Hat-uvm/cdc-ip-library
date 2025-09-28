#!/usr/bin/env python3
"""
AI Documentation Generator for CDC IP Library
---------------------------------------------
- Scans only RTL files changed vs origin/main (avoids redundancy).
- Generates Markdown summaries for those files.
"""

import os
import subprocess
import datetime
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

rtl_dir = "rtl"
output_file = "docs/auto_notes.md"

# Compare against origin/main instead of last commit
changed_files = subprocess.getoutput(
    f"git diff --name-only origin/main HEAD -- {rtl_dir}"
).splitlines()

rtl_files = [f for f in changed_files if f.endswith(".sv")]

if not rtl_files:
    print("[AI Doc Gen] No RTL changes detected. Skipping.")
    exit(0)

os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as f:
    f.write("# 🤖 AI-Generated Notes\n\n")
    f.write(f"_Generated on {datetime.datetime.now(datetime.UTC).isoformat()}_\n\n")

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
