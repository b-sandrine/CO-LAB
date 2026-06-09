import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _selectedDegree;
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedInterests = {};

  final _icons = <String, IconData>{
    'Software Engineering': Icons.code,
    'Global Challenges': Icons.public,
    'Entrepreneurial Leadership': Icons.trending_up,
    'Business Management': Icons.work_outline,
  };

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      final notifier = ref.read(authProvider.notifier);
      notifier.onboardingData.degreeProgram = _selectedDegree;
      notifier.onboardingData.skills = _selectedSkills.toList();
      notifier.onboardingData.interests = _selectedInterests.toList();
      notifier.completeOnboarding();
    }
  }

  bool get _canContinue {
    if (_step == 0) return _selectedDegree != null;
    if (_step == 1) return _selectedSkills.isNotEmpty;
    return _selectedInterests.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _step == 0 ? _buildDegreeStep() : _step == 1 ? _buildSkillsStep() : _buildInterestsStep(),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= _step ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDegreeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text("What's your degree program?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('This helps us personalize your experience', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 28),
        ...AppConstants.degreePrograms.map((degree) => _DegreeOption(
          label: degree,
          icon: _icons[degree] ?? Icons.school,
          selected: _selectedDegree == degree,
          onTap: () => setState(() => _selectedDegree = degree),
        )),
      ],
    );
  }

  Widget _buildSkillsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('What skills do you bring?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Select all that apply', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.allSkills.map((skill) {
            final selected = _selectedSkills.contains(skill);
            return _ChoiceChip(
              label: skill,
              selected: selected,
              onTap: () => setState(() => selected ? _selectedSkills.remove(skill) : _selectedSkills.add(skill)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('What are you interested in?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Help us recommend the right opportunities', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.allInterests.map((interest) {
            final selected = _selectedInterests.contains(interest);
            return _ChoiceChip(
              label: interest,
              selected: selected,
              onTap: () => setState(() => selected ? _selectedInterests.remove(interest) : _selectedInterests.add(interest)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: AnimatedOpacity(
        opacity: _canContinue ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: _canContinue ? _next : null,
          child: Text(_step == 2 ? 'Get Started' : 'Continue'),
        ),
      ),
    );
  }
}

class _DegreeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DegreeOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.chipBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.border, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.primary : AppColors.textPrimary)),
      ),
    );
  }
}
