//+------------------------------------------------------------------+
//|                                              TestShellHub.mq5     |
//|   ShellHub 连通性测试 EA：验证 WebRequest 能连到网站服务器        |
//|                                                                    |
//|   使用步骤：                                                       |
//|   1. MT5 → 工具 → 选项 → 智能交易系统 → 勾选"允许 WebRequest"     |
//|      并添加本机地址，例如 http://101.37.29.106:35741             |
//|   2. 填对 InpBaseUrl 和 InpApiKey                                   |
//|   3. 挂到任意图表，看"专家"日志输出                                |
//+------------------------------------------------------------------+
input string InpBaseUrl = "http://101.37.29.106:35741"; // 服务器地址(含端口)
input string InpApiKey  = "2c7b275a05bb55dae19fcf67349e62ea"; // 上报 Key(生产)

//+------------------------------------------------------------------+
//| POST 请求                                                         |
//+------------------------------------------------------------------+
int DoPost(string url, string json, string &outBody)
{
   char post[];
   char result[];
   string headers = "Content-Type: application/json\r\nx-api-key: " + InpApiKey + "\r\n";

   int n = StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(post, n - 1);   // 去掉结尾 \0

   int code = WebRequest("POST", url, headers, 10000, post, result, headers);
   outBody = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   return code;
}

//+------------------------------------------------------------------+
//| GET 请求                                                          |
//+------------------------------------------------------------------+
int DoGet(string url, string &outBody)
{
   char data[];
   char result[];
   string headers = "";
   ArrayResize(data, 0);

   int code = WebRequest("GET", url, "", 10000, data, result, headers);
   outBody = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   return code;
}

//+------------------------------------------------------------------+
int OnInit()
{
   Print("[ShellHub] 开始连通性测试，目标=", InpBaseUrl);

   string body;
   int code = DoGet(InpBaseUrl + "/api/health", body);
   Print("[ShellHub] GET /api/health => HTTP ", code, " 响应=", body);

   string login = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   string json = StringFormat(
      "{\"login\":\"%s\",\"equity\":%.2f,\"todayProfit\":0,\"weekProfit\":0,\"server\":\"%s\"}",
      login,
      AccountInfoDouble(ACCOUNT_EQUITY),
      AccountInfoString(ACCOUNT_SERVER));

   string out2;
   int code2 = DoPost(InpBaseUrl + "/api/submit", json, out2);
   Print("[ShellHub] POST /api/submit => HTTP ", code2, " 响应=", out2);

   if(code == 200 && code2 == 200)
      Print("[ShellHub] 连通 + 上报成功");
   else
      Print("[ShellHub] 测试未通过，请检查白名单/端口/防火墙/API Key");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // 测试 EA 不做任何交易，仅挂载时测试一次
}
//+------------------------------------------------------------------+
