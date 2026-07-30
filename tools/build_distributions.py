#!/usr/bin/env python3
"""Build separate, self-contained MATLAB and Python SPHINX downloads."""

from __future__ import annotations

import hashlib
from pathlib import Path
import shutil
import tempfile
import zipfile


REPOSITORY = Path(__file__).resolve().parents[1]
DIST = REPOSITORY / "dist"


def copy(source: str, destination: Path) -> None:
    source_path = REPOSITORY / source
    target = destination / source_path.name
    if source_path.is_dir():
        shutil.copytree(source_path, target, ignore=shutil.ignore_patterns("__pycache__", "*.pyc", ".DS_Store"))
    else:
        shutil.copy2(source_path, target)


def write(path: Path, text: str, *, executable: bool = False) -> None:
    path.write_text(text, encoding="utf-8", newline="\n")
    if executable:
        path.chmod(0o755)


def archive(folder: Path, output: Path) -> None:
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for path in sorted(folder.rglob("*")):
            if path.is_file():
                info = zipfile.ZipInfo.from_file(path, path.relative_to(folder.parent))
                info.compress_type = zipfile.ZIP_DEFLATED
                with path.open("rb") as stream:
                    bundle.writestr(info, stream.read(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)


def matlab_bundle(workspace: Path) -> Path:
    root = workspace / "SPHINX-MATLAB"
    root.mkdir()
    for source in ("+sphinx", "matlabSolver", "examples", "tests", "docs", "assets", "setupSPHINX.m", "SPHINX_demo.m", "SPHINX_CORE_MANIFEST.json", "LICENSE", "TRADEMARKS.md"):
        copy(source, root)
    shutil.copy2(REPOSITORY / "distribution" / "MATLAB_README.md", root / "README.md")
    write(
        root / "START_HERE.m",
        "%% SPHINX MATLAB -- double-click this file and press Run\n"
        "rootFolder = fileparts(mfilename('fullpath'));\n"
        "cd(rootFolder)\n"
        "setupSPHINX;\n"
        "result = SPHINX_demo;\n"
        "disp(result.outputFolder)\n",
    )
    output = DIST / "SPHINX-MATLAB.zip"
    archive(root, output)
    return output


def python_bundle(workspace: Path) -> Path:
    root = workspace / "SPHINX-Python"
    root.mkdir()
    for source in ("python/src", "python/examples", "python/tests", "python/pyproject.toml", "assets"):
        source_path = REPOSITORY / source
        relative = source_path.relative_to(REPOSITORY / "python") if source.startswith("python/") else Path(source)
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if source_path.is_dir():
            shutil.copytree(source_path, target, ignore=shutil.ignore_patterns("__pycache__", "*.pyc", ".DS_Store"))
        else:
            shutil.copy2(source_path, target)
    python_readme = (REPOSITORY / "python" / "README.md").read_text(encoding="utf-8")
    write(root / "README.md", python_readme.replace('../assets/', 'assets/'))
    for source in ("SPHINX_CORE_MANIFEST.json", "LICENSE", "TRADEMARKS.md"):
        shutil.copy2(REPOSITORY / source, root / source)
    write(
        root / "install_and_run.command",
        "#!/bin/bash\nset -e\ncd \"$(dirname \"$0\")\"\n"
        "python3 -m venv .venv\n.venv/bin/python -m pip install --upgrade pip\n"
        ".venv/bin/python -m pip install -e .\n.venv/bin/sphinx-demo\n",
        executable=True,
    )
    write(
        root / "install_and_run.sh",
        "#!/usr/bin/env bash\nset -e\ncd \"$(dirname \"$0\")\"\n"
        "python3 -m venv .venv\n.venv/bin/python -m pip install --upgrade pip\n"
        ".venv/bin/python -m pip install -e .\n.venv/bin/sphinx-demo\n",
        executable=True,
    )
    write(
        root / "install_and_run.bat",
        "@echo off\r\ncd /d %~dp0\r\npython -m venv .venv\r\n"
        ".venv\\Scripts\\python -m pip install --upgrade pip\r\n"
        ".venv\\Scripts\\python -m pip install -e .\r\n"
        ".venv\\Scripts\\sphinx-demo.exe\r\npause\r\n",
    )
    output = DIST / "SPHINX-Python.zip"
    archive(root, output)
    return output


def main() -> None:
    DIST.mkdir(exist_ok=True)
    for existing in DIST.glob("SPHINX-*.zip"):
        existing.unlink()
    with tempfile.TemporaryDirectory(prefix="sphinx-distribution-") as temporary:
        workspace = Path(temporary)
        outputs = [matlab_bundle(workspace), python_bundle(workspace)]
    checksums = []
    for output in outputs:
        digest = hashlib.sha256(output.read_bytes()).hexdigest()
        checksums.append(f"{digest}  {output.name}")
        print(f"Built {output.relative_to(REPOSITORY)}")
    (DIST / "SHA256SUMS.txt").write_text("\n".join(checksums) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
