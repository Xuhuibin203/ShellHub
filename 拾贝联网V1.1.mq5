//+------------------------------------------------------------------+
//|                                            拾贝联网V1.1.mq5       |
//|   V1.1 (2026-10-30,用户要求更名):                                |
//|    ①EA 更名为"拾贝联网V1.1",文件名同步改为 拾贝联网V1.1.mq5;      |
//|    ②代码逻辑与 v11.4 完全一致,未做行为改动;                      |
//|   v11.4 测试版(2026-10-30,第二组门槛加固,双Agent复核一致):      |
//|    ①InpPairRescueCnt 增加参数校验:必须>=1(填0/负数会让救援门槛     |
//|      恒成立,第二组无救援即开);                                   |
//|    ②TryOpenPair 增加 closing 拦截:参考组正在平仓时不开反向组      |
//|      (平仓中救援单仍在,门槛会误判为"已进救援");                   |
//|    ③注释自检闸门 g_commentBad 提到反向组之前,原来 TryOpenPair     |
//|      先跑可绕过该闸门;                                           |
//|    ④注释修正:g_rescueCnt 由持仓每秒重建,手动平单会回落(仅少开组); |
//|   v11.3 测试版(2026-10-30,用户拍板第二组开组规则):               |
//|    ①突破开组仅限零组:一组都没有时bid突破框上/下轨即开首组,        |
//|      方向顺突破、InpBoxBreakSec秒硬节奏,行为保持不变;             |
//|    ②有存活组时禁止按突破方向开第二组:第二组一律走反向组,          |
//|      须存活组救援单张数≥InpPairRescueCnt(=1)才解锁,方向取          |
//|      -存活组头仓方向(用户口径:第二组就是反向组,只是零组时才叫     |
//|      突破组);                                                    |
//|    ③修复现象:第一组未进救援、价格在框外时被突破模式开出第二组,    |
//|      且方向可能与第一组头仓相同(突破方向=bid相对框上/下轨);       |
//|   v10.43 测试版(2026-10-28,日志精简):                            |
//|    ①救援三类拦截日志(冷却/出牌间隔/全局间距)+总手数上限拦截:     |
//|      删600秒重打(LOG_GAP_SEC机制整体退场),只保留状态变化式——     |
//|      同通道同类型被拦只打首条,放行后复位;实测扛单期每通道从      |
//|      3~4条降到1条(2025.12~2026.01回测15341条→约1/10);            |
//|    ②反向组间隔日志:剩余<10秒不再打(间隔=1秒时纯噪音);            |
//|    ③(排查记录)反向组触发机制正常:救援后1秒内必开反向组;用户       |
//|      观察"扛单时反向组没做单"实为反向组秒开秒平循环(0.01手×      |
//|      止盈系数200=2美分秒级止盈+间隔1秒重开),属参数效果非bug。     |
//|    ④InpRescueGlobalGap默认true→false(用户2026-10-28拍板):实测     |
//|      2026.01.28~02.02救援死区——救1张0.12@5190.26后,价格在        |
//|      5165~5190震荡7天,旧通道等不到5165深跌,新锚点5189.07等被      |
//|      全局间距闸拦1466次,全程仅3张救援,套牢单硬扛亏损扩大;         |
//|      关闸后救援仍受通道间距+冷却2000秒(用户定保持)约束。          |
//|   v10.42 测试版(2026-10-28,用户拍板救援手数序列制):              |
//|    ①救援手数改为序列参数InpRescueLotSeq(逗号分隔):从左到右=      |
//|      通道第1,2,3…张救援单的最终手数(纯序列即手数,不再叠加        |
//|      基础公式),可填1~20个值,用完沿用最后一个值;主/反组共用;      |
//|    ②删除InpRescueLotStep旧递增公式(手数=基础+(m0+1)×步长,        |
//|      连同轮内同手数逻辑一并替换为逐张顺次取序列值);              |
//|    ③序列解析仅用官方确认API(StringToDouble文档核实)+本机         |
//|      已有先例API(StringSubstr/StringLen/StringGetCharacter);     |
//|   v10.41 测试版(2026-10-28,实测修复):                            |
//|    ①InpBoxMinGap下限30→1(用户2026-10-28拍板放开:实测在测试器     |
//|      填20被下限校验拒绝加载,tester stopped incorrect inputs);     |
//|    ②[框向开组]意图日志只在方向变化或框变化时打(实测闭市时段       |
//|      每tick一条,11秒刷931条,日志膨胀到百MB级,可视化卡顿);         |
//|   v10.40 测试版(2026-10-27,用户拍板方案A高低点框):                |
//|    ①方向判定改为"方向框":上轨=参考周期InpBoxTF近InpBoxBars根      |
//|      最高价,下轨=近N根最低价;高度不足InpBoxMinGap时               |
//|      以中点为中心扩展,行情大不压缩用真实高低点;方向=实时bid vs    |
//|      框中点(上方做多/下方做空);屏幕画框InpBoxShow;                |
//|    ②突破模式:实时bid突破上/下轨→每InpBoxBreakSec秒开一新组       |
//|      (顺突破方向,守最多2组上限,不等上一单走完,M秒硬节奏),         |
//|      回框自动停止,恢复"上一单走完+InpTimeOpenSec秒+中点方向"      |
//|      老节奏;突破计时基准GV持久化重启续接;                         |
//|    ③删除方向判定全套6参数(InpTimeDirLive/InpTimeDirTF/            |
//|      InpTimeDirEMAPeriod1~4/InpTimeDirTF2)+4条EMA句柄+            |
//|      TimeModeDir()+TFToStr(),删干净;                              |
//|    ④InpTimeOpenSec默认180→60(用户2026-10-27定);                   |
//|    ⑤反向组独立参数三件套:InpPairGridA(网格间距)/InpPairStepB      |
//|      (补仓触发步长)/InpPairRescueDist(救援触发距离,0=反向组不     |
//|      救援),默认=主组值(1/5/10)行为不变;阶段一档位/阶段二触发线    |
//|      与重定位/救援锚定与间距全线按组取参;                         |
//|    ⑥改名拾贝测试版本(由拾贝10.3终极版v10.30复制而来)              |
//|   v10.30 主止盈按手数版(2026-10-26,用户需求:主止盈与救援止盈同逻辑):|
//|   黄金拾贝:时间驱动头仓→阶段一固定双档链式网格→阶段二逆势补仓     |
//|             →套牢救援(独立通道)→止盈/利润回撤                     |
//|   标的:XAUUSD | 周期:M15 | 账户:美分账户 | Magic=20260820         |
//|   v10.20 方向参数标定版(2026-10-26,54配置×4场景tick级网格测试):    |
//|    ①InpTimeOpenSec 1→500(用户指定开组延迟500秒)                    |
//|    ②新增InpTimeDirLive方向实时点模式(默认开):判定基于实时bid vs     |
//|      形成中的EMA(iMA shift=0),消除收盘bar滞后;关=旧行为(已收盘bar) |
//|    ③网格测试结论(2026-10-26,构造行情口径):                         |
//|      ·实时点模式完胜收盘bar——同M5/H1配置实时点+1084 vs 收盘bar      |
//|        -30992:收盘滞后导致震荡转单边时逆势开多,组转亏后救援链展开; |
//|      ·参考周期二H1最优(实时点M?/H1合计1084,比H4/D1高27%,比D1高45%);|
//|      ·参考周期一M5与M15结果逐位相同(实时价主导判定),EMA三组参数     |
//|        (13/21,21/50,10/30)差异<1%——回看参数不敏感,取13/21;          |
//|      ·单测:转跌后实时点10分钟判空 vs 收盘bar60分钟(领先50分钟);    |
//|      ·最差浮亏合计:TOP6全部-6.2(收盘bar快周期组合-31228)           |
//|      推荐参数=实时点 M5(EMA13/21)+H1(EMA21/50) TimeOpenSec=500      |
//|   v10.10 模拟验证修复版(2026-10-26,tick级模拟证实两问题后直接修复): |
//|    ①B1补强(模拟发现:实盘参数ByLot=true&PerLot=100下,救援单成交瞬间 |
//|      止盈线跳升到手数×系数,独立于回撤线直接平掉整组——v10.00的峰值  |
//|      下调完全不起作用,7场景与旧行为逐位一致)。修复:InpRescuePeak-  |
//|      Adjust=开时,回撤跟踪已激活期间救援止盈跳升不再打断回撤线,     |
//|      止盈底线回退主止盈InpTwoSideProfit;峰值下调照常,救援链得以    |
//|    v10.30 新增InpProfitByLot/InpProfitPerLot主止盈按手数(用户要求): |
//|      开=主止盈(起始手数/阶段一/阶段二统一)=组内最新成交主链单(非   |
//|      救援)手数×InpProfitPerLot,补仓后止盈随最新单手数自动放大;     |
//|      关=固定InpTwoSideProfit旧行为(v10.30默认关)。手数口径=组内最  |
//|      新成交单手数(用户2026-10-26拍板),排除救援单——否则救援期间    |
//|      回撤下限tpFloor被救援手数×主系数抬高,B1补强失效;              |
//|      主止盈每手系数默认200占位(0.01×200=2.00与固定2.00等价起步),   |
//|      最终值用户自定                                                 |
//|      真正展开。关=完全旧行为                                       |
//|    ②新增InpRescueLotsCap救援总手数上限(默认2.0,沿用2.0手全局预算   |
//|      习惯):全EA同方向救援单总手数达到上限后停止再出救援牌(带600秒  |
//|      节流日志)——封顶"组进阶段二转亏→回撤永不激活→救援链完整展开"  |
//|      的逃逸路径(P7模拟:8张救援/敞口2.65手/浮亏-35234,GlobalGap     |
//|      只降64%风险,此上限直接封死)。0=不限制(旧行为)                |
//|    ③实盘参数表(用户2026-10-26提供)已写入v10.00默认值(15处)        |
//|   v10.00 代码审查修复版(2026-10-26,依据《拾贝EA代码审查报告》+用户拍板):|
//|    ①A1 closing状态持久化:CloseGroup置closing后立即SaveState;        |
//|      ProcessClosing平仓失败分支补SaveState——防重启后待平组复活      |
//|    ②A2 收编扫描残留挂单:AdoptOrphanPositions枚举服务器挂单,按magic  |
//|      回填pendingTicket/Dir,多余撤除——防双份网格                      |
//|    ③A3 轻量自检:挂载时+每300秒扫描本EA持仓注释,发现不含GSB前缀的    |
//|      单子打醒目警告并停止新开组(等人工确认),不改变救援逻辑           |
//|    ④A4 下单前置校验:终端/EA交易许可+品种交易模式+保证金(85%可用)    |
//|      +滑点SetDeviationInPoints+失败退避InpRetryBackoffSec           |
//|    ⑤A6/A7 参数合法性校验:GridA/手数/止盈阈值等,非法拒绝加载;        |
//|      NormalizeLot负值零值不再静默变0.01,记错误日志                   |
//|    ⑥B1 救援成交后同步下调回撤峰值(减新单点差成本),回撤线跟着平移,   |
//|      救援链得以正常展开(InpRescuePeakAdjust开关,默认开)              |
//|    ⑦B3 阶段二冻结告警:进阶段二后无补仓无止盈超InpFreezeAlertSec     |
//|      打告警日志(每轮一次),行为不变                                   |
//|    ⑧D1 magic过滤口径统一为g_maxGroups+越界槽位清理(收编前平高槽位   |
//|      持仓/撤挂单/清GV)——修僵尸组静默死锁                             |
//|    ⑨D6 收编恢复trailActive/peakProfit(崩溃前的回撤保护不再凭空消失) |
//|    ⑩E5 清洁:#property strict删除;g_maxGroups初值改2;面板关闭时     |
//|      仍创建"重置统计"按钮                                            |
//|   v5.00 由拾贝3.32终极版(v3.24)精简+改造而来(主流程框架不变):     |
//|    ①删除压力位/支撑位过滤整套:参数/计算/区间开组开关/画矩形       |
//|    ②删除阶段二单侧最大加仓次数InpMaxP2Adds(触发即补,只受冷却T)    |
//|    ③删除双线带宽整套:InpBandWidth/PX/PXStep/线内上限/密度闸/画线  |
//|    ④删除风控三件套:组寿命/锁仓浮亏百分比/熔断止损(含停机逻辑)     |
//|    ⑤多组跟/反双通道:偶数槽(0,2..)跟指标开仓,奇数槽(1,3..)反向开仓 |
//|      各通道独立冷却基准,互不影响开单;止盈按组本就互不影响          |
//|    ⑥救援轮次:张数基数参数删除,基数固定1——第k轮张数=1+(k-1)×      |
//|      InpRescueCntStep,参数=1时即第1轮1张/第2轮2张/第3轮3张…递增   |
//|    ⑦救援出牌四条规则(用户2026-09-22指定,严格执行):                |
//|      规则1+2:时间闸门——第2张起距上一张救援成交须≥救援冷却        |
//|        (默认900秒),即使点数已到/深过触发价也不开;第一张救援单     |
//|        不受900秒限制(用户确认),只看价格触发;                      |
//|      规则3:禁整轮同出——每tick每通道最多出1张;                     |
//|      规则4:逐张推算——每一张都按价格触发,下一张=通道内最深一张     |
//|        ∓固定间距(间距=触发距离+固定加成,第3张起再逐张+叠加值),    |
//|        基于上一张推算到点才可出;快速行情瞬间穿过多个点位时,        |
//|        由时间闸门保证一张一张按冷却间隔出,不一次性全部补入         |
//|   v5.10:跟/反改为开关InpDualLane控制(用户2026-09-22要求):         |
//|      开=1组跟指标+1组反向(奇偶交替,需InpMaxGroups≥2);             |
//|      关=全部槽位跟指标(单通道,共用组间冷却,旧行为)                |
//|   v5.20:新增全局救援间距闸门InpRescueGlobalGap(用户2026-09-23     |
//|      拍板,默认关=旧行为):开=同方向任意救援单(含各通道第一张)      |
//|      触发价须距全EA最近一张同方向救援单≥触发距离+固定加成         |
//|      (同方向张数>1再逐张+叠加),跨通道跨组生效,反向通道不受影响;   |
//|      修复9/22实盘:相邻通道第一张仅差1.00美元秒级连发的问题        |
//|   v5.30:新增阶段二跟随救援InpP2FollowRescue(用户2026-09-25思路,   |
//|      默认关=旧行为):开=本组救援单存续期间,每成交一张救援单,       |
//|      阶段二立即市价补一手(同方向,手数=阶段二递增公式),不受T冷却;  |
//|      原P0触发线在救援期间暂停,补仓节奏完全由救援四条规则+         |
//|      全局间距闸门约束;跟随单注释GSB补多/补空,与原阶段二单         |
//|      同等待遇(计入收编反推/套牢后同样派生自己的救援通道)          |
//|   v5.40:阶段二跟随救援补强为严格1:1(用户2026-09-25要求):          |
//|      救援成交后跟随单若下单失败(拒单/断线/自动交易未开等),        |
//|      记为欠账pendingFollowCnt,此后每tick重试直到补上              |
//|      (OnTick逐组调用ProcessFollowRescue);欠账随状态GV持久化,      |
//|      重启后继续补;组平仓/槽位重开时欠账作废(跟随随组生命周期)     |
//|   v5.50:新增两个开关(用户2026-09-25要求):                        |
//|    ①InpRescueLotDouble救援手数翻倍(默认关=以往递增逻辑):开=      |
//|      通道内每张救援单手数=首张值×2^(N-1)几何递增(首张=原公式     |
//|      首张值),翻倍模式不保持轮内等手数,以每张翻倍为准;仍受        |
//|      InpMaxLot单笔上限封顶                                       |
//|    ②InpP2StopOnRescue救援期间阶段二停补(默认关=随救援继续):开=   |
//|      本组救援单存续期间阶段二禁止补仓(跟随与P0触发都不补,        |
//|      已有欠账挂起不销);关=阶段二随救援继续补仓(跟随模式照旧)     |
//|   v5.60:新增两个功能(用户2026-09-25要求):                        |
//|    ①InpRescueBaseLot救援首张手数(默认0=旧公式由init+阶段一参数   |
//|      推算):>0时首张=此值,后续按翻倍(开关开)或递增从它起算,       |
//|      与init/阶段一参数彻底解耦                                   |
//|    ②InpRescueProfitByLot救援止盈按手数(默认关=固定InpRescueProfit)|
//|      开=止盈=最新成交救援单手数×InpRescueProfitPerLot(默认100,   |
//|      0.12→12,0.24→24,1.00→100),每次救援成交后自动切换,           |
//|      整组净利口径不变                                            |
//|   v8.90 阶段二/救援单向化——只顺头仓方向(用户2026-10-22拍板,写死):|
//|      阶段二:头仓空(-1)仅涨到上触发线补空;头仓多(+1)仅跌到下触发    |
//|      线补多;反侧触发线跳过(不补/不重定位/系数不递增);头向未知      |
//|      (0,收编组)一律禁止补仓;赚钱方向(顺头仓)不补;                  |
//|      救援:只为方向=头仓方向的套牢单建通道(空仓组只救空单,多仓组    |
//|      只救多单);反方向网格套牢单不救援,等整组止盈/回撤平仓;         |
//|      阶段一链式网格不变(仍一多一空交替,P0±A双档,满2W张进阶段二)   |
//|   v8.80 反向组间隔时间参数(用户2026-10-13要求):                  |
//|      新增InpPairCooldownSec(默认0=旧行为不间隔):上一张反向单       |
//|      平仓(槽位释放)后须满此秒数才能再开下一个反向组;计时基准      |
//|      =用户拍板的"反向单平仓后计时";反向组标记isPair随组状态GV     |
//|      持久化,平仓时刻GV pairclose持久化,重启续接;零组首组与        |
//|      正向组不受此参数影响,仅约束TryOpenPair反向组开组             |
//|   v8.70 组走光必须立马撤挂单(用户2026-10-13要求,写死):            |
//|      修复"单子走掉后挂单还被触发进单",四层闭环:                  |
//|      ·事件级:OnTradeTransaction收到本组平仓deal瞬间,活体持仓=0     |
//|        则毫秒级撤销本组挂单(不等下一tick);平仓中挂单漏网成交的     |
//|        混入单也事件级立即平掉                                     |
//|      ·每tick兜底:closing或持仓走光但挂单还在→持续重试撤单          |
//|      ·CancelGroupPendings重写:撤单失败保留票号重试(旧版失败也      |
//|        清零票号=挂单成孤儿成交后无人管,本次问题根源之一);挂单      |
//|        消失时查历史,已在撤销前成交(竞态)→立即平掉本组全部持仓      |
//|      ·ResetGroup前确认票号撤干净(防ZeroMemory抹票号留孤儿挂单)    |
//|   v8.60 阶段二写死每组只补一次(用户2026-10-13要求,无条件):       |
//|      本组阶段二成交一次后(phase2Adds>0)永不再补,不受触发线/       |
//|      冷却T/救援/重启影响;计数随GV p2adds持久化,重启由LoadState    |
//|      或收编反推恢复,防重启后重复补仓;                             |
//|      同步删除v5.30跟随救援InpP2FollowRescue与v5.50停补             |
//|      InpP2StopOnRescue两参数及全部关联代码(欠账pendingFollow*、   |
//|      GV pflw*、ProcessFollowRescue欠账重试、救援后跟随补仓块)     |
//|   v8.50 双周期双EMA同向开单+统计重置+日志简化(用户2026-10-13拍板):|
//|      ·方向判定升级(用户2026-10-13定稿:两个参考周期,每周期两条EMA, |
//|        共4根):周期一InpTimeDirTF(默认H1)上EMA一                   |
//|        (InpTimeDirEMAPeriod默认10)+EMA二(InpTimeDirEMAPeriod2      |
//|        默认30);周期二InpTimeDirTF2(默认H4)上EMA三                  |
//|        (InpTimeDirEMAPeriod3默认10)+EMA四(InpTimeDirEMAPeriod4     |
//|        默认30);各周期用已收盘bar(shift1)收盘价vs本周期两条EMA:     |
//|        收盘价同时在两条上方=该周期多/同时在下方=空/一上一下(夹在   |
//|        两线之间)=该周期无方向;两个周期方向一致才开首组,任一无方向  |
//|        或两周期一多一空→不开(下tick重试);                          |
//|        反向组不受影响(仍=存活首组反方向);                          |
//|        暂停原因(夹中间/两周期打架)状态变化日志,不逐单刷屏;          |
//|      ·统计重置:新增InpStatsReset参数(挂载时清空)+面板"重置统计"    |
//|        按钮(随时点击)——周期统计/历史周期行/从头到尾最大亏损/        |
//|        总盈利/累计下单手数全部从头起算;实现=统计基准时刻            |
//|        (GV sepoch):基准之后的成交才计入盈亏与手数,旧成交不回溯;     |
//|        时间模式计时基准tmClose与组状态GV不受重置影响                |
//|      ·日志简化:平组两条日志并一条(平组完成+计时秒数);时间模式      |
//|        开首组不再重复打第二条(开组本身已有日志);救援三类拦截诊断    |
//|        加600秒同类最小间隔(LOG_GAP_SEC),原状态变化机制保留;         |
//|      ·死代码:AdoptOrphanPositions的latestPrice只写不读,删除        |
//|   v8.40 信号系统清理(用户"清理"拍板,时间模式收敛为唯一主线):      |
//|      ·删除信号指标整套:SignalIndicatorName/SignalIndicatorTF/     |
//|        SignalEMAPeriod/SignalHigherTF/SignalConfirmHigh五参数、    |
//|        hSig句柄、ReadSignal()(buf2/buf3箭头读取);                  |
//|      ·连带删除纯信号下游:普通信号开组、InpPairMode双组开关        |
//|        (反向组保留:启动条件=存活组救援触发≥InpPairRescueCnt次,    |
//|        由时间模式TryOpenByTime直接调用)、立即重开InpInstantReopen |
//|        (g_reopen三变量/InstantReopenDir)、组间冷却                 |
//|        InpGroupCooldownSec(g_groupCooldown/UpdateCooldown);        |
//|        g_lastOpenTime随读点清零退场(只剩写=死代码);               |
//|      ·InpTimeMode开关退场:信号模式删净后"关=旧行为"失去意义,      |
//|        时间驱动开组成为唯一开组路径(零组按InpTimeOpenSec定时+      |
//|        方向跟随,反向组救援联动,双组并行照旧);                      |
//|      ·InpMaxGroups<2自动提升为2(继承原InpPairMode防静默失效逻辑:  |
//|        反向组救援联动需两槽);                                      |
//|      ·保留零改动:双组并行/救援联动/组内逻辑/周末黑窗/授权/面板     |
//|   v8.30 方向跟随+大清理(用户2026-10-13拍板):                     |
//|      ·时间模式零组首组方向改为跟随周期指标:新增方向参考周期        |
//|        InpTimeDirTF(任选)+EMA周期InpTimeDirEMAPeriod,该周期收盘价  |
//|        在EMA上方=多/下方=空(用已收盘bar,方向变了后续单跟着变,     |
//|        在跑的组不动);反向组仍=首组反方向,救援联动保留;            |
//|      ·删除8项参数及全部关联代码:强制方向InpSignalAlways(含        |
//|        hEmaSig句柄/ReadSignal兜底/InstantReopenDir兜底)、单笔上限  |
//|        InpMaxLot(NormalizeLot封顶块)、阶段一循环间距扩大            |
//|        InpGridCycleWiden、救援首张手数InpRescueBaseLot、救援手数    |
//|        翻倍InpRescueLotDouble、基准组寿命InpPairLifespanSec(连带    |
//|        InpPairTrigByRescue开关退场——寿命删后二选一失去意义,反向组   |
//|        唯一条件=救援触发≥InpPairRescueCnt次)、跟/反双通道           |
//|        InpDualLane(LaneCount/laneStep/lane参数/g_lastLaneOpen数组   |
//|        退场,冷却基准改单变量g_lastOpenTime,GV key改"lastopen")、    |
//|        组间冷却动态CalcCooldownEx(InpPXGC/InpPXGCStep删除,冷却      |
//|        恒=InpGroupCooldownSec);                                     |
//|   v8.20 时间模式改为双组并行(用户2026-10-12实测反馈):            |
//|      v8.10串行交替覆盖了双组机制→救援触发时反向组不补,违背        |
//|      "救援打开时双组一定是使用状态";现改为:                       |
//|      ·零组:按InpTimeOpenSec秒定时开首组(方向固定多,首单立即开);   |
//|      ·有活跃组:反向组按现有v6.20规则开(救援触发≥次数立即开,       |
//|        或寿命满秒数开)——救援联动完整保留,双组并行;                |
//|      ·方向交替g_timeDir退场删除(固定多后无用),计时基准            |
//|        g_timeCloseTime保留GV持久化,重启续接;                      |
//|      ·组内逻辑/周末黑窗/组内止盈回撤完全不变;默认关=旧行为        |
//|   v8.10 新增时间驱动开组模式(用户2026-10-12拍板):                |
//|      InpTimeMode开=不再跟随指标,改为纯时间节奏:首单立即开(多),    |
//|      此后严格"一多一空"交替;上一单(完整组)整组止盈平仓槽位释放    |
//|      后计时满InpTimeOpenSec秒才开下一单;全程串行单组(全槽扫描     |
//|      无活跃组才可开),组内阶段一网格/阶段二/救援/止盈回撤逻辑      |
//|      完全不变;下一单方向与计时基准GV持久化,重启续接不乱序;        |
//|      覆盖信号/双通道/双组寿命/立即重开/组间冷却;周末黑窗保留;     |
//|      默认关=旧行为不变                                            |
//|   v8.00 死代码清理(用户2026-10-12要求,零交易行为变更):           |
//|      删只写不读的g_buyLots及其起点g_mountTime(GV"mount"读写链);  |
//|      删零调用的CancelAllGroupPendings();版本号6.20→8.00          |
//|   v6.20 新增反向组启动条件按救援次数(用户2026-09-30要求):         |
//|      InpPairTrigByRescue开=存活组累计救援触发≥InpPairRescueCnt次   |
//|      才开反方向组(忽略寿命秒);关=按v6.00寿命秒原行为;             |
//|      计数=组内当前持有救援单张数(救援单不单独平仓,等价于累计        |
//|      触发次数;以成交为准,下单失败不计),重启由持仓缓存自然还原      |
//|   v6.10 新增救援拦截诊断日志(用户2026-09-28拍板):                 |
//|      救援被900秒冷却/出牌间隔/全局间距闸门拦截时,原版静默跳过,     |
//|      回测看不到"为何未在规定位置救援";现改为状态变化式提示——       |
//|      同一通道首次被拦打1条日志(含还差多少秒/差多少间距),放行后     |
//|      复位,不改变任何交易行为,仅可观测                              |
//|   v6.00 新增InpPairMode双组寿命模式(用户2026-09-28拍板):          |
//|      最多持有2组;零组时首组跟指标(需信号);每组寿命按自己开仓      |
//|      时刻独立累计,不因他组走掉重置;存活组寿命满后开其反方向组;    |
//|      开=覆盖双通道/组间冷却/立即重开(黑窗保留);关=旧行为          |
//|   v5.90 新增授权激活系统(纯离线,用户2026-09-28拍板):             |
//|     激活码=AES-256加密(账号u64+到期分钟u32+魔数),Base64编码;     |
//|     一户一码:码内账号须=登录账号(ACCOUNT_LOGIN);                 |
//|     时间:到期分钟前有效(经纪商服务器时间,改本机时钟无效);        |
//|     无码/码无效/账号不符/已过期 → 拒绝加载(INIT_FAILED);         |
//|     运行中到期 → 停止一切交易逻辑+面板红字(不自动卸载);          |
//|     配套生成器:Scripts\拾贝激活码生成器.mq5(仅作者使用)          |
//|   v5.80 新增InpGridCycleWiden阶段一循环间距扩大开关:              |
//|     开=循环n的网格档位=P0±(2n-1)×A奇数倍递增(1A,3A,5A,7A…),       |
//|        每循环2张单同倍;例A=1:循环2档±3,循环3档±5                 |
//|     关=旧行为(全部阶段一单固定挂P0±A双档)                         |
//|   v5.70 新增InpInstantReopen止盈平组后立即重开开关:               |
//|     开=平组完成即定方向(实时箭头优先,无箭头按价格vs EMA10),       |
//|        槽位冷却到期后立即开新组,不等下一根信号K线收盘;            |
//|        周末黑窗仍拦截,组间冷却保留(用户2026-09-26拍板)            |
//|     关=旧行为(等信号K线收盘出信号)                                |
//|   历史版本(v1.20~v3.24)完整变更记录见 拾贝3.32终极版.mq5          |
//+------------------------------------------------------------------+
#property copyright "You"
#property version   "1.1"

