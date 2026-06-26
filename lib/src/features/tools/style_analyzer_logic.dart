// lib/src/features/quiz/style_analyzer_logic.dart

enum BodyShape { hourglass, pear, apple, rectangle, invertedTriangle }
enum HeightCategory { petite, average, tall }

class StyleResult {
  final String title;
  final String description;      // شرح مفصل عن استراتيجية التنسيق
  final List<String> recommendedCuts; // القصات المثالية
  final List<String> avoidCuts;      // قصات يجب الحذر منها
  final List<String> bestNecklines;  // الياقات المناسبة (جديد)
  final String fabricAdvice;         // نصيحة خامة القماش
  final List<String> stylingTips;    // نصائح تنسيق إضافية (جديد)

  StyleResult({
    required this.title,
    required this.description,
    required this.recommendedCuts,
    required this.avoidCuts,
    required this.bestNecklines,
    required this.fabricAdvice,
    required this.stylingTips,
  });
}

class StyleAnalyzer {

  // دالة التحليل الرئيسية المطورة
  static StyleResult analyze({
    required BodyShape shape,
    required double heightCm,
    bool wantsToHideTummy = false,
    bool largeBust = false,
  }) {

    // 1. تحديد فئة الطول بدقة
    HeightCategory heightCat;
    if (heightCm < 160) {
      heightCat = HeightCategory.petite;
    } else if (heightCm >= 175) {
      heightCat = HeightCategory.tall;
    } else {
      heightCat = HeightCategory.average;
    }

    // متغيرات لتجميع النتائج
    String title = "";
    String strategy = "";
    List<String> bestCuts = [];
    List<String> avoidCuts = [];
    List<String> necklines = [];
    String fabrics = "";
    List<String> tips = [];

    // 2. التحليل الأساسي حسب شكل الجسم (Base Logic)
    switch (shape) {
      case BodyShape.hourglass:
        title = "جسم الساعة الرملية (المتوازن)";
        strategy = "جسمك يتميز بتوازن مثالي بين الأكتاف والأرداف مع خصر محدد بوضوح. الاستراتيجية الذهبية لكِ هي: \"لا تخفي منحنياتك بل احتضنيها\".";
        bestCuts = ["Mermaid (حورية البحر)", "Trumpet", "Sheath (القصة المستقيمة)", "A-Line (محدد الخصر)"];
        avoidCuts = ["Empire (القصة تحت الصدر مباشرة)", "الفساتين الواسعة جداً (Tent Dress)"];
        fabrics = "الأقمشة التي لها ثقل وانسيابية مثل الكريب، الساتان الحريري، والدانتيل الناعم الذي يتبع خطوط الجسم.";
        tips.add("استخدمي الأحزمة الرفيعة لإبراز الخصر أكثر.");
        break;

      case BodyShape.pear:
        title = "جسم الكمثرى (الأنثوي)";
        strategy = "تتركز الانحناءات في الجزء السفلي. هدفنا هو خلق توازن بصري عبر جذب الانتباه للجزء العلوي وتنحيف الجزء السفلي بنعومة.";
        bestCuts = ["A-Line (الأفضل بلا منازع)", "Ballgown (الأميرات)", "Empire Waist"];
        avoidCuts = ["Mermaid (قد يبرز الوركين بشكل مبالغ)", "Sheath الضيق من الأسفل", "الكسرات الكثيرة عند الخصر"];
        fabrics = "الجزء العلوي: دانتيل مطرز أو شك. الجزء السفلي: أقمشة خفيفة لا تلتصق مثل الشيفون، الأورجانزا، أو التول الناعم.";
        tips.add("اختاري طرحة قصيرة تنتهي عند الأكتاف لإضافة حجم علوي.");
        break;

      case BodyShape.apple:
        title = "جسم التفاحة (المميز)";
        strategy = "يتركز الحجم في المنطقة الوسطى والصدر، وغالباً ما تتمتعين بساقين جميلتين. هدفنا هو سحب النظر بعيداً عن البطن وإطالة الجذع.";
        bestCuts = ["Empire (قصة تحت الصدر)", "A-Line واسع وهيكلي", "Princess Cut (قصة البرنسيس)"];
        avoidCuts = ["Mermaid", "Ballgown ضخمة جداً", "أحزمة عريضة على الخصر الطبيعي"];
        fabrics = "الأقمشة الهيكلية التي تمسك القوام مثل الميكادو (Mikado) أو التفتا، وتجنبي الساتان اللامع الرقيق.";
        tips.add("الفساتين ذات الدرابيه (الثنيات المائلة) عند البطن تخفي العيوب بذكاء مذهل.");
        break;

      case BodyShape.rectangle:
        title = "الجسم المستطيل (الرياضي)";
        strategy = "جسمك متناسق لكن بخصر غير بارز. مهمتنا هي \"خلق الوهم\" بوجود منحنيات وخصر أصغر عبر القصات الذكية.";
        bestCuts = ["Ballgown (لخلق حجم سفلي)", "Sheath مع تنورة إضافية (Overskirt)", "A-Line"];
        avoidCuts = ["الفساتين الضيقة جداً بدون تفاصيل", "القصات المستقيمة تماماً"];
        fabrics = "تحتاجين أقمشة تعطي حجماً وشكلاً مثل الدانتيل السميك، التول المكشكش، والجاكار.";
        tips.add("ابحثي عن فساتين بفتحات جانبية (Cut-outs) عند الخصر، فهي تخلق خصراً وهمياً فوراً.");
        break;

      case BodyShape.invertedTriangle:
        title = "المثلث المقلوب (الجذاب)";
        strategy = "أكتافك أعرض من وركيك. الهدف هو تنعيم عرض الأكتاف وإضافة حجم للأرداف لتحقيق التوازن.";
        bestCuts = ["Ballgown (كبير من الأسفل)", "A-Line منفوش", "Short Dresses (لإبراز الساقين)"];
        avoidCuts = ["Mermaid (قد يبرز عدم التوازن)", "ياقة القارب (Boat Neck)", "أكمام منفوخة"];
        fabrics = "الجزء السفلي يحتاج أقمشة كثيفة (تول طبقات)، والجزء العلوي بسيط وناعم.";
        tips.add("تجنبي التطريز الكثيف على الأكتاف، وركزي الزينة في ذيل الفستان.");
        break;
    }

    // 3. تحليل الئبات (Necklines) بناءً على الصدر والجسم
    if (largeBust) {
      necklines = ["V-Neck (عريض)", "Square (مربع)", "Sweetheart (مع حمالات)"];
      tips.add("بما أن الصدر ممتلئ، تجنبي الياقات العالية (High Neck) لأنها ستخفي الرقبة وتزيد الحجم.");
      // نصيحة خاصة للتفاحة مع صدر كبير
      if (shape == BodyShape.apple) {
        necklines.add("Empire Scoop");
      }
    } else {
      // صدر صغير/متوسط
      necklines = ["Plunging V (عميق)", "Illusion Neckline", "Halter Top", "Off-Shoulder"];
      if (shape == BodyShape.pear) {
        necklines.add("Boat Neck (ئبة القارب)"); // ممتاز لجسم الإجاصة لأنه يعرض الأكتاف
      }
    }

    // 4. تعديلات متقدمة بناءً على الطول (Advanced Height Logic)
    if (heightCat == HeightCategory.petite) {
      // للقصيرات
      strategy += "\n\n📏 لطولك: الهدف هو الإطالة البصرية.";
      if (bestCuts.contains("Ballgown (الأميرات)")) {
        bestCuts.remove("Ballgown (الأميرات)");
        bestCuts.add("Modified A-Line (منفوش ناعم)"); // استبدال المنفوش الضخم بمنفوش ناعم
      }
      avoidCuts.add("Drop Waist (الخصر الساقط)"); // يقصر الساقين
      bestCuts.add("Empire Waist"); // يطيل الساقين
      bestCuts.add("High Slit (فتحة ساق)"); // خدعة بصرية للطول
      tips.add("اعتمدي تسريحة شعر مرفوعة (Updo) لتضيفي بضع سنتيمترات لطولك.");
    } else if (heightCat == HeightCategory.tall) {
      // للطويلات
      tips.add("بسبب طولك، يمكنك ارتداء الفساتين ذات الزخارف الكبيرة والذيل الطويل جداً (Cathedral Train) بكل ثقة.");
      bestCuts.add("Drop Waist"); // رائع للطويلات فقط
    }

    // 5. التعامل مع منطقة البطن (Tummy Control Logic)
    if (wantsToHideTummy) {
      if (!bestCuts.contains("Empire (قصة تحت الصدر)")) {
        bestCuts.insert(0, "Empire / High A-Line");
      }
      tips.add("لإخفاء البطن: ابحثي عن فساتين بكسرات مائلة (Ruched Waist) في منطقة الوسط، فهي تخفي أي بروز.");
      avoidCuts.add("Satin/Silk (ساتان ناعم على البطن)");
    }

    // تجهيز النتيجة النهائية
    return StyleResult(
      title: title,
      description: strategy,
      recommendedCuts: bestCuts,
      avoidCuts: avoidCuts,
      bestNecklines: necklines,
      fabricAdvice: fabrics,
      stylingTips: tips,
    );
  }
}