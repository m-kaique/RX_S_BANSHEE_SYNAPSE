#ifndef TRADE_UTILS_H
#define TRADE_UTILS_H
#property strict

//+------------------------------------------------------------------+
//| Helper class for translating trade return codes into readable    |
//| messages. The standard MQL5 headers are not available in this    |
//| environment, so we map the most common codes manually.            |
//+------------------------------------------------------------------+
class CTradeUtils
{
public:
    static string TradeResultRetcodeDescription(const int retcode)
    {
        switch(retcode)
        {
            case 10004: return "Requote";
            case 10006: return "Order rejected";
            case 10007: return "Order canceled";
            case 10008: return "Order placed";
            case 10009: return "Deal completed";
            case 10010: return "Partial done";
            case 10011: return "Request error";
            case 10012: return "Request timeout";
            case 10013: return "Invalid request";
            case 10014: return "Invalid volume";
            case 10016: return "Invalid price";
            case 10017: return "Invalid stops";
            case 10018: return "Trade disabled";
            case 10019: return "Market closed";
            case 10020: return "Not enough money";
            case 10021: return "Price changed";
            case 10022: return "Off quotes";
            case 10023: return "Invalid expiration";
            case 10024: return "Order changed";
            case 10025: return "Too many requests";
            case 10026: return "No changes";
            case 10027: return "Server disabled";
            case 10028: return "Client disabled";
            case 10029: return "Locked";
            case 10030: return "Frozen";
            case 10031: return "Invalid fill";
            case 10032: return "Connection problems";
            case 10033: return "Only real accounts";
            case 10034: return "Only demo accounts";
            case 10035: return "Close only";
            case 10036: return "Limit positions";
            default:
                return "Unknown error";
        }
    }
};

#endif // TRADE_UTILS_H
