<?php

/**
 * Word Builder PvP Challenge helpers.
 * Letter multiset logic mirrors lib/features/word_builder/domain/word_builder_game_logic.dart
 */

const PVP_CHALLENGE_PENDING_HOURS = 48;
const PVP_CHALLENGE_PLAY_DAYS = 7;
const PVP_CHALLENGE_DURATION_GRACE_SEC = 5;
const PVP_CHALLENGE_MIN_PLAYABLE_WORDS = 8;
const PVP_CHALLENGE_MIN_WORD_LEN = 3;

function pvp_normalize_word($word)
{
    return strtolower(trim((string) $word));
}

function pvp_letter_multiset_for_word($wordLower)
{
    $m = [];
    $len = strlen($wordLower);
    for ($i = 0; $i < $len; $i++) {
        $ch = $wordLower[$i];
        if ($ch === '') {
            continue;
        }
        if (!isset($m[$ch])) {
            $m[$ch] = 0;
        }
        $m[$ch]++;
    }

    return $m;
}

function pvp_pool_max_per_letter_across_words(array $wordsLower)
{
    $maps = [];
    foreach ($wordsLower as $w) {
        $maps[] = pvp_letter_multiset_for_word($w);
    }
    if (count($maps) === 0) {
        return [];
    }
    $keys = [];
    foreach ($maps as $map) {
        foreach (array_keys($map) as $k) {
            $keys[$k] = true;
        }
    }
    $out = [];
    foreach (array_keys($keys) as $k) {
        $mx = 0;
        foreach ($maps as $map) {
            $v = isset($map[$k]) ? (int) $map[$k] : 0;
            if ($v > $mx) {
                $mx = $v;
            }
        }
        $out[$k] = $mx;
    }

    return $out;
}

function pvp_expand_pool_letters(array $pool)
{
    $keys = array_keys($pool);
    sort($keys, SORT_STRING);
    $out = [];
    foreach ($keys as $k) {
        $n = isset($pool[$k]) ? (int) $pool[$k] : 0;
        for ($i = 0; $i < $n; $i++) {
            $out[] = $k;
        }
    }

    return $out;
}

function pvp_can_spell_from_pool($wordLower, array $poolCounts)
{
    $need = pvp_letter_multiset_for_word($wordLower);
    foreach ($need as $ch => $count) {
        if (!isset($poolCounts[$ch]) || (int) $poolCounts[$ch] < (int) $count) {
            return false;
        }
    }

    return true;
}

function pvp_table_exists(PDO $db, $table)
{
    try {
        $stmt = $db->prepare('SHOW TABLES LIKE :t');
        $stmt->execute([':t' => $table]);

        return (bool) $stmt->fetchColumn();
    } catch (PDOException $e) {
        return false;
    }
}

function pvp_tables_ready(PDO $db)
{
    return pvp_table_exists($db, 'pvp_matches')
        && pvp_table_exists($db, 'pvp_match_players');
}

function pvp_expire_stale_matches(PDO $db)
{
    if (!pvp_table_exists($db, 'pvp_matches')) {
        return;
    }
    $db->exec(
        "UPDATE pvp_matches
         SET status = 'expired'
         WHERE status IN ('pending','accepted')
         AND expires_at < NOW()"
    );
}

