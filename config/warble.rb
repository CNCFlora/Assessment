Warbler::Config.new do |config|
    config.dirs     = %w(views public)
    config.includes = FileList["config.ru","app.rb","config.yml"]
end
