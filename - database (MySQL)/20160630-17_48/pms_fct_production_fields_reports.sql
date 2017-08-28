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
-- Table structure for table `fields_reports`
--

DROP TABLE IF EXISTS `fields_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fields_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `field_id` int(11) NOT NULL,
  `report_id` int(11) NOT NULL,
  `seq_no` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `summarize` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `field_format` text,
  `reference_screen_index` int(11) DEFAULT NULL,
  `chart_axis_index` int(11) DEFAULT NULL,
  `label_id` int(11) DEFAULT NULL,
  `sorting_index` int(11) DEFAULT NULL,
  `percentage_weight` text,
  `field_type` varchar(255) DEFAULT NULL,
  `formula` text,
  PRIMARY KEY (`id`),
  KEY `IX_fields_reports_field_id` (`field_id`),
  KEY `IX_fields_reports_report_id` (`report_id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fields_reports`
--

LOCK TABLES `fields_reports` WRITE;
/*!40000 ALTER TABLE `fields_reports` DISABLE KEYS */;
INSERT INTO `fields_reports` VALUES (19,174,13,0,'2013-10-01 04:30:33','2013-10-01 04:31:10','grp','row',NULL,0,NULL,NULL,NULL,'--- !map:HashWithIndifferentAccess \n\"-1\": \"false\"\n','field',''),(20,175,13,1,'2013-10-01 04:30:33','2013-10-01 04:31:10','grp','row',NULL,0,NULL,NULL,NULL,'--- !map:HashWithIndifferentAccess \n\"-1\": \"false\"\n','field',''),(21,174,13,2,'2013-10-01 04:31:10','2013-10-01 04:31:36','cnt','row',NULL,0,NULL,NULL,2,'--- !map:HashWithIndifferentAccess \n\"-1\": \"false\"\n','field',''),(22,54,14,0,'2013-10-01 10:50:46','2013-10-01 12:08:04','non','row',NULL,0,NULL,NULL,NULL,'--- !map:HashWithIndifferentAccess \n\"-1\": \"false\"\n','field',''),(23,204,14,5,'2013-10-01 10:50:46','2013-10-01 12:08:04','cnt','row',NULL,2,NULL,NULL,NULL,'--- !map:HashWithIndifferentAccess \n\"-1\": \"false\"\n','field',''),(24,216,14,6,'2013-10-01 10:50:46','2013-10-01 12:08:04','sum','row',NULL,2,NULL,NULL,0,'--- !map:HashWithIndifferentAccess \n\"-1\": \"false\"\n','field',''),(25,155,14,1,'2013-10-01 11:41:14','2013-10-01 12:08:04','non','row',NULL,0,NULL,NULL,NULL,'--- !map:HashWithIndifferentAccess \n\"-1\": \"false\"\n','field',''),(26,220,14,2,'2013-10-01 11:41:14','2013-10-01 12:08:04','non','row',NULL,0,NULL,NULL,NULL,'--- !map:HashWithIndifferentAccess \n\"-1\": \"false\"\n','field','');
/*!40000 ALTER TABLE `fields_reports` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-06-30 17:47:23
