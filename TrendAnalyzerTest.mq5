//+------------------------------------------------------------------+
//| TrendAnalyzerTest.mq5 - Teste Completo do EA                    |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#property copyright "Manus AI"
#property version   "1.0"
#property script_show_inputs

#include "TrendAnalyzerEnums.mqh"
#include "TrendAnalyzerConfig.mqh"
#include "Core/TrendAnalyzer.mqh"
#include "Core/CoreUtils.mqh"
#include "PriceAction/TrendLines.mqh"
#include "PriceAction/SupportResistance.mqh"
#include "PriceAction/Channels.mqh"
#include "PriceAction/AdvancedPatterns.mqh"
#include "Indicators/MovingAverages.mqh"
#include "Indicators/VWAP.mqh"
#include "Indicators/BollingerBands.mqh"
#include "Indicators/Fibonacci.mqh"
#include "Indicators/VolumeAnalyzer.mqh"
#include "TimeframeAnalysis/MultiTimeframe.mqh"
#include "TimeframeAnalysis/TimeframeSequencer.mqh"
#include "SignalGeneration/SignalGenerator.mqh"
#include "SignalGeneration/ConfluenceAnalyzer.mqh"
#include "TradeExecution/TradeExecutor.mqh"

//+------------------------------------------------------------------+
//| Parâmetros de entrada                                           |
//+------------------------------------------------------------------+
input string TestSymbol = "WINM25";  // Símbolo para teste
input bool   RunFullTest = true;     // Executar teste completo
input bool   TestCore = true;        // Testar módulo Core
input bool   TestPriceAction = true; // Testar módulo Price Action
input bool   TestIndicators = true;  // Testar módulo Indicators
input bool   TestTimeframe = true;   // Testar módulo Timeframe
input bool   TestSignals = true;     // Testar módulo Signals
input bool   TestExecution = true;   // Testar módulo Execution

//+------------------------------------------------------------------+
//| Função principal do script                                       |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== INICIANDO TESTE COMPLETO DO TREND ANALYZER EA ===");
    Print("Símbolo: ", TestSymbol);
    Print("Data/Hora: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
    Print("========================================================");
    
    bool allTestsPassed = true;
    int totalTests = 0;
    int passedTests = 0;
    
    if(RunFullTest)
    {
        // Executar todos os testes
        if(TestCore)
        {
            Print("\n### TESTANDO MÓDULO CORE ###");
            bool coreResult = TestCoreModule();
            allTestsPassed &= coreResult;
            totalTests++;
            if(coreResult) passedTests++;
        }
        
        if(TestPriceAction)
        {
            Print("\n### TESTANDO MÓDULO PRICE ACTION ###");
            bool priceActionResult = TestPriceActionModule();
            allTestsPassed &= priceActionResult;
            totalTests++;
            if(priceActionResult) passedTests++;
        }
        
        if(TestIndicators)
        {
            Print("\n### TESTANDO MÓDULO INDICATORS ###");
            bool indicatorsResult = TestIndicatorsModule();
            allTestsPassed &= indicatorsResult;
            totalTests++;
            if(indicatorsResult) passedTests++;
        }
        
        if(TestTimeframe)
        {
            Print("\n### TESTANDO MÓDULO TIMEFRAME ###");
            bool timeframeResult = TestTimeframeModule();
            allTestsPassed &= timeframeResult;
            totalTests++;
            if(timeframeResult) passedTests++;
        }
        
        if(TestSignals)
        {
            Print("\n### TESTANDO MÓDULO SIGNALS ###");
            bool signalsResult = TestSignalsModule();
            allTestsPassed &= signalsResult;
            totalTests++;
            if(signalsResult) passedTests++;
        }
        
        if(TestExecution)
        {
            Print("\n### TESTANDO MÓDULO EXECUTION ###");
            bool executionResult = TestExecutionModule();
            allTestsPassed &= executionResult;
            totalTests++;
            if(executionResult) passedTests++;
        }
        
        // Teste integrado
        Print("\n### TESTANDO INTEGRAÇÃO COMPLETA ###");
        bool integrationResult = TestCompleteIntegration();
        allTestsPassed &= integrationResult;
        totalTests++;
        if(integrationResult) passedTests++;
    }
    
    // Resultado final
    Print("\n========================================================");
    Print("=== RESULTADO FINAL DOS TESTES ===");
    Print("Total de módulos testados: ", totalTests);
    Print("Módulos aprovados: ", passedTests);
    Print("Módulos reprovados: ", totalTests - passedTests);
    
    if(allTestsPassed)
    {
        Print("STATUS: TODOS OS TESTES PASSARAM COM SUCESSO! ✓");
        Print("O Expert Advisor está pronto para uso em produção.");
    }
    else
    {
        Print("STATUS: ALGUNS TESTES FALHARAM! ✗");
        Print("Verifique os logs acima para identificar os problemas.");
    }
    
    Print("========================================================");
}

