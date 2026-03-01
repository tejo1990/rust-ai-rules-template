#!/usr/bin/env python3
"""
주요 Rust 생태계 소스에서 업데이트를 가져와 markdown으로 저장.

소스:
- This Week in Rust (RSS)
- Rust Blog (RSS)
- crates.io (주요 crate 최신 버전)
- Rust RFC GitHub Issues
"""

import os
import httpx
import feedparser
from datetime import datetime, timedelta, timezone

OUTPUT_FILE = os.environ.get("OUTPUT_FILE", "/tmp/rust_updates.md")
ONE_WEEK_AGO = datetime.now(timezone.utc) - timedelta(days=7)

KEY_CRATES = [
    "axum", "tokio", "sqlx", "tower", "serde",
    "clap", "tracing", "anyhow", "thiserror",
    "embassy-executor", "embassy-time",
    "proptest", "criterion", "mockall",
]


def fetch_rss(url: str, label: str, max_items: int = 5) -> str:
    feed = feedparser.parse(url)
    items = []
    for entry in feed.entries[:max_items]:
        published = getattr(entry, 'published_parsed', None)
        if published:
            pub_dt = datetime(*published[:6], tzinfo=timezone.utc)
            if pub_dt < ONE_WEEK_AGO:
                continue
        items.append(f"- [{entry.title}]({entry.link})")
    if not items:
        return ""
    return f"## {label}\n" + "\n".join(items) + "\n"


def fetch_crate_version(name: str) -> str:
    try:
        r = httpx.get(
            f"https://crates.io/api/v1/crates/{name}/versions",
            headers={"User-Agent": "rust-ai-rules-template-updater"},
            timeout=10,
        )
        r.raise_for_status()
        versions = r.json().get("versions", [])
        if versions:
            latest = versions[0]
            return f"- **{name}** {latest['num']} (published: {latest['created_at'][:10]})"
    except Exception as e:
        return f"- **{name}** (fetch failed: {e})"
    return ""


def main():
    sections = []
    sections.append(f"# Rust Ecosystem Updates — {datetime.now().date()}\n")

    # RSS feeds
    tiwr = fetch_rss(
        "https://this-week-in-rust.org/rss.xml",
        "This Week in Rust"
    )
    if tiwr:
        sections.append(tiwr)

    blog = fetch_rss(
        "https://blog.rust-lang.org/feed.xml",
        "Rust Blog"
    )
    if blog:
        sections.append(blog)

    inside_rust = fetch_rss(
        "https://blog.rust-lang.org/inside-rust/feed.xml",
        "Inside Rust Blog"
    )
    if inside_rust:
        sections.append(inside_rust)

    # crate versions
    crate_lines = [f"## Key Crate Versions (latest)\n"]
    for name in KEY_CRATES:
        line = fetch_crate_version(name)
        if line:
            crate_lines.append(line)
    sections.append("\n".join(crate_lines) + "\n")

    content = "\n".join(sections)
    with open(OUTPUT_FILE, "w") as f:
        f.write(content)
    print(f"Wrote {len(content)} bytes to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
