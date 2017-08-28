class ChangeCaptionNameCharSet < ActiveRecord::Migration
  def self.up
    config =  Rails.configuration.database_configuration[Rails.env]

    execute <<SQLCMD
ALTER TABLE `#{config['database']}`.`captions` MODIFY COLUMN `name` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci;
SQLCMD
  end

  def self.down
    config =  Rails.configuration.database_configuration[Rails.env]

    execute <<SQLCMD
ALTER TABLE `#{config['database']}`.`captions` MODIFY COLUMN `name` VARCHAR(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci;
SQLCMD
  end
end
