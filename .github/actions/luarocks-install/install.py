import sys

from output_config import luarocks, validate_package_name


def main():
    package_names = sys.argv[1].split(",")
    for package_name in package_names:
        validate_package_name(package_name)
        luarocks(["install", package_name])


if __name__ == "__main__":
    main()
