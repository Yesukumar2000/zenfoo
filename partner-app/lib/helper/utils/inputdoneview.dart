import 'package:flutter/cupertino.dart';
import 'package:project/helper/utils/generalImports.dart';

class InputDoneView extends StatelessWidget {
  const InputDoneView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkTheme = Constant.session.getBoolData(SessionManager.isDarkTheme);
    return Container(
        width: double.infinity,
        color: isDarkTheme?Color(0xff2C2C2E):CupertinoColors.extraLightBackgroundGray,
        child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: CupertinoButton(
                padding:
                    const EdgeInsets.only(right: 24.0, top: 8.0, bottom: 8.0),
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Text("Done",
                    style: TextStyle(
                      color: isDarkTheme?ColorsRes.appColorWhite:CupertinoColors.activeBlue,
                    )),
              ),
            )));
  }
}
