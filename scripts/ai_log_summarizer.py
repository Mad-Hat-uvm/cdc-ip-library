#!/usr/bin/env python3
"""
AI Log Summarizer for CDC IP Library
------------------------------------
Scans the logs/ directory, summarizes error logs using the OpenAI API (new v1 client),
and writes them into docs/log_summaries.md.
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

with open(output_file, "w") as f:
    f.write("# 🤖 AI Log Summaries\n\n")
    f.write(f"_Generated on {datetime.datetime.utcnow().isoformat()} UTC_\n\n")

    for file in os.listdir(log_dir):
        if file.endswith(".log"):
            filepath = os.path.join(log_dir, file)
            with open(filepath) as src:
                log_content = src.read()

            if not log_content.strip():
                continue

            prompt = f"Summarize the following simulation log in plain English. Focus on why the test failed and suggest possible causes:\n\n{log_content[:4000]}\n\n"

            try:
                response = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=300
                )
                summary = response.choices[0].message.content.strip()
            except Exception as e:
                summary = f"(AI log summarization failed: {e})"

            f.write(f"## {file}\n\n{summary}\n\n")

print(f"[AI Log Summarizer] Wrote summaries to {output_file}")
