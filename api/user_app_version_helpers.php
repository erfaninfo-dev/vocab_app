<?php

/**
 * Helpers for per-user installed app version (users table columns).
 */

function user_app_version_columns_ready(PDO $db): bool
{
    static $ready = null;
    if ($ready !== null) {
        return $ready;
    }
    try {
        $stmt = $db->query(
            "SHOW COLUMNS FROM users LIKE 'app_installed_version_code'"
        );
        $ready = $stmt !== false && $stmt->fetch(PDO::FETCH_ASSOC) !== false;
    } catch (PDOException $e) {
        $ready = false;
    }
    return $ready;
}

/**
 * @return array{version_code: int, version_name: string}|null
 */
function user_app_fetch_active_android_version(PDO $db): ?array
{
    try {
        $stmt = $db->prepare(
            'SELECT version_code, version_name
             FROM app_updates
             WHERE platform = :platform AND is_active = 1
             ORDER BY version_code DESC, created_at DESC
             LIMIT 1'
        );
        $stmt->execute([':platform' => 'android']);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row === false) {
            return null;
        }
        return [
            'version_code' => (int) $row['version_code'],
            'version_name' => (string) ($row['version_name'] ?? ''),
        ];
    } catch (PDOException $e) {
        return null;
    }
}

function user_app_version_report(
    PDO $db,
    int $userId,
    int $versionCode,
    string $versionName
): void {
    if ($userId < 1 || $versionCode < 1 || !user_app_version_columns_ready($db)) {
        return;
    }
    $name = trim($versionName);
    if (strlen($name) > 32) {
        $name = substr($name, 0, 32);
    }
    try {
        $stmt = $db->prepare(
            'UPDATE users
             SET app_installed_version_code = :code,
                 app_installed_version_name = :name,
                 app_version_reported_at = UTC_TIMESTAMP()
             WHERE id = :id LIMIT 1'
        );
        $stmt->execute([
            ':code' => $versionCode,
            ':name' => $name !== '' ? $name : null,
            ':id'   => $userId,
        ]);
    } catch (PDOException $e) {
        // Non-fatal for public app_update.php
    }
}

/**
 * @param array<string, mixed> $row
 * @return array<string, mixed>
 */
function user_app_version_json_fields(array $row): array
{
    $code = $row['app_installed_version_code'] ?? null;
    $name = $row['app_installed_version_name'] ?? null;
    $at = $row['app_version_reported_at'] ?? null;

    $installedCode = ($code !== null && $code !== '') ? (int) $code : null;
    $installedName = ($name !== null && trim((string) $name) !== '')
        ? trim((string) $name)
        : null;

    $reportedAt = null;
    if ($at !== null && trim((string) $at) !== '') {
        $ts = strtotime((string) $at);
        if ($ts !== false) {
            $reportedAt = gmdate('c', $ts);
        }
    }

    return [
        'installed_app_version_code' => ($installedCode !== null && $installedCode > 0)
            ? $installedCode
            : null,
        'installed_app_version_name' => $installedName,
        'app_version_reported_at'    => $reportedAt,
    ];
}
