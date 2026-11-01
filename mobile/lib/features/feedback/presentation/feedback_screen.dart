import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _feedbackType = 'SARAN'; // 'SARAN', 'KESAN', 'KELUHAN'
  int _rating = 5;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
          content: Text('Please write your feedback message before submitting.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _messageController.clear();
        _rating = 5;
        _feedbackType = 'SARAN';
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.forestGreen),
              SizedBox(width: 10),
              Text('Terima Kasih!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Saran & kesan Anda sangat berharga bagi peningkatan cita rasa dan layanan Bun Atelier.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('TUTUP'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'SARAN & KESAN',
          style: textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We Love\nYour Feedback.',
                style: textTheme.displayLarge?.copyWith(
                  height: 1.1,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ceritakan pengalaman Anda menikmati burger Bun Atelier atau saran pengembangan sistem kami.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 28),

              // Category Selector
              Text(
                'JENIS MASUKAN',
                style: textTheme.labelLarge?.copyWith(fontSize: 11, letterSpacing: 1.1, color: AppColors.forestGreen),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTypeChip('SARAN', 'Saran'),
                  const SizedBox(width: 10),
                  _buildTypeChip('KESAN', 'Kesan'),
                  const SizedBox(width: 10),
                  _buildTypeChip('KELUHAN', 'Keluhan'),
                ],
              ),
              const SizedBox(height: 24),

              // Star Rating
              Text(
                'RATING KEPUASAN',
                style: textTheme.labelLarge?.copyWith(fontSize: 11, letterSpacing: 1.1, color: AppColors.forestGreen),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(
                        starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: starValue <= _rating ? const Color(0xFFF39C12) : AppColors.mutedText,
                        size: 34,
                      ),
                      onPressed: () => setState(() => _rating = starValue),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Message TextArea
              Text(
                'PESAN / ULASAN',
                style: textTheme.labelLarge?.copyWith(fontSize: 11, letterSpacing: 1.1, color: AppColors.forestGreen),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan saran, kritik membangun, atau kesan burger yang telah Anda nikmati...',
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  icon: const Icon(Icons.send_rounded),
                  label: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                        )
                      : const Text('KIRIM MASUKAN'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String id, String label) {
    final isSelected = _feedbackType == id;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _feedbackType = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.forestGreen : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.forestGreen : AppColors.borderLight,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppColors.white : AppColors.espresso,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
