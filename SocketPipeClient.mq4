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
   RequestType_MAX,
};   

string gRequestNameArr[RequestType_MAX] = 
{
    "None",
    "RequestType_Test",
    "RequestType_SendOrder",
    "RequestType_SendOrder_Result",
    "RequestType_RateByTime",
    "RequestType_RateByTime_Result",
    "RequestType_SymbolNameList",
    "RequestType_SymbolNameList_Result"
};


#import "SocketPipeClientDLL.dll"
	int InitSocket();
 	int CloseSocket();
	int GetPacket(int &handle);
	int SendPacket(int handle);
    
    // For PacketReader
   int PacketReaderFree(int handle);
	int RequestGetLong(int handle, long &output);
	int RequestGetInt(int handle, int &output);
	int RequestGetDouble(int handle, double &output);
	int RequestGetString(int handle, char &pChar[], int length);
    
    // For PacketWriter
	int PacketWriterCreate();
	void PacketWriterFree(int handle);
	int PacketWriterSetInt(int handle, int data);
	int PacketWriterSetLong(int handle, long data);
	int PacketWriterSetDouble(int handle, double data);
	int PacketWriterSetString(int handle, char &pChar[]);

#import

//+------------------------------------------------------------------
//| Common                                       //+------------------------------------------------------------------
#define D_SYMBOL_NAME_MAX (24)
#define D_TIME_STRING_MAX (20)
#define D_STRING_LENGTH_MAX (64)

int RequestGetString(int handle, string &str)
{
    char strArr[D_STRING_LENGTH_MAX];
    int ret = RequestGetString(handle, strArr, D_STRING_LENGTH_MAX);
    str = CharArrayToString(strArr, 0, D_STRING_LENGTH_MAX);
    return ret;
}

int PacketWriterSetString(int writeHandle, string str)
{
    char strArr[D_STRING_LENGTH_MAX];
    StringToCharArray(str, strArr, 0, D_STRING_LENGTH_MAX);
    // Set SymbolName
    return PacketWriterSetString(writeHandle, strArr); 
}


int RequestGetDatetime(int handle, datetime &time)
{
    string str;
    int ret = RequestGetString(handle, str);
    time =  StringToTime(str);
    return ret;
}

int PacketWriterSetDatetime(int writeHandle, datetime time)
{
    // Set Time
    char timeArr[D_TIME_STRING_MAX];
    StringToCharArray(TimeToString(time), timeArr, 0);
    return PacketWriterSetString(writeHandle, timeArr);
}




//+------------------------------------------------------------------
//| RequestType_SendOrder                                       
//+------------------------------------------------------------------
extern double LotSize = 0.01;

enum SendOrderCmd
{
   CMD_NONE = 0,
   CMD_BUY = 1,
   CMD_SELL = 2,
   CMD_CLOSE = 3,
};
struct SendOrderRequest
{
	string symbolName;
	SendOrderCmd cmd;
    int magicNumber;
};

void GetSendOrderReq(int readHandle, SendOrderRequest &req)
{
    RequestGetString(readHandle, req.symbolName);
    
    int cmdValue;
    RequestGetInt(readHandle, cmdValue);
    req.cmd =  (SendOrderCmd)cmdValue;
    
    RequestGetInt(readHandle, req.magicNumber);
}

int CheckOrderIndex(int magicNumber)
{
    int orderNum = OrdersTotal();
    for(int i=0; i<orderNum; i++)
    {
      if( OrderSelect(i, SELECT_BY_POS) == false)
         Print("OrderSelect False!");
      if( OrderMagicNumber() == magicNumber )
        return i;
    }
    
    return -1;
}

void SendOrderResult(int result)
{
    int writeHandle = PacketWriterCreate();
    // Set type
    PacketWriterSetInt(writeHandle, RequestType_SendOrder_Result);
    PacketWriterSetInt(writeHandle, result);
    SendPacket(writeHandle);
    PacketWriterFree(writeHandle);
}

double PipPoint(string symbolName)
{
   int calcDigits = (int)MarketInfo(symbolName, MODE_DIGITS);
   double calcPoint;
   if( calcDigits == 2 || calcDigits == 3) calcPoint = 0.01;
   else if( calcDigits == 4 || calcDigits == 5 ) calcPoint = 0.0001;
   else calcPoint = 0.01;
   return calcPoint;
}

int GetSlippage(string symbolName, int slippagePips)
{
   int calcDigits = (int)MarketInfo(symbolName, MODE_DIGITS);
   double calcSlippage = slippagePips;
   if( calcDigits == 3 || calcDigits == 5 ) calcSlippage *= 10;
   return (int)calcSlippage;
}

