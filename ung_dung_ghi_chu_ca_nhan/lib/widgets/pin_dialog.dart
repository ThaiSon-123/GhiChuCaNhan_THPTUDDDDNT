import 'package:flutter/material.dart';

/// Hiện hộp thoại yêu cầu nhập mã PIN.
/// Trả về true nếu nhập đúng, false/null nếu hủy hoặc đóng.
Future<bool?> showPinDialog(BuildContext context, String expectedPin) {
  final controller = TextEditingController();
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      // Biến trạng thái lỗi bên trong dialog
      String? errorText;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Ghi chú bị khóa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nhập mã PIN để mở ghi chú:'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Mã PIN',
                    border: const OutlineInputBorder(),
                    // Hiện lỗi màu đỏ khi nhập sai
                    errorText: errorText,
                  ),
                  onSubmitted: (value) {
                    if (value == expectedPin) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() => errorText = 'Mã PIN không đúng');
                      controller.clear();
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text == expectedPin) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() => errorText = 'Mã PIN không đúng');
                    controller.clear();
                  }
                },
                child: const Text('Mở khóa'),
              ),
            ],
          );
        },
      );
    },
  );
}
