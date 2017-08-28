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
-- Table structure for table `report_templates`
--

DROP TABLE IF EXISTS `report_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `report_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `screen_id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `file` varchar(255) DEFAULT NULL,
  `display` varchar(255) DEFAULT 'edit',
  `output_type` varchar(255) DEFAULT 'pdf',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `report_templates`
--

LOCK TABLES `report_templates` WRITE;
/*!40000 ALTER TABLE `report_templates` DISABLE KEYS */;
INSERT INTO `report_templates` VALUES (1,1060,'Quotation','ReportTemplates::Quotation',NULL,'2013-10-07 04:38:23',NULL,'edit','pdf'),(2,1061,'Purchase Order','ReportTemplates::PurchaseOrder',NULL,'2013-10-15 11:38:00','none','edit','pdf'),(3,1082,'Delivery Sheet','ReportTemplates::DeliverySheet',NULL,'2013-10-07 04:38:23',NULL,'edit','pdf'),(4,1097,'TAX Invoice / Delivery Order / Invoice','ReportTemplates::Invoice',NULL,'2014-07-25 04:50:57','none','edit','pdf'),(9,1073,'Sale History','ReportTemplate',NULL,'2013-10-16 04:03:04','sale_history.html.erb','index','pdf'),(10,1064,'Purchase History','ReportTemplate',NULL,'2013-10-16 03:54:28','purchase_history.html.erb','index','pdf'),(11,1083,'Sale History','ReportTemplate',NULL,'2013-10-16 04:03:13','sale_history.html.erb','index','pdf'),(12,1080,'Purchase History','ReportTemplate',NULL,'2013-10-16 04:02:10','purchase_history.html.erb','index','pdf'),(34,1057,'P/O Balance','ReportTemplates::PurchaseBalance','2013-10-15 09:12:10','2013-10-15 12:26:07','none','index','pdf'),(35,1091,'Data List Project Engineering','ReportTemplates::ProjectDataList','2013-12-09 12:17:58','2013-12-09 12:17:58','none','edit','pdf'),(37,1091,'Data List Project (Excel)','ReportTemplates::ProjectDataListExcel','2014-01-15 10:39:26','2014-01-15 10:42:15','none','edit','xls'),(38,1098,'Sale History','ReportTemplate','2014-07-25 10:43:43','2014-07-25 10:43:43','sale_history.html.erb','index','pdf'),(39,1056,'Sales Balance','ReportTemplates::SalesBalance','2014-07-29 12:20:03','2014-07-29 12:20:03','none','index','pdf'),(40,1096,'Sales Balance','ReportTemplates::SalesBalance','2014-07-29 12:20:20','2014-07-29 12:20:20','none','index','pdf');
/*!40000 ALTER TABLE `report_templates` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-06-30 17:47:37
