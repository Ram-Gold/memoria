/// Modes for Baybayin script rendering.
enum BaybayinMode {
  /// Modern reformed Baybayin utilizing the Spanish krus-kudlit virama (U+1714)
  /// to explicitly represent syllable-final coda consonants.
  modern,

  /// Authentic pre-colonial traditional Baybayin (kaltas method), which omits
  /// syllable-final consonants and relies on contextual reading.
  traditional,
}

/// Deterministic Tagalog-to-Baybayin transliteration, syllabication, and validation utility.
/// Uses standard Unicode Tagalog block (U+1700 - U+171F) and conforms to
/// Komisyon sa Wikang Filipino (KWF) orthography standards.
class BaybayinEngine {
  // Independent vowels
  static const String charA = '\u1700'; // ᜀ
  static const String charI = '\u1701'; // ᜁ (also E)
  static const String charU = '\u1702'; // ᜂ (also O)

  // Base consonants (inherent vowel /a/)
  static const String charKa = '\u1703'; // ᜃ
  static const String charGa = '\u1704'; // ᜄ
  static const String charNga = '\u1705'; // ᜅ
  static const String charTa = '\u1706'; // ᜆ
  static const String charDa = '\u1707'; // ᜇ (historically also Ra)
  static const String charNa = '\u1708'; // ᜈ
  static const String charPa = '\u1709'; // ᜉ
  static const String charBa = '\u170A'; // ᜊ
  static const String charMa = '\u170B'; // ᜋ
  static const String charYa = '\u170C'; // ᜌ
  static const String charLa = '\u170D'; // ᜎ
  static const String charWa = '\u170E'; // ᜏ
  static const String charSa = '\u170F'; // ᜐ
  static const String charHa = '\u1710'; // ᜑ
  static const String charRa = '\u171F'; // ᜟ (Tagalog Archaic Ra, Unicode 14.0)

  // Kudlit diacritics
  static const String kudlitI = '\u1712'; // ᜒ (shifts vowel to i / e)
  static const String kudlitU = '\u1713'; // ᜓ (shifts vowel to u / o)
  static const String virama = '\u1714';  // ᜔ (vowel killer / Spanish krus-kudlit)
  static const String pamudpod = '\u1734'; // ᜴ (Mangyan pamudpod virama)

  // Punctuation
  static const String danda = '\u1735';      // ᜵ (Philippine single danda)
  static const String doubleDanda = '\u1736';// ᜶ (Philippine double danda)

  static final Map<String, String> _consonants = {
    'ng': charNga,
    'k': charKa,
    'g': charGa,
    't': charTa,
    'd': charDa,
    'r': charDa,
    'n': charNa,
    'p': charPa,
    'b': charBa,
    'm': charMa,
    'y': charYa,
    'l': charLa,
    'w': charWa,
    's': charSa,
    'h': charHa,
  };

