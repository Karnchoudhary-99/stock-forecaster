#!/usr/bin/env python3
"""Regenerate data/sample-prices.csv (seeded, deterministic).

120 days of a synthetic price: a gentle uptrend, a slow cycle, and
Gaussian noise. Run from the repo root: python3 examples/make_sample.py
"""
import csv
import math
import random
from datetime import date, timedelta

random.seed(42)
start = date(2025, 1, 2)
rows = []
for t in range(120):
    price = 100 + 0.15 * t + 8 * math.sin(t / 9.0) + random.gauss(0, 1.5)
    rows.append((start + timedelta(days=t), round(price, 2)))

with open("data/sample-prices.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["date", "close"])
    writer.writerows(rows)
print(f"wrote {len(rows)} rows to data/sample-prices.csv")
