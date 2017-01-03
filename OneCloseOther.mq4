/**
      One Close Other
   The EA will execute the following pseudocode:
   if any pending order is filled:
      reset take profit on all market orders
   if any take profit is reached:
      cancel all pending orders
**
**/


#property copyright Hadi Zhang

extern int 

int Slippage = 0;
double pips;
int pendingOrders;
int marketOrders;

/**
  Expert initialization function
**/
int init()
  {
   //Check if automated trading is allowed
   if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
    Alert("EA is no longer allowed to perform automated trades.");
    if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      Alert("Automated trading is forbidden for this EA. Please enable live trading and try again.");
     }
    return 0;
    }
   // Get pips info
   if((MarketInfo(symbol,MODE_DIGITS)==2) || (MarketInfo(symbol,MODE_DIGITS)==3))
     {
      pips=0.01;
     }
   if((MarketInfo(symbol,MODE_DIGITS)==4) || (MarketInfo(symbol,MODE_DIGITS)==5))
     {
      pips=0.0001;
     }
   return 0;
  }

/**
  Expert deinitialization function
**/
int deinit()
  {
  }

/**
  Expert start function 
**/
int start()
  {
   //Check if a pending order was filled
   if 

   //Check if a market order was 
  }

/**
  Cancel all pending orders
**/



/**
  Set all take profits to zero
**/