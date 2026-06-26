// lib/src/features/quiz/style_quiz_screen.dart

import 'package:flutter/material.dart';
import 'style_analyzer_logic.dart';

class StyleQuizScreen extends StatefulWidget {
  const StyleQuizScreen({Key? key}) : super(key: key);

  @override
  State<StyleQuizScreen> createState() => _StyleQuizScreenState();
}

class _StyleQuizScreenState extends State<StyleQuizScreen> {
  int _currentStep = 0;

  // المتغيرات لحفظ الإجابات
  BodyShape? _selectedShape;
  double _height = 160;
  bool _hideTummy = false;
  bool _largeBust = false;

  // النتيجة النهائية
  StyleResult? _result;

  // ============================================
  // 🎨 تعريف لوحة الألوان
  // ============================================
  static const Color _charcoal = Color(0xFF4A4A4A);
  static const Color _roseAccent = Color(0xFFF2C2D4);
  static const Color _earthyPink = Color(0xFFE9BBB6);
  static const Color _goldAccent = Color(0xFFEBC13D);
  static const Color _darkGold = Color(0xFFDEC170);
  static const Color _beige = Color(0xFFEEDECF);
  static const Color _darkBg = Color(0xFF333333);
  static const Color _pearlWhite = Color(0xFFFFFAF0);

  // قائمة بيانات أشكال الجسم
  final List<Map<String, dynamic>> _bodyShapesData = [
    {
      'type': BodyShape.hourglass,
      'label': 'ساعة رملية',
      'desc': 'أكتاف وأرداف متساوية مع خصر محدد',
      'image': 'assets/images/hourglass.png',
    },
    {
      'type': BodyShape.pear,
      'label': 'كمثري',
      'desc': 'أرداف أعرض من الأكتاف',
      'image': 'assets/images/pear.png',
    },
    {
      'type': BodyShape.apple,
      'label': 'تفاحة',
      'desc': 'الوزن متركز في الوسط وصدر ممتلئ',
      'image': 'assets/images/apple.png',
    },
    {
      'type': BodyShape.invertedTriangle,
      'label': 'مثلث مقلوب',
      'desc': 'أكتاف عريضة وأرداف نحيفة',
      'image': 'assets/images/inverted_triangle.png',
    },
    {
      'type': BodyShape.rectangle,
      'label': 'مستطيل',
      'desc': 'الجسم مستقيم وقليل المنحنيات',
      'image': 'assets/images/rectangle.png',
    },
  ];

