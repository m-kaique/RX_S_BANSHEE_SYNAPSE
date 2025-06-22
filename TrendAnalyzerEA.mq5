//+------------------------------------------------------------------+
//| TrendAnalyzerEA.mq5 - Expert Advisor Principal                  |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//| Descrição: EA completo para análise de tendência do WINM25      |
//|            baseado na metodologia do guia fornecido             |
//+------------------------------------------------------------------+

#property copyright "Manus AI"
#property version   "1.0"
#property description "Expert Advisor para análise de tendência WINM25"
#property strict

// Incluir todos os módulos necessários
#include "TrendAnalyzerEnums.mqh"
#include "TrendAnalyzerConfig.mqh"
#include "Core/CoreUtils.mqh"
#include "SignalGeneration/SignalGenerator.mqh"
#include "TradeExecution/TradeExecutor.mqh"

//+------------------------------------------------------------------+
//| Parâmetros de entrada do EA                                     |
//+------------------------------------------------------------------+

// === CONFIGURAÇÕES GERAIS ===
input group "=== CONFIGURAÇÕES GERAIS ==="
input string EA_Symbol = "WINQ25";                    // Símbolo para trading
input bool   EA_Enabled = true;                       // Habilitar EA
input bool   EA_AllowLong = true;                     // Permitir operações de compra
input bool   EA_AllowShort = true;                    // Permitir operações de venda
input int    EA_MagicNumber = 20250621;               // Número mágico
input string EA_Comment = "TrendAnalyzer";            // Comentário das ordens

// === GESTÃO DE RISCO ===
input group "=== GESTÃO DE RISCO ==="
input double Risk_LotSize = 0.1;                      // Tamanho do lote
input bool   Risk_UseFixedLot = true;                 // Usar lote fixo
input double Risk_RiskPercent = 2.0;                  // % de risco por operação
input double Risk_MaxLoss = 1000.0;                   // Perda máxima diária
input double Risk_MaxProfit = 3000.0;                 // Lucro máximo diário
input int    Risk_MaxTrades = 5;                      // Máximo de trades por dia

// === CONFIGURAÇÕES DE SINAL ===
input group "=== CONFIGURAÇÕES DE SINAL ==="
input double Signal_MinStrength = 70.0;               // Força mínima do sinal (%)
input double Signal_MinConfluence = 60.0;             // Confluência mínima (%)
input int    Signal_UpdateInterval = 180;             // Intervalo de atualização (segundos)
input bool   Signal_OnlyLiquidityHours = true;        // Operar apenas em horários de liquidez

// === CONFIGURAÇÕES DE TIMEFRAME ===
input group "=== CONFIGURAÇÕES DE TIMEFRAME ==="
input double TF_MinH4Strength = 60.0;                 // Força mínima H4 (%)
input double TF_MinH1Strength = 50.0;                 // Força mínima H1 (%)
input double TF_MinM15Strength = 70.0;                // Força mínima M15 (%)
input double TF_MinSequenceStrength = 65.0;           // Força mínima da sequência (%)

// === CONFIGURAÇÕES DE STOP E TARGET ===
input group "=== STOP LOSS E TAKE PROFIT ==="
input double SL_ATRMultiplier = 2.0;                  // Multiplicador ATR para Stop Loss
input double TP_RiskRewardRatio = 2.0;                // Razão Risco/Recompensa
input bool   SL_UseTrailingStop = true;               // Usar trailing stop
input double SL_TrailingDistance = 100.0;             // Distância do trailing stop (pontos)
input bool   TP_UsePartialClose = true;               // Fechamento parcial
input double TP_PartialPercent = 50.0;                // % para fechamento parcial

// === CONFIGURAÇÕES DE HORÁRIO ===
input group "=== CONFIGURAÇÕES DE HORÁRIO ==="
input string Time_StartTrading = "09:00";             // Início das operações
input string Time_StopTrading = "17:00";              // Fim das operações
input bool   Time_AvoidNews = true;                   // Evitar horários de notícias
input bool   Time_OnlyLiquidHours = true;             // Apenas horários líquidos

