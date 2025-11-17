CREATE USER 'vlcms_user'@'localhost' IDENTIFIED BY 'vlcms123';
GRANT ALL PRIVILEGES ON VLCMS.* TO 'vlcms_user'@'localhost';

CREATE USER 'service_staff'@'localhost' IDENTIFIED BY 'staff123';
GRANT SELECT, INSERT, UPDATE ON VLCMS.* TO 'service_staff'@'localhost';

CREATE USER 'service_viewer'@'localhost' IDENTIFIED BY 'viewer123';
GRANT SELECT ON VLCMS.* TO 'service_viewer'@'localhost';

CREATE USER 'workshop_owner'@'localhost' IDENTIFIED BY 'workshop123';
GRANT SELECT, INSERT, UPDATE ON VLCMS.WORKSHOP TO 'workshop_owner'@'localhost';
GRANT SELECT ON VLCMS.SERVICE_RECORD TO 'workshop_owner'@'localhost';

FLUSH PRIVILEGES;