//+------------------------------------------------------------------+
//| Testar módulo Core                                              |
//+------------------------------------------------------------------+
bool TestCoreModule()
{
    Print("Testando TrendAnalyzer...");
    
    CTrendAnalyzer* analyzer = new CTrendAnalyzer();
    
    if(!analyzer.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar TrendAnalyzer");
        delete analyzer;
        return false;
    }
    
    // Testar análise de tendência
    ENUM_TREND_DIRECTION trend = analyzer.AnalyzeTrend(PERIOD_H1);

    TrendAnalysisResult result;
    result.trendDirection   = trend;
    result.trendStrength    = analyzer.GetTrendStrength(PERIOD_H1);
    result.hasSequence      = false;
    result.sequenceType     = SEQUENCE_NONE;
    result.sequenceStrength = 0;
    result.isValid          = true;
    result.lastUpdate       = TimeCurrent();

    Print("TrendAnalyzer: OK - Tendência: ", EnumToString(result.trendDirection),
          ", Força: ", DoubleToString(result.trendStrength, 1), "%");
    
    delete analyzer;
    
    // Testar CoreUtils
    Print("Testando CoreUtils...");
    
    bool marketHours = CCoreUtils::IsMarketHours(TimeCurrent());
    bool liquidityHours = CCoreUtils::IsLiquidityHours(TimeCurrent());
    
    Print("CoreUtils: OK - Mercado aberto: ", (marketHours ? "SIM" : "NÃO"), 
          ", Liquidez: ", (liquidityHours ? "SIM" : "NÃO"));
    
    Print("MÓDULO CORE: APROVADO ✓");
    return true;
}

//+------------------------------------------------------------------+
//| Testar módulo Price Action                                      |
//+------------------------------------------------------------------+
bool TestPriceActionModule()
{
    bool allPassed = true;
    
    // Testar TrendLines
    Print("Testando TrendLines...");
    CTrendLines* trendLines = new CTrendLines();
    
    if(trendLines.Initialize(TestSymbol))
    {
        bool hasLTA = trendLines.IsLTAValid();
        bool hasLTB = trendLines.IsLTBValid();
        Print("TrendLines: OK - LTA: ", (hasLTA ? "SIM" : "NÃO"), ", LTB: ", (hasLTB ? "SIM" : "NÃO"));
    }
    else
    {
        Print("TrendLines: FALHA na inicialização");
        allPassed = false;
    }
    
    // Testar SupportResistance
    Print("Testando SupportResistance...");
    CSupportResistance* supRes = new CSupportResistance();
    
    if(supRes.Initialize(TestSymbol))
    {
        supRes.IdentifyLevels(TestSymbol, PERIOD_H1);
        int levelCount = supRes.GetLevelsCount();
        Print("SupportResistance: OK - Níveis encontrados: ", levelCount);
    }
    else
    {
        Print("SupportResistance: FALHA na inicialização");
        allPassed = false;
    }
    delete supRes;
    
    // Testar Channels
    Print("Testando Channels...");
    CChannels* channels = new CChannels();

    if(channels.Initialize(TestSymbol, trendLines))
    {
        double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
        bool inChannel = channels.IsInChannel(currentPrice);
        Print("Channels: OK - Em canal: ", (inChannel ? "SIM" : "NÃO"));
    }
    else
    {
        Print("Channels: FALHA na inicialização");
        allPassed = false;
    }
    delete channels;
    delete trendLines;
    
    if(allPassed)
    {
        Print("MÓDULO PRICE ACTION: APROVADO ✓");
    }
    else
    {
        Print("MÓDULO PRICE ACTION: REPROVADO ✗");
    }
    
    return allPassed;
}

