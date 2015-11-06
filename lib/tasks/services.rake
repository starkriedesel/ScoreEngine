namespace :services do
  desc 'Turn off all services'
  task :off, [:team_id] => [:environment] do |t,args|
    if args[:team_id].nil?
      Service.update_all on: false
    else
      teams = args[:team_id].to_s.split ' '
      Service.update_all({on: false}, {team_id: teams})
    end
  end

  desc 'Turn on all services'
  task :on, [:team_id] => [:environment] do |t,args|
    if args[:team_id].nil?
      Service.update_all on: true
    else
      teams = args[:team_id].to_s.split ' '
      Service.update_all({on: true}, {team_id: teams})
    end
  end

  desc 'Clear logs from all services'
  task :clear, [:team_id] => [:environment] do |t,args|
    if args[:team_id].nil?
      ServiceLog.delete_all
    else
      teams = args[:team_id].to_s.split ' '
      ServiceLog.delete_all team_id: teams
    end
  end
end
