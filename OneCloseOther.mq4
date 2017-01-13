/**
      One Close Other
**
**/


#property copyright "Hadi Zhang"

extern int Slippage = 0;
extern int Hedge = 10;
extern int TakeProfit = 10;

double vPoint;
int vSlippage;
int HedgeOrders[];
/**
  Expert initialization function
**/
int init()
  {
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
    //Create a halt flag based on whether a pending hedge order was filled   
    bool halt = cleanHedgeOrders(HedgeOrders);

    int newHedgeOrders[];
    ArrayResize(newHedgeOrders, OrdersTotal());
    int newHedgeOrderPointer = 0;
    int newTicket;
    
    //Go through all the valid market Orders and set each one to have a "HedgeStop" and TakeProfit
    for (int i = OrdersTotal() - 1; i >= 0; --i)
      {
        if (!OrderSelect(i, SELECT_BY_POS)) continue;
        if (OrderSymbol() != Symbol()) continue;
        if (halt) continue;

        //Buy Orders setup (but only for our manually opened orders)
        if (OrderType() == OP_BUY && OrderTakeProfit() == 0 && !wasHedgeOrder(HedgeOrders, OrderTicket())) 
          {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble(OrderOpenPrice()+TakeProfit*vPoint, Digits), 0, clrNONE)) continue;

            //Create the new pending Hedge Order
            if ((newTicket = OrderSend(Symbol(), OP_SELLSTOP, OrderLots(), NormalizeDouble(OrderOpenPrice() - Hedge*vPoint, Digits), vSlippage, 0, 0, NULL, OrderTicket(), 0, clrNONE)) != -1)
              {
                //Add to newHedgeOrders
                newHedgeOrders[newHedgeOrderPointer] = newTicket;
                newHedgeOrderPointer++;    
                //Print("newHedgeOrders[0] is ", newHedgeOrders[0]);            
              }
          }
        
        //Sell Orders setup (but only for our manually opened orders)
        else if (OrderType() == OP_SELL && OrderTakeProfit() == 0 && !wasHedgeOrder(HedgeOrders, OrderTicket())) 
          {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble(OrderOpenPrice()-TakeProfit*vPoint, Digits), 0, clrNONE)) continue; 

            //Create the new pending Hedge Order
            if ((newTicket = OrderSend(Symbol(), OP_BUYSTOP, OrderLots(), NormalizeDouble(OrderOpenPrice() + Hedge*vPoint, Digits), vSlippage, 0, 0, NULL, OrderTicket(), 0, clrNONE)) != -1)
              {
                newHedgeOrders[newHedgeOrderPointer] = newTicket;
                newHedgeOrderPointer++;
                //Print("newHedgeOrders[0] is ", newHedgeOrders[0]);
              }
          }
        
        //If order has a magic number is not zero, then it must be a hedge order
        else if (wasHedgeOrder(HedgeOrders, OrderTicket()))
          {
            newHedgeOrders[newHedgeOrderPointer] = OrderTicket();
            newHedgeOrderPointer++;
          }
      }
    
    //Copy newHedgeOrders into HedgeOrders
    ArrayResize(HedgeOrders, newHedgeOrderPointer);
    ArrayCopy(HedgeOrders, newHedgeOrders, 0, 0, newHedgeOrderPointer);
    //Check halt flag for resetting all TakeProfits
    if (halt)
      {
        clearAllTakeProfits();
        ExpertRemove();
      }
    return 0;
  }
  
bool cleanHedgeOrders(int& hedgeOrders[]) 
  {
    //Print("Size of HedgeOrders is ", ArraySize(hedgeOrders));
    //Print("First Hedge Order is  ", hedgeOrders[0]);
    int currentOrder;
    //Go through all of the HedgeOrders, check if they merit closing anything
    for (int i = 0; i < ArraySize(hedgeOrders); i++)
     {
       if (!OrderSelect(hedgeOrders[i], SELECT_BY_TICKET)) continue;

       currentOrder = OrderTicket();
       //If a pending Hedge Order has been filled, reset TP of parent Market Order
       if (OrderType() == OP_BUY || OrderType() == OP_SELL) 
         {
           Alert("Hedge order #", currentOrder, " has been filled! The corresponding market order is #", OrderMagicNumber());
           return true; 
         }

       if (!OrderSelect(OrderMagicNumber(), SELECT_BY_TICKET)) continue;      
       //If a pending Hedge Order's parent Order was closed, delete the pending Hedge Order
       if (OrderCloseTime() != 0) 
         {
           if (!OrderDelete(currentOrder)) Alert("Pending order #", currentOrder, " needs to be deleted manually!");
         }
     } 
     return false;
  }
 
bool wasHedgeOrder(int& hedgeOrders[], int ticket)
  {
    for (int i = 0; i < ArraySize(hedgeOrders); i++)
      {
        if (ticket == hedgeOrders[i]) return true;
      }
      return false;
  }
  
void clearAllTakeProfits() 
  {
    for (int i = OrdersTotal() - 1; i >= 0; --i)
      {
        if (!OrderSelect(i, SELECT_BY_POS)) continue;
        if (OrderType() == OP_BUY || OrderType() == OP_SELL)
          {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), 0, 0, 0, clrNONE)) continue;
          }
      }
  }