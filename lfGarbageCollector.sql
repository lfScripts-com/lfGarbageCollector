CREATE TABLE `garbage_zones` (
  `identifier` varchar(60) NOT NULL,
  `zone` int(11) NOT NULL,
  `last_done` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

ALTER TABLE `garbage_zones`
  ADD PRIMARY KEY (`identifier`,`zone`);