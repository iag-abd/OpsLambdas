require 'json'
require 'aws-sdk'

# Expect Cloudwatch|Targets|InputTransformer like this:
# InputPathsMap:
#     container: "$.detail.containers[0]"
#     clusterArn: "$.detail.clusterArn"
#     ip: "$.detail.containers[0].networkInterfaces[0].privateIpv4Address"
#     name: "$.detail.containers[0].name"
#     detail: "$.detail"
#     group: "$.detail.group"
#   InputTemplate: !Sub '"ip: <ip>, name: <name>, clusterArn: <clusterArn>, container: <container>, group: <group>, targets: [${EcsTargetsForGroup}]"'


def attach_to_target_group(message)
  elbv2 = Aws::ElasticLoadBalancingV2::Client.new
  puts ip = message['ip']
  target_groups = message['targetGroup']

  targets = elbv2.describe_target_health(target_group_arn: target_group)
  targets = targets.to_h

  # Deregister unhealthy
  target_groups.each do |target_group|
    targets[:target_health_descriptions].each do |target_health_description|
      id = target_health_description[:target][:id]
      puts target_health_description[:target_health][:state]
      # Been debating initial but will leave here just in case there is more than on container
      next if %w[healthy draining initial].include? target_health_description[:target_health][:state]
      elbv2.deregister_targets(target_group_arn: target_group, targets: [{ id: id}])
    end
  end

  elbv2.register_targets(target_group_arn: target_group, targets: [{ id: ip}])
  
  notify_it message
end

def notify_it(message)
    cluster = message['clusterArn']
    color = '#439FE0'

    message = {
      payload: {
        attachments: [
          {
            color: 'good',
            text: "*ECS State Change* _Traefik is *live* and *running* on #{cluster}_",
            fields: [
              {
                title: 'ip',
                value: message['ip'],
                short: true
              },
              {
                title: 'name',
                value: message['name'],
                short: true
              }
            ]
          },
          {
            color: color,
            text: JSON.pretty_generate(message['detail']['containers'].first)
          }
        ]
      },
      # config: {
      #   #icon_emoji: ":panda_face:",
      #   username: "another notification",
      #   channel: 'devnull'
      # }
    }

    puts message.to_json
    topic.publish({
      message: message.to_json
    })
end

def lambda_handler(event:, context:)
  puts event

  message = {}
  p event["Records"].first["Sns"]["Message"]
  sns_message = event["Records"].first["Sns"]["Message"]
  sns_message.split(', ').each do |msg|
    msg_list = msg.split(': ')
    message[msg_list[0]] = msg_list[1]
  end
  
  puts message
  
  puts JSON.pretty_generate message

  { statusCode: 200, body: JSON.generate('OK') }
end
