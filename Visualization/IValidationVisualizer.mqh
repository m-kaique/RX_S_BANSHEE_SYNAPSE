//+------------------------------------------------------------------+
//| IValidationVisualizer.mqh - Interface para visualização         |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef I_VALIDATION_VISUALIZER_H
#define I_VALIDATION_VISUALIZER_H
#property strict

#include <Object.mqh>

class CTrendLines;
class CSupportResistance;

//+------------------------------------------------------------------+
//| Interface para visualizadores de validação                       |
//+------------------------------------------------------------------+
class IValidationVisualizer : public CObject
{
public:
    // Atualiza desenho das linhas de tendência durante a validação
    virtual void UpdateTrendLines(const CTrendLines *trendLines) = 0;

    // Atualiza desenho dos níveis de suporte e resistência
    virtual void UpdateSupportResistance(const CSupportResistance *sr) = 0;
};

#endif // I_VALIDATION_VISUALIZER_H
