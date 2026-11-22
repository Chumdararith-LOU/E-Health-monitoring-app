// Admin: custom field builder (FR-15, US-16). Definition form → live preview
// in the mobile form and report row → checks → Publish. "Off" archives a
// field but keeps its history. Seyla owns the API behind this later.

import { useState } from 'react';
import { useApp } from '../state/AppState';
import { Crumbs, Header } from '../components/Header';
import { Icon } from '../components/Icon';
import { Alert, Badge, ErrorState, Loading, Panel, Segmented } from '../components/ui';
import type { Lang, VitalField } from '../data/types';
import { fmtValue } from '../lib/stats';

interface Form {
  km: string;
  en: string;
  unit: string;
  decimal: boolean;
  hardMin: string;
  hardMax: string;
  normalMin: string;
  normalMax: string;
  active: boolean;
}

const EMPTY: Form = { km: 'រង្វង់ចង្កេះ', en: 'Waist circumference', unit: 'cm', decimal: true, hardMin: '40', hardMax: '180', normalMin: '60', normalMax: '90', active: true };

const toForm = (fd: VitalField): Form => ({
  km: fd.name.km,
  en: fd.name.en,
  unit: fd.unit,
  decimal: fd.decimal,
  hardMin: String(fd.hardMin),
  hardMax: String(fd.hardMax),
  normalMin: String(fd.normalMin),
  normalMax: String(fd.normalMax),
  active: fd.active,
});

const num = (s: string) => (s.trim() === '' ? NaN : Number(s));

