pub const rune = u21; // A Unicode codepoint.
pub const max_rune: rune = '\u{0010FFFF}'; // Maximum valid Unicode code point.
pub const replacement_char: rune = '\u{FFFD}'; // Represents invalid code points.
pub const max_ascii: rune = '\u{007F}'; // maximum ASCII value.
pub const max_latin_1: rune = '\u{00FF}'; // maximum Latin-1 value.

// linear_max is the maximum size table for linear search for non-Latin1 rune.
// Derived by running 'go test -calibrate'.
pub const linear_max = 18;

/// Bit masks for each code point under U+0100, for fast lookup.
pub const pC: u8 = 1 << 0; // a control character.
pub const pP: u8 = 1 << 1; // a punctuation character.
pub const pN: u8 = 1 << 2; // a numeral.
pub const pS: u8 = 1 << 3; // a symbolic character.
pub const pZ: u8 = 1 << 4; // a spacing character.
pub const pLu: u8 = 1 << 5; // an upper-case letter.
pub const pLl: u8 = 1 << 6; // a lower-case letter.
pub const pp: u8 = 1 << 7; // a printable character according to Go's definition.
pub const pg: u8 = pp | pZ; // a graphical character according to the Unicode definition.
pub const pLo: u8 = pLl | pLu; // a letter that is neither upper nor lower case.
pub const pLmask: u8 = pLo;

/// version is the Unicode edition from which the tables are derived.
pub const version = "13.0.0";

/// Categories is the set of Unicode category tables.
pub const Categories = enum {
    C,
    Cc,
    Cf,
    Co,
    Cs,
    L,
    Ll,
    Lm,
    Lo,
    Lt,
    Lu,
    M,
    Mc,
    Me,
    Mn,
    N,
    Nd,
    Nl,
    No,
    P,
    Pc,
    Pd,
    Pe,
    Pf,
    Pi,
    Po,
    Ps,
    S,
    Sc,
    Sk,
    Sm,
    So,
    Z,
    Zl,
    Zp,
    Zs,
};