#include <Trade\Trade.mqh>

//--- 常量
#define EA_TAG        "Z102"
#define MAX_SLOTS     100
#define OBJ_PREFIX    "GSB_"
#define DASH_X        10
#define DASH_Y        20
#define MAX_PERIOD_HIST 10  // 周期历史保留条数(每周期一行,满则滚动丢弃最旧)
#define LOG_GAP_SEC     600 // 交易闸门错误日志节流(GateThrottled用);v10.43起救援拦截日志不再使用(只状态变化式)

// v11.1 网站上报硬编码(不再作为输入参数)
const bool   UPLOAD_ENABLED = true;
const string UPLOAD_URL     = "http://101.37.29.106:35741";
const string UPLOAD_KEY     = "2c7b275a05bb55dae19fcf67349e62ea";

//=== 输入参数 ======================================================
//--- 利润回撤模式
enum ENUM_TRAIL_MODE
{
   TRAIL_PERCENT = 0,   // 百分比回撤(%)
   TRAIL_MONEY   = 1    // 固定金额回撤(账户货币)
};

input group "═══ 授权 ═══"
input string InpActivationCode = "";     // 激活码(作者生成器输出,绑定账号+到期时间,支持带横线粘贴)

input group "═══ 仓位 ═══"
input double InpInitLots = 0.01;  // init 起始手数
input double InpLotStepX = 0.01;  // X 阶段一手数递增
input double InpLotStepY = 0.01;  // Y 阶段二手数递增

input group "═══ 阶段一 ═══"
input double InpGridA   = 1;    // A 网格间距(美元)
input int    InpCyclesW = 1;      // W 循环次数(达W进阶段二)

input group "═══ 阶段二(逆势补仓) ═══"
input double InpStepB       = 5;    // B 补仓触发步长(美元,触发线外扩间距)
input double InpCooldownT   = 300;   // T 补仓冷却(秒,固定)

input group "═══ 套牢救援(独立于组逻辑) ═══"
input double InpRescueDist       = 10.0;  // 救援触发距离(美元,第一张救援单=套牢单开仓价±此值,0=关闭)
input double InpRescueDistStep   = 15.0;  // 救援固定间距加成(第2张起每张与上一张固定间距=触发距离+此值,v3.03起不再逐次累加)
input double InpRescueGapStep    = 5.0;   // 救援间距逐次叠加(v3.10新增:每多补一张,间距在上一次基础上+此值;0=不叠加保持固定)
input int    InpRescueCntStep    = 1;     // 每轮张数递增(v5.00:基数固定1,第k轮=1+(k-1)×此值,=1时第1/2/3轮=1/2/3张;0=每轮固定1张)
input string InpRescueLotSeq     = "0.12,0.18,0.24,0.30,0.36,0.42,0.48,0.54,0.60,0.66";   // 救援手数序列(v10.42:逗号分隔,从左到右=通道第1,2,3…张救援单最终手数;1~20个值,用完沿用最后一个;主/反组共用;中英文逗号均可)
input double InpRescueCooldown   = 2000;     // 救援冷却(秒,本通道每次救援成交后需冷却此秒数才可再补,间距+冷却同时满足才补;0=不冷却)
input double InpRescueCardSec    = 60;     // 出牌间隔(秒,逐张出牌:每张救援单之间须间隔此秒数,未到则暂停出牌;0=整轮同时出,旧行为)
input bool   InpRescueGlobalGap  = true;  // 全局救援间距闸门(v5.20;v10.43默认改关,用户2026-10-28拍板:实测1月底该闸把深救全堵死——救1张后25美元内新锚点全部被拦1466次/7天,救援死区致扛单亏损扩大;开=同方向任意救援单触发价距全EA最近同方向救援单≥出发+加成,跨通道跨组;关=间距只在通道内生效)
input double InpRescueLotsCap    = 10.0;    // 救援总手数上限(v10.10:全EA同方向救援单累计总手数达到此值后停止再出救援牌,封顶"组转亏后救援链完整展开"的逃逸路径敞口;0=不限制,旧行为)

input group "═══ 反向组(救援联动,最多2组并行) ═══"
input int    InpPairRescueCnt    = 1;      // 反向组启动救援次数(存活组累计救援触发≥此值开反向组,唯一启动条件;时间模式反向组同用此规则)
input int    InpPairCooldownSec  = 60;      // 反向组间隔秒数(v8.80:上一张反向单平仓后须满此秒数才能再开反向组;0=不间隔,旧行为)
input double InpPairGridA        = 5;    // 反向组网格间距(v10.40:阶段一档位P0±此值,美元;默认=主组A,行为不变)
input double InpPairStepB        = 10;    // 反向组补仓触发步长(v10.40:阶段二触发线外扩间距,美元;默认=主组B,行为不变)
input double InpPairRescueDist   = 15.0;  // 反向组救援触发距离(v10.40:反向组套牢单锚定±此值,美元;0=反向组套牢单不救援;默认=主组距离,行为不变)

input group "═══ 时间驱动开组(秒数节奏+双组并行) ═══"
input int    InpTimeOpenSec = 1;   // 零组到开首组间隔(秒,上一单整组平仓完成时开始计时,满此秒数按框中点方向开下一首组;0=平仓后立即开;v10.40用户定60)

input group "═══ 方向框(v10.40,高低点框方案A) ═══"
input ENUM_TIMEFRAMES InpBoxTF      = PERIOD_H4;  // 框参考周期(上/下轨=该周期近N根最高/最低价)
input int    InpBoxBars     = 24;   // 框回看根数(参考周期K线根数,如H1×24=一天)
input double InpBoxMinGap   = 30;   // 框最小间距(美元,下限1,v10.41放开;高度不足时以中点为中心扩展到此值,行情大不压缩用真实高低点)
input double InpBoxBreakSec = 1;   // 突破开组间隔(秒,零组时突破框线每此秒数开首组;v11.3起有存活组不再按突破开组;须>=1)
input bool   InpBoxShow     = true; // 画方向框(上/下轨/中点线+底色矩形)

input group "═══ 止盈/利润回撤(账户货币) ═══"
input double InpTwoSideProfit = 2.00;  // 止盈阈值(单边/双边统一,=回撤跟踪激活线;按手数开关开时作兜底)
input bool   InpProfitByLot   = true; // 主止盈按手数(v10.30:开=主止盈=组内最新成交主链单手数×每手系数,补仓后自动放大;关=固定InpTwoSideProfit旧行为)
input double InpProfitPerLot  = 100;   // 主止盈每手系数(v10.30:止盈=最新主链单手数×此值,0.01×200=2.00与固定2.00等价起步;仅按手数开关开时生效)
input double InpRescueProfit  = 24;     // 救援止盈阈值(组内持有救援单时替代主止盈,整组净利口径整组平;0=不启用,救援阶段也用主止盈)
input bool   InpRescueProfitByLot = true; // 救援止盈按手数(v5.60:开=止盈=最新成交救援单手数×每手系数,每次救援成交后自动切换;关=固定InpRescueProfit)
input double InpRescueProfitPerLot  = 100; // 救援止盈每手系数(v5.60:止盈=手数×此值,0.12×100=12,0.24×100=24;仅按手数开关开时生效)
input bool            InpTrailEnabled = true;         // 启用利润回撤(达双边止盈后持有)
input ENUM_TRAIL_MODE InpTrailMode    = TRAIL_PERCENT; // 回撤模式
input double          InpTrailValue   = 10.0;          // 回撤值(百分比%/固定金额)

input group "═══ 多组 ═══"
input int    InpMaxGroups        = 1;       // 最多并行组数(<2自动提升为2:反向组救援联动需两槽,防静默失效)

input group "═══ 风控 ═══"
input bool   InpWeekendBlackout  = false;    // 周末限制
input int    InpWeekendStartHour = 17;      // 每周五开始小时(=周五交易截止时间,到点后在途挂单做完最后一单即止)
input int    InpWeekendEndHour   = 6;       // 周一结束小时(服务器时间,到点恢复开组/加仓)
input long   InpMagic            = 20260820; // MagicNumber

input group "═══ 统计重置(v8.50) ═══"
input bool   InpStatsReset = true;  // 重置全部统计(挂载时=true则清空周期/历史行/最大亏损/总盈利/累计手数并从头起算,用完改回false;面板"重置统计"按钮可随时点击)

input group "═══ v10.00 审查修复新增 ═══"
input bool   InpRescuePeakAdjust  = true;   // 救援成交后下调回撤峰值(B1修复:减新单点差成本,回撤线随救援平移,救援链正常展开;关=旧行为救援即平仓)
input int    InpFreezeAlertSec    = 10800;  // 阶段二冻结告警秒数(B3:进阶段二后无补仓无止盈超过此秒数打告警日志;0=关)
input int    InpDeviationPoints   = 30;     // 市价单允许滑点(点,A4:0=用品种默认)
input int    InpRetryBackoffSec   = 60;     // 下单失败退避秒数(A4:下单失败后该组冷却此秒数再试,防日志爆炸;0=关)

input group "═══ 面板 ═══"
input bool InpShowDashboard = true;  // 显示状态面板
input int  InpPeriodDays    = 14;     // 统计周期(天)
input int  InpPanelWidth    = 460;   // 面板宽度(像素,最小320)
input int  InpPanelHeight   = 800;   // 面板高度(像素,最小440)

//=== 组状态 ========================================================
struct GroupState
{
   bool     active;        // 组激活
   bool     closing;       // 平仓中
   int      phase;         // 0=阶段一 1=阶段二
   double   p0;            // P 基准价(头仓成交价)
   int      orderCount;    // 已成交单数(含头仓)
   int      lastDir;       // 上一单方向 1多 -1空
   int      k1;            // 阶段二上侧系数
   int      k2;            // 阶段二下侧系数
   int      phase2Adds;    // 阶段二补仓次数 m
   datetime openTime;      // 开组时间(外部平仓检测基准:开组10秒后无持仓无挂单即重置)
   int      headDir;       // v6.00 头仓方向 1多 -1空(反向补组参考;0=收编未知)
   datetime lastAddTime;   // 上次成交时间(阶段二冷却基准)
   ulong    pendingTicket; // 阶段一挂单票号
   int      pendingDir;    // 挂单方向
   bool     trailActive;   // 利润回撤跟踪已激活
   double   peakProfit;    // 激活后利润峰值
   bool     isPair;        // v8.80 反向组标记(TryOpenPair开出=true;其平仓时刻作为反向组间隔计时基准)
};
GroupState groups[MAX_SLOTS];

//=== 全局变量 ======================================================
CTrade   trade;
int      g_maxGroups = 2;             // v10.00 初值改2(旧值3为死值,OnInit必然覆盖)

//--- v10.40 方向框缓存(方案A高低点框;每秒节流重算,实时bid判定方向/突破)
double   g_boxTop = 0, g_boxBottom = 0, g_boxMid = 0;   // 框上轨/下轨/中点(美元)
bool     g_boxReady = false;         // 框数据就绪(未就绪不开单,下tick重试)
datetime g_boxLastCalc = 0;          // 上次重算时刻(每秒节流)
datetime g_boxBreakLastOpen = 0;     // 突破模式上次开组时刻(InpBoxBreakSec硬节奏基准,GV持久化)
bool     g_isTester  = false;
datetime g_failUntil[MAX_SLOTS];     // v10.00 A4 下单失败退避:该组在此时刻前禁止重试下单
datetime g_freezeSince[MAX_SLOTS];   // v10.00 B3 冻结告警:进入"阶段二+无补仓+无止盈"状态的时刻
bool     g_freezeWarned[MAX_SLOTS];  // v10.00 B3 本轮冻结是否已告警(状态解除后复位)
bool     g_commentBad = false;       // v10.00 A3 注释自检:本EA存在无GSB前缀持仓=true(停止新开组)
datetime g_statsEpoch = 0;          // v8.50 统计基准时刻(重置后的盈亏/手数只从此刻起的成交计入,GV持久化;0=未重置过=全历史)
bool     g_blackout  = false;      // 周末限制中
bool     g_rescueDirty = true;     // v3.14 救援缓存脏标志(交易事务置脏,重建后清零)

//--- v10.42 救援手数序列(InpRescueLotSeq解析结果;OnInit校验时填充,运行期只读)
double   g_rescueSeq[20]  = {0};    // 序列值(最多20个,用户定上限)
int      g_rescueSeqN     = 0;      // 实际个数(1~20)

// v10.42 救援手数序列解析:逗号分隔手数值,从左到右=第1,2,3…张救援单手数
// API合规:StringSubstr/StringLen/StringGetCharacter为本机已编译源码先例,
// StringToDouble经官方文档核实(double StringToDouble(string value));
// 兼容中英文逗号/分号/空格/制表符分隔;每个值必须>0;最多20个;
// 成功=true并填充g_rescueSeq/g_rescueSeqN;失败=false并置err供校验日志
bool RescueSeqParse(string seq, string &err)
{
   g_rescueSeqN = 0;
   err = "";
   int len = StringLen(seq);
   for(int i = 0; i < len; )
   {
      ushort ch = StringGetCharacter(seq, i);
      // 跳过分隔符:空格/制表符/中英文逗号/中英文分号
      if(ch == ' ' || ch == '\t' || ch == ',' || ch == ';' ||
         ch == 0xFF0C || ch == 0xFF1B) { i++; continue; }
      // 收集数字token(数字/小数点),其余字符视为非法
      string tok = "";
      while(i < len)
      {
         ch = StringGetCharacter(seq, i);
         if((ch >= '0' && ch <= '9') || ch == '.') { tok += StringSubstr(seq, i, 1); i++; continue; }
         break;
      }
      if(tok == "")
      {
         err = "第" + IntegerToString(g_rescueSeqN + 1) + "个值附近存在非法字符(只允许数字/小数点/逗号/空格)";
         return false;
      }
      if(g_rescueSeqN >= 20)
      {
         err = "最多20个值(用户定1~20次)";
         return false;
      }
      double v = StringToDouble(tok);
      if(v <= 0)
      {
         err = "第" + IntegerToString(g_rescueSeqN + 1) + "个值(" + tok + ")必须>0";
         return false;
      }
      g_rescueSeq[g_rescueSeqN++] = v;
   }
   if(g_rescueSeqN < 1)
   {
      err = "至少填1个手数值(如0.01,0.02,0.03)";
      return false;
   }
   return true;
}

//--- 持仓缓存(每tick单次扫描)
int      g_posCount[MAX_SLOTS];
double   g_netProfit[MAX_SLOTS];
int      g_rescueCnt[MAX_SLOTS];   // v3.22 各组当前持有的救援单张数(缓存重建时统计,用于救援止盈切换)
double   g_totalNet = 0;
datetime g_timeCloseTime = 0;       // v8.20 时间模式上一单平仓完成时刻(零组定时开首组的计时基准,0=从未开过,首单立即开;GV持久化)
datetime g_pairCloseTime = 0;       // v8.80 最近一次反向组平仓时刻(InpPairCooldownSec的计时基准,0=从未有过反向组平仓;GV持久化)

//--- 周期统计(默认7天,余额差口径)
datetime g_periodEpoch   = 0;   // 周期起始时间
double   g_periodBase    = 0;   // 周期起始余额
double   g_periodMaxLoss = 0;   // 周期内最大亏损(含盈利内回撤,正数)
double   g_periodPeakEq  = 0;   // 周期内净值峰值(回撤基准)
double   g_periodMaxProfit = 0; // 周期内峰值盈利(净值相对周期基准,含浮盈,正数)
datetime g_histStart[MAX_PERIOD_HIST];   // 历史周期开始时间(索引0最旧)
double   g_histProfit[MAX_PERIOD_HIST];  // 历史周期利润(余额差口径)
double   g_histLoss[MAX_PERIOD_HIST];    // 历史周期最大亏损(净值口径,正数)
int      g_histCount = 0;                // 已完成周期数(≤MAX_PERIOD_HIST)
double   g_realizedProfit = 0;  // EA历史已实现盈亏(magic过滤,不含浮盈)
double   g_allTimePeakEq  = 0;  // 从头到尾净值峰值(最大亏损的回撤基准,GV持久化)
double   g_allTimeMaxLoss = 0;  // 从头到尾最大亏损(净值自峰值最大回撤,含盈利内回撤,正数,GV持久化)
datetime g_lastDealTime   = 0;  // v3.0 盈亏增量窗口起点(上次处理到的deal时间)
ulong    g_lastDealTicket = 0;  // v3.0 已处理最大deal票号(窗口边界去重);v3.10改ulong与HistoryDealGetTicket返回类型一致,消3条符号警告
double   g_totalOpenLots  = 0;  // v3.11 累计开仓手数(每成交一笔0.01就+0.01,只算开仓deal,面板"当前"旁显示)
datetime g_todayEpoch     = 0;  // v11.0 今日零点时间戳(自然日余额差基准)
double   g_todayBase      = 0;  // v11.0 今日零点余额
datetime g_weekEpoch      = 0;  // v11.0 本周一零点时间戳
double   g_weekBase       = 0;  // v11.0 本周一零点余额
datetime g_lastHoldUpload = 0;  // v11.2 上次扛单主动上报时刻(每小时一次)

//=== 工具函数 ======================================================
void LogInfo(string msg)  { Print("[", EA_TAG, "] ", msg); }
void LogError(string msg) { Print("[", EA_TAG, "][错误] ", msg); }

//=== 诊断文件(记录每步决策到 MQL5\Files\<EA_TAG>_diag.csv,同终端多EA不撞车) ===
int g_diagHandle = INVALID_HANDLE;

void DiagOpen()
{
   g_diagHandle = FileOpen(StringFormat("%s_diag.csv", EA_TAG), FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(g_diagHandle != INVALID_HANDLE)
      FileWrite(g_diagHandle, "time", "event", "group", "phase", "p0", "bid", "k1", "k2", "adds", "detail");
}

void Diag(string event, int g, string detail)
{
   if(g_diagHandle == INVALID_HANDLE) return;
   FileWrite(g_diagHandle,
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), event, IntegerToString(g),
      IntegerToString(groups[g].phase), DoubleToString(groups[g].p0, 2),
      DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), 2),
      IntegerToString(groups[g].k1), IntegerToString(groups[g].k2),
      IntegerToString(groups[g].phase2Adds), detail);
}

// 手数规范化:按品种最小手数/步数对齐(v8.30起单笔上限InpMaxLot已删,不再封顶)
// v10.00 A6:非正数输入不再静默变最小手数,记错误日志返回最小手数
double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   if(lot <= 0)
   {
      LogError(StringFormat("NormalizeLot 收到非正手数 %.4f,按最小手数 %.2f 处理(请检查参数)", lot, minLot));
      return NormalizeDouble(minLot, 8);
   }
   lot = MathFloor(lot / step + 0.5) * step;

   lot = MathMax(minLot, MathMin(maxLot, lot));
   return NormalizeDouble(lot, 8);
}

