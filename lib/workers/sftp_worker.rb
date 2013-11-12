require 'net/sftp'

module Workers
  class SftpWorker < FtpWorker
    set_default_params rport: 22

    def worker_name
      'Sftp'
    end

    def ftp_get_error
      unless @sftp_error.nil?
        [@sftp_error.code, @sftp_error.description]
      end
      nil
    end

    def ftp_connect host, port, username, password
      @sftp = nil
      @sftp_error = nil
      @sftp = Net::SFTP.start(host, username, password: params[:password], port: params[:rport])
      true
    rescue Net::SFTP::StatusException => e
      @sftp_error = e
      false
    end

    def ftp_close
    end

    def ftp_get remote_name, local_name
      @sftp.download! remote_name, local_name
      true
    rescue Net::SFTP::StatusException => e
      @sftp_error = e
      false
    end

    def ftp_put local_path, remote_path
      @sftp.upload! local_path, remote_path
      true
    rescue Net::SFTP::StatusException => e
      @sftp_error = e
      false
    end
  end
end