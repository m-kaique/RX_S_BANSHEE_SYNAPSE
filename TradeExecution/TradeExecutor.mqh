//+------------------------------------------------------------------+
//| TradeExecutor.mqh - Executor de Trades                          |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef TRADE_EXECUTOR_H
#define TRADE_EXECUTOR_H
#property strict

#include <Object.mqh>
#include <Trade/Trade.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"

extern int    g_winningTrades;
extern int    g_losingTrades;
extern double g_dailyProfit;
extern double g_dailyLoss;
extern double g_totalProfit;
extern double g_totalLoss;

//+------------------------------------------------------------------+
//| Classe Executora de Trades                                      |
//+------------------------------------------------------------------+
class CTradeExecutor : public CObject
{
private:
    string               m_symbol;           // Símbolo
    int                  m_magicNumber;      // Número mágico
    
    // Configurações de trading
    double               m_lotSize;          // Tamanho do lote
    double               m_riskPercent;      // Percentual de risco
    bool                 m_useFixedLot;      // Usar lote fixo
    double               m_atrMultiplier;    // Multiplicador ATR
    double               m_riskRewardRatio;  // Razão risco/recompensa
    
    // Configurações de trailing stop
    bool                 m_useTrailingStop;  // Usar trailing stop
    double               m_trailingDistance; // Distância do trailing
    
    // Configurações de fechamento parcial
    bool                 m_usePartialClose;  // Usar fechamento parcial
    double               m_partialPercent;   // Percentual para fechamento parcial
    
    // Objeto de trading
    CTrade               m_trade;            // Objeto CTrade
    
    // Estado das posições
    ulong                m_currentTicket;    // Ticket da posição atual
    bool                 m_hasPosition;      // Tem posição aberta
    bool                 m_partialClosed;    // Fechamento parcial executado
    
    // Estatísticas
    int                  m_totalTrades;      // Total de trades
    int                  m_winningTrades;    // Trades vencedores
    int                  m_losingTrades;     // Trades perdedores
    double               m_totalProfit;      // Lucro total
    double               m_totalLoss;        // Perda total
    
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CTradeExecutor()
    {
        m_symbol = "";
        m_magicNumber = 0;
        
        m_lotSize = 0.1;
        m_riskPercent = 2.0;
        m_useFixedLot = true;
        m_atrMultiplier = 2.0;
        m_riskRewardRatio = 2.0;
        
        m_useTrailingStop = false;
        m_trailingDistance = 100.0;
        
        m_usePartialClose = false;
        m_partialPercent = 50.0;
        
        m_currentTicket = 0;
        m_hasPosition = false;
        m_partialClosed = false;
        
        m_totalTrades = 0;
        m_winningTrades = 0;
        m_losingTrades = 0;
        m_totalProfit = 0;
        m_totalLoss = 0;
        
        m_lastUpdate = 0;
        m_initialized = false;
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CTradeExecutor()
    {
        // Nada específico para limpar
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar executor de trades                                  |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol, int magicNumber)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para TradeExecutor");
            return false;
        }
        
        if(magicNumber <= 0)
        {
            CCoreUtils::LogError("Número mágico inválido para TradeExecutor");
            return false;
        }
        
        m_symbol = symbol;
        m_magicNumber = magicNumber;
        
        // Configurar objeto de trading
        m_trade.SetExpertMagicNumber(m_magicNumber);
        m_trade.SetMarginMode();
        m_trade.SetTypeFillingBySymbol(m_symbol);
        
        // Verificar se trading é permitido
        if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        {
            CCoreUtils::LogError("Trading não permitido no terminal");
            return false;
        }
        
