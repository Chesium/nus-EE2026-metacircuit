# Existing-product floating-point characterization for M5

Run `python3 tools/verify_fp_m5.py --out golden/out/m5-fp/characterization`.
This runs **actual AMD floating-point IP simulation**, using the already-present
`src/ip/floating_point_{fma,div}/sim/*.vhd` wrappers and installed Vivado2025.2
precompiled libraries in an isolated output directory. It neither regenerates
nor upgrades IP. A successful exit means this narrowly declared characterization
passed; it does **not** mean M5 readiness or original-XCI synthesis is qualified.

The tracked XCIs identify2018.2/IPrevision6; ignored existing output-product
headers identify2025.2/IPrevision21. The runner compares every original
`MODELPARAM_VALUE.C_*` (70 per core) with the generated wrapper generic maps.
All70 match, including single precision, FMA/divide operations, latency16/28,
rate1, nonblocking flow, no reset, no output backpressure, and exceptions. There
are77 total generated generic assignments; unmapped original model parameters
are rejected. Revision identity mismatch is recorded separately and remains a
synthesis/provenance blocker. Existing project LU simulation caches use
`src/ip_new`; this runner uses neither those caches nor that directory.

`M5FpCharacterization.sv` streams directed edge cases plus512 deterministic
random vectors per operator through the real primitives. A separate Python
oracle computes exact rational products/sums/divisions, then rounds directly
once to binary32, nearest even. No host double-precision arithmetic determines
acceptance. Expected signed-zero, canonical quiet-NaN, denormal-input/result
flush and exception behavior follows [AMD PG060](https://docs.amd.com/api/khub/documents/ym1A7qsltTGP_saZFTrikQ/content).
The corpus covers fused cancellation, both tie parities, signed zero,
quiet/signaling NaNs, infinities, overflow/underflow, invalid operations and
divide-by-zero. Random normal operands span both signs, all normal exponents
and mantissas. Valid patterns include back-to-back input and zero-to-three
idle cycles. Each result and exception field must match bit for bit, with one
output per valid input and no extra outputs during the final drain.

Latency16/28 is measured using the inclusive count of sampling edges from the
input-valid edge to the edge where output-valid becomes visible. The elapsed
edge difference is15/27. This convention exactly matches the configured
pipeline lengths; the report records16/28 for every observed result. Reset and
output backpressure are absent in these configurations; independently skewed
input channel valids are not qualified by this corpus.

Four cold negative runs corrupt FMA data, divide flags, FMA expected latency
and divide expected latency. Each must produce its specific first-case mismatch
and no pass marker. **XSim returns0 on these `$fatal` exits**, so exit status
alone is insufficient; the runner checks the fatal witness explicitly.

The report pins original XCIs, actual wrapper products, bench/runner source,
Vivado wrapper/unwrapped tools, complete used precompiled libraries (including
FPGA primitive semantics), generated fixtures and logs by SHA256. Source/tool/
library drift during execution invalidates characterization. It retains command
lines, configuration comparisons, tool logs and the exact sampled bit words.

Final evidence: `golden/out/m5-fp/characterization-final-20261010/report.json`.
527FMA and527DIV vectors passed, all measured latencies16/28, all four negative
controls detected. Nine FP tests and eight solver runner tests pass:
`python3 -m unittest discover -s tools/tests -p 'test_verify_*m5.py'`.

Existing Verilator FP stand-ins remain **unvalidated**: latency4/6 differs;
exception flags are always0; denormal handling differs. This characterization
cannot turn the previous stand-in solver runs into actual-IP results. Next use
these pinned config-equivalent products to execute actual solver fixtures in
XSim, or obtain compatible original-revision products and separately qualify
that provenance. Keep the original locked-XCI synthesis constraint explicit.
