/**
 * Shared / platform strings for the web app (Owner: Rith).
 * Khmer is the default language; en must have the exact same keys (TypeScript enforces it).
 */
export const sharedKm = {
  appName: 'អេ-សុខភាព',
  webTagline: 'ផ្ទាំងសម្រាប់គ្លីនិក និងអ្នកគ្រប់គ្រង',

  // common
  save: 'រក្សាទុក',
  cancel: 'បោះបង់',
  delete: 'លុប',
  edit: 'កែប្រែ',
  close: 'បិទ',
  undo: 'មិនធ្វើវិញ',
  search: 'ស្វែងរក',
  clearFilters: 'សម្អាតតម្រង',
  apply: 'អនុវត្ត',
  optional: 'មិនចាំបាច់',
  today: 'ថ្ងៃនេះ',
  yesterday: 'ម្សិលមិញ',
  none: 'គ្មាន',
  all: 'ទាំងអស់',
  actions: 'សកម្មភាព',
  demo: 'សាកល្បង',
  prev: 'មុន',
  next: 'បន្ទាប់',
  pageOf: 'ទំព័រ {n} នៃ {total}',
  showingOf: 'បង្ហាញ {from}–{to} នៃ {total}',
  errRequired: 'ត្រូវតែបំពេញ។',

  // roles
  role_patient: 'អ្នកជំងឺ',
  role_caretaker: 'អ្នកថែទាំ',
  role_family: 'សមាជិកគ្រួសារ',
  role_doctor: 'វេជ្ជបណ្ឌិត',
  role_admin: 'អ្នកគ្រប់គ្រង',
  roleDesc_doctor: 'តាមដានអ្នកជំងឺ អានរបាយការណ៍ សរសេរកំណត់ចំណាំព្យាបាល',
  roleDesc_admin: 'គ្រប់គ្រងអ្នកប្រើ តួនាទី ការភ្ជាប់ និងប្រអប់តាមដាន',

  // measures
  bp: 'សម្ពាធឈាម',
  m_systolic: 'សម្ពាធខាងលើ',
  m_diastolic: 'សម្ពាធខាងក្រោម',
  m_pulse: 'ជីពចរ',
  m_glucose: 'ជាតិស្ករក្នុងឈាម',

  // levels
  lvl_normal: 'ធម្មតា',
  lvl_high: 'ខ្ពស់',
  lvl_low: 'ទាប',
  missed: 'ខកខាន',
  outOfRange: 'ក្រៅកម្រិតធម្មតា',
  normalRange: 'កម្រិតធម្មតា',

  // navigation
  skipToContent: 'រំលងទៅមាតិកាចម្បង',
  nav_patients: 'អ្នកជំងឺរបស់ខ្ញុំ',
  nav_users: 'អ្នកប្រើ និងតួនាទី',
  nav_fields: 'ប្រអប់តាមដាន',
  nav_links: 'ការភ្ជាប់',
  nav_readings: 'ជំនួយលទ្ធផល',
  nav_settings: 'ការកំណត់',
  mainNav: 'ម៉ឺនុយចម្បង',

  // settings
  settingsTitle: 'ការកំណត់',
  profile: 'ប្រវត្តិរូប',
  signedInAs: 'បានចូលជា',
  language: 'ភាសា',
  numerals: 'លេខ',
  numeralsKhmer: 'ខ្មែរ ១២៣',
  numeralsWestern: 'អារ៉ាប់ 123',
  textSize: 'ទំហំអក្សរ',
  textNormal: 'ធម្មតា',
  textLarge: 'ធំ',
  textXL: 'ធំណាស់',
  ranges: 'កម្រិតធម្មតាដែលប្រើសម្រាប់សម្គាល់',
  rangesHint: 'តម្លៃសាកល្បង។ ក្រុមនឹងបញ្ជាក់ឯកសារយោងវេជ្ជសាស្ត្រ (WHO / ក្រសួងសុខាភិបាល)។',
  aboutDemo: 'អំពីកម្មវិធីសាកល្បងនេះ',
  aboutDemoBody: 'មានតែផ្នែកខាងមុខ។ ទិន្នន័យទាំងអស់ជាទិន្នន័យសាកល្បង រក្សាទុកក្នុងកម្មវិធីរុករកនេះ។ គ្មានអ្វីត្រូវបានផ្ញើទៅម៉ាស៊ីនមេទេ។',
  resetDemo: 'កំណត់ទិន្នន័យសាកល្បងឡើងវិញ',
  resetConfirmTitle: 'កំណត់ទិន្នន័យសាកល្បងទាំងអស់ឡើងវិញ?',
  resetConfirmBody: 'លទ្ធផល តួនាទី ការភ្ជាប់ ប្រអប់ និងកំណត់ចំណាំ នឹងត្រឡប់ទៅទិន្នន័យដើមវិញ។',
  reset: 'កំណត់ឡើងវិញ',
  resetDone: 'បានកំណត់ទិន្នន័យសាកល្បងឡើងវិញ',
  version: 'កំណែ',

  // errors & live API
  notFound: 'រកមិនឃើញទំព័រ',
  goHome: 'ទៅទំព័រដើម',
  retry: 'ព្យាយាមម្តងទៀត',
  liveApiLoading: 'កំពុងផ្ទុកសង្ខេបពីម៉ាស៊ីនមេ…',
  liveApiConnected: 'បានភ្ជាប់ម៉ាស៊ីនមេផ្ទាល់ ({fields} ប្រអប់ · ខកខាន {missed} ថ្ងៃ · ក្រៅកម្រិត {outOfRange})',
  liveApiDemoFallback: 'បង្ហាញក្រាហ្វសាកល្បង រហូតដល់ម៉ូឌុលលទ្ធផលត្រូវបានភ្ជាប់។',
} as const;

