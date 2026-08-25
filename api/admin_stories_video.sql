-- Video stories. Run once on existing databases, then deploy
-- admin_stories.php and admin_story_upload.php.
--
-- PHP also needs enough upload headroom for compressed clips
-- (about 40 MB): upload_max_filesize and post_max_size.

ALTER TABLE `admin_stories`
  MODIFY COLUMN `content_type` ENUM('image', 'text', 'video') NOT NULL;
