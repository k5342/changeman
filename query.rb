class TeamSpeak3Query

  ConnectionRefused = Class.new(StandardError)
  
  def TeamSpeak3Query.unescape str
    return str.gsub(Regexp.new('\\\\(\\\\|//|s|p|a|b|f|n|r|t|v|x([0-9A-Fa-f]+))')) do
      case $1
      when '\\' then ''
      when '/'  then '/'
      when 's'  then ' '
      when 'p'  then '|'
      when 'a'  then "\a"
      when 'b'  then "\b"
      when 'f'  then "\f"
      when 'n'  then "\n"
      when 'r'  then "\r"
      when 't'  then "\t"
      when 'v'  then "\v"
      else      $2.to_i(16).chr
      end
    end
  end
  
  def initialize(address, port, id, password)
    begin
      @connection = Net::Telnet::new("Host" => address, "Port" => port)
      @connection.waitfor("Match" => /TS3\n(.*)\n/, "Timeout" => 3)
      
      request "login #{id} #{password}"
    rescue
      raise
    end
    
    request "login #{id} #{password}"
  end
  
  def method_missing(method, *args)
    cmd = []
    cmd << method
    
    unless args.empty?
      case args.first
        when Hash
          args.first.each do |k, v|
            cmd << [k, v].join('=')
          end
        when String
          cmd << args
      end
    end
    
    request cmd.join(' ')
  end
  
  def channellist
    channels = {}
    
    request('channellist').split('|').each do |ch|
      
      channel = {}
      t = ch.split(' ', 2)
      cid = t.first.split('=').last
      
      t.last.split(' ').each do |info|
        k, v = info.split('=')
        channel[k.to_sym] = v
      end
      
      channels[cid.to_i] = channel
    end
    
    channels
    
    # p request('channellist')
    # request('channellist').split('|').map { |ch|
    #   t = ch.split
    #   cid = t.shift.split('=').last.to_i
    #   channel = t.map{|inf| info.split('=', 2)}.to_h
    #   [cid, channel]
    # }.to_h
  end
  
  private
  def request str
    raise unless @connection
    
    @connection.cmd("String"  => str,
                    "Match"   => /error id=.*? msg=.*?\n/,
                    "Timeout" => 3)
  end
end
