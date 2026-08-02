Garmin_SD - Instinct 2
======================

A trimmed-down copy of [Garmin_SD](https://github.com/OpenSeizureDetector/Garmin_SD)
(the OpenSeizureDetector Connect IQ watch app), stripped to only what is
needed to build and run for the **Instinct 2** device. See the original
project for background, licensing (GPLv3, see LICENSE) and full history.

# Build

Requires the Garmin Connect IQ SDK (installed via SDK Manager) with the
Instinct 2 device definition installed, and a developer key
(`developer_key` in this folder - not committed to git).

```
"<SDK>/bin/monkeyc.bat" -f monkey.jungle -d instinct2 -o GarminSD.prg -y developer_key -w
```

# Run in the simulator

```
"<SDK>/bin/connectiq.bat" &
"<SDK>/bin/monkeydo.bat" GarminSD.prg instinct2
```
