# Kroky ke spuštění:
# 1. Nainstaluj Ruby (https://www.ruby-lang.org/en/downloads/)
# 2. Nainstaluj gem Sinatra: gem install sinatra
# 3. Ulož tento soubor jako zlomky_http.rb
# 4. Spusť příkazem: ruby zlomky_http.rb -o 0.0.0.0
# 5. Otevři v prohlížeči http://localhost:4567 nebo http://[IP adresa]:4567

require 'sinatra'
require 'erb'

NUMBERS = (2..10).to_a
BIG_NUMBERS = (11..20).to_a

set :public_folder, 'public'
enable :sessions

HALLOWEEN_MODE = true

def gcd(a, b)
  b.zero? ? a : gcd(b, a % b)
end

def reduce_fraction(numerator, denominator)
  gcd = gcd(numerator.abs, denominator.abs)
  [numerator/gcd, denominator/gcd]
end

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
      user_num = params[:numerator].to_i
      user_denom = params[:denominator].to_i
      numerator = params[:numerator_orig].to_i
      denominator = params[:denominator_orig].to_i
      a = params[:a].to_i
      b = params[:b].to_i
      
      # Kontrola, zda je zlomek správně zkrácený a má stejnou hodnotu
      correct = (user_num.to_f/user_denom == a.to_f/b) && 
                reduce_fraction(user_num, user_denom) == [user_num, user_denom]
                
      reduced_a, reduced_b = reduce_fraction(numerator, denominator)
      example = {
        question: "#{numerator}/#{denominator}",
        user_answer: "#{user_num}/#{user_denom}",
        correct_answer: "#{reduced_a}/#{reduced_b}",
        correct: correct,
        fraction_value: a.to_f/b,
        numerator: reduced_a,
        denominator: reduced_b
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
      reduced_num, reduced_denom = reduce_fraction(correct_num, correct_denom)
      example = {
        question: "#{a}/#{b} #{operation} #{c}/#{d}",
        user_answer: params[:answer],
        correct_answer: "#{reduced_num}/#{reduced_denom}",
        correct: correct,
        fraction_value: correct_num.to_f/correct_denom,
        numerator: reduced_num,
        denominator: reduced_denom
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
      whole = params[:whole].to_i
      user_num = params[:numerator].to_i
      user_denom = params[:denominator].to_i
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
  <title><%= HALLOWEEN_MODE ? "🎃 Strašidelné zlomky" : "Procvičování zlomků" %></title>
  <style>
    :root {
      <% if HALLOWEEN_MODE %>
        --bg-color: #1a1a1a;
        --text-color: #ff9800;
        --container-bg: #2d2d2d;
        --btn-bg: #ff5722;
        --btn-hover: #f4511e;
        --border-color: #ff9800;
      <% else %>
        --bg-color: #ffffff;
        --text-color: #000000;
        --container-bg: #f5f5f5;
        --btn-bg: #007bff;
        --btn-hover: #0056b3;
        --border-color: #ddd;
      <% end %>
    }
    
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      line-height: 1.6;
      background-color: var(--bg-color);
      color: var(--text-color);
      <%= "background-image: url('data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI1MCIgaGVpZ2h0PSI1MCI+PHRleHQ+8J+NqDwvdGV4dD48L3N2Zz4=');" if HALLOWEEN_MODE %>
    }
    .container {
      background: var(--container-bg);
      padding: 20px;
      border-radius: 8px;
      margin-top: 20px;
      <%= "border: 2px solid var(--border-color);" if HALLOWEEN_MODE %>
      <%= "box-shadow: 0 0 10px var(--border-color);" if HALLOWEEN_MODE %>
    }
    .btn {
      display: inline-block;
      padding: 10px 20px;
      background: var(--btn-bg);
      color: white;
      text-decoration: none;
      border-radius: 5px;
      border: none;
      cursor: pointer;
      margin: 5px;
    }
    .btn:hover {
      background: var(--btn-hover);
      <%= "transform: scale(1.05);" if HALLOWEEN_MODE %>
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
    .fraction-input, .mixed-number-input {
      display: flex;
      align-items: center;
      gap: 8px;
      margin: 10px 0;
    }
    .fraction-input input, .mixed-number-input input {
      width: 80px;
    }
    .mixed-number-input input:first-child {
      width: 60px;
    }
    .math-fraction {
      display: inline-flex;
      flex-direction: column;
      text-align: center;
      vertical-align: middle;
      margin: 0 5px;
    }
    
    .math-fraction > span {
      padding: 0 5px;
    }
    
    .math-fraction .numerator {
      border-bottom: 2px solid var(--text-color);
      padding-bottom: 3px;
    }
    
    .math-fraction .denominator {
      padding-top: 3px;
    }
    
    .math-fraction.large {
      font-size: 24px;
    }
    
    .fraction-operation {
      margin: 0 10px;
      font-size: 24px;
    }
    
    .exercise-container {
      display: flex;
      align-items: center;
      gap: 20px;
      margin: 20px 0;
    }
    
    .exercise-answer {
      flex: 1;
    }
    
    .fraction-input {
      display: inline-flex;
      flex-direction: column;
      align-items: center;
      gap: 3px;
    }
    
    .fraction-input input {
      width: 80px;
      text-align: center;
    }
    
    .fraction-input .numerator {
      border-bottom: 2px solid var(--text-color);
      padding-bottom: 3px;
    }
    
    .fraction-input .denominator {
      padding-top: 3px;
    }
    
    .fraction-line {
      height: 2px;
      background-color: var(--text-color);
      width: 100%;
    }
    
    .exercise-form {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 20px;
    }
    
    .exercise-content {
      display: flex;
      align-items: center;
      gap: 20px;
      width: 100%;
    }
    
    .submit-button {
      margin-top: 20px;
      text-align: center;
    }
  </style>
</head>
<body>
  <%= yield %>
</body>
</html>

@@ index
<h1><%= HALLOWEEN_MODE ? "🎃 Strašidelné zlomky 👻" : "Procvičování zlomků" %></h1>

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
      <%= HALLOWEEN_MODE ? "🎃 Strašidelné krácení" : "Krácení zlomků" %>
    <% when 2 %>
      <%= HALLOWEEN_MODE ? "👻 Duchařské sčítání a odčítání" : "Sčítání a odčítání zlomků" %>
    <% when 3 %>
      <%= HALLOWEEN_MODE ? "🦇 Děsivé porovnávání" : "Porovnávání zlomků" %>
    <% when 4 %>
      <%= HALLOWEEN_MODE ? "🕸️ Pavučinový převod" : "Převod na smíšená čísla" %>
    <% when 5 %>
      <%= HALLOWEEN_MODE ? "💀 Kostlivý převod" : "Převod na desetinná čísla" %>
    <% end %>
  </h2>
  
  <p>Příklad <%= @current + 1 %> z <%= session[:example_count] %></p>
  <p>Skóre: <%= @score %></p>
  
  <form action="/check/<%= @type %>" method="post" class="exercise-form">
    <div class="exercise-content">
      <div class="exercise-problem">
        <% case @type %>
        <% when 1 %>
          <div class="math-fraction large">
            <span class="numerator"><%= @numerator %></span>
            <span class="denominator"><%= @denominator %></span>
          </div>
          = 
        <% when 2 %>
          <div class="math-fraction large">
            <span class="numerator"><%= @a %></span>
            <span class="denominator"><%= @b %></span>
          </div>
          <span class="fraction-operation"><%= @operation %></span>
          <div class="math-fraction large">
            <span class="numerator"><%= @c %></span>
            <span class="denominator"><%= @d %></span>
          </div>
          = 
        <% when 3 %>
          <div class="math-fraction large">
            <span class="numerator"><%= @a %></span>
            <span class="denominator"><%= @b %></span>
          </div>
          _ 
          <div class="math-fraction large">
            <span class="numerator"><%= @c %></span>
            <span class="denominator"><%= @d %></span>
          </div>
          <input type="hidden" name="a" value="<%= @a %>">
          <input type="hidden" name="b" value="<%= @b %>">
          <input type="hidden" name="c" value="<%= @c %>">
          <input type="hidden" name="d" value="<%= @d %>">
        <% when 4 %>
          <div class="math-fraction large">
            <span class="numerator"><%= @a %></span>
            <span class="denominator"><%= @b %></span>
          </div>
          = 
        <% end %>
      </div>

      <div class="exercise-answer">
        <% case @type %>
        <% when 1 %>
          <div class="fraction-input">
            <input type="text" name="numerator" inputmode="numeric" placeholder="čitatel" required autocomplete="off" class="numerator">
            <input type="text" name="denominator" inputmode="numeric" placeholder="jmenovatel" required autocomplete="off" class="denominator">
          </div>
          <input type="hidden" name="numerator_orig" value="<%= @numerator %>">
          <input type="hidden" name="denominator_orig" value="<%= @denominator %>">
          <input type="hidden" name="a" value="<%= @a %>">
          <input type="hidden" name="b" value="<%= @b %>">
        <% when 2 %>
          <div class="fraction-input">
            <input type="text" name="numerator" inputmode="numeric" placeholder="čitatel" required autocomplete="off" class="numerator">
            <input type="text" name="denominator" inputmode="numeric" placeholder="jmenovatel" required autocomplete="off" class="denominator">
          </div>
        <% when 3 %>
          <div class="radio-group">
            <label class="radio-option btn">
              <input type="radio" name="answer" value="<" required>
              <span>&lt;</span>
            </label>
            <label class="radio-option btn">
              <input type="radio" name="answer" value="=" required>
              <span>=</span>
            </label>
            <label class="radio-option btn">
              <input type="radio" name="answer" value=">" required>
              <span>&gt;</span>
            </label>
          </div>
        <% when 4 %>
          <div class="exercise-answer">
            <div class="mixed-number-input">
              <input type="text" name="whole" inputmode="numeric" placeholder="celá část" required autocomplete="off">
              <div class="fraction-input">
                <input type="text" name="numerator" inputmode="numeric" placeholder="čitatel" required autocomplete="off" class="numerator">
                <input type="text" name="denominator" inputmode="numeric" placeholder="jmenovatel" required autocomplete="off" class="denominator">
              </div>
            </div>
            <input type="hidden" name="a" value="<%= @a %>">
            <input type="hidden" name="b" value="<%= @b %>">
          </div>
        <% when 5 %>
          <div class="exercise-content">
            <div class="exercise-problem">
              <div class="math-fraction large">
                <span class="numerator"><%= @a %></span>
                <span class="denominator"><%= @b %></span>
              </div>
              = 
            </div>
            <div class="exercise-answer">
              <input type="text" name="answer" inputmode="decimal" placeholder="desetinné číslo" required autocomplete="off">
              <input type="hidden" name="a" value="<%= @a %>">
              <input type="hidden" name="b" value="<%= @b %>">
            </div>
          </div>
        <% end %>
      </div>
    </div>
    
    <div class="submit-button">
      <button type="submit" class="btn">Odpovědět</button>
    </div>
  </form>
</div>

<div class="container">
  <a href="/" class="small-btn">Restart</a>
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
