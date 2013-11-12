module Workers
  class HttpsWorker < HttpWorker
    set_default_params rport: 443

    def worker_name
      'Https'
    end

    def prefix
      "https"
    end
  end
end