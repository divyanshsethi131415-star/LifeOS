import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'ai.dart';
import 'models.dart';
import 'notifications.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store=LifeStore();
  await store.load();
  final notifications=NotificationService();
  await notifications.init();
  runApp(LifeOs(store:store,notifications:notifications));
}

class LifeOs extends StatefulWidget {
  final LifeStore store; final NotificationService notifications;
  const LifeOs({super.key,required this.store,required this.notifications});
  @override State<LifeOs> createState()=>_LifeOsState();
}

class _LifeOsState extends State<LifeOs> {
  ThemeMode mode=ThemeMode.dark;
  @override Widget build(BuildContext context)=>AnimatedBuilder(
    animation:widget.store,
    builder:(context,_)=>MaterialApp(
      title:'LIFE OS',debugShowCheckedModeBanner:false,themeMode:mode,
      theme:appTheme(Brightness.light),darkTheme:appTheme(Brightness.dark),
      home:Shell(store:widget.store,notifications:widget.notifications,onTheme:(m)=>setState(()=>mode=m)),
    ),
  );
}

ThemeData appTheme(Brightness b){
  final dark=b==Brightness.dark;
  return ThemeData(
    useMaterial3:true,brightness:b,
    colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF7C5CFF),brightness:b),
    scaffoldBackgroundColor:dark?const Color(0xFF090A10):const Color(0xFFF4F5F9),
    inputDecorationTheme:InputDecorationTheme(
      filled:true,
      border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),
    ),
  );
}

class Shell extends StatefulWidget {
  final LifeStore store; final NotificationService notifications; final ValueChanged<ThemeMode> onTheme;
  const Shell({super.key,required this.store,required this.notifications,required this.onTheme});
  @override State<Shell> createState()=>_ShellState();
}

class _ShellState extends State<Shell> {
  int index=0; bool setupShown=false;
  final pages=['Dashboard','Tasks','Calendar','Goals','Habits','Projects','Notes','Focus','Statistics','Ideas','Life AI','Settings'];
  final icons=[Icons.grid_view_rounded,Icons.check_circle_outline,Icons.calendar_month,Icons.flag_outlined,Icons.local_fire_department_outlined,Icons.folder_open,Icons.sticky_note_2_outlined,Icons.timer_outlined,Icons.insights,Icons.lightbulb_outline,Icons.auto_awesome,Icons.settings_outlined];

  @override void didChangeDependencies(){
    super.didChangeDependencies();
    if(!setupShown&&!widget.store.onboardingComplete){
      setupShown=true; WidgetsBinding.instance.addPostFrameCallback((_)=>setup(context));
    }
  }

