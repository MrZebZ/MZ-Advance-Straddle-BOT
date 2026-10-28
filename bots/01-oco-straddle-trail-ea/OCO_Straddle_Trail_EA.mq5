//+------------------------------------------------------------------+
//|                                        OCO_Straddle_Trail_EA.mq5 |
//|  Two pending orders (above/below price) with tight initial SL.   |
//|  First fill cancels the other (OCO), then an aggressive trailing |
//|  stop manages the open trade.                                    |
//|  TEST ON DEMO FIRST. No profit is guaranteed.                    |
//+------------------------------------------------------------------+
#property copyright "OCO Straddle Trail EA"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

enum ENUM_ENTRY_KIND
  {
   ENTRY_STOP  = 0,   // Breakout: Buy Stop above / Sell Stop below
   ENTRY_LIMIT = 1    // Fade: Buy Limit below / Sell Limit above
  };

//--- Entry
input group "=== Entry ==="
input ENUM_ENTRY_KIND InpEntryKind   = ENTRY_STOP; // Pending order type
input int    InpDistancePoints       = 100;   // Distance of pendings from price (points)
input int    InpExpiryMinutes        = 5;     // Pendings expire after (minutes, 0 = no expiry)

//--- Exit
input group "=== Exit / Trailing ==="
input int    InpInitialSLPoints      = 80;    // Initial (close) stop loss (points)
input int    InpTakeProfitPoints     = 0;     // Take profit (points, 0 = none, trail only)
input bool   InpUseTrailing          = true;  // Use trailing stop
input int    InpTrailStartPoints     = 40;    // Start trailing after profit of (points)
input int    InpTrailDistancePoints  = 40;    // Trailing distance behind price (points)
input int    InpTrailStepPoints      = 5;     // Minimum SL improvement per move (points)

//--- Risk
input group "=== Risk ==="
input double InpFixedLots            = 0.01;  // Fixed lot (used if risk % = 0)
input double InpRiskPercent          = 0.0;   // Risk % of balance per trade (0 = use fixed lot)
input double InpMaxDailyLossPercent  = 0.0;   // Stop trading for the day at this loss % (0 = off)
input int    InpMaxTradesPerDay      = 0;     // Max trades per day (0 = unlimited)
input int    InpMaxSpreadPoints      = 0;     // Do not arm if spread above (points, 0 = off)

//--- Timing
input group "=== Timing (broker server time) ==="
input bool   InpUseTimeFilter        = false; // Only arm inside time window
input int    InpStartHour            = 8;
input int    InpStartMinute          = 0;
input int    InpEndHour              = 20;
input int    InpEndMinute            = 0;
input bool   InpRearm                = true;  // Re-arm a new straddle after trade closes
input int    InpCooldownSeconds      = 30;    // Wait after a trade closes / orders expire

input group "=== General ==="
input long   InpMagic                = 20261015; // Magic number
input int    InpSlippagePoints       = 20;       // Max deviation (points)
input string InpComment              = "OCOStraddle";

CTrade   trade;
datetime g_lastActivity = 0;
bool     g_hadPosition  = false;
bool     g_firedOnce    = false;   // used when InpRearm = false

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   if(InpDistancePoints <= 0 || InpInitialSLPoints <= 0)
     {
      Print("Distance and initial SL must be > 0");
      return INIT_PARAMETERS_INCORRECT;
     }
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   bool hasPos = HasPosition();

   if(hasPos)
     {
      g_hadPosition = true;
      DeletePendings();                 // OCO: remove the other side
      if(InpUseTrailing) TrailPosition();
      return;
     }

   if(g_hadPosition)                    // position just closed
     {
      g_hadPosition  = false;
      g_lastActivity = TimeCurrent();
     }

   int pend = CountPendings();
   if(pend == 1)                        // one side expired/removed -> clean up
     {
      DeletePendings();
      g_lastActivity = TimeCurrent();
      return;
     }
   if(pend >= 2) return;                // waiting for a fill

   // nothing open, nothing pending -> maybe arm
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     { SetStatus("BLOCKED: click the AutoTrading button in MT5 toolbar (must be green)"); return; }
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
     { SetStatus("BLOCKED: tick 'Allow Algo Trading' in the EA Common tab"); return; }
   if(!InpRearm && g_firedOnce)
     { SetStatus("DONE: re-arm is off, one straddle already placed"); return; }
   if(TimeCurrent() - g_lastActivity < InpCooldownSeconds)
     { SetStatus("Cooldown before next straddle"); return; }
   if(!InTimeWindow())
     { SetStatus("WAITING: outside time window (server time " + TimeToString(TimeCurrent(), TIME_MINUTES) + ")"); return; }
   if(!SpreadOK())
     { SetStatus("WAITING: spread too high (" + IntegerToString((int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)) + " pts, max " + IntegerToString(InpMaxSpreadPoints) + ")"); return; }
   if(DailyLossHit())
     { SetStatus("PAUSED: daily loss limit reached, resumes tomorrow"); return; }
   if(InpMaxTradesPerDay > 0 && TradesToday() >= InpMaxTradesPerDay)
     { SetStatus("PAUSED: max trades per day reached"); return; }

   PlaceStraddle();
  }