string GVPrefix(int g) { return StringFormat("EA_%I64d_G%d_", InpMagic, g); }
string GVPPeriod(string key) { return StringFormat("EA_%I64d_period_%s", InpMagic, key); }
string GVPHist(string key)   { return StringFormat("EA_%I64d_phist_%s", InpMagic, key); }
string GVPAll(string key)     { return StringFormat("EA_%I64d_all_%s", InpMagic, key); }

//=== v10.00 A4 下单前置校验辅助 =====================================
// 拦截日志通用节流:同类拦截600秒内不重复打(LOG_GAP_SEC)
datetime LastGateLog(string tag, bool set)
{
   static string  keys[48];
   static datetime times[48];
   static int      cnt = 0;
   // 找已有key
   for(int i = 0; i < cnt; i++)
      if(keys[i] == tag)
      {
         if(set) times[i] = TimeCurrent();
         return times[i];
      }
   if(cnt < 48 && set) { keys[cnt] = tag; times[cnt] = TimeCurrent(); cnt++; return times[cnt-1]; }
   return 0;
}
bool GateThrottled(string tag)
{
   datetime last = LastGateLog(tag, false);
   if(last > 0 && TimeCurrent() - last < LOG_GAP_SEC) return true;
   LastGateLog(tag, true);
   return false;
}

// 交易许可:终端自动交易开关/EA交易权限/品种交易模式
bool TradeGateOK(string tag)
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   { if(!GateThrottled(tag+":terminal")) LogError(tag + " 被拦:终端自动交易未开启"); return false; }
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   { if(!GateThrottled(tag+":mql")) LogError(tag + " 被拦:EA交易权限未开启"); return false; }
   long tm = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tm == SYMBOL_TRADE_MODE_DISABLED || tm == SYMBOL_TRADE_MODE_CLOSEONLY)
   { if(!GateThrottled(tag+":mode")) LogError(tag + " 被拦:品种当前禁止交易/只可平仓"); return false; }
   return true;
}

// 保证金校验:预计占用保证金须小于可用保证金的85%(留15%缓冲)
bool MarginOK(int dir, double lot, string tag)
{
   double price = (dir > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                            : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double margin = 0;
   if(!OrderCalcMargin(dir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, price, margin))
      return true;   // 计算失败不拦(保守放行,由服务器拒单兜底)
   double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(margin > free * 0.85)
   {
      if(!GateThrottled(tag+":margin"))
         LogError(StringFormat("%s 被拦:保证金不足 需%.2f 可用%.2f 手数%.2f",
                 tag, margin, free, lot));
      return false;
   }
   return true;
}

// A4 失败退避:该组失败冷却未到返回true(跳过);下单失败时调用 FailMark 记录
bool FailBackoff(int g, string tag)
{
   if(InpRetryBackoffSec <= 0) return false;
   if(TimeCurrent() < g_failUntil[g])
   {
      static datetime lastLog = 0;
      if(TimeCurrent() - lastLog >= 600)
      {
         LogInfo(StringFormat("%s 失败退避中(%d秒后重试)", tag,
                 (int)(g_failUntil[g] - TimeCurrent())));
         lastLog = TimeCurrent();
      }
      return true;
   }
   return false;
}
void FailMark(int g) { if(InpRetryBackoffSec > 0) g_failUntil[g] = TimeCurrent() + InpRetryBackoffSec; }

//=== v10.00 A3 注释自检:本EA持仓是否存在无GSB前缀的单子 ============
// 经纪商改写/清空注释会破坏救援链与挂单识别,发现即打醒目警告并置
// g_commentBad=true 停止新开组(已有组的网格/救援照常,等人工确认)
void CheckCommentHealth(string source)
{
   int bad = 0, total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      long mg = PositionGetInteger(POSITION_MAGIC);
      if(mg < InpMagic || mg >= InpMagic + g_maxGroups) continue;
      total++;
      string cm = PositionGetString(POSITION_COMMENT);
      if(StringFind(cm, "GSB") != 0)
      {
         bad++;
         LogError(StringFormat("[注释自检:%s] 持仓#%I64u(magic=%I64d)注释异常:\"%s\"——经纪商可能改写注释,救援链/挂单识别将失效!",
                 source, tk, (long)mg, cm));
      }
   }
   if(bad > 0 && !g_commentBad)
   {
      g_commentBad = true;
      LogError(StringFormat("[注释自检:%s] 发现%d/%d张持仓注释无GSB前缀,已停止新开组(等人工确认;已有组照常运行)", source, bad, total));
   }
   else if(bad == 0 && total > 0)
      g_commentBad = false;   // 全部正常(如异常单已被平掉),恢复开组
}

//=== 状态持久化(GlobalVariables,回测跳过) ==========================
void SavePeriodState()
{
   if(g_isTester) return;
   GlobalVariableSet(GVPPeriod("epoch"),   (double)(long)g_periodEpoch);
   GlobalVariableSet(GVPPeriod("base"),    g_periodBase);
   GlobalVariableSet(GVPPeriod("maxloss"), g_periodMaxLoss);
   GlobalVariableSet(GVPPeriod("peakeq"),  g_periodPeakEq);
   GlobalVariableSet(GVPPeriod("maxprof"), g_periodMaxProfit);
   GlobalVariableSet(GVPHist("n"), g_histCount);
   for(int i = 0; i < g_histCount && i < MAX_PERIOD_HIST; i++)
   {
      GlobalVariableSet(GVPHist(StringFormat("t%d", i)), (double)(long)g_histStart[i]);
      GlobalVariableSet(GVPHist(StringFormat("p%d", i)), g_histProfit[i]);
      GlobalVariableSet(GVPHist(StringFormat("l%d", i)), g_histLoss[i]);
   }
}

// 从头到尾最大亏损持久化(净值峰值/最大回撤,回测跳过)
void SaveAllTimeState()
{
   if(g_isTester) return;
   GlobalVariableSet(GVPAll("peak"), g_allTimePeakEq);
   GlobalVariableSet(GVPAll("max"),  g_allTimeMaxLoss);
}

//=== 今日/本周利润基准(v11.0,自然日历,余额差口径) ==================
datetime DayStart(datetime t)
{
   long sec = (long)t;
   return (datetime)((sec / 86400) * 86400);
}

datetime WeekStart(datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   int back = (dt.day_of_week + 6) % 7;   // 0=Sun..6=Sat → 距本周一天数
   return DayStart(t) - back * 86400;
}

void SaveTodayWeekState()
{
   if(g_isTester) return;
   GlobalVariableSet(GVPAll("today_epoch"), (double)(long)g_todayEpoch);
   GlobalVariableSet(GVPAll("today_base"),  g_todayBase);
   GlobalVariableSet(GVPAll("week_epoch"),  (double)(long)g_weekEpoch);
   GlobalVariableSet(GVPAll("week_base"),   g_weekBase);
}

void RollTodayWeek()
{
   datetime todayStart = DayStart(TimeCurrent());
   datetime weekStart  = WeekStart(TimeCurrent());
   if(todayStart > g_todayEpoch)
   {
      g_todayEpoch = todayStart;
      g_todayBase  = AccountInfoDouble(ACCOUNT_BALANCE);
      SaveTodayWeekState();
   }
   if(weekStart > g_weekEpoch)
   {
      g_weekEpoch = weekStart;
      g_weekBase  = AccountInfoDouble(ACCOUNT_BALANCE);
      SaveTodayWeekState();
   }
}

void TodayWeekInit()
{
   if(!g_isTester && GlobalVariableCheck(GVPAll("today_epoch")))
   {
      g_todayEpoch = (datetime)(long)GlobalVariableGet(GVPAll("today_epoch"));
      g_todayBase  = GlobalVariableGet(GVPAll("today_base"));
      g_weekEpoch  = (datetime)(long)GlobalVariableGet(GVPAll("week_epoch"));
      g_weekBase   = GlobalVariableGet(GVPAll("week_base"));
   }
   else
   {
      g_todayEpoch = DayStart(TimeCurrent());
      g_todayBase  = AccountInfoDouble(ACCOUNT_BALANCE);
      g_weekEpoch  = WeekStart(TimeCurrent());
      g_weekBase   = AccountInfoDouble(ACCOUNT_BALANCE);
      SaveTodayWeekState();
   }
   RollTodayWeek();
}

void TodayWeekUpdate()
{
   static datetime lastUpd = 0;
   if(TimeCurrent() == lastUpd) return;
   lastUpd = TimeCurrent();
   RollTodayWeek();
}

// v11.2 当前本EA持仓最早开仓时间到现在的小时数;无持仓=0
double GetHoldHours()
{
   datetime oldest = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      long mg = PositionGetInteger(POSITION_MAGIC);
      if(mg < InpMagic || mg >= InpMagic + g_maxGroups) continue;
      datetime t = (datetime)PositionGetInteger(POSITION_TIME);
      if(oldest == 0 || t < oldest) oldest = t;
   }
   if(oldest == 0) return 0.0;
   return (double)(TimeCurrent() - oldest) / 3600.0;
}

void UploadReport()
{
   if(!UPLOAD_ENABLED) return;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double todayProfit = balance - g_todayBase;
   double weekProfit  = balance - g_weekBase;
   double holdHours   = GetHoldHours();   // v11.2 扛单小时数(无持仓=0)

   string login = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   string json = StringFormat(
      "{\"login\":\"%s\",\"equity\":%.2f,\"todayProfit\":%.2f,\"weekProfit\":%.2f,\"server\":\"%s\",\"holdHours\":%.1f}",
      login, equity, todayProfit, weekProfit, AccountInfoString(ACCOUNT_SERVER), holdHours);

   char post[];
   char result[];
   string reqHeaders = "Content-Type: application/json\r\nx-api-key: " + UPLOAD_KEY + "\r\n";
   string respHeaders;
   int n = StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(post, n - 1);
   int code = WebRequest("POST", UPLOAD_URL + "/api/submit", reqHeaders, 10000, post, result, respHeaders);
   string resp = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);

   if(code == 200)
      LogInfo(StringFormat("[上报] 成功:净值%.2f 今日%+.2f 本周%+.2f", equity, todayProfit, weekProfit));
   else
      LogError(StringFormat("[上报] 失败 HTTP %d 响应=%s", code, resp));
}

// v11.2 扛单超过1小时后,每小时主动上报一次(让看板实时显示扛单时长)
void MaybeUploadHold()
{
   if(!UPLOAD_ENABLED) return;
   double h = GetHoldHours();
   if(h <= 1.0)
   {
      g_lastHoldUpload = 0;   // 未扛单/扛单不足1小时,重置计时
      return;
   }
   datetime now = TimeCurrent();
   if(g_lastHoldUpload != 0 && now - g_lastHoldUpload < 3600) return;  // 距上次上报不足1小时
   g_lastHoldUpload = now;
   UploadReport();
}

// v8.20 时间驱动开组模式状态持久化(仅计时基准;v8.10的方向交替tmDir已退场)
// v8.80 增存反向组平仓时刻pairclose(InpPairCooldownSec计时基准)
// v10.40 增存突破模式上次开组时刻brkopen(InpBoxBreakSec硬节奏基准)
void SaveTimeModeState()
{
   if(g_isTester) return;
   GlobalVariableSet(GVPAll("tmClose"), (double)(long)g_timeCloseTime);
   GlobalVariableSet(GVPAll("pairclose"), (double)(long)g_pairCloseTime);
   GlobalVariableSet(GVPAll("brkopen"), (double)(long)g_boxBreakLastOpen);
}

void LoadTimeModeState()
{
   if(g_isTester) return;
   if(GlobalVariableCheck(GVPAll("tmClose")))
   {
      g_timeCloseTime = (datetime)(long)GlobalVariableGet(GVPAll("tmClose"));
      LogInfo(StringFormat("时间模式状态恢复:上单平仓=%s(零组时满间隔秒数即开首组)",
               g_timeCloseTime > 0 ? TimeToString(g_timeCloseTime, TIME_DATE|TIME_MINUTES) : "无"));
   }
   if(GlobalVariableCheck(GVPAll("pairclose")))
      g_pairCloseTime = (datetime)(long)GlobalVariableGet(GVPAll("pairclose"));
   if(GlobalVariableCheck(GVPAll("brkopen")))
      g_boxBreakLastOpen = (datetime)(long)GlobalVariableGet(GVPAll("brkopen"));
}

// v8.50 统计重置:周期统计/历史周期行/从头到尾最大亏损/总盈利/累计下单手数
// 全部从头起算。实现=统计基准时刻g_statsEpoch(GV sepoch持久化):增量窗口
// 从基准时刻起算,基准前的成交不再计入盈亏与手数;周期/最大亏损按当前
// 余额净值重新立基。时间模式计时基准tmClose与组状态GV不受影响。
// 触发:①参数InpStatsReset=true挂载时(OnInit调用,用完需改回false)
//       ②面板"重置统计"按钮点击(OnChartEvent调用,随时可用)
void DoStatsReset(string source)
{
   g_statsEpoch     = TimeCurrent();
   g_periodEpoch    = TimeCurrent();
   g_periodBase     = AccountInfoDouble(ACCOUNT_BALANCE);
   g_periodMaxLoss  = 0;
   g_periodPeakEq   = AccountInfoDouble(ACCOUNT_EQUITY);
   g_periodMaxProfit = 0;
   g_histCount      = 0;
   g_allTimePeakEq  = g_periodPeakEq;
   g_allTimeMaxLoss = 0;
   g_lastDealTime   = TimeCurrent();   // 增量窗口重开:旧成交不再计入总盈利/累计手数
   g_lastDealTicket = 0;
   g_realizedProfit = 0;
   g_totalOpenLots  = 0;
   if(!g_isTester)
   {
      GlobalVariableSet(GVPAll("sepoch"), (double)(long)g_statsEpoch);
      // 只删统计类GV:周期统计(period_前缀)与历史行(phist_前缀)整删,
      // 从头到尾峰值/最大亏损(peak/max)单删——tmClose与sepoch同在all_前缀
      // 下但单独保存,不受影响
      GlobalVariablesDeleteAll(GVPPeriod(""));
      GlobalVariablesDeleteAll(GVPHist(""));
      GlobalVariableDel(GVPAll("peak"));
      GlobalVariableDel(GVPAll("max"));
      SavePeriodState();
      SaveAllTimeState();
   }
   LogInfo(StringFormat("统计已重置(%s):周期/历史行/最大亏损/总盈利/累计手数全部从头起算,基准=%s",
           source, TimeToString(g_statsEpoch, TIME_DATE|TIME_SECONDS)));
}

// 周期初始化:加载GV;无记录或停机跨周期 → 以当前余额开新周期
void PeriodInit()
{
   long periodSec = (long)MathMax(1, InpPeriodDays) * 86400;
   // v8.50 统计基准时刻:重置后的总盈利/累计手数只统计此后的成交
   // (增量窗口起点对齐基准,老成交不进窗口;未重置过sepoch=0,窗口从0起=全历史)
   if(!g_isTester && GlobalVariableCheck(GVPAll("sepoch")))
      g_statsEpoch = (datetime)(long)GlobalVariableGet(GVPAll("sepoch"));
   if(!g_isTester && g_statsEpoch > 0 && g_lastDealTime == 0)
      g_lastDealTime = g_statsEpoch;
   // 从头到尾最大亏损:GV恢复(无记录则运行中自当前净值起算)
   if(!g_isTester && GlobalVariableCheck(GVPAll("max")))
   {
      g_allTimePeakEq  = GlobalVariableGet(GVPAll("peak"));
      g_allTimeMaxLoss = GlobalVariableGet(GVPAll("max"));
   }
   if(!g_isTester && GlobalVariableCheck(GVPPeriod("epoch")))
   {
      g_periodEpoch   = (datetime)(long)GlobalVariableGet(GVPPeriod("epoch"));
      g_periodBase    = GlobalVariableGet(GVPPeriod("base"));
      g_periodMaxLoss = GlobalVariableGet(GVPPeriod("maxloss"));
      g_periodPeakEq  = GlobalVariableCheck(GVPPeriod("peakeq"))
                        ? GlobalVariableGet(GVPPeriod("peakeq"))
                        : AccountInfoDouble(ACCOUNT_EQUITY);   // 旧版无此字段→以当前净值起算
      g_periodMaxProfit = GlobalVariableGet(GVPPeriod("maxprof"));
      g_histCount = (int)GlobalVariableGet(GVPHist("n"));
      if(g_histCount < 0) g_histCount = 0;
      if(g_histCount > MAX_PERIOD_HIST) g_histCount = MAX_PERIOD_HIST;
      for(int i = 0; i < g_histCount; i++)
      {
         g_histStart[i]  = (datetime)(long)GlobalVariableGet(GVPHist(StringFormat("t%d", i)));
         g_histProfit[i] = GlobalVariableGet(GVPHist(StringFormat("p%d", i)));
         g_histLoss[i]   = GlobalVariableGet(GVPHist(StringFormat("l%d", i)));
      }
   }
   else
   {
      g_periodEpoch   = TimeCurrent();
      g_periodBase    = AccountInfoDouble(ACCOUNT_BALANCE);
      g_periodMaxLoss = 0;
      g_periodPeakEq  = AccountInfoDouble(ACCOUNT_EQUITY);
      g_periodMaxProfit = 0;
      SavePeriodState();
      return;
   }
   // 停机跨周期(落后≥1个周期) → 滚动对齐并以当前余额开新周期
   if(TimeCurrent() - g_periodEpoch >= periodSec)
   {
      datetime startEpoch = g_periodEpoch;
      while(TimeCurrent() - g_periodEpoch >= periodSec)
         g_periodEpoch = (datetime)((long)g_periodEpoch + periodSec);
      double profit = AccountInfoDouble(ACCOUNT_BALANCE) - g_periodBase;
      LogInfo(StringFormat("停机跨周期:上一周期利润%+.2f 峰值盈利%.2f 最大亏损%.2f,以当前余额开新周期",
               profit, g_periodMaxProfit, g_periodMaxLoss));
      RecordPeriodEnd(startEpoch, profit, g_periodMaxLoss);
      g_periodBase    = AccountInfoDouble(ACCOUNT_BALANCE);
      g_periodMaxLoss = 0;
      g_periodPeakEq  = AccountInfoDouble(ACCOUNT_EQUITY);
      g_periodMaxProfit = 0;
      SavePeriodState();
   }
}

// 周期结束:滚动追加历史记录(满MAX_PERIOD_HIST丢弃最旧),GV持久化,面板显示用
void RecordPeriodEnd(datetime start, double profit, double maxLoss)
{
   if(g_histCount >= MAX_PERIOD_HIST)
   {
      for(int i = 1; i < MAX_PERIOD_HIST; i++)
      {
         g_histStart[i - 1]  = g_histStart[i];
         g_histProfit[i - 1] = g_histProfit[i];
         g_histLoss[i - 1]   = g_histLoss[i];
      }
      g_histCount = MAX_PERIOD_HIST - 1;
   }
   g_histStart[g_histCount]  = start;
   g_histProfit[g_histCount] = profit;
   g_histLoss[g_histCount]   = maxLoss;
   g_histCount++;
   SavePeriodState();
}

// 周期滚动 + 最大亏损跟踪(每秒节流)
void PeriodUpdate()
{
   static datetime lastUpd = 0;
   if(TimeCurrent() == lastUpd) return;
   lastUpd = TimeCurrent();

   long periodSec = (long)MathMax(1, InpPeriodDays) * 86400;
   if(TimeCurrent() - g_periodEpoch >= periodSec)
   {
      double profit = AccountInfoDouble(ACCOUNT_BALANCE) - g_periodBase;
      LogInfo(StringFormat("周期结束(%d天):利润%+.2f 峰值盈利%.2f 最大亏损%.2f,开启新周期",
               InpPeriodDays, profit, g_periodMaxProfit, g_periodMaxLoss));
      datetime startEpoch = g_periodEpoch;
      while(TimeCurrent() - g_periodEpoch >= periodSec)
         g_periodEpoch = (datetime)((long)g_periodEpoch + periodSec);
      RecordPeriodEnd(startEpoch, profit, g_periodMaxLoss);
      g_periodBase    = AccountInfoDouble(ACCOUNT_BALANCE);
      g_periodMaxLoss = 0;
      g_periodPeakEq  = AccountInfoDouble(ACCOUNT_EQUITY);
      g_periodMaxProfit = 0;
      SavePeriodState();
   }

   // 周期亏损(含盈利内回撤):净值自周期内峰值的最大回落
   // 例:周期内净值先到+5再跌回+2 → 亏损记3(回撤亏损),而不是只看是否跌破基准
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > g_periodPeakEq)
   {
      g_periodPeakEq = eq;
      SavePeriodState();
   }
   if(g_periodPeakEq - eq > g_periodMaxLoss)
   {
      g_periodMaxLoss = g_periodPeakEq - eq;
      SavePeriodState();
   }
   // 峰值盈利:净值(含浮盈)相对周期基准的最大涨幅
   double gap = eq - g_periodBase;
   if(gap > g_periodMaxProfit)
   {
      g_periodMaxProfit = gap;
      SavePeriodState();
   }

   // 从头到尾最大亏损:净值自历史峰值的最大回撤(盈利中的回撤也计入,打破纪录即更新)
   if(eq > g_allTimePeakEq)
   {
      g_allTimePeakEq = eq;
      SaveAllTimeState();
   }
   if(g_allTimePeakEq - eq > g_allTimeMaxLoss)
   {
      g_allTimeMaxLoss = g_allTimePeakEq - eq;
      SaveAllTimeState();
   }
}

// EA历史已实现盈亏(magic过滤,增量累计) + 自挂载以来买入开仓手数
// v3.0 性能优化:HistorySelect改为"上次处理时间→当前"的增量时间窗口,
// 每tick成本从O(全部历史)降到O(新增成交)——回测不再随成交数累积变慢。
// ticket去重保证窗口边界重叠的deal不重复统计;重启后窗口从0起全扫一遍,
// 结果口径与旧版一致。交易逻辑零改动。
void UpdateRealizedProfit()
{
   // v3.14 每秒节流:纯统计用途(面板/报表),窗口按时间推进,跳过的tick不丢数据
   static datetime lastUpd = 0;
   if(TimeCurrent() == lastUpd) return;
   lastUpd = TimeCurrent();

   if(!HistorySelect(g_lastDealTime, TimeCurrent())) return;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(ticket <= g_lastDealTicket) continue;   // 上次已处理(窗口边界重叠去重)
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
      if(magic < InpMagic || magic >= InpMagic + g_maxGroups) continue;   // v10.00 D1 口径统一
      // v3.11 累计开仓手数:只统计开仓deal(头仓/网格/补仓/救援),平仓deal不计
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN)
         g_totalOpenLots += HistoryDealGetDouble(ticket, DEAL_VOLUME);
      g_realizedProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT)
                        + HistoryDealGetDouble(ticket, DEAL_SWAP)
                        + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                        + HistoryDealGetDouble(ticket, DEAL_FEE);
      if(ticket > g_lastDealTicket) g_lastDealTicket = ticket;
   }
   // 窗口推进:取窗口内最后一笔deal时间;无新成交则推进到当前时间(窗口清空)
   if(total > 0)
   {
      ulong lastTk = HistoryDealGetTicket(total - 1);
      if(lastTk > 0)
      {
         datetime lastT = (datetime)HistoryDealGetInteger(lastTk, DEAL_TIME);
         if(lastT > g_lastDealTime) g_lastDealTime = lastT;
      }
   }
   else
      g_lastDealTime = TimeCurrent();
}

