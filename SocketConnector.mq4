//+------------------------------------------------------------------+
//|                                              SocketConnector.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

enum RequestType
{
	RequestType_None = 0,
	RequestType_Test,
	RequestType_SendOrder,
	RequestType_RateByTime,
	RequestType_RateByTime_Indicate,
};   
#import "TradeAgentClientDLL.dll"
   int InitSocket();
   int CloseSocket();
   int GetType(int &type);
#import

#import "RateDataRequest.ex4"
   void RateDataRequest();
#import

#define IP_ADDRESS ("127.0.0.1")
#define IP_PORT (9000)

int gConnHandle;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
//---
   int i=0;
   int type;

   InitSocket();
   while(1)
   {
      GetType(type);
      if(type < 0)
      {
         Print("Get error!");
      }
      else if(type == RequestType_RateByTime)
      {
         RateDataRequest();
      }
      else if(type != 0)
      {
         Print("*** Get Request!", type);

      }
      // Print("Wait 1000ms");
      Sleep(1000);
   }
}
  
  
void OnTick()
{


}

void OnDeinit(const int reason)
{
   // CloseConnection(gConnHandle);
   // CloseSocket();
}


//+------------------------------------------------------------------+
