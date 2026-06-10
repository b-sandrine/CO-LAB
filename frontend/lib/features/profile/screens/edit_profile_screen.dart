import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _degreeCtrl;
  List<String> _skills = [];
  List<String> _interests = [];

  final _skillInput = TextEditingController();
  final _interestInput = TextEditingController();

  static const _degrees = [
    'Software Engineering',
    'Entrepreneurial Leadership',
    'Global Challenges',
    'Business Management',
    'Data Science',
    'Computer Science',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _degreeCtrl = TextEditingController(text: user?.degreeProgram ?? '');
    _skills = List.from(user?.skills ?? []);
    _interests = List.from(user?.interests ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _degreeCtrl.dispose();
    _skillInput.dispose();
    _interestInput.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(profileEditProvider.notifier).updateProfile(
          name: _nameCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          degreeProgram: _degreeCtrl.text.trim(),
          skills: _skills,
          interests: _interests,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(profileEditProvider);
    final isLoading = editState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _save,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Full Name', _nameCtrl, hint: 'Your full name'),
            const SizedBox(height: 16),
            _field('Bio', _bioCtrl, hint: 'Tell others about yourself', maxLines: 3),
            const SizedBox(height: 16),
            _degreeField(),
            const SizedBox(height: 24),
            _chipSection(
              title: 'Skills',
              chips: _skills,
              controller: _skillInput,
              hint: 'e.g. Flutter, Python...',
              onAdd: (v) => setState(() => _skills.add(v)),
              onRemove: (i) => setState(() => _skills.removeAt(i)),
            ),
            const SizedBox(height: 24),
            _chipSection(
              title: 'Interests',
              chips: _interests,
              controller: _interestInput,
              hint: 'e.g. Hackathons, Research...',
              onAdd: (v) => setState(() => _interests.add(v)),
              onRemove: (i) => setState(() => _interests.removeAt(i)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _degreeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Degree Program',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _degrees.contains(_degreeCtrl.text) ? _degreeCtrl.text : null,
            hint: const Text('Select your degree'),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            ),
            items: _degrees
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _degreeCtrl.text = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _chipSection({
    required String title,
    required List<String> chips,
    required TextEditingController controller,
    required String hint,
    required void Function(String) onAdd,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(chips.length, (i) {
            return Chip(
              label: Text(chips[i]),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => onRemove(i),
              backgroundColor: AppColors.chipBackground,
              labelStyle: const TextStyle(fontSize: 13),
              side: BorderSide.none,
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.border)),
                ),
                onSubmitted: (v) {
                  final trimmed = v.trim();
                  if (trimmed.isNotEmpty && !chips.contains(trimmed)) {
                    onAdd(trimmed);
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isNotEmpty && !chips.contains(trimmed)) {
                  onAdd(trimmed);
                  controller.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}
