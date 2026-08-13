import 'package:project/helper/utils/generalImports.dart';

Widget editBoxWidget(
  BuildContext context,
  TextEditingController? edtController,
  Function(String)? validationFunction,
  String label,
  String errorLabel,
  TextInputType inputType, {
  Widget? tailIcon,
  Widget? leadingIcon,
  bool isLastField = false,
  bool isEditable = true,
  bool isReadOnly = false,
  List<TextInputFormatter>? inputFormatters,
  TextInputAction? optionalTextInputAction,
  int minLines = 1,
  int maxLines = 1,
  int? maxLength,
  FloatingLabelBehavior floatingLabelBehavior = FloatingLabelBehavior.auto,
  Color? fillColor,
  bool obscureText = false,
  FocusNode? focusNode,
  // double width = 335,
  double height = 52,
  double borderRadius = 12,
  double paddingAll = 14,
  String prefixText = '',
}) {
  return Container(
    width: double.infinity,
    height: height.h,
    padding: EdgeInsets.all(paddingAll),
    decoration: BoxDecoration(
      color: fillColor ?? Colors.white,
      border: Border.all(
        color: const Color(0xFFD5D5D5),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          leadingIcon,
          SizedBox(width: 7),
        ],
        Text(
          prefixText,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 7),
        Expanded(
          child: TextFormField(
            controller: edtController,
            enabled: isEditable,
            readOnly: isReadOnly,
            minLines: minLines,
            maxLines: maxLines,
            maxLength: maxLength,
            obscureText: obscureText,
            focusNode: focusNode,
            textInputAction: optionalTextInputAction ??
                (isLastField ? TextInputAction.done : TextInputAction.next),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: inputType,
            inputFormatters: inputFormatters ?? [],
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.43,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              isDense: true,
              border: InputBorder.none,
              hintText: label,
              hintStyle: GoogleFonts.inter(
                color: Color(0xFF7C7B7B),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              suffixIcon: tailIcon,
              errorStyle: GoogleFonts.inter(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            // validator: (String? value) {
            //   return validationFunction!(value ?? "") == null
            //       ? null
            //       : errorLabel;
            // },
          ),
        ),
      ],
    ),
  );
}
