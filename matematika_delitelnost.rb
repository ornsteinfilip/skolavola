module MatematikaDelitelnost
  class Web < Sinatra::Base
    include Constants
    
    URL_PREFIX = '/matematika/delitelnost'
    NUMBERS = (2..20).to_a
    
    set :views, File.dirname(__FILE__) + '/views'

    helpers do
      def url_prefix
        URL_PREFIX
      end
      
      def gcd(a, b)
        b.zero? ? a : gcd(b, a % b)
      end
      
      def lcm(a, b)
        (a * b) / gcd(a, b)
      end
    end

    get '/' do
      @title = "Dělitelnost"
      erb :delitelnost_index
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
        when 1 # NSD
          @a = NUMBERS.sample
          @b = NUMBERS.sample
        when 2 # NSN
          @a = NUMBERS.sample
          @b = NUMBERS.sample
        end
        
        erb :delitelnost_exercise
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
      when 1 # NSD
        begin
          user_answer = params[:answer].to_i
          a = params[:a].to_i
          b = params[:b].to_i
          correct_answer = gcd(a, b)
          correct = (user_answer == correct_answer)
          
          example = {
            question: "NSD(#{a}, #{b})",
            user_answer: user_answer.to_s,
            correct_answer: correct_answer.to_s,
            correct: correct
          }
        rescue
          correct = false
        end
      when 2 # NSN
        begin
          user_answer = params[:answer].to_i
          a = params[:a].to_i
          b = params[:b].to_i
          correct_answer = lcm(a, b)
          correct = (user_answer == correct_answer)
          
          example = {
            question: "NSN(#{a}, #{b})",
            user_answer: user_answer.to_s,
            correct_answer: correct_answer.to_s,
            correct: correct
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
        @examples = session[:examples] || []
        
        if session[:start_time]
          duration = (Time.now - session[:start_time])/@example_count
          @duration = duration.to_i
        else
          @duration = 0
        end
        
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
  end
end 