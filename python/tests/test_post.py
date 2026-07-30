from pathlib import Path
import tempfile
import unittest

import numpy as np

from sphinx_solver import analyze, configure, import_run, options, produce, run


class PostProductionTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        simulation = configure(
            "cyclotron",
            resolution="quick",
            boundary="periodic",
            grid=(5, 4, 3),
            extent_lambda=((-2, 2), (-1, 1), (-0.5, 0.5)),
            end_time=1e-5,
            time_points=3,
            save_every=1,
            run_name="python_post_test",
            output_root=self.temporary.name,
        )
        self.result = run(simulation)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_import_derives_complete_matlab_field_contract(self) -> None:
        data = import_run(self.result)
        self.assertEqual(data.psi_r.shape, (3, 4, 5, 3))
        for vector in (
            data.A, data.Y, data.B, data.E, data.J, data.probability_current,
            data.canonical_momentum, data.poynting,
        ):
            self.assertIsNotNone(vector)
            self.assertEqual(vector.x.shape, data.psi_r.shape)
        self.assertEqual(data.poynting_divergence.shape, data.psi_r.shape)
        self.assertEqual(data.probability_current_divergence.shape, data.psi_r.shape)

    def test_analysis_selection_box_statistics_and_products(self) -> None:
        data = import_run(self.result)
        coordinates = data.prepared.coordinates
        box = np.asarray([
            [np.min(coordinates[axis]), np.max(coordinates[axis])]
            for axis in "xyz"
        ])
        selected = analyze(data, diagnostics=("probability",), integration_box=box)
        self.assertIsNotNone(selected.probability)
        self.assertIsNone(selected.energy)

        analysis = analyze(data)
        self.assertEqual(set(analysis.field_statistics["probability"]), {"minimum", "maximum", "rms"})
        self.assertTrue(np.isfinite(analysis.energy["total"]).all())
        output = Path(self.temporary.name, "products")
        files = produce(
            data,
            analysis,
            ("summary", "conservation", "energy_breakdown", "snapshot", "lineout", "workspace"),
            output_folder=output,
        )
        self.assertTrue(all(path.is_file() and path.stat().st_size > 0 for path in files))
        self.assertEqual(len(options()["products"]), 7)
        with np.load(output / "postproduction.npz") as workspace:
            self.assertIn("energy_total", workspace)


if __name__ == "__main__":
    unittest.main()
