import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class MedicalDataService {
  // ── Manual CSV parser ──────────────────────────────────────────────────────
  // The csv package fails on multi-line quoted fields (e.g. Jaundice has
  // embedded "" in its description). This simple parser handles them correctly.
  List<List<String>> _parseCsv(String raw) {
    // Normalise line endings
    final input = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final rows = <List<String>>[];
    final fields = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    int i = 0;

    while (i < input.length) {
      final ch = input[i];

      if (inQuotes) {
        if (ch == '"') {
          // Peek: escaped quote?
          if (i + 1 < input.length && input[i + 1] == '"') {
            buf.write('"');
            i += 2;
            continue;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          fields.add(buf.toString().trim());
          buf.clear();
        } else if (ch == '\n') {
          fields.add(buf.toString().trim());
          buf.clear();
          if (fields.isNotEmpty && !(fields.length == 1 && fields[0].isEmpty)) {
            rows.add(List<String>.from(fields));
          }
          fields.clear();
        } else {
          buf.write(ch);
        }
      }
      i++;
    }

    // Handle last field / row (no trailing newline)
    if (buf.isNotEmpty || fields.isNotEmpty) {
      fields.add(buf.toString().trim());
      if (!(fields.length == 1 && fields[0].isEmpty)) {
        rows.add(List<String>.from(fields));
      }
    }

    return rows;
  }

  Future<Map<String, dynamic>> getDetails(
    String disease,
    List<String> userSymptoms,
    Map<String, List<String>> symptomAnswers,
  ) async {
    try {
      final descRaw = await rootBundle.loadString('assets/data/Updated_Symptom_Description.csv');
      final precRaw = await rootBundle.loadString('assets/data/Updated_Symptom_Precaution.csv');
      final sevRaw  = await rootBundle.loadString('assets/data/Updated_Symptom_Severity.csv');

      final List<List<String>> desc = _parseCsv(descRaw);
      final List<List<String>> prec = _parseCsv(precRaw);
      final List<List<String>> sev  = _parseCsv(sevRaw);

      debugPrint('📋 DESC rows: ${desc.length}  |  PREC rows: ${prec.length}  |  SEV rows: ${sev.length}');

      final String diseaseKey = disease.trim().toLowerCase();

      // ── Description match ─────────────────────────────────────────────────
      // Skip header row (index 0)
      List<String>? dRow;
      for (int i = 1; i < desc.length; i++) {
        if (desc[i].isNotEmpty &&
            desc[i][0].trim().toLowerCase() == diseaseKey) {
          dRow = desc[i];
          break;
        }
      }

      // ── Precaution match ──────────────────────────────────────────────────
      List<String>? pRow;
      for (int i = 1; i < prec.length; i++) {
        if (prec[i].isNotEmpty &&
            prec[i][0].trim().toLowerCase() == diseaseKey) {
          pRow = prec[i];
          break;
        }
      }

      debugPrint('🔍 Disease lookup: "$diseaseKey"');
      debugPrint('📝 Description found: ${dRow != null}');
      debugPrint('💊 Precautions found: ${pRow != null}');

      // ── Severity calculation ───────────────────────────────────────────────
      final Set<String> selectedSet = userSymptoms
          .map((s) => s.toLowerCase().trim().replaceAll(' ', '_'))
          .toSet();

      int totalScore = 0;

      // Skip header row (index 0)
      for (int i = 1; i < sev.length; i++) {
        final row = sev[i];
        if (row.length < 2) continue;

        final String csvSymptom =
            row[0].trim().toLowerCase().replaceAll(' ', '_');
        final int weight = int.tryParse(row[1].trim()) ?? 0;

        if (weight == 0 || csvSymptom.isEmpty) continue;

        if (selectedSet.contains(csvSymptom)) {
          final String originalKey = userSymptoms.firstWhere(
            (s) => s.toLowerCase().trim().replaceAll(' ', '_') == csvSymptom,
            orElse: () => '',
          );

          double multiplier = 1.0;
          if (originalKey.isNotEmpty &&
              symptomAnswers.containsKey(originalKey)) {
            final String ans =
                symptomAnswers[originalKey]!.join(' ').toLowerCase();
            if (ans.contains('high') ||
                ans.contains('severe') ||
                ans.contains('104') ||
                ans.contains('yes')) {
              multiplier = 2.0;
            }
          }

          final int finalScore = (weight * multiplier).toInt();
          totalScore += finalScore;
          debugPrint(
              '✅ SEV MATCH  → $csvSymptom | w=$weight | x$multiplier = $finalScore');
        }
      }

      debugPrint('📊 TOTAL SEVERITY: $totalScore for ${userSymptoms.join(", ")}');

      // ── Build precautions list ────────────────────────────────────────────
      final List<String> precautions = pRow == null
          ? ['Consult a healthcare professional.']
          : pRow
              .skip(1) // skip disease name column
              .where((p) =>
                  p.isNotEmpty && p.toLowerCase() != 'nan')
              .toList();

      return {
        'description': dRow != null && dRow.length > 1
            ? dRow[1]
            : 'Detailed description not available for $disease.',
        'precautions': precautions.isEmpty
            ? ['Consult a healthcare professional.']
            : precautions,
        'score': totalScore,
        'level': totalScore > 15
            ? 'High'
            : (totalScore > 7 ? 'Moderate' : 'Low'),
      };
    } catch (e, stack) {
      debugPrint('❌ MedicalDataService Error: $e\n$stack');
      return {
        'description': 'Medical details unavailable.',
        'precautions': ['Consult a doctor.'],
        'score': 0,
        'level': 'Low',
      };
    }
  }
}
