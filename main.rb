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
  if session[:player_name].nil?
    erb :set_username
  else
    redirect "/bet"
  end
end

post '/new_game' do
  session[:player_name] = params[:player_name]
  redirect "/bet"
end

get '/bet' do
  "Please place your bets #{session[:player_name]}!"
end