  @override Widget build(BuildContext context){
    final wide=MediaQuery.sizeOf(context).width>=950;
    return Shortcuts(
      shortcuts:const {
        SingleActivator(LogicalKeyboardKey.keyK,control:true):SearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyN,control:true):NewTaskIntent(),
      },
      child:Actions(
        actions:{
          SearchIntent:CallbackAction<SearchIntent>(onInvoke:(_){showSearch(context:context,delegate:TaskSearch(widget.store));return null;}),
          NewTaskIntent:CallbackAction<NewTaskIntent>(onInvoke:(_){taskDialog(context,widget.store);return null;}),
        },
        child:Scaffold(
          body:SafeArea(child:Row(children:[
            if(wide) rail(),
            Expanded(child:_page(index)),
          ])),
          appBar:wide?null:AppBar(
            title:Text(pages[index],style:const TextStyle(fontWeight:FontWeight.w800)),
            actions:[IconButton(tooltip:'Search',onPressed:()=>showSearch(context:context,delegate:TaskSearch(widget.store)),icon:const Icon(Icons.search))],
          ),
          bottomNavigationBar:wide?null:NavigationBar(
            selectedIndex:index<4?index:4,
            onDestinationSelected:(i){ if(i<4){setState(()=>index=i);}else{moreMenu(context);} },
            destinations:const[
              NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'Home'),
              NavigationDestination(icon:Icon(Icons.check_circle_outline),label:'Tasks'),
              NavigationDestination(icon:Icon(Icons.flag_outlined),label:'Goals'),
              NavigationDestination(icon:Icon(Icons.local_fire_department_outlined),label:'Habits'),
              NavigationDestination(icon:Icon(Icons.more_horiz),label:'More'),
            ],
          ),
          floatingActionButton:FloatingActionButton.extended(
            onPressed:()=>taskDialog(context,widget.store),
            icon:const Icon(Icons.add_task),label:const Text('Quick capture'),
          ),
        ),
      ),
    );
  }

  Widget rail()=>NavigationRail(
    selectedIndex:index,
    onDestinationSelected:(i)=>setState(()=>index=i),
    labelType:NavigationRailLabelType.all,
    leading:const Padding(padding:EdgeInsets.only(top:12,bottom:18),child:Text('LIFE OS',style:TextStyle(fontWeight:FontWeight.w900,fontSize:20))),
    destinations:List.generate(pages.length,(i)=>NavigationRailDestination(icon:Icon(icons[i]),label:Text(pages[i]))),
  );

  Widget _page(int i)=>switch(i){
    0=>Dashboard(store:widget.store,notifications:widget.notifications),
    1=>Tasks(store:widget.store,notifications:widget.notifications),
    2=>CalendarPage(store:widget.store),
    3=>Goals(store:widget.store),
    4=>Habits(store:widget.store),
    5=>Projects(store:widget.store),
    6=>Notes(store:widget.store),
    7=>const FocusPage(),
    8=>Statistics(store:widget.store),
    9=>Ideas(store:widget.store),
    10=>AiPage(store:widget.store),
    _=>Settings(store:widget.store,notifications:widget.notifications,onTheme:widget.onTheme),
  };

  void moreMenu(BuildContext context){
    showModalBottomSheet(context:context,builder:(ctx)=>SafeArea(child:ListView(
      shrinkWrap:true,
      children:List.generate(pages.length-4,(n){
        final i=n+4;
        return ListTile(leading:Icon(icons[i]),title:Text(pages[i]),onTap:(){Navigator.pop(ctx);setState(()=>index=i);});
      }),
    )));
  }

  Future<void> setup(BuildContext context) async{
    final c=TextEditingController();
    var demo=true;
    await showDialog<void>(
      context:context,barrierDismissible:false,
      builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
        title:const Text('Welcome to LIFE OS'),
        content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Align(alignment:Alignment.centerLeft,child:Text('Your life. One system.',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800))),
          const SizedBox(height:14),
          TextField(controller:c,autofocus:true,decoration:const InputDecoration(labelText:'Your name')),
          const SizedBox(height:8),
          SwitchListTile(value:demo,onChanged:(v)=>setD(()=>demo=v),title:const Text('Load demo data'),subtitle:const Text('Good for exploring the system.')),
        ])),
        actions:[FilledButton(onPressed:()async{
          await widget.store.finishOnboarding(c.text,demo:demo);
          if(ctx.mounted)Navigator.pop(ctx);
        },child:const Text('Enter LIFE OS'))],
      )),
    );
  }
}

class SearchIntent extends Intent{const SearchIntent();}
class NewTaskIntent extends Intent{const NewTaskIntent();}

class Frame extends StatelessWidget {
  final String title; final String? subtitle; final List<Widget>? actions; final Widget child;
  const Frame({super.key,required this.title,this.subtitle,this.actions,required this.child});
  @override Widget build(BuildContext context)=>CustomScrollView(slivers:[
    SliverAppBar(floating:true,backgroundColor:Theme.of(context).scaffoldBackgroundColor,title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),if(subtitle!=null)Text(subtitle!,style:Theme.of(context).textTheme.bodySmall)
    ]),actions:actions),
    SliverPadding(padding:const EdgeInsets.fromLTRB(18,8,18,110),sliver:SliverToBoxAdapter(child:child)),
  ]);
}

