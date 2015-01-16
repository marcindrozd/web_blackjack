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

  def winner(msg)
    @play_again = true
    @player_turn = false
    @dealer_button = false
    session[:total_money] += session[:last_bet].to_i
    @winner = "#{session[:player_name]} wins! #{msg}"
  end

  def loser(msg)
    @play_again = true
    @player_turn = false
    @dealer_button = false
    session[:total_money] -= session[:last_bet].to_i
    @loser = "#{session[:player_name]} loses! #{msg}"
  end

  def tie(msg)
    @play_again = true
    @player_turn = false
    @dealer_button = false
    @winner = "It's a tie! #{msg}"
  end

  # extends the String class to check if number was entered
  class String
    def numeric?
      Float(self) != nil rescue false
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
  if session[:total_money] == 0
    redirect "/game_over"
  end

  erb :bet
end

post '/bet' do
  if params[:bet].empty?
    @error = "Please enter how much would you like to bet!"
    halt erb :bet
  elsif !params[:bet].numeric?
    @error = "Please enter a number!"
    halt erb :bet
  elsif params[:bet].to_i.abs > session[:total_money]
    @error = "You cannot bet more than your total: #{session[:total_money]}!"
    halt erb :bet
  else
    session[:last_bet] = params[:bet].to_i.abs
    redirect "/game"
  end
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
    winner("You hit Blackjack!")
  end
  
  erb :game
end

post '/player/hit' do
  @player_turn = true
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])

  if player_total == 21
    winner("You hit Blackjack!")
  elsif player_total > 21
    loser("You busted!")
  end

  erb :game, layout: false
end

post '/player/stay' do
  @hide_dealers_cards_and_total = false

  dealer_total = calculate_total(session[:dealer_cards])
  
  if dealer_total == 21
    loser("The dealer hit Blackjack!")
  else
    redirect '/dealer/hit'
  end
end

get '/dealer/hit' do
  @hide_dealers_cards_and_total = false
  @dealer_button = true

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == 21
    loser("The dealer hit Blackjack!")
  elsif dealer_total > 21
    winner("The dealer busted!")
  elsif dealer_total >= 17
    redirect '/declare/winner'
  else
    @show_dealer_hit_button = true
  end

  erb :game, layout: false
end
    
post '/dealer/hit' do
  @hide_dealers_cards_and_total = false
  @dealer_button = true

  session[:dealer_cards] << session[:deck].pop
  redirect '/dealer/hit'
end

get '/declare/winner' do
  @hide_dealers_card_and_total = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total > dealer_total
    winner("Player had #{player_total} vs. dealer's #{dealer_total}.")
  elsif player_total < dealer_total
    loser("Player had #{player_total} vs. dealer's #{dealer_total}.")
  else
    tie("Player and dealer tied at #{player_total}.")
  end

  erb :game, layout: false
end

get '/game_over' do
  if session[:total_money] == 0
    @no_money = true
    @defeat = "Sorry, you have no more money to bet... :("
  end

  erb :game_over
end