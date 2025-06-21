//+------------------------------------------------------------------+
//| CoreUtils.mqh - Utilitários e Funções Auxiliares               |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef CORE_UTILS_H
#define CORE_UTILS_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"

//+------------------------------------------------------------------+
//| Classe de Utilitários Core                                      |
//+------------------------------------------------------------------+
class CCoreUtils
{
public:
    // Nível atual de log
    static int m_logLevel;

    // Definir nível de log
    static void SetLogLevel(int level)
    {
        m_logLevel = level;
    }

    // Obter nível de log
    static int GetLogLevel()
    {
        return m_logLevel;
    }
    //+------------------------------------------------------------------+
    //| Converter pontos para preço                                     |
    //+------------------------------------------------------------------+
    static double PointsToPrice(double points, string symbol = "")
    {
        if(symbol == "") symbol = Symbol();
        
        double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
        return points * pointValue;
    }
    
    //+------------------------------------------------------------------+
    //| Converter preço para pontos                                     |
    //+------------------------------------------------------------------+
    static double PriceToPoints(double price, string symbol = "")
    {
        if(symbol == "") symbol = Symbol();
        
        double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
        if(pointValue > 0)
            return price / pointValue;
        
        return 0;
    }
    
    //+------------------------------------------------------------------+
    //| Normalizar preço conforme especificações do símbolo            |
    //+------------------------------------------------------------------+
    static double NormalizePrice(double price, string symbol = "")
    {
        if(symbol == "") symbol = Symbol();
        
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        return NormalizeDouble(price, digits);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se está em horário de alta liquidez                  |
    //+------------------------------------------------------------------+
    static bool IsHighLiquidityTime(datetime time = 0)
    {
        if(time == 0) time = TimeCurrent();
        
        MqlDateTime dt;
        TimeToStruct(time, dt);
        
        // Verificar se está entre 10h e 16h
        return (dt.hour >= LIQUIDITY_START && dt.hour < LIQUIDITY_END);
    }

    //+------------------------------------------------------------------+
    //| Alias para compatibilidade - horário de alta liquidez          |
    //+------------------------------------------------------------------+
    static bool IsLiquidityHours(datetime time = 0)
    {
        return IsHighLiquidityTime(time);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se está em horário de negociação                     |
    //+------------------------------------------------------------------+
    static bool IsMarketHours(datetime time = 0)
    {
        if(time == 0) time = TimeCurrent();
        
        MqlDateTime dt;
        TimeToStruct(time, dt);
        
        // Verificar se está entre 9h e 17h (horário de negociação WINM25)
        return (dt.hour >= MARKET_OPEN_HOUR && dt.hour < MARKET_CLOSE_HOUR);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular distância entre dois preços em pontos                 |
    //+------------------------------------------------------------------+
    static double CalculateDistance(double price1, double price2, string symbol = "")
    {
        if(symbol == "") symbol = Symbol();
        
        double distance = MathAbs(price1 - price2);
        return PriceToPoints(distance, symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está dentro de tolerância                   |
    //+------------------------------------------------------------------+
    static bool IsPriceWithinTolerance(double price, double targetPrice, double tolerancePoints, string symbol = "")
    {
        double distance = CalculateDistance(price, targetPrice, symbol);
        return (distance <= tolerancePoints);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular inclinação entre dois pontos                          |
    //+------------------------------------------------------------------+
    static double CalculateSlope(datetime time1, double price1, datetime time2, double price2)
    {
        if(time2 == time1) return 0;
        
        double timeDiff = (double)(time2 - time1);
        double priceDiff = price2 - price1;
        
        return priceDiff / timeDiff;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular preço em linha baseado na inclinação                  |
    //+------------------------------------------------------------------+
    static double CalculateLinePrice(datetime baseTime, double basePrice, double slope, datetime targetTime)
    {
        double timeDiff = (double)(targetTime - baseTime);
        return basePrice + (slope * timeDiff);
    }
    
    //+------------------------------------------------------------------+
    //| Encontrar máxima local em array                                |
    //+------------------------------------------------------------------+
    static int FindLocalMaximum(const double &array[], int start, int end, int minDistance = 3)
    {
        if(start < 0 || end >= ArraySize(array) || start >= end)
            return -1;
        
        int maxIndex = -1;
        double maxValue = -DBL_MAX;
        
        for(int i = start + minDistance; i <= end - minDistance; i++)
        {
            bool isLocalMax = true;
            
            // Verificar se é máximo local
            for(int j = i - minDistance; j <= i + minDistance; j++)
            {
                if(j != i && array[j] >= array[i])
                {
                    isLocalMax = false;
                    break;
                }
            }
            
            if(isLocalMax && array[i] > maxValue)
            {
                maxValue = array[i];
                maxIndex = i;
            }
        }
        
        return maxIndex;
    }
    
    //+------------------------------------------------------------------+
    //| Encontrar mínima local em array                                |
    //+------------------------------------------------------------------+
    static int FindLocalMinimum(const double &array[], int start, int end, int minDistance = 3)
    {
        if(start < 0 || end >= ArraySize(array) || start >= end)
            return -1;
        
        int minIndex = -1;
        double minValue = DBL_MAX;
        
        for(int i = start + minDistance; i <= end - minDistance; i++)
        {
            bool isLocalMin = true;
            
            // Verificar se é mínimo local
            for(int j = i - minDistance; j <= i + minDistance; j++)
            {
                if(j != i && array[j] <= array[i])
                {
                    isLocalMin = false;
                    break;
                }
            }
            
            if(isLocalMin && array[i] < minValue)
            {
                minValue = array[i];
                minIndex = i;
            }
        }
        
        return minIndex;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular ATR (Average True Range)                              |
    //+------------------------------------------------------------------+
    static double CalculateATR(const double &high[], const double &low[], const double &close[], int period, int start = 0)
    {
        if(ArraySize(high) < period + start + 1 || 
           ArraySize(low) < period + start + 1 || 
           ArraySize(close) < period + start + 1)
            return 0;
        
        double atr = 0;
        
        for(int i = start; i < start + period; i++)
        {
            double tr1 = high[i] - low[i];
            double tr2 = (i > 0) ? MathAbs(high[i] - close[i+1]) : tr1;
            double tr3 = (i > 0) ? MathAbs(low[i] - close[i+1]) : tr1;
            
            double trueRange = MathMax(tr1, MathMax(tr2, tr3));
            atr += trueRange;
        }
        
        return atr / period;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se movimento é um spike                              |
    //+------------------------------------------------------------------+
    static bool IsSpike(const double &high[], const double &low[], const double &close[], int index, double atrMultiplier = SPIKE_ATR_MULTIPLIER)
    {
        if(index < SPIKE_MAX_BARS || index >= ArraySize(high) - 1)
            return false;
        
        // Calcular ATR das últimas 20 barras
        double atr = CalculateATR(high, low, close, 20, index - 20);
        if(atr <= 0) return false;
        
        // Verificar amplitude do movimento
        double moveRange = 0;
        for(int i = index - SPIKE_MAX_BARS; i <= index; i++)
        {
            moveRange = MathMax(moveRange, high[i] - low[i]);
        }
        
        // Spike se amplitude > ATR * multiplicador
        return (moveRange > atr * atrMultiplier);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular correlação entre dois arrays                          |
    //+------------------------------------------------------------------+
    static double CalculateCorrelation(const double &array1[], const double &array2[], int period)
    {
        if(ArraySize(array1) < period || ArraySize(array2) < period)
            return 0;
        
        // Calcular médias
        double mean1 = 0, mean2 = 0;
        for(int i = 0; i < period; i++)
        {
            mean1 += array1[i];
            mean2 += array2[i];
        }
        mean1 /= period;
        mean2 /= period;
        
        // Calcular correlação
        double numerator = 0, denominator1 = 0, denominator2 = 0;
        
        for(int i = 0; i < period; i++)
        {
            double diff1 = array1[i] - mean1;
            double diff2 = array2[i] - mean2;
            
            numerator += diff1 * diff2;
            denominator1 += diff1 * diff1;
            denominator2 += diff2 * diff2;
        }
        
        double denominator = MathSqrt(denominator1 * denominator2);
        if(denominator == 0) return 0;
        
        return numerator / denominator;
    }
    
    //+------------------------------------------------------------------+
    //| Converter enum para string                                      |
    //+------------------------------------------------------------------+
    static string TrendDirectionToString(ENUM_TREND_DIRECTION trend)
    {
        switch(trend)
        {
            case TREND_UP:      return "ALTA";
            case TREND_DOWN:    return "BAIXA";
            case TREND_NEUTRAL: return "NEUTRO";
            default:            return "DESCONHECIDO";
        }
    }
    
    //+------------------------------------------------------------------+
    //| Converter enum para string                                      |
    //+------------------------------------------------------------------+
    static string SignalTypeToString(ENUM_SIGNAL_TYPE signal)
    {
        switch(signal)
        {
            case SIGNAL_BUY:  return "COMPRA";
            case SIGNAL_SELL: return "VENDA";
            case SIGNAL_NONE: return "NENHUM";
            default:          return "DESCONHECIDO";
        }
    }
    
    //+------------------------------------------------------------------+
    //| Log com timestamp                                               |
    //+------------------------------------------------------------------+
    static void LogInfo(string message)
    {
        if(m_logLevel <= LOG_LEVEL_INFO && DEBUG_MODE)
        {
            Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), " [INFO] ", message);
        }
    }
    
    //+------------------------------------------------------------------+
    //| Log de warning                                                  |
    //+------------------------------------------------------------------+
    static void LogWarning(string message)
    {
        if(m_logLevel <= LOG_LEVEL_WARNING)
        {
            Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), " [WARNING] ", message);
        }
    }
    
    //+------------------------------------------------------------------+
    //| Log de erro                                                     |
    //+------------------------------------------------------------------+
    static void LogError(string message)
    {
        if(m_logLevel <= LOG_LEVEL_ERROR)
        {
            Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), " [ERROR] ", message);
        }
    }
    
    //+------------------------------------------------------------------+
    //| Validar dados de array                                         |
    //+------------------------------------------------------------------+
    static bool ValidateArrayData(const double &array[], int minSize = 1)
    {
        if(ArraySize(array) < minSize)
        {
            LogError("Array muito pequeno. Tamanho: " + IntegerToString(ArraySize(array)) + ", Mínimo: " + IntegerToString(minSize));
            return false;
        }
        
        // Verificar valores inválidos
        for(int i = 0; i < ArraySize(array); i++)
        {
            if(array[i] == EMPTY_VALUE || !MathIsValidNumber(array[i]))
            {
                LogError("Valor inválido encontrado no array no índice: " + IntegerToString(i));
                return false;
            }
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular percentual de mudança                                 |
    //+------------------------------------------------------------------+
    static double CalculatePercentChange(double oldValue, double newValue)
    {
        if(oldValue == 0) return 0;

        return ((newValue - oldValue) / oldValue) * 100.0;
    }

    //+------------------------------------------------------------------+
    //| Aguarda até que exista um mínimo de barras no timeframe        |
    //+------------------------------------------------------------------+
    static bool WaitForMinimumBars(string symbol, ENUM_TIMEFRAMES timeframe,
                                   int minBars, int timeoutSeconds = 30)
    {
        datetime startTime = TimeCurrent();

        while(Bars(symbol, timeframe) < minBars)
        {
            Print("Aguardando histórico ", EnumToString(timeframe), ": ",
                  Bars(symbol, timeframe), "/", minBars);

            Sleep(1000);
            RefreshRates();

            if(TimeCurrent() - startTime > timeoutSeconds)
            {
                LogError("Timeout ao aguardar histórico de barras");
                return false;
            }
        }

        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se valor está em range                               |
    //+------------------------------------------------------------------+
    static bool IsValueInRange(double value, double min, double max)
    {
        return (value >= min && value <= max);
    }
};

// Inicialização do nível de log
int CCoreUtils::m_logLevel = LOG_LEVEL_INFO;

#endif // CORE_UTILS_H

