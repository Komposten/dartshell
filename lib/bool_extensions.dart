extension BoolExtensions on bool {
  void ifTrue(void Function() action) {
    if (this) {
      action();
    }
  }
}
