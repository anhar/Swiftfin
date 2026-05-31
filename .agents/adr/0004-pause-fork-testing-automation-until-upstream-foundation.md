# Pause Fork Testing Automation Until Upstream Foundation

Status: accepted

We will document the proposed Swift Testing foundation on `ai/main` and pause further fork-only test-target, CI, and quality-script implementation until upstream has reviewed or merged the testing foundation. Simulator CI on macOS can consume meaningful maintainer budget, and fork-only commands would drift quickly if they assume a test target shape upstream has not accepted.

## Considered Options

- Add the full test target and CI immediately: fastest technical progress, but risks imposing CI cost and making unaccepted assumptions.
- Add fork-only quality scripts now: useful locally, but likely to hard-code speculative test commands.
- Pause implementation and document the strategy: slower, but preserves maintainer choice and avoids drift.

## Consequences

Future agents should not add `.agents/scripts/swiftfin-quality.sh` or CI test commands that assume `SwiftfinTests` exists until `ai/main` has been updated from the accepted upstream testing foundation.