void SaveState(int g)
{
   if(g_isTester) return;
   string p = GVPrefix(g);
   GlobalVariableSet(p+"active",   groups[g].active ? 1 : 0);
   GlobalVariableSet(p+"closing",  groups[g].closing ? 1 : 0);
   GlobalVariableSet(p+"phase",    groups[g].phase);
   GlobalVariableSet(p+"p0",       groups[g].p0);
   GlobalVariableSet(p+"cnt",      groups[g].orderCount);
   GlobalVariableSet(p+"lastdir",  groups[g].lastDir);
   GlobalVariableSet(p+"k1",       groups[g].k1);
   GlobalVariableSet(p+"k2",       groups[g].k2);
   GlobalVariableSet(p+"p2adds",   groups[g].phase2Adds);
   GlobalVariableSet(p+"opentime", (double)(long)groups[g].openTime);
   GlobalVariableSet(p+"lastadd",  (double)(long)groups[g].lastAddTime);
   GlobalVariableSet(p+"pend",     (double)(long)groups[g].pendingTicket);
   GlobalVariableSet(p+"penddir",  groups[g].pendingDir);
   GlobalVariableSet(p+"trail",    groups[g].trailActive ? 1 : 0);
   GlobalVariableSet(p+"peak",     groups[g].peakProfit);
   GlobalVariableSet(p+"headdir",  groups[g].headDir);            // v6.00 头仓方向
   GlobalVariableSet(p+"ispair",   groups[g].isPair ? 1 : 0);     // v8.80 反向组标记
}

void DeleteState(int g)
{
   if(g_isTester) return;
   GlobalVariablesDeleteAll(GVPrefix(g));
}

void LoadState()
{
   if(g_isTester) return;
   for(int g = 0; g < g_maxGroups; g++)   // v10.00 D1 只读活跃槽位,高槽位由越界清理处理
   {
      string p = GVPrefix(g);
      if(GlobalVariableCheck(p+"active") && GlobalVariableGet(p+"active") > 0.5)
      {
         groups[g].active      = true;
         groups[g].closing     = (GlobalVariableGet(p+"closing")  > 0.5);
         groups[g].phase       = (int)GlobalVariableGet(p+"phase");
         groups[g].p0          = GlobalVariableGet(p+"p0");
         groups[g].orderCount  = (int)GlobalVariableGet(p+"cnt");
         groups[g].lastDir     = (int)GlobalVariableGet(p+"lastdir");
         groups[g].k1          = (int)GlobalVariableGet(p+"k1");
         groups[g].k2          = (int)GlobalVariableGet(p+"k2");
         groups[g].phase2Adds  = (int)GlobalVariableGet(p+"p2adds");
         groups[g].openTime    = (datetime)(long)GlobalVariableGet(p+"opentime");
         groups[g].lastAddTime = (datetime)(long)GlobalVariableGet(p+"lastadd");
         groups[g].pendingTicket = (ulong)(long)GlobalVariableGet(p+"pend");
         groups[g].pendingDir  = (int)GlobalVariableGet(p+"penddir");
         groups[g].trailActive = (GlobalVariableGet(p+"trail") > 0.5);
         groups[g].peakProfit  = GlobalVariableGet(p+"peak");
         groups[g].headDir     = (int)GlobalVariableGet(p+"headdir");        // v6.00 头仓方向
         groups[g].isPair      = (GlobalVariableGet(p+"ispair") > 0.5);      // v8.80 反向组标记
      }
   }
}

// 重启后收编无状态持仓(崩溃恢复):按持仓位置重建组状态
void AdoptOrphanPositions()
{
   for(int g = 0; g < g_maxGroups; g++)
   {
      if(groups[g].active) continue;
      int    cnt = 0;
      int    rescueCnt = 0;   // v3.01 救援单数(收编反推时剔除,防污染阶段二计数)
      double earliestPrice = 0;
      datetime earliestTime = 0, latestTime = 0;
      int    lastDir = 0;
      int    earliestDir = 0;   // v6.00 最早持仓方向(头仓方向参考)

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagic + g) continue;
         datetime t = (datetime)PositionGetInteger(POSITION_TIME);
         if(cnt == 0 || t < earliestTime)
         { earliestTime = t; earliestPrice = PositionGetDouble(POSITION_PRICE_OPEN);
           earliestDir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1; }
         if(t >= latestTime)
         { latestTime = t;
           lastDir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1; }
         cnt++;
         if(StringFind(PositionGetString(POSITION_COMMENT), "GSB救") == 0) rescueCnt++;
      }
      if(cnt == 0) continue;

      // v3.01 阶段二计数只按非救援单(头仓/网格/阶段二)反推——救援单不再被
      // 算进phase2Adds,重启收编后阶段二手数不会被救援单数虚推
      int normalCnt = cnt - rescueCnt;
      groups[g].active      = true;
      groups[g].closing     = false;
      groups[g].p0          = earliestPrice;
      groups[g].orderCount  = cnt;
      groups[g].lastDir     = lastDir;
      groups[g].k1          = 1;
      groups[g].k2          = 1;
      groups[g].phase2Adds  = MathMax(0, normalCnt - (2*InpCyclesW + 1));
      groups[g].openTime    = earliestTime;
      groups[g].lastAddTime = latestTime;
      groups[g].phase       = (normalCnt - 1 >= 2*InpCyclesW) ? 1 : 0;
      // v10.00 A2 收编前先扫服务器残留挂单:能对上方向的回填票号,其余撤除
      // (旧版无条件清零,残留的GSB网格Stop单会导致双份网格)
      groups[g].pendingTicket = 0;
      groups[g].pendingDir  = 0;
      for(int o = OrdersTotal() - 1; o >= 0; o--)
      {
         ulong ot = OrderGetTicket(o);
         if(ot == 0) continue;
         if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
         if(OrderGetInteger(ORDER_MAGIC) != InpMagic + g) continue;
         long otype = OrderGetInteger(ORDER_TYPE);
         if(otype != ORDER_TYPE_BUY_STOP && otype != ORDER_TYPE_SELL_STOP) continue;
         int odir = (otype == ORDER_TYPE_BUY_STOP) ? 1 : -1;
         if(groups[g].pendingTicket == 0)
         {
            groups[g].pendingTicket = ot;
            groups[g].pendingDir    = odir;
            LogInfo(StringFormat("G%d 收编回填挂单#%I64u(%s)", g, ot, odir > 0 ? "BuyStop" : "SellStop"));
         }
         else
         {
            if(trade.OrderDelete(ot))
               LogInfo(StringFormat("G%d 收编撤除多余残留挂单#%I64u", g, ot));
            else
               LogError(StringFormat("G%d 收编撤除多余挂单#%I64u失败 ret=%d(下tick兜底无法覆盖,请人工检查)", g, ot, trade.ResultRetcode()));
         }
      }
      // v10.00 D6 收编恢复利润回撤状态:GV中持久化的trail/peak不再凭空清零
      string pfx = GVPrefix(g);
      if(GlobalVariableCheck(pfx+"trail") && GlobalVariableGet(pfx+"trail") > 0.5
         && GlobalVariableCheck(pfx+"peak"))
      {
         groups[g].trailActive = true;
         groups[g].peakProfit  = GlobalVariableGet(pfx+"peak");
         LogInfo(StringFormat("G%d 收编恢复回撤状态:peak=%.2f", g, groups[g].peakProfit));
      }
      groups[g].headDir     = earliestDir;   // v6.00 头仓方向=最早持仓方向
      groups[g].isPair      = false;         // v8.80 收编组反向属性未知,按非反向组(其平仓不触发反向组间隔)
      SaveState(g);
      LogInfo(StringFormat("G%d 收编%d个无状态持仓(崩溃恢复):P=%.2f 阶段%d 单数%d(含救援%d) 头向%s",
                           g, cnt, groups[g].p0, groups[g].phase+1, cnt, rescueCnt,
                           earliestDir > 0 ? "多" : (earliestDir < 0 ? "空" : "未知")));
   }
}

//=== 初始化 ========================================================
int OnInit()
{
   g_isTester  = (bool)MQLInfoInteger(MQL_TESTER);
   g_maxGroups = MathMax(1, MathMin(MAX_SLOTS, InpMaxGroups));
   if(g_maxGroups < 2)
   {
      g_maxGroups = 2;   // 反向组救援联动需两槽(最多持有两组),防静默失效
      LogInfo("[双组并行] InpMaxGroups 已强制提升为 2(反向组救援联动需两槽)");
   }

   // v10.00 A6/A7 参数合法性校验:非法直接拒绝加载,不再带病运行
   // v10.40 增:方向框参数(InpBoxMinGap下限1,v10.41放开)+反向组独立三参数
   // v10.42 增:救援手数序列解析(成功时填充g_rescueSeq/g_rescueSeqN,失败拒载)
   string rseqErr = "";
   bool   rseqOK  = RescueSeqParse(InpRescueLotSeq, rseqErr);
   if(!rseqOK
      || InpInitLots <= 0 || InpLotStepX < 0 || InpLotStepY < 0
      || InpGridA <= 0 || InpCyclesW < 1
      || InpTwoSideProfit <= 0
      || (InpRescueProfitByLot && InpRescueProfitPerLot <= 0)
      || (InpProfitByLot && InpProfitPerLot <= 0)
      || InpRescueDist < 0 || InpStepB < 0 || InpCooldownT < 0
      || InpPairGridA <= 0 || InpPairStepB < 0 || InpPairRescueDist < 0
      || InpPairRescueCnt < 1                       // v11.4:0/负数会让救援门槛恒成立,第二组无救援即开
      || InpBoxBars < 2 || InpBoxBars > 1000
      || InpBoxMinGap < 1 || InpBoxBreakSec < 1)
   {
      string why = "";
      if(!rseqOK) why = "救援手数序列非法:" + rseqErr;
      else if(InpInitLots <= 0) why = "InpInitLots 必须>0";
      else if(InpLotStepX < 0 || InpLotStepY < 0) why = "InpLotStepX/Y 不得为负";
      else if(InpGridA <= 0) why = "InpGridA 必须>0(=0会单tick递归市价追单)";
      else if(InpCyclesW < 1) why = "InpCyclesW 必须>=1";
      else if(InpTwoSideProfit <= 0) why = "InpTwoSideProfit 必须>0(<=0会开组即平仓空转)";
      else if(InpRescueProfitByLot && InpRescueProfitPerLot <= 0) why = "InpRescueProfitPerLot 必须>0";
      else if(InpProfitByLot && InpProfitPerLot <= 0) why = "InpProfitPerLot 必须>0(<=0会开组即平仓空转)";
      else if(InpPairGridA <= 0) why = "InpPairGridA 必须>0(=0会单tick递归市价追单)";
      else if(InpPairStepB < 0 || InpPairRescueDist < 0) why = "InpPairStepB/InpPairRescueDist 不得为负";
      else if(InpPairRescueCnt < 1) why = "InpPairRescueCnt 必须>=1(<=0会让第二组无救援即开)";
      else if(InpBoxBars < 2 || InpBoxBars > 1000) why = "InpBoxBars 须在2~1000之间";
      else if(InpBoxMinGap < 1) why = "InpBoxMinGap 不得低于1(用户定框最小间距,v10.41放开)";
      else if(InpBoxBreakSec < 1) why = "InpBoxBreakSec 必须>=1秒(突破开单节奏过快会失控)";
      else why = "InpStepB/InpCooldownT/InpRescueDist 不得为负";
      LogError("参数校验失败:" + why + ",拒绝加载");
      Alert("拾贝联网V1.1 参数校验失败:\n", why);
      return(INIT_PARAMETERS_INCORRECT);
   }

   // v10.00 A4 市价单滑点
   if(InpDeviationPoints > 0) trade.SetDeviationInPoints((ulong)InpDeviationPoints);

   // v5.90 授权校验:无码/码无效/账号不符/已过期 → 拒绝加载
   // (回测模式跳过授权:测试器账号非真实账号,方便作者随时回测;实盘/DEMO严格执行)
   g_authOK    = false;
   g_authReason = "";
   if(g_isTester)
   {
      g_authOK = true;
   }
   else if(!ValidateActivation(InpActivationCode, g_authReason))
   {
      LogError("授权校验失败:" + g_authReason);
      Alert("拾贝联网V1.1 授权校验失败:\n", g_authReason);
      return(INIT_FAILED);
   }
   else
      g_authOK = true;

   trade.SetTypeFillingBySymbol(_Symbol);

   for(int g = 0; g < MAX_SLOTS; g++) ZeroMemory(groups[g]);
   LoadState();
   AdoptOrphanPositions();

   // v10.00 D1 越界槽位清理:高槽位的僵尸组状态/持仓/挂单一次性处置,
   // 防僵尸组让 TryOpenByTime/TryOpenPair 静默死锁
   for(int g = g_maxGroups; g < MAX_SLOTS; g++)
   {
      bool hadGV = false;
      for(int o = OrdersTotal() - 1; o >= 0; o--)   // 先撤高槽位残留挂单
      {
         ulong ot = OrderGetTicket(o);
         if(ot == 0) continue;
         if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
         if(OrderGetInteger(ORDER_MAGIC) != InpMagic + g) continue;
         if(trade.OrderDelete(ot))
            LogInfo(StringFormat("越界清理:撤除高槽位G%d挂单#%I64u", g, ot));
      }
      for(int i = PositionsTotal() - 1; i >= 0; i--)   // 高槽位持仓平掉
      {
         ulong pt = PositionGetTicket(i);
         if(pt == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagic + g) continue;
         if(trade.PositionClose(pt))
            LogInfo(StringFormat("越界清理:平掉高槽位G%d持仓#%I64u", g, pt));
         else
            LogError(StringFormat("越界清理:G%d持仓#%I64u平掉失败 ret=%d,请人工处理", g, pt, trade.ResultRetcode()));
         hadGV = true;
      }
      string p = GVPrefix(g);
      if(GlobalVariablesTotal() > 0 && GlobalVariableCheck(p+"active"))
      { GlobalVariablesDeleteAll(p); hadGV = true; }
      if(hadGV)
         LogInfo(StringFormat("越界清理:G%d(>=g_maxGroups=%d)僵尸状态已清除", g, g_maxGroups));
   }

   // v10.00 A3 注释自检(挂载时)
   CheckCommentHealth("挂载");
   // v8.50 统计重置(参数触发):须在PeriodInit之前,清完GV让周期按当前余额重新立基
   if(InpStatsReset)
   {
      if(!g_isTester)
      {
         DoStatsReset("参数InpStatsReset");
         LogInfo("提醒:InpStatsReset 仍为 true,下次重启将再次清空统计,用完请改回 false");
      }
      else
         LogInfo("回测模式跳过统计重置(回测统计本就从零起算)");
   }
   PeriodInit();
   TodayWeekInit();        // v11.0 今日/本周余额基准初始化
   LoadTimeModeState();   // v8.20 时间模式状态恢复(零组计时基准)

   // v10.00 E5:面板关闭时"重置统计"按钮仍要创建(旧版按钮在UpdateDashboard内
   // 创建,InpShowDashboard=false 时按钮根本不存在,无法随时重置)
   if(!InpShowDashboard && !g_isTester)
      DashButton(OBJ_PREFIX+"BtnReset", 10, 8, 56, 16, "重置统计");

   DiagOpen();
   if(g_diagHandle != INVALID_HANDLE)
      FileWrite(g_diagHandle, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), "INIT", "-1", "0", "0",
                DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), 2), "0", "0", "0",
                StringFormat("B=%.1f T=%.0f",
                             InpStepB, InpCooldownT));

   string rdLog = StringFormat("%.1f", InpRescueDist);
   string rsLog = (InpRescueGapStep > 0)
      ? StringFormat("固定%.1f起每张+%.1f", InpRescueDist + InpRescueDistStep, InpRescueGapStep)
      : StringFormat("固定%.1f(=距离+加成)", InpRescueDist + InpRescueDistStep);
   BoxUpdate();   // v10.40 首次计算方向框(数据未就绪时启动日志显示否,运行中自动重试)
   LogInfo(StringFormat(
      "拾贝联网V1.1 启动 | %s | init=%.2f X=%.2f Y=%.2f | A=%.1f 反A=%.1f W=%d | "
      "阶段二 B=%.1f 反B=%.1f T=%.0f 单向=只顺头仓方向 | "
      "救援=%s 距离=%s 反距=%s 固定间距=%s 每轮张数=1(+%d/轮) 手数序列=%s(共%d个,用完沿用末值) 冷却=%.0f 出牌=%.0f 全局间距=%s | "
      "组=%d 反向组触发=%d次救援 反向组间隔=%s | 止盈 统一%s 救援=%s 回撤%s=%.1f%s | 周期=%d天 | Magic=%I64d",
      _Symbol,
      InpInitLots, InpLotStepX, InpLotStepY,
      InpGridA, InpPairGridA, InpCyclesW,
      InpStepB, InpPairStepB, InpCooldownT,
      (InpRescueDist > 0 || InpPairRescueDist > 0) ? "开" : "关", rdLog,
      StringFormat("%.1f", InpPairRescueDist), rsLog,
      InpRescueCntStep, InpRescueLotSeq, g_rescueSeqN,
      InpRescueCooldown, InpRescueCardSec,
      InpRescueGlobalGap ? "开(跨通道跨组)" : "关",
      g_maxGroups, InpPairRescueCnt,
      InpPairCooldownSec > 0 ? StringFormat("%d秒", InpPairCooldownSec) : "无(旧行为)",
      InpProfitByLot ? StringFormat("手数×%.0f", InpProfitPerLot) : DoubleToString(InpTwoSideProfit, 2),
      InpRescueProfitByLot ? StringFormat("手数×%.0f", InpRescueProfitPerLot)
                           : (InpRescueProfit > 0 ? DoubleToString(InpRescueProfit, 2) : "随主"),
      InpTrailMode == TRAIL_PERCENT ? "%" : "U", InpTrailValue,
      InpTrailEnabled ? "" : "(关)",
      InpPeriodDays, InpMagic));
   LogInfo(StringFormat(
      "[v10.10新增] 救援峰值下调+回撤优先=%s | 救援总手数上限=%s | 冻结告警=%s | 市价滑点=%d点 | 失败退避=%ds | 注释自检=开(异常时停新开组) | magic口径=%d组",
      InpRescuePeakAdjust ? "开" : "关(旧行为)",
      InpRescueLotsCap > 0 ? StringFormat("%.2f手/同方向", InpRescueLotsCap) : "不限制",
      InpFreezeAlertSec > 0 ? StringFormat("%d秒", InpFreezeAlertSec) : "关",
      InpDeviationPoints, InpRetryBackoffSec, g_maxGroups));
   LogInfo(StringFormat("[授权] 有效 | 绑定账号 %I64d | 到期 %s(服务器时间)",
            g_authAcct, TimeToString(g_authExpiry, TIME_DATE | TIME_MINUTES)));
   LogInfo(StringFormat("[方向框v10.43] %s近%d根高低点框:上%.2f 中%.2f 下%.2f(就绪=%s) | 高度<%.0f以中点扩展,行情大不压缩 | 方向=实时bid在中点上方做多/下方做空 | 突破=每%.0f秒开一新组(顺突破方向,守%d组上限,回框停) | 零组老节奏=上单平仓后%d秒开首组 | 画框=%s | 续接:%s",
           StringSubstr(EnumToString(InpBoxTF), 7), InpBoxBars,
           g_boxTop, g_boxMid, g_boxBottom, g_boxReady ? "是" : "否(等数据)",
           InpBoxMinGap, InpBoxBreakSec, MathMin(g_maxGroups, 2), InpTimeOpenSec,
           InpBoxShow ? "开" : "关",
           g_timeCloseTime > 0 ? StringFormat("上单平仓=%s",
               TimeToString(g_timeCloseTime, TIME_DATE|TIME_MINUTES)) : "无记录(挂载即开首单)"));
   return(INIT_SUCCEEDED);
}

//=== 月度盈亏报表(OnDeinit输出) ====================================
// 遍历历史平仓deal(本EA magic),按YYYY.MM聚合,输出每月净盈亏+最大单笔亏损
void MonthReport()
{
   if(!HistorySelect(0, TimeCurrent())) return;
   int total = HistoryDealsTotal();
   if(total == 0) { LogInfo("月报:无历史成交"); return; }

   string curYM = "";
   double monthProfit = 0;
   double monthMaxLoss = 0;   // 当月最大单笔亏损(负数,0=无亏损单)
   bool   hasData = false;
   string report = "═══ 月度盈亏报表(每月净盈亏 + 最大单笔亏损) ═══";

   for(int i = 0; i < total; i++)
   {
      ulong tk = HistoryDealGetTicket(i);
      if(tk == 0) continue;
      long mg = HistoryDealGetInteger(tk, DEAL_MAGIC);
      if(mg < InpMagic || mg >= InpMagic + g_maxGroups) continue;   // 本EA的组
      long entry = HistoryDealGetInteger(tk, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY) continue;   // 只算平仓
      double prof = HistoryDealGetDouble(tk, DEAL_PROFIT)
                  + HistoryDealGetDouble(tk, DEAL_SWAP)
                  + HistoryDealGetDouble(tk, DEAL_COMMISSION);
      datetime tm = (datetime)HistoryDealGetInteger(tk, DEAL_TIME);
      string ym = StringSubstr(TimeToString(tm, TIME_DATE), 0, 7);  // YYYY.MM

      if(ym != curYM)
      {
         if(hasData)
            report += StringFormat("\n  %s: 净盈亏 %+.2f  最大单笔亏损 %.2f", curYM, monthProfit, monthMaxLoss);
         curYM = ym;
         monthProfit = prof;
         monthMaxLoss = (prof < 0) ? prof : 0;
         hasData = true;
      }
      else
      {
         monthProfit += prof;
         if(prof < monthMaxLoss) monthMaxLoss = prof;
      }
   }
   if(hasData)
      report += StringFormat("\n  %s: 净盈亏 %+.2f  最大单笔亏损 %.2f", curYM, monthProfit, monthMaxLoss);
   report += "\n══════════════════════════════════";
   LogInfo(report);
}

void OnDeinit(const int reason)
{
   if(g_diagHandle != INVALID_HANDLE)
   {
      FileClose(g_diagHandle);
      g_diagHandle = INVALID_HANDLE;
   }
   for(int g = 0; g < MAX_SLOTS; g++)
      if(groups[g].active) SaveState(g);
   SavePeriodState();
   // 回测结束:日志输出最后一个不完整周期统计
   if(g_isTester && g_periodEpoch > 0)
      LogInfo(StringFormat("回测结束(不完整周期):利润%+.2f 峰值盈利%.2f 最大亏损%.2f",
               AccountInfoDouble(ACCOUNT_BALANCE) - g_periodBase,
               g_periodMaxProfit, g_periodMaxLoss));
   ObjectsDeleteAll(0, OBJ_PREFIX);
   ChartRedraw();
   MonthReport();   // v1.29 月度盈亏报表
   LogInfo("卸载(状态已持久化)");
}

//=== 持仓缓存 ======================================================
// v5.00 双线带宽(CalcBandWidth/UpdateBands)与压力/支撑位
// (UpdatePressureLevels)整套删除;v8.40 组间冷却整套退场

void RefreshPositionCache()
{
   for(int g = 0; g < MAX_SLOTS; g++)
   {
      g_posCount[g] = 0; g_netProfit[g] = 0;
   }
   g_totalNet = 0;

   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic < InpMagic || magic >= InpMagic + g_maxGroups) continue;

      int g = (int)(magic - InpMagic);
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      g_posCount[g]++;
      g_netProfit[g] += profit;
      g_totalNet += profit;
   }
}

int CountGroupPositions(int g)
{
   int cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic + g) continue;
      cnt++;
   }
   return cnt;
}

int CountActiveGroups()
{
   int n = 0;
   for(int g = 0; g < g_maxGroups; g++)
      if(groups[g].active) n++;
   return n;
}

