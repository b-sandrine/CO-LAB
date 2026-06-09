import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class CreateOpportunityScreen extends StatefulWidget {
  const CreateOpportunityScreen({super.key});

  @override
  State<CreateOpportunityScreen> createState() => _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _selectedType = 'Hackathon';
  final List<String> _skills = ['UI Design', 'Flutter'];
  bool _openToAll = true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _addSkill() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _SkillPickerSheet(
        existing: _skills,
        onAdd: (s) => setState(() { if (!_skills.contains(s)) _skills.add(s); }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Create Opportunity'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoleBanner(),
            const SizedBox(height: 20),
            _buildLabel('Title'),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Give your opportunity a clear title')),
            const SizedBox(height: 20),
            _buildLabel('Type'),
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildLabel('Description'),
            TextField(
              controller: _descCtrl,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(hintText: "What's this opportunity about?"),
            ),
            const SizedBox(height: 20),
            _buildLabel('Skills Needed'),
            _buildSkillsRow(),
            const SizedBox(height: 20),
            _buildLabel('Date & Time'),
            TextField(
              readOnly: true,
              onTap: () async {
                await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              },
              decoration: const InputDecoration(
                hintText: 'Select date and time',
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Location'),
            TextField(controller: _locationCtrl, decoration: const InputDecoration(hintText: 'Where will this take place?', prefixIcon: Icon(Icons.location_on_outlined, size: 18))),
            const SizedBox(height: 20),
            _buildLabel('Who can join?'),
            _buildJoinToggle(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opportunity posted!')));
                context.pop();
              },
              child: const Text('Post Opportunity'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('Posting as: Club Leader', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF92400E))),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTypeSelector() {
    final types = ['Hackathon', 'Peer Study', 'Club Project'];
    return Row(
      children: types.map((t) {
        final sel = t == _selectedType;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.chipBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppColors.textPrimary)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkillsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._skills.map((s) => _SkillChip(
          label: s,
          onRemove: () => setState(() => _skills.remove(s)),
        )),
        GestureDetector(
          onTap: _addSkill,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.add, size: 16, color: Colors.white), SizedBox(width: 4), Text('Add Skill', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white))],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinToggle() {
    return Row(
      children: [
        _JoinOption(label: 'Open to all', selected: _openToAll, onTap: () => setState(() => _openToAll = true)),
        const SizedBox(width: 10),
        _JoinOption(label: 'By approval', selected: !_openToAll, onTap: () => setState(() => _openToAll = false)),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _SkillChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.teal)),
          const SizedBox(width: 6),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 14, color: AppColors.teal)),
        ],
      ),
    );
  }
}

class _JoinOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _JoinOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.chipBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}

class _SkillPickerSheet extends StatelessWidget {
  final List<String> existing;
  final ValueChanged<String> onAdd;
  const _SkillPickerSheet({required this.existing, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Skill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.allSkills.where((s) => !existing.contains(s)).map((s) => GestureDetector(
              onTap: () { onAdd(s); Navigator.pop(context); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Text(s, style: const TextStyle(fontSize: 13)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
