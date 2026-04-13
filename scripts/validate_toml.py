#!/usr/bin/env python3

import sys
import tomllib


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_toml.py <path>", file=sys.stderr)
        return 2

    with open(sys.argv[1], "rb") as fh:
        tomllib.load(fh)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
