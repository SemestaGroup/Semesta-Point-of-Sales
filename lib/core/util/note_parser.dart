/// Centralised note parser/normaliser for POS.
///
/// Notes in this codebase have two layers:
/// * Order-level note: a free-form string attached to the whole transaction.
/// * Item-level note: a per-item note, originally authored per detail row.
///
/// Historically these two layers were concatenated into a single
/// `transactions.note` field using a `---ITEM NOTES---` delimiter so the
/// payload could be sent to the API as one string. After the API echoed
/// the value back, additional code (or another device) sometimes appended
/// its own delimiter, producing duplicated sections.
///
/// This helper splits a raw note into its components in a way that is
/// robust to:
/// * Multiple or accidental `---ITEM NOTES---` occurrences
/// * HTML line breaks (`<br />`, `<br>`)
/// * Empty / whitespace-only sections
/// * Surrounding whitespace
class NoteParser {
  static const String itemMarker = '---ITEM NOTES---';

  /// Returns a list of clean per-product notes (no order type prefix, no
  /// double delimiter). Each entry corresponds to a product name in the
  /// canonical order produced by `buildCanonicalNote`.
  ///
  /// As a safety net, lines that look like "Name | Type - Note" or
  /// "Type - Note" (no pipe) are split so the user-facing note is the
  /// note part only — never the order-type prefix.
  static List<String> extractItemNoteList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final marker = _firstMarkerIndex(raw);
    final base = marker >= 0 ? raw.substring(marker + itemMarker.length) : raw;
    final clean = base
        .replaceAll('<br />', '\n')
        .replaceAll('<br>', '\n');
    final lines = clean.split('\n');
    final out = <String>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.contains(' | ')) {
        final pipeIdx = line.indexOf(' | ');
        final rest = line.substring(pipeIdx + 3).trim();
        if (rest.contains(' - ')) {
          // 'Name | Type - Note' — keep the note part only.
          final dashIdx = rest.indexOf(' - ');
          out.add(rest.substring(dashIdx + 3).trim());
        } else {
          // 'Name | Type' — type only, no note.
          // Don't add an empty note to the list.
        }
      } else if (line.contains(' - ')) {
        // 'Name - Note' or 'Type - Note' — keep the note part only.
        final dashIdx = line.indexOf(' - ');
        out.add(line.substring(dashIdx + 3).trim());
      } else {
        out.add(line);
      }
    }
    return out;
  }

  /// Returns the user-facing note for a single transaction_details row.
  /// Strips a leading "<OrderType> - " prefix if present (legacy data
  /// where the client concatenated type and note into one column).
  static String sanitizeLegacyItemNote(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final cleaned = raw.replaceAll('<br />', ' ').replaceAll('<br>', ' ').trim();
    if (!cleaned.contains(' - ')) return cleaned;
    // Split at the FIRST ' - ' so anything after that is treated as the
    // note text. This matches the canonical wire format.
    final dashIdx = cleaned.indexOf(' - ');
    final after = cleaned.substring(dashIdx + 3).trim();
    return after;
  }

  /// Returns the order-level (global) note part, or empty string if none.
  /// Tolerant to: missing/empty input, no marker, double markers, and lines
  /// that look like item-note dumps (e.g. "Name | Dine In - sugar") appearing
  /// in the order section when the marker was stripped by an intermediary.
  /// The stripping heuristic only triggers when the *order section* contains
  /// 2+ such dump lines, so a legitimate single-line order note like
  /// "Pickup - jam 5" is preserved.
  static String extractOrderNote(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final marker = _firstMarkerIndex(raw);
    String base = marker >= 0 ? raw.substring(0, marker) : raw;
    base = _stripItemNoteLines(base);
    return _cleanText(base);
  }

  /// Drop lines that look like item-note dumps when there are 2+ of them.
  /// A dump line is one that contains either a " | " (Name | Type) or a
  /// " - " (Name - Note) separator. A single such line in the order
  /// section is treated as a legitimate order note and kept.
  static String _stripItemNoteLines(String input) {
    final lines = input.split('\n');
    final dumpIndices = <int>[];
    final knownTypes = {
      'dine in',
      'take away',
      'gofood',
      'grabfood',
      'shopeefood',
      'delivery',
      'other',
      'regular'
    };
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final hasPipe = line.contains(' | ');
      final hasDashNote = line.contains(' - ');
      if (hasPipe) {
        dumpIndices.add(i);
      } else if (hasDashNote) {
        // Only treat as dump line if the right side is a known type
        // or it has a structure like "Name - Type - Note".
        final dashIdx = line.indexOf(' - ');
        final right = line.substring(dashIdx + 3).trim().toLowerCase();
        if (knownTypes.contains(right) || right.contains(' - ')) {
          dumpIndices.add(i);
        }
      }
    }
    if (dumpIndices.length < 2) return input;
    final kept = <String>[];
    for (var i = 0; i < lines.length; i++) {
      if (dumpIndices.contains(i)) continue;
      kept.add(lines[i]);
    }
    return kept.join('\n');
  }

  /// Returns a map of {productNameLower: itemNote} extracted from the
  /// item-notes section. Tolerant to multiple formats:
  ///   * "Name | Type - Note"
  ///   * "Name | Type"
  ///   * "Name - Note"
  static Map<String, String> extractItemNotes(String? raw) {
    final result = <String, String>{};
    if (raw == null || raw.isEmpty) return result;
    final marker = _firstMarkerIndex(raw);
    if (marker < 0) return result;
    final section = raw.substring(marker + itemMarker.length);
    final clean = section
        .replaceAll('<br />', '\n')
        .replaceAll('<br>', '\n');
    for (final rawLine in clean.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      // Format: 'Name | Type - Note'  OR  'Name | Type'
      if (line.contains(' | ')) {
        final pipeIdx = line.indexOf(' | ');
        final namePart = line.substring(0, pipeIdx).trim();
        final rest = line.substring(pipeIdx + 3).trim();
        if (rest.contains(' - ')) {
          final dashIdx = rest.indexOf(' - ');
          final note = rest.substring(dashIdx + 3).trim();
          if (note.isNotEmpty) {
            result[namePart.toLowerCase()] = note;
          }
        }
        // ignore type-only lines — order type lives in transaction_details
        continue;
      }
      // Format: 'Name - Note' (no custom order type)
      if (line.contains(' - ')) {
        final dashIdx = line.indexOf(' - ');
        final namePart = line.substring(0, dashIdx).trim();
        final note = line.substring(dashIdx + 3).trim();
        if (note.isNotEmpty) {
          result[namePart.toLowerCase()] = note;
        }
      }
    }
    return result;
  }

  /// Build a canonical, deduped note string for outgoing API calls.
  /// Collapses multiple markers into a single one and trims whitespace.
  static String buildCanonicalNote({
    required String orderNote,
    required List<MapEntry<String, String>> itemNotes,
  }) {
    final cleanOrder = _cleanText(orderNote);
    final entries = <String>[];
    final seen = <String>{};
    for (final e in itemNotes) {
      final key = e.key.trim();
      final value = e.value.trim();
      if (key.isEmpty || value.isEmpty) continue;
      final dedupeKey = '${key.toLowerCase()}|${value.toLowerCase()}';
      if (seen.add(dedupeKey)) {
        entries.add('$key - $value');
      }
    }
    if (cleanOrder.isEmpty && entries.isEmpty) return '';
    if (entries.isEmpty) return cleanOrder;
    return '$cleanOrder\n$itemMarker\n${entries.join('\n')}';
  }

  // --- internals ---------------------------------------------------------

  /// Returns the index of the first `---ITEM NOTES---` marker, tolerating
  /// multiple accidental occurrences by returning the first one.
  static int _firstMarkerIndex(String raw) {
    // Strip the leading whitespace and search the first occurrence.
    final first = raw.indexOf(itemMarker);
    if (first < 0) return -1;
    return first;
  }

  static String _cleanText(String s) {
    return s
        .replaceAll('<br />', '\n')
        .replaceAll('<br>', '\n')
        .trim();
  }

  /// Decode an HTML-encoded string (used in some server payloads).
  static String decodeHtml(String input) {
    try {
      return htmlUnescape.convert(input);
    } catch (_) {
      return input;
    }
  }

  static const htmlUnescape = _HtmlUnescape();
}

class _HtmlUnescape {
  const _HtmlUnescape();
  String convert(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }
}
