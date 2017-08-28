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
-- Table structure for table `custom_fields`
--

DROP TABLE IF EXISTS `custom_fields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `custom_fields` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `custom_field_id` int(11) DEFAULT NULL,
  `descr` varchar(255) DEFAULT NULL,
  `label_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `value` text,
  `display_flags` text,
  `type` varchar(255) NOT NULL DEFAULT 'CustomField',
  PRIMARY KEY (`id`),
  KEY `IX_custom_fields_custom_field_id` (`custom_field_id`),
  KEY `IX_custom_fields_name` (`name`),
  KEY `IX_custom_fields_type` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=214 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `custom_fields`
--

LOCK TABLES `custom_fields` WRITE;
/*!40000 ALTER TABLE `custom_fields` DISABLE KEYS */;
INSERT INTO `custom_fields` VALUES (42,'txtName',NULL,'',3,'2013-09-16 10:07:42','2014-06-24 05:09:57','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"100\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n','--- {}\n\n','CustomFields::TextField'),(43,'txtPhone',NULL,'',1667,'2013-09-16 10:09:30','2013-09-30 07:29:25','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- /\n- \":\"\n- ;\n- <\n- \">\"\n- \"@\"\n- \"[\"\n- \"]\"\n- \"-1\"\n',NULL,'CustomFields::TextField'),(44,'txtFax',NULL,'',1668,'2013-09-16 10:09:48','2013-09-30 07:30:09','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- /\n- \":\"\n- ;\n- <\n- \">\"\n- \"@\"\n- \"[\"\n- \"]\"\n- \"-1\"\n',NULL,'CustomFields::TextField'),(46,'txtPosition',NULL,'',1712,'2013-09-16 10:52:10','2013-09-16 10:52:10','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"false\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(47,'txtCode',NULL,'',129,'2013-09-16 10:53:01','2013-09-16 10:53:01','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- (\n- )\n- \",\"\n- \"-\"\n- .\n- /\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(52,'dtUpdateOn',NULL,'',1679,'2013-09-16 10:57:01','2013-09-16 11:37:04','--- !map:HashWithIndifferentAccess \ndefault_value: current_date\nformat_date: short_date\n',NULL,'CustomFields::DateTimeField'),(58,'refCorporation_Name',NULL,'Please add corporation\'s name.',1720,'2013-09-16 11:07:32','2013-11-21 08:19:50','--- !map:HashWithIndifferentAccess \nscreen_id: \"1053\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(59,'txaComment',NULL,'Please add comments or special instructions for the customer.<br />Use the <b>@(delivery_date)</b> tag to specify where the \"Delivery Date\" should be placed, and <b>@(term_of_payment)</b> for the \"Term of Payment\".',1719,'2013-09-16 11:12:38','2016-03-08 10:39:28','--- !map:HashWithIndifferentAccess \ndefault_value: |\n  1. Delivery Date: @(delivery_date)\n  2. Term of Payment: @(term_of_payment)\n\nmin_length: \"0\"\nmax_length: \"500\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nnon_english: \"false\"\nalphabet: all\n',NULL,'CustomFields::TextArea'),(60,'refAttendant',NULL,'Please choose person\'s name. (List from Contact screen) ',1721,'2013-09-16 11:30:44','2014-06-30 06:55:11','--- !map:HashWithIndifferentAccess \nscreen_id: \"1054\"\ncustom_field_ids: \n- \"42\"\n- \"117\"\n- \"58\"\n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(62,'refProjectCode',NULL,'Please add project code.(List from Project screen)',1713,'2013-09-17 03:23:19','2013-11-28 11:16:14','--- !map:HashWithIndifferentAccess \nscreen_id: \"1090\"\ncustom_field_ids: \n- \"156\"\n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(65,'dtDate',NULL,'',1722,'2013-09-17 03:53:34','2013-09-17 03:53:34','--- !map:HashWithIndifferentAccess \ndefault_value: current_date\nformat_date: short_date\n',NULL,'CustomFields::DateTimeField'),(66,'txtCredit',NULL,'Input the period before payment. (for example : 30 days)',1723,'2013-09-17 03:55:33','2013-10-17 11:33:31','--- !map:HashWithIndifferentAccess \nmin_length: \"0\"\ndefault_value: \"\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- (\n- )\n- \",\"\n- \"-\"\n- .\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(67,'dtDueDate',NULL,'Please enter the date which payment of a bill.',1724,'2013-09-17 03:56:05','2013-10-10 09:33:08','--- !map:HashWithIndifferentAccess \ndefault_value: empty\nformat_date: short_date\n',NULL,'CustomFields::DateTimeField'),(71,'txtTermOfPayment',NULL,'',1740,'2013-09-17 04:57:19','2013-09-20 03:36:07','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(74,'txtCPONumber',NULL,'',1686,'2013-09-17 07:05:46','2013-09-17 07:05:46','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- (\n- )\n- +\n- \",\"\n- \"-\"\n- /\n- \"@\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(82,'txtYourReference',NULL,'Please input Your Reference',1734,'2013-09-17 07:10:55','2014-07-25 08:27:11','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(83,'refBillTo',NULL,'Please choose name, who is received a bill.(List from Contact screen)',1743,'2013-09-17 08:54:18','2014-06-26 12:37:33','--- !map:HashWithIndifferentAccess \nscreen_id: \"1054\"\ncustom_field_ids: \n- \"42\"\n- \"117\"\n- \"58\"\n- \"-1\"\ncontrol_type: searchable_text\n','--- {}\n\n','CustomFields::Reference'),(84,'refCC',NULL,'Please choose name, who is received a carbon copy.(List from Contact screen)',1704,'2013-09-17 08:54:40','2014-06-26 12:44:47','--- !map:HashWithIndifferentAccess \nscreen_id: \"1054\"\ncustom_field_ids: \n- \"42\"\n- \"117\"\n- \"58\"\n- \"-1\"\ncontrol_type: searchable_text\n','--- {}\n\n','CustomFields::Reference'),(86,'txtDescription',NULL,'Please add text, Described the product.',144,'2013-09-17 09:07:06','2016-03-04 09:58:23','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"100\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nnon_english: \"true\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(93,'txtUnit',NULL,'',1808,'2013-09-17 09:16:07','2013-09-29 07:16:07','--- !map:HashWithIndifferentAccess \nmin_length: \"0\"\ndefault_value: \"\"\nmax_length: \"5\"\nnumeric: \"false\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(97,'dtDeliveryTime',NULL,'',1737,'2013-09-18 08:04:41','2013-09-18 08:04:41','--- !map:HashWithIndifferentAccess \ndefault_value: empty\nformat_date: long_date\n',NULL,'CustomFields::DateTimeField'),(98,'txtShippingCondition',NULL,'',1738,'2013-09-18 08:06:55','2013-09-18 08:06:55','--- !map:HashWithIndifferentAccess \nmin_length: \"0\"\ndefault_value: \"\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(99,'txtPartMaker',NULL,'Please input Part Maker',1739,'2013-09-18 08:07:29','2014-07-25 08:27:34','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(100,'txtCustomerReference',NULL,'Please add text, The used of a source of information in order to ascertain the customer',1748,'2013-09-18 08:09:35','2013-10-10 09:35:28','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(106,'refCountry',NULL,'',1756,'2013-09-18 11:02:30','2013-11-29 07:12:41','--- !map:HashWithIndifferentAccess \nscreen_id: \"1067\"\ncustom_field_ids: \n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(107,'cmbTitle',NULL,'Title Name',1763,'2013-09-18 11:03:10','2013-09-18 11:09:25','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nlabel_ids: \n- \"1764\"\n- \"1765\"\n- \"-1\"\n',NULL,'CustomFields::ComboBox'),(108,'txtHouseNumber',NULL,'',1750,'2013-09-18 11:13:40','2013-09-18 11:13:40','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nnumeric: \"true\"\nsymbols: \n- /\n- \"-1\"\n',NULL,'CustomFields::TextField'),(114,'refProvince',NULL,'',1757,'2013-09-18 11:17:11','2013-09-19 03:37:57','--- !map:HashWithIndifferentAccess \nscreen_id: \"1068\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(115,'txtPostalCode',NULL,'',1758,'2013-09-18 11:36:19','2013-09-18 11:36:19','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"10\"\nnumeric: \"true\"\nsymbols: \n- \"-1\"\n',NULL,'CustomFields::TextField'),(117,'txtSurname',NULL,'',1766,'2013-09-19 03:30:07','2013-09-19 03:30:07','--- !map:HashWithIndifferentAccess \nmin_length: \"0\"\ndefault_value: \"\"\nmax_length: \"50\"\nnumeric: \"false\"\nsymbols: \n- (\n- )\n- \",\"\n- \"-\"\n- .\n- \"[\"\n- \"]\"\n- _\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(118,'txtEmail',NULL,'',1767,'2013-09-19 03:31:40','2014-06-24 03:38:48','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"-\"\n- .\n- \"@\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(119,'txtMobilePhone',NULL,'',1768,'2013-09-19 03:32:54','2013-09-30 07:30:44','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- (\n- )\n- +\n- \",\"\n- \"-\"\n- ;\n- \"-1\"\n',NULL,'CustomFields::TextField'),(120,'txtDepartment',NULL,'',1769,'2013-09-19 04:36:02','2013-09-19 04:36:02','--- !map:HashWithIndifferentAccess \nmin_length: \"0\"\ndefault_value: \"\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(121,'numQty',NULL,'Please add quantity of item.',1781,'2013-09-19 08:48:15','2016-03-09 07:58:39','--- !map:HashWithIndifferentAccess \ndefault_value: \"0.0\"\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"2\"\n  delimiter: \",\"\nformat: number\n',NULL,'CustomFields::NumericField'),(126,'numAmount',NULL,'',1695,'2013-09-19 09:13:31','2014-07-02 07:36:29','--- !map:HashWithIndifferentAccess \ndefault_value: \"0.0000\"\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"4\"\n  delimiter: \",\"\nformat: number\n',NULL,'CustomFields::NumericField'),(127,'numListPrice',NULL,'',1745,'2013-09-19 09:14:02','2014-07-02 07:43:58','--- !map:HashWithIndifferentAccess \ndefault_value: \"0.0000\"\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"4\"\n  delimiter: \",\"\nformat: number\n',NULL,'CustomFields::NumericField'),(129,'numDiscount',NULL,'',1731,'2013-09-19 09:14:26','2016-02-08 04:40:38','--- !map:HashWithIndifferentAccess \ndefault_value: \"0.0\"\nformat: number\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"2\"\n  delimiter: \",\"\n',NULL,'CustomFields::NumericField'),(131,'numUnitPrice',NULL,'',1691,'2013-09-19 09:15:33','2014-07-02 07:44:56','--- !map:HashWithIndifferentAccess \ndefault_value: \"0.0000\"\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"4\"\n  delimiter: \",\"\nformat: number\n',NULL,'CustomFields::NumericField'),(133,'numVatRate',NULL,'Please add percent of value-added tax. (ex. Vat Rate = 7%, add 7)',1742,'2013-09-19 09:16:00','2014-07-02 07:45:35','--- !map:HashWithIndifferentAccess \ndefault_value: \"7.00\"\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"2\"\n  delimiter: \",\"\nformat: number\n',NULL,'CustomFields::NumericField'),(134,'dtQuotationValidUntil',NULL,'',1772,'2013-09-19 09:29:08','2013-09-19 09:29:08','--- !map:HashWithIndifferentAccess \ndefault_value: empty\nformat_date: long_date\n',NULL,'CustomFields::DateTimeField'),(135,'refInChargePerson',NULL,'Please type and choose  person\'s name. (List from Staff screen)',1732,'2013-09-19 09:44:18','2013-10-17 08:05:34','--- !map:HashWithIndifferentAccess \nscreen_id: \"1072\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(136,'refAuthorizedPerson',NULL,'Please type and choose person\'s name. (List from Staff screen)',1774,'2013-09-19 09:46:51','2013-10-17 08:03:28','--- !map:HashWithIndifferentAccess \nscreen_id: \"1072\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(140,'cmbCurrencyID',NULL,'',1744,'2013-09-19 11:36:42','2013-09-19 11:36:42','--- !map:HashWithIndifferentAccess \ndefault_value: \"1777\"\nlabel_ids: \n- \"1777\"\n- \"1776\"\n- \"-1\"\n',NULL,'CustomFields::ComboBox'),(141,'autoPOCode',NULL,'',1779,'2013-09-19 11:40:00','2013-11-26 07:12:08','--- !map:HashWithIndifferentAccess \nformat: \"\\\"FCP-\\\"[refProjectType.Code]\\\"-\\\"yy###\"\nincrement: \"1\"\ncustom_field_ids: \n- \"176\"\n- \"-1\"\n',NULL,'CustomFields::AutoNumbering'),(142,'autoQuotationCode',NULL,'',1778,'2013-09-19 11:40:25','2013-11-22 05:19:56','--- !map:HashWithIndifferentAccess \nformat: \"\\\"FCQ-\\\"[refProjectType.Code]\\\"-\\\"yy###\"\nincrement: \"1\"\ncustom_field_ids: \n- \"176\"\n- \"-1\"\n',NULL,'CustomFields::AutoNumbering'),(143,'autoDeliveryCode',NULL,'',1780,'2013-09-20 04:29:29','2013-11-26 07:04:47','--- !map:HashWithIndifferentAccess \nformat: \"\\\"FCD-\\\"[refProjectType.Code]\\\"-\\\"yy###\"\nincrement: \"1\"\ncustom_field_ids: \n- \"176\"\n- \"-1\"\n',NULL,'CustomFields::AutoNumbering'),(145,'refPrepareBy',NULL,'Please type and choose person\'s name. (List from Staff screen)',1726,'2013-09-20 04:35:54','2013-10-17 08:25:28','--- !map:HashWithIndifferentAccess \nscreen_id: \"1072\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(146,'refDeliveryBy',NULL,'Please type and choose person\'s name. (List from Staff screen)',1728,'2013-09-20 04:36:36','2013-10-17 08:02:19','--- !map:HashWithIndifferentAccess \nscreen_id: \"1072\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(147,'refReceivedBy',NULL,'Please type and choose person\'s name. (List from Contact screen)',1729,'2013-09-20 04:36:58','2013-10-17 08:26:37','--- !map:HashWithIndifferentAccess \nscreen_id: \"1054\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(148,'refAuthorizedBy',NULL,'Please type and choose person\'s name. (List from Staff screen)',1727,'2013-09-20 04:39:01','2013-10-17 08:02:49','--- !map:HashWithIndifferentAccess \nscreen_id: \"1072\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(149,'refPayment',NULL,'The payment\'s special instructions of the customer.',1740,'2013-09-20 07:09:33','2013-10-16 12:02:45','--- !map:HashWithIndifferentAccess \nscreen_id: \"1069\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(150,'refDeliveryTerm',NULL,'The delivery\'s special instructions of the customer.',1762,'2013-09-20 07:10:32','2013-10-16 12:03:13','--- !map:HashWithIndifferentAccess \nscreen_id: \"1070\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(151,'refQuotation',NULL,'',1783,'2013-09-23 05:17:30','2013-09-30 12:25:55','--- !map:HashWithIndifferentAccess \nscreen_id: \"1056\"\ncustom_field_ids: \n- \"-1\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(153,'autoInvoiceNumber',NULL,'',1687,'2013-09-23 06:52:01','2013-09-23 07:40:18','--- !map:HashWithIndifferentAccess \nformat: \"\\\"IV\\\"yy\\\"-\\\"mm\\\"-\\\"###\"\nincrement: \"1\"\ncustom_field_ids: \n- \"-1\"\n',NULL,'CustomFields::AutoNumbering'),(154,'txtTaxIDNumber',NULL,'',1785,'2013-09-23 06:58:10','2013-09-23 06:58:10','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"-\"\n- \"-1\"\n',NULL,'CustomFields::TextField'),(156,'autoProjectCode',NULL,'',1713,'2013-09-23 09:35:38','2013-11-21 07:35:15','--- !map:HashWithIndifferentAccess \nformat: yy###\"-\"[refProjectType.Code]\nincrement: \"1\"\ncustom_field_ids: \n- \"176\"\n- \"-1\"\n',NULL,'CustomFields::AutoNumbering'),(158,'refIssueBy',NULL,'Please type and choose  person\'s name. (List from Staff screen)',1678,'2013-09-23 09:40:01','2013-10-17 08:06:10','--- !map:HashWithIndifferentAccess \nscreen_id: \"1072\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(160,'numExchRate',NULL,'For change JPY to THB. (ex. 100 Yen = 30 Baht, please add Exchange Rate = 0.3) ',1791,'2013-09-24 10:45:09','2016-01-18 09:18:41','--- !map:HashWithIndifferentAccess \nformat: number\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"4\"\n  delimiter: \",\"\ndefault_value: \"0.3\"\n',NULL,'CustomFields::NumericField'),(161,'refPOCode',NULL,'Please add P/O No.(List from Purchase Order screen in Purchase menu)',1779,'2013-09-25 07:00:05','2013-10-17 08:19:34','--- !map:HashWithIndifferentAccess \nscreen_id: \"1057\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(162,'numDutyRate',NULL,'Please add a percent of import duty.(ex. Import Duty = 10%, add 10)',1797,'2013-09-25 07:50:00','2014-07-02 07:38:45','--- !map:HashWithIndifferentAccess \ndefault_value: \"0.00\"\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"2\"\n  delimiter: \",\"\nformat: number\n',NULL,'CustomFields::NumericField'),(163,'refQuotationCode',NULL,'',1778,'2013-09-25 09:47:48','2013-09-30 12:18:13','--- !map:HashWithIndifferentAccess \nscreen_id: \"1056\"\ncustom_field_ids: \n- \"142\"\n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(164,'txaDeliveryPlace',NULL,'Please add text, The name of the intended recipient on parcel',1725,'2013-09-25 10:03:35','2013-10-10 08:44:41','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"200\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextArea'),(168,'txtId',NULL,'',1706,'2013-09-27 07:20:59','2013-09-27 07:20:59','--- !map:HashWithIndifferentAccess \nmin_length: \"0\"\ndefault_value: \"\"\nmax_length: \"10\"\nnumeric: \"true\"\nsymbols: \n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(169,'txaAddress',NULL,'Please add full-text address (to use this address in report)',1666,'2013-09-27 08:27:03','2016-03-08 04:11:51','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"200\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nnon_english: \"true\"\nalphabet: all\n',NULL,'CustomFields::TextArea'),(170,'txaInclude',NULL,'For expand item, please use format: [No.] [detail] [qty] [unit] (ex. 1 Program and Installation 1 job)',1810,'2013-09-30 09:02:46','2016-03-08 10:26:12','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"500\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nnon_english: \"true\"\nalphabet: all\n',NULL,'CustomFields::TextArea'),(171,'txtShortName',NULL,'',1811,'2013-10-08 11:48:23','2014-06-24 05:01:59','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n','--- {}\n\n','CustomFields::TextField'),(173,'refUnit',NULL,'',1808,'2013-10-10 03:37:12','2013-10-10 03:37:12','--- !map:HashWithIndifferentAccess \nscreen_id: \"1084\"\ncustom_field_ids: \n- \"42\"\n- \"-1\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(174,'refP/O Number(Customer)',NULL,'Please select CP/O No.',1686,'2013-10-11 04:50:24','2014-01-08 07:16:50','--- !map:HashWithIndifferentAccess \nscreen_id: \"1056\"\ncustom_field_ids: \n- \"74\"\n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(176,'refProjectType',NULL,'',1815,'2013-11-21 07:32:16','2013-11-21 07:32:16','--- !map:HashWithIndifferentAccess \nscreen_id: \"1087\"\ncustom_field_ids: \n- \"47\"\n- \"-1\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(177,'radProjectInvoiceType',NULL,'',1818,'2013-11-21 08:46:35','2013-11-25 11:18:01','--- !map:HashWithIndifferentAccess \nother_label_id: \"\"\nnew_line: \"false\"\ndefault_value: \"1844\"\nlabel_ids: \n- \"1844\"\n- \"1843\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(180,'autoFakePOCode',NULL,'',1823,'2013-11-21 10:44:38','2013-11-21 10:47:52','--- !map:HashWithIndifferentAccess \nformat: \"\\\"FCT-\\\"yy###\"\nincrement: \"1\"\ncustom_field_ids: \n- \"-1\"\n',NULL,'CustomFields::AutoNumbering'),(181,'radFakePOType',NULL,'',1824,'2013-11-21 11:05:01','2013-11-21 11:09:06','--- !map:HashWithIndifferentAccess \nother_label_id: \"\"\ndefault_value: \"1821\"\nnew_line: \"false\"\nlabel_ids: \n- \"1821\"\n- \"1825\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(182,'radQuotationStatus',NULL,'',1816,'2013-11-21 12:51:29','2013-11-21 12:51:29','--- !map:HashWithIndifferentAccess \nother_label_id: \"\"\ndefault_value: \"1828\"\nnew_line: \"false\"\nlabel_ids: \n- \"1826\"\n- \"1827\"\n- \"1828\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(184,'radDeliveryInvoiceStatus',NULL,'',1816,'2013-11-21 12:54:59','2013-11-21 12:54:59','--- !map:HashWithIndifferentAccess \nother_label_id: \"\"\ndefault_value: \"1836\"\nnew_line: \"false\"\nlabel_ids: \n- \"1826\"\n- \"1837\"\n- \"1836\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(185,'radSupplierPurchaseOrderStatus',NULL,'',1816,'2013-11-21 12:57:32','2013-11-21 12:57:32','--- !map:HashWithIndifferentAccess \nother_label_id: \"\"\ndefault_value: \"1838\"\nnew_line: \"false\"\nlabel_ids: \n- \"1826\"\n- \"1839\"\n- \"1838\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(186,'radPurchaseInvoiceStatus',NULL,'',1816,'2013-11-21 12:58:52','2013-11-21 12:58:52','--- !map:HashWithIndifferentAccess \nother_label_id: \"\"\ndefault_value: \"1836\"\nnew_line: \"false\"\nlabel_ids: \n- \"1826\"\n- \"1840\"\n- \"1836\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(188,'txtQuotationCode',NULL,'',1778,'2013-11-27 12:18:38','2013-11-27 12:18:38','--- !map:HashWithIndifferentAccess \nmin_length: \"0\"\ndefault_value: \"\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \"@\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(189,'refMaker',NULL,'Please add corporation\'s name.',1700,'2013-11-28 09:54:29','2013-11-29 03:41:20','--- !map:HashWithIndifferentAccess \nscreen_id: \"1053\"\ncustom_field_ids: \n- \"42\"\n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(190,'txtAWB',NULL,'Input AWB Document No.',1859,'2014-01-02 06:58:15','2014-01-02 06:58:15','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(191,'txtImpExpDocNo',NULL,'Input Import/Export Document No.',1860,'2014-01-02 06:58:50','2014-01-02 06:58:50','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(192,'radProjectStatus',NULL,'',1816,'2014-01-06 12:57:15','2014-01-06 13:03:39','--- !map:HashWithIndifferentAccess \ndefault_value: \"1861\"\nnew_line: \"false\"\nother_label_id: \"\"\nlabel_ids: \n- \"1826\"\n- \"1862\"\n- \"1861\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(193,'radDownPaymentType',NULL,'',1865,'2014-01-08 09:40:10','2014-01-09 12:44:00','--- !map:HashWithIndifferentAccess \ndefault_value: \"1867\"\nnew_line: \"false\"\nother_label_id: \"\"\nlabel_ids: \n- \"1863\"\n- \"1864\"\n- \"1867\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(194,'numDownPayment',NULL,'Input down payment percentage (20, 30, 50, ...)',1863,'2014-01-08 09:41:01','2014-07-02 07:37:58','--- !map:HashWithIndifferentAccess \ndefault_value: \"100.00\"\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"2\"\n  delimiter: \",\"\nformat: percentage\n',NULL,'CustomFields::NumericField'),(195,'txtInvoiceNo',NULL,'',1687,'2014-01-11 10:14:08','2016-03-21 11:02:01','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"-\"\n- /\n- \"-1\"\nnon_english: \"false\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(196,'dtInvoiceDate',NULL,'',1871,'2014-01-15 04:10:33','2014-01-15 04:10:33','--- !map:HashWithIndifferentAccess \ndefault_value: empty\nformat_date: short_date\n',NULL,'CustomFields::DateTimeField'),(197,'refCorporation_ID',NULL,'',1706,'2014-06-24 07:08:42','2014-06-24 07:08:42','--- !map:HashWithIndifferentAccess \nscreen_id: \"1053\"\ncustom_field_ids: \n- \"168\"\n- \"-1\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(198,'refBillTo(Search)',NULL,'',1743,'2014-06-26 12:17:22','2014-06-26 12:17:30','--- !map:HashWithIndifferentAccess \nscreen_id: \"1054\"\ncustom_field_ids: \n- \"42\"\n- \"117\"\n- \"58\"\n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(199,'refShippingCondition',NULL,'Please choose shipping condition. (List from Shipping Condition screen) ',1738,'2014-06-27 02:54:05','2014-07-25 08:32:23','--- !map:HashWithIndifferentAccess \nscreen_id: \"1095\"\ncustom_field_ids: \n- \"42\"\n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(200,'txaMoreDetail',NULL,'',1873,'2014-07-14 04:10:29','2016-04-11 12:06:44','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"1000\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nnon_english: \"true\"\nalphabet: all\n',NULL,'CustomFields::TextArea'),(201,'cbShowPrice',NULL,'',1874,'2014-07-21 07:39:04','2014-07-21 07:47:18','--- !map:HashWithIndifferentAccess \nnew_line: \"false\"\ndefault_value: \n- checked\n- \"-1\"\nfalse_label_id: \"1876\"\ntrue_label_id: \"1875\"\nlabel_ids: \n- \"-1\"\ntype: single\n',NULL,'CustomFields::CheckBox'),(202,'refInvoiceType',NULL,'',1819,'2014-07-22 08:10:24','2014-07-22 08:10:24','--- !map:HashWithIndifferentAccess \nscreen_id: \"1090\"\ncustom_field_ids: \n- \"177\"\n- \"-1\"\ncontrol_type: combo_box\n',NULL,'CustomFields::Reference'),(203,'autoInvoiceNo',NULL,'',1687,'2014-07-22 08:20:37','2016-02-24 08:45:57','--- !map:HashWithIndifferentAccess \nyear_shift: \"543\"\nformat: \"[refProjectCode.ServiceCode]yy\\\"-\\\"mm\\\"-\\\"###\"\nincrement: \"1\"\ncustom_field_ids: \n- \"62\"\n',NULL,'CustomFields::AutoNumbering'),(204,'refProjectC',NULL,'',1713,'2014-07-24 04:13:45','2014-07-24 04:13:45','--- !map:HashWithIndifferentAccess \nscreen_id: \"1090\"\ncustom_field_ids: \n- \"156\"\n- \"-1\"\ncontrol_type: searchable_text\n',NULL,'CustomFields::Reference'),(205,'txtSubject_for_description',NULL,'',1887,'2016-01-14 11:09:30','2016-02-18 07:49:42','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(206,'imgSignatureUploadImage',NULL,'Select image of the signature',1888,'2016-01-26 04:57:43','2016-01-26 05:16:33','--- !map:HashWithIndifferentAccess \noption: !map:HashWithIndifferentAccess \n  dimensions: 250x80\n  max_size: \"1280\"\n  file_type: !map:HashWithIndifferentAccess \n    jpg: \"true\"\n    tiff: \"true\"\n    \"-1\": \"false\"\n    gif: \"true\"\n    png: \"true\"\n',NULL,'CustomFields::UploadImage'),(210,'imgSignatureForUploadImage',NULL,'Select image of the signature',1890,'2016-01-26 04:57:43','2016-02-29 08:04:37','--- !map:HashWithIndifferentAccess \noption: !map:HashWithIndifferentAccess \n  dimensions: 250x80\n  max_size: \"1280\"\n  file_type: !map:HashWithIndifferentAccess \n    tiff: \"true\"\n    jpg: \"true\"\n    \"-1\": \"false\"\n    gif: \"true\"\n    png: \"true\"\n',NULL,'CustomFields::UploadImage'),(211,'radOfficeType',NULL,'',1892,'2016-04-11 10:09:37','2016-04-11 11:08:11','--- !map:HashWithIndifferentAccess \ndefault_value: \"1893\"\nnew_line: \"false\"\nother_label_id: \"\"\nlabel_ids: \n- \"1894\"\n- \"1893\"\n- \"-1\"\n',NULL,'CustomFields::RadioButton'),(212,'txtBranchNo',NULL,'',1895,'2016-04-11 10:32:29','2016-04-11 10:32:29','--- !map:HashWithIndifferentAccess \ndefault_value: \"\"\nmin_length: \"0\"\nmax_length: \"50\"\nnumeric: \"true\"\nsymbols: \n- \"!\"\n- \"%\"\n- \"&\"\n- (\n- )\n- \"*\"\n- +\n- \",\"\n- \"-\"\n- .\n- /\n- \":\"\n- ;\n- <\n- \"=\"\n- \">\"\n- \"?\"\n- \"@\"\n- \"[\"\n- \"]\"\n- _\n- \"|\"\n- \"-1\"\nnon_english: \"true\"\nalphabet: all\n',NULL,'CustomFields::TextField'),(213,'numPercentageDiscount',NULL,'',1897,'2016-05-06 11:29:17','2016-05-06 11:33:33','--- !map:HashWithIndifferentAccess \ndefault_value: \"0\"\noption: !map:HashWithIndifferentAccess \n  separator: .\n  precision: \"2\"\n  delimiter: \",\"\nformat: number\n',NULL,'CustomFields::NumericField');
/*!40000 ALTER TABLE `custom_fields` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-06-30 17:47:44
