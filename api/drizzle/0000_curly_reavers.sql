CREATE TABLE `doctor_notes` (
	`id` text PRIMARY KEY NOT NULL,
	`patient_id` text NOT NULL,
	`author_id` text NOT NULL,
	`text` text NOT NULL,
	`created_at` text NOT NULL,
	FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`author_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `doctor_notes_patient_created_idx` ON `doctor_notes` (`patient_id`,`created_at`);--> statement-breakpoint
CREATE TABLE `invite_codes` (
	`code` text PRIMARY KEY NOT NULL,
	`patient_id` text NOT NULL,
	`relation` text NOT NULL,
	`expires_at` text NOT NULL,
	`used_at` text,
	`created_at` text NOT NULL,
	FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `invite_codes_patient_idx` ON `invite_codes` (`patient_id`);--> statement-breakpoint
CREATE TABLE `patient_links` (
	`id` text PRIMARY KEY NOT NULL,
	`patient_id` text NOT NULL,
	`user_id` text NOT NULL,
	`relation` text NOT NULL,
	`status` text DEFAULT 'pending' NOT NULL,
	`initiated_by_patient` integer DEFAULT false NOT NULL,
	`created_at` text NOT NULL,
	FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `patient_links_patient_user_uidx` ON `patient_links` (`patient_id`,`user_id`);--> statement-breakpoint
CREATE INDEX `patient_links_user_status_idx` ON `patient_links` (`user_id`,`status`);--> statement-breakpoint
CREATE TABLE `users` (
	`id` text PRIMARY KEY NOT NULL,
	`role` text NOT NULL,
	`name_en` text NOT NULL,
	`name_km` text NOT NULL,
	`phone` text,
	`email` text,
	`password_hash` text NOT NULL,
	`age` integer,
	`conditions_en` text,
	`conditions_km` text,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_phone_unique` ON `users` (`phone`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);--> statement-breakpoint
CREATE INDEX `users_role_idx` ON `users` (`role`);--> statement-breakpoint
CREATE TABLE `custom_fields` (
	`id` text PRIMARY KEY NOT NULL,
	`name_en` text NOT NULL,
	`name_km` text NOT NULL,
	`unit` text NOT NULL,
	`decimals` integer DEFAULT 0 NOT NULL,
	`min_value` real NOT NULL,
	`max_value` real NOT NULL,
	`normal_min` real,
	`normal_max` real,
	`built_in` integer DEFAULT false NOT NULL,
	`active` integer DEFAULT true NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `reading_values` (
	`reading_id` text NOT NULL,
	`field_key` text NOT NULL,
	`value` real NOT NULL,
	PRIMARY KEY(`reading_id`, `field_key`),
	FOREIGN KEY (`reading_id`) REFERENCES `readings`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`field_key`) REFERENCES `custom_fields`(`id`) ON UPDATE no action ON DELETE restrict
);
--> statement-breakpoint
CREATE INDEX `reading_values_field_key_idx` ON `reading_values` (`field_key`);--> statement-breakpoint
CREATE TABLE `readings` (
	`id` text PRIMARY KEY NOT NULL,
	`patient_id` text NOT NULL,
	`entered_by` text NOT NULL,
	`measured_at` text NOT NULL,
	`method` text DEFAULT 'manual' NOT NULL,
	`note` text,
	`photo_uri` text,
	`created_at` text NOT NULL,
	`updated_at` text,
	FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`entered_by`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE restrict
);
--> statement-breakpoint
CREATE INDEX `readings_patient_measured_idx` ON `readings` (`patient_id`,`measured_at`);--> statement-breakpoint
CREATE TABLE `reminders` (
	`patient_id` text PRIMARY KEY NOT NULL,
	`enabled` integer DEFAULT true NOT NULL,
	`minutes_after_midnight` integer DEFAULT 390 NOT NULL,
	`updated_at` text NOT NULL,
	FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
