import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/opportunity_model.dart';
import '../providers/feed_provider.dart';
import '../../auth/providers/auth_provider.dart';

class CreateOpportunityScreen extends ConsumerStatefulWidget {
  const CreateOpportunityScreen({super.key});

  @override
  ConsumerState<CreateOpportunityScreen> createState() =>
      _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState
    extends ConsumerState<CreateOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _selectedType = 'Hackathon';
  final List<String> _skills = ['UI Design', 'Flutter'];
  bool _openToAll = true;
  DateTime? _eventDate;
  bool _isPosting = false;

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
        onAdd: (s) => setState(() {
          if (!_skills.contains(s)) _skills.add(s);
        }),
      ),
    );
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final actions = ref.read(feedActionsProvider);
    if (actions == null) return;

    setState(() => _isPosting = true);
    try {
      final opp = OpportunityModel(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _selectedType,
        postedBy: user.firstName,
        postedByInitial: user.initials.isNotEmpty ? user.initials[0] : '?',
        postedById: user.id,
        eventDate: _eventDate,
        skillTags: List<String>.from(_skills),
        joinLabel: _openToAll ? 'Request to Join' : 'Apply',
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        openToAll: _openToAll,
      );
      await actions.createOpportunity(opp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity posted!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Create Opportunity'),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoleBanner(user?.role ?? 'Student'),
              const SizedBox(height: 20),
              _buildLabel('Title'),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    hintText: 'Give your opportunity a clear title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Type'),
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildLabel('Description'),
              TextFormField(
                controller: _descCtrl,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                    hintText: "What's this opportunity about?"),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Skills Needed'),
              _buildSkillsRow(),
              const SizedBox(height: 20),
              _buildLabel('Date & Time'),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _eventDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        _eventDate == null
                            ? 'Select date and time'
                            : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
                        style: TextStyle(
                            color: _eventDate == null
                                ? AppColors.textHint
                                : AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Location'),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  hintText: 'Where will this take place?',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Who can join?'),
              _buildJoinToggle(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isPosting ? null : _post,
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Post Opportunity'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBanner(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(
            'Posting as: ${role[0].toUpperCase()}${role.substring(1)}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTypeSelector() {
    final types = AppConstants.opportunityTypes.take(3).toList();
    return Wrap(
      spacing: 8,
      children: types.map((t) {
        final sel = t == _selectedType;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = t),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.chipBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(t,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: sel ? Colors.white : AppColors.textPrimary)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text('Add Skill',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinToggle() {
    return Row(
      children: [
        _JoinOption(
            label: 'Open to all',
            selected: _openToAll,
            onTap: () => setState(() => _openToAll = true)),
        const SizedBox(width: 10),
        _JoinOption(
            label: 'By approval',
            selected: !_openToAll,
            onTap: () => setState(() => _openToAll = false)),
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
      decoration: BoxDecoration(
          color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.teal)),
          const SizedBox(width: 6),
          GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 14, color: AppColors.teal)),
        ],
      ),
    );
  }
}

class _JoinOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _JoinOption(
      {required this.label, required this.selected, required this.onTap});

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
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textPrimary)),
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
    final available =
        AppConstants.allSkills.where((s) => !existing.contains(s)).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Skill',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (available.isEmpty)
            const Text('All skills already added.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available
                  .map((s) => GestureDetector(
                        onTap: () {
                          onAdd(s);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: AppColors.chipBackground,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: AppColors.border)),
                          child: Text(s,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
