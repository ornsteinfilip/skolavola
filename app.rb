require 'bundler/setup'
require 'sinatra'
require 'sinatra/base'
require 'erb'
require_relative 'lib/constants'
require_relative 'matematika_zlomky'

include Constants  # Přesunuto na globální úroveň

class MainApp < Sinatra::Base
  configure do
    set :port, ENV['PORT'] || 3000
    set :bind, '0.0.0.0'
    set :public_folder, 'public'
    enable :sessions
  end

  get "/" do
    @title = "Výběr cvičení"
    erb :main_index
  end
end

# Spuštění aplikace
if __FILE__ == $0
  MainApp.run!
end 