import { createApp } from './app';
import { config } from './config';

createApp().listen(config.PORT, () => {
  console.log(`ehealth-api listening on http://localhost:${config.PORT} (${config.NODE_ENV})`);
});
