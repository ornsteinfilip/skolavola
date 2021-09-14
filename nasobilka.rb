#!/usr/bin/ruby

class NotInRange < StandardError; end

puts "\n===========================================\n\n"
puts "   !!!Vítej v programu N4S0B1LK4!!!   "
puts "\n===========================================\n"

puts "\nVyber zda chceš malou nebo velkou?\n"
puts "1) Malá násobilka"
puts "2) Velká násobilka"

choice = gets.chomp

begin
  choice = Integer(choice)
  raise NotInRange unless [1,2].include?(choice)
rescue ArgumentError, TypeError, NotInRange
  puts "Nesprávný vstup, zadej číslo 1 nebo 2!"
  exit!
end

NUMBERS = (2..10).to_a
BIG_NUMBERS = (10..100).to_a

puts "\n===========================================\n"

puts "Násobilka čísel: #{NUMBERS.join(', ')}"
puts "Zadej součin čísel následujících příkladů. Na konci se dozvíš, jak dobře jsis vedl/a."

score = 0
example_count = 10

start_time = Time.now
example_count.times do

  a = NUMBERS.sample
  case choice
  when 1
    b = NUMBERS.sample
  when 2
    b = BIG_NUMBERS.sample
  end

  total = a * b

  puts "\n#{a} x #{b} = ?"

  c = gets.chomp

  begin
    c = Integer(c)
  rescue ArgumentError, TypeError
    puts "Nesprávný vstup, zadej číslo!"
  end

  example = "#{a} x #{b} = #{total}"
  if c == total
    puts "Správně #{example}! [+1 bod]\n"
    score += 1
  else
    puts "Nesprávně #{example}! [0 bodů]\n"
  end

end
end_time = Time.now

duration = (end_time - start_time)/example_count

grade = example_count - score + 1
grade = 5 if grade > 5

score_cz = case score
when 1
  'bod'
when [2,3,4].include?(score)
  'body'
else
  'bodů'
end

puts "\nZískal\a jsi #{score} #{score_cz} z #{example_count}."
puts "Jeden příklad ti průměrně trval #{duration} vteřin."
puts "Máš to za #{grade}."

puts "\n===========================================\n"
puts "Konec programu. Uč se pilně a klidně omylně."
puts "\n===========================================\n"
