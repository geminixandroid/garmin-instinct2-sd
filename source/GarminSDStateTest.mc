using Toybox.Test;
import Toybox.Lang;

(:test)
function testGarminSDStateInitialModeIsRunning(logger as Test.Logger) as Boolean {
    var state = new GarminSDState();
    Test.assertEqualMessage(state.getMode(), MODE_RUNNING, "initial mode should be MODE_RUNNING");
    return true;
}

(:test)
function testGarminSDStateSetModeToMuteDlg(logger as Test.Logger) as Boolean {
    var state = new GarminSDState();
    state.setMode(MODE_MUTEDLG);
    Test.assertEqualMessage(state.getMode(), MODE_MUTEDLG, "mode should be MODE_MUTEDLG after setMode");
    return true;
}

(:test)
function testGarminSDStateSetModeOverwritesPreviousMode(logger as Test.Logger) as Boolean {
    var state = new GarminSDState();
    state.setMode(MODE_MUTEDLG);
    state.setMode(MODE_QUITDLG);
    Test.assertEqualMessage(state.getMode(), MODE_QUITDLG, "later setMode call should win");
    return true;
}
