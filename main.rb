require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'aih3284hreuwf8'

get '/' do
  session.clear
  redirect "/new_game"
end

get '/new_game' do
  if session[:player_name].nil?
    erb :set_username
  else
    redirect "/game"
  end
end

post '/new_game' do
  session[:player_name] = params[:player_name]
  redirect "/game"
end

get '/game' do
  VALUES = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  SUITS = ["D", "H", "C", "S"]

  def prepare_deck
    session[:deck] = []
    SUITS.each do |suit|
      VALUES.each do |value|
        session[:deck] << value + suit
      end
    end
    session[:deck].shuffle!
  end

  prepare_deck

  session[:player_cards] = []
  session[:dealer_cards] = []

  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  redirect "/player_turn"

end

get '/player_turn' do
  def calculate_total(array)
    total = 0
    array.each do |card|
      if card.to_i != 0
        total += card.to_i
      elsif card[0] == "A"
        total += 11
      else
        total += 10
      end
    end

    # Additional aces calculation
    array.select { |item| item =~ /[A]/}.count.times do
      total -= 10 if total > 21
    end 
    total
  end

  erb :"player/turn"
end

post '/player_turn' do
  def calculate_total(array)
    total = 0
    array.each do |card|
      if card.to_i != 0
        total += card.to_i
      elsif card[0] == "A"
        total += 11
      else
        total += 10
      end
    end

    # Additional aces calculation
    array.select { |item| item =~ /[A]/}.count.times do
      total -= 10 if total > 21
    end 
    total
  end

  if params.has_key?("hit")
    session[:player_cards] << session[:deck].pop
    erb :"player/turn"
  elsif params.has_key?("stay")
    erb :"player/stay"
  end
end