string g_lastStatus = "";
void SetStatus(string s)
  {
   if(s == g_lastStatus) return;
   g_lastStatus = s;
   Comment("OCO Straddle EA\n", s);
   Print("OCO Straddle EA: ", s);
  }

//+------------------------------------------------------------------+
bool HasPosition()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagic)
         return true;
     }
   return false;
  }

int CountPendings()
  {
   int n = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == InpMagic)
         n++;
     }
   return n;
  }

void DeletePendings()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == InpMagic)
         trade.OrderDelete(t);
     }
  }

//+------------------------------------------------------------------+
bool InTimeWindow()
  {
   if(!InpUseTimeFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int now   = dt.hour * 60 + dt.min;
   int start = InpStartHour * 60 + InpStartMinute;
   int end   = InpEndHour * 60 + InpEndMinute;
   if(start <= end) return (now >= start && now < end);
   return (now >= start || now < end);   // overnight window
  }

bool SpreadOK()
  {
   if(InpMaxSpreadPoints <= 0) return true;
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return spread <= InpMaxSpreadPoints;
  }

//+------------------------------------------------------------------+
datetime DayStart()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   return StructToTime(dt);
  }

double TodayRealizedPnL()
  {
   double pnl = 0;
   if(!HistorySelect(DayStart(), TimeCurrent())) return 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if(HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      pnl += HistoryDealGetDouble(d, DEAL_PROFIT)
           + HistoryDealGetDouble(d, DEAL_SWAP)
           + HistoryDealGetDouble(d, DEAL_COMMISSION);
     }
   return pnl;
  }

int TradesToday()
  {
   int n = 0;
   if(!HistorySelect(DayStart(), TimeCurrent())) return 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if(HistoryDealGetInteger(d, DEAL_ENTRY) == DEAL_ENTRY_IN) n++;
     }
   return n;
  }

bool DailyLossHit()
  {
   if(InpMaxDailyLossPercent <= 0) return false;
   double pnl = TodayRealizedPnL();
   if(pnl >= 0) return false;
   double startBal = AccountInfoDouble(ACCOUNT_BALANCE) - pnl;
   if(startBal <= 0) return true;
   return (-pnl / startBal * 100.0) >= InpMaxDailyLossPercent;
  }

//+------------------------------------------------------------------+
double NormalizeLots(double lots)
  {
   double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   lots = MathFloor(lots / step) * step;
   lots = MathMax(minL, MathMin(maxL, lots));
   return NormalizeDouble(lots, 2);
  }

double CalcLots()
  {
   if(InpRiskPercent <= 0) return NormalizeLots(InpFixedLots);
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || tickSize <= 0) return NormalizeLots(InpFixedLots);
   double slMoney = (InpInitialSLPoints * _Point / tickSize) * tickVal; // loss per 1.0 lot
   if(slMoney <= 0) return NormalizeLots(InpFixedLots);
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   return NormalizeLots(riskMoney / slMoney);
  }

