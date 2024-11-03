# Kroky ke spuštění:
# 1. Nainstaluj Ruby (https://www.ruby-lang.org/en/downloads/)
# 2. Nainstaluj gem Sinatra: gem install sinatra
# 3. Ulož tento soubor jako zlomky_http.rb
# 4. Spusť příkazem: ruby zlomky_http.rb
# 5. Otevři v prohlížeči http://localhost:4567

require 'sinatra'
require 'erb'

NUMBERS = (2..10).to_a
BIG_NUMBERS = (11..20).to_a

set :public_folder, 'public'
enable :sessions

get '/' do
  erb :index
end

post '/start' do
  session[:score] = 0
  session[:example_count] = 10
  session[:start_time] = Time.now
  session[:current_example] = 0
  session[:examples] = []
  
  redirect "/exercise/#{params[:choice]}"
end

get '/exercise/:type' do |type|
  return redirect '/' if session[:current_example] >= session[:example_count]
  
  @type = type.to_i
  @current = session[:current_example]
  @score = session[:score]
  
  case @type
  when 1
    @a = NUMBERS.sample
    @b = NUMBERS.sample
    multiplier = NUMBERS.sample
    @numerator = @a * multiplier
    @denominator = @b * multiplier
  when 2
    @a = NUMBERS.sample
    @b = NUMBERS.sample
    @c = NUMBERS.sample
    @d = NUMBERS.sample
    @operation = ['+', '-'].sample
  when 3
    @a = NUMBERS.sample
    @b = NUMBERS.sample
    @c = NUMBERS.sample
    @d = NUMBERS.sample
  when 4
    @a = BIG_NUMBERS.sample
    @b = NUMBERS.sample
  when 5
    @a = NUMBERS.sample
    @b = NUMBERS.sample
  end
  
  erb :exercise
end

post '/check/:type' do |type|
  type = type.to_i
  correct = false
  example = {}
  
  case type
  when 1
    begin
      user_num, user_denom = params[:answer].split('/').map(&:to_i)
      a = params[:a].to_i
      b = params[:b].to_i
      correct = (user_num.to_f/user_denom == a.to_f/b)
      example = {
        question: "#{params[:numerator]}/#{params[:denominator]}",
        user_answer: params[:answer],
        correct_answer: "#{a}/#{b}",
        correct: correct,
        fraction_value: a.to_f/b,
        numerator: a,
        denominator: b
      }
    rescue
      correct = false
    end
  when 2
    begin
      user_num, user_denom = params[:answer].split('/').map(&:to_i)
      a = params[:a].to_i
      b = params[:b].to_i
      c = params[:c].to_i
      d = params[:d].to_i
      operation = params[:operation]
      correct_num = operation == '+' ? (a*d + c*b) : (a*d - c*b)
      correct_denom = b*d
      correct = (user_num.to_f/user_denom == correct_num.to_f/correct_denom)
      example = {
        question: "#{a}/#{b} #{operation} #{c}/#{d}",
        user_answer: params[:answer],
        correct_answer: "#{correct_num}/#{correct_denom}",
        correct: correct,
        fraction_value: correct_num.to_f/correct_denom,
        numerator: correct_num,
        denominator: correct_denom
      }
    rescue
      correct = false
    end
  when 3
    answer = params[:answer]
    a = params[:a].to_i
    b = params[:b].to_i
    c = params[:c].to_i
    d = params[:d].to_i
    correct_symbol = if (a.to_f/b) > (c.to_f/d)
      ">"
    elsif (a.to_f/b) < (c.to_f/d)
      "<"
    else
      "="
    end
    correct = (answer == correct_symbol)
    example = {
      question: "#{a}/#{b} _ #{c}/#{d}",
      user_answer: answer,
      correct_answer: correct_symbol,
      correct: correct
    }
  when 4
    begin
      whole, fraction = params[:answer].split(' ')
      user_num, user_denom = fraction.split('/').map(&:to_i)
      whole = whole.to_i
      a = params[:a].to_i
      b = params[:b].to_i
      correct = ((whole + user_num.to_f/user_denom) == a.to_f/b)
      correct_whole = a/b
      correct_num = a % b
      example = {
        question: "#{a}/#{b}",
        user_answer: params[:answer],
        correct_answer: "#{correct_whole} #{correct_num}/#{b}",
        correct: correct,
        fraction_value: a.to_f/b,
        numerator: a,
        denominator: b
      }
    rescue
      correct = false
    end
  when 5
    begin
      user_decimal = params[:answer].gsub(',', '.').to_f
      a = params[:a].to_i
      b = params[:b].to_i
      correct = (user_decimal == (a.to_f/b).round(2))
      example = {
        question: "#{a}/#{b}",
        user_answer: params[:answer],
        correct_answer: (a.to_f/b).round(2).to_s,
        correct: correct,
        fraction_value: a.to_f/b,
        numerator: a,
        denominator: b
      }
    rescue
      correct = false
    end
  end

  session[:score] += 1 if correct
  session[:examples] << example
  session[:current_example] += 1
  
  if session[:current_example] >= session[:example_count]
    redirect '/result'
  else
    redirect "/exercise/#{type}"
  end
