from pathlib import Path
import tempfile
import unittest

import numpy as np

from sphinx_solver import analyze, configure, import_run, prepare, preview, run
from sphinx_solver.operators import all_operators
from sphinx_solver.ordering import flatten, unflatten


class CoreTest(unittest.TestCase):
    def test_non_square_ordering_round_trip(self) -> None:
        field = np.arange(3 * 5 * 4, dtype=float).reshape(3, 5, 4)
        self.assertTrue(np.array_equal(unflatten(flatten(field), (5, 3, 4)), field))

    def test_current_profiles_and_operator_shapes(self) -> None:
        sim = configure("cyclotron", resolution="3d_demo")
        self.assertEqual(sim.domain.grid, (9, 9, 9))
        self.assertEqual(sim.boundary, "periodic")
        self.assertEqual(preview(sim)["snapshots"], 6)
        prepared = prepare(sim)
        operators = all_operators(prepared)
        n = 9**3
        self.assertEqual(operators["G"].shape, (3 * n, n))
        self.assertEqual(operators["C"].shape, (3 * n, 3 * n))

    def test_small_run_import_and_analysis(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            sim = configure(
                "cyclotron",
                resolution="quick",
                grid=(7, 7, 1),
                end_time=1e-5,
                time_points=3,
                save_every=1,
                run_name="python_core_test",
                output_root=temporary,
            )
            result = run(sim)
            self.assertTrue(result.solver.converged)
            data = import_run(result)
            self.assertEqual(data.psi_r.shape, (3, 7, 7, 1))
            diagnostics = analyze(data)
            self.assertTrue(np.isfinite(diagnostics.probability["integral"]).all())
            self.assertTrue(np.isfinite(diagnostics.energy["total"]).all())
            self.assertTrue(Path(result.output_folder, "manifest.json").is_file())


if __name__ == "__main__":
    unittest.main()
