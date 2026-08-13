import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

class OrdersHeader extends StatelessWidget {
  final VoidCallback? onHelp;
  const OrdersHeader({Key? key, this.onHelp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9AC444), Colors.white],
              stops: [0, 0.73],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Orders title
                  Expanded(
                    child: Text(
                      getTranslatedValue(context, ordersLabel),
                      style: GoogleFonts.inter(
                        color: Color(0xFF171717),
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ),
                  // "Help us" button
                  Material(
                    color: Color(0xFFF8FFEB),
                    shape: StadiumBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: onHelp,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              getTranslatedValue(context, helpUsLabel),
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                height: 1.02,
                                letterSpacing: -0.55,
                              ),
                            ),
                            SizedBox(width: 7),
                            Icon(Icons.headset_mic_rounded,
                                size: 20, color: Color(0xFF22332C)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
