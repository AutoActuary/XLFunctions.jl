import subprocess
import os
from pathlib import Path
import re


class ProjectTomlNotFound(Exception):
    pass


def get_current_dir():
    current_dir = Path(os.getcwd())
    while not Path(current_dir, "Project.toml").exists():
        old_current_dir = current_dir
        current_dir = current_dir.parent
        if current_dir == old_current_dir:
            raise ProjectTomlNotFound(
                "Could not find a Project.toml file. Please run this script from a directory that contains a Project.toml file."
            )
    return current_dir


class cd:
    def __init__(self, newPath):
        self.newPath = newPath

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.savedPath)


def get_latest_tag():
    try:
        with cd(get_current_dir()):
            # Get the latest tag but don't echo fatal: No names found, cannot describe anything.
            return (
                subprocess.check_output(
                    ["git", "describe", "--tags", "--abbrev=0"],
                    stderr=subprocess.DEVNULL,
                )
                .decode("utf-8")
                .strip()
            )
    except subprocess.CalledProcessError:
        return None


def replace_version_tag(tag):
    with cd(get_current_dir()):
        project_file = Path(get_current_dir(), "Project.toml")
        project_file_contents = project_file.read_text()

        project_file_contents = re.sub(
            r'version = ".*"', f'version = "{tag}"', project_file_contents
        )
        project_file.write_text(project_file_contents)


class GitDirty(Exception):
    pass


def ensure_git_repo_is_clean():
    with cd(get_current_dir()):
        if (
            subprocess.check_output(["git", "status", "--porcelain"])
            .decode("utf-8")
            .strip()
        ):
            raise GitDirty(
                "Git repo is dirty. Please commit or stash your changes before running this script."
            )


def git_commit(message):
    with cd(get_current_dir()):
        subprocess.check_call(["git", "add", "."])
        subprocess.check_call(["git", "commit", "-m", message])


def get_git_main_branch():
    with cd(get_current_dir()):
        return (
            subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"])
            .decode("utf-8")
            .strip()
        )


class GitNotMainBranch(Exception):
    pass


def ensure_git_on_main_branch():
    if get_git_main_branch() != get_git_main_branch():
        raise GitNotMainBranch(
            "Git is not on the main branch. Please switch to the main branch before running this script."
        )


def git_push():
    with cd(get_current_dir()):
        subprocess.check_call(["git", "push", "--follow-tags"])


def git_tag(tag):
    with cd(get_current_dir()):
        subprocess.check_call(["git", "tag", tag])


def get_current_package_name():
    return str(os.path.basename(get_current_dir())).replace(".jl", "")


def is_valid_semver(version):
    pattern = re.compile(
        r"^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"
    )
    return pattern.match(version)


class InvalidSemver(Exception):
    pass


def ensure_valid_semver(version):
    if not is_valid_semver(version):
        raise InvalidSemver(f"{version} is not a valid semver version.")


def main():
    ensure_git_repo_is_clean()
    ensure_git_on_main_branch()

    new_tag = input(f"Enter a new tag (latest tag is {get_latest_tag()}): ")
    ensure_valid_semver(new_tag)

    replace_version_tag(new_tag)
    print(f"Update version to {new_tag}")
    git_commit(f"Update version to {new_tag}")
    git_tag(new_tag)
    git_push()

    package = get_current_package_name()

    with cd(get_current_dir()):
        subprocess.check_call(
            [
                "julia",
                "-e",
                f'using Pkg; pkg"dev ."; using LocalRegistry; using {package}; register({package})',
            ]
        )


if __name__ == "__main__":
    main()
