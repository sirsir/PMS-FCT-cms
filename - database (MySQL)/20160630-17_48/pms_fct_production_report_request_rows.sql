-- MySQL dump 10.13  Distrib 5.6.24, for Win64 (x86_64)
--
-- Host: 192.168.1.3    Database: pms_fct_production
-- ------------------------------------------------------
-- Server version	5.1.73

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `report_request_rows`
--

DROP TABLE IF EXISTS `report_request_rows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `report_request_rows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_request_row_id` int(11) DEFAULT NULL,
  `row_id` int(11) DEFAULT NULL,
  `report_request_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `reference_screen_index` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `IX_report_request_rows_report_request_id` (`report_request_id`),
  KEY `IX_report_request_rows_report_request_row_id` (`report_request_row_id`),
  KEY `IX_report_request_rows_row_id` (`row_id`)
) ENGINE=InnoDB AUTO_INCREMENT=147 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `report_request_rows`
--

LOCK TABLES `report_request_rows` WRITE;
/*!40000 ALTER TABLE `report_request_rows` DISABLE KEYS */;
INSERT INTO `report_request_rows` VALUES (80,NULL,144,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(81,NULL,175,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(82,NULL,179,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(83,NULL,180,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(84,NULL,181,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(85,NULL,182,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(86,NULL,183,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(87,NULL,185,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(88,NULL,186,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(89,NULL,187,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(90,NULL,188,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(91,NULL,205,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(92,NULL,206,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(93,NULL,207,6,'2013-10-01 04:34:48','2013-10-01 04:34:48',0),(124,NULL,0,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',0),(125,124,-1,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(126,125,134,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(127,125,176,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(128,124,197,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(129,128,-2,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(130,124,201,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(131,130,-2,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(132,124,202,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(133,132,-2,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(134,124,203,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(135,134,-2,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(136,124,204,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(137,136,-2,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(138,NULL,131,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',0),(139,138,-1,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(140,139,-2,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(141,NULL,155,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',0),(142,141,-1,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(143,142,-2,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2),(144,NULL,193,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',0),(145,144,-1,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',1),(146,145,-2,7,'2013-10-01 12:08:47','2013-10-01 12:08:47',2);
/*!40000 ALTER TABLE `report_request_rows` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-06-30 17:47:25
