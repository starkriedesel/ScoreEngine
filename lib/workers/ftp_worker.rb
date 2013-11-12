require 'net/ftp'

module Workers
  class FtpWorker < GenericWorker
    set_default_params rport: 21
    set_service_params({
      username: {description: 'User to login as', default: 'anonymous', required: true},
      password: {description: 'Password to login with'},
      static_file: {description: 'File whose contents must stay static'},
      static_file_check: {description: 'MD5/Regex of file static file'},
      upload_dir: {description: 'Directory w/ write priveleges (blank for no upload)'},
    })

    def worker_name
      'Ftp'
    end

    def do_check
      params[:upload_dir].chomp! '/'

      log_server_connect
      log_server_login

      upload_file_contents = Time.now.to_i.to_s
      upload_file_name = "#{params[:upload_dir]}/flag-#{Time.now.to_i.to_s}.txt"
      static_contents = nil

      perform_action do

        # Connect + Login
        return unless do_connect params[:rhost], params[:rport], params[:username], params[:password], "Cannot connect to #{params[:rhost]} : #{params[:rport]}"

        # Download a file
        unless params[:static_file].blank?
          static_contents = do_get params[:static_file], "Error reading file #{params[:static_file]}"
          return if static_contents.nil?
        end

        # Upload a file
        unless params[:upload_dir].blank?
          return unless do_put upload_file_name, upload_file_contents, "Error writing file #{upload_file_name}"
        end

        # Close Connection
        ftp_close
      end

      if @log.status.blank?
        unless params[:static_file_check].blank?
          @log.debug_message += "Checking file contents, should be MD5/Regex: #{params[:static_file_check]}\n"
          if perform_check static_contents, params[:static_file_check]
            @log.status = ServiceLog::STATUS_ERROR
            @log.message = "Invalid file contents"
            return
          end
        end
        @log.status = ServiceLog::STATUS_RUNNING
        @log.message = 'FTP Success'
      end
    end

    def do_connect host, port, username, password, err_msg
      return false unless ftp_connect host, port, username, password
      log_invalid_response err_msg
    end

    def ftp_connect host, port, username, password
      begin
        @ftp = Net::FTP.new
        @ftp.connect host, port
        @ftp.login username, password
      rescue Net::FTPPermError
        log_server_error "Authentication failed"
        return false
      end
    end

    def do_get file_name, err_msg
      # Create a temp file to read to
      output = ''
      tmp_read = Tempfile.new("read")
      @log.debug_message += "Reading file: '#{file_name}'\n"

      # Perform FTP Action
      if ftp_get file_name, tmp_read.path
        # Read it from the temp file
        tmp_read.rewind
        output = tmp_read.read.chop
        @log.debug_message += "Read Complete\nContents:\n#{output}\n"
      end

      # Remove temp file
      tmp_read.close
      tmp_read.unlink

      # Log invalid action, return file contents
      return nil unless log_invalid_response err_msg
      output = '' if output.nil?
      output
    end

    def ftp_get remote_name, local_name
      @ftp.get remote_name, local_name
      true
    rescue Net::FTPPermError
      false
    end

    def do_put file_name, file_contents, err_msg
      # Save the temp file locally
      tmp_write = Tempfile.new("write")
      tmp_write.write file_contents
      tmp_write.rewind
      @log.debug_message += "Writting file: #{file_name}\nContents:\n#{file_contents}\n"

      # Perform the FTP action
      if ftp_put tmp_write.path, file_name
        @log.debug_message += "Write Complete\n"
      end

      # Remove temp file
      tmp_write.close
      tmp_write.unlink

      # Log any invalid action
      log_invalid_response err_msg
    end

    def ftp_put local_path, remote_path
      @ftp.put local_path, remote_path
      true
    rescue Net::FTPPermError
      false
    end

    def ftp_close
      @ftp.close
    end

    # Checks for and logs invalid response codes
    def log_invalid_response  message
      error = ftp_get_error
      unless error.nil?
        log_server_error "#{message} (FTP Error: #{error[0]})"
        @log.debug_message += "\nInvalid Response: #{error[1]}"
        return false
      end
      true
    end

    # Checks for errors, returns [code, message] or nil
    def ftp_get_error
      code = @ftp.last_response_code
      code[0] == '2' ? nil : [code, @ftp.last_response]
    end

    def try_chdir ftp, dir
      begin
        ftp.chdir dir
        return true
      rescue Net::FTPPermError
        return false
      end
    end
  end
end