export function AdminFields() {
  const { t, f, lang, data, saveField, setFieldActive, simulate, setSimulate } = useApp();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<Form>(EMPTY);
  const [tried, setTried] = useState(false);
  const [previewLang, setPreviewLang] = useState<Lang>(lang);
  const [banner, setBanner] = useState<string | null>(null);
  const offline = simulate === 'offline';

  const set = <K extends keyof Form>(k: K, v: Form[K]) => setForm((p) => ({ ...p, [k]: v }));

  // ---------- Validation (err.adminRangeInvalid etc.) ----------
  const hMin = num(form.hardMin);
  const hMax = num(form.hardMax);
  const nMin = num(form.normalMin);
  const nMax = num(form.normalMax);
  const numbersOk = [hMin, hMax, nMin, nMax].every((v) => !Number.isNaN(v));
  const checks = {
    names: form.km.trim() !== '' && form.en.trim() !== '',
    unit: form.unit.trim() !== '',
    hard: numbersOk && hMin < hMax,
    normal: numbersOk && nMin < nMax && nMin >= hMin && nMax <= hMax,
    fit: form.km.trim().length <= 28 && form.en.trim().length <= 28,
  };
  const errors: Partial<Record<keyof Form | 'range', string>> = {};
  if (!checks.names) errors.km = t.errNames;
  if (!checks.unit) errors.unit = t.errUnit;
  if (!numbersOk) errors.range = t.errNumber;
  else if (!checks.hard) errors.hardMin = t.errHard;
  else if (!checks.normal) errors.normalMin = t.errNormal;
  const valid = Object.keys(errors).length === 0;

  function publish() {
    setTried(true);
    if (!valid || offline) return;
    const id = editingId ?? `cf-${form.en.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${Date.now().toString(36)}`;
    const field: VitalField = {
      id,
      name: { km: form.km.trim(), en: form.en.trim() },
      unit: form.unit.trim(),
      decimal: form.decimal,
      hardMin: hMin,
      hardMax: hMax,
      normalMin: nMin,
      normalMax: nMax,
      core: false,
      active: form.active,
    };
    saveField(field);
    setBanner(t.published(field.name[lang]));
    setEditingId(null);
    setForm({ ...EMPTY, km: '', en: '', unit: '' });
    setTried(false);
  }

  const show = (k: keyof typeof errors) => (tried ? errors[k] : undefined);
  const previewName = (previewLang === 'km' ? form.km : form.en) || '—';
  const pf = { ...f };
  const fakeField: VitalField = { id: 'preview', name: { km: form.km, en: form.en }, unit: form.unit, decimal: form.decimal, hardMin: hMin, hardMax: hMax, normalMin: nMin, normalMax: nMax, core: false, active: true };
  const sample = numbersOk ? (nMin + nMax) / 2 : 0;
  const fmt = (v: number) => (numbersOk ? fmtValue(fakeField, v) : '—');

  let table;
  if (simulate === 'loading') table = <Loading />;
  else if (simulate === 'error') table = <ErrorState onRetry={() => setSimulate('none')} />;
  else
    table = (
      <Panel title={t.fieldsTable} bodyClass="" right={<span className="cap">{t.fieldsSync}</span>}>
        <div className="tbl-scroll">
          <table className="dt num" style={{ minWidth: 820 }}>
            <thead>
              <tr>
                <th>{t.colField}</th>
                <th>{t.colUnit}</th>
                <th>{t.colType}</th>
                <th>{t.colHard}</th>
                <th>{t.colNormal}</th>
                <th>{t.status}</th>
                <th style={{ width: 180 }}>{t.colAction}</th>
              </tr>
            </thead>
            <tbody>
              {data.customFields.map((fd) => (
                <tr key={fd.id} className={!fd.active ? 'r-off' : undefined}>
                  <td>
                    <b>{fd.name.km}</b>
                    <div className="cap">{fd.name.en}</div>
                  </td>
                  <td>{fd.unit}</td>
                  <td>{fd.decimal ? t.decimal : t.integer}</td>
                  <td>{f.n(`${fmtValue(fd, fd.hardMin)} – ${fmtValue(fd, fd.hardMax)}`)}</td>
                  <td>{f.n(`${fmtValue(fd, fd.normalMin)} – ${fmtValue(fd, fd.normalMax)}`)}</td>
                  <td>
                    {fd.active ? (
                      <Badge tone="ok">{t.active}</Badge>
                    ) : (
                      <>
                        <Badge tone="gray" icon={null}>
                          {t.disabled}
                        </Badge>
                        <div className="cap">{t.historyKept}</div>
                      </>
                    )}
                  </td>
                  <td>
                    <div className="row" style={{ gap: 6, flexWrap: 'nowrap' }}>
                      <button
                        type="button"
                        className="btn btn-gray btn-sm"
                        onClick={() => {
                          setEditingId(fd.id);
                          setForm(toForm(fd));
                          setTried(false);
                          setBanner(null);
                          document.getElementById('field-form')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        }}
                      >
                        {t.edit}
                      </button>
                      <button
                        type="button"
                        className={`btn btn-sm ${fd.active ? 'btn-danger' : 'btn-gray'}`}
                        disabled={offline}
                        onClick={() => {
                          setFieldActive(fd.id, !fd.active);
                          setBanner(fd.active ? t.turnedOff(fd.name[lang]) : t.turnedOn(fd.name[lang]));
                        }}
                      >
                        {fd.active ? t.disable : t.enable}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="cap" style={{ padding: '10px 14px', borderTop: '1px solid var(--border)' }}>
          <Icon name="lock" /> {t.coreLocked}
        </p>
      </Panel>
    );

  const Check = ({ ok, children }: { ok: boolean; children: string }) => (
    <div className="row" style={{ gap: 8, flexWrap: 'nowrap', alignItems: 'flex-start', color: ok ? 'var(--ok-text)' : 'var(--err-text)' }}>
      <Icon name={ok ? 'check' : 'x'} strokeWidth={3} />
      <span>{children}</span>
    </div>
  );

  return (
    <>
      <Header active="fields" />
      <Crumbs items={[{ label: t.adminPortal, href: '#/admin/users' }, { label: t.tabFields }]} />
      <main className="wrap page">
        <div>
          <h1 className="page-title">{t.fieldsTitle}</h1>
          <p className="cap">{t.fieldsSub}</p>
        </div>
        {banner && <Alert sev="ok">{banner}</Alert>}
        {offline && (
          <Alert sev="warn" icon="wifiOff">
            {t.offlineAction}
          </Alert>
        )}
        {table}

        <div className="split" id="field-form">
          <section className="panel" style={{ flex: '1 1 420px', minWidth: 0 }}>
            <div className="ph">
              <h2>{editingId ? t.formEdit : t.formAdd}</h2>
              <Badge tone={editingId ? 'info' : 'gray'} icon={null}>
                {editingId ? t.editing : t.newField}
              </Badge>
            </div>
            <form
              className="pb"
              style={{ display: 'flex', flexDirection: 'column', gap: 14 }}
              onSubmit={(e) => {
                e.preventDefault();
                publish();
              }}
              noValidate
            >
              <div>
                <label className="label" htmlFor="f-km">
                  {t.nameKm}
                </label>
                <input id="f-km" className={`input input-block ${show('km') && !form.km.trim() ? 'err' : ''}`} value={form.km} onChange={(e) => set('km', e.target.value)} />
              </div>
              <div>
                <label className="label" htmlFor="f-en">
                  {t.nameEn}
                </label>
                <input id="f-en" className={`input input-block ${show('km') && !form.en.trim() ? 'err' : ''}`} value={form.en} onChange={(e) => set('en', e.target.value)} />
                {show('km') && <div className="field-err">{errors.km}</div>}
              </div>
              <div className="grid2">
                <div>
                  <label className="label" htmlFor="f-unit">
                    {t.unit}
                  </label>
                  <input id="f-unit" className={`input input-block ${show('unit') ? 'err' : ''}`} value={form.unit} onChange={(e) => set('unit', e.target.value)} />
                  {show('unit') && <div className="field-err">{errors.unit}</div>}
                </div>
                <div>
                  <span className="label">{t.numberType}</span>
                  <Segmented
                    label={t.numberType}
                    value={form.decimal}
                    onChange={(v) => set('decimal', v)}
                    options={[
                      { value: false, label: t.integer },
                      { value: true, label: t.decimal },
                    ]}
                  />
                </div>
              </div>
              <fieldset className="box">
                <legend>{t.hardLimits}</legend>
                <div className="grid2">
                  <div>
                    <label className="label" htmlFor="f-hmin">
                      {t.min}
                    </label>
                    <input id="f-hmin" inputMode="decimal" className={`input input-block num ${show('hardMin') || show('range') ? 'err' : ''}`} value={form.hardMin} onChange={(e) => set('hardMin', e.target.value)} />
                  </div>
                  <div>
                    <label className="label" htmlFor="f-hmax">
                      {t.max}
                    </label>
                    <input id="f-hmax" inputMode="decimal" className={`input input-block num ${show('hardMin') || show('range') ? 'err' : ''}`} value={form.hardMax} onChange={(e) => set('hardMax', e.target.value)} />
                  </div>
                </div>
                {show('hardMin') && <div className="field-err">{errors.hardMin}</div>}
              </fieldset>
              <fieldset className="box">
                <legend>{t.normalBand}</legend>
                <div className="grid2">
                  <div>
                    <label className="label" htmlFor="f-nmin">
                      {t.min}
                    </label>
                    <input id="f-nmin" inputMode="decimal" className={`input input-block num ${show('normalMin') || show('range') ? 'err' : ''}`} value={form.normalMin} onChange={(e) => set('normalMin', e.target.value)} />
                  </div>
                  <div>
                    <label className="label" htmlFor="f-nmax">
                      {t.max}
                    </label>
                    <input id="f-nmax" inputMode="decimal" className={`input input-block num ${show('normalMin') || show('range') ? 'err' : ''}`} value={form.normalMax} onChange={(e) => set('normalMax', e.target.value)} />
                  </div>
                </div>
                {show('normalMin') && <div className="field-err">{errors.normalMin}</div>}
                {show('range') && <div className="field-err">{errors.range}</div>}
              </fieldset>
              <label className="chk">
                <input type="checkbox" checked={form.active} onChange={(e) => set('active', e.target.checked)} />
                {t.activeNow}
              </label>
              {tried && !valid && <Alert sev="err">{t.fixFirst}</Alert>}
              <div className="row" style={{ justifyContent: 'flex-end', paddingTop: 4, borderTop: '1px solid var(--divider)' }}>
                <button
                  type="button"
                  className="btn btn-gray"
                  onClick={() => {
                    setEditingId(null);
                    setForm(EMPTY);
                    setTried(false);
                  }}
                >
                  {t.cancel}
                </button>
                <button type="submit" className="btn btn-green" disabled={offline || (tried && !valid)}>
                  <Icon name="check" strokeWidth={3} />
                  {t.publish}
                </button>
              </div>
            </form>
          </section>

          <Panel
            className=""
            title={t.preview}
            right={
              <Segmented
                label={t.language}
                value={previewLang}
                onChange={setPreviewLang}
                options={[
                  { value: 'km', label: 'ខ្មែរ' },
                  { value: 'en', label: 'EN' },
                ]}
              />
            }
          >
            <div style={{ display: 'flex', flexDirection: 'column', gap: 16, minWidth: 0 }}>
              <div>
                <div className="cap" style={{ fontWeight: 700, color: 'var(--text)', marginBottom: 6 }}>
                  {t.previewForm}
                </div>
                <div style={{ maxWidth: 360, padding: 12, border: '1px dashed var(--border-strong)', borderRadius: 4, background: 'var(--canvas)' }}>
                  <div className="row between" style={{ flexWrap: 'nowrap' }}>
                    <span style={{ fontSize: 16, fontWeight: 600, lineHeight: 1.65, overflowWrap: 'anywhere' }}>{previewName}</span>
                    <Badge tone="gray" icon={null}>
                      {previewLang === 'km' ? 'មិនចាំបាច់' : 'Optional'}
                    </Badge>
                  </div>
                  <div style={{ display: 'flex', height: 56, marginTop: 4, border: '1px solid var(--border-input)', borderRadius: 4, background: '#fff', overflow: 'hidden' }}>
                    <span className="num" style={{ flex: 1, display: 'flex', alignItems: 'center', padding: '0 14px', fontSize: 20, fontWeight: 600 }}>
                      {pf.n(fmt(sample))}
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minWidth: 84, padding: '0 8px', background: '#E8ECEF', borderLeft: '1px solid var(--border-input)', fontSize: 15, fontWeight: 600, color: 'var(--text2)' }}>{form.unit || '—'}</span>
                  </div>
                  <div className="cap num" style={{ marginTop: 4 }}>
                    {previewLang === 'km' ? 'អនុញ្ញាត' : 'Allowed'} {pf.n(`${fmt(hMin)}–${fmt(hMax)}`)} {form.unit} · {previewLang === 'km' ? 'ធម្មតា' : 'normal'} {pf.n(`${fmt(nMin)}–${fmt(nMax)}`)} {form.unit}
                  </div>
                </div>
              </div>
              <div>
                <div className="cap" style={{ fontWeight: 700, color: 'var(--text)', marginBottom: 6 }}>
                  {t.previewRow}
                </div>
                <table className="dt num" style={{ border: '1px solid var(--border)' }}>
                  <thead>
                    <tr>
                      <th>{previewLang === 'km' ? 'ការវាស់' : 'Measure'}</th>
                      <th className="r">{previewLang === 'km' ? 'ទាបបំផុត' : 'Min'}</th>
                      <th className="r">{previewLang === 'km' ? 'មធ្យម' : 'Avg'}</th>
                      <th className="r">{previewLang === 'km' ? 'ខ្ពស់បំផុត' : 'Max'}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td style={{ height: 44 }}>
                        {previewName} ({form.unit || '—'})
                      </td>
                      <td className="r">{pf.n(fmt(sample - (numbersOk ? (nMax - nMin) * 0.1 : 0)))}</td>
                      <td className="r">{pf.n(fmt(sample))}</td>
                      <td className="r">{pf.n(fmt(sample + (numbersOk ? (nMax - nMin) * 0.1 : 0)))}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div>
                <div className="cap" style={{ fontWeight: 700, color: 'var(--text)', marginBottom: 6 }}>
                  {t.previewChecks}
                </div>
                <div className={`alert ${valid && checks.fit ? 'a-ok' : 'a-warn'}`} style={{ flexDirection: 'column', gap: 4 }}>
                  <Check ok={checks.names}>{t.chkNames}</Check>
                  <Check ok={checks.unit}>{t.chkUnit}</Check>
                  <Check ok={checks.hard}>{t.chkHard}</Check>
                  <Check ok={checks.normal}>{t.chkNormal}</Check>
                  <Check ok={checks.fit}>{t.chkFit}</Check>
                </div>
              </div>
            </div>
          </Panel>
        </div>
      </main>
    </>
  );
}
