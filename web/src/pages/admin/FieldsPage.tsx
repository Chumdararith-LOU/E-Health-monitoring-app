import { useState } from 'react';
import { MEASURE_ORDER, MEASURES } from '../../data/ranges';
import { parseNum } from '../../data/validate';
import { CustomField } from '../../data/types';
import { newId, useApp } from '../../store/AppStore';
import { Modal, useFeedback } from '../../ui/Feedback';
import { Badge, Button, Card, Field, PageHeader } from '../../ui/Kit';

interface Draft {
  nameKm: string;
  nameEn: string;
  unit: string;
  decimals: string;
  min: string;
  max: string;
}
const EMPTY: Draft = { nameKm: '', nameEn: '', unit: '', decimals: '1', min: '', max: '' };

/** FR-15 / US-16: admin adds a tracked field; it appears in the entry form, history and reports. */
export function FieldsPage() {
  const { i18n, state, dispatch } = useApp();
  const { confirm, toast } = useFeedback();
  const { t } = i18n;
  const [editing, setEditing] = useState<CustomField | 'new' | null>(null);
  const [d, setD] = useState<Draft>(EMPTY);
  const [submitted, setSubmitted] = useState(false);
  const used = (id: string) => state.data.readings.filter((r) => r.extra?.[id] != null).length;

  const startNew = () => {
    setD(EMPTY);
    setSubmitted(false);
    setEditing('new');
  };
  const startEdit = (f: CustomField) => {
    setD({ nameKm: f.nameKm, nameEn: f.nameEn, unit: f.unit, decimals: String(f.decimals), min: String(f.min), max: String(f.max) });
    setSubmitted(false);
    setEditing(f);
  };

  const locked = editing && editing !== 'new' && used(editing.id) > 0;

  // validation
  const errs: Partial<Record<keyof Draft, string>> = {};
  const others = state.data.fields.filter((f) => editing === 'new' || f.id !== (editing as CustomField | null)?.id);
  const builtInNames = MEASURE_ORDER.flatMap((k) => [t(`m_${k}`).toLowerCase()]);
  if (!d.nameKm.trim()) errs.nameKm = t('errRequired');
  else if (others.some((f) => f.nameKm.trim() === d.nameKm.trim())) errs.nameKm = t('errDupName');
  if (!d.nameEn.trim()) errs.nameEn = t('errRequired');
  else if (others.some((f) => f.nameEn.trim().toLowerCase() === d.nameEn.trim().toLowerCase()) || builtInNames.includes(d.nameEn.trim().toLowerCase())) errs.nameEn = t('errDupName');
  if (!d.unit.trim()) errs.unit = t('errRequired');
  const mn = parseNum(d.min), mx = parseNum(d.max);
  if (mn == null) errs.min = t('errRequired');
  else if (mn === 'nan') errs.min = t('errNumber');
  if (mx == null) errs.max = t('errRequired');
  else if (mx === 'nan') errs.max = t('errNumber');
  if (typeof mn === 'number' && typeof mx === 'number' && mn >= mx) errs.max = t('errMinMax');
  const ok = !Object.keys(errs).length;
  const err = (k: keyof Draft) => (submitted ? errs[k] : undefined);

  const save = () => {
    setSubmitted(true);
    if (!ok) {
      const first = (['nameKm', 'nameEn', 'unit', 'min', 'max'] as const).find((k) => errs[k]);
      if (first) document.getElementById(`f-${first}`)?.focus();
      return;
    }
    const base = editing === 'new' ? { id: newId('f'), active: true, createdAt: new Date().toISOString() } : editing!;
    const field: CustomField = {
      ...base,
      nameKm: d.nameKm.trim(),
      nameEn: d.nameEn.trim(),
      unit: d.unit.trim(),
      decimals: Number(d.decimals),
      min: mn as number,
      max: mx as number,
    };
    dispatch({ type: 'upsertField', field });
    setEditing(null);
    toast({ message: t('fieldSaved', { name: i18n.name(field) }) });
  };

  const toggleArchive = async (f: CustomField) => {
    if (f.active) {
      const yes = await confirm({ title: t('archiveTitle', { name: i18n.name(f) }), body: t('archiveBody'), confirmLabel: t('archive'), icon: 'archive', danger: true });
      if (!yes) return;
    }
    dispatch({ type: 'upsertField', field: { ...f, active: !f.active } });
    toast({
      message: t(f.active ? 'fieldArchived' : 'fieldRestored', { name: i18n.name(f) }),
      undo: () => dispatch({ type: 'upsertField', field: f }),
    });
  };

  const input = (k: keyof Draft, label: string, extra: Record<string, unknown> = {}, hint?: string) => (
    <Field label={label} error={err(k)} hint={hint}>
      {(p) => <input {...p} id={`f-${k}`} className="input" value={d[k]} onChange={(e) => setD({ ...d, [k]: e.target.value })} {...extra} />}
    </Field>
  );

  const previewName = (i18n.lang === 'km' ? d.nameKm : d.nameEn) || (i18n.lang === 'km' ? d.nameEn : d.nameKm) || '…';
  const step = d.decimals === '0' ? '1' : d.decimals === '1' ? '0.1' : '0.01';

  return (
    <>
      <PageHeader title={t('nav_fields')} subtitle={t('fieldsSubtitle')} actions={<Button icon="plus" onClick={startNew}>{t('addField')}</Button>} />
      <Card className="card-tight">
        <div className="table-wrap">
          <table className="table responsive">
            <caption className="sr-only">{t('nav_fields')}</caption>
            <thead>
              <tr>
                <th scope="col">{t('colField')}</th>
                <th scope="col">{t('unit')}</th>
                <th scope="col">{t('numberType')}</th>
                <th scope="col" className="num">{t('allowedValues')}</th>
                <th scope="col" className="num">{t('colUsed')}</th>
                <th scope="col">{t('status')}</th>
                <th scope="col"><span className="sr-only">{t('actions')}</span></th>
              </tr>
            </thead>
            <tbody>
              {MEASURE_ORDER.map((k) => (
                <tr key={k}>
                  <td data-label={t('colField')}>
                    <span className="strong">{t(`m_${k}`)}</span>
                  </td>
                  <td data-label={t('unit')}>{MEASURES[k].unit}</td>
                  <td data-label={t('numberType')}>{t('decimals_0')}</td>
                  <td data-label={t('allowedValues')} className="num">
                    {i18n.num(MEASURES[k].safeMin)}–{i18n.num(MEASURES[k].safeMax)}
                  </td>
                  <td data-label={t('colUsed')} className="num muted">–</td>
                  <td data-label={t('status')}><Badge kind="info" icon="lock">{t('builtIn')}</Badge></td>
                  <td />
                </tr>
              ))}
              {state.data.fields.map((f) => (
                <tr key={f.id} style={f.active ? undefined : { color: 'var(--text-muted)' }}>
                  <td data-label={t('colField')}>
                    <span className="strong">{i18n.name(f)}</span>
                    <div className="cell-sub">{i18n.lang === 'km' ? f.nameEn : f.nameKm}</div>
                  </td>
                  <td data-label={t('unit')}>{f.unit}</td>
                  <td data-label={t('numberType')}>{t(`decimals_${f.decimals}` as 'decimals_0')}</td>
                  <td data-label={t('allowedValues')} className="num">
                    {i18n.num(f.min, f.decimals)}–{i18n.num(f.max, f.decimals)}
                  </td>
                  <td data-label={t('colUsed')} className="num">{t('usedIn', { n: used(f.id) })}</td>
                  <td data-label={t('status')}>
                    {f.active ? <Badge kind="normal" icon="check">{t('active')}</Badge> : <Badge kind="neutral" icon="archive">{t('archived')}</Badge>}
                  </td>
                  <td>
                    <div className="row" style={{ justifyContent: 'flex-end' }}>
                      <Button small variant="ghost" icon="edit" onClick={() => startEdit(f)} aria-label={`${t('edit')}: ${i18n.name(f)}`}>
                        {t('edit')}
                      </Button>
                      <Button small variant={f.active ? 'ghost-danger' : 'ghost'} icon={f.active ? 'archive' : 'unarchive'} onClick={() => toggleArchive(f)} aria-label={`${f.active ? t('archive') : t('restore')}: ${i18n.name(f)}`}>
                        {f.active ? t('archive') : t('restore')}
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <Modal
        open={!!editing}
        onClose={() => setEditing(null)}
        wide
        icon="fields"
        title={editing === 'new' ? t('addField') : t('editField')}
        footer={
          <>
            <Button variant="secondary" onClick={() => setEditing(null)}>{t('cancel')}</Button>
            <Button icon="check" onClick={save}>{t('save')}</Button>
          </>
        }
      >
        {submitted && !ok ? <div className="banner banner-error" role="alert">{t('errFixBelow')}</div> : null}
        <div className="form-grid">
          {input('nameKm', t('fieldNameKm'), { lang: 'km', autoFocus: true })}
          {input('nameEn', t('fieldNameEn'), { lang: 'en' })}
          {input('unit', t('unit'), { disabled: locked }, t('unitHint'))}
          <Field label={t('numberType')}>
            {(p) => (
              <select {...p} className="select" value={d.decimals} disabled={!!locked} onChange={(e) => setD({ ...d, decimals: e.target.value })}>
                <option value="0">{t('decimals_0')}</option>
                <option value="1">{t('decimals_1')}</option>
                <option value="2">{t('decimals_2')}</option>
              </select>
            )}
          </Field>
          {input('min', t('minValue'), { inputMode: 'decimal' })}
          {input('max', t('maxValue'), { inputMode: 'decimal' })}
          <p className="hint span-2">{locked ? t('noFieldChangeUnit') : t('limitsHint')}</p>
        </div>
        <div className="stack-sm">
          <span className="field-label">{t('preview')}</span>
          <div style={{ maxWidth: '20rem', padding: 'var(--s4)', border: '1px dashed var(--border-strong)', borderRadius: 'var(--r-lg)', background: 'var(--surface-alt)' }} aria-hidden>
            <div className="field">
              <span className="field-label">
                {previewName} ({t('optional')})
              </span>
              <div className="input-wrap">
                <input className="input input-big" placeholder="–" tabIndex={-1} readOnly step={step} />
                <span className="suffix">{d.unit || ''}</span>
              </div>
              <span className="hint">
                {d.min || '?'}–{d.max || '?'} {d.unit}
              </span>
            </div>
          </div>
        </div>
      </Modal>
    </>
  );
}