pub const Cc = Categories.Cc; // Cc is the set of Unicode characters in category Cc (Other, control).
pub const Cf = Categories.Cf; // Cf is the set of Unicode characters in category Cf (Other, format).
pub const Co = Categories.Co; // Co is the set of Unicode characters in category Co (Other, private use).
pub const Cs = Categories.Cs; // Cs is the set of Unicode characters in category Cs (Other, surrogate).
pub const Digit = Categories.Nd; // Digit is the set of Unicode characters with the "decimal digit" property.
pub const Nd = Categories.Nd; // Nd is the set of Unicode characters in category Nd (Number, decimal digit).
pub const Letter = Categories.L; // Letter/L is the set of Unicode letters, category L.
pub const L = Categories.L;
pub const Lm = Categories.Lm; // Lm is the set of Unicode characters in category Lm (Letter, modifier).
pub const Lo = Categories.Lo; // Lo is the set of Unicode characters in category Lo (Letter, other).
pub const Lower = Categories.Ll; // Lower is the set of Unicode lower case letters.
pub const Ll = Categories.Ll; // Ll is the set of Unicode characters in category Ll (Letter, lowercase).
pub const Mark = Categories.M; // Mark/M is the set of Unicode mark characters, category M.
pub const M = Categories.M;
pub const Mc = Categories.Mc; // Mc is the set of Unicode characters in category Mc (Mark, spacing combining).
pub const Me = Categories.Me; // Me is the set of Unicode characters in category Me (Mark, enclosing).
pub const Mn = Categories.Mn; // Mn is the set of Unicode characters in category Mn (Mark, nonspacing).
pub const Nl = Categories.Nl; // Nl is the set of Unicode characters in category Nl (Number, letter).
pub const No = Categories.No; // No is the set of Unicode characters in category No (Number, other).
pub const Number = Categories.N; // Number/N is the set of Unicode number characters, category N.
pub const N = Categories.N;
pub const Other = Categories.C; // Other/C is the set of Unicode control and special characters, category C.
pub const C = Categories.C;
pub const Pc = Categories.Pc; // Pc is the set of Unicode characters in category Pc (Punctuation, connector).
pub const Pd = Categories.Pd; // Pd is the set of Unicode characters in category Pd (Punctuation, dash).
pub const Pe = Categories.Pe; // Pe is the set of Unicode characters in category Pe (Punctuation, close).
pub const Pf = Categories.Pf; // Pf is the set of Unicode characters in category Pf (Punctuation, final quote).
pub const Pi = Categories.Pi; // Pi is the set of Unicode characters in category Pi (Punctuation, initial quote).
pub const Po = Categories.Po; // Po is the set of Unicode characters in category Po (Punctuation, other).
pub const Ps = Categories.Ps; // Ps is the set of Unicode characters in category Ps (Punctuation, open).
pub const Punct = Categories.P; // Punct/P is the set of Unicode punctuation characters, category P.
pub const P = Categories.P;
pub const Sc = Categories.Sc; // Sc is the set of Unicode characters in category Sc (Symbol, currency).
pub const Sk = Categories.Sk; // Sk is the set of Unicode characters in category Sk (Symbol, modifier).
pub const Sm = Categories.Sm; // Sm is the set of Unicode characters in category Sm (Symbol, math).
pub const So = Categories.So; // So is the set of Unicode characters in category So (Symbol, other).
pub const Space = Categories.Z; // Space/Z is the set of Unicode space characters, category Z.
pub const Z = Categories.Z;
pub const Symbol = Categories.S; // Symbol/S is the set of Unicode symbol characters, category S.
pub const S = Categories.S;
pub const Title = Categories.Lt; // Title is the set of Unicode title case letters.
pub const Lt = Categories.Lt; // Lt is the set of Unicode characters in category Lt (Letter, titlecase).
pub const Upper = Categories.Lu; // Upper is the set of Unicode upper case letters.
pub const Lu = Categories.Lu; // Lu is the set of Unicode characters in category Lu (Letter, uppercase).
pub const Zl = Categories.Zl; // Zl is the set of Unicode characters in category Zl (Separator, line).
pub const Zp = Categories.Zp; // Zp is the set of Unicode characters in category Zp (Separator, paragraph).
pub const Zs = Categories.Zs; // Zs is the set of Unicode characters in category Zs (Separator, space).

