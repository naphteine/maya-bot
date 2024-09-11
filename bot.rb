require 'telegram_bot'
require 'date'
token = '1508647619:AAFOJVrNDnMzaZVNRvzw9SRB8qZk2H2RxmY'
bot = TelegramBot.new(token: token)
command_list = "/start /commands /username /firstname /clock"

def maya_logger(text)
	dateNow = DateTime.now
	puts "#{dateNow}\t#{text}"
	open('maya.log', 'a') { |f|
		f.puts "#{dateNow}\t#{text}"
	}
end

bot.get_updates(fail_silently: true) do |message|
	maya_logger "@#{message.from.username}: #{message.text}"
	command = message.get_command_for(bot)

	message.reply do |reply|
		case command
		when /start/i, /commands/i
			reply.text = command_list
		when /username/i
			reply.text = message.from.username
		when /firstname/i
			reply.text = message.from.first_name
		#when /site/i
			#bot.api.send_message(chat_id: message.chat.id, text: "https://www.omfgdogs.com/")
		#when /map/i
			#bot.api.send_location(chat_id: message.chat.id, latitude: 52.479761, longitude: 62.185661)
		when /clock/i
			dateNow = DateTime.now
			reply.text = dateNow
		else
			reply.text = "#{command.inspect} not found."
		end
		sentMessage = "sending #{reply.text.inspect} to @#{message.from.username}"
		maya_logger sentMessage
		reply.send_with(bot)
	end
end