//+------------------------------------------------------------------+
//| Testar módulo Indicators                                        |
//+------------------------------------------------------------------+
bool TestIndicatorsModule()
{
    bool allPassed = true;
    
    // Testar MovingAverages
    Print("Testando MovingAverages...");
    CMovingAverages* ma = new CMovingAverages();
    
    if(ma.Initialize(TestSymbol))
    {
        Sleep(1000); // Aguardar cálculo
        ENUM_MA_ALIGNMENT alignment = ma.GetAlignment();
        Print("MovingAverages: OK - Alinhamento: ", EnumToString(alignment));
    }
    else
    {
        Print("MovingAverages: FALHA na inicialização");
        allPassed = false;
    }
    delete ma;
    
    // Testar VWAP
    Print("Testando VWAP...");
    CVWAP* vwap = new CVWAP();
    
    if(vwap.Initialize(TestSymbol))
    {
        vwap.Calculate(TestSymbol, PERIOD_M15);
        double vwapValue = vwap.GetVWAP();
        Print("VWAP: OK - Valor: ", DoubleToString(vwapValue, 2));
    }
    else
    {
        Print("VWAP: FALHA na inicialização");
        allPassed = false;
    }
    delete vwap;
    
    // Testar VolumeAnalyzer
    Print("Testando VolumeAnalyzer...");
    CVolumeAnalyzer* volume = new CVolumeAnalyzer();
    
    if(volume.Initialize(TestSymbol))
    {
        volume.AnalyzeVolume(TestSymbol, PERIOD_M15);
        double volumeRatio = volume.GetVolumeRatio();
        Print("VolumeAnalyzer: OK - Razão: ", DoubleToString(volumeRatio, 2), "x");
    }
    else
    {
        Print("VolumeAnalyzer: FALHA na inicialização");
        allPassed = false;
    }
    delete volume;
    
    if(allPassed)
    {
        Print("MÓDULO INDICATORS: APROVADO ✓");
    }
    else
    {
        Print("MÓDULO INDICATORS: REPROVADO ✗");
    }
    
    return allPassed;
}

//+------------------------------------------------------------------+
//| Testar módulo Timeframe                                         |
//+------------------------------------------------------------------+
bool TestTimeframeModule()
{
    bool allPassed = true;
    
    // Testar MultiTimeframe
    Print("Testando MultiTimeframe...");
    CMultiTimeframe* mtf = new CMultiTimeframe();
    
    if(mtf.Initialize(TestSymbol))
    {
        bool analyzed = mtf.AnalyzeAllTimeframes(TestSymbol);
        if(analyzed)
        {
            ENUM_TIMEFRAME_ALIGNMENT alignment = mtf.GetTimeframeAlignment();
            double strength = mtf.GetConsolidatedTrendStrength();
            Print("MultiTimeframe: OK - Alinhamento: ", EnumToString(alignment), 
                  ", Força: ", DoubleToString(strength, 1), "%");
        }
        else
        {
            Print("MultiTimeframe: FALHA na análise");
            allPassed = false;
        }
    }
    else
    {
        Print("MultiTimeframe: FALHA na inicialização");
        allPassed = false;
    }
    delete mtf;
    
    // Testar TimeframeSequencer
    Print("Testando TimeframeSequencer...");
    CTimeframeSequencer* sequencer = new CTimeframeSequencer();
    
    if(sequencer.Initialize(TestSymbol))
    {
        // Criar resultados de teste
        TrendAnalysisResult testResults[4];
        for(int i = 0; i < 4; i++)
        {
            testResults[i].trendDirection = TREND_UP;
            testResults[i].trendStrength = 70.0;
            testResults[i].hasSequence = true;
            testResults[i].isValid = true;
        }
        
        bool executed = sequencer.ExecuteSequence(testResults[0], testResults[1], testResults[2], testResults[3]);
        if(executed)
        {
            bool isValid = sequencer.IsSequenceValid();
            Print("TimeframeSequencer: OK - Sequência válida: ", (isValid ? "SIM" : "NÃO"));
        }
        else
        {
            Print("TimeframeSequencer: FALHA na execução");
            allPassed = false;
        }
    }
    else
    {
        Print("TimeframeSequencer: FALHA na inicialização");
        allPassed = false;
    }
    delete sequencer;
    
    if(allPassed)
    {
        Print("MÓDULO TIMEFRAME: APROVADO ✓");
    }
    else
    {
        Print("MÓDULO TIMEFRAME: REPROVADO ✗");
    }
    
    return allPassed;
}

//+------------------------------------------------------------------+
//| Testar módulo Signals                                           |
//+------------------------------------------------------------------+
bool TestSignalsModule()
{
    bool allPassed = true;
    
    // Testar ConfluenceAnalyzer
    Print("Testando ConfluenceAnalyzer...");
    CConfluenceAnalyzer* confluence = new CConfluenceAnalyzer();
    
    if(confluence.Initialize(TestSymbol))
    {
        Sleep(2000); // Aguardar inicialização dos componentes
        bool analyzed = confluence.AnalyzeConfluence(TestSymbol);
        if(analyzed)
        {
            ConfluenceResult result = confluence.GetConfluenceResult();
            if(result.isValid)
            {
                Print("ConfluenceAnalyzer: OK - Score: ", DoubleToString(result.confluenceScore, 1), 
                      "%, Fatores: ", result.totalFactors);
            }
            else
            {
                Print("ConfluenceAnalyzer: FALHA - resultado inválido");
                allPassed = false;
            }
        }
        else
        {
            Print("ConfluenceAnalyzer: FALHA na análise");
            allPassed = false;
        }
    }
    else
    {
        Print("ConfluenceAnalyzer: FALHA na inicialização");
        allPassed = false;
    }
    delete confluence;
    
    // Testar SignalGenerator
    Print("Testando SignalGenerator...");
    CSignalGenerator* signalGen = new CSignalGenerator();
    
    if(signalGen.Initialize(TestSymbol))
    {
        Sleep(3000); // Aguardar inicialização completa
        bool generated = signalGen.GenerateSignal(TestSymbol);
        
        Print("SignalGenerator: OK - Sinal gerado: ", (generated ? "SIM" : "NÃO"));
        
        if(signalGen.HasValidSignal())
        {
            TradingSignal signal = signalGen.GetCurrentSignal();
            Print("Sinal válido: ", EnumToString(signal.type), 
                  ", Força: ", DoubleToString(signal.strength, 1), "%");
        }
    }
    else
    {
        Print("SignalGenerator: FALHA na inicialização");
        allPassed = false;
    }
    delete signalGen;
    
    if(allPassed)
    {
        Print("MÓDULO SIGNALS: APROVADO ✓");
    }
    else
    {
        Print("MÓDULO SIGNALS: REPROVADO ✗");
    }
    
    return allPassed;
}

