OpenSeizure Detector for Garmin Instinct 2
======================
This is a **fork** of [Garmin_SD](https://github.com/OpenSeizureDetector/Garmin_SD)
(the OpenSeizureDetector Connect IQ watch app), adapted **as-is** to build and
run on the **Instinct 2** device only. No functional changes were made beyond
what was required to target this device (device-specific resources such as
the launcher icon, and trimming unused build targets); all app logic and
behaviour are unchanged from upstream. See the original project for
background, features, licensing (GPLv3, see LICENSE) and full history.

# Build

Requires the Garmin Connect IQ SDK, version **8.1.1** (the version this
project was built/tested against), installed via the
[SDK Manager](https://developer.garmin.com/connect-iq/sdk/), with the
Instinct 2 device definition installed, and a developer key
(`developer_key` in this folder - not committed to git).

Open this folder in VS Code with the [Monkey C](https://marketplace.visualstudio.com/items?itemName=garmin.monkeyc)
extension installed, then use "Monkey C: Build Current Project" from the
command palette (or F5 to build and run in the simulator).

# Install on the watch

Connect the Instinct 2 to your computer via USB and copy the built
`.prg` file to the `Garmin/Apps` folder on the device.

<img width="30%" alt="image" src="https://github.com/user-attachments/assets/7fa3c958-3368-4809-81c4-08258649c692" />
