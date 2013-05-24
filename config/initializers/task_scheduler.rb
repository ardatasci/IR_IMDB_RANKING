require 'rubygems'
require 'rufus/scheduler'  
require 'rake'

scheduler_app_statistics = Rufus::Scheduler.start_new

process_path = Rails.root.join('lib','tasks', 'suggestion_maker.rake')
load File.join(process_path)

#scheduler_app_statistics.every '2m' do #TODO: Decide time interval
 #   Thread.new do
  
 #   begin
  #    Rake::Task['generate_suggestions'].reenable
   #   Rake::Task['generate_suggestions'].invoke
   # rescue Exception => e
   #   puts "Error on Usage Process: #{e.to_s}"
   # end


#end
#end