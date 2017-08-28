class ChangeRowsRemarkCharSet < ActiveRecord::Migration
    def self.up
        config =  Rails.configuration.database_configuration[Rails.env]
        
        execute <<SQLCMD
ALTER TABLE `#{config['database']}`.`rows` MODIFY COLUMN `remark` #{data_type} CHARACTER SET utf8 COLLATE utf8_general_ci;
SQLCMD

    end

    def self.down
        config =  Rails.configuration.database_configuration[Rails.env]

        execute <<SQLCMD
ALTER TABLE `#{config['database']}`.`rows` MODIFY COLUMN `remark` #{data_type} CHARACTER SET latin1 COLLATE latin1_swedish_ci;
SQLCMD
    end
    
    def self.data_type
        native_database_types[:yaml][:name]
    end
end
