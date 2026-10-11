#!/usr/bin/env python3
"""Actual configured-IP augmented-capacity rejection and exact boundary recovery."""

import argparse
import json
import re
import shutil
import struct
from pathlib import Path
from verify_solver_m5 import ROOT, command, packet, sha256
from verify_solver_xsim_m5 import actual_sources
from verify_fp_m5 import VIVADO, configuration_audit


def packets(frame, nodes, elements):
    return (
        [packet(f"NB,{frame},{len(elements):02X},{nodes:02X}")]
        + [
            packet(f"NC,{frame},{j:02X},{k:02X},{a:02X},{b:02X},{v:03d},00")
            for j, (k, a, b, v) in enumerate(elements)
        ]
        + [packet(f"NE,{frame},{len(elements):02X},{nodes:02X}")]
    )


def capacity_fixtures():
    return [
        {
            "label": "reject_one_voltage_dimension33",
            "frame": "FF40",
            "nodes": 32,
            "elements": [(3, 0, 255, 10)] + [(1, j, j + 1, 1) for j in range(31)],
            "rejection": True,
        },
        {
            "label": "recover_boundary_dimension32_one_voltage",
            "frame": "FF41",
            "nodes": 31,
            "elements": [(3, 0, 255, 31)]
            + [(1, j, j + 1, 1) for j in range(30)]
            + [(1, 30, 255, 1)],
            "rejection": False,
            "values": list(range(31, 0, -1)),
        },
        {
            "label": "reject_two_voltage_dimension33",
            "frame": "FF42",
            "nodes": 31,
            "elements": [(3, 0, 255, 10), (3, 1, 255, 9)]
            + [(1, j, j + 1, 1) for j in range(30)],
            "rejection": True,
        },
        {
            "label": "recover_boundary_dimension32_zero_voltage",
            "frame": "FF43",
            "nodes": 32,
            "elements": [(1, j, 255, 1) for j in range(32)],
            "rejection": False,
            "values": [0] * 32,
        },
    ]


