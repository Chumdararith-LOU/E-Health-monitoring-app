import { levelOf, MEASURE_ORDER, MEASURES, readingLevel } from '../data/ranges';
import { Reading } from '../data/types';
import { useApp } from '../store/AppStore';
import { Modal } from './Feedback';
import { Icon } from './Icon';
import { Button, StatusBadge } from './Kit';

/** Read-only reading detail: each value against its normal range explains WHY it is flagged. */
export function ReadingModal({ reading, onClose, footer }: { reading: Reading | null; onClose: () => void; footer?: React.ReactNode }) {
  const { i18n, userById, state } = useApp();
  const { t } = i18n;
  const r = reading;
  const author = r ? userById(r.enteredBy) : undefined;
  return (
    <Modal
      open={!!r}
      onClose={onClose}
      title={r ? `${i18n.date(r.takenAt)} · ${i18n.time(r.takenAt)}` : ''}
      footer={
        footer ?? (
          <Button variant="secondary" onClick={onClose}>
            {t('close')}
          </Button>
        )
      }
    >
      {r ? (
        <>
          <div className="row">
            <span className="muted">{i18n.name(userById(r.patientId))}</span>
            <span className="right" />
            <StatusBadge level={readingLevel(r)} />
          </div>
          <table className="table stats">
            <thead>
              <tr>
                <th scope="col">{t('measure')}</th>
                <th scope="col" className="num">
                  {t('value')}
                </th>
                <th scope="col">{t('normalRange')}</th>
                <th scope="col">{t('status')}</th>
              </tr>
            </thead>
            <tbody>
              {MEASURE_ORDER.filter((k) => r[k] != null).map((k) => (
                <tr key={k}>
                  <th scope="row" style={{ background: 'none', color: 'var(--text)', fontSize: '0.9375rem', fontWeight: 500 }}>
                    {t(`m_${k}`)}
                  </th>
                  <td className="num strong">
                    {i18n.num(r[k])} <span className="cell-sub">{MEASURES[k].unit}</span>
                  </td>
                  <td className="muted num">
                    {i18n.num(MEASURES[k].normalMin)}–{i18n.num(MEASURES[k].normalMax)}
                  </td>
                  <td>
                    <StatusBadge level={levelOf(k, r[k])!} />
                  </td>
                </tr>
              ))}
              {state.data.fields
                .filter((f) => r.extra?.[f.id] != null)
                .map((f) => (
                  <tr key={f.id}>
                    <th scope="row" style={{ background: 'none', color: 'var(--text)', fontSize: '0.9375rem', fontWeight: 500 }}>
                      {i18n.name(f)}
                    </th>
                    <td className="num strong">
                      {i18n.num(r.extra[f.id], f.decimals)} <span className="cell-sub">{f.unit}</span>
                    </td>
                    <td className="muted">–</td>
                    <td />
                  </tr>
                ))}
            </tbody>
          </table>
          <div className="stack-sm">
            <div className="row">
              <Icon name={r.method === 'ocr' ? 'camera' : 'keyboard'} />
              {t(`method_${r.method}`)}
            </div>
            <div className="row">
              <Icon name="account" />
              {t('enteredBy')}: {i18n.name(author)} ({author ? i18n.role(author.role) : ''})
            </div>
            {r.note ? (
              <div className="row" style={{ alignItems: 'flex-start' }}>
                <Icon name="note" />
                <span>{r.note}</span>
              </div>
            ) : null}
          </div>
        </>
      ) : null}
    </Modal>
  );
}
