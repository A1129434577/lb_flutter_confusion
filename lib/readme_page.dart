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
        
        目前是在所有类前添加垃圾类，所有方法前添加垃圾方法，属性前面添加垃圾属性（每个文件限制添加的垃圾属性个数可自定），
        并且在方法内调用垃圾类以及垃圾方法。
        可根据需要自行添加垃圾代码（重置功能是重置垃圾代码）：
        自行添加垃圾类代码:
        1.不需要引入任何库；
        2.私有；
        3.无构造方法；
        4.互不关联；
        5.中等复杂；
        6.类名乱码处理；
        7.每个类独立，不引用私有类。
        
        自行添加垃圾方法代码:
        1.不需要引入任何库；
        2.私有；
        3.互不关联；
        4.中等复杂；
        5.方法名乱码处理；
        6.每个方法独立，不需要调用私有方法。
        
        自行添加垃圾final属性代码（属性越多代码随机性越大）:
        1.不需要引入任何库；
        2.final的基本数据类型（防止其他类型加入const类型对象报错）；
        3.无需分组；
        4.赋初值；
        5.属性名乱码处理。
        
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
