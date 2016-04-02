require 'net/telnet'
require './query.rb'

LOGINID       = ENV['changeman_login_id']
LOGINPASSWORD = ENV['changeman_login_password']

puts "login => #{LOGINID}, password => #{LOGINPASSWORD}"

VOICE = 4
MUSIC = 5

def estimate_quality clients
  case clients
  when 0..2; [10, MUSIC]
  when 3;    [3,  MUSIC]
  when 4;    [0,  VOICE]
  when 5;    [10, MUSIC]
  when 6;    [6,  VOICE]
  when 7;    [5,  VOICE]
  when 8;    [2,  VOICE]
  when 9;    [1,  VOICE]
  else;      [0,  VOICE]
  end
end

def how_many_k5342_is_in_economy_channel? q
  tmp = []
  q.clientlist("-voice").split('|').each do |c|
    if c =~ /cid=205 client_database_id=(2|96) /
      tmp << c
    end
  end
  
  return tmp.size
end

begin
  puts "connecting..."
  
  q = TeamSpeak3Query.new('ts.ksswre.net', 10011, LOGINID, LOGINPASSWORD)
  
  q.use :port => 9987
  q.clientupdate :client_nickname => 'Changeman'
  
  puts "successfully connected."
  
  current = []
  loop do
    channels = q.channellist
    
    unless channels[205]
      p channels
      raise "Cannot fetch channel list"
    end
    
    current_clients = channels[205][:total_clients].to_i
    quality_tmp = estimate_quality(current_clients)
    
    if ((cnt = how_many_k5342_is_in_economy_channel? q) > 0)
      cnt_tmp_decided = cnt
      cnt.downto(0) do |cnt_tmp|
        q_tmp = estimate_quality(current_clients - cnt_tmp)
        if q_tmp.first > quality_tmp.first
          cnt_tmp_decided = cnt_tmp
          quality_tmp = q_tmp
        end
      end
      
      puts "#{cnt} k5342(s) are connected. (#{cnt_tmp_decided} ignored)"
    end
    
    quality, codec = quality_tmp
    unless current == quality_tmp
      q.channeledit :cid => 205,
                    :channel_codec_quality => quality, 
                    :channel_codec => codec 
      
      puts "Set #{TeamSpeak3Query.unescape(channels[205][:channel_name])} for #{quality} (codec: #{codec})"
      puts "channel quality has successfully changed."
    end
    
    current = quality_tmp
    
    sleep 3
  end
rescue => e
  puts "#{Time.now} : [ERROR] #{e.message}"
  puts e.backtrace
  exit
end

puts 'exit.'
