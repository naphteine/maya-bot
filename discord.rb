require 'discordrb'

load('secrets.rb')

$isplaying = 0

bot = Discordrb::Commands::CommandBot.new token: $dctoken, client_id: 836975553759543358, prefix: '!'

# Mentions
bot.mention do |event|
	event.user.pm('おはよう！')
end

# Messages
bot.message(content: 'Ping!') do |event|
	m = event.respond('ポン！')
	m.edit "「ポン！」は#{Time.now - event.timestamp}秒かかりました。"
end

# Commands
bot.command :user do |event|
	event.user.name
end

bot.command :bold do |_event, *args|
	"**#{args.join(' ')}**"
end

bot.command :italic do |_event, *args|
	"*#{args.join(' ')}*"
end

bot.command(:invite, chain_usable: false) do |event|
	event.bot.invite_url
end

bot.command(:random, min_args: 0, max_args: 2, description: 'MinとMaxの間欄ドムランダムを作ること', usage: 'random [min/max] [max]') do |_event, min, max|
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
end

bot.command(:connect) do |event|
	channel = event.user.voice_channel
	next "No ボイス！" unless channel
	bot.voice_connect(channel)
	"チャンネル： #{channel.name}"
end

bot.command(:play_mp3) do |event|
	voice_bot = event.voice
	voice_bot.play_file('assets/music.mp3')
end

bot.command(:play) do |event, songlink|
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
	$isplaying = 0
	event.voice.stop_playing
	bot.voices[event.server.id].destroy
	nil
end

begin
	bot.run
rescue Exception => e
	puts e
end