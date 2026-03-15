import 'package:google_fonts/google_fonts.dart';
import 'package:qwok/core/config/app_export.dart';

class RecommendationChipsWidget extends StatelessWidget {
  const RecommendationChipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildChip("App Development", true),
          SizedBox(width: 8.w),
          _buildChip("Web Development", false),
          SizedBox(width: 8.w),
          _buildChip("Saas", false),
          SizedBox(width: 8.w),
          _buildChip("Video Editing", false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: selected
            ? const Color.fromARGB(255, 63, 72, 248) // Light blue for selected
            : const Color(0xFF000FE2).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.h), // Matching search bar radius
        border: Border.all(
          color: selected
              ? const Color(0xFF7C83FD).withValues(alpha: 0.2)
              : const Color(0xFF000FE2).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13.fSize,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected
              ? Colors.white
              : const Color(0xFF000FE2).withValues(alpha: 0.8),
        ),
      ),
    );
  }
}



