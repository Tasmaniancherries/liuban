import "package:liuban/data/models/promotion_dto.dart";

class PromotionItem {
  const PromotionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.publishedAt,
    required this.body,
  });

  final String id;
  final String title;
  final String subtitle;
  final String publishedAt;
  final String body;

  factory PromotionItem.fromDto(PromotionDto d) => PromotionItem(
        id: d.id,
        title: d.title,
        subtitle: d.subtitle,
        publishedAt: d.publishedAt,
        body: d.body,
      );
}

const kMockPromotions = <PromotionItem>[
  PromotionItem(
    id: "1",
    title: "初秋租房節 · 港島學生公寓早鳥優惠",
    subtitle: "留伴 · 平台精選",
    publishedAt: "2026-03-28",
    body: "本文為推廣區示例。\n\n合作方供稿、平台審核後發佈；正式上線可內嵌圖片與外連。洽談請透過「訊息 · 官方客服」。",
  ),
  PromotionItem(
    id: "2",
    title: "法律講座：留學生簽證與兼職須知",
    subtitle: "留伴 · 合作機構",
    publishedAt: "2026-03-20",
    body: "示例內容：點進後為完整文章區塊，版面可仿公眾號或新聞 App。",
  ),
];

PromotionItem? promotionById(String id) {
  for (final p in kMockPromotions) {
    if (p.id == id) return p;
  }
  return null;
}
