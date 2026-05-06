/// Arabic digits map for converting English digits to Arabic digits.
const Map<String, String> _arabicDigits = {
  "0": "٠",
  "1": "١",
  "2": "٢",
  "3": "٣",
  "4": "٤",
  "5": "٥",
  "6": "٦",
  "7": "٧",
  "8": "٨",
  "9": "٩",
};

convertToArabicNumber(int number) =>
    number.toString().replaceAllMapped(RegExp(r'[0-9]'), (match) {
      return _arabicDigits[match.group(0)!] ?? match.group(0)!;
    });
