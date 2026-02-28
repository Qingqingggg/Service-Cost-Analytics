# Service Cost Analytics 

**Autorin:** Qingqing Ye  
**Ziel:** Dieses Projekt lädt Rechnungs- und Servicedaten, prüft die Daten kurz auf Qualität (z. B. fehlende Werte) und erstellt mehrere Plots

---

## Projektstruktur

```
.
├─ analysis.R
├─ service_records.csv
├─ line_items.csv
├─ figures/
│  ├─ 01_cost_hist.png
│  ├─ 02_cost_over_time.png
│  ├─ 03_cost_drivers.png
│  └─ 04_service_type_cost.png
└─ (optional) outputs/
```

- **analysis.R**: Hauptskript 
- **service_records.csv**: Rechnungs-/Servicebesuche auf Header-Ebene (eine Zeile pro Servicefall)
- **line_items.csv**: Positionen/Leistungen pro Servicefall (mehrere Zeilen pro Servicefall möglich)
- **figures/**: Exportierte Diagramme (automatisch erstellt)

---

## Voraussetzungen

### R-Pakete
Das Skript nutzt:

- `tidyverse`
- `lubridate`
- `scales`
- `janitor`
- `ggthemes`

Installieren:

```r
install.packages(c("tidyverse", "lubridate", "scales", "janitor", "ggthemes"))
```

### Dateien
Lege **service_records.csv** und **line_items.csv** ins Projekt-Root (gleicher Ordner wie `analysis.R`).

---

## Ausführen In RStudio
1. Projekt/Ordner öffnen
2. `analysis.R` öffnen
3. Skript ausführen 


## Datenannahmen

### service_records.csv (Beispiele relevanter Spalten)
- `service_id` 
- `invoice_number` 
- `visit_date` 
- `total_payment_due` 
- Kostenkomponenten (für Kostentreiber):
  - `labor_total`
  - `parts_total`
  - `gas_oil_lube_total`
  - `sublet_total`
  - `misc_charges`
  - `sales_tax`
  - `adjustments`
- optionale Meta-Infos:
  - `vehicle_make`, `vehicle_model`

### line_items.csv (Beispiele relevanter Spalten)
- `service_id` (Join-Key auf service_records)
- `service_type` (Kategorisierung der Leistung)
- `line_total` (Kosten der Position)

---

## Was das Skript macht

### 1) Laden & Standardisieren
- CSV Import
- Spaltennamen werden via `janitor::clean_names()` vereinheitlicht (snake_case)

### 2) Parsing & Hauptmetrik
- `visit_date` wird in ein echtes Datum umgewandelt
- `month` wird als Monatsbucket erzeugt
- `cost` wird als `total_payment_due` definiert

### 3) Datenchecks (Konsole)
- Missing-Rate pro Spalte
- Basisstatistiken zu `cost` (n, NA, 0, negativ, min/median/mean/max)
- Top-3 teuerste Rechnungen 

### 4) Visualisierungen 
1. **01_cost_hist.png** – Kostenverteilung (Histogramm)
2. **02_cost_over_time.png** – Monatliche Gesamtkosten 
3. **03_cost_drivers.png** – Kostentreiber (Summe der Komponenten)
4. **04_service_type_cost.png** – Top-Servicearten nach Line-Item-Kosten

---

## Interpretation / typische Insights

- **Histogramm**
- **Zeitreihe**: erkennt Trends oder Ausreißermonate
- **Kostentreiber**: identifiziert die größten Komponenten 
- **Top Service Types**: zeigt, welche Servicearten die meisten Kosten verursachen
- **Konzentrationskurve**: quantifiziert, wie viel Anteil der Gesamtkosten von wenigen teuren Fällen kommt

---


## Datenquelle & Referenzen

- **Dataset (Kaggle):** *My Car’s Maintenance Diary: Real Service Cost Data*  
  https://www.kaggle.com/datasets/josephnehrenz/my-cars-maintenance-diary-real-service-cost-data

- **Quick-Start Notebook (Kaggle):** *Car Service Data – Quick Start Notebook* (josephnehrenz)  
  https://www.kaggle.com/code/josephnehrenz/car-service-data-quick-start-notebook

