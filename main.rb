require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'aih3284hreuwf8'

helpers do
  VALUES = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
  SUITS = ["diamonds", "hearts", "clubs", "spades"]

  def prepare_deck
    session[:deck] = []
    SUITS.each do |suit|
      VALUES.each do |value|
        session[:deck] << suit + "_" + value
      end
    end
    session[:deck].shuffle!
  end

  def calculate_total(array)
    total = 0
    array.each do |card|
      card = card.split("_")[1]
      if card.to_i != 0
        total += card.to_i
      elsif card == "ace"
        total += 11
      else
        total += 10
      end
    end

    # Additional aces calculation
    array.select { |item| item =~ /ace/}.count.times do
      total -= 10 if total > 21
    end 
    total
  end

  def check_blackjack_or_bust(player_or_dealer)
    if player_or_dealer == "player"
      if calculate_total(session[:player_cards]) == 21
        redirect "/player_blackjack"
        # redirect to blackjack_player message
      elsif calculate_total(session[:player_cards]) > 21
        redirect "/player_busted"
        # redirect to busted_player message
      end
    else
      if calculate_total(session[:dealer_cards]) == 21
        redirect "/dealer_blackjack"
        # redirect to blackjack_player message
      elsif calculate_total(session[:dealer_cards]) > 21
        redirect "/dealer_busted"
        # redirect to busted_player message
      end
    end
  end

end

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
  # check if player busts or blackjack
  check_blackjack_or_bust("player")

  erb :"player/turn"
end

post '/player_turn' do
  # check bust or blackjack

  check_blackjack_or_bust("player")

  if params.has_key?("hit")
    session[:player_cards] << session[:deck].pop
    redirect "/player_turn"
  elsif params.has_key?("stay")
    redirect "/dealer_turn"
  end
end

get '/player_blackjack' do
  erb :"player/blackjack"
end

get '/player_busted' do
  erb :"player/busted"
end

get '/dealer_turn' do
  check_blackjack_or_bust("dealer")

  if calculate_total(session[:dealer_cards]) < 17
    erb :"dealer/turn"
  else
    redirect "/declare_winner"
  end
end

post '/dealer_turn' do
  session[:dealer_cards] << session[:deck].pop

  check_blackjack_or_bust("dealer")

  if calculate_total(session[:dealer_cards]) < 17
    erb :"dealer/turn"
  else
    redirect "/declare_winner"
  end
end

get '/dealer_busted' do
  erb :"dealer/busted"
end

get '/dealer_blackjack' do
  erb :"dealer/blackjack"
end

get '/declare_winner' do
  if calculate_total(session[:player_cards]) > calculate_total(session[:dealer_cards])
    session[:message] = "Congratulations! #{session[:player_name]} wins!"
  elsif calculate_total(session[:player_cards]) < calculate_total(session[:dealer_cards])
    session[:message] = "Sorry :( Dealer wins"
  else
    session[:message] = "It's a tie!"
  end

  erb :declare_winner
end
