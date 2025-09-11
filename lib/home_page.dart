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

const String annotateString = '@pragma(\'vm:entry-point\')';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const junkClassCodeCacheKey = 'lb_confuse_class';
  static const junkMethodCodeCacheKey = 'lb_confuse_methods';

  final TextEditingController _confuseClassTextController = TextEditingController();
  final TextEditingController _confuseMethodTextController = TextEditingController();
  final TextEditingController _filePathTextController = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    _confuseClassTextController.addListener(() {
      DefaultCacheManager().putFile(junkClassCodeCacheKey, utf8.encode(_confuseClassTextController.text));
    });
    _confuseMethodTextController.addListener(() {
      DefaultCacheManager().putFile(junkMethodCodeCacheKey, utf8.encode(_confuseMethodTextController.text));
    });
    _readAndCacheConfuseCode();
  }

  ///读取垃圾代码
  Future _readAndCacheConfuseCode({bool resetClass=false, bool resetMethod=false}) async {
    File? junkClassFile = (await DefaultCacheManager().getFileFromCache(junkClassCodeCacheKey))?.file;
    File? junkMethodsFile = (await DefaultCacheManager().getFileFromCache(junkMethodCodeCacheKey))?.file;
    if(junkClassFile == null || resetClass){
      String junkClassPath = 'assets/lb_confuse_class.dart';
      String junkClassCode = await rootBundle.loadString(junkClassPath);
      junkClassFile = await DefaultCacheManager().putFile(junkClassCodeCacheKey, utf8.encode(junkClassCode));
    }
    if(junkMethodsFile == null || resetMethod){
      String junkMethodsPath = 'assets/lb_confuse_methods.dart';
      String junkMethodCode = await rootBundle.loadString(junkMethodsPath);
      junkMethodsFile = await DefaultCacheManager().putFile(junkMethodCodeCacheKey, utf8.encode(junkMethodCode));
    }

    _confuseClassTextController.text = junkClassFile.readAsStringSync();
    _confuseMethodTextController.text = junkMethodsFile.readAsStringSync();
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
    ///获取垃圾类和方法代码列表
    List<String> junkClassList = [], junkMethodList = [];
    String junkClassAndMethodCodeString = _confuseClassTextController.text+_confuseMethodTextController.text;
    final junkParseResult = parseString(content: junkClassAndMethodCodeString);
    final junkCompilationUnit = junkParseResult.unit;
    //遍历所有顶级声明
    for (final declaration in junkCompilationUnit.declarations) {
      if (declaration is ClassDeclaration) {
        //发现类
        // print('发现类: ${declaration.name}');
        String junkClassBody = junkClassAndMethodCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
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
          }
        }
      } else if (declaration is FunctionDeclaration) {
        //发现顶级函数
        // print('发现顶级函数: ${declaration.name}');
        String junkTopMethodBody = junkClassAndMethodCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
        junkTopMethodBody += '\n';
        junkMethodList.add(junkTopMethodBody);
      }
    }

    ///利用dart代码静态分析工具analyzer获取抽象语法树(AST)：
    ///向目标.dart文件所有类和方法前面插入垃圾代码
    for(File file in dartFileList){
      String fileCodeString = await file.readAsString();
      ///找到可以添加垃圾代码的那一行代码申明：类声明的前面、方法申明的前面。
      ///不能单单只记录行号，因为添加垃圾代码后，行号会变化，
      ///所以要记录代码体，然后再去原始代码中查找代码体的位置。
      bool isAlreadyConfused = false;
      List<String> targetClassBodys = [];
      List<String> targetMethodBodys = [];
      final parseResult = parseString(content: fileCodeString);
      final compilationUnit = parseResult.unit;
      //遍历所有顶级声明
      for (final declaration in compilationUnit.declarations) {
        if (declaration is ClassDeclaration) {
          //发现类
          // print('发现类: ${declaration.name}');
          String targetClassBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          String? findClassString = junkClassList.where((e){
            return e.contains(targetClassBody);
          }).toList().firstOrNull;
          if(findClassString != null){
            isAlreadyConfused = true;
            break;
          }
          targetClassBodys.add(targetClassBody);
          // 遍历类成员
          for (final member in declaration.members) {
            if (member is MethodDeclaration) {
              //发现方法
              // print('发现方法: ${member.name}');
              String targetMethodBody = fileCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
              String? findMethodString = junkMethodList.where((e){
                return e.contains(targetMethodBody);
              }).toList().firstOrNull;
              if(findMethodString != null){
                isAlreadyConfused = true;
                break;
              }
              targetMethodBodys.add(targetMethodBody);
            }
          }
        } else if (declaration is FunctionDeclaration) {
          //发现顶级函数
          // print('发现顶级函数: ${declaration.name}');
          String targetTopMethodBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          String? findMethodString = junkMethodList.where((e){
            return e.contains(targetTopMethodBody);
          }).toList().firstOrNull;
          if(findMethodString != null){
            isAlreadyConfused = true;
            break;
          }
          targetMethodBodys.add(targetTopMethodBody);
        }
      }

      if(isAlreadyConfused){
        continue;
      }

      ///再次遍历代码行，给具体行添加垃圾代码
      String newFileCodeString = fileCodeString;
      Random random = Random();
      //已经使用过的index(防止同一文件中植入相同类或方法)
      List<int> randomClassIndexList = [];
      List<int> randomMethodIndexList = [];
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
    ///获取垃圾类和方法代码列表
    List<String> junkClassList = [], junkMethodList = [];
    String junkClassAndMethodCodeString = _confuseClassTextController.text+_confuseMethodTextController.text;
    final junkParseResult = parseString(content: junkClassAndMethodCodeString);
    final junkCompilationUnit = junkParseResult.unit;
    //遍历所有顶级声明
    for (final declaration in junkCompilationUnit.declarations) {
      if (declaration is ClassDeclaration) {
        //发现类
        // print('发现类: ${declaration.name}');
        String junkClassBody = junkClassAndMethodCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
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
          }
        }
      } else if (declaration is FunctionDeclaration) {
        //发现顶级函数
        // print('发现顶级函数: ${declaration.name}');
        String junkTopMethodBody = junkClassAndMethodCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
        junkTopMethodBody += '\n';
        junkMethodList.add(junkTopMethodBody);
      }
    }

    ///利用dart代码静态分析工具analyzer获取抽象语法树(AST)：
    ///找到已经添加的垃圾代码类、方法。
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
          String? findClassString = junkClassList.where((e){
            return e.contains(targetClassBody);
          }).toList().firstOrNull;
          if(findClassString != null){
            junkCodeBodyList.add(findClassString);
          }
          // 遍历类成员
          for (final member in declaration.members) {
            if (member is MethodDeclaration) {
              //发现方法
              // print('发现方法: ${member.name}');
              String targetMethodBody = fileCodeString.substring(member.beginToken.charOffset, member.endToken.charEnd);
              String? findMethodString = junkMethodList.where((e){
                return e.contains(targetMethodBody);
              }).toList().firstOrNull;
              if(findMethodString != null){
                junkCodeBodyList.add(findMethodString);
              }
            }
          }
        } else if (declaration is FunctionDeclaration) {
          //发现顶级函数
          // print('发现顶级函数: ${declaration.name}');
          String targetTopMethodBody = fileCodeString.substring(declaration.beginToken.charOffset, declaration.endToken.charEnd);
          String? findMethodString = junkMethodList.where((e){
            return e.contains(targetTopMethodBody);
          }).toList().firstOrNull;
          if(findMethodString != null){
            junkCodeBodyList.add(findMethodString);
          }
        }
      }

      String newFileCodeString = fileCodeString;
      for(String junkCode in junkCodeBodyList){
        newFileCodeString = newFileCodeString.replaceAll(junkCode, '');
      }
      file.writeAsStringSync(newFileCodeString);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '"垃圾类"代码列表',
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
                                _readAndCacheConfuseCode(resetClass: true);
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
                            hintText: '请输入垃圾类列表，并使用$annotateString注解',
                            controller: _confuseClassTextController,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '"垃圾方法"代码列表',
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
                                _readAndCacheConfuseCode(resetMethod: true);
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
                            )
                          ],
                        ),
                        SizedBox(height: 5),
                        Expanded(
                          child: ConfuseTextFiled(
                            hintText: '请输入垃圾方法列表，并使用$annotateString注解',
                            controller: _confuseMethodTextController,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
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
