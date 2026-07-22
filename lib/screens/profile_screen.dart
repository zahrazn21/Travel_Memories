import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_memories/providers/theme_provider.dart';
import 'package:travel_memories/services/auth_service.dart';
import 'package:travel_memories/screens/login_screen.dart';
import 'package:travel_memories/themes/app_background_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user ?? _getDefaultUser();
        _loading = false;
        _updateControllers();
      });
    }
  }

  Map<String, dynamic> _getDefaultUser() {
    return {
      'name': 'کاربر مهمان',
      'email': 'guest@example.com',
      'phone': '۰۹۱۲۳۴۵۶۷۸۹',
      'location': 'تهران، ایران',
      'birthDate': '۱۳۷۰/۰۱/۰۱',
    };
  }

  void _updateControllers() {
    _nameController.text = _user?['name'] as String? ?? '';
    _phoneController.text = _user?['phone'] as String? ?? '';
    _locationController.text = _user?['location'] as String? ?? '';
    _birthDateController.text = _user?['birthDate'] as String? ?? '';
  }

  void _saveProfile() {
    setState(() {
      _user = {
        ...?_user,
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'کاربر عزیز',
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : '۰۹۱۲۳۴۵۶۷۸۹',
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : 'تهران، ایران',
        'birthDate': _birthDateController.text.trim().isNotEmpty
            ? _birthDateController.text.trim()
            : '۱۳۷۰/۰۱/۰۱',
      };
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ اطلاعات پروفایل با موفقیت به‌روزرسانی شد'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('خروج از حساب'),
          content: const Text('مطمئنی می‌خوای خارج بشی؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'خروج',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppBackgroundTheme>()!;
    final isDark = theme.brightness == Brightness.dark;
    final isPink =
        appTheme.gradientColors.first == Color.fromARGB(255, 255, 186, 209);

    final currentTheme = context.watch<ThemeProvider>().currentTheme;

    final primaryColor = isPink
        ? Colors.pink
        : (isDark ? Colors.purple : Colors.blue);
    final textColor = isPink
        ? const Color(0xFF4A1942)
        : (isDark ? Colors.white : Colors.black87);

    final displayName =
        _user?['name'] as String? ?? 'کاربر عزیز';
    final email =
        _user?['email'] as String? ?? 'user@example.com';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'ویرایش پروفایل' : 'پروفایل',
            style: TextStyle(
              color: isPink
                  ? const Color(0xFF4A1942)
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
          centerTitle: true,
          backgroundColor: isPink
              ? const Color(0xFFFFF0F5)
              : (isDark ? const Color(0xFF0A0E27) : Colors.white),
          foregroundColor: isPink
              ? const Color(0xFF4A1942)
              : (isDark ? Colors.white : Colors.black),
          elevation: 0,
          actions: [
            // دکمه ویرایش
            if (!_isEditing)
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: isPink
                      ? const Color(0xFF4A1942)
                      : (isDark ? Colors.white : Colors.black),
                ),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _updateControllers();
                  });
                },
              ),
            PopupMenuButton<String>(
              onSelected: (value) =>
                  context.read<ThemeProvider>().setTheme(value),
              icon: Icon(
                Icons.palette_outlined,
                color: isPink
                    ? const Color(0xFF4A1942)
                    : (isDark ? Colors.white : Colors.black),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'dark',
                  child: SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Icon(Icons.nightlight_round,
                            color: Colors.deepPurple, size: 20),
                        SizedBox(width: 10),
                        Text('تاریک'),
                      ],
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'blue',
                  child: SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Icon(Icons.water_drop,
                            color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Text('آبی'),
                      ],
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'pink',
                  child: SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Icon(Icons.favorite,
                            color: Colors.pink, size: 20),
                        SizedBox(width: 10),
                        Text('صورتی'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: isPink
                    ? const Color(0xFF4A1942)
                    : (isDark ? Colors.white : Colors.black),
              ),
              onPressed: () {},
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: appTheme.gradientColors,
            ),
          ),
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                      color: primaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // آواتار با حرف اول اسم - بزرگتر
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: isPink
                                  ? Colors.pink.shade100
                                  : (isDark
                                      ? Colors.purple.shade900
                                      : Colors.blue.shade100),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: isPink
                                      ? Colors.pink.shade700
                                      : (isDark
                                          ? Colors.purple.shade200
                                          : Colors.blue),
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isPink
                                    ? Colors.pink.shade50
                                    : (isDark
                                        ? Colors.grey.shade800
                                        : Colors.white),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(Icons.edit,
                                  size: 22, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (!_isEditing) ...[
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: appTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 16,
                            color: appTheme.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 35),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isPink
                                ? Colors.white.withOpacity(0.6)
                                : (isDark
                                    ? const Color.fromARGB(255, 33, 33, 33).withOpacity(0.6)
                                    : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPink
                                  ? Colors.pink.withOpacity(0.2)
                                  : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade200),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildProfileItem(
                                  Icons.phone,
                                  _user?['phone'] as String? ??
                                      'شماره تلفن',
                                  primaryColor: primaryColor,
                                  textColor: textColor),
                              _buildDivider(
                                  isDark: isDark, isPink: isPink),
                              _buildProfileItem(
                                  Icons.location_on,
                                  _user?['location'] as String? ??
                                      'موقعیت مکانی',
                                  primaryColor: primaryColor,
                                  textColor: textColor),
                              _buildDivider(
                                  isDark: isDark, isPink: isPink),
                              _buildProfileItem(
                                  Icons.cake,
                                  _user?['birthDate'] as String? ??
                                      'تاریخ تولد',
                                  primaryColor: primaryColor,
                                  textColor: textColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ] else ...[
                        const SizedBox(height: 10),
                        _buildEditField(
                          controller: _nameController,
                          label: 'نام و نام خانوادگی',
                          icon: Icons.person,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildEditField(
                          controller: _phoneController,
                          label: 'شماره تلفن',
                          icon: Icons.phone,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildEditField(
                          controller: _locationController,
                          label: 'موقعیت مکانی',
                          icon: Icons.location_on,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildEditField(
                          controller: _birthDateController,
                          label: 'تاریخ تولد',
                          icon: Icons.cake,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 30),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _isEditing = false);
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('انصراف'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saveProfile,
                                icon: const Icon(Icons.save),
                                label: const Text('ذخیره اطلاعات'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],

                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //       horizontal: 20, vertical: 10),
                      //   decoration: BoxDecoration(
                      //     color: isPink
                      //         ? Colors.pink.shade50.withOpacity(0.6)
                      //         : (isDark
                      //             ? Colors.grey.shade800.withOpacity(0.4)
                      //             : Colors.grey.shade100),
                      //     borderRadius: BorderRadius.circular(25),
                      //     border: Border.all(
                      //       color: isPink
                      //           ? Colors.pink.withOpacity(0.3)
                      //           : (isDark
                      //               ? Colors.grey.shade700
                      //               : Colors.grey.shade300),
                      //       width: 1.5,
                      //     ),
                      //   ),
                      //   child: Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //     children: [
                      //       Icon(
                      //         currentTheme == 'pink'
                      //             ? Icons.favorite
                      //             : (currentTheme == 'dark'
                      //                 ? Icons.nightlight_round
                      //                 : Icons.water_drop),
                      //         color: currentTheme == 'pink'
                      //             ? Colors.pink
                      //             : (currentTheme == 'dark'
                      //                 ? Colors.deepPurple
                      //                 : Colors.blue),
                      //         size: 20,
                      //       ),
                      //       const SizedBox(width: 10),
                      //       Text(
                      //         currentTheme == 'pink'
                      //             ? 'تم صورتی'
                      //             : (currentTheme == 'dark'
                      //                 ? 'تم تاریک'
                      //                 : 'تم آبی'),
                      //         style: TextStyle(
                      //           color: appTheme.textColor,
                      //           fontSize: 14,
                      //           fontWeight: FontWeight.w600,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, size: 22),
                          label: const Text(
                            'خروج از حساب',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.travelTextColor[1],
                            foregroundColor:Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: primaryColor, size: 24),
        filled: true,
        fillColor: isDark ? const Color.fromARGB(166, 29, 23, 71) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String value, {
    required Color primaryColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 26),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider({required bool isDark, required bool isPink}) {
    return Divider(
      height: 1,
      thickness: 1.5,
      indent: 20,
      endIndent: 20,
      color: isPink
          ? Colors.pink.withOpacity(0.15)
          : (isDark ? const Color.fromARGB(255, 210, 203, 203) : Colors.grey.shade200),
    );
  }
}