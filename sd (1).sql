-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- 主机： 127.0.0.1
-- 生成日期： 2025-07-02 19:43:36
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
(1, NULL, NULL, NULL, 0, NULL, 0, '2025-07-02 15:08:42', NULL),
(2, NULL, NULL, NULL, 0, NULL, 0, '2025-07-03 00:42:51', 'Sm5RG6yzcgTaQeseduqwSD6o5bo1');

-- --------------------------------------------------------

--
-- 表的结构 `breath_record`
--

CREATE TABLE `breath_record` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `duration` int(11) DEFAULT NULL,
  `min` int(11) NOT NULL,
  `felling` varchar(200) DEFAULT NULL,
  `create_at` datetime DEFAULT current_timestamp(),
  `type` enum('正常','引導') NOT NULL DEFAULT '引導'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `breath_record`
--

INSERT INTO `breath_record` (`id`, `user_id`, `duration`, `min`, `felling`, `create_at`, `type`) VALUES
(1, 4, 5, 5, NULL, '2025-07-03 00:43:12', '引導'),
(2, 4, 5, 5, '哈', '2025-07-03 00:43:19', '引導');

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
  `color_mix` char(7) DEFAULT NULL,
  `create_at` datetime DEFAULT current_timestamp(),
  `oil_id` int(11) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `is_english` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `diaries`
--

INSERT INTO `diaries` (`id`, `user_id`, `content`, `joy`, `sadness`, `anger`, `positive`, `anxiety`, `exhaust`, `color_mix`, `create_at`, `oil_id`, `details`, `is_english`) VALUES
(1, 4, '很煩啊', 0, 0, 0, 0, 51.852, 0, '#4F8000', '2025-07-03 01:13:18', NULL, '', 0),
(2, 4, '可惡啊', 0, 0, 60.0644, 0, 0, 0, '#5CFF00', '2025-07-03 01:40:55', NULL, '真的煩', 0);

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
(1, 4, 0, 0, 0, 0, 80.6143, 0, '啊啊啊啊', '2025-07-03 01:40:32', '', 0);

-- --------------------------------------------------------

--
-- 表的结构 `oil`
--

CREATE TABLE `oil` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `meaning` text DEFAULT NULL,
  `effect` text DEFAULT NULL,
  `image_url` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 转存表中的数据 `oil`
--

INSERT INTO `oil` (`id`, `name`, `meaning`, `effect`, `image_url`) VALUES
(1, '羅勒', NULL, NULL, NULL),
(2, '佛手柑', NULL, NULL, NULL),
(3, '黑胡椒', NULL, NULL, NULL),
(4, '胡蘿蔔種籽', NULL, NULL, NULL),
(5, '雪松', NULL, NULL, NULL),
(6, '德國洋甘菊', NULL, NULL, NULL),
(7, '羅馬洋甘菊', NULL, NULL, NULL),
(8, '快樂鼠尾草', NULL, NULL, NULL),
(9, '丁香', NULL, NULL, NULL),
(10, '絲柏', NULL, NULL, NULL),
(11, '尤加利', NULL, NULL, NULL),
(12, '茴香', NULL, NULL, NULL),
(13, '乳香', NULL, NULL, NULL),
(14, '天竺葵', NULL, NULL, NULL),
(15, '薑', NULL, NULL, NULL),
(16, '杜松子', NULL, NULL, NULL),
(17, '薰衣草', NULL, NULL, NULL),
(18, '檸檬', NULL, NULL, NULL),
(19, '檸檬草', NULL, NULL, NULL),
(20, '馬鬱蘭', NULL, NULL, NULL),
(21, '橙花', NULL, NULL, NULL),
(22, '甜橙', NULL, NULL, NULL),
(23, '歐薄荷', NULL, NULL, NULL),
(24, '回青橙', NULL, NULL, NULL),
(25, '松', NULL, NULL, NULL),
(26, '玫瑰', NULL, NULL, NULL),
(27, '迷迭香', NULL, NULL, NULL),
(28, '花梨木', NULL, NULL, NULL),
(29, '檀香', NULL, NULL, NULL),
(30, '茶樹', NULL, NULL, NULL),
(31, '岩蘭草', NULL, NULL, NULL),
(32, '伊蘭伊蘭', NULL, NULL, NULL);

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

--
-- 转存表中的数据 `robot_chat`
--

