#!/usr/bin/env python3
"""
AI Log Summarizer for CDC IP Library
------------------------------------
- Scans only log files changed vs origin/main.
- Adds PASS/FAIL/INCONCLUSIVE verdicts before AI summary.
"""

import os
import subprocess
import datetime
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

log_dir = "logs"
output_file = "docs/log_summaries.md"

# Compare against origin/main
changed_logs = subprocess.getoutput(
    f"git diff --name-only origin/main HEAD -- {log_dir}"
).splitlines()

log_files = [f for f in changed_logs if f.endswith(".log") and os.path.exists(f)]

if not log_files:
    print("[AI Log Summarizer] No new/changed logs detected. Skipping.")
    exit(0)

os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as out:
    out.write("# 🤖 AI Log Summaries\n\n")
    out.write(f"_Generated on {datetime.datetime.now(datetime.UTC).isoformat()}_\n\n")

    for filepath in log_files:
        with open(filepath) as f:
            log_content = f.read()

        # Triage verdict
        if "FAILED" in log_content or "$error" in log_content:
            verdict = "❌ TEST FAILED"
        elif "Assertion" in log_content and "FAILED" in log_content:
            verdict = "❌ Assertion failures detected"
        elif "Finished" in log_content or "$finish" in log_content:
            verdict = "✅ TEST PASSED (no assertion failures)"
        else:
            verdict = "⚠️ INCONCLUSIVE (no clear PASS/FAIL markers)"

        # Extract important lines
        important_lines = [
            line for line in log_content.splitlines()
            if ("assert" in line.lower()
                or "failed" in line.lower()
                or "error" in line.lower()
                or "offending" in line.lower())
        ]
        snippet = "\n".join(important_lines[:1000]) if important_lines else log_content[:2000]

        prompt = f"""You are an ASIC/FPGA verification engineer.
Summarize this simulation log in plain English.
Focus on:
- Which assertions failed (if any)
- At what times
- Likely reasons (timing, reset, CDC behavior)
- Whether the test outcome matches expectations

Verdict: {verdict}

Log snippet:
{snippet}
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
            summary = f"(⚠️ AI log summarization failed: {e})"

        out.write(f"## {os.path.basename(filepath)}\n\n**{verdict}**\n\n{summary}\n\n")

print(f"[AI Log Summarizer] Wrote summaries for {len(log_files)} changed log(s) to {output_file}")
