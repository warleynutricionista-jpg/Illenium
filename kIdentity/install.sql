CREATE TABLE IF NOT EXISTS `player_identity` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `license` VARCHAR(100) NOT NULL,
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL,
    `dateofbirth` DATE DEFAULT NULL,
    `nationality` INT(11) DEFAULT 0,
    `gender` VARCHAR(10) DEFAULT 'male',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
