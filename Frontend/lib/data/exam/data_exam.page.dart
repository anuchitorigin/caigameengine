import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:cai_gameengine/constansts/doccument_status.const.dart';
import 'package:cai_gameengine/constansts/maturity_rating.const.dart';

import 'package:cai_gameengine/data/exam/exam.dialog.dart';
import 'package:cai_gameengine/components/selectors/module.selector.dart';
import 'package:cai_gameengine/components/selectors/lesson.selector.dart';
import 'package:cai_gameengine/components/common/search_criteria.chip.dart';
import 'package:cai_gameengine/components/common/image_thumbnail.widget.dart';
import 'package:cai_gameengine/components/common/tag.chip.dart';

import 'package:cai_gameengine/api/exam.api.dart';
import 'package:cai_gameengine/api/module.api.dart';
import 'package:cai_gameengine/api/bucket.api.dart';

import 'package:cai_gameengine/services/filter_memory.service.dart';
import 'package:cai_gameengine/services/loading_dialog.service.dart';
import 'package:cai_gameengine/services/success_snackbar.service.dart';
import 'package:cai_gameengine/services/failure_dialog.service.dart';

import 'package:cai_gameengine/models/api_result.model.dart';
import 'package:cai_gameengine/models/login_session.model.dart';
import 'package:cai_gameengine/models/exam.model.dart';
import 'package:cai_gameengine/models/module.model.dart';
import 'package:cai_gameengine/models/lesson.model.dart';
import 'package:cai_gameengine/models/bucket.model.dart';

class DataExamPage extends StatefulWidget {
  const DataExamPage({super.key});

  @override
  State<DataExamPage> createState() => _DataExamPageState();
}

class _DataExamPageState extends State<DataExamPage> {
  List<ExamModel> exams = [];

  bool isLoading = false;

  final filterName = 'dat-exam';
  final filterMemory = FilterMemoryService();

  final ExpansionTileController _controller = ExpansionTileController();

  int? belockedSearchSelection;
  int? becancelledSearchSelection;
  int? docstatusSearchSelection;
  TextEditingController examcodeController = TextEditingController();

  ModuleModel? moduleSelection;
  TextEditingController moduleController = TextEditingController();
  LessonModel? lessonSelection;
  TextEditingController lessonController = TextEditingController();

  TextEditingController titleController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  TextEditingController descrController = TextEditingController();
  int? maturityratingSearchSelection;
  TextEditingController tagsController = TextEditingController();

  int? searchBelocked;
  int? searchBecancelled;
  int? searchDocstatus;
  String searchExamcode = '';
  ModuleModel? searchModule;
  LessonModel? searchLesson;
  String searchTitle = '';
  String searchCaption = '';
  String searchDescr = '';
  int? searchMaturityrating;
  String searchTags = '';

  int currentPage = 0;
  int totalExams = 0;

  final formatter = NumberFormat("#,##0.00", "en_US");

  late double cardWidth;

  late LoginSessionModel loginSession;
  late BoxConstraints globalConstraints;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();

    final LoadingDialogService loading = LoadingDialogService();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      loading.presentLoading(context);

      loginSession = context.read<LoginSessionModel>();

      await loadFilterMemory();

