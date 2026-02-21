import 'package:flutter/material.dart';

class PaperInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PaperInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/paper_ui/Sprites/Content/5_Holders/9.png',
                    width: 28,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                  Expanded(
                    child: Image.asset(
                      'assets/paper_ui/Sprites/Content/5_Holders/10.png',
                      repeat: ImageRepeat.repeatX,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  Image.asset(
                    'assets/paper_ui/Sprites/Content/5_Holders/11.png',
                    width: 28,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontSize: 18,
                  fontFamily: 'ArkPixel',
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Color(0xFF8D6E63),
                    fontSize: 16,
                    fontFamily: 'ArkPixel',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
