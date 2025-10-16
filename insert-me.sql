
CREATE TABLE IF NOT EXISTS `codem_new_inventory` (
  `identifier` char(50) DEFAULT NULL,
  `inventory` longtext DEFAULT NULL,
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;


CREATE TABLE IF NOT EXISTS `codem_new_stash` (
  `stashname` char(50) DEFAULT NULL,
  `inventory` longtext DEFAULT NULL,
  UNIQUE KEY `stashname` (`stashname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS `codem_new_vehicleandglovebox` (
  `plate` char(50) DEFAULT NULL,
  `trunk` longtext DEFAULT NULL,
  `glovebox` longtext DEFAULT NULL,
  UNIQUE KEY `plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS `codem_new_clothingsitem` (
  `identifier` char(50) DEFAULT NULL,
  `inventory` longtext DEFAULT NULL,
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
