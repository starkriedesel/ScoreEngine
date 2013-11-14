module Workers
  class MysqlWorker < GenericWorker
    set_default_params rport: 3306
    set_service_params({
      username: {description: 'User to login as', default: 'root', required: true},
      password: {description: 'Password to login with', default: ''},
      database: {description: 'Database to connect to', default: '', required: true},
      select_table: {description: 'Table to select from (blank for no select test)'},
      select_column: {description: 'Column to select from', default: '*'},
      select_check: {description: 'MD5/Regex of result from select (first row only)', default: ''},
      insert_table: {description: 'Table to insert to (blank for no insert test)'},
      insert_column: {description: 'Column to insert to'},
    })

    def worker_name
      'Mysql'
    end

    def do_check
      register_exception Mysql2::Error do |e|
        log_server_error e.to_s
      end

      perform_action do
        select_response = nil

        log_server_connect
        log_server_login
        @log.debug_message += "Database: #{params[:database]}\n\n"

        client = Mysql2::Client.new host: params[:rhost], port: params[:rport].to_i, username: params[:username], password: params[:password], database: params[:database]
        [:select_table, :select_columns, :insert_table, :insert_column].each {|k| params[k] = client.escape params[k] unless params[k].nil?}

        unless params[:select_table].blank?
          sql = "SELECT #{params[:select_column]} FROM #{params[:select_table]}"
          @log.debug_message += "Retrieving record from database: #{sql}\n"
          select_response = client.query(sql)

          if select_response.nil?
            log_server_error 'No response recieved for select statement'
            return
          else
            unless params[:select_check].blank?
              r = select_response.first[params[:select_column]]
              @log.debug_message += "Received response: #{r}\n"
              @log.debug_message += "Checking select response for: #{params[:select_check]}\n"
              unless r =~ %r{#{params[:select_check]}}
                log_server_error 'Incorrect response for select statement'
                return
              end
            end
          end
        end

        unless params[:insert_table].blank?
          insert_value = Time.now.to_i
          sql = "INSERT INTO #{params[:insert_table]} (#{params[:insert_column]}) VALUES ('#{insert_value}')"
          @log.debug_message += "Inserting record into database: #{sql}\n"
          client.query(sql)
        end
      end

      if @log.status.nil?
        @log.status = ServiceLog::STATUS_RUNNING
        @log.message = 'No Errors'
      end
    end
  end
end