class CardBox extends StatelessWidget {
  final String title; final IconData icon; final Widget child;
  const CardBox({super.key,required this.title,required this.icon,required this.child});
  @override Widget build(BuildContext context)=>Card(
    child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(icon,size:20),const SizedBox(width:8),Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18))]),
      const SizedBox(height:14),child
    ])),
  );
}

class Metric extends StatelessWidget {
  final String label,value,caption; final IconData icon;
  const Metric({super.key,required this.label,required this.value,required this.caption,required this.icon});
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
    Row(children:[Icon(icon),const SizedBox(width:8),Text(label,style:const TextStyle(fontWeight:FontWeight.w700))]),
    Text(value,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900)),
    Text(caption,style:Theme.of(context).textTheme.bodySmall),
  ])));
}

class Dashboard extends StatelessWidget {
  final LifeStore store; final NotificationService notifications;
  const Dashboard({super.key,required this.store,required this.notifications});
  @override Widget build(BuildContext context){
    final hour=DateTime.now().hour;
    final greeting=hour<12?'GOOD MORNING':hour<18?'GOOD AFTERNOON':'GOOD EVENING';
    final columns=MediaQuery.sizeOf(context).width>1100?4:MediaQuery.sizeOf(context).width>700?2:1;
    final active=[...store.tasks]..sort((a,b){
      if(a.completed!=b.completed)return a.completed?1:-1;
      return b.priority.index.compareTo(a.priority.index);
    });
    return Frame(title:greeting+', '+store.userName.toUpperCase()+' 👋',subtitle:DateFormat('EEEE, MMM d, y').format(DateTime.now()),actions:[
      IconButton(tooltip:'Test notification',onPressed:()async{await notifications.permission();await notifications.test();},icon:const Icon(Icons.notifications_none))
    ],child:Column(children:[
      GridView.count(crossAxisCount:columns,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.6,children:[
        Metric(label:'Today',value:store.dueToday.toString(),caption:store.overdue.toString()+' overdue',icon:Icons.today),
        Metric(label:'Completion',value:(store.completionRate*100).round().toString()+'%',caption:store.tasks.where((x)=>x.completed).length.toString()+' completed',icon:Icons.task_alt),
        Metric(label:'Habits',value:store.habits.isEmpty?'—':store.habits.map((h)=>h.currentStreak).fold<int>(0,(a,b)=>a>b?a:b).toString(),caption:'best current streak',icon:Icons.local_fire_department_outlined),
        Metric(label:'Goals',value:store.goals.where((g)=>g.progress<100).length.toString(),caption:'active goals',icon:Icons.flag_outlined),
      ]),
      const SizedBox(height:14),
      LayoutBuilder(builder:(context,c)=>Column(children:[
        CardBox(title:'Today',icon:Icons.check_circle_outline,child:active.isEmpty?const Text('Your system is empty. Use Quick capture to start.'):Column(children:active.take(7).map((t)=>taskTile(context,store,t,notifications)).toList())),
        const SizedBox(height:14),
        CardBox(title:'Life AI',icon:Icons.auto_awesome,child:Row(children:[
          const Expanded(child:Text('Offline assistant for planning, overdue work, task breakdowns, goals, habits, notes and stats.')),
          FilledButton.tonal(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AiPage(store:store))),child:const Text('Ask AI')),
        ])),
      ]))
    ]));
  }
}

Widget taskTile(BuildContext context,LifeStore store,Task t,NotificationService? notifications)=>ListTile(
  contentPadding:EdgeInsets.zero,
  leading:Checkbox(value:t.completed,onChanged:(_)=>store.toggleTask(t)),
  title:Text(t.title,style:TextStyle(fontWeight:FontWeight.w700,decoration:t.completed?TextDecoration.lineThrough:null)),
  subtitle:Text(t.category+' • '+t.priority.name.toUpperCase()+' • '+(t.dueAt==null?'No due date':DateFormat('MMM d • HH:mm').format(t.dueAt!))),
  trailing:PopupMenuButton<String>(onSelected:(v)async{
    if(v=='delete')await store.deleteTask(t);
    if(v=='remind'&&notifications!=null){await notifications.permission();await notifications.schedule(t.id,t.title,t.description.isEmpty?'Life OS reminder':t.description,t.reminderAt??DateTime.now().add(const Duration(minutes:1)));}
  },itemBuilder:(_)=>const[PopupMenuItem(value:'remind',child:Text('Remind me')),PopupMenuItem(value:'delete',child:Text('Delete'))]),
);

