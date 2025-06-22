#ifndef TRADE_UTILS_H
#define TRADE_UTILS_H
#property strict

#include <Trade/Trade.mqh>

class CTradeUtils
{
public:
    static string TradeResultRetcodeDescription(const int retcode)
    {
        // Defer to the platform-provided description for the error code.
        // This avoids maintaining our own table of trade retcodes that may
        // differ between platform versions.
        return ErrorDescription(retcode);
    }
}; 

#endif // TRADE_UTILS_H
