from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

import numpy as np
from scipy.io import loadmat

from sphinx_solver import analyze, configure, import_run, run


REPOSITORY = Path(__file__).resolve().parents[2]
DEFAULT_MATLAB = Path("/Applications/MATLAB_R2025b.app/bin/matlab")
MATLAB = Path(os.environ.get("MATLAB_BIN", DEFAULT_MATLAB))


@unittest.skipUnless(MATLAB.is_file(), "MATLAB executable not found; set MATLAB_BIN")
class CrossLanguageTest(unittest.TestCase):
    def test_fixed_2d_and_periodic_3d(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            matlab_code = self._matlab_reference_code(root)
            command = [str(MATLAB), "-batch", matlab_code]
            if Path("/usr/bin/arch").is_file() and "MATLAB_R2025b.app" in str(MATLAB):
                command = ["/usr/bin/arch", "-x86_64", *command]
            subprocess.run(command, check=True, cwd=REPOSITORY)

            geometries = {
                "periodic": dict(boundary="periodic", grid=(5, 4, 3), extent_lambda=((-2, 2), (-1, 1), (-0.5, 0.5))),
                "fixed": dict(grid=(5, 5, 1)),
            }
            for geometry, special in geometries.items():
              for mode in ("EM", "QM", "both"):
                name = f"{geometry}_{mode.lower()}"
                sim = configure(
                    "cyclotron",
                    resolution="quick",
                    end_time=1e-5,
                    time_points=4,
                    save_every=1,
                    model=mode,
                    run_name=f"python_{name}",
                    output_root=root,
                    **special,
                )
                python_result = run(sim)
                matlab_folder = Path((root / f"matlab_{name}_path.txt").read_text().strip())
                self._compare_snapshots(matlab_folder, Path(python_result.output_folder))
                if mode == "both":
                    self._compare_analysis(name, matlab_folder, python_result, root)

    def _compare_snapshots(self, matlab: Path, python: Path) -> None:
        for field in ("S", "F"):
            for step in range(4):
                matlab_state = np.loadtxt(matlab / field / f"{field}_{step:07d}.txt", delimiter=",").reshape(-1)
                python_state = np.loadtxt(python / field / f"{field}_{step:07d}.txt", delimiter=",").reshape(-1)
                relative = np.linalg.norm(python_state - matlab_state) / max(np.linalg.norm(matlab_state), np.finfo(float).tiny)
                self.assertLess(relative, 1e-8, f"{field} step {step} relative mismatch")

    def _compare_analysis(self, name: str, matlab_folder: Path, python_result: object, root: Path) -> None:
        python_analysis = analyze(import_run(python_result))
        reference = loadmat(root / f"matlab_{name}_analysis.mat", squeeze_me=True)
        pairs = {
            "probability": python_analysis.probability["integral"],
            "total": python_analysis.energy["total"],
            "em": python_analysis.energy["electromagnetic"],
            "qm": python_analysis.energy["quantum"],
        }
        for reference_name, python_values in pairs.items():
            matlab_values = np.asarray(reference[reference_name]).reshape(-1)
            relative = np.linalg.norm(python_values - matlab_values) / max(np.linalg.norm(matlab_values), np.finfo(float).tiny)
            self.assertLess(relative, 1e-8, f"{reference_name} diagnostic mismatch")

    @staticmethod
    def _matlab_reference_code(root: Path) -> str:
        repo = str(REPOSITORY).replace("'", "''")
        destination = str(root).replace("'", "''")
        blocks = [f"cd('{repo}'); setupSPHINX;"]
        geometries = {
            "periodic": "'Boundary','periodic','Grid',[5,4,3],'ExtentLambda',[-2,2;-1,1;-0.5,0.5]",
            "fixed": "'Grid',[5,5,1]",
        }
        for geometry, geometry_options in geometries.items():
            for mode in ("EM", "QM", "both"):
                name = f"{geometry}_{mode.lower()}"
                blocks.append(
                    f"sim=sphinx.configure('cyclotron','Resolution','quick',{geometry_options},"
                    f"'Model','{mode}','EndTime',1e-5,'TimePoints',4,'SaveEvery',1,"
                    f"'RunName','matlab_{name}','OutputRoot','{destination}');"
                    f"r=sphinx.run(sim); writelines(r.outputFolder,'{destination}/matlab_{name}_path.txt');"
                )
                if mode == "both":
                    blocks.append(
                        "d=sphinx.post.importRun(r); a=sphinx.post.analyze(d);"
                        "probability=a.probability.integral; total=a.energy.total; "
                        "em=a.energy.electromagnetic; qm=a.energy.quantum;"
                        f"save('{destination}/matlab_{name}_analysis.mat','probability','total','em','qm','-v7');"
                    )
        return " ".join(blocks)


if __name__ == "__main__":
    unittest.main()
