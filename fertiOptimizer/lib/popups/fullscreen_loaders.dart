
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/image_strings.dart';
import '../helper_functions/helper_functions.dart';
import 'loaders.dart';


/// A utility class for managing a full-screen loading dialog.
class EFullScreenLoader {
  /// Open a full-screen loading dialog with a given text and animation.
  static void openLoadingDialog(String text, BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          color: EHelperFunctions.isDarkMode(context)
              ? Colors.black
              : Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EAnimationLoaderWidget(
                  text: text,
                  image: EHelperFunctions.isDarkMode(context)
                      ? EImages.darkLoadingAppLogo
                      : EImages.lightLoadingAppLogo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  static void stopLoading(BuildContext context) {
    context.pop(true);
  }
}