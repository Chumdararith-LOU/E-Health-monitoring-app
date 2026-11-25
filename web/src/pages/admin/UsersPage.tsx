import { useState } from 'react';
import { Role } from '../../data/types';
import { fromKhmerDigits } from '../../i18n';
import { useApp } from '../../store/AppStore';
import { useFeedback } from '../../ui/Feedback';
import { Icon } from '../../ui/Icon';
import { Avatar, Card, Chip, Empty, PageHeader } from '../../ui/Kit';

const ROLES: Role[] = ['patient', 'caretaker', 'family', 'doctor', 'admin'];

/** FR-02 / US-02: each user has exactly one role; the admin changes it here. */
export function UsersPage() {
  const { i18n, state, user, dispatch } = useApp();
  const { confirm, toast } = useFeedback();
  const { t } = i18n;
  const [q, setQ] = useState('');
  const [role, setRole] = useState<Role | 'all'>('all');
  const users = state.data.users;
  const query = fromKhmerDigits(q).trim().toLowerCase();
  const list = users
    .filter((u) => role === 'all' || u.role === role)
    .filter((u) => !query || [u.nameEn, u.nameKm, u.phone].some((s) => s.toLowerCase().replace(/\s/g, '').includes(query.replace(/\s/g, ''))))
    .sort((a, b) => ROLES.indexOf(a.role) - ROLES.indexOf(b.role) || i18n.name(a).localeCompare(i18n.name(b)));

  const linkCount = (id: string) => state.data.links.filter((l) => l.patientId === id || l.userId === id).length;

  const change = async (id: string, next: Role) => {
    const u = users.find((x) => x.id === id)!;
    if (u.role === next) return;
    const ok = await confirm({
      title: t('changeRoleTitle', { name: i18n.name(u) }),
      body: t('changeRoleBody', { from: i18n.role(u.role), to: i18n.role(next) }),
      confirmLabel: t('changeRole'),
      icon: 'users',
    });
    if (!ok) return;
    const prev = u.role;
    dispatch({ type: 'setRole', userId: id, role: next });
    toast({ message: t('roleChanged', { name: i18n.name(u), role: i18n.role(next) }), undo: () => dispatch({ type: 'setRole', userId: id, role: prev }) });
  };

  return (
    <>
      <PageHeader title={t('nav_users')} subtitle={t('usersSubtitle')} />
      <Card className="card-tight">
        <div className="toolbar" style={{ padding: 'var(--s4)' }}>
          <div className="search">
            <Icon name="search" />
            <input className="input" type="search" placeholder={t('search')} aria-label={t('search')} value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          <div className="row-wrap" role="group" aria-label={t('colRole')}>
            <Chip pressed={role === 'all'} onClick={() => setRole('all')} count={i18n.num(users.length)}>
              {t('all')}
            </Chip>
            {ROLES.map((r) => (
              <Chip key={r} pressed={role === r} onClick={() => setRole(r)} count={i18n.num(users.filter((u) => u.role === r).length)}>
                {i18n.role(r)}
              </Chip>
            ))}
          </div>
        </div>
        {!list.length ? (
          <Empty icon="search" title={t('noMatch')} />
        ) : (
          <div className="table-wrap">
            <table className="table responsive">
              <caption className="sr-only">{t('nav_users')}</caption>
              <thead>
                <tr>
                  <th scope="col">{t('colName')}</th>
                  <th scope="col">{t('colPhone')}</th>
                  <th scope="col">{t('colRole')}</th>
                  <th scope="col" className="num">{t('colLinks')}</th>
                </tr>
              </thead>
              <tbody>
                {list.map((u) => {
                  const self = u.id === user?.id;
                  return (
                    <tr key={u.id}>
                      <td data-label={t('colName')}>
                        <div className="row">
                          <Avatar name={i18n.name(u)} />
                          <div>
                            <div className="strong">{i18n.name(u)}</div>
                            <div className="cell-sub">{i18n.lang === 'km' ? u.nameEn : u.nameKm}</div>
                          </div>
                        </div>
                      </td>
                      <td data-label={t('colPhone')} style={{ fontVariantNumeric: 'tabular-nums' }}>{u.phone}</td>
                      <td data-label={t('colRole')}>
                        <select
                          className="select"
                          style={{ maxWidth: '14rem' }}
                          value={u.role}
                          disabled={self}
                          aria-label={`${t('colRole')}: ${i18n.name(u)}`}
                          title={self ? t('cannotChangeOwn') : undefined}
                          onChange={(e) => change(u.id, e.target.value as Role)}
                        >
                          {ROLES.map((r) => (
                            <option key={r} value={r}>
                              {i18n.role(r)}
                            </option>
                          ))}
                        </select>
                        {self ? <div className="cell-sub">{t('cannotChangeOwn')}</div> : null}
                      </td>
                      <td data-label={t('colLinks')} className="num">{i18n.num(linkCount(u.id))}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
        <div className="pager">
          <span className="small muted">{t('usersCount', { n: list.length })}</span>
        </div>
      </Card>
    </>
  );
}