CAPACITY_TASK = """  integer total_solver_starts=0;
  integer starts_before;
  always @(posedge clk) if(dut.solver_start) total_solver_starts++;
  task automatic expect_capacity(input string frame,expected);
    integer k,scanned; reg [7:0] checksum,received; reg [15:0] argument;
    begin
      recv_uart_line(rx_line);
      $display("CAPACITY_REPLY %s",rx_line);
      if(rx_line.len()!=19 || rx_line.substr(0,11)!=$sformatf("@ER,%s,03,",frame))
        $fatal(1,"augmented capacity mismatch expected STATUS_CAPACITY03 error got %s",rx_line);
      checksum=0;
      for(k=1;k<16;k++) checksum=checksum^rx_line[k];
      scanned=$sscanf(rx_line.substr(17,18),"%h",received);
      if(scanned!=1 || rx_line[16]!="*" || received!=checksum)
        $fatal(1,"augmented capacity checksum mismatch got %s",rx_line);
      scanned=$sscanf(rx_line.substr(12,15),"%h",argument);
      if(scanned!=1 || argument!=16'h0021)
        $fatal(1,"augmented capacity argument mismatch expected0021 got %s",rx_line);
      // Require a valid baseline observation before injecting the control.
      $display("CAPACITY_BASELINE_VALID");
      if($test$plusargs("CORRUPT_CAPACITY")) begin
        rx_line={rx_line,"X"};
        $display("CORRUPT_CAPACITY_CONTROL applied");
      end
      if(rx_line!=expected)
        $fatal(1,"capacity observation mismatch expected %s got %s",expected,rx_line);
    end
  endtask
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--fp-report", type=Path, required=True)
    parser.add_argument(
        "--solver-top",
        type=Path,
        help="explicit isolated override; production is default",
    )
    parser.add_argument("--timeout", type=int, default=180)
    args = parser.parse_args()
    if args.timeout < 1:
        parser.error("timeout must be positive")
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    template = ROOT / "src/testbench/M5SolverUartXsim.sv"
    bench = out / "M5SolverRecoveryXsim.sv"
    text = template.read_text().replace("M5SolverUartXsim", "M5SolverRecoveryXsim")
    text = text.replace(
        "  initial begin\n    if(!numeric_policy",
        CAPACITY_TASK + "  initial begin\n    if(!numeric_policy",
    )
    bench.write_text(text)
    fixtures = capacity_fixtures()
    lines = []
    for f in fixtures:
        f["tx"] = packets(f["frame"], f["nodes"], f["elements"])
        f["voltage_sources"] = sum(e[0] == 3 for e in f["elements"])
        f["dimension"] = f["nodes"] + f["voltage_sources"]
        frame = f["frame"]
        count = f["nodes"]
        lines += (
            [
                f'$display("CAPACITY_CASE {f["label"]}");',
                "starts_before=total_solver_starts;",
                "fork",
                "  begin",
            ]
            + [f'    send_uart_line("{s}");' for s in f["tx"]]
            + ["  end", "  begin"]
        )
        if f["rejection"]:
            f["rx"] = [packet(f"ER,{frame},03,0021")]
            lines += [f'    expect_capacity("{frame}","{f["rx"][0]}");']
        else:
            f["rx"] = (
                [packet(f"VB,{frame},{count:02X},00")]
                + [
                    packet(f"VN,{frame},{j:02X},{struct.pack('>f', v).hex().upper()}")
                    for j, v in enumerate(f["values"])
                ]
                + [packet(f"VE,{frame},{count:02X},00")]
            )
            lines += [f'    expect_line("{s}");' for s in f["rx"]]
        lines += ["  end", "join"]
        expected = 0 if f["rejection"] else 1
        lines += [
            f'if(total_solver_starts-starts_before!={expected}) $fatal(1,"capacity recovery solve-count mismatch case{frame}");'
        ]
    (out / "M5SolverUartFixtures.svh").write_text("\n".join(lines) + "\n")
    (out / "fixtures.json").write_text(
        json.dumps(
            {
                "oracle": "Analytical linear1ohm series chain with31V gives31..1V;32independently grounded1ohm resistors give exact0V. Both boundary dimensions32 require count reset after rejection. No physical error tolerance.",
                "fixtures": fixtures,
            },
            indent=2,
        )
        + "\n"
    )
    sources = actual_sources(solver_top=args.solver_top)[:-1] + [bench]
    audit = {n: configuration_audit(n) for n in ("fma", "div")}
    fp_path = args.fp_report.resolve()
    fp = json.loads(fp_path.read_text())
    fp_drift = [
        p
        for p, d in fp["source_tool_library_sha256"].items()
        if not Path(p).is_file() or sha256(p) != d
    ]
    fp_valid = (
        fp.get("characterization_passed") is True
        and all(fp.get("negative_controls", {}).values())
        and not fp_drift
    )
    rom = ROOT / "src/design/solver_board/bcd_unit_to_fp32_rom.mem"
    shutil.copyfile(rom, out / rom.name)
    original = ROOT / "src/design/solver_board/SolverBoard_top.sv"
    tracked = sources + [
        template,
        original,
        rom,
        Path(__file__),
        ROOT / "tools/verify_solver_xsim_m5.py",
        ROOT / "tools/verify_solver_m5.py",
        ROOT / "tools/verify_fp_m5.py",
        fp_path,
        out / "fixtures.json",
        out / "M5SolverUartFixtures.svh",
    ]
    pins = {str(p): sha256(p) for p in tracked}
    report = {
        "schema": "metacircuit.m5-capacity-recovery-xsim.v1",
        "source_sha256": pins,
        "configuration_audit": audit,
        "fp_characterization": {
            "path": str(fp_path),
            "sha256": sha256(fp_path),
            "valid": fp_valid,
            "source_drift": fp_drift,
        },
        "source_overrides": (
            {
                str(original): {
                    "effective": str(args.solver_top.resolve()),
                    "original_sha256": sha256(original),
                    "effective_sha256": sha256(args.solver_top),
                }
            }
            if args.solver_top
            else {}
        ),
        "scope": "augmented-capacity rejection and exact boundary recovery; explicit override recorded when supplied; unchanged frozen frontend contract",
        "operations": {},
        "full_m5_ready": False,
        "original_xci_synthesis_qualified": False,
    }
    cmds = [
        (
            "vhdl",
            [
                str(VIVADO / "bin/xvhdl"),
                "--work",
                "xil_defaultlib",
                *[a["product"] for a in audit.values()],
            ],
        ),
        (
            "sv",
            [
                str(VIVADO / "bin/xvlog"),
                "--sv",
                "--work",
                "xil_defaultlib",
                "-i",
                str(out),
                *map(str, sources),
            ],
        ),
        (
            "elaborate",
            [
                str(VIVADO / "bin/xelab"),
                "xil_defaultlib.M5SolverRecoveryXsim",
                "-s",
                "m5recovery",
                "-L",
                "floating_point_v7_1_21",
                "--timescale",
                "1ns/1ps",
                "-mt",
                "4",
            ],
        ),
        ("run", [str(VIVADO / "bin/xsim"), "m5recovery", "-runall"]),
        (
            "negative_data",
            [
                str(VIVADO / "bin/xsim"),
                "m5recovery",
                "-runall",
                "-testplusarg",
                "CORRUPT_CAPACITY",
            ],
        ),
        (
            "negative_recovery",
            [
                str(VIVADO / "bin/xsim"),
                "m5recovery",
                "-runall",
                "-testplusarg",
                "CORRUPT_SOLVER",
            ],
        ),
    ]
    if fp_valid and all(a["configuration_matches"] for a in audit.values()):
        for name, cmd in cmds:
            item = command(cmd, out, out / (name + ".log"), args.timeout)
            report["operations"][name] = item
            print(name, item["returncode"], flush=True)
            log = (out / (name + ".log")).read_text()
            if (
                item["returncode"] != 0
                or re.search(r"^ERROR:", log, re.M)
                or (name == "run" and "M5SolverRecoveryXsim passed." not in log)
            ):
                break
    run = (out / "run.log").read_text() if (out / "run.log").exists() else ""
    negative = (
        (out / "negative_data.log").read_text()
        if (out / "negative_data.log").exists()
        else ""
    )
    report["source_drift"] = [p for p, d in pins.items() if sha256(p) != d]
    report["fp_characterization"]["final_source_drift"] = [
        p
        for p, digest in fp["source_tool_library_sha256"].items()
        if not Path(p).is_file() or sha256(p) != digest
    ]
    report["case_events"] = re.findall(r"^CAPACITY_CASE .+$", run, re.M)
    report["rejections"] = re.findall(r"^CAPACITY_REPLY .+$", run, re.M)
    report["solves"] = re.findall(r"^ACTUAL_SOLVE .+$", run, re.M)
    report["negative_data_detected"] = (
        all(
            s in negative
            for s in (
                "CAPACITY_BASELINE_VALID",
                "CORRUPT_CAPACITY_CONTROL applied",
                "Fatal: capacity observation mismatch",
            )
        )
        and "M5SolverRecoveryXsim passed." not in negative
    )
    recovery_negative = (
        (out / "negative_recovery.log").read_text()
        if (out / "negative_recovery.log").exists()
        else ""
    )
    report["negative_recovery_detected"] = (
        "CAPACITY_BASELINE_VALID" in recovery_negative
        and "CAPACITY_CASE recover_boundary_dimension32_one_voltage"
        in recovery_negative
        and "Fatal: M5SolverRecoveryXsim mismatch expected '@VN,FF41,00,"
        in recovery_negative
        and "M5SolverRecoveryXsim passed." not in recovery_negative
    )
    report["capacity_recovery_passed"] = (
        "M5SolverRecoveryXsim passed." in run
        and report["negative_data_detected"]
        and report["negative_recovery_detected"]
        and len(report["case_events"]) == 4
        and len(report["solves"]) == 2
        and fp_valid
        and not report["source_drift"]
        and not report["fp_characterization"]["final_source_drift"]
    )
    report["artifact_sha256"] = {p.name: sha256(p) for p in out.glob("*.log")}
    (out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(
        json.dumps(
            {
                "passed": report["capacity_recovery_passed"],
                "report": str(out / "report.json"),
            }
        )
    )
    return 0 if report["capacity_recovery_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