end

get '/result' do
  @score = session[:score]
  @example_count = session[:example_count]
  duration = (Time.now - session[:start_time])/@example_count
  @duration = duration.to_i
  @examples = session[:examples]
  
  @grade = @example_count - @score + 1
  @grade = 5 if @grade > 5
  
  @score_cz = case @score
  when 1
    'bod'
  when 2..4
    'body'
  else
    'bodů'
  end
  
  erb :result
end

__END__

@@ layout
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Procvičování zlomků</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      line-height: 1.6;
    }
    .container {
      background: #f5f5f5;
      padding: 20px;
      border-radius: 8px;
      margin-top: 20px;
    }
    .btn {
      display: inline-block;
      padding: 10px 20px;
      background: #007bff;
      color: white;
      text-decoration: none;
      border-radius: 5px;
      border: none;
      cursor: pointer;
      margin: 5px;
    }
    .fraction {
      font-size: 24px;
      margin: 20px 0;
    }
    input[type="text"] {
      padding: 8px;
      font-size: 16px;
      border-radius: 4px;
      border: 1px solid #ddd;
    }
    .correct {
      color: green;
    }
    .incorrect {
      color: red;
    }
    .radio-group {
      display: flex;
      gap: 20px;
      margin: 20px 0;
    }
    .radio-option {
      font-size: 20px;
    }
    @media (max-width: 600px) {
      body {
        padding: 10px;
      }
      .btn {
        display: block;
        width: 100%;
        margin: 10px 0;
      }
    }
  </style>
</head>
<body>
  <%= yield %>
</body>
</html>

@@ index
<h1>Procvičování zlomků</h1>

<div class="container">
  <h2>Vyber si typ úlohy:</h2>
  <form action="/start" method="post">
    <button class="btn" name="choice" value="1">1 - Krácení zlomků</button>
    <button class="btn" name="choice" value="2">2 - Sčítání a odčítání zlomků</button>
    <button class="btn" name="choice" value="3">3 - Porovnávání zlomků</button>
    <button class="btn" name="choice" value="4">4 - Převod na smíšená čísla</button>
    <button class="btn" name="choice" value="5">5 - Převod na desetinná čísla</button>
  </form>
</div>

