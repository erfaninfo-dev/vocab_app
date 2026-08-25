<?php

/**
 * Shared helpers for admin story endpoints.
 * Compatible with PHP 7.4+.
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';

function admin_story_current_user(PDO $db)
{
    $raw = auth_bearer_token();
    if ($raw === null || $raw === '') {
        auth_send_json(['error' => 'Missing token'], 401);
    }
    $user = auth_user_from_token($db, $raw);
    if ($user === null) {
        auth_send_json(['error' => 'Invalid or expired token'], 401);
    }
    return $user;
}

function admin_story_optional_user(PDO $db)
{
    $raw = auth_bearer_token();
    if ($raw === null || $raw === '') {
        return null;
    }
    $user = auth_user_from_token($db, $raw);
    return $user === null ? null : $user;
}

function admin_story_display_name(array $row)
{
    $name = isset($row['display_name']) ? trim((string) $row['display_name']) : '';
    if ($name !== '') {
        return $name;
    }
    return isset($row['email']) ? (string) $row['email'] : '';
}

function admin_story_is_admin(array $user)
{
    return (int) ($user['is_admin'] ?? 0) === 1;
}

function admin_story_require_admin(array $user)
{
    if (!admin_story_is_admin($user)) {
        auth_send_json(['error' => 'Admin access required'], 403);
    }
    return (int) $user['id'];
}

function admin_story_json_encode($value)
{
    $encoded = json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($encoded === false) {
        auth_send_json(['error' => 'Invalid JSON payload'], 400);
    }
    return $encoded;
}

function admin_story_normalize_target_ids($raw)
{
    if (!is_array($raw)) {
        return [];
    }
    $out = [];
    foreach ($raw as $v) {
        $id = (int) $v;
        if ($id > 0) {
            $out[$id] = true;
        }
    }
    return array_keys($out);
}

function admin_story_normalize_client_request_id($raw)
{
    $value = trim((string) $raw);
    if ($value === '') {
        return null;
    }
    if (strlen($value) > 80) {
        $value = substr($value, 0, 80);
    }
    return preg_replace('/[^A-Za-z0-9_.:-]/', '', $value);
}

function admin_story_has_client_request_id_column(PDO $db)
{
    static $hasColumn = null;
    if ($hasColumn !== null) {
        return $hasColumn;
    }
    try {
        $stmt = $db->query("SHOW COLUMNS FROM admin_stories LIKE 'client_request_id'");
        $hasColumn = $stmt && $stmt->fetch(PDO::FETCH_ASSOC) !== false;
    } catch (PDOException $e) {
        $hasColumn = false;
    }
    return $hasColumn;
}

function admin_story_content_type_supports_video(PDO $db)
{
    static $supports = null;
    if ($supports !== null) {
        return $supports;
    }
    try {
        $stmt = $db->query("SHOW COLUMNS FROM admin_stories LIKE 'content_type'");
        $row = $stmt ? $stmt->fetch(PDO::FETCH_ASSOC) : false;
        $type = is_array($row) && isset($row['Type']) ? (string) $row['Type'] : '';
        $supports = stripos($type, "'video'") !== false;
    } catch (PDOException $e) {
        $supports = false;
    }
    return $supports;
}

function admin_story_allowed_content_types(PDO $db)
{
    $types = ['text', 'image'];
    if (admin_story_content_type_supports_video($db)) {
        $types[] = 'video';
    }
    return $types;
}

function admin_story_upload_error_message($code)
{
    switch ((int) $code) {
        case UPLOAD_ERR_INI_SIZE:
        case UPLOAD_ERR_FORM_SIZE:
            return 'File is too large for the server. Please pick a shorter video.';
        case UPLOAD_ERR_PARTIAL:
            return 'Upload was interrupted. Please try again.';
        case UPLOAD_ERR_NO_FILE:
            return 'No file was uploaded';
        case UPLOAD_ERR_NO_TMP_DIR:
        case UPLOAD_ERR_CANT_WRITE:
            return 'Server could not save the upload';
        default:
            return 'Upload failed';
    }
}

function admin_story_detect_video_extension($tmp, $clientName)
{
    $fh = @fopen($tmp, 'rb');
    $header = $fh ? (string) fread($fh, 16) : '';
    if ($fh) {
        fclose($fh);
    }
    if (strlen($header) >= 8 && substr($header, 4, 4) === 'ftyp') {
        $brand = strtolower(substr($header, 8, 4));
        if ($brand === 'qt  ' || $brand === 'mqt ') {
            return 'mov';
        }
        return 'mp4';
    }
    if (strncmp($header, "\x1A\x45\xDF\xA3", 4) === 0) {
        return 'webm';
    }

    $name = strtolower((string) $clientName);
    if (substr($name, -4) === '.mov') {
        return 'mov';
    }
    if (substr($name, -5) === '.webm') {
        return 'webm';
    }
    if (substr($name, -4) === '.3gp' || substr($name, -5) === '.3gpp') {
        return '3gp';
    }
    if (substr($name, -4) === '.m4v' || substr($name, -4) === '.mp4') {
        return 'mp4';
    }
    return null;
}

function admin_story_has_visibility_hours_column(PDO $db)
{
    static $hasColumn = null;
    if ($hasColumn !== null) {
        return $hasColumn;
    }
    try {
        $stmt = $db->query("SHOW COLUMNS FROM admin_stories LIKE 'visibility_hours'");
        $hasColumn = $stmt && $stmt->fetch(PDO::FETCH_ASSOC) !== false;
    } catch (PDOException $e) {
        $hasColumn = false;
    }
    return $hasColumn;
}

function admin_story_normalize_visibility_hours($value)
{
    $hours = (int) $value;
    $allowed = [24, 48, 168, 720];
    return in_array($hours, $allowed, true) ? $hours : 24;
}

function admin_story_expiry_where_clause(PDO $db)
{
    if (admin_story_has_visibility_hours_column($db)) {
        return 's.created_at >= DATE_SUB(NOW(), INTERVAL COALESCE(s.visibility_hours, 24) HOUR)';
    }
    return 's.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)';
}

function admin_story_user_target_visibility_sql($userIdParam)
{
    return "(
             s.target_mode = 'all'
             OR s.admin_user_id = $userIdParam
             OR EXISTS (
               SELECT 1 FROM admin_story_targets t
               WHERE t.story_id = s.id AND t.user_id = $userIdParam
             )
           )";
}

function admin_story_poll_tables_exist(PDO $db)
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    try {
        $stmt = $db->query("SHOW TABLES LIKE 'admin_story_polls'");
        $hasPolls = $stmt && $stmt->fetch(PDO::FETCH_NUM) !== false;
        $stmt = $db->query("SHOW TABLES LIKE 'admin_story_poll_votes'");
        $hasVotes = $stmt && $stmt->fetch(PDO::FETCH_NUM) !== false;
        $exists = $hasPolls && $hasVotes;
    } catch (PDOException $e) {
        $exists = false;
    }
    return $exists;
}

function admin_story_grammar_tables_exist(PDO $db)
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    try {
        $stmt = $db->query("SHOW TABLES LIKE 'admin_story_grammar_games'");
        $hasGames = $stmt && $stmt->fetch(PDO::FETCH_NUM) !== false;
        $stmt = $db->query("SHOW TABLES LIKE 'admin_story_grammar_attempts'");
        $hasAttempts = $stmt && $stmt->fetch(PDO::FETCH_NUM) !== false;
        $exists = $hasGames && $hasAttempts;
    } catch (PDOException $e) {
        $exists = false;
    }
    return $exists;
}

function admin_story_find_client_request(PDO $db, $adminId, $clientRequestId)
{
    if ($clientRequestId === null || $clientRequestId === '') {
        return 0;
    }
    $stmt = $db->prepare(
        'SELECT id FROM admin_stories
         WHERE admin_user_id = :admin AND client_request_id = :request_id
         LIMIT 1'
    );
    $stmt->execute([
        ':admin' => (int) $adminId,
        ':request_id' => (string) $clientRequestId,
    ]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return $row ? (int) $row['id'] : 0;
}

function admin_story_text_length($value)
{
    $s = (string) $value;
    return function_exists('mb_strlen') ? mb_strlen($s, 'UTF-8') : strlen($s);
}

function admin_story_lower($value)
{
    $s = (string) $value;
    return function_exists('mb_strtolower') ? mb_strtolower($s, 'UTF-8') : strtolower($s);
}

function admin_story_clamp_float($value, $fallback, $min, $max)
{
    if (!is_numeric($value)) {
        return (float) $fallback;
    }
    $n = (float) $value;
    if ($n < $min) {
        return (float) $min;
    }
    if ($n > $max) {
        return (float) $max;
    }
    return $n;
}

function admin_story_validate_poll_payload($raw)
{
    if (!is_array($raw)) {
        auth_send_json(['error' => 'Invalid poll payload'], 400);
    }

    $question = isset($raw['question']) ? trim((string) $raw['question']) : '';
    if ($question !== '' && admin_story_text_length($question) > 80) {
        auth_send_json(['error' => 'Poll question is too long'], 400);
    }

    $rawOptions = isset($raw['options']) && is_array($raw['options']) ? $raw['options'] : [];
    if (count($rawOptions) < 2) {
        auth_send_json(['error' => 'Poll needs at least two options'], 400);
    }
    if (count($rawOptions) > 4) {
        auth_send_json(['error' => 'Poll can have at most four options'], 400);
    }

    $ids = ['a', 'b', 'c', 'd'];
    $seen = [];
    $options = [];
    foreach ($rawOptions as $i => $rawOption) {
        $text = '';
        if (is_array($rawOption)) {
            $text = isset($rawOption['text']) ? trim((string) $rawOption['text']) : '';
        } else {
            $text = trim((string) $rawOption);
        }
        if ($text === '') {
            auth_send_json(['error' => 'Poll option text is required'], 400);
        }
        if (admin_story_text_length($text) > 30) {
            auth_send_json(['error' => 'Poll option is too long'], 400);
        }
        $key = admin_story_lower($text);
        if (isset($seen[$key])) {
            auth_send_json(['error' => 'Poll options must be unique'], 400);
        }
        $seen[$key] = true;
        $options[] = ['id' => $ids[$i], 'text' => $text];
    }

    return [
        'question' => $question,
        'options' => $options,
        'x' => admin_story_clamp_float($raw['x'] ?? ($raw['position_x'] ?? 0.5), 0.5, 0.08, 0.92),
        'y' => admin_story_clamp_float($raw['y'] ?? ($raw['position_y'] ?? 0.58), 0.58, 0.12, 0.88),
        'scale' => admin_story_clamp_float($raw['scale'] ?? 1, 1, 0.75, 1.45),
    ];
}

function admin_story_poll_from_style($style)
{
    if (!is_array($style) || !isset($style['poll'])) {
        return null;
    }
    return admin_story_validate_poll_payload($style['poll']);
}

function admin_story_user_can_access(PDO $db, $storyId, $userId)
{
    $stmt = $db->prepare(
        "SELECT id
         FROM admin_stories s
         WHERE s.id = :sid
           AND s.deleted_at IS NULL
           AND " . admin_story_user_target_visibility_sql(':uid') . "
         LIMIT 1"
    );
    $stmt->execute([':sid' => (int) $storyId, ':uid' => (int) $userId]);
    return $stmt->fetch(PDO::FETCH_ASSOC) !== false;
}

function admin_story_user_can_access_active(PDO $db, $storyId, $userId)
{
    $grammarVisibleClause = admin_story_grammar_tables_exist($db)
        ? "OR EXISTS (SELECT 1 FROM admin_story_grammar_games g WHERE g.story_id = s.id)"
        : "";
    $stmt = $db->prepare(
        "SELECT id
         FROM admin_stories s
         LEFT JOIN admin_story_views v ON v.story_id = s.id AND v.user_id = :uid1
         WHERE s.id = :sid
           AND s.deleted_at IS NULL
           AND " . admin_story_user_target_visibility_sql(':uid2') . "
           AND (
             " . admin_story_expiry_where_clause($db) . "
             $grammarVisibleClause
           )
         LIMIT 1"
    );
    $stmt->execute([
        ':sid' => (int) $storyId,
        ':uid1' => (int) $userId,
        ':uid2' => (int) $userId,
    ]);
    return $stmt->fetch(PDO::FETCH_ASSOC) !== false;
}

function admin_story_poll_option_exists(array $poll, $optionId)
{
    $optionId = trim((string) $optionId);
    foreach ($poll['options'] ?? [] as $option) {
        if (isset($option['id']) && (string) $option['id'] === $optionId) {
            return true;
        }
    }
    return false;
}

function admin_story_grammar_option_exists(array $game, $optionId)
{
    $optionId = trim((string) $optionId);
    foreach ($game['options'] ?? [] as $option) {
        if (isset($option['id']) && (string) $option['id'] === $optionId) {
            return true;
        }
    }
    return false;
}

function admin_story_grammar_options_from_question(array $row)
{
    $out = [];
    for ($i = 1; $i <= 4; $i++) {
        $key = 'option' . $i;
        $text = isset($row[$key]) ? trim((string) $row[$key]) : '';
        if ($text !== '') {
            $out[] = ['id' => $key, 'text' => $text];
        }
    }
    return $out;
}

function admin_story_grammar_game_json_from_row(array $game, $selectedOptionId, $isCorrect, $showCorrect)
{
    $options = json_decode((string) ($game['options_json'] ?? '[]'), true);
    if (!is_array($options)) {
        $options = [];
    }
    $json = [
        'id' => (int) $game['id'],
        'question_id' => isset($game['grammar_question_id']) ? (int) $game['grammar_question_id'] : 0,
        'topic' => isset($game['topic']) ? (string) $game['topic'] : '',
        'question_text' => (string) $game['question_text'],
        'options' => $options,
        'game_type' => isset($game['game_type']) ? (string) $game['game_type'] : 'water_rescue',
    ];
    if ($selectedOptionId !== null && $selectedOptionId !== '') {
        $json['selected_option_id'] = (string) $selectedOptionId;
        $json['is_correct'] = (int) $isCorrect === 1;
    }
    if ($showCorrect) {
        $json['correct_option_id'] = (string) $game['correct_option_id'];
    }
    return $json;
}

function admin_story_poll_json_from_row(array $poll, array $counts, $selectedOptionId, $showResults)
{
    $options = json_decode((string) ($poll['options_json'] ?? '[]'), true);
    if (!is_array($options)) {
        $options = [];
    }

    $total = 0;
    foreach ($counts as $count) {
        $total += (int) $count;
    }

    $outOptions = [];
    foreach ($options as $option) {
        if (!is_array($option)) {
            continue;
        }
        $id = isset($option['id']) ? (string) $option['id'] : '';
        $count = isset($counts[$id]) ? (int) $counts[$id] : 0;
        $out = [
            'id' => $id,
            'text' => isset($option['text']) ? (string) $option['text'] : '',
        ];
        if ($showResults) {
            $out['vote_count'] = $count;
            $out['percent'] = $total > 0 ? round(($count * 100) / $total, 1) : 0;
        }
        $outOptions[] = $out;
    }

    $json = [
        'id' => (int) $poll['id'],
        'question' => (string) $poll['question'],
        'options' => $outOptions,
        'x' => isset($poll['position_x']) ? (float) $poll['position_x'] : 0.5,
        'y' => isset($poll['position_y']) ? (float) $poll['position_y'] : 0.58,
        'scale' => isset($poll['scale']) ? (float) $poll['scale'] : 1.0,
    ];
    if ($showResults) {
        $json['total_votes'] = $total;
    }
    if ($selectedOptionId !== null && $selectedOptionId !== '') {
        $json['selected_option_id'] = (string) $selectedOptionId;
    }
    return $json;
}

function admin_story_attach_polls(PDO $db, array $stories, $userId, $showAdminOwnerResults)
{
    if (count($stories) < 1) {
        return $stories;
    }
    if (!admin_story_poll_tables_exist($db)) {
        return $stories;
    }

    $storyIds = [];
    foreach ($stories as $story) {
        $storyIds[] = (int) $story['id'];
    }
    $storyIds = array_values(array_unique($storyIds));
    if (count($storyIds) < 1) {
        return $stories;
    }

    $placeholders = implode(',', array_fill(0, count($storyIds), '?'));
    $stmt = $db->prepare(
        "SELECT p.*, v.option_id AS selected_option_id
         FROM admin_story_polls p
         LEFT JOIN admin_story_poll_votes v ON v.poll_id = p.id AND v.user_id = ?
         WHERE p.story_id IN ($placeholders)"
    );
    $stmt->execute(array_merge([(int) $userId], $storyIds));
    $pollRows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (count($pollRows) < 1) {
        return $stories;
    }

    $pollByStory = [];
    $pollIds = [];
    foreach ($pollRows as $poll) {
        $pollByStory[(int) $poll['story_id']] = $poll;
        $pollIds[] = (int) $poll['id'];
    }

    $countsByPoll = [];
    $votePlaceholders = implode(',', array_fill(0, count($pollIds), '?'));
    $countStmt = $db->prepare(
        "SELECT poll_id, option_id, COUNT(*) AS c
         FROM admin_story_poll_votes
         WHERE poll_id IN ($votePlaceholders)
         GROUP BY poll_id, option_id"
    );
    $countStmt->execute($pollIds);
    foreach ($countStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $pid = (int) $row['poll_id'];
        if (!isset($countsByPoll[$pid])) {
            $countsByPoll[$pid] = [];
        }
        $countsByPoll[$pid][(string) $row['option_id']] = (int) $row['c'];
    }

    foreach ($stories as $i => $story) {
        $sid = (int) $story['id'];
        if (!isset($pollByStory[$sid])) {
            continue;
        }
        $poll = $pollByStory[$sid];
        $selected = isset($poll['selected_option_id']) && $poll['selected_option_id'] !== null
            ? (string) $poll['selected_option_id']
            : null;
        $showResults = $selected !== null || (
            $showAdminOwnerResults && (int) ($story['admin_user_id'] ?? 0) === (int) $userId
        );
        $pollJson = admin_story_poll_json_from_row(
            $poll,
            $countsByPoll[(int) $poll['id']] ?? [],
            $selected,
            $showResults
        );
        $style = isset($stories[$i]['text_style']) && is_array($stories[$i]['text_style'])
            ? $stories[$i]['text_style']
            : [];
        $style['poll'] = $pollJson;
        $stories[$i]['text_style'] = $style;
        $stories[$i]['poll'] = $pollJson;
    }

    return $stories;
}

function admin_story_attach_grammar_games(PDO $db, array $stories, $userId, $showAdminOwnerResults)
{
    if (count($stories) < 1) {
        return $stories;
    }
    if (!admin_story_grammar_tables_exist($db)) {
        return $stories;
    }

    $storyIds = [];
    foreach ($stories as $story) {
        $storyIds[] = (int) $story['id'];
    }
    $storyIds = array_values(array_unique($storyIds));
    if (count($storyIds) < 1) {
        return $stories;
    }

    $placeholders = implode(',', array_fill(0, count($storyIds), '?'));
    $stmt = $db->prepare(
        "SELECT g.*, a.selected_option_id, a.is_correct
         FROM admin_story_grammar_games g
         LEFT JOIN admin_story_grammar_attempts a ON a.game_id = g.id AND a.user_id = ?
         WHERE g.story_id IN ($placeholders)"
    );
    $stmt->execute(array_merge([(int) $userId], $storyIds));
    $gameRows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (count($gameRows) < 1) {
        return $stories;
    }

    $gameByStory = [];
    foreach ($gameRows as $game) {
        $gameByStory[(int) $game['story_id']] = $game;
    }

    foreach ($stories as $i => $story) {
        $sid = (int) $story['id'];
        if (!isset($gameByStory[$sid])) {
            continue;
        }
        $game = $gameByStory[$sid];
        $selected = isset($game['selected_option_id']) && $game['selected_option_id'] !== null
            ? (string) $game['selected_option_id']
            : null;
        $isCorrect = isset($game['is_correct']) && $game['is_correct'] !== null
            ? (int) $game['is_correct']
            : null;
        $showCorrect = $showAdminOwnerResults && (int) ($story['admin_user_id'] ?? 0) === (int) $userId;
        $gameJson = admin_story_grammar_game_json_from_row($game, $selected, $isCorrect, $showCorrect);
        $style = isset($stories[$i]['text_style']) && is_array($stories[$i]['text_style'])
            ? $stories[$i]['text_style']
            : [];
        $style['grammar_game'] = $gameJson;
        $stories[$i]['text_style'] = $style;
        $stories[$i]['grammar_game'] = $gameJson;
    }

    return $stories;
}

function admin_story_row_to_json(array $r)
{
    $style = null;
    if (isset($r['text_style_json']) && $r['text_style_json'] !== null && $r['text_style_json'] !== '') {
        $decoded = json_decode((string) $r['text_style_json'], true);
        if (is_array($decoded)) {
            $style = $decoded;
        }
    }
    $avatar = isset($r['admin_avatar']) && trim((string) $r['admin_avatar']) !== ''
        ? trim((string) $r['admin_avatar'])
        : 'm1';
    $viewedAt = isset($r['viewed_at']) && $r['viewed_at'] !== null ? (string) $r['viewed_at'] : null;
    return [
        'id'             => (int) $r['id'],
        'admin_user_id'  => (int) $r['admin_user_id'],
        'admin_name'     => admin_story_display_name([
            'display_name' => $r['admin_name'] ?? null,
            'email'        => $r['admin_email'] ?? null,
        ]),
        'admin_avatar'   => $avatar,
        'content_type'   => (string) $r['content_type'],
        'image_path'     => isset($r['image_path']) ? $r['image_path'] : null,
        'text_content'   => isset($r['text_content']) ? $r['text_content'] : null,
        'text_style'     => $style,
        'target_mode'       => (string) $r['target_mode'],
        'visibility_hours'  => isset($r['visibility_hours'])
            ? (int) $r['visibility_hours']
            : 24,
        'created_at'        => (string) $r['created_at'],
        'viewed_at'      => $viewedAt,
        'seen'           => $viewedAt !== null,
        'liked'          => isset($r['liked']) && (int) $r['liked'] === 1,
        'view_count'     => isset($r['view_count']) ? (int) $r['view_count'] : 0,
        'like_count'     => isset($r['like_count']) ? (int) $r['like_count'] : 0,
    ];
}

function admin_story_people_rows(PDO $db, $storyId, $table, $timeColumn)
{
    $allowed = [
        'admin_story_views' => 'viewed_at',
        'admin_story_likes' => 'liked_at',
    ];
    if (!isset($allowed[$table]) || $allowed[$table] !== $timeColumn) {
        auth_send_json(['error' => 'Invalid audience table'], 500);
    }
    $sql = "SELECT u.id,
                   u.email,
                   u.display_name,
                   u.avatar,
                   a.$timeColumn AS happened_at
            FROM $table a
            INNER JOIN users u ON u.id = a.user_id
            WHERE a.story_id = :sid
            ORDER BY a.$timeColumn DESC, u.id DESC";
    $stmt = $db->prepare($sql);
    $stmt->execute([':sid' => (int) $storyId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $out = [];
    foreach ($rows as $r) {
        $avatar = isset($r['avatar']) && trim((string) $r['avatar']) !== '' ? trim((string) $r['avatar']) : 'm1';
        $out[] = [
            'id'           => (int) $r['id'],
            'email'        => $r['email'],
            'display_name' => $r['display_name'],
            'avatar'       => $avatar,
            'happened_at'  => $r['happened_at'],
        ];
    }
    return $out;
}
