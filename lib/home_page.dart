import 'dart:io';
import 'dart:math';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lb_flutter_confusion/readme_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _confuseClassTextController = TextEditingController();
  final TextEditingController _confuseMethodTextController = TextEditingController();
  final TextEditingController _filePathTextController = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    _readConfuseCode();
  }

  ///读取垃圾代码
  Future _readConfuseCode() async {
    String junkClassPath = 'assets${Platform.pathSeparator}lb_confuse_class.dart';
    rootBundle.loadString(junkClassPath).then((junkClassCode) {
      _confuseClassTextController.text = junkClassCode;
    });

    String junkMethodsPath = 'assets${Platform.pathSeparator}lb_confuse_methods.dart';
    rootBundle.loadString(junkMethodsPath).then((junkMethodCode) {
      _confuseMethodTextController.text = junkMethodCode;
    });
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

    ///获取垃圾代码列表（垃圾类）
    List<String> junkClassList = [];
    List<String> junkClassCodeLines = _confuseClassTextController.text.split('\n');
    String junkClassString = '';
    for(String line in junkClassCodeLines){
      if(line == '@pragma(\'vm:entry-point\')'){
        junkClassList.add(junkClassString);
        junkClassString = '';
      }
      junkClassString += '$line\n';
    }
    junkClassList.removeAt(0);

    ///获取垃圾代码列表（垃圾方法）
    List<String> junkMethodList = [];
    List<String> junkMethodCodeLines = _confuseMethodTextController.text.split('\n');
    String junkMethodString = '';
    for(String line in junkMethodCodeLines){
      if(line == '@pragma(\'vm:entry-point\')'){
        junkMethodList.add(junkMethodString);
        junkMethodString = '';
      }
      junkMethodString += '$line\n';
    }
    junkMethodList.removeAt(0);


    ///向目标.dart文件插入垃圾代码
    Random random = Random();
    for(File file in dartFileList){
      ///利用dart代码静态分析工具analyzer获取抽象语法树(AST)：
      ///找到可以添加垃圾代码的那一行代码申明：类声明的前面、方法申明的前面。
      List<String> targetClassLines = [];
      List<String> targetMethodLines = [];
      String fileCodeString = await file.readAsString();
      final parseResult = parseString(content: fileCodeString);
      final compilationUnit = parseResult.unit;
      // 遍历所有顶级声明
      for (final declaration in compilationUnit.declarations) {
        if (declaration is ClassDeclaration) {
          //发现类
          // print('    发现类: ${declaration.name}');
          String targetClassLine = fileCodeString.substring(declaration.classKeyword.charOffset, declaration.leftBracket.charEnd);
          targetClassLines.add(targetClassLine);
          // 遍历类成员
          for (final member in declaration.members) {
            if (member is MethodDeclaration) {
              //发现方法
              // print('    发现方法: ${member.name}');
              int? methodStart, methodEnd;
              if(member.modifierKeyword != null){
                methodStart = member.modifierKeyword!.offset;
              }
              else if(member.returnType != null){
                methodStart = member.returnType!.offset;
              }
              if(member.parameters != null){
                methodEnd = member.parameters!.rightParenthesis.charEnd;
              }

              if(methodStart!=null && methodEnd!=null){
                String targetMethodLine = fileCodeString.substring(methodStart, methodEnd);
                targetMethodLines.add(targetMethodLine);
              }
            }
          }
        } else if (declaration is FunctionDeclaration) {
          //发现顶级函数
          // print('发现顶级函数: ${declaration.name}');
        }
      }

      // print(targetClassLines.join('\n'));
      // print(targetMethodLines.join('\n'));

      //已经使用过的index(防止同一文件中植入相同类或方法)
      List<int> randomClassIndexList = [];
      List<int> randomMethodIndexList = [];
      ///再次遍历代码行，给具体行添加垃圾代码
      List<String> codeLines = file.readAsLinesSync();
      List<String> newCodeLines = [];
      for(String line in codeLines){
        int index = codeLines.indexOf(line);
        int previousIndex = index-1;
        if(previousIndex>-1 && (codeLines[previousIndex].contains('@')==false)){
          if(targetClassLines.contains(line.trim())){
            if(randomClassIndexList.length<junkClassList.length) {
              int randomIndex;
              do{
                randomIndex = random.nextInt(junkClassList.length);
              }while(randomClassIndexList.contains(randomIndex));
              randomClassIndexList.add(randomIndex);
              line = '${junkClassList[randomIndex]}$line';
            }
          }
          else {
            String tempLine = line.trim();
            int i = tempLine.lastIndexOf(')');
            if(i>-1) {
              String l = tempLine.substring(0, i+1);
              if (targetMethodLines.contains(l)) {
                if(randomMethodIndexList.length<junkMethodList.length) {
                  int randomIndex;
                  do{
                    randomIndex = random.nextInt(junkMethodList.length);
                  }while(randomMethodIndexList.contains(randomIndex));
                  randomMethodIndexList.add(randomIndex);
                  line = '${junkMethodList[randomIndex]}$line';
                }
              }
            }
          }
        }
        newCodeLines.add(line);
      }
      ///重新写入文件
      file.writeAsStringSync(newCodeLines.join("\n"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LB Flutter Confusion',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          CupertinoButton(
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
                        Text(
                          '"垃圾类"代码列表',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: ConfuseTextFiled(
                            hintText: '请输入垃圾类列表，并使用@pragma(\'vm:entry-point\')注解',
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
                        Text(
                          '"垃圾方法"代码列表',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: ConfuseTextFiled(
                            hintText: '请输入垃圾类列表，并使用@pragma(\'vm:entry-point\')注解',
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
          contentPadding: EdgeInsets.symmetric(horizontal:8),
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
