import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;


class BottomSheetThemeListContainer extends StatefulWidget {
  BottomSheetThemeListContainer({
    Key? key,
  }) : super(key: key);

  @override
  State<BottomSheetThemeListContainer> createState() =>
      _BottomSheetThemeListContainerState();
}

class _BottomSheetThemeListContainerState
    extends State<BottomSheetThemeListContainer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // System and Dark options are disabled for now — only Light is shown.
    List lblThemeDisplayNames = [
      themeDisplayNamesLightLabel,
    ];

    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getSizedBox(
              height: 20,
            ),
            Center(
              child: CustomTextLabel(
                jsonKey: changeThemeLabel,
                softWrap: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium!.merge(
                      TextStyle(
                        letterSpacing: 0.5,
                        color: ColorsRes.mainTextColor,
                      ),
                    ),
              ),
            ),
            getSizedBox(
              height: 10,
            ),
            ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: List.generate(
                lblThemeDisplayNames.length,
                (index) {
                  app_theme.ThemeMode mode = app_theme.ThemeMode.light;

                  return GestureDetector(
                    onTap: () {
                      themeProvider.setThemeMode(mode);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: Constant.size10),
                            child: CustomTextLabel(
                              jsonKey: lblThemeDisplayNames[index],
                            ),
                          ),
                        ),
                        CustomRadio(
                          inactiveColor: ColorsRes.mainTextColor,
                          activeColor: ColorsRes.appColor,
                          value: mode,
                          groupValue: themeProvider.themeMode,
                          onChanged: (value) {
                            themeProvider.setThemeMode(mode);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: 10,
                end: 10,
                bottom: 25,
              ),
              child: gradientBtnWidget(
                context,
                10,
                callback: () {
                  Navigator.pop(context);
                },
                otherWidgets: CustomTextLabel(
                  jsonKey: changeLabel,
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleMedium!.merge(
                        TextStyle(
                          color: ColorsRes.appColorWhite,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
