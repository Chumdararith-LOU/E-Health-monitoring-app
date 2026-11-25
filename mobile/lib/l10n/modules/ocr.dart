// OCR camera & fallback strings for the mobile app (Owner: Phak).
// Covers screens/record/ocr_screen.dart.

const Map<String, String> ocrKm = {
  'ocrTitleBp': 'ថតឧបករណ៍វាស់សម្ពាធ',
  'ocrTitleGlu': 'ថតឧបករណ៍វាស់ជាតិស្ករ',
  'ocrHowTo': 'របៀបថតរូបឲ្យច្បាស់',
  'ocrTip1': 'កាន់ទូរស័ព្ទឲ្យត្រង់ពីលើអេក្រង់',
  'ocrTip2': 'ត្រូវឲ្យលេខទាំងអស់នៅក្នុងរូប',
  'ocrTip3': 'ជៀសវាងពន្លឺចាំងពីភ្លើង ឬព្រះអាទិត្យ',
  'openCamera': 'បើកកាមេរ៉ា',
  'demoPhotoClear': 'ប្រើរូបសាកល្បង (ច្បាស់)',
  'demoPhotoBlurry': 'ប្រើរូបសាកល្បង (ព្រិល)',
  'demoOcrNote': 'សាកល្បង៖ មិនទាន់មានការអានអក្សរពិតទេ។ លេខត្រូវបានបង្កើតដើម្បីសាកល្បងដំណើរការ។',
  'reading': 'កំពុងអានលេខ…',
  'ocrFailTitle': 'យើងមិនអាចអានលេខបានទេ',
  'ocrFailBody': 'រូបថតមិនច្បាស់គ្រប់គ្រាន់។ សូមវាយលេខ ដោយមើលរូបថត។',
  'typeInstead': 'វាយលេខដោយខ្លួនឯង',
  'retakePhoto': 'ថតរូបម្តងទៀត',
  'cameraDenied': 'មិនបានអនុញ្ញាតកាមេរ៉ាទេ។ អ្នកនៅតែអាចវាយលេខបាន។',
};

const Map<String, String> ocrEn = {
  'ocrTitleBp': 'Photo of BP monitor',
  'ocrTitleGlu': 'Photo of glucose meter',
  'ocrHowTo': 'How to take a good photo',
  'ocrTip1': 'Hold the phone straight above the screen',
  'ocrTip2': 'Make sure all numbers are inside the photo',
  'ocrTip3': 'Avoid glare from lights or the sun',
  'openCamera': 'Open camera',
  'demoPhotoClear': 'Use demo photo (clear)',
  'demoPhotoBlurry': 'Use demo photo (blurry)',
  'demoOcrNote': 'Demo: no real text recognition yet. Numbers are simulated so you can test the flow.',
  'reading': 'Reading the numbers…',
  'ocrFailTitle': 'We could not read the numbers',
  'ocrFailBody': 'The photo is not clear enough. Please type the numbers while looking at the photo.',
  'typeInstead': 'Type the numbers',
  'retakePhoto': 'Take another photo',
  'cameraDenied': 'Camera permission was not given. You can still type the numbers.',
};
