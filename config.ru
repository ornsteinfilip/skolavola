require './app'
require 'securerandom'

use Rack::Session::Cookie, secret: SecureRandom.hex(64)

map "/" do
  run MainApp
end

map "/matematika/zlomky" do
  run MatematikaZlomky::Web
end

map "/matematika/delitelnost" do
  run MatematikaDelitelnost::Web
end