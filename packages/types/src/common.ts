// Owner: Rith. Draft from the skeleton – owner reviews it by Dec 9.

export type Language = 'km' | 'en';

export type ISODateTime = string;

// Roles agreed in the requirements doc; shared by all modules.
export const ROLES = ['patient', 'caretaker', 'family', 'doctor', 'admin'] as const;
export type Role = (typeof ROLES)[number];

export type AuthUser = { id: string; role: Role; name: string };

export type ApiError = {
  error: {
    code: string;
    messageKey: string; // i18n key
  };
};
