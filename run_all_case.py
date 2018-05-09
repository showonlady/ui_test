# coding : utf-8
import unittest
import os
import HTMLTestRunner

case_path = os.path.join(os.getcwd(), "case")
report_path = os.path.join(os.getcwd(), "report")


def all_case():
    discover = unittest.defaultTestLoader.discover(case_path, pattern="test*.py", top_level_dir=None)
    print discover
    return discover


if __name__ == "__main__":
    report_paths = os.path.join(report_path, "report.html")
    fp = open(report_paths, "wb")
    runner = HTMLTestRunner.HTMLTestRunner(stream=fp, title="test result", description="test result")

    runner.run(all_case())
    fp.close()
