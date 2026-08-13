import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/resgistration/food/food_registration_provider.dart';
import 'package:project/screens/profileScreen/edit_personal_profile_screen.dart';
import 'package:project/screens/profileScreen/edit_store_profile_screen.dart';

profileHeader(
    {required BuildContext context,
    required String name,
    required String mobile}) {
  return GestureDetector(
    onTap: () {
      if (Constant.session.isSeller()) {
        openBottomSheetDialog(context, "Edit Profile", (sheetContext) {
          return [
            ListTile(
              leading: Icon(Icons.person, color: ColorsRes.appColor),
              title: CustomTextLabel(text: "Personal Information"),
              trailing: Icon(Icons.arrow_forward_ios, size: 15),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangeNotifierProvider<FoodRegistrationProvider>(
                      create: (context) => FoodRegistrationProvider(context),
                      child: EditPersonalProfileScreen(),
                    ),
                  ),
                );
              },
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.store, color: ColorsRes.appColor),
              title: CustomTextLabel(text: "Store Information"),
              trailing: Icon(Icons.arrow_forward_ios, size: 15),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangeNotifierProvider<FoodRegistrationProvider>(
                      create: (context) => FoodRegistrationProvider(context),
                      child: EditStoreProfileScreen(),
                    ),
                  ),
                );
              },
            ),
          ];
        });
      } else {
        Navigator.pushNamed(context, editDeliveryBoyProfileScreen,
            arguments: "");
      }
    },
    child: Card(
      color: Theme.of(context).cardColor,
      surfaceTintColor: ColorsRes.appColorTransparent,
      elevation: 0,
      margin: EdgeInsetsDirectional.only(bottom: 5, start: 3, end: 3),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: CustomTextLabel(
                      text: name,
                    ),
                    subtitle: CustomTextLabel(
                      text: mobile,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .apply(color: ColorsRes.appColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Container(
              decoration: DesignConfig.boxGradient(5),
              padding: EdgeInsets.all(5),
              margin: EdgeInsetsDirectional.only(end: 8, top: 8),
              child: defaultImg(
                  image: AppAssets.editIcon,
                  iconColor: ColorsRes.appColorWhite,
                  height: 20,
                  width: 20),
            ),
          ),
        ],
      ),
    ),
  );
}
