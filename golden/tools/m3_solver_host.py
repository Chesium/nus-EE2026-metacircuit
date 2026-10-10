#!/usr/bin/env python3
"""D-012 simulated board S, with deterministic stale/corrupt reply witnesses."""
import argparse
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from src.uart_link.frontend_tester import FrontendTester
from src.uart_link.protocol import encode_packet, ErrorPacket


class Endpoint:
    def __init__(self):
        self.data = bytearray()

    def write(self, data):
        self.data.extend(data)
        return len(data)

    def flush(self):
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--faults', action='store_true')
    args = parser.parse_args()
    endpoint = Endpoint()
    tester = FrontendTester(endpoint, logger=lambda message: print(message, file=sys.stderr, flush=True))
    replies = 0
    for raw in sys.stdin:
        message = json.loads(raw)
        if message['event'] != 'line':
            continue
        tester.handle_line(bytes.fromhex(message['hex']))
        reply = {}
        if endpoint.data:
            replies += 1
            text = endpoint.data.decode('ascii')
            endpoint.data.clear()
            # The first real solve is deliberately delivered after a later edit.
            if args.faults and replies == 1:
                reply['delay_bits'] = 15000
                text += encode_packet(ErrorPacket(0, 4, 0)).decode('ascii') + '@VB,0000,01,00*00\r\n'
            reply['text'] = text
        print(json.dumps(reply), flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
