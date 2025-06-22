//+------------------------------------------------------------------+
//| ValidationVisualizer.mqh - Desenho de linhas de validação       |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef VALIDATION_VISUALIZER_H
#define VALIDATION_VISUALIZER_H
#property strict

#include <Object.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "IValidationVisualizer.mqh"
#include "../PriceAction/TrendLines.mqh"
#include "../PriceAction/SupportResistance.mqh"

//+------------------------------------------------------------------+
//| Classe para visualização de validações                           |
//+------------------------------------------------------------------+
class CValidationVisualizer : public IValidationVisualizer
{
private:
    string m_symbol;        // Símbolo
    long   m_chartID;       // ID do gráfico
    string m_ltaName;       // Nome do objeto LTA
    string m_ltbName;       // Nome do objeto LTB
    string m_srPrefix;      // Prefixo para níveis SR
public:
    // Construtor
    CValidationVisualizer()
    {
        m_symbol   = "";
        m_chartID  = 0;
        m_ltaName  = "VALID_LTA";
        m_ltbName  = "VALID_LTB";
        m_srPrefix = "VALID_SR_";
    }

    // Inicializar
    bool Initialize(string symbol, long chartID = 0)
    {
        if(symbol == "" || symbol == NULL)
            return false;
        m_symbol  = symbol;
        m_chartID = (chartID == 0 ? ChartID() : chartID);
        return true;
    }

    // Desenhar/atualizar linhas de tendência
    void UpdateTrendLines(const CTrendLines &trendLines)
    {
        if(trendLines.IsLTAValid())
        {
            TrendLine lta = trendLines.GetLTA();
            CreateOrUpdateLine(m_ltaName, lta.time1, lta.price1, lta.time2, lta.price2, clrGreen);
        }
        else
        {
            ObjectDelete(m_chartID, m_ltaName);
        }

        if(trendLines.IsLTBValid())
        {
            TrendLine ltb = trendLines.GetLTB();
            CreateOrUpdateLine(m_ltbName, ltb.time1, ltb.price1, ltb.time2, ltb.price2, clrRed);
        }
        else
        {
            ObjectDelete(m_chartID, m_ltbName);
        }
    }

    // Desenhar/atualizar níveis de suporte e resistência
    void UpdateSupportResistance(const CSupportResistance &sr)
    {
        RemoveSRObjects();

        SR_Level levels[];
        sr.GetAllLevels(levels);
        for(int i = 0; i < ArraySize(levels); i++)
        {
            SR_Level level = levels[i];
            string name   = m_srPrefix + IntegerToString(i);
            color  clr    = level.isSupport ? clrDodgerBlue : clrTomato;
            CreateOrUpdateHLine(name, level.price, clr);
        }
    }

private:
    // Criar ou atualizar linha de tendência
    void CreateOrUpdateLine(string name, datetime t1, double p1, datetime t2, double p2, color clr)
    {
        if(ObjectFind(m_chartID, name) < 0)
        {
            ObjectCreate(m_chartID, name, OBJ_TREND, 0, t1, p1, t2, p2);
            ObjectSetInteger(m_chartID, name, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(m_chartID, name, OBJPROP_WIDTH, 2);
        }
        else
        {
            ObjectMove(m_chartID, name, 0, t1, p1);
            ObjectMove(m_chartID, name, 1, t2, p2);
        }
        ObjectSetInteger(m_chartID, name, OBJPROP_COLOR, clr);
    }

    // Criar ou atualizar linha horizontal
    void CreateOrUpdateHLine(string name, double price, color clr)
    {
        datetime now = TimeCurrent();
        if(ObjectFind(m_chartID, name) < 0)
        {
            ObjectCreate(m_chartID, name, OBJ_HLINE, 0, now, price);
            ObjectSetInteger(m_chartID, name, OBJPROP_WIDTH, 1);
        }
        else
        {
            ObjectSetDouble(m_chartID, name, OBJPROP_PRICE, price);
        }
        ObjectSetInteger(m_chartID, name, OBJPROP_COLOR, clr);
    }

    // Remover linhas SR existentes
    void RemoveSRObjects()
    {
        for(int i = 0;; i++)
        {
            string name = m_srPrefix + IntegerToString(i);
            if(ObjectFind(m_chartID, name) < 0)
                break;
            ObjectDelete(m_chartID, name);
        }
    }
};

#endif // VALIDATION_VISUALIZER_H

