require 'bundler/setup'
require 'sinatra'
require 'sinatra/base'
require 'erb'

class ZlomkyApp < Sinatra::Base
  # Konfigurace pro Glitch.com
  set :port, ENV['PORT'] || 3000
  set :bind, '0.0.0.0'
  
  set :public_folder, 'public'
  enable :sessions
  
  NUMBERS = (2..10).to_a
  BIG_NUMBERS = (11..20).to_a
  HALLOWEEN_MODE = true

  set :views, File.dirname(__FILE__) + '/views'

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
    begin
      redirect '/' if !session[:current_example] || !session[:example_count]
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
    rescue => e
      puts "Chyba při renderování exercise: #{e.message}"
      puts e.backtrace
      redirect '/'
    end
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
        
        reduced_user = reduce_fraction(user_num, user_denom)
        reduced_original = reduce_fraction(numerator, denominator)
        correct = reduced_user == reduced_original
        
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
        user_num = params[:numerator].to_i
        user_denom = params[:denominator].to_i
        a = params[:a].to_i
        b = params[:b].to_i
        c = params[:c].to_i
        d = params[:d].to_i
        operation = params[:operation]
        
        correct_num = operation == '+' ? (a*d + c*b) : (a*d - c*b)
        correct_denom = b*d
        
        reduced_user = reduce_fraction(user_num, user_denom)
        reduced_correct = reduce_fraction(correct_num, correct_denom)
        correct = (reduced_user == reduced_correct)
        
        reduced_num, reduced_denom = reduce_fraction(correct_num, correct_denom)
        example = {
          question: "#{a}/#{b} #{operation} #{c}/#{d}",
          user_answer: "#{user_num}/#{user_denom}",
          correct_answer: "#{reduced_num}/#{reduced_denom}",
          correct: correct,
          fraction_value: correct_num.to_f/correct_denom,
          numerator: reduced_num,
          denominator: reduced_denom
        }
      rescue => e
        correct = false
        example = {
          question: "#{params[:a]}/#{params[:b]} #{params[:operation]} #{params[:c]}/#{params[:d]}",
          user_answer: "#{params[:numerator]}/#{params[:denominator]}",
          correct_answer: "chyba výpočtu",
          correct: false
        }
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
    begin
      # Kontrola existence session proměnných
      redirect '/' unless session[:score] && session[:example_count] && session[:start_time]
      
      @score = session[:score]
      @example_count = session[:example_count]
      
      # Ošetření výpočtu duration
      if session[:start_time]
        duration = (Time.now - session[:start_time])/@example_count
        @duration = duration.to_i
      else
        @duration = 0
      end
      
      @examples = session[:examples] || []
      
      # Ošetření výpočtu známky
      @grade = if @score && @example_count
        grade = @example_count - @score + 1
        [grade, 5].min  # Omezení na maximum 5
      else
        5
      end
      
      @score_cz = case @score
      when 1
        'bod'
      when 2..4
        'body'
      else
        'bodů'
      end
      
      erb :result
    rescue => e
      puts "Chyba při zobrazení výsledků: #{e.message}"
      puts e.backtrace
      redirect '/'
    end
  end

  run! if app_file == $0
end
