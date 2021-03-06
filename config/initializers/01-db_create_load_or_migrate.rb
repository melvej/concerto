#Checks current migration status of Concerto and migrates to any more recent migration version available
#Creates and migrates the database if it doesn't yet exist
#Implementation based on http://trevorturk.wordpress.com/2008/04/10/automatically-creating-loading-and-migrating-your-database/

begin
  current_version = ActiveRecord::Migrator.current_version
  #Grab the timestamp from each migration filename, and run max() on the resulting array
  highest_version = Dir.glob("#{Rails.root.to_s}/db/migrate/*.rb").map { |f| f.match(/\d+/).to_s.to_i}.max
  if current_version == 0
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
  elsif current_version != highest_version && current_version != nil
    require 'rake'
    Concerto::Application.load_tasks
    Rake::Task["db:migrate"].invoke
  end
rescue
  require 'rake'
  Concerto::Application.load_tasks
  Rake::Task["db:create"].invoke
  Rake::Task["db:migrate"].invoke
  Rake::Task["db:seed"].invoke
  retry
end