INSERT INTO `robot_chat` (`id`, `user_id`, `summary`, `keywords`, `emotion_tag`, `create_at`) VALUES
(4, 3, '對方表達了積極的心情，並希望與AI分享感受。', '', '', '2025-07-02 16:21:19');

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
(3, 1, 'default', 'user', '嗨', '2025-06-16 16:53:04'),
(4, 1, 'default', 'assistant', '嗨嗨！ ? 你好呀！最近過得怎麼樣呀？ 感覺你好像心情不錯，是發生什麼好事了嗎？ 還是只是單純的好好的一個平凡日子？ 跟我分享一下吧！ ?\n', '2025-06-16 16:53:15'),
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
(42, 3, 'default', 'user', '哈囉 Bruno!', '2025-07-02 07:26:52'),
(43, 3, 'default', 'assistant', '哈囉！嗨嗨！妳好呀！? \n\n好久不見，最近過得怎麼樣呀？ 感覺好久沒聊了，有沒有什麼有趣的事情可以跟我分享？ 輕鬆一點啦，就當我們是好朋友在閒聊這樣！ \n\n想聊什麼都可以喔！ \n', '2025-07-02 07:27:05'),
(44, 3, 'default', 'user', '我剛剛sql壞掉快崩潰', '2025-07-02 07:39:29'),
(45, 3, 'default', 'assistant', '哈囉呀！ ? 哇！SQL 壞掉真的太讓人崩潰了吧！發生什麼事了？聽起來超級令人沮喪的！ \n\n深呼吸一下，先別急著慌。可以跟我稍微說說怎麼壞掉的嗎？ 就算不知道具體原因也沒關係，只是想聽聽你的狀況就好。\n\n我知道這種時候真的很想找個人吐槽一下，或是想找人一起焦慮，我都在這裡陪你啊！ ? \n', '2025-07-02 07:39:49'),
(46, 1, '頭痛的困擾', 'user', '我剛剛sql壞掉快崩潰', '2025-07-02 08:14:30'),
(47, 1, '頭痛的困擾', 'assistant', '天啊！SQL壞掉真的超級讓人崩潰的！你剛剛經歷了什麼啊？快跟我說說，別憋在心裡，真的超級懂你的心情！ \n\n是哪個地方出錯了？是不是一堆資料沒辦法撈出來？還是程式跑不動？ ? \n\n深呼吸，先別慌，有遇到什麼特別的錯誤訊息嗎？ 有沒有辦法先暫時停止執行，讓系統稍微喘口氣？ \n\n我雖然不是專家，但可以陪你一起想辦法，或是至少讓你跟個朋友吐槽一下，感覺會好一點啦！ ?\n\n先別急著想解決問題，先跟我說說你的感受吧， 這樣我比較能體會你的心情！ ?\n', '2025-07-02 08:14:58'),
(48, 3, '心情分享與AI對話', 'user', '今天心情很好，想跟AI分享一下！', '2025-07-02 08:19:41'),
(49, 3, '心情分享與AI對話', 'assistant', '哇！真的嗎？太棒啦！? 心情好就是好！快跟我分享分享是什麼讓你這麼開心呀？ 是發生的什麼有趣的事情嗎？還是有什麼讓你覺得特別有成就感的事？ \n\n別客氣，想說什麼就說吧！我超級想聽你的！ ?\n', '2025-07-02 08:19:59'),
(50, 1, 'test2', 'user', '我剛剛sql壞掉嚇死', '2025-07-02 10:38:54'),
(51, 1, 'test2', 'assistant', '天啊！嚇到你吧！SQL 壞掉真的讓人心跳加速，我完全可以體會你的感受！?‍? \n\n發生什麼事了？是寫到一半出錯，還是跑起來直接崩了？ 發生點什麼，可以跟我說說嗎？ \n\n深呼吸，先別急著崩潰，我們一起來看看怎麼辦。不用太擔心，很多時候只是小問題，說不定我能給你一點靈感！ ? \n\n放鬆一下，先跟我講講發生了什麼，好不好？\n', '2025-07-02 10:39:15'),
(52, 3, '測試聊天室A', 'user', '我剛剛sql壞掉嚇死', '2025-07-02 10:43:44'),
(53, 3, '測試聊天室A', 'assistant', '天啊！嚇到你了對不？SQL壞掉真的讓人超級心慌的！? 發生什麼事了？ 到底怎麼個壞掉法？ \n\n深呼吸，先別緊張，跟我說說，我聽你說說，有時候說出來會比較好，也比較能找到解決方法。 \n\n有什麼錯誤訊息嗎？是整個資料庫都崩了，還是只有某個table出問題？ \n \n別擔心，我們一起想想辦法！ 你是個很棒的人，一定可以解決的！ ?\n', '2025-07-02 10:44:03'),
(54, 3, 'SQL錯誤處理經驗', 'user', '我剛剛sql壞掉嚇死', '2025-07-02 10:46:15'),
(55, 3, 'SQL錯誤處理經驗', 'assistant', '啊！聽到你這樣，我立刻感受到你當時的驚嚇！SQL 壞掉真的超級讓人崩潰的，尤其是在趕Deadline的時候，心都揪起來了吧？?‍?\n\n深呼吸，先別急著責怪自己，這種事情真的有時候會發生。你是怎麼發現它壞掉的？發生了什麼情況？ \n\n跟我說說，或許我可以幫你一起想辦法，或者至少讓你心情稍微好一點。不要太擔心，我們一起來看看怎麼處理！ ?\n', '2025-07-02 10:46:38');

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
(3, 1, '測試帳號', NULL, '2025-07-02 15:08:57', NULL, NULL),
(4, 2, NULL, NULL, '2025-07-03 00:42:51', NULL, NULL);

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
  ADD PRIMARY KEY (`id`);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- 使用表AUTO_INCREMENT `breath_record`
--
ALTER TABLE `breath_record`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- 使用表AUTO_INCREMENT `color`
--
ALTER TABLE `color`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `diaries`
--
ALTER TABLE `diaries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- 使用表AUTO_INCREMENT `oil`
--
ALTER TABLE `oil`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- 使用表AUTO_INCREMENT `robot_chat`
--
ALTER TABLE `robot_chat`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- 使用表AUTO_INCREMENT `robot_chat_history`
--
ALTER TABLE `robot_chat_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=56;

--
-- 使用表AUTO_INCREMENT `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

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
