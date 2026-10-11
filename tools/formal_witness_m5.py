"""Retain reachable input witnesses alongside scoped safety proofs."""
from pathlib import Path
import hashlib
import subprocess


def cover(yosys, source, directory, top, observer, reset=None, parameters="", cycles=16,
          remove_assertions=False, input_constraints=""):
    directory = Path(directory)
    source = Path(source)
    text = source.read_text()
    if text.count("endmodule") != 1:
        raise ValueError("cover requires one instrumented module")
    generated = directory / "cover.sv"
    generated.write_text(text.replace("endmodule", observer + "\nendmodule"))
    script = directory / "cover.ys"
    trace = directory / "cover.vcd"
    reset_setting = f"-set-at 1 {reset} " if reset else ""
    cleanup = "chformal -assert -remove\nopt\n" if remove_assertions else ""
    script.write_text(
        f"read_verilog -formal -sv {generated}\n{parameters}"
        f"hierarchy -top {top}\nproc\nflatten\nopt\nmemory_map\nopt\n"
        f"{cleanup}sat -seq {cycles} {reset_setting}{input_constraints} -set-assumes "
        f"-prove proof_exercised 0 -show-inputs -show proof_exercised -dump_vcd {trace}\n"
    )
    log_path = directory / "cover.log"
    with log_path.open("w") as log:
        try:
            code = subprocess.run(
                [yosys, "-Q", "-s", str(script)], stdout=log,
                stderr=subprocess.STDOUT, timeout=120,
            ).returncode
        except subprocess.TimeoutExpired:
            code = 124
    # Refuting exercised==0 is the desired existential cover witness. A tool
    # failure or an induction-only model is never a positive witness.
    reached = code == 0 and "model found: FAIL!" in log_path.read_text() and trace.is_file()
    return {
        "reachable": reached,
        "returncode": code,
        "cycles": cycles,
        "trace": str(trace),
        "method": "bounded SAT input witness under the proof assumptions",
        "initial_reset": reset,
        "input_constraints": input_constraints,
        "artifacts": {
            str(p): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in (generated, script, trace, log_path) if p.is_file()
        },
    }


FIFO_OBSERVER = """
reg saw_selected = 0, saw_rank = 0, saw_overlap = 0, saw_retired = 0;
always @(posedge clk) begin
 if (!rst_n || clear) begin saw_selected<=0;saw_rank<=0;saw_overlap<=0;saw_retired<=0; end
 else if (established) begin
  if (!watched_valid && select_transaction && do_add && tail_ptr == watched_address) begin
   saw_selected<=1;
   if (count > (do_pop ? 1 : 0)) saw_rank<=1;
  end
  if (watched_valid && do_add && do_pop) saw_overlap<=1;
  if (retire_output) saw_retired<=1;
 end
end
(* keep *) wire proof_exercised = saw_selected && saw_retired @EXTRA@;
"""

GUARD_OBSERVER = """
reg witnessed_start = 0, witnessed_finish = 0;
reg seen_read_stall = 0, seen_write_stall = 0, seen_reply_delay = 0;
always @(posedge clk) begin
 if (reset) begin witnessed_start<=0;witnessed_finish<=0;seen_read_stall<=0;seen_write_stall<=0;seen_reply_delay<=0; end
 else if (established) begin
  if (controller_done && count != 0 && state == COLLECT) witnessed_start<=1;
  if (witnessed_start && idle) witnessed_finish<=1;
  if (bg_cmd_valid && !bg_cmd_ready && !bg_cmd_write) seen_read_stall<=1;
  if (bg_cmd_valid && !bg_cmd_ready && bg_cmd_write) seen_write_stall<=1;
  if (pending_read && !bg_rsp_valid) seen_reply_delay<=1;
 end
end
(* keep *) wire proof_exercised = witnessed_finish @EXTRA@;
"""
