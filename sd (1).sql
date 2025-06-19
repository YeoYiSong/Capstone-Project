-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- 主機： 127.0.0.1
-- 產生時間： 2025-06-16 05:40:48
-- 伺服器版本： 10.4.32-MariaDB
-- PHP 版本： 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- 資料庫： `sd`
--

-- --------------------------------------------------------

--
-- 資料表結構 `auth_users`
--

CREATE TABLE `auth_users` (
  `id` int(11) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `password` text DEFAULT NULL,
  `google_id` varchar(100) DEFAULT NULL,
  `google_bound` tinyint(1) DEFAULT 0,
  `apple_id` varchar(100) DEFAULT NULL,
  `apple_bound` tinyint(1) DEFAULT 0,
  `create_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 資料表結構 `breath_record`
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

-- --------------------------------------------------------

--
-- 資料表結構 `color`
--

CREATE TABLE `color` (
  `id` int(11) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `hex_code` char(7) DEFAULT NULL,
  `emotion_tag` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 資料表結構 `diaries`
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
  `oil_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 資料表結構 `emoji`
--

CREATE TABLE `emoji` (
  `id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `image_url` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 資料表結構 `now`
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
  `create_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 資料表結構 `oil`
--

CREATE TABLE `oil` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `meaning` text DEFAULT NULL,
  `effect` text DEFAULT NULL,
  `image_url` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 資料表結構 `robot_chat`
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
-- 資料表結構 `users`
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

-- --------------------------------------------------------

--
-- 資料表結構 `user_preferences`
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
-- 資料表結構 `white_noise`
--

CREATE TABLE `white_noise` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `file_path` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- 已傾印資料表的索引
--

--
-- 資料表索引 `auth_users`
--
ALTER TABLE `auth_users`
  ADD PRIMARY KEY (`id`);

--
-- 資料表索引 `breath_record`
--
ALTER TABLE `breath_record`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- 資料表索引 `color`
--
ALTER TABLE `color`
  ADD PRIMARY KEY (`id`);

--
-- 資料表索引 `diaries`
--
ALTER TABLE `diaries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `fk_diaries_oil` (`oil_id`);

--
-- 資料表索引 `emoji`
--
ALTER TABLE `emoji`
  ADD PRIMARY KEY (`id`);

--
-- 資料表索引 `now`
--
ALTER TABLE `now`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- 資料表索引 `oil`
--
ALTER TABLE `oil`
  ADD PRIMARY KEY (`id`);

--
-- 資料表索引 `robot_chat`
--
ALTER TABLE `robot_chat`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- 資料表索引 `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD KEY `auth_user_id` (`auth_user_id`),
  ADD KEY `fk_users_oil` (`oil_id`),
  ADD KEY `fk_users_white_noise` (`favorite_music`);

--
-- 資料表索引 `user_preferences`
--
ALTER TABLE `user_preferences`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- 資料表索引 `white_noise`
--
ALTER TABLE `white_noise`
  ADD PRIMARY KEY (`id`);

--
-- 在傾印的資料表使用自動遞增(AUTO_INCREMENT)
--

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `auth_users`
--
ALTER TABLE `auth_users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `breath_record`
--
ALTER TABLE `breath_record`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `color`
--
ALTER TABLE `color`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `diaries`
--
ALTER TABLE `diaries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `emoji`
--
ALTER TABLE `emoji`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `now`
--
ALTER TABLE `now`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `oil`
--
ALTER TABLE `oil`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `robot_chat`
--
ALTER TABLE `robot_chat`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `user_preferences`
--
ALTER TABLE `user_preferences`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `white_noise`
--
ALTER TABLE `white_noise`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 已傾印資料表的限制式
--

--
-- 資料表的限制式 `breath_record`
--
ALTER TABLE `breath_record`
  ADD CONSTRAINT `breath_record_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- 資料表的限制式 `diaries`
--
ALTER TABLE `diaries`
  ADD CONSTRAINT `diaries_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_diaries_oil` FOREIGN KEY (`oil_id`) REFERENCES `oil` (`id`);

--
-- 資料表的限制式 `now`
--
ALTER TABLE `now`
  ADD CONSTRAINT `now_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- 資料表的限制式 `robot_chat`
--
ALTER TABLE `robot_chat`
  ADD CONSTRAINT `robot_chat_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- 資料表的限制式 `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_oil` FOREIGN KEY (`oil_id`) REFERENCES `oil` (`id`),
  ADD CONSTRAINT `fk_users_white_noise` FOREIGN KEY (`favorite_music`) REFERENCES `white_noise` (`id`),
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`auth_user_id`) REFERENCES `auth_users` (`id`) ON DELETE CASCADE;

--
-- 資料表的限制式 `user_preferences`
--
ALTER TABLE `user_preferences`
  ADD CONSTRAINT `user_preferences_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
