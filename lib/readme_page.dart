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
        
        目前是在所有类前添加垃圾类，所有方法前添加垃圾方法，属性前面添加垃圾属性（每个文件限制添加的垃圾属性个数可自定）。
        可根据需要自行添加垃圾代码（重置功能是重置垃圾代码）：
        自行添加垃圾类代码:
        1.不需要引入任何库；
        2.互不关联；
        3.中等复杂；
        4.每个类独立，不引用私有类；
        5.加上@pragma('vm:entry-point')注解（防止打包被编译器删除）。
        
        自行添加垃圾方法代码:
        1.不需要引入任何库；
        2.互不关联；
        3.中等复杂；
        4.每个方法独立，不需要调用私有方法；
        5.加上@pragma('vm:entry-point')注解（防止打包被编译器删除）。
        
        自行添加垃圾属性代码（属性越多代码随机性越大）:
        1.不需要引入任何库；
        2.加上@pragma('vm:entry-point')注解（防止打包被编译器删除）。
        
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
