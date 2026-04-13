#!/usr/bin/env python3

import sys

import yaml


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_yaml.py <path>", file=sys.stderr)
        return 2

    with open(sys.argv[1], "r", encoding="utf-8") as fh:
        yaml.safe_load(fh)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
