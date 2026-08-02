using Toybox.Test;
using Toybox.Sensor;
import Toybox.Lang;

(:test)
function testDataHandlerGetDataJsonFormat(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("1.2.3");
    var n = handler.mSamplesX.size();
    for (var i = 0; i < n; i += 1) {
        handler.mSamplesX[i] = 0;
        handler.mSamplesY[i] = 0;
        handler.mSamplesZ[i] = 0;
    }
    handler.mHR = 70;
    handler.mO2sat = 95;
    handler.mMute = true;

    var expectedData3D = "";
    for (var i = 0; i < n; i += 1) {
        if (i > 0) {
            expectedData3D = expectedData3D + ",";
        }
        expectedData3D = expectedData3D + "0,0,0";
    }
    var expected = "{dataType:'raw',data3D:[" + expectedData3D + "],HR:70,O2sat:95,Mute:1}";

    Test.assertEqualMessage(handler.getDataJson(), expected, "getDataJson() format mismatch");
    return true;
}

(:test)
function testDataHandlerGetDataJsonMuteFalseGivesZero(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("1.2.3");
    var n = handler.mSamplesX.size();
    for (var i = 0; i < n; i += 1) {
        handler.mSamplesX[i] = 0;
        handler.mSamplesY[i] = 0;
        handler.mSamplesZ[i] = 0;
    }
    handler.mMute = false;

    var json = handler.getDataJson();
    Test.assertMessage(json.find("Mute:0") != null, "Mute should be reported as 0 when not muted");
    return true;
}

(:test)
function testDataHandlerGetSettingsJsonStaticFields(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("9.9.9");
    var json = handler.getSettingsJson();

    Test.assertMessage(json.find("analysisPeriod: 5") != null, "analysisPeriod missing from settings json");
    Test.assertMessage(json.find("sampleFreq: 25") != null, "sampleFreq missing from settings json");
    Test.assertMessage(json.find("sdVersion: 9.9.9") != null, "sdVersion missing from settings json");
    Test.assertMessage(json.find("sdName: GarminSD") != null, "sdName missing from settings json");
    return true;
}

(:test)
function testDataHandlerMuteAlarmsSetsMuteFlag(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("1.0.0");
    Test.assertEqualMessage(handler.mMute, false, "mMute should start false");

    handler.muteAlarms();
    Test.assertEqualMessage(handler.mMute, true, "mMute should be true after muteAlarms()");
    return true;
}

(:test)
function testDataHandlerMuteTimerCallbackClearsMuteFlag(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("1.0.0");
    handler.muteAlarms();

    handler.muteTimerCallback();
    Test.assertEqualMessage(handler.mMute, false, "mMute should be false after muteTimerCallback()");
    return true;
}

(:test)
function testDataHandlerAccelCallbackCopiesValidSamples(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("1.0.0");

    var n = 25; // SAMPLE_PERIOD * SAMPLE_FREQUENCY
    var xs = new Array<Float or Number>[n];
    var ys = new Array<Float or Number>[n];
    var zs = new Array<Float or Number>[n];
    for (var i = 0; i < n; i += 1) {
        xs[i] = i;
        ys[i] = i * 2;
        zs[i] = i * 3;
    }

    var accelData = new Sensor.AccelerometerData();
    accelData.x = xs;
    accelData.y = ys;
    accelData.z = zs;
    var sensorData = new Sensor.SensorData();
    sensorData.accelerometerData = accelData;

    handler.accel_callback(sensorData);

    Test.assertEqualMessage(handler.nSamp, 1, "nSamp should increment after a valid sample window");
    Test.assertEqualMessage(handler.mSamplesX[0], 0, "mSamplesX[0] mismatch");
    Test.assertEqualMessage(handler.mSamplesX[24], 24, "mSamplesX[24] mismatch");
    Test.assertEqualMessage(handler.mSamplesY[24], 48, "mSamplesY[24] mismatch");
    Test.assertEqualMessage(handler.mSamplesZ[24], 72, "mSamplesZ[24] mismatch");
    return true;
}

