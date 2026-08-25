<?php
/**
 * POST /admin_story_upload.php
 * Admin only. multipart/form-data:
 *   photo — jpg/png/webp image (max 12 MB)
 *   video — mp4/mov/webm/3gp clip (max 40 MB)
 * Response: { ok: true, image_path: "uploads/stories/..." }
 */

require_once __DIR__ . '/admin_story_helpers.php';

auth_options_exit();
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    auth_send_json(['error' => 'Only POST is allowed'], 405);
}

@ini_set('max_execution_time', '120');

const ADMIN_STORY_IMAGE_MAX_BYTES = 12 * 1024 * 1024;
const ADMIN_STORY_VIDEO_MAX_BYTES = 40 * 1024 * 1024;

try {
    $db = getDb();
    $user = admin_story_current_user($db);
    admin_story_require_admin($user);

    $isVideo = isset($_FILES['video']) && is_array($_FILES['video']);
    $field = $isVideo ? 'video' : 'photo';
    if (!isset($_FILES[$field]) || !is_array($_FILES[$field])) {
        auth_send_json(['error' => 'Missing file field "photo" or "video"'], 400);
    }

    $err = (int) ($_FILES[$field]['error'] ?? UPLOAD_ERR_NO_FILE);
    if ($err !== UPLOAD_ERR_OK) {
        auth_send_json(['error' => admin_story_upload_error_message($err)], 400);
    }
    $tmp = (string) ($_FILES[$field]['tmp_name'] ?? '');
    if ($tmp === '' || !is_uploaded_file($tmp)) {
        auth_send_json(['error' => 'Invalid upload'], 400);
    }
    $size = filesize($tmp);
    $maxBytes = $isVideo ? ADMIN_STORY_VIDEO_MAX_BYTES : ADMIN_STORY_IMAGE_MAX_BYTES;
    if ($size === false || $size < 32 || $size > $maxBytes) {
        auth_send_json([
            'error' => $isVideo
                ? 'Video is too large (max 40 MB). Please pick a shorter clip.'
                : 'File too large (max 12 MB)',
        ], 400);
    }

    $ext = null;
    if ($isVideo) {
        $ext = admin_story_detect_video_extension(
            $tmp,
            (string) ($_FILES[$field]['name'] ?? '')
        );
        if ($ext === null) {
            $finfoMime = '';
            if (function_exists('finfo_open')) {
                $finfo = finfo_open(FILEINFO_MIME_TYPE);
                if ($finfo) {
                    $finfoMime = (string) finfo_file($finfo, $tmp);
                    finfo_close($finfo);
                }
            }
            $videoMimes = [
                'video/mp4' => 'mp4',
                'video/quicktime' => 'mov',
                'video/webm' => 'webm',
                'video/3gpp' => '3gp',
                'video/3gp' => '3gp',
                'video/x-m4v' => 'm4v',
            ];
            if (isset($videoMimes[$finfoMime])) {
                $ext = $videoMimes[$finfoMime];
            }
        }
        if ($ext === null) {
            auth_send_json(['error' => 'Only MP4, MOV, WEBM, or 3GP videos are allowed'], 400);
        }
    } else {
        $info = @getimagesize($tmp);
        if ($info === false || !isset($info['mime'])) {
            auth_send_json(['error' => 'Unsupported image'], 400);
        }
        $mime = (string) $info['mime'];
        $extMap = [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
        ];
        if (!isset($extMap[$mime])) {
            auth_send_json(['error' => 'Only JPG, PNG, or WEBP images are allowed'], 400);
        }
        $ext = $extMap[$mime];
    }

    $dir = __DIR__ . '/uploads/stories';
    if (!is_dir($dir)) {
        if (!mkdir($dir, 0755, true) && !is_dir($dir)) {
            auth_send_json(['error' => 'Could not create upload directory'], 500);
        }
    }
    $name = 'story_' . (int) $user['id'] . '_' . date('YmdHis') . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
    $path = $dir . '/' . $name;
    if (!move_uploaded_file($tmp, $path)) {
        auth_send_json(['error' => $isVideo ? 'Could not save video' : 'Could not save image'], 500);
    }
    @chmod($path, 0644);
    auth_send_json(['ok' => true, 'image_path' => 'uploads/stories/' . $name], 201);
} catch (PDOException $e) {
    auth_send_json(['error' => 'Upload failed'], 500);
}
