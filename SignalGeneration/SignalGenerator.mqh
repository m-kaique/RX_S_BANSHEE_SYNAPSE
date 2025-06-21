//+------------------------------------------------------------------+
//| SignalGenerator.mqh - Gerador de Sinais                         |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef SIGNAL_GENERATOR_H
#define SIGNAL_GENERATOR_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"
#include "../TimeframeAnalysis/MultiTimeframe.mqh"
#include "../TimeframeAnalysis/TimeframeSequencer.mqh"
#include "ConfluenceAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Classe Geradora de Sinais                                       |
//+------------------------------------------------------------------+
class CSignalGenerator : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Componentes de análise
    CMultiTimeframe*     m_multiTimeframe;   // Análise multi-timeframe
    CTimeframeSequencer* m_sequencer;        // Sequenciador
    CConfluenceAnalyzer* m_confluence;       // Analisador de confluência
    
    // Sinais gerados
    TradingSignal        m_currentSignal;    // Sinal atual
    TradingSignal        m_lastSignal;       // Último sinal
    
    // Histórico de sinais
    TradingSignal        m_signalHistory[];  // Histórico
    int                  m_historySize;      // Tamanho do histórico
    
    // Estado do gerador
    datetime             m_lastUpdate;       // Última atualização
    datetime             m_lastSignalTime;   // Último sinal gerado
    bool                 m_initialized;      // Status de inicialização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CSignalGenerator()
    {
        m_symbol = "";
        
        m_multiTimeframe = NULL;
        m_sequencer = NULL;
        m_confluence = NULL;
        
        InitializeSignal(m_currentSignal);
        InitializeSignal(m_lastSignal);
        
        m_historySize = 0;
        ArrayResize(m_signalHistory, MAX_SIGNAL_HISTORY);
        
        m_lastUpdate = 0;
        m_lastSignalTime = 0;
        m_initialized = false;
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CSignalGenerator()
    {
        if(m_multiTimeframe != NULL) delete m_multiTimeframe;
        if(m_sequencer != NULL) delete m_sequencer;
        if(m_confluence != NULL) delete m_confluence;
        
        ArrayFree(m_signalHistory);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar gerador de sinais                                  |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para SignalGenerator");
            return false;
        }
        
        m_symbol = symbol;
        
        // Criar componentes de análise
        m_multiTimeframe = new CMultiTimeframe();
        m_sequencer = new CTimeframeSequencer();
        m_confluence = new CConfluenceAnalyzer();
        
        // Inicializar componentes
        if(!m_multiTimeframe.Initialize(symbol))
        {
            CCoreUtils::LogError("Falha ao inicializar MultiTimeframe");
            return false;
        }
        
        if(!m_sequencer.Initialize(symbol))
        {
            CCoreUtils::LogError("Falha ao inicializar TimeframeSequencer");
            return false;
        }
        
        if(!m_confluence.Initialize(symbol))
        {
            CCoreUtils::LogError("Falha ao inicializar ConfluenceAnalyzer");
            return false;
        }
        
        m_initialized = true;
        CCoreUtils::LogInfo("SignalGenerator inicializado com sucesso para " + symbol);
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Gerar sinal de trading                                         |
    //+------------------------------------------------------------------+
    bool GenerateSignal(string symbol = "")
    {
        if(symbol != "") m_symbol = symbol;
        
        if(!m_initialized)
        {
            CCoreUtils::LogError("SignalGenerator não inicializado");
            return false;
        }
        
        // Verificar se é hora de gerar novo sinal
        if(!ShouldGenerateNewSignal())
        {
            return false;
        }
        
        // Salvar sinal anterior
        m_lastSignal = m_currentSignal;
        
        // Resetar sinal atual
        InitializeSignal(m_currentSignal);
        m_currentSignal.symbol = m_symbol;
        m_currentSignal.timestamp = TimeCurrent();
        
        // Executar análise multi-timeframe
        if(!m_multiTimeframe.AnalyzeAllTimeframes(m_symbol))
        {
            CCoreUtils::LogWarning("Falha na análise multi-timeframe");
            return false;
        }
        
        // Obter resultados dos timeframes
        TrendAnalysisResult resultH4 = m_multiTimeframe.GetTimeframeResult(PERIOD_H4);
        TrendAnalysisResult resultH1 = m_multiTimeframe.GetTimeframeResult(PERIOD_H1);
        TrendAnalysisResult resultM15 = m_multiTimeframe.GetTimeframeResult(PERIOD_M15);
        TrendAnalysisResult resultM5 = m_multiTimeframe.GetTimeframeResult(PERIOD_M5);
        
        // Executar sequência de timeframes
        if(!m_sequencer.ExecuteSequence(resultH4, resultH1, resultM15, resultM5))
        {
            CCoreUtils::LogWarning("Falha na execução da sequência");
            return false;
        }
        
        // Analisar confluência
        if(!m_confluence.AnalyzeConfluence(m_symbol))
        {
            CCoreUtils::LogWarning("Falha na análise de confluência");
            return false;
        }
        
        // Gerar sinal baseado nas análises
        bool signalGenerated = GenerateSignalFromAnalysis();
        
        if(signalGenerated)
        {
            // Adicionar ao histórico
            AddToHistory(m_currentSignal);
            m_lastSignalTime = TimeCurrent();
            
            CCoreUtils::LogInfo("Sinal gerado: " + EnumToString(m_currentSignal.type) + 
                              " - Força: " + DoubleToString(m_currentSignal.strength, 1) + "%");
        }
        
        m_lastUpdate = TimeCurrent();
        
        return signalGenerated;
    }
    
    //+------------------------------------------------------------------+
    //| Obter sinal atual                                              |
    //+------------------------------------------------------------------+
    TradingSignal GetCurrentSignal() const { return m_currentSignal; }
    
    //+------------------------------------------------------------------+
    //| Obter último sinal                                             |
    //+------------------------------------------------------------------+
    TradingSignal GetLastSignal() const { return m_lastSignal; }
    
    //+------------------------------------------------------------------+
    //| Verificar se há sinal válido                                   |
    //+------------------------------------------------------------------+
    bool HasValidSignal() const
    {
        return (m_currentSignal.isValid && m_currentSignal.type != SIGNAL_NONE);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se sinal é para compra                               |
    //+------------------------------------------------------------------+
    bool IsBuySignal() const
    {
        return (m_currentSignal.isValid && m_currentSignal.type == SIGNAL_BUY);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se sinal é para venda                                |
    //+------------------------------------------------------------------+
    bool IsSellSignal() const
    {
        return (m_currentSignal.isValid && m_currentSignal.type == SIGNAL_SELL);
    }
    
    //+------------------------------------------------------------------+
    //| Obter força do sinal atual                                     |
    //+------------------------------------------------------------------+
    double GetSignalStrength() const
    {
        return m_currentSignal.isValid ? m_currentSignal.strength : 0;
    }
    
    //+------------------------------------------------------------------+
    //| Obter confluência do sinal atual                               |
    //+------------------------------------------------------------------+
    double GetSignalConfluence() const
    {
        return m_currentSignal.isValid ? m_currentSignal.confluence : 0;
    }
    
    //+------------------------------------------------------------------+
    //| Obter histórico de sinais                                      |
    //+------------------------------------------------------------------+
    int GetSignalHistory(TradingSignal &history[])
    {
        if(m_historySize == 0) return 0;
        
        ArrayResize(history, m_historySize);
        
        for(int i = 0; i < m_historySize; i++)
        {
            history[i] = m_signalHistory[i];
        }
        
        return m_historySize;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

private:
    //+------------------------------------------------------------------+
    //| Inicializar estrutura de sinal                                 |
    //+------------------------------------------------------------------+
    void InitializeSignal(TradingSignal &signal)
    {
        signal.type = SIGNAL_NONE;
        signal.symbol = "";
        signal.timestamp = 0;
        signal.strength = 0;
        signal.confluence = 0;
        signal.entryPrice = 0;
        signal.stopLoss = 0;
        signal.takeProfit = 0;
        signal.riskReward = 0;
        signal.timeframe = PERIOD_CURRENT;
        signal.reason = "";
        signal.isValid = false;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se deve gerar novo sinal                             |
    //+------------------------------------------------------------------+
    bool ShouldGenerateNewSignal()
    {
        datetime currentTime = TimeCurrent();
        
        // Não gerar sinais muito frequentes (mínimo 5 minutos)
        if(currentTime - m_lastSignalTime < SIGNAL_MIN_INTERVAL)
        {
            return false;
        }
        
        // Verificar horário de mercado
        if(!CCoreUtils::IsMarketHours(currentTime))
        {
            return false;
        }
        
        // Verificar liquidez
        if(!CCoreUtils::IsLiquidityHours(currentTime))
        {
            return false;
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Gerar sinal baseado nas análises                               |
    //+------------------------------------------------------------------+
    bool GenerateSignalFromAnalysis()
    {
        // Verificar se sequência é válida
        if(!m_sequencer.IsSequenceValid())
        {
            m_currentSignal.reason = "Sequência de timeframes inválida";
            return false;
        }
        
        // Obter análise consolidada
        MultiTimeframeAnalysis mtfAnalysis = m_multiTimeframe.GetConsolidatedAnalysis();
        if(!mtfAnalysis.isValid)
        {
            m_currentSignal.reason = "Análise multi-timeframe inválida";
            return false;
        }
        
        // Obter confluência
        ConfluenceResult confluence = m_confluence.GetConfluenceResult();
        if(!confluence.isValid)
        {
            m_currentSignal.reason = "Análise de confluência inválida";
            return false;
        }
        
        // Determinar direção do sinal
        ENUM_TREND_DIRECTION signalDirection = DetermineSignalDirection(mtfAnalysis, confluence);
        
        if(signalDirection == TREND_NEUTRAL)
        {
            m_currentSignal.reason = "Nenhuma direção clara identificada";
            return false;
        }
        
        // Verificar se sequência permite entrada nesta direção
        if(!m_sequencer.IsSequenceValidForEntry(signalDirection))
        {
            m_currentSignal.reason = "Sequência não permite entrada na direção identificada";
            return false;
        }
        
        // Verificar força mínima
        double sequenceStrength = m_sequencer.GetSequenceStrength();
        if(sequenceStrength < MIN_SIGNAL_STRENGTH)
        {
            m_currentSignal.reason = "Força da sequência insuficiente (" + 
                                   DoubleToString(sequenceStrength, 1) + "% < " + 
                                   DoubleToString(MIN_SIGNAL_STRENGTH, 1) + "%)";
            return false;
        }
        
        // Verificar confluência mínima
        if(confluence.confluenceScore < MIN_CONFLUENCE_SCORE)
        {
            m_currentSignal.reason = "Score de confluência insuficiente (" + 
                                   DoubleToString(confluence.confluenceScore, 1) + "% < " + 
                                   DoubleToString(MIN_CONFLUENCE_SCORE, 1) + "%)";
            return false;
        }
        
        // Gerar sinal
        return CreateTradingSignal(signalDirection, mtfAnalysis, confluence, sequenceStrength);
    }
    
    //+------------------------------------------------------------------+
    //| Determinar direção do sinal                                    |
    //+------------------------------------------------------------------+
    ENUM_TREND_DIRECTION DetermineSignalDirection(const MultiTimeframeAnalysis &mtfAnalysis,
                                                  const ConfluenceResult &confluence)
    {
        // Priorizar direção da análise multi-timeframe
        ENUM_TREND_DIRECTION mtfDirection = mtfAnalysis.overallDirection;
        
        // Verificar se confluência confirma
        bool confluenceConfirms = false;
        
        if(mtfDirection == TREND_UP && confluence.bullishFactors >= confluence.bearishFactors)
        {
            confluenceConfirms = true;
        }
        else if(mtfDirection == TREND_DOWN && confluence.bearishFactors >= confluence.bullishFactors)
        {
            confluenceConfirms = true;
        }
        
        // Verificar alinhamento forte
        bool strongAlignment = (mtfAnalysis.alignment == TF_BULLISH_STRONG || 
                               mtfAnalysis.alignment == TF_BEARISH_STRONG);
        
        if(confluenceConfirms && strongAlignment)
        {
            return mtfDirection;
        }
        
        // Verificar se confluência é muito forte mesmo com alinhamento fraco
        if(confluence.confluenceScore >= 80.0)
        {
            if(confluence.bullishFactors > confluence.bearishFactors + 2)
            {
                return TREND_UP;
            }
            else if(confluence.bearishFactors > confluence.bullishFactors + 2)
            {
                return TREND_DOWN;
            }
        }
        
        return TREND_NEUTRAL;
    }
    
    //+------------------------------------------------------------------+
    //| Criar sinal de trading                                         |
    //+------------------------------------------------------------------+
    bool CreateTradingSignal(ENUM_TREND_DIRECTION direction,
                            const MultiTimeframeAnalysis &mtfAnalysis,
                            const ConfluenceResult &confluence,
                            double sequenceStrength)
    {
        // Definir tipo do sinal
        m_currentSignal.type = (direction == TREND_UP) ? SIGNAL_BUY : SIGNAL_SELL;
        
        // Calcular força do sinal (média ponderada)
        double mtfWeight = 0.4;
        double confluenceWeight = 0.3;
        double sequenceWeight = 0.3;
        
        m_currentSignal.strength = (mtfAnalysis.overallStrength * mtfWeight) +
                                  (confluence.confluenceScore * confluenceWeight) +
                                  (sequenceStrength * sequenceWeight);
        
        // Definir confluência
        m_currentSignal.confluence = confluence.confluenceScore;
        
        // Obter preço atual
        double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        if(m_currentSignal.type == SIGNAL_BUY)
        {
            currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        }
        
        m_currentSignal.entryPrice = currentPrice;
        
        // Calcular stop loss e take profit
        CalculateStopLossAndTakeProfit(direction, confluence);
        
        // Definir timeframe dominante
        m_currentSignal.timeframe = mtfAnalysis.dominantTimeframe;
        
        // Criar razão do sinal
        CreateSignalReason(mtfAnalysis, confluence);
        
        // Marcar como válido
        m_currentSignal.isValid = true;
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular stop loss e take profit                               |
    //+------------------------------------------------------------------+
    void CalculateStopLossAndTakeProfit(ENUM_TREND_DIRECTION direction,
                                       const ConfluenceResult &confluence)
    {
        double atr = CCoreUtils::CalculateATR(NULL, NULL, NULL, 20, 20); // Simplificado
        if(atr <= 0) atr = 100; // Valor padrão em pontos
        
        double stopDistance = atr * STOP_LOSS_ATR_MULTIPLIER;
        double takeProfitDistance = stopDistance * RISK_REWARD_RATIO;
        
        // Ajustar baseado na confluência
        if(confluence.confluenceScore >= 80.0)
        {
            // Confluência alta: stop mais apertado, TP mais distante
            stopDistance *= 0.8;
            takeProfitDistance *= 1.2;
        }
        else if(confluence.confluenceScore < 60.0)
        {
            // Confluência baixa: stop mais largo
            stopDistance *= 1.2;
        }
        
        // Converter para preços
        double stopPoints = CCoreUtils::PointsToPrice(stopDistance, m_symbol);
        double tpPoints = CCoreUtils::PointsToPrice(takeProfitDistance, m_symbol);
        
        if(direction == TREND_UP)
        {
            m_currentSignal.stopLoss = m_currentSignal.entryPrice - stopPoints;
            m_currentSignal.takeProfit = m_currentSignal.entryPrice + tpPoints;
        }
        else
        {
            m_currentSignal.stopLoss = m_currentSignal.entryPrice + stopPoints;
            m_currentSignal.takeProfit = m_currentSignal.entryPrice - tpPoints;
        }
        
        // Calcular risk/reward
        double risk = MathAbs(m_currentSignal.entryPrice - m_currentSignal.stopLoss);
        double reward = MathAbs(m_currentSignal.takeProfit - m_currentSignal.entryPrice);
        
        m_currentSignal.riskReward = (risk > 0) ? (reward / risk) : 0;
    }
    
    //+------------------------------------------------------------------+
    //| Criar razão do sinal                                           |
    //+------------------------------------------------------------------+
    void CreateSignalReason(const MultiTimeframeAnalysis &mtfAnalysis,
                           const ConfluenceResult &confluence)
    {
        string reason = "";
        
        // Alinhamento de timeframes
        switch(mtfAnalysis.alignment)
        {
            case TF_BULLISH_STRONG:
                reason += "Alinhamento bullish forte. ";
                break;
            case TF_BULLISH_WEAK:
                reason += "Alinhamento bullish fraco. ";
                break;
            case TF_BEARISH_STRONG:
                reason += "Alinhamento bearish forte. ";
                break;
            case TF_BEARISH_WEAK:
                reason += "Alinhamento bearish fraco. ";
                break;
        }
        
        // Confluência
        reason += "Confluência: " + DoubleToString(confluence.confluenceScore, 1) + "% ";
        reason += "(" + IntegerToString(confluence.bullishFactors) + " bull, " + 
                  IntegerToString(confluence.bearishFactors) + " bear). ";
        
        // Força da sequência
        double sequenceStrength = m_sequencer.GetSequenceStrength();
        reason += "Sequência: " + DoubleToString(sequenceStrength, 1) + "%. ";
        
        // Timeframe dominante
        reason += "TF dominante: " + EnumToString(mtfAnalysis.dominantTimeframe) + ".";
        
        m_currentSignal.reason = reason;
    }
    
    //+------------------------------------------------------------------+
    //| Adicionar sinal ao histórico                                   |
    //+------------------------------------------------------------------+
    void AddToHistory(const TradingSignal &signal)
    {
        if(m_historySize >= MAX_SIGNAL_HISTORY)
        {
            // Remover o mais antigo
            for(int i = 0; i < MAX_SIGNAL_HISTORY - 1; i++)
            {
                m_signalHistory[i] = m_signalHistory[i + 1];
            }
            m_historySize = MAX_SIGNAL_HISTORY - 1;
        }
        
        m_signalHistory[m_historySize] = signal;
        m_historySize++;
    }
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "SignalGenerator não inicializado";
        }
        
        string info = "=== GERADOR DE SINAIS ===\n";
        
        if(m_currentSignal.isValid)
        {
            info += "SINAL ATUAL:\n";
            info += "  Tipo: " + EnumToString(m_currentSignal.type) + "\n";
            info += "  Força: " + DoubleToString(m_currentSignal.strength, 1) + "%\n";
            info += "  Confluência: " + DoubleToString(m_currentSignal.confluence, 1) + "%\n";
            info += "  Entrada: " + DoubleToString(m_currentSignal.entryPrice, 2) + "\n";
            info += "  Stop Loss: " + DoubleToString(m_currentSignal.stopLoss, 2) + "\n";
            info += "  Take Profit: " + DoubleToString(m_currentSignal.takeProfit, 2) + "\n";
            info += "  Risk/Reward: " + DoubleToString(m_currentSignal.riskReward, 2) + "\n";
            info += "  Timeframe: " + EnumToString(m_currentSignal.timeframe) + "\n";
            info += "  Razão: " + m_currentSignal.reason + "\n";
            info += "  Timestamp: " + TimeToString(m_currentSignal.timestamp, TIME_DATE|TIME_SECONDS) + "\n";
        }
        else
        {
            info += "Nenhum sinal válido no momento\n";
        }
        
        info += "\nHistórico: " + IntegerToString(m_historySize) + " sinais\n";
        info += "Último sinal: " + TimeToString(m_lastSignalTime, TIME_DATE|TIME_SECONDS) + "\n";
        info += "Última atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // SIGNAL_GENERATOR_H

