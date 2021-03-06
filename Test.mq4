//+------------------------------------------------------------------+
//|                                                         Test.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
//---
	int max_bars=TerminalInfoInteger(TERMINAL_MAXBARS);
	datetime first_date=0;
	int bars_count;
	
	string symbol = "USDJPY";
	int time_frame = PERIOD_M1;
	
	bars_count = SeriesInfoInteger(symbol,time_frame,SERIES_BARS_COUNT);
	first_date = (datetime)SeriesInfoInteger(symbol,time_frame,SERIES_FIRSTDATE);
	first_date = (datetime)SeriesInfoInteger(symbol,time_frame,SERIES_LASTBAR_DATE);
	first_date = (datetime)SeriesInfoInteger(symbol,time_frame,SERIES_SERVER_FIRSTDATE);
	
	bars_count = iBars( symbol, time_frame );
	
	bars_count = sizeof(MqlRates);

}
//+------------------------------------------------------------------+
