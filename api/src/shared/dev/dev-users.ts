import type { AuthUser, Role } from '@ehealth/types';

// Fixed test users for dev login. A future accounts seed may create them with the same ids.
export const devUsers = {
  patient: { id: '00000000-0000-4000-8000-000000000001', role: 'patient', name: 'Sok Dara' },
  caretaker: { id: '00000000-0000-4000-8000-000000000002', role: 'caretaker', name: 'Chan Sophea' },
  family: { id: '00000000-0000-4000-8000-000000000003', role: 'family', name: 'Sok Vanna' },
  doctor: { id: '00000000-0000-4000-8000-000000000004', role: 'doctor', name: 'Dr. Keo Rathana' },
  admin: { id: '00000000-0000-4000-8000-000000000005', role: 'admin', name: 'Admin' },
} as const satisfies Record<Role, AuthUser>;
