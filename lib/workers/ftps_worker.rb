require 'net/ftp'
require 'ftpfxp'
module Workers
  class FtpsWorker < FtpWorker
    set_default_params rport: 990

    def worker_name
      :Ftps
    end

    def ftp_connect host, port, username, password
      begin
        @ftp = Net::FTPFXPTLS.new
        @ftp.passive = true
        @ftp.connect host, port
        @ftp.login username, password
      rescue Net::FTPPermError
        log_server_error "Authentication failed"
        return false
      end
    end
  end
end