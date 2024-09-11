require 'date'
require 'telegram/bot'
require 'dentaku'
require 'open-uri'
require 'json'

load('secrets.rb')

def maya_logger(text)
	puts "#{DateTime.now} #{text}"
	open('logs/maya.log', 'a') { |f|
		f.puts "#{DateTime.now} #{text}"
	}
end

maya_logger("Maya is waking up...")

# Globals
$waking_up = Process.clock_gettime(Process::CLOCK_MONOTONIC)

begin
	$cats = JSON.load(URI.open("https://cat-fact.herokuapp.com/facts"))
	maya_logger("DEBUG: Loaded #{$cats.length} data from Cat Facts API")
rescue
	$cats = {
	}
	maya_logger("DEBUG: Couldn't load Cat Facts API. Creating empty hash")
end

begin
	$stickers = JSON.load_file('stickers.json')
	maya_logger("DEBUG: Loaded #{$stickers.length} sticker hashes from file")
rescue
	$stickers = {
	}
	maya_logger("DEBUG: No file, created new sticker hash")
end

begin
	$photos = JSON.load_file('photos.json')
	maya_logger("DEBUG: Loaded #{$photos.length} photo hashes from file")
rescue
	$photos = {
	}
	maya_logger("DEBUG: No file, created new photos hash")
end


# Methods
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

maya_logger("Maya is now awake!")

begin
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
						'anim id est laborum.'],
					[4, 'Cat Facts', $cats.sample['text']]
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
						reply_text = "はずかしい 😳"
					else
						reply_text = "Sorry, but I love and only will sleep with.. my master 💕"
					end
				when /(^\/cat$)|(^\/cat@Mayachanbot$)/i
					begin
						reply_text = $cats.sample['text']
					rescue Exception => e
						reply_text = "No cats for today.."
					end
				when /^\/dogs/i
					begin
						photo = JSON.load(URI.open("http://shibe.online/api/shibes?count=1&urls=true&httpsUrls=true"))[0]
					rescue Exception => e
						reply_text = "No dogs for you! Bad person!!"
					end
				when /(^\/cats$)|(^\/cats@Mayachanbot$)/i
					begin
						photo = JSON.load(URI.open("https://aws.random.cat/meow"))['file']
					rescue Exception => e
						reply_text = "No cats for you! Bad person!!"
					end
				when /(^\/foxes$)|(^\/foxes@Mayachanbot$)/i
					begin
						photo = JSON.load(URI.open("https://randomfox.ca/floof/"))['image']
					rescue Exception => e
						reply_text = "No foxes for you! Bad person!!"
					end

				# Chatting
				when /^Maya$/i
					if message.from.id == $master_id
						sticker = 'menhera/nani.webp'
					else
						reply_text = "???"
					end
				when /^Maya I love you$/i
					if message.from.id == $master_id
						sticker = ['menhera/nyan_love.webp', 'menhera/nyan_paws.webp', 'menhera/pillow_hug.webp'].sample
					else
						reply_text = "Thank you! But I love my master.."
					end
				end

				# Send photos, stickers and text messages
				unless photo.to_s.strip.empty?
					maya_logger "Sending to chat##{message.chat.id} #{message.from.id}@#{message.from.username}: IMG #{photo}"
					if $photos.has_key?(photo)
						bot.api.send_photo(chat_id: message.chat.id, photo: $photos[photo])
					else
						sent = bot.api.send_photo(chat_id: message.chat.id, photo: photo)
						$photos[photo] = sent['result']['photo'][sent['result']['photo'].length - 1]['file_id']
					end
				end

				unless sticker.to_s.strip.empty?
					maya_logger "Sending to chat##{message.chat.id} #{message.from.id}@#{message.from.username}: STICKER #{sticker}"
					if $stickers.has_key?(sticker)
						bot.api.send_sticker(chat_id: message.chat.id, sticker: $stickers[sticker])
					else
						$stickers[sticker] = bot.api.send_sticker(chat_id: message.chat.id, sticker: Faraday::UploadIO.new(sticker, 'image/webp'))['result']['sticker']['file_id']
					end
				end

				unless reply_text.to_s.strip.empty?
					maya_logger "Sending to chat##{message.chat.id} #{message.from.id}@#{message.from.username}: #{reply_text}"
					bot.api.send_message(chat_id: message.chat.id, text: reply_text)
				end
			end
		end
	end
rescue Exception => e
	maya_logger("EXCEPTION: #{e}")
end

maya_logger("Maya going down...")

# Save hashes to file
begin
	File.open('stickers.json', "w+") do |f|
		f << $stickers.to_json
	end
	maya_logger("DEBUG: Saved #{$stickers.length} sticker hashes to file")
rescue Exception => e
	maya_logger("EXCEPTION: Couldn't save sticker ashes! #{e}")
end

begin
	File.open('photos.json', "w+") do |f|
		f << $photos.to_json
	end
	maya_logger("DEBUG: Saved #{$photos.length} photo hashes to file")
rescue Exception => e
	maya_logger("EXCEPTION: Couldn't save photo hashes! #{e}")
end

maya_logger("さようなら。。。")