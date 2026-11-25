import * as mdi from '@mdi/js';

/** Material Design Icons (same family as the mobile app). Decorative by default (aria-hidden). */
export type IconName =
  | 'heartPulse' | 'patients' | 'users' | 'fields' | 'link' | 'readings' | 'settings' | 'logout' | 'search'
  | 'chevronRight' | 'chevronLeft' | 'up' | 'down' | 'normal' | 'highCircle' | 'lowCircle' | 'missed' | 'error'
  | 'alert' | 'info' | 'warning' | 'check' | 'close' | 'plus' | 'edit' | 'delete' | 'pdf' | 'note' | 'camera'
  | 'keyboard' | 'phone' | 'account' | 'doctor' | 'caretaker' | 'family' | 'table' | 'chart' | 'sortUp' | 'sortDown'
  | 'sort' | 'archive' | 'unarchive' | 'shield' | 'clockAlert' | 'translate' | 'eye' | 'eyeOff' | 'login' | 'water'
  | 'restore' | 'calendar' | 'lock' | 'waiting' | 'checkCircle';

const PATHS: Record<IconName, string> = {
  heartPulse: mdi.mdiHeartPulse,
  patients: mdi.mdiAccountGroupOutline,
  users: mdi.mdiAccountKeyOutline,
  fields: mdi.mdiFormTextbox,
  link: mdi.mdiLinkVariant,
  readings: mdi.mdiClipboardPulseOutline,
  settings: mdi.mdiCogOutline,
  logout: mdi.mdiLogout,
  search: mdi.mdiMagnify,
  chevronRight: mdi.mdiChevronRight,
  chevronLeft: mdi.mdiChevronLeft,
  up: mdi.mdiArrowUpBold,
  down: mdi.mdiArrowDownBold,
  normal: mdi.mdiCheckCircle,
  highCircle: mdi.mdiArrowUpBoldCircle,
  lowCircle: mdi.mdiArrowDownBoldCircle,
  missed: mdi.mdiCalendarRemove,
  error: mdi.mdiAlertCircle,
  alert: mdi.mdiAlert,
  info: mdi.mdiInformationOutline,
  warning: mdi.mdiAlertOutline,
  check: mdi.mdiCheck,
  close: mdi.mdiClose,
  plus: mdi.mdiPlus,
  edit: mdi.mdiPencil,
  delete: mdi.mdiTrashCanOutline,
  pdf: mdi.mdiFilePdfBox,
  note: mdi.mdiNoteTextOutline,
  camera: mdi.mdiCameraOutline,
  keyboard: mdi.mdiKeyboardOutline,
  phone: mdi.mdiPhoneOutline,
  account: mdi.mdiAccountCircle,
  doctor: mdi.mdiStethoscope,
  caretaker: mdi.mdiHandHeart,
  family: mdi.mdiAccountMultiple,
  table: mdi.mdiTable,
  chart: mdi.mdiChartLine,
  sortUp: mdi.mdiArrowUp,
  sortDown: mdi.mdiArrowDown,
  sort: mdi.mdiSwapVertical,
  archive: mdi.mdiArchiveOutline,
  unarchive: mdi.mdiArchiveArrowUpOutline,
  shield: mdi.mdiShieldAccountOutline,
  clockAlert: mdi.mdiClockAlertOutline,
  translate: mdi.mdiTranslate,
  eye: mdi.mdiEyeOutline,
  eyeOff: mdi.mdiEyeOffOutline,
  login: mdi.mdiLogin,
  water: mdi.mdiWaterOutline,
  restore: mdi.mdiRestore,
  calendar: mdi.mdiCalendarRange,
  lock: mdi.mdiLockOutline,
  waiting: mdi.mdiTimerSand,
  checkCircle: mdi.mdiCheckCircleOutline,
};

export function Icon({ name, size = 20, title, className }: { name: IconName; size?: number; title?: string; className?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      aria-hidden={title ? undefined : true}
      role={title ? 'img' : undefined}
      focusable="false"
    >
      {title ? <title>{title}</title> : null}
      <path d={PATHS[name]} />
    </svg>
  );
}
