module MatematikaZlomky
  class Web < Sinatra::Base
    include Constants
    
    NUMBERS = (2..10).to_a
    BIG_NUMBERS = (11..20).to_a
    URL_PREFIX = '/matematika/zlomky'
    
    set :views, File.dirname(__FILE__) + '/views'

    # Přidáme helper pro přístup k URL_PREFIX v šablonách
    helpers do
      def url_prefix
        URL_PREFIX
      end
    end

    def gcd(a, b)
      b.zero? ? a : gcd(b, a % b)
    end

    def reduce_fraction(numerator, denominator)
      gcd = gcd(numerator.abs, denominator.abs)
      [numerator/gcd, denominator/gcd]
    end

    def fraction_to_s(rational)
      "#{rational.numerator}/#{rational.denominator}"
    end

    def generate_addition_subtraction
      operation = [:+, :-].sample
      
      loop do
        # Generování prvního zlomku
        a = rand(1..10)
        b = rand(1..10)
        first = Rational(a, b)
        
        # Generování druhého zlomku
        c = rand(1..10)
        d = rand(1..10)
        second = Rational(c, d)
        
        # Vypočítáme výsledek
        result = operation == :+ ? first + second : first - second
        
        # Pokud je výsledek záporný, pokračujeme v generování
        next if result < 0
        
        return {
          a: a,
          b: b,
          c: c,
          d: d,
          operation: operation == :+ ? '+' : '-',
          result: result,
          question: "#{fraction_to_s(first)} #{operation} #{fraction_to_s(second)} = "
        }
      end
    end

    get '/' do
      @title = "Zlomky"
      erb :index
    end

    post "/start" do
      session[:score] = 0
      session[:example_count] = 10
      session[:start_time] = Time.now
      session[:current_example] = 0
      session[:examples] = []
      
      redirect "#{URL_PREFIX}/exercise/#{params[:choice]}"
    end

    get "/exercise/:type" do |type|
      begin
        redirect "#{URL_PREFIX}/" if !session[:current_example] || !session[:example_count]
        return redirect "#{URL_PREFIX}/" if session[:current_example] >= session[:example_count]
        
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
          example_data = generate_addition_subtraction
          session[:example_data] = example_data
          @a = example_data[:a]
          @b = example_data[:b]
          @c = example_data[:c]
          @d = example_data[:d]
          @operation = example_data[:operation]
          @question = example_data[:question]
        when 3
          @a = NUMBERS.sample
          @b = NUMBERS.sample
          @c = NUMBERS.sample
          @d = NUMBERS.sample
        when 4
          # Generujeme čísla tak, aby zbytek po dělení nebyl 0
          loop do
            @a = BIG_NUMBERS.sample  # čitatel (11-20)
            @b = NUMBERS.sample      # jmenovatel (2-10)
            
            # Pokračuj v generování, pokud by byl zbytek 0
            next if (@a % @b) == 0
            
            break
          end
        when 5
          @a = NUMBERS.sample
          @b = NUMBERS.sample
        end
        
        erb :exercise
      rescue => e
        puts "Chyba při renderování exercise: #{e.message}"
        puts e.backtrace
        redirect "#{URL_PREFIX}/"
      end
    end

    post "/check/:type" do |type|
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
          example_data = session[:example_data]
          
          correct_num = example_data[:operation] == '+' ? 
            (example_data[:a]*example_data[:d] + example_data[:c]*example_data[:b]) : 
            (example_data[:a]*example_data[:d] - example_data[:c]*example_data[:b])
          correct_denom = example_data[:b]*example_data[:d]
          
          reduced_user = reduce_fraction(user_num, user_denom)
          reduced_correct = reduce_fraction(correct_num, correct_denom)
          correct = (reduced_user == reduced_correct)
          
          reduced_num, reduced_denom = reduce_fraction(correct_num, correct_denom)
          example = {
            question: example_data[:question],
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
            question: session[:example_data][:question],
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
          # Přijmeme jak čárku, tak tečku
          user_decimal = params[:answer].gsub(',', '.').to_f
          a = params[:a].to_i
          b = params[:b].to_i
          correct_result = (a.to_f/b).round(2)
          correct = (user_decimal == correct_result)
          example = {
            question: "#{a}/#{b}",
            user_answer: params[:answer],
            correct_answer: correct_result.to_s.gsub('.', ','), # Zobrazíme s čárkou
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
        redirect "#{URL_PREFIX}/result"
      else
        redirect "#{URL_PREFIX}/exercise/#{type}"
      end
    end

    get "/result" do
      begin
        redirect "#{URL_PREFIX}/" unless session[:score] && session[:example_count] && session[:start_time]
        
        @score = session[:score]
        @example_count = session[:example_count]
        
        if session[:start_time]
          duration = (Time.now - session[:start_time])/@example_count
          @duration = duration.to_i
        else
          @duration = 0
        end
        
        @examples = session[:examples] || []
        
        @grade = if @score && @example_count
          grade = @example_count - @score + 1
          [grade, 5].min
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
        redirect "#{URL_PREFIX}/"
      end
    end

    run! if app_file == $0
  end
end
