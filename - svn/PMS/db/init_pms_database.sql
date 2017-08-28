/*
connected to localhost as root
*/
GRANT ALL ON *.* TO root;

DROP database IF EXISTS pms_development;
DROP database IF EXISTS pms_test;
DROP database IF EXISTS pms_production;
CREATE DATABASE pms_development;
CREATE DATABASE pms_test;
CREATE DATABASE pms_production;
ALTER DATABASE `pms_development` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER DATABASE `pms_test` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER DATABASE `pms_production` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

GRANT ALL ON pms_development.* TO 'pmsuser'@'192.168.%' IDENTIFIED BY 'fed118';
GRANT ALL ON pms_test.* TO 'pmsuser'@'192.168.%' IDENTIFIED BY 'fed118';
GRANT ALL ON pms_production.* TO 'pmsuser'@'192.168.%' IDENTIFIED BY 'fed118';

GRANT ALL ON pms_development.* TO 'pmsuser'@'localhost' IDENTIFIED BY 'fed118';
GRANT ALL ON pms_test.* TO 'pmsuser'@'localhost' IDENTIFIED BY 'fed118';
GRANT ALL ON pms_production.* TO 'pmsuser'@'localhost' IDENTIFIED BY 'fed118';