void SendOrderRequest(int handle)
{
    SendOrderRequest req;
    GetSendOrderReq(handle, req);
    int UseSlippage = 5;
    
    UseSlippage = GetSlippage(req.symbolName, UseSlippage);
    double ask = MarketInfo(req.symbolName, MODE_ASK);
    double bid = MarketInfo(req.symbolName, MODE_BID);
    double vpoint = MarketInfo(req.symbolName, MODE_POINT);
    int vdigits = (int)MarketInfo(req.symbolName, MODE_DIGITS);
    int vspread = (int)MarketInfo(req.symbolName, MODE_SPREAD);
    
    if( CheckOrderIndex(req.magicNumber) >= 0 )
    {
        // Order existed
        int type = OrderType();
        if( (type == OP_BUY && req.cmd == CMD_BUY) ||
            (type == OP_SELL && req.cmd == CMD_SELL) )
        {
            SendOrderResult(0);
            return ;
        }
        
        // Close order
        double CloseLots = OrderLots();
        double ClosePrice;
        if( type == OP_BUY )
            ClosePrice = ask;
        else
            ClosePrice = bid;
        if( OrderClose(OrderTicket(), CloseLots, ClosePrice, 
            UseSlippage, Black) == false)
         {
            int err = GetLastError();
            Print("OrderClose False! " + IntegerToString(err) );
         }

    }
    
    if( req.cmd == CMD_BUY )
    {
        double openPrise = ask;
        if( OrderSend(req.symbolName, OP_BUY, LotSize, openPrise,
            UseSlippage, 0, 0, IntegerToString(req.magicNumber) + ": Buy " + req.symbolName, req.magicNumber, 0, Green) < 0 )
            Print("OrderSend error!");
    }
    else if( req.cmd == CMD_SELL )
    {
        double openPrise = bid;
        if( OrderSend(req.symbolName, OP_SELL, LotSize, openPrise,
            UseSlippage, 0, 0, IntegerToString(req.magicNumber) + ": Sell " + req.symbolName, req.magicNumber, 0, Red) < 0 )
            Print("OrderSend error!");
    }
    
    SendOrderResult(0);
    return;
}

//+------------------------------------------------------------------
//| RequestType_RateByTime                                       
//+------------------------------------------------------------------
struct RatesByTimeRequest
{
	string symbolName;
	ENUM_TIMEFRAMES timeFrame;
	datetime startTime;
	datetime stopTime;
};

void GetRatesByTimeReq(int readHandle, RatesByTimeRequest &req)
{
    RequestGetString(readHandle, req.symbolName);
    int intValue;
    RequestGetInt(readHandle, intValue);
    req.timeFrame = (ENUM_TIMEFRAMES)intValue;
    RequestGetDatetime(readHandle, req.startTime);
    RequestGetDatetime(readHandle, req.stopTime);
}

void SetRateInfo(int handle, MqlRates &info)
{
    PacketWriterSetDatetime(handle, info.time);
    PacketWriterSetDouble(handle, info.open);
    PacketWriterSetDouble(handle, info.close);
    PacketWriterSetDouble(handle, info.high);
    PacketWriterSetDouble(handle, info.low);
    PacketWriterSetLong(handle, info.tick_volume);
    PacketWriterSetLong(handle, info.real_volume);
    PacketWriterSetInt(handle, info.spread);
}


void RateDataRequest(int handle)
{
#define RATE_INFO_MAX_LENGTH 1024
    RatesByTimeRequest req;
    GetRatesByTimeReq(handle, req);
    
    MqlRates rates[];
    ArraySetAsSeries(rates,false);
    int copied = -1;
    datetime oneDayTime = 3600*24;
    while(true)
    {
        copied = CopyRates(req.symbolName, req.timeFrame, req.startTime, 
            req.stopTime, rates);
        if(copied>=0)
            break;
        req.stopTime += oneDayTime;
        if(req.stopTime > __DATETIME__)
            break;
    }
    int dataLength = MathMin(RATE_INFO_MAX_LENGTH, copied); 
    int writeHandle = PacketWriterCreate();
    // Set type
    PacketWriterSetInt(writeHandle, RequestType_RateByTime_Result);
    PacketWriterSetInt(writeHandle, dataLength);
    for(int i=0; i<dataLength; i++)
    {
        SetRateInfo(writeHandle, rates[i]);
    }

    // Print("Get Request: ",req.symbolName, "T:",req.timeFrame,
    //     "Count:",dataLength);

    SendPacket(writeHandle);
    PacketWriterFree(writeHandle);
}




//+------------------------------------------------------------------
//| RequestType_SymbolNameList                                       
//+------------------------------------------------------------------
void SymbolNameListRequest(int handle)
{
   int writeHandle = PacketWriterCreate();
  
   // Set type
   PacketWriterSetInt(writeHandle, RequestType_SymbolNameList_Result);

   int symNum = SymbolsTotal(false);
   // Set count
   PacketWriterSetInt(writeHandle, symNum);
   Print("Total number of symbol: ",symNum);
   
   for(int i=0; i<symNum; i++)
   {
      string symName = SymbolName(i, false);
      PacketWriterSetString(writeHandle, symName);
      Print(i,": ",symName);
   }
   
   SendPacket(writeHandle);
   PacketWriterFree(writeHandle);
}


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    //---
    int i=0;
    int readHandle, type, ret;

    InitSocket();
    while(1)
    {
        RefreshRates();
        ret = GetPacket(readHandle);
        if( readHandle != 0 )
        {
           RequestGetInt(readHandle, type);
           Print("Get ", gRequestNameArr[type], "!");
           if(type == RequestType_RateByTime)
           {
               RateDataRequest(readHandle);
           }
           else if(type == RequestType_SymbolNameList)
           {
               SymbolNameListRequest(readHandle);
           }
           else if(type == RequestType_SendOrder)
           {
               SendOrderRequest(readHandle);
           }
           else if(type != 0)
           {
               Print("*** Get Request!", type);
      
           }
           PacketReaderFree(readHandle);
        }
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
