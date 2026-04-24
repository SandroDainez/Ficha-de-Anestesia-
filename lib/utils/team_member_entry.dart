class TeamMemberEntry {
  const TeamMemberEntry({required this.name, this.crm = '', this.details = ''});

  factory TeamMemberEntry.parse(String rawEntry) {
    final parts = [...rawEntry.split('|'), '', ''];
    if (parts.length < 3) {
      return TeamMemberEntry(name: rawEntry.trim());
    }

    return TeamMemberEntry(
      name: parts[0].trim(),
      crm: parts[1].trim(),
      details: parts[2].trim(),
    );
  }

  final String name;
  final String crm;
  final String details;

  bool get isEmpty =>
      name.trim().isEmpty && crm.trim().isEmpty && details.trim().isEmpty;

  String encode() => '${name.trim()}|${crm.trim()}|${details.trim()}';

  String get subtitle {
    final parts = <String>[
      if (crm.trim().isNotEmpty) 'CRM ${crm.trim()}',
      if (details.trim().isNotEmpty) details.trim(),
    ];
    return parts.join(' • ');
  }

  String get formatted {
    final parts = <String>[
      if (name.trim().isNotEmpty) name.trim(),
      if (crm.trim().isNotEmpty) 'CRM ${crm.trim()}',
      if (details.trim().isNotEmpty) details.trim(),
    ];
    return parts.join(' • ');
  }
}