//=== 授权激活(v5.90,纯离线) ========================================
// 激活码 = Base64( AES256( 账号u64LE + 到期分钟u32LE + 魔数0x5B9E + 保留2B ) )
// key = SHA256(主密钥口令):源码仅存哈希结果32字节,无明文口令
// 生成器:Scripts\拾贝激活码生成器.mq5(同算法同key,作者专用)
uchar AUTH_KEY[32] =
{
   0x22,0xBD,0x3F,0x9D,0x88,0xE4,0x70,0xD0,
   0x9F,0xD7,0x6E,0xCF,0x3F,0xC9,0xA1,0xB2,
   0x93,0x88,0xDD,0x56,0xC6,0x05,0xAC,0x22,
   0x86,0xA9,0xD3,0x11,0x54,0xAD,0x69,0xD0
};
#define AUTH_MAGIC0   0x5B
#define AUTH_MAGIC1   0x9E
datetime g_authExpiry = 0;      // 授权到期时刻(服务器时间)
long     g_authAcct   = 0;      // 授权绑定账号
bool     g_authOK     = false;  // 当前授权状态(运行中到期即置false)
string   g_authReason = "";     // 授权失败原因(面板/日志显示)

string StripCode(string s)
{
   StringReplace(s, "-", "");
   StringReplace(s, " ", "");
   StringReplace(s, "\r", "");
   StringReplace(s, "\n", "");
   return s;
}

// 校验激活码:成功→填全局到期/账号并返回true;失败→填reason返回false
bool ValidateActivation(string codeIn, string &reason)
{
   string code = StripCode(codeIn);
   if(StringLen(code) == 0) { reason = "未填激活码"; return false; }

   // Base64解码(容忍缺padding自动补'=')→必须32字节密文
   int blen = StringLen(code);
   uchar b64[];
   ArrayResize(b64, blen);
   for(int i = 0; i < blen; i++)
      b64[i] = (uchar)StringGetCharacter(code, i);
   int pad = (4 - blen % 4) % 4;
   if(pad > 0)
   {
      ArrayResize(b64, blen + pad);
      for(int i = 0; i < pad; i++) b64[blen + i] = '=';
   }
   uchar dummy[], enc[];
   int encLen = CryptDecode(CRYPT_BASE64, b64, dummy, enc);
   if(encLen < 16 || encLen % 16 != 0)
   { reason = "激活码格式无效"; return false; }   // 密文16或32字节均兼容(自适应PKCS7有无)

   // AES-256解密→16字节明文
   uchar key[32];
   ArrayCopy(key, AUTH_KEY, 0, 0, 32);
   uchar plain[];
   if(CryptDecode(CRYPT_AES256, enc, key, plain) != 16)
   { reason = "激活码无效(密钥不符或码被篡改)"; return false; }
   if(plain[12] != AUTH_MAGIC0 || plain[13] != AUTH_MAGIC1)
   { reason = "激活码无效(密钥不符或码被篡改)"; return false; }

   // 拆装:账号+到期分钟
   ulong acct = 0, minutes = 0;
   for(int i = 0; i < 8; i++) acct    |= ((ulong)plain[i])     << (8 * i);
   for(int i = 0; i < 4; i++) minutes |= ((ulong)plain[8 + i]) << (8 * i);

   // 关卡1:账号绑定(一户一码)
   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   if(login != (long)acct)
   {
      reason = StringFormat("激活码绑定账号 %I64d 与当前登录账号 %I64d 不符", (long)acct, login);
      return false;
   }

   g_authAcct   = (long)acct;
   g_authExpiry = (datetime)(minutes * 60);

   // 关卡2:时间有效(经纪商服务器时间,改本机时钟无效)
   if(TimeCurrent() >= g_authExpiry)
   {
      reason = StringFormat("授权已过期(到期 %s)",
               TimeToString(g_authExpiry, TIME_DATE | TIME_MINUTES));
      return false;
   }
   return true;
}

// 授权无效/过期面板(红字,居中;对象带OBJ_PREFIX,OnDeinit统一清理)
void ShowAuthPanel()
{
   string name = OBJ_PREFIX + "AuthPanel";
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 200);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 60);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Black");
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
   long chartW = 0;
   ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chartW);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, (int)chartW / 2 - 230);
   ObjectSetString(0, name, OBJPROP_TEXT,
                   "授权无效/已过期:" + g_authReason);
}

//=== 周末限制 ======================================================
bool IsWeekendBlackout()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_week == 5 && dt.hour >= InpWeekendStartHour) return true;  // 周五晚
   if(dt.day_of_week == 6) return true;                                     // 周六
   if(dt.day_of_week == 0) return true;                                     // 周日
   if(dt.day_of_week == 1 && dt.hour < InpWeekendEndHour) return true;      // 周一早
   return false;
}

// v8.70 平掉本组全部持仓(按magic活体重扫;挂单竞态成交/兜底处置用)
void CloseAllGroupPositionsNow(int g)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong pt = PositionGetTicket(i);
      if(pt == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic + g) continue;
      if(!trade.PositionClose(pt))
         LogError(StringFormat("G%d 平仓失败#%I64u ret=%d(%s)",
                  g, pt, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
   }
}

// v8.70 重写:撤本组挂单。返回true=票号已清(撤掉/已不存在且已处置);
// false=撤单失败(票号保留,由每tick兜底/事件级持续重试,直到撤掉为止)。
// 旧版缺陷(用户2026-10-13实测"单子走掉后挂单进单"的根源之一):
// 撤单失败也照样清零票号→挂单留在服务器上成EA已忘掉的孤儿,成交后无人管。
// 挂单已不存在时查历史:已在撤销前成交(竞态)→立即平掉本组全部持仓。
bool CancelGroupPendings(int g, string reason)
{
   if(groups[g].pendingTicket == 0) return true;
   ulong tk = groups[g].pendingTicket;
   if(OrderSelect(tk))
   {
      if(!trade.OrderDelete(tk))
      {
         // 撤单失败:保留票号,下tick重试(绝不清零,防孤儿挂单)
         LogError(StringFormat("G%d 撤单失败#%I64u ret=%d,保留票号下tick重试",
                  g, tk, trade.ResultRetcode()));
         return false;
      }
      if(reason != "")
         LogInfo(StringFormat("G%d 撤销挂单#%I64u(%s)", g, tk, reason));
   }
   else
   {
      // 挂单已不存在:查订单历史——已在撤销前成交(竞态进单)则立即平掉
      bool filled = false;
      if(HistoryOrderSelect(tk))
      {
         ENUM_ORDER_STATE st = (ENUM_ORDER_STATE)HistoryOrderGetInteger(tk, ORDER_STATE);
         filled = (st == ORDER_STATE_FILLED || st == ORDER_STATE_PARTIAL);
      }
      if(filled)
      {
         LogError(StringFormat("G%d 挂单#%I64u在撤销前已成交(竞态),立即平掉本组全部持仓", g, tk));
         groups[g].pendingTicket = 0;
         groups[g].pendingDir    = 0;
         SaveState(g);
         CloseAllGroupPositionsNow(g);
         return true;
      }
   }
   groups[g].pendingTicket = 0;
   groups[g].pendingDir    = 0;
   SaveState(g);
   return true;
}

//=== 组管理 ========================================================
void ResetGroup(int g)
{
   ZeroMemory(groups[g]);
   DeleteState(g);
}

//=== 开组核心:v5.70 从TryOpenGroups抽出(v8.30 lane参数已删;v8.40 reopen参数退场) ==
// v8.80 增 isPair 标记(默认false=首组/正向组;TryOpenPair开反向组传true)
bool OpenHeadAt(int g, int dir, bool isPair=false)
{
   if(FailBackoff(g, StringFormat("G%d 开头仓", g))) return false;   // v10.00 A4
   if(!TradeGateOK(StringFormat("G%d 开头仓", g))) return false;      // v10.00 A4
   double lot = NormalizeLot(InpInitLots);
   if(!MarginOK(dir, lot, StringFormat("G%d 开头仓", g))) return false;   // v10.00 A4
   trade.SetExpertMagicNumber(InpMagic + g);
   bool ok = (dir > 0) ? trade.Buy(lot, _Symbol, 0, 0, 0, "GSB头仓")
                       : trade.Sell(lot, _Symbol, 0, 0, 0, "GSB头仓");
   uint ret = trade.ResultRetcode();
   if(!ok || (ret != TRADE_RETCODE_DONE && ret != TRADE_RETCODE_DONE_PARTIAL))
   {
      FailMark(g);   // v10.00 A4 失败退避
      LogError(StringFormat("头仓下单失败 ret=%d(%s)", ret, trade.ResultRetcodeDescription()));
      return false;
   }

   double price = trade.ResultPrice();
   if(price <= 0)
      price = (dir > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                        : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   groups[g].active        = true;
   groups[g].closing       = false;
   groups[g].phase         = 0;
   groups[g].p0            = price;
   groups[g].orderCount    = 1;
   groups[g].lastDir       = dir;
   groups[g].k1            = 1;
   groups[g].k2            = 1;
   groups[g].phase2Adds    = 0;
   groups[g].openTime      = TimeCurrent();
   groups[g].headDir       = dir;   // v6.00 头仓方向(双组寿命模式反向补组参考)
   groups[g].isPair        = isPair;   // v8.80 反向组标记
   groups[g].lastAddTime   = TimeCurrent();
   groups[g].pendingTicket = 0;
   groups[g].pendingDir    = 0;
   groups[g].trailActive   = false;
   groups[g].peakProfit    = 0;

   SaveState(g);

   LogInfo(StringFormat("开组G%d:头%s %.2f手 @%.2f P=%.2f | 活跃组%d/%d",
                        g, dir > 0 ? "多" : "空",
                        lot, price, price,
                        CountActiveGroups(), g_maxGroups));

   PlacePhase1Pending(g);
   return true;
}

//=== 反向组:救援联动补组(v6.00规则;v8.40随信号清理InpPairMode开关退场) ==
// 由时间模式TryOpenByTime在有活跃组时直接调用(零组首组由TryOpenByTime开):
//   最多持有2组;
//   存活组启动条件(唯一):救援单张数≥InpPairRescueCnt次(g_rescueCnt=
//   组内当前持有救援单张数,EA 内无单独平救援单的路径,故组存活期实际
//   只增不减;仅手动平单/强平会使计数回落,后果是少开组,不会提前开;
//   缓存重建时由持仓还原,下单失败不计)
//   参考组正在平仓(closing)不开(v11.4);
//   满足且有空槽 → 开其反方向组;
//   周末黑窗保留(OnTick调用处拦截)
// v10.40 返回bool:返回true=本tick已开出反向组(调用方跳过突破开组,防同tick双开)
bool TryOpenPair()
{
   int n = MathMin(g_maxGroups, 2);             // 新组只开在前两槽
   int free_g = -1, alive = -1, aliveCnt = 0;
   for(int g = 0; g < g_maxGroups; g++)         // v10.00 D1 口径统一:只扫活跃槽位(高槽位由OnInit越界清理保证无残留组,不再全槽扫)
   {
      if(!groups[g].active) continue;
      aliveCnt++;
      if(alive < 0) alive = g;                  // 反向参考取槽位最靠前的活跃组
   }
   if(aliveCnt >= 2) return false;              // 已有2组并存,不开新组
   if(alive < 0) return false;                  // 零组:首组由TryOpenByTime按秒数+框方向开,此处不处理
   // v11.4:参考组正在平仓→不开反向组(其救援单仍在,门槛会误判为"已进救援";
   // 且此时开出的新组已无对手组可对冲)
   if(groups[alive].closing) return false;

   for(int g = 0; g < n; g++)
      if(!groups[g].active) { free_g = g; break; }
   if(free_g < 0) return false;                 // 前两槽均被占

   // v8.30 反向组启动条件(唯一):存活组累计救援触发≥InpPairRescueCnt次
   // (原"寿命满秒数"分支随InpPairLifespanSec删除,二选一开关退场)
   if(g_rescueCnt[alive] < InpPairRescueCnt) return false;
   // v8.80 反向组间隔:上一张反向单平仓后未满InpPairCooldownSec秒不再开
   // (基准=反向组平仓时刻g_pairCloseTime,GV持久化重启续接;0=不间隔旧行为;
   //  反向组存活期间本就开不了新组,此参数实际约束的是平仓后的冷却)
   if(InpPairCooldownSec > 0 && g_pairCloseTime > 0
      && TimeCurrent() - g_pairCloseTime < InpPairCooldownSec)
   {
      static datetime cdLogLast = 0;
      // v10.43 剩余<10秒不打(间隔秒数很小时如1秒,此日志纯噪音)
      if(TimeCurrent() - cdLogLast >= 60 &&
         InpPairCooldownSec - (long)(TimeCurrent() - g_pairCloseTime) >= 10)
      {
         LogInfo(StringFormat("反向组间隔中:上张反向单平仓%s,满%d秒才可再开(剩%d秒)",
                 TimeToString(g_pairCloseTime, TIME_DATE|TIME_MINUTES),
                 InpPairCooldownSec,
                 (int)(InpPairCooldownSec - (long)(TimeCurrent() - g_pairCloseTime))));
         cdLogLast = TimeCurrent();
      }
      return false;
   }
   if(groups[alive].headDir == 0)
   {
      // 收编旧组头向未知:不盲开,只提示一次
      static int warnedSlot = -1;
      if(warnedSlot != alive)
      {
         LogInfo(StringFormat("G%d 收编组头仓方向未知,双组模式不盲开反向组(待该组走倒后恢复正常补组)", alive));
         warnedSlot = alive;
      }
      return false;
   }
   return OpenHeadAt(free_g, -groups[alive].headDir, true);
}

//=== v10.40 方向框(方案A高低点框,用户2026-10-27拍板) ==================
// 上轨=参考周期InpBoxTF近InpBoxBars根已收盘K线的最高价,
// 下轨=近N根最低价(不含当前形成中的K线,框每根K线收盘才移动一次,
// 突破判定稳定不闪烁);高度不足InpBoxMinGap(下限1,v10.41放开)以中点为中心
// 扩展,行情大不压缩用真实高低点;实时bid判定方向与突破:
//   方向: bid>中点=多 / bid<中点=空 / 正好=中点不开(极罕见);
//   突破: bid>上轨=上破 / bid<下轨=下破 / 框内=无突破。
// 数据未就绪 g_boxReady=false(不开单,下tick重试)。
void BoxUpdate()
{
   datetime now = TimeCurrent();
   if(g_boxReady && now == g_boxLastCalc) return;   // 每秒节流
   g_boxLastCalc = now;
   g_boxReady = false;
   double hi[], lo[];
   if(CopyHigh(_Symbol, InpBoxTF, 1, InpBoxBars, hi) < InpBoxBars) return;
   if(CopyLow(_Symbol, InpBoxTF, 1, InpBoxBars, lo) < InpBoxBars) return;
   int iHi = ArrayMaximum(hi);
   int iLo = ArrayMinimum(lo);
   if(iHi < 0 || iLo < 0) return;
   double top = hi[iHi], bot = lo[iLo];
   if(top <= 0 || bot <= 0 || top < bot) return;
   double mid = (top + bot) * 0.5;
   if(top - bot < InpBoxMinGap)   // 高度不足最小间距:以中点为中心对称扩展
   {
      top = mid + InpBoxMinGap * 0.5;
      bot = mid - InpBoxMinGap * 0.5;
   }
   g_boxTop    = NormalizeDouble(top, _Digits);
   g_boxBottom = NormalizeDouble(bot, _Digits);
   g_boxMid    = NormalizeDouble(mid, _Digits);
   g_boxReady  = true;
}

// 框内方向:1=bid在中点上方(开多) -1=下方(开空) 0=框未就绪/正中(不开)
int BoxDir()
{
   if(!g_boxReady) return 0;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid > g_boxMid) return 1;
   if(bid < g_boxMid) return -1;
   return 0;
}

// 突破状态:1=上破(bid>上轨) -1=下破(bid<下轨) 0=框内/未就绪
int BoxBreakState()
{
   if(!g_boxReady) return 0;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid > g_boxTop) return 1;
   if(bid < g_boxBottom) return -1;
   return 0;
}

//=== 时间驱动开组:方向框定方向 + 突破M秒硬节奏 + 双组并行(v10.40) =====
// 规则(用户2026-10-27拍板,方案A高低点框):
//   ·方向=方向框:实时bid在框中点上方=多/下方=空(框=参考周期近N根
//     最高/最低价,高度不足最小间距以中点扩展,行情大不压缩);
//   ·零组框内:上一单整组平仓后满InpTimeOpenSec秒→按中点方向开首组
//     (基准g_timeCloseTime,GV持久化重启续接);
//   ·突破模式:实时bid突破上/下轨→每InpBoxBreakSec秒开一新组
//     (顺突破方向,不等上一单走完,M秒硬节奏),回框自动停止恢复老节奏;
//     突破计时基准g_boxBreakLastOpen随GV持久化重启续接;
//     v11.3(用户2026-10-30拍板):突破开组仅限零组(即首组),
//     有存活组时不再按突破方向开第二组;
//   ·第二组=反向组:存活组救援触发≥InpPairRescueCnt次才解锁,
//     方向=-存活组头仓方向(不按突破方向);
//   ·最多2组并存,两组各自止盈平仓互不影响;
//   ·组内阶段一网格/阶段二/救援/止盈回撤逻辑完全不变;
//   ·周末黑窗拦截不变(OnTick调用处);框未就绪/无空槽下tick重试。
void TryOpenByTime()
{
   // v10.40 方向框数据(内部每秒节流;未就绪不开单,下tick重试)
   BoxUpdate();
   if(!g_boxReady)
   {
      static datetime nrLast = 0;
      if(TimeCurrent() - nrLast >= 600)
      {
         LogInfo("方向框数据未就绪(参考周期历史加载中),暂停开单,就绪后自动恢复");
         nrLast = TimeCurrent();
      }
      return;
   }

   // v10.00 A3:注释自检发现异常持仓时停止新开组(突破组/首组/反向组同闸;
   // v11.4:本闸门提到反向组之前,原来 TryOpenPair 先跑会绕过此闸门)
   if(g_commentBad)
   {
      static datetime cblLast = 0;
      if(TimeCurrent() - cblLast >= 600)
      {
         LogError("[注释自检] 存在无GSB前缀的本EA持仓,暂停新开组(等人工确认;已有组照常运行)");
         cblLast = TimeCurrent();
      }
      return;
   }

   // 反向组:救援联动(内部判槽位/救援次数/间隔;开出组则本tick到此为止)
   for(int g = 0; g < g_maxGroups; g++)
      if(groups[g].active)
      {
         if(TryOpenPair()) return;
         break;
      }

   // 空闲槽位(新组只开前两槽,守最多2组上限)
   int free_g = -1;
   for(int g = 0; g < MathMin(g_maxGroups, 2); g++)
      if(!groups[g].active) { free_g = g; break; }
   if(free_g < 0) return;

   // v11.3 突破开组仅限零组(用户2026-10-30拍板):
   //   有存活组时第二组一律由上面的反向组开出(救援解锁+方向=-存活组头仓方向),
   //   不允许按突破方向直接开第二组
   bool hasAlive = false;
   for(int g = 0; g < g_maxGroups; g++)
      if(groups[g].active) { hasAlive = true; break; }

   // v10.40 突破模式:实时价在框外 → 每InpBoxBreakSec秒开一新组(顺突破方向)
   // (不等上一单走完,M秒硬节奏;2组上限由free_g保证;回框自动走不到此分支)
   int breakDir = hasAlive ? 0 : BoxBreakState();
   if(breakDir != 0)
   {
      if(g_boxBreakLastOpen > 0 &&
         (double)(TimeCurrent() - g_boxBreakLastOpen) < (double)InpBoxBreakSec)
         return;
      if(OpenHeadAt(free_g, breakDir))
      {
         g_boxBreakLastOpen = TimeCurrent();
         SaveTimeModeState();
         LogInfo(StringFormat("[突破开组] 方向=%s(bid%.2f在框外 上%.2f/下%.2f),%.0f秒后可再开(回框自动停)",
                 breakDir > 0 ? "多" : "空", SymbolInfoDouble(_Symbol, SYMBOL_BID),
                 g_boxTop, g_boxBottom, InpBoxBreakSec));
      }
      return;
   }

   // 框内+零组:老节奏开首组(有活跃组时首组概念不存在,反向组已处理)
   for(int g = 0; g < g_maxGroups; g++)
      if(groups[g].active) return;

   // 平仓后计时未满不开(首单g_timeCloseTime=0立即开)
   if(g_timeCloseTime > 0 &&
      (double)(TimeCurrent() - g_timeCloseTime) < (double)InpTimeOpenSec)
      return;

   int dir = BoxDir();
   if(dir == 0) return;
   // v10.41 意图日志只在方向变化或框变化时打(闭市/盘整期间每tick重试
   // 不再刷屏;实测11秒931条把代理日志撑到百MB级;真正开单成败由
   // OpenHeadAt开组日志/失败日志负责,意图重复无信息量)
   static int    lgDir = 0;
   static double lgTop = 0, lgBot = 0;
   if(dir != lgDir || g_boxTop != lgTop || g_boxBottom != lgBot)
   {
      LogInfo(StringFormat("[框向开组] bid%.2f在框中点%.2f%s,开%s(框 上%.2f/下%.2f)",
              SymbolInfoDouble(_Symbol, SYMBOL_BID), g_boxMid,
              dir > 0 ? "上方" : "下方", dir > 0 ? "多" : "空",
              g_boxTop, g_boxBottom));
      lgDir = dir;
      lgTop = g_boxTop;
      lgBot = g_boxBottom;
   }
   OpenHeadAt(free_g, dir);
}

//=== 阶段一:固定双档链式网格 ======================================
double Phase1Lot(int g) { return NormalizeLot(InpInitLots + groups[g].orderCount * InpLotStepX); }

void PlacePhase1Pending(int g)
{
   if(FailBackoff(g, StringFormat("G%d 挂网格单", g))) return;   // v10.00 A4
   if(!TradeGateOK(StringFormat("G%d 挂网格单", g))) return;      // v10.00 A4
   // v3.09:周末截止只停开新组,已开组的链式网格跨周末继续挂单
   // (开新组已在OnTick处被g_blackout闸门挡住,此处不再拦截)

   int nextDir = -groups[g].lastDir;                       // 链式:与上一单反向
   double lot = Phase1Lot(g);
   // v8.30 循环间距扩大(InpGridCycleWiden)已删:档位恒=P0±A固定双档
   // v10.40 反向组独立网格间距:反向组用InpPairGridA,主组用InpGridA
   double gap = groups[g].isPair ? InpPairGridA : InpGridA;
   double level = (nextDir > 0) ? groups[g].p0 + gap        // 上档 P+gap 做多
                                : groups[g].p0 - gap;       // 下档 P−gap 做空
   level = NormalizeDouble(level, _Digits);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double stopsDist = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   trade.SetExpertMagicNumber(InpMagic + g);

   // 价格已越过档位(跳空等)→ 视为档位触发,市价立即成交
   if(nextDir > 0 && level <= ask + stopsDist)
   {
      LogInfo(StringFormat("G%d 价格已越过上档%.2f,市价多单替代挂单", g, level));
      DoGridFill(g, 1, lot);
      return;
   }
   if(nextDir < 0 && level >= bid - stopsDist)
   {
      LogInfo(StringFormat("G%d 价格已越过下档%.2f,市价空单替代挂单", g, level));
      DoGridFill(g, -1, lot);
      return;
   }

   bool ok = (nextDir > 0)
             ? trade.BuyStop(lot, level, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "GSB网格")
             : trade.SellStop(lot, level, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "GSB网格");
   if(ok)
   {
      groups[g].pendingTicket = trade.ResultOrder();
      groups[g].pendingDir = nextDir;
      SaveState(g);
   }
   else
   {
      FailMark(g);   // v10.00 A4
      LogError(StringFormat("G%d 挂单失败(%s @%.2f) ret=%d(%s)",
               g, nextDir > 0 ? "BuyStop" : "SellStop", level,
               trade.ResultRetcode(), trade.ResultRetcodeDescription()));
   }
}

