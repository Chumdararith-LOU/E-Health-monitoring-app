import { useEffect } from 'react';
import { useApp } from './state/AppState';
import { navigate, useRoute } from './lib/router';
import { Login } from './pages/Login';
import { DoctorDashboard } from './pages/DoctorDashboard';
import { PatientReport } from './pages/PatientReport';
import { AdminUsers } from './pages/AdminUsers';
import { AdminFields } from './pages/AdminFields';

/** Routes + role guard: doctors see /doctor/*, admins see /admin/*. */
export function App() {
  const { session } = useApp();
  const parts = useRoute();
  const [area, sub, id] = parts;

  const home = session ? (session.role === 'admin' ? '/admin/users' : '/doctor') : '/login';
  const allowed =
    !session ? area === 'login' : (session.role === 'doctor' && area === 'doctor') || (session.role === 'admin' && area === 'admin');

  useEffect(() => {
    if (!allowed) navigate(home);
  }, [allowed, home]);

  if (!allowed) return null;
  if (!session) return <Login />;
  if (area === 'doctor' && sub === 'patient' && id) return <PatientReport key={id} patientId={id} />;
  if (area === 'doctor') return <DoctorDashboard />;
  if (area === 'admin' && sub === 'fields') return <AdminFields />;
  return <AdminUsers />;
}
