require 'client_env'

module ActiveRecord
  class Migrator#:nodoc:

    def migrations
      @migrations ||= begin
        files = Dir[File.join(@migrations_path, '[0-9]*_*.rb')]
        files += Dir[File.join(ClientEnv.root, @migrations_path, '[0-9]*_*.rb')]

        migrations = files.inject([]) do |klasses, file|
          version, name = file.scan(/([0-9]+)_([_a-z0-9]*).rb/).first

          raise IllegalMigrationNameError.new(file) unless version
          version = version.to_i

          if klasses.detect { |m| m.version == version }
            raise DuplicateMigrationVersionError.new(version)
          end

          if klasses.detect { |m| m.name == name.camelize }
            raise DuplicateMigrationNameError.new(name.camelize)
          end

          klasses << returning(MigrationProxy.new) do |migration|
            migration.name     = name.camelize
            migration.version  = version
            migration.filename = file
          end
        end

        migrations = migrations.sort_by(&:version)
        down? ? migrations.reverse : migrations
      end
    end
  end
end