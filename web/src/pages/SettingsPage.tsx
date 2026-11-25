import { MEASURE_ORDER, MEASURES } from '../data/ranges';
import { useApp } from '../store/AppStore';
import { useFeedback } from '../ui/Feedback';
import { Avatar, Button, Card, PageHeader, Segmented } from '../ui/Kit';

export function SettingsPage() {
  const { i18n, user, state, setSettings, dispatch } = useApp();
  const { confirm, toast } = useFeedback();
  const { t } = i18n;
  const s = state.settings;
  if (!user) return null;

  const row = (label: string, control: React.ReactNode) => (
    <div className="row-wrap" style={{ justifyContent: 'space-between', gap: 'var(--s3)' }}>
      <span className="strong">{label}</span>
      {control}
    </div>
  );

  return (
    <>
      <PageHeader title={t('settingsTitle')} />
      <div className="grid-2" style={{ alignItems: 'start' }}>
        <div className="stack">
          <Card>
            <h2>{t('profile')}</h2>
            <div className="row" style={{ gap: 'var(--s3)' }}>
              <Avatar name={i18n.name(user)} big />
              <div>
                <div className="small muted">{t('signedInAs')}</div>
                <div className="strong">{i18n.name(user)}</div>
                <div className="small muted">
                  {i18n.role(user.role)} · {user.phone}
                </div>
              </div>
            </div>
          </Card>
          <Card>
            <h2>{t('language')}</h2>
            {row(
              t('language'),
              <Segmented label={t('language')} value={s.lang} onChange={(lang) => setSettings({ lang })} options={[{ value: 'km', label: 'ខ្មែរ' }, { value: 'en', label: 'English' }]} />,
            )}
            {row(
              t('numerals'),
              <Segmented label={t('numerals')} value={s.numerals} onChange={(numerals) => setSettings({ numerals })} options={[{ value: 'western', label: t('numeralsWestern') }, { value: 'khmer', label: t('numeralsKhmer') }]} />,
            )}
            {row(
              t('textSize'),
              <Segmented label={t('textSize')} value={s.textScale} onChange={(textScale) => setSettings({ textScale })} options={[{ value: 1, label: t('textNormal') }, { value: 1.15, label: t('textLarge') }, { value: 1.3, label: t('textXL') }]} />,
            )}
          </Card>
        </div>
        <div className="stack">
          <Card>
            <h2>{t('ranges')}</h2>
            <table className="table stats">
              <thead>
                <tr>
                  <th scope="col">{t('measure')}</th>
                  <th scope="col" className="num">{t('normalRange')}</th>
                </tr>
              </thead>
              <tbody>
                {MEASURE_ORDER.map((k) => (
                  <tr key={k}>
                    <td>{t(`m_${k}`)}</td>
                    <td className="num">
                      {i18n.num(MEASURES[k].normalMin)}–{i18n.num(MEASURES[k].normalMax)} <span className="cell-sub">{MEASURES[k].unit}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className="hint">{t('rangesHint')}</p>
          </Card>
          <Card>
            <h2>{t('aboutDemo')}</h2>
            <p>{t('aboutDemoBody')}</p>
            <p className="small muted">{t('version')} 1.0.0 (demo)</p>
            <div>
              <Button
                variant="secondary"
                icon="restore"
                onClick={async () => {
                  if (await confirm({ title: t('resetConfirmTitle'), body: t('resetConfirmBody'), confirmLabel: t('reset'), danger: true, icon: 'restore' })) {
                    dispatch({ type: 'resetData' });
                    toast({ message: t('resetDone') });
                  }
                }}
              >
                {t('resetDemo')}
              </Button>
            </div>
          </Card>
        </div>
      </div>
    </>
  );
}