class Tasks extends StatelessWidget {
  final LifeStore store; final NotificationService notifications;
  const Tasks({super.key,required this.store,required this.notifications});
  @override Widget build(BuildContext context){
    final overdue=store.tasks.where((t)=>!t.completed&&t.dueAt!=null&&t.dueAt!.isBefore(DateTime.now())).toList();
    final open=store.tasks.where((t)=>!t.completed&&(t.dueAt==null||!t.dueAt!.isBefore(DateTime.now()))).toList();
    return Frame(title:'Tasks',subtitle:'Inbox • Today • Upcoming • Overdue',actions:[IconButton(onPressed:()=>taskDialog(context,store),icon:const Icon(Icons.add))],child:Column(children:[
      if(overdue.isNotEmpty)CardBox(title:'Overdue',icon:Icons.warning_amber_rounded,child:Column(children:overdue.map((t)=>taskTile(context,store,t,notifications)).toList())),
      if(overdue.isNotEmpty)const SizedBox(height:14),
      CardBox(title:'Open work',icon:Icons.inbox_rounded,child:open.isEmpty?const Text('Nothing open. Add a task when you need it.'):Column(children:open.map((t)=>taskTile(context,store,t,notifications)).toList())),
      if(store.tasks.any((t)=>t.completed))...[
        const SizedBox(height:14),
        CardBox(title:'Completed',icon:Icons.done_all,child:Column(children:store.tasks.where((t)=>t.completed).take(12).map((t)=>taskTile(context,store,t,null)).toList()))
      ]
    ]));
  }
}

Future<void> taskDialog(BuildContext context,LifeStore store)async{
  final title=TextEditingController();final desc=TextEditingController();
  var priority=Priority.medium;var category='Personal';DateTime? due;
  await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
    title:const Text('Quick capture'),
    content:SizedBox(width:500,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,autofocus:true,decoration:const InputDecoration(labelText:'Title')),
      const SizedBox(height:10),
      TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'Description')),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:DropdownButtonFormField<Priority>(value:priority,items:Priority.values.map((p)=>DropdownMenuItem(value:p,child:Text(p.name.toUpperCase()))).toList(),onChanged:(v)=>setD(()=>priority=v??priority),decoration:const InputDecoration(labelText:'Priority'))),
        const SizedBox(width:10),
        Expanded(child:DropdownButtonFormField<String>(value:category,items:const['Personal','School','Work','Coding','Gaming','Health'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setD(()=>category=v??category),decoration:const InputDecoration(labelText:'Category'))),
      ]),
      const SizedBox(height:10),
      OutlinedButton.icon(onPressed:()async{
        final d=await showDatePicker(context:ctx,firstDate:DateTime.now().subtract(const Duration(days:365)),lastDate:DateTime.now().add(const Duration(days:3650)),initialDate:DateTime.now());
        if(d==null||!ctx.mounted)return;
        final time=await showTimePicker(context:ctx,initialTime:TimeOfDay.now());
        if(time!=null)setD(()=>due=DateTime(d.year,d.month,d.day,time.hour,time.minute));
      },icon:const Icon(Icons.schedule),label:Text(due==null?'Set due date':DateFormat('MMM d • HH:mm').format(due!)))
    ]))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),
      FilledButton(onPressed:()async{if(title.text.trim().isEmpty)return;await store.addTask(title.text,description:desc.text,dueAt:due,priority:priority,category:category);if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Create'))
    ],
  )));
}

