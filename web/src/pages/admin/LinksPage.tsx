import { useState } from 'react';
import { Link as RLink } from 'react-router-dom';
import { LinkStatus } from '../../data/types';
import { useApp } from '../../store/AppStore';
import { useFeedback } from '../../ui/Feedback';
import { Icon, IconName } from '../../ui/Icon';
import { Badge, Button, Card, Chip, Empty, PageHeader } from '../../ui/Kit';

const REL_ICON: Record<string, IconName> = { doctor: 'doctor', caretaker: 'caretaker', family: 'family' };

/** Admin view of every patient link (US-03 support). Patients approve links in the mobile app. */
export function LinksPage() {
  const { i18n, state, userById, dispatch } = useApp();
  const { confirm, toast } = useFeedback();
  const { t } = i18n;
  const [status, setStatus] = useState<LinkStatus | 'all'>('all');
  const links = state.data.links
    .filter((l) => status === 'all' || l.status === status)
    .sort((a, b) => i18n.name(userById(a.patientId)).localeCompare(i18n.name(userById(b.patientId))) || a.relation.localeCompare(b.relation));

  const remove = async (id: string) => {
    const l = state.data.links.find((x) => x.id === id)!;
    const ok = await confirm({
      title: t('removeLinkTitle'),
      body: t('removeLinkBody', { user: i18n.name(userById(l.userId)), patient: i18n.name(userById(l.patientId)) }),
      confirmLabel: t('remove'),
      danger: true,
      icon: 'link',
    });
    if (!ok) return;
    dispatch({ type: 'removeLink', id });
    toast({ message: t('linkRemoved'), undo: () => dispatch({ type: 'restoreLink', link: l }) });
  };

  const count = (s: LinkStatus) => state.data.links.filter((l) => l.status === s).length;

  return (
    <>
      <PageHeader title={t('nav_links')} subtitle={t('linksSubtitle')} />
      <Card className="card-tight">
        <div className="toolbar" style={{ padding: 'var(--s4)' }} role="group" aria-label={t('status')}>
          <Chip pressed={status === 'all'} onClick={() => setStatus('all')} count={i18n.num(state.data.links.length)}>{t('all')}</Chip>
          <Chip pressed={status === 'active'} onClick={() => setStatus('active')} count={i18n.num(count('active'))}>{t('status_active')}</Chip>
          <Chip pressed={status === 'pending'} onClick={() => setStatus('pending')} count={i18n.num(count('pending'))} icon="waiting">{t('status_pending')}</Chip>
        </div>
        {!links.length ? (
          <Empty icon="link" title={t('noMatch')} />
        ) : (
          <div className="table-wrap">
            <table className="table responsive">
              <caption className="sr-only">{t('nav_links')}</caption>
              <thead>
                <tr>
                  <th scope="col">{t('colPatient')}</th>
                  <th scope="col">{t('colLinkedUser')}</th>
                  <th scope="col">{t('colRelation')}</th>
                  <th scope="col">{t('status')}</th>
                  <th scope="col">{t('colSince')}</th>
                  <th scope="col"><span className="sr-only">{t('actions')}</span></th>
                </tr>
              </thead>
              <tbody>
                {links.map((l) => (
                  <tr key={l.id}>
                    <td data-label={t('colPatient')}>
                      <RLink className="row-link" to={`/patients/${l.patientId}`}>{i18n.name(userById(l.patientId))}</RLink>
                    </td>
                    <td data-label={t('colLinkedUser')}>{i18n.name(userById(l.userId))}</td>
                    <td data-label={t('colRelation')}>
                      <span className="row" style={{ gap: 4 }}>
                        <Icon name={REL_ICON[l.relation]} size={18} />
                        {i18n.role(l.relation)}
                      </span>
                    </td>
                    <td data-label={t('status')}>
                      {l.status === 'active' ? <Badge kind="normal" icon="check">{t('status_active')}</Badge> : <Badge kind="low" icon="waiting">{t('status_pending')}</Badge>}
                    </td>
                    <td data-label={t('colSince')}>{i18n.date(l.createdAt)}</td>
                    <td style={{ textAlign: 'right' }}>
                      <Button small variant="ghost-danger" icon="delete" onClick={() => remove(l.id)} aria-label={`${t('remove')}: ${i18n.name(userById(l.userId))} – ${i18n.name(userById(l.patientId))}`}>
                        {t('remove')}
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </>
  );
}
