-- MySQL dump 10.13  Distrib 5.6.24, for Win64 (x86_64)
--
-- Host: 192.168.1.3    Database: pms_fct_development
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
-- Table structure for table `screens`
--

DROP TABLE IF EXISTS `screens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `screens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `screen_id` int(11) DEFAULT NULL,
  `label_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `system` int(11) DEFAULT NULL,
  `display_seq` int(11) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `controller` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `alias_screen` int(11) DEFAULT NULL,
  `relate_screen` int(11) DEFAULT NULL,
  `value` text,
  `icon` varchar(255) DEFAULT NULL,
  `page_size` varchar(255) DEFAULT 'A4',
  `page_layout` varchar(255) DEFAULT 'portrait',
  PRIMARY KEY (`id`),
  KEY `IX_screens_action_controller` (`action`,`controller`),
  KEY `IX_screens_name` (`name`),
  KEY `IX_screens_screen_id` (`screen_id`),
  KEY `IX_screens_system` (`system`),
  KEY `IX_screens_type` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=1099 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `screens`
--

LOCK TABLES `screens` WRITE;
/*!40000 ALTER TABLE `screens` DISABLE KEYS */;
INSERT INTO `screens` VALUES (1,'Setting',8,9,'2008-12-22 07:17:52','2008-12-22 09:55:12',1,4,'setting','front_desk','MenuGroupScreen',NULL,NULL,NULL,NULL,'A4','portrait'),(4,'Reports',8,12,'2008-12-22 07:21:47','2008-12-30 07:20:34',1,2,'report','front_desk','MenuGroupScreen',NULL,NULL,NULL,NULL,'A4','portrait'),(6,'Preference',8,14,'2008-12-22 07:24:55','2008-12-22 07:24:55',1,3,'preference','front_desk','MenuGroupScreen',NULL,NULL,NULL,NULL,'A4','portrait'),(7,'Security',8,15,'2008-12-22 07:25:45','2008-12-22 07:25:45',1,5,'security','front_desk','MenuGroupScreen',NULL,NULL,NULL,NULL,'A4','portrait'),(8,'root',NULL,NULL,'2008-12-22 08:41:35','2008-12-22 08:41:35',1,0,'index','front_desk','MenuGroupScreen',NULL,NULL,NULL,NULL,'A4','portrait'),(11,'languages',1,18,NULL,NULL,1,1,'index','languages','ListScreen',NULL,NULL,NULL,'system','A4','portrait'),(12,'labels',1,19,NULL,NULL,1,2,'index','labels','ListScreen',NULL,NULL,NULL,'system','A4','portrait'),(15,'screens',1,22,NULL,NULL,1,5,'index','screens','ListScreen',NULL,NULL,NULL,'system','A4','portrait'),(18,'users',7,25,NULL,NULL,1,4,'index','users','ListScreen',NULL,NULL,NULL,'user','A4','portrait'),(21,'User Information',6,28,NULL,NULL,1,3,'edit','users','Screen',NULL,NULL,NULL,'options','A4','portrait'),(35,'custom_fields',1,34,NULL,NULL,1,4,'index','custom_fields','ListScreen',NULL,NULL,NULL,'system','A4','portrait'),(36,'Permissions',7,300,NULL,NULL,1,1,'permission','front_desk','MenuGroupScreen',NULL,NULL,NULL,'permission','A4','portrait'),(37,'screens',8,22,NULL,NULL,1,1,'screen','front_desk','MenuGroupScreen',NULL,NULL,NULL,NULL,'A4','portrait'),(142,'Role',7,294,NULL,NULL,1,5,'index','roles','ListScreen',NULL,NULL,NULL,'role','A4','portrait'),(147,'Report',1,12,'2009-09-17 14:52:39','2009-09-24 08:08:21',1,7,'index','reports','HeaderScreen',NULL,NULL,NULL,'system','A4','portrait'),(148,'Role Screen',36,301,NULL,NULL,1,1,'index_role_screen','permissions','ListScreen',NULL,NULL,NULL,'permission','A4','portrait'),(149,'Role Field',36,302,NULL,NULL,1,2,'index_role_field','permissions','ListScreen',NULL,NULL,NULL,'permission','A4','portrait'),(150,'User Screen',36,303,NULL,NULL,1,3,'index_user_screen','permissions','ListScreen',NULL,NULL,NULL,'permission','A4','portrait'),(151,'User Field',36,304,NULL,NULL,1,4,'index_user_field','permissions','ListScreen',NULL,NULL,NULL,'permission','A4','portrait'),(184,'Report Requests',4,13,'2011-01-07 04:00:19','2011-01-24 20:11:23',1,NULL,'index','report_requests',NULL,NULL,NULL,NULL,'graph','A4','portrait'),(939,'MAINTENANCE',8,1349,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,7,'maintenance','maintenance','MenuGroupScreen',NULL,NULL,NULL,NULL,'A4','portrait'),(940,'VERSION',939,1350,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,1,'version','maintenance',NULL,NULL,NULL,NULL,'info','A4','portrait'),(941,'SERVICE',939,1351,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,2,'service','maintenance',NULL,NULL,NULL,NULL,'multi_app','A4','portrait'),(942,'DATA_LOG',939,1352,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,4,'data_log','maintenance',NULL,NULL,NULL,NULL,'search_file','A4','portrait'),(943,'SYSTEM_LOG',939,1353,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,5,'system_log','maintenance',NULL,NULL,NULL,NULL,'search_file','A4','portrait'),(944,'BACKUP',939,1354,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,6,'backup','maintenance',NULL,NULL,NULL,NULL,'backup','A4','portrait'),(945,'RESTORE',939,1355,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,7,'restore','maintenance',NULL,NULL,NULL,NULL,'restore','A4','portrait'),(946,'RESTART',939,1356,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,8,'restart','maintenance',NULL,NULL,NULL,NULL,'restart','A4','portrait'),(947,'FIRMWARE',939,1357,'2011-08-29 05:38:34','2011-08-29 05:38:34',1,9,'firmware','maintenance',NULL,NULL,NULL,NULL,'info','A4','portrait'),(1024,'MEMORY',939,1663,'2012-10-10 00:00:00','2012-10-10 00:00:00',1,3,'memory','maintenance',NULL,NULL,NULL,NULL,'memory','A4','portrait'),(1044,'fields',1,293,NULL,NULL,1,6,'index','fields','ListScreen',NULL,NULL,NULL,'system','A4','portrait'),(1053,'Corporation',1066,1707,'2013-09-16 09:37:22','2014-08-01 04:48:27',0,3,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A3','landscape'),(1054,'Contact',1066,1671,'2013-09-16 09:37:56','2013-11-05 11:19:16',0,4,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','landscape'),(1056,'Quotation',37,1708,'2013-09-16 09:52:50','2014-01-08 04:37:27',0,2,'show','screens','HeaderScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','landscape'),(1057,'Purchase Order',37,1709,'2013-09-16 09:53:15','2014-01-08 04:55:07',0,3,'show','screens','HeaderScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','landscape'),(1060,'Quotation Revision',1056,1714,'2013-09-16 09:58:49','2013-11-05 11:39:58',0,NULL,'show','screens','RevisionScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"true\"\n','screen','A4','portrait'),(1061,'Purchase Order Revision',1057,1715,'2013-09-16 09:59:17','2013-09-19 07:56:55',0,NULL,'show','screens','RevisionScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"true\"\n','screen','A4','portrait'),(1064,'Purchase Order Details',1061,1718,'2013-09-16 10:03:09','2014-08-01 05:25:59',0,NULL,'show','screens','DetailScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A2','landscape'),(1066,'ScreenMaster_MasterData',37,1749,'2013-09-18 09:24:01','2013-09-18 09:24:01',0,1,'show','screens','MenuGroupScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1067,'Country',1066,1759,'2013-09-18 10:39:00','2013-09-18 10:39:00',0,1,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1068,'Province',1066,1760,'2013-09-18 10:39:29','2013-09-18 11:55:38',0,2,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1069,'Payment',1066,1761,'2013-09-18 10:39:53','2013-09-18 10:39:53',0,7,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1070,'Delivery Date',1066,1762,'2013-09-18 10:40:17','2013-09-18 10:40:17',0,8,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1072,'Staff',1066,1773,'2013-09-19 07:58:37','2013-09-19 07:58:37',0,5,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1073,'Quotation_Detail',1060,1717,'2013-09-19 08:32:37','2014-08-01 05:03:25',0,NULL,'show','screens','DetailScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A2','landscape'),(1081,'Delivery & Invoice',37,1710,'2013-09-27 11:19:43','2014-08-01 05:26:42',0,4,'show','screens','HeaderScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','landscape'),(1082,'Delivery Revision',1081,1805,'2013-09-27 11:25:22','2014-07-02 10:14:21',0,NULL,'show','screens','RevisionScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1083,'Delivery Detail',1082,1806,'2013-09-27 11:25:50','2014-08-01 06:53:42',0,NULL,'show','screens','DetailScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A3','landscape'),(1084,'Unit',1066,1808,'2013-10-10 03:29:32','2013-10-10 03:59:35',0,6,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1086,'report_templates',1,1814,NULL,NULL,1,7,'index','report_templates','ListScreen',NULL,NULL,NULL,'system','A4','portrait'),(1087,'Project Type',1066,1815,'2013-11-21 03:23:32','2013-11-21 06:45:43',0,9,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1090,'Project',37,1673,'2013-11-25 10:23:53','2014-08-01 04:55:13',0,1,'show','screens','HeaderScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A2','landscape'),(1091,'Project Revision',1090,1674,'2013-11-25 10:32:09','2013-11-25 10:32:09',0,NULL,'show','screens','RevisionScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1092,'Project Detail',1091,1675,'2013-11-25 10:35:13','2014-08-01 04:57:08',0,NULL,'show','screens','DetailScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A2','landscape'),(1093,'Project Detail 2',1091,1845,'2013-11-25 11:51:48','2014-08-01 04:57:46',0,NULL,'show','screens','DetailScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A3','landscape'),(1094,'Purchase Invoice',1061,1809,'2014-01-11 10:01:08','2014-08-01 05:10:27',0,NULL,'show','screens','DetailScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','landscape'),(1095,'Shipping Condition',1066,1738,'2014-06-26 11:22:38','2014-06-26 11:22:38',0,10,'show','screens','ListScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1096,'Invoice',37,1782,'2014-07-22 07:29:54','2014-08-01 06:56:54',0,5,'show','screens','HeaderScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A3','landscape'),(1097,'Invoice Revision',1096,1877,'2014-07-22 07:43:44','2014-07-30 08:13:46',0,NULL,'show','screens','RevisionScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','portrait'),(1098,'Invoice Detail',1097,1878,'2014-07-22 07:45:31','2014-08-01 06:59:15',0,NULL,'show','screens','DetailScreen',NULL,NULL,'--- !map:HashWithIndifferentAccess \nrevision_control: \"false\"\n','screen','A4','landscape');
/*!40000 ALTER TABLE `screens` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-06-30 17:47:32
