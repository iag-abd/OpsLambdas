require 'json'
require 'aws-sdk'

def lambda_handler(event:, context:)
    puts JSON.pretty_generate(event)
    sns = Aws::SNS::Resource.new()
    topic = sns.topic(ENV['TOPIC'])
    
    sns_message = JSON.parse event["Records"].first["Sns"]["Message"]
    
    cluster = sns_message['detail']['clusterArn']
    group = sns_message['detail']['group']
    last_status = sns_message['detail']['lastStatus']
    desired_status = sns_message['detail']['desiredStatus']
    color = '#439FE0'
    
    color = 'good' if last_status == desired_status
    
    message = {
      payload: {
        attachments: [
          {
            color: color,
            text: "*ECS State Change* _for #{group} on #{cluster}_",
            fields: [
              {
                title: 'lastStatus',
                value: last_status,
                short: true
              },
              {
                title: 'desiredStatus',
                value: desired_status,
                short: true
                
              }
            ],
          },
          # {
          #   text: sns_message.to_json
          # }
        ]
      },
      # config: {
      #   icon_emoji: ":panda_face:",
      #   username: "another notification"
      # }
    }
  
    topic.publish({
      message: message.to_json
    })
    
    { statusCode: 200, body: JSON.generate('OK') }
end
