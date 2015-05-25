//+------------------------------------------------------------------+
//|                                               SymbolNameList.mq4 |
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
void SymbolNameListRequest() export
{
   int symNum = SymbolsTotal(false);
   Print("Total number of symbol: ",symNum);
   for(int i=0; i<symNum; i++)
   {
      string symName = SymbolName(i, false);
      Print(i,": ",symName);
   }
}
//+------------------------------------------------------------------+