void DoGridFill(int g, int dir, double lot)
{
   if(FailBackoff(g, StringFormat("G%d 网格市价单", g))) return;   // v10.00 A4
   if(!TradeGateOK(StringFormat("G%d 网格市价单", g))) return;      // v10.00 A4
   if(!MarginOK(dir, lot, StringFormat("G%d 网格市价单", g))) return;   // v10.00 A4
   trade.SetExpertMagicNumber(InpMagic + g);
   bool ok = (dir > 0) ? trade.Buy(lot, _Symbol, 0, 0, 0, "GSB网格")
                       : trade.Sell(lot, _Symbol, 0, 0, 0, "GSB网格");
   uint ret = trade.ResultRetcode();
   if(!ok || (ret != TRADE_RETCODE_DONE && ret != TRADE_RETCODE_DONE_PARTIAL))
   {
      FailMark(g);   // v10.00 A4
      LogError(StringFormat("G%d 网格市价单失败 ret=%d(%s)", g, ret, trade.ResultRetcodeDescription()));
      return;
   }
   OnGridFilled(g, dir);
}

void OnGridFilled(int g, int dir)
{
   groups[g].orderCount++;
   groups[g].lastDir = dir;
   groups[g].lastAddTime = TimeCurrent();
   int gridFills = groups[g].orderCount - 1;

   LogInfo(StringFormat("G%d 网格成交:%s 第%d单(循环%d/%d)",
                        g, dir > 0 ? "多" : "空", groups[g].orderCount,
                        gridFills / 2, InpCyclesW));

   if(gridFills >= 2 * InpCyclesW)
   {
      groups[g].phase = 1;
      // v10.40 触发线日志按组对应A/B取参(反向组用InpPairGridA/InpPairStepB)
      double ga = groups[g].isPair ? InpPairGridA : InpGridA;
      double sb = groups[g].isPair ? InpPairStepB : InpStepB;
      LogInfo(StringFormat("G%d 进入阶段二:P=%.2f 上触发=%.2f 下触发=%.2f",
               g, groups[g].p0,
               groups[g].p0 + ga + groups[g].k1 * sb,
               groups[g].p0 - ga - groups[g].k2 * sb));
   }
   SaveState(g);

   if(groups[g].phase == 0)
      PlacePhase1Pending(g);   // 链式:立即挂下一张
}

void CheckPendingFilled(int g)
{
   if(groups[g].pendingTicket == 0) return;
   if(OrderSelect(groups[g].pendingTicket)) return;   // 挂单还在

   ulong oldTicket = groups[g].pendingTicket;
   int oldDir = groups[g].pendingDir;
   groups[g].pendingTicket = 0;
   groups[g].pendingDir = 0;

   // v3.24 修复重复下单:挂单消失≠撤单。
   // 旧逻辑只比持仓缓存(g_posCount在tick开头扫描,挂单成交瞬间新仓位
   // 尚未出现在持仓表→误判"外部撤单"→同档位同手数重挂→同手数重复下单)。
   // 新逻辑:先查订单历史真实状态——已成交(全成/部分成)按成交计数;
   // 历史查不到时当场重扫持仓兜底(持仓数超过EA计数即有成交);
   // 确认无成交才按外部撤单处理(重挂由ProcessPhase1完成)。
   bool filled = false;
   if(HistoryOrderSelect(oldTicket))
   {
      ENUM_ORDER_STATE st = (ENUM_ORDER_STATE)HistoryOrderGetInteger(oldTicket, ORDER_STATE);
      filled = (st == ORDER_STATE_FILLED || st == ORDER_STATE_PARTIAL);
   }
   if(!filled)
   {
      // 兜底(历史查询异常时):当场重扫,按"头仓+网格"链上张数比对——
      // 只统计GSB头仓/GSB网格注释的持仓,排除救援单/阶段二单干扰计数
      int chain = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong tk = PositionGetTicket(i);
         if(tk == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagic + g) continue;
         string cm = PositionGetString(POSITION_COMMENT);
         if(StringFind(cm, "GSB头仓") == 0 || StringFind(cm, "GSB网格") == 0) chain++;
      }
      if(chain > groups[g].orderCount) filled = true;
   }
   if(filled)
      OnGridFilled(g, oldDir);
   else
   {
      LogError(StringFormat("G%d 挂单#%I64u消失且确认未成交(持仓%d/计数%d),按外部撤单处理",
               g, oldTicket, g_posCount[g], groups[g].orderCount));
      SaveState(g);
   }
}

void ProcessPhase1(int g)
{
   if(groups[g].phase != 0) return;

   // 安全兜底:单数已达标但阶段未切换
   if(groups[g].orderCount - 1 >= 2 * InpCyclesW)
   {
      groups[g].phase = 1;
      CancelGroupPendings(g, "切入阶段二");
      SaveState(g);
      return;
   }

   // v3.13 阶段二控制线已删除,"提前切入阶段二"随之取消——
   // 阶段二入口只有一条:网格成交满2W张

   // 正常/恢复:无挂单则挂(v3.09 链子跨周末继续运行)
   if(groups[g].pendingTicket == 0)
      PlacePhase1Pending(g);
}

