#!/usr/bin/env python3

import os
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP_DIR = ROOT / "app"
PUBSPEC_PATH = APP_DIR / "pubspec.yaml"
OUTPUT_DIR = APP_DIR / "build" / "releases"
APK_PATH = APP_DIR / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
FLUTTER_BIN = Path("/Users/munir/Desktop/flutter/bin/flutter")
ANDROID_HOME = Path("/Users/munir/Library/Android/sdk")
JAVA_HOME = Path("/Applications/Android Studio.app/Contents/jbr/Contents/Home")


def bump_build_number():
    content = PUBSPEC_PATH.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$", content, re.MULTILINE)
    if not match:
        raise RuntimeError("Could not find version in pubspec.yaml")

    version_name = match.group(1)
    build_number = int(match.group(2)) + 1
    new_version = f"{version_name}+{build_number}"
    updated = re.sub(
        r"^version:\s*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+\s*$",
        f"version: {new_version}",
        content,
        count=1,
        flags=re.MULTILINE,
    )
    PUBSPEC_PATH.write_text(updated, encoding="utf-8")
    return new_version


def run(command):
    env = {
        "JAVA_HOME": str(JAVA_HOME),
        "ANDROID_HOME": str(ANDROID_HOME),
        "ANDROID_SDK_ROOT": str(ANDROID_HOME),
        "PATH": ":".join(
            [
                str(FLUTTER_BIN.parent),
                str(ANDROID_HOME / "cmdline-tools" / "latest" / "bin"),
                str(ANDROID_HOME / "platform-tools"),
                str(JAVA_HOME / "bin"),
            ]
        ),
    }
    merged_env = dict(os.environ)
    merged_env.update(env)
    merged_env["PATH"] = f"{env['PATH']}:{os.environ.get('PATH', '')}"
    subprocess.run(command, cwd=APP_DIR, env=merged_env, check=True)


def main():
    version = bump_build_number()
    run([str(FLUTTER_BIN), "pub", "get"])
    run([str(FLUTTER_BIN), "build", "apk", "--release"])

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    versioned_apk = OUTPUT_DIR / f"tracker-v{version}.apk"
    shutil.copy2(APK_PATH, versioned_apk)
    print(versioned_apk)


if __name__ == "__main__":
    main()
