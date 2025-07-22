namespace :db do
  desc "Resets the database, including dropping PostGIS extension"
  task reset_postgis: :environment do
    # Connect to a default database (e.g., postgres) to drop the target databases
    ActiveRecord::Base.establish_connection(Rails.application.config.database_configuration[Rails.env].merge({ database: "postgres", schema_search_path: 'public' }))
    ActiveRecord::Base.connection.execute('DROP EXTENSION IF EXISTS postgis CASCADE;')
    ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS spatial_ref_sys CASCADE;')

    # Now, reset the database using db:migrate:reset
    Rake::Task['db:migrate:reset'].invoke
  end
end