//=== 阶段二:逆势补仓(市价即时单) ================================
// 触发线锚定P0外扩:上触发=P0+A+K1×B 补空,下触发=P0−A−K2×B 补多
// v3.13 控制线门禁已删除;v5.00 单侧上限InpMaxP2Adds删除——触发即补,只受冷却T约束
// v8.90 单向化(写死,用户2026-10-22拍板):只顺头仓方向——头仓空仅上触发补空,
// 头仓多仅下触发补多,头向未知(收编组)禁止;反侧触发线跳过(不补/不重定位)
void ProcessPhase2(int g)
{
   if(groups[g].phase != 1) return;
   // v8.60 写死硬闸门:阶段二每组只补一次(用户2026-10-13要求,无条件)
   // 本组只要补过一次(phase2Adds>0)就永不再补——不受触发线/冷却T/
   // 救援/重启影响;计数随GV p2adds持久化,重启由LoadState或收编反推
   // (AdoptOrphanPositions按持仓数恢复)恢复,防重启后重复补仓
   if(groups[g].phase2Adds > 0) return;
   // v8.90 方向闸门(用户2026-10-22拍板,写死):阶段二只顺头仓方向——
   // 头仓空(-1)仅涨到上触发线补空;头仓多(+1)仅跌到下触发线补多;
   // 头向未知(0,收编组)一律禁止补仓。赚钱方向(顺头仓)不补。
   int hd = groups[g].headDir;
   if(hd == 0) return;
   // v10.00 A4 前置校验+失败退避(阶段二本就只补一次,失败退避防极端拒单刷屏)
   if(FailBackoff(g, StringFormat("G%d 阶段二补仓", g))) return;
   if(!TradeGateOK(StringFormat("G%d 阶段二补仓", g))) return;
   // v3.09:周末截止只停开新组,阶段二逆势补仓跨周末照常执行

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   // v10.40 反向组独立参数:触发线锚定P0±组对应网格间距,外扩按组对应步长
   double gridA = groups[g].isPair ? InpPairGridA : InpGridA;
   double stepB = groups[g].isPair ? InpPairStepB : InpStepB;
   double upperTrig = NormalizeDouble(groups[g].p0 + gridA + groups[g].k1 * stepB, _Digits);
   double lowerTrig = NormalizeDouble(groups[g].p0 - gridA - groups[g].k2 * stepB, _Digits);

   //--- 触发线重定位(防补仓风暴) -----------------------------------
   // 跳空/冷却/重启后,现价可能已深过触发线(如4200开组跌到4100,下触发仍在4196)。
   // 若不重定位,冷却一到就会按冷却间隔连发补仓(手数递增),直接打爆账户。
   // 此处将触发线推进到现价外一个B:
   //   平滑下跌 → 仍保持"每跌B补一次"的原始节奏;
   //   冷却期间/跳空越过的档位 → 直接跳过,不追补。只进不退,不影响正常震荡补仓。
   // v3.17:比较改为含等号——深过触发线满1个B(含正好1个B)即重定位。
   //   修复:冷却期间价格正好落在下一档位边界时,冷却到期先补1仓、
   //   再下一个冷却无需新低又白补1仓(=连续补两个位置)的追补问题;
   //   现在冷却期间穿越的档位一律跳过,冷却到期后从现价外1个B起重新起算。
   if(stepB > 0)
   {
      if(hd == 1 && ask <= lowerTrig - stepB)   // v8.90 下侧重定位仅多头头仓
      {
         int k2Need = (int)MathCeil((groups[g].p0 - gridA - ask) / stepB) + 1;
         if(k2Need > groups[g].k2)
         {
            LogInfo(StringFormat("G%d 下触发线重定位:%.2f→%.2f(现价%.2f已深过触发线,K2 %d→%d)",
                     g, lowerTrig, groups[g].p0 - gridA - k2Need * stepB, ask,
                     groups[g].k2, k2Need));
            groups[g].k2 = k2Need;
            SaveState(g);
         }
      }
      if(hd == -1 && bid >= upperTrig + stepB)   // v8.90 上侧重定位仅空头头仓
      {
         int k1Need = (int)MathCeil((bid - groups[g].p0 - gridA) / stepB) + 1;
         if(k1Need > groups[g].k1)
         {
            LogInfo(StringFormat("G%d 上触发线重定位:%.2f→%.2f(现价%.2f已深过触发线,K1 %d→%d)",
                     g, upperTrig, groups[g].p0 + gridA + k1Need * stepB, bid,
                     groups[g].k1, k1Need));
            groups[g].k1 = k1Need;
            SaveState(g);
         }
      }
      upperTrig = NormalizeDouble(groups[g].p0 + gridA + groups[g].k1 * stepB, _Digits);
      lowerTrig = NormalizeDouble(groups[g].p0 - gridA - groups[g].k2 * stepB, _Digits);
   }

   if((double)(TimeCurrent() - groups[g].lastAddTime) < InpCooldownT) return;  // 冷却 T(v3.16 固定值)

   // 手数:init + 2W×X + m×Y(m=本次为第几次补仓)
   double lot = NormalizeLot(InpInitLots + 2 * InpCyclesW * InpLotStepX
                             + (groups[g].phase2Adds + 1) * InpLotStepY);
   int p2dir = (hd == -1) ? -1 : 1;
   if(!MarginOK(p2dir, lot, StringFormat("G%d 阶段二补仓", g))) { FailMark(g); return; }   // v10.00 A4
   trade.SetExpertMagicNumber(InpMagic + g);

   // 涨到上触发 → 补空(v8.90 仅空头头仓;多头头仓跳过,赚钱方向不补)
   if(hd == -1 && bid >= upperTrig)
   {
      if(trade.Sell(lot, _Symbol, 0, 0, 0, "GSB补空"))
      {
         groups[g].k1++;
         groups[g].phase2Adds++;
         groups[g].orderCount++;
         groups[g].lastDir = -1;
         groups[g].lastAddTime = TimeCurrent();
         SaveState(g);
         LogInfo(StringFormat("G%d 阶段二补空:%.2f手 触发%.2f K1=%d 净%.2f",
                  g, lot, upperTrig, groups[g].k1, g_netProfit[g]));
      }
      else
      {
         FailMark(g);   // v10.00 A4
         LogError(StringFormat("G%d 补空失败 ret=%d(%s)", g, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
      }
   }
   // 跌到下触发 → 补多(v8.90 仅多头头仓;空头头仓跳过,赚钱方向不补)
   else if(hd == 1 && ask <= lowerTrig)
   {
      if(trade.Buy(lot, _Symbol, 0, 0, 0, "GSB补多"))
      {
         groups[g].k2++;
         groups[g].phase2Adds++;
         groups[g].orderCount++;
         groups[g].lastDir = 1;
         groups[g].lastAddTime = TimeCurrent();
         SaveState(g);
         LogInfo(StringFormat("G%d 阶段二补多:%.2f手 触发%.2f K2=%d 净%.2f",
                  g, lot, lowerTrig, groups[g].k2, g_netProfit[g]));
      }
      else
      {
         FailMark(g);   // v10.00 A4
         LogError(StringFormat("G%d 补多失败 ret=%d(%s)", g, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
      }
   }
}

//=== 套牢救援:逐张单独立检测,与阶段二相同的补仓机制 ================
// 现价逆势偏离某张单开仓价达 InpRescueDist 美元 → 为这张单单独启动一个救援
// 通道(锚定 开仓价±距离,独立计数),不改变原组任何逻辑/状态。
// v5.00 出牌四条规则(用户2026-09-22指定,严格执行):
//   规则1+2(时间闸门):第2张起,距上一张救援成交须≥InpRescueCooldown秒
//     (默认900秒)——即使救援点数已到/深过触发价,时间没到一律不开;
//     第一张救援单不受900秒限制(用户确认),只看价格触发;
//   规则3(禁整轮同出):每tick每通道最多出1张,绝不一次性把快速行情
//     覆盖的补仓点位全部补入;
//   规则4(逐张推算):每一张都按价格触发,下一张触发价=通道内最深一张
//     开仓价∓固定间距(间距=触发距离+固定加成,第3张起再逐张+叠加值),
//     基于上一张推算,到点才可出;快速下跌瞬间穿过多个点位时,由时间
//     闸门保证一张一张按冷却间隔出,不追补已越过的点位;
// 间距:第2张起每张与上一张救援单的间距固定 = InpRescueDist + InpRescueDistStep
//   (InpRescueDistStep=0 时退回固定B间距,与阶段二共用B);
//   第3张起可按 InpRescueGapStep 逐张叠加(0=不叠加);
// 轮次:张数基数固定1(参数已删),第k轮张数=1+(k-1)×InpRescueCntStep
//   (参数=1时即第1轮1张/第2轮2张/第3轮3张…逐轮递增);
// 手数:v10.42序列制,第m+1张救援单取InpRescueLotSeq第m+1个值(从左到右),
//   超出序列长度沿用最后一个值;纯序列即最终手数,主/反组共用
// 设计要点:
//   · 无状态:通道用订单注释 "GSB救<锚定价>L/S" 识别,已补次数/最深价全部
//     从当前持仓实时推导,重启/断线后自动恢复,无需额外持久化;
//   · 防风暴:下一档触发价 = 本通道最深一张开仓价再让固定间距(跳空越过的档位不追补);
//   · 救援单挂本组Magic:随本组止盈一起平仓,盈亏计入组净利;
//   · 救援单自身不再派生新通道(防通道无限增殖);
//   · v8.90 方向闸门(写死,用户2026-10-22拍板):只为方向=头仓方向的套牢单
//     建通道——空仓组只救空单,多仓组只救多单;反方向网格套牢单不救援
//     (等整组止盈/回撤平仓);头向未知(0,收编组)一律禁止救援;
//   · 同方向同价位的套牢单共享同一通道;
//   · 周末限制内不加仓;组平仓中(closing)不救援。
// v3.0 性能优化:一次O(P)扫描把全部持仓信息缓存到内存数组,外层遍历与
// 通道统计全部改为纯内存读取——原版外层×内层重复PositionGet调用为O(P²),
// 持仓多时每tick上万次API调用;现在API调用降为O(P)次,交易逻辑零改动。
struct RescuePosCache
{
   int      g;         // 组号
   int      dir;       // 1多 -1空
   double   open;      // 开仓价
   datetime opentime;  // 开仓时间(救援独立冷却基准)
   bool     isRescue;  // 是否救援单(注释GSB救开头)
   string   comment;   // 持仓注释(通道key匹配用)
   double   vol;       // 手数(v10.10 救援总手数上限统计用)
};
void ProcessRescue()
{
   // v10.40 主组/反向组救援距离独立:两者都<=0才整体跳过(循环内再按组各自判0)
   if(InpRescueDist <= 0 && InpPairRescueDist <= 0) return;   // 触发距离=0才关闭(v3.03动态基准已删)
   // v3.09:周末截止只停开新组,救援通道跨周末照常工作(与周一一致)

   // v3.19 防重发护栏:持仓缓存最多滞后1秒,刚出过的牌不因缓存未刷新而连发
   // (重启后由通道内救援单开仓时间自然恢复,无需持久化)
   static string   lastDealKey  = "";
   static datetime lastDealTime = 0;

   // v5.20 全局间距闸门状态:全EA同方向救援单的 最近一张(开仓价/时间)+张数
   // (跨通道跨组聚合;重启后由持仓缓存重建自然还原,无需持久化)
   // v10.10 增 globLots:同方向救援单累计总手数(InpRescueLotsCap 上限统计用)
   static double   globLastPrice[2] = {0, 0};   // [0]=多方向 [1]=空方向
   static datetime globLastTime[2]  = {0, 0};
   static int      globCnt[2]       = {0, 0};
   static double   globLots[2]      = {0, 0};   // v10.10 同方向救援总手数

   // v6.10 拦截诊断:状态变化式日志(同通道首次被拦打1条,放行后复位,防每tick刷屏)
   // v10.43 时间节流(LOG_GAP_SEC 600秒重打)已删:扛单冷却期每通道只留首条
   static bool    blkCdLogged  = false;   static string   blkCdKey  = "";   // 冷却拦截
   static bool    blkSecLogged = false;   static string   blkSecKey = "";   // 出牌间隔拦截
   static bool    blkGgLogged  = false;   static string   blkGgKey  = "";   // 全局间距拦截
   static bool    blkCapLogged = false;   static string   blkCapKey = "";   // v10.10 总手数上限拦截

   // v3.0 一次O(P)扫描缓存全部持仓(仅本EA:品种+magic范围过滤)
   // v3.13 静态数组复用:只在持仓数增长时扩容,消除每tick内存重分配
   // v3.14 事务驱动:仅当发生交易事务(开仓/平仓/挂单变动)或每秒兜底时重建
   // 缓存;持仓不变期间触发判定走纯内存缓存,消除每tick的持仓API扫描
   static RescuePosCache cache[];
   static int      cacheCap  = 0;
   static int      nCache    = 0;
   static datetime lastBuild = 0;
   static bool     built     = false;
   datetime now = TimeCurrent();
   if(!built || g_rescueDirty || now != lastBuild)
   {
      int totalRaw = PositionsTotal();
      if(totalRaw > cacheCap)
      {
         ArrayResize(cache, totalRaw + 64);
         cacheCap = totalRaw + 64;
      }
      int n = 0;
      ArrayInitialize(g_rescueCnt, 0);   // v3.22 重建时同步统计各组救援单张数(止盈切换用)
      // v5.20 全局间距闸门:重建时从持仓还原全EA同方向救援单状态
      globCnt[0] = 0;       globCnt[1] = 0;
      globLastTime[0] = 0;  globLastTime[1] = 0;
      globLastPrice[0] = 0; globLastPrice[1] = 0;
      globLots[0] = 0;      globLots[1] = 0;   // v10.10
      for(int i = 0; i < totalRaw; i++)
      {
         if(PositionGetTicket(i) == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         long mgk = PositionGetInteger(POSITION_MAGIC);
         if(mgk < InpMagic || mgk >= InpMagic + g_maxGroups) continue;
         cache[n].g        = (int)(mgk - InpMagic);
         cache[n].dir      = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
         cache[n].open     = PositionGetDouble(POSITION_PRICE_OPEN);
         cache[n].opentime = (datetime)PositionGetInteger(POSITION_TIME);
         cache[n].comment  = PositionGetString(POSITION_COMMENT);
         cache[n].isRescue = (StringFind(cache[n].comment, "GSB救") == 0);
         cache[n].vol      = PositionGetDouble(POSITION_VOLUME);   // v10.10
         if(cache[n].isRescue)
         {
            g_rescueCnt[cache[n].g]++;
            int dIdx = (cache[n].dir > 0) ? 0 : 1;   // v5.20 全局还原:同方向最近一张+张数
            globCnt[dIdx]++;
            globLots[dIdx] += cache[n].vol;          // v10.10 同方向救援总手数还原
            if(cache[n].opentime >= globLastTime[dIdx])
            {
               globLastTime[dIdx]  = cache[n].opentime;
               globLastPrice[dIdx] = cache[n].open;
            }
         }
         n++;
      }
      nCache = n;
      built = true;
      lastBuild = now;
      g_rescueDirty = false;
   }
   int n = nCache;

   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = 0; i < n; i++)
   {
      int g = cache[i].g;
      long mg = InpMagic + g;
      if(!groups[g].active || groups[g].closing) continue;
      if(cache[i].isRescue) continue;   // 救援单不派生新通道
      // v8.90 方向闸门(用户2026-10-22拍板,写死):救援只顺头仓方向——
      // 只为方向=头仓方向的套牢单建通道(空仓组只救空单,多仓组只救多单);
      // 反方向网格套牢单跳过不救援(等整组止盈/回撤平仓);
      // 头向未知(0,收编组)时任何方向都不等于0,一律禁止救援
      if(cache[i].dir != groups[g].headDir) continue;

      // v10.40 反向组独立救援距离:反向组用InpPairRescueDist,主组用InpRescueDist
      // (0=该类组套牢单不救援,等整组止盈/回撤平仓)
      double dist = groups[g].isPair ? InpPairRescueDist : InpRescueDist;
      if(dist <= 0) continue;

      // v10.40 救援间距回退值(DistStep=0时共用阶段二B)同样按组取主/反参数
      double grpB  = groups[g].isPair ? InpPairStepB : InpStepB;
      double stepB = (grpB > 0) ? grpB : 1.0;

      int    dir = cache[i].dir;
      double P   = cache[i].open;
      double anchor = NormalizeDouble(dir > 0 ? P - dist : P + dist, _Digits);

      // 现价未逆势达到锚定价 → 通道未激活
      if(dir > 0 && bid > anchor) { blkCdLogged = false; blkSecLogged = false; blkGgLogged = false; blkCapLogged = false; continue; }   // v6.10 价格离开,复位拦截诊断标志
      if(dir < 0 && bid < anchor) { blkCdLogged = false; blkSecLogged = false; blkGgLogged = false; blkCapLogged = false; continue; }   // v6.10 同上

      string key = StringFormat("GSB救%.2f%s", anchor, dir > 0 ? "L" : "S");

      // v5.00 防重发护栏:同一通道1秒内(持仓缓存可能未刷新)不重复出牌
      if(key == lastDealKey &&
         (double)(TimeCurrent() - lastDealTime) < 1.0) continue;

      // 统计该通道已有救援单:次数m / 最深开仓价 / 最近一次救援成交时间
      // v3.0:纯内存遍历缓存,不再重复PositionGet(原为每张候选单O(P)次API调用)
      // v3.03:冷却机制已删除,lastT不再需要
      // v3.16 新增通道冷却:从通道内救援单的开仓时间还原最近一次救援时间
      int      m = 0;
      double   deepest = 0;
      datetime lastRescue = 0;
      for(int j = 0; j < n; j++)
      {
         if(cache[j].g != g) continue;
         if(!cache[j].isRescue) continue;
         if(StringFind(cache[j].comment, key) != 0) continue;
         double op = cache[j].open;
         if(m == 0) deepest = op;
         else       deepest = (dir > 0) ? MathMin(deepest, op) : MathMax(deepest, op);
         if(cache[j].opentime > lastRescue) lastRescue = cache[j].opentime;
         m++;
      }

      // 轮次位置还原:由通道现有张数m逐轮累加,判断本单是"新一轮首张"
      // 还是"当前轮续牌"——用于轮次日志与轮内手数一致
      // v5.00:基数固定1(参数已删),第k轮张数=1+(k-1)×InpRescueCntStep,
      // 参数=1时即第1轮1张/第2轮2张/第3轮3张…逐轮递增
      int cntBase = 1;
      int cntStep = (InpRescueCntStep > 0) ? InpRescueCntStep : 0;
      int doneRounds = 0, acc = 0;
      while(acc < m && doneRounds < 10000)
      {
         doneRounds++;
         acc += cntBase + (doneRounds - 1) * cntStep;
      }
      bool newRound   = (m == acc);   // m在轮次边界=新一轮首张;否则为当前轮续牌
      int  roundTotal = newRound ? (cntBase + doneRounds * cntStep)          // 新一轮总张数
                                 : (cntBase + (doneRounds - 1) * cntStep);   // 当前轮总张数
      if(roundTotal < 1) continue;
      int roundNo = newRound ? (doneRounds + 1) : doneRounds;    // 当前轮次(1起)
      int cardNo  = newRound ? 1 : (m - (acc - roundTotal) + 1); // 本轮第几张(1起)

      //--- 出牌节奏(v5.00 四条规则) -----------------------------------
      // 规则1+2(时间闸门):第2张起,距上一张救援成交须≥救援冷却
      //   InpRescueCooldown(默认900秒)——即使点数已到/深过触发价,
      //   时间没到一律不开;第一张救援单(m=0)不受900秒限制(用户确认)。
      //   另看出牌间隔 InpRescueCardSec(>0时)。
      // 规则3(禁整轮同出):每tick每通道最多出1张(见下方下单)。
      // 规则4(逐张推算):fire一律按价格判定,不再有"续牌只看间隔"的
      //   无条件出牌(v3.19旧行为删除)。
      double nowD = (double)TimeCurrent();
      if(m > 0)
      {
         if(InpRescueCooldown > 0 &&
            nowD - (double)lastRescue < InpRescueCooldown)
         {
            // v6.10 拦截诊断:同通道首次被拦打1条(含还差秒数),放行/价格离开后复位
            // v8.50 同类日志600秒节流:反复进出触发区时不再重复刷屏
            if(!blkCdLogged || blkCdKey != key)   // v10.43 只状态变化打1条(600秒重打已删,扛单冷却期不再重复)
            {
               LogInfo(StringFormat("G%d 救援被拦(冷却):第%d轮第%d/%d张位置已到,距上次救援%.0f秒<冷却%.0f秒,还差%.0f秒",
                       g, roundNo, cardNo, roundTotal, nowD - (double)lastRescue,
                       InpRescueCooldown, InpRescueCooldown - (nowD - (double)lastRescue)));
               blkCdLogged = true;
               blkCdKey    = key;
            }
            continue;   // 救援冷却未到,点数到了也不开
         }
         blkCdLogged = false;   // v6.10 冷却放行,复位拦截标志
         if(InpRescueCardSec > 0 &&
            nowD - (double)lastRescue < InpRescueCardSec)
         {
            // v6.10 拦截诊断:同通道首次被拦打1条(含还差秒数),放行/价格离开后复位
            // v8.50 同类日志600秒节流
            if(!blkSecLogged || blkSecKey != key)   // v10.43 只状态变化打1条
            {
               LogInfo(StringFormat("G%d 救援被拦(出牌间隔):第%d轮第%d/%d张位置已到,距上次救援%.0f秒<间隔%.0f秒,还差%.0f秒",
                       g, roundNo, cardNo, roundTotal, nowD - (double)lastRescue,
                       InpRescueCardSec, InpRescueCardSec - (nowD - (double)lastRescue)));
               blkSecLogged = true;
               blkSecKey    = key;
            }
            continue;    // 出牌间隔未到,暂停出牌
         }
         blkSecLogged = false;   // v6.10 间隔放行,复位拦截标志
      }

      // v3.03 固定间距(用户指定):第2张起每张与上一张救援单的间距固定为
      // 触发距离+间距加成 = dist + InpRescueDistStep(v10.40 dist按组取主/反参数);
      // InpRescueDistStep=0 时退回固定B间距(与阶段二共用B)
      // v3.10 间距逐次叠加:第3张起每多补一张,间距再+InpRescueGapStep(0=不叠加)
      double gap = (InpRescueDistStep > 0) ? dist + InpRescueDistStep
                                           : stepB;
      if(m > 1 && InpRescueGapStep > 0)
         gap += (m - 1) * InpRescueGapStep;

      // 触发价:首单=锚定价;后续=最深一张再让固定间距(只顺势外移,防跳空追补)
      double trig = (m == 0) ? anchor : ((dir > 0) ? deepest - gap : deepest + gap);
      // v5.00 规则4:每一张都按价格触发——首张=锚定价,后续=最深一张∓间距
      // (基于上一张推算;快速行情瞬间穿过多个点位时,由上方时间闸门保证
      //  一张一张按冷却间隔出,不允许一次性全部补入)
      bool fire = (dir > 0) ? (ask <= trig) : (bid >= trig);
      if(!fire)
      {
         blkCdLogged = false;   // v6.10 价格离开触发位,本轮拦截事件结束,复位诊断标志
         blkSecLogged = false;
         blkGgLogged = false;
         blkCapLogged = false;
         continue;
      }

      // v5.20 全局间距闸门(用户2026-09-23拍板):开=同方向任意救援单(含各通道
      // 第一张)触发价须距全EA最近一张同方向救援单≥触发距离+固定加成
      // (同方向张数>1再逐张+叠加,与通道内公式同形),跨通道跨组生效;
      // 反向通道互不约束。关=旧行为(间距只在通道内生效)。
      // 修复场景:相邻通道锚定仅差1.00,价格扫过时第一张秒级连发。
      string ggapLog = "";
      if(InpRescueGlobalGap)
      {
         int dIdx = (dir > 0) ? 0 : 1;
         if(globCnt[dIdx] > 0)
         {
            // v10.40 全局间距公式的触发距离按当前出牌组取主/反参数(默认值相同时行为不变)
            double ggap = (InpRescueDistStep > 0) ? dist + InpRescueDistStep
                                                  : stepB;
            if(globCnt[dIdx] > 1 && InpRescueGapStep > 0)
               ggap += (globCnt[dIdx] - 1) * InpRescueGapStep;
            bool okGap = (dir > 0) ? (trig <= globLastPrice[dIdx] - ggap)
                                   : (trig >= globLastPrice[dIdx] + ggap);
            if(!okGap)
            {
               // v6.10 拦截诊断:同通道首次被拦打1条(含差多少间距),放行后复位
               // v8.50 同类日志600秒节流
               if(!blkGgLogged || blkGgKey != key)   // v10.43 只状态变化打1条
               {
                  LogInfo(StringFormat("G%d 救援被拦(全局间距):第%d轮第%d/%d张 触发%.2f 距全EA上张同向%.2f<要求%.2f",
                          g, roundNo, cardNo, roundTotal, trig,
                          MathAbs(trig - globLastPrice[dIdx]), ggap));
                  blkGgLogged = true;
                  blkGgKey    = key;
               }
               continue;   // 全局间距未到:本通道条件再满足也不出
            }
            blkGgLogged = false;   // v6.10 闸门放行,复位拦截标志
            ggapLog = StringFormat(" 全局距上张%.2f(要求%.2f)",
                                   MathAbs(trig - globLastPrice[dIdx]), ggap);
         }
      }

      // 手数:v10.42 序列制(用户2026-10-28拍板,替代旧"基础+(m0+1)×步长"公式)——
      // 本单=通道第m+1张救援单 → 取InpRescueLotSeq第m+1个值(从左到右逐张
      // 顺次,轮内各张不再强制同值);超出序列长度沿用最后一个值;
      // 纯序列即最终手数(不再叠加基础),主组/反向组共用同一序列
      int seqIdx = (m < g_rescueSeqN) ? m : (g_rescueSeqN - 1);
      double lot = NormalizeLot(g_rescueSeq[seqIdx]);

      // v10.10 救援总手数上限(封顶"组转亏后救援链完整展开"的逃逸路径敞口):
      // 全EA同方向救援单累计总手数+本单将超上限 → 本tick不出牌(继续拦截诊断)
      if(InpRescueLotsCap > 0)
      {
         int capIdx = (dir > 0) ? 0 : 1;
         if(globLots[capIdx] + lot > InpRescueLotsCap)
         {
            if(!blkCapLogged || blkCapKey != key)   // v10.43 只状态变化打1条
            {
               LogInfo(StringFormat("G%d 救援被拦(总手数上限):第%d轮第%d/%d张 %.2f手将使同方向救援总手数%.2f超上限%.2f,停止出牌(等整组止盈/回撤平仓)",
                       g, roundNo, cardNo, roundTotal, lot, globLots[capIdx], InpRescueLotsCap));
               blkCapLogged = true;
               blkCapKey    = key;
            }
            continue;
         }
         blkCapLogged = false;   // 放行,复位拦截标志
      }

      // v10.00 A4 前置校验+失败退避
      if(FailBackoff(g, StringFormat("G%d 救援", g))) continue;
      if(!TradeGateOK(StringFormat("G%d 救援", g))) continue;
      if(!MarginOK(dir, lot, StringFormat("G%d 救援", g))) { FailMark(g); continue; }

      trade.SetExpertMagicNumber(mg);
      // v5.00 规则3:每tick每通道只出1张,禁止整轮同时出
      // (下一张由冷却/出牌间隔/价格在后续tick重新判定)
      bool ok = (dir > 0) ? trade.Buy(lot, _Symbol, 0, 0, 0, key)
                          : trade.Sell(lot, _Symbol, 0, 0, 0, key);
      if(!ok)
      {
         FailMark(g);   // v10.00 A4
         LogError(StringFormat("G%d 救援补仓失败(第%d轮第%d/%d张) ret=%d(%s)",
                 g, roundNo, cardNo, roundTotal, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
         continue;   // 失败保留进度,下一tick重新判定
      }
      // 防重发护栏:极端情况下持仓缓存滞后1秒,刚出过的牌不重复出
      lastDealKey      = key;
      lastDealTime     = TimeCurrent();
      // v5.20 全局间距闸门:成交后立即刷新全局记录(缓存重建每秒最多一次,
      // 同秒内后续tick靠此内存值挡住相邻通道,防止1.00间距连发)
      if(InpRescueGlobalGap)
      {
         int dIdx = (dir > 0) ? 0 : 1;
         double fp = trade.ResultPrice();
         globLastPrice[dIdx] = (fp > 0) ? fp : trig;
         globLastTime[dIdx]  = TimeCurrent();
         globCnt[dIdx]++;
      }
      // v10.10 救援总手数:成交后立即刷新(缓存重建每秒最多一次,同秒后续tick靠内存值挡住)
      {
         int dIdx = (dir > 0) ? 0 : 1;
         globLots[dIdx] += lot;
      }
      LogInfo(StringFormat("G%d 救援补仓(%s):第%d轮 第%d/%d张 %.2f手 触发%.2f 套牢价%.2f 锚定%.2f | 固定间距%.2f%s",
               g, dir > 0 ? "多" : "空", roundNo, cardNo, roundTotal, lot,
               trig, P, anchor, gap, ggapLog));
      Diag("救援补仓", g, StringFormat("%s第%d轮第%d/%d张 %.2f手 间距%.2f",
               dir > 0 ? "L" : "S", roundNo, cardNo, roundTotal, lot, gap));

      // v10.00 B1(用户2026-10-26拍板):救援成交后同步下调回撤峰值,
      // 减去新单承担的点差成本Δ=点差×手数×合约大小。回撤线跟着平移,
      // 不再"救援一成交就整组平仓",救援链得以正常展开。
      // (InpRescuePeakAdjust=false = 旧行为)
      if(InpRescuePeakAdjust && groups[g].trailActive)
      {
         double spread = MathMax(0, ask - bid);
         double contract = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
         if(contract <= 0) contract = 100;
         double delta = spread * lot * contract;
         double oldPeak = groups[g].peakProfit;
         groups[g].peakProfit = MathMax(0, groups[g].peakProfit - delta);
         SaveState(g);
         LogInfo(StringFormat("G%d 回撤峰值随救援下调:%.2f→%.2f(减新单点差成本%.2f)",
                 g, oldPeak, groups[g].peakProfit, delta));
      }

      return;   // 每tick最多一个通道出牌
   }
}

//=== 止盈/风控 =====================================================
// 回撤底线(按模式):百分比=峰值×(1−v%),金额=峰值−v
double TrailFloor(double peak)
{
   return (InpTrailMode == TRAIL_PERCENT)
          ? peak * (1.0 - InpTrailValue / 100.0)
          : peak - InpTrailValue;
}

// v3.22 组内有效止盈:组内当前持有救援单(GSB救)且救援止盈>0 → 切换为救援止盈;
// 否则(无救援单或未启用)用主止盈。口径不变:整组净利与阈值比较,整组平仓
// v5.60 组内最新成交救援单的手数(按开仓时间最新;无救援单返回0)
double RescueLatestLot(int g)
{
   double lot = 0;
   datetime latest = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic + g) continue;
      if(StringFind(PositionGetString(POSITION_COMMENT), "GSB救") != 0) continue;
      datetime t = (datetime)PositionGetInteger(POSITION_TIME);
      if(t >= latest)
      {
         latest = t;
         lot = PositionGetDouble(POSITION_VOLUME);
      }
   }
   return lot;
}

//=== v10.30 主止盈按手数 ==========================================
// MainLatestLot:组内最新成交"主链单"(非救援,注释非GSB救开头)手数。
// 排除救援单的原因:救援期间回撤下限tpFloor也要用主止盈兜底,若含救援单
// 则救援手数×主系数会抬高tpFloor,直接废掉v10.10 B1补强(回撤线被顶穿立即平组)。
double MainLatestLot(int g)
{
   double lot = 0;
   datetime latest = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic + g) continue;
      if(StringFind(PositionGetString(POSITION_COMMENT), "GSB救") == 0) continue;
      datetime t = (datetime)PositionGetInteger(POSITION_TIME);
      if(t >= latest)
      {
         latest = t;
         lot = PositionGetDouble(POSITION_VOLUME);
      }
   }
   return lot;
}

// MainTP:主止盈(起始手数/阶段一/阶段二统一出口)。
// InpProfitByLot开=组内最新主链单手数×InpProfitPerLot(补仓后自动放大);
// 查不到主链单(缓存/行情滞后等极端情况)或开关关=固定InpTwoSideProfit旧行为。
double MainTP(int g)
{
   if(InpProfitByLot)
   {
      double ml = MainLatestLot(g);
      if(ml > 0) return ml * InpProfitPerLot;
   }
   return InpTwoSideProfit;
}

double GroupTP(int g)
{
   // v5.60 止盈按手数:开=持有救援单期间止盈=最新成交救援单手数×每手系数
   // (0.12×100=12,0.24×100=24,每次救援成交后自动切换;整组净利口径不变);
   // 查不到救援单(缓存滞后等极端情况)兜底回主止盈;关=固定InpRescueProfit旧行为
   // v10.30 兜底与主止盈统一走 MainTP()(按手数开关自动切换,关=InpTwoSideProfit原值)
   if(g_rescueCnt[g] > 0)
   {
      if(InpRescueProfitByLot)
      {
         double rl = RescueLatestLot(g);
         if(rl > 0) return rl * InpRescueProfitPerLot;
         return (InpRescueProfit > 0) ? InpRescueProfit : MainTP(g);
      }
      return (InpRescueProfit > 0) ? InpRescueProfit : MainTP(g);
   }
   return MainTP(g);
}

void ProcessTakeProfit(int g)
{
   if(!groups[g].active || groups[g].closing) return;
   if(g_posCount[g] == 0) return;

   double profit = g_netProfit[g];
   double tp = GroupTP(g);   // v3.22 本tick有效止盈(救援阶段自动切换)

   // --- 回撤已激活:跟踪峰值,利润回落到触发线整组平仓 ---
   if(groups[g].trailActive)
   {
      if(profit > groups[g].peakProfit)
      {
         groups[g].peakProfit = profit;
         SaveState(g);
      }
      // 触发线 = max(止盈下限, 回撤底线)  ← 每次取止盈点与回撤值的最大值
      // v10.10 B1补强(模拟证实):ByLot=true时救援一成交止盈线跳升到手数×系数,
      // 远高于当时净利,会无视峰值下调直接平掉整组(v10.00七场景与旧行为逐位一致)。
      // 修复=回撤跟踪存续期间止盈下限回退主止盈,救援止盈跳升只在未激活回撤时使用,
      // 救援链得以真正展开。InpRescuePeakAdjust=false 时整组回退旧行为。
      // v10.30 主止盈统一走MainTP()(按手数开关自动切换;救援单手数已被排除,不会抬高下限)
      double tpFloor = (InpRescuePeakAdjust && g_rescueCnt[g] > 0) ? MainTP(g) : tp;
      double threshold = MathMax(tpFloor, TrailFloor(groups[g].peakProfit));
      if(profit <= threshold)
      {
         LogInfo(StringFormat("G%d 利润回撤平仓:峰值%.2f 触发线%.2f 当前%.2f%s",
                  g, groups[g].peakProfit, threshold, profit,
                  (g_rescueCnt[g] > 0) ? " [救援止盈]" : ""));
         CloseGroup(g);
      }
      return;
   }

   // --- 未激活:利润达止盈线整组平(v3.16 单边/双边统一;v3.22 救援阶段用救援止盈) ---
   if(profit >= tp)
   {
      if(!InpTrailEnabled)
      {
         LogInfo(StringFormat("G%d 止盈(%.2f≥%.2f):全平该组%s", g, profit, tp,
                  (g_rescueCnt[g] > 0) ? " [救援止盈]" : ""));
         CloseGroup(g);
         return;
      }
      // 激活回撤跟踪:不立即平仓,继续持有
      groups[g].trailActive = true;
      groups[g].peakProfit  = profit;
      SaveState(g);
      LogInfo(StringFormat("G%d 利润达止盈%.2f,激活回撤跟踪:峰值%.2f 触发线%.2f%s",
               g, tp, profit, MathMax(tp, TrailFloor(profit)),
               (g_rescueCnt[g] > 0) ? " [救援止盈]" : ""));
   }
}

void CloseGroup(int g)
{
   groups[g].closing = true;
   SaveState(g);   // v10.00 A1 立即持久化,防崩溃重启后待平组复活
   CancelGroupPendings(g, "");
   ProcessClosing(g);
}

void ProcessClosing(int g)
{
   // 按 magic 平掉本组全部持仓(止盈/利润回撤共用;v5.00 寿命/锁仓已删)
   bool ok = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic + g) continue;
      if(!trade.PositionClose(ticket))
      {
         ok = false;
         LogError(StringFormat("G%d 平仓失败#%I64u ret=%d(%s)",
                  g, ticket, trade.ResultRetcode(), trade.ResultRetcodeDescription()));
      }
   }
   if(!ok)
   {
      SaveState(g);   // v10.00 A1 平仓失败也要落盘closing状态,防重启复活
      return;
   }
   if(ok && CountGroupPositions(g) == 0)
   {
      // v8.70:重置前必须确认挂单已撤干净——撤单失败则本tick到此为止,
      // 下tick重试;防ZeroMemory抹掉票号后挂单成孤儿(成交后无人管)。
      // (若挂单已在撤销前竞态成交,CancelGroupPendings内部已平掉本组持仓)
      if(!CancelGroupPendings(g, "平仓完成撤挂单")) return;
      // 时间驱动模式:以本时刻为计时基准,零组后满InpTimeOpenSec开首组
      // (方向按两参考周期同向判定;反向组节奏由TryOpenPair规则接管;
      //  黑窗内平仓照常计时)
      // v8.50 日志简化:原"平组完成"+"计时开始"两条并一条
      g_timeCloseTime = TimeCurrent();
      // v8.80 反向组平仓:记录时刻作为反向组间隔计时基准(须在ResetGroup
      // 清零isPair之前读取;SaveTimeModeState同时持久化tmClose与pairclose)
      if(groups[g].isPair)
         g_pairCloseTime = g_timeCloseTime;
      SaveTimeModeState();
      LogInfo(StringFormat("G%d 平组完成,槽位释放 | %d秒后若零组则开首组(两参考周期各自双EMA同向才开)",
               g, InpTimeOpenSec));
      ResetGroup(g);
      UploadReport();      // v11.0 平组完成后上报一次
   }
}

//=== 图表对象 ======================================================
// v5.00 双线画线(DrawHLine/DrawBandLines)与压力/支撑位矩形
// (DrawPressureBand)整套删除,只保留救援均价线与面板

//=== 救援补偿均价可视化(v1.35) ============================================
// 每次救援后,对该救援通道所在(组,方向)的全部持仓计算加权平均开仓价,
// 画黄色粗水平线显示补偿均价;通道持仓清空后线自动消失。
// 均价口径:该组该方向所有持仓(头仓/网格/阶段二/救援单)按手数加权平均,
// 即救援摊薄后该方向的整体持仓成本。
void DrawRescueAvgLines()
{
   // 每秒节流
   static datetime lastUpd = 0;
   if(TimeCurrent() == lastUpd) return;
   lastUpd = TimeCurrent();

   // 按 (组, 方向) 聚合:是否含救援单 / Σ(价×手) / Σ手数
   bool   hasRescue[MAX_SLOTS][2];
   double sumPV  [MAX_SLOTS][2];
   double sumVol [MAX_SLOTS][2];
   for(int a = 0; a < MAX_SLOTS; a++)
      for(int b = 0; b < 2; b++)
      { hasRescue[a][b] = false; sumPV[a][b] = 0.0; sumVol[a][b] = 0.0; }

   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      long mg = PositionGetInteger(POSITION_MAGIC);
      if(mg < InpMagic || mg >= InpMagic + g_maxGroups) continue;   // v10.00 D1 口径统一
      int g = (int)(mg - InpMagic);
      int d = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 0 : 1;
      double vol   = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      sumPV[g][d]  += price * vol;
      sumVol[g][d] += vol;
      if(StringFind(PositionGetString(POSITION_COMMENT), "GSB救") == 0)
         hasRescue[g][d] = true;
   }

   // 对存在救援单的(组,方向)画黄色粗均价线
   // v3.0 性能优化:去掉每秒"全删全建"(ObjectsTotal枚举+全部重建),改为
   // 存在即原地更新价格/标签,只在通道出现/消失时创建/删除线
   for(int g = 0; g < g_maxGroups; g++)
   {
      for(int d = 0; d < 2; d++)
      {
         string name = OBJ_PREFIX + "RescueAvg" + IntegerToString(g) + (d == 0 ? "L" : "S");
         if(!hasRescue[g][d] || sumVol[g][d] <= 0)
         { ObjectDelete(0, name); continue; }

         double avg = sumPV[g][d] / sumVol[g][d];
         string tag = StringFormat("救援均价 G%d %s %.2f (手数%.2f)", g, d == 0 ? "多" : "空", avg, sumVol[g][d]);
         if(ObjectFind(0, name) < 0)
         {
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, avg);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrYellow);   // 黄色
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID); // 实线
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);           // 宽一点,醒目
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         }
         ObjectSetDouble(0, name, OBJPROP_PRICE, avg);
         ObjectSetString (0, name, OBJPROP_TEXT, tag);
      }
   }

   // v3.0 清理超出当前组数的残留线(InpMaxGroups调小后不留孤儿线)
   for(int g = g_maxGroups; g < MAX_SLOTS; g++)
      for(int d = 0; d < 2; d++)
      {
         string name = OBJ_PREFIX + "RescueAvg" + IntegerToString(g) + (d == 0 ? "L" : "S");
         if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
      }
}

