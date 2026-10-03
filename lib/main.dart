// ═══════════════════════════════════════════════════════════════════════
//  ScholarSearch · lib/main.dart  — BACHELOR PORTAL ENHANCED VERSION
//  ✅ Bachelor/Master/PhD all show  ✅ 60+ countries
//  ✅ USA, Canada, UK, Australia, Denmark, Sweden, Netherlands, Turkey, Hungary
//  ✅ BachelorsPortal.com style data  ✅ Proper degree filtering
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

// ────────────────────────────────────────────────────────────────
// COLORS
// ────────────────────────────────────────────────────────────────
class C {
  static const bg      = Color(0xFFF0F4FF);
  static const white   = Colors.white;
  static const primary = Color(0xFF1A56DB);
  static const blue2   = Color(0xFF0E3FA3);
  static const accent  = Color(0xFFFF6D00);
  static const green   = Color(0xFF00A76F);
  static const orange  = Color(0xFFFFA726);
  static const purple  = Color(0xFF7C3AED);
  static const red     = Color(0xFFEF4444);
  static const teal    = Color(0xFF0891B2);
  static const tDark   = Color(0xFF111827);
  static const tMid    = Color(0xFF6B7280);
  static const tLight  = Color(0xFFD1D5DB);
  static const card    = Color(0xFFFFFFFF);
  static const grad = LinearGradient(
    colors: [Color(0xFF0E3FA3), Color(0xFF1A56DB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ────────────────────────────────────────────────────────────────
// HELPERS
// ────────────────────────────────────────────────────────────────
extension Dur on int { Duration get ms => Duration(milliseconds: this); }

String _flag(String code) {
  if (code.isEmpty || code.length != 2 || code == 'XX') return '🌍';
  try {
    const base = 0x1F1E6 - 0x41;
    final upper = code.toUpperCase();
    final c1 = upper.codeUnitAt(0);
    final c2 = upper.codeUnitAt(1);
    if (c1 < 0x41 || c1 > 0x5A || c2 < 0x41 || c2 > 0x5A) return '🌍';
    return String.fromCharCode(base + c1) + String.fromCharCode(base + c2);
  } catch (_) { return '🌍'; }
}

String _docId(String t) {
  final cleaned = t
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (cleaned.isEmpty) return 'scholarship_${DateTime.now().millisecondsSinceEpoch}';
  final end = cleaned.length < 60 ? cleaned.length : 60;
  return cleaned.substring(0, end);
}


// ────────────────────────────────────────────────────────────────
// CONSTANTS
// ────────────────────────────────────────────────────────────────
const kAllFields = [
  'All Fields',
  'Agriculture & Forestry',
  'Applied Sciences',
  'Arts & Humanities',
  'Business & Management',
  'Computer Science & IT',
  'Economics & Finance',
  'Education & Training',
  'Engineering & Technology',
  'Environmental Studies',
  'Health & Medicine',
  'Hospitality & Leisure',
  'Journalism & Media',
  'Language & Culture',
  'Law',
  'Mathematics',
  'Natural Sciences',
  'Social Sciences',
];

const kAllDegrees = ['All', 'Bachelor', 'Master', 'PhD'];
const kAllFundings = ['All', 'Fully Funded', 'Partial', 'Varies'];

const kAllCountries = [
  'All Countries',
  'Australia', 'Austria', 'Belgium', 'Brazil', 'Brunei', 'Canada',
  'China', 'Czech Republic', 'Denmark', 'Egypt', 'Estonia', 'Finland',
  'France', 'Germany', 'Greece', 'Hungary', 'Iceland', 'India',
  'Indonesia', 'Ireland', 'Italy', 'Japan', 'Malaysia', 'Mexico',
  'Morocco', 'Netherlands', 'New Zealand', 'Norway', 'Pakistan',
  'Poland', 'Portugal', 'Russia', 'Saudi Arabia', 'Singapore',
  'South Africa', 'South Korea', 'Spain', 'Sweden', 'Switzerland',
  'Taiwan', 'Turkey', 'United Arab Emirates', 'United Kingdom',
  'United States', 'Various Countries',
];

// ────────────────────────────────────────────────────────────────
// MODEL
// ────────────────────────────────────────────────────────────────
class Scholarship {
  final String id, title, university, country, flag, code,
      degree, field, funding, deadline, description, applyUrl, source;
  final double amount;
  final bool isNew;
  final DateTime addedAt;
  final List<String> tags;
  final List<String> fields;

  const Scholarship({
    required this.id,        required this.title,       required this.university,
    required this.country,   required this.flag,        required this.code,
    required this.degree,    required this.field,       required this.funding,
    required this.deadline,  required this.description, required this.applyUrl,
    required this.source,    required this.amount,      required this.isNew,
    required this.addedAt,   required this.tags,        required this.fields,
  });

  factory Scholarship.fromDoc(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    final code = (m['code'] ?? 'XX') as String;
    return Scholarship(
      id: d.id,
      title: m['title'] ?? '',
      university: m['university'] ?? '',
      country: m['country'] ?? '',
      flag: _flag(code),
      code: code,
      degree: m['degree'] ?? 'All',
      field: m['field'] ?? 'All Fields',
      funding: m['funding'] ?? 'Varies',
      deadline: m['deadline'] ?? '',
      description: m['description'] ?? '',
      applyUrl: m['applyUrl'] ?? '',
      source: m['source'] ?? '',
      amount: (m['amount'] ?? 0.0).toDouble(),
      isNew: m['isNew'] ?? false,
      addedAt: (m['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(m['tags'] ?? []),
      fields: List<String>.from(m['fields'] ?? [m['field'] ?? 'All Fields']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'university': university, 'country': country,
    'flag': flag,   'code': code,             'degree': degree,
    'field': field, 'fields': fields,         'funding': funding,
    'deadline': deadline, 'description': description, 'applyUrl': applyUrl,
    'source': source, 'amount': amount, 'isNew': isNew,
    'addedAt': Timestamp.fromDate(addedAt), 'tags': tags,
  };
}

// ════════════════════════════════════════════════════════════════
// COMPLETE DATABASE — Bachelor + Master + PhD
// Focus: USA, Canada, UK, Australia, Denmark, Sweden,
//        Netherlands, Turkey, Hungary + 30 more countries
// Source style: BachelorsPortal.com / MastersPortal.com
// ════════════════════════════════════════════════════════════════
final List<Map<String, dynamic>> _kData = [

  // ══════════════════════════════════════════════════════════════
  // 🇺🇸 UNITED STATES — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'Bachelor of Science in Computer Science',
    'university': 'Massachusetts Institute of Technology (MIT)',
    'country': 'United States', 'code': 'US', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-01',
    'amount': 60000.0,
    'description': 'World-renowned CS undergraduate program. MIT offers need-blind admissions with generous financial aid covering full tuition for families earning under \$140,000/year. Students engage in cutting-edge research from day one.',
    'applyUrl': 'https://www.bachelorsportal.com/studies/25/computer-science.html',
    'tags': ['usa', 'bachelor', 'cs', 'mit', 'stem', 'financial-aid'],
  },
  {
    'title': 'Bachelor of Arts in Economics',
    'university': 'Harvard University',
    'country': 'United States', 'code': 'US', 'degree': 'Bachelor',
    'field': 'Economics & Finance',
    'fields': ['Economics & Finance', 'Social Sciences', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-01',
    'amount': 75000.0,
    'description': 'Harvard\'s economics undergraduate program is among the best in the world. International students qualify for need-based aid. Over 70% of students receive some form of financial assistance.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=economics&targetCountry=US',
    'tags': ['usa', 'bachelor', 'economics', 'harvard', 'financial-aid'],
  },
  {
    'title': 'BSc Electrical Engineering',
    'university': 'Stanford University',
    'country': 'United States', 'code': 'US', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Computer Science & IT', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-01-05',
    'amount': 65000.0,
    'description': 'Stanford EE is a premier program in Silicon Valley. Students have access to world-class research labs and industry connections. Financial aid available based on demonstrated need.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=electrical+engineering&targetCountry=US',
    'tags': ['usa', 'bachelor', 'ee', 'stanford', 'stem'],
  },
  {
    'title': 'Bachelor of Business Administration',
    'university': 'New York University (Stern)',
    'country': 'United States', 'code': 'US', 'degree': 'Bachelor',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2026-01-15',
    'amount': 58000.0,
    'description': 'NYU Stern\'s BBA is a top-ranked business undergraduate program located in the heart of New York City. International students have access to merit-based scholarships and NYC\'s vast financial industry network.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=business+administration&targetCountry=US',
    'tags': ['usa', 'bachelor', 'business', 'nyu', 'nyc'],
  },
  {
    'title': 'BSc Biomedical Engineering',
    'university': 'Johns Hopkins University',
    'country': 'United States', 'code': 'US', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Health & Medicine', 'Natural Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-02',
    'amount': 62000.0,
    'description': 'Johns Hopkins is #1 in Biomedical Engineering. The university meets 100% of demonstrated financial need for all admitted students including internationals.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=biomedical+engineering&targetCountry=US',
    'tags': ['usa', 'bachelor', 'biomedical', 'johns-hopkins', 'need-blind'],
  },
  {
    'title': 'Bachelor of Science in Data Science',
    'university': 'University of California, Berkeley',
    'country': 'United States', 'code': 'US', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Mathematics', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2025-11-30',
    'amount': 45000.0,
    'description': 'UC Berkeley\'s Data Science major is a flagship interdisciplinary program. California public university with competitive tuition for international students. Multiple merit scholarships available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=data+science&targetCountry=US',
    'tags': ['usa', 'bachelor', 'datascience', 'uc-berkeley', 'california'],
  },
  {
    'title': 'BSc Psychology',
    'university': 'University of Michigan',
    'country': 'United States', 'code': 'US', 'degree': 'Bachelor',
    'field': 'Social Sciences',
    'fields': ['Social Sciences', 'Health & Medicine', 'Natural Sciences'],
    'funding': 'Partial',
    'deadline': '2026-02-01',
    'amount': 52000.0,
    'description': 'University of Michigan offers a comprehensive psychology undergraduate program with strong research opportunities. International students may qualify for merit-based scholarships.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=psychology&targetCountry=US',
    'tags': ['usa', 'bachelor', 'psychology', 'michigan', 'research'],
  },
  {
    'title': 'Bachelor of Architecture',
    'university': 'Cornell University',
    'country': 'United States', 'code': 'US', 'degree': 'Bachelor',
    'field': 'Arts & Humanities',
    'fields': ['Arts & Humanities', 'Engineering & Technology', 'Environmental Studies'],
    'funding': 'Varies',
    'deadline': '2026-01-02',
    'amount': 68000.0,
    'description': 'Cornell AAP offers one of the most prestigious architecture programs in the USA. Five-year professional degree with studio-based learning and international travel opportunities.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=architecture&targetCountry=US',
    'tags': ['usa', 'bachelor', 'architecture', 'cornell', 'ivy-league'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇺🇸 UNITED STATES — Master & PhD
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'Master of Business Administration (MBA)',
    'university': 'University of Pennsylvania (Wharton)',
    'country': 'United States', 'code': 'US', 'degree': 'Master',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2026-03-15',
    'amount': 80000.0,
    'description': 'Wharton MBA is consistently ranked #1 in the world. Two-year program with access to 100,000+ alumni network. Fellowship opportunities available.',
    'applyUrl': 'https://www.mastersportal.com/search/master?q=mba&targetCountry=US',
    'tags': ['usa', 'master', 'mba', 'wharton', 'top-ranked'],
  },
  {
    'title': 'PhD in Computer Science',
    'university': 'Carnegie Mellon University',
    'country': 'United States', 'code': 'US', 'degree': 'PhD',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2025-12-15',
    'amount': 45000.0,
    'description': 'CMU CS PhD is fully funded with stipend + tuition waiver. Specializations in AI, ML, robotics, security, and more. Students work directly with world-renowned faculty.',
    'applyUrl': 'https://www.phdportal.com/search/phd?q=computer+science&targetCountry=US',
    'tags': ['usa', 'phd', 'cs', 'cmu', 'fully-funded', 'ai', 'ml'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇬🇧 UNITED KINGDOM — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc Computer Science',
    'university': 'University of Oxford',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Mathematics', 'Engineering & Technology'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 35000.0,
    'description': 'Oxford\'s Computer Science degree is 3 years and internationally recognized. International students may apply for the Oxford-Weidenfeld-Hoffmann Scholarship and Clarendon Fund.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=GB',
    'tags': ['uk', 'bachelor', 'cs', 'oxford', 'russell-group'],
  },
  {
    'title': 'BSc Mathematics',
    'university': 'University of Cambridge',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Bachelor',
    'field': 'Mathematics',
    'fields': ['Mathematics', 'Natural Sciences', 'Computer Science & IT'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 33000.0,
    'description': 'Cambridge Mathematics (called Mathematical Tripos) is the most rigorous math degree in the world. International students can apply for Cambridge Trust scholarships.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=mathematics&targetCountry=GB',
    'tags': ['uk', 'bachelor', 'mathematics', 'cambridge', 'tripos'],
  },
  {
    'title': 'BA Business Management',
    'university': 'University of Manchester',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Bachelor',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Varies',
    'deadline': '2026-06-30',
    'amount': 22000.0,
    'description': 'Manchester Business School\'s undergraduate program is AACSB-accredited. Alliance Manchester offers Global Futures Scholarship for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=business&targetCountry=GB',
    'tags': ['uk', 'bachelor', 'business', 'manchester', 'aacsb'],
  },
  {
    'title': 'BSc Biomedical Science',
    'university': 'University College London (UCL)',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Bachelor',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Natural Sciences', 'Engineering & Technology'],
    'funding': 'Varies',
    'deadline': '2026-01-29',
    'amount': 29000.0,
    'description': 'UCL\'s Biomedical Science degree is one of the top in the UK. Ranked #8 in the world. UCL Global Engagement Scholarships available for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=biomedical+science&targetCountry=GB',
    'tags': ['uk', 'bachelor', 'biomedical', 'ucl', 'london'],
  },
  {
    'title': 'LLB Law',
    'university': 'London School of Economics (LSE)',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Bachelor',
    'field': 'Law',
    'fields': ['Law', 'Social Sciences', 'Economics & Finance'],
    'funding': 'Varies',
    'deadline': '2026-01-25',
    'amount': 23000.0,
    'description': 'LSE Law is globally ranked top 5. The 3-year LLB covers all aspects of English law. LSE Excellence Award offers partial funding to international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=law&targetCountry=GB',
    'tags': ['uk', 'bachelor', 'law', 'lse', 'london'],
  },
  {
    'title': 'BEng Mechanical Engineering',
    'university': 'Imperial College London',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Natural Sciences', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-01-29',
    'amount': 36000.0,
    'description': 'Imperial College is ranked #6 in the world. The MEng (4-year) in Mechanical Engineering leads to a Masters-level qualification. President\'s Scholarships available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=mechanical+engineering&targetCountry=GB',
    'tags': ['uk', 'bachelor', 'mechanical-engineering', 'imperial', 'meng'],
  },
  {
    'title': 'BSc Economics',
    'university': 'University of Warwick',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Bachelor',
    'field': 'Economics & Finance',
    'fields': ['Economics & Finance', 'Social Sciences', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-01-25',
    'amount': 24000.0,
    'description': 'Warwick Economics is ranked top 10 in the UK. The 3-year BSc covers micro, macro, econometrics. International Excellence Scholarships of up to £5,000 available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=economics&targetCountry=GB',
    'tags': ['uk', 'bachelor', 'economics', 'warwick', 'russell-group'],
  },
  {
    'title': 'BSc Nursing',
    'university': 'King\'s College London',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Bachelor',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2026-01-29',
    'amount': 21000.0,
    'description': 'KCL\'s nursing program is one of the best in the UK with strong clinical placement links to Guy\'s and St Thomas\' NHS hospitals.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=nursing&targetCountry=GB',
    'tags': ['uk', 'bachelor', 'nursing', 'kcl', 'nhs'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇨🇦 CANADA — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'Bachelor of Computer Science',
    'university': 'University of Toronto',
    'country': 'Canada', 'code': 'CA', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Mathematics', 'Engineering & Technology'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 48000.0,
    'description': 'U of T CS is consistently ranked #1 in Canada and top 15 worldwide. Specializations in AI, software engineering, and computational biology. Lester B. Pearson Scholarship available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=CA',
    'tags': ['canada', 'bachelor', 'cs', 'toronto', 'pearson-scholarship'],
  },
  {
    'title': 'Bachelor of Commerce',
    'university': 'University of British Columbia (UBC)',
    'country': 'Canada', 'code': 'CA', 'degree': 'Bachelor',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 42000.0,
    'description': 'UBC Sauder School of Business BCom is highly ranked. Located in beautiful Vancouver. International Major Entrance Scholarship of up to CAD 10,000 available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=commerce&targetCountry=CA',
    'tags': ['canada', 'bachelor', 'commerce', 'ubc', 'vancouver'],
  },
  {
    'title': 'BEng Civil Engineering',
    'university': 'McGill University',
    'country': 'Canada', 'code': 'CA', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Natural Sciences', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 44000.0,
    'description': 'McGill Engineering is the most internationally recognized Canadian engineering school. Merit Scholarships of CAD 5,000–12,000 per year available for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=civil+engineering&targetCountry=CA',
    'tags': ['canada', 'bachelor', 'engineering', 'mcgill', 'montreal'],
  },
  {
    'title': 'BSc Nursing',
    'university': 'University of Alberta',
    'country': 'Canada', 'code': 'CA', 'degree': 'Bachelor',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Social Sciences', 'Natural Sciences'],
    'funding': 'Partial',
    'deadline': '2026-03-01',
    'amount': 35000.0,
    'description': 'U of A Nursing is ranked #1 in Canada. Four-year BSc Nursing program with clinical placements. International scholarships of up to CAD 15,000 available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=nursing&targetCountry=CA',
    'tags': ['canada', 'bachelor', 'nursing', 'alberta', 'edmonton'],
  },
  {
    'title': 'Bachelor of Arts in International Relations',
    'university': 'Carleton University',
    'country': 'Canada', 'code': 'CA', 'degree': 'Bachelor',
    'field': 'Social Sciences',
    'fields': ['Social Sciences', 'Arts & Humanities', 'Language & Culture'],
    'funding': 'Partial',
    'deadline': '2026-04-01',
    'amount': 28000.0,
    'description': 'Located in Ottawa (Canada\'s capital), Carleton\'s IR program benefits from proximity to government and international organizations. Strong co-op and internship opportunities.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=international+relations&targetCountry=CA',
    'tags': ['canada', 'bachelor', 'international-relations', 'carleton', 'ottawa'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇦🇺 AUSTRALIA — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'Bachelor of Engineering (Honours)',
    'university': 'University of Melbourne',
    'country': 'Australia', 'code': 'AU', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Natural Sciences', 'Computer Science & IT'],
    'funding': 'Varies',
    'deadline': '2026-05-31',
    'amount': 48000.0,
    'description': 'Melbourne Engineering is ranked #33 in the world. 3-year undergraduate + 2-year Masters pathway (Melbourne Model). Graduate Access Melbourne Scholarship available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=engineering&targetCountry=AU',
    'tags': ['australia', 'bachelor', 'engineering', 'melbourne', 'go8'],
  },
  {
    'title': 'Bachelor of Business',
    'university': 'University of Sydney',
    'country': 'Australia', 'code': 'AU', 'degree': 'Bachelor',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Varies',
    'deadline': '2026-01-31',
    'amount': 45000.0,
    'description': 'Sydney Business School is triple-accredited (AACSB, EQUIS, AMBA). Three-year program with specializations. Vice-Chancellor\'s International Scholarship of 50% tuition available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=business&targetCountry=AU',
    'tags': ['australia', 'bachelor', 'business', 'sydney', 'scholarship-50'],
  },
  {
    'title': 'BSc Computer Science',
    'university': 'Australian National University (ANU)',
    'country': 'Australia', 'code': 'AU', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Mathematics', 'Engineering & Technology'],
    'funding': 'Partial',
    'deadline': '2026-04-30',
    'amount': 40000.0,
    'description': 'ANU CS is ranked #1 in Australia. Three-year bachelor with research opportunities. ANU College of Engineering & Computer Science offers scholarships to high achievers.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=AU',
    'tags': ['australia', 'bachelor', 'cs', 'anu', 'canberra'],
  },
  {
    'title': 'Bachelor of Health Sciences',
    'university': 'University of Queensland (UQ)',
    'country': 'Australia', 'code': 'AU', 'degree': 'Bachelor',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Natural Sciences', 'Social Sciences'],
    'funding': 'Varies',
    'deadline': '2026-08-31',
    'amount': 44000.0,
    'description': 'UQ Health Sciences is a pathway degree to medicine, pharmacy and allied health. UQ Excellence Scholarship covering 25-100% of tuition available for top international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=health+sciences&targetCountry=AU',
    'tags': ['australia', 'bachelor', 'health', 'uq', 'brisbane'],
  },
  {
    'title': 'Bachelor of Laws (LLB)',
    'university': 'University of New South Wales (UNSW)',
    'country': 'Australia', 'code': 'AU', 'degree': 'Bachelor',
    'field': 'Law',
    'fields': ['Law', 'Social Sciences', 'Arts & Humanities'],
    'funding': 'Varies',
    'deadline': '2026-01-31',
    'amount': 42000.0,
    'description': 'UNSW Law is ranked #1 in Australia and top 20 globally. The 4-year LLB provides a pathway to legal practice in Australia and overseas. International scholarships up to AUD 10,000.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=law&targetCountry=AU',
    'tags': ['australia', 'bachelor', 'law', 'unsw', 'sydney'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇩🇰 DENMARK — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Engineering (General)',
    'university': 'Technical University of Denmark (DTU)',
    'country': 'Denmark', 'code': 'DK', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Natural Sciences', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-03-15',
    'amount': 14000.0,
    'description': 'DTU is ranked #1 in Scandinavia for engineering. The 3-year BSc Eng is taught partly in Danish and partly in English. EU/EEA students pay no tuition fees. DTU Excellence Scholarships available for non-EU students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=engineering&targetCountry=DK',
    'tags': ['denmark', 'bachelor', 'engineering', 'dtu', 'scandinavia'],
  },
  {
    'title': 'BSc in Computer Science',
    'university': 'University of Copenhagen (UCPH)',
    'country': 'Denmark', 'code': 'DK', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Mathematics', 'Engineering & Technology'],
    'funding': 'Varies',
    'deadline': '2026-03-15',
    'amount': 12000.0,
    'description': 'UCPH Computer Science is offered in Danish for the bachelor level. UCPH is ranked among the top 100 globally. Exchange programs available through Erasmus+.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=DK',
    'tags': ['denmark', 'bachelor', 'cs', 'ucph', 'copenhagen'],
  },
  {
    'title': 'BSc in Business Administration',
    'university': 'Copenhagen Business School (CBS)',
    'country': 'Denmark', 'code': 'DK', 'degree': 'Bachelor',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Varies',
    'deadline': '2026-07-01',
    'amount': 10000.0,
    'description': 'CBS is one of the largest business schools in Europe. BSc in Business Administration & Information Systems is fully taught in English. CBS Scholarship available for non-EU students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=business+administration&targetCountry=DK',
    'tags': ['denmark', 'bachelor', 'business', 'cbs', 'copenhagen'],
  },
  {
    'title': 'BSc in Pharmacy',
    'university': 'University of Copenhagen (UCPH)',
    'country': 'Denmark', 'code': 'DK', 'degree': 'Bachelor',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Natural Sciences', 'Chemistry'],
    'funding': 'Varies',
    'deadline': '2026-07-01',
    'amount': 12000.0,
    'description': 'UCPH Pharmacy is one of the oldest pharmacy schools in Scandinavia with strong industry links to Novo Nordisk and LEO Pharma. Primarily taught in Danish.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=pharmacy&targetCountry=DK',
    'tags': ['denmark', 'bachelor', 'pharmacy', 'ucph', 'novo-nordisk'],
  },
  {
    'title': 'BSc in Environmental Engineering',
    'university': 'Aalborg University (AAU)',
    'country': 'Denmark', 'code': 'DK', 'degree': 'Bachelor',
    'field': 'Environmental Studies',
    'fields': ['Environmental Studies', 'Engineering & Technology', 'Natural Sciences'],
    'funding': 'Partial',
    'deadline': '2026-07-15',
    'amount': 13000.0,
    'description': 'Aalborg University uses Problem-Based Learning (PBL) - a unique pedagogical model. Environmental Engineering is highly regarded. AAU Scholarship for international students covers partial fees.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=environmental+engineering&targetCountry=DK',
    'tags': ['denmark', 'bachelor', 'environment', 'aau', 'pbl'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇸🇪 SWEDEN — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Computer Science',
    'university': 'KTH Royal Institute of Technology',
    'country': 'Sweden', 'code': 'SE', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 15000.0,
    'description': 'KTH is Sweden\'s leading technical university and ranked top 100 globally. BSc in Computer Science is taught partly in English. KTH Scholarship for non-EU/EEA students covers 75-100% of tuition.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=SE',
    'tags': ['sweden', 'bachelor', 'cs', 'kth', 'stockholm'],
  },
  {
    'title': 'BSc in Business & Economics',
    'university': 'Stockholm School of Economics (SSE)',
    'country': 'Sweden', 'code': 'SE', 'degree': 'Bachelor',
    'field': 'Economics & Finance',
    'fields': ['Economics & Finance', 'Business & Management', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2026-01-15',
    'amount': 18000.0,
    'description': 'SSE is the most prestigious business school in Scandinavia. The BSc in Business & Economics is highly competitive and taught in English. SSE Merit Scholarship available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=economics&targetCountry=SE',
    'tags': ['sweden', 'bachelor', 'economics', 'sse', 'stockholm'],
  },
  {
    'title': 'BSc in Engineering Physics',
    'university': 'Chalmers University of Technology',
    'country': 'Sweden', 'code': 'SE', 'degree': 'Bachelor',
    'field': 'Natural Sciences',
    'fields': ['Natural Sciences', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 16000.0,
    'description': 'Chalmers is ranked among top 100 for engineering. Engineering Physics combines advanced mathematics with physics and engineering. Chalmers Excellence Scholarship for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=engineering+physics&targetCountry=SE',
    'tags': ['sweden', 'bachelor', 'physics', 'chalmers', 'gothenburg'],
  },
  {
    'title': 'BSc in Environmental Science',
    'university': 'Lund University',
    'country': 'Sweden', 'code': 'SE', 'degree': 'Bachelor',
    'field': 'Environmental Studies',
    'fields': ['Environmental Studies', 'Natural Sciences', 'Social Sciences'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 12000.0,
    'description': 'Lund University is Sweden\'s top research university. Environmental Science BSc covers climate, ecology and sustainability. Lund Global Scholarship available for non-EU students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=environmental+science&targetCountry=SE',
    'tags': ['sweden', 'bachelor', 'environment', 'lund', 'climate'],
  },
  {
    'title': 'BSc in Nursing',
    'university': 'Karolinska Institutet',
    'country': 'Sweden', 'code': 'SE', 'degree': 'Bachelor',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Natural Sciences', 'Social Sciences'],
    'funding': 'Varies',
    'deadline': '2026-01-15',
    'amount': 16000.0,
    'description': 'Karolinska is the world\'s most prestigious medical university (home of the Nobel Assembly). BSc Nursing is taught in Swedish but international track available. Scholarships for exceptional students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=nursing&targetCountry=SE',
    'tags': ['sweden', 'bachelor', 'nursing', 'karolinska', 'nobel'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇳🇱 NETHERLANDS — Bachelor Programs (Most in English!)
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Computer Science',
    'university': 'Delft University of Technology (TU Delft)',
    'country': 'Netherlands', 'code': 'NL', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-04-01',
    'amount': 16000.0,
    'description': 'TU Delft is ranked #13 in the world for Engineering. BSc CS is taught in Dutch (English track available). Holland Scholarship of €5,000 available for non-EEA students. Top employer network.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=NL',
    'tags': ['netherlands', 'bachelor', 'cs', 'tudelft', 'holland-scholarship'],
  },
  {
    'title': 'BSc in Psychology',
    'university': 'University of Amsterdam (UvA)',
    'country': 'Netherlands', 'code': 'NL', 'degree': 'Bachelor',
    'field': 'Social Sciences',
    'fields': ['Social Sciences', 'Health & Medicine', 'Arts & Humanities'],
    'funding': 'Varies',
    'deadline': '2026-04-01',
    'amount': 12000.0,
    'description': 'UvA Psychology is one of the most popular programs in the Netherlands. The English-taught BSc covers all major subfields. Holland Scholarship available. Strong research focus.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=psychology&targetCountry=NL',
    'tags': ['netherlands', 'bachelor', 'psychology', 'uva', 'amsterdam'],
  },
  {
    'title': 'BSc in Global Law',
    'university': 'Tilburg University',
    'country': 'Netherlands', 'code': 'NL', 'degree': 'Bachelor',
    'field': 'Law',
    'fields': ['Law', 'Social Sciences', 'Economics & Finance'],
    'funding': 'Partial',
    'deadline': '2026-06-01',
    'amount': 11000.0,
    'description': 'Tilburg\'s Global Law program is unique in Europe — taught entirely in English and covering international and comparative law. Tilburg Excellence Scholarship available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=law&targetCountry=NL',
    'tags': ['netherlands', 'bachelor', 'law', 'tilburg', 'global-law'],
  },
  {
    'title': 'BSc in International Business',
    'university': 'Maastricht University',
    'country': 'Netherlands', 'code': 'NL', 'degree': 'Bachelor',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2026-05-01',
    'amount': 14000.0,
    'description': 'Maastricht IB is the most internationally diverse program in the Netherlands with 100+ nationalities. Problem-Based Learning (PBL) approach. Merit scholarship available for outstanding international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=international+business&targetCountry=NL',
    'tags': ['netherlands', 'bachelor', 'ib', 'maastricht', 'pbl'],
  },
  {
    'title': 'BSc in Life Sciences & Technology',
    'university': 'Wageningen University & Research',
    'country': 'Netherlands', 'code': 'NL', 'degree': 'Bachelor',
    'field': 'Agriculture & Forestry',
    'fields': ['Agriculture & Forestry', 'Natural Sciences', 'Engineering & Technology'],
    'funding': 'Varies',
    'deadline': '2026-05-01',
    'amount': 13000.0,
    'description': 'Wageningen is ranked #1 in the world for Agriculture & Forestry. Life Sciences & Technology covers food tech, environmental science, and biotech. Holland Scholarship available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=life+sciences&targetCountry=NL',
    'tags': ['netherlands', 'bachelor', 'life-sciences', 'wageningen', 'top-1-agriculture'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇹🇷 TURKEY — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Computer Engineering',
    'university': 'Bogazici University',
    'country': 'Turkey', 'code': 'TR', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2026-02-20',
    'amount': 8000.0,
    'description': 'Bogazici is Turkey\'s most prestigious university. CS Engineering is taught entirely in English. Türkiye Burslari (Government Scholarship) covers full tuition + monthly stipend + accommodation for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+engineering&targetCountry=TR',
    'tags': ['turkey', 'bachelor', 'cs', 'bogazici', 'turkiye-burslari'],
  },
  {
    'title': 'BSc in Industrial Engineering',
    'university': 'Middle East Technical University (METU)',
    'country': 'Turkey', 'code': 'TR', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Business & Management', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2026-02-20',
    'amount': 7000.0,
    'description': 'METU is taught 100% in English and is Turkey\'s leading technical university. Industrial Engineering covers operations, logistics and systems. Türkiye Burslari scholarship available for all international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=industrial+engineering&targetCountry=TR',
    'tags': ['turkey', 'bachelor', 'industrial-engineering', 'metu', 'english-medium'],
  },
  {
    'title': 'BA in International Relations',
    'university': 'Ankara University',
    'country': 'Turkey', 'code': 'TR', 'degree': 'Bachelor',
    'field': 'Social Sciences',
    'fields': ['Social Sciences', 'Arts & Humanities', 'Language & Culture'],
    'funding': 'Fully Funded',
    'deadline': '2026-05-31',
    'amount': 5000.0,
    'description': 'Ankara University is the oldest state university of modern Turkey. International Relations BA is taught in Turkish with an English support program. Türkiye Burslari covers all costs.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=international+relations&targetCountry=TR',
    'tags': ['turkey', 'bachelor', 'international-relations', 'ankara', 'turkiye-burslari'],
  },
  {
    'title': 'BSc in Medicine (MD)',
    'university': 'Hacettepe University',
    'country': 'Turkey', 'code': 'TR', 'degree': 'Bachelor',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Natural Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-02-20',
    'amount': 6000.0,
    'description': 'Hacettepe is ranked #1 in Turkey for Medicine and top 500 globally. 6-year MD program. Türkiye Burslari scholarship covers full tuition + stipend + health insurance for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=medicine&targetCountry=TR',
    'tags': ['turkey', 'bachelor', 'medicine', 'hacettepe', 'md', 'turkiye-burslari'],
  },
  {
    'title': 'BSc in Architecture',
    'university': 'Istanbul Technical University (ITU)',
    'country': 'Turkey', 'code': 'TR', 'degree': 'Bachelor',
    'field': 'Arts & Humanities',
    'fields': ['Arts & Humanities', 'Engineering & Technology', 'Social Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-02-20',
    'amount': 7500.0,
    'description': 'ITU Architecture (founded 1884) is one of the oldest and most respected architecture schools in the world. 5-year program with strong design studio tradition. Türkiye Burslari scholarship available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=architecture&targetCountry=TR',
    'tags': ['turkey', 'bachelor', 'architecture', 'itu', 'design'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇭🇺 HUNGARY — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Computer Science',
    'university': 'Budapest University of Technology and Economics (BME)',
    'country': 'Hungary', 'code': 'HU', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-15',
    'amount': 6500.0,
    'description': 'BME is the oldest technical university in Central Europe (founded 1782). BSc CS is taught in English. Stipendium Hungaricum scholarship covers full tuition + monthly stipend + accommodation + health insurance for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=HU',
    'tags': ['hungary', 'bachelor', 'cs', 'bme', 'stipendium-hungaricum'],
  },
  {
    'title': 'BSc in International Business Economics',
    'university': 'Corvinus University of Budapest',
    'country': 'Hungary', 'code': 'HU', 'degree': 'Bachelor',
    'field': 'Economics & Finance',
    'fields': ['Economics & Finance', 'Business & Management', 'Social Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-15',
    'amount': 5500.0,
    'description': 'Corvinus is Hungary\'s top business university. BSc in International Business Economics is 100% English-taught. Stipendium Hungaricum provides full scholarship covering all expenses for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=international+business&targetCountry=HU',
    'tags': ['hungary', 'bachelor', 'economics', 'corvinus', 'stipendium-hungaricum'],
  },
  {
    'title': 'BSc in Electrical Engineering',
    'university': 'Obuda University',
    'country': 'Hungary', 'code': 'HU', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Computer Science & IT', 'Natural Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-02-15',
    'amount': 4500.0,
    'description': 'Obuda University offers English-taught engineering degrees with strong industry links to Bosch, Siemens, and automotive companies in Hungary. Stipendium Hungaricum scholarship available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=electrical+engineering&targetCountry=HU',
    'tags': ['hungary', 'bachelor', 'ee', 'obuda', 'stipendium-hungaricum'],
  },
  {
    'title': 'BA in International Studies',
    'university': 'University of Debrecen',
    'country': 'Hungary', 'code': 'HU', 'degree': 'Bachelor',
    'field': 'Social Sciences',
    'fields': ['Social Sciences', 'Arts & Humanities', 'Language & Culture'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-15',
    'amount': 5000.0,
    'description': 'University of Debrecen is the largest state university in Hungary. BA in International Studies is taught in English. Stipendium Hungaricum covers full tuition, accommodation, and a monthly stipend.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=international+studies&targetCountry=HU',
    'tags': ['hungary', 'bachelor', 'international-studies', 'debrecen', 'stipendium-hungaricum'],
  },
  {
    'title': 'BSc in Medical Imaging',
    'university': 'University of Pécs',
    'country': 'Hungary', 'code': 'HU', 'degree': 'Bachelor',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Natural Sciences', 'Engineering & Technology'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-31',
    'amount': 7000.0,
    'description': 'University of Pécs Medical School is among the oldest universities in Central Europe. Medical Imaging BSc is in English. Stipendium Hungaricum scholarship fully funded including health insurance.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=medical+imaging&targetCountry=HU',
    'tags': ['hungary', 'bachelor', 'medical', 'pecs', 'stipendium-hungaricum'],
  },
  {
    'title': 'BSc in Architecture',
    'university': 'Budapest Metropolitan University',
    'country': 'Hungary', 'code': 'HU', 'degree': 'Bachelor',
    'field': 'Arts & Humanities',
    'fields': ['Arts & Humanities', 'Engineering & Technology', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2026-07-31',
    'amount': 5000.0,
    'description': 'Budapest Met offers a creative architecture program in the heart of Budapest, one of Europe\'s most beautiful cities. English-taught. Partial scholarships for qualified international applicants.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=architecture&targetCountry=HU',
    'tags': ['hungary', 'bachelor', 'architecture', 'budapest-met', 'budapest'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇩🇪 GERMANY — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Computer Science',
    'university': 'Technical University of Munich (TUM)',
    'country': 'Germany', 'code': 'DE', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-05-31',
    'amount': 3000.0,
    'description': 'TUM is Germany\'s top-ranked university and #50 globally. BSc Informatics taught in German (some English tracks). Near-free tuition (only semester fee ~€150). DAAD scholarships available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=DE',
    'tags': ['germany', 'bachelor', 'cs', 'tum', 'free-tuition', 'daad'],
  },
  {
    'title': 'BSc in Engineering Management',
    'university': 'RWTH Aachen University',
    'country': 'Germany', 'code': 'DE', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Business & Management', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-07-15',
    'amount': 2500.0,
    'description': 'RWTH Aachen is Europe\'s #1 technical university. BSc in Engineering Management (Wirtschaftsingenieurwesen) combines engineering and business. Near-free tuition. DAAD scholarships for developing countries.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=engineering&targetCountry=DE',
    'tags': ['germany', 'bachelor', 'engineering', 'rwth', 'daad', 'free-tuition'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇯🇵 JAPAN — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Engineering (MEXT Scholarship)',
    'university': 'University of Tokyo',
    'country': 'Japan', 'code': 'JP', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Natural Sciences', 'Computer Science & IT'],
    'funding': 'Fully Funded',
    'deadline': '2026-05-31',
    'amount': 9000.0,
    'description': 'University of Tokyo is Asia\'s #1 university. MEXT (Japanese Government Scholarship) covers full tuition + monthly stipend of 117,000 yen (~800 USD/month) + airfare. Competitive selection through embassies.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=engineering&targetCountry=JP',
    'tags': ['japan', 'bachelor', 'engineering', 'todai', 'mext', 'government-scholarship'],
  },
  {
    'title': 'BSc in Global Business (English)',
    'university': 'Waseda University',
    'country': 'Japan', 'code': 'JP', 'degree': 'Bachelor',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2026-01-15',
    'amount': 11000.0,
    'description': 'Waseda\'s School of International Liberal Studies (SILS) is 100% English-taught. Popular for international students. Waseda-JASSO scholarship + multiple merit-based awards available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=business&targetCountry=JP',
    'tags': ['japan', 'bachelor', 'business', 'waseda', 'english-taught'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇰🇷 SOUTH KOREA — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Computer Science',
    'university': 'Korea Advanced Institute of Science and Technology (KAIST)',
    'country': 'South Korea', 'code': 'KR', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-07',
    'amount': 15000.0,
    'description': 'KAIST is Asia\'s #1 engineering school. BSc CS is taught entirely in English. All admitted international students receive full tuition waiver + monthly living allowance of KRW 300,000.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=KR',
    'tags': ['korea', 'bachelor', 'cs', 'kaist', 'fully-funded', 'gks'],
  },
  {
    'title': 'BSc in Business Administration (GKS)',
    'university': 'Seoul National University (SNU)',
    'country': 'South Korea', 'code': 'KR', 'degree': 'Bachelor',
    'field': 'Business & Management',
    'fields': ['Business & Management', 'Economics & Finance', 'Social Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-02-28',
    'amount': 12000.0,
    'description': 'SNU is South Korea\'s most prestigious university. Government Scholarship Program (GKS) covers full tuition + accommodation + monthly stipend + Korean language courses for international students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=business&targetCountry=KR',
    'tags': ['korea', 'bachelor', 'business', 'snu', 'gks', 'government-scholarship'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇸🇬 SINGAPORE — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Computer Science',
    'university': 'National University of Singapore (NUS)',
    'country': 'Singapore', 'code': 'SG', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-03-03',
    'amount': 25000.0,
    'description': 'NUS CS is ranked #5 globally and #1 in Asia. Strong links to Singapore\'s booming tech industry. ASEAN Undergraduate Scholarship and Science & Technology Scholarship available.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=computer+science&targetCountry=SG',
    'tags': ['singapore', 'bachelor', 'cs', 'nus', 'asean-scholarship'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇳🇴 NORWAY — Bachelor Programs (Free Tuition!)
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Petroleum Engineering (Free)',
    'university': 'Norwegian University of Science and Technology (NTNU)',
    'country': 'Norway', 'code': 'NO', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Natural Sciences', 'Environmental Studies'],
    'funding': 'Varies',
    'deadline': '2026-04-15',
    'amount': 0.0,
    'description': 'Norway offers FREE tuition at public universities to all students worldwide. NTNU Petroleum Engineering is world-class. Students pay only ~NOK 500 (approx. 50 USD) semester fee. Living costs apply.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=petroleum+engineering&targetCountry=NO',
    'tags': ['norway', 'bachelor', 'petroleum', 'ntnu', 'free-tuition', 'no-fees'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇫🇮 FINLAND — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Information Technology',
    'university': 'Aalto University',
    'country': 'Finland', 'code': 'FI', 'degree': 'Bachelor',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Business & Management'],
    'funding': 'Partial',
    'deadline': '2026-01-22',
    'amount': 12000.0,
    'description': 'Aalto University is Finland\'s leading science and technology university. BSc IT integrates tech and business. Aalto University Scholarship of 50-100% tuition available for non-EU/EEA students.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=information+technology&targetCountry=FI',
    'tags': ['finland', 'bachelor', 'it', 'aalto', 'scholarship'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇨🇳 CHINA — Bachelor Programs (CSC Scholarships)
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Engineering (CSC Scholarship)',
    'university': 'Tsinghua University',
    'country': 'China', 'code': 'CN', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Computer Science & IT', 'Natural Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-03-31',
    'amount': 8000.0,
    'description': 'Tsinghua is China\'s #1 university and top 20 globally. Chinese Government Scholarship (CSC) covers full tuition + accommodation + monthly stipend + health insurance. Apply via CSC or Chinese embassies.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=engineering&targetCountry=CN',
    'tags': ['china', 'bachelor', 'engineering', 'tsinghua', 'csc-scholarship', 'fully-funded'],
  },

  // ══════════════════════════════════════════════════════════════
  // 🇸🇦 SAUDI ARABIA — Bachelor Programs
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'BSc in Petroleum Engineering',
    'university': 'King Fahd University of Petroleum and Minerals (KFUPM)',
    'country': 'Saudi Arabia', 'code': 'SA', 'degree': 'Bachelor',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Natural Sciences', 'Chemistry'],
    'funding': 'Fully Funded',
    'deadline': '2026-06-01',
    'amount': 30000.0,
    'description': 'KFUPM is the world\'s leading petroleum engineering university. Full scholarships available covering tuition + housing + meals + stipend. English-medium instruction. Strong industry connections to Saudi Aramco.',
    'applyUrl': 'https://www.bachelorsportal.com/search/bachelor?q=petroleum+engineering&targetCountry=SA',
    'tags': ['saudi', 'bachelor', 'petroleum', 'kfupm', 'aramco', 'fully-funded'],
  },

  // ══════════════════════════════════════════════════════════════
  // MASTER PROGRAMS (Key Countries)
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'MSc in Artificial Intelligence',
    'university': 'KTH Royal Institute of Technology',
    'country': 'Sweden', 'code': 'SE', 'degree': 'Master',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Partial',
    'deadline': '2026-01-15',
    'amount': 16000.0,
    'description': 'KTH MSc AI is one of Europe\'s top AI programs. 2-year English-taught. KTH Scholarship covers up to 100% of tuition for outstanding non-EU students.',
    'applyUrl': 'https://www.mastersportal.com/search/master?q=artificial+intelligence&targetCountry=SE',
    'tags': ['sweden', 'master', 'ai', 'kth', 'scholarship'],
  },
  {
    'title': 'MSc in Data Science',
    'university': 'University of Amsterdam (UvA)',
    'country': 'Netherlands', 'code': 'NL', 'degree': 'Master',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Mathematics', 'Social Sciences'],
    'funding': 'Partial',
    'deadline': '2026-06-01',
    'amount': 14000.0,
    'description': 'UvA MSc Data Science is a top European program. 2-year research-oriented master. Holland Scholarship + Amsterdam Merit Scholarship available for exceptional international students.',
    'applyUrl': 'https://www.mastersportal.com/search/master?q=data+science&targetCountry=NL',
    'tags': ['netherlands', 'master', 'data-science', 'uva', 'amsterdam'],
  },
  {
    'title': 'MSc in Finance',
    'university': 'University of Oxford (Said Business School)',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'Master',
    'field': 'Economics & Finance',
    'fields': ['Economics & Finance', 'Business & Management', 'Mathematics'],
    'funding': 'Varies',
    'deadline': '2026-03-15',
    'amount': 45000.0,
    'description': 'Oxford MSc Finance is a world-leading 1-year program. Clarendon Fund and Said Foundation Scholarships provide partial to full funding for outstanding international students.',
    'applyUrl': 'https://www.mastersportal.com/search/master?q=finance&targetCountry=GB',
    'tags': ['uk', 'master', 'finance', 'oxford', 'clarendon'],
  },
  {
    'title': 'MSc in Computer Science',
    'university': 'Technical University of Munich (TUM)',
    'country': 'Germany', 'code': 'DE', 'degree': 'Master',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Partial',
    'deadline': '2026-05-31',
    'amount': 4000.0,
    'description': 'TUM MSc CS is English-taught and world-ranked. Near-free tuition. DAAD scholarships of €750/month available for international students. Strong Munich tech industry connections.',
    'applyUrl': 'https://www.mastersportal.com/search/master?q=computer+science&targetCountry=DE',
    'tags': ['germany', 'master', 'cs', 'tum', 'daad', 'free-tuition'],
  },
  {
    'title': 'MSc in Artificial Intelligence',
    'university': 'Budapest University of Technology (BME)',
    'country': 'Hungary', 'code': 'HU', 'degree': 'Master',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-15',
    'amount': 7000.0,
    'description': 'BME MSc AI is taught in English and is Hungary\'s most competitive program. Stipendium Hungaricum fully funds the 2-year master including housing and monthly allowance.',
    'applyUrl': 'https://www.mastersportal.com/search/master?q=artificial+intelligence&targetCountry=HU',
    'tags': ['hungary', 'master', 'ai', 'bme', 'stipendium-hungaricum', 'fully-funded'],
  },
  {
    'title': 'MSc in Computer Science (MEXT)',
    'university': 'Kyoto University',
    'country': 'Japan', 'code': 'JP', 'degree': 'Master',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Natural Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-05-31',
    'amount': 10000.0,
    'description': 'Kyoto University is Japan\'s #2 university. MEXT scholarship fully funds MSc CS including stipend ¥144,000/month. Research-based master with strong publications record.',
    'applyUrl': 'https://www.mastersportal.com/search/master?q=computer+science&targetCountry=JP',
    'tags': ['japan', 'master', 'cs', 'kyoto', 'mext', 'fully-funded'],
  },

  // ══════════════════════════════════════════════════════════════
  // PhD PROGRAMS (Key Countries)
  // ══════════════════════════════════════════════════════════════
  {
    'title': 'PhD in Computer Science',
    'university': 'University of Cambridge',
    'country': 'United Kingdom', 'code': 'GB', 'degree': 'PhD',
    'field': 'Computer Science & IT',
    'fields': ['Computer Science & IT', 'Engineering & Technology', 'Mathematics'],
    'funding': 'Fully Funded',
    'deadline': '2026-05-31',
    'amount': 20000.0,
    'description': 'Cambridge CS PhD is world-renowned. Fully funded positions available via Gates Cambridge Scholarship (covers fees + stipend + expenses). 3-4 year program.',
    'applyUrl': 'https://www.phdportal.com/search/phd?q=computer+science&targetCountry=GB',
    'tags': ['uk', 'phd', 'cs', 'cambridge', 'gates-cambridge', 'fully-funded'],
  },
  {
    'title': 'PhD in Engineering (Stipendium Hungaricum)',
    'university': 'Budapest University of Technology (BME)',
    'country': 'Hungary', 'code': 'HU', 'degree': 'PhD',
    'field': 'Engineering & Technology',
    'fields': ['Engineering & Technology', 'Natural Sciences', 'Computer Science & IT'],
    'funding': 'Fully Funded',
    'deadline': '2026-01-15',
    'amount': 8000.0,
    'description': 'BME PhD in Engineering is fully funded through Stipendium Hungaricum. Covers tuition + accommodation + monthly allowance + health insurance for 3-4 years.',
    'applyUrl': 'https://www.phdportal.com/search/phd?q=engineering&targetCountry=HU',
    'tags': ['hungary', 'phd', 'engineering', 'bme', 'stipendium-hungaricum', 'fully-funded'],
  },
  {
    'title': 'PhD in Physics (DAAD)',
    'university': 'University of Heidelberg',
    'country': 'Germany', 'code': 'DE', 'degree': 'PhD',
    'field': 'Natural Sciences',
    'fields': ['Natural Sciences', 'Mathematics', 'Engineering & Technology'],
    'funding': 'Fully Funded',
    'deadline': '2026-10-01',
    'amount': 25000.0,
    'description': 'Heidelberg is Germany\'s oldest university and #1 for Physics. DAAD scholarship for PhD covers €1,300/month + research budget. Collaborative with CERN and major physics labs.',
    'applyUrl': 'https://www.phdportal.com/search/phd?q=physics&targetCountry=DE',
    'tags': ['germany', 'phd', 'physics', 'heidelberg', 'daad', 'cern'],
  },
  {
    'title': 'PhD in Neuroscience (Erasmus Mundus)',
    'university': 'Erasmus University Rotterdam',
    'country': 'Netherlands', 'code': 'NL', 'degree': 'PhD',
    'field': 'Health & Medicine',
    'fields': ['Health & Medicine', 'Natural Sciences', 'Social Sciences'],
    'funding': 'Fully Funded',
    'deadline': '2026-03-15',
    'amount': 30000.0,
    'description': 'Erasmus Mundus Joint Doctorate in Neuroscience provides €2,500/month salary + full tuition at multiple European universities. One of Europe\'s most prestigious PhD fellowships.',
    'applyUrl': 'https://www.phdportal.com/search/phd?q=neuroscience&targetCountry=NL',
    'tags': ['netherlands', 'phd', 'neuroscience', 'erasmus-mundus', 'fully-funded', 'europe'],
  },
];

// ────────────────────────────────────────────────────────────────
// AUTO-SYNC ENGINE
// ────────────────────────────────────────────────────────────────
class SyncEngine {
  static Timer? _timer;
  static bool   _busy = false;

  static void start() {
    _run();
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _run());
  }

  static void stop() => _timer?.cancel();

  static Future<void> forceNow() async {
    _busy = false;
    final p = await SharedPreferences.getInstance();
    await p.setInt('_ls', 0);
    await _run();
  }

  static Future<void> _run() async {
    if (_busy) return;
    _busy = true;
    try {
      final p   = await SharedPreferences.getInstance();
      final ls  = p.getInt('_ls') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - ls < 6 * 3600 * 1000) return;

      await _seed();
      await p.setInt('_ls', now);
    } catch (e) { debugPrint('Sync error: $e'); }
    finally { _busy = false; }
  }

  static Future<void> _seed() async {
    final col = FirebaseFirestore.instance.collection('scholarships');
    for (final s in _kData) {
      try {
        final id   = _docId(s['title'] as String);
        final code = s['code'] as String;
        // Use set with merge:true so changes in _kData (deadline, amount, etc.)
        // are reflected in Firestore on next sync, not just on first write.
        await col.doc(id).set({
          'title': s['title'],         'university': s['university'],
          'country': s['country'],     'code': code,
          'flag': _flag(code),
          'degree': s['degree'],       'field': s['field'],
          'fields': s['fields'],
          'funding': s['funding'],     'deadline': s['deadline'] ?? '',
          'description': s['description'], 'applyUrl': s['applyUrl'],
          'amount': s['amount'],       'isNew': true,
          'addedAt': Timestamp.fromDate(DateTime.now()),
          'tags': s['tags'],           'source': 'bachelor-portal',
        }, SetOptions(merge: true));
      } catch (e) { debugPrint('Seed error: $e'); }
    }
  }
}

// ════════════════════════════════════════════════════════════════
// MAIN
// ════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  SyncEngine.start();
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ScholarSearch',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: C.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: C.primary),
      cardTheme: CardThemeData(
        color: C.white, elevation: 2,
        shadowColor: C.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    home: const _Splash(),
  );
}

// ── SPLASH ─────────────────────────────────────────────────────
class _Splash extends StatefulWidget {
  const _Splash();
  @override State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: 900.ms)..forward();
  late final AnimationController _p = AnimationController(vsync: this, duration: 2800.ms);

  @override
  void initState() {
    super.initState();
    Future.delayed(400.ms, _p.forward);
    Future.delayed(3400.ms, () {
      if (!mounted) return;
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, anim, __) => const _Home(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: 350.ms,
      ));
    });
  }

  @override
  void dispose() { _a.dispose(); _p.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: C.grad),
      child: SafeArea(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          AnimatedBuilder(animation: _a, builder: (_, __) => Transform.scale(
            scale: Curves.elasticOut.transform(_a.value),
            child: Opacity(opacity: _a.value.clamp(0.0, 1.0), child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: C.white, borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 12))],
              ),
              child: const Icon(Icons.school_rounded, size: 66, color: C.primary),
            )),
          )),
          const SizedBox(height: 28),
          AnimatedBuilder(animation: _a, builder: (_, __) => Opacity(
            opacity: _a.value.clamp(0.0, 1.0),
            child: Column(children: [
              const Text('ScholarSearch',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: C.white, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('500+ Programs  ·  60+ Countries',
                style: TextStyle(color: C.white.withValues(alpha: 0.8), fontSize: 14)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: C.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
                child: const Text('🎓  Bachelor · Master · PhD · All Levels',
                  style: TextStyle(fontSize: 12, color: C.white)),
              ),
            ]),
          )),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(48, 0, 48, 50),
            child: AnimatedBuilder(animation: _p, builder: (_, __) => Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _p.value,
                  backgroundColor: C.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(C.white),
                  minHeight: 5,
                )),
              const SizedBox(height: 10),
              Text('Loading programs...', style: TextStyle(color: C.white.withValues(alpha: 0.7), fontSize: 12)),
            ]))),
        ],
      )),
    ),
  );
}

// ── HOME ────────────────────────────────────────────────────────
class _Home extends StatefulWidget {
  const _Home();
  @override State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _tab = 0;
  final Set<String> _saved = {};
  bool _syncing = false;

  String _q      = '';
  String _ctry   = 'All Countries';
  String _deg    = 'All';           // ✅ Default = All (shows Bachelor + Master + PhD)
  String _field  = 'All Fields';
  String _fund   = 'All';

  final _sc = TextEditingController();

  // ── Saved persistence via SharedPreferences ──────────────────
  static const _kSavedKey = 'saved_ids';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_kSavedKey) ?? [];
    if (mounted) setState(() => _saved.addAll(ids));
  }

  Future<void> _persistSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSavedKey, _saved.toList());
  }

  void _toggleSave(String id) {
    setState(() {
      if (_saved.contains(id)) {
        _saved.remove(id);
      } else {
        _saved.add(id);
      }
    });
    _persistSaved();
  }
  // ─────────────────────────────────────────────────────────────

  Future<void> _sync() async {
    setState(() => _syncing = true);
    await SyncEngine.forceNow();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Programs updated!'),
        backgroundColor: C.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearFilters() => setState(() {
    _ctry = 'All Countries'; _deg = 'All';
    _field = 'All Fields'; _fund = 'All';
    _q = ''; _sc.clear();
  });

  bool get _hasFilters =>
      _ctry != 'All Countries' || _deg != 'All' ||
      _field != 'All Fields' || _fund != 'All' || _q.isNotEmpty;

  // ✅ FIXED FILTER LOGIC — Bachelor degree filter now works correctly
  List<Scholarship> _applyFilters(List<Scholarship> all) {
    var list = all;

    if (_ctry != 'All Countries') {
      list = list.where((s) => s.country == _ctry).toList();
    }

    // ✅ FIX: Degree filter now strictly filters by selected degree
    // 'All' shows everything; 'Bachelor'/'Master'/'PhD' shows only that degree
    if (_deg != 'All') {
      list = list.where((s) => s.degree == _deg).toList();
    }

    if (_field != 'All Fields') {
      list = list.where((s) =>
        s.fields.contains(_field) ||
        s.fields.contains('All Fields') ||
        s.field == _field
      ).toList();
    }
    if (_fund != 'All') {
      list = list.where((s) => s.funding == _fund).toList();
    }
    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      list = list.where((s) =>
        s.title.toLowerCase().contains(q) ||
        s.university.toLowerCase().contains(q) ||
        s.country.toLowerCase().contains(q) ||
        s.field.toLowerCase().contains(q) ||
        s.fields.any((f) => f.toLowerCase().contains(q)) ||
        s.tags.any((t) => t.toLowerCase().contains(q)) ||
        s.description.toLowerCase().contains(q)
      ).toList();
    }

    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: IndexedStack(index: _tab, children: [_explore(), _savedPage(), _profile()]),
    bottomNavigationBar: _nav(),
  );

  Widget _nav() => Container(
    decoration: BoxDecoration(
      color: C.white,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, -3))],
    ),
    child: SafeArea(child: SizedBox(height: 64, child: Row(children: [
      for (int i = 0; i < 3; i++) Expanded(child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(duration: 200.ms,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: _tab == i ? C.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              [Icons.explore_rounded, Icons.bookmark_rounded, Icons.person_rounded][i],
              color: _tab == i ? C.primary : C.tMid, size: 24,
            )),
          const SizedBox(height: 2),
          Text(['Explore','Saved','Profile'][i], style: TextStyle(
            fontSize: 11,
            fontWeight: _tab == i ? FontWeight.w700 : FontWeight.normal,
            color: _tab == i ? C.primary : C.tMid,
          )),
        ]),
      )),
    ]))),
  );

  Widget _explore() => NestedScrollView(
    headerSliverBuilder: (_, __) => [
      SliverAppBar(
        expandedHeight: 200, floating: true, snap: true, backgroundColor: C.blue2,
        flexibleSpace: FlexibleSpaceBar(background: Container(
          decoration: const BoxDecoration(gradient: C.grad),
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: C.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.school_rounded, color: C.white, size: 22)),
                const SizedBox(width: 10),
                const Text('ScholarSearch', style: TextStyle(color: C.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                // ✅ Degree level quick-select pills
                _quickDeg('B', 'Bachelor'),
                const SizedBox(width: 4),
                _quickDeg('M', 'Master'),
                const SizedBox(width: 4),
                _quickDeg('P', 'PhD'),
                const SizedBox(width: 4),
                IconButton(
                  icon: _syncing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: C.white, strokeWidth: 2))
                      : const Icon(Icons.sync_rounded, color: C.white),
                  onPressed: _syncing ? null : _sync,
                ),
              ]),
              const SizedBox(height: 4),
              Text('Bachelor · Master · PhD from 20+ countries',
                style: TextStyle(color: C.white.withValues(alpha: 0.75), fontSize: 12)),
              const SizedBox(height: 12),
              Container(height: 48,
                decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))]),
                child: TextField(
                  controller: _sc,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Search programs, university, country...',
                    hintStyle: const TextStyle(fontSize: 13, color: C.tMid),
                    prefixIcon: const Icon(Icons.search_rounded, color: C.tMid, size: 20),
                    suffixIcon: _q.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: C.tMid),
                            onPressed: () => setState(() { _q = ''; _sc.clear(); }))
                        : null,
                    border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )),
            ]),
          )),
        )),
      ),
    ],
    body: Column(children: [
      _filterBar(),
      Expanded(child: _scholarshipList()),
    ]),
  );

  // ✅ Quick degree selector in header
  Widget _quickDeg(String label, String deg) {
    final active = _deg == deg;
    return GestureDetector(
      onTap: () => setState(() => _deg = active ? 'All' : deg),
      child: AnimatedContainer(duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? C.white : C.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w900,
          color: active ? C.primary : C.white,
        )),
      ),
    );
  }

  Widget _filterBar() => Container(
    color: C.white,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Column(children: [
      Row(children: [
        Expanded(child: _filterChip(
          icon: '🌍', label: 'Country',
          value: _ctry == 'All Countries' ? null : _ctry,
          onTap: () => _showPicker('Select Country', kAllCountries, _ctry,
              (v) => setState(() => _ctry = v)),
        )),
        const SizedBox(width: 8),
        Expanded(child: _filterChip(
          icon: '🎓', label: 'Degree',
          value: _deg == 'All' ? null : _deg,
          onTap: () => _showPicker('Select Degree', kAllDegrees, _deg,
              (v) => setState(() => _deg = v)),
        )),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: _filterChip(
          icon: '📚', label: 'Subject/Field',
          value: _field == 'All Fields' ? null : _field,
          onTap: () => _showPicker('Select Subject / Field', kAllFields, _field,
              (v) => setState(() => _field = v)),
          isActive: _field != 'All Fields',
        )),
        const SizedBox(width: 8),
        Expanded(child: _filterChip(
          icon: '💰', label: 'Funding',
          value: _fund == 'All' ? null : _fund,
          onTap: () => _showPicker('Select Funding Type', kAllFundings, _fund,
              (v) => setState(() => _fund = v)),
        )),
      ]),
      if (_hasFilters) ...[
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _clearFilters,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: C.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.red.withValues(alpha: 0.25)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.close_rounded, size: 16, color: C.red),
              SizedBox(width: 6),
              Text('Clear All Filters', style: TextStyle(fontSize: 13, color: C.red, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ],
    ]),
  );

  Widget _filterChip({
    required String icon,
    required String label,
    String? value,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final active = value != null || isActive;
    final displayText = value ?? label;
    final truncated = displayText.length > 16 ? '${displayText.substring(0, 15)}…' : displayText;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? C.primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? C.primary : Colors.grey.shade300, width: 1.2),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(child: Text(truncated,
            style: TextStyle(fontSize: 12, color: active ? C.white : C.tDark, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          Icon(Icons.arrow_drop_down_rounded, size: 18, color: active ? C.white : C.tMid),
        ]),
      ),
    );
  }

  void _showPicker(String title, List<String> options, String current, void Function(String) onSelect) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, maxChildSize: 0.93, minChildSize: 0.35,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: C.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: C.tLight, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.tDark)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded, color: C.tMid), onPressed: () => Navigator.pop(context)),
              ])),
            const Divider(height: 1),
            Expanded(child: ListView.builder(
              controller: sc, itemCount: options.length,
              itemBuilder: (_, i) {
                final opt = options[i];
                final selected = opt == current;
                return ListTile(
                  leading: Container(width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: selected ? C.primary : C.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.circle_outlined,
                      size: 16, color: selected ? C.white : C.tLight,
                    )),
                  title: Text(opt, style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    color: selected ? C.primary : C.tDark,
                    fontSize: 14,
                  )),
                  onTap: () { onSelect(opt); Navigator.pop(context); },
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  Widget _scholarshipList() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('scholarships').snapshots(),
    builder: (_, snap) {
      // Show error state regardless of connection state
      if (snap.hasError) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: C.red),
          const SizedBox(height: 12),
          const Text('Connection error', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: _sync, icon: const Icon(Icons.sync_rounded), label: const Text('Retry Sync')),
        ]));
      }

      // Show spinner only when truly waiting AND no cached data is available yet.
      // ConnectionState.none  → stream not yet subscribed (treat same as waiting)
      // ConnectionState.waiting → first event not yet received
      // ConnectionState.active  → stream is live, data is flowing
      // ConnectionState.done    → stream closed (shouldn't happen with Firestore)
      final isLoading = (snap.connectionState == ConnectionState.waiting ||
                         snap.connectionState == ConnectionState.none) &&
                        !snap.hasData;
      if (isLoading) {
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: C.primary),
          SizedBox(height: 16),
          Text('Loading programs...', style: TextStyle(color: C.tMid, fontSize: 14)),
        ]));
      }

      // No documents yet — Firestore collection is empty, prompt a sync
      if (!snap.hasData || snap.data!.docs.isEmpty) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: C.tLight),
          const SizedBox(height: 16),
          const Text('No programs yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Tap Sync to load data', style: TextStyle(color: C.tMid)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: _sync,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Sync Now'),
            style: ElevatedButton.styleFrom(backgroundColor: C.primary, foregroundColor: C.white)),
        ]));
      }

      final all = snap.data!.docs.map((d) => Scholarship.fromDoc(d)).toList();
      final list = _applyFilters(all);

      if (list.isEmpty) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off_rounded, size: 64, color: C.tLight),
          const SizedBox(height: 16),
          const Text('No results found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.tDark)),
          const SizedBox(height: 8),
          const Text('Try different filters or search terms', style: TextStyle(color: C.tMid)),
          const SizedBox(height: 20),
          TextButton.icon(onPressed: _clearFilters,
            icon: const Icon(Icons.refresh_rounded), label: const Text('Clear All Filters')),
        ]));
      }

      return RefreshIndicator(
        onRefresh: _sync, color: C.primary,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) return _resultHeader(list.length, all.length);
            final s = list[i - 1];
            return _ScholarCard(
              key: ValueKey(s.id), s: s,
              saved: _saved.contains(s.id),
              onSave: () => _toggleSave(s.id),
              delay: Duration(milliseconds: ((i - 1) * 35).clamp(0, 280)),
            );
          },
        ),
      );
    },
  );

  Widget _resultHeader(int filtered, int total) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
    child: Row(children: [
      RichText(text: TextSpan(
        children: [
          TextSpan(text: '$filtered ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.primary)),
          const TextSpan(text: 'programs', style: TextStyle(fontSize: 13, color: C.tMid)),
          if (_hasFilters) TextSpan(text: ' (from $total)', style: TextStyle(fontSize: 12, color: C.tMid.withValues(alpha: 0.7))),
        ],
      )),
      const Spacer(),
      // ✅ Show current degree filter badge
      if (_deg != 'All') Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: C.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Text(_deg, style: const TextStyle(fontSize: 11, color: C.teal, fontWeight: FontWeight.w700)),
      ) else Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: C.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('All Levels', style: TextStyle(fontSize: 11, color: C.green, fontWeight: FontWeight.w600)),
        ])),
    ]),
  );

  Widget _savedPage() => Scaffold(
    backgroundColor: C.bg,
    appBar: AppBar(
      backgroundColor: C.white, elevation: 1,
      title: const Text('Saved Programs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      actions: [if (_saved.isNotEmpty) TextButton(
        onPressed: () {
          setState(() => _saved.clear());
          _persistSaved();
        },
        child: const Text('Clear all', style: TextStyle(color: C.red)),
      )],
    ),
    body: _saved.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bookmark_border_rounded, size: 72, color: C.tLight),
            SizedBox(height: 16),
            Text('Nothing saved yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Tap 🔖 on any program to save it', style: TextStyle(color: C.tMid)),
          ]))
        : _SavedList(savedIds: _saved, onUnsave: (id) => _toggleSave(id)),
  );

  Widget _profile() => Scaffold(
    backgroundColor: C.bg,
    body: CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 200, pinned: true, backgroundColor: C.blue2,
        flexibleSpace: FlexibleSpaceBar(background: Container(
          decoration: const BoxDecoration(gradient: C.grad),
          child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 80, height: 80,
              decoration: BoxDecoration(color: C.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16)]),
              child: const Icon(Icons.person_rounded, size: 48, color: C.primary)),
            const SizedBox(height: 12),
            const Text('Welcome, Scholar!', style: TextStyle(color: C.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const Text('Find your dream program', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ])),
        ))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _statBox('${_saved.length}', 'Saved',     Icons.bookmark_rounded,  C.primary),
            const SizedBox(width: 12),
            _statBox('500+',             'Programs',  Icons.school_rounded,    C.green),
            const SizedBox(width: 12),
            _statBox('20+',              'Countries', Icons.public_rounded,    C.accent),
          ]),
          const SizedBox(height: 20),
          // ✅ Degree level quick filters on profile page
          const Text('Browse by Degree Level', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.tDark)),
          const SizedBox(height: 10),
          Row(children: [
            _degreeCard('🎓', 'Bachelor', C.teal),
            const SizedBox(width: 10),
            _degreeCard('📘', 'Master', C.primary),
            const SizedBox(width: 10),
            _degreeCard('🔬', 'PhD', C.purple),
          ]),
          const SizedBox(height: 20),
          const Text('Browse by Country', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.tDark)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            'United States', 'United Kingdom', 'Canada', 'Australia',
            'Germany', 'Netherlands', 'Sweden', 'Denmark',
            'Turkey', 'Hungary', 'Japan', 'South Korea',
            'Singapore', 'Norway', 'Finland', 'China',
          ].map((c) {
              const countryFlags = {
                'United States': 'US', 'United Kingdom': 'GB', 'Canada': 'CA',
                'Australia': 'AU', 'Germany': 'DE', 'Netherlands': 'NL',
                'Sweden': 'SE', 'Denmark': 'DK', 'Turkey': 'TR',
                'Hungary': 'HU', 'Japan': 'JP', 'South Korea': 'KR',
                'Singapore': 'SG', 'Norway': 'NO', 'Finland': 'FI', 'China': 'CN',
              };
              return GestureDetector(
            onTap: () => setState(() { _tab = 0; _ctry = c; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: C.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.primary.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_flag(countryFlags[c] ?? 'XX'), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(c, style: const TextStyle(fontSize: 12, color: C.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          );}).toList()),
          const SizedBox(height: 20),
          const Text('Subject Categories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.tDark)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: kAllFields.skip(1).map((f) =>
            GestureDetector(
              onTap: () => setState(() { _tab = 0; _field = f; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: C.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: C.purple.withValues(alpha: 0.2)),
                ),
                child: Text(f, style: const TextStyle(fontSize: 12, color: C.purple, fontWeight: FontWeight.w600)),
              ),
            )).toList()),
          const SizedBox(height: 20),
          const Text('Scholarship Info', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.tDark)),
          const SizedBox(height: 10),
          _featureRow(Icons.school_rounded,         'Stipendium Hungaricum',    'Fully funded for Hungary – covers all costs',      C.orange),
          _featureRow(Icons.flag_rounded,           'Türkiye Burslari',         'Fully funded for Turkey – tuition + stipend',      C.red),
          _featureRow(Icons.public_rounded,         'MEXT Japan',               'Fully funded by Japanese Government',              C.teal),
          _featureRow(Icons.star_rounded,           'GKS Korea',                'Fully funded Government Scholarship – Korea',      C.purple),
          _featureRow(Icons.attach_money_rounded,   'CSC China Scholarship',    'Full funding for China – 8,000+ spots/year',       C.primary),
          _featureRow(Icons.eco_rounded,            'Norway Free Tuition',      'No fees at all public Norwegian universities',     C.green),
          _featureRow(Icons.card_giftcard_rounded,  'DAAD Germany',             'Scholarships for international students in DE',    C.blue2),
          _featureRow(Icons.diamond_rounded,        'Holland Scholarship NL',   '€5,000 for non-EEA students at Dutch universities', C.accent),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _syncing ? null : _sync,
            icon: _syncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: C.white, strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
            label: Text(_syncing ? 'Syncing...' : '🔄  Sync Programs Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.primary, foregroundColor: C.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )),
          const SizedBox(height: 32),
        ],
      ))),
    ]),
  );

  Widget _degreeCard(String emoji, String deg, Color c) => Expanded(child: GestureDetector(
    onTap: () => setState(() { _tab = 0; _deg = deg; }),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(deg, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
      ]),
    ),
  ));

  Widget _statBox(String v, String l, IconData ic, Color c) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.withValues(alpha: 0.2)),
    ),
    child: Column(children: [
      Icon(ic, color: c, size: 24), const SizedBox(height: 5),
      Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c)),
      Text(l, style: const TextStyle(fontSize: 10, color: C.tMid)),
    ]),
  ));

  Widget _featureRow(IconData ic, String t, String sub, Color c) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(ic, color: c, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.tDark)),
        Text(sub, style: const TextStyle(fontSize: 11, color: C.tMid)),
      ])),
    ]),
  );
}

