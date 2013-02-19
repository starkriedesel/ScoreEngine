# Be sure to restart your server when you modify this file.

#ScoreEngine::Application.config.session_store :cookie_store, key: '_ScoreEngine_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
ScoreEngine::Application.config.session_store :active_record_store

ScoreEngine::Application.config.session = {
    :session_key => 'session_id',
    :secret => '6ddf68214927bf421b720940c2cc0d18b07921106d9c60a2a7b339f85f4081c1ef0f5145854240ccb38bf080dca4b7ccd069ce2e880da12bd14b03b66df74a08',
}