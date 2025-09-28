#!/usr/bin/env python3
"""
AI Documentation Generator for CDC IP Library
---------------------------------------------
- Summarizes *all* RTL files in rtl/ each run (avoids diff confusion).
- Overwrites docs/auto_notes.md cleanly.
"""

import os, datetime
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

rtl_dir = "rtl"
output_file = "docs/auto_notes.md"

rtl_files = [os.path.join(rtl_dir, f) for f in os.listdir(rtl_dir) if f.endswith(".sv")]

if not rtl_files:
    print("[AI Doc Gen] No RTL files found. Skipping.")
    exit(0)

os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as f:
    f.write("# 🤖 AI-Generated Notes\n\n")
    f.write(f"_Generated on {datetime.datetime.now(datetime.UTC).isoformat()}_\n\n")

    for filepath in rtl_files:
        with open(filepath) as src:
            code = src.read()

        prompt = f"""You are an ASIC/FPGA verification engineer.
Summarize this SystemVerilog RTL module for documentation:
- Function and purpose
- I/O behavior
- Parameters, clocking, reset details
- Typical usage

Here is the code:
{code}
"""
        try:
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=3000,
                temperature=0.3
            )
            summary = response.choices[0].message.content.strip()
        except Exception as e:
            summary = f"(⚠️ Doc generation failed: {e})"

        f.write(f"## {os.path.basename(filepath)}\n\n{summary}\n\n")

print(f"[AI Doc Gen] Wrote notes for {len(rtl_files)} file(s) to {output_file}")
