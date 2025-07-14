# lb_flutter_confusion
Flutter项目混淆，向合适的地方插入垃圾代码，支持自定义垃圾代码库。

脚本利用dart代码静态分析工具analyzer获取抽象语法树(AST)，
在合适的地方（目前是在所有类前添加垃圾类，以及非顶层方法前添加垃圾方法），
垃圾类代码库在assets/lb_confuse_class.dart，也可通过输入框直接添加，
垃圾方法代码库在assets/lb_confuse_methods.dart，也可通过输入框直接添加，
可根据需要自行添加垃圾代码（注意需使用@pragma('vm:entry-point')注解，防止打包后被编译器优化）。

使用方法：
1.选择需要混淆的文件夹或dart文件
比如要混淆项目根根目录lib下的所有文件：~/Desktop/confusion_test_demo/lib；
2.点击开始混淆即可。

注意：混淆不可逆，混淆后代码可读性会很差，所以建议打包上架前拷贝工程，仅打包混淆使用。