// === CONFIGURAÇÕES DE DEBUG ===
input group "=== DEBUG E LOGS ==="
input bool   Debug_Enabled = true;                    // Habilitar debug
input bool   Debug_ShowPanel = true;                  // Mostrar painel de informações
input bool   Debug_LogSignals = true;                 // Log de sinais
input bool   Debug_LogTrades = true;                  // Log de trades

//+------------------------------------------------------------------+
//| Variáveis globais do EA                                         |
//+------------------------------------------------------------------+

// Componentes principais
CSignalGenerator*    g_signalGenerator = NULL;        // Gerador de sinais
CTradeExecutor*      g_tradeExecutor = NULL;          // Executor de trades

// Estado do EA
bool                 g_initialized = false;           // Status de inicialização
bool                 g_waitForHistory = false;        // Aguardando histórico
datetime             g_lastSignalCheck = 0;           // Última verificação de sinal
datetime             g_lastUpdate = 0;                // Última atualização
datetime             g_sessionStart = 0;              // Início da sessão
int                  g_dailyTrades = 0;               // Trades do dia
double               g_dailyProfit = 0;               // Lucro do dia
double               g_dailyLoss = 0;                 // Perda do dia

// Controle de sinais
TradingSignal        g_currentSignal;                 // Sinal atual
TradingSignal        g_lastSignal;                    // Último sinal
bool                 g_signalActive = false;          // Sinal ativo

// Estatísticas
int                  g_totalTrades = 0;               // Total de trades
int                  g_winningTrades = 0;             // Trades vencedores
int                  g_losingTrades = 0;              // Trades perdedores
double               g_totalProfit = 0;               // Lucro total
double               g_totalLoss = 0;                 // Perda total

//+------------------------------------------------------------------+
//| Função de inicialização do EA                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== INICIANDO TREND ANALYZER EA v1.0 ===");
    
    // Validar parâmetros
    if(!ValidateParameters())
    {
        Print("ERRO: Parâmetros inválidos");
        return INIT_PARAMETERS_INCORRECT;
    }

    // Configurar ambiente
    if(!SetupEnvironment())
    {
        Print("ERRO: Falha na configuração do ambiente");
        return INIT_FAILED;
    }

    // Verificar se já existe histórico suficiente
    if(CCoreUtils::HasMinimumBars(EA_Symbol, PERIOD_H4, MA_PERIOD_200))
    {
        if(!InitializeComponents())
        {
            Print("ERRO: Falha na inicialização dos componentes");
            CleanupComponents();
            return INIT_FAILED;
        }
        if(ComponentsValid())
        {
            g_initialized = true;
        }
        else
        {
            Print("ERRO: Componentes inválidos após inicialização");
            CleanupComponents();
            return INIT_FAILED;
        }
    }
    else
    {
        PrintFormat("Aguardando %d barras no H4 para iniciar componentes...", MA_PERIOD_200);
        g_waitForHistory = true;
    }
    
    // Inicializar estatísticas
    InitializeStatistics();

    g_lastUpdate = TimeCurrent();

    if(g_initialized)
        Print("EA inicializado com sucesso para ", EA_Symbol);
    else
        Print("EA em modo de espera - histórico insuficiente");
    Print("Configurações: Lote=", Risk_LotSize, ", Risco=", Risk_RiskPercent, "%, Magic=", EA_MagicNumber);
    
    if(Debug_ShowPanel)
    {
        CreateInfoPanel();
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Função de desinicialização do EA                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=== FINALIZANDO TREND ANALYZER EA ===");
    
    // Limpar componentes
    CleanupComponents();
    
    // Remover objetos gráficos
    if(Debug_ShowPanel)
    {
        RemoveInfoPanel();
    }
    
    // Log final
    PrintFinalStatistics();
    
    string reasonStr = "";
    switch(reason)
    {
        case REASON_PROGRAM:     reasonStr = "EA removido"; break;
        case REASON_REMOVE:      reasonStr = "EA deletado"; break;
        case REASON_RECOMPILE:   reasonStr = "EA recompilado"; break;
        case REASON_CHARTCHANGE: reasonStr = "Mudança de gráfico"; break;
        case REASON_CHARTCLOSE:  reasonStr = "Gráfico fechado"; break;
        case REASON_PARAMETERS:  reasonStr = "Parâmetros alterados"; break;
        case REASON_ACCOUNT:     reasonStr = "Conta alterada"; break;
        default:                 reasonStr = "Motivo desconhecido"; break;
    }
    
    Print("EA finalizado. Motivo: ", reasonStr);
}

