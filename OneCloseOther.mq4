/**
      One Close Other
**
**/


#property copyright "Hadi Zhang"

extern int Slippage = 0;
extern int Hedge = 10;
extern int TakeProfit = 15;

double vPoint;
int vSlippage;
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

   //Setup a virtual Point and Slippage
   if(Digits == 5 || Digits == 3)
     {
      vPoint = Point * 10;
      vSlippage = Slippage * 10;
     } 
   else 
     {
      vPoint = Point;
      vSlippage = Slippage;
     }
 
  return 0;
  }

/**
  Expert deinitialization function
**/
int deinit()
  {
  return 0;
  }

/**
  Expert start function 
**/
int start()
  {
    static int HedgeOrders[];
    
    cleanHedgeOrders(HedgeOrders);

    int newHedgeOrders[];
    ArrayResize(newHedgeOrders, OrdersTotal());
    int newHedgeOrderPointer = 0;
    int newTicket;
    int numberHedgeOrders = 0;
    
    //Go through all the valid market Orders and set each one to have a "HedgeStop" and TakeProfit
    for (int i = OrdersTotal() - 1; i >= 0; --i)
      {
        if (!OrderSelect(i, SELECT_BY_POS)) continue;
        if (OrderSymbol() != Symbol()) continue;

        //Buy Orders setup
        if (OrderType() == OP_BUY && OrderTakeProfit() == 0) 
          {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble(OrderOpenPrice()+TakeProfit*vPoint, Digits), 0, Green)) continue;

            //Create the new pending Hedge Order
            if ((newTicket = OrderSend(Symbol(), OP_SELLSTOP, OrderLots(), NormalizeDouble(Bid - Hedge*vPoint, Digits), vSlippage, 0, 0, NULL, OrderTicket(), 0, clrNONE)) != -1)
              {
                //Add to newHedgeOrders
                newHedgeOrders[newHedgeOrderPointer] = newTicket;
                newHedgeOrderPointer++;                
              }
          }
        
        //Sell Orders setup
        else if (OrderType() == OP_SELL && OrderTakeProfit() == 0) 
          {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble(OrderOpenPrice()-TakeProfit*vPoint, Digits), 0, Red)) continue; 

            //Create the new pending Hedge Order
            if ((newTicket = OrderSend(Symbol(), OP_BUYSTOP, OrderLots(), NormalizeDouble(Bid + Hedge*vPoint, Digits), vSlippage, 0, 0, NULL, OrderTicket(), 0, clrNONE)) != -1)
              {
                //Add to newHedgeOrders
                newHedgeOrders[newHedgeOrderPointer] = newTicket;
                newHedgeOrderPointer++;
              }
          }
        
        //If order has a magic number is not zero, then it must be a hedge order
        else if (OrderMagicNumber() != 0)
          {
            numberHedgeOrders += 1;
          }
      }
    
    //Copy newHedgeOrders into HedgeOrders
    ArrayResize(HedgeOrders, numberHedgeOrders);
    ArrayCopy(HedgeOrders, newHedgeOrders, 0, 0, numberHedgeOrders);
    return 0;
  }
  
void cleanHedgeOrders(int& hedgeOrders[]) 
  {
    //Go through all of the HedgeOrders, check if they merit closing anything
    for (int i = 0; i < ArraySize(hedgeOrders); i++)
     {
       if (!OrderSelect(hedgeOrders[i], SELECT_BY_TICKET)) continue;

       int currentOrder = OrderTicket();
       //If a pending Hedge Order has been filled, 
       if (OrderType() == OP_BUY || OrderType() == OP_SELL) 
         {
           Alert("Hedge order #", currentOrder, " has been filled! The corresponding market order is #", OrderMagicNumber());
         }

       if (!OrderSelect(OrderMagicNumber(), SELECT_BY_TICKET)) continue;      
       //If a pending Hedge Order's parent Order was closed
       if (OrderCloseTime() > 0) 
         {
           if (!OrderDelete(currentOrder)) Alert("Pending order #", currentOrder, " needs to be deleted manually!");
         }
     } 
  }