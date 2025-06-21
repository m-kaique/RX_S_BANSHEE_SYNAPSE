//+------------------------------------------------------------------+
//| PriceActionUtils.mqh - Utilitários para Price Action            |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef PRICE_ACTION_UTILS_H
#define PRICE_ACTION_UTILS_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Classe de Utilitários para Price Action                         |
//+------------------------------------------------------------------+
class CPriceActionUtils
{
public:
    //+------------------------------------------------------------------+
    //| Identificar tipo de barra                                      |
    //+------------------------------------------------------------------+
    static bool IsBullishBar(double open, double close)
    {
        return (close > open);
    }
    
    //+------------------------------------------------------------------+
    //| Identificar barra bearish                                      |
    //+------------------------------------------------------------------+
    static bool IsBearishBar(double open, double close)
    {
        return (close < open);
    }
    
    //+------------------------------------------------------------------+
    //| Identificar doji                                               |
    //+------------------------------------------------------------------+
    static bool IsDoji(double open, double close, double high, double low, string symbol = "")
    {
        if(symbol == "") symbol = Symbol();
        
        double bodySize = MathAbs(close - open);
        double totalRange = high - low;
        
        if(totalRange == 0) return false;
        
        // Doji se corpo é menor que 10% do range total
        return (bodySize / totalRange < 0.1);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular tamanho do corpo da barra                            |
    //+------------------------------------------------------------------+
    static double GetBodySize(double open, double close)
    {
        return MathAbs(close - open);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular tamanho da sombra superior                           |
    //+------------------------------------------------------------------+
    static double GetUpperShadow(double open, double close, double high)
    {
        double bodyTop = MathMax(open, close);
        return high - bodyTop;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular tamanho da sombra inferior                           |
    //+------------------------------------------------------------------+
    static double GetLowerShadow(double open, double close, double low)
    {
        double bodyBottom = MathMin(open, close);
        return bodyBottom - low;
    }
    
    //+------------------------------------------------------------------+
    //| Identificar hammer                                             |
    //+------------------------------------------------------------------+
    static bool IsHammer(double open, double close, double high, double low)
    {
        double bodySize = GetBodySize(open, close);
        double lowerShadow = GetLowerShadow(open, close, low);
        double upperShadow = GetUpperShadow(open, close, high);
        
        // Hammer: sombra inferior longa, corpo pequeno, sombra superior pequena
        return (lowerShadow > bodySize * 2 && upperShadow < bodySize * 0.5);
    }
    
    //+------------------------------------------------------------------+
    //| Identificar shooting star                                      |
    //+------------------------------------------------------------------+
    static bool IsShootingStar(double open, double close, double high, double low)
    {
        double bodySize = GetBodySize(open, close);
        double lowerShadow = GetLowerShadow(open, close, low);
        double upperShadow = GetUpperShadow(open, close, high);
        
        // Shooting Star: sombra superior longa, corpo pequeno, sombra inferior pequena
        return (upperShadow > bodySize * 2 && lowerShadow < bodySize * 0.5);
    }
    
    //+------------------------------------------------------------------+
    //| Identificar engulfing bullish                                 |
    //+------------------------------------------------------------------+
    static bool IsBullishEngulfing(double open1, double close1, double open2, double close2)
    {
        // Primeira barra bearish, segunda barra bullish que engole a primeira
        return (IsBearishBar(open1, close1) && 
                IsBullishBar(open2, close2) &&
                open2 < close1 && 
                close2 > open1);
    }
    
    //+------------------------------------------------------------------+
    //| Identificar engulfing bearish                                 |
    //+------------------------------------------------------------------+
    static bool IsBearishEngulfing(double open1, double close1, double open2, double close2)
    {
        // Primeira barra bullish, segunda barra bearish que engole a primeira
        return (IsBullishBar(open1, close1) && 
                IsBearishBar(open2, close2) &&
                open2 > close1 && 
                close2 < open1);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular força da barra (0-100)                               |
    //+------------------------------------------------------------------+
    static double GetBarStrength(double open, double close, double high, double low, long volume = 0)
    {
        double totalRange = high - low;
        if(totalRange == 0) return 0;
        
        double bodySize = GetBodySize(open, close);
        double bodyRatio = bodySize / totalRange;
        
        // Força baseada no tamanho do corpo em relação ao range
        double strength = bodyRatio * 100;
        
        // Ajustar baseado na direção
        if(IsBullishBar(open, close))
        {
            // Barra bullish: força adicional se fechou próximo da máxima
            double closePosition = (close - low) / totalRange;
            strength *= closePosition;
        }
        else if(IsBearishBar(open, close))
        {
            // Barra bearish: força adicional se fechou próximo da mínima
            double closePosition = (high - close) / totalRange;
            strength *= closePosition;
        }
        
        // Ajustar baseado no volume (se disponível)
        if(volume > 0)
        {
            // Assumir volume médio como referência (simplificado)
            strength *= MathMin(2.0, volume / 1000.0); // Ajuste conforme necessário
        }
        
        return MathMin(100, MathMax(0, strength));
    }
    
    //+------------------------------------------------------------------+
    //| Identificar inside bar                                         |
    //+------------------------------------------------------------------+
    static bool IsInsideBar(double high1, double low1, double high2, double low2)
    {
        // Barra 2 está completamente dentro da barra 1
        return (high2 <= high1 && low2 >= low1);
    }
    
    //+------------------------------------------------------------------+
    //| Identificar outside bar                                        |
    //+------------------------------------------------------------------+
    static bool IsOutsideBar(double high1, double low1, double high2, double low2)
    {
        // Barra 2 engloba completamente a barra 1
        return (high2 > high1 && low2 < low1);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular momentum da barra                                     |
    //+------------------------------------------------------------------+
    static double GetBarMomentum(double open, double close, double high, double low)
    {
        double totalRange = high - low;
        if(totalRange == 0) return 0;
        
        double bodySize = GetBodySize(open, close);
        double momentum = bodySize / totalRange;
        
        // Ajustar sinal baseado na direção
        if(IsBearishBar(open, close))
        {
            momentum = -momentum;
        }
        
        return momentum; // Retorna -1 a +1
    }
    
    //+------------------------------------------------------------------+
    //| Identificar gap                                                |
    //+------------------------------------------------------------------+
    static bool IsGap(double close1, double open2, double tolerance = 0)
    {
        return (MathAbs(open2 - close1) > tolerance);
    }
    
    //+------------------------------------------------------------------+
    //| Identificar gap de alta                                       |
    //+------------------------------------------------------------------+
    static bool IsGapUp(double close1, double open2, double tolerance = 0)
    {
        return (open2 > close1 + tolerance);
    }
    
    //+------------------------------------------------------------------+
    //| Identificar gap de baixa                                      |
    //+------------------------------------------------------------------+
    static bool IsGapDown(double close1, double open2, double tolerance = 0)
    {
        return (open2 < close1 - tolerance);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular pressão compradora/vendedora                         |
    //+------------------------------------------------------------------+
    static double GetBuyingPressure(double open, double close, double high, double low)
    {
        double totalRange = high - low;
        if(totalRange == 0) return 0;
        
        // Pressão compradora baseada na posição do fechamento
        return (close - low) / totalRange; // 0 a 1
    }
    
    //+------------------------------------------------------------------+
    //| Calcular pressão vendedora                                    |
    //+------------------------------------------------------------------+
    static double GetSellingPressure(double open, double close, double high, double low)
    {
        double totalRange = high - low;
        if(totalRange == 0) return 0;
        
        // Pressão vendedora baseada na posição do fechamento
        return (high - close) / totalRange; // 0 a 1
    }
    
    //+------------------------------------------------------------------+
    //| Identificar barra de reversão                                 |
    //+------------------------------------------------------------------+
    static bool IsReversalBar(double open, double close, double high, double low, bool lookingForBullish)
    {
        if(lookingForBullish)
        {
            // Barra de reversão bullish: mínima baixa, fechamento alto
            double lowerShadow = GetLowerShadow(open, close, low);
            double bodySize = GetBodySize(open, close);
            
            return (IsBullishBar(open, close) && lowerShadow > bodySize);
        }
        else
        {
            // Barra de reversão bearish: máxima alta, fechamento baixo
            double upperShadow = GetUpperShadow(open, close, high);
            double bodySize = GetBodySize(open, close);
            
            return (IsBearishBar(open, close) && upperShadow > bodySize);
        }
    }
    
    //+------------------------------------------------------------------+
    //| Calcular volatilidade da barra                                |
    //+------------------------------------------------------------------+
    static double GetBarVolatility(double high, double low, double atr)
    {
        if(atr == 0) return 0;
        
        double barRange = high - low;
        return barRange / atr; // Múltiplo do ATR
    }
    
    //+------------------------------------------------------------------+
    //| Identificar barra de breakout                                 |
    //+------------------------------------------------------------------+
    static bool IsBreakoutBar(double high, double low, double resistanceLevel, double supportLevel, double tolerance)
    {
        // Breakout de resistência
        if(high > resistanceLevel + tolerance)
        {
            return true;
        }
        
        // Breakdown de suporte
        if(low < supportLevel - tolerance)
        {
            return true;
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular eficiência do movimento                              |
    //+------------------------------------------------------------------+
    static double GetMovementEfficiency(const double &close[], int period)
    {
        if(period < 2 || ArraySize(close) < period) return 0;
        
        // Movimento direto (ponto A para ponto B)
        double directMove = MathAbs(close[0] - close[period - 1]);
        
        // Movimento total (soma de todos os movimentos)
        double totalMove = 0;
        for(int i = 0; i < period - 1; i++)
        {
            totalMove += MathAbs(close[i] - close[i + 1]);
        }
        
        if(totalMove == 0) return 0;
        
        // Eficiência = movimento direto / movimento total
        return directMove / totalMove; // 0 a 1
    }
    
    //+------------------------------------------------------------------+
    //| Converter padrão para string                                  |
    //+------------------------------------------------------------------+
    static string PatternToString(bool isHammer, bool isShootingStar, bool isDoji, bool isEngulfing)
    {
        string pattern = "";
        
        if(isHammer) pattern += "Hammer ";
        if(isShootingStar) pattern += "Shooting Star ";
        if(isDoji) pattern += "Doji ";
        if(isEngulfing) pattern += "Engulfing ";
        
        if(pattern == "") pattern = "Nenhum padrão identificado";
        
        return pattern;
    }
    
    //+------------------------------------------------------------------+
    //| Validar sequência de barras                                   |
    //+------------------------------------------------------------------+
    static bool ValidateBarSequence(const double &open[], const double &close[], const double &high[], const double &low[], int count)
    {
        if(ArraySize(open) < count || ArraySize(close) < count || 
           ArraySize(high) < count || ArraySize(low) < count)
        {
            return false;
        }
        
        for(int i = 0; i < count; i++)
        {
            // Verificar consistência dos dados OHLC
            if(high[i] < MathMax(open[i], close[i]) || 
               low[i] > MathMin(open[i], close[i]))
            {
                CCoreUtils::LogError("Dados OHLC inconsistentes no índice " + IntegerToString(i));
                return false;
            }
            
            // Verificar valores válidos
            if(!MathIsValidNumber(open[i]) || !MathIsValidNumber(close[i]) ||
               !MathIsValidNumber(high[i]) || !MathIsValidNumber(low[i]))
            {
                CCoreUtils::LogError("Valores inválidos no índice " + IntegerToString(i));
                return false;
            }
        }
        
        return true;
    }
};

#endif // PRICE_ACTION_UTILS_H