  /// Check whether a given text contains valid Baybayin characters
  static bool hasBaybayinGlyphs(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x1700 && rune <= 0x171F) {
        return true;
      }
    }
    return false;
  }

  /// Normalizes foreign loanwords, Spanish phonemes, and non-Abakada letters into
  /// standard KWF phonetic Tagalog equivalents suitable for Baybayin transcription.
  static String normalizeTagalogPhonetics(String input) {
    var text = input.trim().toLowerCase();

    // Spanish / foreign digraphs
    text = text.replaceAll('ch', 'ts');
    text = text.replaceAll('sh', 'sy');
    text = text.replaceAll('ll', 'ly');
    text = text.replaceAll('ñ', 'ny');

    // Qu- patterns
    text = text.replaceAll('qui', 'ki');
    text = text.replaceAll('que', 'ke');
    text = text.replaceAll('qua', 'kwa');
    text = text.replaceAll('quo', 'kwo');

    // Single foreign letters
    final sb = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == 'c') {
        if (i + 1 < text.length && (text[i + 1] == 'e' || text[i + 1] == 'i')) {
          sb.write('s');
        } else {
          sb.write('k');
        }
      } else if (ch == 'f') {
        sb.write('p');
      } else if (ch == 'v') {
        sb.write('b');
      } else if (ch == 'j') {
        // Tagalog phonetic adaptation of 'j' is usually 'dy' or 'h'
        sb.write('dy');
      } else if (ch == 'z') {
        sb.write('s');
      } else if (ch == 'x') {
        sb.write('ks');
      } else if (ch == 'q') {
        sb.write('k');
      } else {
        sb.write(ch);
      }
    }

    return sb.toString();
  }

  /// Converts a modern Latin Filipino word or phrase into authentic Baybayin Unicode script.
  /// Handles special grammatical particles ("mga", "ng"), loanwords, and punctuation.
  static String transliterate(
    String tagalogText, {
    BaybayinMode mode = BaybayinMode.modern,
  }) {
    if (tagalogText.trim().isEmpty) return '';

    // Split text into tokens (words and non-word characters like spaces, punctuation)
    final tokens = RegExp(r"([a-zA-ZñÑ'-]+|[^a-zA-ZñÑ'-]+)").allMatches(tagalogText);
    final output = StringBuffer();

    for (final match in tokens) {
      final token = match.group(0)!;

      // Non-word token (whitespace, punctuation, numbers)
      if (!RegExp(r"^[a-zA-ZñÑ'-]+$").hasMatch(token)) {
        if (token == '.') {
          output.write(doubleDanda);
        } else if (token == ',' || token == ';') {
          output.write(danda);
        } else {
          output.write(token);
        }
        continue;
      }

      // Word token
      final lower = token.toLowerCase();

      // Special particle: 'mga' is pronounced /manga/
      if (lower == 'mga') {
        output.write(charMa);
        output.write(charNga);
        continue;
      }

      // Special particle: 'ng' is pronounced /nang/
      if (lower == 'ng') {
        output.write(charNa);
        output.write(charNga);
        if (mode == BaybayinMode.modern) {
          output.write(virama);
        }
        continue;
      }

      // Enclitic contractions: e.g. "ako'y" -> "akoy", "bata't" -> "batat"
      final cleanWord = lower.replaceAll("'", '');
      final phonetic = normalizeTagalogPhonetics(cleanWord);

      output.write(_transliterateWord(phonetic, mode));
    }

    return output.toString();
  }

  /// Core single-word transliteration routine
  static String _transliterateWord(String word, BaybayinMode mode) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < word.length) {
      // Hyphens (e.g. mag-aral) represent glottal stops
      if (word[i] == '-') {
        i++;
        continue;
      }

      // 1. Check digraph 'ng'
      if (i + 1 < word.length && word.substring(i, i + 2) == 'ng') {
        i += 2;
        if (i < word.length && _isVowel(word[i])) {
          buffer.write(charNga);
          buffer.write(_getKudlit(word[i]));
          i++;
        } else {
          // Final coda consonant
          if (mode == BaybayinMode.modern) {
            buffer.write(charNga);
            buffer.write(virama);
          }
        }
        continue;
      }

      final char = word[i];

      // 2. Standalone vowel (initial or hiatus / vowel-after-vowel)
      if (_isVowel(char)) {
        buffer.write(_getStandaloneVowel(char));
        i++;
        continue;
      }

      // 3. Consonants
      if (_consonants.containsKey(char)) {
        final glyph = _consonants[char]!;
        i++;
        if (i < word.length && _isVowel(word[i])) {
          buffer.write(glyph);
          buffer.write(_getKudlit(word[i]));
          i++;
        } else {
          // Coda consonant
          if (mode == BaybayinMode.modern) {
            buffer.write(glyph);
            buffer.write(virama);
          }
        }
        continue;
      }

      // Fallback for any unexpected character
      buffer.write(char);
      i++;
    }

    return buffer.toString();
  }

  /// Syllabicates a Tagalog word into standard hyphenated syllables following
  /// Komisyon sa Wikang Filipino (KWF) orthography rules (e.g. 'aklat' -> ['ak', 'lat']).
  static List<String> syllabicate(String word) {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final syllables = <String>[];
    final letters = clean.split('');
    final n = letters.length;
    var currentSyllable = StringBuffer();

    int i = 0;
    while (i < n) {
      final ch = letters[i];

      // Handle hyphen explicitly
      if (ch == '-') {
        if (currentSyllable.isNotEmpty) {
          syllables.add(currentSyllable.toString());
          currentSyllable = StringBuffer();
        }
        i++;
        continue;
      }

      currentSyllable.write(ch);

      // Digraph 'ng'
      if (ch == 'n' && i + 1 < n && letters[i + 1] == 'g') {
        currentSyllable.write('g');
        i += 2;
      } else {
        i++;
      }

      // Syllable boundary detection
      if (i < n) {
        final nextChar = letters[i];
        final nextIsVowel = _isVowel(nextChar);
        final currentHasVowel = _isVowel(ch);

        if (currentHasVowel && nextIsVowel) {
          // V-V boundary: e.g. da-an, ba-o, ta-o
          syllables.add(currentSyllable.toString());
          currentSyllable = StringBuffer();
        } else if (currentHasVowel && !nextIsVowel) {
          // V-C: check what comes after next consonant
          int lookahead = i + 1;
          if (nextChar == 'n' && lookahead < n && letters[lookahead] == 'g') {
            lookahead++;
          }
          if (lookahead < n && _isVowel(letters[lookahead])) {
            // V-CV boundary: e.g. ba-ta, pu-sa
            syllables.add(currentSyllable.toString());
            currentSyllable = StringBuffer();
          }
        } else if (!currentHasVowel && !nextIsVowel) {
          // C-C boundary: e.g. ak-lat, pan-tik
          int lookahead = i + 1;
          if (nextChar == 'n' && lookahead < n && letters[lookahead] == 'g') {
            lookahead++;
          }
          if (lookahead < n && _isVowel(letters[lookahead])) {
            syllables.add(currentSyllable.toString());
            currentSyllable = StringBuffer();
          }
        }
      }
    }

    if (currentSyllable.isNotEmpty) {
      syllables.add(currentSyllable.toString());
    }

    return syllables;
  }

  /// Formats a Tagalog word into bracketed syllable pronunciation guide,
  /// e.g. 'aklat' -> '[ak-lat]', 'bulaklak' -> '[bu-lak-lak]'
  static String formatPronunciation(String word) {
    final syls = syllabicate(word);
    if (syls.isEmpty) return '[$word]';
    return '[${syls.join('-')}]';
  }

  static bool _isVowel(String char) {
    return char == 'a' || char == 'e' || char == 'i' || char == 'o' || char == 'u';
  }

  static String _getStandaloneVowel(String v) {
    switch (v) {
      case 'i':
      case 'e':
        return charI;
      case 'u':
      case 'o':
        return charU;
      case 'a':
      default:
        return charA;
    }
  }

  static String _getKudlit(String v) {
    switch (v) {
      case 'i':
      case 'e':
        return kudlitI;
      case 'u':
      case 'o':
        return kudlitU;
      case 'a':
      default:
        return ''; // Inherent /a/ vowel needs no kudlit
    }
  }
}
