#ifndef TRADE_UTILS_H
#define TRADE_UTILS_H
#property strict

#include <Trade/Trade.mqh>

class CTradeUtils
{
public:
    static string TradeResultRetcodeDescription(const int retcode)
    {
        // Convert the return code to its enumeration name. This provides a
        // human readable message without relying on optional standard
        // library files that may not be present in the runtime environment.
        return EnumToString((ENUM_TRADE_RETURN_CODE)retcode);
    }
}; 

#endif // TRADE_UTILS_H