        if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
            CCoreUtils::LogError("Trading não permitido para EAs");
            return false;
        }
        
        // Verificar símbolo
        if(!SymbolSelect(m_symbol, true))
        {
            CCoreUtils::LogError("Não foi possível selecionar símbolo: " + m_symbol);
            return false;
        }
        
        m_initialized = true;
        CCoreUtils::LogInfo("TradeExecutor inicializado para " + symbol + " com magic " + IntegerToString(magicNumber));
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Abrir posição de compra                                        |
    //+------------------------------------------------------------------+
    bool OpenBuyPosition(double entryPrice, double stopLoss, double takeProfit, string comment = "")
    {
        if(!m_initialized)
        {
            CCoreUtils::LogError("TradeExecutor não inicializado");
            return false;
        }
        
        if(m_hasPosition)
        {
            CCoreUtils::LogWarning("Já existe posição aberta");
            return false;
        }
        
        // Calcular lote
        double lotSize = CalculateLotSize(entryPrice, stopLoss);
        if(lotSize <= 0)
        {
            CCoreUtils::LogError("Tamanho do lote inválido");
            return false;
        }
        
        // Normalizar preços
        double normalizedEntry = NormalizePrice(entryPrice);
        double normalizedSL = NormalizePrice(stopLoss);
        double normalizedTP = NormalizePrice(takeProfit);
        
        // Validar níveis
        if(!ValidateLevels(ORDER_TYPE_BUY, normalizedEntry, normalizedSL, normalizedTP))
        {
            CCoreUtils::LogError("Níveis de preço inválidos para compra");
            return false;
        }
        
        // Executar ordem
        bool result = m_trade.Buy(lotSize, m_symbol, normalizedEntry, normalizedSL, normalizedTP, comment);
        
        if(result)
        {
            m_currentTicket = m_trade.ResultOrder();
            m_hasPosition = true;
            m_partialClosed = false;
            m_totalTrades++;
            
            CCoreUtils::LogInfo("Posição de compra aberta - Ticket: " + IntegerToString(m_currentTicket) + 
                              ", Lote: " + DoubleToString(lotSize, 2) + 
                              ", Entrada: " + DoubleToString(normalizedEntry, 2));
        }
        else
        {
            int ret = m_trade.ResultRetcode();
            string msg = TradeResultRetcodeDescription(ret);
            CCoreUtils::LogError("Falha ao abrir posição de compra - Retcode: " + IntegerToString(ret) + " - " + msg);
        }
        
        return result;
    }
    
    //+------------------------------------------------------------------+
    //| Abrir posição de venda                                         |
    //+------------------------------------------------------------------+
    bool OpenSellPosition(double entryPrice, double stopLoss, double takeProfit, string comment = "")
    {
        if(!m_initialized)
        {
            CCoreUtils::LogError("TradeExecutor não inicializado");
            return false;
        }
        
        if(m_hasPosition)
        {
            CCoreUtils::LogWarning("Já existe posição aberta");
            return false;
        }
        
        // Calcular lote
        double lotSize = CalculateLotSize(entryPrice, stopLoss);
        if(lotSize <= 0)
        {
            CCoreUtils::LogError("Tamanho do lote inválido");
            return false;
        }
        
        // Normalizar preços
        double normalizedEntry = NormalizePrice(entryPrice);
        double normalizedSL = NormalizePrice(stopLoss);
        double normalizedTP = NormalizePrice(takeProfit);
        
        // Validar níveis
        if(!ValidateLevels(ORDER_TYPE_SELL, normalizedEntry, normalizedSL, normalizedTP))
        {
            CCoreUtils::LogError("Níveis de preço inválidos para venda");
            return false;
        }
        
        // Executar ordem
        bool result = m_trade.Sell(lotSize, m_symbol, normalizedEntry, normalizedSL, normalizedTP, comment);
        
        if(result)
        {
            m_currentTicket = m_trade.ResultOrder();
            m_hasPosition = true;
            m_partialClosed = false;
            m_totalTrades++;
            
            CCoreUtils::LogInfo("Posição de venda aberta - Ticket: " + IntegerToString(m_currentTicket) + 
                              ", Lote: " + DoubleToString(lotSize, 2) + 
                              ", Entrada: " + DoubleToString(normalizedEntry, 2));
        }
        else
        {
            int ret = m_trade.ResultRetcode();
            string msg = TradeResultRetcodeDescription(ret);
            CCoreUtils::LogError("Falha ao abrir posição de venda - Retcode: " + IntegerToString(ret) + " - " + msg);
        }
        
        return result;
    }
    
    //+------------------------------------------------------------------+
    //| Gerenciar posições existentes                                  |
    //+------------------------------------------------------------------+
    void ManagePositions()
    {
        if(!m_initialized || !m_hasPosition)
        {
            return;
        }
        
        // Verificar se posição ainda existe
        if(!PositionSelectByTicket(m_currentTicket))
        {
            // Posição foi fechada
            OnPositionClosed();
            return;
        }
        
        // Aplicar trailing stop
        if(m_useTrailingStop)
        {
            ApplyTrailingStop();
        }
        
        // Aplicar fechamento parcial
        if(m_usePartialClose && !m_partialClosed)
        {
            CheckPartialClose();
        }
        
        m_lastUpdate = TimeCurrent();
    }
    
    //+------------------------------------------------------------------+
    //| Fechar posição atual                                           |
    //+------------------------------------------------------------------+
    bool CloseCurrentPosition(string comment = "Manual Close")
    {
        if(!m_initialized || !m_hasPosition)
        {
            return false;
        }
        
        if(!PositionSelectByTicket(m_currentTicket))
        {
            m_hasPosition = false;
            return false;
        }
        
        bool result = m_trade.PositionClose(m_currentTicket);
        
        if(result)
        {
            CCoreUtils::LogInfo("Posição fechada manualmente - Ticket: " + IntegerToString(m_currentTicket));
            OnPositionClosed();
        }
        else
        {
            CCoreUtils::LogError("Falha ao fechar posição - Erro: " + IntegerToString(GetLastError()));
        }
        
        return result;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se tem posição aberta                                |
    //+------------------------------------------------------------------+
    bool HasOpenPosition() const { return m_hasPosition; }
    
    //+------------------------------------------------------------------+
    //| Obter ticket da posição atual                                  |
    //+------------------------------------------------------------------+
    ulong GetCurrentTicket() const { return m_currentTicket; }
    
    //+------------------------------------------------------------------+
    //| Configurar tamanho do lote                                     |
    //+------------------------------------------------------------------+
    void SetLotSize(double lotSize) { m_lotSize = lotSize; }
    
    //+------------------------------------------------------------------+
    //| Configurar percentual de risco                                 |
    //+------------------------------------------------------------------+
    void SetRiskPercent(double riskPercent) { m_riskPercent = riskPercent; }
    
    //+------------------------------------------------------------------+
    //| Configurar uso de lote fixo                                    |
    //+------------------------------------------------------------------+
    void SetUseFixedLot(bool useFixedLot) { m_useFixedLot = useFixedLot; }
    
    //+------------------------------------------------------------------+
    //| Configurar multiplicador ATR                                   |
    //+------------------------------------------------------------------+
    void SetATRMultiplier(double atrMultiplier) { m_atrMultiplier = atrMultiplier; }
    
    //+------------------------------------------------------------------+
    //| Configurar razão risco/recompensa                              |
    //+------------------------------------------------------------------+
    void SetRiskRewardRatio(double riskRewardRatio) { m_riskRewardRatio = riskRewardRatio; }
    
    //+------------------------------------------------------------------+
    //| Configurar trailing stop                                       |
    //+------------------------------------------------------------------+
    void SetTrailingStop(bool useTrailingStop, double trailingDistance)
    {
        m_useTrailingStop = useTrailingStop;
        m_trailingDistance = trailingDistance;
    }
    
    //+------------------------------------------------------------------+
    //| Configurar fechamento parcial                                  |
    //+------------------------------------------------------------------+
    void SetPartialClose(bool usePartialClose, double partialPercent)
    {
        m_usePartialClose = usePartialClose;
        m_partialPercent = partialPercent;
    }
    
    //+------------------------------------------------------------------+
    //| Obter estatísticas                                             |
    //+------------------------------------------------------------------+
    int GetTotalTrades() const { return m_totalTrades; }
    int GetWinningTrades() const { return m_winningTrades; }
    int GetLosingTrades() const { return m_losingTrades; }
    double GetTotalProfit() const { return m_totalProfit; }
    double GetTotalLoss() const { return m_totalLoss; }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

private:
    //+------------------------------------------------------------------+
    //| Calcular tamanho do lote                                       |
    //+------------------------------------------------------------------+
    double CalculateLotSize(double entryPrice, double stopLoss)
    {
        if(m_useFixedLot)
        {
            return m_lotSize;
        }
        
        // Calcular lote baseado no risco
        double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = accountBalance * (m_riskPercent / 100.0);
        
        double stopDistance = MathAbs(entryPrice - stopLoss);
        if(stopDistance <= 0)
        {
            return m_lotSize; // Fallback para lote fixo
        }
        
        double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
        
        if(tickValue <= 0 || tickSize <= 0)
        {
            return m_lotSize; // Fallback para lote fixo
        }
        
        double pointValue = tickValue * (SymbolInfoDouble(m_symbol, SYMBOL_POINT) / tickSize);
        double riskInPoints = stopDistance / SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        
        double calculatedLot = riskAmount / (riskInPoints * pointValue);
        
        // Normalizar lote
        double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
        
        calculatedLot = MathMax(minLot, MathMin(maxLot, calculatedLot));
        calculatedLot = NormalizeLot(calculatedLot, lotStep);
        
        return calculatedLot;
    }
    
    //+------------------------------------------------------------------+
    //| Normalizar lote                                                |
    //+------------------------------------------------------------------+
    double NormalizeLot(double lot, double lotStep)
    {
        if(lotStep <= 0) return lot;
        
        return MathRound(lot / lotStep) * lotStep;
    }
    
    //+------------------------------------------------------------------+
    //| Normalizar preço                                               |
    //+------------------------------------------------------------------+
    double NormalizePrice(double price)
    {
        double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
        if(tickSize <= 0) return price;
        
        return MathRound(price / tickSize) * tickSize;
    }
    
    //+------------------------------------------------------------------+
    //| Validar níveis de preço                                        |
    //+------------------------------------------------------------------+
    bool ValidateLevels(ENUM_ORDER_TYPE orderType, double entry, double stopLoss, double takeProfit)
    {
        double minDistance = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        
        if(orderType == ORDER_TYPE_BUY)
        {
            // Para compra: SL < Entry < TP
            if(stopLoss >= entry || takeProfit <= entry)
            {
                return false;
            }
            
            // Verificar distância mínima
            if((entry - stopLoss) < minDistance || (takeProfit - entry) < minDistance)
            {
                return false;
            }
        }
        else if(orderType == ORDER_TYPE_SELL)
        {
            // Para venda: TP < Entry < SL
            if(takeProfit >= entry || stopLoss <= entry)
            {
                return false;
            }
            
            // Verificar distância mínima
            if((stopLoss - entry) < minDistance || (entry - takeProfit) < minDistance)
            {
                return false;
            }
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Aplicar trailing stop                                          |
    //+------------------------------------------------------------------+
    void ApplyTrailingStop()
    {
        if(!PositionSelectByTicket(m_currentTicket))
        {
            return;
        }
        
        double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        ENUM_POSITION_TYPE positionType =
            (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        
        double trailingPoints = CCoreUtils::PointsToPrice(m_trailingDistance, m_symbol);
        double newSL = 0;
        bool shouldModify = false;
        
        if(positionType == POSITION_TYPE_BUY)
        {
            // Para compra: mover SL para cima
            newSL = currentPrice - trailingPoints;
            
            if(newSL > currentSL && newSL > openPrice)
            {
                shouldModify = true;
            }
        }
        else if(positionType == POSITION_TYPE_SELL)
        {
            // Para venda: mover SL para baixo
            newSL = currentPrice + trailingPoints;
            
            if((currentSL == 0 || newSL < currentSL) && newSL < openPrice)
            {
                shouldModify = true;
            }
        }
        
        if(shouldModify)
        {
            double currentTP = PositionGetDouble(POSITION_TP);
            newSL = NormalizePrice(newSL);
            
            if(m_trade.PositionModify(m_currentTicket, newSL, currentTP))
            {
                CCoreUtils::LogInfo("Trailing stop aplicado - Novo SL: " + DoubleToString(newSL, 2));
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Verificar fechamento parcial                                   |
    //+------------------------------------------------------------------+
    void CheckPartialClose()
    {
        if(!PositionSelectByTicket(m_currentTicket))
        {
            return;
        }
        
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        double takeProfit = PositionGetDouble(POSITION_TP);
        ENUM_POSITION_TYPE positionType =
            (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        
        bool shouldPartialClose = false;
        
        if(positionType == POSITION_TYPE_BUY && takeProfit > 0)
        {
            // Para compra: verificar se atingiu 50% do TP
            double targetDistance = takeProfit - openPrice;
            double currentDistance = currentPrice - openPrice;
            
            if(currentDistance >= targetDistance * 0.5)
            {
                shouldPartialClose = true;
            }
        }
        else if(positionType == POSITION_TYPE_SELL && takeProfit > 0)
        {
            // Para venda: verificar se atingiu 50% do TP
            double targetDistance = openPrice - takeProfit;
            double currentDistance = openPrice - currentPrice;
            
            if(currentDistance >= targetDistance * 0.5)
            {
                shouldPartialClose = true;
            }
        }
        
        if(shouldPartialClose)
        {
            ExecutePartialClose();
        }
    }
    
    //+------------------------------------------------------------------+
    //| Executar fechamento parcial                                    |
    //+------------------------------------------------------------------+
    void ExecutePartialClose()
    {
        if(!PositionSelectByTicket(m_currentTicket))
        {
            return;
        }
        
        double currentVolume = PositionGetDouble(POSITION_VOLUME);
        double partialVolume = currentVolume * (m_partialPercent / 100.0);
        
        // Normalizar volume
        double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
        
        partialVolume = MathMax(minLot, NormalizeLot(partialVolume, lotStep));
        
        if(partialVolume >= minLot && partialVolume < currentVolume)
        {
            if(m_trade.PositionClosePartial(m_currentTicket, partialVolume))
            {
                m_partialClosed = true;
                CCoreUtils::LogInfo("Fechamento parcial executado - Volume: " + DoubleToString(partialVolume, 2));
                
                // Mover SL para breakeven
                MoveStopToBreakeven();
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Mover stop para breakeven                                      |
    //+------------------------------------------------------------------+
    void MoveStopToBreakeven()
    {
        if(!PositionSelectByTicket(m_currentTicket))
        {
            return;
        }
        
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentTP = PositionGetDouble(POSITION_TP);
        double normalizedSL = NormalizePrice(openPrice);
        
        if(m_trade.PositionModify(m_currentTicket, normalizedSL, currentTP))
        {
            CCoreUtils::LogInfo("Stop movido para breakeven: " + DoubleToString(normalizedSL, 2));
        }
    }
    
    //+------------------------------------------------------------------+
    //| Callback quando posição é fechada                              |
    //+------------------------------------------------------------------+
    void OnPositionClosed()
    {
        // Atualizar estatísticas
        double positionProfit = 0;

        if(HistorySelectByPosition(m_currentTicket))
        {
            int dealsTotal = HistoryDealsTotal();

            for(int i = 0; i < dealsTotal; i++)
            {
                ulong dealTicket = HistoryDealGetTicket(i);

                if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == m_currentTicket)
                {
                    positionProfit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                }
            }
        }

        if(positionProfit > 0)
        {
            m_winningTrades++;
            m_totalProfit += positionProfit;

            g_winningTrades++;
            g_totalProfit += positionProfit;
            g_dailyProfit += positionProfit;
        }
        else if(positionProfit < 0)
        {
            m_losingTrades++;
            m_totalLoss += MathAbs(positionProfit);

            g_losingTrades++;
            g_totalLoss += MathAbs(positionProfit);
            g_dailyLoss += MathAbs(positionProfit);
        }
        
        CCoreUtils::LogInfo("Posição fechada - Ticket: " + IntegerToString(m_currentTicket));

        m_hasPosition = false;
        m_currentTicket = 0;
        m_partialClosed = false;
    }
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "TradeExecutor não inicializado";
        }
        
        string info = "=== TRADE EXECUTOR ===\n";
        info += "Símbolo: " + m_symbol + "\n";
        info += "Magic Number: " + IntegerToString(m_magicNumber) + "\n";
        info += "Lote: " + DoubleToString(m_lotSize, 2) + "\n";
        info += "Risco: " + DoubleToString(m_riskPercent, 1) + "%\n";
        info += "Lote fixo: " + (m_useFixedLot ? "SIM" : "NÃO") + "\n";
        info += "Trailing stop: " + (m_useTrailingStop ? "SIM" : "NÃO") + "\n";
        info += "Fechamento parcial: " + (m_usePartialClose ? "SIM" : "NÃO") + "\n\n";
        
        info += "POSIÇÃO ATUAL:\n";
        if(m_hasPosition)
        {
            info += "Ticket: " + IntegerToString(m_currentTicket) + "\n";
            info += "Fechamento parcial: " + (m_partialClosed ? "SIM" : "NÃO") + "\n";
        }
        else
        {
            info += "Nenhuma posição aberta\n";
        }
        
        info += "\nESTATÍSTICAS:\n";
        info += "Total de trades: " + IntegerToString(m_totalTrades) + "\n";
        info += "Trades vencedores: " + IntegerToString(m_winningTrades) + "\n";
        info += "Trades perdedores: " + IntegerToString(m_losingTrades) + "\n";
        
        if(m_totalTrades > 0)
        {
            double winRate = (double)m_winningTrades / m_totalTrades * 100;
            info += "Taxa de acerto: " + DoubleToString(winRate, 1) + "%\n";
        }
        
        info += "Lucro total: " + DoubleToString(m_totalProfit, 2) + "\n";
        info += "Perda total: " + DoubleToString(m_totalLoss, 2) + "\n";
        info += "Resultado líquido: " + DoubleToString(m_totalProfit - m_totalLoss, 2) + "\n";
        
        info += "\nÚltima atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // TRADE_EXECUTOR_H

