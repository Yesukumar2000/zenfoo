import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stage 2: Category Groups Management Screen
/// Groups multiple categories together with name and image
class CategoryGroupsScreen extends StatefulWidget {
  const CategoryGroupsScreen({Key? key}) : super(key: key);

  @override
  State<CategoryGroupsScreen> createState() => _CategoryGroupsScreenState();
}

class _CategoryGroupsScreenState extends State<CategoryGroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB9E990), Color(0xFFFFFFFF)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 24),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 22,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Stage 2: Category Groups",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            color: Colors.black,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                        Text(
                          "Group multiple categories",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        // TODO: Navigate to Add Group screen
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Add",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      size: 64,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No groups yet",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Create groups by selecting multiple categories and giving them a name",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
