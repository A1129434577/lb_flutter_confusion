import 'package:flutter/material.dart';

class ReadmePage extends StatelessWidget {
  const ReadmePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '说明',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Text(
          '''
        该app提供Flutter项目混淆，向合适的地方插入垃圾代码（可还原），支持自定义垃圾代码库。
        
        目前是在所有类前添加垃圾类，以及非顶层方法前添加垃圾方法，
        可根据需要自行添加垃圾代码，
        自行添加垃圾代码要注意:
        1.需使用@pragma('vm:entry-point')注解，防止打包后被编译器优化。
        2.无任何继承（防止编译报错）；
        3.不需要导入任何库（避免需要手动导入库）；
        4.尽量复杂点。
        
        使用方法：
        1.选择需要混淆的文件夹或单个.dart文件
        比如要混淆项目根根目录lib下的所有文件：~/Desktop/confusion_test_demo/lib；
        2.点击开始混淆即可;
        3.如需还原请点击还原方法。
        
        ''',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