class CalendarPage extends StatefulWidget {
  final LifeStore store;const CalendarPage({super.key,required this.store});
  @override State<CalendarPage> createState()=>_CalendarPageState();
}
class _CalendarPageState extends State<CalendarPage>{
  DateTime month=DateTime(DateTime.now().year,DateTime.now().month);
  @override Widget build(BuildContext context){
    final start=DateTime(month.year,month.month,1);final total=DateTime(month.year,month.month+1,0).day;final offset=start.weekday-1;
    return Frame(title:'Calendar',subtitle:DateFormat('MMMM y').format(month),actions:[
      IconButton(onPressed:()=>setState(()=>month=DateTime(month.year,month.month-1)),icon:const Icon(Icons.chevron_left)),
      IconButton(onPressed:()=>setState(()=>month=DateTime(month.year,month.month+1)),icon:const Icon(Icons.chevron_right)),
    ],child:CardBox(title:'Deadlines',icon:Icons.calendar_month,child:Column(children:[
      Row(children:['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d)=>Expanded(child:Center(child:Text(d,style:const TextStyle(fontWeight:FontWeight.w700))))).toList()),
      const SizedBox(height:10),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:offset+total,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,crossAxisSpacing:6,mainAxisSpacing:6),itemBuilder:(context,i){
        if(i<offset)return const SizedBox.shrink();
        final day=i-offset+1;final date=DateTime(month.year,month.month,day);final today=DateUtils.isSameDay(date,DateTime.now());
        final count=widget.store.tasks.where((t)=>t.dueAt!=null&&DateUtils.isSameDay(t.dueAt,date)).length;
        return Container(padding:const EdgeInsets.all(7),decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),border:Border.all(color:today?Theme.of(context).colorScheme.primary:Theme.of(context).dividerColor)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(day.toString(),style:TextStyle(fontWeight:today?FontWeight.w900:FontWeight.w500)),
          if(count>0)...[const Spacer(),Text(count.toString()+' task'+(count==1?'':'s'),style:Theme.of(context).textTheme.labelSmall)]
        ]));
      })
    ]));
  }
}

class Goals extends StatelessWidget{
  final LifeStore store;const Goals({super.key,required this.store});
  @override Widget build(BuildContext context)=>Frame(title:'Goals',subtitle:'Outcomes → milestones → progress',actions:[IconButton(onPressed:()=>goalDialog(context,store),icon:const Icon(Icons.add))],child:store.goals.isEmpty?const Text('No goals yet.'):Column(children:store.goals.map((g)=>CardBox(title:g.name,icon:Icons.flag_outlined,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Chip(label:Text(g.category)),const Spacer(),Text(g.progress.toString()+'%')]),
    const SizedBox(height:8),LinearProgressIndicator(value:g.progress/100,minHeight:8,borderRadius:BorderRadius.circular(8)),
    Slider(value:g.progress.toDouble(),min:0,max:100,divisions:20,onChanged:(v)=>store.updateGoal(g,v.round()))
  ]))).toList());
}

