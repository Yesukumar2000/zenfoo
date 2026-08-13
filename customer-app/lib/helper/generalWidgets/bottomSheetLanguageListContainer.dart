import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class BottomSheetLanguageListContainer extends StatefulWidget {
  const BottomSheetLanguageListContainer({Key? key}) : super(key: key);

  @override
  State<BottomSheetLanguageListContainer> createState() =>
      _BottomSheetLanguageListContainerState();
}

class _BottomSheetLanguageListContainerState
    extends State<BottomSheetLanguageListContainer> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      context.read<LanguageProvider>().getAvailableLanguageList(
          params: {ApiAndParams.system_type: "1"}, context: context);

      context.read<LanguageProvider>().setSelectedLanguage(
          Constant.session.getData(SessionManager.keySelectedLanguageId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: colorScheme.iconPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        getTranslatedValue(context, changeLanguageLabel),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Language list
              if (languageProvider.languageState == LanguageState.loaded ||
                  languageProvider.languageState == LanguageState.updating)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: List.generate(
                      languageProvider.languageList?.data?.length ?? 0,
                      (index) {
                        final lang = languageProvider.languageList!.data![index];
                        final isSelected = languageProvider.selectedLanguage ==
                            lang.id.toString();
                        final isDefault = index == 0; // Assuming first is default

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            languageProvider.setSelectedLanguage(
                              lang.id.toString(),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : colorScheme.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.border,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.displayName == 'null'
                                            ? lang.name ?? ''
                                            : lang.displayName ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.textPrimary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      if (lang.name != null && lang.displayName != 'null')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            lang.name ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.textSecondary,
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      "Default",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.textSecondary,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.border,
                                      width: 2,
                                    ),
                                    color: colorScheme.surface,
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (languageProvider.languageState == LanguageState.loading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: List.generate(
                      4,
                      (index) => CustomShimmer(
                        height: 70,
                        width: double.maxFinite,
                        margin: const EdgeInsets.only(bottom: 12),
                        borderRadius: 20,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Update button
              if (languageProvider.languageState == LanguageState.loaded ||
                  languageProvider.languageState == LanguageState.updating)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: gradientBtnWidget(
                      context,
                      26,
                      height: 52,
                      callback: () {
                        if (languageProvider.languageState !=
                            LanguageState.updating) {
                          Map<String, String> params = {
                            ApiAndParams.system_type: "1",
                            ApiAndParams.id:
                                languageProvider.selectedLanguage.toString(),
                          };
                          languageProvider
                              .getLanguageDataProvider(
                            params: params,
                            context: context,
                          )
                              .then((_) {
                            Navigator.pop(context);
                          });
                        }
                      },
                      otherWidgets: languageProvider.languageState ==
                              LanguageState.updating
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                getTranslatedValue(context, changeLabel),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

              if (languageProvider.languageState == LanguageState.loading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CustomShimmer(
                    height: 52,
                    width: double.maxFinite,
                    borderRadius: 26,
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// import 'package:project/helper/utils/generalImports.dart';


// class BottomSheetLanguageListContainer extends StatefulWidget {
//   BottomSheetLanguageListContainer({
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<BottomSheetLanguageListContainer> createState() =>
//       _BottomSheetLanguageListContainerState();
// }

// class _BottomSheetLanguageListContainerState
//     extends State<BottomSheetLanguageListContainer> {
//   @override
//   void initState() {
//     Future.delayed(Duration.zero, () async {
//       context.read<LanguageProvider>().getAvailableLanguageList(
//           params: {ApiAndParams.system_type: "1"}, context: context);

//       context.read<LanguageProvider>().setSelectedLanguage(
//           Constant.session.getData(SessionManager.keySelectedLanguageId));
//     });
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<LanguageProvider>(
//       builder: (context, languageProvider, _) {
//         return Column(
//           children: [
//             getSizedBox(
//               height: 20,
//             ),
//             Center(
//               child: CustomTextLabel(
//                 jsonKey: changeLanguageLabel,
//                 softWrap: true,
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context).textTheme.titleMedium!.merge(
//                       TextStyle(
//                         letterSpacing: 0.5,
//                         color: ColorsRes.mainTextColor,
//                       ),
//                     ),
//               ),
//             ),
//             getSizedBox(
//               height: 10,
//             ),
//             if (languageProvider.languageState == LanguageState.loaded ||
//                 languageProvider.languageState == LanguageState.updating)
//               ListView(
//                 shrinkWrap: true,
//                 children: List.generate(
//                   languageProvider.languageList?.data?.length ?? 0,
//                   (index) {
//                     return GestureDetector(
//                       onTap: () {
//                         languageProvider.setSelectedLanguage(
//                           languageProvider.languageList!.data![index].id
//                               .toString(),
//                         );
//                       },
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Padding(
//                               padding: EdgeInsetsDirectional.only(
//                                   start: Constant.size10),
//                               child: CustomTextLabel(
//                                 text:
//                                     "${languageProvider.languageList!.data![index].displayName == 'null' ? languageProvider.languageList!.data![index].name : languageProvider.languageList!.data![index].displayName} - ${languageProvider.languageList!.data![index].code?.toUpperCase()}",
//                               ),
//                             ),
//                           ),
//                           CustomRadio(
//                             inactiveColor: ColorsRes.mainTextColor,
//                             activeColor: ColorsRes.appColor,
//                             value: languageProvider.selectedLanguage,
//                             groupValue: languageProvider
//                                 .languageList!.data![index].id
//                                 .toString(),
//                             onChanged: (value) {
//                               languageProvider.setSelectedLanguage(
//                                 languageProvider.languageList!.data![index].id
//                                     .toString(),
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             getSizedBox(
//               height: 10,
//             ),
//             if (languageProvider.languageState == LanguageState.loading)
//               Column(
//                 children: List.generate(
//                   8,
//                   (index) {
//                     return CustomShimmer(
//                       height: 26,
//                       width: double.maxFinite,
//                       margin: EdgeInsetsDirectional.all(
//                         10,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             if (languageProvider.languageState == LanguageState.loaded ||
//                 languageProvider.languageState == LanguageState.updating)
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: Constant.size10,
//                 ),
//                 child: gradientBtnWidget(
//                   context,
//                   10,
//                   callback: () {
//                     Map<String, String> params = {};
//                     params[ApiAndParams.system_type] = "1";
//                     params[ApiAndParams.id] =
//                         languageProvider.selectedLanguage.toString();
//                     languageProvider
//                         .getLanguageDataProvider(
//                       params: params,
//                       context: context,
//                     )
//                         .then((value) {
//                       Navigator.pop(context);
//                     });
//                   },
//                   otherWidgets: (languageProvider.languageState ==
//                           LanguageState.updating)
//                       ? CircularProgressIndicator(
//                           color: ColorsRes.appColorWhite)
//                       : CustomTextLabel(
//                           jsonKey: changeLabel,
//                           softWrap: true,
//                           style: Theme.of(context).textTheme.titleMedium!.merge(
//                                 TextStyle(
//                                   color: ColorsRes.appColorWhite,
//                                   letterSpacing: 0.5,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                         ),
//                 ),
//               ),
//             if (languageProvider.languageState == LanguageState.loading)
//               Padding(
//                 padding: EdgeInsetsDirectional.only(
//                   top: Constant.size10,
//                   start: Constant.size10,
//                   end: Constant.size10,
//                 ),
//                 child: CustomShimmer(
//                   height: 55,
//                   width: double.maxFinite,
//                 ),
//               ),
//             getSizedBox(
//               height: 20,
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