//+------------------------------------------------------------------+
//| Função principal do EA (chamada a cada tick)                    |
//+------------------------------------------------------------------+
void OnTick()
{
    // Verificar se EA está habilitado
    if(!EA_Enabled)
    {
        return;
    }

    // Se já inicializado, verificar integridade dos componentes
    if(g_initialized && !ComponentsValid())
    {
        Print("ERRO: Componentes inválidos detectados. Reinicializando...");
        CleanupComponents();
        g_initialized = false;
    }

    // Tentar inicialização se não estiver aguardando histórico
    if(!g_initialized && !g_waitForHistory)
    {
        Print("Tentando inicialização dos componentes...");
        if(!InitializeComponents() || !ComponentsValid())
        {
            Print("ERRO: Falha na inicialização dos componentes");
            CleanupComponents();
            return;
        }
        g_initialized = true;
        Print("Componentes inicializados com sucesso");
    }

    // Se ainda aguardando histórico, verificar condição
    if(g_waitForHistory && !g_initialized)
    {
        if(CCoreUtils::HasMinimumBars(EA_Symbol, PERIOD_H4, MA_PERIOD_200))
        {
            Print("Histórico mínimo alcançado. Inicializando componentes...");
            if(!InitializeComponents() || !ComponentsValid())
            {
                Print("ERRO: Falha na inicialização dos componentes");
                CleanupComponents();
                return;
            }
            g_initialized = true;
            g_waitForHistory = false;
            Print("Componentes inicializados com sucesso");
        }
        else
        {
            static datetime lastLog = 0;
            if(TimeCurrent() - lastLog >= 60)
            {
                PrintFormat("Aguardando histórico H4: %d/%d", Bars(EA_Symbol, PERIOD_H4), MA_PERIOD_200);
                lastLog = TimeCurrent();
            }
            return;
        }
    }

    if(!g_initialized)
    {
        return;
    }
    
    // Verificar horário de trading
    if(!IsValidTradingTime())
    {
        return;
    }
    
    // Atualizar estatísticas diárias
    UpdateDailyStatistics();
    
    // Verificar limites diários
    if(!CheckDailyLimits())
    {
        return;
    }
    
    // Gerenciar posições existentes
    ManageExistingPositions();
    
    // Verificar se é hora de buscar novos sinais
    if(ShouldCheckForSignals())
    {
        CheckForTradingSignals();
    }
    
    // Atualizar painel de informações
    if(Debug_ShowPanel)
    {
        UpdateInfoPanel();
    }
    
    g_lastUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Validar parâmetros de entrada                                   |
//+------------------------------------------------------------------+
bool ValidateParameters()
{
    // Validar símbolo
    if(EA_Symbol == "" || !SymbolSelect(EA_Symbol, true))
    {
        Print("ERRO: Símbolo inválido: ", EA_Symbol);
        return false;
    }
    
    // Validar lote
    if(Risk_LotSize <= 0)
    {
        Print("ERRO: Tamanho do lote deve ser maior que zero");
        return false;
    }
    
    // Validar percentual de risco
    if(Risk_RiskPercent <= 0 || Risk_RiskPercent > 10)
    {
        Print("ERRO: Percentual de risco deve estar entre 0 e 10%");
        return false;
    }
    
    // Validar força mínima do sinal
    if(Signal_MinStrength < 50 || Signal_MinStrength > 100)
    {
        Print("ERRO: Força mínima do sinal deve estar entre 50 e 100%");
        return false;
    }
    
    // Validar confluência mínima
    if(Signal_MinConfluence < 30 || Signal_MinConfluence > 100)
    {
        Print("ERRO: Confluência mínima deve estar entre 30 e 100%");
        return false;
    }
    
    // Validar multiplicador ATR
    if(SL_ATRMultiplier <= 0 || SL_ATRMultiplier > 10)
    {
        Print("ERRO: Multiplicador ATR deve estar entre 0 e 10");
        return false;
    }
    
    // Validar razão risco/recompensa
    if(TP_RiskRewardRatio <= 0 || TP_RiskRewardRatio > 10)
    {
        Print("ERRO: Razão risco/recompensa deve estar entre 0 e 10");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Inicializar componentes do EA                                   |
//+------------------------------------------------------------------+
bool InitializeComponents()
{
    // Criar gerador de sinais
    g_signalGenerator = new CSignalGenerator();
    if(g_signalGenerator == NULL)
    {
        Print("ERRO: Falha ao alocar SignalGenerator");
        return false;
    }
    if(!g_signalGenerator.Initialize(EA_Symbol))
    {
        Print("ERRO: Falha ao inicializar SignalGenerator");
        delete g_signalGenerator;
        g_signalGenerator = NULL;
        return false;
    }

    // Criar executor de trades
    g_tradeExecutor = new CTradeExecutor();
    if(g_tradeExecutor == NULL)
    {
        Print("ERRO: Falha ao alocar TradeExecutor");
        delete g_signalGenerator;
        g_signalGenerator = NULL;
        return false;
    }
    if(!g_tradeExecutor.Initialize(EA_Symbol, EA_MagicNumber))
    {
        Print("ERRO: Falha ao inicializar TradeExecutor");
        delete g_signalGenerator;
        g_signalGenerator = NULL;
        delete g_tradeExecutor;
        g_tradeExecutor = NULL;
        return false;
    }
    
    // Configurar executor
    g_tradeExecutor.SetLotSize(Risk_LotSize);
    g_tradeExecutor.SetRiskPercent(Risk_RiskPercent);
    g_tradeExecutor.SetUseFixedLot(Risk_UseFixedLot);
    g_tradeExecutor.SetATRMultiplier(SL_ATRMultiplier);
    g_tradeExecutor.SetRiskRewardRatio(TP_RiskRewardRatio);
    g_tradeExecutor.SetTrailingStop(SL_UseTrailingStop, SL_TrailingDistance);
    g_tradeExecutor.SetPartialClose(TP_UsePartialClose, TP_PartialPercent);

    // Verificar se todos os módulos internos foram inicializados
    Sleep(200);
    if(!g_signalGenerator.AreModulesInitialized() || !g_tradeExecutor.IsInitialized())
    {
        Print("ERRO: Módulos não foram inicializados corretamente");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Verificar se componentes estão válidos                         |
//+------------------------------------------------------------------+
bool ComponentsValid()
{
    if(g_signalGenerator == NULL || g_tradeExecutor == NULL)
        return false;
    if(!g_signalGenerator.AreModulesInitialized() || !g_tradeExecutor.IsInitialized())
        return false;
    return true;
}

//+------------------------------------------------------------------+
//| Liberar componentes                                              |
//+------------------------------------------------------------------+
void CleanupComponents()
{
    if(g_signalGenerator != NULL)
    {
        delete g_signalGenerator;
        g_signalGenerator = NULL;
    }
    if(g_tradeExecutor != NULL)
    {
        delete g_tradeExecutor;
        g_tradeExecutor = NULL;
    }
}

//+------------------------------------------------------------------+
//| Configurar ambiente de trading                                  |
//+------------------------------------------------------------------+
bool SetupEnvironment()
{
    // Configurar símbolo
    if(!SymbolSelect(EA_Symbol, true))
    {
        Print("ERRO: Não foi possível selecionar o símbolo ", EA_Symbol);
        return false;
    }
    
    // Verificar se o mercado está aberto
    if(!SymbolInfoInteger(EA_Symbol, SYMBOL_TRADE_MODE))
    {
        Print("AVISO: Trading não permitido para ", EA_Symbol);
    }
    
    // Configurar logs
    if(Debug_Enabled)
    {
        CCoreUtils::SetLogLevel(LOG_LEVEL_INFO);
    }
    else
    {
        CCoreUtils::SetLogLevel(LOG_LEVEL_ERROR);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Inicializar estatísticas                                        |
//+------------------------------------------------------------------+
void InitializeStatistics()
{
    g_dailyTrades = 0;
    g_dailyProfit = 0;
    g_dailyLoss = 0;
    g_sessionStart = TimeCurrent();
    
    // Carregar estatísticas históricas se necessário
    LoadHistoricalStatistics();
}

//+------------------------------------------------------------------+
//| Verificar se é horário válido para trading                      |
//+------------------------------------------------------------------+
bool IsValidTradingTime()
{
    datetime currentTime = TimeCurrent();
    
    // Verificar horário de mercado
    if(!CCoreUtils::IsMarketHours(currentTime))
    {
        return false;
    }
    
    // Verificar horário de liquidez se configurado
    if(Time_OnlyLiquidHours && !CCoreUtils::IsLiquidityHours(currentTime))
    {
        return false;
    }
    
    // Verificar horário personalizado
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
    
    // Converter horários de string para minutos
    string startParts[];
    string stopParts[];
    
    if(StringSplit(Time_StartTrading, ':', startParts) != 2 ||
       StringSplit(Time_StopTrading, ':', stopParts) != 2)
    {
        return true; // Se não conseguir parsear, permitir trading
    }
    
    int startMinutes = (int)StringToInteger(startParts[0]) * 60 + (int)StringToInteger(startParts[1]);
    int stopMinutes = (int)StringToInteger(stopParts[0]) * 60 + (int)StringToInteger(stopParts[1]);
    
    if(startMinutes <= stopMinutes)
    {
        return (currentMinutes >= startMinutes && currentMinutes <= stopMinutes);
    }
    else
    {
        // Horário que cruza meia-noite
        return (currentMinutes >= startMinutes || currentMinutes <= stopMinutes);
    }
}

//+------------------------------------------------------------------+
//| Atualizar estatísticas diárias                                  |
//+------------------------------------------------------------------+
void UpdateDailyStatistics()
{
    static datetime lastDay = 0;
    datetime currentDay = (datetime)(TimeCurrent() / 86400) * 86400; // Início do dia
    
    if(lastDay != currentDay)
    {
        // Novo dia - resetar estatísticas diárias
        if(lastDay != 0)
        {
            PrintDailyReport();
        }
        
        g_dailyTrades = 0;
        g_dailyProfit = 0;
        g_dailyLoss = 0;
        lastDay = currentDay;
        
        Print("Nova sessão de trading iniciada: ", TimeToString(currentDay, TIME_DATE));
    }
}

//+------------------------------------------------------------------+
//| Verificar limites diários                                       |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
    // Verificar máximo de trades
    if(Risk_MaxTrades > 0 && g_dailyTrades >= Risk_MaxTrades)
    {
        if(Debug_Enabled)
        {
            Print("Limite diário de trades atingido: ", g_dailyTrades, "/", Risk_MaxTrades);
        }
        return false;
    }
    
    // Verificar perda máxima
    if(Risk_MaxLoss > 0 && g_dailyLoss >= Risk_MaxLoss)
    {
        if(Debug_Enabled)
        {
            Print("Perda máxima diária atingida: ", g_dailyLoss, "/", Risk_MaxLoss);
        }
        return false;
    }
    
    // Verificar lucro máximo
    if(Risk_MaxProfit > 0 && g_dailyProfit >= Risk_MaxProfit)
    {
        if(Debug_Enabled)
        {
            Print("Lucro máximo diário atingido: ", g_dailyProfit, "/", Risk_MaxProfit);
        }
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Gerenciar posições existentes                                   |
//+------------------------------------------------------------------+
void ManageExistingPositions()
{
    if(g_tradeExecutor != NULL)
    {
        g_tradeExecutor.ManagePositions();
    }
}

//+------------------------------------------------------------------+
//| Verificar se deve buscar novos sinais                           |
//+------------------------------------------------------------------+
bool ShouldCheckForSignals()
{
    datetime currentTime = TimeCurrent();
    
    // Verificar intervalo mínimo
    if(currentTime - g_lastSignalCheck < Signal_UpdateInterval)
    {
        return false;
    }
    
    // Não buscar sinais se já há posição aberta
    if(g_tradeExecutor != NULL && g_tradeExecutor.HasOpenPosition())
    {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Verificar sinais de trading                                     |
//+------------------------------------------------------------------+
void CheckForTradingSignals()
{
    g_lastSignalCheck = TimeCurrent();
    
    if(g_signalGenerator == NULL)
    {
        return;
    }
    
    // Gerar novo sinal
    bool signalGenerated = g_signalGenerator.GenerateSignal(EA_Symbol);
    
    if(!signalGenerated || !g_signalGenerator.HasValidSignal())
    {
        g_signalActive = false;
        return;
    }
    
    // Obter sinal atual
    TradingSignal signal = g_signalGenerator.GetCurrentSignal();
    
    // Validar sinal
    if(!ValidateSignal(signal))
    {
        g_signalActive = false;
        return;
    }
    
    // Executar trade baseado no sinal
    ExecuteSignal(signal);
    
    g_currentSignal = signal;
    g_signalActive = true;
    
    if(Debug_LogSignals)
    {
        LogSignal(signal);
    }
}

//+------------------------------------------------------------------+
//| Validar sinal de trading                                        |
//+------------------------------------------------------------------+
bool ValidateSignal(const TradingSignal &signal)
{
    // Verificar se sinal é válido
    if(!signal.isValid || signal.type == SIGNAL_NONE)
    {
        return false;
    }
    
    // Verificar força mínima
    if(signal.strength < Signal_MinStrength)
    {
        if(Debug_Enabled)
        {
            Print("Sinal rejeitado - força insuficiente: ", signal.strength, " < ", Signal_MinStrength);
        }
        return false;
    }
    
    // Verificar confluência mínima
    if(signal.confluence < Signal_MinConfluence)
    {
        if(Debug_Enabled)
        {
            Print("Sinal rejeitado - confluência insuficiente: ", signal.confluence, " < ", Signal_MinConfluence);
        }
        return false;
    }
    
    // Verificar direção permitida
    if(signal.type == SIGNAL_BUY && !EA_AllowLong)
    {
        if(Debug_Enabled)
        {
            Print("Sinal de compra rejeitado - operações longas desabilitadas");
        }
        return false;
    }
    
    if(signal.type == SIGNAL_SELL && !EA_AllowShort)
    {
        if(Debug_Enabled)
        {
            Print("Sinal de venda rejeitado - operações curtas desabilitadas");
        }
        return false;
    }
    
    // Verificar risk/reward mínimo
    if(signal.riskReward < 1.0)
    {
        if(Debug_Enabled)
        {
            Print("Sinal rejeitado - risk/reward insuficiente: ", signal.riskReward);
        }
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Executar sinal de trading                                       |
//+------------------------------------------------------------------+
void ExecuteSignal(const TradingSignal &signal)
{
    if(g_tradeExecutor == NULL)
    {
        return;
    }
    
    // Executar ordem
    bool executed = false;
    
    if(signal.type == SIGNAL_BUY)
    {
        executed = g_tradeExecutor.OpenBuyPosition(signal.entryPrice, signal.stopLoss, signal.takeProfit, EA_Comment);
    }
    else if(signal.type == SIGNAL_SELL)
    {
        executed = g_tradeExecutor.OpenSellPosition(signal.entryPrice, signal.stopLoss, signal.takeProfit, EA_Comment);
    }
    
    if(executed)
    {
        g_dailyTrades++;
        g_totalTrades++;
        
        if(Debug_LogTrades)
        {
            Print("Trade executado: ", EnumToString(signal.type), 
                  " - Entrada: ", signal.entryPrice,
                  " - SL: ", signal.stopLoss,
                  " - TP: ", signal.takeProfit,
                  " - Força: ", signal.strength, "%",
                  " - Confluência: ", signal.confluence, "%");
        }
    }
    else
    {
        if(Debug_Enabled)
        {
            Print("Falha ao executar trade: ", EnumToString(signal.type));
        }
    }
}

//+------------------------------------------------------------------+
//| Carregar estatísticas históricas                                |
//+------------------------------------------------------------------+
void LoadHistoricalStatistics()
{
    // Implementar carregamento de estatísticas de arquivo se necessário
    // Por enquanto, inicializar com zeros
    g_totalTrades = 0;
    g_winningTrades = 0;
    g_losingTrades = 0;
    g_totalProfit = 0;
    g_totalLoss = 0;
}

//+------------------------------------------------------------------+
//| Imprimir relatório diário                                       |
//+------------------------------------------------------------------+
void PrintDailyReport()
{
    Print("=== RELATÓRIO DIÁRIO ===");
    Print("Trades realizados: ", g_dailyTrades);
    Print("Lucro do dia: ", g_dailyProfit);
    Print("Perda do dia: ", g_dailyLoss);
    Print("Resultado líquido: ", g_dailyProfit - g_dailyLoss);
    Print("========================");
}

//+------------------------------------------------------------------+
//| Imprimir estatísticas finais                                    |
//+------------------------------------------------------------------+
void PrintFinalStatistics()
{
    Print("=== ESTATÍSTICAS FINAIS ===");
    Print("Total de trades: ", g_totalTrades);
    Print("Trades vencedores: ", g_winningTrades);
    Print("Trades perdedores: ", g_losingTrades);
    
    if(g_totalTrades > 0)
    {
        double winRate = (double)g_winningTrades / g_totalTrades * 100;
        Print("Taxa de acerto: ", DoubleToString(winRate, 1), "%");
    }
    
    Print("Lucro total: ", g_totalProfit);
    Print("Perda total: ", g_totalLoss);
    Print("Resultado líquido: ", g_totalProfit - g_totalLoss);
    Print("===========================");
}

//+------------------------------------------------------------------+
//| Log de sinal                                                    |
//+------------------------------------------------------------------+
void LogSignal(const TradingSignal &signal)
{
    string logMessage = "SINAL: " + EnumToString(signal.type) + 
                       " | Força: " + DoubleToString(signal.strength, 1) + "%" +
                       " | Confluência: " + DoubleToString(signal.confluence, 1) + "%" +
                       " | Entrada: " + DoubleToString(signal.entryPrice, 2) +
                       " | SL: " + DoubleToString(signal.stopLoss, 2) +
                       " | TP: " + DoubleToString(signal.takeProfit, 2) +
                       " | R/R: " + DoubleToString(signal.riskReward, 2) +
                       " | TF: " + EnumToString(signal.timeframe) +
                       " | Razão: " + signal.reason;
    
    Print(logMessage);
}

//+------------------------------------------------------------------+
//| Criar painel de informações                                     |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
    // Implementar criação de painel gráfico com informações do EA
    // Por enquanto, apenas log
    if(Debug_Enabled)
    {
        Print("Painel de informações habilitado");
    }
}

//+------------------------------------------------------------------+
//| Atualizar painel de informações                                 |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
    // Implementar atualização do painel gráfico
    // Por enquanto, apenas log periódico
    static datetime lastPanelUpdate = 0;
    
    if(TimeCurrent() - lastPanelUpdate > 60) // Atualizar a cada minuto
    {
        if(Debug_Enabled && g_signalActive)
        {
            Print("Status: Sinal ativo - ", EnumToString(g_currentSignal.type), 
                  " | Força: ", g_currentSignal.strength, "%");
        }
        
        lastPanelUpdate = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Remover painel de informações                                   |
//+------------------------------------------------------------------+
void RemoveInfoPanel()
{
    // Implementar remoção de objetos gráficos
    if(Debug_Enabled)
    {
        Print("Painel de informações removido");
    }
}

