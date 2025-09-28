#!/usr/bin/env python3
"""
AI Log Summarizer for CDC IP Library
------------------------------------
- Summarizes *all* .log files in logs/ each run.
- Adds PASS/FAIL/INCONCLUSIVE verdicts.
"""

import os, datetime
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

log_dir = "logs"
output_file = "docs/log_summaries.md"

if not os.path.exists(log_dir):
    print("[AI Log Summarizer] No logs directory found. Skipping.")
    exit(0)

log_files = [os.path.join(log_dir, f) for f in os.listdir(log_dir) if f.endswith(".log")]

if not log_files:
    print("[AI Log Summarizer] No .log files found. Skipping.")
    exit(0)

os.makedirs("docs", exist_ok=True)

with open(output_file, "w") as out:
    out.write("# 🤖 AI Log Summaries\n\n")
    out.write(f"_Generated on {datetime.datetime.now(datetime.UTC).isoformat()}_\n\n")

    for filepath in log_files:
        with open(filepath) as f:
            log_content = f.read()

        # Verdict
        if "FAILED" in log_content or "$error" in log_content:
            verdict = "❌ TEST FAILED"
        elif "Assertion" in log_content and "FAILED" in log_content:
            verdict = "❌ Assertion failures detected"
        elif "Finished" in log_content or "$finish" in log_content:
            verdict = "✅ TEST PASSED (no assertion failures)"
        else:
            verdict = "⚠️ INCONCLUSIVE (no clear markers)"

        # Snippet
        important = [
            l for l in log_content.splitlines()
            if any(k in l.lower() for k in ["assert", "fail", "error", "offending"])
        ]
        snippet = "\n".join(important[:1000]) if important else log_content[:2000]

        prompt = f"""You are an ASIC/FPGA verification engineer.
Summarize this log in plain English:
- Which assertions failed
- At what times
- Likely cause
- Whether outcome matches expectations

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
            summary = f"(⚠️ Log summarization failed: {e})"

        out.write(f"## {os.path.basename(filepath)}\n\n**{verdict}**\n\n{summary}\n\n")

print(f"[AI Log Summarizer] Wrote summaries for {len(log_files)} log(s) to {output_file}")
