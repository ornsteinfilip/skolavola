require './app'
require 'securerandom'

# Generování náhodného secret klíče při každém spuštění
use Rack::Session::Cookie, secret: SecureRandom.hex(64)

# Definice mapování
map "/" do
  run MainApp
end

map "/matematika/zlomky" do
  run MatematikaZlomky::Web
end

# Přidat na začátek souboru
port = ENV['PORT'] || 3000
Rack::Server.start(
  Port: port,
  Host: '0.0.0.0',
  app: Rack::Builder.new {
    use Rack::Session::Cookie, secret: SecureRandom.hex(64)
    
    map "/" do
      run MainApp
    end
    
    map "/matematika/zlomky" do
      run MatematikaZlomky::Web
    end
  }
) 