from unittest import TestCase
from pktfwd.pktfwd_app import PktfwdApp


class TestPktfwdApp(TestCase):
    def test_can_instantiate(self):
        pktfwd_app = PktfwdApp("NEBHNT-IN1", "US915", "/var/pktfwd/region",
                               "/opt/pktfwd/config/lora_templates_sx1301",
                               "/opt/pktfwd/config/lora_templates_sx1302",
                               False, "", "", "/var/pktfwd/diagnostics", "5",
                               "/opt", "/opt/outputs/sx1301/reset_lgw.sh",
                               "UTIL_CHIP_ID_FILEPATH",
                               "SX1302_LORA_PKT_FWD_FILEPATH",
                               "/opt/outputs/sx1301")

        self.assertEqual(pktfwd_app.variant, 'NEBHNT-IN1')
