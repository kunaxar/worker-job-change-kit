import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data.dart';
import 'ui.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Job-change kit (prototype)', debugShowCheckedModeBanner: false, theme: buildTheme(),
        builder: (c, child) => Container(color: g100, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: ClipRect(child: child)))),
        home: const Shell(),
      );
}

class AppState extends ChangeNotifier {
  int post = 0;
  final renewed = <String>{};
  final refs = <Ref>[Ref('Sam T.', 'Supervisor, Riverside Apartments', '555-0101 (fictional)')];
  final incl = <int>{0, 1};
  final done = <String>{};
  Posting get posting => postings[post];
  DateTime? expiryOf(Cred c) => renewed.contains(c.name) ? DateTime(2028, 10, 19) : c.expires;
  String statusOf(Cred c) {
    final e = expiryOf(c);
    if (e == null) return 'No expiry set';
    final d = e.difference(today).inDays;
    if (d < 0) return 'Expired';
    if (d <= 60) return 'Expires in $d days';
    return 'Valid';
  }
  // 0 = met, 1 = warning, 2 = missing
  (int, String) check(Need n) {
    final k = n.kind;
    if (k.startsWith('cred:')) {
      final key = k.substring(5).toLowerCase();
      final m = creds.where((c) => c.name.toLowerCase().contains(key)).toList();
      if (m.isEmpty) return (2, 'Not in your credentials');
      final c = m.first; final s = statusOf(c);
      if (s == 'Expired') return (1, '${c.name}: expired');
      if (s.startsWith('Expires')) return (1, '${c.name}: ${s.toLowerCase()}');
      return (0, '${c.name}: ${s.toLowerCase()}');
    }
    if (k.startsWith('years:')) {
      final need = int.parse(k.substring(6));
      const have = 3;
      return have >= need ? (0, 'Your record shows about $have years (2023 - now)') : (2, 'Your record shows about $have years, posting asks $need+');
    }
    if (k == 'ref') return refs.isNotEmpty ? (0, '${refs.length} reference on file') : (2, 'No reference yet');
    if (k.startsWith('refs:')) {
      final need = int.parse(k.substring(5));
      return refs.length >= need ? (0, '${refs.length} references on file') : (2, '${refs.length} of $need references');
    }
    if (k == 'task:ladder') return (2, 'Not listed on any job in your record');
    return (2, 'Unknown');
  }
  void upd(VoidCallback f) { f(); notifyListeners(); }
}

final app = AppState();
Future<void> open(String u) => launchUrl(Uri.parse(u));

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Column(children: [demoBanner(), Expanded(child: ListenableBuilder(listenable: app, builder: (c, _) => [ReadyTab(), SummaryTab(), DayOneTab(), ResearchTab()][tab]))])),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), backgroundColor: Colors.white, indicatorColor: Colors.transparent, height: 64,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check, color: orange), label: 'Ready?'),
            NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: orange), label: 'Summary'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist, color: orange), label: 'Day one'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book, color: orange), label: 'Research'),
          ],
        ),
      );
}

Widget card(Widget child, {Color? bg}) => Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg ?? Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: g200)), child: child);

