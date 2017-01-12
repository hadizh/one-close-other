/**
      One Close Other
**
**/

#property copyright "Hadi Zhang"

extern int Slippage = 0;
extern int Hedge = 1;
extern int TakeProfit = 1;

double vPoint;
int vSlippage;
int HedgeOrders[];

class IntList
  {
    private:
      struct Node
        {
          int value;
          Node* next;
        };
      Node* head;
      Node* tail;
      int length;
      
    public:
       IntList()
         {
           head = new Node;
           head->next = NULL;
           tail = head;
           length = 0;
         }
       void addInt(int value)
         {
           tail->next = new Node;
           tail->next->value = value;
           tail->next->next = NULL;
           tail = tail->next;
           length++;
         }
       bool removeInt(int value)
         {
           Node* prev = head;
           Node* tmp = head;
           while (tmp) 
             {
               if (tmp->value == value) 
                 {
                   if ((prev->next = tmp->next) == NULL) tail = prev;
                   delete tmp;
                   length--;
                   return true;
                  }
                prev = tmp;
                tmp = prev->next;
              }
            return false;                   
         }
       bool hasInt(int value)
         {
           Node* curr = head->next;
           while (curr) 
             {
               if (curr->value == value) return true;
               curr = curr->next;
             }
           return false;
         }
       ~IntList()
         {
           Node* prev = head;
           Node* tmp = head;
           while (tmp) 
             {
               prev = tmp;
               tmp = prev->tmp;
               if (tmp) delete prev;
             }
         }
   };


class HashTable
  {
    private:
      int length;
      IntList* arr;
      
/**
      void resize(int newLength) 
        {
          //Copy old table
          int oldTable[length];
          for (int i = 0; i < length; i++)
            {
              oldTable[i] 
            }
          //Reassign old table to new cells
          arr = new IntList 
        }
**/

    public:
      HashTable() 
        {
          length = 11;
          arr = new IntList[length];
        }
      void put(int key)
        {
          bool retval = arr[key % length].addInt(key);          
          return retval;
        }
      bool remove(int key)
        {
          bool retval = arr[key % length].removeInt(key);
          return retval;
        }
      bool get(int key)
        {
          return arr[key % length].hasInt(key);
        }
      ~HashTable()
        {
          delete[] arr;
        }
  };

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
    cleanHedgeOrders(HedgeOrders);

    int newHedgeOrders[];
    ArrayResize(newHedgeOrders, OrdersTotal());
    int newHedgeOrderPointer = 0;
    bool processed;
    int newTicket;
    
    //Go through all the valid market Orders and set each one to have a "HedgeStop" and TakeProfit
    for (int i = OrdersTotal() - 1; i >= 0; --i)
      {
        if (!OrderSelect(i, SELECT_BY_POS)) continue;
        if (OrderSymbol() != Symbol()) continue;
        processed = checkProcessed(OrderTicket(), 

        //Buy Orders setup (but only for our manually opened orders)
        if (OrderType() == OP_BUY) 
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
        else if (OrderType() == OP_SELL && OrderTakeProfit() == 0 && OrderMagicNumber() == 0) 
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
        else if (OrderMagicNumber() != 0)
          {
            newHedgeOrders[newHedgeOrderPointer] = OrderTicket();
            newHedgeOrderPointer++;
          }
      }
    
    //Copy newHedgeOrders into HedgeOrders
    ArrayResize(HedgeOrders, newHedgeOrderPointer);
    ArrayCopy(HedgeOrders, newHedgeOrders, 0, 0, newHedgeOrderPointer);
    //Print("newHedgeOrders first is ", newHedgeOrders[0]);
    //Print("HedgeOrders first is ", HedgeOrders[0]);
    return 0;
  }
  
void cleanHedgeOrders(int& hedgeOrders[]) 
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
           OrderSelect(OrderMagicNumber(), SELECT_BY_TICKET);
           OrderModify(OrderTicket(), OrderOpenPrice(), 0, 0, 0, clrNONE);
           ExpertRemove();
         }

       if (!OrderSelect(OrderMagicNumber(), SELECT_BY_TICKET)) continue;      
       //If a pending Hedge Order's parent Order was closed, delete the pending Hedge Order
       if (OrderCloseTime() != 0) 
         {
           if (!OrderDelete(currentOrder)) Alert("Pending order #", currentOrder, " needs to be deleted manually!");
         }
     } 
  }
