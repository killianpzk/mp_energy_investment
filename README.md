# Master Thesis : "Monetary Policy and Energy Investment: Evidence from U.S. Interconnection Queues"

**Project Status:** Under Review

This repository contains all the source files, data, scripts, and drafts for my Master's thesis on the link between monetary policy and energy investments. 

---

## 📝 Overview

*   **Author:** [Killian Pliszczak](https://www.linkedin.com/in/killian-pliszczak/?locale=en-US).
*   **Committee:** [Olivier Darmouni](https://sites.google.com/site/olivierdarmouni/), [Johan Hombert](https://johanhombert.github.io/)
*   **Academic Year:** 2025-2026
*   **Institution:** HEC Paris

### Abstract

Unexpected monetary policy shocks pose a substantial risk to capital-intensive infrastructure, yet their transmission to early-stage energy investments remains poorly understood. Combining granular project-level records from US interconnection queues with high-frequency monetary surprises, we trace the causal impact of policy shocks on project entry and withdrawal dynamics using microeconomic discrete-time duration models and aggregate Local Projections Instrumental Variables (LP-IV). At the micro level, a contractionary shock temporarily increases project cancellation hazards, but this eviction is confined to small-scale ventures and does not aggregate into a statistically significant decline in withdrawn capacity. In contrast, monetary tightening exerts a powerful deterrent effect on prospective projects, where upfront sunk capital remains low. Following an exogenous 25 bps surprise in the 10-year yield, incoming renewable capacity contracts by roughly 14% three months post-shock, alongside a sharp decline in project counts. Finally, this entry slowdown is heavily concentrated in wind and solar assets, while conventional fossil generation remains virtually insulated. These findings suggest that monetary tightening disproportionately slows renewable deployment, raising the risk of long-term carbon lock-in across regional power grids.

---

## 📂 Repository Structure

*Note: This project is currently under Review.*

```text
├── cleaned_data/        # Cleaned data stored as .rds files
├── code/                # Econometric models and empirical analysis
│   ├── regressions/     # Model specifications estimated in the thesis
│   └── treatments/      # Data cleaning and variable preparation scripts
├── outputs/             # Generated figures and tables
│   ├── robustness/      # Robustness checks
│   ├── section1/        # Outputs corresponding to Section 1
│   ├── section2/        # Outputs corresponding to Section 2
│   ├── section3/        # Outputs corresponding to Section 3
│   └── stats/           # Summary statistics
├── raw_data/            # Original, unmodified datasets
├── .gitignore           # Ignores large data files and R workspace cache
├── README.md            # Repository documentation and replication guide
└── project.Rproj        # RStudio project file