  void _analyze() {
    if (_selectedShape == null) return;

    setState(() {
      _result = StyleAnalyzer.analyze(
        shape: _selectedShape!,
        heightCm: _height,
        wantsToHideTummy: _hideTummy,
        largeBust: _largeBust,
      );
    });
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _selectedShape = null;
      _result = null;
      _height = 160;
      _hideTummy = false;
      _largeBust = false;
    });
  }

  // 🔥 دالة لربط اسم الفستان بصورته
  String _getDressImage(String dressName) {
    if (dressName.contains('Mermaid')) return 'assets/images/dress_mermaid.png';
    if (dressName.contains('A-Line')) return 'assets/images/dress_aline.png';
    if (dressName.contains('Ballgown')) return 'assets/images/dress_ballgown.png';
    if (dressName.contains('Empire')) return 'assets/images/dress_empire.png';
    if (dressName.contains('Sheath')) return 'assets/images/dress_sheath.png';
    if (dressName.contains('Short')) return 'assets/images/dress_short.png';
    if (dressName.contains('Drop Waist')) return 'assets/images/dress_drop_waist.png';
    if (dressName.contains('Trumpet')) return 'assets/images/dress_mermaid.png';

    // الإضافات الجديدة
    if (dressName.contains('High Slit') || dressName.contains('فتحة')) return 'assets/images/dress_slit.png';
    if (dressName.contains('Princess')) return 'assets/images/dress_princess.png';
    if (dressName.contains('Modified A-Line')) return 'assets/images/dress_aline.png';

    return '';
  }

  // 🔥 دالة لربط اسم الياقة بصورتها (تم الإصلاح هنا ✅)
  String _getNecklineImage(String neckName) {
    if (neckName.contains('Plunging')) return 'assets/images/neck_plunging.png'; // تم تصحيح dressName إلى neckName
    if (neckName.contains('V-Neck')) return 'assets/images/neck_v.png';
    if (neckName.contains('Sweetheart')) return 'assets/images/neck_sweetheart.png';
    if (neckName.contains('Square')) return 'assets/images/neck_square.png';
    if (neckName.contains('Off-Shoulder')) return 'assets/images/neck_off_shoulder.png';
    if (neckName.contains('High Neck')) return 'assets/images/neck_high.png';
    if (neckName.contains('Boat')) return 'assets/images/neck_boat.png';

    // الإضافات الجديدة
    if (neckName.contains('Scoop')) return 'assets/images/neck_scoop.png';
    if (neckName.contains('Halter')) return 'assets/images/neck_halter.png';
    if (neckName.contains('Illusion')) return 'assets/images/neck_illusion.png';

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? _darkBg : _beige;
    final Color textColor = isDark ? _pearlWhite : _charcoal;
    final Color cardColor = isDark ? _charcoal : _earthyPink;
    final Color primaryButtonBg = _charcoal;
    final Color primaryButtonText = _earthyPink;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "محلل الستايل",
          style: TextStyle(color: _darkGold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _charcoal,
        iconTheme: const IconThemeData(color: _beige),
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _result != null
            ? _buildResultScreen(isDark, textColor, cardColor)
            : _buildQuizScreens(isDark, textColor, cardColor, primaryButtonBg, primaryButtonText),
      ),
    );
  }

  // =========================================
  // واجهة الأسئلة (Steps)
  // =========================================
  Widget _buildQuizScreens(bool isDark, Color textColor, Color cardColor, Color btnBg, Color btnText) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentStep + 1) / 3,
          backgroundColor: isDark ? Colors.black26 : Colors.white54,
          color: isDark ? _earthyPink : _charcoal,
          minHeight: 6,
        ),

        Expanded(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (_currentStep == 0) _step1BodyShape(isDark, textColor, cardColor),
              if (_currentStep == 1) _step2Measurements(isDark, textColor),
              if (_currentStep == 2) _step3FinalCheck(isDark, textColor, cardColor),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(20),
          color: isDark ? Colors.black12 : Colors.white10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton.icon(
                  onPressed: () => setState(() => _currentStep--),
                  icon: Icon(Icons.arrow_forward, color: textColor),
                  label: Text("السابق", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox(width: 80),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnBg,
                  foregroundColor: btnText,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (_currentStep == 0 && _selectedShape == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("الرجاء اختيار شكل الجسم للمتابعة")),
                    );
                    return;
                  }
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    _analyze();
                  }
                },
                child: Text(
                  _currentStep == 2 ? "تحليل النتيجة" : "التالي",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // ------------------------------------------
  // الخطوات 1, 2, 3
  // ------------------------------------------
  Widget _step1BodyShape(bool isDark, Color textColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("أي الأشكال التالية الأقرب لجسمك؟", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
          const SizedBox(height: 25),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
            itemCount: _bodyShapesData.length,
            itemBuilder: (ctx, i) {
              final item = _bodyShapesData[i];
              final isSelected = _selectedShape == item['type'];
              final Color currentCardBg = isSelected ? _roseAccent : cardColor;
              final Color contentColor = isDark ? (isSelected ? _charcoal : _pearlWhite) : _charcoal;

              return InkWell(
                onTap: () => setState(() => _selectedShape = item['type']),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    color: currentCardBg,
                    border: Border.all(color: isSelected ? _darkGold : Colors.transparent, width: isSelected ? 3 : 0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: Padding(padding: const EdgeInsets.all(12.0), child: Image.asset(item['image'], fit: BoxFit.contain))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(item['label'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: contentColor))),
                      Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 12), child: Text(item['desc'], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: contentColor.withOpacity(0.8)))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _step2Measurements(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.height, size: 50, color: _darkGold),
          const SizedBox(height: 20),
          Text("كم طولك تقريباً؟", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 50),
          Text("${_height.toInt()} سم", style: TextStyle(fontSize: 48, color: isDark ? _earthyPink : _charcoal, fontWeight: FontWeight.w900)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: _darkGold, inactiveTrackColor: textColor.withOpacity(0.3), thumbColor: _charcoal, overlayColor: _darkGold.withOpacity(0.2), valueIndicatorColor: _charcoal),
            child: Slider(value: _height, min: 140, max: 190, divisions: 50, label: _height.round().toString(), onChanged: (val) => setState(() => _height = val)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("140 سم", style: TextStyle(color: textColor)), Text("متوسط", style: TextStyle(color: textColor)), Text("190 سم", style: TextStyle(color: textColor))]))
        ],
      ),
    );
  }

  Widget _step3FinalCheck(bool isDark, Color textColor, Color cardColor) {
    final Color contentColor = isDark ? _pearlWhite : _charcoal;
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("لمسات أخيرة..", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 30),
          Container(decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)), child: SwitchListTile(title: Text("هل ترغبين بقصات تخفي منطقة البطن؟", style: TextStyle(fontWeight: FontWeight.bold, color: contentColor)), subtitle: Text("سنرشح لك قصات انسيابية من الوسط", style: TextStyle(color: contentColor.withOpacity(0.7), fontSize: 12)), activeColor: _darkGold, activeTrackColor: isDark ? Colors.black38 : _charcoal.withOpacity(0.3), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), value: _hideTummy, onChanged: (val) => setState(() => _hideTummy = val))),
          const SizedBox(height: 15),
          Container(decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)), child: SwitchListTile(title: Text("هل لديك صدر ممتلئ؟", style: TextStyle(fontWeight: FontWeight.bold, color: contentColor)), subtitle: Text("سنقترح ياقات مناسبة لتدعيم الشكل", style: TextStyle(color: contentColor.withOpacity(0.7), fontSize: 12)), activeColor: _darkGold, activeTrackColor: isDark ? Colors.black38 : _charcoal.withOpacity(0.3), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), value: _largeBust, onChanged: (val) => setState(() => _largeBust = val))),
        ],
      ),
    );
  }

  // =========================================
  // ✅ واجهة عرض النتيجة (المطورة)
  // =========================================
  Widget _buildResultScreen(bool isDark, Color textColor, Color cardColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. رأس الصفحة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 50),
            decoration: const BoxDecoration(
              color: _charcoal,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Column(
              children: [
                const CircleAvatar(radius: 35, backgroundColor: _earthyPink, child: Icon(Icons.check, size: 40, color: _charcoal)),
                const SizedBox(height: 20),
                const Text("تحليلك جاهز!", style: TextStyle(color: _beige, fontSize: 18)),
                const SizedBox(height: 5),
                Text(_result!.title, style: const TextStyle(color: _pearlWhite, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ],
            ),
          ),

          // 2. المحتوى
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أ) الاستراتيجية والشرح
                _buildSectionTitle("💡 التحليل والشكل", textColor),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                  child: Text(_result!.description, style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? _pearlWhite : _charcoal)),
                ),
                const SizedBox(height: 25),

                // ب) القصات المقترحة (صور كبيرة)
                _buildSectionTitle("✅ قصات تناسبك جداً", textColor),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _result!.recommendedCuts.map((cut) {
                    final String imagePath = _getDressImage(cut);
                    return _buildGraphicCard(cut, imagePath);
                  }).toList(),
                ),
                const SizedBox(height: 25),

                // ج) الياقات المناسبة (جديد ✨)
                if (_result!.bestNecklines.isNotEmpty) ...[
                  _buildSectionTitle("✨ الياقات (الفتحة)", textColor),
                  SizedBox(
                    height: 110, // سكرول أفقي
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _result!.bestNecklines.map((neck) {
                        final String img = _getNecklineImage(neck);
                        return Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: _buildGraphicCard(neck, img, isSmall: true),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],

                // د) الأقمشة
                _buildSectionTitle("🧵 الأقمشة المقترحة", textColor),
                Text(_result!.fabricAdvice, style: TextStyle(fontSize: 15, height: 1.5, color: textColor)),
                const SizedBox(height: 25),

                // هـ) نصائح إضافية (جديد ✨)
                if (_result!.stylingTips.isNotEmpty) ...[
                  _buildSectionTitle("🌟 نصائح ذهبية", textColor),
                  ..._result!.stylingTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, size: 18, color: _goldAccent),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tip, style: TextStyle(color: textColor, height: 1.4))),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 25),
                ],

                // و) الممنوعات
                _buildSectionTitle("❌ يفضل تجنبها", textColor),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _result!.avoidCuts.map((cut) => Chip(
                    label: Text(cut, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    backgroundColor: _charcoal.withOpacity(0.9),
                    side: BorderSide.none,
                    avatar: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.close, color: Colors.white, size: 14)),
                  )).toList(),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text("إعادة الاختبار", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: _charcoal, foregroundColor: _earthyPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة عرض الصور (للقصات والياقات)
  Widget _buildGraphicCard(String label, String imagePath, {bool isSmall = false}) {
    final double width = isSmall ? 90 : 100;
    final double height = isSmall ? 60 : 80;

    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _roseAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _earthyPink, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath.isNotEmpty)
            Image.asset(imagePath, height: height, fit: BoxFit.contain)
          else
            Icon(Icons.check_circle, size: height / 2, color: _charcoal),

          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _charcoal, height: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: _darkGold),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}