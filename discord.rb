require 'discordrb'

load('secrets.rb')

$isplaying = 0
$log = "\n"

def maya_logger(text)
	log = "#{DateTime.now} #{text}"
	puts log
	$log += "\n" + log

	if $log.lines.length > 50
		open('logs/discord.log', 'a') { |f|
			f.write $log
		}

		$log = ""
	end

end

bot = Discordrb::Commands::CommandBot.new token: $dctoken, client_id: 836975553759543358, prefix: '!', advanced_functionality: true

# Mentions
bot.mention do |event|
	maya_logger("Catched: Mention. User: #{event.user.name}")
	event.user.pm('おはよう！')
end

# Messages
bot.message(content: 'Ping!') do |event|
	maya_logger("Catched: Ping!. User: #{event.user.name}")
	m = event.respond('ポン！')
	m.edit "「ポン！」は#{Time.now - event.timestamp}秒かかりました。"
end

# Commands
bot.command :user do |event|
	maya_logger("Catched: CMD user. User: #{event.user.name}")
	event.user.name
end

bot.command(:bold, chain_usable: true) do |event, *args|
	maya_logger("Catched: CMD bold. User: #{event.user.name}")
	"**#{args.join(' ')}**"
end

bot.command(:italic, chain_usable: true) do |event, *args|
	maya_logger("Catched: CMD italic. User: #{event.user.name}")
	"*#{args.join(' ')}*"
end

bot.command(:invite, chain_usable: false) do |event|
	maya_logger("Catched: CMD invite. User: #{event.user.name}")
	event.bot.invite_url
end

bot.command(:random, min_args: 0, max_args: 2, description: 'MinとMaxの間欄ドムランダムを作ること', usage: 'random [min/max] [max]') do |event, min, max|
	maya_logger("Catched: CMD random. User: #{event.user.name}")

	if max
		rand(min.to_i..max.to_i)
	elsif min
		rand(0..min.to_i)
	else
		rand
	end
end

bot.command :long do |event|
	event << 'こんにちは！'
	event << '今日は良い天気ですね！'
	event << '自分に気をつけて下さい。'
	event << 'マヤはみんなが好きです!'
	maya_logger("Catched: CMD long. User: #{event.user.name}")
end

bot.command(:connect) do |event|
	channel = event.user.voice_channel
	next "No ボイス！" unless channel
	bot.voice_connect(channel)
	"チャンネル： #{channel.name}"
	maya_logger("Catched: CMD connect. User: #{event.user.name}")
end

bot.command(:play_mp3) do |event|
	voice_bot = event.voice
	voice_bot.play_file('assets/music.mp3')
	maya_logger("Catched: CMD play_mp3. User: #{event.user.name}")
end

bot.command(:play) do |event, songlink|
	maya_logger("Catched: CMD play. User: #{event.user.name}")

	if $isplaying == 1
		event.message.delete
		event.respond 'Already playing music'
		break
	end
	
	channel = event.user.voice_channel
	
	unless channel.nil?
		voice_bot = bot.voice_connect(channel)
		system("youtube-dl --no-playlist --max-filesize 50m -o 'assets/music/s.%(ext)s' -x --audio-format mp3 #{songlink}")
		event.respond "Playing"
		$isplaying = 1
		voice_bot.play_file('./assets/music/s.mp3')
		voice_bot.destroy
		$isplaying = 0
		break
	end
	
	'You\'re not in any voice channel!'
end

bot.command(:stop) do |event|
	maya_logger("Catched: CMD stop. User: #{event.user.name}")

	$isplaying = 0
	event.voice.stop_playing
	bot.voices[event.server.id].destroy
	nil
end

maya_logger("M A Y A : Discord waking up...")

at_exit { bot.stop }

begin
	bot.run
rescue Exception => e
	maya_logger("EXCEPTION: #{e}")
end

# Save log
open('logs/discord.log', 'a') { |f|
		f.write $log
}