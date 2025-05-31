// import 'package:flutter/material.dart';

// class AnimationUtils {
//   static AnimationController createController({
//     required TickerProvider vsync,
//     Duration duration = const Duration(milliseconds: 600),
//   }) {
//     return AnimationController(vsync: vsync, duration: duration);
//   }

//   static Animation<double> createFadeAnimation(AnimationController controller) {
//     return Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
//   }

//   static Animation<double> createScaleAnimation(
//     AnimationController controller,
//   ) {
//     return Tween<double>(begin: 0.5, end: 1.0).animate(
//       CurvedAnimation(
//         parent: controller,
//         curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
//       ),
//     );
//   }

//   static Animation<Offset> createSlideAnimation({
//     required AnimationController controller,
//     Offset begin = const Offset(0.0, 0.5),
//     Offset end = Offset.zero,
//   }) {
//     return Tween<Offset>(
//       begin: begin,
//       end: end,
//     ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutBack));
//   }

//   static void triggerStaggeredAnimations(
//     List<AnimationController> controllers,
//   ) {
//     for (int i = 0; i < controllers.length; i++) {
//       Future.delayed(Duration(milliseconds: i * 150), () {
//         if (!controllers[i].isAnimating) {
//           controllers[i].forward();
//         }
//       });
//     }
//   }

//   static void startAnimation(AnimationController controller) {
//     if (!controller.isAnimating) {
//       controller.forward();
//     }
//   }

//   static void resetAndStartAnimation(AnimationController controller) {
//     controller.reset();
//     controller.forward();
//   }

//   static void disposeControllers(List<AnimationController> controllers) {
//     for (var controller in controllers) {
//       controller.dispose();
//     }
//   }

//   static void disposeController(AnimationController controller) {
//     controller.dispose();
//   }
// }
