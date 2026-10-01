import 'dart:convert';

enum Priority { low, medium, high, critical }
enum ProjectStatus { planning, active, paused, completed, archived }
enum HabitFrequency { daily, weekly, custom }
enum IdeaStatus { newIdea, developing, started, completed, abandoned }

String enumValue(Object value) => value.toString().split('.').last;

T enumFrom<T extends Enum>(Iterable<T> values, String raw, T fallback) {
  for (final value in values) {
    if (enumValue(value) == raw) return value;
  }
  return fallback;
}

class Task {
  final int id;
  final String title;
  final String description;
  final DateTime? dueAt;
  final Priority priority;
  final String category;
  final int? projectId;
  final DateTime? reminderAt;
  final bool completed;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueAt,
    this.priority = Priority.medium,
    this.category = 'Personal',
    this.projectId,
    this.reminderAt,
    this.completed = false,
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueAt,
    Priority? priority,
    String? category,
    int? projectId,
    DateTime? reminderAt,
    bool? completed,
  }) => Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueAt: dueAt ?? this.dueAt,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        projectId: projectId ?? this.projectId,
        reminderAt: reminderAt ?? this.reminderAt,
        completed: completed ?? this.completed,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'due_at': dueAt?.millisecondsSinceEpoch,
        'priority': enumValue(priority),
        'category': category,
        'project_id': projectId,
        'reminder_at': reminderAt?.millisecondsSinceEpoch,
        'completed': completed ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, Object?> m) => Task(
        id: m['id']! as int,
        title: m['title'] as String,
        description: (m['description'] as String?) ?? '',
        dueAt: m['due_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(m['due_at']! as int),
        priority: enumFrom(Priority.values, m['priority'] as String? ?? 'medium', Priority.medium),
        category: (m['category'] as String?) ?? 'Personal',
        projectId: m['project_id'] as int?,
        reminderAt: m['reminder_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(m['reminder_at']! as int),
        completed: (m['completed'] as int? ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
      );
}

class Goal {
  final int id;
  final String name;
  final String category;
  final DateTime? deadline;
  final int progress;
  final DateTime createdAt;

  const Goal({required this.id, required this.name, this.category='Personal', this.deadline, this.progress=0, required this.createdAt});

  Goal copyWith({String? name, String? category, DateTime? deadline, int? progress}) => Goal(
    id: id, name: name ?? this.name, category: category ?? this.category,
    deadline: deadline ?? this.deadline, progress: progress ?? this.progress, createdAt: createdAt,
  );

  Map<String,Object?> toMap()=>{'id':id,'name':name,'category':category,'deadline':deadline?.millisecondsSinceEpoch,'progress':progress,'created_at':createdAt.millisecondsSinceEpoch};
  factory Goal.fromMap(Map<String,Object?> m)=>Goal(
    id:m['id']! as int,name:m['name'] as String,category:(m['category'] as String?)??'Personal',
    deadline:m['deadline']==null?null:DateTime.fromMillisecondsSinceEpoch(m['deadline']! as int),
    progress:(m['progress'] as int?)??0,createdAt:DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int));
}

class Habit {
  final int id;
  final String name;
  final String icon;
  final HabitFrequency frequency;
  final List<String> completedDays;
  final DateTime createdAt;

  const Habit({required this.id,required this.name,this.icon='✓',this.frequency=HabitFrequency.daily,this.completedDays=const [],required this.createdAt});

  static String key(DateTime d) => '${d.year}-${d.month}-${d.day}';
  bool isDoneOn(DateTime d)=>completedDays.contains(key(d));
  Habit toggled(DateTime d){
    final next=[...completedDays]; final k=key(d);
    next.contains(k)?next.remove(k):next.add(k);
    return Habit(id:id,name:name,icon:icon,frequency:frequency,completedDays:next,createdAt:createdAt);
  }
  int get currentStreak{
    var cursor=DateTime.now(); var n=0;
    while(isDoneOn(cursor)){n++; cursor=cursor.subtract(const Duration(days:1));}
    return n;
  }
  Map<String,Object?> toMap()=>{'id':id,'name':name,'icon':icon,'frequency':enumValue(frequency),'completed_days':jsonEncode(completedDays),'created_at':createdAt.millisecondsSinceEpoch};
  factory Habit.fromMap(Map<String,Object?> m)=>Habit(
    id:m['id']! as int,name:m['name'] as String,icon:(m['icon'] as String?)??'✓',
    frequency:enumFrom(HabitFrequency.values,m['frequency'] as String? ?? 'daily',HabitFrequency.daily),
    completedDays:List<String>.from(jsonDecode((m['completed_days'] as String?)??'[]') as List),
    createdAt:DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int));
}

class Project {
  final int id; final String name; final String description; final ProjectStatus status; final int progress; final DateTime createdAt;
  const Project({required this.id,required this.name,this.description='',this.status=ProjectStatus.active,this.progress=0,required this.createdAt});
  Map<String,Object?> toMap()=>{'id':id,'name':name,'description':description,'status':enumValue(status),'progress':progress,'created_at':createdAt.millisecondsSinceEpoch};
  factory Project.fromMap(Map<String,Object?> m)=>Project(id:m['id']! as int,name:m['name'] as String,description:(m['description'] as String?)??'',status:enumFrom(ProjectStatus.values,m['status'] as String? ?? 'active',ProjectStatus.active),progress:(m['progress'] as int?)??0,createdAt:DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int));
}

class Note {
  final int id; final String title; final String body; final String tags; final DateTime updatedAt;
  const Note({required this.id,required this.title,required this.body,this.tags='',required this.updatedAt});
  Map<String,Object?> toMap()=>{'id':id,'title':title,'body':body,'tags':tags,'updated_at':updatedAt.millisecondsSinceEpoch};
  factory Note.fromMap(Map<String,Object?> m)=>Note(id:m['id']! as int,title:m['title'] as String,body:m['body'] as String,tags:(m['tags'] as String?)??'',updatedAt:DateTime.fromMillisecondsSinceEpoch(m['updated_at']! as int));
}

class Idea {
  final int id; final String title; final String description; final IdeaStatus status; final DateTime createdAt;
  const Idea({required this.id,required this.title,this.description='',this.status=IdeaStatus.newIdea,required this.createdAt});
  Map<String,Object?> toMap()=>{'id':id,'title':title,'description':description,'status':enumValue(status),'created_at':createdAt.millisecondsSinceEpoch};
  factory Idea.fromMap(Map<String,Object?> m)=>Idea(id:m['id']! as int,title:m['title'] as String,description:(m['description'] as String?)??'',status:enumFrom(IdeaStatus.values,m['status'] as String? ?? 'newIdea',IdeaStatus.newIdea),createdAt:DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int));
}
