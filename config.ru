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