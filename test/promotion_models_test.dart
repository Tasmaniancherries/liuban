import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/data/models/promotion_dto.dart';
import 'package:liuban/features/promotion/promotion_models.dart';

void main() {
  test('PromotionItem.fromDto copies fields', () {
    const dto = PromotionDto(
      id: 'x',
      title: 'T',
      subtitle: 'S',
      publishedAt: 'd',
      body: 'b',
    );
    final item = PromotionItem.fromDto(dto);
    expect(item.id, 'x');
    expect(item.title, 'T');
    expect(item.subtitle, 'S');
    expect(item.publishedAt, 'd');
    expect(item.body, 'b');
  });

  test('promotionById finds mock id or returns null', () {
    expect(promotionById('1'), isNotNull);
    expect(promotionById('1')!.title, isNotEmpty);
    expect(promotionById('missing'), isNull);
  });
}
