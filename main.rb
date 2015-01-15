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

  def check_if_win_or_bust_player(array)
    if calculate_total(array) == 21
      @success = "Congratulations! You hit blackjack! You win $#{session[:last_bet].to_i * 2}}"
      session[:total_money] += session[:last_bet].to_i * 2
      @player_turn = false
      erb :game
    elsif calculate_total(array) > 21
      @defeat = "Sorry, you busted! You lost $#{session[:last_bet]}"
      @player_turn = false
      erb :game
    end
  end

  def check_if_win_or_bust_dealer(array)
    if calculate_total(array) < 17
      erb :game  
    elsif calculate_total(array) == 21
      @defeat = "Sorry! The dealer hit blackjack! You lost $#{session[:last_bet]}"
      erb :game
    elsif calculate_total(array) > 21
      @success = "The dealer busted! You win $#{session[:last_bet].to_i * 2}!"
      session[:total_money] += session[:last_bet].to_i * 2
      erb :game
    else
      redirect "/declare/winner"
    end
  end
end

before do
  @hide_dealers_cards_and_total = true
  @player_turn = false
end

get '/' do
  session.clear
  session[:total_money] = 500
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
  redirect "/bet"
end

get '/bet' do
  erb :bet
end

post '/bet' do
  if params[:bet].empty?
    @error = "Please enter how much would you like to bet!"
    halt erb :bet
  end

  session[:total_money] -= params[:bet].to_i
  session[:last_bet] = params[:bet].to_i
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

  check_if_win_or_bust_player(session[:player_cards])
  
  erb :game
end

post '/player/hit' do
  @player_turn = true
  session[:player_cards] << session[:deck].pop

  check_if_win_or_bust_player(session[:player_cards])

  erb :game
end

post '/player/stay' do
  @hide_dealers_cards_and_total = false

  check_if_win_or_bust_dealer(session[:dealer_cards])
end

post '/dealer/hit' do
  @hide_dealers_cards_and_total = false

  session[:dealer_cards] << session[:deck].pop

  check_if_win_or_bust_dealer(session[:dealer_cards])
end

get '/declare/winner' do
  @hide_dealers_card_and_total = false

  if calculate_total(session[:player_cards]) > calculate_total(session[:dealer_cards])
    @success = "Congratulations! #{session[:player_name]} wins $#{session[:last_bet].to_i * 2}!"
    session[:total_money] += session[:last_bet].to_i * 2
  elsif calculate_total(session[:player_cards]) < calculate_total(session[:dealer_cards])
    @defeat = "Sorry :( Dealer wins. You lost $#{session[:last_bet]}"
  else
    @info = "It's a tie! You get the $#{session[:last_bet]} back."
    session[:total_money] += session[:last_bet].to_i
  end

  erb :declare_winner
end
