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
-- Table structure for table `reports`
--

DROP TABLE IF EXISTS `reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `descr` varchar(255) DEFAULT NULL,
  `reference_screen_ids` text,
  `criterias` text,
  `reference_screen_alias` text,
  `remark` varchar(255) DEFAULT NULL,
  `reference_screen_outer_joins` text,
  `grand_total` varchar(255) DEFAULT NULL,
  `cell_location` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `IX_reports_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reports`
--

LOCK TABLES `reports` WRITE;
/*!40000 ALTER TABLE `reports` DISABLE KEYS */;
INSERT INTO `reports` VALUES (13,'Quotation Detail History','2013-10-01 04:28:25','2013-10-01 04:29:13','','--- \n- \"1073\"\n- \"-1\"\n','--- []\n\n','--- \n- qd\n','','--- \n- !map:HashWithIndifferentAccess \n  \"-1\": \"false\"\n','--- \n- \"-1\"\n','col'),(14,'Cust Quotation Summary','2013-10-01 08:34:49','2013-10-01 12:03:15','','--- \n- \"1053\"\n- \"1055\"\n- \"1056\"\n- \"-1\"\n','--- \n- !map:HashWithIndifferentAccess \n  b_field_id: 66\n  b_screen_index: 1\n  a_field_id: -1\n  a_screen_index: 0\n  operation: ==\n- !map:HashWithIndifferentAccess \n  b_field_id: 81\n  b_screen_index: 2\n  a_field_id: -1\n  a_screen_index: 1\n  operation: ==\n','--- \n- c\n- p\n- q\n','','--- \n- !map:HashWithIndifferentAccess \n  \"-1\": \"false\"\n  \"0\": \"true\"\n- !map:HashWithIndifferentAccess \n  \"-1\": \"false\"\n  \"0\": \"true\"\n- !map:HashWithIndifferentAccess \n  \"-1\": \"false\"\n  \"0\": \"true\"\n','--- \n- row\n- \"-1\"\n','col');
/*!40000 ALTER TABLE `reports` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-06-30 17:47:29
