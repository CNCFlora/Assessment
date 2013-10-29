Warbler::Config.new do |config|
    config.dirs     = %w(views public model locales config)
    config.includes = FileList["config.ru","app.rb","config.yml"]
    config.webxml.rack.env = ENV['RACK_ENV'] || 'production'
end
