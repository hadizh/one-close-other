/**
      One Close Other
**
**/

#property copyright "Hadi Zhang"

extern int Slippage = 0;
extern int Hedge = 1;
extern int TakeProfit = 1;

class IntList
  {
    private:
      class Node
        {
          public:
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
           head.next = NULL;
           tail = head;
           length = 0;
         }
       void addInt(int value)
         {
           tail.next = new Node;
           tail.next.value = value;
           tail.next.next = NULL;
           tail = tail.next;
           length++;
         }
       bool removeInt(int value)
         {
           Node* prev = head;
           Node* tmp = head;
           while (tmp) 
             {
               if (tmp.value == value) 
                 {
                   if ((prev.next = tmp.next) == NULL) tail = prev;
                   delete tmp;
                   length--;
                   return true;
                  }
                prev = tmp;
                tmp = prev.next;
              }
            return false;                   
         }
       bool hasInt(int value)
         {
           Node* curr = head.next;
           while (curr) 
             {
               if (curr.value == value) return true;
               curr = curr.next;
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
               tmp = prev.next;
               if (tmp) delete prev;
             }
         }
   };


class HashTable
  {
    private:
      int length;
      IntList* arr[];
      
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
          ArrayResize(arr, length);
          for (int i = 0; i < length; i++)
            {
              arr[i] = new IntList();
            }
        }
      void put(int key)
        {
          arr[key % length].addInt(key);          
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
          for (int i = 0; i < length; i++) 
            {
              delete arr[i];
            }
        }
  };
  
double vPoint;
int vSlippage;

int PrevOrders[];
HashTable *ProcessedOrders = new HashTable();

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
  delete ProcessedOrders;
  return 0;
  }

/**
  Expert start function 
**/
int start()
  { 
    //Clean previous orders
    cleanPrevOrders(PrevOrders, ProcessedOrders);     

    int newOrders[];
    ArrayResize(newOrders, OrdersTotal());
    int newOrdersPointer = 0;
    int newTicket;
    
    //Go through all the valid market Orders and set each one to have a "HedgeStop" and TakeProfit
    for (int i = OrdersTotal() - 1; i >= 0; --i)
      {
        if (!OrderSelect(i, SELECT_BY_POS)) continue;
        if (OrderSymbol() != Symbol()) continue;

        //Buy Orders setup (but only for our manually opened orders)
        if (OrderType() == OP_BUY && !ProcessedOrders.get(OrderTicket())) 
          {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble(OrderOpenPrice()+TakeProfit*vPoint, Digits), 0, clrNONE)) continue;
            ProcessedOrders.put(OrderTicket());

            //Create the new pending Hedge Order
            if ((newTicket = OrderSend(Symbol(), OP_SELLSTOP, OrderLots(), NormalizeDouble(OrderOpenPrice() - Hedge*vPoint, Digits), vSlippage, 0, 0, NULL, OrderTicket(), 0, clrNONE)) != -1)
              {
                ProcessedOrders.put(newTicket);
                newOrders[newOrdersPointer] = newTicket;
                newOrdersPointer++;   
              }
          }
        
        //Sell Orders setup (but only for our manually opened orders)
        else if (OrderType() == OP_SELL && !ProcessedOrders.get(OrderTicket())) 
          {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), 0, NormalizeDouble(OrderOpenPrice()-TakeProfit*vPoint, Digits), 0, clrNONE)) continue; 
            ProcessedOrders.put(OrderTicket());

            //Create the new pending Hedge Order
            if ((newTicket = OrderSend(Symbol(), OP_BUYSTOP, OrderLots(), NormalizeDouble(OrderOpenPrice() + Hedge*vPoint, Digits), vSlippage, 0, 0, NULL, OrderTicket(), 0, clrNONE)) != -1)
              {
                ProcessedOrders.put(newTicket);
                newOrders[newOrdersPointer] = newTicket;
                newOrdersPointer++;
              }
          }
        
        //If order was processed, just add it back onto the newOrders array
        else if (ProcessedOrders.get(OrderTicket()))
          {
              newOrders[newOrdersPointer] = newTicket;
              newOrdersPointer++;
          }
      }
    //Copy newOrders into prevOrders
    ArrayResize(PrevOrders, OrdersTotal());
    ArrayCopy(PrevOrders, newOrders, 0, 0, WHOLE_ARRAY);
    return 0;
  }
  
void cleanPrevOrders(int& prevOrders[], HashTable& processedOrders)
  {
    //Try selecting the prevOrder by ticket number, check the close time
    //If the close time is not 0 or the order no longer exists, then it must be gone
    //Delete the order from the processedOrders
    for (int i = 0; i < ArraySize(prevOrders); i++)
      {
       if (!OrderSelect(prevOrders[i], SELECT_BY_TICKET)) continue;
       if (OrderCloseTime() != 0)
         {
           processedOrders.remove(OrderTicket());
         }
      }
  }
/**  
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
 **/
