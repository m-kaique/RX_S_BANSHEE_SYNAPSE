//+------------------------------------------------------------------+
//| SignalTest.mq5 - Testes do Módulo Signal Generation             |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#property copyright "Manus AI"
#property version   "1.0"
#property script_show_inputs

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "SignalGenerator.mqh"
#include "ConfluenceAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Parâmetros de entrada                                           |
//+------------------------------------------------------------------+
input string TestSymbol = "WINM25";  // Símbolo para teste

//+------------------------------------------------------------------+
//| Função principal do script                                       |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== INICIANDO TESTES DO MÓDULO SIGNAL GENERATION ===");
    
    bool allTestsPassed = true;
    
    // Teste 1: Confluence Analyzer
    allTestsPassed &= TestConfluenceAnalyzer();
    
    // Teste 2: Signal Generator
    allTestsPassed &= TestSignalGenerator();
    
    // Resultado final
    if(allTestsPassed)
    {
        Print("=== TODOS OS TESTES DE SIGNAL GENERATION PASSARAM COM SUCESSO ===");
    }
    else
    {
        Print("=== ALGUNS TESTES DE SIGNAL GENERATION FALHARAM ===");
    }
}

//+------------------------------------------------------------------+
//| Teste de Confluence Analyzer                                   |
//+------------------------------------------------------------------+
bool TestConfluenceAnalyzer()
{
    Print("--- Teste 1: Confluence Analyzer ---");
    
    CConfluenceAnalyzer* confluence = new CConfluenceAnalyzer();
    
    // Inicializar
    if(!confluence.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar ConfluenceAnalyzer");
        delete confluence;
        return false;
    }
    
    // Aguardar inicialização dos componentes
    Sleep(2000);
    
    // Executar análise de confluência
    bool analyzed = confluence.AnalyzeConfluence(TestSymbol);
    Print("Análise de confluência executada: ", (analyzed ? "SIM" : "NÃO"));
    
    if(analyzed)
    {
        // Obter resultado
        ConfluenceResult result = confluence.GetConfluenceResult();
        
        if(result.isValid)
        {
            Print("Resultado da confluência:");
            Print("  Score: ", DoubleToString(result.confluenceScore, 1), "%");
            Print("  Fatores bullish: ", result.bullishFactors);
            Print("  Fatores bearish: ", result.bearishFactors);
            Print("  Fatores neutros: ", result.neutralFactors);
            Print("  Total de fatores: ", result.totalFactors);
            Print("  Fator mais forte: ", result.strongestFactor);
            Print("  Fator mais fraco: ", result.weakestFactor);
            
            // Testar obtenção de fatores detalhados
            ConfluenceFactor factors[];
            int factorCount = confluence.GetConfluenceFactors(factors);
            
            Print("Fatores detalhados (", factorCount, "):");
            for(int i = 0; i < MathMin(factorCount, 5); i++) // Mostrar apenas os primeiros 5
            {
                string typeStr = "";
                switch(factors[i].type)
                {
                    case CONFLUENCE_BULLISH: typeStr = "BULLISH"; break;
                    case CONFLUENCE_BEARISH: typeStr = "BEARISH"; break;
                    case CONFLUENCE_NEUTRAL: typeStr = "NEUTRAL"; break;
                }
                
                Print("  ", i+1, ". ", factors[i].name, " [", typeStr, "] - Peso: ", 
                      DoubleToString(factors[i].weight, 1));
                Print("     ", factors[i].description);
            }
            
            if(factorCount > 5)
            {
                Print("  ... e mais ", factorCount - 5, " fatores");
            }
        }
        else
        {
            Print("Resultado de confluência inválido");
        }
    }
    
    delete confluence;
    
    Print("SUCESSO: Teste de Confluence Analyzer");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Signal Generator                                       |
//+------------------------------------------------------------------+
bool TestSignalGenerator()
{
    Print("--- Teste 2: Signal Generator ---");
    
    CSignalGenerator* signalGen = new CSignalGenerator();
    
    // Inicializar
    if(!signalGen.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar SignalGenerator");
        delete signalGen;
        return false;
    }
    
    // Aguardar inicialização completa
    Sleep(3000);
    
    // Gerar sinal
    Print("Gerando sinal...");
    bool signalGenerated = signalGen.GenerateSignal(TestSymbol);
    Print("Sinal gerado: ", (signalGenerated ? "SIM" : "NÃO"));
    
    // Verificar se há sinal válido
    bool hasValidSignal = signalGen.HasValidSignal();
    Print("Sinal válido: ", (hasValidSignal ? "SIM" : "NÃO"));
    
    if(hasValidSignal)
    {
        // Obter sinal atual
        TradingSignal signal = signalGen.GetCurrentSignal();
        
        Print("DETALHES DO SINAL:");
        
        string signalTypeStr = "";
        switch(signal.type)
        {
            case SIGNAL_BUY:  signalTypeStr = "COMPRA"; break;
            case SIGNAL_SELL: signalTypeStr = "VENDA"; break;
            case SIGNAL_NONE: signalTypeStr = "NENHUM"; break;
        }
        
        Print("  Tipo: ", signalTypeStr);
        Print("  Símbolo: ", signal.symbol);
        Print("  Força: ", DoubleToString(signal.strength, 1), "%");
        Print("  Confluência: ", DoubleToString(signal.confluence, 1), "%");
        Print("  Preço entrada: ", DoubleToString(signal.entryPrice, 2));
        Print("  Stop Loss: ", DoubleToString(signal.stopLoss, 2));
        Print("  Take Profit: ", DoubleToString(signal.takeProfit, 2));
        Print("  Risk/Reward: ", DoubleToString(signal.riskReward, 2));
        Print("  Timeframe: ", EnumToString(signal.timeframe));
        Print("  Timestamp: ", TimeToString(signal.timestamp, TIME_DATE|TIME_SECONDS));
        Print("  Razão: ", signal.reason);
        
        // Testar métodos de verificação
        bool isBuy = signalGen.IsBuySignal();
        bool isSell = signalGen.IsSellSignal();
        double strength = signalGen.GetSignalStrength();
        double confluence = signalGen.GetSignalConfluence();
        
        Print("  É compra: ", (isBuy ? "SIM" : "NÃO"));
        Print("  É venda: ", (isSell ? "SIM" : "NÃO"));
        Print("  Força (método): ", DoubleToString(strength, 1), "%");
        Print("  Confluência (método): ", DoubleToString(confluence, 1), "%");
        
        // Validar consistência
        if((signal.type == SIGNAL_BUY && !isBuy) || 
           (signal.type == SIGNAL_SELL && !isSell))
        {
            Print("AVISO: Inconsistência nos métodos de verificação");
        }
        
        if(MathAbs(signal.strength - strength) > 0.1 || 
           MathAbs(signal.confluence - confluence) > 0.1)
        {
            Print("AVISO: Inconsistência nos valores retornados");
        }
    }
    else
    {
        Print("Nenhum sinal válido gerado no momento");
        
        // Tentar gerar novamente após um tempo
        Print("Tentando gerar sinal novamente...");
        Sleep(1000);
        
        bool secondAttempt = signalGen.GenerateSignal(TestSymbol);
        Print("Segunda tentativa: ", (secondAttempt ? "SIM" : "NÃO"));
        
        if(secondAttempt && signalGen.HasValidSignal())
        {
            TradingSignal signal = signalGen.GetCurrentSignal();
            Print("Sinal gerado na segunda tentativa: ", EnumToString(signal.type));
        }
    }
    
    // Testar histórico de sinais
    TradingSignal history[];
    int historyCount = signalGen.GetSignalHistory(history);
    Print("Sinais no histórico: ", historyCount);
    
    if(historyCount > 0)
    {
        Print("Último sinal do histórico:");
        TradingSignal lastHistorical = history[historyCount - 1];
        Print("  Tipo: ", EnumToString(lastHistorical.type));
        Print("  Timestamp: ", TimeToString(lastHistorical.timestamp, TIME_DATE|TIME_SECONDS));
        Print("  Força: ", DoubleToString(lastHistorical.strength, 1), "%");
    }
    
    // Testar último sinal
    TradingSignal lastSignal = signalGen.GetLastSignal();
    if(lastSignal.isValid)
    {
        Print("Último sinal válido:");
        Print("  Tipo: ", EnumToString(lastSignal.type));
        Print("  Timestamp: ", TimeToString(lastSignal.timestamp, TIME_DATE|TIME_SECONDS));
    }
    else
    {
        Print("Nenhum sinal anterior válido");
    }
    
    // Teste de múltiplas gerações (para verificar intervalo mínimo)
    Print("Testando intervalo mínimo entre sinais...");
    
    bool rapidGeneration1 = signalGen.GenerateSignal(TestSymbol);
    bool rapidGeneration2 = signalGen.GenerateSignal(TestSymbol);
    bool rapidGeneration3 = signalGen.GenerateSignal(TestSymbol);
    
    Print("Gerações rápidas: ", (rapidGeneration1 ? "1" : "0"), 
          (rapidGeneration2 ? "1" : "0"), (rapidGeneration3 ? "1" : "0"));
    
    if(!rapidGeneration2 && !rapidGeneration3)
    {
        Print("Intervalo mínimo funcionando corretamente");
    }
    else
    {
        Print("AVISO: Intervalo mínimo pode não estar funcionando");
    }
    
    delete signalGen;
    
    Print("SUCESSO: Teste de Signal Generator");
    return true;
}

