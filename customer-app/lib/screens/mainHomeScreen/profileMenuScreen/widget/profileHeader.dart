import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = Constant.session.isUserLoggedIn();
    final String name = isLoggedIn
        ? (Constant.session.getData(SessionManager.keyUserName).isNotEmpty ??
                false
            ? Constant.session.getData(SessionManager.keyUserName)
            : "Guest")
        : "Guest";
    final String phone = isLoggedIn
        ? (Constant.session.getData(SessionManager.keyPhone) ?? "")
        : "";
    final String imageUrl = isLoggedIn
        ? (Constant.session.getData(SessionManager.keyUserImage) ?? "")
        : "";

    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Center(
          child: GradientBorderCard(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            borderRadius: 20,
            borderWidth: 1.4,
            gradient: colorScheme.heroGradient,
            borderGradient: colorScheme.borderGradientStrong,
            shadows: colorScheme.cardShadow,
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Avatar — gradient ring drawn as an inset outer circle
            Container(
              width: 79,
              height: 79,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: colorScheme.avatarRingGradient,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.cardBackground,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: colorScheme.shimmerBase,
                            highlightColor: colorScheme.shimmerHighlight,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholder(name, colorScheme),
                        )
                      : _buildPlaceholder(name, colorScheme),
                ),
              ),
            ),
            SizedBox(width: 15),
            // Info + Edit
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name/phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (phone.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            phone,
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  // Edit Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: colorScheme.buttonGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final result = await Navigator.pushNamed(
                          context,
                          editProfileScreen,
                          arguments: [
                            isLoggedIn ? "header" : "register_header",
                            null
                          ],
                        );

                        // Refresh the header if profile was updated
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Edit',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(String name, dynamic colorScheme) {
    // Get initials from name
    String initials = _getInitials(name);

    return Container(
      decoration: BoxDecoration(
        gradient: colorScheme.heroGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            color: colorScheme.primaryDark,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'G';

    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0])
          .toUpperCase();
    }
  }
}

// class ProfileHeader extends StatelessWidget {
//   const ProfileHeader({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Theme.of(context).cardColor,
//       padding: const EdgeInsets.all(5),
//       margin: EdgeInsetsDirectional.only(top: 10),
//       child: Stack(
//         children: [
//           Row(
//             children: [
//               Padding(
//                 padding: EdgeInsetsDirectional.only(
//                     start: 10, top: 10, bottom: 10, end: 20),
//                 child: CircleAvatar(
//                   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//                   maxRadius: 40,
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(50),
//                     child: Constant.session.isUserLoggedIn()
//                         ? Consumer<UserProfileProvider>(
//                             builder: (context, value, child) {
//                               return setNetworkImg(
//                                 height: 75,
//                                 width: 75,
//                                 boxFit: BoxFit.cover,
//                                 image: Constant.session.getData(
//                                   SessionManager.keyUserImage,
//                                 ),
//                               );
//                             },
//                           )
//                         : defaultImg(
//                             height: 75,
//                             width: 75,
//                             image: AppAssets.defaultUserIcon,
//                           ),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Consumer2<UserProfileProvider, LanguageProvider>(builder: (context, userProfileProvide, languageProvider, child) {
//                             return CustomTextLabel(
//                               text: Constant.session.isUserLoggedIn()
//                                   ? userProfileProvide.getUserDetailBySessionKey(
//                                       isBool: false,
//                                       key: SessionManager.keyUserName,
//                                     )
//                                   : getTranslatedValue(
//                                       context,
//                                       welcomeLabel,
//                                     ),
//                               style: TextStyle(color: ColorsRes.mainTextColor, fontWeight: FontWeight.bold, fontSize: 15),
//                             );
//                           }),
//                         ),
//                         if (Constant.session.isUserLoggedIn())
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pushNamed(
//                                 context,
//                                 editProfileScreen,
//                                 arguments: [
//                                   Constant.session.isUserLoggedIn()
//                                       ? "header"
//                                       : "register_header",
//                                   null
//                                 ],
//                               );
//                             },
//                             child: Padding(
//                               padding: EdgeInsetsDirectional.only(end: 10),
//                               child: CustomTextLabel(
//                                 jsonKey: editLabel,
//                                 style: TextStyle(
//                                   color: ColorsRes.appColor,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     if (Constant.session.isUserLoggedIn())
//                       getSizedBox(height: 5),
//                     if (Constant.session.isUserLoggedIn())
//                       CustomTextLabel(
//                         jsonKey: Constant.session.getData(
//                           SessionManager.keyEmail,
//                         ),
//                         style: TextStyle(
//                           color: ColorsRes.mainTextColor,
//                           fontSize: 13,
//                         ),
//                       ),
//                     if (Constant.session.isUserLoggedIn())
//                       getSizedBox(height: 5),
//                     if (Constant.session.isUserLoggedIn())
//                       CustomTextLabel(
//                         jsonKey: Constant.session.isUserLoggedIn()
//                             ? Constant.session.getData(
//                                 SessionManager.keyPhone,
//                               )
//                             : loginLabel,
//                         style: TextStyle(
//                           color: ColorsRes.mainTextColor,
//                           fontSize: 13,
//                         ),
//                       ),
//                     if (!Constant.session.isUserLoggedIn())
//                       getSizedBox(height: 10),
//                     if (!Constant.session.isUserLoggedIn())
//                       GestureDetector(
//                         onTap: () {
//                           Navigator.pushNamed(
//                             context,
//                             loginAccountScreen,
//                             arguments: "register_header",//"header",
//                           );
//                         },
//                         child: Container(
//                           decoration: BoxDecoration(
//                               color: ColorsRes.appColorRed,
//                               borderRadius: BorderRadius.circular(5)),
//                           child: Padding(
//                             padding: EdgeInsetsDirectional.only(
//                               start: 15,
//                               end: 15,
//                               top: 5,
//                               bottom: 5,
//                             ),
//                             child: CustomTextLabel(
//                               jsonKey: loginLabel,
//                             ),
//                           ),
//                         ),
//                       )
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
