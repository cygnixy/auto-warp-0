# cygnixy/auto-warp-0

Autonomous autopilot and navigation bot for EVE Online. Flies active stargate routes to destination systems, executes 0km warps to stargates/stations, and manages in-flight transitions.

---

## Capabilities

- **Route Execution**: Traverses plotted routes jump-by-jump via stargate warps and dock commands.
- **Dynamic Destination Setting**: Sets destination using search bar when `destination` variable is specified.
- **In-Flight Fitting Survey**: Automatically executes ship module survey (`std.survey`) while in warp to optimize cycle time without stalling on grid.
- **Travel Tab Isolation**: Maintains Overview on dedicated travel tab to prevent unwanted target locks during transit.
- **Standing Order Management**: Detects and clears external/stale maneuvers (e.g. Approach) before issuing flight orders.

---

## Configuration Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `destination` | string | `""` | Destination system/station name. If empty, flies currently plotted route. |
| `travel_tab` | integer | `nil` | 1-based index of Overview tab for travel/navigation. |
| `survey_ship` | boolean | `true` | When true, surveys ship modules during warp transitions. |
| `remember_module_names` | boolean | `false` | When true, caches identified module names across sessions. |
| `downtime_guard_seconds` | integer | `300` | Aborts flight if cluster downtime is within threshold. |

---

## Testing

Run unit tests via `bot-harness`:

```bash
cargo run -p bot-harness -- --lib <path/to/std> <path/to/auto-warp-0>
```
