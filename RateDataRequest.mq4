//+------------------------------------------------------------------+
//|                                              RateDataRequest.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property library
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
// For SendRateByTimeIndicate
#define D_TIME_STRING_MAX (20)
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

#define D_SYMBOL_NAME_MAX (16)
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

void RateDataRequest() export
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
   int copied=CopyRates(symbolName, timeFrame, startDate, stopDate, rates);
   
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
