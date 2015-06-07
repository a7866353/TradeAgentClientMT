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
	RequestType_SendOrder_Result,
	RequestType_RateByTime,
	RequestType_RateByTime_Result,
	RequestType_SymbolNameList,
	RequestType_SymbolNameList_Result,
};   
#import "TradeAgentClientDLL.dll"
   int InitSocket();
   int CloseSocket();
   int GetType(int &type);
#import


#define IP_ADDRESS ("127.0.0.1")
#define IP_PORT (9000)

int gConnHandle;







//==================================
#define D_SYMBOL_NAME_MAX (24)
#define D_TIME_STRING_MAX (20)

//+------------------------------------------------------------------+
//| RequestType_SendOrder                                       |
//+------------------------------------------------------------------+
struct SendOrderRequest
{
	char symbolName[D_SYMBOL_NAME_MAX];
	char cmd;
};

enum SendOrderCmd
{
   Nothing = 0,
   Buy = 1,
   Sell = 2,
   CloseOrder = 3,
};

#import "TradeAgentClientDLL.dll"
int GetSendOrderReq(SendOrderRequest &req);
#import

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void SendOrderRequest() export
{
   SendOrderRequest req;
   GetSendOrderReq(req);
}
   
   

//+------------------------------------------------------------------+
//| RequestType_RateByTime                                             |
//+------------------------------------------------------------------+
struct RateInfo {
	char time[D_TIME_STRING_MAX];
//	char dummy0[4];
	double open;
	double high;
	double low;
	double close; 
	char isEnd;
//	char dummy1[7];
};

struct RatesByTimeRequest
{
	char symbolName[D_SYMBOL_NAME_MAX];
	int timeFrame;
	char startTime[D_TIME_STRING_MAX];
	char stopTime[D_TIME_STRING_MAX];
};

#import "TradeAgentClientDLL.dll"
   int SendRateByTimeIndicate(RateInfo &info[], int count, char isEnd);
   int GetRateByTimeReq(RatesByTimeRequest &req);
#import

void RateDataRequest()
{
#define RATE_INFO_MAX_LENGTH 1024
   RateInfo rateInfoArr[RATE_INFO_MAX_LENGTH];
   RatesByTimeRequest req;
   GetRateByTimeReq(req);
   
   string symbolName = CharArrayToString(req.symbolName, 0, D_SYMBOL_NAME_MAX);
   ENUM_TIMEFRAMES  timeFrame = req.timeFrame;
   datetime startDate = StringToTime(CharArrayToString(req.startTime,0));         
   datetime stopDate = StringToTime(CharArrayToString(req.stopTime,0));
   
   MqlRates rates[];
   ArraySetAsSeries(rates,false);
   int copied = -1;
   datetime oneDayTime = 3600*24;
   while(true)
   {
      copied = CopyRates(symbolName, timeFrame, startDate, stopDate, rates);
      if(copied>=0)
         break;
      stopDate += oneDayTime;
      if(stopDate > __DATETIME__)
         break;
      
   }
   int dataLength = MathMin(RATE_INFO_MAX_LENGTH, copied); 
   for(int i=0; i<dataLength; i++)
   {
      MqlRates rate = rates[i];
      rateInfoArr[i].high = rate.high;
      rateInfoArr[i].low = rate.low;
      rateInfoArr[i].open = rate.open;
      rateInfoArr[i].close = rate.close;
      StringToCharArray(TimeToString(rate.time), rateInfoArr[i].time, 0);
      // rateInfoArr[i].time =  rate.time;
      rateInfoArr[i].isEnd = 0;
   }
   
   
   Print("Get Request: ",symbolName, "T:",req.timeFrame,"Count:",dataLength);
   
   SendRateByTimeIndicate(rateInfoArr, dataLength,  True);
}




//+------------------------------------------------------------------+
//| RequestType_SymbolNameList                                       |
//+------------------------------------------------------------------+
#define SYMBOL_NAME_LIST_MAX_LENGTH 100

#import "TradeAgentClientDLL.dll"
   int SendSymbolNameListResult(char &symbolArr[], int count);
#import

void SymbolNameListRequest()
{
   char symbolNameListArr[SYMBOL_NAME_LIST_MAX_LENGTH * D_SYMBOL_NAME_MAX];

   int symNum = SymbolsTotal(false);
   Print("Total number of symbol: ",symNum);
   for(int i=0; i<symNum; i++)
   {
      string symName = SymbolName(i, false);
      StringToCharArray(symName, symbolNameListArr, i*D_SYMBOL_NAME_MAX, D_SYMBOL_NAME_MAX);
      Print(i,": ",symName);
   }
   
   SendSymbolNameListResult(symbolNameListArr, symNum);
}


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
      else if(type == RequestType_SymbolNameList)
      {
         SymbolNameListRequest();
      }
      else if(type != 0)
      {
         Print("*** Get Request!", type);

      }
      // Print("Wait 1000ms");
      Sleep(1);
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
