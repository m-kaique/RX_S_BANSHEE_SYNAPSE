//+------------------------------------------------------------------+
//| ChartDrawer.mqh - Desenho de Objetos no Gráfico                  |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef CHART_DRAWER_H
#define CHART_DRAWER_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"
#include "../PriceAction/TrendLines.mqh"
#include "../PriceAction/SupportResistance.mqh"

//+------------------------------------------------------------------+
//| Classe responsável por desenhar e atualizar objetos no gráfico   |
//+------------------------------------------------------------------+
class CChartDrawer : public CObject
{
private:
    string m_symbol; // Símbolo utilizado

public:
    //+------------------------------------------------------------------+
    //| Construtor                                                      |
    //+------------------------------------------------------------------+
    CChartDrawer()
    {
        m_symbol = "";
    }

    //+------------------------------------------------------------------+
    //| Inicialização                                                   |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        m_symbol = (symbol == "" || symbol == NULL) ? Symbol() : symbol;
        return true;
    }

    //+------------------------------------------------------------------+
    //| Atualizar linhas de tendência                                   |
    //+------------------------------------------------------------------+
    void UpdateTrendLines(CTrendLines &trendLines)
    {
        DrawTrendLine(trendLines.GetLTA(), "LTA_" + m_symbol, clrLime);
        DrawTrendLine(trendLines.GetLTB(), "LTB_" + m_symbol, clrRed);
    }

    //+------------------------------------------------------------------+
    //| Atualizar níveis de suporte/resistência                         |
    //+------------------------------------------------------------------+
    void UpdateSupportResistance(CSupportResistance &sr, int maxLevels=5)
    {
        string prefixSup = "SUP_" + m_symbol + "_";
        string prefixRes = "RES_" + m_symbol + "_";

        // Limpar objetos existentes
        DeleteObjectsByPrefix(prefixSup);
        DeleteObjectsByPrefix(prefixRes);

        SR_Level levels[];
        sr.GetAllLevels(levels);
        int count = MathMin(ArraySize(levels), maxLevels);

        for(int i=0; i<count; i++)
        {
            string objName = (levels[i].isSupport ? prefixSup : prefixRes) + IntegerToString(i);
            color  objColor = levels[i].isSupport ? clrDodgerBlue : clrOrange;
            DrawHLine(levels[i].price, objName, objColor);
        }
    }

private:
    //+------------------------------------------------------------------+
    //| Desenhar ou atualizar linha de tendência                        |
    //+------------------------------------------------------------------+
    void DrawTrendLine(const TrendLine &line, string name, color clr)
    {
        if(!line.isValid)
        {
            ObjectDelete(0, name);
            return;
        }

        if(!ObjectFind(0, name))
        {
            ObjectCreate(0, name, OBJ_TREND, 0, line.time1, line.price1, line.time2, line.price2);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
        }
        else
        {
            ObjectMove(0, name, 0, line.time1, line.price1);
            ObjectMove(0, name, 1, line.time2, line.price2);
        }
    }

    //+------------------------------------------------------------------+
    //| Desenhar ou atualizar linha horizontal                           |
    //+------------------------------------------------------------------+
    void DrawHLine(double price, string name, color clr)
    {
        if(price == 0)
        {
            ObjectDelete(0, name);
            return;
        }

        if(!ObjectFind(0, name))
        {
            ObjectCreate(0, name, OBJ_HLINE, 0, TimeCurrent(), price);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        }
        else
        {
            ObjectSetDouble(0, name, OBJPROP_PRICE, price);
        }
    }

    //+------------------------------------------------------------------+
    //| Remover objetos com prefixo específico                           |
    //+------------------------------------------------------------------+
    void DeleteObjectsByPrefix(string prefix)
    {
        int total = ObjectsTotal(0, -1, -1);
        for(int i = total - 1; i >= 0; i--)
        {
            string objName = ObjectName(0, i, -1, -1);
            if(StringFind(objName, prefix) == 0)
                ObjectDelete(0, objName);
        }
    }
};

#endif // CHART_DRAWER_H