      // ignore: use_build_context_synchronously
      context.pop();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadFilterMemory() async {
    final String jsonMemory = await filterMemory.getFilterMemory(filterName);

    Map<dynamic, dynamic> memory = {};
    try {
      memory = jsonDecode(jsonMemory);
    } catch(err) {
      // not json
    }

    if(memory.keys.isNotEmpty) {
      try {
        belockedSearchSelection = memory['belocked'];
      } catch(err) {
        // belocked not found
      }
      try {
        becancelledSearchSelection = memory['becancelled'];
      } catch(err) {
        // becancelled not found
      }
      try {
        docstatusSearchSelection = memory['docstatus'];
      } catch(err) {
        // docstatus not found
      }
      try {
        examcodeController.text = memory['examcode'];
      } catch(err) {
        // examcode not found
      }
      try {
        int? moduleID = int.tryParse(memory['module']);
        if(moduleID != null) {
          final ModuleAPI moduleAPI = ModuleAPI();
          APIResult resModule = await moduleAPI.readOne(loginSession.token, moduleID);

          if(resModule.status == 1) {
            final ModuleModel module = resModule.result[0] as ModuleModel;

            moduleSelection = module;
            moduleController.text = module.modulecode;
          }
        }
      } catch(err) {
        // module not found
      }
      try {
        int? lessonID = int.tryParse(memory['module']);
        if(lessonID != null) {
          final ModuleAPI moduleAPI = ModuleAPI();
          APIResult resLesson = await moduleAPI.readLessonOne(loginSession.token, lessonID);

          if(resLesson.status == 1) {
            final LessonModel lesson = resLesson.result[0] as LessonModel;

            lessonSelection = lesson;
            lessonController.text = lesson.lessoncode;
          }
        }
      } catch(err) {
        // lesson not found
      }
      try {
        titleController.text = memory['title'];
      } catch(err) {
        // title not found
      }
      try {
        captionController.text = memory['caption'];
      } catch(err) {
        // caption not found
      }
      try {
        descrController.text = memory['descr'];
      } catch(err) {
        // descr not found
      }
      try {
        maturityratingSearchSelection = memory['maturityrating'];
      } catch(err) {
        // maturityrating not found
      }
      try {
        tagsController.text = memory['tags'];
      } catch(err) {
        // tags not found
      }

      setState(() {});
    }
  }

  saveFilterMemory() async {
    final memory = {};

    if(belockedSearchSelection != null) {
      memory.addAll({ 'belocked': belockedSearchSelection });
    }
    if(becancelledSearchSelection != null) {
      memory.addAll({ 'becancelled': becancelledSearchSelection });
    }
    if(docstatusSearchSelection != null) {
      memory.addAll({ 'docstatus': docstatusSearchSelection });
    }
    if(examcodeController.text.isNotEmpty) {
      memory.addAll({ 'examcode': examcodeController.text });
    }
    if(moduleSelection != null) {
      memory.addAll({ 'module': moduleSelection!.id });
    }
    if(lessonSelection != null) {
      memory.addAll({ 'lesson': lessonSelection!.id });
    }
    if(titleController.text.isNotEmpty) {
      memory.addAll({ 'title': titleController.text });
    }
    if(captionController.text.isNotEmpty) {
      memory.addAll({ 'caption': captionController.text });
    }
    if(descrController.text.isNotEmpty) {
      memory.addAll({ 'descr': descrController.text });
    }
    if(maturityratingSearchSelection != null) {
      memory.addAll({ 'maturityrating': maturityratingSearchSelection });
    }
    if(tagsController.text.isNotEmpty) {
      memory.addAll({ 'tags': tagsController.text });
    }

    await filterMemory.setFilterMemory(filterName, jsonEncode(memory));
  }

