import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:travel_memories/themes/app_background_theme.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:flutter/services.dart' show rootBundle;

class Memory {
  final String title;
  final DateTime date;
  final String description;
  final String mood;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String city;
  final String attractionName;

  Memory({
    required this.title,
    required this.date,
    required this.description,
    required this.mood,
    this.imagePath,
    this.imageBytes,
    required this.city,
    required this.attractionName,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'mood': mood,
      'imagePath': imagePath,
      'city': city,
      'attractionName': attractionName,
    };
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      title: json['title'] ?? '',
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
      mood: json['mood'] ?? '',
      imagePath: json['imagePath'],
      city: json['city'] ?? '',
      attractionName: json['attractionName'] ?? '',
    );
  }
}

class AddMemoryPage extends StatefulWidget {
  final String? initialCity;
  final String? initialAttraction;
  final Memory? initialMemory;

  const AddMemoryPage({
    super.key,
    this.initialCity,
    this.initialAttraction,
    this.initialMemory,
    this.onMemorySaved,
  });

  final Function(Memory)? onMemorySaved;

  @override
  State<AddMemoryPage> createState() => _AddMemoryPageState();
}

class _AddMemoryPageState extends State<AddMemoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedMood;
  String _selectedCity = '';
  String _selectedAttraction = '';
  List<String> _cities = [];
  bool _isFromAttraction = false;
  bool get _isEditing => widget.initialMemory != null;

  final List<String> _moodOptions = [
    '😊 خوشحال',
    '😘 عاشق',
    '😌 آرام',
    '😢 ناراحت',
    '🤩 هیجان‌زده',
    '😴 خواب‌آلود',
  ];

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isImageLoading = false;

  Color _getPrimaryColor(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      if (theme.primaryColor == const Color.fromARGB(255, 190, 123, 202)) {
        return const Color(0xFFE8D5F5);
      }
      return Colors.white;
    }
    return const Color(0xFFFFE4E1);
  }

  Color _getTextColor(BuildContext context) {
    final bgTheme = Theme.of(context).extension<AppBackgroundTheme>();
    return bgTheme?.textColor ?? Colors.white;
  }

  Color _getCardColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.7);
  }

  Color _getAccentColor(BuildContext context) {
    final bgTheme = Theme.of(context).extension<AppBackgroundTheme>();
    return bgTheme!.memoryTextColor[1];
  }

  List<Color> _getGradientColors(BuildContext context) {
    final bgTheme = Theme.of(context).extension<AppBackgroundTheme>();
    return bgTheme?.gradientColors ??
        [
          const Color(0xFFFFF0F5),
          const Color(0xFFFFE4E1),
          const Color(0xFFFFD1DC),
        ];
  }

  @override
  void initState() {
    super.initState();

    final existing = widget.initialMemory;

    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _selectedDate = existing?.date ?? DateTime.now();
    _selectedMood = existing?.mood ?? _moodOptions.first;

    if (existing != null) {
      _selectedCity = existing.city;
      _selectedAttraction = existing.attractionName;
      _isFromAttraction = existing.attractionName.isNotEmpty;

      if (existing.imageBytes != null) {
        _selectedImageBytes = existing.imageBytes;
      } else if (existing.imagePath != null &&
          existing.imagePath!.isNotEmpty &&
          !kIsWeb) {
        final file = File(existing.imagePath!);
        if (file.existsSync()) {
          _selectedImage = file;
        }
      }
    } else {
      if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
        _isFromAttraction = true;
        _selectedCity = widget.initialCity!;
      }
      if (widget.initialAttraction != null &&
          widget.initialAttraction!.isNotEmpty) {
        _selectedAttraction = widget.initialAttraction!;
      }
    }

    _loadCitiesFromJson();
  }

  Future<void> _loadCitiesFromJson() async {
    try {
      final String response = await rootBundle.loadString('data/cities.json');
      final data = json.decode(response);
      final loadedCities = List<Map<String, dynamic>>.from(data['cities']);

      setState(() {
        _cities = loadedCities.map((city) => city['name'] as String).toList();

        if (!_isFromAttraction && !_isEditing && _selectedCity.isEmpty && _cities.isNotEmpty) {
          _selectedCity = _cities.first;
        }
      });
    } catch (e) {
      setState(() {
        _cities = [
          'تهران', 'اصفهان', 'شیراز', 'مشهد', 'تبریز',
          'کرمانشاه', 'اهواز', 'رشت', 'کرمان', 'یزد',
          'قزوین', 'سنندج', 'همدان', 'اراک', 'اردبیل'
        ];
        if (!_isFromAttraction && !_isEditing && _selectedCity.isEmpty && _cities.isNotEmpty) {
          _selectedCity = _cities.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor(context);
    final textColor = _getTextColor(context);
    final cardColor = _getCardColor(context);
    final gradientColors = _getGradientColors(context);

    String titleText = _isEditing ? 'ویرایش خاطره' : 'خاطره جدید';
    if (!_isEditing) {
      if (_selectedAttraction.isNotEmpty) {
        titleText = 'خاطره $_selectedAttraction';
      } else if (_selectedCity.isNotEmpty) {
        titleText = 'خاطره در $_selectedCity';
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEditing ? '✏️' : '✍️', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                titleText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 8),
                ],
              ),
              child: Icon(Icons.arrow_back_ios, size: 18, color: accentColor),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.help_outline, size: 20, color: accentColor),
              ),
              onPressed: _showHelpDialog,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: accentColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_selectedAttraction.isNotEmpty) ...[
                              _buildAttractionDisplay(
                                context: context,
                                accentColor: accentColor,
                                textColor: textColor,
                                cardColor: cardColor,
                              ),
                              const SizedBox(height: 20),
                            ],
                            _buildCitySelector(
                              context: context,
                              accentColor: accentColor,
                              textColor: textColor,
                              cardColor: cardColor,
                            ),
                            const SizedBox(height: 20),
                            _buildCuteTextField(
                              context: context,
                              controller: _titleController,
                              label: '📝 عنوان خاطره',
                              hint: 'یه عنوان قشنگ برای خاطره‌ت انتخاب کن...',
                              icon: Icons.title,
                              accentColor: accentColor,
                              textColor: textColor,
                              cardColor: cardColor,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'لطفاً یه عنوان وارد کن 💕';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildDatePicker(
                              context: context,
                              accentColor: accentColor,
                              textColor: textColor,
                              cardColor: cardColor,
                            ),
                            const SizedBox(height: 20),
                            _buildMoodSelector(
                              context: context,
                              accentColor: accentColor,
                              textColor: textColor,
                              cardColor: cardColor,
                            ),
                            const SizedBox(height: 20),
                            _buildCuteTextField(
                              context: context,
                              controller: _descriptionController,
                              label: '📖 متن خاطره',
                              hint: 'چیزی که امروز اتفاق افتاد رو بنویس... ✨',
                              icon: Icons.edit_note,
                              maxLines: 5,
                              accentColor: accentColor,
                              textColor: textColor,
                              cardColor: cardColor,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'لطفاً خاطره‌ات رو بنویس 🌸';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildImagePickerWidget(
                              context: context,
                              accentColor: accentColor,
                              textColor: textColor,
                              cardColor: cardColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSubmitButton(
                      context: context,
                      accentColor: accentColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '💖 هر خاطره یک گنجینه‌ست...',
                        style: TextStyle(
                          color: accentColor.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttractionDisplay({
    required BuildContext context,
    required Color accentColor,
    required Color textColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            '📍 جاذبه',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.place,
                color: accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedAttraction,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'جاذبه',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCitySelector({
    required BuildContext context,
    required Color accentColor,
    required Color textColor,
    required Color cardColor,
  }) {
    if (_isFromAttraction) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              '🏙️ شهر',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_city,
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCity,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, color: accentColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'قفل شده',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            '🏙️ شهر',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _cities.contains(_selectedCity) ? _selectedCity : null,
            items: _cities.map((city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(
                  city,
                  style: TextStyle(color: textColor),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedCity = newValue!;
              });
            },
            decoration: InputDecoration(
              hintText: 'شهر مورد نظر را انتخاب کنید',
              hintStyle: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.location_city,
                color: accentColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1040)
                : Colors.white,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: accentColor,
            ),
            style: TextStyle(color: textColor),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'لطفاً شهر مورد نظر را انتخاب کنید 🏙️';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCuteTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    required Color textColor,
    required Color cardColor,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: accentColor.withOpacity(0.2), blurRadius: 6),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          validator: validator,
          initialValue: controller.text,
          autovalidateMode: AutovalidateMode.disabled,
          builder: (FormFieldState<String> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: field.hasError
                          ? Colors.pinkAccent
                          : accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: controller,
                    maxLines: maxLines,
                    onChanged: (value) {
                      field.didChange(value);
                    },
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      suffixIcon: Icon(icon, color: accentColor, size: 22),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: maxLines > 1 ? 16 : 12,
                      ),
                    ),
                  ),
                ),
                if (field.hasError) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.pinkAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          field.errorText ?? '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required Color accentColor,
    required Color textColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            '📅 تاریخ',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_down,
                  color: accentColor.withOpacity(0.5),
                ),
                const Spacer(),
                Text(
                  _getPersianDate(_selectedDate),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, color: accentColor, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector({
    required BuildContext context,
    required Color accentColor,
    required Color textColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            '🎭 حالت امروز چطور بود؟',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _moodOptions.length,
            itemBuilder: (context, index) {
              final mood = _moodOptions[index];
              final isSelected = _selectedMood == mood;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withOpacity(0.3)
                        : cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : accentColor.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      mood,
                      style: TextStyle(
                        color: isSelected
                            ? textColor
                            : textColor.withOpacity(0.6),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerWidget({
    required BuildContext context,
    required Color accentColor,
    required Color textColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🖼️ عکس (اختیاری)',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo_library, color: accentColor, size: 22),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  tooltip: 'انتخاب از گالری',
                ),
                IconButton(
                  icon: Icon(Icons.photo_camera, color: accentColor, size: 22),
                  onPressed: () => _pickImage(ImageSource.camera),
                  tooltip: 'گرفتن عکس با دوربین',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImagePickerOptions(context),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isImageLoading
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : (_selectedImage != null || _selectedImageBytes != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        (kIsWeb || _selectedImage == null) &&
                                _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(_selectedImage!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedImage = null;
                              _selectedImageBytes = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'عکس انتخاب شد',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: accentColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildImagePlaceholder(accentColor, textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(Color accentColor, Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 50,
          color: accentColor.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'برای انتخاب عکس ضربه بزن 🌸',
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'دوربین یا گالری',
          style: TextStyle(color: accentColor.withOpacity(0.4), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required BuildContext context,
    required Color accentColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withOpacity(0.8), accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _submitMemory,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isEditing ? '✅ ذخیره تغییرات' : '✨ ثبت خاطره',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isImageLoading = true);
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (xFile != null) {
        if (kIsWeb) {
          final bytes = await xFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
            _isImageLoading = false;
          });
        } else {
          setState(() {
            _selectedImage = File(xFile.path);
            _selectedImageBytes = null;
            _isImageLoading = false;
          });
        }
      } else {
        setState(() => _isImageLoading = false);
      }
    } catch (e) {
      setState(() => _isImageLoading = false);
    }
  }

  void _showImagePickerOptions(BuildContext context) {
    final accentColor = _getAccentColor(context);
    final textColor = _getTextColor(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1040)
          : Colors.white,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'انتخاب عکس',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildImageOption(
                    icon: Icons.photo_camera,
                    label: 'دوربین',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                    color: accentColor,
                    textColor: textColor,
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'گالری',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                    color: accentColor,
                    textColor: textColor,
                  ),
                  if (_selectedImage != null || _selectedImageBytes != null)
                    _buildImageOption(
                      icon: Icons.delete_outline,
                      label: 'حذف',
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedImage = null;
                          _selectedImageBytes = null;
                        });
                      },
                      color: Colors.red,
                      textColor: textColor,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'انصراف',
                  style: TextStyle(color: textColor.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: textColor, fontSize: 14)),
        ],
      ),
    );
  }

  String _getPersianDate(DateTime date) {
    final Jalali jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/'
        '${jalali.month.toString().padLeft(2, '0')}/'
        '${jalali.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final Jalali initialDate = Jalali.fromDateTime(_selectedDate);
    final Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: Jalali(1300, 1, 1),
      lastDate: Jalali(1500, 12, 29),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = picked.toDateTime();
    });
  }

  void _submitMemory() {
    if (_formKey.currentState!.validate()) {
      final memory = Memory(
        title: _titleController.text,
        date: _selectedDate,
        description: _descriptionController.text,
        mood: _selectedMood,
        imagePath: _selectedImage?.path,
        imageBytes: _selectedImageBytes,
        city: _selectedCity,
        attractionName: _selectedAttraction,
      );

      if (widget.onMemorySaved != null) {
        widget.onMemorySaved!(memory);
      }

      Navigator.pop(context, memory);
    }
  }

  void _showHelpDialog() {
    final accentColor = _getAccentColor(context);
    final textColor = _getTextColor(context);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1040)
              : Colors.white,
          title: Row(
            children: [
              const Text('💕', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                'راهنمای ثبت خاطره',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildHelpItem('📍', 'جاذبه مورد نظر را انتخاب کن', textColor),
              _buildHelpItem('🏙️', 'شهر مورد نظر را انتخاب کن', textColor),
              _buildHelpItem('📝', 'عنوانی برای خاطره‌ات انتخاب کن', textColor),
              _buildHelpItem('📅', 'تاریخ رو مشخص کن', textColor),
              _buildHelpItem('🎭', 'حالت رو انتخاب کن', textColor),
              _buildHelpItem('📖', 'هرچیزی که دوست داری بنویس', textColor),
              _buildHelpItem(
                '📸',
                'از دوربین عکس بگیر یا از گالری انتخاب کن',
                textColor,
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'متوجه شدم 💕',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}