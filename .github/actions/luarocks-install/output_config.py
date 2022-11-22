import hashlib
import platform
import re
import subprocess
import sys
from typing import List

enabled_shell = platform.system() == "Windows"


def luarocks(args: list, stdout=None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["luarocks"] + args,
        stdout=stdout,
        shell=enabled_shell,
    )


def luarocks_pipe(args: List[str]) -> str:
    result = luarocks(args, stdout=subprocess.PIPE)
    return result.stdout.decode("utf-8")


def validate_package_name(package_name: str):
    if re.search("^[a-zA-Z0-9-_]+$", package_name) is None:
        raise Exception("invalid package name: " + package_name)


def output(name: str, value: str) -> None:
    print(f"{name}={value}")


def search_latest_version(package_name: str) -> str:
    validate_package_name(package_name)

    search_result = luarocks_pipe(["search", package_name, "--porcelain"])
    all_lines = search_result.split("\n")
    lines = [line for line in all_lines if line.startswith(package_name)]
    if len(lines) == 0:
        raise Exception("not found: " + package_name)

    return lines[0]


def main():
    for config in [
        {"path": "rocks_trees[1].root", "key": "rocks_tree1"},
        {"path": "rocks_trees[2].root", "key": "rocks_tree2"},
        {"path": "program_version", "key": "program_version"},
    ]:
        value = luarocks_pipe(["config", config["path"]])
        output(config["key"], value)

    latest_versions = []
    package_names = sys.argv[1].split(",")
    for package_name in package_names:
        latest_version = search_latest_version(package_name)
        latest_versions.append(latest_version)

    versions_hash = hashlib.sha256()
    versions = "\n".join(latest_versions)
    versions_hash.update(bytes(versions, "utf-8"))
    output("versions_hash", versions_hash.hexdigest())


if __name__ == "__main__":
    main()
