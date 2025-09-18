#!/usr/bin/env python3
"""
AI Documentation Generator for CDC IP Library
---------------------------------------------
Scans the RTL folder and produces Markdown summaries
for each RTL file. Uses the OpenAI API (new v1 client) for summaries.
"""

import os
import datetime
from openai import OpenAI

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Paths
rtl_dir = "rtl"
output_file = "docs/auto_notes.md"

# Make sure output folder exists
os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as f:
    f.write("# 🤖 AI-Generated Notes\n\n")
    f.write(f"_Generated on {datetime.datetime.utcnow().isoformat()} UTC_\n\n")

    for file in os.listdir(rtl_dir):
        if file.endswith(".sv"):
            filepath = os.path.join(rtl_dir, file)
            with open(filepath) as src:
                code = src.read()

            # Improved prompt for engineering-quality summaries
            prompt = f"""You are an ASIC/FPGA verification engineer.
Summarize the following SystemVerilog module for technical documentation.

- Identify its function.
- Describe how the inputs/outputs behave.
- Mention key parameters or special reset/clock behavior.
- State when or why this module would be used.

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

            # Write to markdown
            f.write(f"## {file}\n\n{summary}\n\n")

print(f"[AI Doc Gen] Wrote notes to {output_file}")
