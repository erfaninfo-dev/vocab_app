<?php

/**
 * Shared DB + JSON helpers for all API scripts.
 * Compatible with PHP 7.4+ (avoid PHP 8-only syntax so shared hosting works).
 *
 * On the LIVE server: set DB_USER / DB_PASS / DB_NAME to the MySQL user from your
 * hosting panel (cPanel → MySQL Databases). Do NOT use root with an empty password
 * unless your server is configured for that — otherwise you get:
 *   SQLSTATE[HY000] [1045] Access denied ... (using password: NO)
 *
 * Local XAMPP often uses root + empty password + database ielts_vocab — adjust as needed.
 */
define('DB_HOST', 'localhost');
define('DB_USER', 'apiuser');
define('DB_PASS', '');
define('DB_NAME', 'erfaninfocom_appbooks');

if (is_file(__DIR__ . '/secrets.php')) {
    require_once __DIR__ . '/secrets.php';
}

// ─── Password reset email ────────────────────────────────────────────────────
// PHP mail() is not enough for Gmail/Yahoo. Set SMTP_* in secrets.php
// (cPanel → Email Accounts → create no-reply@erfaninfo.com).
if (!defined('APP_NAME')) {
    define('APP_NAME', 'Erfan Academy');
}
if (!defined('MAIL_FROM')) {
    define('MAIL_FROM', 'no-reply@erfaninfo.com');
}
if (!defined('MAIL_FROM_NAME')) {
    define('MAIL_FROM_NAME', APP_NAME);
}

/**
 * Returns a PDO connection to the database.
 *
 * @return PDO
 */
function getDb()
{
    static $pdo = null;
    if ($pdo === null) {
        try {
            $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4';
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);
        } catch (PDOException $e) {
            if (is_file(__DIR__ . '/api_log.php')) {
                require_once __DIR__ . '/api_log.php';
                api_log_error(
                    'database',
                    'PDO connection failed in getDb()',
                    [
                        'code' => $e->getCode(),
                        'msg'  => $e->getMessage(),
                    ]
                );
            }
            sendError('Database connection failed: ' . $e->getMessage(), 500);
        }
    }

    return $pdo;
}

/**
 * @param mixed $data
 */
function sendJson($data)
{
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');

    if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        exit;
    }

    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/**
 * @param int $code HTTP status
 */
function sendError($message, $code = 400)
{
    http_response_code($code);
    sendJson(['error' => $message]);
}
