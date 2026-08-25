<?php
/**
 * GET /admin_stories.php
 *   Returns visible stories. Bearer auth is optional; guests see target_mode=all stories.
 *
 * POST /admin_stories.php
 *   Admin only. JSON:
 *   {
 *     "content_type": "text"|"image"|"video",
 *     "image_path"?: string,
 *     "text_content"?: string,
 *     "text_style"?: object,
 *     "target_mode": "all"|"specific",
 *     "target_user_ids"?: int[]
 *   }
 *
 * DELETE /admin_stories.php?id=
 *   Admin only. Soft-deletes a story.
 */

require_once __DIR__ . '/admin_story_helpers.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

try {
    $db = getDb();
    $user = $method === 'GET'
        ? admin_story_optional_user($db)
        : admin_story_current_user($db);
    $uid = $user === null ? 0 : (int) $user['id'];

    if ($method === 'GET') {
        $isAdmin = $user !== null && admin_story_is_admin($user);
        $mode = isset($_GET['mode']) ? trim((string) $_GET['mode']) : 'visible';
        $hasGrammarGames = admin_story_grammar_tables_exist($db);

        if ($mode === 'admin' && $isAdmin) {
            $stmt = $db->query(
                "SELECT s.*,
                        u.email AS admin_email,
                        u.display_name AS admin_name,
                        u.avatar AS admin_avatar,
                        NULL AS viewed_at,
                        0 AS liked,
                        (SELECT COUNT(*) FROM admin_story_views v WHERE v.story_id = s.id) AS view_count,
                        (SELECT COUNT(*) FROM admin_story_likes l WHERE l.story_id = s.id) AS like_count
                 FROM admin_stories s
                 INNER JOIN users u ON u.id = s.admin_user_id
                 WHERE s.deleted_at IS NULL
                 ORDER BY s.created_at DESC, s.id DESC
                 LIMIT 100"
            );
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        } else {
            $grammarVisibleClause = $hasGrammarGames
                ? "OR EXISTS (SELECT 1 FROM admin_story_grammar_games g WHERE g.story_id = s.id)"
                : "";
            $visibilitySql = $uid > 0
                ? admin_story_user_target_visibility_sql(':uid3')
                : "s.target_mode = 'all'";
            $stmt = $db->prepare(
                "SELECT s.*,
                        u.email AS admin_email,
                        u.display_name AS admin_name,
                        u.avatar AS admin_avatar,
                        v.viewed_at,
                        CASE WHEN l.user_id IS NULL THEN 0 ELSE 1 END AS liked,
                        (SELECT COUNT(*) FROM admin_story_views vx WHERE vx.story_id = s.id) AS view_count,
                        (SELECT COUNT(*) FROM admin_story_likes lx WHERE lx.story_id = s.id) AS like_count
                 FROM admin_stories s
                 INNER JOIN users u ON u.id = s.admin_user_id
                 LEFT JOIN admin_story_views v ON v.story_id = s.id AND v.user_id = :uid1
                 LEFT JOIN admin_story_likes l ON l.story_id = s.id AND l.user_id = :uid2
                 WHERE s.deleted_at IS NULL
                   AND $visibilitySql
                   AND (
                     " . admin_story_expiry_where_clause($db) . "
                     $grammarVisibleClause
                   )
                 ORDER BY s.created_at ASC, s.id ASC"
            );
            $params = [':uid1' => $uid, ':uid2' => $uid];
            if ($uid > 0) {
                $params[':uid3'] = $uid;
            }
            $stmt->execute($params);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }

        $stories = array_map('admin_story_row_to_json', $rows);
        $stories = admin_story_attach_polls($db, $stories, $uid, $isAdmin);
        $stories = admin_story_attach_grammar_games($db, $stories, $uid, $isAdmin);
        auth_send_json(['stories' => $stories], 200);
    }

    if ($method === 'POST') {
        $adminId = admin_story_require_admin($user);
        $data = auth_json_body();
        $type = isset($data['content_type']) ? trim((string) $data['content_type']) : '';
        $allowedTypes = admin_story_allowed_content_types($db);
        if (!in_array($type, $allowedTypes, true)) {
            if ($type === 'video') {
                auth_send_json(['error' => 'Video stories are not enabled on this server. Run admin_stories_video.sql.'], 500);
            }
            auth_send_json(['error' => 'Invalid content_type'], 400);
        }

        $imagePath = isset($data['image_path']) ? trim((string) $data['image_path']) : '';
        $text = isset($data['text_content']) ? trim((string) $data['text_content']) : '';
        $targetMode = isset($data['target_mode']) ? trim((string) $data['target_mode']) : 'all';
        $clientRequestId = admin_story_normalize_client_request_id($data['client_request_id'] ?? '');
        $hasClientRequestId = admin_story_has_client_request_id_column($db);
        if (!$hasClientRequestId) {
            $clientRequestId = null;
        }
        $existingStoryId = $hasClientRequestId
            ? admin_story_find_client_request($db, $adminId, $clientRequestId)
            : 0;
        if ($existingStoryId > 0) {
            auth_send_json(['ok' => true, 'id' => $existingStoryId, 'duplicate' => true], 200);
        }
        if ($targetMode !== 'all' && $targetMode !== 'specific') {
            auth_send_json(['error' => 'Invalid target_mode'], 400);
        }
        $targetIds = admin_story_normalize_target_ids($data['target_user_ids'] ?? []);
        if ($targetMode === 'specific' && count($targetIds) < 1) {
            auth_send_json(['error' => 'Select at least one user'], 400);
        }

        $styleArray = isset($data['text_style']) && is_array($data['text_style'])
            ? $data['text_style']
            : null;
        $poll = $styleArray !== null ? admin_story_poll_from_style($styleArray) : null;
        if ($poll !== null && !admin_story_poll_tables_exist($db)) {
            auth_send_json(['error' => 'Story poll tables are not installed. Run admin_story_polls_schema.sql.'], 500);
        }

        if ($type === 'text') {
            if ($text === '' && $poll === null) {
                auth_send_json(['error' => 'text_content is required'], 400);
            }
            if (function_exists('mb_strlen') ? mb_strlen($text, 'UTF-8') > 1000 : strlen($text) > 3000) {
                auth_send_json(['error' => 'Story text is too long'], 400);
            }
            $imagePath = null;
        } else {
            if ($imagePath === '' || strpos($imagePath, 'uploads/stories/') !== 0) {
                auth_send_json(['error' => $type === 'video' ? 'video path is required' : 'image_path is required'], 400);
            }
            if ($type === 'video') {
                $lowerPath = strtolower($imagePath);
                $videoOk = substr($lowerPath, -4) === '.mp4'
                    || substr($lowerPath, -4) === '.mov'
                    || substr($lowerPath, -4) === '.m4v'
                    || substr($lowerPath, -4) === '.3gp'
                    || substr($lowerPath, -5) === '.webm'
                    || substr($lowerPath, -5) === '.3gpp';
                if (!$videoOk) {
                    auth_send_json(['error' => 'video path is invalid'], 400);
                }
            }
            $text = $text === '' ? null : $text;
        }

        $style = $styleArray !== null
            ? admin_story_json_encode($styleArray)
            : null;
        $hasVisibilityHours = admin_story_has_visibility_hours_column($db);
        $visibilityHours = admin_story_normalize_visibility_hours(
            $data['visibility_hours'] ?? 24
        );

        $db->beginTransaction();
        if ($hasClientRequestId && $hasVisibilityHours) {
            $stmt = $db->prepare(
                'INSERT INTO admin_stories
                    (admin_user_id, client_request_id, content_type, image_path, text_content, text_style_json, target_mode, visibility_hours)
                 VALUES
                    (:admin, :request_id, :type, :image, :text, :style, :target, :visibility_hours)'
            );
        } elseif ($hasClientRequestId) {
            $stmt = $db->prepare(
                'INSERT INTO admin_stories
                    (admin_user_id, client_request_id, content_type, image_path, text_content, text_style_json, target_mode)
                 VALUES
                    (:admin, :request_id, :type, :image, :text, :style, :target)'
            );
        } elseif ($hasVisibilityHours) {
            $stmt = $db->prepare(
                'INSERT INTO admin_stories
                    (admin_user_id, content_type, image_path, text_content, text_style_json, target_mode, visibility_hours)
                 VALUES
                    (:admin, :type, :image, :text, :style, :target, :visibility_hours)'
            );
        } else {
            $stmt = $db->prepare(
                'INSERT INTO admin_stories
                    (admin_user_id, content_type, image_path, text_content, text_style_json, target_mode)
                 VALUES
                    (:admin, :type, :image, :text, :style, :target)'
            );
        }
        $params = [
            ':admin' => $adminId,
            ':type' => $type,
            ':image' => $imagePath,
            ':text' => $text,
            ':style' => $style,
            ':target' => $targetMode,
        ];
        if ($hasClientRequestId) {
            $params[':request_id'] = $clientRequestId;
        }
        if ($hasVisibilityHours) {
            $params[':visibility_hours'] = $visibilityHours;
        }
        try {
            $stmt->execute($params);
        } catch (PDOException $e) {
            if ($hasClientRequestId && $e->getCode() === '23000') {
                $db->rollBack();
                $existingStoryId = admin_story_find_client_request($db, $adminId, $clientRequestId);
                if ($existingStoryId > 0) {
                    auth_send_json(['ok' => true, 'id' => $existingStoryId, 'duplicate' => true], 200);
                }
            }
            throw $e;
        }
        $storyId = (int) $db->lastInsertId();

        if ($targetMode === 'specific') {
            $targetStmt = $db->prepare(
                'INSERT IGNORE INTO admin_story_targets (story_id, user_id)
                 SELECT :sid, id FROM users WHERE id = :uid'
            );
            foreach ($targetIds as $tid) {
                $targetStmt->execute([':sid' => $storyId, ':uid' => (int) $tid]);
            }
        }
        if ($poll !== null) {
            $pollStmt = $db->prepare(
                'INSERT INTO admin_story_polls
                    (story_id, question, options_json, position_x, position_y, scale)
                 VALUES
                    (:sid, :question, :options, :x, :y, :scale)'
            );
            $pollStmt->execute([
                ':sid' => $storyId,
                ':question' => $poll['question'],
                ':options' => admin_story_json_encode($poll['options']),
                ':x' => $poll['x'],
                ':y' => $poll['y'],
                ':scale' => $poll['scale'],
            ]);
        }
        $db->commit();
        auth_send_json(['ok' => true, 'id' => $storyId], 201);
    }

    if ($method === 'DELETE') {
        admin_story_require_admin($user);
        $storyId = isset($_GET['id']) ? (int) $_GET['id'] : 0;
        if ($storyId <= 0) {
            $data = auth_json_body();
            $storyId = isset($data['id']) ? (int) $data['id'] : 0;
        }
        if ($storyId <= 0) {
            auth_send_json(['error' => 'id is required'], 400);
        }
        $stmt = $db->prepare(
            'UPDATE admin_stories SET deleted_at = NOW() WHERE id = :id AND deleted_at IS NULL LIMIT 1'
        );
        $stmt->execute([':id' => $storyId]);
        if ($stmt->rowCount() < 1) {
            auth_send_json(['error' => 'Story not found or already deleted'], 404);
        }
        auth_send_json(['ok' => true, 'id' => $storyId], 200);
    }

    auth_send_json(['error' => 'Method not allowed'], 405);
} catch (PDOException $e) {
    if (isset($db) && $db instanceof PDO && $db->inTransaction()) {
        $db->rollBack();
    }
    auth_send_json(['error' => 'Story API failed'], 500);
}
