Replicate.client.api_token = ENV.fetch('REPLICATE_API_KEY')

class ReplicateWebhook
  def call(prediction)
    return unless prediction.succeeded? || prediction.failed? || prediction.canceled?

    ai_call = AiCall.find_by_task_id(prediction.id)

    if ai_call
      ai_call.update!(
        status: prediction.status,
        data: prediction
      )
      return [ai_call, prediction.output]
    else
      fail "[Replicate]task id not exist"
    end
  end
end

ReplicateRails.configure do |config|
  config.webhook_adapter = ReplicateWebhook.new
end

# prediction:inspect{
#   "task_id": {
#     "client": {
#       "api_token": "xxxx",
#       "api_endpoint_url": "https://api.replicate.com/v1",
#       "dreambooth_endpoint_url": "https://dreambooth-api-experimental.replicate.com/v1",
#       "webhook_url": null,
#       "api_endpoint": {
#         "endpoint_url": "https://api.replicate.com/v1",
#         "api_token": "xxxx",
#         "content_type": "application/json",
#         "agent": {
#           "parallel_manager": null,
#           "headers": {
#             "Content-Type": "application/json",
#             "User-Agent": "Faraday v2.13.1"
#           },
#           "params": {},
#           "options": {
#             "params_encoder": null,
#             "proxy": null,
#             "bind": null,
#             "timeout": null,
#             "open_timeout": null,
#             "read_timeout": null,
#             "write_timeout": null,
#             "boundary": null,
#             "oauth": null,
#             "context": null,
#             "on_data": null
#           },
#           "ssl": {
#             "verify": true,
#             "verify_hostname": null,
#             "hostname": null,
#             "ca_file": null,
#             "ca_path": null,
#             "verify_mode": null,
#             "cert_store": null,
#             "client_cert": null,
#             "client_key": null,
#             "certificate": null,
#             "private_key": null,
#             "verify_depth": null,
#             "version": null,
#             "min_version": null,
#             "max_version": null,
#             "ciphers": null
#           },
#           "default_parallel_manager": null,
#           "manual_proxy": false,
#           "builder": {
#             "adapter": {
#               "name": "Faraday::Adapter::NetHttp",
#               "args": [],
#               "kwargs": {},
#               "block": null
#             },
#             "handlers": [
#               {
#                 "name": "Faraday::Retry::Middleware",
#                 "args": [],
#                 "kwargs": {},
#                 "block": null
#               },
#               {
#                 "name": "Faraday::Request::Authorization",
#                 "args": [
#                   "Token",
#                   "xxxx"
#                 ],
#                 "kwargs": {},
#                 "block": null
#               }
#             ],
#             "app": {
#               "app": {
#                 "type": "Token",
#                 "params": [
#                   "xxxx"
#                 ],
#                 "app": {
#                   "ssl_cert_store": {
#                     "verify_callback": null,
#                     "error": null,
#                     "error_string": null,
#                     "chain": null,
#                     "time": null
#                   },
#                   "app": {},
#                   "connection_options": {},
#                   "config_block": null
#                 },
#                 "options": {}
#               },
#               "options": {
#                 "max": 2,
#                 "interval": null,
#                 "max_interval": null,
#                 "interval_randomness": null,
#                 "backoff_factor": null,
#                 "exceptions": [
#                   "Errno::ETIMEDOUT",
#                   "Timeout::Error",
#                   "Faraday::TimeoutError",
#                   "Faraday::RetriableResponse"
#                 ],
#                 "methods": null,
#                 "retry_if": null,
#                 "retry_block": null,
#                 "retry_statuses": [],
#                 "rate_limit_retry_header": null,
#                 "rate_limit_reset_header": null,
#                 "header_parser_block": null,
#                 "exhausted_retries_block": null
#               },
#               "errmatch": null
#             }
#           },
#           "url_prefix": "https://api.replicate.com/v1",
#           "proxy": null
#         },
#         "last_response": {
#           "status": 201,
#           "body": "{\"id\":\"x0fmfzfcf5rma0cq65c825tcbm\",\"model\":\"kwaivgi/kling-v1.6-standard\",\"version\":\"hidden\",\"input\":{\"prompt\":\"漫威Ironman面向镜头挥手，用中文说出“安安，豆豆，你们好！好好学习，你们长大后也可以是钢铁侠”，金属面罩透出蓝光，全身分解展示酷炫变身过程。镜头聚焦手部装甲层层展开，肘关节喷射口旋转启动，肩甲液压装置伸缩，胸口反应堆能量汇聚，膝盖护甲翻转重组，脚部推进器逐级变形。金属质感搭配纳米粒子流光特效，未来科技风格。用中文说出“我要去打日本鬼了，拜拜！“，然后飞远\"},\"logs\":\"\",\"output\":null,\"data_removed\":false,\"error\":null,\"status\":\"starting\",\"created_at\":\"2025-06-02T15:53:20.761Z\",\"urls\":{\"cancel\":\"https://api.replicate.com/v1/predictions/x0fmfzfcf5rma0cq65c825tcbm/cancel\",\"get\":\"https://api.replicate.com/v1/predictions/x0fmfzfcf5rma0cq65c825tcbm\",\"stream\":\"https://stream.replicate.com/v1/files/bcwr-g3bhdmfvdowf5tligcizomzjshpjrupqszb2ajpykq6v7hzzs5xq\",\"web\":\"https://replicate.com/p/x0fmfzfcf5rma0cq65c825tcbm\"}}\n",
#           "response_headers": {
#             "date": "Mon, 02 Jun 2025 15:53:20 GMT",
#             "content-type": "application/json; charset=utf-8",
#             "content-length": "1099",
#             "connection": "keep-alive",
#             "x-xss-protection": "1; mode=block",
#             "x-frame-options": "SAMEORIGIN",
#             "server": "cloudflare",
#             "cf-ray": "94981f7ae95cf07e-DFW",
#             "cf-cache-status": "DYNAMIC",
#             "strict-transport-security": "max-age=15552000",
#             "via": "1.1 google",
#             "alt-svc": "h3=\":443\"; ma=86400",
#             "ratelimit-remaining": "599",
#             "ratelimit-reset": "1",
#             "report-to": "{\"endpoints\":[{\"url\":\"https:\/\/a.nel.cloudflare.com\/report\/v4?s=%2BNl60Q9rilpFeRQNmL2YnWOwoQkm3n%2FBAfAVCQdewNZrqStCgVrhenucJr03%2BKi4hpw5fd2CbnUA4H8Aht101G8B%2Fw%2Ftj99Pg1ZcDFAOLOxYXhYrDAGELf32hb1uyEQ4VEHn\"}],\"group\":\"cf-nel\",\"max_age\":604800}",
#             "nel": "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}",
#             "vary": "Accept-Encoding",
#             "expect-ct": "max-age=86400, enforce",
#             "referrer-policy": "same-origin",
#             "x-content-type-options": "nosniff",
#             "server-timing": "cfL4;desc=\"?proto=TCP&rtt=1015&min_rtt=927&rtt_var=410&sent=5&recv=7&lost=0&retrans=0&sent_bytes=2797&recv_bytes=1607&delivery_rate=3124056&cwnd=242&unsent_bytes=0&cid=d69abd2e3ddcfaad&ts=992&x=0\""
#           },
#           "url": "https://api.replicate.com/v1/predictions"
#         }
#       }
#     },
#     "data": {
#       "id": "x0fmfzfcf5rma0cq65c825tcbm",
#       "model": "kwaivgi/kling-v1.6-standard",
#       "version": "hidden",
#       "input": {
#         "prompt": "漫威Ironman面向镜头挥手，用中文说出“安安，豆豆，你们好！好好学习，你们长大后也可以是钢铁侠”，金属面罩透出蓝光，全身分解展示酷炫变身过程。镜头聚焦手部装甲层层展开，肘关节喷射口旋转启动，肩甲液压装置伸缩，胸口反应堆能量汇聚，膝盖护甲翻转重组，脚部推进器逐级变形。金属质感搭配纳米粒子流光特效，未来科技风格。用中文说出“我要去打日本鬼了，拜拜！“，然后飞远"
#       },
#       "logs": "",
#       "output": null,
#       "data_removed": false,
#       "error": null,
#       "status": "starting",
#       "created_at": "2025-06-02T15:53:20.761Z",
#       "urls": {
#         "cancel": "https://api.replicate.com/v1/predictions/x0fmfzfcf5rma0cq65c825tcbm/cancel",
#         "get": "https://api.replicate.com/v1/predictions/x0fmfzfcf5rma0cq65c825tcbm",
#         "stream": "https://stream.replicate.com/v1/files/bcwr-g3bhdmfvdowf5tligcizomzjshpjrupqszb2ajpykq6v7hzzs5xq",
#         "web": "https://replicate.com/p/x0fmfzfcf5rma0cq65c825tcbm"
#       }
#     }
#   }
# }