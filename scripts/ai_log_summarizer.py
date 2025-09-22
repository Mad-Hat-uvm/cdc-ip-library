#!/usr/bin/env python3
"""
AI Log Summarizer for CDC IP Library
------------------------------------
Scans the logs/ directory, detects assertion failures or errors,
and uses OpenAI to generate human-readable summaries.
Always produces docs/log_summaries.md.
"""

import os
import datetime
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

log_dir = "logs"
output_file = "docs/log_summaries.md"

if not os.path.exists(log_dir):
    print("[AI Log Summarizer] No logs directory found. Skipping.")
    exit(0)

os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as out:
    out.write("# 🤖 AI Log Summaries\n\n")
    out.write(f"_Generated on {datetime.datetime.utcnow().isoformat()} UTC_\n\n")

    for file in os.listdir(log_dir):
        if file.endswith(".log"):
            filepath = os.path.join(log_dir, file)
            with open(filepath) as f:
                log_content = f.read()

            # Grab only lines of interest (assertion failures / errors)
            important_lines = [
                line for line in log_content.splitlines()
                if ("assert" in line.lower()
                    or "failed" in line.lower()
                    or "offending" in line.lower()
                    or "error" in line.lower())
            ]

            if important_lines:
                snippet = "\n".join(important_lines[:1000])  # cap length
                prompt = f"""You are an ASIC/FPGA verification engineer.
Summarize the following simulation failures for a log report.
Focus on:
- Which assertions failed
- At what times
- Likely reasons (timing, reset, CDC behavior)

Log snippet:
{snippet}
"""
            else:
                # Fallback: no clear failures found
                snippet = log_content[:2000]  # capture start of log
                prompt = f"""Summarize this simulation log in plain English.
Mention if simulation ran to completion and note any warnings.

Log snippet:
{snippet}
"""

            try:
                response = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=300,
                    temperature=0.3
                )
                summary = response.choices[0].message.content.strip()
            except Exception as e:
                summary = f"(⚠️ AI log summarization failed: {e})"

            out.write(f"## {file}\n\n{summary}\n\n")

print(f"[AI Log Summarizer] Wrote summaries to {output_file}")