Future<void> goalDialog(BuildContext context,LifeStore store)async{
  final c=TextEditingController();var category='Personal';
  await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('New goal'),content:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:c,autofocus:true,decoration:const InputDecoration(labelText:'Goal name')),
    const SizedBox(height:10),
    DropdownButtonFormField<String>(value:category,items:const['Personal','Academic','Fitness','Coding','Gaming','Work'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>category=v??category)
  ]),actions:[FilledButton(onPressed:()async{if(c.text.trim().isNotEmpty)await store.addGoal(c.text,category);if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Create'))]));
}

class Habits extends StatelessWidget{
  final LifeStore store;const Habits({super.key,required this.store});
  @override Widget build(BuildContext context)=>Frame(title:'Habits',subtitle:'Consistency without punishment',actions:[IconButton(onPressed:()=>habitDialog(context,store),icon:const Icon(Icons.add))],child:store.habits.isEmpty?const Text('No habits yet.'):Column(children:store.habits.map((h)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
    leading:CircleAvatar(child:Text(h.icon)),title:Text(h.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(h.currentStreak.toString()+' day streak'),trailing:FilledButton.tonal(onPressed:()=>store.toggleHabit(h,DateTime.now()),child:Text(h.isDoneOn(DateTime.now())?'Done':'Mark done')),
  ))).toList());
}
Future<void> habitDialog(BuildContext context,LifeStore store)async{
  final c=TextEditingController();await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('New habit'),content:TextField(controller:c,autofocus:true,decoration:const InputDecoration(labelText:'Habit name')),actions:[FilledButton(onPressed:()async{if(c.text.trim().isNotEmpty)await store.addHabit(c.text,'✓');if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Create'))]));
}

class Projects extends StatelessWidget{
  final LifeStore store;const Projects({super.key,required this.store});
  @override Widget build(BuildContext context)=>Frame(title:'Projects',subtitle:'Keep multi-step work together',actions:[IconButton(onPressed:()=>projectDialog(context,store),icon:const Icon(Icons.add))],child:store.projects.isEmpty?const Text('No projects yet.'):Column(children:store.projects.map((p)=>CardBox(title:p.name,icon:Icons.folder_open,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(p.description.isEmpty?'No description':p.description),const SizedBox(height:10),LinearProgressIndicator(value:p.progress/100),const SizedBox(height:6),Text(p.progress.toString()+'% • '+p.status.name)
  ])).toList());
}
Future<void> projectDialog(BuildContext context,LifeStore store)async{
  final n=TextEditingController();final d=TextEditingController();await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('New project'),content:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:n,autofocus:true,decoration:const InputDecoration(labelText:'Name')),const SizedBox(height:10),TextField(controller:d,maxLines:3,decoration:const InputDecoration(labelText:'Description'))
  ]),actions:[FilledButton(onPressed:()async{if(n.text.trim().isNotEmpty)await store.addProject(n.text,d.text);if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Create'))]));
}

class Notes extends StatefulWidget{final LifeStore store;const Notes({super.key,required this.store});@override State<Notes> createState()=>_NotesState();}
class _NotesState extends State<Notes>{String q='';
  @override Widget build(BuildContext context){final xs=widget.store.notes.where((n)=>(n.title+' '+n.body+' '+n.tags).toLowerCase().contains(q.toLowerCase())).toList();return Frame(title:'Notes',subtitle:'Searchable local knowledge',actions:[IconButton(onPressed:()=>noteDialog(context,widget.store),icon:const Icon(Icons.add))],child:Column(children:[
    TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search notes')),const SizedBox(height:12),
    ...xs.map((n)=>Padding(padding:const EdgeInsets.only(bottom:10),child:CardBox(title:n.title,icon:Icons.sticky_note_2_outlined,child:Text(n.body))))
  ]);}
}
Future<void> noteDialog(BuildContext context,LifeStore store)async{final n=TextEditingController();final b=TextEditingController();await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('New note'),content:SizedBox(width:550,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,autofocus:true,decoration:const InputDecoration(labelText:'Title')),const SizedBox(height:10),TextField(controller:b,minLines:5,maxLines:10,decoration:const InputDecoration(labelText:'Write...'))])),actions:[FilledButton(onPressed:()async{if(n.text.trim().isNotEmpty)await store.addNote(n.text,b.text,'');if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Save'))]));}

class FocusPage extends StatefulWidget{const FocusPage({super.key});@override State<FocusPage> createState()=>_FocusState();}
class _FocusState extends State<FocusPage>{static const total=1500;int remaining=total;Timer? timer;bool running=false;
  @override void dispose(){timer?.cancel();super.dispose();}
  void toggle(){if(running){timer?.cancel();setState(()=>running=false);}else{setState(()=>running=true);timer=Timer.periodic(const Duration(seconds:1),(_){if(remaining<=1){timer?.cancel();setState((){remaining=total;running=false;});}else{setState(()=>remaining--);}});}}
  @override Widget build(BuildContext context){final m=(remaining~/60).toString().padLeft(2,'0');final s=(remaining%60).toString().padLeft(2,'0');return Frame(title:'Focus',subtitle:'25-minute deep work',child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:540),child:CardBox(title:'Focus session',icon:Icons.timer_outlined,child:Column(children:[
    const SizedBox(height:20),Text(m+':'+s,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:72)),LinearProgressIndicator(value:1-remaining/total,minHeight:10),const SizedBox(height:22),Row(mainAxisAlignment:MainAxisAlignment.center,children:[FilledButton.icon(onPressed:toggle,icon:Icon(running?Icons.pause:Icons.play_arrow),label:Text(running?'Pause':'Start')),const SizedBox(width:10),OutlinedButton(onPressed:()=>setState(()=>remaining=total),child:const Text('Reset'))])
  ]))));}
}

class Statistics extends StatelessWidget{final LifeStore store;const Statistics({super.key,required this.store});
 @override Widget build(BuildContext context){final done=store.tasks.where((t)=>t.completed).length;final active=store.tasks.length-done;final habits=store.habits.where((h)=>h.isDoneOn(DateTime.now())).length;final avg=store.goals.isEmpty?null:(store.goals.map((g)=>g.progress).reduce((a,b)=>a+b)/store.goals.length).round();return Frame(title:'Statistics',subtitle:'Your system at a glance',child:GridView.count(crossAxisCount:MediaQuery.sizeOf(context).width>900?3:1,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.6,children:[
  Metric(label:'Completed tasks',value:done.toString(),caption:active.toString()+' open',icon:Icons.check_circle_outline),
  Metric(label:'Habits today',value:habits.toString(),caption:store.habits.length.toString()+' configured',icon:Icons.local_fire_department_outlined),
  Metric(label:'Goal progress',value:avg==null?'—':avg.toString()+'%',caption:'average',icon:Icons.flag_outlined),
 ]);}
}

class Ideas extends StatelessWidget{final LifeStore store;const Ideas({super.key,required this.store});
 @override Widget build(BuildContext context)=>Frame(title:'Ideas',subtitle:'Capture first. Decide later.',actions:[IconButton(onPressed:()=>ideaDialog(context,store),icon:const Icon(Icons.add))],child:store.ideas.isEmpty?const Text('No ideas yet.'):Column(children:store.ideas.map((i)=>Padding(padding:const EdgeInsets.only(bottom:10),child:CardBox(title:i.title,icon:Icons.lightbulb_outline,child:Text(i.description.isEmpty?'No description':i.description)))).toList());
}
Future<void> ideaDialog(BuildContext context,LifeStore store)async{final n=TextEditingController();final d=TextEditingController();await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Capture idea'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,autofocus:true,decoration:const InputDecoration(labelText:'Idea')),const SizedBox(height:10),TextField(controller:d,maxLines:4,decoration:const InputDecoration(labelText:'Notes'))]),actions:[FilledButton(onPressed:()async{if(n.text.trim().isNotEmpty)await store.addIdea(n.text,d.text);if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Capture'))]));}

class AiPage extends StatefulWidget{final LifeStore store;const AiPage({super.key,required this.store});@override State<AiPage> createState()=>_AiState();}
class _AiState extends State<AiPage>{final c=TextEditingController();final ai=LifeAi();AiReply? reply;
 @override void dispose(){c.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Frame(title:'Life AI',subtitle:'Offline • no API key • private by default',child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:800),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  CardBox(title:'Ask',icon:Icons.auto_awesome,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:TextField(controller:c,minLines:1,maxLines:4,onSubmitted:(_)=>ask(),decoration:const InputDecoration(hintText:'Try: plan my day, what is overdue?, break down a task...'))),const SizedBox(width:10),FilledButton(onPressed:ask,child:const Text('Ask'))])),
  if(reply!=null)...[const SizedBox(height:12),CardBox(title:'Response',icon:Icons.forum_outlined,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(reply!.text,style:const TextStyle(fontSize:16)),...reply!.steps.map((s)=>Padding(padding:const EdgeInsets.only(top:8),child:Row(children:[const Text('• '),Expanded(child:Text(s))]))) ]))]
 ])));
 void ask()=>setState(()=>reply=ai.ask(c.text,widget.store.tasks,widget.store.goals,widget.store.habits,widget.store.notes));
}

