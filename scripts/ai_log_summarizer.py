#!/usr/bin/env python3
"""
AI Log Summarizer for CDC IP Library
------------------------------------
Scans the logs/ directory, detects errors/warnings,
and uses OpenAI to generate human-readable summaries.
"""

import os, openai

openai.api_key = os.getenv("OPENAI_API_KEY")

log_dir = "logs"
output_file = "docs/log_summaries.md"

if not os.path.exists(log_dir):
    print("[AI Log Summarizer] No logs directory found. Skipping.")
    exit(0)

os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as out:
    out.write("# 🤖 AI Log Summaries\n\n")
    out.write("This file contains AI-generated summaries of simulation logs.\n\n")

    for file in os.listdir(log_dir):
        if file.endswith(".log"):
            filepath = os.path.join(log_dir, file)
            with open(filepath) as f:
                log_content = f.read()

            # Only summarize if there are errors/warnings
            if "ERROR" in log_content or "FATAL" in log_content:
                prompt = f"Summarize the following simulation log in plain English. Focus on why the test failed and suggest possible causes:\n\n{log_content[:4000]}\n\n"
                try:
                    response = openai.ChatCompletion.create(
                        model="gpt-4o-mini",
                        messages=[{"role": "user", "content": prompt}],
                        max_tokens=300
                    )
                    summary = response.choices[0].message["content"].strip()
                except Exception as e:
                    summary = f"(AI log summarization failed: {e})"

                out.write(f"## {file}\n\n{summary}\n\n")

print(f"[AI Log Summarizer] Wrote summaries to {output_file}")
