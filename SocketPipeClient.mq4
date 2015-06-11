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
    RequestType_MAX;
};   

string gRequestNameArr[RequestType_MAX]
{
    "None",
    "RequestType_Test",
    "RequestType_SendOrder",
    "RequestType_SendOrder_Result",
    "RequestType_RateByTime",
    "RequestType_RateByTime_Result",
    "RequestType_SymbolNameList",
    "RequestType_SymbolNameList_Result",
    "RequestType_MAX",
}


#import "SocketPipeClientDLL.dll"
	int InitSocket();
 	int CloseSocket();
	int GetPacket(int &handle);
	int SendPacket(int handle);
    
    // For PacketReader
    int PacketReaderFree(int handle);
	int RequestGetLong(PacketReaderHandle handle, long *output);
	int RequestGetInt(int handle, int &output);
	int RequestGetDouble(int handle, double &output);
	int RequestGetString(int handle, char& pStr, int length);
    
    // For PacketWriter
	int PacketWriterCreate();
	void PacketWriterFree(int handle);
	int PacketWriterSetInt(int handle, int data);
	int PacketWriterSetLong(PacketWriterHandle handle, long data);
	int PacketWriterSetDouble(int handle, double data);
	int PacketWriterSetString(int handle, char &data);

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
    int ret = RequestGetString(handle, str),
    time = StringToTime(str);
    return ret;
}

int PacketWriterSetDatetime(int writeHandle, datetime time)
{
    // Set Time
    char timeArr[D_TIME_STRING_MAX];
    StringToCharArray(TimeToString(time), timeArr, 0);
    return PacketWriterSetString(handle, timeArr);
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
    RequestGetInt(readHandle, req.cmd);
    RequestGetInt(readHandle, req.magicNumber);
}

int CheckOrderIndex(int magicNumber)
{
    int orderNum = OrderTotal();
    for(int i=0; i<orderNum; i++)
    {
      OrderSelect(i, SELECT_BY_POS);
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

void SendOrderRequest(int handle)
{
    SendOrderRequest req;
    GetSendOrderReq(handle, req);
    
    if( CheckOrderIndex(req.magicNumber) >= 0 )
    {
        // Order existed
        int type = OrderType();
        if( (type == OP_BUY && req.cmd == CMD_BUY) ||
            (type == OP_SELL && req.cmd == CMD_SELL) )
        {
            SendOrderRequest(0);
            return ;
        }
        
        // Close order
        double CloseLots = OrderLots();
        double ClosePrice;
        if( type == OP_BUY )
            ClosePrice = Bid;
        else
            ClosePrice = Ask;
        OrderClose(OrderTicket(), CloseLots, ClosePrice, 
            UseSlippage, Black);
    }
    
    if( req.cmd == CMD_BUY )
    {
        double openPrise = Ask;
        OrderSend(req.SymbolName, OP_BUY, LotSize, openPrise,
            UseSlippage, 0, 0, "Buy Order", req.magicNumber, 0, Green);
    }
    else if( req.cmd == CMD_SELL )
    {
        double openPrise = Bid;
        OrderSend(req.SymbolName, OP_SELL, LotSize, openPrise,
            UseSlippage, 0, 0, "Sell Order", req.magicNumber, 0, Red);

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
    RequestGetInt(readHandle, req.timeFrame);
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
        copied = CopyRates(symbolName, timeFrame, startDate, 
            stopDate, rates);
        if(copied>=0)
            break;
        stopDate += oneDayTime;
        if(stopDate > __DATETIME__)
            break;
    }
    int dataLength = MathMin(RATE_INFO_MAX_LENGTH, copied); 
    int writeHandle = PacketWriterCreate();
    for(int i=0; i<dataLength; i++)
    {
        SetRateInfo(writeHandle, rates[i]);
    }

    Print("Get Request: ",symbolName, "T:",req.timeFrame,
        "Count:",dataLength);

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
        GetPacket(readHandle);
        ret = RequestGetInt(readHandle, type);
        if(ret < 0)
        {
            Print("Get error!");
            continue;
        }
        print("Get ", gRequestNameArr[type], "!");
        
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