class Settings extends StatelessWidget{final LifeStore store;final NotificationService notifications;final ValueChanged<ThemeMode> onTheme;const Settings({super.key,required this.store,required this.notifications,required this.onTheme});
 @override Widget build(BuildContext context)=>Frame(title:'Settings',subtitle:'Appearance, notifications and backups',child:Column(children:[
  CardBox(title:'Appearance',icon:Icons.palette_outlined,child:Wrap(spacing:8,children:[
    FilledButton.tonal(onPressed:()=>onTheme(ThemeMode.dark),child:const Text('Dark')),
    OutlinedButton(onPressed:()=>onTheme(ThemeMode.light),child:const Text('Light')),
    OutlinedButton(onPressed:()=>onTheme(ThemeMode.system),child:const Text('System')),
  ])),
  const SizedBox(height:12),
  CardBox(title:'Notifications',icon:Icons.notifications_none,child:Row(children:[const Expanded(child:Text('Enable local task reminders on supported platforms.')),FilledButton.tonal(onPressed:()async{await notifications.permission();await notifications.test();},child:const Text('Test'))])),
  const SizedBox(height:12),
  CardBox(title:'Backup',icon:Icons.import_export,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Export structured JSON or restore a previous backup.'),
    const SizedBox(height:10),
    FilledButton.tonal(onPressed:()=>jsonDialog(context,store.exportJson(),false,store),child:const Text('Export JSON')),
    OutlinedButton(onPressed:()=>jsonDialog(context,'',true,store),child:const Text('Import JSON')),
  ])),
  const SizedBox(height:12),
  CardBox(title:'Local data',icon:Icons.storage_outlined,child:Text(store.tasks.length.toString()+' tasks • '+store.goals.length.toString()+' goals • '+store.habits.length.toString()+' habits • '+store.projects.length.toString()+' projects • '+store.notes.length.toString()+' notes')),
 ]));
}

