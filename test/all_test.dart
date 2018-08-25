import "package:test/test.dart";
import "package:geesdk/geesdk.dart";

void main() {
  test("String.split() splits the string on the delimiter", () {
    var string = "foo,bar,baz";
    expect(string.split(","), equals(["foo", "bar", "baz"]));
  });

  test("String.trim() removes surrounding whitespace", () {
    var string = "  foo ";
    expect(string.trim(), equals("foo"));
  });

  test("getMd5() ", () {
    var string = "test";
    expect(getMd5(string), equals("098f6bcd4621d373cade4e832627b4f6"));
  });
}
