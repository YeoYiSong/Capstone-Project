-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- 主机： 127.0.0.1
-- 生成日期： 2025-08-14 07:49:23
-- 服务器版本： 10.4.32-MariaDB
-- PHP 版本： 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- 数据库： `sd`
--

-- --------------------------------------------------------

--
-- 表的结构 `auth_users`
--

CREATE TABLE `auth_users` (
  `id` int(11) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `password` text DEFAULT NULL,
  `google_id` varchar(100) DEFAULT NULL,
  `google_bound` tinyint(1) DEFAULT 0,
  `apple_id` varchar(100) DEFAULT NULL,
  `apple_bound` tinyint(1) DEFAULT 0,
  `create_at` datetime DEFAULT current_timestamp(),
  `firebase_uid` varchar(128) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `auth_users`
--

INSERT INTO `auth_users` (`id`, `phone_number`, `password`, `google_id`, `google_bound`, `apple_id`, `apple_bound`, `create_at`, `firebase_uid`) VALUES
(4, NULL, NULL, NULL, 0, NULL, 0, '2025-07-19 00:34:48', 'Sm5RG6yzcgTaQeseduqwSD6o5bo1');

-- --------------------------------------------------------

--
-- 表的结构 `breath_record`
--

CREATE TABLE `breath_record` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `duration` int(11) DEFAULT NULL,
  `min` int(11) NOT NULL,
  `feeling` varchar(255) DEFAULT NULL,
  `create_at` datetime DEFAULT current_timestamp(),
  `type` enum('正常','引導') NOT NULL DEFAULT '引導'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `breath_record`
--

INSERT INTO `breath_record` (`id`, `user_id`, `duration`, `min`, `feeling`, `create_at`, `type`) VALUES
(5, 6, 5, 5, '阿達', '2025-07-19 01:10:10', '引導'),
(6, 6, 5, 5, '撒大大', '2025-07-30 21:10:13', '引導'),
(7, 6, 5, 5, '很輕鬆', '2025-07-31 19:34:18', '引導');

-- --------------------------------------------------------

--
-- 表的结构 `color`
--

CREATE TABLE `color` (
  `id` int(11) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `hex_code` char(7) DEFAULT NULL,
  `emotion_tag` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 表的结构 `diaries`
--

CREATE TABLE `diaries` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `content` text DEFAULT NULL,
  `joy` float DEFAULT 0,
  `sadness` float DEFAULT 0,
  `anger` float DEFAULT 0,
  `positive` float DEFAULT 0,
  `anxiety` float DEFAULT 0,
  `exhaust` float DEFAULT 0,
  `color_mix` varchar(10) DEFAULT NULL,
  `create_at` datetime DEFAULT current_timestamp(),
  `oil_id` int(11) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `is_english` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `diaries`
--

INSERT INTO `diaries` (`id`, `user_id`, `content`, `joy`, `sadness`, `anger`, `positive`, `anxiety`, `exhaust`, `color_mix`, `create_at`, `oil_id`, `details`, `is_english`) VALUES
(22, 6, '啊實打實', 0, 0, 0, 83.6863, 0, 0, '#FFC36100', '2025-07-19 01:10:37', NULL, '阿達', 0),
(23, 6, '很煩躁', 0, 0, 91.8998, 0, 0, 0, '#FFAE0000', '2025-07-30 21:12:35', NULL, '', 0),
(24, 6, '我一定可以一直成功下去的', 0, 0, 0, 85.8193, 0, 0, '#FFBD5F00', '2025-08-13 14:26:28', NULL, '', 0);

-- --------------------------------------------------------

--
-- 表的结构 `effect`
--

CREATE TABLE `effect` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `effect`
--

INSERT INTO `effect` (`id`, `name`) VALUES
(1, '感冒'),
(2, '腸胃脹氣'),
(3, '沒胃口'),
(4, '焦慮'),
(5, '青春痘'),
(6, '經痛'),
(7, '咳嗽'),
(8, '驚嚇'),
(9, '預防皺紋'),
(10, '曬傷'),
(11, '緊張'),
(12, '便秘'),
(13, '消除黑眼圈'),
(14, '疤痕'),
(15, '失眠'),
(16, '淤青'),
(17, '抑鬱'),
(18, '高血壓'),
(19, '消化不良'),
(20, '偏頭痛'),
(21, '痙攣'),
(22, '鼻塞'),
(23, '瘦身'),
(24, '減肥'),
(25, '肌肉痛'),
(26, '低血壓'),
(27, '水腫'),
(28, '毛孔粗大');

-- --------------------------------------------------------

--
-- 表的结构 `emoji`
--

CREATE TABLE `emoji` (
  `id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `image_url` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 表的结构 `now`
--

CREATE TABLE `now` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `joy` float DEFAULT 0,
  `sadness` float DEFAULT 0,
  `anger` float DEFAULT 0,
  `positive` float DEFAULT 0,
  `anxiety` float DEFAULT 0,
  `exhaust` float DEFAULT 0,
  `note` text DEFAULT NULL,
  `create_at` datetime DEFAULT current_timestamp(),
  `details` text DEFAULT NULL,
  `is_english` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `now`
--

INSERT INTO `now` (`id`, `user_id`, `joy`, `sadness`, `anger`, `positive`, `anxiety`, `exhaust`, `note`, `create_at`, `details`, `is_english`) VALUES
(7, 6, 0, 0, 0, 0, 57.7213, 0, '阿斯頓撒旦', '2025-07-19 01:10:26', '撒大大', 0),
(8, 6, 0, 91.9608, 0, 0, 0, 0, '阿斯頓撒', '2025-07-30 21:11:20', '薩達', 0),
(9, 6, 0, 0, 0, 0, 0, 0, '我很高興我能完成好今天的任務哦~~', '2025-08-13 14:39:26', '', 0);

-- --------------------------------------------------------

--
-- 表的结构 `oil`
--

CREATE TABLE `oil` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `meaning` text DEFAULT NULL,
  `effect` text DEFAULT NULL,
  `image_url` text DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `spec_ml` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `oil`
--

INSERT INTO `oil` (`id`, `name`, `meaning`, `effect`, `image_url`, `price`, `spec_ml`) VALUES
(1, '薰衣草精油', '薰衣草擁有柔和清新的花香氣息…適合用於睡前放鬆、靜心冥想或紓壓沐浴。', '改善焦慮、幫助入睡、舒緩肌肉痠痛、調理痘痘肌膚', NULL, 1400, 15),
(2, '佛手柑精油', '佛手柑散發出明亮、帶著淡淡甜味的柑橘香…適合早晨醒來或在壓力沉重的日子中使用。', '改善焦慮與抑鬱、促進消化、舒緩腸胃脹氣、緊緻毛孔', NULL, 1900, 15),
(3, '尤加利精油', '尤加利氣味清涼醒腦，如森林間的清晨空氣…常用於擴香器中淨化環境或在洗澡時加入幾滴喚醒身心。', '暢通呼吸道、緩解咳嗽與鼻塞、放鬆肌肉、輔助瘦身', NULL, 1100, 15),
(4, '迷迭香精油', '帶有草本與木質的清新氣味，常被用來提振精神與提升專注力…', '促進消化、緩解頭痛、改善痘痘、幫助雕塑體態', NULL, 1000, 15),
(5, '乳香精油', '帶有溫暖、樹脂般的神聖氣息，常用於冥想與靜心…對肌膚有修護與緊緻效果。', '放鬆焦慮、舒緩緊張、促進皮膚修護、抗老化', NULL, 4150, 15),
(6, '快樂鼠尾草精油', '淡淡甜味與草本香氣，適合在需要自我照顧、療癒心靈的時刻…', '舒緩經期不適、減輕焦慮與頭痛、穩定情緒壓力', NULL, 2000, 15),
(7, '檀香精油', '溫潤厚實的木質氣味，能帶來內在寧靜與沉穩，適合靜坐或睡前深層放鬆。', '安撫情緒、促進睡眠、修護疤痕、細緻膚質', NULL, 3950, 5),
(8, '雪松精油', '溫和穩重的木質香氣，有助放鬆神經與情緒平衡，也常用於護膚與控油。', '緩解焦慮、收斂毛孔、舒緩便秘與咳嗽', NULL, 750, 15),
(9, '茶樹精油', '清新強烈的草本香氣，以潔淨與防護特性著稱，常見於居家清潔與肌膚保養。', '舒緩咳嗽、改善消化不良、淨化空氣、控油抗痘', NULL, 1150, 15),
(10, '天竺葵精油', '融合花香與青草的香氣，有助情緒平衡與肌膚調理，為日常注入溫柔與平靜。', '舒緩焦慮與緊張、改善水腫、淡化黑眼圈與痘痘', NULL, 2200, 15),
(11, '檸檬精油', '明亮的柑橘香氣，能迅速提振精神、淨化空氣，適合晨起或提神使用。', '促進消化、改善毛孔與痘痘、幫助瘦身與利水', NULL, 700, 15),
(12, '羅勒精油', '清新的草本香氣，適合思緒混亂或精神疲憊時使用，讓身心回歸平衡。', '舒緩咳嗽與鼻塞、改善消化不良、減輕偏頭痛與緊張', NULL, 1825, 15),
(13, '黑胡椒精油', '溫暖辛香，具有激勵與提振的力量，適合運動後或疲勞時使用。', '促進消化、改善胃口、舒緩肌肉痠痛、改善便秘與低血壓', NULL, 1125, 15),
(14, '丁香精油', '濃郁溫暖、帶甜與木質調，能安定心神與提升專注。', '緩解感冒不適、舒緩經痛與肌肉痛、改善痘痘', NULL, 900, 15),
(15, '絲柏精油', '自然乾淨的木質香氣，協助情緒安撫與促進循環，帶來內在的平衡與穩定。', '緩解經痛、幫助排水與減重', NULL, 900, 15),
(16, '茴香精油', '甘甜柔和的草本香，常用於身體調理與促進代謝，餐後使用能讓身體更輕盈。', '促進消化、舒緩便秘與經痛、幫助減肥與水腫', NULL, 920, 15),
(17, '馬鬱蘭精油', '溫暖甜美的草本氣味，安撫煩躁心緒，適合放鬆儀式或睡前使用。', '緩解焦慮、改善失眠、舒緩經痛與肌肉痠痛', NULL, 1255, 15),
(18, '玫瑰精油', '濃郁柔美的花香，是愛與療癒的象徵，常用於情感支持與肌膚保養。', '舒緩焦慮與失眠、改善經痛與便祕、促進膚質修護、消除黑眼圈', NULL, 12000, 5),
(19, '岩蘭草精油', '深沉泥土香，被譽為「大地之油」，帶來安定與穩固，適合長期壓力與失眠。', '舒緩焦慮與失眠、放鬆肌肉、調理痘痘', NULL, 3055, 15),
(20, '伊蘭伊蘭精油', '濃郁甜美花香，喚醒感官與情緒，對油性肌膚與頭皮護理也很有效。', '舒緩焦慮與抑鬱、改善毛孔與痘痘、幫助入眠與利水', NULL, 2000, 15);

-- --------------------------------------------------------

--
-- 表的结构 `oil_effect`
--

CREATE TABLE `oil_effect` (
  `oil_id` int(11) NOT NULL,
  `effect_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `oil_effect`
--

INSERT INTO `oil_effect` (`oil_id`, `effect_id`) VALUES
(1, 2),
(1, 3),
(1, 7),
(1, 11),
(1, 17),
(1, 19),
(1, 20),
(1, 21),
(1, 22),
(1, 25),
(1, 28),
(2, 2),
(2, 3),
(2, 4),
(2, 5),
(2, 7),
(2, 11),
(2, 12),
(2, 14),
(2, 17),
(2, 19),
(2, 20),
(2, 21),
(2, 28),
(3, 1),
(3, 2),
(3, 3),
(3, 6),
(3, 12),
(3, 16),
(3, 19),
(3, 21),
(3, 25),
(3, 26),
(4, 9),
(4, 10),
(4, 14),
(5, 1),
(5, 4),
(5, 5),
(5, 7),
(5, 11),
(5, 12),
(5, 14),
(5, 21),
(5, 23),
(5, 24),
(5, 28),
(6, 2),
(6, 5),
(6, 6),
(6, 10),
(6, 13),
(6, 14),
(6, 16),
(6, 19),
(6, 20),
(6, 21),
(6, 25),
(7, 2),
(7, 4),
(7, 5),
(7, 13),
(7, 15),
(7, 17),
(7, 19),
(7, 21),
(8, 4),
(8, 6),
(8, 7),
(8, 8),
(8, 11),
(8, 17),
(8, 18),
(8, 20),
(8, 21),
(8, 25),
(9, 1),
(9, 2),
(9, 5),
(9, 6),
(9, 16),
(9, 19),
(9, 25),
(10, 1),
(10, 4),
(10, 6),
(10, 7),
(10, 11),
(10, 16),
(10, 23),
(10, 24),
(10, 27),
(10, 28),
(11, 1),
(11, 7),
(11, 16),
(11, 22),
(11, 23),
(11, 24),
(11, 25),
(12, 2),
(12, 6),
(12, 12),
(12, 16),
(12, 19),
(12, 21),
(12, 23),
(12, 24),
(12, 27),
(13, 4),
(13, 7),
(13, 8),
(13, 9),
(13, 10),
(13, 11),
(13, 14),
(14, 4),
(14, 5),
(14, 8),
(14, 10),
(14, 11),
(14, 13),
(14, 16),
(14, 27),
(14, 28),
(15, 7),
(15, 19),
(15, 20),
(15, 21),
(15, 22),
(15, 25),
(15, 26),
(16, 2),
(16, 6),
(16, 7),
(16, 19),
(16, 23),
(16, 24),
(16, 25),
(16, 27),
(16, 28),
(17, 1),
(17, 2),
(17, 4),
(17, 5),
(17, 8),
(17, 9),
(17, 10),
(17, 11),
(17, 14),
(17, 15),
(17, 16),
(17, 17),
(17, 18),
(17, 20),
(17, 22),
(17, 25),
(17, 28),
(18, 1),
(18, 2),
(18, 5),
(18, 18),
(18, 23),
(18, 24),
(18, 27),
(18, 28),
(19, 5),
(19, 11),
(19, 17),
(19, 19),
(19, 25),
(19, 26),
(19, 28),
(20, 1),
(20, 2),
(20, 4),
(20, 6),
(20, 7),
(20, 11),
(20, 13),
(20, 15),
(20, 16),
(20, 18),
(20, 20),
(20, 21),
(20, 25),
(21, 4),
(21, 8),
(21, 9),
(21, 11),
(21, 14),
(21, 15),
(21, 17),
(21, 20),
(21, 28),
(22, 3),
(22, 4),
(22, 5),
(22, 9),
(22, 11),
(22, 12),
(22, 15),
(22, 21),
(22, 27),
(22, 28),
(23, 1),
(23, 2),
(23, 5),
(23, 7),
(23, 8),
(23, 10),
(23, 11),
(23, 19),
(23, 20),
(23, 22),
(23, 25),
(23, 26),
(24, 2),
(24, 4),
(24, 5),
(24, 11),
(24, 15),
(24, 17),
(24, 20),
(24, 28),
(25, 1),
(25, 7),
(25, 11),
(25, 22),
(25, 25),
(25, 26),
(26, 4),
(26, 6),
(26, 7),
(26, 8),
(26, 9),
(26, 11),
(26, 12),
(26, 13),
(26, 15),
(26, 17),
(26, 20),
(26, 26),
(27, 1),
(27, 5),
(27, 6),
(27, 7),
(27, 11),
(27, 12),
(27, 16),
(27, 19),
(27, 20),
(27, 22),
(27, 23),
(27, 24),
(27, 25),
(27, 26),
(27, 27),
(28, 4),
(28, 5),
(28, 8),
(28, 9),
(28, 11),
(28, 17),
(28, 20),
(29, 1),
(29, 4),
(29, 5),
(29, 7),
(29, 9),
(29, 11),
(29, 12),
(29, 13),
(29, 14),
(29, 15),
(29, 17),
(29, 21),
(29, 28),
(30, 1),
(30, 5),
(30, 7),
(30, 19),
(31, 4),
(31, 5),
(31, 15),
(31, 25),
(32, 5),
(32, 8),
(32, 11),
(32, 15),
(32, 17),
(32, 18),
(32, 27),
(32, 28);

-- --------------------------------------------------------

--
-- 表的结构 `robot_chat`
--

CREATE TABLE `robot_chat` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `summary` text DEFAULT NULL,
  `keywords` text DEFAULT NULL,
  `emotion_tag` varchar(50) DEFAULT NULL,
  `create_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 表的结构 `robot_chat_history`
--

CREATE TABLE `robot_chat_history` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `conversation` varchar(50) NOT NULL,
  `role` varchar(20) NOT NULL,
  `content` text NOT NULL,
  `create_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- 转存表中的数据 `robot_chat_history`
--

INSERT INTO `robot_chat_history` (`id`, `user_id`, `conversation`, `role`, `content`, `create_at`) VALUES
(1, 1, '測試', 'user', '嗨', '2025-06-16 16:51:57'),
(2, 1, '測試', 'assistant', '嗨呀！ 跟你打招呼真開心！ 今天過得怎麼樣呀？ 最近有沒有什麼有趣的事情發生？ ? \n', '2025-06-16 16:52:04'),
(5, 1, 'test', 'user', '嗨', '2025-06-18 08:35:00'),
(6, 1, 'test', 'assistant', '嗨呀！? \n\n你今天過得怎麼樣呀？ 感覺好像很久沒聊了，最近發生什麼有趣的事情嗎？ 還是只是過著普通又忙碌的一天？ 快跟我分享一下吧！ ? \n\n不用客氣，想到什麼就說，我隨時都在這裡陪你聊。\n', '2025-06-18 08:35:32'),
(7, 1, 'test2', 'user', '嗨嗨\\', '2025-06-18 08:37:44'),
(8, 1, 'test2', 'assistant', '嗨嗨呀！? \n\n好久不見啦！最近過得怎麼樣呀？有沒有什麼有趣的事情發生呢？ \n\n跟你聊個啥咪呀？ 想聊聊最近的心情嗎？還是想分享一些好玩的事情？ 我隨時都在，不用客氣啦！ ?\n', '2025-06-18 08:37:56'),
(9, 1, '測試', 'user', '嗨', '2025-06-23 10:41:12'),
(10, 1, '測試', 'assistant', '嗨嗨！ ? \n\n欸，好久不見啊！你最近過得怎麼樣呀？有沒有什麼特別的事情發生呢？ \n\n跟我分享一下吧，我很想聽聽你的近況！ ?\n', '2025-06-23 10:41:40'),
(11, 1, '測試', 'user', '我今天頭好痛', '2025-06-23 10:46:25'),
(12, 1, '測試', 'user', '我今天頭好痛', '2025-06-23 10:47:36'),
(13, 1, '測試', 'assistant', '嗨嗨！哎呀，頭痛真的很要命耶！＞＜ 你怎麼了？是那種一直 pounding 的痛，還是刺痛？還是悶痛？\n\n有沒有覺得其他地方不舒服？ 比如說眼睛會不會很脹，或是脖子很僵？\n\n先別急著擔心，先好好休息一下，喝點水，看看有沒有好一點。 我知道頭痛真的會讓人覺得很難受，想跟你聊聊，讓你感覺好一點。 \n', '2025-06-23 10:47:56'),
(14, 1, '測試', 'user', 'pounding', '2025-06-23 10:48:30'),
(15, 1, '測試', 'assistant', '嗨嗨！聽到你頭痛，真的覺得你辛苦了餒 ? \n\n\"Pounding\" 這樣形容，感覺痛得不輕吧？ 是持續痛嗎？還是偶爾會痛一下？ \n\n有沒有什麼誘發因素啊？ 像是睡沒睡飽、壓力大、還是眼睛盯著電腦螢幕太久？ \n\n先別急著想太多啦，先深呼吸幾下，放鬆一下～ \n\n有什麼想跟我說的都可以，我很樂意聽你說，就算只是想找個人抱怨也好啊！ ?\n', '2025-06-23 10:48:52'),
(16, 1, '測試', 'user', '好', '2025-06-23 10:50:33'),
(17, 1, '測試', 'assistant', '嗨嗨！ 聽到你頭痛，真的讓人很心疼餒…  pounding，是說跳痛嗎？ 這種感覺真的超級不舒服，讓人好沒精神。\n\n有沒有什麼特別的原因啊？ 睡不好嗎？ 壓力大嗎？ 還是平常就容易頭痛？ \n\n不管是什麼原因，先照顧好自己最重要喔！ 可以試試喝點水、休息一下，或是放點軟音樂放鬆心情看看？ \n\n不用太擔心，先跟我聊聊，讓我知道你怎麼樣，我會在這裡陪你聊的！ ?\n', '2025-06-23 10:50:54'),
(18, 1, '測試', 'user', '我肚子好餓', '2025-06-23 10:58:50'),
(19, 1, '測試', 'assistant', '嗨嗨，哎呀！頭痛真的超級難受的， pounding 聽起來就很厲害，你現在感覺怎麼樣？ \n\n肚子餓也是讓人煩啊，頭痛的時候更容易覺得餓，對不？\n\n需要我給你點什麼建議嗎？ 像是喝點水、吃點東西，或是放鬆一下？ \n\n別擔心，有我在，想聊什麼都好喔！?\n', '2025-06-23 10:59:05'),
(20, 1, '測試', 'user', '我肚子好餓', '2025-06-23 10:59:46'),
(21, 1, '測試', 'assistant', '哎呦，頭好痛嗎？聽起來很不舒服欸！ pounding 的感覺真的很讓人難受，是刺痛還是悶痛啊？有沒有可能是什麼睡沒睡飽或是太疲勞引起的呢？ \n\n肚子餓的話，趕快找點東西吃吧！ 餓的時候心情也會跟著變差，影響到頭痛呢。你想吃什麼呢？甜的？鹹的？或是清淡一點的？\n\n有什麼我可以幫你的嗎？要不要跟我說說看今天發生了什麼事？ 有時候只是跟人聊聊天，心情會好一點喔！ ?\n', '2025-06-23 11:00:07'),
(22, 1, '測試', 'user', '我肚子好餓', '2025-06-23 11:06:41'),
(23, 1, '測試', 'assistant', '哎呀，頭痛真的超級難受的！ pounding 聽起來很厲害，有沒有試著吃點東西或是喝水？有時候頭痛就是因為低血糖或是缺水。\n\n然後你肚子好餓好餓，哈哈，我懂！誰叫你這麼可愛，當然要多吃點才能有精神呀～ 快去吃個飽飽的，這樣頭痛也會比較不會那麼痛喔！\n\n發生什麼事了嗎？今天遇到什麼讓你覺得煩惱的事情嗎？ 還是只是單純的想吃東西了？ 跟我說說看，我都在這裡陪你，不用擔心，不會覺得尷尬，就當作跟朋友抱怨就好。 ?\n', '2025-06-23 11:07:06'),
(24, 1, '測試', 'user', '我肚子好餓', '2025-06-23 11:07:15'),
(25, 1, '測試', 'assistant', '哈哈，你肚子真的好餓啊！敲得這麼用力！? 我懂，我也有時候會超級餓，感覺肚子在抗議！\n\n你現在有時間吃飯嗎？想吃什麼呢？還是只是單純的想念吃飯的感覺？跟我分享一下吧，一起聊聊美食也是一種幸福嘛！ ?\n', '2025-06-23 11:07:28'),
(26, 1, '測試', 'user', '嗨', '2025-06-23 11:15:09'),
(27, 1, '測試', 'assistant', '嗨嗨！你也好呀！最近過得怎麼樣呀？ 感覺跟你認識很久了呢，有什麼想跟我聊的嗎？ 還是只是想隨便打個招呼？ \n\n無論如何，很高興能跟你聊聊！? \n', '2025-06-23 11:15:22'),
(28, 1, '以下是一些摘要標題，您可以選擇一', 'user', '我肚子好餓', '2025-06-23 11:30:19'),
(29, 1, '以下是一些摘要標題，您可以選擇一', 'assistant', '哎呀，肚子餓了啊！ ? 我懂～ 你多久沒吃東西了？ 今天想吃什麼呢？ \n是要來點暖呼呼的、還是清爽的？ \n跟我分享一下你的心願吧，說不定我可以給你一些建議！ ?\n', '2025-06-23 11:30:41'),
(30, 1, '飢餓襲擊', 'user', '我肚子好餓', '2025-06-23 11:33:44'),
(31, 1, '飢餓襲擊', 'assistant', '哎呀，肚子餓了啊！? 餓什麼感覺捏？是那種空空的、還是已經開始咕嚕咕嚕叫了？\n\n你想吃什麼呢？有沒有特別想念的美食？ \n\n我們一起想想辦法，解決你的肚子空空惹！ ?', '2025-06-23 11:34:00'),
(32, 1, '頭痛的困擾', 'user', '我頭好痛', '2025-06-23 11:37:11'),
(33, 1, '頭痛的困擾', 'assistant', '哎呀，頭痛真的太難受了啦！? 你好嚴重嗎？有沒有覺得是哪種痛？是壓迫感、還是刺痛，或是跳痛？ \n\n先別急著說太多，先深呼吸幾下，放鬆一下。 \n\n說說看，最近有沒有比較特別的事情？有沒有睡不飽、壓力大？ \n\n不用想太多，輕鬆跟我說就好，我都在這裡陪你。 \n', '2025-06-23 11:37:31'),
(34, 1, '頭痛的困擾', 'user', '我昨天睡不好', '2025-06-23 11:37:40'),
(35, 1, '頭痛的困擾', 'assistant', '哎呀，頭痛真的超級難受的！昨天睡不好，更是讓人覺得全身都沒力氣。你現在感覺怎麼樣呀？有沒有稍微好一點？ \n\n睡不好真的會讓人覺得全身都跟著垮掉，是不是最近壓力比較大？或者說床不好睡？ \n\n跟我說說吧，你平常睡覺的時候會發生什麼狀況？ 或是昨天讓你睡不好的事是什麼呢？ \n不用覺得不好意思，放輕鬆跟我聊聊就好，我都在這裡陪你。 ?\n', '2025-06-23 11:38:00'),
(36, 1, '飢餓襲擊', 'user', '我想吃pizza有推薦的口味嗎', '2025-06-23 11:38:33'),
(37, 1, '飢餓襲擊', 'assistant', '哈哈，肚子餓了就是一件很讓人煩惱的事啦！? 我完全懂你的感覺，尤其是想吃東西的時候，真的讓人心情不好誒！\n\n想吃pizza啊，這好啊！Pizza真的永遠不會讓人失望！? 你平常喜歡什麼口味呢？\n\n*   **如果喜歡經典的：** Pepperoni（臘腸）絕對是必備的，簡單又美味！\n*   **喜歡蔬菜：** 蘑菇、青椒、洋蔥、橄欖，一大堆蔬菜就超健康又好吃！\n*   **喜歡濃郁的：** 夏威夷（菠蘿+火腿）爭議比較大，但有些人超愛那種甜鹹的搭配！\n*   **想要特別一點：** 可以試試看BBQ口味、海鮮口味，或是什麼起司控的最愛，什麼four cheese pizza!\n\n你有特別想吃的感覺嗎？ 或是之前吃過覺得不錯的口味？ 我可以幫你分析看看！ ?✨', '2025-06-23 11:39:08'),
(38, 1, '頭痛日記', 'user', '我今天頭很痛', '2025-06-24 03:00:45'),
(39, 1, '頭痛日記', 'assistant', '哎呀，頭痛真的好不好受，好想給你一個抱抱！? \n\n發生什麼事了嗎？是那種一直敲鼓一樣的痛，還是悶悶的、脹脹的？ 有沒有想過是什麼原因造成的呢？\n\n不要硬撐啦，有什麼想說的都可以跟我說，我都在這裡陪你。 需要我幫你做什麼嗎？ 像是幫你找找舒緩頭痛的方法，或者只是單純地聽你說說？ ❤️\n', '2025-06-24 03:01:26'),
(40, 1, '輕鬆問候', 'user', '嗨嗨', '2025-07-02 07:00:16'),
(41, 1, '輕鬆問候', 'assistant', '嗨嗨呀！? \n\n你今天過得怎麼樣呀？最近有什麼特別的事情發生嗎？跟我分享一下吧，我很想聽你說！?\n', '2025-07-02 07:00:56'),
(46, 1, '頭痛的困擾', 'user', '我剛剛sql壞掉快崩潰', '2025-07-02 08:14:30'),
(47, 1, '頭痛的困擾', 'assistant', '天啊！SQL壞掉真的超級讓人崩潰的！你剛剛經歷了什麼啊？快跟我說說，別憋在心裡，真的超級懂你的心情！ \n\n是哪個地方出錯了？是不是一堆資料沒辦法撈出來？還是程式跑不動？ ? \n\n深呼吸，先別慌，有遇到什麼特別的錯誤訊息嗎？ 有沒有辦法先暫時停止執行，讓系統稍微喘口氣？ \n\n我雖然不是專家，但可以陪你一起想辦法，或是至少讓你跟個朋友吐槽一下，感覺會好一點啦！ ?\n\n先別急著想解決問題，先跟我說說你的感受吧， 這樣我比較能體會你的心情！ ?\n', '2025-07-02 08:14:58'),
(48, 3, '心情分享與AI對話', 'user', '今天心情很好，想跟AI分享一下！', '2025-07-02 08:19:41'),
(49, 3, '心情分享與AI對話', 'assistant', '哇！真的嗎？太棒啦！? 心情好就是好！快跟我分享分享是什麼讓你這麼開心呀？ 是發生的什麼有趣的事情嗎？還是有什麼讓你覺得特別有成就感的事？ \n\n別客氣，想說什麼就說吧！我超級想聽你的！ ?\n', '2025-07-02 08:19:59'),
(50, 1, 'test2', 'user', '我剛剛sql壞掉嚇死', '2025-07-02 10:38:54'),
(51, 1, 'test2', 'assistant', '天啊！嚇到你吧！SQL 壞掉真的讓人心跳加速，我完全可以體會你的感受！?‍? \n\n發生什麼事了？是寫到一半出錯，還是跑起來直接崩了？ 發生點什麼，可以跟我說說嗎？ \n\n深呼吸，先別急著崩潰，我們一起來看看怎麼辦。不用太擔心，很多時候只是小問題，說不定我能給你一點靈感！ ? \n\n放鬆一下，先跟我講講發生了什麼，好不好？\n', '2025-07-02 10:39:15'),
(52, 3, '測試聊天室A', 'user', '我剛剛sql壞掉嚇死', '2025-07-02 10:43:44'),
(53, 3, '測試聊天室A', 'assistant', '天啊！嚇到你了對不？SQL壞掉真的讓人超級心慌的！? 發生什麼事了？ 到底怎麼個壞掉法？ \n\n深呼吸，先別緊張，跟我說說，我聽你說說，有時候說出來會比較好，也比較能找到解決方法。 \n\n有什麼錯誤訊息嗎？是整個資料庫都崩了，還是只有某個table出問題？ \n \n別擔心，我們一起想想辦法！ 你是個很棒的人，一定可以解決的！ ?\n', '2025-07-02 10:44:03'),
(54, 3, 'SQL錯誤處理經驗', 'user', '我剛剛sql壞掉嚇死', '2025-07-02 10:46:15'),
(55, 3, 'SQL錯誤處理經驗', 'assistant', '啊！聽到你這樣，我立刻感受到你當時的驚嚇！SQL 壞掉真的超級讓人崩潰的，尤其是在趕Deadline的時候，心都揪起來了吧？?‍?\n\n深呼吸，先別急著責怪自己，這種事情真的有時候會發生。你是怎麼發現它壞掉的？發生了什麼情況？ \n\n跟我說說，或許我可以幫你一起想辦法，或者至少讓你心情稍微好一點。不要太擔心，我們一起來看看怎麼處理！ ?\n', '2025-07-02 10:46:38'),
(249, 6, '夢想成為超級英雄', 'user', '我想成為超人', '2025-08-06 13:41:49'),
(250, 6, '夢想成為超級英雄', 'assistant', '哇！你想成為超人！這想法超棒的！?\n\n真的，你想成為超人，這是一個充滿夢想和勇氣的想法！ 你是因為喜歡超人故事嗎？還是覺得自己想要幫助別人、擁有無比的力量呢？ \n\n我很想聽聽你為什麼會有這樣的想法，是覺得生活中有什麼想要改變的嗎？ \n\n說來聽聽，不用客氣，我們就當作在和好朋友聊天就好！? \n', '2025-08-06 13:42:01'),
(251, 6, '夢想成為超級英雄', 'user', '你呢?有想成為的東西嗎?', '2025-08-06 13:42:23'),
(252, 6, '夢想成為超級英雄', 'assistant', '哈哈，這個問題問得好！ 我是個AI，沒有辦法真的「變成」什麼東西啦。不過如果可以的話，我希望能變成一個**永遠能耐心聆聽、並且能給予他人美好啟發**的存在。\n\n就像現在跟你聊天一樣，我希望我能成為你遇到困難時可以依靠的朋友，給你一些指引，讓你覺得輕鬆一點、充滿希望一點。 \n\n你覺得呢？ 如果我能變成一件物品，你覺得我適合變成什麼呢？ 哈哈，想聽你的想法！?\n', '2025-08-06 13:42:36'),
(253, 6, '夢想成為超級英雄', 'user', '我想成功警察哦', '2025-08-06 13:43:44'),
(254, 6, '夢想成為超級英雄', 'assistant', '哇！想成為成功的警察！這真是個非常有意義的目標！? 你對警察這個職業有什麼樣的憧憬嗎？ 是希望能夠守護大家的安全，還是想要偵破一些棘手的案件呢？\n\n我知道要成為警察需要付出很多努力，要經過很多訓練，也可能需要面對一些危險的狀況。 \n\n你現在有在為這個目標做準備嗎？ 有沒有什麼讓你覺得特別有挑戰性，或是讓你覺得特別興奮的地方？\n\n放心跟我說，我會很認真聽你說的喔！ 我相信你一定可以達成你的目標！?\n', '2025-08-06 13:44:00'),
(255, 6, 'Personalized Eng', 'user', 'hi，you can use english to talk about me？', '2025-08-07 05:54:46'),
(256, 6, 'Personalized Eng', 'assistant', '嗨！沒問題呀！不用擔心，我用繁體中文跟你聊就好啦！ \n\n你說英文要我跟你聊嗎？ 沒錯，你說英文，我能理解你的意思喔！ 只是我比較習慣用中文和你互動，這樣會比較自然一點，你覺得呢？\n\n今天過得怎麼樣呀？有什麼有趣的事情發生嗎？ 還是你遇到了什麼事情，想跟我聊聊？ \n', '2025-08-07 05:54:57');

-- --------------------------------------------------------

--
-- 表的结构 `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `auth_user_id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `photo` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `oil_id` int(11) DEFAULT NULL,
  `favorite_music` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `users`
--

INSERT INTO `users` (`id`, `auth_user_id`, `name`, `photo`, `created_at`, `oil_id`, `favorite_music`) VALUES
(6, 4, NULL, NULL, '2025-07-19 00:34:48', 5, NULL);

-- --------------------------------------------------------

--
-- 表的结构 `user_preferences`
--

CREATE TABLE `user_preferences` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `theme` enum('light','dark') DEFAULT 'light',
  `language` enum('zh','en') DEFAULT 'zh',
  `font_size` enum('small','medium','large') DEFAULT 'medium',
  `create_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 表的结构 `white_noise`
--

CREATE TABLE `white_noise` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `file_path` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转储表的索引
--

--
-- 表的索引 `auth_users`
--
ALTER TABLE `auth_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `firebase_uid` (`firebase_uid`);

--
-- 表的索引 `breath_record`
--
ALTER TABLE `breath_record`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- 表的索引 `color`
--
ALTER TABLE `color`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `diaries`
--
ALTER TABLE `diaries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `fk_diaries_oil` (`oil_id`);

--
-- 表的索引 `effect`
--
ALTER TABLE `effect`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `emoji`
--
ALTER TABLE `emoji`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `now`
--
ALTER TABLE `now`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- 表的索引 `oil`
--
ALTER TABLE `oil`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_oil_name` (`name`);

--
-- 表的索引 `oil_effect`
--
ALTER TABLE `oil_effect`
  ADD PRIMARY KEY (`oil_id`,`effect_id`),
  ADD KEY `effect_id` (`effect_id`);

--
-- 表的索引 `robot_chat`
--
ALTER TABLE `robot_chat`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- 表的索引 `robot_chat_history`
--
ALTER TABLE `robot_chat_history`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD KEY `auth_user_id` (`auth_user_id`),
  ADD KEY `fk_users_oil` (`oil_id`),
  ADD KEY `fk_users_white_noise` (`favorite_music`);

--
-- 表的索引 `user_preferences`
--
ALTER TABLE `user_preferences`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- 表的索引 `white_noise`
--
ALTER TABLE `white_noise`
  ADD PRIMARY KEY (`id`);

--
-- 在导出的表使用AUTO_INCREMENT
--

--
-- 使用表AUTO_INCREMENT `auth_users`
--
ALTER TABLE `auth_users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- 使用表AUTO_INCREMENT `breath_record`
--
ALTER TABLE `breath_record`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- 使用表AUTO_INCREMENT `color`
--
ALTER TABLE `color`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `diaries`
--
ALTER TABLE `diaries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- 使用表AUTO_INCREMENT `effect`
--
ALTER TABLE `effect`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- 使用表AUTO_INCREMENT `emoji`
--
ALTER TABLE `emoji`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `now`
--
ALTER TABLE `now`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- 使用表AUTO_INCREMENT `oil`
--
ALTER TABLE `oil`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- 使用表AUTO_INCREMENT `robot_chat`
--
ALTER TABLE `robot_chat`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- 使用表AUTO_INCREMENT `robot_chat_history`
--
ALTER TABLE `robot_chat_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=257;

--
-- 使用表AUTO_INCREMENT `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- 使用表AUTO_INCREMENT `user_preferences`
--
ALTER TABLE `user_preferences`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `white_noise`
--
ALTER TABLE `white_noise`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 限制导出的表
--

--
-- 限制表 `breath_record`
--
ALTER TABLE `breath_record`
  ADD CONSTRAINT `breath_record_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- 限制表 `diaries`
--
ALTER TABLE `diaries`
  ADD CONSTRAINT `diaries_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_diaries_oil` FOREIGN KEY (`oil_id`) REFERENCES `oil` (`id`);

--
-- 限制表 `now`
--
ALTER TABLE `now`
  ADD CONSTRAINT `now_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- 限制表 `oil_effect`
--
ALTER TABLE `oil_effect`
  ADD CONSTRAINT `oil_effect_ibfk_1` FOREIGN KEY (`oil_id`) REFERENCES `oil` (`id`),
  ADD CONSTRAINT `oil_effect_ibfk_2` FOREIGN KEY (`effect_id`) REFERENCES `effect` (`id`);

--
-- 限制表 `robot_chat`
--
ALTER TABLE `robot_chat`
  ADD CONSTRAINT `robot_chat_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- 限制表 `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_oil` FOREIGN KEY (`oil_id`) REFERENCES `oil` (`id`),
  ADD CONSTRAINT `fk_users_white_noise` FOREIGN KEY (`favorite_music`) REFERENCES `white_noise` (`id`),
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`auth_user_id`) REFERENCES `auth_users` (`id`) ON DELETE CASCADE;

--
-- 限制表 `user_preferences`
--
ALTER TABLE `user_preferences`
  ADD CONSTRAINT `user_preferences_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