  getTotalExamCount() async {
    if(loginSession.token.isNotEmpty) {
      final ExamAPI examAPI = ExamAPI();

      APIResult resCount = await examAPI.readCount(loginSession.token, searchBelocked, searchBecancelled, searchDocstatus, searchExamcode, searchModule?.id, searchLesson?.id, searchTitle, searchCaption, searchDescr, searchMaturityrating, searchTags.split(','));
      if(resCount.status == 1 && resCount.result[0].RecordCount > 0) {
        totalExams = resCount.result[0].RecordCount;
      } else {
        if(mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }

      saveFilterMemory();
    }
  }

  loadModules() async {
    if(loginSession.token.isNotEmpty && totalExams > 0) {
      final ExamAPI examAPI = ExamAPI();

      currentPage++;
      APIResult resFilter = await examAPI.readFilter(loginSession.token, 10, currentPage, "", searchBelocked, searchBecancelled, searchDocstatus, searchExamcode, searchModule?.id, searchLesson?.id, searchTitle, searchCaption, searchDescr, searchMaturityrating, searchTags.split(','));
      if(resFilter.status == 1) {
        exams.addAll(resFilter.result as List<ExamModel>);
      }

      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    setState(() {
      colorScheme = Theme.of(context).colorScheme;
    });

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, BoxConstraints constraints) {
          globalConstraints = constraints;

          final isLg = globalConstraints.maxWidth > 992;
          final isMd = globalConstraints.maxWidth > 768;
          final isSm = globalConstraints.maxWidth > 576;

          final cardWidth = isLg ? globalConstraints.maxWidth * 0.5 : (isMd ? globalConstraints.maxWidth * 0.7 : (isSm ? globalConstraints.maxWidth * 0.8 : globalConstraints.maxWidth * 0.9));

          return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Text('แบบทดสอบ', style: TextStyle(fontSize: 36),),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        examDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        backgroundColor: colorScheme.primary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: colorScheme.onPrimary,),
                          Text(' เพิ่มแบบทดสอบ', style: TextStyle(fontSize: 16, color: colorScheme.onPrimary,),),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10, bottom: 0, right: 10),
                  child: SizedBox(
                    width: cardWidth,
                    child: ExpansionTile(
                      controller: _controller,
                      initiallyExpanded: true,
                      maintainState: true,
                      collapsedBackgroundColor: colorScheme.primaryContainer,
                      onExpansionChanged: (state) { },
                      childrenPadding: const EdgeInsets.all(0),
                      title: Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 5,),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 22, color: colorScheme.onPrimaryContainer,),
                            Text(' ตัวเลือกการค้นหา', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                          ],
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: DropdownButtonFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'สถานะการใช้งาน',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      belockedSearchSelection = value;
                                    });
                                  },
                                  value: belockedSearchSelection,
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('ทั้งหมด'),
                                    ),
                                    DropdownMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          Icon(Icons.lock_open, color: colorScheme.brightness == Brightness.light ? const Color( 0xFF009000 ) : const Color( 0xFF0FF000 ),),
                                          const Text(' ปกติ'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Row(
                                        children: [
                                          Icon(Icons.lock_outline, color: colorScheme.error),
                                          const Text(' ถูกระงับ'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: DropdownButtonFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'สถานะการยกเลิก',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      becancelledSearchSelection = value;
                                    });
                                  },
                                  value: becancelledSearchSelection,
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('ทั้งหมด'),
                                    ),
                                    DropdownMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_sharp, color: colorScheme.brightness == Brightness.light ? const Color( 0xFF009000 ) : const Color( 0xFF0FF000 ),),
                                          const Text(' ปกติ'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel, color: colorScheme.error),
                                          const Text(' ถูกยกเลิก'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: DropdownButtonFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'สถานะเอกสาร',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      docstatusSearchSelection = value;
                                    });
                                  },
                                  value: docstatusSearchSelection,
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('ทั้งหมด'),
                                    ),
                                    ...DocStatus.entries.map((docStatus) {
                                      return DropdownMenuItem(
                                        value: docStatus.key,
                                        child: Text(docStatus.value),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: TextFormField(
                                  controller: examcodeController,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'หมายเลขแบบทดสอบ',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    onSearchFormSubmit();
                                  },
                                  textInputAction: TextInputAction.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: TextFormField(
                                  controller: moduleController,
                                  autocorrect: false,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'โมดูล',
                                    border: const OutlineInputBorder(),
                                    floatingLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: const TextStyle(fontSize: 14, height: 0.8),
                                    icon: IconButton(
                                      onPressed: () async {
                                        final ModuleModel? module = await showDialog<ModuleModel>(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return const ModuleSelector();
                                          },
                                        ).then((value) => value);

                                        if(module != null) {
                                          setState(() {
                                            moduleSelection = module;
                                            moduleController.text = module.modulecode;
                                          });
                                        }
                                      },
                                      color: colorScheme.primary,
                                      icon: const Icon(Icons.view_module),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: moduleSelection == null ?
                                        null :
                                        () {
                                          setState(() {
                                            moduleSelection = null;
                                            moduleController.text = '';

                                            lessonSelection = null;
                                            lessonController.text = '';
                                          });
                                        },
                                      icon: const Icon(Icons.clear),
                                    ),
                                  ),
                                  onFieldSubmitted: (value) {
                                    onSearchFormSubmit();
                                  },
                                  textInputAction: TextInputAction.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: TextFormField(
                                  controller: lessonController,
                                  autocorrect: false,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'บทเรียน',
                                    border: const OutlineInputBorder(),
                                    floatingLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: const TextStyle(fontSize: 14, height: 0.8),
                                    icon: IconButton(
                                      tooltip: moduleSelection == null ? 'กรุณาเลือกโมดูลก่อนเลือกบทเรียน' : null,
                                      onPressed: moduleSelection == null ? null : () async {
                                        final LessonModel? lesson = await showDialog<LessonModel>(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return LessonSelector(inModuleID: moduleSelection!.id);
                                          },
                                        ).then((value) => value);

                                        if(lesson != null) {
                                          setState(() {
                                            lessonSelection = lesson;
                                            lessonController.text = lesson.lessoncode;
                                          });
                                        }
                                      },
                                      color: colorScheme.primary,
                                      icon: const Icon(Icons.quiz),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: lessonSelection == null ?
                                        null :
                                        () {
                                          setState(() {
                                            lessonSelection = null;
                                            lessonController.text = '';
                                          });
                                        },
                                      icon: const Icon(Icons.clear),
                                    ),
                                  ),
                                  onFieldSubmitted: (value) {
                                    onSearchFormSubmit();
                                  },
                                  textInputAction: TextInputAction.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: TextFormField(
                                  controller: titleController,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'หัวข้อ',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    onSearchFormSubmit();
                                  },
                                  textInputAction: TextInputAction.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: TextFormField(
                                  controller: captionController,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'คำชี้แจง',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    onSearchFormSubmit();
                                  },
                                  textInputAction: TextInputAction.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: TextFormField(
                                  controller: descrController,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'รายละเอียด',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    onSearchFormSubmit();
                                  },
                                  textInputAction: TextInputAction.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: DropdownButtonFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'ระดับวัยที่เหมาะสม',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      maturityratingSearchSelection = value;
                                    });
                                  },
                                  value: maturityratingSearchSelection,
                                  items: [
                                    const DropdownMenuItem(
                                      value: 0,
                                      child: Text('ทั้งหมด'),
                                    ),
                                    ...MaturityRating.entries.map((docStatus) {
                                      return DropdownMenuItem(
                                        value: docStatus.key,
                                        child: Text(docStatus.value),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: TextFormField(
                                  controller: tagsController,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'ป้ายกำกับ',
                                    border: OutlineInputBorder(),
                                    floatingLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    errorStyle: TextStyle(fontSize: 14, height: 0.8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    onSearchFormSubmit();
                                  },
                                  textInputAction: TextInputAction.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15, bottom: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
                                      ),
                                      onPressed: () {
                                        onSearchFormSubmit();
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.search, size: 22, color: colorScheme.onPrimary,),
                                          Text(' ค้นหา', style: TextStyle(fontSize: 20, color: colorScheme.onPrimary,),),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.secondary,
                                        padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
                                      ),
                                      onPressed: () {
                                        belockedSearchSelection = null;
                                        becancelledSearchSelection = null;
                                        docstatusSearchSelection = null;
                                        examcodeController.clear();

                                        moduleSelection = null;
                                        moduleController.clear();
                                        lessonSelection = null;
                                        lessonController.clear();

                                        titleController.clear();
                                        captionController.clear();
                                        descrController.clear();
                                        maturityratingSearchSelection = null;
                                        tagsController.clear();

                                        clearSearch();
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.replay_outlined, size: 22, color: colorScheme.onSecondary,),
                                          Text(' ล้างค่า', style: TextStyle(fontSize: 20, color: colorScheme.onSecondary,),),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 3,),
                  child: SizedBox(
                    width: cardWidth,
                    child: Column(
                      children: [
                        Wrap(
                          direction: Axis.horizontal,
                          runSpacing: 3,
                          children: [
                            SearchCriteriaChip(
                              visible: searchBelocked != null,
                              children: [
                                Text('สถานะการใช้งาน: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Icon(searchBelocked != null && searchBelocked == 0 ? Icons.lock_open : Icons.lock_rounded, size: 14, color: searchBelocked != null && searchBelocked == 0 ? (colorScheme.brightness == Brightness.light ? const Color( 0xFF009000 ) : const Color( 0xFF0FF000 )): const Color( 0xFFFF0000 ),),
                                Text(searchBelocked != null && searchBelocked == 0 ? ' ปกติ' : ' ถูกระงับ', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchBecancelled != null,
                              children: [
                                Text('สถานะการยกเลิก: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Icon(searchBelocked != null && searchBelocked == 0 ? Icons.check : Icons.cancel, size: 14, color: searchBelocked != null && searchBelocked == 0 ? (colorScheme.brightness == Brightness.light ? const Color( 0xFF009000 ) : const Color( 0xFF0FF000 )): const Color( 0xFFFF0000 ),),
                                Text(searchBecancelled != null && searchBecancelled == 0 ? ' ปกติ' : ' ถูกยกเลิก', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchDocstatus != null,
                              children: [
                                Text('สถานะเอกสาร: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text(searchDocstatus != null ? DocStatus.entries.firstWhere((e) => e.key == searchDocstatus).value : '', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchExamcode.isNotEmpty,
                              children: [
                                Text('รหัสแบบทดสอบ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text('"$searchExamcode"', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchModule != null,
                              children: [
                                Text('โมดูล: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text(searchModule != null ? searchModule!.modulecode : '', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchLesson != null,
                              children: [
                                Text('บทเรียน: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text(searchLesson != null ? searchLesson!.lessoncode : '', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchTitle.isNotEmpty,
                              children: [
                                Text('หัวข้อ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text('"$searchTitle"', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchCaption.isNotEmpty,
                              children: [
                                Text('คำชี้แจง: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text('"$searchCaption"', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchDescr.isNotEmpty,
                              children: [
                                Text('รายละเอียด: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text('"$searchDescr"', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchMaturityrating != null,
                              children: [
                                Text('ระดับวัยที่เหมาะสม: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text(searchMaturityrating != null ? MaturityRating.entries.firstWhere((e) => e.key == searchMaturityrating).value : '', style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                            SearchCriteriaChip(
                              visible: searchTags.isNotEmpty,
                              children: [
                                Text('ป้ายกำกับ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onTertiary,),),
                                Text(searchTags, style: TextStyle(fontSize: 12, color: colorScheme.onTertiary,),)
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (BuildContext context) {
                          if(exams.isNotEmpty) {
                            return Flex(
                              direction: Axis.vertical,
                              children: buildExamList(exams, cardWidth),
                            );
                          } else if(!isLoading) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: cardWidth,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('ไม่พบแบบทดสอบตามเงื่อนไขการค้นหา', style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 18))
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                      Visibility(
                        visible: isLoading,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (BuildContext context) {
                          if(totalExams > 0 && exams.length < totalExams) {
                            return VisibilityDetector(
                              key: const Key('ModuleInfiniteScroll'),
                              onVisibilityChanged: (visibilityInfo) {
                                var visiblePercentage = visibilityInfo.visibleFraction * 100;

                                if(visiblePercentage > 50) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  loadModules();
                                }
                              },
                              child: const SizedBox(width: 100, height: 50,),
                            );
                          } else {
                            return Container();
                          }
                        }
                      ),
                    ],
                  ),
                ),
              ],
            );
        }
      ),
    );
  }

  onSearchFormSubmit() {
    searchRecipeSubmit(
      belockedSearchSelection,
      becancelledSearchSelection,
      docstatusSearchSelection,
      examcodeController.value.text,
      moduleSelection,
      lessonSelection,
      titleController.value.text,
      captionController.value.text,
      descrController.value.text,
      maturityratingSearchSelection,
      tagsController.value.text
    );
  }

  Future<Widget> getCover(String bucketid, String name) async {
    final BucketAPI bucketAPI = BucketAPI();
    final APIResult res = await bucketAPI.readOne(loginSession.token, bucketid);

    if(res.status == 1) {
      final bucket = res.result[0] as BucketModel;

      final Uint8List  mediaBytes = bucket.bucketdata.data;
      return ImageThumbnailWidget(image: Image.memory(mediaBytes), title: name);
    } else {
      return ImageThumbnailWidget(image: Image.asset('assets/images/default_picture.png',), title: name);
    }
  }

  Future<String> getModuleCode(int id) async {
    final ModuleAPI moduleAPI = ModuleAPI();

    if(id != 0) {
      APIResult resBom = await moduleAPI.readOne(loginSession.token, id);
      if(resBom.status == 1) {
        return (resBom.result[0] as ModuleModel).modulecode;
      } else {
        return '(ไม่พบข้อมูลโมดูล)';
      }
    } else {
      return '-';
    }
  }

  Future<String> getLessonCode(int id) async {
    final ModuleAPI moduleAPI = ModuleAPI();

    if(id != 0) {
      APIResult resBom = await moduleAPI.readLessonOne(loginSession.token, id);
      if(resBom.status == 1) {
        return (resBom.result[0] as LessonModel).lessoncode;
      } else {
        return '(ไม่พบข้อมูลบทเรียน)';
      }
    } else {
      return '-';
    }
  }

  List<Widget> buildExamList(List<ExamModel> examList, double cardWidth) {
    List<Widget> examWidgetList = [];

    final TextStyle nameStyle = TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 17);

    final Duration timezoneOffset = DateTime.now().timeZoneOffset;

    for(final exam in examList) {
      Future<Widget> coverWidget;
      if(exam.coverid != null && exam.coverid!.isNotEmpty) {
        coverWidget = getCover(exam.coverid!, exam.title);
      } else {
        coverWidget = Future.value(ImageThumbnailWidget(image: Image.asset('assets/images/default_picture.png',), title: exam.title));
      }

      Future<String> moduleCode = getModuleCode(exam.module_id);
      Future<String> lessonCode = getLessonCode(exam.lesson_id);

      examWidgetList.addAll([
        Container(
          width: cardWidth,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: FutureBuilder<Widget>(
                                  future: coverWidget,
                                  builder: (context, AsyncSnapshot mediaSnapshot) {
                                    if(mediaSnapshot.hasData) {
                                      return mediaSnapshot.data!;
                                    } else {
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: CircularProgressIndicator(
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  }
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            child: Text(exam.title, style: const TextStyle(fontSize: 17,),),
                          )
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        exam.becancelled ?
                          Icon(Icons.cancel, color: colorScheme.error) :
                          (!exam.belocked ?
                          Icon(Icons.lock_open, color: colorScheme.brightness == Brightness.light ? const Color( 0xFF009000 ) : const Color( 0xFF0FF000 ),) :
                          Icon(Icons.lock_outline, color: colorScheme.error)),
                        const SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 0.5,
                color: colorScheme.onSurface,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('รหัสแบบทดสอบ', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(exam.examcode, style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('คำชี้แจง', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(exam.caption, style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 0.5,
                color: colorScheme.onSurface,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('รายละเอียด', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(exam.descr ?? '-', style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 0.5,
                color: colorScheme.onSurface,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('รหัสโมดูล', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        FutureBuilder<String>(
                          future: moduleCode,
                          builder: (BuildContext context, AsyncSnapshot<String> modulecodeSnapshot) {
                            if(modulecodeSnapshot.hasData) {
                              return Row(
                                children: [
                                  Text(modulecodeSnapshot.data!, style: const TextStyle(fontSize: 14,),),
                                ],
                              );
                            } else {
                              return const Text('-', style: TextStyle(fontSize: 14,),);
                            }
                          }
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('รหัสบทเรียน', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        FutureBuilder<String>(
                          future: lessonCode,
                          builder: (BuildContext context, AsyncSnapshot<String> lessoncodeSnapshot) {
                            if(lessoncodeSnapshot.hasData) {
                              return Row(
                                children: [
                                  Text(lessoncodeSnapshot.data!, style: const TextStyle(fontSize: 14,),),
                                ],
                              );
                            } else {
                              return const Text('-', style: TextStyle(fontSize: 14,),);
                            }
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 0.5,
                color: colorScheme.onSurface,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('เวลาสอบ (นาที)', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(exam.examminute > 0 ? exam.examminute.toString() : 'ไม่กำหนดเวลา', style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('คะแนนเต็ม', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(exam.maxscore.toString(), style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 0.5,
                color: colorScheme.onSurface,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('วันเวลาที่สร้าง', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(exam.created_at).add(timezoneOffset)), style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('วันเวลาที่แก้ไขล่าสุด', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(exam.updated_at != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(exam.updated_at!).add(timezoneOffset)) : '-', style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 0.5,
                color: colorScheme.onSurface,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('สถานะ', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(DocStatus.entries.firstWhere((e) => e.key == exam.docstatus).value, style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('วันที่เผยแพร่', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(exam.released_at != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(exam.released_at!).add(timezoneOffset)) : '-', style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 0.5,
                color: colorScheme.onSurface,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ระดับวัยที่เหมาะสม', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        Text(MaturityRating.entries.firstWhere((e) => e.key == exam.maturityrating).value, style: const TextStyle(fontSize: 14,),),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 0.5,
                color: colorScheme.onSurface,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ป้ายกำกับ', style: TextStyle(color: colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),),
                        exam.tags.isNotEmpty ?
                          Wrap(
                            runSpacing: 3,
                            children: [
                              ...exam.tags.map((e) => TagChip(tag: e)) 
                            ],
                          ) :
                          const SizedBox(
                            height: 20,
                          )
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 1,
                color: colorScheme.onSurface,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      context.go('/data/exam/${exam.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                      backgroundColor: colorScheme.secondary,
                    ),
                    child: Icon(Icons.menu_book, color: colorScheme.onSecondary,),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      examDialog(examID: exam.id);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                      backgroundColor: colorScheme.primary,
                    ),
                    child: Icon(Icons.edit_square, color: colorScheme.onPrimary,),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      confirmDeleteExamDialog(exam);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                      backgroundColor: colorScheme.error,
                    ),
                    child: Icon(Icons.delete_forever_rounded, color: colorScheme.onError,),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 25,
        ),
      ]);
    }

    return examWidgetList;
  }

  searchRecipeSubmit(
    int? formBelocked,
    int? formCancelled,
    int? formDocstatus,
    String formExamcode,
    ModuleModel? formModule,
    LessonModel? formLesson,
    String formTitle,
    String formCaption,
    String formDescr,
    int? formMaturityrating,
    String formTags
  ) async {
    searchBelocked = formBelocked;
    searchBecancelled = formCancelled;
    searchDocstatus = formDocstatus;
    searchExamcode = formExamcode;
    searchModule = formModule;
    searchLesson = formLesson;
    searchTitle = formTitle;
    searchCaption = formCaption;
    searchDescr = formDescr;
    searchMaturityrating = formMaturityrating;
    searchTags = formTags;

    setState(() {
      isLoading = true;
    });
    
    currentPage = 0;
    totalExams = 0;
    exams = [];

    _controller.collapse();

    await getTotalExamCount();
    await loadModules();
  }

  clearSearch() async {
    searchBelocked = null;
    searchBecancelled = null;
    searchDocstatus = null;
    searchExamcode = '';
    searchModule = null;
    searchLesson = null;
    searchTitle = '';
    searchCaption = '';
    searchDescr = '';
    searchMaturityrating = null;
    searchTags = '';

    setState(() {
      isLoading = true;
    });
    
    currentPage = 0;
    totalExams = 0;
    exams = [];

    _controller.collapse();

    await getTotalExamCount();
    await loadModules();
  }

  examDialog({int? examID}) async {
    final isSuccess = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return ExamDialog(inExamID: examID);
      },
    );

    if(isSuccess != null && isSuccess) {
      onSearchFormSubmit();
    }
  }

  confirmDeleteExamDialog(ExamModel inExam) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, size: 30, color: colorScheme.error,),
            const Text(' ลบแบบทดสอบ', style: TextStyle(fontSize: 30,),),
          ],
        ),
        content: Text('ต้องการลบแบบทดสอบ "${inExam.title}" ออกจากระบบหรือไม่', style: const TextStyle(fontSize: 20,),),
        buttonPadding: const EdgeInsets.all(25),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
            ),
            onPressed: () async {
              final LoadingDialogService loading = LoadingDialogService();
              loading.presentLoading(context);

              final BucketAPI bucketAPI = BucketAPI();

              if(inExam.coverid != null && inExam.coverid!.isNotEmpty) {
                // ignore: unused_local_variable
                APIResult resBucket = await bucketAPI.deleteOne(loginSession.token, inExam.coverid!);
              }

              final ExamAPI examAPI = ExamAPI();

              APIResult res = await examAPI.deleteOne(loginSession.token, inExam.id);

              // ignore: use_build_context_synchronously
              context.pop();
              // ignore: use_build_context_synchronously
              context.pop();
              
              if(res.status == 1) {
                totalExams--;

                setState(() {
                  exams.retainWhere((module) => module.id != inExam.id);
                });

                SuccessSnackBar snack = SuccessSnackBar();

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(snack.showSuccess('ลบแบบทดสอบออกจากระบบเรียบร้อยแล้ว', globalConstraints, colorScheme));
              } else {
                final FailureDialog failureDialog = FailureDialog();

                // ignore: use_build_context_synchronously
                failureDialog.showFailure(context, colorScheme, res.message);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever_rounded, size: 22, color: colorScheme.onError,),
                Text(' ลบ', style: TextStyle(fontSize: 20, color: colorScheme.onError,),),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
            ),
            onPressed: () => context.pop(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_circle_right_outlined, size: 22, color: colorScheme.onSecondary,),
                Text(' ถอยกลับ', style: TextStyle(fontSize: 20, color: colorScheme.onSecondary,),),
              ],
            ),
          ),
        ],
      ),
    );
  }

}