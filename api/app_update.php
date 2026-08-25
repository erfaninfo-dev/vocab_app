<?php
/**
 * GET /app_update.php (public)
 *
 * Reads the latest Android / Windows update info from MySQL.
 *
 * Query:
 * - installed_version (optional) — buildNumber / versionCode on the device.
 * - installed_version_name (optional)
 * - platform (optional) — android|windows for release_notes lookup (default android)
 *
 * Table: app_updates (platform = android|windows; apk_url holds APK or Windows zip/exe URL)
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if (!isset($_SERVER['REQUEST_METHOD']) || $_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError('Only GET is allowed', 405);
}

$db = getDb();
$installedVersion = isset($_GET['installed_version'])
    ? max(0, (int) $_GET['installed_version'])
    : 0;
$notesPlatform = isset($_GET['platform']) ? strtolower(trim((string) $_GET['platform'])) : 'android';
if ($notesPlatform !== 'windows') {
    $notesPlatform = 'android';
}

$emptyNotes = [
    'en' => '',
    'fa' => '',
    'ku' => '',
];

/**
 * @return array<string, mixed>|null
 */
function app_update_fetch_latest(PDO $db, string $platform): ?array
{
    $stmt = $db->prepare(
        'SELECT version_code, version_name, apk_url, force_update
         FROM app_updates
         WHERE platform = :platform AND is_active = 1
         ORDER BY version_code DESC, created_at DESC
         LIMIT 1'
    );
    $stmt->execute([':platform' => $platform]);
    $row = $stmt->fetch();
    return $row ?: null;
}

try {
    $androidRow = app_update_fetch_latest($db, 'android');
    $windowsRow = app_update_fetch_latest($db, 'windows');

    $releaseNotes = $emptyNotes;
    if ($installedVersion > 0) {
        $notesStmt = $db->prepare(
            'SELECT message_en, message_fa, message_ku
             FROM app_updates
             WHERE platform = :platform AND version_code = :version AND is_active = 1
             LIMIT 1'
        );
        $notesStmt->execute([
            ':platform' => $notesPlatform,
            ':version'  => $installedVersion,
        ]);
        $notesRow = $notesStmt->fetch();
        if ($notesRow) {
            $releaseNotes = [
                'en' => (string) ($notesRow['message_en'] ?? ''),
                'fa' => (string) ($notesRow['message_fa'] ?? ''),
                'ku' => (string) ($notesRow['message_ku'] ?? ''),
            ];
        }
    }

    sendJson([
        'android_version_code' => (int) ($androidRow['version_code'] ?? 0),
        'android_version_name' => (string) ($androidRow['version_name'] ?? ''),
        'apk_url'              => (string) ($androidRow['apk_url'] ?? ''),
        'android_force_update' => isset($androidRow['force_update']) ? (int) $androidRow['force_update'] : 0,
        'windows_version_code' => (int) ($windowsRow['version_code'] ?? 0),
        'windows_version_name' => (string) ($windowsRow['version_name'] ?? ''),
        'windows_url'          => (string) ($windowsRow['apk_url'] ?? ''),
        'windows_force_update' => isset($windowsRow['force_update']) ? (int) $windowsRow['force_update'] : 0,
        'force_update'         => isset($androidRow['force_update']) ? (int) $androidRow['force_update'] : 0,
        'release_notes'        => $releaseNotes,
    ]);
} catch (Exception $e) {
    sendError('Update check failed: ' . $e->getMessage(), 500);
}