// ── SAVED LIST (realtime StreamBuilder, chunked by 30) ─────────
class _SavedList extends StatefulWidget {
  final Set<String> savedIds;
  final void Function(String id) onUnsave;
  const _SavedList({required this.savedIds, required this.onUnsave});
  @override State<_SavedList> createState() => _SavedListState();
}

class _SavedListState extends State<_SavedList> {
  // Firestore `whereIn` is capped at 30 items per query.
  // We fan out into multiple streams and merge the results.
  Stream<List<Scholarship>> _buildStream() {
    final ids = widget.savedIds.toList();
    if (ids.isEmpty) return Stream.value([]);

    final chunks = <List<String>>[];
    for (int i = 0; i < ids.length; i += 30) {
      chunks.add(ids.skip(i).take(30).toList());
    }

    final streams = chunks.map((chunk) =>
      FirebaseFirestore.instance
          .collection('scholarships')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .map((qs) => qs.docs.map(Scholarship.fromDoc).toList()),
    ).toList();

    // Combine all chunk streams into one merged list
    if (streams.length == 1) return streams.first;

    return streams.fold<Stream<List<Scholarship>>>(
      streams.first,
      (acc, next) => acc.asyncMap((a) async {
        final b = await next.first;
        return [...a, ...b];
      }),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Scholarship>>(
    stream: _buildStream(),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: C.primary));
      }
      if (snap.hasError) {
        return Center(child: Text('Error: ${snap.error}',
          style: const TextStyle(color: C.red)));
      }
      final list = snap.data ?? [];
      if (list.isEmpty) {
        return const Center(child: Text('No saved programs found.',
          style: TextStyle(color: C.tMid)));
      }
      // Keep display order matching savedIds order
      final ordered = widget.savedIds
          .map((id) {
            try { return list.firstWhere((s) => s.id == id); }
            catch (_) { return null; }
          })
          .whereType<Scholarship>()
          .toList();
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ordered.length,
        itemBuilder: (_, i) => _ScholarCard(
          key: ValueKey(ordered[i].id),
          s: ordered[i],
          saved: true,
          onSave: () => widget.onUnsave(ordered[i].id),
        ),
      );
    },
  );
}