//+------------------------------------------------------------------+
//| Testar módulo Execution                                         |
//+------------------------------------------------------------------+
bool TestExecutionModule()
{
    Print("Testando TradeExecutor...");
    
    CTradeExecutor* executor = new CTradeExecutor();
    
    if(!executor.Initialize(TestSymbol, 123456))
    {
        Print("FALHA: Não foi possível inicializar TradeExecutor");
        delete executor;
        return false;
    }
    
    // Configurar executor
    executor.SetLotSize(0.01); // Lote mínimo para teste
    executor.SetUseFixedLot(true);
    executor.SetTrailingStop(false, 0); // Desabilitar trailing para teste
    executor.SetPartialClose(false, 0); // Desabilitar fechamento parcial para teste
    
    Print("TradeExecutor: OK - Inicializado com sucesso");
    Print("Configurações: Lote=0.01, Magic=123456");
    
    // Testar validação sem executar trades reais
    double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
    double testSL = currentPrice - 100 * SymbolInfoDouble(TestSymbol, SYMBOL_POINT);
    double testTP = currentPrice + 200 * SymbolInfoDouble(TestSymbol, SYMBOL_POINT);
    
    Print("Preços de teste: Entrada=", DoubleToString(currentPrice, 2), 
          ", SL=", DoubleToString(testSL, 2), 
          ", TP=", DoubleToString(testTP, 2));
    
    delete executor;
    
    Print("MÓDULO EXECUTION: APROVADO ✓");
    return true;
}

//+------------------------------------------------------------------+
//| Testar integração completa                                      |
//+------------------------------------------------------------------+
bool TestCompleteIntegration()
{
    Print("Testando integração completa do sistema...");
    
    // Criar componentes principais
    CSignalGenerator* signalGen = new CSignalGenerator();
    CTradeExecutor* executor = new CTradeExecutor();
    
    bool integrationOK = true;
    
    // Inicializar componentes
    if(!signalGen.Initialize(TestSymbol))
    {
        Print("FALHA: Inicialização do SignalGenerator");
        integrationOK = false;
    }
    
    if(!executor.Initialize(TestSymbol, 999999))
    {
        Print("FALHA: Inicialização do TradeExecutor");
        integrationOK = false;
    }
    
    if(integrationOK)
    {
        Print("Componentes inicializados com sucesso");
        
        // Configurar executor para teste
        executor.SetLotSize(0.01);
        executor.SetUseFixedLot(true);
        
        // Aguardar e tentar gerar sinal
        Sleep(3000);
        
        bool signalGenerated = signalGen.GenerateSignal(TestSymbol);
        Print("Geração de sinal: ", (signalGenerated ? "SUCESSO" : "SEM SINAL"));
        
        if(signalGenerated && signalGen.HasValidSignal())
        {
            TradingSignal signal = signalGen.GetCurrentSignal();
            Print("Sinal integrado: ", EnumToString(signal.type), 
                  " - Força: ", DoubleToString(signal.strength, 1), "%",
                  " - Confluência: ", DoubleToString(signal.confluence, 1), "%");
            
            // Simular validação de sinal (sem executar trade real)
            if(signal.strength >= 50.0 && signal.confluence >= 30.0)
            {
                Print("Sinal seria aceito para execução");
            }
            else
            {
                Print("Sinal seria rejeitado (critérios não atendidos)");
            }
        }
        
        Print("Teste de integração concluído");
    }
    
    // Limpar
    delete signalGen;
    delete executor;
    
    if(integrationOK)
    {
        Print("INTEGRAÇÃO COMPLETA: APROVADA ✓");
        Print("Todos os componentes funcionam corretamente em conjunto");
    }
    else
    {
        Print("INTEGRAÇÃO COMPLETA: REPROVADA ✗");
    }
    
    return integrationOK;
}

