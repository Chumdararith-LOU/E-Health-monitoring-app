// Admin: users & roles (FR-02, US-02). Inline role dropdown + Save per row;
// unsaved changes are amber; saving shows the "applies on next request" banner.

import { useMemo, useState } from 'react';
import { useApp } from '../state/AppState';
import { Crumbs, Header } from '../components/Header';
import { Icon } from '../components/Icon';
import { Alert, Badge, Empty, ErrorState, Loading, Pager } from '../components/ui';
import type { Role } from '../data/types';

const PAGE = 10;
const ROLES: Role[] = ['patient', 'caretaker', 'family', 'doctor', 'admin'];

export function AdminUsers() {
  const { t, f, lang, data, setUserRole, setUserActive, simulate, setSimulate } = useApp();
  const [q, setQ] = useState('');
  const [roleFilter, setRoleFilter] = useState<Role | 'all'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'disabled'>('all');
  const [page, setPage] = useState(0);
  const [pending, setPending] = useState<Record<string, Role>>({});
  const [savedId, setSavedId] = useState<string | null>(null);
  const [banner, setBanner] = useState<{ sev: 'ok' | 'err'; text: string } | null>(null);

  const roleName = (r: Role) => ({ patient: t.rolePatient, caretaker: t.roleCaretaker, family: t.roleFamily, doctor: t.roleDoctor, admin: t.roleAdmin })[r];
  const offline = simulate === 'offline';

  const rows = useMemo(() => {
    const needle = q.trim().toLowerCase().replace(/\s+/g, '');
    return data.users.filter((u) => {
      if (needle && !`${u.name.km}${u.name.en}${u.contact}`.toLowerCase().replace(/\s+/g, '').includes(needle)) return false;
      if (roleFilter !== 'all' && u.role !== roleFilter) return false;
      if (statusFilter === 'active' && !u.active) return false;
      if (statusFilter === 'disabled' && u.active) return false;
      return true;
    });
  }, [data.users, q, roleFilter, statusFilter]);

  const pages = Math.max(1, Math.ceil(rows.length / PAGE));
  const cur = Math.min(page, pages - 1);
  const shown = rows.slice(cur * PAGE, cur * PAGE + PAGE);

  function save(userId: string) {
    const role = pending[userId];
    const user = data.users.find((u) => u.id === userId);
    if (!role || !user) return;
    if (!setUserRole(userId, role)) {
      setBanner({ sev: 'err', text: t.lastAdmin });
      return;
    }
    setPending((p) => {
      const n = { ...p };
      delete n[userId];
      return n;
    });
    setSavedId(userId);
    setBanner({ sev: 'ok', text: t.roleSaved(user.name[lang], roleName(role)) });
  }

  let body;
  if (simulate === 'loading') body = <Loading />;
  else if (simulate === 'error') body = <ErrorState onRetry={() => setSimulate('none')} />;
  else if (rows.length === 0 || simulate === 'empty')
    body = (
      <Empty
        icon="search"
        title={t.noUsers}
        action={
          <button
            type="button"
            className="btn btn-gray"
            onClick={() => {
              setQ('');
              setRoleFilter('all');
              setStatusFilter('all');
              setSimulate('none');
            }}
          >
            <Icon name="reset" />
            {t.resetFilters}
          </button>
        }
      />
    );
  else
    body = (
      <section className="panel">
        <div className="tbl-scroll">
          <table className="dt num" style={{ minWidth: 900 }}>
            <caption className="sr-only">{t.usersTitle}</caption>
            <thead>
              <tr>
                <th>{t.colName}</th>
                <th>{t.colContact}</th>
                <th>{t.role}</th>
                <th>{t.status}</th>
                <th>{t.colCreated}</th>
                <th style={{ width: 220 }}>{t.colAction}</th>
              </tr>
            </thead>
            <tbody>
              {shown.map((u) => {
                const p = pending[u.id];
                const isPending = p !== undefined && p !== u.role;
                return (
                  <tr key={u.id} className={isPending ? 'r-warn' : !u.active ? 'r-off' : undefined}>
                    <td>
                      <b>{u.name[lang]}</b>
                    </td>
                    <td>{f.n(u.contact)}</td>
                    <td>
                      <select
                        className="input"
                        aria-label={t.roleOf(u.name[lang])}
                        value={p ?? u.role}
                        style={isPending ? { border: '2px solid var(--focus)', boxShadow: '0 0 0 3px rgba(25,118,210,0.22)' } : undefined}
                        onChange={(e) => {
                          const v = e.target.value as Role;
                          setSavedId(null);
                          setPending((prev) => {
                            const n = { ...prev };
                            if (v === u.role) delete n[u.id];
                            else n[u.id] = v;
                            return n;
                          });
                        }}
                      >
                        {ROLES.map((r) => (
                          <option key={r} value={r}>
                            {roleName(r)}
                          </option>
                        ))}
                      </select>
                      {isPending && (
                        <div className="cap" style={{ color: 'var(--warn-text)' }}>
                          {t.wasRole(roleName(u.role))}
                        </div>
                      )}
                    </td>
                    <td>{u.active ? <Badge tone="ok">{t.active}</Badge> : <Badge tone="gray" icon={null}>{t.disabled}</Badge>}</td>
                    <td className="cap">{f.dayY(u.created)}</td>
                    <td>
                      <div className="row" style={{ gap: 6, flexWrap: 'nowrap' }}>
                        {isPending ? (
                          <>
                            <button type="button" className="btn btn-navy btn-sm" disabled={offline} onClick={() => save(u.id)}>
                              {t.save}
                            </button>
                            <button
                              type="button"
                              className="btn btn-gray btn-sm"
                              onClick={() =>
                                setPending((prev) => {
                                  const n = { ...prev };
                                  delete n[u.id];
                                  return n;
                                })
                              }
                            >
                              {t.cancel}
                            </button>
                          </>
                        ) : savedId === u.id ? (
                          <Badge tone="ok">{t.saved}</Badge>
                        ) : (
                          <button type="button" className="btn btn-gray btn-sm" disabled>
                            {t.save}
                          </button>
                        )}
                        {!isPending && (
                          <button type="button" className={`btn btn-sm ${u.active ? 'btn-danger' : 'btn-gray'}`} disabled={offline || u.role === 'admin'} onClick={() => setUserActive(u.id, !u.active)}>
                            {u.active ? t.disable : t.enable}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        <div className="panel-foot">
          <span className="cap">{t.showingUsers(f.n(cur * PAGE + 1), f.n(cur * PAGE + shown.length), f.n(rows.length))}</span>
          <Pager page={cur} pages={pages} onPage={setPage} />
        </div>
      </section>
    );

  return (
    <>
      <Header active="users" />
      <Crumbs items={[{ label: t.adminPortal, href: '#/admin/users' }, { label: t.tabUsers }]} />
      <main className="wrap page">
        <div>
          <h1 className="page-title">{t.usersTitle}</h1>
          <p className="cap">{f.n(t.usersSub)}</p>
        </div>
        {banner && <Alert sev={banner.sev}>{banner.text}</Alert>}
        {offline && (
          <Alert sev="warn" icon="wifiOff">
            {t.offlineAction}
          </Alert>
        )}
        <section className="panel toolbar" aria-label={t.search}>
          <div className="row" style={{ flex: '1 1 320px', minWidth: 0, flexWrap: 'nowrap' }}>
            <label className="sr-only" htmlFor="uq">
              {t.search}
            </label>
            <input
              id="uq"
              className="input"
              style={{ flex: 1 }}
              placeholder={t.searchUsers}
              value={q}
              onChange={(e) => {
                setQ(e.target.value);
                setPage(0);
              }}
            />
          </div>
          <div className="row" style={{ gap: 6 }}>
            <label className="cap" htmlFor="rf" style={{ fontWeight: 600, color: 'var(--text)' }}>
              {t.role}
            </label>
            <select
              id="rf"
              className="input"
              value={roleFilter}
              onChange={(e) => {
                setRoleFilter(e.target.value as Role | 'all');
                setPage(0);
              }}
            >
              <option value="all">{t.all}</option>
              {ROLES.map((r) => (
                <option key={r} value={r}>
                  {roleName(r)}
                </option>
              ))}
            </select>
          </div>
          <div className="row" style={{ gap: 6 }}>
            <label className="cap" htmlFor="sf" style={{ fontWeight: 600, color: 'var(--text)' }}>
              {t.status}
            </label>
            <select
              id="sf"
              className="input"
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value as 'all' | 'active' | 'disabled');
                setPage(0);
              }}
            >
              <option value="all">{t.all}</option>
              <option value="active">{t.active}</option>
              <option value="disabled">{t.disabled}</option>
            </select>
          </div>
        </section>
        {body}
        <p className="cap">{t.usersGuard}</p>
      </main>
    </>
  );
}