class ReadyTab extends StatelessWidget {
  const ReadyTab({super.key});
  @override
  Widget build(BuildContext context) {
    final p = app.posting;
    final res = p.needs.map(app.check).toList();
    final ok = res.where((r) => r.$1 == 0).length;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text('Before you apply', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
      const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 12), child: Text('Pick a job posting. See what you can show and what to fix first.', style: TextStyle(color: g500, fontSize: 15))),
      SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
        for (var i = 0; i < postings.length; i++) Padding(padding: const EdgeInsets.only(right: 8), child: Pill(postings[i].title.split(',').first, on: app.post == i, onTap: () => app.upd(() => app.post = i))),
      ])),
      const SizedBox(height: 12),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SAMPLE POSTING (FICTIONAL)', style: TextStyle(color: g500, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(p.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        Text('${p.company} - ${p.where}', style: const TextStyle(color: g500, fontSize: 13)),
      ])),
      card(Row(children: [
        Icon(ok == res.length ? Icons.check_circle : Icons.info, color: ok == res.length ? green : orange),
        const SizedBox(width: 10),
        Expanded(child: Text('$ok of ${res.length} items ready', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      ]), bg: ok == res.length ? greenBg : amberBg),
      for (var i = 0; i < p.needs.length; i++) card(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(res[i].$1 == 0 ? Icons.check_circle : res[i].$1 == 1 ? Icons.warning_amber_rounded : Icons.cancel, color: res[i].$1 == 0 ? green : res[i].$1 == 1 ? amber : const Color(0xFFB42318)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.needs[i].label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(res[i].$2, style: const TextStyle(color: g500, fontSize: 13)),
        ])),
      ])),
      sectionTitle('Your credentials', sub: 'Dates as of 19 Oct 2026 (demo date)'),
      for (final c in creds) card(Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(c.issuer, style: const TextStyle(color: g500, fontSize: 12)),
          const SizedBox(height: 4),
          Tag(app.statusOf(c), app.statusOf(c) == 'Valid' || app.statusOf(c) == 'No expiry set' ? green : amber, app.statusOf(c) == 'Valid' || app.statusOf(c) == 'No expiry set' ? greenBg : amberBg),
        ])),
        if (app.statusOf(c).startsWith('Expire')) TextButton(onPressed: () => app.upd(() => app.renewed.add(c.name)), child: const Text('I renewed it')),
      ])),
      sectionTitle('References', sub: 'People who can say what you did'),
      for (final r in app.refs) card(Row(children: [const Icon(Icons.person, color: slate), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)), Text('${r.role} - ${r.phone}', style: const TextStyle(color: g500, fontSize: 12))]))])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: OutlinedButton.icon(
        onPressed: () => app.upd(() => app.refs.add(Ref('Dana R.', 'Foreman, Community clinic', '555-0102 (fictional)'))),
        icon: const Icon(Icons.add), label: const Text('Add a reference (demo adds a fictional one)'))),
    ]);
  }
}

class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text('One-page summary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
      const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 12), child: Text('Choose which jobs to show. Save it as a PDF to attach to an application or print.', style: TextStyle(color: g500, fontSize: 15))),
      for (var i = 0; i < jobs.length; i++) card(Row(children: [
        Checkbox(value: app.incl.contains(i), activeColor: slate, onChanged: (v) => app.upd(() => v! ? app.incl.add(i) : app.incl.remove(i))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${jobs[i].role} - ${jobs[i].project}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(jobs[i].years, style: const TextStyle(color: g500, fontSize: 12)),
          Tag(jobs[i].confirmed ? 'Confirmed by a foreman (demo)' : 'Self-reported', jobs[i].confirmed ? green : g600, jobs[i].confirmed ? greenBg : g100),
        ])),
      ])),
      const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 8), child: Text('PREVIEW', style: TextStyle(color: g500, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1))),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: g300), borderRadius: BorderRadius.circular(4)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Marcus A. (fictional)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Text('Apprentice electrician', style: TextStyle(color: g600)),
          const Divider(height: 22),
          const Text('CREDENTIALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: g500, letterSpacing: 1)),
          for (final c in creds) Text('${c.name} - ${app.statusOf(c)}', style: const TextStyle(fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          const Text('WORK RECORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: g500, letterSpacing: 1)),
          for (final i in app.incl.toList()..sort()) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${jobs[i].role}, ${jobs[i].project} (${jobs[i].years})${jobs[i].confirmed ? ' - confirmed by foreman (demo)' : ''}\n${jobs[i].tasks.join('; ')}', style: const TextStyle(fontSize: 13, height: 1.4))),
          const SizedBox(height: 10),
          const Text('REFERENCES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: g500, letterSpacing: 1)),
          for (final r in app.refs) Text('${r.name}, ${r.role}', style: const TextStyle(fontSize: 13, height: 1.5)),
        ]),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: slate, minimumSize: const Size.fromHeight(52)),
        onPressed: () => Printing.layoutPdf(name: 'worker-summary-demo.pdf', onLayout: (f) => buildPdf(f)),
        icon: const Icon(Icons.picture_as_pdf), label: const Text('Save as PDF'))),
      const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 0), child: Text('Opens your browser print dialog; choose "Save as PDF". Nothing is uploaded or sent.', style: TextStyle(color: g500, fontSize: 12))),
    ]);
  }
}

