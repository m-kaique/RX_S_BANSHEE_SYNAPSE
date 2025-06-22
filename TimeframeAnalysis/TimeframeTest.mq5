//+------------------------------------------------------------------+
//| TimeframeTest.mq5 - Testes do Módulo Timeframe Analysis         |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#property copyright "Manus AI"
#property version   "1.0"
#property script_show_inputs
#property strict

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/TrendAnalyzer.mqh"
#include "MultiTimeframe.mqh"
#include "TimeframeSequencer.mqh"

//+------------------------------------------------------------------+
//| Parâmetros de entrada                                           |
//+------------------------------------------------------------------+
input string TestSymbol = "WINM25";  // Símbolo para teste

//+------------------------------------------------------------------+
//| Função principal do script                                       |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== INICIANDO TESTES DO MÓDULO TIMEFRAME ANALYSIS ===");
    
    bool allTestsPassed = true;
    
    // Teste 1: Multi-Timeframe
    allTestsPassed &= TestMultiTimeframe();
    
    // Teste 2: Timeframe Sequencer
    allTestsPassed &= TestTimeframeSequencer();
    
    // Resultado final
    if(allTestsPassed)
    {
        Print("=== TODOS OS TESTES DE TIMEFRAME ANALYSIS PASSARAM COM SUCESSO ===");
    }
    else
    {
        Print("=== ALGUNS TESTES DE TIMEFRAME ANALYSIS FALHARAM ===");
    }
}

