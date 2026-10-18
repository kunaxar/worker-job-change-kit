// Demo "today" is fixed so expiry flags are the same on every visit.
final today = DateTime(2026, 10, 19);

class Cred {
  final String name, issuer;
  final DateTime? expires;
  const Cred(this.name, this.issuer, this.expires);
  int? get daysLeft => expires?.difference(today).inDays;
  String get status {
    final d = daysLeft;
    if (d == null) return 'No expiry set';
    if (d < 0) return 'Expired';
    if (d <= 60) return 'Expires in $d days';
    return 'Valid';
  }
  bool get flagged => daysLeft != null && daysLeft! <= 60;
}

final creds = <Cred>[
  Cred('OSHA 30-hour Construction', 'Example Safety Training (fictional)', null),
  Cred('NCCER Core', 'Example Training Center (fictional)', null),
  Cred('First Aid / CPR', 'Example Red Cross-style class (fictional)', DateTime(2026, 11, 12)),
  Cred('Forklift operator', 'Example Employer (fictional)', DateTime(2026, 8, 30)),
];

class Job {
  final String project, role, years;
  final bool confirmed;
  final List<String> tasks;
  const Job(this.project, this.role, this.years, this.confirmed, this.tasks);
}

const jobs = <Job>[
  Job('Riverside Apartments, unit fit-out', 'Apprentice electrician', '2024 - now', true, ['Run conduit and pull wire', 'Connect breakers and panels', 'Test circuits with a meter']),
  Job('Community clinic, tenant improvement', 'Helper electrician', '2023 - 2024', true, ['Read blueprints and plan wiring', 'Install fixtures and devices']),
];

class Ref {
  String name, role, phone;
  Ref(this.name, this.role, this.phone);
}

class Posting {
  final String title, company, where;
  final List<Need> needs;
  const Posting(this.title, this.company, this.where, this.needs);
}

class Need {
  final String label, kind; // kind: cred:<name> | years:<n> | jobs | ref
  const Need(this.label, this.kind);
}

const postings = <Posting>[
  Posting('Electrician apprentice (2nd year)', 'Example Electric Co. (fictional)', 'Anywhere, USA', [
    Need('OSHA 10 or 30-hour card', 'cred:OSHA'),
    Need('1+ year of electrical work', 'years:1'),
    Need('One reference from a supervisor', 'ref'),
  ]),
  Posting('Journeyman electrician, commercial', 'Sample Builders (fictional)', 'Anywhere, USA', [
    Need('OSHA 30-hour card', 'cred:OSHA 30'),
    Need('State journeyman license', 'cred:Journeyman license'),
    Need('4+ years of electrical work', 'years:4'),
    Need('Forklift operator card (valid)', 'cred:Forklift'),
  ]),
  Posting('Solar installer helper', 'Demo Solar (fictional)', 'Anywhere, USA', [
    Need('First aid / CPR (valid)', 'cred:First Aid'),
    Need('Work at height, ladders and lifts', 'task:ladder'),
    Need('Two references', 'refs:2'),
  ]),
];

class Item {
  final String text, note;
  final String? url;
  const Item(this.text, this.note, [this.url]);
}

const dayOne = <Item>[
  Item('Documents for Form I-9', 'Your employer needs proof of identity and work authorization. USCIS says the employee completes Section 1 no later than the first day of employment.', 'https://www.uscis.gov/i-9-central/completing-form-i-9/completing-section-1-employee-information-and-attestation'),
  Item('Your credential cards or PDFs', 'OSHA card, licences, certificates. Have them on your phone and a printed copy.'),
  Item('Required safety gear', 'Ask what the employer provides and what you bring (boots, hard hat, glasses).'),
  Item('Bank details for pay', 'Account and routing number if you want direct deposit.'),
  Item('Emergency contact', 'Name and phone number.'),
  Item('Your work record link or PDF', 'So your new foreman can see what you have done on earlier jobs.'),
];

const leaving = <Item>[
  Item('Give notice the way your employer expects', 'Check your offer letter or ask your supervisor. Practices differ.'),
  Item('Ask your foreman to confirm your jobs', 'Do this before you leave. People are easier to reach while you still work together.'),
  Item('Get copies of your training records', 'Anything your employer paid for or holds for you.'),
  Item('Return company tools and badges', 'Keep a photo of what you handed back.'),
];
