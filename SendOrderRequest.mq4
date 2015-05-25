//+------------------------------------------------------------------+
//|                                             SendOrderRequest.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property library
#property strict

#define D_SYMBOL_NAME_MAX (16)
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
