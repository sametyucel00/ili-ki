import 'package:flutter_test/flutter_test.dart';
import 'package:iliski_kocu_ai/core/utils/error_text.dart';

void main() {
  test('maps insufficient credits to user-facing text', () {
    final message = toUserFacingError(Exception('Insufficient credits'));
    expect(message.contains('kredi'), isTrue);
  });
}
