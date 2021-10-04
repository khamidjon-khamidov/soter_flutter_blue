extension ToMacExt on String {
  static final RegExp _numeric = RegExp(r'^-?[0-9]+$');

  String toMac() {
    if (contains(':') || _numeric.hasMatch(this)) {
      return this;
    }

    String temp;
    try {
      temp = BigInt.parse(this, radix: 10).toRadixString(16);
    } catch (e) {
      return this;
    }

    if (temp.length < 2 || temp.length % 2 == 1) {
      return this;
    }

    String result = temp.substring(0, 2);
    temp = temp.substring(2);

    while (temp.isNotEmpty) {
      result += (':' + temp.substring(0, 2));
      temp = temp.substring(2);
    }

    return result;
  }
}
