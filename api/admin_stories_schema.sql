-- Admin Instagram-style stories.
-- Run once on MySQL 8+ before deploying admin story PHP endpoints.

CREATE TABLE IF NOT EXISTS `admin_stories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_user_id` INT UNSIGNED NOT NULL,
  `content_type` ENUM('image', 'text', 'video') NOT NULL,
  `image_path` VARCHAR(255) NULL DEFAULT NULL,
  `client_request_id` VARCHAR(80) NULL DEFAULT NULL,
  `text_content` MEDIUMTEXT NULL,
  `text_style_json` MEDIUMTEXT NULL,
  `target_mode` ENUM('all', 'specific') NOT NULL DEFAULT 'all',
  `visibility_hours` INT UNSIGNED NOT NULL DEFAULT 24,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_admin_stories_admin_created` (`admin_user_id`, `created_at`),
  KEY `idx_admin_stories_visible` (`deleted_at`, `created_at`),
  UNIQUE KEY `uniq_admin_stories_client_request` (`admin_user_id`, `client_request_id`),
  CONSTRAINT `fk_admin_stories_admin`
    FOREIGN KEY (`admin_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admin_story_targets` (
  `story_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`story_id`, `user_id`),
  KEY `idx_admin_story_targets_user` (`user_id`),
  CONSTRAINT `fk_admin_story_targets_story`
    FOREIGN KEY (`story_id`) REFERENCES `admin_stories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_admin_story_targets_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admin_story_views` (
  `story_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `viewed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`story_id`, `user_id`),
  KEY `idx_admin_story_views_user` (`user_id`, `viewed_at`),
  CONSTRAINT `fk_admin_story_views_story`
    FOREIGN KEY (`story_id`) REFERENCES `admin_stories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_admin_story_views_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admin_story_likes` (
  `story_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `liked_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`story_id`, `user_id`),
  KEY `idx_admin_story_likes_user` (`user_id`, `liked_at`),
  CONSTRAINT `fk_admin_story_likes_story`
    FOREIGN KEY (`story_id`) REFERENCES `admin_stories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_admin_story_likes_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
