from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


RUNNER = Path(__file__).resolve().parents[1] / 'scripts' / 'decode_ft8mon.py'


class DecoderRunnerTests(unittest.TestCase):
    def run_fake(self, body):
        with tempfile.TemporaryDirectory() as directory:
            decoder = Path(directory) / 'decoder'
            decoder.write_text('#!' + sys.executable + '\nimport os, sys\n' + body)
            decoder.chmod(0o755)
            return subprocess.run(
                [sys.executable, str(RUNNER), 'test.wav', '--decoder', str(decoder),
                 '--budget', '12'], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                universal_newlines=True)

    def test_both_bands_and_overlap_deduplication(self):
        result = self.run_fake('''
assert sys.argv[1:] == ['-file', 'test.wav']
assert os.environ['FT8MON_BUDGET'] == '12.0'
low = os.environ['FT8MON_MIN_HZ']
high = os.environ['FT8MON_MAX_HZ']
assert (low, high) in [('150', '1925'), ('1825', '3600')]
print('000000 -1 0.0 1870 ~ CQ  SAME AA00')
print('000000 -1 0.0 1000 ~ CQ BAND' + low + ' AA00')
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count('CQ  SAME AA00'), 1)
        self.assertIn('CQ BAND150 AA00', result.stdout)
        self.assertIn('CQ BAND1825 AA00', result.stdout)
        self.assertIn('3 unique message strings', result.stderr)

    def test_worker_failure_is_reported_without_partial_results(self):
        result = self.run_fake('''
print('000000 -1 0.0 1000 ~ CQ PARTIAL AA00')
sys.exit(1 if os.environ['FT8MON_MIN_HZ'] == '1825' else 0)
''')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertIn('worker failed', result.stderr)


if __name__ == '__main__':
    unittest.main()
