<?php
/**
 * GET /api/game_word_categories.php
 *
 * Returns every active Word Builder theme category ("Animals", "Food", ...)
 * with its full word bank nested inside. Response is small and static, so the
 * client is expected to fetch and cache it in one shot.
 *
 * Response:
 * [
 *   {
 *     "id": 1,
 *     "slug": "animals",
 *     "name_en": "Animals",
 *     "name_fa": "حیوانات",
 *     "name_ckb": "ئاژەڵەکان",
 *     "icon": "pets_rounded",
 *     "sort_order": 0,
 *     "words": [
 *       {
 *         "word": "cat",
 *         "meaning_en": "",
 *         "meaning_fa": "گربه",
 *         "meaning_kur": "پشیله",
 *         "example_en": null,
 *         "example_fa": null,
 *         "example_kur": null
 *       },
 *       ...
 *     ]
 *   },
 *   ...
 * ]
 */

require_once __DIR__ . '/config.php';

try {
    $db = getDb();

    $stmt = $db->query(
        'SELECT c.id          AS category_id,
                c.slug        AS category_slug,
                c.name_en     AS category_name_en,
                c.name_fa     AS category_name_fa,
                c.name_ckb    AS category_name_ckb,
                c.icon        AS category_icon,
                c.sort_order  AS category_sort_order,
                w.word, w.meaning_en, w.meaning_fa, w.meaning_kur,
                w.example_en, w.example_fa, w.example_kur
         FROM   game_word_categories c
         LEFT JOIN game_category_words w ON w.category_id = c.id
         WHERE  c.is_active = 1
         ORDER  BY c.sort_order ASC, c.id ASC, w.sort_order ASC, w.id ASC'
    );

    $categoriesById = [];
    foreach ($stmt->fetchAll() as $row) {
        $id = (int) $row['category_id'];
        if (!isset($categoriesById[$id])) {
            $categoriesById[$id] = [
                'id'         => $id,
                'slug'       => $row['category_slug'],
                'name_en'    => $row['category_name_en'],
                'name_fa'    => $row['category_name_fa'],
                'name_ckb'   => $row['category_name_ckb'],
                'icon'       => $row['category_icon'],
                'sort_order' => (int) $row['category_sort_order'],
                'words'      => [],
            ];
        }
        if ($row['word'] !== null) {
            $categoriesById[$id]['words'][] = [
                'word'        => $row['word'],
                'meaning_en'  => $row['meaning_en']  ?? '',
                'meaning_fa'  => $row['meaning_fa']  ?? '',
                'meaning_kur' => $row['meaning_kur'] ?? '',
                'example_en'  => $row['example_en'],
                'example_fa'  => $row['example_fa'],
                'example_kur' => $row['example_kur'],
            ];
        }
    }

    sendJson(array_values($categoriesById));
} catch (PDOException $e) {
    sendError('Failed to load word categories: ' . $e->getMessage(), 500);
}
