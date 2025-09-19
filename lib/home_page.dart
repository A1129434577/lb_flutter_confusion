import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lb_flutter_confusion/readme_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const junkClassCodeCacheKey = 'lb_confuse_class';
  static const junkMethodCodeCacheKey = 'lb_confuse_methods';
  static const junkFieldsCodeCacheKey = 'lb_confuse_fields';

  final TextEditingController _confuseClassTextController = TextEditingController();
  final TextEditingController _confuseMethodTextController = TextEditingController();
  final TextEditingController _confuseFieldsTextController = TextEditingController();

  final TextEditingController _filePathTextController = TextEditingController();
  String? _message;

  //想要添加的属性个数
  ValueNotifier<int> addFiledCount = ValueNotifier(6);

  @override
  void initState() {
    super.initState();
    _confuseClassTextController.addListener(() {
      DefaultCacheManager().putFile(junkClassCodeCacheKey, utf8.encode(_confuseClassTextController.text));
    });
    _confuseMethodTextController.addListener(() {
      DefaultCacheManager().putFile(junkMethodCodeCacheKey, utf8.encode(_confuseMethodTextController.text));
    });
    _confuseFieldsTextController.addListener(() {
      DefaultCacheManager().putFile(junkFieldsCodeCacheKey, utf8.encode(_confuseFieldsTextController.text));
    });
    _readAndCacheConfuseCode();
  }

  ///读取垃圾代码
  Future _readAndCacheConfuseCode({bool resetClass=false, bool resetMethods=false, bool resetFields=false}) async {
    File? junkClassFile = (await DefaultCacheManager().getFileFromCache(junkClassCodeCacheKey))?.file;
    File? junkMethodsFile = (await DefaultCacheManager().getFileFromCache(junkMethodCodeCacheKey))?.file;
    File? junkFieldsFile = (await DefaultCacheManager().getFileFromCache(junkFieldsCodeCacheKey))?.file;

    if(junkClassFile == null || resetClass){
      String junkClassPath = 'assets/$junkClassCodeCacheKey.dart';
      String junkClassCode = await rootBundle.loadString(junkClassPath);
      junkClassFile = await DefaultCacheManager().putFile(junkClassCodeCacheKey, utf8.encode(junkClassCode));
    }

    if(junkMethodsFile == null || resetMethods){
      String junkMethodsPath = 'assets/$junkMethodCodeCacheKey.dart';
      String junkMethodCode = await rootBundle.loadString(junkMethodsPath);
      junkMethodsFile = await DefaultCacheManager().putFile(junkMethodCodeCacheKey, utf8.encode(junkMethodCode));
    }

    if(junkFieldsFile == null || resetFields){
      String junkFieldsPath = 'assets/$junkFieldsCodeCacheKey.dart';
      String junkFieldsCode = await rootBundle.loadString(junkFieldsPath);
      junkFieldsFile= await DefaultCacheManager().putFile(junkFieldsCodeCacheKey, utf8.encode(junkFieldsCode));
    }

    _confuseClassTextController.text = junkClassFile.readAsStringSync();
    _confuseMethodTextController.text = junkMethodsFile.readAsStringSync();
    _confuseFieldsTextController.text = junkFieldsFile.readAsStringSync();
  }

  ///开始混淆
  Future startConfuseCode() async {
    ///遍历文件夹下的所有.dart文件为其添加垃圾代码
    String filePath = _filePathTextController.text;
    List<File> dartFileList = [];
    Directory fileDirectory = Directory(filePath);
    if(fileDirectory.existsSync()) {
      Future readFileRecursively(Directory directory) async {
        if (directory.existsSync()) {
          await for (var entity in directory.list()) {
            if (entity is Directory) {
              await readFileRecursively(entity);
            } else if (entity is File) {
              if (entity.path.endsWith('.dart')) {
                dartFileList.add(entity);
              }
            }
          }
        }
      }
      await readFileRecursively(fileDirectory);
    }else{
      File file = File(filePath);
      if(file.existsSync()) {
        if (file.path.endsWith('.dart')) {
          dartFileList.add(file);
        }
      }
    }

    ///利用dart代码静态分析工具analyzer获取抽象语法树(AST)：
    ///获取垃圾类、方法和属性代码列表
    List<String> junkClassList = [], junkMethodList = [], junkFieldsList = [];
    String junkAllCodeString = _confuseClassTextController.text+_confuseMethodTextController.text+_confuseFieldsTextController.text;
    final junkParseResult = parseString(content: junkAllCodeString);
    final junkCompilationUnit = junkParseResult.unit;
    //遍历所有顶级声明
    for (final declaration in junkCompilationUnit.declarations) {
      if (declaration is ClassDeclaration) {
        //发现类
        // print('发现类: ${declaration.name}');
        String junkClassBody = junkAllCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
        junkClassBody += '\n';
        junkClassList.add(junkClassBody);
        // 遍历类成员
        for (final member in declaration.members) {
          if (member is MethodDeclaration) {
            //发现方法
            // print('发现方法: ${member.name}');
            //Warning: 这里不添加子方法，因为垃圾代码中每个方法已经独立
            // String junkMethodBody = junkClassAndMethodCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
            // junkMethodBody += '\n';
            // junkMethodList.add(junkMethodBody);
          }else if (member is FieldDeclaration) {
            //发现字段
            // print('发现字段: ${member.fields}');
          }
        }
      }
      else if (declaration is FunctionDeclaration) {
        //发现顶级函数
        // print('发现顶级函数: ${declaration.functionExpression.parameters}');
        String junkTopMethodBody = junkAllCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
        junkTopMethodBody += '\n';
        junkMethodList.add(junkTopMethodBody);
      }
      else if(declaration is TopLevelVariableDeclaration) {
        //发现字段
        // print('发现字段: ${declaration}');
        String junkTopFieldBody = junkAllCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
        junkTopFieldBody += '\n';
        junkFieldsList.add(junkTopFieldBody);
      }
    }

    Random random = Random();

    ///利用dart代码静态分析工具analyzer获取抽象语法树(AST)：
    ///向目标.dart文件所有类、方法和属性前面插入垃圾代码
    for(File file in dartFileList){
      String fileCodeString = await file.readAsString();
      ///找到可以添加垃圾代码的那一行代码申明：类声明、方法申明和属性声明的前面。
      ///不能单单只记录行号，因为添加垃圾代码后，行号会变化，
      ///所以要记录代码体，然后再去原始代码中查找代码体的位置。
      bool isAlreadyConfused = false;
      List<String> targetClassBodys = [];
      List<String> targetMethodBodys = [];
      //value:是否是const类的属性
      Map<List<String>, bool> targetFieldBodysInfo = {};
      final parseResult = parseString(content: fileCodeString);
      final compilationUnit = parseResult.unit;
      //遍历所有顶级声明
      for (final declaration in compilationUnit.declarations) {
        List<String> thisClassTargetFieldBodys = [], thisClassTargetMethodBodys = [];
        //如果是虚拟类，不添加垃圾方法和属性
        bool isCannotJunkFields = false, isCannotJunkMethods = false, isConstClass = false;
        if (declaration is ClassDeclaration) {
          //发现类
          // print('发现类: ${declaration.name}');
          String targetClassBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          if(junkClassList.contains('$targetClassBody\n')){
            isAlreadyConfused = true;
            break;
          }
          targetClassBodys.add(targetClassBody);
          if(declaration.abstractKeyword!=null){
            isCannotJunkFields = true;
            isCannotJunkMethods = true;
          }
          // 遍历类成员
          for (final member in declaration.members) {
            if (member is MethodDeclaration) {
              //发现方法
              // print('发现方法: ${member.name}');
              String targetMethodBody = fileCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
              if(junkMethodList.contains('$targetMethodBody\n')){
                isAlreadyConfused = true;
                break;
              }
              thisClassTargetMethodBodys.add(targetMethodBody);
            }
            else if(member is FieldDeclaration){
              //发现字段
              // print('发现字段: ${member.fields}');
              String targetFieldBody = fileCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
              if(junkFieldsList.contains('$targetFieldBody\n')){
                isAlreadyConfused = true;
                break;
              }
              thisClassTargetFieldBodys.add(targetFieldBody);
            }
            else if(member is ConstructorDeclaration){
              if(member.constKeyword != null){
                isConstClass = true;
              }
            }
          }
        }
        else if (declaration is FunctionDeclaration) {
          //发现顶级函数
          // print('发现顶级函数: ${declaration.name}');
          String targetTopMethodBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          if(junkMethodList.contains('$targetTopMethodBody\n')){
            isAlreadyConfused = true;
            break;
          }
          thisClassTargetMethodBodys.add(targetTopMethodBody);
        }
        if(isCannotJunkMethods == false){
          targetMethodBodys.addAll(thisClassTargetMethodBodys);
        }
        if(isCannotJunkFields == false){
          targetFieldBodysInfo[thisClassTargetFieldBodys] = isConstClass;
        }
      }

      if(isAlreadyConfused){
        continue;
      }

      ///再次遍历代码行，给具体行添加垃圾代码
      String newFileCodeString = fileCodeString;
      //已经使用过的index(防止同一文件中植入相同类或方法)
      List<int> randomClassIndexList = [];
      List<int> randomMethodIndexList = [];
      List<int> randomFiledIndexList = [];
      for (String codeBody in targetClassBodys) {
        int index = newFileCodeString.indexOf(codeBody);
        if (index != -1) {
          if (randomClassIndexList.length < junkClassList.length) {
            int randomIndex;
            do {
              randomIndex = random.nextInt(junkClassList.length);
            } while (randomClassIndexList.contains(randomIndex));
            randomClassIndexList.add(randomIndex);
            newFileCodeString = newFileCodeString.replaceRange(
                index, index, junkClassList[randomIndex]);
          }
        }
      }
      for (String codeBody in targetMethodBodys) {
        int index = newFileCodeString.indexOf(codeBody);
        if (index != -1) {
          if (randomMethodIndexList.length < junkMethodList.length) {
            int randomIndex;
            do {
              randomIndex = random.nextInt(junkMethodList.length);
            } while (randomMethodIndexList.contains(randomIndex));
            randomMethodIndexList.add(randomIndex);
            newFileCodeString = newFileCodeString.replaceRange(
                index, index, junkMethodList[randomIndex]);
          }
        }
      }
      targetFieldBodysInfo.forEach((targetFieldBodys, isConstClass){
        for (String codeBody in targetFieldBodys) {
          int index = newFileCodeString.indexOf(codeBody);
          if (index != -1) {
            if (randomFiledIndexList.length < junkFieldsList.length && randomFiledIndexList.length<addFiledCount.value) {
              int randomIndex;
              do {
                randomIndex = random.nextInt(junkFieldsList.length);
              } while (randomFiledIndexList.contains(randomIndex));
              randomFiledIndexList.add(randomIndex);
              newFileCodeString = newFileCodeString.replaceRange(
                  index, index, junkFieldsList[randomIndex]);
            }
          }
        }
      });

      ///重新写入文件
      file.writeAsStringSync(newFileCodeString);
    }

    ///再一次：利用dart代码静态分析工具analyzer获取抽象语法树(AST)：
    ///遍历已经加入垃圾代码类和方法的文件，找到非垃圾方法体，并非垃圾方法内部调用垃圾代码类初始化和调用垃圾方法。
    for(File file in dartFileList){
      String fileCodeString = await file.readAsString();

      final parseResult = parseString(content: fileCodeString);
      final compilationUnit = parseResult.unit;
      Map<List,List<List>> classInvokeMethodMap = {};
      List<String> thisFileInvokeClassList = [];
      //遍历所有顶级声明
      for (final declaration in compilationUnit.declarations) {
        List<String> thisClassInvokeMethodList = [], thisClassTargetMethodBodys = [];

        if (declaration is ClassDeclaration) {
          //发现类
          // print('发现类: ${declaration.name}');
          String targetClassBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          targetClassBody += '\n';
          if(junkClassList.contains(targetClassBody)){
            //如果是垃圾类，继续下一个类
            String invokeClassString = '${declaration.name}()';
            thisFileInvokeClassList.add(invokeClassString);
            continue;
          }
          // 遍历类成员
          for (final member in declaration.members) {
            if (member is MethodDeclaration) {
              //发现方法
              // print('发现方法: ${member.name}');
              String methodBody = fileCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
              methodBody += '\n';
              if(junkMethodList.contains(methodBody)){
                //如果是垃圾代码，加入调用列表
                String invokeMethodString = '${member.name}()';
                thisClassInvokeMethodList.add(invokeMethodString);
              }else{
                String methodBody = fileCodeString.substring(member.body.beginToken.charOffset, member.body.endToken.charEnd);
                thisClassTargetMethodBodys.add(methodBody);
              }
            }
          }
        }
        else if (declaration is FunctionDeclaration) {
          //发现顶级函数
          // print('发现顶级函数: ${declaration.name}');
          String topMethodBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          topMethodBody += '\n';
          if(junkMethodList.contains(topMethodBody)){
            //如果是垃圾代码，加入调用列表
            String invokeMethodString = '${declaration.name}()';
            thisClassInvokeMethodList.add(invokeMethodString);
          }
        }
        classInvokeMethodMap[thisClassTargetMethodBodys] = [thisFileInvokeClassList, thisClassInvokeMethodList];
      }
      Map<String, String> targetInvokeMethodRelationshipInfo = {};

      classInvokeMethodMap.forEach((targetMethodList, invokeClassAndMethodList){
        List invokeClassList = invokeClassAndMethodList.first;
        List invokeMethodList = invokeClassAndMethodList.last;

        //已经使用过的index(防止同一文件中植入相同类或方法)
        List<int> randomInvokeClassIndexList = [];
        List<int> randomInvokeMethodIndexList = [];
        for(String targetMethod in targetMethodList){
          List lines = targetMethod.split(';');
          int targetIndex = random.nextInt(lines.length);
          int invokeClassIndex;
          do {
            invokeClassIndex = random.nextInt(invokeClassList.length);
          } while (randomInvokeClassIndexList.contains(invokeClassIndex));
          lines.insert(targetIndex, '\n${invokeClassList[invokeClassIndex]}');

          int targetIndex1 = random.nextInt(lines.length);
          int invokeMethodIndex;
          do {
            invokeMethodIndex = random.nextInt(invokeMethodList.length);
          } while (randomInvokeMethodIndexList.contains(invokeMethodIndex));
          lines.insert(targetIndex1, '\n${invokeMethodList[invokeMethodIndex]}');

          String newMethodBody = lines.join(';');
          targetInvokeMethodRelationshipInfo[targetMethod] = newMethodBody;
        }
      });
      String newFileCodeString = fileCodeString;

      //替换原有方法体
      targetInvokeMethodRelationshipInfo.forEach((targetMethodBody, newMethodBody){
        newFileCodeString = newFileCodeString.replaceAll(targetMethodBody, newMethodBody);
      });

      ///重新写入文件
      file.writeAsStringSync(newFileCodeString);
    }
  }

  ///还原代码
  Future resetCode() async {
    ///遍历文件夹下的所有.dart文件准备还原
    String filePath = _filePathTextController.text;
    List<File> dartFileList = [];
    Directory fileDirectory = Directory(filePath);
    if(fileDirectory.existsSync()) {
      Future readFileRecursively(Directory directory) async {
        if (directory.existsSync()) {
          await for (var entity in directory.list()) {
            if (entity is Directory) {
              await readFileRecursively(entity);
            } else if (entity is File) {
              if (entity.path.endsWith('.dart')) {
                dartFileList.add(entity);
              }
            }
          }
        }
      }
      await readFileRecursively(fileDirectory);
    }else{
      File file = File(filePath);
      if(file.existsSync()) {
        if (file.path.endsWith('.dart')) {
          dartFileList.add(file);
        }
      }
    }

    ///利用dart代码静态分析工具analyzer获取抽象语法树(AST)：
    ///获取垃圾类、方法、属性以及调用代码列表
    List<String> junkClassList = [], junkMethodList = [], junkFieldsList = [], invokeCodeList = [];
    String junkAllCodeString = _confuseClassTextController.text+_confuseMethodTextController.text+_confuseFieldsTextController.text;
    final junkParseResult = parseString(content: junkAllCodeString);
    final junkCompilationUnit = junkParseResult.unit;
    //遍历所有顶级声明
    for (final declaration in junkCompilationUnit.declarations) {
      if (declaration is ClassDeclaration) {
        //发现类
        // print('发现类: ${declaration.name}');
        String junkClassBody = junkAllCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
        junkClassBody += '\n';
        junkClassList.add(junkClassBody);
        invokeCodeList.add('${declaration.name}();\n');
        // 遍历类成员
        for (final member in declaration.members) {
          if (member is MethodDeclaration) {
            //发现方法
            // print('发现方法: ${member.name}');
            //Warning: 这里不添加子方法，因为垃圾代码中每个方法已经独立
            // String junkMethodBody = junkClassAndMethodCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
            // junkMethodBody += '\n';
            // junkMethodList.add(junkMethodBody);
          }else if (member is FieldDeclaration) {
            //发现字段
            // print('发现字段: ${member.fields}');
          }
        }
      }
      else if (declaration is FunctionDeclaration) {
        //发现顶级函数
        // print('发现顶级函数: ${declaration.name}');
        String junkTopMethodBody = junkAllCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
        junkTopMethodBody += '\n';
        junkMethodList.add(junkTopMethodBody);
        invokeCodeList.add('${declaration.name}();\n');
      }
      else if(declaration is TopLevelVariableDeclaration) {
        //发现字段
        // print('发现字段: ${declaration}');
        String junkTopFieldBody = junkAllCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
        junkTopFieldBody += '\n';
        junkFieldsList.add(junkTopFieldBody);
      }
    }

    ///利用dart代码静态分析工具analyzer获取抽象语法树(AST)：
    ///找到已经添加的垃圾代码类、方法和属性。
    for(File file in dartFileList){
      String fileCodeString = await file.readAsString();
      //发现的混淆代码类列表
      List<String> junkCodeBodyList = [];
      final parseResult = parseString(content: fileCodeString);
      final compilationUnit = parseResult.unit;
      //遍历所有顶级声明
      for (final declaration in compilationUnit.declarations) {
        if (declaration is ClassDeclaration) {
          //发现类
          // print('发现类: ${declaration.name}');
          String targetClassBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          String? findClassString = '$targetClassBody\n';
          if(junkClassList.contains(findClassString)){
            junkCodeBodyList.add(findClassString);
          }
          // 遍历类成员
          for (final member in declaration.members) {
            if (member is MethodDeclaration) {
              //发现方法
              // print('发现方法: ${member.name}');
              String targetMethodBody = fileCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
              String? findMethodString = '$targetMethodBody\n';
              if(junkMethodList.contains(findMethodString)){
                junkCodeBodyList.add(findMethodString);
              }
            }
            else if(member is FieldDeclaration){
              //发现字段
              // print('发现字段: ${member.fields}');
              String targetFieldBody = fileCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
              String? findFieldString = '$targetFieldBody\n';
              if(junkFieldsList.contains(findFieldString)){
                junkCodeBodyList.add(findFieldString);
              }
            }
          }
        } else if (declaration is FunctionDeclaration) {
          //发现顶级函数
          // print('发现顶级函数: ${declaration.name}');
          String targetTopMethodBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          String? findMethodString = '$targetTopMethodBody\n';
          if(junkMethodList.contains(findMethodString)){
            junkCodeBodyList.add(findMethodString);
          }
        }
      }

      String newFileCodeString = fileCodeString;
      for(String junkCode in junkCodeBodyList){
        newFileCodeString = newFileCodeString.replaceAll(junkCode, '');
      }
      for(String junkCode in invokeCodeList){
        newFileCodeString = newFileCodeString.replaceAll(junkCode, '');
      }
      file.writeAsStringSync(newFileCodeString);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> titles = ['"垃圾类"代码列表', '"垃圾方法"代码列表', '"垃圾属性"代码列表'];
    final List<String> placeholderList = [
      '''
生成n个dart类，要求如下：
1.不需要引入任何库；
2.互不关联；
3.中等复杂；
4.每个类独立，不引用私有类；
5.加上@pragma('vm:entry-point')注解（防止打包被编译器删除）。
    ''',
      '''
生成n个dart方法，要求如下：
1.不需要引入任何库；
2.互不关联；
3.中等复杂；
4.每个方法独立，不需要调用私有方法；
5.加上@pragma('vm:entry-point')注解（防止打包被编译器删除）。
    ''',
      '''
生成n个dart的final属性，要求如下：
1.无需分组；
2.属性名乱码处理；
2.不需要引入任何库；
3.加上@pragma('vm:entry-point')注解（防止打包被编译器删除）。
    '''
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flutter Confusion',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: CupertinoButton(
          sizeStyle: CupertinoButtonSize.small,
          padding: EdgeInsets.only(left: 15),
          alignment: Alignment.centerLeft,
          onPressed: () async {
            await resetCode();
            setState(() {
              _message = '已还原';
            });
          },
          child: Text(
            '还原',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ),
        actions: [
          CupertinoButton(
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.only(right: 15),
            alignment: Alignment.centerRight,
            onPressed: (){
              Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (BuildContext context) {
                      return ReadmePage();
                    },
                ),
              );
            },
            child: Text(
              '说明',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Expanded(
              child: Row(
                spacing: 10,
                children: titles.map((title){
                  int index = titles.indexOf(title);
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            CupertinoButton(
                              color: Colors.blue,
                              sizeStyle: CupertinoButtonSize.small,
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              onPressed: (){
                                if(index==0){
                                  _readAndCacheConfuseCode(resetClass: true);
                                }else if(index == 1){
                                  _readAndCacheConfuseCode(resetMethods: true);
                                }else if(index == 2){
                                  _readAndCacheConfuseCode(resetFields: true);
                                }
                              },
                              child: Text(
                                '重置',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Expanded(
                          child: ConfuseTextFiled(
                            hintText: placeholderList[index],
                            controller: [
                              _confuseClassTextController,
                              _confuseMethodTextController,
                              _confuseFieldsTextController
                            ][index],
                          ),
                        ),
                        if(index == 2)Row(
                          children: [
                            Text(
                              '添加属性个数',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            CupertinoButton(
                              onPressed: (){
                                addFiledCount.value = max(addFiledCount.value-1, 0);
                              },
                              alignment: Alignment.center,
                              padding: EdgeInsets.zero,
                              sizeStyle: CupertinoButtonSize.small,
                              child: Text(
                                '-',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha((255*0.5).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ValueListenableBuilder(
                                valueListenable: addFiledCount,
                                builder: (BuildContext context, int value, Widget? child) {
                                  return Text(
                                    '$value',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                            CupertinoButton(
                              onPressed: (){
                                addFiledCount.value ++;
                              },
                              alignment: Alignment.center,
                              padding: EdgeInsets.zero,
                              sizeStyle: CupertinoButtonSize.small,
                              child: Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 15),
            SizedBox(
              height: 44,
              child: ConfuseTextFiled(
                hintText: '选择需要添加垃圾代码的文件夹/文件',
                controller: _filePathTextController,
                suffixIcon: SizedBox(
                  height: 44,
                  width: 44,
                  child: CupertinoButton(
                    onPressed: () async {
                      List<String>? files = await FilePicker.platform.pickFileAndDirectoryPaths();
                      _filePathTextController.text = files?.firstOrNull??'';
                    },
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child: Icon(Icons.arrow_drop_down_sharp),
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            CupertinoButton(
              onPressed: () async {
                await startConfuseCode();
                setState(() {
                  _message = '混淆完成';
                });
              },
              sizeStyle: CupertinoButtonSize.small,
              padding: EdgeInsets.zero,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '开始混淆',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  )
                ),
              ),
            ),
            Text(
              _message??'',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.pinkAccent,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ConfuseTextFiled extends StatelessWidget {
  final String? hintText;
  final int? maxLines;
  final Widget? suffixIcon;
  final TextEditingController? controller;

  const ConfuseTextFiled({
    super.key,
    this.hintText,
    this.maxLines,
    this.suffixIcon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha((255*0.5).round()),
        borderRadius: BorderRadius.circular(4)
      ),
      child: TextFormField(
        maxLines: maxLines,
        controller: controller,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w300,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal:8, vertical: 8),
          suffixIcon: suffixIcon,
          hintText: hintText,
          counterText: '', //隐藏字数统计
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w300,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