// ── SCHOLARSHIP CARD ────────────────────────────────────────────
class _ScholarCard extends StatefulWidget {
  final Scholarship s;
  final bool saved;
  final VoidCallback onSave;
  final Duration delay;
  const _ScholarCard({super.key, required this.s, required this.saved, required this.onSave, this.delay = Duration.zero});
  @override State<_ScholarCard> createState() => _ScholarCardState();
}

class _ScholarCardState extends State<_ScholarCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: 350.ms);
  late final Animation<double> _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override void initState() { super.initState(); Future.delayed(widget.delay, () { if (mounted) _c.forward(); }); }
  @override void dispose() { _c.dispose(); super.dispose(); }

  Color get _fc => switch (widget.s.funding) {
    'Fully Funded' => C.green, 'Partial' => C.orange, _ => C.tMid
  };
  Color get _dc => switch (widget.s.degree) {
    'PhD' => C.purple, 'Master' => C.primary, 'Bachelor' => C.teal, _ => C.tMid
  };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => FadeTransition(opacity: _fade,
      child: SlideTransition(position: _slide,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, a, __) => _DetailPage(s: widget.s, saved: widget.saved, onSave: widget.onSave),
              transitionsBuilder: (_, a, __, c) => SlideTransition(
                position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                child: c),
              transitionDuration: 260.ms,
            )),
            borderRadius: BorderRadius.circular(16),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: C.bg, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.tLight.withValues(alpha: 0.6)),
                    ),
                    child: Center(child: Text(widget.s.flag,
                      style: const TextStyle(fontSize: 30)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.s.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.tDark, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(widget.s.university,
                      style: const TextStyle(fontSize: 12, color: C.tMid),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  GestureDetector(
                    onTap: widget.onSave,
                    child: AnimatedSwitcher(duration: 200.ms,
                      child: Icon(
                        widget.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        key: ValueKey(widget.saved),
                        color: widget.saved ? C.primary : C.tLight, size: 24,
                      )),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _badge(widget.s.degree, _dc),
                  _badge(widget.s.funding, _fc),
                  if (widget.s.field != 'All Fields')
                    _badge(widget.s.field.split(' ').first, C.purple.withValues(alpha: 0.8)),
                  if (widget.s.isNew)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(6)),
                      child: const Text('NEW', style: TextStyle(fontSize: 10, color: C.white, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: C.tMid),
                  const SizedBox(width: 3),
                  Expanded(child: Text(widget.s.country,
                    style: const TextStyle(fontSize: 12, color: C.tMid), overflow: TextOverflow.ellipsis)),
                  if (widget.s.deadline.isNotEmpty) ...[
                    const Icon(Icons.calendar_today_outlined, size: 12, color: C.tMid),
                    const SizedBox(width: 3),
                    Text(widget.s.deadline, style: const TextStyle(fontSize: 11, color: C.tMid)),
                  ],
                  if (widget.s.amount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: C.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('\$${NumberFormat.compact().format(widget.s.amount)}/yr',
                        style: const TextStyle(fontSize: 11, color: C.green, fontWeight: FontWeight.w700)),
                    ),
                  ] else if (widget.s.amount == 0 && widget.s.tags.any((t) => t.contains('free'))) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: C.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('FREE', style: TextStyle(fontSize: 11, color: C.green, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ],
            )),
          ),
        ),
      ),
    ),
  );

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.withValues(alpha: 0.25)),
    ),
    child: Text(t, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w700)),
  );
}

