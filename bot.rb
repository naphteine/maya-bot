require 'date'
require 'telegram/bot'
require 'dentaku'

load('secrets.rb')

$waking_up = Process.clock_gettime(Process::CLOCK_MONOTONIC)

def maya_logger(text)
	puts "#{DateTime.now} #{text}"
	open('logs/maya.log', 'a') { |f|
		f.puts "#{DateTime.now} #{text}"
	}
end

def nihonjikan()
	return DateTime.now.new_offset('+09:00').strftime("%H:%M")
end

def awake
	raw_seconds = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - $waking_up).round()
	raw_minutes = raw_seconds / 60
	hours = raw_minutes / 60
	seconds = raw_seconds - raw_minutes * 60
	minutes = raw_minutes - hours * 60

	if raw_seconds > 7260
		output = "#{hours} hours and #{minutes} minutes"
	elsif raw_seconds > 7201
		output = "#{hours} hours"
	elsif raw_seconds > 3659
		output = "#{hours} hour and #{minutes} minutes"
	elsif raw_seconds > 3599
		output = "#{hours} hour"
	elsif raw_seconds > 119
		output = "#{minutes} minutes and #{seconds} seconds"
	elsif raw_seconds > 59
		output = "#{minutes} minute and #{seconds} seconds"
	else
		output = "#{seconds} seconds"
	end

	return output
end

def command_arguments(command)
	return command.split(/(.+?)\s(.+)/)[-1]
end

def calculate(text)
	input = command_arguments(text)
	operation = input.split(/^([-+]? ?(\d+|\(\g<1>\))( ?[-+*\/] ?\g<1>)?)$/)
	operation = operation[1]

	if operation.nil?
		return "It's not right, mate"
	else
		calculator = Dentaku::Calculator.new
		calculated = calculator.evaluate(operation)

		if calculated.nil?
			return "Why you did that >:("
		else
			maya_logger("Math calculation: #{operation} = #{calculated}")
			return "#{calculated}"
		end
	end
end

maya_logger("Maya is waking up...")

Telegram::Bot::Client.run($token) do |bot|
	bot.listen do |message|
		case message
		when Telegram::Bot::Types::InlineQuery
			results = [
				[1, 'Clock', "日本時間は#{nihonjikan}でーす。"],
				[2, 'Awake', "#{awake()} 😪"],
				[3, 'Lorem', 'Lorem ipsum dolor sit amet, consectetur '\
					'adipisicing elit, sed do eiusmod tempor incididunt ut '\
					'labore et doloremagna aliqua. Ut enim ad minim veniam, '\
					'quis nostrud exercitation ullamco laboris nisi ut aliquip '\
					'ex ea commodo consequat. Duis aute irure dolor in '\
					'reprehenderit in voluptate velit esse cillum dolore eu '\
					'fugiat nulla pariatur. Excepteur sint occaecat cupidatat '\
					'non proident, sunt in culpa qui officia deserunt mollit '\
					'anim id est laborum.']
			].map do |arr|
				Telegram::Bot::Types::InlineQueryResultArticle.new(
					id: arr[0],
					title: arr[1],
					input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(message_text: arr[2])
				)
			end
			bot.api.answer_inline_query(inline_query_id: message.id, results: results, cache_time: 5)
			maya_logger "InlineQuery activity!"
		when Telegram::Bot::Types::Message
			maya_logger "chat##{message.chat.id} #{message.from.id}@#{message.from.username}: #{message.text}"

			case message.text
			# Commands
			when /^\/start/i then reply_text = "摩耶ちゃんでーす！"
			when /^\/time/i then reply_text = "日本時間は#{nihonjikan}でーす。"
			when /^\/map/i
				bot.api.send_location(chat_id: message.chat.id, latitude: 52.479761, longitude: 62.185661)
				reply_text = ["家", "いえ", "お父の家", "ハハハハ"].sample
			when /^\/awake/i then reply_text = "#{awake()} 😪"
			when /^\/love/i then reply_text = "あたしも好きよ！　マスターを。。。"
			when /^\/math/i then reply_text = calculate(message.text)
			when /^\/sleep/i
				if message.from.id == $master_id
					reply_text = "Noo.. Sleeping with master 😳😳😳"
				else
					reply_text = "I only sleep with master... バカ"
				end

			# Chatting
			when /^Maya$/i
				if message.from.id == $master_id
					reply_text = "Yes, master?"
				else
					reply_text = "What?"
				end
			end

			unless reply_text.to_s.strip.empty?
				maya_logger "Sending to chat##{message.chat.id} #{message.from.id}@#{message.from.username}: #{reply_text}"
				bot.api.send_message(chat_id: message.chat.id, text: reply_text)
			end
		end
	end
end

maya_logger("Maya going down... さようなら。")
