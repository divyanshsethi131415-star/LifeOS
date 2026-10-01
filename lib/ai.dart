import 'models.dart';

class AiReply {
  final String text;
  final List<String> steps;
  const AiReply(this.text,{this.steps=const []});
}

class LifeAi {
  AiReply ask(String prompt,List<Task> tasks,List<Goal> goals,List<Habit> habits,List<Note> notes) {
    final q=prompt.trim().toLowerCase();
    if(q.isEmpty) return const AiReply('Tell me what you want to organize.');
    if(q.contains('overdue')) {
      final xs=tasks.where((t)=>!t.completed&&t.dueAt!=null&&t.dueAt!.isBefore(DateTime.now())).toList();
      return xs.isEmpty?const AiReply('No overdue tasks.'):AiReply('You have '+xs.length.toString()+' overdue task'+(xs.length==1?'':'s')+'. Start with '+xs.take(3).map((t)=>t.title).join(', ')+'.');
    }
    if(q.contains('today')||q.contains('plan my day')) {
      final xs=tasks.where((t)=>!t.completed&&t.dueAt!=null&&sameDay(t.dueAt!,DateTime.now())).toList();
      xs.sort((a,b)=>score(b.priority).compareTo(score(a.priority)));
      return xs.isEmpty?const AiReply('Your calendar is clear. Add concrete tasks and I can structure the day.'):AiReply('Suggested order: '+xs.take(5).map((t)=>t.title).join(' → ')+'.');
    }
    if(q.contains('break')||q.contains('subtask')||q.contains('split')) {
      return AiReply('Break the task into a small outcome, first action, review, and finish.',steps:const [
        'Define the exact outcome',
        'Do the smallest useful first action',
        'Review what changed',
        'Mark complete and capture the next action',
      ]);
    }
    if(q.contains('goal')) return goals.isEmpty?const AiReply('No goals yet.'):AiReply('Active goals: '+goals.where((g)=>g.progress<100).map((g)=>g.name+' '+g.progress.toString()+'%').join(' • '));
    if(q.contains('habit')) return habits.isEmpty?const AiReply('No habits yet.'):AiReply('Habits: '+habits.map((h)=>h.icon+' '+h.name+' ('+h.currentStreak.toString()+'d)').join(' • '));
    if(q.contains('note')||q.contains('summary')) {
      if(notes.isEmpty) return const AiReply('No notes to summarize yet.');
      return AiReply('Latest note: '+notes.first.title+' — '+notes.first.body.replaceAll(RegExp(r'\s+'),' ').trim());
    }
    if(q.contains('stats')||q.contains('how many')) return AiReply('Tasks '+tasks.length.toString()+' • Goals '+goals.length.toString()+' • Habits '+habits.length.toString()+' • Notes '+notes.length.toString());
    return const AiReply('I am the offline Life AI. Try: “plan my day”, “what is overdue?”, “break down a task”, “show my goals”, or “summarize my notes”.');
  }

  bool sameDay(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;
  int score(Priority p)=>switch(p){Priority.low=>1,Priority.medium=>2,Priority.high=>3,Priority.critical=>4};
}