Future<void> jsonDialog(BuildContext context,String initial,bool edit,LifeStore store)async{final c=TextEditingController(text:initial);await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:Text(edit?'Import JSON':'Export JSON'),content:SizedBox(width:700,child:TextField(controller:c,readOnly:!edit,minLines:10,maxLines:18)),actions:[
  TextButton(onPressed:(){Clipboard.setData(ClipboardData(text:c.text));Navigator.pop(ctx);},child:const Text('Copy')),
  if(edit)FilledButton(onPressed:()async{try{await store.importJson(c.text);if(ctx.mounted)Navigator.pop(ctx);}catch(_){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('Invalid backup JSON.')));}},child:const Text('Restore')),
  if(!edit)TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close')),
]));}

class TaskSearch extends SearchDelegate<Task?>{
 final LifeStore store;TaskSearch(this.store);
 @override List<Widget>? buildActions(BuildContext c)=>[IconButton(onPressed:()=>query='',icon:const Icon(Icons.clear))];
 @override Widget? buildLeading(BuildContext c)=>IconButton(onPressed:()=>close(c,null),icon:const Icon(Icons.arrow_back));
 @override Widget buildSuggestions(BuildContext c)=>results();
 @override Widget buildResults(BuildContext c)=>results();
 Widget results(){final q=query.toLowerCase();final xs=store.tasks.where((t)=>(t.title+' '+t.description+' '+t.category).toLowerCase().contains(q)).toList();return ListView(children:xs.map((t)=>ListTile(title:Text(t.title),subtitle:Text(t.category),leading:Checkbox(value:t.completed,onChanged:(_)=>store.toggleTask(t)))).toList());}
}
