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
end

before do
  @hide_dealers_cards_and_total = true
  @player_turn = false
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
  if params[:player_name].empty?
    @error = "Player name cannot be empty!"
    halt erb :set_username
  end

  session[:player_name] = params[:player_name]
  redirect "/game"
end

get '/game' do
  @player_turn = true
  prepare_deck

  session[:player_cards] = []
  session[:dealer_cards] = []

  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == 21
    @success = "Congratulations! You hit blackjack!"
    @player_turn = false
    erb :game
  elsif calculate_total(session[:player_cards]) > 21
    @defeat = "Sorry, you busted!"
    @player_turn = false
    erb :game
  end
  
  erb :game
end

post '/player/hit' do
  @player_turn = true
  session[:player_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == 21
    @success = "Congratulations! You hit blackjack!"
    @player_turn = false
    erb :game
  elsif calculate_total(session[:player_cards]) > 21
    @defeat = "Sorry, you busted!"
    @player_turn = false
    erb :game
  end

  erb :game
end

post '/player/stay' do
  @hide_dealers_cards_and_total = false

  if calculate_total(session[:dealer_cards]) < 17
    erb :game  
  elsif calculate_total(session[:dealer_cards]) == 21
    @defeat = "Sorry! The dealer hit blackjack!"
    erb :game
  else
    redirect "/declare/winner"
  end
end

post '/dealer/hit' do
  @hide_dealers_cards_and_total = false

  session[:dealer_cards] << session[:deck].pop

  if calculate_total(session[:dealer_cards]) < 17
    erb :game  
  elsif calculate_total(session[:dealer_cards]) == 21
    @defeat = "Sorry! The dealer hit blackjack!"
    erb :game
  elsif calculate_total(session[:dealer_cards]) > 21
    @success = "The dealer busted! You win!"
    erb :game
  else
    redirect "/declare/winner"
  end
end

get '/declare/winner' do
  @hide_dealers_card_and_total = false

  if calculate_total(session[:player_cards]) > calculate_total(session[:dealer_cards])
    @success = "Congratulations! #{session[:player_name]} wins!"
  elsif calculate_total(session[:player_cards]) < calculate_total(session[:dealer_cards])
    @defeat = "Sorry :( Dealer wins"
  else
    @info = "It's a tie!"
  end

  erb :declare_winner
end
