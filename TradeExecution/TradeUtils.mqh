#ifndef TRADE_UTILS_H
#define TRADE_UTILS_H
#property strict

#include <Trade/Trade.mqh>

class CTradeUtils
{
public:
    static string TradeResultRetcodeDescription(const int retcode)
    {
        switch(retcode)
        {
            case TRADE_RETCODE_REQUOTE:        return "Requote";            
            case TRADE_RETCODE_REJECT:         return "Rejected";
            case TRADE_RETCODE_CANCEL:         return "Canceled";
            case TRADE_RETCODE_PLACED:         return "Order placed";
            case TRADE_RETCODE_DONE:           return "Deal executed";
            case TRADE_RETCODE_DONE_PARTIAL:   return "Partial";
            case TRADE_RETCODE_ERROR:          return "Trade error";
            case TRADE_RETCODE_TIMEOUT:        return "Timeout";
            case TRADE_RETCODE_INVALID:        return "Invalid request";
            case TRADE_RETCODE_INVALID_VOLUME: return "Invalid volume";
            case TRADE_RETCODE_INVALID_PRICE:  return "Invalid price";
            case TRADE_RETCODE_INVALID_STOPS:  return "Invalid stops";
            case TRADE_RETCODE_TRADE_DISABLED: return "Trading disabled";
            case TRADE_RETCODE_MARKET_CLOSED:  return "Market closed";
            case TRADE_RETCODE_NO_MONEY:       return "Not enough money";
            case TRADE_RETCODE_PRICE_CHANGED:  return "Price changed";
            case TRADE_RETCODE_PRICE_OFF:      return "Off quotes";
            case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid expiration";
            case TRADE_RETCODE_ORDER_CHANGED:  return "Order changed";
            case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too many requests";
            case TRADE_RETCODE_NO_CHANGES:     return "No changes";
            case TRADE_RETCODE_SERVER_DISABLES_AT: return "Server disabled";
            case TRADE_RETCODE_CLIENT_DISABLES_AT: return "Client disabled";
            case TRADE_RETCODE_LOCKED:         return "Account locked";
            case TRADE_RETCODE_FROZEN:         return "Account frozen";
            case TRADE_RETCODE_DONE_REMAINDER: return "Remaining closed";
            case TRADE_RETCODE_POSITION_CLOSED: return "Position closed";
            case TRADE_RETCODE_INVALID_CLOSE_VOLUME: return "Invalid close volume";
            case TRADE_RETCODE_CLOSE_ORDER_EXIST: return "Close order exist";
            case TRADE_RETCODE_LIMIT_ORDER:    return "Limit order";
            case TRADE_RETCODE_REJECT_CANCEL:  return "Cancel rejected";
            case TRADE_RETCODE_LONG_ONLY:      return "Long only";
            default:
                return "Unknown retcode(" + IntegerToString(retcode) + ")";
        }
    }
};

#endif // TRADE_UTILS_H
