import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'models.dart';

class LifeStore extends ChangeNotifier {
  final LifeDatabase db;
  final SharedPreferencesAsync prefs;
  LifeStore({LifeDatabase? database,SharedPreferencesAsync? preferences})
      : db=database??LifeDatabase.instance,prefs=preferences??SharedPreferencesAsync();

  String userName='there';
  bool onboardingComplete=false;
  List<Task> tasks=[];
  List<Goal> goals=[];
  List<Habit> habits=[];
  List<Project> projects=[];
  List<Note> notes=[];
  List<Idea> ideas=[];

  Future<void> load() async {
    userName=await prefs.getString('name')??'there';
    onboardingComplete=await prefs.getBool('onboarding_complete')??false;
    tasks=(await db.all('tasks',orderBy:'due_at ASC')).map(Task.fromMap).toList();
    goals=(await db.all('goals',orderBy:'deadline ASC')).map(Goal.fromMap).toList();
    habits=(await db.all('habits',orderBy:'created_at DESC')).map(Habit.fromMap).toList();
    projects=(await db.all('projects',orderBy:'created_at DESC')).map(Project.fromMap).toList();
    notes=(await db.all('notes',orderBy:'updated_at DESC')).map(Note.fromMap).toList();
    ideas=(await db.all('ideas',orderBy:'created_at DESC')).map(Idea.fromMap).toList();
    notifyListeners();
  }

  Future<void> finishOnboarding(String name,{bool demo=false}) async {
    userName=name.trim().isEmpty?'there':name.trim();
    onboardingComplete=true;
    await prefs.setString('name',userName);
    await prefs.setBool('onboarding_complete',true);
    if(demo && tasks.isEmpty) await seedDemo();
    notifyListeners();
  }

  Future<void> seedDemo() async {
    final now=DateTime.now();
    await addTask('Review today priorities',dueAt:DateTime(now.year,now.month,now.day,9),priority:Priority.high,category:'School');
    await addTask('Build the Life OS first module',dueAt:now.add(const Duration(hours:2)),priority:Priority.critical,category:'Coding');
    await addTask('Plan tomorrow',dueAt:DateTime(now.year,now.month,now.day,20),priority:Priority.low);
    await addGoal('Build a reliable study system','Academic',progress:35,deadline:now.add(const Duration(days:30)));
    await addHabit('Read for 20 minutes','📖');
    await addProject('Life OS','All-in-one personal productivity system');
    await addNote('Welcome to Life OS','Capture context here. Keep important information local and searchable.','welcome,system');
    await load();
  }

  Future<void> addTask(String title,{String description='',DateTime? dueAt,Priority priority=Priority.medium,String category='Personal',DateTime? reminderAt,int? projectId}) async {
    final item=Task(id:await db.nextId('tasks'),title:title.trim(),description:description.trim(),dueAt:dueAt,priority:priority,category:category,reminderAt:reminderAt,projectId:projectId,createdAt:DateTime.now());
    await db.save('tasks',item.toMap()); tasks=[item,...tasks]; notifyListeners();
  }
  Future<void> toggleTask(Task task) async {
    final next=task.copyWith(completed:!task.completed); await db.save('tasks',next.toMap());
    tasks=tasks.map((x)=>x.id==task.id?next:x).toList(); notifyListeners();
  }
  Future<void> deleteTask(Task task) async { await db.delete('tasks',task.id); tasks=tasks.where((x)=>x.id!=task.id).toList(); notifyListeners(); }

  Future<void> addGoal(String name,String category,{DateTime? deadline,int progress=0}) async {
    final item=Goal(id:await db.nextId('goals'),name:name.trim(),category:category,deadline:deadline,progress:progress,createdAt:DateTime.now());
    await db.save('goals',item.toMap()); goals=[item,...goals]; notifyListeners();
  }
  Future<void> updateGoal(Goal goal,int progress) async {
    final next=goal.copyWith(progress:progress.clamp(0,100)); await db.save('goals',next.toMap());
    goals=goals.map((x)=>x.id==goal.id?next:x).toList(); notifyListeners();
  }

  Future<void> addHabit(String name,String icon) async {
    final item=Habit(id:await db.nextId('habits'),name:name.trim(),icon:icon,createdAt:DateTime.now());
    await db.save('habits',item.toMap()); habits=[item,...habits]; notifyListeners();
  }
  Future<void> toggleHabit(Habit habit,DateTime day) async {
    final next=habit.toggled(day); await db.save('habits',next.toMap());
    habits=habits.map((x)=>x.id==habit.id?next:x).toList(); notifyListeners();
  }

  Future<void> addProject(String name,String description) async {
    final item=Project(id:await db.nextId('projects'),name:name.trim(),description:description.trim(),createdAt:DateTime.now());
    await db.save('projects',item.toMap()); projects=[item,...projects]; notifyListeners();
  }
  Future<void> addNote(String title,String body,String tags) async {
    final item=Note(id:await db.nextId('notes'),title:title.trim(),body:body.trim(),tags:tags.trim(),updatedAt:DateTime.now());
    await db.save('notes',item.toMap()); notes=[item,...notes]; notifyListeners();
  }
  Future<void> addIdea(String title,String description) async {
    final item=Idea(id:await db.nextId('ideas'),title:title.trim(),description:description.trim(),createdAt:DateTime.now());
    await db.save('ideas',item.toMap()); ideas=[item,...ideas]; notifyListeners();
  }

  bool sameDay(DateTime? a,DateTime b)=>a!=null&&a.year==b.year&&a.month==b.month&&a.day==b.day;
  int get dueToday=>tasks.where((t)=>!t.completed&&sameDay(t.dueAt,DateTime.now())).length;
  int get overdue=>tasks.where((t)=>!t.completed&&t.dueAt!=null&&t.dueAt!.isBefore(DateTime.now())).length;
  double get completionRate=>tasks.isEmpty?0:tasks.where((t)=>t.completed).length/tasks.length;

  String exportJson()=>jsonEncode({'version':1,'name':userName,'tasks':tasks.map((x)=>x.toMap()).toList(),'goals':goals.map((x)=>x.toMap()).toList(),'habits':habits.map((x)=>x.toMap()).toList(),'projects':projects.map((x)=>x.toMap()).toList(),'notes':notes.map((x)=>x.toMap()).toList(),'ideas':ideas.map((x)=>x.toMap()).toList()});

  Future<void> importJson(String raw) async {
    final data=jsonDecode(raw) as Map<String,dynamic>;
    await db.clearAll();
    for(final e in (data['tasks'] as List? ?? const [])) await db.save('tasks',Map<String,Object?>.from(e as Map));
    for(final e in (data['goals'] as List? ??const [])) await db.save('goals',Map<String,Object?>.from(e as Map));
    for(final e in (data['habits'] as List? ??const [])) await db.save('habits',Map<String,Object?>.from(e as Map));
    for(final e in (data['projects'] as List? ??const [])) await db.save('projects',Map<String,Object?>.from(e as Map));
    for(final e in (data['notes'] as List? ??const [])) await db.save('notes',Map<String,Object?>.from(e as Map));
    for(final e in (data['ideas'] as List? ??const [])) await db.save('ideas',Map<String,Object?>.from(e as Map));
    await load();
  }
}
