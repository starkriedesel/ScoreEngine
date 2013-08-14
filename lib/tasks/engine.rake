namespace :engine do
  def daemon_command cmd
    rails_root = Rails.root
    daemon_dir = File.join(rails_root, 'lib/daemon.rb')
    pid_dir = File.join(rails_root, 'tmp/pids/')

    Daemons.run(
        daemon_dir,
        {
            app_name: 'ScoreEngine_Daemon',
            ARGV: [cmd],
            multiple: false,
            backtrace: true,
            dir_mode: :normal,
            dir: pid_dir,
        }
    )
  end

  desc 'Start the ScoreEngine daemon'
  task :start => :environment do
    daemon_command 'start'
  end

  desc 'Stop the ScoreEngine daemon'
  task :stop => :environment do
    daemon_command 'stop'
  end

  desc 'Restart the ScoreEngine daemon'
  task :restart => :environment do
    daemon_command 'restart'
  end

  desc 'Get the status of the ScoreEngine daemon'
  task :status => :environment do
    daemon_command 'status'
  end

end
