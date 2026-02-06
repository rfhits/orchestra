"""
Command-line interface for Orchestra MCP server.
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path
import importlib.resources as resources

import server


def _copy_tree(src: Path, dest: Path) -> None:
    for item in src.rglob("*"):
        rel = item.relative_to(src)
        target = dest / rel
        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)


def _cmd_launch(_: argparse.Namespace) -> int:
    server.main()
    return 0


def _cmd_scripts(args: argparse.Namespace) -> int:
    dest_root = Path(args.path).expanduser()
    if not dest_root.exists():
        print(f"Path does not exist: {dest_root}", file=sys.stderr)
        return 1
    target_root = dest_root / "rfhits" / "orchestra"

    scripts_root = resources.files("reaper_scripts")
    with resources.as_file(scripts_root) as src_dir:
        _copy_tree(Path(src_dir), target_root)

    print(f"Installed REAPER scripts to: {target_root}")
    return 0


def main(argv: list[str] | None = None) -> int:
    prog_name = Path(sys.argv[0]).name
    parser = argparse.ArgumentParser(prog=prog_name)
    subparsers = parser.add_subparsers(dest="command", required=True)

    launch_parser = subparsers.add_parser("launch", help="Run MCP server (stdio)")
    launch_parser.set_defaults(func=_cmd_launch)

    scripts_parser = subparsers.add_parser("scripts", help="Install REAPER scripts")
    scripts_parser.add_argument("path", help="Path to REAPER Scripts directory")
    scripts_parser.set_defaults(func=_cmd_scripts)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