//+------------------------------------------------------------------+
void PlaceStraddle()
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   long   stopsLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long   freeze   = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   int    minDist  = (int)MathMax(stopsLvl, freeze) + 2;

   int dist = MathMax(InpDistancePoints, minDist);
   int sl   = MathMax(InpInitialSLPoints, minDist);
   int tp   = (InpTakeProfitPoints > 0) ? MathMax(InpTakeProfitPoints, minDist) : 0;

   double lots = CalcLots();
   datetime exp = (InpExpiryMinutes > 0) ? TimeCurrent() + InpExpiryMinutes * 60 : 0;
   ENUM_ORDER_TYPE_TIME tt = (InpExpiryMinutes > 0) ? ORDER_TIME_SPECIFIED : ORDER_TIME_GTC;

   double buyPrice, sellPrice;
   if(InpEntryKind == ENTRY_STOP)
     { buyPrice = ask + dist * _Point; sellPrice = bid - dist * _Point; }
   else
     { buyPrice = ask - dist * _Point; sellPrice = bid + dist * _Point; }

   buyPrice  = NormalizeDouble(buyPrice,  _Digits);
   sellPrice = NormalizeDouble(sellPrice, _Digits);

   double buySL  = NormalizeDouble(buyPrice  - sl * _Point, _Digits);
   double sellSL = NormalizeDouble(sellPrice + sl * _Point, _Digits);
   double buyTP  = (tp > 0) ? NormalizeDouble(buyPrice  + tp * _Point, _Digits) : 0;
   double sellTP = (tp > 0) ? NormalizeDouble(sellPrice - tp * _Point, _Digits) : 0;

   bool okBuy, okSell;
   if(InpEntryKind == ENTRY_STOP)
     {
      okBuy  = trade.BuyStop(lots, buyPrice, _Symbol, buySL, buyTP, tt, exp, InpComment);
      okSell = trade.SellStop(lots, sellPrice, _Symbol, sellSL, sellTP, tt, exp, InpComment);
     }
   else
     {
      okBuy  = trade.BuyLimit(lots, buyPrice, _Symbol, buySL, buyTP, tt, exp, InpComment);
      okSell = trade.SellLimit(lots, sellPrice, _Symbol, sellSL, sellTP, tt, exp, InpComment);
     }

   if(!okBuy || !okSell)
     {
      string why = trade.ResultRetcodeDescription();
      PrintFormat("Straddle placement failed (buy=%d sell=%d) err=%d %s",
                  okBuy, okSell, trade.ResultRetcode(), why);
      DeletePendings();                 // never leave a one-sided order

      // retry once without expiry (some brokers reject expiration)
      if(InpExpiryMinutes > 0)
        {
         if(InpEntryKind == ENTRY_STOP)
           {
            okBuy  = trade.BuyStop(lots, buyPrice, _Symbol, buySL, buyTP, ORDER_TIME_GTC, 0, InpComment);
            okSell = trade.SellStop(lots, sellPrice, _Symbol, sellSL, sellTP, ORDER_TIME_GTC, 0, InpComment);
           }
         else
           {
            okBuy  = trade.BuyLimit(lots, buyPrice, _Symbol, buySL, buyTP, ORDER_TIME_GTC, 0, InpComment);
            okSell = trade.SellLimit(lots, sellPrice, _Symbol, sellSL, sellTP, ORDER_TIME_GTC, 0, InpComment);
           }
         if(!okBuy || !okSell) DeletePendings();
        }
      if(!okBuy || !okSell)
        {
         SetStatus("ORDER REJECTED by broker: " + why + " (see Experts tab)");
         g_lastActivity = TimeCurrent();
         return;
        }
     }
   SetStatus("ACTIVE: straddle placed, waiting for a fill");
   g_firedOnce    = true;
   g_lastActivity = TimeCurrent();
  }

//+------------------------------------------------------------------+
void TrailPosition()
  {
   long stopsLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minGap = (stopsLvl + 2) * _Point;
   double dist   = MathMax(InpTrailDistancePoints, (int)stopsLvl + 2) * _Point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;

      long   type  = PositionGetInteger(POSITION_TYPE);
      double open  = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double curTP = PositionGetDouble(POSITION_TP);
      double step  = InpTrailStepPoints * _Point;

      if(type == POSITION_TYPE_BUY)
        {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(bid - open < InpTrailStartPoints * _Point) continue;
         double newSL = NormalizeDouble(bid - dist, _Digits);
         if(bid - newSL < minGap) continue;
         if(curSL == 0 || newSL >= curSL + step)
            trade.PositionModify(t, newSL, curTP);
        }
      else if(type == POSITION_TYPE_SELL)
        {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(open - ask < InpTrailStartPoints * _Point) continue;
         double newSL = NormalizeDouble(ask + dist, _Digits);
         if(newSL - ask < minGap) continue;
         if(curSL == 0 || newSL <= curSL - step)
            trade.PositionModify(t, newSL, curTP);
        }
     }
  }
//+------------------------------------------------------------------+
