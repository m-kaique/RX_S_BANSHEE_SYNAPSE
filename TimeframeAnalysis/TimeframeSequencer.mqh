//+------------------------------------------------------------------+
//| TimeframeSequencer.mqh - Sequenciador de Timeframes             |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef TIMEFRAME_SEQUENCER_H
#define TIMEFRAME_SEQUENCER_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"
#include <Object.mqh>

//+------------------------------------------------------------------+
//| Classe Sequenciador de Timeframes                               |
//+------------------------------------------------------------------+
class CTimeframeSequencer : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Sequência de análise conforme metodologia
    ENUM_TIMEFRAMES      m_analysisSequence[4];
    
    // Resultados da sequência
    SequenceAnalysisResult m_sequenceResults[4];
    
    // Estado da sequência
    int                  m_currentStep;      // Passo atual (0-3)
    bool                 m_sequenceComplete; // Sequência completa
    bool                 m_sequenceValid;    // Sequência válida
    
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CTimeframeSequencer()
    {
        m_symbol = "";
        
        // Definir sequência conforme metodologia do guia
        m_analysisSequence[0] = PERIOD_H4;   // 1º: Tendência principal
        m_analysisSequence[1] = PERIOD_H1;   // 2º: Confirmação
        m_analysisSequence[2] = PERIOD_M15;  // 3º: Entrada
        m_analysisSequence[3] = PERIOD_M5;   // 4º: Timing
        
        // Inicializar resultados
        for(int i = 0; i < 4; i++)
        {
            InitializeSequenceResult(m_sequenceResults[i]);
        }
        
        m_currentStep = 0;
        m_sequenceComplete = false;
        m_sequenceValid = false;
        m_lastUpdate = 0;
        m_initialized = false;
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CTimeframeSequencer()
    {
        // Nada específico para limpar
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar sequenciador                                       |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para TimeframeSequencer");
            return false;
        }
        
        m_symbol = symbol;
        m_initialized = true;
        
        CCoreUtils::LogInfo("TimeframeSequencer inicializado para " + symbol);
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Executar sequência de análise                                  |
    //+------------------------------------------------------------------+
    bool ExecuteSequence(const TrendAnalysisResult &resultH4,
                        const TrendAnalysisResult &resultH1,
                        const TrendAnalysisResult &resultM15,
                        const TrendAnalysisResult &resultM5)
    {
        if(!m_initialized)
        {
            CCoreUtils::LogError("TimeframeSequencer não inicializado");
            return false;
        }
        
        // Resetar sequência
        ResetSequence();
        
        // Executar cada passo da sequência
        bool step1 = ExecuteStep1_TrendPrincipal(resultH4);
        bool step2 = ExecuteStep2_Confirmacao(resultH1, step1);
        bool step3 = ExecuteStep3_Entrada(resultM15, step2);
        bool step4 = ExecuteStep4_Timing(resultM5, step3);
        
        // Avaliar sequência completa
        m_sequenceComplete = (m_currentStep == 4);
        m_sequenceValid = EvaluateSequenceValidity();
        
        m_lastUpdate = TimeCurrent();
        
        CCoreUtils::LogInfo("Sequência executada. Válida: " + (m_sequenceValid ? "SIM" : "NÃO"));
        
        return m_sequenceComplete;
    }
    
    //+------------------------------------------------------------------+
    //| Obter próximo timeframe na sequência                           |
    //+------------------------------------------------------------------+
    ENUM_TIMEFRAMES GetNextTimeframe()
    {
        if(!m_initialized || m_currentStep >= 4)
        {
            return PERIOD_CURRENT;
        }
        
        return m_analysisSequence[m_currentStep];
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se sequência permite entrada                         |
    //+------------------------------------------------------------------+
    bool IsSequenceValidForEntry(ENUM_TREND_DIRECTION entryDirection)
    {
        if(!m_sequenceComplete || !m_sequenceValid)
        {
            return false;
        }
        
        // Verificar alinhamento da sequência com direção de entrada
        int alignedSteps = 0;
        
        for(int i = 0; i < 4; i++)
        {
            if(m_sequenceResults[i].stepPassed && 
               m_sequenceResults[i].trendDirection == entryDirection)
            {
                alignedSteps++;
            }
        }
        
        // Entrada válida se 3+ passos estão alinhados
        return (alignedSteps >= 3);
    }
    
    //+------------------------------------------------------------------+
    //| Obter força da sequência                                       |
    //+------------------------------------------------------------------+
    double GetSequenceStrength()
    {
        if(!m_sequenceComplete)
        {
            return 0;
        }
        
        double totalStrength = 0;
        int validSteps = 0;
        
        // Pesos por passo (H4 mais importante)
        double weights[] = {4.0, 3.0, 2.0, 1.0};
        double totalWeight = 0;
        
        for(int i = 0; i < 4; i++)
        {
            if(m_sequenceResults[i].stepPassed)
            {
                totalStrength += m_sequenceResults[i].stepStrength * weights[i];
                totalWeight += weights[i];
                validSteps++;
            }
        }
        
        if(totalWeight == 0) return 0;
        
        return totalStrength / totalWeight;
    }
    
    //+------------------------------------------------------------------+
    //| Obter resultado de passo específico                            |
    //+------------------------------------------------------------------+
    SequenceAnalysisResult GetStepResult(int stepIndex)
    {
        SequenceAnalysisResult emptyResult;
        InitializeSequenceResult(emptyResult);
        
        if(stepIndex < 0 || stepIndex >= 4)
        {
            return emptyResult;
        }
        
        return m_sequenceResults[stepIndex];
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se sequência está completa                           |
    //+------------------------------------------------------------------+
    bool IsSequenceComplete() const { return m_sequenceComplete; }
    
    //+------------------------------------------------------------------+
    //| Verificar se sequência é válida                                |
    //+------------------------------------------------------------------+
    bool IsSequenceValid() const { return m_sequenceValid; }
    
    //+------------------------------------------------------------------+
    //| Obter passo atual                                              |
    //+------------------------------------------------------------------+
    int GetCurrentStep() const { return m_currentStep; }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

private:
    //+------------------------------------------------------------------+
    //| Inicializar resultado de sequência                             |
    //+------------------------------------------------------------------+
    void InitializeSequenceResult(SequenceAnalysisResult &result)
    {
        result.timeframe = PERIOD_CURRENT;
        result.stepNumber = 0;
        result.stepPassed = false;
        result.stepStrength = 0;
        result.trendDirection = TREND_NEUTRAL;
        result.failureReason = "";
        result.isValid = false;
    }
    
    //+------------------------------------------------------------------+
    //| Resetar sequência                                              |
    //+------------------------------------------------------------------+
    void ResetSequence()
    {
        for(int i = 0; i < 4; i++)
        {
            InitializeSequenceResult(m_sequenceResults[i]);
        }
        
        m_currentStep = 0;
        m_sequenceComplete = false;
        m_sequenceValid = false;
    }
    
    //+------------------------------------------------------------------+
    //| Passo 1: Análise da Tendência Principal (H4)                  |
    //+------------------------------------------------------------------+
    bool ExecuteStep1_TrendPrincipal(const TrendAnalysisResult &resultH4)
    {
        m_sequenceResults[0].timeframe = PERIOD_H4;
        m_sequenceResults[0].stepNumber = 1;
        m_sequenceResults[0].trendDirection = resultH4.trendDirection;
        m_sequenceResults[0].isValid = true;
        
        // Critérios para H4
        bool hasTrend = (resultH4.trendDirection != TREND_NEUTRAL);
        bool strongTrend = (resultH4.trendStrength >= MIN_H4_TREND_STRENGTH);
        bool hasSequence = resultH4.hasSequence;
        
        if(hasTrend && strongTrend)
        {
            m_sequenceResults[0].stepPassed = true;
            m_sequenceResults[0].stepStrength = resultH4.trendStrength;
            m_currentStep = 1;
            
            CCoreUtils::LogInfo("Passo 1 (H4) PASSOU - Tendência: " + 
                              TrendDirectionToString(resultH4.trendDirection) + 
                              ", Força: " + DoubleToString(resultH4.trendStrength, 1) + "%");
            return true;
        }
        else
        {
            m_sequenceResults[0].stepPassed = false;
            m_sequenceResults[0].stepStrength = 0;
            
            string reason = "";
            if(!hasTrend) reason += "Sem tendência definida. ";
            if(!strongTrend) reason += "Tendência fraca (<" + DoubleToString(MIN_H4_TREND_STRENGTH, 0) + "%). ";
            if(!hasSequence) reason += "Sem sequência válida. ";
            
            m_sequenceResults[0].failureReason = reason;
            
            CCoreUtils::LogWarning("Passo 1 (H4) FALHOU - " + reason);
            return false;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Passo 2: Confirmação (H1)                                     |
    //+------------------------------------------------------------------+
    bool ExecuteStep2_Confirmacao(const TrendAnalysisResult &resultH1, bool step1Passed)
    {
        m_sequenceResults[1].timeframe = PERIOD_H1;
        m_sequenceResults[1].stepNumber = 2;
        m_sequenceResults[1].trendDirection = resultH1.trendDirection;
        m_sequenceResults[1].isValid = true;
        
        if(!step1Passed)
        {
            m_sequenceResults[1].stepPassed = false;
            m_sequenceResults[1].failureReason = "Passo 1 falhou";
            CCoreUtils::LogWarning("Passo 2 (H1) FALHOU - Passo anterior falhou");
            return false;
        }
        
        // H1 deve confirmar ou ser neutro em relação ao H4
        ENUM_TREND_DIRECTION h4Direction = m_sequenceResults[0].trendDirection;
        bool confirmsH4 = (resultH1.trendDirection == h4Direction);
        bool isNeutral = (resultH1.trendDirection == TREND_NEUTRAL);
        bool strongEnough = (resultH1.trendStrength >= MIN_H1_TREND_STRENGTH);
        
        if((confirmsH4 || isNeutral) && strongEnough)
        {
            m_sequenceResults[1].stepPassed = true;
            m_sequenceResults[1].stepStrength = resultH1.trendStrength;
            m_currentStep = 2;
            
            CCoreUtils::LogInfo("Passo 2 (H1) PASSOU - Tendência: " + 
                              TrendDirectionToString(resultH1.trendDirection) + 
                              ", Confirma H4: " + (confirmsH4 ? "SIM" : "NEUTRO"));
            return true;
        }
        else
        {
            m_sequenceResults[1].stepPassed = false;
            m_sequenceResults[1].stepStrength = 0;
            
            string reason = "";
            if(!confirmsH4 && !isNeutral) reason += "Contradiz H4. ";
            if(!strongEnough) reason += "Força insuficiente. ";
            
            m_sequenceResults[1].failureReason = reason;
            
            CCoreUtils::LogWarning("Passo 2 (H1) FALHOU - " + reason);
            return false;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Passo 3: Entrada (M15)                                        |
    //+------------------------------------------------------------------+
    bool ExecuteStep3_Entrada(const TrendAnalysisResult &resultM15, bool step2Passed)
    {
        m_sequenceResults[2].timeframe = PERIOD_M15;
        m_sequenceResults[2].stepNumber = 3;
        m_sequenceResults[2].trendDirection = resultM15.trendDirection;
        m_sequenceResults[2].isValid = true;
        
        if(!step2Passed)
        {
            m_sequenceResults[2].stepPassed = false;
            m_sequenceResults[2].failureReason = "Passo 2 falhou";
            CCoreUtils::LogWarning("Passo 3 (M15) FALHOU - Passo anterior falhou");
            return false;
        }
        
        // M15 deve ter tendência definida e alinhada
        ENUM_TREND_DIRECTION expectedDirection = m_sequenceResults[0].trendDirection;
        bool isAligned = (resultM15.trendDirection == expectedDirection);
        bool strongEnough = (resultM15.trendStrength >= MIN_M15_TREND_STRENGTH);
        bool hasSequence = resultM15.hasSequence;
        
        if(isAligned && strongEnough)
        {
            m_sequenceResults[2].stepPassed = true;
            m_sequenceResults[2].stepStrength = resultM15.trendStrength;
            m_currentStep = 3;
            
            CCoreUtils::LogInfo("Passo 3 (M15) PASSOU - Tendência: " + 
                              TrendDirectionToString(resultM15.trendDirection) + 
                              ", Força: " + DoubleToString(resultM15.trendStrength, 1) + "%");
            return true;
        }
        else
        {
            m_sequenceResults[2].stepPassed = false;
            m_sequenceResults[2].stepStrength = 0;
            
            string reason = "";
            if(!isAligned) reason += "Não alinhado com H4. ";
            if(!strongEnough) reason += "Força insuficiente. ";
            if(!hasSequence) reason += "Sem sequência. ";
            
            m_sequenceResults[2].failureReason = reason;
            
            CCoreUtils::LogWarning("Passo 3 (M15) FALHOU - " + reason);
            return false;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Passo 4: Timing (M5)                                          |
    //+------------------------------------------------------------------+
    bool ExecuteStep4_Timing(const TrendAnalysisResult &resultM5, bool step3Passed)
    {
        m_sequenceResults[3].timeframe = PERIOD_M5;
        m_sequenceResults[3].stepNumber = 4;
        m_sequenceResults[3].trendDirection = resultM5.trendDirection;
        m_sequenceResults[3].isValid = true;
        
        if(!step3Passed)
        {
            m_sequenceResults[3].stepPassed = false;
            m_sequenceResults[3].failureReason = "Passo 3 falhou";
            CCoreUtils::LogWarning("Passo 4 (M5) FALHOU - Passo anterior falhou");
            return false;
        }
        
        // M5 pode ser neutro ou alinhado (timing mais flexível)
        ENUM_TREND_DIRECTION expectedDirection = m_sequenceResults[0].trendDirection;
        bool isAligned = (resultM5.trendDirection == expectedDirection);
        bool isNeutral = (resultM5.trendDirection == TREND_NEUTRAL);
        bool notOpposite = (resultM5.trendDirection != GetOppositeDirection(expectedDirection));
        
        if(isAligned || isNeutral || notOpposite)
        {
            m_sequenceResults[3].stepPassed = true;
            m_sequenceResults[3].stepStrength = resultM5.trendStrength;
            m_currentStep = 4;
            
            CCoreUtils::LogInfo("Passo 4 (M5) PASSOU - Tendência: " + 
                              TrendDirectionToString(resultM5.trendDirection) + 
                              ", Timing adequado");
            return true;
        }
        else
        {
            m_sequenceResults[3].stepPassed = false;
            m_sequenceResults[3].stepStrength = 0;
            m_sequenceResults[3].failureReason = "Timing desfavorável - contradiz tendência principal";
            
            CCoreUtils::LogWarning("Passo 4 (M5) FALHOU - Timing desfavorável");
            return false;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Avaliar validade da sequência                                  |
    //+------------------------------------------------------------------+
    bool EvaluateSequenceValidity()
    {
        if(!m_sequenceComplete)
        {
            return false;
        }
        
        // Contar passos que passaram
        int passedSteps = 0;
        for(int i = 0; i < 4; i++)
        {
            if(m_sequenceResults[i].stepPassed)
            {
                passedSteps++;
            }
        }
        
        // Sequência válida se 3+ passos passaram
        bool validByCount = (passedSteps >= 3);
        
        // Passo 1 (H4) é obrigatório
        bool h4Passed = m_sequenceResults[0].stepPassed;
        
        // Força geral adequada
        double sequenceStrength = GetSequenceStrength();
        bool strongEnough = (sequenceStrength >= MIN_SEQUENCE_STRENGTH);
        
        return (validByCount && h4Passed && strongEnough);
    }
    
    //+------------------------------------------------------------------+
    //| Obter direção oposta                                          |
    //+------------------------------------------------------------------+
    ENUM_TREND_DIRECTION GetOppositeDirection(ENUM_TREND_DIRECTION direction)
    {
        switch(direction)
        {
            case TREND_UP:   return TREND_DOWN;
            case TREND_DOWN: return TREND_UP;
            default:         return TREND_NEUTRAL;
        }
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
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "TimeframeSequencer não inicializado";
        }
        
        string info = "=== SEQUÊNCIA DE TIMEFRAMES ===\n";
        info += "Passo atual: " + IntegerToString(m_currentStep) + "/4\n";
        info += "Sequência completa: " + (m_sequenceComplete ? "SIM" : "NÃO") + "\n";
        info += "Sequência válida: " + (m_sequenceValid ? "SIM" : "NÃO") + "\n";
        info += "Força da sequência: " + DoubleToString(GetSequenceStrength(), 1) + "%\n\n";
        
        // Detalhes de cada passo
        string stepNames[] = {"H4 (Tendência Principal)", "H1 (Confirmação)", "M15 (Entrada)", "M5 (Timing)"};
        
        for(int i = 0; i < 4; i++)
        {
            info += "Passo " + IntegerToString(i + 1) + " - " + stepNames[i] + ":\n";
            info += "  Status: " + (m_sequenceResults[i].stepPassed ? "PASSOU" : "FALHOU") + "\n";
            info += "  Tendência: " + TrendDirectionToString(m_sequenceResults[i].trendDirection) + "\n";
            info += "  Força: " + DoubleToString(m_sequenceResults[i].stepStrength, 1) + "%\n";
            
            if(!m_sequenceResults[i].stepPassed && m_sequenceResults[i].failureReason != "")
            {
                info += "  Motivo: " + m_sequenceResults[i].failureReason + "\n";
            }
            info += "\n";
        }
        
        info += "Última atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // TIMEFRAME_SEQUENCER_H