Future<Uint8List> buildPdf(PdfPageFormat f) async {
  final d = pw.Document();
  pw.Widget h(String t) => pw.Padding(padding: const pw.EdgeInsets.only(top: 14, bottom: 4), child: pw.Text(t, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)));
  d.addPage(pw.Page(pageFormat: f, margin: const pw.EdgeInsets.all(40), build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text('Marcus A. (fictional)', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
    pw.Text('Apprentice electrician'),
    h('CREDENTIALS'),
    for (final c in creds) pw.Text('${c.name} - ${app.statusOf(c)}'),
    h('WORK RECORD'),
    for (final i in app.incl.toList()..sort()) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text('${jobs[i].role}, ${jobs[i].project} (${jobs[i].years})${jobs[i].confirmed ? ' - confirmed by foreman (demo)' : ''}\n${jobs[i].tasks.join('; ')}')),
    h('REFERENCES'),
    for (final r in app.refs) pw.Text('${r.name}, ${r.role}'),
    pw.Spacer(),
    pw.Text('Demo document. Fictional worker. Confirmations are simulated.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
  ])));
  return d.save();
}

class DayOneTab extends StatelessWidget {
  const DayOneTab({super.key});
  Widget list(List<Item> items) => Column(children: [
        for (final it in items) card(InkWell(
          onTap: () => app.upd(() => app.done.contains(it.text) ? app.done.remove(it.text) : app.done.add(it.text)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(app.done.contains(it.text) ? Icons.check_circle : Icons.circle_outlined, color: app.done.contains(it.text) ? green : g300),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.text, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(it.note, style: const TextStyle(color: g500, fontSize: 13, height: 1.4)),
              if (it.url != null) TextButton(style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)), onPressed: () => open(it.url!), child: const Text('Source: USCIS')),
            ])),
          ]),
        )),
      ]);
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text('Switching jobs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 4), child: Text('Tap to tick. Ticks stay in this tab only.', style: TextStyle(color: g500, fontSize: 15))),
        sectionTitle('Before you leave'),
        list(leaving),
        sectionTitle('Have ready for day one'),
        list(dayOne),
      ]);
}

class ResearchTab extends StatelessWidget {
  const ResearchTab({super.key});
  Widget b(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 14, height: 1.45, color: g600)));
  Widget link(String t, String u) => InkWell(onTap: () => open(u), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [const Icon(Icons.open_in_new, size: 16, color: slate), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(color: slate, fontSize: 14, decoration: TextDecoration.underline)))])));
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Research and limits', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text('WHAT IS REAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: g500, letterSpacing: 1)),
        b('USCIS: the employee completes Form I-9 Section 1 no later than the first day of employment. That is why day one lists identity and work-authorization documents.'),
        b('Credential rules differ by place. Federal OSHA does not require the 10- or 30-hour card, but some states and projects do (Nevada law; Rhode Island for state and municipal projects of \$100,000 or more). The postings here are fictional, so the app only checks whether you hold a card, not whether a job legally needs it.'),
        b('Save as PDF builds the summary as a PDF in your browser and opens the print dialog. I could not test the dialog end to end, so treat it as untested.'),
        const SizedBox(height: 8),
        const Text('WHAT IS SIMULATED OR MADE UP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: g500, letterSpacing: 1)),
        b('Marcus, his credentials, jobs, references, dates and the three postings are fictional. The date is fixed at 19 Oct 2026 so expiry flags look the same every time.'),
        b('"Confirmed by a foreman" is a demo label. Nothing is sent to employers, foremen or referees. Checks compare your list with a posting\'s list. They do not say you would be hired or qualify.'),
        b('Hypotheses, no worker interviews: workers lose time at a job change because proof is scattered, and an expiring card is easiest to fix before applying.'),
        const SizedBox(height: 8),
        const Text('SOURCES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: g500, letterSpacing: 1)),
        link('USCIS: Completing Form I-9 Section 1', 'https://www.uscis.gov/i-9-central/completing-form-i-9/completing-section-1-employee-information-and-attestation'),
        link('Nevada: OSHA 10-hour construction training', 'https://www.4safenv.state.nv.us/training/10-30-hour-osha-training/osha-10-hour-construction-training/'),
        link('Rhode Island law 37-23-1', 'https://webserver.rilegislature.gov/Statutes/TITLE37/37-23/37-23-1.htm'),
        link('CareerOneStop: resumes', 'https://www.careeronestop.org/JobSearch/Resumes/resumes.aspx'),
      ]);
}
