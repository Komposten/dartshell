enum ReturnType {
  stdout('Future<String>'),
  stdoutStderr('Future<(String, String)>');

  final String signature;

  const ReturnType(this.signature);

  static ReturnType of(String signature) =>
      values.where((value) => value.signature == signature).first;
}
