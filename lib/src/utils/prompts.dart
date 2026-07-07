import 'package:interact2/interact2.dart';

bool confirmContinue({String prompt = "Continue?", bool defaultValue = false}) {
  return Confirm(
    prompt: prompt,
    defaultValue: defaultValue, // this is optional
    waitForNewLine: true, // optional and will be false by default
  ).interact();
}

SpinnerState spinnerWorking({
  String? inProgressPrompt,
  String Function()? done,
  String Function()? failed,
}) {
  return Spinner(
    icon: '',
    failedIcon: '',
    leftPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => inProgressPrompt ?? "Working...",
      SpinnerStateType.done => done?.call() ?? 'Done!\n',
      SpinnerStateType.failed => failed?.call() ?? 'Failed!\n',
    },
  ).interact();
}
