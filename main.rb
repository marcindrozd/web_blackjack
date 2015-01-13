require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'aih3284hreuwf8'

get '/' do
  erb :hello
end

get '/set_username' do
  erb :set_username
end