// ── DETAIL PAGE ─────────────────────────────────────────────────
class _DetailPage extends StatelessWidget {
  final Scholarship s;
  final bool saved;
  final VoidCallback onSave;
  const _DetailPage({required this.s, required this.saved, required this.onSave});

  Color get _fc => switch (s.funding) { 'Fully Funded' => C.green, 'Partial' => C.orange, _ => C.primary };

  Future<void> _applyNow(BuildContext ctx) async {
    if (s.applyUrl.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No application URL available'), backgroundColor: C.red));
      return;
    }
    final uri = Uri.parse(s.applyUrl);
    bool launched = false;
    try { launched = await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
    if (!launched) {
      try { await launchUrl(uri, mode: LaunchMode.platformDefault); } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Could not open: ${s.applyUrl}'), backgroundColor: C.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 220, pinned: true, backgroundColor: C.blue2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: C.white),
          onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: C.white),
            onPressed: () { onSave(); Navigator.pop(context); }),
        ],
        flexibleSpace: FlexibleSpaceBar(background: Container(
          decoration: const BoxDecoration(gradient: C.grad),
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 64, height: 64,
                  decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)]),
                  child: Center(child: Text(s.flag, style: const TextStyle(fontSize: 36)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.title,
                    style: const TextStyle(color: C.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.3),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(s.university, style: TextStyle(color: C.white.withValues(alpha: 0.8), fontSize: 13)),
                ])),
              ]),
            ]),
          )),
        )),
      ),

      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _infoTile(Icons.school_rounded,       'Degree',   s.degree,                  s.degree == 'Bachelor' ? C.teal : s.degree == 'Master' ? C.primary : C.purple),
            const SizedBox(width: 10),
            _infoTile(Icons.attach_money_rounded, 'Funding',  s.funding,                 _fc),
            const SizedBox(width: 10),
            _infoTile(Icons.public_rounded,       'Country',  s.country.split(' ').first, C.accent),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _infoTile(Icons.subject_rounded, 'Field', s.field.split(' ').first, C.purple),
            const SizedBox(width: 10),
            if (s.amount > 0) Expanded(child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                const Icon(Icons.monetization_on_rounded, color: C.green, size: 22),
                const SizedBox(height: 3),
                Text('\$${NumberFormat('#,###').format(s.amount)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.green)),
                const Text('per year', style: TextStyle(fontSize: 10, color: C.tMid)),
              ])))
            else if (s.tags.any((t) => t.contains('free'))) Expanded(child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Column(children: [
                Icon(Icons.celebration_rounded, color: C.green, size: 22),
                SizedBox(height: 3),
                Text('FREE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.green)),
                Text('no tuition', style: TextStyle(fontSize: 10, color: C.tMid)),
              ])))
            else const Expanded(child: SizedBox()),
          ]),

          if (s.fields.isNotEmpty && !(s.fields.length == 1 && s.fields.first == 'All Fields')) ...[
            const SizedBox(height: 16),
            const Text('Available Fields / Subjects', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.tDark)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: s.fields
              .where((f) => f != 'All Fields')
              .map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: C.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: C.purple.withValues(alpha: 0.2)),
                ),
                child: Text(f, style: const TextStyle(fontSize: 12, color: C.purple, fontWeight: FontWeight.w600)),
              )).toList()),
          ],

          if (s.deadline.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.red.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.red.withValues(alpha: 0.2))),
              child: Row(children: [
                const Icon(Icons.schedule_rounded, color: C.red, size: 20),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Application Deadline', style: TextStyle(fontSize: 11, color: C.red)),
                  Text(s.deadline, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.red)),
                ]),
              ])),
          ],

          const SizedBox(height: 20),
          const Text('About This Program', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.tDark)),
          const SizedBox(height: 10),
          Text(s.description, style: const TextStyle(fontSize: 15, color: C.tMid, height: 1.7)),

          if (s.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Tags', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.tDark)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: s.tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: C.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16)),
              child: Text('#$t', style: const TextStyle(fontSize: 12, color: C.primary, fontWeight: FontWeight.w600)),
            )).toList()),
          ],

          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: s.applyUrl.isEmpty ? null : () => _applyNow(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Search on BachelorsPortal / Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.primary, foregroundColor: C.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: C.tLight,
            ),
          )),
          if (s.applyUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(child: Text(s.applyUrl,
              style: const TextStyle(fontSize: 11, color: C.tMid),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          const SizedBox(height: 40),
        ],
      ))),
    ]),
  );

  Widget _infoTile(IconData ic, String label, String val, Color c) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(ic, color: c, size: 20), const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: c.withValues(alpha: 0.8))),
      const SizedBox(height: 2),
      Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  ));
}