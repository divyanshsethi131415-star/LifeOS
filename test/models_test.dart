import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/models.dart';

void main(){
  test('task survives a map round trip',(){
    final d=DateTime(2026,10,1,10,30);
    final original=Task(id:7,title:'Exam prep',description:'Chapters 1-3',dueAt:d,priority:Priority.critical,category:'School',createdAt:d);
    final copy=Task.fromMap(original.toMap());
    expect(copy.id,7);
    expect(copy.title,'Exam prep');
    expect(copy.description,'Chapters 1-3');
    expect(copy.priority,Priority.critical);
    expect(copy.dueAt,d);
  });

  test('habit streak counts consecutive dates',(){
    final today=DateTime.now();
    final previous=today.subtract(const Duration(days:1));
    final h=Habit(id:1,name:'Read',completedDays:[Habit.key(today),Habit.key(previous)],createdAt:today);
    expect(h.currentStreak,2);
  });
}