//=== v10.40 方向框可视化(InpBoxShow开关;GSB_Box前缀,OnDeinit统一清理) ==
// 线框矩形=回看窗口到当前右侧2根(OBJ_RECTANGLE时间-价格版,不填充纯边框,
// 与10.4已编译源码同款API),上/下轨与中点=灰色全宽横线(OBJ_HLINE,与10.3
// 救援均价线同款API,无需时间锚点);
// 2026-10-28 用户要求:透明无色不亮→全部灰阶线框(矩形不填充C'130',上下轨
// C'100'实线,中点C'160'虚线);
// 框每秒随BoxUpdate缓存刷新,历史K线加载完成前(g_boxReady=false)不画。
void DrawBox()
{
   if(!InpBoxShow || !g_boxReady) return;
   datetime t1 = iTime(_Symbol, InpBoxTF, InpBoxBars);        // 窗口最旧一根(shift1起N根)
   datetime t2 = TimeCurrent() + PeriodSeconds(InpBoxTF) * 2; // 右侧延伸2根
   if(t1 <= 0) return;

   string nm = OBJ_PREFIX + "BoxZone";
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_RECTANGLE, 0, t1, g_boxTop, t2, g_boxBottom);
      ObjectSetInteger(0, nm, OBJPROP_FILL, false);   // 2026-10-28 不填充=纯线框
      ObjectSetInteger(0, nm, OBJPROP_BACK, true);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, nm, OBJPROP_COLOR, C'130,130,130');   // 中灰边框(透明无色不亮)
   ObjectSetInteger(0, nm, OBJPROP_TIME, 0, (long)t1);
   ObjectSetDouble (0, nm, OBJPROP_PRICE, 0, g_boxTop);
   ObjectSetInteger(0, nm, OBJPROP_TIME, 1, (long)t2);
   ObjectSetDouble (0, nm, OBJPROP_PRICE, 1, g_boxBottom);

   BoxLine(OBJ_PREFIX + "BoxTop", g_boxTop,    C'100,100,100', STYLE_SOLID);
   BoxLine(OBJ_PREFIX + "BoxBot", g_boxBottom, C'100,100,100', STYLE_SOLID);
   BoxLine(OBJ_PREFIX + "BoxMid", g_boxMid,    C'160,160,160', STYLE_DOT);
}

// 方向框横线(全宽HLINE;价格每秒随框缓存刷新)
void BoxLine(string nm, double price, color clr, ENUM_LINE_STYLE st)
{
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, nm, OBJPROP_STYLE, st);
   ObjectSetInteger(0, nm, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, nm, OBJPROP_BACK, false);
   ObjectSetDouble (0, nm, OBJPROP_PRICE, price);
}

//=== 面板(赛博暗色主题) ===========================================
//--- 配色(电光蓝+紫,深空底色)
#define COL_BG        C'10,14,22'    // 主背景(深空黑蓝)
#define COL_BORDER    C'38,58,92'    // 主背景描边
#define COL_HEADER    C'14,20,34'    // 标题栏背景
#define COL_ACCENT    C'0,212,255'   // 电光蓝主装饰
#define COL_TITLE     C'240,248,255' // 标题文字
#define COL_SUB       C'118,140,168' // 次要文字
#define COL_SEP       C'40,54,78'    // 分隔线
#define COL_GREEN     C'0,230,118'   // 盈利(荧光绿)
#define COL_RED       C'255,82,82'   // 亏损(警示红)
#define COL_CURBG     C'18,26,42'    // 当前周期行背景
#define COL_CURBD     C'0,150,205'   // 当前周期行描边(电蓝)
#define COL_GOLD      C'255,198,64'  // 点缀金

#define CUR_ROW_H     48             // 当前周期行高(像素)

//--- 布局(按用户宽高每秒重算,自适应行距;利润/亏损列整体左移)
int g_dashW = 460, g_dashH = 600;               // 面板实际宽高(下限保护后)
int g_yStatLbl = 0, g_yStatVal = 0;             // 双列统计标签/数值(总盈利|最大亏损)
int g_ySep = 0, g_ySecHead = 0, g_yColHead = 0; // 分隔线/周期标题/列头
int g_yHist0 = 0, g_lineH = 24, g_yCur = 0;     // 历史首行/行高/当前行
int g_xProfit = 0, g_xLoss = 0;                 // 利润/亏损列右锚点(左移后)

void DashLayout()
{
   g_dashW = MathMax(320, InpPanelWidth);
   g_dashH = MathMax(440, InpPanelHeight);
   g_yStatLbl = 70;
   g_yStatVal = 90;
   g_ySep     = 132;
   g_ySecHead = 144;
   g_yColHead = 166;
   g_yHist0   = 186;
   g_yCur     = g_dashH - 12 - CUR_ROW_H;
   g_xProfit  = g_dashW - 170;   // 利润列右锚点(原dashW-150,左移20)
   g_xLoss    = g_dashW - 42;    // 亏损列右锚点(原dashW-22,左移20)
   int histAvail = g_yCur - 10 - g_yHist0;
   g_lineH    = MathMax(16, histAvail / MAX_PERIOD_HIST);
   if(g_lineH > 48)
   {
      g_yHist0 += (histAvail - 48 * MAX_PERIOD_HIST) / 2;
      g_lineH   = 48;
   }
}

void DashRect(string nm, int x, int y, int w, int h, color bg, color border, bool back = false)
{
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, nm, OBJPROP_BACK, back);   // 底层绘制:行情画在面板之上
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, DASH_X + x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, DASH_Y + y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, border);
}

void DashText(string nm, int x, int y, string text, color clr, int fs, string font, int anchor)
{
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, DASH_X + x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, DASH_Y + y);
   ObjectSetString(0, nm, OBJPROP_TEXT, text);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, fs);
   ObjectSetString(0, nm, OBJPROP_FONT, font);
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR, anchor);
}

// v8.50 面板按钮(OBJ_BUTTON,点击事件在OnChartEvent处理)
void DashButton(string nm, int x, int y, int w, int h, string text)
{
   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 8);
      ObjectSetString (0, nm, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, COL_BORDER);      // 深底
      ObjectSetInteger(0, nm, OBJPROP_COLOR, COL_TITLE);         // 亮字
      ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, COL_ACCENT); // 电蓝描边
   }
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, DASH_X + x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, DASH_Y + y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetString (0, nm, OBJPROP_TEXT, text);
}

void UpdateDashboard()
{
   if(g_isTester && !MQLInfoInteger(MQL_VISUAL_MODE)) return;
   static datetime lastUpd = 0;
   if(TimeCurrent() == lastUpd) return;
   lastUpd = TimeCurrent();

   DashLayout();

   // --- 背景/装饰(创建顺序即覆盖顺序:BG最底,文字最顶) ---
   DashRect(OBJ_PREFIX+"DashBG",     0, 3, g_dashW, g_dashH - 3, COL_BG, COL_BORDER);
   DashRect(OBJ_PREFIX+"DashAccent", 0, 0, g_dashW, 3, COL_ACCENT, COL_ACCENT);
   DashRect(OBJ_PREFIX+"DashHeader", 0, 3, g_dashW, 53, COL_HEADER, COL_HEADER);
   DashRect(OBJ_PREFIX+"HeadLine",   0, 56, g_dashW, 1, COL_ACCENT, COL_ACCENT);
   DashRect(OBJ_PREFIX+"StatDiv",  g_dashW / 2, 64, 1, 60, COL_SEP, COL_SEP);
   DashRect(OBJ_PREFIX+"DashSep",   20, g_ySep, g_dashW - 40, 1, COL_SEP, COL_SEP);
   DashRect(OBJ_PREFIX+"DashBottom", 0, g_dashH - 2, g_dashW, 2, COL_ACCENT, COL_ACCENT);

   // --- 历史行斑马纹(奇数行微亮,增强层次) ---
   for(int z = 0; z < MAX_PERIOD_HIST; z++)
   {
      color zc = (z % 2 == 1) ? C'14,20,34' : COL_BG;
      DashRect(OBJ_PREFIX + "Zebra" + IntegerToString(z),
               12, g_yHist0 + z * g_lineH - 3, g_dashW - 24, g_lineH - 3, zc, zc);
   }

   // --- 当前周期高亮行:电蓝描边 + 左侧电光条 ---
   DashRect(OBJ_PREFIX+"DashCurBG", 10, g_yCur, g_dashW - 20, CUR_ROW_H, COL_CURBG, COL_CURBD);
   DashRect(OBJ_PREFIX+"CurStripe", 10, g_yCur, 4, CUR_ROW_H, COL_ACCENT, COL_ACCENT);

   // --- 标题(粗体大字+电光下划线) + 右上角版本徽标 + 左上角重置按钮 ---
   if(ObjectFind(0, OBJ_PREFIX+"Title2") >= 0) ObjectDelete(0, OBJ_PREFIX+"Title2");   // 清理旧副标题
   DashText(OBJ_PREFIX+"Title1", g_dashW / 2, 14, "黄金拾贝 GoldShiBei", COL_TITLE, 14, "Arial Black", ANCHOR_UPPER);
   DashRect(OBJ_PREFIX+"TitleAccent", g_dashW / 2 - 52, 42, 104, 2, COL_ACCENT, COL_ACCENT);
   DashText(OBJ_PREFIX+"VerTag", g_dashW - 14, 8,
            "拾贝联网V1.1", COL_ACCENT, 8, "Consolas", ANCHOR_RIGHT_UPPER);
   DashButton(OBJ_PREFIX+"BtnReset", 10, 8, 56, 16, "重置统计");   // v8.50 点击清空全部统计(OnChartEvent)

   // --- 双列统计:总盈利 | 最大亏损(从头到尾最大回撤,含盈利内回撤) ---
   double totalProfit = g_realizedProfit + g_totalNet;
   DashText(OBJ_PREFIX+"ProfLbl", g_dashW / 4, g_yStatLbl, "总 盈 利", COL_SUB, 8, "Arial", ANCHOR_UPPER);
   DashText(OBJ_PREFIX+"ProfVal", g_dashW / 4, g_yStatVal, StringFormat("%+.2f", totalProfit),
            totalProfit >= 0 ? COL_GREEN : COL_RED, 17, "Consolas", ANCHOR_UPPER);
   DashText(OBJ_PREFIX+"MaxLbl", g_dashW * 3 / 4, g_yStatLbl, "最大亏损", COL_SUB, 8, "Arial", ANCHOR_UPPER);
   DashText(OBJ_PREFIX+"MaxVal", g_dashW * 3 / 4, g_yStatVal, StringFormat("%.2f", g_allTimeMaxLoss),
            COL_RED, 17, "Consolas", ANCHOR_UPPER);

   // --- 周期标题 + 列头(利润/亏损列整体左移) ---
   DashText(OBJ_PREFIX+"SecHead", g_dashW / 2, g_ySecHead,
            StringFormat("── %d天周期 · 已完成%d期 ──", InpPeriodDays, g_histCount),
            COL_GOLD, 9, "Arial", ANCHOR_UPPER);
   DashText(OBJ_PREFIX+"ColD", 22, g_yColHead, "日期", COL_SUB, 8, "Arial", ANCHOR_LEFT_UPPER);
   DashText(OBJ_PREFIX+"ColP", g_xProfit, g_yColHead, "利润", COL_SUB, 8, "Arial", ANCHOR_RIGHT_UPPER);
   DashText(OBJ_PREFIX+"ColL", g_xLoss, g_yColHead, "亏损", COL_SUB, 8, "Arial", ANCHOR_RIGHT_UPPER);

   // --- 历史周期(旧→新):日期/利润/亏损(取整四舍五入,亏损红色) ---
   for(int i = 0; i < MAX_PERIOD_HIST; i++)
   {
      int y = g_yHist0 + i * g_lineH;
      string dnm = OBJ_PREFIX + "HistD" + IntegerToString(i);
      string pnm = OBJ_PREFIX + "HistP" + IntegerToString(i);
      string lnm = OBJ_PREFIX + "HistL" + IntegerToString(i);
      if(i < g_histCount)
      {
         DashText(dnm, 22, y, TimeToString(g_histStart[i], TIME_DATE), COL_SUB, 9, "Consolas", ANCHOR_LEFT_UPPER);
         DashText(pnm, g_xProfit, y, StringFormat("%+.0f", g_histProfit[i]),
                  g_histProfit[i] >= 0 ? COL_GREEN : COL_RED, 9, "Consolas", ANCHOR_RIGHT_UPPER);
         DashText(lnm, g_xLoss, y, StringFormat("%.0f", g_histLoss[i]), COL_RED, 9, "Consolas", ANCHOR_RIGHT_UPPER);
      }
      else
      {
         DashText(dnm, 22, y, " ", COL_SUB, 9, "Consolas", ANCHOR_LEFT_UPPER);
         DashText(pnm, g_xProfit, y, " ", COL_SUB, 9, "Consolas", ANCHOR_RIGHT_UPPER);
         DashText(lnm, g_xLoss, y, " ", COL_SUB, 9, "Consolas", ANCHOR_RIGHT_UPPER);
      }
   }

   // --- 当前周期(高亮行):带"利润/亏损"字样,数值左移与历史列对齐 ---
   // 亏损 = 周期亏损(净值自周期内峰值的最大回落,含盈利中的回撤)
   double periodProfit = AccountInfoDouble(ACCOUNT_BALANCE) - g_periodBase;
   int curY = g_yCur + 17;
   DashText(OBJ_PREFIX+"CurLbl", 24, curY, "当前", COL_GOLD, 10, "Arial Black", ANCHOR_LEFT_UPPER);
   // v3.11 累计开仓手数:紧跟"当前"二字右侧,每成交一笔按手数累加
   DashText(OBJ_PREFIX+"CurLots", 76, curY + 2, StringFormat("累计下单 %.2f 手", g_totalOpenLots),
            COL_GOLD, 8, "Arial", ANCHOR_LEFT_UPPER);
   DashText(OBJ_PREFIX+"CurPLbl", g_xProfit - 46, curY + 2, "利润", COL_SUB, 8, "Arial", ANCHOR_RIGHT_UPPER);
   DashText(OBJ_PREFIX+"CurP", g_xProfit, curY, StringFormat("%+.0f", periodProfit),
            periodProfit >= 0 ? COL_GREEN : COL_RED, 12, "Consolas", ANCHOR_RIGHT_UPPER);
   DashText(OBJ_PREFIX+"CurLLbl", g_xLoss - 46, curY + 2, "亏损", COL_SUB, 8, "Arial", ANCHOR_RIGHT_UPPER);
   DashText(OBJ_PREFIX+"CurL", g_xLoss, curY, StringFormat("%.0f", g_periodMaxLoss), COL_RED, 12, "Consolas", ANCHOR_RIGHT_UPPER);

   ChartRedraw();
}

//=== 主流程 ========================================================
// v5.00 熔断止损(CheckHaltLoss/HaltCloseAll)已随参数删除
void OnTick()
{
   // v5.90 授权到期检查:到期即停一切交易逻辑,面板红字(EA不自动卸载;回测跳过)
   if(!g_isTester && g_authOK && TimeCurrent() >= g_authExpiry)
   {
      g_authOK     = false;
      g_authReason = StringFormat("授权已过期(到期 %s)",
                     TimeToString(g_authExpiry, TIME_DATE | TIME_MINUTES));
      LogError(g_authReason + ",停止一切交易逻辑");
      Alert("拾贝联网V1.1 ", g_authReason);
   }
   if(!g_authOK)
   {
      ShowAuthPanel();
      ChartRedraw();
      return;
   }

   // 1. 持仓缓存(单次扫描全部持仓)
   RefreshPositionCache();

   // 2. 周末限制(v3.09 只停开新组,链子照跑)
   //    周五截止(每周五开始小时)生效:只挡开新组;已开组的网格续挂/
   //    阶段二补仓/救援通道与周一完全一致,跨周末照常运行;
   //    未成交的挂单跨周末保留,周一开盘即可继续做这单(黑窗内触发也算),
   //    周一黑窗结束(每周一结束小时)后开新组恢复
   bool newBlackout = InpWeekendBlackout && IsWeekendBlackout();
   if(newBlackout != g_blackout)
   {
      g_blackout = newBlackout;
      if(g_blackout)
         LogInfo("周五截止生效:只停开新组,已开组的网格/阶段二/救援照常运行");
      else
         LogInfo("周末限制结束:恢复开新组,链子与救援全程未停");
   }

   // 3. 开新组(时间驱动:零组按InpTimeOpenSec秒+方向跟随开首组;
   //    有活跃组走反向组规则(救援触发≥InpPairRescueCnt次),救援联动,双组并行)
   // v10.00 A3 注释自检每300秒兜底一次(捕捉运行中新开的单被经纪商改写注释)
   {
      static datetime lastCmChk = 0;
      if(TimeCurrent() - lastCmChk >= 300)
      { lastCmChk = TimeCurrent(); CheckCommentHealth("周期"); }
   }
   if(!g_blackout)
      TryOpenByTime();

   // 4.5 套牢救援:逐张单检测,现价逆势偏离达阈值 → 独立通道补仓
   ProcessRescue();

   // 5. 逐组处理
   for(int g = 0; g < g_maxGroups; g++)
   {
      if(!groups[g].active) continue;

      // v8.70 写死:组持仓走掉必须立马撤掉本组挂单——
      // closing=撤单失败持续重试;非closing=外部平仓兜底(活体重扫确认
      // 走光才撤,防tick开头缓存滞后误撤),与事件级撤单双保险
      if(groups[g].pendingTicket != 0
         && (groups[g].closing || g_posCount[g] == 0))
      {
         if(groups[g].closing || CountGroupPositions(g) == 0)
            CancelGroupPendings(g, groups[g].closing ? "平仓中重试撤单" : "持仓已走光");
      }

      if(groups[g].closing)
      {
         ProcessClosing(g);
         continue;
      }

      // 外部平仓/异常空组检测(开组10秒后仍无持仓无挂单 → 重置)
      if(g_posCount[g] == 0 && groups[g].pendingTicket == 0
         && TimeCurrent() - groups[g].openTime > 10)
      {
         // 时间模式:外部平仓也算上一单结束,以当前时刻重新计时
         // v8.50 日志简化:原"无持仓挂单"+"重新计时"两条并一条
         g_timeCloseTime = TimeCurrent();
         // v8.80 外部平仓同样记录反向组平仓时刻(手动平掉反向组也触发间隔)
         if(groups[g].isPair)
            g_pairCloseTime = g_timeCloseTime;
         SaveTimeModeState();
         LogInfo(StringFormat("G%d 外部平仓(无持仓无挂单),槽位重置 | 重新计时%d秒后零组则开首组",
                 g, InpTimeOpenSec));
         ResetGroup(g);
         UploadReport();      // v11.0 外部平仓也上报一次
         continue;
      }

      // 成交检测(周末也检测,链子续挂跨周末运行)
      CheckPendingFilled(g);
      if(!groups[g].active) continue;

      // v3.09:链子(网格/阶段二)周末照跑,只停开新组
      if(groups[g].phase == 0) ProcessPhase1(g);
      else                     ProcessPhase2(g);

      ProcessTakeProfit(g);

      // v10.00 B3 阶段二冻结告警(用户2026-10-26拍板:只加日志,行为不变):
      // 进阶段二后无补仓、未达止盈、未激活回撤持续超 InpFreezeAlertSec →
      // 打一条告警(本轮只打一次),提示退出条件距行情过远,组在真空地带漂移
      if(InpFreezeAlertSec > 0 && groups[g].phase == 1
         && groups[g].phase2Adds == 0 && !groups[g].trailActive)
      {
         if(g_freezeSince[g] == 0)
         { g_freezeSince[g] = TimeCurrent(); g_freezeWarned[g] = false; }
         else if(!g_freezeWarned[g] && TimeCurrent() - g_freezeSince[g] >= InpFreezeAlertSec)
         {
            g_freezeWarned[g] = true;
            LogError(StringFormat(
               "G%d [冻结告警] 进阶段二后%d秒无补仓无止盈:止盈/补仓/救援所需价格均距当前行情过远(B3真空地带),组将持续累积浮亏。P0=%.2f 上触发=%.2f 下触发=%.2f",
               g, InpFreezeAlertSec,
               groups[g].p0,
               groups[g].p0 + (groups[g].isPair ? InpPairGridA : InpGridA) + groups[g].k1 * (groups[g].isPair ? InpPairStepB : InpStepB),
               groups[g].p0 - (groups[g].isPair ? InpPairGridA : InpGridA) - groups[g].k2 * (groups[g].isPair ? InpPairStepB : InpStepB)));
         }
      }
      else
      { g_freezeSince[g] = 0; g_freezeWarned[g] = false; }   // 状态解除复位,下次冻结重新计时
   }

   // 6. 周期滚动/最大亏损跟踪 + 历史盈亏增量累计
   PeriodUpdate();
   TodayWeekUpdate();     // v11.0 今日/本周基准滚动(跨天/跨周)
   MaybeUploadHold();     // v11.2 扛单超1小时每小时上报
   UpdateRealizedProfit();

   // 7. 画线 + 面板(非可视化回测跳过全部图表绘制/对象操作,
   //    只保留交易与统计逻辑;实盘与可视化回测行为不变)
   //    可视化模式按真实时间节流(200ms≈5fps),交易逻辑不受影响
   if(!g_isTester || MQLInfoInteger(MQL_VISUAL_MODE))
   {
      static uint lastDrawMs = 0;
      uint nowMs = GetTickCount();
      if(!g_isTester || nowMs - lastDrawMs >= 200)
      {
         lastDrawMs = nowMs;
         DrawRescueAvgLines(); // v1.35 救援补偿均价黄色粗线
         DrawBox();            // v10.40 方向框可视化(上/下轨/中点+底色)
         if(InpShowDashboard) UpdateDashboard();
      }
   }
}

//=== 交易事务(v3.14) ==============================================
// 任一交易事务(成交/撤单/订单/持仓变动)置脏救援缓存,下一个tick重建;
// 配合每秒兜底刷新,即使个别事务丢失缓存最多滞后1秒,不影响正确性
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   g_rescueDirty = true;

   // v8.70 写死:组持仓走光的瞬间(交易事务事件级,毫秒响应,不等下一tick)
   // 立即撤销本组挂单——杜绝"单子走掉后挂单还挂着被触发进单"的窗口
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(trans.deal)) return;
   long mg = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   if(mg < InpMagic || mg >= InpMagic + MAX_SLOTS) return;
   int g = (int)(mg - InpMagic);
   if(g < 0 || g >= g_maxGroups || !groups[g].active) return;
   long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);

   if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
   {
      // 平仓成交:本组持仓已走光且挂单还挂着 → 事件级立即撤单
      if(groups[g].pendingTicket != 0 && CountGroupPositions(g) == 0)
         CancelGroupPendings(g, "事件级:持仓走光");
   }
   else if(entry == DEAL_ENTRY_IN && groups[g].closing)
   {
      // 平仓过程中挂单漏网成交(撤单前竞态):事件级立即平掉,不等下tick
      long posID = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
      if(posID > 0 && PositionSelectByTicket((ulong)posID)
         && PositionGetInteger(POSITION_MAGIC) == InpMagic + g)
      {
         if(trade.PositionClose((ulong)posID))
            LogInfo(StringFormat("G%d 平仓中混入单#%I64d已事件级平掉", g, posID));
         else
            LogError(StringFormat("G%d 混入单#%I64d平掉失败 ret=%d(下tick ProcessClosing重扫兜底)",
                     g, posID, trade.ResultRetcode()));
      }
   }
}

//=== 面板按钮事件(v8.50) ==========================================
// 点击面板"重置统计"按钮:清空周期/历史行/最大亏损/总盈利/累计手数,
// 全部从头起算(授权失效时不响应;回测可视化模式同样可用,仅作用于内存)
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == OBJ_PREFIX+"BtnReset")
   {
      ObjectSetInteger(0, OBJ_PREFIX+"BtnReset", OBJPROP_STATE, false);   // 按钮弹起
      if(g_authOK)
         DoStatsReset("面板按钮");
      ChartRedraw();
   }
}
//+------------------------------------------------------------------+