export const sharedEn: Record<keyof typeof sharedKm, string> = {
  appName: 'E-Health',
  webTagline: 'Clinic & admin portal',

  // common
  save: 'Save',
  cancel: 'Cancel',
  delete: 'Delete',
  edit: 'Edit',
  close: 'Close',
  undo: 'Undo',
  search: 'Search',
  clearFilters: 'Clear filters',
  apply: 'Apply',
  optional: 'optional',
  today: 'Today',
  yesterday: 'Yesterday',
  none: 'None',
  all: 'All',
  actions: 'Actions',
  demo: 'Demo',
  prev: 'Previous',
  next: 'Next',
  pageOf: 'Page {n} of {total}',
  showingOf: 'Showing {from}–{to} of {total}',
  errRequired: 'This is required.',

  // roles
  role_patient: 'Patient',
  role_caretaker: 'Caretaker',
  role_family: 'Family member',
  role_doctor: 'Doctor',
  role_admin: 'Admin',
  roleDesc_doctor: 'Follow linked patients, read reports, write clinical notes',
  roleDesc_admin: 'Manage users, roles, links and tracked fields',

  // measures
  bp: 'Blood pressure',
  m_systolic: 'Systolic',
  m_diastolic: 'Diastolic',
  m_pulse: 'Pulse',
  m_glucose: 'Blood sugar',

  // levels
  lvl_normal: 'Normal',
  lvl_high: 'High',
  lvl_low: 'Low',
  missed: 'Missed',
  outOfRange: 'Out of range',
  normalRange: 'Normal range',

  // navigation
  skipToContent: 'Skip to main content',
  nav_patients: 'My patients',
  nav_users: 'Users & roles',
  nav_fields: 'Tracked fields',
  nav_links: 'Links',
  nav_readings: 'Readings support',
  nav_settings: 'Settings',
  mainNav: 'Main navigation',

  // settings
  settingsTitle: 'Settings',
  profile: 'Profile',
  signedInAs: 'Signed in as',
  language: 'Language',
  numerals: 'Numbers',
  numeralsKhmer: 'Khmer ១២៣',
  numeralsWestern: 'Western 123',
  textSize: 'Text size',
  textNormal: 'Normal',
  textLarge: 'Large',
  textXL: 'Extra large',
  ranges: 'Normal ranges used for flags',
  rangesHint: 'Demo values. The team will confirm the medical reference (WHO / Cambodian MoH).',
  aboutDemo: 'About this demo',
  aboutDemoBody: 'Front-end only. All data is made up and kept in this browser. Nothing is sent to a server.',
  resetDemo: 'Reset demo data',
  resetConfirmTitle: 'Reset all demo data?',
  resetConfirmBody: 'Readings, roles, links, fields and notes go back to the original demo data.',
  reset: 'Reset',
  resetDone: 'Demo data reset',
  version: 'Version',

  // errors & live API
  notFound: 'Page not found',
  goHome: 'Go to start page',
  retry: 'Retry',
  liveApiLoading: 'Loading live summary…',
  liveApiConnected: 'Live API connected ({fields} fields · {missed} missed days · {outOfRange} out of range)',
  liveApiDemoFallback: 'Showing demo charts until the readings module is connected.',
};
