/// Deterministic Tagalog-to-Baybayin transliteration and validation utility.
/// Uses standard Unicode Tagalog block (U+1700 - U+171F).
class BaybayinEngine {
  static const String charA = '\u1700'; // ᜀ
  static const String charI = '\u1701'; // ᜁ
  static const String charU = '\u1702'; // ᜂ

  static const String charKa = '\u1703'; // ᜃ
  static const String charGa = '\u1704'; // ᜄ
  static const String charNga = '\u1705'; // ᜅ
  static const String charTa = '\u1706'; // ᜆ
  static const String charDa = '\u1707'; // ᜇ (also Ra)
  static const String charNa = '\u1708'; // ᜈ
  static const String charPa = '\u1709'; // ᜉ
  static const String charBa = '\u170A'; // ᜊ
  static const String charMa = '\u170B'; // ᜋ
  static const String charYa = '\u170C'; // ᜌ
  static const String charLa = '\u170D'; // ᜎ
  static const String charWa = '\u170E'; // ᜏ
  static const String charSa = '\u170F'; // ᜐ
  static const String charHa = '\u1710'; // ᜑ

  // Kudlit diacritics
  static const String kudlitI = '\u1712'; // ᜒ (shifts vowel to i/e)
  static const String kudlitU = '\u1713'; // ᜓ (shifts vowel to u/o)
  static const String virama = '\u1714';  // ᜔ (vowel killer / pamudpod)

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
    'c': charKa,
    'f': charPa,
    'v': charBa,
    'j': charDa,
    'z': charSa,
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

  /// Converts a modern Latin Filipino word into authentic Baybayin Unicode script.
  static String transliterate(String tagalogWord) {
    final clean = tagalogWord.trim().toLowerCase();
    final buffer = StringBuffer();
    int i = 0;

    while (i < clean.length) {
      // Check 2-letter consonant "ng"
      if (i + 1 < clean.length && clean.substring(i, i + 2) == 'ng') {
        i += 2;
        if (i < clean.length && _isVowel(clean[i])) {
          buffer.write(charNga);
          buffer.write(_getKudlit(clean[i]));
          i++;
        } else {
          // Final consonant with virama
          buffer.write(charNga);
          buffer.write(virama);
        }
        continue;
      }

      final char = clean[i];

      // Single standalone vowel
      if (_isVowel(char)) {
        buffer.write(_getStandaloneVowel(char));
        i++;
        continue;
      }

      // Consonant
      if (_consonants.containsKey(char)) {
        final glyph = _consonants[char]!;
        i++;
        if (i < clean.length && _isVowel(clean[i])) {
          buffer.write(glyph);
          buffer.write(_getKudlit(clean[i]));
          i++;
        } else {
          // Final consonant with virama
          buffer.write(glyph);
          buffer.write(virama);
        }
        continue;
      }

      // Punctuation, space, or numbers
      buffer.write(char);
      i++;
    }

    return buffer.toString();
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
        return ''; // Default inherant 'a' vowel needs no kudlit
    }
  }
}