@@ exercise
<div class="container">
  <h2>
    <% case @type %>
    <% when 1 %>
      Krácení zlomků
    <% when 2 %>
      Sčítání a odčítání zlomků
    <% when 3 %>
      Porovnávání zlomků
    <% when 4 %>
      Převod na smíšená čísla
    <% when 5 %>
      Převod na desetinná čísla
    <% end %>
  </h2>
  
  <p>Příklad <%= @current + 1 %> z <%= session[:example_count] %></p>
  <p>Skóre: <%= @score %></p>
  
  <div class="fraction">
    <% case @type %>
    <% when 1 %>
      <%= @numerator %>/<%= @denominator %> = ?
    <% when 2 %>
      <%= @a %>/<%= @b %> <%= @operation %> <%= @c %>/<%= @d %> = ?
    <% when 3 %>
      <%= @a %>/<%= @b %> _ <%= @c %>/<%= @d %>
    <% when 4 %>
      <%= @a %>/<%= @b %> = ?
    <% when 5 %>
      <%= @a %>/<%= @b %> = ?
    <% end %>
  </div>
  
  <form action="/check/<%= @type %>" method="post">
    <% case @type %>
    <% when 1 %>
      <input type="text" name="answer" placeholder="čitatel/jmenovatel" required inputmode="text" autocomplete="off" spellcheck="false">
      <input type="hidden" name="a" value="<%= @a %>">
      <input type="hidden" name="b" value="<%= @b %>">
      <input type="hidden" name="numerator" value="<%= @numerator %>">
      <input type="hidden" name="denominator" value="<%= @denominator %>">
    <% when 2 %>
      <input type="text" name="answer" placeholder="čitatel/jmenovatel" required inputmode="text" autocomplete="off" spellcheck="false">
      <input type="hidden" name="a" value="<%= @a %>">
      <input type="hidden" name="b" value="<%= @b %>">
      <input type="hidden" name="c" value="<%= @c %>">
      <input type="hidden" name="d" value="<%= @d %>">
      <input type="hidden" name="operation" value="<%= @operation %>">
    <% when 3 %>
      <div class="radio-group">
        <label class="radio-option">
          <input type="radio" name="answer" value="<" required> <
        </label>
        <label class="radio-option">
          <input type="radio" name="answer" value="=" required> =
        </label>
        <label class="radio-option">
          <input type="radio" name="answer" value=">" required> >
        </label>
      </div>
      <input type="hidden" name="a" value="<%= @a %>">
      <input type="hidden" name="b" value="<%= @b %>">
      <input type="hidden" name="c" value="<%= @c %>">
      <input type="hidden" name="d" value="<%= @d %>">
    <% when 4 %>
      <input type="text" name="answer" placeholder="celé čitatel/jmenovatel" required inputmode="text" autocomplete="off" spellcheck="false">
      <input type="hidden" name="a" value="<%= @a %>">
      <input type="hidden" name="b" value="<%= @b %>">
    <% when 5 %>
      <input type="text" name="answer" placeholder="desetinné číslo" required inputmode="decimal" autocomplete="off" spellcheck="false">
      <input type="hidden" name="a" value="<%= @a %>">
      <input type="hidden" name="b" value="<%= @b %>">
    <% end %>
    <button type="submit" class="btn">Odpovědět</button>
  </form>
</div>

@@ result
<div class="container">
  <h2>Výsledky</h2>
  <p>Získal/a jsi <%= @score %> <%= @score_cz %> z <%= @example_count %>.</p>
  <p>Jeden příklad ti průměrně trval <%= @duration %> vteřin(y).</p>
  <p>Máš to za <%= @grade %>.</p>
  
  <h3>Přehled příkladů:</h3>
  <% @examples.each_with_index do |example, index| %>
    <div class="<%= example[:correct] ? 'correct' : 'incorrect' %>">
      <p>
        Příklad <%= index + 1 %>: <%= example[:question] %><br>
        Tvoje odpověď: <%= example[:user_answer] %><br>
        Správná odpověď: <%= example[:correct_answer] %><br>
        <%= example[:correct] ? '✓ Správně' : '✗ Špatně' %>
      </p>
    </div>
  <% end %>
  
  <a href="/" class="btn">Zpět na začátek</a>
</div>
