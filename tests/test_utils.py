import tempfile
import io
from unittest import TestCase
from pktfwd.utils import write_diagnostics, get_region_filename, \
                         replace_sx1301_global_conf_with_regional


class TestUtils(TestCase):
    def test_write_diagnotics_is_running(self):
        diagnostics_filepath = tempfile.mkstemp()[1]
        write_diagnostics(diagnostics_filepath, True)

        contents = open(diagnostics_filepath).read()
        self.assertEqual(contents, "true")

    def test_write_diagnotics_not_running(self):
        diagnostics_filepath = tempfile.mkstemp()[1]
        write_diagnostics(diagnostics_filepath, False)

        contents = open(diagnostics_filepath).read()
        self.assertEqual(contents, "false")

    def test_get_region_filename(self):
        self.assertEqual(get_region_filename("AS923_4"),
                         "AS923-4-global_conf.json")
        self.assertEqual(get_region_filename("EU868"),
                         "EU-global_conf.json")
        self.assertEqual(get_region_filename("US915"),
                         "US-global_conf.json")

    def test_replace_sx1301_global_conf_with_regional(self):
        configs_dir = tempfile.mkdtemp()
        expected_config_filepath = "{}/IN-global_conf.json".format(configs_dir)
        with open(expected_config_filepath, "w") as expected_config_file:
            expected_config_file.write("foobar")
        replace_sx1301_global_conf_with_regional(configs_dir,
                                                 configs_dir, "IN865")

        global_conf_filepath = "{}/global_conf.json".format(configs_dir)
        self.assertListEqual(
            list(io.open(global_conf_filepath)),
            list(io.open(expected_config_filepath)))
