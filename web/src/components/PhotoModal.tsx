// OCR photo lightbox (US-11 / doctor verification): drawn device screen next
// to the recorded numbers, with previous/next across photos.
// Phak: replace <DevicePhoto> with the stored photo (<img src=…>).

import { useEffect } from 'react';
import type { Patient, Reading } from '../data/types';
import { useApp } from '../state/AppState';
import { byField, readingFlags } from '../lib/stats';
import { Badge } from './ui';
import { Icon } from './Icon';

function DevicePhoto({ r }: { r: Reading }) {
  return (
    <div className="row" style={{ gap: 16, justifyContent: 'center' }}>
      <div className="device" style={{ width: 210 }}>
        <div className="screen lcd">
          {[
            ['SYS', r.systolic, 54],
            ['DIA', r.diastolic, 54],
            ['PUL', r.pulse, 38],
          ].map(([k, v, size]) => (
            <div key={k as string} style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 13 }}>{k}</span>
              <span style={{ fontSize: size as number, lineHeight: 1.05 }}>{v}</span>
            </div>
          ))}
        </div>
      </div>
      <div className="device glu" style={{ width: 150, borderRadius: 20 }}>
        <div className="screen lcd">
          <div style={{ fontSize: 46, lineHeight: 1 }}>{Math.round(r.glucose)}</div>
          <div style={{ fontSize: 13, marginTop: 4 }}>mg/dL</div>
        </div>
      </div>
    </div>
  );
}

export function PhotoModal({ patient, photos, index, onIndex, onClose }: { patient: Patient; photos: Reading[]; index: number; onIndex: (i: number) => void; onClose: () => void }) {
  const { t, f, lang, fields } = useApp();
  const r = photos[index];

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  if (!r) return null;
  const fl = readingFlags(fields, r);
  const by = r.author === 'caretaker' && patient.caretaker ? `${patient.caretaker.name[lang]} (${t.roleCaretaker})` : `${patient.name[lang]}`;
  const method = r.method === 'ocrEdited' ? t.ocrEdited : r.method === 'manual' ? t.manual : `OCR · ${t.notEdited}`;
  const rows: [string, number, string, boolean][] = [
    [byField(fields, 'sys').name[lang], r.systolic, 'mmHg', fl.sys !== 'normal'],
    [byField(fields, 'dia').name[lang], r.diastolic, 'mmHg', fl.dia !== 'normal'],
    [byField(fields, 'pul').name[lang], r.pulse, 'bpm', fl.pul !== 'normal'],
    [byField(fields, 'glu').name[lang], r.glucose, 'mg/dL', fl.glu !== 'normal'],
  ];

  return (
    <div className="scrim" onClick={onClose}>
      <div className="modal" role="dialog" aria-modal="true" aria-labelledby="photo-title" onClick={(e) => e.stopPropagation()}>
        <div className="modal-h">
          <h2 id="photo-title" className="num">
            {t.photoTitle} · {patient.name[lang]} · {f.dayY(r.time)} · {f.time(r.time)}
          </h2>
          <button type="button" className="btn btn-gray btn-sm" onClick={onClose} autoFocus>
            <Icon name="x" />
            {t.close}
          </button>
        </div>
        <div className="row" style={{ alignItems: 'stretch', gap: 0 }}>
          <div style={{ flex: '1 1 380px', background: '#2F343A', padding: 20, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
            <DevicePhoto r={r} />
            <p className="cap" style={{ color: '#D5DCE3' }}>
              {t.photoCrop}
            </p>
          </div>
          <div style={{ flex: '1 1 300px', padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <h3 style={{ fontSize: 15 }}>{t.recordedValues}</h3>
            <table className="dt num" style={{ border: '1px solid var(--border)' }}>
              <tbody>
                {rows.map(([name, v, unit, hi]) => (
                  <tr key={name}>
                    <td style={{ height: 40 }}>{name}</td>
                    <td className={`r ${hi ? 'hi' : ''}`} style={{ height: 40 }}>
                      {f.n(Math.round(v))}
                      {hi ? ' ▲' : ''} {unit}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="row">
              <Badge tone="gray" icon="camera">
                {method}
              </Badge>
              <span className="cap">{t.recordedBy(by)}</span>
            </div>
            <div className="alert a-info">
              <Icon name="info" size={18} />
              <span>{t.photoCompare}</span>
            </div>
            {r.note && <p className="cap">{t.patientNote(r.note[lang])}</p>}
          </div>
        </div>
        <div className="modal-f">
          <div className="row">
            <button type="button" className="btn btn-gray" disabled={index >= photos.length - 1} onClick={() => onIndex(index + 1)}>
              <Icon name="chevLeft" />
              {t.prevPhoto}
            </button>
            <button type="button" className="btn btn-gray" disabled={index <= 0} onClick={() => onIndex(index - 1)}>
              {t.nextPhoto}
              <Icon name="chevRight" />
            </button>
          </div>
          <button type="button" className="btn btn-navy" onClick={onClose}>
            {t.close}
          </button>
        </div>
      </div>
    </div>
  );
}
