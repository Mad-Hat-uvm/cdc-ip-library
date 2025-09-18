#!/usr/bin/env python3
"""
AI Documentation Generator for CDC IP Library
---------------------------------------------
Scans the RTL folder and produces Markdown summaries
for each RTL file. Uses the OpenAI API (v1 client).
Always produces docs/auto_notes.md, even if no RTL is found.
"""

import os
import datetime
from openai import OpenAI

# Initialize OpenAI client with API key from environment
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Paths
rtl_dir = "rtl"
output_file = "docs/auto_notes.md"

# Make sure docs/ folder exists
os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as f:
    f.write("# 🤖 AI-Generated Notes\n\n")
    f.write(f"_Generated on {datetime.datetime.utcnow().isoformat()} UTC_\n\n")

    files_processed = 0

    # Process all .sv files in rtl/
    if os.path.exists(rtl_dir):
        for file in os.listdir(rtl_dir):
            if file.endswith(".sv"):
                files_processed += 1
                filepath = os.path.join(rtl_dir, file)

                try:
                    with open(filepath) as src:
                        code = src.read()
                except Exception as e:
                    f.write(f"## {file}\n\n⚠️ Could not read file: {e}\n\n")
                    continue

                if not code.strip():
                    summary = "⚠️ File is empty, no code to summarize."
                else:
                    prompt = f"""You are an ASIC/FPGA verification engineer.
Summarize this SystemVerilog module for documentation.

- Identify its function.
- Describe how the inputs/outputs behave.
- Mention any parameters or special reset/clock behavior.
- State typical use cases.

Here is the code:
{code}
"""
                    try:
                        response = client.chat.completions.create(
                            model="gpt-4o-mini",
                            messages=[{"role": "user", "content": prompt}],
                            max_tokens=300,
                            temperature=0.5
                        )
                        summary = response.choices[0].message.content.strip()
                    except Exception as e:
                        summary = f"(⚠️ AI doc generation failed: {e})"

                # Write per-file summary
                f.write(f"## {file}\n\n{summary}\n\n")

    # If no files processed, add a clear message
    if files_processed == 0:
        f.write("⚠️ No .sv files were found in rtl/. Please add RTL to generate documentation.\n")

print(f"[AI Doc Gen] Wrote notes to {output_file}")
