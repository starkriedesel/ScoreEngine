if Settings.server_manager.nil?
  Rails.logger.error('Server manager options missing. Disabling server management.')
else
  enabled = false
  if Settings.server_manager.aws.nil?
    Rails.logger.error('No AWS settings given. Use \'server_manager.aws.enable = false\' to disable explicitly. Disabling AWS server management.')
  elsif Settings.server_manager.aws.enable
    enabled = true
    Rails.logger.error("AWS server management enabled on region '#{Settings.server_manager.aws.region}'.")
    AWS.config(
        access_key_id: Settings.server_manager.aws.access_key_id,
        secret_access_key: Settings.server_manager.aws.secret_access_key,
        region: Settings.server_manager.aws.region)
  end
  unless enabled
    Rails.logger.error('No sever manager enabled. Disabling server management.')
  end
end