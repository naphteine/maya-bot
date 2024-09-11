require 'date'
require 'telegram/bot'
require 'dentaku'
require 'open-uri'
require 'json'
require 'benchmark'

require_relative 'maya'

load('secrets.rb')

$log = "\n"

def maya_logger(text)
	log = "#{DateTime.now} #{text}"
	puts log
	$log += "\n" + log

	if $log.lines.length > 50
		open('logs/maya.log', 'a') { |f|
			f.write $log
		}

		$log = ""
	end

end

maya_logger("M A Y A waking up...")

# Globals
$waking_up = Process.clock_gettime(Process::CLOCK_MONOTONIC)

begin
	time = Benchmark.measure do
		$cats = JSON.load(URI.open("https://cat-fact.herokuapp.com/facts"))
	end
	maya_logger("DEBUG: Loaded #{$cats.length} data from Cat Facts API")
	puts "BENCHMARK Cats Facts API: #{time}"
rescue
	$cats = {
	}
	maya_logger("DEBUG: Couldn't load Cat Facts API. Creating empty hash")
end

begin
	time = Benchmark.measure do
		$stickers = JSON.load_file('assets/stickers.json')
	end
	maya_logger("DEBUG: Loaded #{$stickers.length} sticker hashes from file")
	puts "BENCHMARK Stickers load: #{time}"
rescue
	$stickers = {
	}
	maya_logger("DEBUG: No file, created new sticker hash")
end

begin
	time = Benchmark.measure do
		$photos = JSON.load_file('assets/photos.json')
	end
	maya_logger("DEBUG: Loaded #{$photos.length} photo hashes from file")
	puts "BENCHMARK photos load: #{time}"
rescue
	$photos = {
	}
	maya_logger("DEBUG: No file, created new photos hash")
end


# Methods
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

$forex_response = JSON.load(URI.open("https://www.frankfurter.app/latest?from=USD"))

def forex(message)
  lastThree = message[-3..]
  response = "IDK"
  lastThree.upcase!

  if lastThree == "ALL"
    output = "All FOREX data:\n"
    $forex_response["rates"].each { |k,v| output += "USD/#{k} = #{sprintf('%.2f', v)}\n" }
    return output
  end

  begin
    response = lastThree + " is " + ($forex_response["rates"][lastThree]).to_s
  rescue Exception => e
    puts e
    response = "I don't know?"
  end

  return response
end

def random_choice(message)
  return command_arguments(message).split(",").sample
end

maya_logger("M A Y A is now awake!")

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
				when /^\/time/i then reply_text = "日本時間は#{Maya.nihonjikan}でーす。"
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
						photo = JSON.load(URI.open("https://random.dog/woof.json"))['url']
						ext = File.extname(URI.parse(photo).path)
						case ext
						when ".mp4"
                            video = photo
                            photo = ""
                        when ".webm"
                            video = photo
                            photo = ""
						when ".gif"
							animation = photo
							photo = ""
						end
					rescue Exception => e
						reply_text = "No dogs for you! Bad person!!"
					end
				when /^\/shiba/i
					begin
						photo = JSON.load(URI.open("http://shibe.online/api/shibes?count=1&urls=true&httpsUrls=true"))[0]
					rescue Exception => e
						reply_text = "No shiba for you! Bad person!!"
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
                when /^\/forex/i
                  reply_text = forex(message.text)
                when /^\/choice/i
                  reply_text = random_choice(message.text)

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
				when /^Maya I need love$/i
					if message.from.id == $master_id
						sticker = ['menhera/nyan_love.webp', 'menhera/nyan_paws.webp', 'menhera/pillow_hug.webp'].sample
						reply_text = "I love you!!"
					else
						reply_text = "Thank you! But I only love my master.."
					end
				when /^Maya bring me water$/i
					if message.from.id == $master_id
						reply_text = "かしこまりました！　はい、どうぞう！　🥤🥤"
					else
						reply_text = "No! You bring me"
					end
				end

				# Send photos, stickers and text messages
				unless video.to_s.strip.empty?
					maya_logger "Sending to chat##{message.chat.id} #{message.from.id}@#{message.from.username}: VIDEO #{video}"
					puts "Going to send video"
					if $photos.has_key?(video)
						puts "Has key"
						bot.api.send_video(chat_id: message.chat.id, video: $photos[video])
					else
						puts "No key"
						sent = bot.api.send_video(chat_id: message.chat.id, video: video)
                        puts sent.to_s

						if sent['result']['animation']
							puts "Has anim object"
							$photos[video] = sent['result']['animation']['file_id']
						elsif sent['result']['video']
							puts "Has video object"
							$photos[video] = sent['result']['video']['file_id']
						end
					end
				end

                unless animation.to_s.strip.empty?
					maya_logger "Sending to chat##{message.chat.id} #{message.from.id}@#{message.from.username}: ANIM #{animation}"
					puts "Going to send animation"
					if $photos.has_key?(animation)
						puts "Has key"
						bot.api.send_animation(chat_id: message.chat.id, animation: $photos[animation])
						puts "Sent"
					else
						puts "No key"
						sent = bot.api.send_animation(chat_id: message.chat.id, animation: animation)
						puts "Sent"
						$photos[animation] = sent['result']['animation']['file_id']
						puts "Added key"
					end
				end

				unless photo.to_s.strip.empty?
					maya_logger "Sending to chat##{message.chat.id} #{message.from.id}@#{message.from.username}: IMG #{photo}"
					puts "Going to send image"
					if $photos.has_key?(photo)
						puts "Has key"
						bot.api.send_photo(chat_id: message.chat.id, photo: $photos[photo])
					else
						puts "No key"
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

maya_logger("M A Y A going to sleep...")

# Save hashes to file
begin
	File.open('assets/stickers.json', "w+") do |f|
		f << JSON.pretty_generate($stickers)
	end
	maya_logger("DEBUG: Saved #{$stickers.length} sticker hashes to file")
rescue Exception => e
	maya_logger("EXCEPTION: Couldn't save sticker ashes! #{e}")
end

begin
	File.open('assets/photos.json', "w+") do |f|
		f << JSON.pretty_generate($photos)
	end
	maya_logger("DEBUG: Saved #{$photos.length} photo hashes to file")
rescue Exception => e
	maya_logger("EXCEPTION: Couldn't save photo hashes! #{e}")
end

maya_logger("M A Y A asleep.. Zzz")

# Save log
open('logs/maya.log', 'a') { |f|
		f.write $log
}