/// Scripts is the set of Unicode script tables.
const Scripts = enum {
    Adlam,
    Ahom,
    Anatolian_Hieroglyphs,
    Arabic,
    Armenian,
    Avestan,
    Balinese,
    Bamum,
    Bassa_Vah,
    Batak,
    Bengali,
    Bhaiksuki,
    Bopomofo,
    Brahmi,
    Braille,
    Buginese,
    Buhid,
    Canadian_Abori,
    ginal,
    Carian,
    Caucasian_Alba,
    nian,
    Chakma,
    Cham,
    Cherokee,
    Chorasmian,
    Common,
    Coptic,
    Cuneiform,
    Cypriot,
    Cyrillic,
    Deseret,
    Devanagari,
    Dives_Akuru,
    Dogra,
    Duployan,
    Egyptian_Hieroglyphs,
    Elbasan,
    Elymaic,
    Ethiopic,
    Georgian,
    Glagolitic,
    Gothic,
    Grantha,
    Greek,
    Gujarati,
    Gunjala_Gondi,
    Gurmukhi,
    Han,
    Hangul,
    Hanifi_Rohingya,
    Hanunoo,
    Hatran,
    Hebrew,
    Hiragana,
    Imperial_Aramaic,
    Inherited,
    Inscriptional_Pahlavi,
    Inscriptional_Parthian,
    Javanese,
    Kaithi,
    Kannada,
    Katakana,
    Kayah_Li,
    Kharoshthi,
    Khitan_Small_Script,
    Khmer,
    Khojki,
    Khudawadi,
    Lao,
    Latin,
    Lepcha,
    Limbu,
    Linear_A,
    Linear_B,
    Lisu,
    Lycian,
    Lydian,
    Mahajani,
    Makasar,
    Malayalam,
    Mandaic,
    Manichaean,
    Marchen,
    Masaram_Gondi,
    Medefaidrin,
    Meetei_Mayek,
    Mende_Kikakui,
    Meroitic_Cursive,
    Meroitic_Hieroglyphs,
    Miao,
    Modi,
    Mongolian,
    Mro,
    Multani,
    Myanmar,
    Nabataean,
    Nandinagari,
    New_Tai_Lue,
    Newa,
    Nko,
    Nushu,
    Nyiakeng_Puachue_Hmong,
    Ogham,
    Ol_Chiki,
    Old_Hungarian,
    Old_Italic,
    Old_North_Arabian,
    Old_Permic,
    Old_Persian,
    Old_Sogdian,
    Old_South_Arabian,
    Old_Turkic,
    Oriya,
    Osage,
    Osmanya,
    Pahawh_Hmong,
    Palmyrene,
    Pau_Cin_Hau,
    Phags_Pa,
    Phoenician,
    Psalter_Pahlavi,
    Rejang,
    Runic,
    Samaritan,
    Saurashtra,
    Sharada,
    Shavian,
    Siddham,
    SignWriting,
    Sinhala,
    Sogdian,
    Sora_Sompeng,
    Soyombo,
    Sundanese,
    Syloti_Nagri,
    Syriac,
    Tagalog,
    Tagbanwa,
    Tai_Le,
    Tai_Tham,
    Tai_Viet,
    Takri,
    Tamil,
    Tangut,
    Telugu,
    Thaana,
    Thai,
    Tibetan,
    Tifinagh,
    Tirhuta,
    Ugaritic,
    Vai,
    Wancho,
    Warang_Citi,
    Yezidi,
    Yi,
    Zanabazar_Square,
};

/// Properties is the set of Unicode property tables.
pub const Properties = enum {
    ASCII_Hex_Digit,
    Bidi_Control,
    Dash,
    Deprecated,
    Diacritic,
    Extender,
    Hex_Digit,
    Hyphen,
    IDS_Binary_Operator,
    IDS_Trinary_Operator,
    Ideographic,
    Join_Control,
    Logical_Order_Exception,
    Noncharacter_Code_Point,
    Other_Alphabetic,
    Other_Default_Ignorable_Code_Point,
    Other_Grapheme_Extend,
    Other_ID_Continue,
    Other_ID_Start,
    Other_Lowercase,
    Other_Math,
    Other_Uppercase,
    Pattern_Syntax,
    Pattern_White_Space,
    Prepended_Concatenation_Mark,
    Quotation_Mark,
    Radical,
    Regional_Indicator,
    Sentence_Terminal,
    Soft_Dotted,
    Terminal_Punctuation,
    Unified_Ideograph,
    Variation_Selector,
    White_Space,
};