(:test)
function testDataHandlerAccelCallbackZeroesSamplesOnWrongSize(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("1.0.0");

    // Pre-fill the window with non-zero values so we can tell they were cleared.
    for (var i = 0; i < 25; i += 1) {
        handler.mSamplesX[i] = 9;
        handler.mSamplesY[i] = 9;
        handler.mSamplesZ[i] = 9;
    }

    var wrongSize = 10; // not SAMPLE_PERIOD * SAMPLE_FREQUENCY (25)
    var xs = new Array<Float or Number>[wrongSize];
    var ys = new Array<Float or Number>[wrongSize];
    var zs = new Array<Float or Number>[wrongSize];
    for (var i = 0; i < wrongSize; i += 1) {
        xs[i] = i;
        ys[i] = i;
        zs[i] = i;
    }

    var accelData = new Sensor.AccelerometerData();
    accelData.x = xs;
    accelData.y = ys;
    accelData.z = zs;
    var sensorData = new Sensor.SensorData();
    sensorData.accelerometerData = accelData;

    handler.accel_callback(sensorData);

    Test.assertEqualMessage(handler.nSamp, 0, "nSamp should not increment when the sample window is invalid");
    Test.assertEqualMessage(handler.mSamplesX[0], 0, "mSamplesX should be zeroed on invalid sample window");
    Test.assertEqualMessage(handler.mSamplesY[24], 0, "mSamplesY should be zeroed on invalid sample window");
    Test.assertEqualMessage(handler.mSamplesZ[24], 0, "mSamplesZ should be zeroed on invalid sample window");
    return true;
}

// Feeds one valid 25-sample accelerometer window into the handler.
function feedValidAccelWindow(handler as GarminSDDataHandler) as Void {
    var n = 25; // SAMPLE_PERIOD * SAMPLE_FREQUENCY
    var xs = new Array<Float or Number>[n];
    var ys = new Array<Float or Number>[n];
    var zs = new Array<Float or Number>[n];
    for (var i = 0; i < n; i += 1) {
        xs[i] = i;
        ys[i] = i;
        zs[i] = i;
    }
    var accelData = new Sensor.AccelerometerData();
    accelData.x = xs;
    accelData.y = ys;
    accelData.z = zs;
    var sensorData = new Sensor.SensorData();
    sensorData.accelerometerData = accelData;
    handler.accel_callback(sensorData);
}

(:test)
function testDataHandlerAccelCallbackTriggersAnalysisAtEndOfPeriod(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("1.0.0");

    // ANALYSIS_PERIOD (5) full windows should trigger the HR/O2/reset logic
    // on the 5th call, and none of the earlier ones.
    for (var i = 0; i < 4; i += 1) {
        feedValidAccelWindow(handler);
        Test.assertEqualMessage(handler.nSamp, i + 1, "nSamp should just keep counting up before the analysis period elapses");
    }
    feedValidAccelWindow(handler);

    Test.assertEqualMessage(handler.nSamp, 0, "nSamp should reset to 0 once the analysis period elapses");
    // mHR is populated straight from Sensor.getInfo() - we can't control what
    // the simulator reports, but we can check it now mirrors the live reading.
    Test.assertMessage(handler.mHR == Sensor.getInfo().heartRate, "mHR should be refreshed from Sensor.getInfo().heartRate");
    return true;
}

(:test)
function testDataHandlerAccelCallbackForcesO2satZeroWhenSensorDisabled(logger as Test.Logger) as Boolean {
    var handler = new GarminSDDataHandler("1.0.0");
    handler.mO2SensorIsEnabled = false;
    handler.mO2sat = 123; // sentinel so we can tell it was actually overwritten

    for (var i = 0; i < 5; i += 1) {
        feedValidAccelWindow(handler);
    }

    Test.assertEqualMessage(handler.mO2sat, 0, "mO2sat should be forced to 0 when the O2 sensor is disabled, regardless of hardware support");
    return true;
}
