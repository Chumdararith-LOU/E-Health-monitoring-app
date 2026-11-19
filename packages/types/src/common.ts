// Owner: Rith. Draft from the skeleton – owner reviews it by Dec 9.

export type Language = 'km' | 'en';

export type ISODateTime = string;

export type ApiError = {
  error: {
    code: string;
    messageKey: string; // i18n key
  };
};
