require 'json'
require 'net/https'

# Expects:
#  {
#   "payload": {
#     "text": "hi there"
#   },
#  #### Config is optional
#   "config": {
#     "channel": "devnull"
#   }
# }
#
# OR sns with message = json string as above

def get_config(config = {})
  {
    slack_url: config[:slack_url] || config['slack_url'] || ENV['SLACK_URL'],
    icon_emoji: config[:icon_emoji] || config['icon_emoji'] || ENV['ICON_EMOJI'],
    username: config[:username] || config['username'] || ENV['USERNAME'],
    channel: config[:channel] || config['channel'] || ENV['CHANNEL'],
  }
end

def base_payload(config)
  {
    channel: config[:channel],
    username: config[:username],
    icon_emoji: config[:icon_emoji],
  }
end

def send(slack_url,payload)
  uri = URI.parse(slack_url)

  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true

  response = http.post(slack_url, payload)

  raise "bad response code #{response.code}" unless response.code == "200"
end

def lambda_handler(event:, context:)
  puts event
  message = event # default but will fail for now if not sns or formatted as per above 
                  # format = { payload: {stuff} } || { payload: {stuff}, config: {stuff} }

  if event['Records'] and event['Records'].first['EventSource'] == "aws:sns"
    message = JSON.parse(event["Records"].first["Sns"]["Message"])
  end

  raise 'No Payload defined in event' unless message['payload']

  config = get_config(message['config'] || {})
  payload = message['payload'] || event['payload'] || { text: "no payload" }
  payload = base_payload(config).merge! payload

  puts payload if config['debug']

  send config[:slack_url], "payload=#{payload.to_json}"

  { statusCode: 200, body: JSON.generate('OK') }
end