pub const properties = [max_latin_1 + 1]u8{
    pC, // '\x00'
    pC, // '\x01'
    pC, // '\x02'
    pC, // '\x03'
    pC, // '\x04'
    pC, // '\x05'
    pC, // '\x06'
    pC, // '\a'
    pC, // '\b'
    pC, // '\t'
    pC, // '\n'
    pC, // '\v'
    pC, // '\f'
    pC, // '\r'
    pC, // '\x0e'
    pC, // '\x0f'
    pC, // '\x10'
    pC, // '\x11'
    pC, // '\x12'
    pC, // '\x13'
    pC, // '\x14'
    pC, // '\x15'
    pC, // '\x16'
    pC, // '\x17'
    pC, // '\x18'
    pC, // '\x19'
    pC, // '\x1a'
    pC, // '\x1b'
    pC, // '\x1c'
    pC, // '\x1d'
    pC, // '\x1e'
    pC, // '\x1f'
    pZ | pp, // ' '
    pP | pp, // '!'
    pP | pp, // '"'
    pP | pp, // '#'
    pS | pp, // '$'
    pP | pp, // '%'
    pP | pp, // '&'
    pP | pp, // '\''
    pP | pp, // '('
    pP | pp, // ')'
    pP | pp, // '*'
    pS | pp, // '+'
    pP | pp, // ','
    pP | pp, // '-'
    pP | pp, // '.'
    pP | pp, // '/'
    pN | pp, // '0'
    pN | pp, // '1'
    pN | pp, // '2'
    pN | pp, // '3'
    pN | pp, // '4'
    pN | pp, // '5'
    pN | pp, // '6'
    pN | pp, // '7'
    pN | pp, // '8'
    pN | pp, // '9'
    pP | pp, // ':'
    pP | pp, // ';'
    pS | pp, // '<'
    pS | pp, // '='
    pS | pp, // '>'
    pP | pp, // '?'
    pP | pp, // '@'
    pLu | pp, // 'A'
    pLu | pp, // 'B'
    pLu | pp, // 'C'
    pLu | pp, // 'D'
    pLu | pp, // 'E'
    pLu | pp, // 'F'
    pLu | pp, // 'G'
    pLu | pp, // 'H'
    pLu | pp, // 'I'
    pLu | pp, // 'J'
    pLu | pp, // 'K'
    pLu | pp, // 'L'
    pLu | pp, // 'M'
    pLu | pp, // 'N'
    pLu | pp, // 'O'
    pLu | pp, // 'P'
    pLu | pp, // 'Q'
    pLu | pp, // 'R'
    pLu | pp, // 'S'
    pLu | pp, // 'T'
    pLu | pp, // 'U'
    pLu | pp, // 'V'
    pLu | pp, // 'W'
    pLu | pp, // 'X'
    pLu | pp, // 'Y'
    pLu | pp, // 'Z'
    pP | pp, // '['
    pP | pp, // '\\'
    pP | pp, // ']'
    pS | pp, // '^'
    pP | pp, // '_'
    pS | pp, // '`'
    pLl | pp, // 'a'
    pLl | pp, // 'b'
    pLl | pp, // 'c'
    pLl | pp, // 'd'
    pLl | pp, // 'e'
    pLl | pp, // 'f'
    pLl | pp, // 'g'
    pLl | pp, // 'h'
    pLl | pp, // 'i'
    pLl | pp, // 'j'
    pLl | pp, // 'k'
    pLl | pp, // 'l'
    pLl | pp, // 'm'
    pLl | pp, // 'n'
    pLl | pp, // 'o'
    pLl | pp, // 'p'
    pLl | pp, // 'q'
    pLl | pp, // 'r'
    pLl | pp, // 's'
    pLl | pp, // 't'
    pLl | pp, // 'u'
    pLl | pp, // 'v'
    pLl | pp, // 'w'
    pLl | pp, // 'x'
    pLl | pp, // 'y'
    pLl | pp, // 'z'
    pP | pp, // '{'
    pS | pp, // '|'
    pP | pp, // '}'
    pS | pp, // '~'
    pC, // '\u007f'
    pC, // '\u0080'
    pC, // '\u0081'
    pC, // '\u0082'
    pC, // '\u0083'
    pC, // '\u0084'
    pC, // '\u0085'
    pC, // '\u0086'
    pC, // '\u0087'
    pC, // '\u0088'
    pC, // '\u0089'
    pC, // '\u008a'
    pC, // '\u008b'
    pC, // '\u008c'
    pC, // '\u008d'
    pC, // '\u008e'
    pC, // '\u008f'
    pC, // '\u0090'
    pC, // '\u0091'
    pC, // '\u0092'
    pC, // '\u0093'
    pC, // '\u0094'
    pC, // '\u0095'
    pC, // '\u0096'
    pC, // '\u0097'
    pC, // '\u0098'
    pC, // '\u0099'
    pC, // '\u009a'
    pC, // '\u009b'
    pC, // '\u009c'
    pC, // '\u009d'
    pC, // '\u009e'
    pC, // '\u009f'
    pZ, // '\u00a0'
    pP | pp, // '¡'
    pS | pp, // '¢'
    pS | pp, // '£'
    pS | pp, // '¤'
    pS | pp, // '¥'
    pS | pp, // '¦'
    pP | pp, // '§'
    pS | pp, // '¨'
    pS | pp, // '©'
    pLo | pp, // 'ª'
    pP | pp, // '«'
    pS | pp, // '¬'
    0, // '\u00ad'
    pS | pp, // '®'
    pS | pp, // '¯'
    pS | pp, // '°'
    pS | pp, // '±'
    pN | pp, // '²'
    pN | pp, // '³'
    pS | pp, // '´'
    pLl | pp, // 'µ'
    pP | pp, // '¶'
    pP | pp, // '·'
    pS | pp, // '¸'
    pN | pp, // '¹'
    pLo | pp, // 'º'
    pP | pp, // '»'
    pN | pp, // '¼'
    pN | pp, // '½'
    pN | pp, // '¾'
    pP | pp, // '¿'
    pLu | pp, // 'À'
    pLu | pp, // 'Á'
    pLu | pp, // 'Â'
    pLu | pp, // 'Ã'
    pLu | pp, // 'Ä'
    pLu | pp, // 'Å'
    pLu | pp, // 'Æ'
    pLu | pp, // 'Ç'
    pLu | pp, // 'È'
    pLu | pp, // 'É'
    pLu | pp, // 'Ê'
    pLu | pp, // 'Ë'
    pLu | pp, // 'Ì'
    pLu | pp, // 'Í'
    pLu | pp, // 'Î'
    pLu | pp, // 'Ï'
    pLu | pp, // 'Ð'
    pLu | pp, // 'Ñ'
    pLu | pp, // 'Ò'
    pLu | pp, // 'Ó'
    pLu | pp, // 'Ô'
    pLu | pp, // 'Õ'
    pLu | pp, // 'Ö'
    pS | pp, // '×'
    pLu | pp, // 'Ø'
    pLu | pp, // 'Ù'
    pLu | pp, // 'Ú'
    pLu | pp, // 'Û'
    pLu | pp, // 'Ü'
    pLu | pp, // 'Ý'
    pLu | pp, // 'Þ'
    pLl | pp, // 'ß'
    pLl | pp, // 'à'
    pLl | pp, // 'á'
    pLl | pp, // 'â'
    pLl | pp, // 'ã'
    pLl | pp, // 'ä'
    pLl | pp, // 'å'
    pLl | pp, // 'æ'
    pLl | pp, // 'ç'
    pLl | pp, // 'è'
    pLl | pp, // 'é'
    pLl | pp, // 'ê'
    pLl | pp, // 'ë'
    pLl | pp, // 'ì'
    pLl | pp, // 'í'
    pLl | pp, // 'î'
    pLl | pp, // 'ï'
    pLl | pp, // 'ð'
    pLl | pp, // 'ñ'
    pLl | pp, // 'ò'
    pLl | pp, // 'ó'
    pLl | pp, // 'ô'
    pLl | pp, // 'õ'
    pLl | pp, // 'ö'
    pS | pp, // '÷'
    pLl | pp, // 'ø'
    pLl | pp, // 'ù'
    pLl | pp, // 'ú'
    pLl | pp, // 'û'
    pLl | pp, // 'ü'
    pLl | pp, // 'ý'
    pLl | pp, // 'þ'
    pLl | pp, // 'ÿ'
};
