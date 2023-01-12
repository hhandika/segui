import 'package:flutter/material.dart';

class FeatureButton extends StatelessWidget {
  const FeatureButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.mainColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final Color mainColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          // Lerp colors
          color: Color.lerp(
            Theme.of(context).colorScheme.secondaryContainer,
            mainColor,
            0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
