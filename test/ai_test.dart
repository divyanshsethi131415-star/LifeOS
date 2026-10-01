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
}