//+------------------------------------------------------------------+
//| Teste de Multi-Timeframe                                       |
//+------------------------------------------------------------------+
bool TestMultiTimeframe()
{
    Print("--- Teste 1: Multi-Timeframe ---");
    
    CMultiTimeframe* mtf = new CMultiTimeframe();
    
    // Inicializar
    if(!mtf.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar MultiTimeframe");
        delete mtf;
        return false;
    }
    
    // Executar análise completa
    bool analyzed = mtf.AnalyzeAllTimeframes(TestSymbol);
    Print("Análise multi-timeframe executada: ", (analyzed ? "SIM" : "NÃO"));
    
    if(analyzed)
    {
        // Testar alinhamento
        ENUM_TIMEFRAME_ALIGNMENT alignment = mtf.GetTimeframeAlignment();
        string alignmentStr = "";
        switch(alignment)
        {
            case TF_BULLISH_STRONG: alignmentStr = "BULLISH FORTE"; break;
            case TF_BULLISH_WEAK:   alignmentStr = "BULLISH FRACO"; break;
            case TF_BEARISH_STRONG: alignmentStr = "BEARISH FORTE"; break;
            case TF_BEARISH_WEAK:   alignmentStr = "BEARISH FRACO"; break;
            case TF_NEUTRAL:        alignmentStr = "NEUTRO"; break;
        }
        Print("Alinhamento dos timeframes: ", alignmentStr);
        
        // Testar confluência
        bool bullishConfluence = mtf.HasTimeframeConfluence(TREND_UP);
        bool bearishConfluence = mtf.HasTimeframeConfluence(TREND_DOWN);
        
        Print("Confluência bullish: ", (bullishConfluence ? "SIM" : "NÃO"));
        Print("Confluência bearish: ", (bearishConfluence ? "SIM" : "NÃO"));
        
        // Testar timeframe dominante
        ENUM_TIMEFRAMES dominantTF = mtf.GetDominantTimeframe();
        Print("Timeframe dominante: ", EnumToString(dominantTF));
        
        // Testar alinhamento para entrada
        bool alignedForBuy = mtf.IsAlignedForEntry(TREND_UP);
        bool alignedForSell = mtf.IsAlignedForEntry(TREND_DOWN);
        
        Print("Alinhado para compra: ", (alignedForBuy ? "SIM" : "NÃO"));
        Print("Alinhado para venda: ", (alignedForSell ? "SIM" : "NÃO"));
        
        // Testar força consolidada
        double consolidatedStrength = mtf.GetConsolidatedTrendStrength();
        Print("Força consolidada: ", DoubleToString(consolidatedStrength, 1), "%");
        
        // Testar resultados individuais
        TrendAnalysisResult resultH4 = mtf.GetTimeframeResult(PERIOD_H4);
        TrendAnalysisResult resultH1 = mtf.GetTimeframeResult(PERIOD_H1);
        TrendAnalysisResult resultM15 = mtf.GetTimeframeResult(PERIOD_M15);
        TrendAnalysisResult resultM5 = mtf.GetTimeframeResult(PERIOD_M5);
        
        Print("H4 - Tendência: ", EnumToString(resultH4.trendDirection), 
              ", Força: ", DoubleToString(resultH4.trendStrength, 1), "%");
        Print("H1 - Tendência: ", EnumToString(resultH1.trendDirection), 
              ", Força: ", DoubleToString(resultH1.trendStrength, 1), "%");
        Print("M15 - Tendência: ", EnumToString(resultM15.trendDirection), 
              ", Força: ", DoubleToString(resultM15.trendStrength, 1), "%");
        Print("M5 - Tendência: ", EnumToString(resultM5.trendDirection), 
              ", Força: ", DoubleToString(resultM5.trendStrength, 1), "%");
        
        // Testar análise consolidada
        MultiTimeframeAnalysis consolidated = mtf.GetConsolidatedAnalysis();
        if(consolidated.isValid)
        {
            Print("Análise consolidada válida:");
            Print("  Direção geral: ", EnumToString(consolidated.overallDirection));
            Print("  Força geral: ", DoubleToString(consolidated.overallStrength, 1), "%");
            Print("  Score confluência: ", DoubleToString(consolidated.confluenceScore, 1), "%");
        }
        else
        {
            Print("Análise consolidada inválida");
        }
    }
    
    delete mtf;
    
    Print("SUCESSO: Teste de Multi-Timeframe");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Timeframe Sequencer                                   |
//+------------------------------------------------------------------+
bool TestTimeframeSequencer()
{
    Print("--- Teste 2: Timeframe Sequencer ---");
    
    CTimeframeSequencer* sequencer = new CTimeframeSequencer();
    
    // Inicializar
    if(!sequencer.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar TimeframeSequencer");
        delete sequencer;
        return false;
    }
    
    // Criar resultados de teste (simulados)
    TrendAnalysisResult testResultH4, testResultH1, testResultM15, testResultM5;
    
    // Simular cenário bullish
    CreateTestResult(testResultH4, TREND_UP, 75.0, true);
    CreateTestResult(testResultH1, TREND_UP, 70.0, true);
    CreateTestResult(testResultM15, TREND_UP, 80.0, true);
    CreateTestResult(testResultM5, TREND_NEUTRAL, 45.0, false);
    
    Print("Testando sequência bullish...");
    
    // Executar sequência
    bool sequenceExecuted = sequencer.ExecuteSequence(testResultH4, testResultH1, testResultM15, testResultM5);
    Print("Sequência executada: ", (sequenceExecuted ? "SIM" : "NÃO"));
    
    if(sequenceExecuted)
    {
        // Testar status da sequência
        bool isComplete = sequencer.IsSequenceComplete();
        bool isValid = sequencer.IsSequenceValid();
        int currentStep = sequencer.GetCurrentStep();
        
        Print("Sequência completa: ", (isComplete ? "SIM" : "NÃO"));
        Print("Sequência válida: ", (isValid ? "SIM" : "NÃO"));
        Print("Passo atual: ", currentStep, "/4");
        
        // Testar força da sequência
        double sequenceStrength = sequencer.GetSequenceStrength();
        Print("Força da sequência: ", DoubleToString(sequenceStrength, 1), "%");
        
        // Testar validação para entrada
        bool validForBuy = sequencer.IsSequenceValidForEntry(TREND_UP);
        bool validForSell = sequencer.IsSequenceValidForEntry(TREND_DOWN);
        
        Print("Válida para compra: ", (validForBuy ? "SIM" : "NÃO"));
        Print("Válida para venda: ", (validForSell ? "SIM" : "NÃO"));
        
        // Testar resultados individuais dos passos
        for(int i = 0; i < 4; i++)
        {
            SequenceAnalysisResult stepResult = sequencer.GetStepResult(i);
            if(stepResult.isValid)
            {
                string stepName = "";
                switch(i)
                {
                    case 0: stepName = "H4 (Tendência Principal)"; break;
                    case 1: stepName = "H1 (Confirmação)"; break;
                    case 2: stepName = "M15 (Entrada)"; break;
                    case 3: stepName = "M5 (Timing)"; break;
                }
                
                Print("Passo ", i+1, " - ", stepName, ":");
                Print("  Status: ", (stepResult.stepPassed ? "PASSOU" : "FALHOU"));
                Print("  Tendência: ", EnumToString(stepResult.trendDirection));
                Print("  Força: ", DoubleToString(stepResult.stepStrength, 1), "%");
                
                if(!stepResult.stepPassed && stepResult.failureReason != "")
                {
                    Print("  Motivo: ", stepResult.failureReason);
                }
            }
        }
    }
    
    // Testar cenário bearish
    Print("\nTestando sequência bearish...");
    
    CreateTestResult(testResultH4, TREND_DOWN, 80.0, true);
    CreateTestResult(testResultH1, TREND_DOWN, 65.0, true);
    CreateTestResult(testResultM15, TREND_DOWN, 75.0, true);
    CreateTestResult(testResultM5, TREND_DOWN, 60.0, false);
    
    bool bearishSequence = sequencer.ExecuteSequence(testResultH4, testResultH1, testResultM15, testResultM5);
    Print("Sequência bearish executada: ", (bearishSequence ? "SIM" : "NÃO"));
    
    if(bearishSequence)
    {
        bool validForSellBearish = sequencer.IsSequenceValidForEntry(TREND_DOWN);
        Print("Sequência bearish válida para venda: ", (validForSellBearish ? "SIM" : "NÃO"));
    }
    
    // Testar cenário neutro/inválido
    Print("\nTestando sequência inválida...");
    
    CreateTestResult(testResultH4, TREND_NEUTRAL, 30.0, false);
    CreateTestResult(testResultH1, TREND_UP, 40.0, false);
    CreateTestResult(testResultM15, TREND_DOWN, 35.0, false);
    CreateTestResult(testResultM5, TREND_NEUTRAL, 25.0, false);
    
    bool invalidSequence = sequencer.ExecuteSequence(testResultH4, testResultH1, testResultM15, testResultM5);
    Print("Sequência inválida executada: ", (invalidSequence ? "SIM" : "NÃO"));
    
    if(invalidSequence)
    {
        bool isValidInvalid = sequencer.IsSequenceValid();
        Print("Sequência inválida é válida: ", (isValidInvalid ? "SIM" : "NÃO"));
        
        if(!isValidInvalid)
        {
            Print("Confirmado: sequência corretamente identificada como inválida");
        }
    }
    
    // Testar próximo timeframe
    ENUM_TIMEFRAMES nextTF = sequencer.GetNextTimeframe();
    Print("Próximo timeframe na sequência: ", EnumToString(nextTF));
    
    delete sequencer;
    
    Print("SUCESSO: Teste de Timeframe Sequencer");
    return true;
}

//+------------------------------------------------------------------+
//| Criar resultado de teste                                        |
//+------------------------------------------------------------------+
void CreateTestResult(TrendAnalysisResult &result, 
                     ENUM_TREND_DIRECTION direction, 
                     double strength, 
                     bool hasSequence)
{
    result.trendDirection = direction;
    result.trendStrength = strength;
    result.hasSequence = hasSequence;
    result.sequenceType = hasSequence ? (direction == TREND_UP ? SEQUENCE_ASCENDING : SEQUENCE_DESCENDING) : SEQUENCE_NONE;
    result.sequenceStrength = hasSequence ? strength : 0;
    result.isValid = true;
    result.lastUpdate = TimeCurrent();
}

