require "active_record"
require "gschool_database_connection"
require "yaml"

include ActiveRecord::Tasks

DatabaseTasks.database_configuration = YAML.load_file("config/database.yml")
DatabaseTasks.env = ENV["RACK_ENV"] || "development"

ActiveRecord::Base.configurations = DatabaseTasks.database_configuration

def db_dir
  File.expand_path(
    "../../../db", __FILE__
  )
end

namespace :db do
  desc "Create the database for the current environment"
  task :create do
    DatabaseTasks.create_current
  end

  desc "Drop the database for the current environment"
  task :drop do
    DatabaseTasks.drop_current
  end

  desc "Migrate the database for the current environment"
  task :migrate do
    GschoolDatabaseConnection::DatabaseConnection.establish(DatabaseTasks.env)
    ActiveRecord::Migrator.migrate(db_dir)
  end

  desc "Rollback the database for the current environment"
  task :rollback do
    GschoolDatabaseConnection::DatabaseConnection.establish(DatabaseTasks.env)
    ActiveRecord::Migrator.rollback(db_dir)
  end

  desc "Create a new database migration"
  task :create_migration do
    puts "What is the name of the migration? Use snakecase, i.e. name_of_migration"
    migration_name = STDIN.gets.chomp
    migration_class_name = migration_name.split("_").map(&:capitalize).join
    timestamp = Time.now.to_i
    migration_file_name = db_dir + "/migrate/#{timestamp}_#{migration_name}.rb"

    file = File.new(migration_file_name, "w+")

    file.puts(<<-TEMPLATE)
class #{migration_class_name} < ActiveRecord::Migration
  def up
    # add migration code here
  end

  def down
    # add reverse migration code here
  end
end
TEMPLATE
    file.close
    puts "migration created: #{migration_file_name}"
  end
end
