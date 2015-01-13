require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'aih3284hreuwf8'

get '/' do
  erb :hello
end

get '/new_game' do
  erb :set_username
end

post '/new_game' do
  session[:player_name] = params[:player_name]
  "Hello #{session[:player_name]}"
end