function pvp_has_active_match_between(PDO $db, $uidA, $uidB)
{
    pvp_expire_stale_matches($db);
    $lo = min((int) $uidA, (int) $uidB);
    $hi = max((int) $uidA, (int) $uidB);
    $stmt = $db->prepare(
        "SELECT id FROM pvp_matches
         WHERE status IN ('pending','accepted')
         AND LEAST(challenger_id, opponent_id) = :lo
         AND GREATEST(challenger_id, opponent_id) = :hi
         LIMIT 1"
    );
    $stmt->execute([':lo' => $lo, ':hi' => $hi]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row ? (int) $row['id'] : null;
}

function pvp_seeded_shuffle(array $items, $seed)
{
    $copy = array_values($items);
    $n = count($copy);
    if ($n <= 1) {
        return $copy;
    }
    $state = (int) $seed;
    for ($i = $n - 1; $i > 0; $i--) {
        $state = ($state * 1103515245 + 12345) & 0x7fffffff;
        $j = $state % ($i + 1);
        $tmp = $copy[$i];
        $copy[$i] = $copy[$j];
        $copy[$j] = $tmp;
    }

    return $copy;
}

function pvp_fetch_active_categories(PDO $db)
{
    $stmt = $db->query(
        "SELECT c.id, c.slug, c.name_en, c.name_fa, c.name_ckb, c.icon,
                COUNT(w.id) AS word_count
         FROM game_word_categories c
         INNER JOIN game_category_words w ON w.category_id = c.id
         WHERE c.is_active = 1
         GROUP BY c.id, c.slug, c.name_en, c.name_fa, c.name_ckb, c.icon, c.sort_order
         HAVING word_count >= 10
         ORDER BY c.sort_order ASC, c.id ASC"
    );

    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function pvp_fetch_category_words(PDO $db, $categoryId)
{
    $stmt = $db->prepare(
        'SELECT LOWER(TRIM(word)) AS word
         FROM game_category_words
         WHERE category_id = :cid
         AND CHAR_LENGTH(TRIM(word)) >= :minlen
         ORDER BY sort_order ASC, id ASC'
    );
    $stmt->execute([
        ':cid' => (int) $categoryId,
        ':minlen' => PVP_CHALLENGE_MIN_WORD_LEN,
    ]);
    $out = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $w = pvp_normalize_word($row['word']);
        if ($w === '' || !preg_match('/^[a-z]+$/', $w)) {
            continue;
        }
        $out[$w] = true;
    }

    return array_keys($out);
}

function pvp_pick_anchor_words(array $words, $seed, $count = 3)
{
    $candidates = [];
    foreach ($words as $w) {
        $len = strlen($w);
        if ($len >= 4 && $len <= 7) {
            $candidates[] = $w;
        }
    }
    if (count($candidates) < $count) {
        $candidates = $words;
    }
    $shuffled = pvp_seeded_shuffle($candidates, (int) $seed);
    $picked = [];
    foreach ($shuffled as $w) {
        if (count($picked) >= $count) {
            break;
        }
        if (!in_array($w, $picked, true)) {
            $picked[] = $w;
        }
    }

    return $picked;
}

function pvp_count_playable_words(array $dictionaryWords, array $letters)
{
    $pool = [];
    foreach ($letters as $ch) {
        $k = pvp_normalize_word($ch);
        if ($k === '' || strlen($k) !== 1) {
            continue;
        }
        if (!isset($pool[$k])) {
            $pool[$k] = 0;
        }
        $pool[$k]++;
    }
    $n = 0;
    foreach ($dictionaryWords as $w) {
        if (strlen($w) < PVP_CHALLENGE_MIN_WORD_LEN) {
            continue;
        }
        if (pvp_can_spell_from_pool($w, $pool)) {
            $n++;
        }
    }

    return $n;
}

function pvp_generate_match_letters(PDO $db, $matchId)
{
    $categories = pvp_fetch_active_categories($db);
    if (count($categories) === 0) {
        return null;
    }
    $catOrder = pvp_seeded_shuffle($categories, (int) $matchId);
    foreach ($catOrder as $catIdx => $cat) {
        $categoryId = (int) $cat['id'];
        $words = pvp_fetch_category_words($db, $categoryId);
        if (count($words) < 10) {
            continue;
        }
        for ($attempt = 0; $attempt < 20; $attempt++) {
            $seed = (int) $matchId * 1000 + ($catIdx * 20) + $attempt;
            $anchor = pvp_pick_anchor_words($words, $seed, 3);
            if (count($anchor) < 3) {
                continue;
            }
            $pool = pvp_pool_max_per_letter_across_words($anchor);
            $letters = pvp_expand_pool_letters($pool);
            if (count($letters) < 6) {
                continue;
            }
            $playable = pvp_count_playable_words($words, $letters);
            if ($playable >= PVP_CHALLENGE_MIN_PLAYABLE_WORDS) {
                return [
                    'category_id' => $categoryId,
                    'category' => $cat,
                    'letter_seed' => $seed,
                    'anchor_words' => $anchor,
                    'letters' => $letters,
                ];
            }
        }
    }

    return null;
}

function pvp_word_in_category(PDO $db, $categoryId, $wordLower)
{
    $stmt = $db->prepare(
        'SELECT 1 FROM game_category_words
         WHERE category_id = :cid AND LOWER(TRIM(word)) = :w LIMIT 1'
    );
    $stmt->execute([':cid' => (int) $categoryId, ':w' => $wordLower]);

    return (bool) $stmt->fetchColumn();
}

function pvp_compute_score(array $validWords)
{
    $score = 0;
    foreach ($validWords as $w) {
        $score += strlen($w);
    }

    return $score;
}

function pvp_validate_submitted_words(PDO $db, $categoryId, array $letters, array $rawWords)
{
    $pool = [];
    foreach ($letters as $ch) {
        $k = pvp_normalize_word($ch);
        if ($k === '' || strlen($k) !== 1) {
            continue;
        }
        if (!isset($pool[$k])) {
            $pool[$k] = 0;
        }
        $pool[$k]++;
    }

    $valid = [];
    $invalid = [];
    $duplicate = [];
    $seen = [];

    foreach ($rawWords as $raw) {
        $w = pvp_normalize_word($raw);
        if ($w === '' || !preg_match('/^[a-z]+$/', $w)) {
            if ($w !== '') {
                $invalid[] = $w;
            }
            continue;
        }
        if (strlen($w) < PVP_CHALLENGE_MIN_WORD_LEN) {
            $invalid[] = $w;
            continue;
        }
        if (isset($seen[$w])) {
            $duplicate[] = $w;
            continue;
        }
        $seen[$w] = true;
        if (!pvp_word_in_category($db, $categoryId, $w)) {
            $invalid[] = $w;
            continue;
        }
        if (!pvp_can_spell_from_pool($w, $pool)) {
            $invalid[] = $w;
            continue;
        }
        $valid[] = $w;
    }

    return [
        'valid_words' => $valid,
        'invalid_words' => array_values(array_unique($invalid)),
        'duplicate_words' => array_values(array_unique($duplicate)),
        'score' => pvp_compute_score($valid),
    ];
}

function pvp_fetch_user_brief(PDO $db, $userId)
{
    $stmt = $db->prepare(
        'SELECT id, display_name, avatar FROM users WHERE id = :id LIMIT 1'
    );
    $stmt->execute([':id' => (int) $userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return null;
    }
    $av = isset($row['avatar']) && $row['avatar'] !== '' ? $row['avatar'] : 'm1';

    return [
        'user_id' => (int) $row['id'],
        'display_name' => $row['display_name'],
        'avatar' => $av,
    ];
}

function pvp_fetch_match_players(PDO $db, $matchId)
{
    $stmt = $db->prepare(
        'SELECT mp.*, u.display_name, u.avatar
         FROM pvp_match_players mp
         INNER JOIN users u ON u.id = mp.user_id
         WHERE mp.match_id = :mid
         ORDER BY mp.turn_order ASC'
    );
    $stmt->execute([':mid' => (int) $matchId]);

    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function pvp_player_row_by_user(array $players, $userId)
{
    foreach ($players as $p) {
        if ((int) $p['user_id'] === (int) $userId) {
            return $p;
        }
    }

    return null;
}

function pvp_challenger_player(array $players)
{
    foreach ($players as $p) {
        if ((int) $p['turn_order'] === 1) {
            return $p;
        }
    }

    return null;
}

function pvp_opponent_player(array $players)
{
    foreach ($players as $p) {
        if ((int) $p['turn_order'] === 2) {
            return $p;
        }
    }

    return null;
}

function pvp_parse_words_json($json)
{
    if ($json === null || $json === '') {
        return null;
    }
    $decoded = is_string($json) ? json_decode($json, true) : $json;
    if (!is_array($decoded)) {
        return null;
    }

    return array_values($decoded);
}

function pvp_category_summary_from_row(array $matchRow, PDO $db)
{
    $stmt = $db->prepare(
        'SELECT id, slug, name_en, name_fa, name_ckb, icon
         FROM game_word_categories WHERE id = :id LIMIT 1'
    );
    $stmt->execute([':id' => (int) $matchRow['category_id']]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return [
            'id' => (int) $matchRow['category_id'],
            'slug' => '',
            'name_en' => 'Topic',
            'name_fa' => '',
            'name_ckb' => '',
            'icon' => 'category_rounded',
        ];
    }

    return [
        'id' => (int) $row['id'],
        'slug' => $row['slug'],
        'name_en' => $row['name_en'],
        'name_fa' => $row['name_fa'],
        'name_ckb' => $row['name_ckb'],
        'icon' => $row['icon'],
    ];
}

function pvp_viewer_state(array $matchRow, array $players, $viewerUserId)
{
    $viewerId = (int) $viewerUserId;
    $challengerId = (int) $matchRow['challenger_id'];
    $opponentId = (int) $matchRow['opponent_id'];
    $status = $matchRow['status'];
    $me = pvp_player_row_by_user($players, $viewerId);
    $challenger = pvp_challenger_player($players);
    $opponent = pvp_opponent_player($players);

    $canAccept = false;
    $canDecline = false;
    $canPlay = false;
    $reason = null;

    if ($status === 'pending' && $viewerId === $opponentId) {
        $canAccept = true;
        $canDecline = true;
    }

    if ($status === 'accepted' && $me !== null) {
        $myStatus = $me['player_status'];
        if ($myStatus === 'submitted') {
            $canPlay = false;
            $reason = 'already_submitted';
        } elseif ($viewerId === $challengerId) {
            $canPlay = true;
        } elseif ($viewerId === $opponentId) {
            if ($challenger !== null && $challenger['player_status'] === 'submitted') {
                $canPlay = true;
            } else {
                $canPlay = false;
                $reason = 'waiting_for_challenger';
            }
        }
    }

    $hideLetters = ($status === 'pending' && $viewerId === $opponentId);

    return [
        'user_id' => $viewerId,
        'can_accept' => $canAccept,
        'can_decline' => $canDecline,
        'can_play' => $canPlay,
        'hide_letters' => $hideLetters,
        'reason_if_blocked' => $reason,
        'is_challenger' => $viewerId === $challengerId,
        'is_opponent' => $viewerId === $opponentId,
    ];
}

function pvp_match_to_json(PDO $db, array $matchRow, $viewerUserId)
{
    $players = pvp_fetch_match_players($db, (int) $matchRow['id']);
    $letters = json_decode($matchRow['letters_json'], true);
    if (!is_array($letters)) {
        $letters = [];
    }
    $anchor = json_decode($matchRow['anchor_words_json'], true);
    if (!is_array($anchor)) {
        $anchor = [];
    }
    $viewer = pvp_viewer_state($matchRow, $players, $viewerUserId);
    if (!empty($viewer['hide_letters'])) {
        $letters = [];
        $anchor = [];
    }

    $viewerPlayer = pvp_player_row_by_user($players, $viewerUserId);
    $viewerSubmitted = $viewerPlayer !== null && $viewerPlayer['player_status'] === 'submitted';

    $playerOut = [];
    foreach ($players as $p) {
        $words = pvp_parse_words_json($p['words_json']);
        $hideScore = false;
        if ($matchRow['status'] === 'accepted'
            && (int) $p['user_id'] !== (int) $viewerUserId
            && $p['player_status'] === 'submitted'
            && !$viewerSubmitted) {
            $hideScore = true;
        }

        $playerOut[] = [
            'user_id' => (int) $p['user_id'],
            'display_name' => $p['display_name'],
            'avatar' => $p['avatar'] !== '' ? $p['avatar'] : 'm1',
            'turn_order' => (int) $p['turn_order'],
            'player_status' => $p['player_status'],
            'score' => $hideScore ? null : (int) $p['score'],
            'words' => $hideScore ? null : $words,
            'started_at' => $p['started_at'],
            'completed_at' => $p['completed_at'],
        ];
    }

    $challenger = pvp_fetch_user_brief($db, (int) $matchRow['challenger_id']);
    $opponent = pvp_fetch_user_brief($db, (int) $matchRow['opponent_id']);

    return [
        'id' => (int) $matchRow['id'],
        'status' => $matchRow['status'],
        'duration_sec' => (int) $matchRow['duration_sec'],
        'category' => pvp_category_summary_from_row($matchRow, $db),
        'letters' => array_values($letters),
        'anchor_words' => array_values($anchor),
        'expires_at' => $matchRow['expires_at'],
        'created_at' => $matchRow['created_at'],
        'accepted_at' => $matchRow['accepted_at'],
        'completed_at' => $matchRow['completed_at'],
        'winner_id' => $matchRow['winner_id'] !== null ? (int) $matchRow['winner_id'] : null,
        'is_draw' => (int) $matchRow['is_draw'] === 1,
        'challenger' => $challenger,
        'opponent' => $opponent,
        'players' => $playerOut,
        'viewer' => $viewer,
    ];
}

function pvp_resolve_winner(PDO $db, $matchId)
{
    $stmt = $db->prepare('SELECT * FROM pvp_matches WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => (int) $matchId]);
    $match = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($match === false || $match['status'] !== 'accepted') {
        return;
    }
    $players = pvp_fetch_match_players($db, (int) $matchId);
    if (count($players) < 2) {
        return;
    }
    $allSubmitted = true;
    foreach ($players as $p) {
        if ($p['player_status'] !== 'submitted') {
            $allSubmitted = false;
            break;
        }
    }
    if (!$allSubmitted) {
        return;
    }

    $p1 = pvp_challenger_player($players);
    $p2 = pvp_opponent_player($players);
    $s1 = (int) $p1['score'];
    $s2 = (int) $p2['score'];
    $winnerId = null;
    $isDraw = 0;
    if ($s1 > $s2) {
        $winnerId = (int) $p1['user_id'];
    } elseif ($s2 > $s1) {
        $winnerId = (int) $p2['user_id'];
    } else {
        $isDraw = 1;
    }

    $upd = $db->prepare(
        "UPDATE pvp_matches
         SET status = 'completed', winner_id = :wid, is_draw = :draw, completed_at = NOW()
         WHERE id = :id AND status = 'accepted'"
    );
    $upd->execute([
        ':wid' => $winnerId,
        ':draw' => $isDraw,
        ':id' => (int) $matchId,
    ]);
}

function pvp_assert_participant(array $matchRow, $userId)
{
    $uid = (int) $userId;
    if ($uid !== (int) $matchRow['challenger_id'] && $uid !== (int) $matchRow['opponent_id']) {
        auth_send_json(['error' => 'forbidden'], 403);
    }
}

function pvp_match_summary_card(PDO $db, array $matchRow, $viewerUserId)
{
    $full = pvp_match_to_json($db, $matchRow, $viewerUserId);
    $other = ((int) $viewerUserId === (int) $matchRow['challenger_id'])
        ? $full['opponent']
        : $full['challenger'];
    $mePlayer = null;
    $otherPlayer = null;
    foreach ($full['players'] as $p) {
        if ((int) $p['user_id'] === (int) $viewerUserId) {
            $mePlayer = $p;
        } else {
            $otherPlayer = $p;
        }
    }

    $isMyTurn = !empty($full['viewer']['can_play']);

    return [
        'id' => $full['id'],
        'status' => $full['status'],
        'category' => $full['category'],
        'expires_at' => $full['expires_at'],
        'is_my_turn' => $isMyTurn,
        'is_draw' => $full['is_draw'],
        'winner_id' => $full['winner_id'],
        'other_user' => $other,
        'my_score' => $mePlayer !== null ? $mePlayer['score'] : null,
        'other_score' => $otherPlayer !== null ? $otherPlayer['score'] : null,
        'viewer' => $full['viewer'],
    ];
}

function pvp_parse_iso_datetime($raw)
{
    $s = trim((string) $raw);
    if ($s === '') {
        return null;
    }
    try {
        $dt = new DateTimeImmutable($s);

        return $dt->format('Y-m-d H:i:s');
    } catch (Exception $e) {
        return null;
    }
}

function pvp_duration_seconds($startedAt, $completedAt)
{
    if ($startedAt === null || $completedAt === null) {
        return null;
    }
    $a = strtotime($startedAt);
    $b = strtotime($completedAt);
    if ($a === false || $b === false) {
        return null;
    }

    return max(0, $b - $a);
}
