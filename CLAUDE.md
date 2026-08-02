# GarminSD (Instinct 2)

Garmin Connect IQ watch app (Monkey C), trimmed to target the Instinct 2 only.
Fork of [OpenSeizureDetector/Garmin_SD](https://github.com/OpenSeizureDetector/Garmin_SD).
It is **not** a seizure detector itself — it's a sensor relay + alarm UI: it
streams accelerometer/HR/SpO2 data to a local OpenSeizureDetector server
(default `http://127.0.0.1:8080`) over HTTP, and reflects the server's alarm
state back via vibration/sound/backlight.

## Source layout (`source/`)
- `GarminSDApp.mc` — `AppBase` entry point; 1s repeating `Timer`, wires up the view + delegate.
- `GarminSDView.mc` — watch UI (view + input delegate `SdDelegate`).
- `GarminSDState.mc` — state machine: `Mode` enum (`MODE_RUNNING`, `MODE_MUTEDLG`, `MODE_QUITDLG`).
- `GarminSDDataHandler.mc` — core logic: buffers accelerometer samples (`ANALYSIS_PERIOD=5`s × `SAMPLE_FREQUENCY=25`Hz = 125 samples/axis), reads HR/SpO2 via `Sensor.getInfo()`, serializes to JSON (`getDataJson()`, `getSettingsJson()`), handles the 5-min mute timer.
- `GarminSDComms.mc` — HTTP layer (`Communications.makeWebRequest`) posting to `/data` and `/settings`, polling status, triggering Attention (vibrate/tone/backlight) from server-reported `alarmState`/`alarmPhrase`. Reads user toggles from `Storage` (`MENUITEM_VIBRATION`/`SOUND`/`LIGHT`/`O2SENSOR`).
- `GarminSDCommon.mc` — `writeLog()` helper + `MENUITEM_*` settings enum.

The accelerometer windowing and the JSON wire format are the highest-impact
places for bugs — that payload is what OSD actually analyzes.

## Toolchain
Connect IQ SDK 8.1.1 is installed locally at
`%USERPROFILE%\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.1.1-2025-03-27-66dae750f`
(path recorded in `current-sdk.cfg`). VS Code has the `garmin.monkey-c`
extension; `.vscode/launch.json` already has "Run App" / "Run Tests" / "Run
Complication Apps" / "Run Native Pairing" configs.

## Tests
Unit tests live next to the code they cover (`source/*Test.mc`), using
Connect IQ's native `(:test)` framework (`Toybox.Test`). `(:test)`-annotated
code compiles in only under `-t` — verified it does not leak into normal
builds (grepped a non-`-t` build's debug symbols for the test function
names: zero matches).

CLI workflow (`$SDK` = the SDK `bin` folder above):
1. `monkeyc.bat -o build/test.prg -f monkey.jungle -d instinct2 -y developer_key -t -w`
2. Start the simulator as its own process first — `monkeydo` requires it
   already running (`simulator.exe`; on Windows, start it via PowerShell
   `Start-Process`, not a backgrounded Bash job — that didn't reliably start it).
3. `monkeydo.bat build/test.prg instinct2 /t` (all tests) or `/t <testName>`
   for one.
4. From Git Bash specifically: MSYS path-conversion mangles a bare `/t` arg
   into a bogus path — prefix the command with `MSYS_NO_PATHCONV=1`. Not an
   issue from PowerShell/cmd.
5. Stop the simulator process afterward — nothing does it automatically.

API quirks hit while writing tests:
- `Test.assertEqualMessage(actual, expected, msg)` throws `Unexpected Type
  Error: Failed invoking <symbol>` if `actual` is `null` (calls `.equals()`
  on it with no null check). Hits `Sensor.getInfo().heartRate`/
  `.oxygenSaturation`, which are `null` in the simulator with no real
  sensor. Use `Test.assertMessage(a == b, msg)` instead whenever the actual
  value might legitimately be `null`.
- `Toybox.Sensor.AccelerometerData`/`SensorData` have public no-arg
  constructors and writable fields (`x`/`y`/`z`, `accelerometerData`) despite
  being system-fed data classes — fake sensor payloads can be built directly
  in tests and fed into `GarminSDDataHandler.accel_callback()`, no mocking
  needed.
- Calling `accel_callback()` `ANALYSIS_PERIOD` (5) times triggers a real
  `Communications.makeWebRequest()` to `127.0.0.1:8080` as a side effect —
  harmless in tests (fails silently, async) but explains stray log noise.

When adding tests here, keep only genuinely useful ones: no duplicate tests
that just swap an enum value with no new coverage, and no assertions whose
"expected" value re-implements the same conditional as the code under test
(mirrors it instead of independently verifying it) — prefer a sentinel value
that proves a real overwrite happened.
