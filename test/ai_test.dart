import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/ai.dart';
import 'package:life_os/models.dart';

void main(){
  final now=DateTime.now();
  final tasks=[
    Task(id:1,title:'Finish maths',dueAt:now,priority:Priority.high,createdAt:now),
    Task(id:2,title:'Old task',dueAt:now.subtract(const Duration(days:1)),createdAt:now),
  ];

  test('AI detects overdue tasks',(){
    final r=LifeAi().ask('what is overdue?',tasks,[],[],[]);
    expect(r.text,contains('1 overdue'));
    expect(r.text,contains('Old task'));
  });

  test('AI creates an actionable breakdown',(){
    final r=LifeAi().ask('break down my coding task',tasks,[],[],[]);
    expect(r.steps.length,4);
    expect(r.steps.first,contains('outcome'));
  });

  test('AI plans today',(){
    final r=LifeAi().ask('plan my day',tasks,[],[],[]);
    expect(r.text,contains('Finish maths'));
  });
  test('AI handles empty prompt safely',(){
    final r=LifeAi().ask('',tasks,[],[],[]);
    expect(r.text,contains('organize'));
  });

  test('AI summarizes goal and habit state',(){
    final goal=Goal(id:1,name:'Learn Flutter',progress:40,createdAt:now);
    final habit=Habit(id:1,name:'Read',createdAt:now);
    expect(LifeAi().ask('show my goals',tasks,[goal],[habit],[]).text,contains('Learn Flutter'));
    expect(LifeAi().ask('show my habits',tasks,[goal],[habit],[]).text,contains('Read'));
  });

  test('AI reports note context and statistics',(){
    final note=Note(id:1,title:'Ideas',body:'Build a calmer dashboard',updatedAt:now);
    expect(LifeAi().ask('summarize notes',tasks,[],[],[note]).text,contains('Ideas'));
    expect(LifeAi().ask('stats',tasks,[],[],[note]).text,contains('Tasks 2'));
  });
}
