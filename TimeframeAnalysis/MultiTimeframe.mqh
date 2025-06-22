//+------------------------------------------------------------------+
//| MultiTimeframe.mqh - Análise Multi-Timeframe                    |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef MULTI_TIMEFRAME_H
#define MULTI_TIMEFRAME_H

#include <Object.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"
#include "../Core/TrendAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Classe de Análise Multi-Timeframe                               |
//+------------------------------------------------------------------+
class CMultiTimeframe : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Analisadores por timeframe
    CTrendAnalyzer*      m_analyzerH4;       // Analisador H4
    CTrendAnalyzer*      m_analyzerH1;       // Analisador H1
    CTrendAnalyzer*      m_analyzerM15;      // Analisador M15
    CTrendAnalyzer*      m_analyzerM5;       // Analisador M5
    
    // Resultados por timeframe
    TrendAnalysisResult  m_resultH4;         // Resultado H4
    TrendAnalysisResult  m_resultH1;         // Resultado H1
    TrendAnalysisResult  m_resultM15;        // Resultado M15
    TrendAnalysisResult  m_resultM5;         // Resultado M5
    
    // Análise consolidada
    MultiTimeframeAnalysis m_consolidatedAnalysis;
    
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CMultiTimeframe()
    {
        m_symbol = "";
        
        m_analyzerH4 = NULL;
        m_analyzerH1 = NULL;
        m_analyzerM15 = NULL;
        m_analyzerM5 = NULL;
        
        InitializeTrendResult(m_resultH4);
        InitializeTrendResult(m_resultH1);
        InitializeTrendResult(m_resultM15);
        InitializeTrendResult(m_resultM5);
        
        InitializeConsolidatedAnalysis(m_consolidatedAnalysis);
        
        m_lastUpdate = 0;
        m_initialized = false;
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CMultiTimeframe()
    {
        if(m_analyzerH4 != NULL) delete m_analyzerH4;
        if(m_analyzerH1 != NULL) delete m_analyzerH1;
        if(m_analyzerM15 != NULL) delete m_analyzerM15;
        if(m_analyzerM5 != NULL) delete m_analyzerM5;
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar análise multi-timeframe                            |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para MultiTimeframe");
            return false;
        }
        
        m_symbol = symbol;
        
        // Criar analisadores para cada timeframe
        m_analyzerH4 = new CTrendAnalyzer();
        m_analyzerH1 = new CTrendAnalyzer();
        m_analyzerM15 = new CTrendAnalyzer();
        m_analyzerM5 = new CTrendAnalyzer();
        
        // Inicializar analisadores
        if(!m_analyzerH4.Initialize(symbol) ||
           !m_analyzerH1.Initialize(symbol) ||
           !m_analyzerM15.Initialize(symbol) ||
           !m_analyzerM5.Initialize(symbol))
        {
            CCoreUtils::LogError("Falha ao inicializar analisadores de tendência");
            return false;
        }
        
        m_initialized = true;
        CCoreUtils::LogInfo("MultiTimeframe inicializado com sucesso para " + symbol);
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Executar análise completa multi-timeframe                      |
    //+------------------------------------------------------------------+
    bool AnalyzeAllTimeframes(string symbol = "")
    {
        if(symbol != "") m_symbol = symbol;
        
        if(!m_initialized)
        {
            CCoreUtils::LogError("MultiTimeframe não inicializado");
            return false;
        }
        
        bool allSuccess = true;
        
        // Analisar cada timeframe
        allSuccess &= AnalyzeTimeframe(PERIOD_H4, m_analyzerH4, m_resultH4);
        allSuccess &= AnalyzeTimeframe(PERIOD_H1, m_analyzerH1, m_resultH1);
        allSuccess &= AnalyzeTimeframe(PERIOD_M15, m_analyzerM15, m_resultM15);
        allSuccess &= AnalyzeTimeframe(PERIOD_M5, m_analyzerM5, m_resultM5);
        
        if(!allSuccess)
        {
            CCoreUtils::LogWarning("Algumas análises de timeframe falharam");
        }
        
        // Consolidar análise
        ConsolidateAnalysis();
        
        m_lastUpdate = TimeCurrent();
        
        CCoreUtils::LogInfo("Análise multi-timeframe concluída");
        return allSuccess;
    }
    
    //+------------------------------------------------------------------+
    //| Obter alinhamento entre timeframes                             |
    //+------------------------------------------------------------------+
    ENUM_TIMEFRAME_ALIGNMENT GetTimeframeAlignment()
    {
        if(!m_initialized)
        {
            return TF_NEUTRAL;
        }
        
        // Contar tendências por direção
        int bullishCount = 0;
        int bearishCount = 0;
        int neutralCount = 0;
        
        ENUM_TREND_DIRECTION trends[] = {
            m_resultH4.trendDirection,
            m_resultH1.trendDirection,
            m_resultM15.trendDirection,
            m_resultM5.trendDirection
        };
        
        for(int i = 0; i < 4; i++)
        {
            switch(trends[i])
            {
                case TREND_UP:      bullishCount++; break;
                case TREND_DOWN:    bearishCount++; break;
                case TREND_NEUTRAL: neutralCount++; break;
            }
        }
        
        // Determinar alinhamento
        if(bullishCount >= 3) return TF_BULLISH_STRONG;
        if(bearishCount >= 3) return TF_BEARISH_STRONG;
        if(bullishCount == 2 && bearishCount <= 1) return TF_BULLISH_WEAK;
        if(bearishCount == 2 && bullishCount <= 1) return TF_BEARISH_WEAK;
        
        return TF_NEUTRAL;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar confluência entre timeframes                         |
    //+------------------------------------------------------------------+
    bool HasTimeframeConfluence(ENUM_TREND_DIRECTION direction)
    {
        if(!m_initialized)
        {
            return false;
        }
        
        int confirmingTimeframes = 0;
        
        // Verificar cada timeframe
        if(m_resultH4.trendDirection == direction) confirmingTimeframes++;
        if(m_resultH1.trendDirection == direction) confirmingTimeframes++;
        if(m_resultM15.trendDirection == direction) confirmingTimeframes++;
        if(m_resultM5.trendDirection == direction) confirmingTimeframes++;
        
        // Confluência se 3+ timeframes confirmam
        return (confirmingTimeframes >= 3);
    }
    
    //+------------------------------------------------------------------+
    //| Obter timeframe dominante                                       |
    //+------------------------------------------------------------------+
    ENUM_TIMEFRAMES GetDominantTimeframe()
    {
        if(!m_initialized)
        {
            return PERIOD_CURRENT;
        }
        
        // Priorizar timeframes maiores com tendência definida
        if(m_resultH4.trendDirection != TREND_NEUTRAL && m_resultH4.trendStrength > 60)
        {
            return PERIOD_H4;
        }
        
        if(m_resultH1.trendDirection != TREND_NEUTRAL && m_resultH1.trendStrength > 70)
        {
            return PERIOD_H1;
        }
        
        if(m_resultM15.trendDirection != TREND_NEUTRAL && m_resultM15.trendStrength > 80)
        {
            return PERIOD_M15;
        }
        
        return PERIOD_M5; // Padrão
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se timeframes estão alinhados para entrada           |
    //+------------------------------------------------------------------+
    bool IsAlignedForEntry(ENUM_TREND_DIRECTION entryDirection)
    {
        if(!m_initialized)
        {
            return false;
        }
        
        // H4 deve estar alinhado ou neutro
        if(m_resultH4.trendDirection != TREND_NEUTRAL && 
           m_resultH4.trendDirection != entryDirection)
        {
            return false;
        }
        
        // H1 deve estar alinhado
        if(m_resultH1.trendDirection != entryDirection)
        {
            return false;
        }
        
        // M15 deve estar alinhado
        if(m_resultM15.trendDirection != entryDirection)
        {
            return false;
        }
        
        // M5 pode ser neutro ou alinhado
        if(m_resultM5.trendDirection != TREND_NEUTRAL && 
           m_resultM5.trendDirection != entryDirection)
        {
            return false;
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Obter força consolidada da tendência                           |
    //+------------------------------------------------------------------+
    double GetConsolidatedTrendStrength()
    {
        if(!m_initialized)
        {
            return 0;
        }
        
        // Média ponderada das forças (H4 peso 4, H1 peso 3, M15 peso 2, M5 peso 1)
        double weightedSum = (m_resultH4.trendStrength * 4) +
                            (m_resultH1.trendStrength * 3) +
                            (m_resultM15.trendStrength * 2) +
                            (m_resultM5.trendStrength * 1);
        
        double totalWeight = 4 + 3 + 2 + 1;
        
        return weightedSum / totalWeight;
    }
    
    //+------------------------------------------------------------------+
    //| Obter resultado de timeframe específico                        |
    //+------------------------------------------------------------------+
    TrendAnalysisResult GetTimeframeResult(ENUM_TIMEFRAMES tf)
    {
        TrendAnalysisResult emptyResult;
        InitializeTrendResult(emptyResult);
        
        if(!m_initialized) return emptyResult;
        
        switch(tf)
        {
            case PERIOD_H4:  return m_resultH4;
            case PERIOD_H1:  return m_resultH1;
            case PERIOD_M15: return m_resultM15;
            case PERIOD_M5:  return m_resultM5;
            default:         return emptyResult;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Obter análise consolidada                                      |
    //+------------------------------------------------------------------+
    MultiTimeframeAnalysis GetConsolidatedAnalysis() const
    {
        return m_consolidatedAnalysis;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

private:
    //+------------------------------------------------------------------+
    //| Inicializar resultado de tendência                             |
    //+------------------------------------------------------------------+
    void InitializeTrendResult(TrendAnalysisResult &result)
    {
        result.trendDirection = TREND_NEUTRAL;
        result.trendStrength = 0;
        result.hasSequence = false;
        result.sequenceType = SEQUENCE_NONE;
        result.sequenceStrength = 0;
        result.isValid = false;
        result.lastUpdate = 0;
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar análise consolidada                                |
    //+------------------------------------------------------------------+
    void InitializeConsolidatedAnalysis(MultiTimeframeAnalysis &analysis)
    {
        analysis.overallDirection = TREND_NEUTRAL;
        analysis.overallStrength = 0;
        analysis.alignment = TF_NEUTRAL;
        analysis.dominantTimeframe = PERIOD_CURRENT;
        analysis.confluenceScore = 0;
        analysis.isValid = false;
        analysis.lastUpdate = 0;
    }
    
    //+------------------------------------------------------------------+
    //| Analisar timeframe específico                                  |
    //+------------------------------------------------------------------+
    bool AnalyzeTimeframe(ENUM_TIMEFRAMES tf, CTrendAnalyzer* analyzer, TrendAnalysisResult &result)
    {
        if(analyzer == NULL)
        {
            CCoreUtils::LogError("Analisador nulo para timeframe " + EnumToString(tf));
            return false;
        }

        // Executar análise de tendência
        ENUM_TREND_DIRECTION direction = analyzer.AnalyzeTrend(tf);

        // Preencher resultado utilizando as informações disponíveis no analisador
        result.trendDirection   = direction;
        result.trendStrength    = analyzer.CalculateTrendStrength(tf, direction);
        result.hasSequence      = false;
        result.sequenceType     = SEQUENCE_NONE;
        result.sequenceStrength = 0;
        result.isValid          = true;
        result.lastUpdate       = TimeCurrent();

        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Consolidar análise de todos os timeframes                      |
    //+------------------------------------------------------------------+
    void ConsolidateAnalysis()
    {
        // Determinar direção geral
        m_consolidatedAnalysis.overallDirection = DetermineOverallDirection();
        
        // Calcular força geral
        m_consolidatedAnalysis.overallStrength = GetConsolidatedTrendStrength();
        
        // Determinar alinhamento
        m_consolidatedAnalysis.alignment = GetTimeframeAlignment();
        
        // Determinar timeframe dominante
        m_consolidatedAnalysis.dominantTimeframe = GetDominantTimeframe();
        
        // Calcular score de confluência
        m_consolidatedAnalysis.confluenceScore = CalculateConfluenceScore();
        
        // Marcar como válido
        m_consolidatedAnalysis.isValid = true;
        m_consolidatedAnalysis.lastUpdate = TimeCurrent();
    }
    
    //+------------------------------------------------------------------+
    //| Determinar direção geral                                       |
    //+------------------------------------------------------------------+
    ENUM_TREND_DIRECTION DetermineOverallDirection()
    {
        // Usar voto ponderado (H4 peso 4, H1 peso 3, M15 peso 2, M5 peso 1)
        double bullishScore = 0;
        double bearishScore = 0;
        
        // H4
        if(m_resultH4.trendDirection == TREND_UP) bullishScore += 4;
        else if(m_resultH4.trendDirection == TREND_DOWN) bearishScore += 4;
        
        // H1
        if(m_resultH1.trendDirection == TREND_UP) bullishScore += 3;
        else if(m_resultH1.trendDirection == TREND_DOWN) bearishScore += 3;
        
        // M15
        if(m_resultM15.trendDirection == TREND_UP) bullishScore += 2;
        else if(m_resultM15.trendDirection == TREND_DOWN) bearishScore += 2;
        
        // M5
        if(m_resultM5.trendDirection == TREND_UP) bullishScore += 1;
        else if(m_resultM5.trendDirection == TREND_DOWN) bearishScore += 1;
        
        // Determinar direção
        if(bullishScore > bearishScore + 1) return TREND_UP;
        if(bearishScore > bullishScore + 1) return TREND_DOWN;
        
        return TREND_NEUTRAL;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular score de confluência                                  |
    //+------------------------------------------------------------------+
    double CalculateConfluenceScore()
    {
        double score = 0;
        
        // Pontuação baseada no alinhamento
        ENUM_TIMEFRAME_ALIGNMENT alignment = GetTimeframeAlignment();
        
        switch(alignment)
        {
            case TF_BULLISH_STRONG:
            case TF_BEARISH_STRONG:
                score += 40; // Alinhamento forte
                break;
                
            case TF_BULLISH_WEAK:
            case TF_BEARISH_WEAK:
                score += 25; // Alinhamento fraco
                break;
                
            case TF_NEUTRAL:
                score += 0; // Sem alinhamento
                break;
        }
        
        // Pontuação baseada na força das tendências
        double avgStrength = (m_resultH4.trendStrength + m_resultH1.trendStrength + 
                             m_resultM15.trendStrength + m_resultM5.trendStrength) / 4.0;
        
        score += (avgStrength * 0.6); // Máximo 60 pontos
        
        return MathMin(100, score);
    }
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "MultiTimeframe não inicializado";
        }
        
        string info = "=== ANÁLISE MULTI-TIMEFRAME ===\n";
        
        // Resultados por timeframe
        info += "H4: " + TrendDirectionToString(m_resultH4.trendDirection) + 
                " (" + DoubleToString(m_resultH4.trendStrength, 1) + "%)\n";
        info += "H1: " + TrendDirectionToString(m_resultH1.trendDirection) + 
                " (" + DoubleToString(m_resultH1.trendStrength, 1) + "%)\n";
        info += "M15: " + TrendDirectionToString(m_resultM15.trendDirection) + 
                " (" + DoubleToString(m_resultM15.trendStrength, 1) + "%)\n";
        info += "M5: " + TrendDirectionToString(m_resultM5.trendDirection) + 
                " (" + DoubleToString(m_resultM5.trendStrength, 1) + "%)\n";
        
        // Análise consolidada
        info += "\n--- CONSOLIDADO ---\n";
        info += "Direção geral: " + TrendDirectionToString(m_consolidatedAnalysis.overallDirection) + "\n";
        info += "Força geral: " + DoubleToString(m_consolidatedAnalysis.overallStrength, 1) + "%\n";
        info += "Alinhamento: " + TimeframeAlignmentToString(m_consolidatedAnalysis.alignment) + "\n";
        info += "TF dominante: " + EnumToString(m_consolidatedAnalysis.dominantTimeframe) + "\n";
        info += "Score confluência: " + DoubleToString(m_consolidatedAnalysis.confluenceScore, 1) + "%\n";
        info += "Última atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
    
    //+------------------------------------------------------------------+
    //| Converter direção de tendência para string                     |
    //+------------------------------------------------------------------+
    string TrendDirectionToString(ENUM_TREND_DIRECTION direction)
    {
        switch(direction)
        {
            case TREND_UP:      return "ALTA";
            case TREND_DOWN:    return "BAIXA";
            case TREND_NEUTRAL: return "NEUTRO";
            default:            return "INDEFINIDO";
        }
    }
    
    //+------------------------------------------------------------------+
    //| Converter alinhamento de timeframe para string                 |
    //+------------------------------------------------------------------+
    string TimeframeAlignmentToString(ENUM_TIMEFRAME_ALIGNMENT alignment)
    {
        switch(alignment)
        {
            case TF_BULLISH_STRONG: return "BULLISH FORTE";
            case TF_BULLISH_WEAK:   return "BULLISH FRACO";
            case TF_BEARISH_STRONG: return "BEARISH FORTE";
            case TF_BEARISH_WEAK:   return "BEARISH FRACO";
            case TF_NEUTRAL:        return "NEUTRO";
            default:                return "INDEFINIDO";
        }
    }
};

#endif // MULTI_TIMEFRAME_H

